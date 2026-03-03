//+------------------------------------------------------------------+
//|                                                  DeltaZigZag.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "Delta ZigZag determines a reversal by the minimal height of swing, and also identifies "
#property description "a trend by breakthrough of the local minimum/maximum levels and colors "
#property description "the zigzag sections to the current trend color."
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   3
//--- plot ZigZag
#property indicator_label1  "ZigZag Bottom;ZigZag Top"
#property indicator_type1   DRAW_COLOR_ZIGZAG
#property indicator_color1  clrRed,clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Reverse to Down-trend level
#property indicator_label2  "Reverse to Down"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot Reverse to Up-trend level
#property indicator_label3  "Reverse to Up"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrTomato
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//---
enum APPLIED_PRICE {
   CLOSE_CLOSE,   // close
   HIGH_LOW       // high/low
};
//---
enum REVERSAL_MODE {
   PIPS,          // In pips
   PERCENT        // In percentage
};
//---
struct zzData {
   int highBar;
   int lowBar;
   double highValue;
   double lowValue;
   bool up;
};
//--- input parameters
input APPLIED_PRICE  InpAppliedPrice = HIGH_LOW;   // Apply to price
input REVERSAL_MODE  InpReversalMode = PIPS;       // Reversal mode
input int            InpPips = 500;                // Reversal in pips
input double         InpPercent = 0.5;             // Reversal in %
input int            InpLevels = 1;                // Levels number
//--- indicator buffers
double         ZzBtmBuffer[];
double         ZzTopBuffer[];
double         ZigZagColors[];
double         ReverseToDownBuffer[];
double         ReverseToUpBuffer[];
//--- global variables
zzData         last;
double         minLevels[];
double         maxLevels[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0, ZzBtmBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ZzTopBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ZigZagColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3, ReverseToUpBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, ReverseToDownBuffer, INDICATOR_DATA);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(1, PLOT_ARROW, 159);
   PlotIndexSetInteger(2, PLOT_ARROW, 159);   
//---
   for ( int i = 0; i < 3; i++ ) {
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0);
      PlotIndexSetInteger(i, PLOT_SHIFT, 0);
   }
//---
   ArrayResize(minLevels, InpLevels);
   ArrayResize(maxLevels, InpLevels);
//---
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//---
   string modeData = (InpReversalMode == PIPS) ? (string)InpPips+" pips" : DoubleToString(InpPercent, 2)+"%";
   IndicatorSetString(INDICATOR_SHORTNAME, "Delta ZigZag ("+modeData+", "+(string)InpLevels+")");  
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Get Reversal Value function                                      |
//+------------------------------------------------------------------+
double getReversal(double price) {
//---
   if ( InpReversalMode == PIPS ) {
      return(InpPips*_Point);
   }
   return(NormalizeDouble((price/100)*InpPercent, _Digits));
//---
}
//+------------------------------------------------------------------+
//| Add price to array function                                      |
//+------------------------------------------------------------------+
void addLevelToArray(double &array[], double price) {
//---
   for ( int i = InpLevels-1; i >= 1; i-- ) {
      array[i] = array[i-1];
   }
   array[0] = price;
//---
}
//+------------------------------------------------------------------+
//| Get array max value function                                     |
//+------------------------------------------------------------------+
double arrayMaxValue(const double &array[]) {
//---
   double max = array[0];
   
   for ( int i = InpLevels - 1; i > 0; i-- ) {
      if ( array[i] > max ) {
         max = array[i];
      }
   }
//---
   return(max);
}
//+------------------------------------------------------------------+
//| Get array min value function                                     |
//+------------------------------------------------------------------+
double arrayMinValue(const double &array[]) {
//---
   double min = array[0];
   
   for ( int i = InpLevels - 1; i > 0; i-- ) {
      if ( array[i] < min ) {
         min = array[i];
      }
   }
//---
   return(min);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---
   int startBar, lastBar;
   bool upTrend;
   double reversal;
   zzData current;
   
   static bool _upTrend;
//---
   lastBar = rates_total - 1;
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      ArrayInitialize(ZzBtmBuffer, 0.0);
      ArrayInitialize(ZzTopBuffer, 0.0);
      ArrayInitialize(ZigZagColors, 0.0);
      ArrayInitialize(ReverseToUpBuffer, 0.0);
      ArrayInitialize(ReverseToDownBuffer, 0.0);
      reversal = getReversal(close[0]);
      for ( startBar = 1; MathAbs(close[startBar]-close[0]) - reversal <= 0.00001; startBar++ );
      if ( close[startBar] > close[0] ) {
         last.up = _upTrend = true;
         last.highBar = startBar;
         last.lowBar = 0;
         last.highValue = ZzTopBuffer[startBar] = close[startBar];
         last.lowValue = ZzBtmBuffer[0] = close[0];
      } else {
         last.up = _upTrend = false;
         last.highBar = 0;
         last.highValue = ZzTopBuffer[0] = close[0];
         last.lowBar = startBar;
         last.lowValue = ZzBtmBuffer[startBar] = close[startBar];
      }
      ArrayInitialize(minLevels, last.lowValue);
      ArrayInitialize(maxLevels, last.highValue);
   } else {
      startBar = prev_calculated - 1;
      ZzBtmBuffer[lastBar] = 0.0;
      ZzTopBuffer[lastBar] = 0.0;
      ZzBtmBuffer[last.lowBar] = last.lowValue;
      ZzTopBuffer[last.highBar] = last.highValue;      
   }
