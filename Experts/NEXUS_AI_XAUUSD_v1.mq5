//+------------------------------------------------------------------+
//|                   NEXUS_AI_XAUUSD_v1.mq5                       |
//|      Advanced XAUUSD Scalping EA  —  Profitable Build v2       |
//|  HTF Bias | EMA Stack | OFI | Kalman | Kelly | Self-Correct    |
//+------------------------------------------------------------------+
#property copyright "NEXUS AI Trading Systems"
#property version   "2.00"
#property description "Profitable XAUUSD Scalping EA — M5 with H1 HTF Bias"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//|                        INPUT PARAMETERS                         |
//+------------------------------------------------------------------+

input group "=== RISK MANAGEMENT ==="
input double  InpRiskPercent      = 1.2;    // Risk % of equity per trade
input double  InpMaxDailyLossPC   = 4.0;    // Max daily loss % of equity
input double  InpMaxDrawdownPC    = 12.0;   // Max drawdown % from equity peak
input int     InpMaxDailyTrades   = 20;     // Max trades per day
input double  InpMaxLotSize       = 3.0;    // Hard lot cap
input bool    InpUseKelly         = true;   // Quarter-Kelly lot scaling
input double  InpKellyFraction    = 0.25;   // Kelly fraction

input group "=== ATR STOP/TARGET ==="
input int     InpATRPeriod        = 14;     // ATR period (M5)
input double  InpSLMultiplier     = 1.2;    // SL = ATR x mult
input double  InpTPMultiplier     = 2.5;    // TP = ATR x mult (RR ~2.0)
input double  InpMinSLPts         = 60.0;   // Minimum SL points
input double  InpMaxSLPts         = 500.0;  // Maximum SL points

input group "=== SIGNAL ENGINE ==="
input int     InpMinScore         = 6;      // Min confluence score (0-14)
input int     InpEMAFast          = 8;      // Fast EMA (M5)
input int     InpEMAMid           = 21;     // Mid EMA (M5)
input int     InpEMASlow          = 50;     // Slow EMA (M5)
input int     InpHTF_EMAFast      = 21;     // Fast EMA (H1)
input int     InpHTF_EMASlow      = 50;     // Slow EMA (H1)
input int     InpRSIPeriod        = 14;     // RSI period
input int     InpOFPeriod         = 10;     // Order flow lookback bars
input double  InpOFThreshold      = 0.50;   // OFI threshold

input group "=== TRADE MANAGEMENT ==="
input bool    InpUseTrailing      = true;   // Trailing stop on/off
input double  InpTrailMult        = 1.0;    // Trail dist = ATR x mult
input bool    InpUseBreakEven     = true;   // Break-even on/off
input double  InpBEMult           = 0.9;    // Break-even at ATR x mult profit
input bool    InpUsePartial       = true;   // Partial close on/off
input double  InpPartialPct       = 50.0;   // Partial close %
input double  InpPartialTrigger   = 1.3;    // Partial trigger = ATR x mult

input group "=== SESSION FILTER ==="
input bool    InpLondonSession    = true;   // Trade London (07:00-12:00)
input bool    InpNYSession        = true;   // Trade New York (13:00-18:00)
input bool    InpAsiaSession      = false;  // Trade Asia (01:00-06:00)

input group "=== SELF CORRECTION ==="
input int     InpConsecLossPause  = 3;      // Consecutive losses -> pause
input int     InpPauseMinutes     = 60;     // Pause duration (minutes)
input int     InpPerfLookback     = 15;     // Trades for win rate evaluation

input int     InpMagicNumber      = 20250215;

//+------------------------------------------------------------------+
//|                        GLOBAL STATE                             |
//+------------------------------------------------------------------+
CTrade        g_trade;
CPositionInfo g_pos;

int           h_ATR_M5, h_RSI_M5;
int           h_EMA_Fast, h_EMA_Mid, h_EMA_Slow;
int           h_HTF_Fast, h_HTF_Slow;
int           h_ATR_H1;

double        buf_ATR_M5[], buf_RSI[];
double        buf_EMA_F[],  buf_EMA_M[], buf_EMA_S[];
double        buf_HTF_F[],  buf_HTF_S[];
double        buf_ATR_H1[];

// Kalman state
double        kf_x = 0.0, kf_p = 1.0;

