//+---------------------------------------------------------------------+ 
//|                                                      ColorXOSMA.mq5 | 
//|                                  Copyright © 2011, Nikolay Kositsin | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
//| Place the SmoothAlgorithms.mqh file                                 |
//| in the directory: terminal_data_folder\MQL5\Include                 |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers 2
#property indicator_buffers 2 
//---- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a four-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- the following colors are used in the four-color histogram Gray, OliveDrab, DodgerBlue, DeepPink, Magenta
#property indicator_color1 Gray,OliveDrab,DodgerBlue,DeepPink,Magenta
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the indicator label
#property indicator_label1 "XOSMA"
//+-----------------------------------+
//|  Smoothings classes description   |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//---- declaration of the CXMA class variables from the SmoothAlgorithms.mqh file
CXMA XMA1,XMA2,XMA3;
//+-----------------------------------+
//|  declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_ //Type of constant
  {
   PRICE_CLOSE_ = 1,     // Close
   PRICE_OPEN_,          // Open
   PRICE_HIGH_,          // High
   PRICE_LOW_,           // Low
   PRICE_MEDIAN_,        // Median Price (HL/2)
   PRICE_TYPICAL_,       // Typical Price (HLC/3)
   PRICE_WEIGHTED_,      // Weighted Close (HLCC/4)
   PRICE_SIMPLE,         // Simple Price (OC/2)
   PRICE_QUARTER_,       // Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  // TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   // TrendFollow_2 Price 
  };
/*enum Smooth_Method - enumeration is declared in the SmoothAlgorithms.mqh file
  {
   MODE_SMA_,  // SMA
   MODE_EMA_,  // EMA
   MODE_SMMA_, // SMMA
   MODE_LWMA_, // LWMA
   MODE_JJMA,  // JJMA
   MODE_JurX,  // JurX
   MODE_ParMA, // ParMA
   MODE_T3,    // T3
   MODE_VIDYA, // VIDYA
   MODE_AMA,   // AMA
  }; */
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input Smooth_Method OSMA_Method=MODE_T3;        // Histogram smoothing method
input int Fast_XMA = 12;                        // Fast moving aveerage period
input int Slow_XMA = 26;                        // Slow moving average period
input int OSMA_Phase= 100;                      // Moving averages smoothing parameter
input Smooth_Method Signal_Method=MODE_JJMA;    // Signal line smoothing method
input int Signal_XMA=9;                         // Signal line period 
input int Signal_Phase=100;                     // Signal line smoothing parameter
input Applied_price_ AppliedPrice=PRICE_CLOSE_; // Price constant
//---- declaration of the integer variables for the start of data calculation
int start,macd_start;
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double XOSMABuffer[],ColorXOSMABuffer[];
#include <SmoothAlgorithms.mqh> 
//+------------------------------------------------------------------+    
//| XOSMA indicator initialization function                          | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   macd_start=MathMax(XMA1.GetStartBars(OSMA_Method,Fast_XMA,OSMA_Phase),XMA1.GetStartBars(OSMA_Method,Slow_XMA,OSMA_Phase));
   start=macd_start+XMA1.GetStartBars(Signal_Method,Signal_XMA,Signal_Phase);

//---- set XOSMABuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,XOSMABuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,macd_start);
//---- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"XOSMA");
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set ColorXOSMABuffer[] dynamic array as an indicator buffer   
   SetIndexBuffer(1,ColorXOSMABuffer,INDICATOR_COLOR_INDEX);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,macd_start+1);

//---- setting up alerts for unacceptable values of external variables
   XMA1.XMALengthCheck("Fast_XMA", Fast_XMA);
   XMA1.XMALengthCheck("Slow_XMA", Slow_XMA);
   XMA1.XMALengthCheck("Signal_XMA", Signal_XMA);
//---- setting up alerts for unacceptable values of external variables
   XMA1.XMAPhaseCheck("Phase", OSMA_Phase, OSMA_Method);
   XMA1.XMAPhaseCheck("Signal_Phase", Signal_Phase, Signal_Method);

//---- initializations of a variable for the indicator short name
   string shortname;
   string Smooth1=XMA1.GetString_MA_Method(OSMA_Method);
   string Smooth2=XMA1.GetString_MA_Method(Signal_Method);
   StringConcatenate(shortname,
                     "XOSMA( ",Fast_XMA,", ",Slow_XMA,", ",Signal_XMA,", ",Smooth1,", ",Smooth2," )");
//---- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- initialization end
  }
//+------------------------------------------------------------------+  
//| XOSMA iteration function                                         | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<start) return(0);

//---- declaration of integer variables
   int first1,first2,bar;
//---- declaration of variables with a floating point  
   double price_,fast_xma,slow_xma,xmacd,sign_xma,xosma;

//---- initialization of the indicator in the OnCalculate() block
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      first1=0;            // starting index for calculation of all first loop bars
      first2=macd_start+1; // starting index for calculation of all second loop bars
     }
   else // starting index for calculation of new bars
     {
      first1=prev_calculated-1;
      first2=first1;
     }

//---- main indicator calculation loop
   for(bar=first1; bar<rates_total; bar++)
     {
      price_=PriceSeries(AppliedPrice,bar,open,low,high,close);;

      fast_xma = XMA1.XMASeries(0, prev_calculated, rates_total, OSMA_Method, OSMA_Phase, Fast_XMA, price_, bar, false);
      slow_xma = XMA2.XMASeries(0, prev_calculated, rates_total, OSMA_Method, OSMA_Phase, Slow_XMA, price_, bar, false);

      xmacd=fast_xma-slow_xma;
      sign_xma=XMA3.XMASeries(macd_start,prev_calculated,rates_total,Signal_Method,Signal_Phase,Signal_XMA,xmacd,bar,false);
      xosma=xmacd-sign_xma;

      //---- loading the obtained values in the indicator buffer
      if(bar>=start) XOSMABuffer[bar]=xmacd;
      else           XOSMABuffer[bar]=EMPTY_VALUE;
     }

//---- main loop of the XOSMA indicator coloring
   for(bar=first2; bar<rates_total; bar++)
     {
      ColorXOSMABuffer[bar]=0;

      if(XOSMABuffer[bar]>0)
        {
         if(XOSMABuffer[bar]>XOSMABuffer[bar-1]) ColorXOSMABuffer[bar]=1;
         if(XOSMABuffer[bar]<XOSMABuffer[bar-1]) ColorXOSMABuffer[bar]=2;
        }

      if(XOSMABuffer[bar]<0)
        {
         if(XOSMABuffer[bar]<XOSMABuffer[bar-1]) ColorXOSMABuffer[bar]=3;
         if(XOSMABuffer[bar]>XOSMABuffer[bar-1]) ColorXOSMABuffer[bar]=4;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
