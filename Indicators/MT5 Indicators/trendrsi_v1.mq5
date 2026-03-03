//+------------------------------------------------------------------+
//|                                                  TrendRSI_v1.mq5 |
//|                           Copyright © 2005, TrendLaboratory Ltd. |
//|                                       E-mail: igorad2004@list.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, TrendLaboratory Ltd."
#property link      "E-mail: igorad2004@list.ru"
//--- indicator version
#property version   "1.00"
//--- indicator description
#property description ""
//--- drawing the indicator in a separate window
#property indicator_separate_window  
//--- three buffers are used for the indicator calculation and drawing
#property indicator_buffers 3
//--- three plots are used
#property indicator_plots   3
//+----------------------------------------------+
//| RSI drawing parameters                       |
//+----------------------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//--- blue color is used for the indicator line
#property indicator_color1  clrBlue
//--- the line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- indicator 1 line width is equal to 1
#property indicator_width1  1
//--- displaying the indicator label
#property indicator_label1  "RSI"
//+----------------------------------------------+
//| MARSI fast drawing parameters                |
//+----------------------------------------------+
//--- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//--- red color is used as the color of the indicator line
#property indicator_color2  clrRed
//--- the line of the indicator 2 is a continuous curve
#property indicator_style2  STYLE_SOLID
//--- indicator 2 line width is equal to 1
#property indicator_width2  1
//--- displaying the indicator label
#property indicator_label2  "MARSI fast"
//+----------------------------------------------+
//| MARSI slow drawing parameters                |
//+----------------------------------------------+
//--- drawing indicator 3 as a line
#property indicator_type3   DRAW_LINE
//--- green color is used as the color of the indicator bearish line
#property indicator_color3  clrGreen
//--- the line of the indicator 3 is a continuous curve
#property indicator_style3  STYLE_SOLID
//--- indicator 3 line width is equal to 1
#property indicator_width3  1
//--- display of the bearish indicator label
#property indicator_label3  "MARSI slow"
//+----------------------------------------------+
//| Parameters of displaying horizontal levels   |
//+----------------------------------------------+
#property indicator_level1 70.0
#property indicator_level2 50.0
#property indicator_level3 30.0
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//| declaration of constants                     |
//+----------------------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint                 RSIPeriod=14;
input ENUM_APPLIED_PRICE   RSIPrice=PRICE_CLOSE;
input uint                 FastMAPeriod=9;
input  ENUM_MA_METHOD      FastMAType=MODE_EMA;
input uint                 SlowMAPeriod=45;
input  ENUM_MA_METHOD      SlowMAType=MODE_EMA;
input int                  Shift=0;            // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double Ind1Buffer[];
double Ind2Buffer[];
double Ind3Buffer[];
//--- declaration of integer variables of data starting point
int min_rates_total;
//--- declaration of integer variables for the indicator handles
int RSI_Handle,FsMA_Handle,SlMA_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(MathMax(FastMAPeriod,SlowMAPeriod)+RSIPeriod);
//--- getting the handle of the iRSI indicator
   RSI_Handle=iRSI(NULL,0,RSIPeriod,RSIPrice);
   if(RSI_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the iRSI indicator");
      return(INIT_FAILED);
     }
//--- getting the handle of the Fast iMA indicator
   FsMA_Handle=iMA(_Symbol,PERIOD_CURRENT,FastMAPeriod,0,FastMAType,RSI_Handle);
   if(FsMA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the Fast iMA indicator");
      return(INIT_FAILED);
     }
//--- getting the handle of the Slow iMA indicator
   SlMA_Handle=iMA(_Symbol,PERIOD_CURRENT,SlowMAPeriod,0,SlowMAType,RSI_Handle);
   if(SlMA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the Slow iMA indicator");
      return(INIT_FAILED);
     }
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,Ind1Buffer,INDICATOR_DATA);
//--- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- shifting the starting point for drawing indicator 1 by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Ind1Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,Ind2Buffer,INDICATOR_DATA);
//--- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//--- shifting the starting point for drawing indicator 2 by min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Ind2Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(2,Ind3Buffer,INDICATOR_DATA);
//--- shifting the indicator 3 horizontally by Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//--- shifting the starting point for drawing indicator 3 by min_rates_total
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Ind3Buffer,true);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"TrendRSI_v1");
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
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of price lows for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(RSI_Handle)<rates_total
      || BarsCalculated(FsMA_Handle)<rates_total
      || BarsCalculated(SlMA_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);
//--- declarations of local variables 
   int to_copy;
//--- calculations of the necessary amount of data to be copied 
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
      to_copy=rates_total-min_rates_total; // starting index for the calculation of all bars
   else to_copy=rates_total-prev_calculated+1; // starting index for the calculation of new bars
//--- copy newly appeared data in the arrays
   if(CopyBuffer(RSI_Handle,0,0,to_copy,Ind1Buffer)<=0) return(RESET);
   if(CopyBuffer(FsMA_Handle,0,0,to_copy,Ind2Buffer)<=0) return(RESET);
   if(CopyBuffer(SlMA_Handle,0,0,to_copy,Ind3Buffer)<=0) return(RESET);
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