// Performance
double        g_startEquity    = 0;
double        g_peakEquity     = 0;
double        g_dailyPnL       = 0;
int           g_dailyTrades    = 0;
int           g_consecLosses   = 0;
datetime      g_pauseUntil     = 0;
datetime      g_dayResetTime   = 0;

int           g_totalTrades    = 0;
int           g_totalWins      = 0;
double        g_adaptiveMult   = 1.0;

#define STATS_SIZE 40
double        g_statWin[STATS_SIZE];
double        g_statPnL[STATS_SIZE];
int           g_statIdx        = 0;

ulong         g_partialDone[100];
int           g_partialCount   = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   g_trade.SetDeviationInPoints(40);

   // M5 indicators
   h_ATR_M5   = iATR(_Symbol, PERIOD_M5, InpATRPeriod);
   h_RSI_M5   = iRSI(_Symbol, PERIOD_M5, InpRSIPeriod, PRICE_CLOSE);
   h_EMA_Fast = iMA (_Symbol, PERIOD_M5, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
   h_EMA_Mid  = iMA (_Symbol, PERIOD_M5, InpEMAMid,  0, MODE_EMA, PRICE_CLOSE);
   h_EMA_Slow = iMA (_Symbol, PERIOD_M5, InpEMASlow, 0, MODE_EMA, PRICE_CLOSE);

   // H1 trend bias
   h_HTF_Fast = iMA (_Symbol, PERIOD_H1, InpHTF_EMAFast, 0, MODE_EMA, PRICE_CLOSE);
   h_HTF_Slow = iMA (_Symbol, PERIOD_H1, InpHTF_EMASlow, 0, MODE_EMA, PRICE_CLOSE);
   h_ATR_H1   = iATR(_Symbol, PERIOD_H1, InpATRPeriod);

   if(h_ATR_M5==INVALID_HANDLE || h_RSI_M5==INVALID_HANDLE   ||
      h_EMA_Fast==INVALID_HANDLE|| h_EMA_Mid==INVALID_HANDLE  ||
      h_EMA_Slow==INVALID_HANDLE|| h_HTF_Fast==INVALID_HANDLE ||
      h_HTF_Slow==INVALID_HANDLE|| h_ATR_H1==INVALID_HANDLE)
   {
      Alert("NEXUS: Indicator init failed!"); return INIT_FAILED;
   }

   ArraySetAsSeries(buf_ATR_M5, true); ArraySetAsSeries(buf_RSI,    true);
   ArraySetAsSeries(buf_EMA_F,  true); ArraySetAsSeries(buf_EMA_M,  true);
   ArraySetAsSeries(buf_EMA_S,  true); ArraySetAsSeries(buf_HTF_F,  true);
   ArraySetAsSeries(buf_HTF_S,  true); ArraySetAsSeries(buf_ATR_H1, true);

   ArrayInitialize(g_statWin, -1);
   ArrayInitialize(g_statPnL,  0);

   g_startEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_peakEquity  = g_startEquity;

   // Seed Kalman filter with current market price to avoid cold-start divergence
   kf_x = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(kf_x <= 0) kf_x = 0.0;  // fallback if price not yet available

   Print("====================================================");
   Print(" NEXUS AI v2.0 | XAUUSD M5 | Magic:", InpMagicNumber);
   Print(" Equity: $", DoubleToString(g_startEquity,2),
         " | Leverage: 1:", AccountInfoInteger(ACCOUNT_LEVERAGE));
   Print("====================================================");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   int handles[8];
   handles[0]=h_ATR_M5;  handles[1]=h_RSI_M5;
   handles[2]=h_EMA_Fast; handles[3]=h_EMA_Mid;
   handles[4]=h_EMA_Slow; handles[5]=h_HTF_Fast;
   handles[6]=h_HTF_Slow; handles[7]=h_ATR_H1;
   for(int i=0;i<8;i++) IndicatorRelease(handles[i]);

   double finalEq = AccountInfoDouble(ACCOUNT_EQUITY);
   double wr = (g_totalTrades>0) ? (double)g_totalWins/g_totalTrades*100.0 : 0;
   Print("====================================================");
   Print(" NEXUS SESSION END");
   Print(" Trades: ",g_totalTrades," | WinRate: ",DoubleToString(wr,1),"%");
   Print(" Net P&L: $",DoubleToString(finalEq-g_startEquity,2));
   Print("====================================================");
}

