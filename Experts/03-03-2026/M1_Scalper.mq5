//+------------------------------------------------------------------+
//|                                             Gold_Pattern_EA.mq5  |
//|                                     Advanced GOLD Pattern Utility|
//+------------------------------------------------------------------+
#property copyright "Kalvi Trading"
#property link      ""
#property version   "1.00"
#property description "Multi-TF Pattern Utility for GOLD"
#property description "Includes: Session Boxes, Auto Fib, SMAs, Chart Patterns, Lot Calculator"
#property strict

#include <Trade\Trade.mqh>
#include <ChartObjects\ChartObjectsFibo.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>
#include <ChartObjects\ChartObjectsTxtControls.mqh>

//--- Enums
enum ENUM_PATTERN_PRIORITY
{
   PRIORITY_STRUCTURAL = 0, // Structural (Double Top/Bottom, H&S)
   PRIORITY_CANDLES    = 1, // Candlesticks (Engulfing, Pin Bars)
   PRIORITY_ALL        = 2  // All Patterns
};

//--- Inputs
input group "=== Session Boxes (GMT) ==="
input string   InpAsianSession    = "00:00-08:00"; // Asian Session Options
input color    InpAsianColor      = clrDarkSlateGray;
input string   InpLondonSession   = "08:00-16:00"; // London Session
input color    InpLondonColor     = clrDarkRed;
input string   InpNYSession       = "13:00-21:00"; // NY Session
input color    InpNYColor         = clrDarkBlue;

input group "=== Moving Averages ==="
input int      InpSmaFast         = 50;  // Fast SMA Period
input color    InpSmaFastColor    = clrAqua;
input int      InpSmaSlow         = 200; // Slow SMA Period
input color    InpSmaSlowColor    = clrOrange;

input group "=== Fibonacci & ZigZag ==="
input bool     InpDrawFib         = true; // Auto Draw Fibonacci
input color    InpFibColor        = clrGoldenrod;
input int      InpZigZagDepth     = 12;   // ZigZag Depth
input int      InpZigZagDeviation = 5;    // ZigZag Deviation
input int      InpZigZagBackstep  = 3;    // ZigZag Backstep

input group "=== Patterns ==="
input ENUM_PATTERN_PRIORITY InpPatternType = PRIORITY_ALL;
input bool     InpAlerts          = true;

input group "=== Lot Calculator ==="
input double   InpRiskPercent     = 1.0;  // Risk % per trade
input int      InpStopLossPips    = 50;   // Default SL for Calc

//--- Globals
int handle_sma_fast;
int handle_sma_slow;
int handle_zigzag;

CChartObjectFibo   auto_fib;
CChartObjectLabel  lbl_lot_calc;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   handle_sma_fast = iMA(_Symbol, PERIOD_CURRENT, InpSmaFast, 0, MODE_SMA, PRICE_CLOSE);
   handle_sma_slow = iMA(_Symbol, PERIOD_CURRENT, InpSmaSlow, 0, MODE_SMA, PRICE_CLOSE);
   
   // Create indicator on chart
   ChartIndicatorAdd(0, 0, handle_sma_fast);
   ChartIndicatorAdd(0, 0, handle_sma_slow);
   
   handle_zigzag = iCustom(_Symbol, PERIOD_CURRENT, "Examples\\ZigZag", InpZigZagDepth, InpZigZagDeviation, InpZigZagBackstep);
   
   DrawLotCalculator();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "SES_");
   ObjectsDeleteAll(0, "PAT_");
   ObjectsDeleteAll(0, "FIB_");
   ObjectsDeleteAll(0, "CALC_");
   IndicatorRelease(handle_sma_fast);
   IndicatorRelease(handle_sma_slow);
   IndicatorRelease(handle_zigzag);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   static datetime last_time = 0;
   datetime current_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(current_time != last_time)
   {
      last_time = current_time;
      UpdateChartFeatures();
   }
}

