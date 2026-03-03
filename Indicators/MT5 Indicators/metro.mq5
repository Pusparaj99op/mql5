//+------------------------------------------------------------------+
//|                                                        METRO.mq5 | 
//|                           Copyright © 2005, TrendLaboratory Ltd. |
//|                                       E-mail: igorad2004@list.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, TrendLaboratory Ltd."
#property link      "E-mail: igorad2004@list.ru"
#property description "METRO"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers 3
#property indicator_buffers 3 
//---- only three plots are used
#property indicator_plots   3
//+----------------------------------------------+
//|  RSI indicator drawing parameters            |
//+----------------------------------------------+
//---- drawing the indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- use orange color for the indicator line
#property indicator_color1  Orange
//---- the indicator 1 line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator 1 line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "RSI"
//+----------------------------------------------+
//|  StepRSI fast indicator drawing parameters   |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used for the indicator line
#property indicator_color2  Blue
//---- the indicator 2 line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator label
#property indicator_label2  "StepRSI fast"
//+----------------------------------------------+
//|  StepRSI slow indicator drawing parameters   |
//+----------------------------------------------+
//---- drawing the indicator 3 as a line
#property indicator_type3   DRAW_LINE
//---- magenta color is used for the indicator line
#property indicator_color3  Magenta
//---- the indicator 3 line is a continuous curve
#property indicator_style3  STYLE_SOLID
//---- indicator 3 line width is equal to 1
#property indicator_width3  1
//---- displaying the indicator label
#property indicator_label3  "StepRSI slow"
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1  70
#property indicator_level2  50
#property indicator_level3  30
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//| Indicator window size limitation             |
//+----------------------------------------------+
#property indicator_minimum   0
#property indicator_maximum 100
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int PeriodRSI=7;     // Indicator period
input int StepSizeFast=5;  // Fast step
input int StepSizeSlow=15; // Slow step
input int Shift=0;         // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double Line1Buffer[];
double Line2Buffer[];
double Line3Buffer[];
//---- declaration of integer variables for the indicators handles
int RSI_Handle;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=PeriodRSI;

//---- getting handle of the RSI indicator
   RSI_Handle=iRSI(NULL,0,PeriodRSI,PRICE_CLOSE);
   if(RSI_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the RSI indicator");
      return(1);
     }

//---- set Line1Buffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,Line1Buffer,INDICATOR_DATA);
//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing shift of the beginning of counting of drawing the indicator 1 by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(Line1Buffer,true);

//---- set Line2Buffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,Line2Buffer,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- performing shift of the beginning of counting of drawing the indicator 2 by min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(Line2Buffer,true);

//---- set Line3Buffer[] dynamic array as an indicator buffer
   SetIndexBuffer(2,Line3Buffer,INDICATOR_DATA);
//---- shifting the indicator 3 horizontally by Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- performing shift of the beginning of counting of drawing the indicator 3 by min_rates_total
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(Line3Buffer,true);

//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"METRO(",PeriodRSI,", ",StepSizeFast,", ",StepSizeSlow,", ",Shift,")");
//--- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//----
  return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(RSI_Handle)<rates_total || rates_total<min_rates_total) return(0);

//---- declarations of local variables 
   int limit,to_copy,bar,ftrend,strend;
   double fmin0,fmax0,smin0,smax0,RSI0,RSI[];
   static double fmax1,fmin1,smin1,smax1;
   static int ftrend_,strend_;

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(RSI,true);

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit=rates_total-1; // starting index for calculation of all bars
      fmin1=+999999;
      fmax1=-999999;
      smin1=+999999;
      smax1=-999999;
      ftrend_=0;
      strend_=0;
     }
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

   to_copy=limit+1;

//--- copy newly appeared data in the array
   if(CopyBuffer(RSI_Handle,0,0,to_copy,RSI)<=0) return(0);

//---- restore values of the variables
   ftrend = ftrend_;
   strend = strend_;

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         ftrend_=ftrend;
         strend_=strend;
        }

      RSI0=RSI[bar];

      fmax0=RSI0+2*StepSizeFast;
      fmin0=RSI0-2*StepSizeFast;

      if(RSI0>fmax1)  ftrend=+1;
      if(RSI0<fmin1)  ftrend=-1;

      if(ftrend>0 && fmin0<fmin1) fmin0=fmin1;
      if(ftrend<0 && fmax0>fmax1) fmax0=fmax1;

      smax0=RSI0+2*StepSizeSlow;
      smin0=RSI0-2*StepSizeSlow;

      if(RSI0>smax1)  strend=+1;
      if(RSI0<smin1)  strend=-1;

      if(strend>0 && smin0<smin1) smin0=smin1;
      if(strend<0 && smax0>smax1) smax0=smax1;

      Line1Buffer[bar]=RSI0;

      if(ftrend>0) Line2Buffer[bar]=fmin0+StepSizeFast;
      if(ftrend<0) Line2Buffer[bar]=fmax0-StepSizeFast;
      if(strend>0) Line3Buffer[bar]=smin0+StepSizeSlow;
      if(strend<0) Line3Buffer[bar]=smax0-StepSizeSlow;

      if(bar>0)
        {
         fmin1=fmin0;
         fmax1=fmax0;
         smin1=smin0;
         smax1=smax0;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
