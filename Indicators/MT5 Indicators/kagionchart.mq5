//+------------------------------------------------------------------+
//|                                                  KagiOnChart.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "The Kagi chart in the main chart window considering the time scale."
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   5
//--- plot Yang
#property indicator_label1  "Yang"
#property indicator_type1   DRAW_HISTOGRAM2
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Yin
#property indicator_label2  "Yin"
#property indicator_type2   DRAW_HISTOGRAM2
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot Bend1
#property indicator_label3  "Bend1"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrRed,clrBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//--- plot Bend2
#property indicator_label4  "Bend2"
#property indicator_type4   DRAW_COLOR_LINE
#property indicator_color4  clrRed,clrBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
//--- plot Bend3
#property indicator_label5  "Bend3"
#property indicator_type5   DRAW_COLOR_LINE
#property indicator_color5  clrRed,clrBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2
//---
enum REVERSAL_MODE {
   PIPS,    // In pips
   PERCENT  // In percentage
};
//--- input parameters
input REVERSAL_MODE  InpMode = PIPS;   // Reversal
input int            InpPips = 100;    // Reversal in pips
input double         InpPercent = 0.5; // Reversal in %-õ
//--- indicator buffers
double         YangBuffer1[];
double         YangBuffer2[];
double         YinBuffer1[];
double         YinBuffer2[];
double         Bend1Buffer[];
double         Bend1Colors[];
double         Bend2Buffer[];
double         Bend2Colors[];
double         Bend3Buffer[];
double         Bend3Colors[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0, YangBuffer1, INDICATOR_DATA);
   SetIndexBuffer(1, YangBuffer2, INDICATOR_DATA);
   SetIndexBuffer(2, YinBuffer1, INDICATOR_DATA);
   SetIndexBuffer(3, YinBuffer2, INDICATOR_DATA);
   SetIndexBuffer(4, Bend1Buffer, INDICATOR_DATA);
   SetIndexBuffer(5, Bend1Colors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6, Bend2Buffer, INDICATOR_DATA);
   SetIndexBuffer(7, Bend2Colors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(8, Bend3Buffer, INDICATOR_DATA);
   SetIndexBuffer(9, Bend3Colors, INDICATOR_COLOR_INDEX);
//---
   for ( int i = 0; i < 5; i++ ) {
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0);
      PlotIndexSetInteger(i, PLOT_SHIFT, 0);
   }
   for ( int i = 2; i < 5; i++ ) {
      PlotIndexSetInteger(i, PLOT_SHOW_DATA, false);
   }
//---
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//---
   string modeData = (InpMode == PIPS) ? (string)InpPips+" pips" : DoubleToString(InpPercent, 2)+"%";
   IndicatorSetString(INDICATOR_SHORTNAME, "Kagi ("+modeData+")");
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Get Reversal Value function                                      |
//+------------------------------------------------------------------+
double getReversal(double price) {
//---
   if ( InpMode == PIPS ) {
      return(InpPips*_Point);
   }
   return(NormalizeDouble((price/100)*InpPercent, _Digits));
//---
}
//+------------------------------------------------------------------+
//| function                                                         |
//+------------------------------------------------------------------+
void setBendContinue(int bar, double price, int clr) {
//---
   if ( Bend1Buffer[bar-1] == price ) {
      Bend1Buffer[bar] = price;
      Bend1Colors[bar] = clr;
   } else if ( Bend2Buffer[bar-1] == price ) {
      Bend2Buffer[bar] = price;
      Bend2Colors[bar] = clr;
   } else if ( Bend3Buffer[bar-1] == price ) {
      Bend3Buffer[bar] = price;
      Bend3Colors[bar] = clr;
   }
//---
}
//+------------------------------------------------------------------+
//| function                                                         |
//+------------------------------------------------------------------+
void setBendNew(int bar, double price, int clr) {
//---
   if ( Bend1Buffer[bar-1] == 0.0 ) {
      Bend1Buffer[bar] = price;
      Bend1Colors[bar] = clr;
   } else if ( Bend2Buffer[bar-1] == 0.0 ) {
      Bend2Buffer[bar] = price;
      Bend2Colors[bar] = clr;
   } else if ( Bend3Buffer[bar-1] == 0.0 ) {
      Bend3Buffer[bar] = price;
      Bend3Colors[bar] = clr;
   }
//---
}
//+------------------------------------------------------------------+
//| function                                                         |
//+------------------------------------------------------------------+
void setBends(int bar, double contPrice, int contClr, double newPrice, int newClr) {
//---
   setBendContinue(bar, contPrice, contClr);
   setBendNew(bar, newPrice, newClr);
//---
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
   bool up, yang;
   double localMin, localMax;
   double reversalMin, reversalMax;
   
   static bool _up, _yang; 
   static double _localMin, _localMax;
   static double _reversalMin, _reversalMax;
//---
   double reversal = getReversal(price[0]);
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      ArrayInitialize(YangBuffer1, 0.0);
      ArrayInitialize(YangBuffer2, 0.0);
      ArrayInitialize(YinBuffer1, 0.0);
      ArrayInitialize(YinBuffer2, 0.0);
      ArrayInitialize(Bend1Buffer, 0.0);
      ArrayInitialize(Bend2Buffer, 0.0);
      ArrayInitialize(Bend3Buffer, 0.0);
      //---
      for ( startBar = 1; MathAbs(price[startBar]-price[0]) - reversal <= 0.00001; startBar++ );
      if ( price[startBar] > price[0] ) {
         _localMin = _reversalMin = price[0];
         _localMax = _reversalMax = price[startBar];
         _yang = _up = true;
      } else {
         _localMin = _reversalMin = price[startBar];
         _localMax = _reversalMax = price[0];
         _yang = _up = false;
      }
   } else {
      startBar = prev_calculated - 1;
   }
