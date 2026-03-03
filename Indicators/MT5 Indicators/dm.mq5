//+------------------------------------------------------------------+
//|                                                           DM.mq5 |
//|                                          Copyright © 2007, AlexP | 
//|                                                                  | 
//+------------------------------------------------------------------+
//--- Copyright
#property copyright "Copyright © 2007, AlexP"
//--- a link to the website of the author
#property link      ""
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- two buffers are used for the indicator calculation and drawing
#property indicator_buffers 2
//--- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Drawing parameters of the bearish indicator |
//+----------------------------------------------+
//--- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//--- the Tomato color is used as the color of the indicator bearish line
#property indicator_color1  clrTomato
//--- indicator 1 line width is equal to 4
#property indicator_width1  4
//--- display of the indicator bullish label
#property indicator_label1  "DM Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//--- drawing the indicator 2 as a symbol
#property indicator_type2   DRAW_ARROW
//--- the Dark Violet color is used as the color of the bullish line of the indicator
#property indicator_color2  clrDarkViolet
//---- indicator 2 line width is equal to 4
#property indicator_width2  4
//--- display of the bearish indicator label
#property indicator_label2 "DM Buy"
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET 0   // A constant for returning the indicator recalculation command to the terminal
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//---
bool uptrend_,old;
//--- declaration of integer variables for the indicators handles
int ATR_Handle;
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialization of global variables 
   int ATR_Period=15;
   min_rates_total=int(MathMax(ATR_Period,4));
//---- Getting the handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the ATR indicator");
      return(INIT_FAILED);
     }
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//--- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,234);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellBuffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//--- shifting the starting point of the indicator 2 drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,233);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyBuffer,true);
//--- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- name for the data window and the label for sub-windows 
   string short_name="DM";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- initialization end
   return(INIT_SUCCEEDED);
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
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//--- declarations of local variables 
   int to_copy,limit,bar,trend;
   double ATR[],c3,c2,c1,c0,l3,l2,l1,l0,h3,h2,h1,h0;
   static int oldtrend;
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      limit=rates_total-min_rates_total; // starting index for the calculation of all bars
      oldtrend=0;
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for the calculation of new bars
     }
   to_copy=limit+1;
//--- copying new data in the ATR[] arrays
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//--- main calculation loop of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
      c3=close[bar+3];
      c2=close[bar+2];
      c1=close[bar+1];
      c0=close[bar];
      l3=low[bar+3];
      l2=low[bar+2];
      l1=low[bar+1];
      l0=low[bar];
      h3=high[bar+3];
      h2=high[bar+2];
      h1=high[bar+1];
      h0=high[bar];
      if(l3>l1 && l2>l1 && l1<=l0 && c3>c2 && c2>c1 && c1<c0) trend=+1;
      if(h3<h1 && h2<h1 && h1>=h0 && c3<c2 && c2<c1 && c1>c0) trend=-1;
      if(oldtrend<=0 && trend>0) BuyBuffer [bar]=low [bar]-ATR[bar]*3/8;
      if(oldtrend>=0 && trend<0) SellBuffer[bar]=high[bar]+ATR[bar]*3/8;
      //--- save values of the variables before running at the current bar
      if(bar) oldtrend=trend;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
