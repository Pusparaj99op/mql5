//+------------------------------------------------------------------+
//| GoldAggressiveScalper_OF.mq5                                     |
//| Aggressive scalper framework with DOM/tick-flow + dynamic risk    |
//+------------------------------------------------------------------+
#property version   "1.00"
#property description "XAUUSD-only aggressive scalper with order-flow proxy + dynamic risk + chart panel"

#include <Trade/Trade.mqh>
CTrade trade;

// -------------------- Inputs --------------------
input string InpSymbol              = "Gold.i#";     // trade ONLY this symbol
input ENUM_TIMEFRAMES InpTF1        = PERIOD_M1;     // allowed TF 1
input ENUM_TIMEFRAMES InpTF2        = PERIOD_M5;     // allowed TF 2

// Trading time (server time)
input int    InpStartHour           = 1;             // 01:00
input int    InpEndHour             = 23;            // 23:00

// Execution / scalping guards
input int    InpMaxSpreadPoints     = 350;           // max spread in points (tune per broker)
input int    InpMaxSlippagePoints   = 50;            // max slippage (points) for fills
input int    InpMinATRPoints        = 80;            // avoid dead market
input int    InpMaxATRPoints        = 2000;          // avoid extreme spikes/news

// Entry logic
input int    InpFastEMA             = 9;
input int    InpSlowEMA             = 21;
input int    InpRSIPeriod           = 7;
input double InpRSIMin              = 30.0;
input double InpRSIMax              = 70.0;

// Order-flow / DOM
input bool   InpUseDOMIfAvailable   = true;
input int    InpDOMLevels           = 10;            // sum top N levels each side
input double InpDOMImbalanceThresh  = 0.18;          // |imbalance| threshold

// Synthetic tick-flow (CVD proxy)
input int    InpTickFlowWindow      = 200;           // number of ticks in rolling window
input double InpTickDeltaThresh     = 0.55;          // directional ratio threshold [0..1]

// Stops/Targets
input bool   InpUseATRStops         = true;
input int    InpATRPeriod           = 14;
input double InpATR_SL_Mult         = 1.2;           // SL = ATR*mult
input double InpRR                  = 1.0;           // TP = SL*RR
input int    InpFixedSL_Points      = 600;           // used if ATR stops off
input int    InpFixedTP_Points      = 600;

// Risk management
input double InpBaseRiskPct         = 1.0;           // baseline risk % of equity per trade
input double InpMinRiskPct          = 0.2;
input double InpMaxRiskPct          = 2.5;
input bool   InpUseFractionalKelly  = true;
input double InpKellyFraction       = 0.25;          // quarter Kelly
input int    InpStatsLookbackTrades = 200;           // for winrate/payout estimate
input int    InpLoseStreakCut       = 3;             // reduce risk after N losses
input double InpLoseStreakFactor    = 0.5;           // risk *= factor

// Daily protection
input double InpMaxDailyDDPct       = 5.0;           // stop trading if equity drop today exceeds this
input bool   InpAllowUnlimitedTrades= true;          // no limit, but still guarded by protections

// Chart panel
input bool   InpShowPanel           = true;
input int    InpPanelCorner         = 0;             // 0=left top
input int    InpPanelX              = 10;
input int    InpPanelY              = 15;

// -------------------- Globals --------------------
int      hFastMA=-1, hSlowMA=-1, hRSI=-1, hATR=-1;
double   g_lastBid=0.0, g_lastAsk=0.0;

bool     g_dom_ok=false;
double   g_domImb=0.0;        // [-1..+1]
long     g_domBidVol=0, g_domAskVol=0;

double   g_tickBuyVol=0.0, g_tickSellVol=0.0; // rolling sums (approx)
double   g_tickDirRatio=0.5;  // buy/(buy+sell)
double   g_prevMid=0.0;

datetime g_dayStart=0;
double   g_dayEquityStart=0.0;

