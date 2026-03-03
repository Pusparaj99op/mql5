//+------------------------------------------------------------------+
//|                                            XAUUSD_HFT_EA.mq5    |
//|                         M1 Breakout Scalper for Gold (XAUUSD)   |
//+------------------------------------------------------------------+
//|                                            XAUUSD_HFT_EA.mq5    |
//|                      M1 Mathematical Scalper for Gold (XAUUSD)  |
//+------------------------------------------------------------------+
#property copyright "MIT License"
#property version   "2.00"
#property description "M1 mathematical scalper with fixed 0.01 lot, money SL/TP, trailing and daily DD guard."
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

input group             "=== Core ==="
input double FixedLotSize               = 0.01;
input int    MaxSpreadPoints            = 80;
input int    SlippagePoints             = 20;
input int    PendingOffsetPoints        = 25;
input int    PendingExpiryMinutes       = 0;

input group             "=== Mathematical Trigger (M1) ==="
input int    VelocityBars               = 3;
input double MinVelocityPoints          = 30.0;
input double MinAvgBodyRatio            = 0.55;

input group             "=== Money Targets Per Trade ==="
input double TargetProfitUSD            = 0.60;
input double TargetLossUSD              = 1.00;

input group             "=== Trailing (Money Based) ==="
input bool   EnableTrailing             = true;
input double TrailingStartUSD           = 0.35;
input double TrailingDistanceUSD        = 0.25;
input double TrailingStepUSD            = 0.05;

input group             "=== Daily Protection ==="
input double MaxDailyDrawdownPercent    = 5.0;

input group             "=== Margin and Identity ==="
input double MarginSafetyMultiplier     = 1.20;
input int    MagicNumber                = 20260302;
input string TradeComment               = "XAUUSD_MATH_HFT";

CTrade        g_trade;
CPositionInfo g_pos;

bool     g_dailyDdLocked       = false;

double g_point                 = 0.0;
double g_tickSize              = 0.0;
double g_tickValue             = 0.0;
double g_minLot                = 0.0;
double g_lotStep               = 0.0;

datetime g_dayStartTime        = 0;
double   g_dayStartEquity      = 0.0;

int OnInit()
{
   if(Period() != PERIOD_M1)
   {
      Alert("XAUUSD_MATH_HFT: Attach EA to M1 timeframe only.");
      return INIT_PARAMETERS_INCORRECT;
   }

   if(StringFind(Symbol(), "XAUUSD") < 0)
      Print("XAUUSD_MATH_HFT: WARNING symbol is ", Symbol(), ", expected XAUUSD variant.");

   if(FixedLotSize <= 0.0 || TargetProfitUSD <= 0.0 || TargetLossUSD <= 0.0)
      return INIT_PARAMETERS_INCORRECT;
   if(MaxSpreadPoints <= 0 || PendingOffsetPoints <= 0 || VelocityBars < 2 || MinVelocityPoints <= 0.0 || MinAvgBodyRatio <= 0.0)
      return INIT_PARAMETERS_INCORRECT;
   if(MaxDailyDrawdownPercent <= 0.0 || MarginSafetyMultiplier < 1.0)
      return INIT_PARAMETERS_INCORRECT;

   g_point     = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   g_tickSize  = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   g_tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   g_minLot    = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   g_lotStep   = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

   if(g_point <= 0.0 || g_tickSize <= 0.0 || g_tickValue <= 0.0)
   {
      Alert("XAUUSD_MATH_HFT: Invalid symbol tick/point settings.");
      return INIT_PARAMETERS_INCORRECT;
   }

   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(SlippagePoints);

   int fillMode = (int)SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE);
   if((fillMode & ORDER_FILLING_FOK) != 0)
      g_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((fillMode & ORDER_FILLING_IOC) != 0)
      g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      g_trade.SetTypeFilling(ORDER_FILLING_RETURN);

   ResetDailyBaseline();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   Comment("");
}

