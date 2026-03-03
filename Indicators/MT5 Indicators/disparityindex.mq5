//+------------------------------------------------------------------+
//|                                               DisparityIndex.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "Disparity Index shows the difference between the closing price and the selected moving "
#property description "average in percentages. Recommended for use in combination with candlestick "
#property description "models."
//---
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   3
//--- plot Disparity Index
#property indicator_label1  "Disparity Index"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrRed,clrBlue,clrTomato,clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Upper Level
#property indicator_label2  "Upper Level"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDimGray
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot Lower Level
#property indicator_label3  "Lower Level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDimGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//---
enum MA_METHOD {
   MODE_EMA_,  // Exponential
   MODE_LWMA_, // Linear Weighted
   MODE_SMA_,  // Simple
   MODE_SMMA_  // Smoothed
};
//--- input parameters
input MA_METHOD   InpMaMethod = MODE_SMA_;   // лю method
input int         InpMaPeriod = 10;          // лю period
input double      InpLevelsCoeff = 3.0;      // levels coefficients
//--- indicator buffers
double         DiBuffer[];
double         DiColors[];
double         UpperBuffer[];
double         LowerBuffer[];
double         AbsRocBuffer[];
double         AbsRocMaBuffer[];
double         MaBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0, DiBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, DiColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, UpperBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, LowerBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, AbsRocBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, AbsRocMaBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, MaBuffer, INDICATOR_CALCULATIONS);
//---
   for ( int i = 0; i < 3; i++ ) {
      PlotIndexSetInteger(i, PLOT_DRAW_BEGIN, InpMaPeriod-1);
   }
//---
   IndicatorSetInteger(INDICATOR_DIGITS, 4);
//---
   string shortname = "Disparity Index ("+(string)InpMaPeriod+", "+DoubleToString(InpLevelsCoeff, 2)+")";
   IndicatorSetString(INDICATOR_SHORTNAME, shortname); 
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
//---
   int startBar;
   int minRequiredBars = begin + InpMaPeriod - 1;
   static int maWeightSum, rocWeightSum;
//---
   if ( begin > 0 ) {
      PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, minRequiredBars);
      PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, minRequiredBars);
      PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, minRequiredBars);
   }
   if ( prev_calculated < minRequiredBars ) {
      ArrayInitialize(DiBuffer, 0.0);
      ArrayInitialize(DiColors, 0.0);
      ArrayInitialize(UpperBuffer, 0.0);
      ArrayInitialize(LowerBuffer, 0.0);
      ArrayInitialize(AbsRocBuffer, 0.0);
      startBar = minRequiredBars;
      maWeightSum = rocWeightSum = 0;
   } else {
      startBar = prev_calculated - 1;
   }
//---
   for ( int bar = startBar; bar < rates_total && !IsStopped(); bar++ ) {
      AbsRocBuffer[bar] = MathAbs(price[bar]-price[bar-1]) / price[bar] * 100;
   }
//---
   switch ( InpMaMethod ) {
      case MODE_EMA_:
         ExponentialMAOnBuffer(rates_total, prev_calculated, begin, InpMaPeriod, price, MaBuffer);
         ExponentialMAOnBuffer(rates_total, prev_calculated, begin, InpMaPeriod, AbsRocBuffer, AbsRocMaBuffer);
         break;
      case MODE_LWMA_:
         LinearWeightedMAOnBuffer(rates_total, prev_calculated, begin, InpMaPeriod, price, MaBuffer, maWeightSum);
         LinearWeightedMAOnBuffer(rates_total, prev_calculated, begin, InpMaPeriod, AbsRocBuffer, AbsRocMaBuffer, rocWeightSum);
         break;
      case MODE_SMMA_:
         SmoothedMAOnBuffer(rates_total, prev_calculated, begin, InpMaPeriod, price, MaBuffer);
         SmoothedMAOnBuffer(rates_total, prev_calculated, begin, InpMaPeriod, AbsRocBuffer, AbsRocMaBuffer);
         break;
      case MODE_SMA_:
      default:
         SimpleMAOnBuffer(rates_total, prev_calculated, begin, InpMaPeriod, price, MaBuffer);
         SimpleMAOnBuffer(rates_total, prev_calculated, begin, InpMaPeriod, AbsRocBuffer, AbsRocMaBuffer);
         break;        
   }
//---
   for ( int bar = startBar; bar < rates_total && !IsStopped(); bar++ ) {
      if ( MaBuffer[bar] != 0.0 ) {
         DiBuffer[bar] = 100 * (price[bar] - MaBuffer[bar]) / (MaBuffer[bar]);
         UpperBuffer[bar] = AbsRocMaBuffer[bar] * InpLevelsCoeff;
         LowerBuffer[bar] = -AbsRocMaBuffer[bar] * InpLevelsCoeff;
      }
      //---
      if ( DiBuffer[bar] >= 0.0 ) {
         if ( DiBuffer[bar] > UpperBuffer[bar] ) {
            DiColors[bar] = 1;
         } else {
            DiColors[bar] = 3;
         }
      } else {
         if ( DiBuffer[bar] < LowerBuffer[bar] ) {
            DiColors[bar] = 0;
         } else {
            DiColors[bar] = 2;
         }
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
