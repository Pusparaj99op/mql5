/*
 * Place the file SmoothAlgorithms.mqh
 * in the terminal_data_folder\\MQL5\Include
 */
//+------------------------------------------------------------------+ 
//|                                                    ColorMACD.mq5 | 
//|                               Copyright © 2011, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers 4
#property indicator_buffers 4 
//---- only two plots are used
#property indicator_plots   2
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing indicator as a four-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- the following colors are used in the four-colored histogram
#property indicator_color1 Gray,Teal,DarkViolet,IndianRed,Magenta
//---- indicator line - continuous
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying of the indicator line label
#property indicator_label1 "MACD"

//---- drawing indicator as a three-colored line
#property indicator_type2 DRAW_COLOR_LINE
//---- the following colors are used for the three-colored line
#property indicator_color2 Gray,Lime,Red
//---- the indicator line is a dash-dotted curve
#property indicator_style2 STYLE_DASHDOTDOT
//---- the width of the indicator line is 3
#property indicator_width2 3
//---- displaying label of the signal line
#property indicator_label2  "Signal Line"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
enum Applied_price_ //Type of constant
  {
   PRICE_CLOSE_ = 1,     //PRICE_CLOSE
   PRICE_OPEN_,          //PRICE_OPEN
   PRICE_HIGH_,          //PRICE_HIGH
   PRICE_LOW_,           //PRICE_LOW
   PRICE_MEDIAN_,        //PRICE_MEDIAN
   PRICE_TYPICAL_,       //PRICE_TYPICAL
   PRICE_WEIGHTED_,      //PRICE_WEIGHTED
   PRICE_SIMPLE,         //PRICE_SIMPLE
   PRICE_QUARTER_,       //PRICE_QUARTER_
   PRICE_TRENDFOLLOW0_,  //PRICE_TRENDFOLLOW0_
   PRICE_TRENDFOLLOW1_   //PRICE_TRENDFOLLOW1_
  };
input int Fast_MA = 12; //Fast moving average period
input int Slow_MA = 26; //SMMA smoothing depth
input ENUM_MA_METHOD MA_Method_=MODE_EMA; //Indicator averaging method
input int Signal_SMA=9; //Signal line period 
input Applied_price_ AppliedPrice=PRICE_CLOSE_;//Price constant
/* , used for the indicator calculation ( 1-CLOSE, 2-OPEN, 3-HIGH, 4-LOW, 
  5-MEDIAN, 6-TYPICAL, 7-WEIGHTED, 8-SIMPLE, 9-QUARTER, 10-TRENDFOLLOW, 11-0.5 * TRENDFOLLOW.) */
//+-----------------------------------+
//---- Declaration of the integer variables for the start of data calculation
int start,macd_start=0;
//---- declaration of dynamic arrays that further
//---- will be used as indicator buffers
double MACDBuffer[],SignBuffer[],ColorMACDBuffer[],ColorSignBuffer[];
//+------------------------------------------------------------------+
// iPriceSeries function description                                 |
// Moving_Average class description                                  | 
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh> 
//+------------------------------------------------------------------+    
//| MACD indicator initialization function                           | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   if(MA_Method_!=MODE_EMA) macd_start=MathMax(Fast_MA,Slow_MA);
   start=macd_start+Signal_SMA+1;

//---- set MACDBuffer dynamic array as indicator buffer
   SetIndexBuffer(0,MACDBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,macd_start);
//---- creating a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"MACD");
//---- setting values of the indicator that will not be visible on the chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- turning a dynamic array into a color index buffer   
   SetIndexBuffer(1,ColorMACDBuffer,INDICATOR_COLOR_INDEX);
//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,macd_start+1);

//---- set SignBuffer dynamic array as indicator buffer
   SetIndexBuffer(2,SignBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,start);
//--- creating a label to display in DataWindow
   PlotIndexSetString(2,PLOT_LABEL,"Signal SMA");
//---- setting values of the indicator that will not be visible on the chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- turning a dynamic array into a color index buffer   
   SetIndexBuffer(3,ColorSignBuffer,INDICATOR_COLOR_INDEX);
//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,start+1);

//---- initializations of a variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"MACD( ",Fast_MA,", ",Slow_MA,", ",Signal_SMA," )");
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- end of initialization
  }
//+------------------------------------------------------------------+  
//| MACD iteration function                                          | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- Checking the number of bars to be enough for the calculation
   if(rates_total<start) return(0);

//---- Declaration of integer variables
   int first1,first2,first3,bar;
//---- Declaration of variables with a floating point  
   double price_,fast_ma,slow_ma;

//---- Initialization of the indicator in the OnCalculate() block
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      first1=0;            // starting number for calculation of all first loop bars
      first2=macd_start+1; // starting number for calculation of all second loop bars
      first3=start+1;      // starting number for calculation of all third loop bars
     }
   else // starting number for calculation of new bars
     {
      first1=prev_calculated-1;
      first2=first1;
      first3=first1;
     }

//---- declaration of variables of the CMoving_Average class from the file MASeries_Cls.mqh
   static CMoving_Average MA1,MA2,MA3;

//---- Main loop of the indicator calculation
   for(bar=first1; bar<rates_total; bar++)
     {
      price_=PriceSeries(AppliedPrice,bar,open,low,high,close);

      fast_ma = MA1.MASeries(0, prev_calculated, rates_total, Fast_MA, MA_Method_, price_, bar, false);
      slow_ma = MA2.MASeries(0, prev_calculated, rates_total, Slow_MA, MA_Method_, price_, bar, false);

      MACDBuffer[bar]=fast_ma-slow_ma;

      SignBuffer[bar]=MA3.SMASeries(macd_start,prev_calculated,rates_total,Signal_SMA,MACDBuffer[bar],bar,false);
     }

//---- Main loop of the MACD indicator coloring
   for(bar=first2; bar<rates_total; bar++)
     {
      ColorMACDBuffer[bar]=0;

      if(MACDBuffer[bar]>0)
        {
         if(MACDBuffer[bar]>MACDBuffer[bar-1]) ColorMACDBuffer[bar]=1;
         if(MACDBuffer[bar]<MACDBuffer[bar-1]) ColorMACDBuffer[bar]=2;
        }

      if(MACDBuffer[bar]<0)
        {
         if(MACDBuffer[bar]<MACDBuffer[bar-1]) ColorMACDBuffer[bar]=3;
         if(MACDBuffer[bar]>MACDBuffer[bar-1]) ColorMACDBuffer[bar]=4;
        }
     }

//---- Main loop of the signal line coloring
   for(bar=first3; bar<rates_total; bar++)
     {
      ColorSignBuffer[bar]=0;
      if(MACDBuffer[bar]>SignBuffer[bar-1]) ColorSignBuffer[bar]=1;
      if(MACDBuffer[bar]<SignBuffer[bar-1]) ColorSignBuffer[bar]=2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