void OnTick()
{
   if(!IsSymbolReady())
      return;

   HandleDailyReset();
   UpdateDailyDdLock();
   ManageTrailingStops();
   ShowTotalProfitLoss();

   if(g_dailyDdLocked)
      return;

   int spread = (int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   if(spread <= 0 || spread > MaxSpreadPoints)
      return;

   bool longSignal = false;
   bool shortSignal = false;
   if(!GetMathSignal(longSignal, shortSignal))
      return;

   if(!longSignal && !shortSignal)
      return;

   double lot = NormalizeVolume(FixedLotSize);
   if(lot < g_minLot)
      return;

   if(!HasMarginForTrade(lot, longSignal ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_SELL_STOP))
      return;

   if(longSignal)
   {
      PlacePendingOrder(ORDER_TYPE_BUY_STOP, lot);
   }
   else if(shortSignal)
   {
      PlacePendingOrder(ORDER_TYPE_SELL_STOP, lot);
   }
}

bool IsSymbolReady()
{
   if((int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL)
      return false;

   if(SymbolInfoDouble(Symbol(), SYMBOL_ASK) <= 0.0 || SymbolInfoDouble(Symbol(), SYMBOL_BID) <= 0.0)
      return false;

   if(iBars(Symbol(), PERIOD_M1) < VelocityBars + 5)
      return false;

   return true;
}

double ValuePerPointPerLot()
{
   return g_tickValue * g_point / g_tickSize;
}

double MoneyToPoints(double moneyAmount, double lot)
{
   double valuePerPoint = ValuePerPointPerLot() * lot;
   if(valuePerPoint <= 0.0)
      return 0.0;
   return moneyAmount / valuePerPoint;
}

double NormalizeVolume(double lot)
{
   if(g_lotStep <= 0.0)
      return lot;
   double stepped = MathFloor(lot / g_lotStep) * g_lotStep;
   return NormalizeDouble(stepped, 2);
}

bool GetMathSignal(bool &longSignal, bool &shortSignal)
{
   longSignal = false;
   shortSignal = false;

   double velocityPrice = 0.0;
   double ratioSum = 0.0;

   for(int i = 1; i <= VelocityBars; i++)
   {
      double cNow = iClose(Symbol(), PERIOD_M1, i);
      double cPrev = iClose(Symbol(), PERIOD_M1, i + 1);
      double h = iHigh(Symbol(), PERIOD_M1, i);
      double l = iLow(Symbol(), PERIOD_M1, i);
      double o = iOpen(Symbol(), PERIOD_M1, i);

      double range = h - l;
      if(range <= 0.0)
         return false;

      velocityPrice += (cNow - cPrev);
      ratioSum += MathAbs(cNow - o) / range;
   }

   double velocityPoints = velocityPrice / g_point;
   double avgBodyRatio = ratioSum / VelocityBars;

   double close1 = iClose(Symbol(), PERIOD_M1, 1);
   double open1 = iOpen(Symbol(), PERIOD_M1, 1);

   longSignal = (velocityPoints >= MinVelocityPoints && avgBodyRatio >= MinAvgBodyRatio && close1 > open1);
   shortSignal = (velocityPoints <= -MinVelocityPoints && avgBodyRatio >= MinAvgBodyRatio && close1 < open1);

   if(longSignal && shortSignal)
      shortSignal = false;

   return true;
}

bool HasMarginForTrade(double lot, ENUM_ORDER_TYPE orderType)
{
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double minStopPoints = (double)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
   double offsetPoints = MathMax((double)PendingOffsetPoints, minStopPoints);
   double price = (orderType == ORDER_TYPE_BUY_STOP) ? (ask + offsetPoints * g_point) : (bid - offsetPoints * g_point);

   double required = 0.0;
   if(!OrderCalcMargin(orderType, Symbol(), lot, price, required))
      return false;

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(freeMargin <= 0.0)
      return false;

   return freeMargin >= (required * MarginSafetyMultiplier);
}

bool BuildStops(ENUM_ORDER_TYPE type, double entry, double lot, double &sl, double &tp)
{
   double slPoints = MoneyToPoints(TargetLossUSD, lot);
   double tpPoints = MoneyToPoints(TargetProfitUSD, lot);
   if(slPoints <= 0.0 || tpPoints <= 0.0)
      return false;

   double minStopPoints = (double)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
   if(slPoints < minStopPoints)
      slPoints = minStopPoints;
   if(tpPoints < minStopPoints)
      tpPoints = minStopPoints;

   if(type == ORDER_TYPE_BUY || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_BUY_LIMIT)
   {
      sl = NormalizeDouble(entry - slPoints * g_point, _Digits);
      tp = NormalizeDouble(entry + tpPoints * g_point, _Digits);
   }
   else
   {
      sl = NormalizeDouble(entry + slPoints * g_point, _Digits);
      tp = NormalizeDouble(entry - tpPoints * g_point, _Digits);
   }

   return true;
}

bool PlacePendingOrder(ENUM_ORDER_TYPE type, double lot)
{
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double minStopPoints = (double)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
   double offsetPoints = MathMax((double)PendingOffsetPoints, minStopPoints);
   double entry = (type == ORDER_TYPE_BUY_STOP) ? (ask + offsetPoints * g_point) : (bid - offsetPoints * g_point);
   entry = NormalizeDouble(entry, _Digits);

   double sl = 0.0;
   double tp = 0.0;
   if(!BuildStops(type, entry, lot, sl, tp))
      return false;

   datetime expiration = 0;
   ENUM_ORDER_TYPE_TIME timeType = ORDER_TIME_GTC;
   if(PendingExpiryMinutes > 0)
   {
      timeType = ORDER_TIME_SPECIFIED;
      expiration = TimeTradeServer() + (PendingExpiryMinutes * 60);
   }

   bool ok = false;
   if(type == ORDER_TYPE_BUY_STOP)
      ok = g_trade.BuyStop(lot, entry, Symbol(), sl, tp, timeType, expiration, TradeComment);
   else
      ok = g_trade.SellStop(lot, entry, Symbol(), sl, tp, timeType, expiration, TradeComment);

   if(!ok)
      Print("XAUUSD_MATH_HFT pending order failed: ", g_trade.ResultRetcodeDescription(), " (", g_trade.ResultRetcode(), ")");

   return ok;
}

void ManageTrailingStops()
{
   if(!EnableTrailing)
      return;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !g_pos.SelectByTicket(ticket))
         continue;
      if(g_pos.Symbol() != Symbol() || g_pos.Magic() != MagicNumber)
         continue;

      double volume = g_pos.Volume();
      if(volume <= 0.0)
         continue;

      double startPoints = MoneyToPoints(TrailingStartUSD, volume);
      double distPoints = MoneyToPoints(TrailingDistanceUSD, volume);
      double stepPoints = MoneyToPoints(TrailingStepUSD, volume);
      if(startPoints <= 0.0 || distPoints <= 0.0 || stepPoints <= 0.0)
         continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)g_pos.PositionType();
      double openPrice = g_pos.PriceOpen();
      double currentSl = g_pos.StopLoss();
      double currentTp = g_pos.TakeProfit();

      if(posType == POSITION_TYPE_BUY)
      {
         double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         double profitPoints = (bid - openPrice) / g_point;
         if(profitPoints < startPoints)
            continue;

         double targetSl = NormalizeDouble(bid - distPoints * g_point, _Digits);
         bool improve = (currentSl <= 0.0) || ((targetSl - currentSl) >= stepPoints * g_point);
         if(improve)
            g_trade.PositionModify(ticket, targetSl, currentTp);
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         double profitPoints = (openPrice - ask) / g_point;
         if(profitPoints < startPoints)
            continue;

         double targetSl = NormalizeDouble(ask + distPoints * g_point, _Digits);
         bool improve = (currentSl <= 0.0) || ((currentSl - targetSl) >= stepPoints * g_point);
         if(improve)
            g_trade.PositionModify(ticket, targetSl, currentTp);
      }
   }
}

