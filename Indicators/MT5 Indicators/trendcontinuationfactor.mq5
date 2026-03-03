//+------------------------------------------------------------------+
//|                                      TrendContinuationFactor.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "The indicator is created by the by the formulas and a description in http://www.linnsoft.com/tour/techind/tcf.htm"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot Tcf
#property indicator_label1  "TCF"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrDodgerBlue,clrTomato
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//---
#property indicator_level1 0
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DOT
//--- input parameters
input int      InpTcfPeriod = 20;   // TCF period
//--- indicator buffers
double         TcfBuffer1[];
double         TcfBuffer2[];
//--- global variables
int            minRequiredBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   minRequiredBars = InpTcfPeriod;
//--- indicator buffers mapping
   SetIndexBuffer(0,TcfBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,TcfBuffer2,INDICATOR_DATA);
//---
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, minRequiredBars);
//---
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//---
   IndicatorSetString(INDICATOR_SHORTNAME, "TCF ("+(string)InpTcfPeriod+")");
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
//---
   if ( rates_total < minRequiredBars ) {
      Print("Not enough data to calculate");
      return(0);
   }
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      startBar = minRequiredBars;
   } else {
      startBar = prev_calculated - 1;
   }
//---
   for ( int bar = startBar; bar < rates_total && !IsStopped(); bar++ ) {
      double changePlus, changeMinus, cfPlus, cfMinus;
      double prevCfPlus = 0.0, prevCfMinus = 0.0;
      double changePlusSum = 0.0, changeMinusSum = 0.0, cfPlusSum = 0.0, cfMinusSum = 0.0;
      //---
      for ( int i = bar - InpTcfPeriod + 1; i <= bar; i++ ) {
         double curPrice = price[i];
         double prevPrice = price[i-1];
         //---
         changePlus = changeMinus = cfPlus = cfMinus = 0.0;
         if ( curPrice > prevPrice ) {
            changePlus = curPrice - prevPrice;
            changePlusSum += changePlus;
            cfPlus = changePlus + prevCfPlus;
            cfPlusSum += cfPlus;
         } else {
            changeMinus = prevPrice - curPrice;
            changeMinusSum += changeMinus;
            cfMinus = changeMinus + prevCfMinus;
            cfMinusSum += cfMinus;
         }
         //---
         prevCfPlus = cfPlus;
         prevCfMinus = cfMinus;
         //---
      }
      TcfBuffer1[bar] = changePlusSum - cfMinusSum;
      TcfBuffer2[bar] = changeMinusSum - cfPlusSum;
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+