int      g_consecutiveLosses=0;

// ring buffer for tick volumes
double   g_tickVolBuf[];
int      g_tickDirBuf[]; // +1 buy, -1 sell, 0 flat
int      g_tickIdx=0;
int      g_tickCount=0;

// -------------------- Utils --------------------
bool IsAllowedSymbol()
{
   return (_Symbol==InpSymbol);
}

bool IsAllowedTF()
{
   ENUM_TIMEFRAMES tf=(ENUM_TIMEFRAMES)_Period;
   return (tf==InpTF1 || tf==InpTF2);
}

bool IsTradeTime()
{
   MqlDateTime tm; TimeToStruct(TimeCurrent(), tm);

   // Mon..Fri => 1..5
   if(tm.day_of_week==0 || tm.day_of_week==6) return false;

   if(tm.hour < InpStartHour) return false;
   if(tm.hour > InpEndHour)   return false;

   return true;
}

double PointsToPrice(int points)
{
   return points * _Point;
}

int SpreadPoints()
{
   double ask=SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask<=0 || bid<=0) return 999999;
   return (int)MathRound((ask-bid)/_Point);
}

double GetATRPoints()
{
   double atr[];
   if(CopyBuffer(hATR,0,0,1,atr)!=1) return 0.0;
   return atr[0]/_Point;
}

double Clamp(double x,double a,double b){ return MathMax(a, MathMin(b,x)); }

// tick-value based lot sizing: risk money / (SL points * money-per-point-per-lot)
double CalcLotsByRisk(double riskPct, double sl_points)
{
   if(sl_points<=0) return 0.0;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * (riskPct/100.0);

   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double vol_step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vol_min    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vol_max    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(tick_size<=0 || tick_value<=0 || vol_step<=0) return 0.0;

   // money per 1.0 lot for sl_points movement:
   double moneyPerLot = (sl_points*_Point / tick_size) * tick_value;

   if(moneyPerLot<=0) return 0.0;

   double lots = riskMoney / moneyPerLot;

   // normalize to volume step
   lots = MathFloor(lots/vol_step)*vol_step;
   lots = Clamp(lots, vol_min, vol_max);

   return lots;
}

// Estimate fractional Kelly % from EA trade history (simple, cautious)
double EstimateKellyPct()
{
   if(!InpUseFractionalKelly) return 0.0;

   HistorySelect(0, TimeCurrent());
   int deals = HistoryDealsTotal();
   if(deals<=0) return 0.0;

   // Scan last N closed position results for THIS symbol & magic (we keep magic=0 here for simplicity)
   int n=0; int wins=0;
   double sumWin=0.0, sumLoss=0.0;

   for(int i=deals-1; i>=0 && n<InpStatsLookbackTrades; --i)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket==0) continue;

      string sym = (string)HistoryDealGetString(dealTicket, DEAL_SYMBOL);
      if(sym!=_Symbol) continue;

      long entry = (long)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      if(entry!=DEAL_ENTRY_OUT) continue; // only exits

      double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                    + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                    + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);

      n++;
      if(profit>0){ wins++; sumWin += profit; }
      else if(profit<0){ sumLoss += -profit; }
   }

   if(n<30) return 0.0; // not enough stats => no kelly

   double W = (double)wins / (double)n;
   double avgWin = (wins>0) ? (sumWin/wins) : 0.0;
   int losses = n-wins;
   double avgLoss = (losses>0) ? (sumLoss/losses) : 0.0;

   if(avgLoss<=0 || avgWin<=0) return 0.0;

   double R = avgWin/avgLoss; // payoff ratio

   // Kelly fraction (simplified): f* = W - (1-W)/R
   double k = W - ((1.0 - W)/R);

   if(k<=0) return 0.0;
   return k * InpKellyFraction * 100.0; // convert to %
}

