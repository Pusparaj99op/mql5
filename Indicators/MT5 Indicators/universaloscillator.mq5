//+------------------------------------------------------------------+
//|                                          UniversalOscillator.mq5 |
//|                                            Copyright 2013, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "1) Includes Bears Power, Bulls Power, CCI, DeMarker, MACD, Momentum, RSI, Stochastic, WPR."
#property description "2) Has three draw mode: a) Line, b) Filling, c) Color Histogram."
#property description "3) Has three levels mode: a) constant levels, b) dynamic levels based on MA, c) dynamic levels "
#property description "based on Bollinger Bands."
//---
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   4
//--- plot Value
#property indicator_label1  "Value1;Value2"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrBlue,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Middle
#property indicator_label2  "Middle"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkGray
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot OverBought
#property indicator_label3  "OverBought"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDarkGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot OverSold
#property indicator_label4  "OverSold"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDarkGray
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//---
enum OSCILLATOR_NAME {
   BEARS,            // Bears Power
   BULLS,            // Bulls Power
   CCI,              // CCI
   DEMARKER,         // DeMarker
   MACD,             // MACD
   MOMENTUM,         // Momentum
   RSI,              // RSI
   STOCHASTIC,       // Stochastic
   WPR               // Williams Percent Range
};
//---
enum LEVEL_MODE {
   CONST_VALUE_MODE, // Constant level value mode
   MA_MODE,          // Moving Average mode
   BB_MODE           // Bollinger Bands Mode
};
//---
enum DRAW_MODE {
   LINE,             // Line
   FILLING,          // Filling
   HISTOGRAM         // Histogram
};
//--- input parameters
input OSCILLATOR_NAME      InpOscillator = RSI;                         // Oscillator
input int                  InpOscPeriod1 = 14;                          // Period
input ENUM_APPLIED_PRICE   InpAppliedPrice = PRICE_CLOSE;               // Applied price
input DRAW_MODE            InpDrawMode = FILLING;                       // Draw Mode
input LEVEL_MODE           InpLevelsMode = BB_MODE;                     // Levels Mode
input int                  InpLevelsPeriod = 50;                        // Levels Period
input double               InpLevelsIndent = 2.0;                       // Levels Indent / Deviation
input bool                 InpIndentAutoCorrection = true;              // Levels Auto Correction
input string               InpDivider = "---For Stochastic or MACD---"; // Just Divider NOT Parameter
input int                  InpOscPeriod2 = 3;                           // Stoch %D / MACD Slow EMA
input int                  InpOscPeriod3 = 3;                           // Stoch Slowing / MACD Signal 
input ENUM_STO_PRICE       InpStochPrice = STO_LOWHIGH;                 // Stochastic Price

//--- indicator buffers
double         ExtBuffer1[];
double         ExtBuffer2[];
double         ExtBuffer3[];
double         ExtBuffer4[];
double         ExtBuffer5[];
double         ExtBuffer6[];
//--- global variables
int            oscPeriod1;
int            levelsPeriod;
int            minRequiredBars;
int            oscHandle;
int            oscPeriod2;
int            oscPeriod3;
double         midValue;
double         addValue;
double         levelsIndent;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   if ( InpOscPeriod1 < 1 ) {
      oscPeriod1 = 14;
      printf("Incorrected input parameter InpOscPeriod1 = %d. Indicator will use value %d.", InpOscPeriod1, oscPeriod1);
   } else {
      oscPeriod1 = InpOscPeriod1;
   }
   
   if ( InpLevelsPeriod < 1 ) {
      levelsPeriod = 10;
      printf("Incorrected input parameter InpLevelsPeriod = %d. Indicator will use value %d.", InpLevelsPeriod, levelsPeriod);
   } else {
      levelsPeriod = InpLevelsPeriod;
   }
   
   if ( InpOscPeriod2 < 1 ) {
      oscPeriod2 = 3;
      printf("Incorrected input parameter InpOscPeriod2 = %d. Indicator will use value %d.", InpOscPeriod2, oscPeriod2);
   } else {
      oscPeriod2 = InpOscPeriod2;
   }
   
   if ( InpOscPeriod3 < 1 ) {
      oscPeriod3 = 3;
      printf("Incorrected input parameter InpOscPeriod3 = %d. Indicator will use value %d.", InpOscPeriod3, oscPeriod3);
   } else {
      oscPeriod3 = InpOscPeriod3;
   }
   
   levelsIndent = MathAbs(InpLevelsIndent);