//+------------------------------------------------------------------+
void OnTick()
{
   CheckDailyReset();

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > g_peakEquity) g_peakEquity = eq;

   if(!SafetyCheck()) return;
   ManagePositions();
   DrawDashboard();  // Update HUD on every tick (OpenTrade also calls this)

   static datetime s_lastBar = 0;
   datetime curBar = iTime(_Symbol, PERIOD_M5, 0);
   if(curBar == s_lastBar) return;
   s_lastBar = curBar;

   if(!IsSession())                  return;
   if(TimeCurrent() < g_pauseUntil)  return;
   if(g_dailyTrades >= InpMaxDailyTrades) return;
   if(!RefreshBuffers())             return;

   // ── HTF BIAS (H1) — #1 PROFITABILITY DRIVER ──────────────────
   // Only trade in the direction of the H1 EMA trend
   double htfFast = buf_HTF_F[1];
   double htfSlow = buf_HTF_S[1];
   bool   htfBull = (htfFast > htfSlow);
   bool   htfBear = (htfFast < htfSlow);

   // Require clear HTF separation (filter choppy H1 transitions)
   double htfSpread = MathAbs(htfFast - htfSlow);
   double atrH1     = buf_ATR_H1[1];
   if(htfSpread < atrH1 * 0.05) return;   // HTF is flat/sideways -> skip

   int buyScore=0, sellScore=0;
   CalcScores(buyScore, sellScore, htfBull, htfBear);

   UpdateAdaptiveMult();
   int minScore = (int)MathCeil(InpMinScore * g_adaptiveMult);

   // Only 1 open position per direction at a time
   if(buyScore  >= minScore && htfBull && CountByType(POSITION_TYPE_BUY)  == 0)
      OpenTrade(ORDER_TYPE_BUY,  buyScore);
   else if(sellScore >= minScore && htfBear && CountByType(POSITION_TYPE_SELL) == 0)
      OpenTrade(ORDER_TYPE_SELL, sellScore);
}

//+------------------------------------------------------------------+
//|                     SESSION FILTER                              |
//| Focus on high-liquidity sessions where Gold moves cleanly       |
//+------------------------------------------------------------------+
bool IsSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_week==0 || dt.day_of_week==6) return false;

   int h = dt.hour, m = dt.min;

   // Avoid first 15 min of each session open (spread / volatility spike)
   bool london = InpLondonSession && ((h==7 && m>=15)||(h>=8 && h<12));
   bool ny     = InpNYSession     && ((h==13 && m>=15)||(h>=14 && h<18));
   bool asia   = InpAsiaSession   && ((h==1  && m>=15)||(h>=2  && h<6));

   return (london || ny || asia);
}

//+------------------------------------------------------------------+
bool RefreshBuffers()
{
   if(CopyBuffer(h_ATR_M5,  0,0,30,buf_ATR_M5)<30) return false;
   if(CopyBuffer(h_RSI_M5,  0,0,30,buf_RSI)   <30) return false;
   if(CopyBuffer(h_EMA_Fast,0,0,5, buf_EMA_F) < 5) return false;
   if(CopyBuffer(h_EMA_Mid, 0,0,5, buf_EMA_M) < 5) return false;
   if(CopyBuffer(h_EMA_Slow,0,0,5, buf_EMA_S) < 5) return false;
   if(CopyBuffer(h_HTF_Fast,0,0,5, buf_HTF_F) < 5) return false;
   if(CopyBuffer(h_HTF_Slow,0,0,5, buf_HTF_S) < 5) return false;
   if(CopyBuffer(h_ATR_H1,  0,0,5, buf_ATR_H1)< 5) return false;
   return true;
}

//+------------------------------------------------------------------+
//|               KALMAN FILTER                                    |
//+------------------------------------------------------------------+
double KalmanUpdate(double meas)
{
   double Q=0.001, R=0.01;
   double x_p = kf_x;
   double p_p = kf_p + Q;
   double K   = p_p / (p_p + R);
   kf_x = x_p + K*(meas - x_p);
   kf_p = (1.0-K)*p_p;
   return kf_x;
}