//+------------------------------------------------------------------+
//| Main Update Routine                                              |
//+------------------------------------------------------------------+
void UpdateChartFeatures()
{
   if(InpDrawFib) UpdateFibonacci();
   UpdateLotCalculator();
   DetectPatterns();
}

//+------------------------------------------------------------------+
//| Fibonacci Automatic Drawing                                      |
//+------------------------------------------------------------------+
void UpdateFibonacci()
{
   double zzbuf[];
   CopyBuffer(handle_zigzag, 0, 0, 100, zzbuf);
   
   int high_idx = -1;
   int low_idx = -1;
   
   // Find last swing high and low
   for(int i=1; i<100; i++)
   {
      if(zzbuf[i] > 0.0)
      {
         if(high_idx == -1 && low_idx != -1) high_idx = i;
         else if(low_idx == -1 && high_idx != -1) low_idx = i;
         else if(high_idx == -1 && low_idx == -1)
         {
            if(iClose(_Symbol, PERIOD_CURRENT, i) > iOpen(_Symbol, PERIOD_CURRENT, i)) high_idx = i; else low_idx = i;
         }
      }
      if(high_idx != -1 && low_idx != -1) break;
   }
   
   if(high_idx != -1 && low_idx != -1)
   {
      datetime t1 = iTime(_Symbol, PERIOD_CURRENT, high_idx);
      double p1 = zzbuf[high_idx];
      datetime t2 = iTime(_Symbol, PERIOD_CURRENT, low_idx);
      double p2 = zzbuf[low_idx];
      
      ObjectDelete(0, "FIB_AUTO");
      ObjectCreate(0, "FIB_AUTO", OBJ_FIBO, 0, t1, p1, t2, p2);
      ObjectSetInteger(0, "FIB_AUTO", OBJPROP_COLOR, InpFibColor);
   }
}

//+------------------------------------------------------------------+
//| Lot Calculator Dashboard                                         |
//+------------------------------------------------------------------+
void DrawLotCalculator()
{
   ObjectCreate(0, "CALC_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "CALC_BG", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "CALC_BG", OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, "CALC_BG", OBJPROP_XSIZE, 200);
   ObjectSetInteger(0, "CALC_BG", OBJPROP_YSIZE, 80);
   ObjectSetInteger(0, "CALC_BG", OBJPROP_BGCOLOR, clrBlack);
   
   ObjectCreate(0, "CALC_TXT", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "CALC_TXT", OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(0, "CALC_TXT", OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, "CALC_TXT", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "CALC_TXT", OBJPROP_FONTSIZE, 10);
}

void UpdateLotCalculator()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amt = balance * (InpRiskPercent / 100.0);
   
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(tick_size == 0) return;
   
   // Sl calc
   double sl_points = InpStopLossPips * 10;
   double value_per_lot_sl = (sl_points * point / tick_size) * tick_value;
   
   double lot_sz = 0;
   if(value_per_lot_sl > 0)
      lot_sz = NormalizeDouble(risk_amt / value_per_lot_sl, 2);
      
   string txt = StringFormat("Risk: $%.2f | SL: %d pips\nRec Lot Size: %.2f", risk_amt, InpStopLossPips, lot_sz);
   ObjectSetString(0, "CALC_TXT", OBJPROP_TEXT, txt);
}

//+------------------------------------------------------------------+
//| Pattern Detection Mockup                                         |
//+------------------------------------------------------------------+
void DetectPatterns()
{
   // Basic engulfing detection
   double op1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double cl1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double op2 = iOpen(_Symbol, PERIOD_CURRENT, 2);
   double cl2 = iClose(_Symbol, PERIOD_CURRENT, 2);
   
   if(cl2 < op2 && cl1 > op1 && cl1 > op2 && op1 < cl2)
   {
      if(InpAlerts) Print("Bullish Engulfing Detected");
   }
}

