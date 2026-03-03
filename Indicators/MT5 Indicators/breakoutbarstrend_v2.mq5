//+------------------------------------------------------------------+
//|                                         BreakoutBarsTrend_v2.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "The alternative indicator to determine the trend based on the breakthrough bars and the distance from extremums."
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   4
//--- plot Values
#property indicator_label1  "BBT Values"
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot BBT
#property indicator_label2  "BBT Open;BBT High;BBT Low;BBT Close"
#property indicator_type2   DRAW_COLOR_CANDLES
#property indicator_color2  clrBlue,clrRoyalBlue,clrDeepSkyBlue,clrRed,clrTomato,clrOrange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot ReverseToDown
#property indicator_label3  "Reverse To Down"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrDodgerBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot ReverseToUp
#property indicator_label4  "Reverse To Up"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrTomato
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//---
enum REVERSAL_MODE {
   PIPS,       // In pips
   PERCENT     // In percentage
};
//---
struct bbtData {
   int value;
   int result;
   double firstPrice;
};
//--- input parameters
input REVERSAL_MODE  InpReversal = PIPS;           // Reversal
input double         InpDelta = 1000;              // Delta
input bool           InpShowReverseLevels = true;  // Show the reversal levels
input bool           InpShowTrendsInfo = true;     // Show the trends info
input int            InpTrendsQuantity = 5;        // Number of trends
//--- indicator buffers
double         ValuesBuffer[];
double         OpenBuffer[];
double         HighBuffer[];
double         LowBuffer[];
double         CloseBuffer[];
double         ColorsBuffer[];
double         ReverseToDownBuffer[];
double         ReverseToUpBuffer[];
//--- global variables
int            minRequiredBars;
int            quantity;
double         delta;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   minRequiredBars = 2;
//---
   delta = InpDelta;
   if ( InpReversal == PIPS ) {
      if ( InpDelta < 30 ) {
         delta = 1000;
         printf("The \"Delta\" parameter is specified incorrectly: %d. the: %d. value will be used",
            (int)InpDelta, (int)delta);
      }
      delta *=  _Point;
   } else {
      if ( InpDelta < 0.03 || InpDelta > 30.0 ) {
         delta = 1.0;
         printf("The \"Delta\" parameter is specified incorrectly: %f. the: %f. value will be used",
            InpDelta, delta);
      }
   }
//---
   if ( InpShowTrendsInfo ) {
      if ( InpTrendsQuantity < 2 || InpTrendsQuantity > 20 ) {
         quantity = 5;
         printf("The \"Number of series\" parameter is specified incorrectly: %d. the: %d. value will be used",
            InpTrendsQuantity, quantity);
      } else {
         quantity = InpTrendsQuantity;
      }
   }
//--- indicator buffers mapping
   SetIndexBuffer(0, ValuesBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, OpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, HighBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, LowBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, CloseBuffer, INDICATOR_DATA);
   SetIndexBuffer(5, ColorsBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6, ReverseToDownBuffer, INDICATOR_DATA);
   SetIndexBuffer(7, ReverseToUpBuffer, INDICATOR_DATA);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(2, PLOT_ARROW, 159);
   PlotIndexSetInteger(3, PLOT_ARROW, 159);
//---
   for ( int i = 0; i < 4; i++ ) {
      PlotIndexSetInteger(i, PLOT_DRAW_BEGIN, minRequiredBars);
      PlotIndexSetInteger(i, PLOT_SHIFT, 0);
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0);
   }