//+------------------------------------------------------------------+
//|             ORDER FLOW IMBALANCE                               |
//+------------------------------------------------------------------+
double CalcOFI(int period)
{
   double opens[],closes[],highs[],lows[];
   long   tv[];
   ArraySetAsSeries(opens,true); ArraySetAsSeries(closes,true);
   ArraySetAsSeries(highs,true); ArraySetAsSeries(lows,  true);
   ArraySetAsSeries(tv,   true);

   if(CopyOpen (_Symbol,PERIOD_M5,1,period,opens)       <period) return 0;
   if(CopyClose(_Symbol,PERIOD_M5,1,period,closes)      <period) return 0;
   if(CopyHigh (_Symbol,PERIOD_M5,1,period,highs)       <period) return 0;
   if(CopyLow  (_Symbol,PERIOD_M5,1,period,lows)        <period) return 0;
   if(CopyTickVolume(_Symbol,PERIOD_M5,1,period,tv)     <period) return 0;

   double bv=0, sv=0;
   for(int i=0;i<period;i++)
   {
      double rng = highs[i]-lows[i];
      if(rng<_Point) continue;
      double v = (double)tv[i];
      bv += v*(closes[i]-lows[i]) /rng;
      sv += v*(highs[i]-closes[i])/rng;
   }
   double tot = bv+sv;
   return (tot>0)?(bv-sv)/tot:0;
}

//+------------------------------------------------------------------+
//|             Z-SCORE  (mean reversion measure)                  |
//+------------------------------------------------------------------+
double CalcZScore(int period)
{
   double cl[];
   ArraySetAsSeries(cl,true);
   if(CopyClose(_Symbol,PERIOD_M5,1,period,cl)<period) return 0;
   double mean=0;
   for(int i=0;i<period;i++) mean+=cl[i];
   mean/=period;
   double var=0;
   for(int i=0;i<period;i++) var+=MathPow(cl[i]-mean,2);
   double sd=MathSqrt(var/period);
   double c=iClose(_Symbol,PERIOD_M5,1);
   return (sd>_Point)?(c-mean)/sd:0;
}

//+------------------------------------------------------------------+
//|           CANDLE CONFIRMATION                                  |
//+------------------------------------------------------------------+
int CandlePattern(int shift=1)
{
   double o=iOpen (_Symbol,PERIOD_M5,shift);
   double c=iClose(_Symbol,PERIOD_M5,shift);
   double h=iHigh (_Symbol,PERIOD_M5,shift);
   double l=iLow  (_Symbol,PERIOD_M5,shift);
   double body =MathAbs(c-o);
   double range=h-l;
   if(range<_Point) return 0;
   if(body/range<0.35) return 0;   // doji
   return (c>o)?1:-1;
}

