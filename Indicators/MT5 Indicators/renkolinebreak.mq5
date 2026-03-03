//+------------------------------------------------------------------+
//|                                               RenkoLineBreak.mq5 |
//|                                            Copyright 2013, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "It is a hybrid of Renko and Three Line Break indicators. Built on the "
#property description "close prices of current Time Frame, the box size must be equal or larger than the specified."
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3
//--- plot Upper
#property indicator_label1  "Upper"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRoyalBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Lower
#property indicator_label2  "Lower"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrCrimson
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot Boxes
#property indicator_label3  "Boxes"
#property indicator_type3   DRAW_NONE
#property indicator_color3  clrNONE
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- input parameters
input int      InpMinBoxSize = 300;    // Min Box Size
//--- indicator buffers
double         UpperBuffer[];
double         LowerBuffer[];
double         BoxesBuffer[];
//---
double         box_size;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   if ( InpMinBoxSize < 0 ) {
      box_size = 300;
      printf("Incorrected input value InpMinBoxSize = %d. Indicator will use value %d", 
         InpMinBoxSize, (int)box_size);
   } else {
      box_size = InpMinBoxSize;
   }
//--- indicator buffers mapping
   SetIndexBuffer(0,UpperBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,LowerBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,BoxesBuffer,INDICATOR_DATA);
//---
   for ( int plot = 0; plot < 3; plot++ ) {
      PlotIndexSetInteger(plot, PLOT_DRAW_BEGIN, 1);
      PlotIndexSetInteger(plot, PLOT_SHIFT, 0);
      PlotIndexSetDouble(plot, PLOT_EMPTY_VALUE, 0.0);
   }
//---
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   IndicatorSetString(INDICATOR_SHORTNAME, "Renko Line Break ("
      +DoubleToString(box_size, 0)+")");
   box_size *= _Point;
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
   int start_bar;
   bool up;
   static bool _up;
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      for ( start_bar = 0; MathAbs(price[0]-price[start_bar]) < box_size; start_bar++ ) {}
      if ( price[start_bar] > price[0] ) {
         UpperBuffer[start_bar] = price[start_bar];
         LowerBuffer[start_bar] = price[0];
         BoxesBuffer[start_bar] = 1.0;
         _up = true;
      } else {
         UpperBuffer[start_bar] = price[0];
         LowerBuffer[start_bar] = price[start_bar];
         BoxesBuffer[start_bar] = -1.0;
         _up = false;
      }
      start_bar += 1;
      for ( int plot = 0; plot < 3; plot++ ) {
         PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, start_bar);
      }
   } else {
      start_bar = prev_calculated - 1;
   }
//---
   up = _up;
//---
   for ( int bar = start_bar; bar < rates_total; bar++ ) {
      double prev_up = UpperBuffer[bar-1];
      double prev_dn = LowerBuffer[bar-1];
      double prev_boxes = BoxesBuffer[bar-1];
      
      if ( price[bar] >= prev_up + box_size ) {
         UpperBuffer[bar] = price[bar];
         LowerBuffer[bar] = prev_up;
         if ( up ) {
            BoxesBuffer[bar] = prev_boxes + 1;   
         } else {
            up = true;
            BoxesBuffer[bar] = 1.0;
         }
      } else if ( price[bar] <= prev_dn - box_size ) {
         UpperBuffer[bar] = prev_dn;
         LowerBuffer[bar] = price[bar];
         if ( up ) {
            up = false;
            BoxesBuffer[bar] = -1;
         } else {
            BoxesBuffer[bar] = prev_boxes - 1;
         }
      } else {
         UpperBuffer[bar] = prev_up;
         LowerBuffer[bar] = prev_dn;
         BoxesBuffer[bar] = prev_boxes;
      }
      
      if ( bar < rates_total - 1 ) {
         _up = up;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
