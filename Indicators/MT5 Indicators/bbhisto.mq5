//+------------------------------------------------------------------+
//|                                                      bbhisto.mq5 | 
//|                                     Copyright © 2005, Nick Bilak |
//|        http://metatrader.50webs.com/         beluck[at]gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Nick Bilak"
#property link      "http://metatrader.50webs.com/"
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- number of indicator buffers 3
#property indicator_buffers 3 
//---- three plots are used
#property indicator_plots   3
//+----------------------------------------------+
//| Bullish indicator drawing parameters         |
//+----------------------------------------------+
//--- drawing the indicator as a histogram
#property indicator_type1   DRAW_HISTOGRAM
//--- DarkOrchid color is used as the color of the line of the indicator
#property indicator_color1  clrDarkOrchid
//--- indicator 1 line width is equal to 2
#property indicator_width1  2
//---- displaying of the the indicator label
#property indicator_label1  "Histogram"
//+----------------------------------------------+
//| Bullish indicator drawing parameters         |
//+----------------------------------------------+
//--- drawing the indicator 2 as a label
#property indicator_type2   DRAW_ARROW
//--- DeepSkyBlue color is used for the indicator
#property indicator_color2  clrDeepSkyBlue
//--- indicator 2 width is equal to 2
#property indicator_width2  2
//--- displaying the indicator label
#property indicator_label2  "Buy"
//+----------------------------------------------+
//| Drawing parameters of the bearish indicator  |
//+----------------------------------------------+
//--- drawing the indicator 3 as a label
#property indicator_type3   DRAW_ARROW
//--- magenta color is used for the indicator
#property indicator_color3  clrMagenta
//--- indicator 3 width is equal to 2
#property indicator_width3  2
//--- displaying the indicator label
#property indicator_label3  "Sell"
//+-----------------------------------------------+
//| declaring constants                           |
//+-----------------------------------------------+
#define RESET  0 // a constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint                 MAPeriod=13;
input  ENUM_MA_METHOD      MAType=MODE_EMA;
input ENUM_APPLIED_PRICE   MAPrice=PRICE_CLOSE;
input int Shift=0;    // Horizontal shift of the indicator in bars 
//--- declaration of dynamic arrays that will be used as indicator buffers
double UpBuffer[],DnBuffer[];
double IndBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int MA_Handle,STD_Handle;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
int OnInit()
  {
//--- initialization of variables of data calculation start
   min_rates_total=int(MAPeriod);
//--- getting the handle of the iMA indicator
   MA_Handle=iMA(NULL,0,MAPeriod,0,MAType,MAPrice);
   if(MA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of iMA");
      return(INIT_FAILED);
     }
//--- getting the handle of the iStdDev indicator
   STD_Handle=iStdDev(NULL,0,MAPeriod,0,MAType,MAPrice);
   if(STD_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the iStdDev indicator");
      return(INIT_FAILED);
     }
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,UpBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,DnBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
   ArraySetAsSeries(UpBuffer,true);
   ArraySetAsSeries(DnBuffer,true);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"bbhisto");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
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
   if(BarsCalculated(MA_Handle)<rates_total
      || BarsCalculated(STD_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);
//--- declarations of local variables 
   int to_copy,limit,bar;
   double MA[],STD[],BB;
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-2; // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }
   to_copy=limit+1;
//--- copy newly appeared data in the arrays
   if(CopyBuffer(MA_Handle,0,0,to_copy,MA)<=0) return(RESET);
   if(CopyBuffer(STD_Handle,0,0,to_copy,STD)<=0) return(RESET);
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(MA,true);
   ArraySetAsSeries(STD,true);
   ArraySetAsSeries(close,true);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      UpBuffer[bar]=EMPTY_VALUE;
      DnBuffer[bar]=EMPTY_VALUE;
      IndBuffer[bar]=EMPTY_VALUE;
      if(STD[bar]<0.0001) STD[bar]=0.0001;
      BB=4*((close[bar]+2*STD[bar]-MA[bar])/(4*STD[bar]))-2;
      BB/=3;
      IndBuffer[bar]=BB;
      if(BB>=0) UpBuffer[bar]=+1.0;
      else DnBuffer[bar]=-1.0;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+