//---
   up = _up;
   yang = _yang;
   localMin = _localMin;
   localMax = _localMax;
   reversalMin = _reversalMin;
   reversalMax = _reversalMax;
//---
   for ( int bar = startBar; bar < rates_total && !IsStopped(); bar++ ) {
      double current = price[bar];
      //---
      if ( rates_total != prev_calculated && bar == rates_total - 1 ) {
         _up = up;
         _yang = yang;
         _localMin = localMin;
         _localMax = localMax;
         _reversalMin = reversalMin;
         _reversalMax = reversalMax;
      }
      //---
      if ( yang ) {
         if ( up ) {
            reversal = getReversal(localMax);
            YangBuffer1[bar] = localMax;
            if ( current > localMax ) {               
               setBends(bar, localMax, 1, current, 1);
               YangBuffer2[bar] = current;
               localMax = current;
            } else if ( current < localMax - reversal ) {
               if ( current < reversalMin ) {
                  setBends(bar, localMax, 1, current, 0);
                  YangBuffer2[bar] = YinBuffer1[bar] = reversalMin;
                  YinBuffer2[bar] = current;
                  localMin = current;
                  reversalMax = localMax;
                  yang = false;
               } else {
                  setBends(bar, localMax, 1, current, 1);
                  YangBuffer2[bar] = current;
                  localMin = current;
                  reversalMax = localMax;
               }
               up = false;
            } else {
               setBendContinue(bar, localMax, 1);
               YangBuffer2[bar] = localMax;
            }
         } else { // yang !up (down)
            reversal = getReversal(localMin);
            YangBuffer1[bar] = localMin;
            if ( current < localMin ) {
               if ( current < reversalMin ) {
                  setBends(bar, localMin, 1, current, 0);
                  YangBuffer2[bar] = YinBuffer1[bar] = reversalMin;
                  YinBuffer2[bar] = current;
                  localMin = current;
                  reversalMax = localMax;
                  yang = false;
               } else {
                  setBends(bar, localMin, 1, current, 1);
                  YangBuffer2[bar] = current;
                  localMin = current;
               }
            } else if ( current > localMin + reversal ) {
               setBends(bar, localMin, 1, current, 1);
               YangBuffer2[bar] = current;
               localMax = current;
               reversalMin = localMin;
               up = true;
            } else {
               setBendContinue(bar, localMin, 1);
               YangBuffer2[bar] = localMin;
            }
         }
      } else {    // Yin
         if ( up ) {
            reversal = getReversal(localMax);
            YinBuffer1[bar] = localMax;
            if ( current > localMax ) {
               if ( current > reversalMax ) {
                  setBends(bar, localMax, 0, current, 1);
                  YinBuffer2[bar] = YangBuffer1[bar] = reversalMax;
                  YangBuffer2[bar] = current;
                  localMax = current;
                  reversalMin = localMin;
                  yang = true;
               } else {
                  setBends(bar, localMax, 0, current, 0);
                  YinBuffer2[bar] = current;
                  localMax = current;
               }
            } else if ( current < localMax - reversal ) {
               setBends(bar, localMax, 0, current, 0);
               YinBuffer2[bar] = current;
               localMin = current;
               reversalMax = localMax;
               up = false;
            } else {
               setBendContinue(bar, localMax, 0);
               YinBuffer2[bar] = localMax;
            }
         } else { // Yin !up (down)
            reversal = getReversal(localMin);
            YinBuffer1[bar] = localMin;
            if ( current < localMin ) {
               setBends(bar, localMin, 0, current, 0);
               YinBuffer2[bar] = current;
               localMin = current;
            } else if ( current > localMin + reversal ) {
               if ( current > reversalMax ) {
                  setBends(bar, localMin, 0, current, 1);
                  YinBuffer2[bar] = YangBuffer1[bar] = reversalMax;
                  YangBuffer2[bar] = current;
                  localMax = current;
                  reversalMin = localMin;
                  yang = true;
               } else {
                  setBends(bar, localMin, 0, current, 0);
                  YinBuffer2[bar] = current;
                  localMax = current;
                  reversalMin = localMin;
               }
               up = true;
            } else {
               setBendContinue(bar, localMin, 0);
               YinBuffer2[bar] = localMin;
            }
         }
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