void ResetDailyBaseline()
{
   datetime now = TimeTradeServer();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   g_dayStartTime = StructToTime(dt);
   g_dayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_dailyDdLocked = false;
}

void HandleDailyReset()
{
   datetime now = TimeTradeServer();
   if(now < g_dayStartTime || now >= (g_dayStartTime + 86400))
      ResetDailyBaseline();
}

void UpdateDailyDdLock()
{
   if(g_dailyDdLocked || g_dayStartEquity <= 0.0)
      return;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dd = (g_dayStartEquity - equity) * 100.0 / g_dayStartEquity;
   if(dd >= MaxDailyDrawdownPercent)
   {
      g_dailyDdLocked = true;
      Print("XAUUSD_MATH_HFT: Daily DD lock activated. New entries disabled.");
   }
}

double GetOpenProfit()
{
   double total = 0.0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !g_pos.SelectByTicket(ticket))
         continue;
      if(g_pos.Symbol() != Symbol() || g_pos.Magic() != MagicNumber)
         continue;
      total += g_pos.Profit();
   }
   return total;
}

double GetTodayClosedProfit()
{
   datetime from = g_dayStartTime;
   datetime to = TimeTradeServer();
   if(!HistorySelect(from, to))
      return 0.0;

   double total = 0.0;
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0)
         continue;

      if((string)HistoryDealGetString(dealTicket, DEAL_SYMBOL) != Symbol())
         continue;
      if((long)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != MagicNumber)
         continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY) != DEAL_ENTRY_OUT)
         continue;

      total += HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
      total += HistoryDealGetDouble(dealTicket, DEAL_SWAP);
      total += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
   }

   return total;
}

void ShowTotalProfitLoss()
{
   double totalPl = GetOpenProfit() + GetTodayClosedProfit();
   Comment("Total Profit/Loss: ", DoubleToString(totalPl, 2));
}
//+------------------------------------------------------------------+