//+------------------------------------------------------------------+
//|         MULTI-FACTOR SIGNAL SCORE ENGINE                       |
//+------------------------------------------------------------------+
void CalcScores(int &buy, int &sell, bool htfBull, bool htfBear)
{
   buy = sell = 0;

   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double mid = (bid+ask)/2.0;
   double atr = buf_ATR_M5[1];
   if(atr<_Point) return;

   double ef1=buf_EMA_F[1], ef2=buf_EMA_F[2];
   double em1=buf_EMA_M[1], em2=buf_EMA_M[2];
   double es1=buf_EMA_S[1];
   double rsi=buf_RSI[1];

   // ─── SIGNAL 1: M5 EMA STACK (+2) ────────────────────────────
   // All 3 EMAs aligned = clear short-term trend
   if(ef1>em1 && em1>es1) buy +=2;
   if(ef1<em1 && em1<es1) sell+=2;

   // ─── SIGNAL 2: FAST EMA CROSS OVER MID EMA (+2) ─────────────
   // Fresh cross = new momentum burst
   if(ef1>em1 && ef2<=em2) buy +=2;
   if(ef1<em1 && ef2>=em2) sell+=2;

   // ─── SIGNAL 3: PULLBACK TO FAST EMA (+1) ────────────────────
   // Price dipped to EMA then recovered = ideal entry
   double c1=iClose(_Symbol,PERIOD_M5,1);
   double c2=iClose(_Symbol,PERIOD_M5,2);
   if(c2<ef1 && c1>ef1 && htfBull) buy++;
   if(c2>ef1 && c1<ef1 && htfBear) sell++;

   // ─── SIGNAL 4: RSI (+1/+2) ──────────────────────────────────
   if(rsi>50 && rsi<68) buy++;
   if(rsi<50 && rsi>32) sell++;
   // Oversold bounce in HTF uptrend / overbought fade in downtrend
   if(rsi<40 && buf_RSI[1]>buf_RSI[2] && htfBull) buy +=2;
   if(rsi>60 && buf_RSI[1]<buf_RSI[2] && htfBear) sell+=2;

   // ─── SIGNAL 5: ORDER FLOW IMBALANCE (+2/+1) ─────────────────
   double ofi = CalcOFI(InpOFPeriod);
   if(ofi >  InpOFThreshold) buy +=2;
   if(ofi < -InpOFThreshold) sell+=2;
   if(ofi > 0.25) buy++;
   if(ofi <-0.25) sell++;

   // ─── SIGNAL 6: KALMAN MEAN REVERSION (+1) ───────────────────
   double kEst = KalmanUpdate(mid);
   double kDev = (mid-kEst)/(atr+_Point);
   if(kDev<-0.3 && htfBull) buy++;
   if(kDev> 0.3 && htfBear) sell++;

   // ─── SIGNAL 7: Z-SCORE (+1) ─────────────────────────────────
   double zs = CalcZScore(20);
   if(zs<-1.2 && htfBull) buy++;
   if(zs> 1.2 && htfBear) sell++;

   // ─── SIGNAL 8: CANDLE CONFIRMATION (+1) ─────────────────────
   // Last closed bar must confirm direction
   int cp = CandlePattern(1);
   if(cp== 1) buy++;
   if(cp==-1) sell++;

   // ─── SIGNAL 9: VOLATILITY HEALTH CHECK (+1) ─────────────────
   // Filter dead markets and extreme spike zones
   double atrH1 = buf_ATR_H1[1];
   double norm  = atr / (atrH1/12.0 + _Point);
   bool goodVol = (norm>0.6 && norm<3.0);
   if(goodVol) { buy++; sell++; }
   // Extreme spike = skip entirely
   if(norm>4.0) { buy=0; sell=0; return; }

   // ─── PENALTIES ──────────────────────────────────────────────
   // Penalise counter-HTF signals hard
   if(!htfBull) buy  = MathMax(0, buy  -3);
   if(!htfBear) sell = MathMax(0, sell -3);

   // Self-correction: consecutive loss pause trigger
   if(g_consecLosses >= InpConsecLossPause)
   {
      g_pauseUntil   = TimeCurrent()+(InpPauseMinutes*60);
      g_consecLosses = 0;
      Print("NEXUS: PAUSE TRIGGERED — ",InpConsecLossPause,
            " consec losses. Pausing ",InpPauseMinutes," min.");
      buy=sell=0;
   }
}

//+------------------------------------------------------------------+
//|         KELLY + VOLATILITY-ADJUSTED LOT SIZING               |
//+------------------------------------------------------------------+
double CalcLots(double slPts)
{
   double eq     = AccountInfoDouble(ACCOUNT_EQUITY);
   double tv     = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double ts     = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double minLot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxLot = MathMin(InpMaxLotSize,SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX));
   double step   = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(ts<_Point || tv<_Point) return minLot;

   double riskPc = InpRiskPercent/100.0;

   // Quarter-Kelly refinement
   if(InpUseKelly && g_totalTrades>=12)
   {
      double wr = WinRate(InpPerfLookback);
      double aw = AvgWin();
      double al = AvgLoss();
      if(al>_Point && wr>0)
      {
         double rr    = aw/(al+_Point);
         double kelly = (wr-(1.0-wr)/(rr+_Point))*InpKellyFraction;
         if(kelly>0) riskPc = MathMin(riskPc, MathMax(kelly, 0.004));
      }
   }

   double riskAmt = eq*riskPc;
   double vpp     = tv/ts;
   if(vpp<_Point) return minLot;

   double lots = riskAmt/(slPts*vpp);
   lots = MathFloor(lots/step)*step;
   lots = MathMax(minLot,MathMin(maxLot,lots));

   // Margin safety guard
   double reqMgn=0;
   if(OrderCalcMargin(ORDER_TYPE_BUY,_Symbol,lots,
      SymbolInfoDouble(_Symbol,SYMBOL_ASK),reqMgn))
   {
      double freeMgn = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(reqMgn>freeMgn*0.70)
      {
         lots=MathFloor(lots*0.5/step)*step;
         lots=MathMax(minLot,lots);
      }
   }
   return lots;
}