//---
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//---
   string modeData = (InpReversal == PIPS) ? DoubleToString(InpDelta, 0)+" pips" : DoubleToString(InpDelta, 2)+"%";
   IndicatorSetString(INDICATOR_SHORTNAME, "Breakout Bars Trend v2 ("+modeData+")");
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
//| Get Reversal Value function                                      |
//+------------------------------------------------------------------+
double getReversal(double price) {
//---
   if ( InpReversal == PIPS ) {
      return(delta);
   }
   return(NormalizeDouble((price/100)*delta, _Digits));
//---
}
//+------------------------------------------------------------------+
//| Calculate Trends Info function                                   |
//+------------------------------------------------------------------+
void calculateTrendsInfo(bbtData &data[], int bar, const double &price[], int qty) {
//---
   double curPrice = price[bar];
//---
   data[0].value = (int)ValuesBuffer[bar];
   for ( int i = 1; i < qty && bar > 0; bar-- ) {
      //---
      if ( ValuesBuffer[bar-1] * ValuesBuffer[bar] < 0 ) {
            data[i].value = (int)ValuesBuffer[bar-1];
            data[i-1].firstPrice = price[bar];
            calculateResult(data[i-1], curPrice);
            curPrice = price[bar];
            i += 1;
      }
   }
   for ( ; bar > 0; bar--  ) {
      if ( ValuesBuffer[bar-1] * ValuesBuffer[bar] < 0 ) {
         data[qty-1].firstPrice = price[bar];
         calculateResult(data[qty-1], curPrice);
         break;
      }
   }
//---
}
//+------------------------------------------------------------------+
//| function                                                         |
//+------------------------------------------------------------------+
void calculateResult(bbtData &data, double price) {
//---
   if ( data.value > 0 ) {
      data.result = int((price - data.firstPrice) / _Point);
   } else {
      data.result = int((data.firstPrice - price) / _Point);
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
   int startBar, lastBar;
   bool upTrend;
   double minPrice, maxPrice, reversal;
   
   static bool _upTrend;
   static double _minPrice, _maxPrice;
//---
   lastBar = rates_total - 1;
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      ArrayInitialize(ReverseToDownBuffer, 0.0);
      ArrayInitialize(ReverseToUpBuffer, 0.0);
      reversal = getReversal(close[0]);
      for ( startBar = 1; MathAbs(close[startBar]-close[0]) - reversal <= 0.00001; startBar++ );
      for ( int bar = 0; bar < startBar; bar++ ) {
         ValuesBuffer[bar] = 0.0;
         OpenBuffer[bar] = 0.0;
         HighBuffer[bar] = 0.0;
         LowBuffer[bar] = 0.0;
         CloseBuffer[bar] = 0.0;
         ReverseToDownBuffer[bar] = 0.0;
         ReverseToUpBuffer[bar] = 0.0;
      }
      if ( close[startBar] > close[0] ) {
         ValuesBuffer[startBar] = 1;
         _upTrend = true;
         _minPrice = low[0];
         _maxPrice = high[startBar];
      } else {
         ValuesBuffer[startBar] = -1;
         _upTrend = false;
         _minPrice = low[startBar];
         _maxPrice = high[0];
      }
   } else {
      startBar = prev_calculated - 1;
   }
//---
   upTrend = _upTrend;
   minPrice = _minPrice;
   maxPrice = _maxPrice;
//---
   for ( int bar = startBar; bar < rates_total && !IsStopped(); bar++ ) {
      int prevBar = bar - 1;
      //---
      minPrice = MathMin(minPrice, low[prevBar]);
      maxPrice = MathMax(maxPrice, high[prevBar]);
      //---
      if ( prev_calculated != rates_total && bar == lastBar ) {
         if ( ValuesBuffer[prevBar] * ValuesBuffer[prevBar-1] < 0 ) {
            minPrice = low[prevBar];
            maxPrice = high[prevBar];
         }
         _upTrend = upTrend;
         _minPrice = minPrice;
         _maxPrice = maxPrice;
      }
      //---
      OpenBuffer[bar] = open[bar];
      HighBuffer[bar] = high[bar];
      LowBuffer[bar] = low[bar];
      CloseBuffer[bar] = close[bar];
      //---
      if ( upTrend ) {
         reversal = getReversal(maxPrice);
         if ( close[bar] > maxPrice ) {
            ValuesBuffer[bar] = ValuesBuffer[prevBar] + 1;
            ColorsBuffer[bar] = 0;
         } else if ( close[bar] < MathMax(maxPrice, high[bar]) - reversal && close[bar] < low[prevBar] ) {
            upTrend = false;
            ValuesBuffer[bar] = -1;
            ColorsBuffer[bar] = 3;
            if ( bar != lastBar ) {
               maxPrice = high[bar];
               minPrice = low[bar];
            }
         } else {
            ValuesBuffer[bar] = ValuesBuffer[prevBar];
            if ( close[bar] >= open[bar] ) {
               ColorsBuffer[bar] = 1;
            } else {
               ColorsBuffer[bar] = 2;
            }
         }
      } else {
         reversal = getReversal(minPrice);
         if ( close[bar] < minPrice ) {
            ValuesBuffer[bar] = ValuesBuffer[prevBar] - 1;
            ColorsBuffer[bar] = 3;
         } else if ( close[bar] > MathMin(minPrice, low[bar]) + reversal && close[bar] > high[prevBar] ) {
            upTrend = true;
            ValuesBuffer[bar] = 1;
            ColorsBuffer[bar] = 0;
            if ( bar != lastBar ) {
               minPrice = low[bar];
               maxPrice = high[bar];
            }
         } else {
            ValuesBuffer[bar] = ValuesBuffer[prevBar];
            if ( close[bar] >= open[bar] ) {
               ColorsBuffer[bar] = 5;
            } else {
               ColorsBuffer[bar] = 4;
            }
         }
      }
      //---
      if ( InpShowReverseLevels ) {
         if ( upTrend ) {
            ReverseToDownBuffer[bar] = maxPrice - reversal;
            ReverseToUpBuffer[bar] = 0.0;
         } else {
            ReverseToDownBuffer[bar] = 0.0;
            ReverseToUpBuffer[bar] = minPrice + reversal;
         }
      }
   }
//---
   if ( InpShowTrendsInfo ) {
      bbtData trendsData[];
      ArrayResize(trendsData, quantity);
      calculateTrendsInfo(trendsData, lastBar, close, quantity);
      //---
      string comm = "Trends Info:\n";
      for ( int i = quantity - 1; i >= 0; i-- ) {
         comm += (string)trendsData[i].value + ":  " + (string)trendsData[i].result + " pips\n";
      }
      Comment(comm);
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