//---
   minRequiredBars = oscPeriod1 + oscPeriod2 + oscPeriod3 + levelsPeriod - 1;
//--- indicator buffers mapping
   SetIndexBuffer(0, ExtBuffer1, INDICATOR_DATA);
   SetIndexBuffer(1, ExtBuffer2, INDICATOR_DATA);
   SetIndexBuffer(2, ExtBuffer3, INDICATOR_DATA);
   SetIndexBuffer(3, ExtBuffer4, INDICATOR_DATA);
   SetIndexBuffer(4, ExtBuffer5, INDICATOR_DATA);
   SetIndexBuffer(5, ExtBuffer6, INDICATOR_DATA);
//---
   string shortname = "UniOsc: ";
//---
   switch ( InpOscillator ) {
      case BEARS:
         oscHandle = iBearsPower(_Symbol, _Period, oscPeriod1);
         midValue = 0.0;
         shortname += "Bears Power (" + (string)oscPeriod1 + ")";
         break;
         
      case BULLS:
         oscHandle = iBullsPower(_Symbol, _Period, oscPeriod1);
         midValue = 0.0;
         shortname += "Bulls Power (" + (string)oscPeriod1 + ")";
         break;
         
      case CCI:
         oscHandle = iCCI(_Symbol, _Period, oscPeriod1, InpAppliedPrice);
         midValue = 0.0;
         levelsAutoCorrect(30.0, 300.0, 200.0);
         shortname += "CCI (" + (string)oscPeriod1 + ")";
         break;
         
      case DEMARKER:
         oscHandle = iDeMarker(_Symbol, _Period, oscPeriod1);
         midValue = 0.5;
         levelsAutoCorrect(0.05, 0.5, 0.3);
         shortname += "DeMarker (" + (string)oscPeriod1 + ")";
         break;
         
      case MACD:
         oscHandle = iMACD(_Symbol, _Period, oscPeriod1, oscPeriod2, oscPeriod3, InpAppliedPrice);
         midValue = 0.0;
         shortname += "MACD (" + (string)oscPeriod1 + ", " + (string)oscPeriod2 + ", " + (string)oscPeriod3 + ")";
         break;
         
      case MOMENTUM:
         oscHandle = iMomentum(_Symbol, _Period, oscPeriod1, InpAppliedPrice);
         midValue = 100.0;
         levelsAutoCorrect(0.03, 5.0, 0.5);
         shortname += "Momentum (" + (string)oscPeriod1 + ")";
         break;
         
      case RSI:
         oscHandle = iRSI(_Symbol, _Period, oscPeriod1, InpAppliedPrice);
         midValue = 50.0;
         levelsAutoCorrect(5.0, 50.0, 20.0);
         shortname += "RSI (" + (string)oscPeriod1 + ")";
         break;
         
      case STOCHASTIC:
         oscHandle = iStochastic(_Symbol, _Period, oscPeriod1, oscPeriod2, oscPeriod3, MODE_SMA, InpStochPrice);
         midValue = 50.0;
         levelsAutoCorrect(5.0, 50.0, 30.0);
         shortname += "Stochastic (" + (string)oscPeriod1 + ", " + (string)oscPeriod2 + ", " + (string)oscPeriod3 + ")";
         break;
         
      case WPR:
         oscHandle = iWPR(_Symbol, _Period, oscPeriod1);
         midValue = -50.0;
         levelsAutoCorrect(5.0, 50.0, 30.0);
         shortname += "WPR (" + (string)oscPeriod1 + ")";
         break;
         
      default:
         oscHandle = INVALID_HANDLE;
         Print("Unknown Oscillator!");
         return(-1);
   }