//+------------------------------------------------------------------+
//|                     OPEN TRADE                                 |
//+------------------------------------------------------------------+
void OpenTrade(ENUM_ORDER_TYPE type, int score)
{
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double atr = buf_ATR_M5[1];
   double pt  = _Point;

   // Score bonus: high conviction -> bigger TP
   double tpBoost = 1.0 + MathMin((score-InpMinScore)*0.07, 0.35);

   double slDist = MathMax(InpMinSLPts*pt,
                   MathMin(InpMaxSLPts*pt, atr*InpSLMultiplier));
   double tpDist = slDist*(InpTPMultiplier/InpSLMultiplier)*tpBoost;

   // Broker minimum stops check
   long stopLvl = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double minStp = stopLvl*pt*1.2;
   if(slDist<minStp) slDist=minStp;
   if(tpDist<minStp) tpDist=minStp;

   double entry,sl,tp;
   if(type==ORDER_TYPE_BUY)
   {
      entry=ask;
      sl=NormalizeDouble(entry-slDist,_Digits);
      tp=NormalizeDouble(entry+tpDist,_Digits);
   }
   else
   {
      entry=bid;
      sl=NormalizeDouble(entry+slDist,_Digits);
      tp=NormalizeDouble(entry-tpDist,_Digits);
   }

   double lots = CalcLots(slDist/pt);
   double rr   = tpDist/slDist;

   string cmt = StringFormat("NEXUS|S%d|RR%.1f",score,rr);
   bool ok = (type==ORDER_TYPE_BUY) ?
             g_trade.Buy (lots,_Symbol,0,sl,tp,cmt) :
             g_trade.Sell(lots,_Symbol,0,sl,tp,cmt);

   if(ok)
   {
      g_dailyTrades++;
      Print(StringFormat("NEXUS OPEN: %s %.2f lots | SL=%.5f TP=%.5f | RR=%.2f | Score=%d",
            (type==ORDER_TYPE_BUY)?"BUY":"SELL",lots,sl,tp,rr,score));
   }
   else
      Print("NEXUS: Open failed — ",g_trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//|         POSITION MANAGEMENT (BE / Chandelier Trail / Partial)  |
//+------------------------------------------------------------------+
void ManagePositions()
{
   if(ArraySize(buf_ATR_M5)<3) return;
   double atr = buf_ATR_M5[1];
   if(atr<_Point) return;
   double pt = _Point;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!g_pos.SelectByIndex(i))          continue;
      if(g_pos.Symbol()!=_Symbol)          continue;
      if(g_pos.Magic() !=InpMagicNumber)   continue;

      ulong  ticket = g_pos.Ticket();
      double openPx = g_pos.PriceOpen();
      double curSL  = g_pos.StopLoss();
      double curTP  = g_pos.TakeProfit();
      double lots   = g_pos.Volume();
      ENUM_POSITION_TYPE pType = g_pos.PositionType();

      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double mkt = (pType==POSITION_TYPE_BUY)?bid:ask;
      double prof= (pType==POSITION_TYPE_BUY)?(mkt-openPx):(openPx-mkt);

      double newSL = curSL;
      bool   mod   = false;

      // ── BREAK EVEN ──────────────────────────────────────────
      if(InpUseBreakEven && prof>=atr*InpBEMult)
      {
         double beSL = (pType==POSITION_TYPE_BUY)?
                        openPx+pt*5 : openPx-pt*5;
         if(pType==POSITION_TYPE_BUY  && beSL>curSL+pt) { newSL=beSL; mod=true; }
         if(pType==POSITION_TYPE_SELL && (curSL==0||beSL<curSL-pt)) { newSL=beSL; mod=true; }
      }

      // ── CHANDELIER TRAILING STOP ────────────────────────────
      if(InpUseTrailing)
      {
         double trailDist = atr*InpTrailMult;
         if(pType==POSITION_TYPE_BUY)
         {
            double hh  = HighestHigh(5);
            double tSL = (hh>0)?hh-trailDist:bid-trailDist;
            if(tSL>newSL+pt) { newSL=tSL; mod=true; }
         }
         else
         {
            double ll  = LowestLow(5);
            double tSL = (ll>0)?ll+trailDist:ask+trailDist;
            if(curSL==0||tSL<newSL-pt) { newSL=tSL; mod=true; }
         }
      }

      if(mod) g_trade.PositionModify(ticket,NormalizeDouble(newSL,_Digits),curTP);

      // ── PARTIAL CLOSE ───────────────────────────────────────
      if(InpUsePartial && !IsPartialDone(ticket) && prof>=atr*InpPartialTrigger)
      {
         double step2  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
         double minLt  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
         double pLots  = MathFloor(lots*(InpPartialPct/100.0)/step2)*step2;
         if(pLots>=minLt && pLots<lots)
         {
            if(g_trade.PositionClosePartial(ticket,pLots))
            {
               MarkPartialDone(ticket);
               Print("NEXUS PARTIAL: ",ticket," closed ",pLots," lots");
            }
         }
      }
   }
}

