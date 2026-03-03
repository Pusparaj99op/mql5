//+------------------------------------------------------------------+ 
//|                                                     iAnchMom.mq5 | 
//|                                            Copyright © 2007, NNN | 
//|                                                                  | 
//+------------------------------------------------------------------+  
#property copyright "Copyright © 2007, NNN"
#property link ""
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window 
//--- number of indicator buffers
#property indicator_buffers 2 
//--- one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0 // A constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing the indicator as a color histogram
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrRed,clrMagenta,clrGray,clrBlue,clrGreen
#property indicator_width1  2
#property indicator_label1  "iAnchMom"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input uint SMAPeriod=34;                   // SMA period 
input uint EMAPeriod=20;                   // EMA period
input ENUM_APPLIED_PRICE IPC=PRICE_CLOSE;  // Price constant used for the indicator calculation
input int Shift=0;                         // Horizontal shift of the indicator in bars
//+-----------------------------------+
//--- indicator buffers
double IndBuffer[];
double ColorIndBuffer[];
//--- declaration of integer variables for the indicators handles
int SMA_Handle,EMA_Handle;
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+    
//| Momentum indicator initialization function                       | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- getting the handle of the SMA indicator
   SMA_Handle=iMA(NULL,0,SMAPeriod,0,MODE_SMA,IPC);
   if(SMA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the SMA indicator");
      return(INIT_FAILED);
     }
//--- getting the handle of the SMA indicator
   EMA_Handle=iMA(NULL,0,EMAPeriod,0,MODE_EMA,IPC);
   if(EMA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the EMA indicator");
      return(INIT_FAILED);
     }
//--- initialization of variables of the start of data calculation   
   min_rates_total=int(SMAPeriod+1);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"iAnchMom(",SMAPeriod,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,4);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Momentum iteration function                                      | 
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
   if(BarsCalculated(SMA_Handle)<rates_total
      || BarsCalculated(EMA_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);
//--- declaration of variables with a floating point  
   double SMA[],EMA[];
//--- declaration of integer variables and getting already calculated bars
   int to_copy,limit,bar;
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-1-min_rates_total+1; // starting index for the calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }
   to_copy=limit+1;
//--- copy newly appeared data in the arrays
   if(CopyBuffer(SMA_Handle,0,0,to_copy,SMA)<=0) return(RESET);
   if(CopyBuffer(EMA_Handle,0,0,to_copy,EMA)<=0) return(RESET);
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(SMA,true);
   ArraySetAsSeries(EMA,true);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      if(SMA[bar]) IndBuffer[bar]=100*((EMA[bar]/SMA[bar])-1.0);
      else IndBuffer[bar]=EMPTY_VALUE;
     }
   if(prev_calculated>rates_total || prev_calculated<=0) limit--;
//--- main cycle of the indicator coloring
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
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