double EffectiveRiskPct()
{
   double risk = InpBaseRiskPct;

   // Add fractional Kelly suggestion (capped) as an adaptive overlay
   double kelly = EstimateKellyPct();
   if(kelly>0)
      risk = MathMax(risk, kelly); // take the higher of base vs. "edge" estimate (still capped below)

   // Losing streak throttle
   if(g_consecutiveLosses>=InpLoseStreakCut)
      risk *= InpLoseStreakFactor;

   return Clamp(risk, InpMinRiskPct, InpMaxRiskPct);
}

// Daily DD protection
void ResetDayIfNeeded()
{
   MqlDateTime tm; TimeToStruct(TimeCurrent(), tm);
   datetime day0 = StructToTime(tm) - (tm.hour*3600 + tm.min*60 + tm.sec); // start of day
   if(g_dayStart==0 || day0!=g_dayStart)
   {
      g_dayStart=day0;
      g_dayEquityStart=AccountInfoDouble(ACCOUNT_EQUITY);
   }
}

bool DailyProtectionOK()
{
   ResetDayIfNeeded();
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(g_dayEquityStart<=0) return true;
   double ddPct = 100.0*(g_dayEquityStart - eq)/g_dayEquityStart;
   return (ddPct < InpMaxDailyDDPct);
}

// -------------------- Order-flow: DOM --------------------
bool TryInitDOM()
{
   if(!InpUseDOMIfAvailable) return false;

   if(!MarketBookAdd(_Symbol)) // subscribe DOM
      return false;

   return true;
}

void UpdateDOMSnapshot()
{
   g_domImb=0.0; g_domBidVol=0; g_domAskVol=0;

   MqlBookInfo book[];
   if(!MarketBookGet(_Symbol, book))
   {
      g_dom_ok=false;
      return;
   }

   // Sum top N levels for bid and ask
   int total = ArraySize(book);
   if(total<=0){ g_dom_ok=false; return; }

   int usedBid=0, usedAsk=0;

   // book array contains both sides; iterate and aggregate nearest levels
   for(int i=0; i<total; i++)
   {
      if(book[i].type==BOOK_TYPE_BUY && usedBid<InpDOMLevels)
      {
         g_domBidVol += (long)book[i].volume;
         usedBid++;
      }
      else if(book[i].type==BOOK_TYPE_SELL && usedAsk<InpDOMLevels)
      {
         g_domAskVol += (long)book[i].volume;
         usedAsk++;
      }

      if(usedBid>=InpDOMLevels && usedAsk>=InpDOMLevels) break;
   }

   long denom = g_domBidVol + g_domAskVol;
   if(denom>0)
      g_domImb = (double)(g_domBidVol - g_domAskVol) / (double)denom;

   g_dom_ok=true;
}

// Called when DOM changes (if subscribed)
void OnBookEvent(const string &symbol)
{
   if(symbol==_Symbol)
      UpdateDOMSnapshot();
}

// -------------------- Order-flow: Tick delta proxy --------------------
void InitTickFlow()
{
   ArrayResize(g_tickVolBuf, InpTickFlowWindow);
   ArrayResize(g_tickDirBuf, InpTickFlowWindow);
   ArrayInitialize(g_tickVolBuf, 0.0);
   ArrayInitialize(g_tickDirBuf, 0);
   g_tickIdx=0; g_tickCount=0;
   g_tickBuyVol=0.0; g_tickSellVol=0.0;
}

