//+------------------------------------------------------------------+
//|                                                   iUniMA_MTF.mq5 |
//|                                           Copyright © 2010, AK20 |
//|                                             traderak20@gmail.com |
//|                                                                  |
//|                                                        Based on: |
//|                                            iUniMA.mq5 by Integer |
//|                                        MetaQuotes Software Corp. |
//|                                                 http://dmffx.com |
//+------------------------------------------------------------------+
#property copyright   "2010, traderak20@gmail.com"
#property description "iUniMA, Multi-timeframe of version the Universal Moving Average"
#property version     "V03"

/*--------------------------------------------------------------------
2010 09 26: v03   Improved display of values on timeframes smaller than the chart's timeframe
                     Set buffers to EMPTY_VALUE instead of 0 after: if(convertedTime<tempTimeArray_TF2[0])
                  Code optimization
                     Removed PLOT_DRAW_BEGIN from OnInit() - inherited from single time frame indicator
                     Moved ArraySetAsSeries of buffers and arrays into OnInit()
----------------------------------------------------------------------*/

#property indicator_chart_window

#property indicator_buffers 1
#property indicator_plots   1

//--- indicator plots
#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
#property indicator_width1  1
#property indicator_label1  "MA_TF2"
#property indicator_style1  STYLE_SOLID
//--- enum variables
enum maswitch
  {
   Simple=MODE_SMA,
   Exponential=MODE_EMA,
   Smoothed=MODE_SMMA,
   LinearWeighted=MODE_LWMA,
   AMA=IND_AMA,
   DEMA=IND_DEMA,
   FRAMA=IND_FRAMA,
   TEMA=IND_TEMA,
   VIDYA=IND_VIDYA
  };

//--- input parameters
input ENUM_TIMEFRAMES      InpTimeFrame_2=PERIOD_H1;                          // Timeframe 2 (TF2) period
input maswitch             InpAppliedMA=MODE_SMA;                             // Applied MA method for signal line
input int                  InpMaPeriod=14;                                    // MA Period
input int                  InpAmaFast=2;                                      // Fast AMA period
input int                  InpAmaSlow=30;                                     // Slow AMA period
input int                  InpCmoPeriod=9;                                    // CMO period for VIDYA
input ENUM_APPLIED_PRICE   InpAppliedPrice=PRICE_CLOSE;                       // Applied price

//--- indicator buffers
double                     ExtMaBuffer_TF2[];

//--- arrays TF2 - to retrieve TF 2 values of buffers and/or timeseries
double                     ExtMaArray_TF2[];             // intermediate array to hold TF2 ma buffer values

//--- variables
int                        PeriodRatio=1;                // ratio between timeframe 1 (TF1) and timeframe 2 (TF2)
int                        PeriodSeconds_TF1;            // TF1 period in seconds
int                        PeriodSeconds_TF2;            // TF2 period in seconds

//--- indicator handles TF2
int                        ExtMaHandle_TF2;              // ma handle TF2

//--- turn on/off error messages
bool                       ShowErrorMessages=true;       // turn on/off error messages for debugging
//+------------------------------------------------------------------+
//| Abbreviate applied price to single character                     |
//+------------------------------------------------------------------+
string fNamePriceShort(ENUM_APPLIED_PRICE aPrice)
  {
   switch(aPrice)
     {
      case PRICE_CLOSE:
         return("C");
      case PRICE_HIGH:
         return("H");
      case PRICE_LOW:
         return("L");
      case PRICE_MEDIAN:
         return("M");
      case PRICE_OPEN:
         return("O");
      case PRICE_TYPICAL:
         return("T");
      case PRICE_WEIGHTED:
         return("W");
      default:
         return("");
     }
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMaBuffer_TF2,INDICATOR_DATA);

//--- set buffers as series, most recent entry at index [0]
   ArraySetAsSeries(ExtMaBuffer_TF2,true);
//--- set arrays as series, most recent entry at index [0]
   ArraySetAsSeries(ExtMaArray_TF2,true);

//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,Digits()-1);

//--- calculate at which bar to start drawing indicators
   PeriodSeconds_TF1=PeriodSeconds();
   PeriodSeconds_TF2=PeriodSeconds(InpTimeFrame_2);

   if(PeriodSeconds_TF1<PeriodSeconds_TF2)
      PeriodRatio=PeriodSeconds_TF2/PeriodSeconds_TF1;

//--- name for indicator
   IndicatorSetString(INDICATOR_SHORTNAME,"MA("+string(InpMaPeriod)+")");