//---
   current = last;
   upTrend = _upTrend;
//---
   for ( int bar = startBar; bar < rates_total && !IsStopped(); bar++ ) {
      //---
      double curLow, curHigh;
      
      if ( InpAppliedPrice == HIGH_LOW ) {
         curLow = low[bar];
         curHigh = high[bar];
      } else {
         curLow = curHigh = close[bar];
      }
      //---
      if ( rates_total != prev_calculated && bar == lastBar ) {
         last = current;
         _upTrend = upTrend;
         if ( current.up && ZzTopBuffer[bar-1] != 0.0  && minLevels[0] != current.lowValue ) {
            addLevelToArray(minLevels, current.lowValue);
         }
         if ( !current.up && ZzBtmBuffer[bar-1] != 0.0 && maxLevels[0] != current.highValue ) {
            addLevelToArray(maxLevels, current.highValue);
         }
      }
      //---
      if ( current.up ) {
         reversal = getReversal(current.highValue);
         if ( curHigh > current.highValue ) {
            ZzTopBuffer[current.highBar] = 0.0;
            ZzTopBuffer[bar] = curHigh;
            ZzBtmBuffer[bar] = 0.0;
            current.highBar = bar;
            current.highValue = curHigh; 
         } else {
            if ( curLow < current.highValue - reversal ) {
               ZzBtmBuffer[bar] = curLow;
               current.lowBar = bar;
               current.lowValue = curLow;
               ZzTopBuffer[bar] = 0.0;
               current.up = false;
               if ( bar != lastBar && maxLevels[0] != current.highValue ) {
                  addLevelToArray(maxLevels, current.highValue);
               }
            } else {
               ZzBtmBuffer[bar] = 0.0;
               ZzTopBuffer[bar] = 0.0;
            }
         }
      } else {
         reversal = getReversal(current.lowValue);
         if ( curLow < current.lowValue ) {
            ZzBtmBuffer[current.lowBar] = 0.0;
            ZzBtmBuffer[bar] = curLow;
            ZzTopBuffer[bar] = 0.0;
            current.lowBar = bar;
            current.lowValue = curLow;
         } else {
            if ( curHigh > current.lowValue + reversal ) {
               ZzTopBuffer[bar] = curHigh;
               current.highBar = bar;
               current.highValue = curHigh;
               ZzBtmBuffer[bar] = 0.0;
               current.up = true;
               if ( bar != lastBar && minLevels[0] != current.lowValue ) {
                  addLevelToArray(minLevels, current.lowValue);
               }
            } else {
               ZzBtmBuffer[bar] = 0.0;
               ZzTopBuffer[bar] = 0.0;
            }
         }
      }
      //---
      if ( !upTrend && current.highValue > arrayMaxValue(maxLevels) ) {
         upTrend = true;
      } else if ( upTrend && current.lowValue < arrayMinValue(minLevels) ) {
         upTrend = false;
      }
      //---
      if ( upTrend ) {
         ReverseToDownBuffer[bar] = arrayMinValue(minLevels);
         ReverseToUpBuffer[bar] = 0.0;  
         ZigZagColors[bar] = 1; 
      } else {
         ReverseToDownBuffer[bar] = 0.0;
         ReverseToUpBuffer[bar] = arrayMaxValue(maxLevels);
         ZigZagColors[bar] = 0;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
