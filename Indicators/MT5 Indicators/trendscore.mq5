//+------------------------------------------------------------------+
//|                                                   TrendScore.mq5 |
//|                                            Copyright 2013, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "simple indicator that attempts to show when price is trending by looking at up and down days."
//---
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot TS
#property indicator_label1  "TS"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//---
#property indicator_level1  0
#property indicator_levelcolor clrGray
//---
enum ENUM_TS_PRICE {
   CLOSE_CLOSE,         // Close/Close
   OPEN_CLOSE           // Open/Close
};

enum ENUM_USE_PERIOD_MODE {
   USE_PERIOD,          // Use Period
   NO_USE_PERIOD        // No Period
};
//--- input parameters
input ENUM_TS_PRICE        InpPriceMode = OPEN_CLOSE;    // Price Mode
input ENUM_USE_PERIOD_MODE InpPeriodMode = USE_PERIOD;   // Period Mode
input ushort               InpTsPeriod = 10;             // Period
//--- indicator buffers
double         TSBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0, TSBuffer, INDICATOR_DATA);
//---
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpTsPeriod);
//---
   IndicatorSetInteger(INDICATOR_DIGITS, 0);
   string shortname = "Trend Score (";
   if ( InpPeriodMode == USE_PERIOD ) {
      shortname += (string)InpTsPeriod + ", ";
   }
   shortname += EnumToString(InpPriceMode) + ")";
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NoPeriodScore(double cur_price, double prev_price, double prev_score) {
//---
   double cur_score;

   if ( cur_price > prev_price ) {
      if ( prev_score >= 0.0 ) {
         cur_score = prev_score + 1;
      } else {
         cur_score = 1.0;
      }
   } else if ( cur_price < prev_price ) {
      if ( prev_score < 0.0 ) {
         cur_score = prev_score - 1;
      } else {
         cur_score = -1.0;
      }
   } else {
      cur_score = prev_score;
   }   
//---
   return(cur_score);
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
   int start_bar;
   
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      ArrayInitialize(TSBuffer, 0.0);
      start_bar = InpTsPeriod;
   } else {
      start_bar = prev_calculated - 1;
   }
//---
   for ( int bar = start_bar; bar < rates_total; bar++ ) {
      
      if ( InpPeriodMode == USE_PERIOD ) {
         int sum = 0;
      
         for ( int shift = bar - InpTsPeriod + 1; shift <= bar; shift++ ) {
            double prev_price = open[shift];
            
            if ( InpPriceMode == CLOSE_CLOSE ) {
               prev_price = close[shift-1];
            }
            if ( close[shift] > prev_price ) {
               sum += 1;
            } else if ( close[shift] < prev_price ) {
               sum -= 1; 
            } 
         }
         TSBuffer[bar] = sum;
      } else {
         double prev_price = open[bar];
         
         if ( InpPriceMode == CLOSE_CLOSE ) {
            prev_price = close[bar-1];
         }
         TSBuffer[bar] = NoPeriodScore(close[bar], prev_price, TSBuffer[bar-1]);
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
