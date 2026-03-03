//+------------------------------------------------------------------+
//|                                                    ATR ratio.mq5 |
//|                         Copyright © 2005, Luis Guilherme Damiani |
//|                                      http://www.damianifx.com.br |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2005, Luis Guilherme Damiani"
//---- link to the website of the author
#property link      "http://www.damianifx.com.br"
#property description "ATR ratio"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers 1
#property indicator_buffers 1 
//---- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type1 DRAW_LINE
//---- medium orchid color is used for the line
#property indicator_color1 MediumOrchid
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the signal line label
#property indicator_label1  "ATR ratio"
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1 1
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int Short_ATRPeriod=7; //Fast ATR period
input int Long_ATRPeriod=49; //Slow ATR period
input int ATRShift=0; // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of a dynamic array that further 
//---- will be used as an indicator buffer
double ExtLineBuffer[];
//---- declaration of variables for storing the indicators handles
int SATR_Handle,LATR_Handle;
//---- declaration of the integer variables for the start of data calculation
int StartBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- getting handle of the ATR indicator
   SATR_Handle=iATR(NULL,PERIOD_CURRENT,Short_ATRPeriod);
   if(SATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");
//---- getting handle of the ATR indicator
   LATR_Handle=iATR(NULL,PERIOD_CURRENT,Long_ATRPeriod);
   if(LATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");

//---- initialization of variables of the start of data calculation
   StartBars=MathMax(Short_ATRPeriod,Long_ATRPeriod);
//---- set ExtLineBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"ATR ratio(",Short_ATRPeriod," ",Long_ATRPeriod,")");
//---- performing the horizontal shift of the indicator 1 by ATRShift
   PlotIndexSetInteger(0,PLOT_SHIFT,ATRShift);
//---- create label to display in Data Window
   PlotIndexSetString(0,PLOT_LABEL,shortname);
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtLineBuffer,true);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//----
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
   if(BarsCalculated(SATR_Handle)<rates_total
      || BarsCalculated(LATR_Handle)<rates_total
      || rates_total<StartBars)
      return(0);

//---- declarations of local variables 
   int to_copy,limit,bar;
   double SRange[],LRange[];

//---- calculations of the necessary amount of data to be copied and
//---- the limit starting index for the loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      to_copy=rates_total; // calculated number of all bars
      limit=rates_total-1; // starting index for calculation of all bars
     }
   else
     {
      to_copy=rates_total-prev_calculated+1; // calculated number of new bars only
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }

//---- copy the newly appeared data into the SRange[] and LRange[] arrays
   if(CopyBuffer(SATR_Handle,0,0,to_copy,SRange)<=0) return(0);
   if(CopyBuffer(LATR_Handle,0,0,to_copy,LRange)<=0) return(0);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(SRange,true);
   ArraySetAsSeries(LRange,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0; bar--)
     {
      if(LRange[bar]!=0.0 && LRange[bar]!=EMPTY_VALUE) ExtLineBuffer[bar]=SRange[bar]/LRange[bar];
      else ExtLineBuffer[bar]=0;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