void UpdateTickFlow()
{
   MqlTick t;
   if(!SymbolInfoTick(_Symbol, t)) return;

   double mid = 0.5*(t.bid + t.ask);
   if(g_prevMid==0.0) g_prevMid=mid;

   int dir=0;
   if(mid > g_prevMid) dir=+1;
   else if(mid < g_prevMid) dir=-1;

   // tick volume proxy
   double v = (double)t.volume; // for many brokers: 1; still ok as proxy
   if(v<=0) v=1.0;

   // remove outgoing element from rolling sums
   int oldDir = g_tickDirBuf[g_tickIdx];
   double oldV = g_tickVolBuf[g_tickIdx];
   if(oldDir==+1) g_tickBuyVol -= oldV;
   else if(oldDir==-1) g_tickSellVol -= oldV;

   // insert new element
   g_tickDirBuf[g_tickIdx]=dir;
   g_tickVolBuf[g_tickIdx]=v;

   if(dir==+1) g_tickBuyVol += v;
   else if(dir==-1) g_tickSellVol += v;

   g_tickIdx = (g_tickIdx + 1) % InpTickFlowWindow;
   if(g_tickCount < InpTickFlowWindow) g_tickCount++;

   double denom = g_tickBuyVol + g_tickSellVol;
   if(denom>0) g_tickDirRatio = g_tickBuyVol / denom;
   else g_tickDirRatio=0.5;

   g_prevMid=mid;
}