// ── Chandelier helpers ──
double HighestHigh(int bars)
{
   double h[]; ArraySetAsSeries(h,true);
   if(CopyHigh(_Symbol,PERIOD_M5,1,bars,h)<bars) return 0;
   double mx=h[0];
   for(int i=1;i<bars;i++) if(h[i]>mx) mx=h[i];
   return mx;
}
double LowestLow(int bars)
{
   double l[]; ArraySetAsSeries(l,true);
   if(CopyLow(_Symbol,PERIOD_M5,1,bars,l)<bars) return 0;
   double mn=l[0];
   for(int i=1;i<bars;i++) if(l[i]<mn) mn=l[i];
   return mn;
}

//+------------------------------------------------------------------+
//|              SAFETY CHECKS                                     |
//+------------------------------------------------------------------+
bool SafetyCheck()
{
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);

   if(g_peakEquity>0)
   {
      double dd = (g_peakEquity-eq)/g_peakEquity*100.0;
      if(dd>=InpMaxDrawdownPC)
      {
         static datetime lw=0;
         if(TimeCurrent()-lw>300)
         { Print("NEXUS: MAX DD ",DoubleToString(dd,1),"% — closing all."); CloseAll(); lw=TimeCurrent(); }
         return false;
      }
   }

   double dlim = g_startEquity*InpMaxDailyLossPC/100.0;
   if(g_dailyPnL<=-dlim)
   {
      static datetime lw2=0;
      if(TimeCurrent()-lw2>300)
      { Print("NEXUS: DAILY LOSS LIMIT $",DoubleToString(g_dailyPnL,2)); lw2=TimeCurrent(); }
      return false;
   }
   return true;
}

void CheckDailyReset()
{
   MqlDateTime now,last;
   TimeToStruct(TimeCurrent(),now);
   TimeToStruct(g_dayResetTime,last);
   if(now.day!=last.day)
   {
      g_dailyPnL=0; g_dailyTrades=0; g_dayResetTime=TimeCurrent();
      Print("NEXUS: Daily reset — ",TimeToString(TimeCurrent(),TIME_DATE));
   }
}

//+------------------------------------------------------------------+
//|         ADAPTIVE THRESHOLD (self-correction)                   |
//+------------------------------------------------------------------+
void UpdateAdaptiveMult()
{
   if(g_totalTrades<8){g_adaptiveMult=1.0;return;}
   double wr=WinRate(InpPerfLookback);
   if     (wr>0.60) g_adaptiveMult=0.90;
   else if(wr>0.50) g_adaptiveMult=1.00;
   else if(wr>0.42) g_adaptiveMult=1.20;
   else             g_adaptiveMult=1.40;
}

//+------------------------------------------------------------------+
//|         TRADE EVENT HANDLER                                    |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &req,
                        const MqlTradeResult      &res)
{
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetInteger(trans.deal,DEAL_MAGIC)!=InpMagicNumber) return;
   if(HistoryDealGetInteger(trans.deal,DEAL_ENTRY)!=DEAL_ENTRY_OUT) return;

   double pnl = HistoryDealGetDouble(trans.deal,DEAL_PROFIT)
              + HistoryDealGetDouble(trans.deal,DEAL_SWAP)
              + HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
   bool win = (pnl>0);

   g_dailyPnL+=pnl;
   g_totalTrades++;
   if(win){g_totalWins++;g_consecLosses=0;}
   else   {g_consecLosses++;}

   g_statWin[g_statIdx]=win?1:0;
   g_statPnL[g_statIdx]=pnl;
   g_statIdx=(g_statIdx+1)%STATS_SIZE;

   double wr=(g_totalTrades>0)?(double)g_totalWins/g_totalTrades*100.0:0; P&L=$%.2f | DayPnL=$%.2f | WR=%.1f%% | CL=%d | Mult=%.2f",
         pnl,g_dailyPnL,wr,g_consecLosses,g_adaptiveMult));

   DrawDashboard();
}

