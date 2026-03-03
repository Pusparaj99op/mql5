//+------------------------------------------------------------------+ 
//|                                          Cronex_Impulse_MACD.mq5 | 
//|                                        Copyright © 2007, Cronex. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2008, Cronex"
#property  link      "http://www.metaquotes.net/"
//---- Indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers 4
#property indicator_buffers 4 
//---- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
//---- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//---- the following colors are used as the indicator colors
#property indicator_color1  clrLime,clrRed
//---- displaying the indicator label
#property indicator_label1  "Cronex_Impulse_MACD Signal"
//+----------------------------------------------+
//|  Indicator 2 drawing parameters              |
//+----------------------------------------------+
//---- drawing indicator as a four-color histogram
#property indicator_type2 DRAW_COLOR_HISTOGRAM
//---- colors of the five-color histogram are as follows
#property indicator_color2 clrMediumVioletRed,clrViolet,clrGray,clrDeepSkyBlue,clrBlue
//---- Indicator line is a solid one
#property indicator_style2 STYLE_SOLID
//---- indicator line width is 2
#property indicator_width2 2
//---- displaying the indicator label
#property indicator_label2  "Cronex_Impulse_MACD"
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET  0 // A constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint Master_MA=34;  // MACD averaging period
input uint Signal_MA=9;   // Signal line period 
//+-----------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double IndBuffer[],ColorIndBuffer[];
double UpBuffer[],DnBuffer[];
//---- Declaration of integer variables for indicators handles
int MAh_Handle,MAl_Handle,MAw_Handle;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total,min_rates_1;
//+------------------------------------------------------------------+    
//| MACD indicator initialization function                           | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_1=int(Master_MA+1);
   min_rates_total=int(min_rates_1+Signal_MA+1);

//---- Getting the handle of the iMA 1 indicator
   MAh_Handle=iMA(NULL,0,Master_MA,0,MODE_SMMA,PRICE_HIGH);
   if(MAh_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of iMA 1");
      return(INIT_FAILED);
     }

//---- Getting the handle of the iMA 2 indicator
   MAl_Handle=iMA(NULL,0,Master_MA,0,MODE_SMMA,PRICE_LOW);
   if(MAl_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of iMA 2");
      return(INIT_FAILED);
     }

//---- Getting the handle of the iMA 3 indicator
   MAw_Handle=iMA(NULL,0,Master_MA,0,MODE_SMA,PRICE_WEIGHTED);
   if(MAw_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of iMA 3");
      return(INIT_FAILED);
     }

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpBuffer,true);

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,DnBuffer,INDICATOR_DATA);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnBuffer,true);

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(2,IndBuffer,INDICATOR_DATA);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);

//---- set dynamic array as a color index buffer   
   SetIndexBuffer(3,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);

//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);

//---- Initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Cronex_Impulse_MACD(",Master_MA,", ",Signal_MA,")");
//--- Creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- Determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| MACD iteration function                                          | 
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
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(MAh_Handle)<rates_total
      || BarsCalculated(MAl_Handle)<rates_total
      || BarsCalculated(MAw_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declaration of local variables 
   int to_copy,limit,bar;
   double MAh[],MAl[],MAw[];

//---- calculations of the necessary amount of data to be copied
//---- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_1-1; // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }

   to_copy=limit+1; // calculated number of all bars  

//---- copy newly appeared data into the arrays
   if(CopyBuffer(MAh_Handle,0,0,to_copy,MAh)<=0) return(RESET);
   if(CopyBuffer(MAl_Handle,0,0,to_copy,MAl)<=0) return(RESET);
   if(CopyBuffer(MAw_Handle,0,0,to_copy,MAw)<=0) return(RESET);

//---- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(MAh,true);
   ArraySetAsSeries(MAl,true);
   ArraySetAsSeries(MAw,true);

//---- The main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      IndBuffer[bar]=0.0;
      if(MAw[bar]>MAh[bar]) IndBuffer[bar]=MAw[bar]-MAh[bar];
      if(MAw[bar]<MAl[bar]) IndBuffer[bar]=MAw[bar]-MAl[bar];
      IndBuffer[bar]/=_Point;
      UpBuffer[bar]=IndBuffer[bar];
      double Sum=0.0;
      if(IndBuffer[bar])
        {
         for(int iii=0; iii<int(Signal_MA) && !IsStopped(); iii++) Sum+=IndBuffer[MathMin(bar+iii,rates_total-1)];
         DnBuffer[bar]=Sum/Signal_MA;
        }
      else
        {
         UpBuffer[bar]=UpBuffer[bar+1];
         DnBuffer[bar]=UpBuffer[bar];
        }
     }

   if(prev_calculated>rates_total || prev_calculated<=0) limit--;
//---- main loop of the Ind indicator coloring
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
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
