//+------------------------------------------------------------------+
//|                                                  ChandelExit.mq5 |
//|                                                       MQLService |
//|                                           scripts@mqlservice.com |
//+------------------------------------------------------------------+
//--- copyright
#property copyright "MQLService"
#property link      "scripts@mqlservice.com"
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- two buffers are used for the indicator calculation and drawing
#property indicator_buffers 2
//--- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//| Indicator drawing parameters                 |
//+----------------------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_FILLING
//--- the following colors are used for the indicator
#property indicator_color1  clrViolet,clrLime
//--- the line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- indicator 1 line width is equal to 1
#property indicator_width1  1
//--- display of the indicator bullish label
#property indicator_label1  "UpLoss Line"
//+----------------------------------------------+
//| declaration of constants                     |
//+----------------------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+ 
//| Price constant enumeration                   |
//+----------------------------------------------+ 
enum ENUM_PRICE_MODE   // Constant type
  {
   CLOSE_CLOSE= 1,     //Close/Close
   HIGH_LOW            //High/low
  };
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input int RangePeriod=15;
input int Shift=1;
input int ATRPeriod=14;
input int MultipleATR=4;
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double UpBuffer[];
double DnBuffer[];
//--- declaration of integer variables for the indicators handles
int ATR_Handle;
//--- declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=MathMax(ATRPeriod,RangePeriod+Shift);
//--- Getting the handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,ATRPeriod);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the ATR indicator");
      return(INIT_FAILED);
     }
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpBuffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,DnBuffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnBuffer,true);
//--- shifting the starting point for drawing indicator by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//--- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"ChandelExit(",RangePeriod,", ",ATRPeriod,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
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
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//--- declarations of local variables 
   static int direction;
   int to_copy,limit,bar;
   double ATR[],HH0,LL0;
//--- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      limit=rates_total-1-min_rates_total; // starting index for the calculation of all bars
      direction=0;
     }
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars
//--- calculation of the necessary amount of data to be copied
   to_copy=limit+1;
//--- copy newly appeared data in the ATR[] array
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//--- main calculation loop of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ATR[bar]*=MultipleATR;
      HH0=high[ArrayMaximum(high,bar+Shift,RangePeriod)]-ATR[bar];
      LL0=low[ArrayMinimum(low,bar+Shift,RangePeriod)]+ATR[bar];
      //---
      if(direction>=0)
        {
         if(close[bar]<HH0)
           {
            if(bar) direction=-1;
            UpBuffer[bar]=LL0;
            DnBuffer[bar]=HH0;
           }
         else
           {
            UpBuffer[bar]=HH0;
            DnBuffer[bar]=LL0;
           }
        }
      else
      if(direction<=0)
        {
         if(close[bar]>LL0)
           {
            if(bar) direction=+1;
            DnBuffer[bar]=LL0;
            UpBuffer[bar]=HH0;
           }
         else
           {
            UpBuffer[bar]=LL0;
            DnBuffer[bar]=HH0;
           }
        }
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