//--- name for plots
   string Label;

   switch(InpAppliedMA)
     {
      case Simple:
         Label="SMA("+string(InpMaPeriod)+","+fNamePriceShort(InpAppliedPrice)+")";
         break;
      case Exponential:
         Label="EMA("+string(InpMaPeriod)+","+fNamePriceShort(InpAppliedPrice)+")";
         break;
      case Smoothed:
         Label="SMMA("+string(InpMaPeriod)+","+fNamePriceShort(InpAppliedPrice)+")";
         break;
      case LinearWeighted:
         Label="LWMA("+string(InpMaPeriod)+","+fNamePriceShort(InpAppliedPrice)+")";
         break;
      case AMA:
         Label="AMA("+string(InpMaPeriod)+","+string(InpAmaFast)+","+string(InpAmaSlow)+","+fNamePriceShort(InpAppliedPrice)+")";
         break;
      case DEMA:
         Label="DEMA("+string(InpMaPeriod)+","+fNamePriceShort(InpAppliedPrice)+")";
         break;
      case FRAMA:
         Label="FRAM("+string(InpMaPeriod)+","+fNamePriceShort(InpAppliedPrice)+")";
         break;
      case TEMA:
         Label="TEMA("+string(InpMaPeriod)+","+fNamePriceShort(InpAppliedPrice)+")";
         break;
      case VIDYA:
         Label="VIDYA("+string(InpMaPeriod)+","+string(InpCmoPeriod)+","+fNamePriceShort(InpAppliedPrice)+")";
         break;
     }

   PlotIndexSetString(0,PLOT_LABEL,Label);

//--- get MA handle
   switch(InpAppliedMA)
     {
      case Simple:
         ExtMaHandle_TF2=iMA(NULL,InpTimeFrame_2,InpMaPeriod,0,MODE_SMA,InpAppliedPrice);
         break;
      case Exponential:
         ExtMaHandle_TF2=iMA(NULL,InpTimeFrame_2,InpMaPeriod,0,MODE_EMA,InpAppliedPrice);
         break;
      case Smoothed:
         ExtMaHandle_TF2=iMA(NULL,InpTimeFrame_2,InpMaPeriod,0,MODE_SMMA,InpAppliedPrice);
         break;
      case LinearWeighted:
         ExtMaHandle_TF2=iMA(NULL,InpTimeFrame_2,InpMaPeriod,0,MODE_LWMA,InpAppliedPrice);
         break;
      case AMA:
         ExtMaHandle_TF2=iAMA(NULL,InpTimeFrame_2,InpMaPeriod,InpAmaFast,InpAmaSlow,0,InpAppliedPrice);
         break;
      case DEMA:
         ExtMaHandle_TF2=iDEMA(NULL,InpTimeFrame_2,InpMaPeriod,0,InpAppliedPrice);
         break;
      case FRAMA:
         ExtMaHandle_TF2=iFrAMA(NULL,InpTimeFrame_2,InpMaPeriod,0,InpAppliedPrice);
         break;
      case TEMA:
         ExtMaHandle_TF2=iTEMA(NULL,InpTimeFrame_2,InpMaPeriod,0,InpAppliedPrice);
         break;
      case VIDYA:
         ExtMaHandle_TF2=iVIDyA(NULL,InpTimeFrame_2,InpCmoPeriod,InpMaPeriod,0,InpAppliedPrice);
         break;
     }

//--- initialization done
  }
//+------------------------------------------------------------------+
//| Universal Moving Average                                         |
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
   if(bars_TF2<InpMaPeriod)
      return(0);

//--- not all data may be calculated
   int calculated_TF2;

   calculated_TF2=BarsCalculated(ExtMaHandle_TF2);
   if(calculated_TF2<bars_TF2)
     {
      if(ShowErrorMessages) Print("Not all data of ExtMaHandle_TF2 has been calculated (",calculated_TF2," bars). Error",GetLastError());
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
         ExtMaBuffer_TF2[i]=EMPTY_VALUE;
         continue;
        }

      //--- get ma buffer values of TF2
      if(CopyBuffer(ExtMaHandle_TF2,0,convertedTime,1,ExtMaArray_TF2)<=0)
        {
         if(ShowErrorMessages) Print("Getting MA TF2 failed! Error",GetLastError());
         return(0);
        }
      //--- set ma TF2 buffer on TF1
      else
         ExtMaBuffer_TF2[i]=ExtMaArray_TF2[0];
     }

//--- return value of rates_total, will be used as prev_calculated in next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
