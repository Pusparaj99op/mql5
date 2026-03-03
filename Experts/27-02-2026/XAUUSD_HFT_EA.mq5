//+------------------------------------------------------------------+
//|                                            XAUUSD_HFT_EA.mq5    |
//|                         M1 Breakout Scalper for Gold (XAUUSD)   |
//|  Enters on breakout of last N closed M1 candles' high/low range. |
//|  Filters: spread cap, total-open-risk cap, margin cap per trade. |
//+------------------------------------------------------------------+
#property copyright "MIT License"
#property version   "1.00"
#property description "M1 breakout scalper for XAUUSD."
#property description "Enters long on breakout above N-candle high, short on breakout below N-candle low."
#property description "Configurable TP, SL, spread limit, risk %, and lot sizing."
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//=== Trade Sizing =========================================================
input group              "=== Trade Sizing ==="
input double DefaultLotSize    = 0.01;   // Base lot size per trade
input double MarginCapPercent  = 5.0;    // Max % of free margin used per new trade

//=== Strategy =============================================================
input group              "=== Strategy ==="
input int    BreakoutCandles   = 5;      // Closed candles to define high/low range
input int    MaxSpread         = 60;     // Max allowed spread in points (skip if wider)
input int    TP_Points         = 200;    // Take profit distance in points
input int    SL_Points         = 100;    // Stop loss distance in points

//=== Risk Management ======================================================
input group              "=== Risk Management ==="
input double MaxRiskPercent    = 2.0;    // Max total open risk as % of account balance

//=== Order Identity =======================================================
input group              "=== Order Identity ==="
input int    MagicNumber       = 20240101; // Unique identifier for this EA's orders
input string TradeComment      = "XAUUSD_HFT"; // Order comment

//==========================================================================
//  Global objects
//==========================================================================
CTrade        g_trade;
CPositionInfo g_pos;

//==========================================================================
//  Per-candle state  (reset when a new M1 candle opens)
//==========================================================================
datetime g_lastCandleTime    = 0;
bool     g_boughtThisCandle  = false;
bool     g_soldThisCandle    = false;

//==========================================================================
//  Cached symbol properties  (populated in OnInit)
//==========================================================================
double g_point        = 0.0;
double g_tickSize     = 0.0;
double g_tickValue    = 0.0;
double g_minLot       = 0.0;
double g_lotStep      = 0.0;
double g_contractSize = 0.0;

