//+------------------------------------------------------------------+ 
//|                                                       MACD-2.mq5 | 
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
//--- indicator version
#property version   "1.00"
//--- indicator description
#property description "MACD-2"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- number of indicator buffers 4
#property indicator_buffers 4 
//--- two plots are used
#property indicator_plots   2
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET  0 // a constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//--- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//--- the following colors are used as the indicator colors
#property indicator_color1  clrLime,clrDeepPink
//--- displaying the indicator label
#property indicator_label1  "MACD_Cloud"
//+----------------------------------------------+
//|  Indicator 2 drawing parameters              |
//+----------------------------------------------+
//--- drawing indicator as a four-color histogram
#property indicator_type2 DRAW_COLOR_HISTOGRAM
//--- colors of the five-color histogram are as follows
#property indicator_color2 clrBrown,clrViolet,clrGray,clrDeepSkyBlue,clrBlue
//--- indicator line is a solid one
#property indicator_style2 STYLE_SOLID
//--- indicator line width is 2
#property indicator_width2 2
//--- displaying the indicator label
#property indicator_label2  "MACD"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input uint FastMACD     = 12;
input uint SlowMACD     = 26;
input uint SignalMACD   = 9;
input ENUM_APPLIED_PRICE   PriceMACD=PRICE_CLOSE;
//+-----------------------------------+
//--- declaration of integer variables for the start of data calculation
int  min_rates_total;
//--- declaration of dynamic arrays that will be used as indicator buffers
double ExtABuffer[],ExtBBuffer[];
double IndBuffer[],ColorIndBuffer[];
//--- declaration of integer variables for the indicators handles
int MACD_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(SignalMACD+MathMax(FastMACD,SlowMACD));
//--- getting the handle of iMACD
   MACD_Handle=iMACD(NULL,0,FastMACD,SlowMACD,SignalMACD,PriceMACD);
   if(MACD_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of iMACD");
      return(INIT_FAILED);
     }
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtABuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtABuffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,ExtBBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtBBuffer,true);
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(2,IndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//--- setting a dynamic array as a color index buffer   
   SetIndexBuffer(3,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD-2");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(MACD_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//--- declarations of local variables 
   int to_copy,limit;
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
   else limit=rates_total-prev_calculated;  // starting index for calculation of new bars only  
   to_copy=limit+1;
//--- copy newly appeared data in the arrays
   if(CopyBuffer(MACD_Handle,MAIN_LINE,0,to_copy,ExtABuffer)<=0) return(RESET);
   if(CopyBuffer(MACD_Handle,SIGNAL_LINE,0,to_copy,ExtBBuffer)<=0) return(RESET);
//--- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ExtABuffer[bar]/=_Point;
      ExtBBuffer[bar]/=_Point;
      IndBuffer[bar]=3*(ExtABuffer[bar]-ExtBBuffer[bar]);
     }
   if(prev_calculated>rates_total || prev_calculated<=0) limit--;
//--- Main loop of the Ind indicator coloring
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      int clr=2;
      if(IndBuffer[bar]>0)
        {
         if(IndBuffer[bar]>IndBuffer[bar+1]) clr=4;
         if(IndBuffer[bar]<IndBuffer[bar+1]) clr=3;
        }
      if(IndBuffer[bar]<0)
        {
         if(IndBuffer[bar]<IndBuffer[bar+1]) clr=0;
         if(IndBuffer[bar]>IndBuffer[bar+1]) clr=1;
        }
      ColorIndBuffer[bar]=clr;
     }
//---    
   return(rates_total);
  }
//+------------------------------------------------------------------+
