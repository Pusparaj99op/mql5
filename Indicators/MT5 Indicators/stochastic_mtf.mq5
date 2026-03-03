//+------------------------------------------------------------------+
//|                                               Stochastic_MTF.mq5 |
//|                                           Copyright © 2010, AK20 |
//|                                             traderak20@gmail.com |
//+------------------------------------------------------------------+
#property copyright   "2010, traderak20@gmail.com"
#property description "Stochastic, Multi-timeframe"
/*--------------------------------------------------------------------
2010 09 26: v04   Improved display of values on timeframes smaller than the chart's timeframe
                     Set buffers to EMPTY_VALUE instead of 0 after: if(convertedTime<tempTimeArray_TF2[0])
                  Code optimization
                     Removed PLOT_DRAW_BEGIN from OnInit() - inherited from single time frame indicator
                     Moved ArraySetAsSeries of buffers and arrays into OnInit()

2010 09 06: v03   Fixed bug with Time[] array which caused indicator to be drawn incorrectly

2010 08 25: v02   Indicator first published
----------------------------------------------------------------------*/

#property indicator_separate_window

#property indicator_buffers 2
#property indicator_plots   2

//--- indicator plots
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_color2  Red
#property indicator_width1  1
#property indicator_width2  1
#property indicator_label1  "Main_TF2"
#property indicator_label2  "Signal_TF2"

//--- input parameters
input ENUM_TIMEFRAMES      InpTimeFrame_2=PERIOD_H1;                    // Timeframe 2 (TF2) period
input int                  InpKPeriod=5;                                // K period
input int                  InpDPeriod=3;                                // D period
input int                  InpSlowing=3;                                // Slowing
input ENUM_MA_METHOD       InpAppliedMA=MODE_SMA;                       // Applied MA method for signal line
input ENUM_STO_PRICE       InpAppliedPrice=STO_LOWHIGH;                 // Applied price

//--- indicator buffers
double                     ExtMainBuffer_TF2[];
double                     ExtSignalBuffer_TF2[];

//--- arrays TF2 - to retrieve TF 2 values of buffers and/or timeseries
double                     ExtMainArray_TF2[];           // intermediate array to hold TF2 main buffer values
double                     ExtSignalArray_TF2[];         // intermediate array to hold TF2 signal buffer values

//--- variables
int                        PeriodRatio=1;                // ratio between timeframe 1 (TF1) and timeframe 2 (TF2)
int                        PeriodSeconds_TF1;            // TF1 period in seconds
int                        PeriodSeconds_TF2;            // TF2 period in seconds

//--- indicator handles TF2
int                        ExtStochasticHandle_TF2;      // stochastic handle TF2

//--- turn on/off error messages
bool                       ShowErrorMessages=true;       // turn on/off error messages for debugging
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMainBuffer_TF2,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer_TF2,INDICATOR_DATA);

//--- set buffers as series, most recent entry at index [0]
   ArraySetAsSeries(ExtMainBuffer_TF2,true);
   ArraySetAsSeries(ExtSignalBuffer_TF2,true);
//--- set arrays as series, most recent entry at index [0]
   ArraySetAsSeries(ExtMainArray_TF2,true);
   ArraySetAsSeries(ExtSignalArray_TF2,true);

//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);

//--- set levels
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,20);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,80);

//--- set maximum and minimum for subwindow 
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,100);

//--- calculate at which bar to start drawing indicators
   PeriodSeconds_TF1=PeriodSeconds();
   PeriodSeconds_TF2=PeriodSeconds(InpTimeFrame_2);

   if(PeriodSeconds_TF1<PeriodSeconds_TF2)
      PeriodRatio=PeriodSeconds_TF2/PeriodSeconds_TF1;

//--- name for indicator
   IndicatorSetString(INDICATOR_SHORTNAME,"Stoch("+(string)InpKPeriod+","+(string)InpDPeriod+","+(string)InpSlowing+")");

//--- get Stochastic handle
   ExtStochasticHandle_TF2=iStochastic(NULL,InpTimeFrame_2,InpKPeriod,InpDPeriod,InpSlowing,InpAppliedMA,InpAppliedPrice);

//--- initialization done
  }
//+------------------------------------------------------------------+
//| Stochastic Oscillator                                            |
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
   if(bars_TF2<InpKPeriod+InpDPeriod+InpSlowing)
      return(0);

//--- not all data may be calculated
   int calculated_TF2;

   calculated_TF2=BarsCalculated(ExtStochasticHandle_TF2);
   if(calculated_TF2<bars_TF2)
     {
      if(ShowErrorMessages) Print("Not all data of ExtStochasticHandle_TF2 has been calculated (",calculated_TF2," bars). Error",GetLastError());
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
      convertedTime=Time[i]+PeriodSeconds_TF1-PeriodSeconds_TF2;

      //--- check if TF2 data is available at convertedTime
      datetime tempTimeArray_TF2[];
      CopyTime(NULL,InpTimeFrame_2,calculated_TF2-1,1,tempTimeArray_TF2);
      //--- no TF2 data available
      if(convertedTime<tempTimeArray_TF2[0])
        {
         ExtMainBuffer_TF2[i]=EMPTY_VALUE;
         ExtSignalBuffer_TF2[i]=EMPTY_VALUE;
         continue;
        }

      //--- get main buffer values of TF2
      if(CopyBuffer(ExtStochasticHandle_TF2,0,convertedTime,1,ExtMainArray_TF2)<=0)
        {
         if(ShowErrorMessages) Print("Getting Stochastic TF2 failed! Error",GetLastError());
         return(0);
        }
      //--- set main TF2 buffer on TF1
      else
         ExtMainBuffer_TF2[i]=ExtMainArray_TF2[0];

      //--- get signal buffer values of TF2
      if(CopyBuffer(ExtStochasticHandle_TF2,1,convertedTime,1,ExtSignalArray_TF2)<=0)
        {
         if(ShowErrorMessages) Print("Getting Signal TF2 failed! Error",GetLastError());
         return(0);
        }
      //--- set signal TF2 buffer on TF1
      else
         ExtSignalBuffer_TF2[i]=ExtSignalArray_TF2[0];
     }

//--- return value of rates_total, will be used as prev_calculated in next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
