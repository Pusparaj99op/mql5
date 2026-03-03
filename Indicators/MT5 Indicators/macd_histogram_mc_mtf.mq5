//+------------------------------------------------------------------+
//|                                        MACD_Histogram_MTF_MC.mq5 |
//|                                           Copyright © 2010, AK20 |
//|                                             traderak20@gmail.com |
//|                                                                  |
//|                                                        Based on: |
//|                                                         MACD.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2010, traderak20@gmail.com"
#property description "Moving Average Convergence/Divergence, Histogram, Multi-timeframe, Multi-color"
/*--------------------------------------------------------------------
2010 09 26: v03   Improved display of values on timeframes smaller than the chart's timeframe
                     Set buffers to EMPTY_VALUE instead of 0 after: if(convertedTime<tempTimeArray_TF2[0])
                  Code optimization
                     Removed PLOT_DRAW_BEGIN from OnInit() - inherited from single time frame indicator
                     Moved ArraySetAsSeries of buffers and arrays into OnInit()
                  Added MODE_SMMA and MODE_LWMA as MA methods for Signal line
----------------------------------------------------------------------*/
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3
//--- indicator plots
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Blue
#property indicator_color2  Red
#property indicator_color3  Green,Red,Blue
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_label1  "MACD_TF2"
#property indicator_label2  "Signal_TF2"
#property indicator_label3  "Histogram_TF2"
//--- enum variables
enum colorswitch           // use single or multi-color display of Histogram
  {
   MultiColor=0,
   SingleColor=1
  };
//--- input parameters
input ENUM_TIMEFRAMES      InpTimeFrame_2=PERIOD_H1;              // Timeframe 2 (TF2) period
input string               InpIndicator_TF1="MACD_Histogram_MC";  // Location of single timeframe indicator
input int                  InpFastEMA=12;                         // Fast EMA period
input int                  InpSlowEMA=26;                         // Slow EMA period
input int                  InpSignalMA=9;                         // Signal MA period
input ENUM_MA_METHOD       InpAppliedSignalMA=MODE_SMA;           // Applied MA method for signal line
input colorswitch          InpUseMultiColor=MultiColor;           // Use multi-color or single-color histogram
input ENUM_APPLIED_PRICE   InpAppliedPrice=PRICE_CLOSE;           // Applied price
//--- indicator buffers
double                     ExtMacdBuffer_TF2[];
double                     ExtSignalBuffer_TF2[];
double                     ExtHistogramBuffer_TF2[];
double                     ExtHistogramColorBuffer_TF2[];
//--- arrays TF2 - to retrieve TF 2 values of buffers and/or timeseries
double                     ExtMacdArray_TF2[];           // intermediate array to hold TF2 MACD buffer values
double                     ExtSignalArray_TF2[];         // intermediate array to hold TF2 signal buffer values
double                     ExtHistogramArray_TF2[];      // intermediate array to hold TF2 histogram buffer values
double                     ExtHistogramColorArray_TF2[]; // intermediate array to hold TF2 histogram color buffer values
//--- variables
int                        PeriodRatio=1;                // ratio between timeframe 1 (TF1) and timeframe 2 (TF2)
int                        PeriodSeconds_TF1;            // TF1 period in seconds
int                        PeriodSeconds_TF2;            // TF2 period in seconds
//--- indicator handles TF2
int                        ExtMacdHandle_TF2;            // MACD handle TF2
//--- turn on/off error messages
bool                       ShowErrorMessages=true;       // turn on/off error messages for debugging
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBuffer_TF2,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer_TF2,INDICATOR_DATA);
   SetIndexBuffer(2,ExtHistogramBuffer_TF2,INDICATOR_DATA);
   SetIndexBuffer(3,ExtHistogramColorBuffer_TF2,INDICATOR_COLOR_INDEX);

//--- set buffers as series, most recent entry at index [0]
   ArraySetAsSeries(ExtMacdBuffer_TF2,true);
   ArraySetAsSeries(ExtSignalBuffer_TF2,true);
   ArraySetAsSeries(ExtHistogramBuffer_TF2,true);
   ArraySetAsSeries(ExtHistogramColorBuffer_TF2,true);
//--- set arrays as series, most recent entry at index [0]
   ArraySetAsSeries(ExtMacdArray_TF2,true);
   ArraySetAsSeries(ExtSignalArray_TF2,true);
   ArraySetAsSeries(ExtHistogramArray_TF2,true);
   ArraySetAsSeries(ExtHistogramColorArray_TF2,true);

//--- calculate at which bar to start drawing indicators
   PeriodSeconds_TF1=PeriodSeconds();
   PeriodSeconds_TF2=PeriodSeconds(InpTimeFrame_2);

   if(PeriodSeconds_TF1<PeriodSeconds_TF2)
      PeriodRatio=PeriodSeconds_TF2/PeriodSeconds_TF1;