//+------------------------------------------------------------------+
//| Expert initialisation                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Basic period check
   if(Period() != PERIOD_M1)
   {
      Alert("XAUUSD_HFT: Must be attached to an M1 chart. Aborting.");
      return INIT_PARAMETERS_INCORRECT;
   }

   //--- Symbol advisory (allow broker variants like XAUUSDm)
   string sym = Symbol();
   if(StringFind(sym, "XAUUSD") < 0)
      Print("XAUUSD_HFT: WARNING — symbol is '", sym, "', expected XAUUSD variant.");

   //--- Input validation
   if(BreakoutCandles < 2)
   {
      Alert("XAUUSD_HFT: BreakoutCandles must be >= 2.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(SL_Points <= 0 || TP_Points <= 0)
   {
      Alert("XAUUSD_HFT: SL_Points and TP_Points must be > 0.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(MaxSpread <= 0)
   {
      Alert("XAUUSD_HFT: MaxSpread must be > 0.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(DefaultLotSize <= 0.0 || MarginCapPercent <= 0.0 || MaxRiskPercent <= 0.0)
   {
      Alert("XAUUSD_HFT: DefaultLotSize, MarginCapPercent and MaxRiskPercent must be > 0.");
      return INIT_PARAMETERS_INCORRECT;
   }

   //--- Cache symbol properties
   g_point        = SymbolInfoDouble(sym, SYMBOL_POINT);
   g_tickSize     = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   g_tickValue    = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   g_contractSize = SymbolInfoDouble(sym, SYMBOL_TRADE_CONTRACT_SIZE);
   g_minLot       = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   g_lotStep      = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);

   PrintFormat("XAUUSD_HFT Init | symbol=%s | point=%.5f | tickSize=%.5f | tickValue=%.5f "
               "| contractSize=%.0f | minLot=%.2f | lotStep=%.2f",
               sym, g_point, g_tickSize, g_tickValue,
               g_contractSize, g_minLot, g_lotStep);

   //--- Sanity: avoid division by zero in risk math
   if(g_point <= 0.0 || g_tickSize <= 0.0)
   {
      Alert("XAUUSD_HFT: Invalid symbol point/tickSize. Check broker symbol settings.");
      return INIT_PARAMETERS_INCORRECT;
   }

   //--- Configure CTrade
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(10);  // 1 point slippage tolerance

   //--- Detect order filling mode supported by this broker/symbol
   int fillMode = (int)SymbolInfoInteger(sym, SYMBOL_FILLING_MODE);
   if((fillMode & ORDER_FILLING_FOK) != 0)
      g_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((fillMode & ORDER_FILLING_IOC) != 0)
      g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      g_trade.SetTypeFilling(ORDER_FILLING_RETURN);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // No chart objects created by this EA; nothing to remove.
   g_lastCandleTime   = 0;
   g_boughtThisCandle = false;
   g_soldThisCandle   = false;
}

//+------------------------------------------------------------------+
//| Main tick handler                                                |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsSymbolReady()) return;

   //--- Detect new candle and reset per-candle flags inside
   IsNewCandle();

   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   //--- Calculate the N-candle range
   double rangeHigh = 0.0, rangeLow = 0.0;
   if(!GetBreakoutLevels(rangeHigh, rangeLow)) return;

   //--- Spread filter (also rejects 0-spread stale-quote condition)
   int spread = GetSpread();
   if(spread <= 0 || spread > MaxSpread) return;

   double balance       = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0.0)   return;
   double maxRiskAmount = balance * MaxRiskPercent / 100.0;

   //=== BUY signal: ask price breaks above the range high ================
   if(ask > rangeHigh && !g_boughtThisCandle)
   {
      if(GetTotalOpenRisk() < maxRiskAmount)
      {
         double lot = CalcCappedLot(ORDER_TYPE_BUY, ask);
         if(lot >= g_minLot)
         {
            if(OpenBuy(lot, ask))
               g_boughtThisCandle = true;
         }
         else
            Print("XAUUSD_HFT: BUY skipped — lot below minimum after margin cap.");
      }
      else
         Print("XAUUSD_HFT: BUY skipped — max open risk reached.");
   }

   //=== SELL signal: bid price breaks below the range low ================
   if(bid < rangeLow && !g_soldThisCandle)
   {
      if(GetTotalOpenRisk() < maxRiskAmount)
      {
         double lot = CalcCappedLot(ORDER_TYPE_SELL, bid);
         if(lot >= g_minLot)
         {
            if(OpenSell(lot, bid))
               g_soldThisCandle = true;
         }
         else
            Print("XAUUSD_HFT: SELL skipped — lot below minimum after margin cap.");
      }
      else
         Print("XAUUSD_HFT: SELL skipped — max open risk reached.");
   }
}

//+------------------------------------------------------------------+
//| Pre-trade safety gate                                            |
//+------------------------------------------------------------------+
bool IsSymbolReady()
{
   //--- Market must be fully open for trading
   if((int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL)
      return false;

   //--- Need enough closed bars for the breakout range
   if(iBars(NULL, PERIOD_M1) < BreakoutCandles + 2)
      return false;

   //--- Prices must be valid
   if(SymbolInfoDouble(Symbol(), SYMBOL_ASK) <= 0.0)
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Detect M1 candle change and reset per-candle entry flags         |
//+------------------------------------------------------------------+
bool IsNewCandle()
{
   datetime currentOpen = iTime(NULL, PERIOD_M1, 0);
   if(currentOpen != g_lastCandleTime)
   {
      g_lastCandleTime   = currentOpen;
      g_boughtThisCandle = false;
      g_soldThisCandle   = false;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Find high/low of last BreakoutCandles closed candles             |
//| Bars 1..BreakoutCandles (bar 0 is the forming candle, excluded)  |
//+------------------------------------------------------------------+
bool GetBreakoutLevels(double &rangeHigh, double &rangeLow)
{
   int highIdx = iHighest(NULL, PERIOD_M1, MODE_HIGH, BreakoutCandles, 1);
   int lowIdx  = iLowest (NULL, PERIOD_M1, MODE_LOW,  BreakoutCandles, 1);

   if(highIdx < 0 || lowIdx < 0) return false;

   rangeHigh = iHigh(NULL, PERIOD_M1, highIdx);
   rangeLow  = iLow (NULL, PERIOD_M1, lowIdx);

   if(rangeHigh <= 0.0 || rangeLow <= 0.0 || rangeHigh <= rangeLow)
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Return current live spread in broker points                      |
//+------------------------------------------------------------------+
int GetSpread()
{
   return (int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
}

//+------------------------------------------------------------------+
//| Sum the monetised risk of all open EA positions                  |
//| Risk per position = SL_distance_in_points × valuePerPoint × lots|
//+------------------------------------------------------------------+
double GetTotalOpenRisk()
{
   //--- Value per 1-point move per 1 lot in account currency
   //    Correct formula: tickValue * point / tickSize
   //    (avoids 10x overcount when point != tickSize, e.g. 0.001 vs 0.01)
   double valuePerPoint = (g_tickSize > 0.0) ? (g_tickValue * g_point / g_tickSize) : 0.0;

   double totalRisk = 0.0;
   int    total     = PositionsTotal();

   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!g_pos.SelectByTicket(ticket)) continue;

      //--- Only count this EA's positions on this symbol
      if(g_pos.Symbol() != Symbol())    continue;
      if(g_pos.Magic()  != MagicNumber) continue;

      double openPrice = g_pos.PriceOpen();
      double slPrice   = g_pos.StopLoss();

      double slDistPoints;
      if(slPrice <= 0.0)
         slDistPoints = (double)SL_Points;          // Worst-case proxy
      else
         slDistPoints = MathAbs(openPrice - slPrice) / g_point;

      totalRisk += slDistPoints * valuePerPoint * g_pos.Volume();
   }

   return totalRisk;
}

//+------------------------------------------------------------------+
//| Calculate lot size capped by available free margin               |
//| Returns 0.0 if result is below broker minimum (trade should skip)|
//+------------------------------------------------------------------+
double CalcCappedLot(ENUM_ORDER_TYPE orderType, double entryPrice)
{
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(freeMargin <= 0.0) return 0.0;

   double maxMargin = freeMargin * MarginCapPercent / 100.0;
   double lot       = DefaultLotSize;

   double marginRequired = 0.0;
   if(!OrderCalcMargin(orderType, Symbol(), lot, entryPrice, marginRequired))
   {
      Print("XAUUSD_HFT: OrderCalcMargin() failed for lot=", lot);
      return 0.0;
   }

   if(marginRequired > maxMargin && marginRequired > 0.0)
   {
      //--- Scale lot to fit within the margin cap, then round DOWN to lotStep
      lot = lot * (maxMargin / marginRequired);
      lot = MathFloor(lot / g_lotStep) * g_lotStep;
      lot = NormalizeDouble(lot, 2);
   }

   if(lot < g_minLot) return 0.0;

   return lot;
}

//+------------------------------------------------------------------+
//| Place a BUY market order with normalised TP and SL               |
//+------------------------------------------------------------------+
bool OpenBuy(double lot, double ask)
{
   double sl = NormalizeDouble(ask - SL_Points * g_point, _Digits);
   double tp = NormalizeDouble(ask + TP_Points * g_point, _Digits);

   bool result = g_trade.Buy(lot, Symbol(), ask, sl, tp, TradeComment);
   if(!result)
      Print("XAUUSD_HFT: Buy() failed — ", g_trade.ResultRetcodeDescription(),
            " (retcode=", g_trade.ResultRetcode(), ")");
   return result;
}

//+------------------------------------------------------------------+
//| Place a SELL market order with normalised TP and SL              |
//+------------------------------------------------------------------+
bool OpenSell(double lot, double bid)
{
   double sl = NormalizeDouble(bid + SL_Points * g_point, _Digits);
   double tp = NormalizeDouble(bid - TP_Points * g_point, _Digits);

   bool result = g_trade.Sell(lot, Symbol(), bid, sl, tp, TradeComment);
   if(!result)
      Print("XAUUSD_HFT: Sell() failed — ", g_trade.ResultRetcodeDescription(),
            " (retcode=", g_trade.ResultRetcode(), ")");
   return result;
}
//+------------------------------------------------------------------+
