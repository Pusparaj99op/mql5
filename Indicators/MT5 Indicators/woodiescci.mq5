//+------------------------------------------------------------------+
//|                                                   WoodiesCCI.mq5 |
//|                                           Copyright © 2005, Gaba | 
//|                                                                  | 
//+------------------------------------------------------------------+ 
//--- Copyright
#property copyright "Copyright © 2005, Gaba"
//--- link to the website of the author
#property link "" 
#property description "WoodiesCCI"
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- four buffers are used for indicator calculation and drawing
#property indicator_buffers 4
//--- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
//---- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//---- the following colors are used as the indicator colors
#property indicator_color1  clrLime,clrRed
//--- displaying the indicator label
#property indicator_label1  "WoodiesCCI Signal"
//+----------------------------------------------+
//|  Indicator 2 drawing parameters              |
//+----------------------------------------------+
//---- drawing indicator as a four-color histogram
#property indicator_type2 DRAW_COLOR_HISTOGRAM
//--- colors of the five-color histogram are as follows
#property indicator_color2 clrDarkOrange,clrGray,clrBlue
//--- Indicator line is a solid one
#property indicator_style2 STYLE_SOLID
//--- indicator line width is 2
#property indicator_width2 2
//--- displaying the indicator label
#property indicator_label2  "WoodiesCCI"
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET  0 // a constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| Parameters of displaying horizontal levels   |
//+----------------------------------------------+
#property indicator_level1 +200
#property indicator_level2 +100
#property indicator_level3    0
#property indicator_level4 -100
#property indicator_level5 -200
#property indicator_levelcolor clrBlue
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint fastPeriod=6;                          // Fast CCI period
input uint slowPeriod=14;                         // Slow CCI period
input ENUM_APPLIED_PRICE   CCIPrice=PRICE_MEDIAN; // Price
//+----------------------------------------------+
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double IndBuffer[],ColorIndBuffer[];
double UpBuffer[],DnBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int Fast_Handle,Slow_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(MathMax(fastPeriod,slowPeriod)+8); 
//---- getting the handle of the Fast CCI indicator
   Fast_Handle=iCCI(Symbol(),PERIOD_CURRENT,fastPeriod,CCIPrice);
   if(Fast_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the Fast CCI indicator");
      return(INIT_FAILED);
     }
//---- getting the handle of the slow CCI indicator
   Slow_Handle=iCCI(Symbol(),PERIOD_CURRENT,slowPeriod,CCIPrice);
   if(Slow_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the slow CCI indicator");
      return(INIT_FAILED);
     }
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpBuffer,true);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,DnBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnBuffer,true);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(2,IndBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);   
//--- set dynamic array as a color index buffer   
   SetIndexBuffer(3,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"WoodiesCCI");
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
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(Fast_Handle)<rates_total
      || BarsCalculated(Slow_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);
//--- declaration of local variables 
   int to_copy,limit,bar;
   double slowCCI;
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated;   // starting index for calculation of new bars
     }
    to_copy=limit+1;
//--- copy newly appeared data in the arrays
   if(CopyBuffer(Fast_Handle,0,0,to_copy,UpBuffer)<=0) return(RESET);
   if(CopyBuffer(Slow_Handle,0,0,to_copy,DnBuffer)<=0) return(RESET);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      IndBuffer[bar]=DnBuffer[bar];     
      //---Filling the array of points and defining trend
      int up=0;
      int dn=0;
      for(int kkk=0; kkk<8; kkk++)
        {
         slowCCI=DnBuffer[bar+kkk];
         if (slowCCI>0) up++;
         if (slowCCI<=0) dn++;
        }
      ColorIndBuffer[bar]=1;  
      if (up>5) ColorIndBuffer[bar]=2;
      if (dn>5) ColorIndBuffer[bar]=0;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