// -------------------- Indicators --------------------
bool InitIndicators()
{
   hFastMA = iMA(_Symbol, _Period, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlowMA = iMA(_Symbol, _Period, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hRSI    = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   hATR    = iATR(_Symbol, _Period, InpATRPeriod);

   return (hFastMA!=INVALID_HANDLE && hSlowMA!=INVALID_HANDLE && hRSI!=INVALID_HANDLE && hATR!=INVALID_HANDLE);
}

bool GetIndicators(double &fast, double &slow, double &rsi)
{
   double a[], b[], c[];
   if(CopyBuffer(hFastMA,0,0,2,a)!=2) return false;
   if(CopyBuffer(hSlowMA,0,0,2,b)!=2) return false;
   if(CopyBuffer(hRSI,0,0,1,c)!=1) return false;

   fast=a[0];
   slow=b[0];
   rsi=c[0];
   return true;
}

// -------------------- Trading decisions --------------------
bool GuardsOK()
{
   if(!IsAllowedSymbol()) return false;
   if(!IsAllowedTF())     return false;
   if(!IsTradeTime())     return false;
   if(!DailyProtectionOK()) return false;

   int spr = SpreadPoints();
   if(spr > InpMaxSpreadPoints) return false;

   double atrPts = GetATRPoints();
   if(atrPts < InpMinATRPoints) return false;
   if(atrPts > InpMaxATRPoints) return false;

   return true;
}

int SignalDirection()
{
   // +1 buy, -1 sell, 0 none
   double fast, slow, rsi;
   if(!GetIndicators(fast, slow, rsi)) return 0;

   // trend
   int trend = 0;
   if(fast > slow) trend = +1;
   else if(fast < slow) trend = -1;

   // RSI guard (avoid buying extremely overbought / selling extremely oversold)
   if(rsi < InpRSIMin && trend==-1) return 0;
   if(rsi > InpRSIMax && trend==+1) return 0;

   // Order-flow score
   double ofScore = 0.0;

   // DOM imbalance if available
   if(InpUseDOMIfAvailable && g_dom_ok)
   {
      if(g_domImb >  InpDOMImbalanceThresh) ofScore += 1.0;
      if(g_domImb < -InpDOMImbalanceThresh) ofScore -= 1.0;
   }

   // Tick-flow ratio
   // ratio close to 1 => buy pressure; close to 0 => sell pressure
   if(g_tickCount >= (int)(0.5*InpTickFlowWindow))
   {
      if(g_tickDirRatio > InpTickDeltaThresh) ofScore += 1.0;
      if(g_tickDirRatio < (1.0-InpTickDeltaThresh)) ofScore -= 1.0;
   }

   // Quant trigger: aggressive pullback in trend (simple)
   double close0 = iClose(_Symbol, _Period, 0);
   double close1 = iClose(_Symbol, _Period, 1);

   // Buy if trend up + mild pullback candle + orderflow positive
   if(trend==+1 && close0 < close1 && ofScore>0.0) return +1;

   // Sell if trend down + mild pullback candle + orderflow negative
   if(trend==-1 && close0 > close1 && ofScore<0.0) return -1;

   return 0;
}

bool PlaceTrade(int dir)
{
   MqlTick t;
   if(!SymbolInfoTick(_Symbol, t)) return false;

   double entry = (dir==+1)? t.ask : t.bid;

   // Stops/targets
   double sl=0, tp=0;
   double sl_points = 0;

   if(InpUseATRStops)
   {
      double atrPts = GetATRPoints();
      sl_points = atrPts * InpATR_SL_Mult;
   }
   else
   {
      sl_points = (double)InpFixedSL_Points;
   }

   double tp_points = sl_points * InpRR;
   if(!InpUseATRStops && InpFixedTP_Points>0) tp_points = (double)InpFixedTP_Points;

   if(dir==+1)
   {
      sl = entry - sl_points*_Point;
      tp = entry + tp_points*_Point;
   }
   else
   {
      sl = entry + sl_points*_Point;
      tp = entry - tp_points*_Point;
   }

   // Respect broker stop level (if provided)
   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist = stopsLevel * _Point;
   if(minDist>0)
   {
      if(dir==+1)
      {
         if((entry-sl) < minDist) sl = entry - minDist;
         if((tp-entry) < minDist) tp = entry + minDist;
      }
      else
      {
         if((sl-entry) < minDist) sl = entry + minDist;
         if((entry-tp) < minDist) tp = entry - minDist;
      }
   }

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   double riskPct = EffectiveRiskPct();
   double lots = CalcLotsByRisk(riskPct, sl_points);
   if(lots<=0) return false;

   trade.SetDeviationInPoints(InpMaxSlippagePoints);

   bool ok=false;
   string cmt = "GoldScalp_OF";

   if(dir==+1) ok = trade.Buy(lots, _Symbol, entry, sl, tp, cmt);
   else        ok = trade.Sell(lots, _Symbol, entry, sl, tp, cmt);

   return ok;
}

// -------------------- Panel: account + open trades --------------------
string PanelName(string s){ return "GAS_PANEL_" + s; }

void PanelSet(string name, string text, int yOffset)
{
   long cid=ChartID();
   string obj=PanelName(name);

   if(!ObjectFind(cid, obj))
   {
      ObjectCreate(cid, obj, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(cid, obj, OBJPROP_CORNER, InpPanelCorner);
      ObjectSetInteger(cid, obj, OBJPROP_XDISTANCE, InpPanelX);
      ObjectSetInteger(cid, obj, OBJPROP_YDISTANCE, InpPanelY + yOffset);
      ObjectSetInteger(cid, obj, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(cid, obj, OBJPROP_FONTSIZE, 10);
      ObjectSetString (cid, obj, OBJPROP_FONT, "Consolas");
   }
   ObjectSetString(cid, obj, OBJPROP_TEXT, text);
}

string SideStr(long type)
{
   if(type==POSITION_TYPE_BUY) return "BUY ";
   if(type==POSITION_TYPE_SELL) return "SELL";
   return "----";
}

void DrawPanel()
{
   if(!InpShowPanel) return;

   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq  = AccountInfoDouble(ACCOUNT_EQUITY);

   int spr = SpreadPoints();

   ResetDayIfNeeded();
   double todayPL = eq - g_dayEquityStart;

   string domTxt = g_dom_ok ? StringFormat("DOM imb: %.3f (B:%lld A:%lld)", g_domImb, g_domBidVol, g_domAskVol)
                            : "DOM imb: n/a";

   string tfTxt  = StringFormat("TickFlow ratio(buy): %.2f", g_tickDirRatio);

   PanelSet("L1", StringFormat("Symbol: %s  TF:%s  Spread:%d", _Symbol, EnumToString((ENUM_TIMEFRAMES)_Period), spr), 0);
   PanelSet("L2", StringFormat("Balance: %.2f  Equity: %.2f  Today P/L: %.2f", bal, eq, todayPL), 16);
   PanelSet("L3", StringFormat("Risk%% eff: %.2f  LossStreak: %d  DailyProtect: %s",
                               EffectiveRiskPct(), g_consecutiveLosses, DailyProtectionOK()?"OK":"STOP"), 32);
   PanelSet("L4", domTxt, 48);
   PanelSet("L5", tfTxt, 64);

   // Open trades list
   int y = 84;
   PanelSet("HDR", "Open positions:", y); y += 16;

   int total=PositionsTotal();
   int shown=0;

   for(int i=0;i<total && shown<8;i++)
   {
      if(!PositionSelectByIndex(i)) continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      if(sym!=_Symbol) continue;

      long type = PositionGetInteger(POSITION_TYPE);
      double vol = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double pr = PositionGetDouble(POSITION_PROFIT);
      ulong ticket = (ulong)PositionGetInteger(POSITION_TICKET);

      string line = StringFormat("#%I64u %s %.2f @%.2f SL %.2f TP %.2f P/L %.2f",
                                 ticket, SideStr(type), vol, price, sl, tp, pr);

      PanelSet("P"+(string)shown, line, y);
      y += 16;
      shown++;
   }

   // Clear unused lines
   for(int k=shown;k<8;k++)
      PanelSet("P"+(string)k, "", y + 16*(k-shown));
}

// -------------------- Trade result tracking (self-correcting) --------------------
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   // Update losing streak on closed deals
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD)
   {
      ulong deal = trans.deal;
      if(deal==0) return;

      if((string)HistoryDealGetString(deal, DEAL_SYMBOL)!=_Symbol) return;

      long entry = (long)HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry!=DEAL_ENTRY_OUT) return;

      double profit = HistoryDealGetDouble(deal, DEAL_PROFIT)
                    + HistoryDealGetDouble(deal, DEAL_SWAP)
                    + HistoryDealGetDouble(deal, DEAL_COMMISSION);

      if(profit<0) g_consecutiveLosses++;
      else if(profit>0) g_consecutiveLosses=0;
   }
}

// -------------------- EA lifecycle --------------------
int OnInit()
{
   if(!IsAllowedSymbol())
   {
      Print("Attach this EA only to symbol: ", InpSymbol, " (current: ", _Symbol, ")");
      return INIT_FAILED;
   }
   if(!IsAllowedTF())
   {
      Print("Attach this EA only to M1 or M5 (current: ", EnumToString((ENUM_TIMEFRAMES)_Period), ")");
      return INIT_FAILED;
   }

   if(!InitIndicators())
   {
      Print("Failed to init indicators.");
      return INIT_FAILED;
   }

   InitTickFlow();

   // Try DOM subscription
   g_dom_ok=false;
   if(InpUseDOMIfAvailable)
   {
      bool ok = TryInitDOM();
      if(!ok)
         Print("DOM not available/subscription failed. Will use tick-flow proxy.");
      else
         Print("DOM subscription OK (MarketBookAdd).");
   }

   ResetDayIfNeeded();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(InpUseDOMIfAvailable)
      MarketBookRelease(_Symbol);
}

void OnTick()
{
   UpdateTickFlow();
   if(InpUseDOMIfAvailable && g_dom_ok==false)
   {
      // occasional snapshot attempt even if OnBookEvent not firing
      UpdateDOMSnapshot();
   }

   DrawPanel();

   if(!GuardsOK()) return;

   int dir = SignalDirection();
   if(dir==0) return;

   // Aggressive: unlimited trades allowed, but you may still want to prevent duplicate same-tick spam
   // Minimal safety: only one trade per tick
   static datetime lastTradeTickTime=0;
   datetime now=TimeCurrent();
   if(now==lastTradeTickTime) return;

   bool ok = PlaceTrade(dir);
   if(ok) lastTradeTickTime=now;
}