//---
   switch ( InpDrawMode ) {
      case FILLING:
         SetIndexBuffer(2, ExtBuffer3, INDICATOR_DATA);
         PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_FILLING);
         break;
         
      case HISTOGRAM:
         SetIndexBuffer(2, ExtBuffer3, INDICATOR_COLOR_INDEX);
         PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_COLOR_HISTOGRAM2);
         break;
         
      case LINE:
      default:
         SetIndexBuffer(2, ExtBuffer3, INDICATOR_DATA);
         PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
         break;
   }
//---
   IndicatorSetString(INDICATOR_SHORTNAME, shortname); 
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Levels indent / deviation correction function                    |
//+------------------------------------------------------------------+
void levelsAutoCorrect(double minIndent, double maxIndent, double correctIndent) {
//---
   if ( InpLevelsMode == BB_MODE ) {
      if ( levelsIndent > 4.0 ) {
         levelsIndent = 2.0;
         printf("Incorrected deviation input parameter InpLevelsIndent = %f. Indicator will use value %f.", 
            InpLevelsIndent, levelsIndent);
      }
   } else {
      if ( levelsIndent < minIndent || levelsIndent > maxIndent ) {
         levelsIndent = correctIndent;
         printf("Incorrected indent input parameter InpLevelsIndent = %f. Indicator will use value %f.", 
            InpLevelsIndent, levelsIndent);
      }
   }
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
   int startBar, calculated, toCopy;
//---
   if ( rates_total < minRequiredBars ) {
      Print("Not enough bars for calculation.");
      return(0);
   }
//---
   calculated = BarsCalculated(oscHandle);
   if ( calculated < rates_total ) {
      Print("Not all data of oscHandle is calculated (", calculated, " bars. Error #", GetLastError());
      return(0);
   }
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      startBar = minRequiredBars;
      toCopy = rates_total;
   } else {
      startBar = prev_calculated - 1;
      toCopy = rates_total - prev_calculated;
      if ( prev_calculated > 0 ) {
         toCopy += 1;
      }
   }
//---
   if ( CopyBuffer(oscHandle, 0, 0, toCopy, ExtBuffer1) <= 0 ) {
      Print("Getting Oscillator is failed. Error #", GetLastError());
      return(0);
   }
//---
   if ( InpLevelsMode != CONST_VALUE_MODE ) {
      SimpleMAOnBuffer(rates_total, prev_calculated, oscPeriod1+levelsPeriod, levelsPeriod, ExtBuffer1, ExtBuffer2);
   }
//---   
   for ( int bar = startBar; bar < rates_total; bar++ ) {
      double value, sum = 0.0;
      double middleLine, indent;
      //---
      switch ( InpLevelsMode ) {
         case MA_MODE:
            middleLine = ExtBuffer2[bar];
            indent = levelsIndent;
            break;
         case BB_MODE:
            middleLine = value = ExtBuffer2[bar];
            for ( int i = bar - levelsPeriod + 1; i <= bar; i++ ) {
               sum += MathPow(ExtBuffer1[i]-value, 2);
            }
            indent = levelsIndent * MathSqrt(sum/levelsPeriod);            
            break;
         case CONST_VALUE_MODE:
         default:
            middleLine = ExtBuffer2[bar] = midValue;
            indent = levelsIndent;
            break;
      }
      //---
      switch ( InpDrawMode ) {
         case LINE:
            ExtBuffer3[bar] = middleLine + indent;
            ExtBuffer4[bar] = middleLine - indent;
            break;
         case FILLING:
            ExtBuffer3[bar] = middleLine;
            ExtBuffer4[bar] = middleLine + indent;
            ExtBuffer5[bar] = middleLine - indent;
            break;
         case HISTOGRAM:
            if ( ExtBuffer1[bar] >= ExtBuffer2[bar] ) {
               ExtBuffer3[bar] = 0;
            } else {
               ExtBuffer3[bar] = 1;
            }
            ExtBuffer4[bar] = middleLine;
            ExtBuffer5[bar] = middleLine + indent;
            ExtBuffer6[bar] = middleLine - indent;
            break;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