//+------------------------------------------------------------------+
//|              STATS HELPERS                                     |
//+------------------------------------------------------------------+
double WinRate(int n)
{
   int cnt=MathMin(n, g_totalTrades);
   if(cnt==0) return 0.5;
   double w=0;
   for(int i=0;i<cnt;i++)
   {
      int idx=((g_statIdx-1-i)+STATS_SIZE)%STATS_SIZE;
      if(g_statWin[idx]>0) w++;
   }
   return w/cnt;
}
double AvgWin()
{
   int n=MathMin(g_totalTrades, STATS_SIZE);
   double s=0; int c=0;
   for(int i=0;i<n;i++)
   {
      int idx=((g_statIdx-1-i)+STATS_SIZE)%STATS_SIZE;
      if(g_statWin[idx]>0 && g_statPnL[idx]>0){s+=g_statPnL[idx]; c++;}
   }
   return c>0 ? s/c : 1.0;
}
double AvgLoss()
{
   int n=MathMin(g_totalTrades, STATS_SIZE);
   double s=0; int c=0;
   for(int i=0;i<n;i++)
   {
      int idx=((g_statIdx-1-i)+STATS_SIZE)%STATS_SIZE;
      if(g_statWin[idx]==0 && g_statPnL[idx]<0){s+=MathAbs(g_statPnL[idx]); c++;}
   }
   return c>0 ? s/c : 1.0;
}

int CountByType(ENUM_POSITION_TYPE pt)
{
   int n=0;
   for(int i=0;i<PositionsTotal();i++)
      if(g_pos.SelectByIndex(i)&&g_pos.Symbol()==_Symbol&&
         g_pos.Magic()==InpMagicNumber&&g_pos.PositionType()==pt) n++;
   return n;
}
void CloseAll()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(g_pos.SelectByIndex(i)&&g_pos.Symbol()==_Symbol&&
         g_pos.Magic()==InpMagicNumber)
         g_trade.PositionClose(g_pos.Ticket());
}
bool IsPartialDone(ulong t)
{ for(int i=0;i<g_partialCount;i++) if(g_partialDone[i]==t) return true; return false; }
void MarkPartialDone(ulong t)
{ if(g_partialCount<100){g_partialDone[g_partialCount]=t;g_partialCount++;} }

//+------------------------------------------------------------------+
//|               LIVE HUD DASHBOARD                               |
//+------------------------------------------------------------------+
void DrawDashboard()
{
   double eq  = AccountInfoDouble(ACCOUNT_EQUITY);
   double dd  = (g_peakEquity>0)?(g_peakEquity-eq)/g_peakEquity*100.0:0;
   double wr  = (g_totalTrades>0)?(double)g_totalWins/g_totalTrades*100.0:0;
   bool   ses = IsSession();

   string lines[7];
   lines[0]=StringFormat("NEXUS AI v2.0  |  %s  |  %s",_Symbol,ses?"ACTIVE":"OFF");
   lines[1]=StringFormat("Equity: $%.2f  |  Peak DD: %.1f%%",eq,dd);
   lines[2]=StringFormat("Day P&L: $%.2f  |  Trades: %d/%d",g_dailyPnL,g_dailyTrades,InpMaxDailyTrades);
   lines[3]=StringFormat("Total: %d  |  WinRate: %.1f%%",g_totalTrades,wr);
   lines[4]=StringFormat("Adapt: %.2f  |  ConsecLoss: %d",g_adaptiveMult,g_consecLosses);
   lines[5]=StringFormat("AvgWin: $%.2f  |  AvgLoss: $%.2f",AvgWin(),AvgLoss());
   lines[6]=(TimeCurrent()<g_pauseUntil)?
             StringFormat("PAUSED until %s",TimeToString(g_pauseUntil,TIME_MINUTES)):"READY";

   for(int i=0;i<7;i++)
   {
      string nm="NEXUS_HUD_"+IntegerToString(i);
      if(ObjectFind(0,nm)<0)
      {
         ObjectCreate(0,nm,OBJ_LABEL,0,0,0);
         ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,10);
         ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,20+i*18);
         ObjectSetInteger(0,nm,OBJPROP_CORNER,CORNER_LEFT_UPPER);
         ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,9);
         ObjectSetString (0,nm,OBJPROP_FONT,"Courier New");
      }
      color clr=(i==6&&TimeCurrent()<g_pauseUntil)?clrOrangeRed:(i==0)?clrGold:clrSilver;
      ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);
      ObjectSetString (0,nm,OBJPROP_TEXT,lines[i]);
   }
   ChartRedraw(0);
}

void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp)
{ if(id==CHARTEVENT_CHART_CHANGE) DrawDashboard(); }
//+------------------------------------------------------------------+