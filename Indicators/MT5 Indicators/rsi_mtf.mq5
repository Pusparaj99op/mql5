//+------------------------------------------------------------------+
//|                                                      RSI_MTF.mq5 |
//|                                           Copyright © 2010, AK20 |
//|                                             traderak20@gmail.com |
//+------------------------------------------------------------------+
#property copyright   "2010, traderak20@gmail.com"
#property description "RSI, Multi-timeframe"
/*--------------------------------------------------------------------
2010 09 26: v03   Improved display of values on timeframes smaller than the chart's timeframe
                     Set buffers to EMPTY_VALUE instead of 0 after: if(convertedTime<tempTimeArray_TF2[0])
                  Code optimization
                     Removed PLOT_DRAW_BEGIN from OnInit() - inherited from single time frame indicator
                     Moved ArraySetAsSeries of buffers and arrays into OnInit()

2010 09 06: v02   Fixed bug with Time[] array which caused indicator to be drawn incorrectly

2010 08 25: v01   Indicator first published
----------------------------------------------------------------------*/
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
//--- indicator plots
#property indicator_type1   DRAW_LINE
#property indicator_color1  DodgerBlue
#property indicator_width1  1
#property indicator_label1  "RSI_TF2"
//--- input parameters
input ENUM_TIMEFRAMES      InpTimeFrame_2=PERIOD_H1;      // Timeframe 2 (TF2) period
input int                  InpPeriodRSI=14;               // RSI period
input ENUM_APPLIED_PRICE   InpAppliedPrice=PRICE_CLOSE;   // Applied price
//--- indicator buffers
double                     ExtRsiBuffer_TF2[];
//--- arrays TF2 - to retrieve TF 2 values of buffers and/or timeseries
double                     ExtRsiArray_TF2[];       // intermediate array to hold TF2 RSI buffer values
//--- variables
int                        PeriodRatio=1;           // ratio between timeframe 1 (TF1) and timeframe 2 (TF2)
int                        PeriodSeconds_TF1;       // TF1 period in seconds
int                        PeriodSeconds_TF2;       // TF2 period in seconds
//--- indicator handles TF2
int                        ExtRsiHandle_TF2;        // RSI handle TF2
//--- turn on/off error messages
bool                       ShowErrorMessages=true;  // turn on/off error messages for debugging
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtRsiBuffer_TF2,INDICATOR_DATA);

//--- set buffers as series, most recent entry at index [0]
   ArraySetAsSeries(ExtRsiBuffer_TF2,true);
//--- set arrays as series, most recent entry at index [0]
   ArraySetAsSeries(ExtRsiArray_TF2,true);

//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);

//--- set levels
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,30);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,70);

//--- set maximum and minimum for subwindow 
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,100);

//--- calculate at which bar to start drawing indicators
   PeriodSeconds_TF1=PeriodSeconds();
   PeriodSeconds_TF2=PeriodSeconds(InpTimeFrame_2);

   if(PeriodSeconds_TF1<PeriodSeconds_TF2)
      PeriodRatio=PeriodSeconds_TF2/PeriodSeconds_TF1;

//--- name for indicator
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI("+string(InpPeriodRSI)+")");

//--- get RSI handle
   ExtRsiHandle_TF2=iRSI(NULL,InpTimeFrame_2,InpPeriodRSI,InpAppliedPrice);

//--- initialization done
  }
//+------------------------------------------------------------------+
//| RSI                                                              |
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
   if(bars_TF2<InpPeriodRSI)
      return(0);

//--- not all data may be calculated
   int calculated_TF2;

   calculated_TF2=BarsCalculated(ExtRsiHandle_TF2);
   if(calculated_TF2<bars_TF2)
     {
      if(ShowErrorMessages) Print("Not all data of ExtRsiHandle_TF2 has been calculated (",calculated_TF2," bars). Error",GetLastError());
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
      //--- use this for calculations with PRICE_CLOSE, PRICE_HIGH, PRICE_LOW, PRICE_MEDIAN, PRICE_TYPICAL, PRICE_WEIGHTED
      if(InpAppliedPrice!=PRICE_OPEN)
         convertedTime=Time[i]+PeriodSeconds_TF1-PeriodSeconds_TF2;
      //--- convert time TF1 to nearest earlier time TF2 for a bar opened on TF2 at the same time or before the current TF1 bar
      //--- use this for calculations with PRICE_OPEN
      if(InpAppliedPrice==PRICE_OPEN)
         convertedTime=Time[i];

      //--- check if TF2 data is available at convertedTime
      datetime tempTimeArray_TF2[];
      CopyTime(NULL,InpTimeFrame_2,calculated_TF2-1,1,tempTimeArray_TF2);
      //--- no TF2 data available
      if(convertedTime<tempTimeArray_TF2[0])
        {
         ExtRsiBuffer_TF2[i]=EMPTY_VALUE;
         continue;
        }

      //--- get rsi buffer values of TF2
      if(CopyBuffer(ExtRsiHandle_TF2,0,convertedTime,1,ExtRsiArray_TF2)<=0)
        {
         if(ShowErrorMessages) Print("Getting RSI TF2 failed! Error",GetLastError());
         return(0);
        }
      //--- set rsi TF2 buffer on TF1
      else
         ExtRsiBuffer_TF2[i]=ExtRsiArray_TF2[0];
     }

//--- return value of rates_total, will be used as prev_calculated in next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
