//+------------------------------------------------------------------+
//|                                            BreakoutBarsTrend.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "Indicator to determine the trend, based on the breakdown of bars and the distance from the extremums."
//--- indicator settings 
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   2
//--- plot Series
#property indicator_label1  "Series Values"
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrNONE
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Breakout
#property indicator_label2  "Breakout Open;Breakout High;Breakout Low;Breakout Close"
#property indicator_type2   DRAW_COLOR_CANDLES
#property indicator_color2  clrBlue,clrRoyalBlue,clrDeepSkyBlue,clrRed,clrTomato,clrOrange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      InpDelta = 1000;           // Delta
input bool     InpShowLastValues = true;  // Show the size of the series
input int      InpSeriesQuantity = 5;     // Number of series
//--- indicator buffers
double         SeriesBuffer[];
double         OpenBreakoutBuffer[];
double         HighBreakoutBuffer[];
double         LowBreakoutBuffer[];
double         CloseBreakoutBuffer[];
double         BreakoutColors[];
//---
int            minRequiredBars;
double         delta, maxPrice, minPrice;
int            seriesData[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   minRequiredBars = 2;
   delta = InpDelta * _Point;
//--- indicator buffers mapping
   SetIndexBuffer(0, SeriesBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, OpenBreakoutBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, HighBreakoutBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, LowBreakoutBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, CloseBreakoutBuffer, INDICATOR_DATA);
   SetIndexBuffer(5, BreakoutColors, INDICATOR_COLOR_INDEX);
//---
   for ( int i = 0; i < 2; i++ ) {
      PlotIndexSetInteger(i, PLOT_DRAW_BEGIN, minRequiredBars);
      PlotIndexSetInteger(i, PLOT_SHIFT, 0);
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0);
   }
//---
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//---
   IndicatorSetString(INDICATOR_SHORTNAME, "BreakoutBarsTrend ("+(string)InpDelta+")");     
//---
   if ( InpShowLastValues ) {
      ArrayResize(seriesData, InpSeriesQuantity);
      ArrayInitialize(seriesData, 0);
   }
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   Comment("");
//---
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
   int startBar;
//---
   if ( rates_total < minRequiredBars ) {
      Print("Not enough data for the calculation");
      return(0);
   }  
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      startBar = minRequiredBars;
      for ( int bar = 0; bar < minRequiredBars; bar++ ) {
         SeriesBuffer[bar] = 0.0;
         OpenBreakoutBuffer[bar] = 0.0;
         HighBreakoutBuffer[bar] = 0.0;
         LowBreakoutBuffer[bar] = 0.0;
         CloseBreakoutBuffer[bar] = 0.0;
      }
   } else {
      startBar = prev_calculated - 1;
   }
//---
   for ( int bar = startBar; bar < rates_total && !IsStopped(); bar++ ) {
      int prevBar = bar - 1;
      double seriesValue;
      //---
      if ( prev_calculated != rates_total ) {
         if ( SeriesBuffer[prevBar] * SeriesBuffer[prevBar-1] < 0 ) {
            maxPrice = high[prevBar];
            minPrice = low[prevBar];
            if ( InpShowLastValues ) {
               arrayShift(seriesData, (int)SeriesBuffer[prevBar-1]);
            }
         } else {
            maxPrice = MathMax(maxPrice, high[prevBar]);
            minPrice = MathMin(minPrice, low[prevBar]);
         }
      }
      //---
      seriesValue = SeriesBuffer[bar] = SeriesBuffer[prevBar];
      OpenBreakoutBuffer[bar] = open[bar];
      HighBreakoutBuffer[bar] = high[bar];
      LowBreakoutBuffer[bar] = low[bar];
      CloseBreakoutBuffer[bar] = close[bar];
      //---
      if ( seriesValue > 0.0 ) {
         if ( close[bar] > maxPrice ) {
            BreakoutColors[bar] = 0;
            SeriesBuffer[bar] = SeriesBuffer[prevBar] + 1;
         } else if ( close[bar] < MathMax(maxPrice, high[bar]) - delta && close[bar] < low[prevBar] ) {
            SeriesBuffer[bar] = -1;
            BreakoutColors[bar] = 3;
            maxPrice = high[bar];
         } else {
            if ( close[bar] >= open[bar] ) {
               BreakoutColors[bar] = 1;
            } else {
               BreakoutColors[bar] = 2;
            }
         }
      } else if ( seriesValue < 0.0 ) {
         if ( close[bar] < minPrice ) {
            BreakoutColors[bar] = 3;
            SeriesBuffer[bar] = SeriesBuffer[prevBar] - 1;
         } else if ( close[bar] > MathMin(minPrice, low[bar]) + delta && close[bar] > high[prevBar] ) {
            SeriesBuffer[bar] = 1;
            BreakoutColors[bar] = 0;
            minPrice = low[bar];
         } else {
            if ( close[bar] >= open[bar] ) {
               BreakoutColors[bar] = 5;
            } else {
               BreakoutColors[bar] = 4;
            }
         }
      } else if ( seriesValue == 0.0 ) {
         if ( close[bar] >= close[prevBar] ) {
            SeriesBuffer[bar] = 1;
         } else {
            SeriesBuffer[bar] = -1;
         }
         maxPrice = high[bar];
         minPrice = low[bar];
      }
   }
//---
   if ( InpShowLastValues ) {
      string comm = "Series Values: ";
      
      seriesData[InpSeriesQuantity-1] = (int)SeriesBuffer[rates_total-1];
      for ( int i = 0; i < InpSeriesQuantity; i++ ) {
         comm += (string)seriesData[i] + " ";
      }
      Comment(comm);
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Array Shift function                                             |
//+------------------------------------------------------------------+
void arrayShift(int &array[], int newValue) {
   int last = InpSeriesQuantity - 2;
   
   for ( int i = 0; i < last; i++ ) {
      array[i] = array[i+1];
   }
   array[last] = newValue;
}
//+------------------------------------------------------------------+