//--- name for indicator
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD("+string(InpFastEMA)+","+string(InpSlowEMA)+","+string(InpSignalMA)+")");

//--- get Macd handle
   ExtMacdHandle_TF2=iCustom(NULL,InpTimeFrame_2,InpIndicator_TF1,InpFastEMA,InpSlowEMA,InpSignalMA,InpAppliedSignalMA,InpUseMultiColor,InpAppliedPrice);
   if(ExtMacdHandle_TF2==INVALID_HANDLE)
     {
      Print("Error creating MACD_Histogram_MC indicator");
      return(1);
     }
//--- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- set arrays as series, most recent entry at index [0]
   ArraySetAsSeries(Time,true);

//--- check for data
   int bars_TF2=Bars(NULL,InpTimeFrame_2);
   if(bars_TF2<InpSlowEMA+InpSignalMA)
      return(0);

//--- not all data may be calculated
   int calculated_TF2;

   calculated_TF2=BarsCalculated(ExtMacdHandle_TF2);
   if(calculated_TF2<bars_TF2)
     {
      if(ShowErrorMessages) Print("Not all data of ExtMacdHandle_TF2 has been calculated (",calculated_TF2," bars). Error",GetLastError());
      return(0);
     }

//--- set limit for which bars need to be (re)calculated
   int limit;
   if(prev_calculated==0 || prev_calculated<0 || prev_calculated>rates_total)
      limit=rates_total-1;
   else
      limit=rates_total-prev_calculated;

//--- create variable required to convert between TF1 and TF2
   datetime convertedTime;

//--- loop through TF1 bars to set buffer TF1 values
   for(int i=limit;i>=0;i--)
     {
      //--- convert time TF1 to nearest earlier time TF2 for a bar opened on TF2 which is to close during the current TF1 bar
      if(InpAppliedPrice!=PRICE_OPEN)
         convertedTime=Time[i]+PeriodSeconds_TF1-PeriodSeconds_TF2;
      //--- convert time TF1 to nearest earlier time TF2 for a bar opened on TF2 at the same time or before the current TF1 bar
      if(InpAppliedPrice==PRICE_OPEN)
         convertedTime=Time[i];

      //--- check if TF2 data is available at convertedTime
      datetime tempTimeArray_TF2[];
      CopyTime(NULL,InpTimeFrame_2,calculated_TF2-1,1,tempTimeArray_TF2);
      //--- no TF2 data available
      if(convertedTime<tempTimeArray_TF2[0])
        {
         ExtMacdBuffer_TF2[i]=EMPTY_VALUE;
         ExtSignalBuffer_TF2[i]=EMPTY_VALUE;
         ExtHistogramBuffer_TF2[i]=EMPTY_VALUE;
         ExtHistogramColorBuffer_TF2[i]=EMPTY_VALUE;
         continue;
        }

      //--- get macd buffer values of TF2
      if(CopyBuffer(ExtMacdHandle_TF2,0,convertedTime,1,ExtMacdArray_TF2)<=0)
        {
         if(ShowErrorMessages) Print("Getting MACD TF2 failed! Error",GetLastError());
         return(0);
        }
      //--- set macd TF2 buffer on TF1
      else
         ExtMacdBuffer_TF2[i]=ExtMacdArray_TF2[0];

      //--- get signal buffer values of TF2
      if(CopyBuffer(ExtMacdHandle_TF2,1,convertedTime,1,ExtSignalArray_TF2)<=0)
        {
         if(ShowErrorMessages) Print("Getting Signal TF2 failed! Error",GetLastError());
         return(0);
        }
      //--- set signal TF2 buffer on TF1
      else
         ExtSignalBuffer_TF2[i]=ExtSignalArray_TF2[0];

      //--- get histogram buffer values of TF2
      if(CopyBuffer(ExtMacdHandle_TF2,2,convertedTime,1,ExtHistogramArray_TF2)<=0)
        {
         if(ShowErrorMessages) Print("Getting Histogram TF2 failed! Error",GetLastError());
         return(0);
        }
      //--- set histogram TF2 buffer on TF1
      else
         ExtHistogramBuffer_TF2[i]=ExtHistogramArray_TF2[0];

      //--- get histogram color buffer values of TF2
      if(CopyBuffer(ExtMacdHandle_TF2,3,convertedTime,1,ExtHistogramColorArray_TF2)<=0)
        {
         if(ShowErrorMessages) Print("Getting Histogram Color TF2 failed! Error",GetLastError());
         return(0);
        }
      //--- set histogram color TF2 buffer on TF1
      else
         ExtHistogramColorBuffer_TF2[i]=ExtHistogramColorArray_TF2[0];
     }

//--- return value of rates_total, will be used as prev_calculated in next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
