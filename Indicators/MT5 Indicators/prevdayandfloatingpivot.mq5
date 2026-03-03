//+------------------------------------------------------------------+
//|                                      PrevDayAndFloatingPivot.mq4 |
//|                             Copyright © 2006, mbkennel@gmail.com |
//|                                        http://www.metatrader.org |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, mbkennel@gmail.com"
#property link      "http://www.metatrader.org"
//--- indicator version number
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- two buffers are used for the indicator calculation and drawing
#property indicator_buffers 2
//--- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Cycle indicator drawing parameters          |
//+----------------------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//--- DeepPink color is used as the color of the bullish line of the indicator
#property indicator_color1  clrDeepPink
//--- line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- thickness of line of the indicator 1 is equal to 1
#property indicator_width1  1
//--- displaying of the bullish label of the indicator
#property indicator_label1  "Previous Day Pivot"
//+----------------------------------------------+
//|  Trigger indicator drawing parameters        |
//+----------------------------------------------+
//--- drawing the indicator 2 as a line
#property indicator_type2   DRAW_LINE
//--- BlueViolet color is used for the indicator bearish line
#property indicator_color2  clrBlueViolet
//--- the indicator 2 line is a continuous curve
#property indicator_style2  STYLE_SOLID
//--- indicator 2 line width is equal to 1
#property indicator_width2  1
//--- displaying of the bearish label of the indicator
#property indicator_label2  "Floating current pivot"
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input int Shift=0; // horizontal shift of the indicator in bars 
//+----------------------------------------------+
//--- declaration of dynamic arrays that will further be used as indicator buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
//--- declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+
//| TodaysHighestLowest() function                                   |
//+------------------------------------------------------------------+
int TodaysHighestLowest(const datetime &Time[],const double &High[],const double &Low[],int shift,double &H,double &L)
  {
//--- return the higest and lowest so far today.
   static int Max=0;
   static bool start=true;
   
   if(start)
     {
      Max=PeriodSeconds(PERIOD_D1)/PeriodSeconds(PERIOD_CURRENT);
      start=false;
     }

   int tbs=TodaysBarShift(Time,shift);
   if(tbs<0) return(-1);

   datetime iTime[1];
   if(CopyTime(NULL,PERIOD_D1,tbs,1,iTime)<=0) return(-1);
//---  
   H=High[shift];
   L=Low[shift];
//---  
   int j=shift+1;
   while(Time[j]>=iTime[0])
     {
      double Ht=High[j];
      double Lt=Low[j];

      H=MathMax(H,Ht);
      L=MathMin(L,Lt);
      j++;

      if(j-shift>Max)
        {
         Print(__FUNCTION__+"(): Shit!");
         break;
        }
     }
//---
   return(+1);
  }
//+------------------------------------------------------------------+
//| PreviousNonSundayBarShift() function                             |
//+------------------------------------------------------------------+
int PreviousNonSundayBarShift(const datetime &Time[],int shift)
  {
//---
   int tbs=TodaysBarShift(Time,shift);
   if(tbs<0) return(-1);
   int ybs=tbs+1;
   datetime iTime[1];
   if(CopyTime(NULL,PERIOD_D1,ybs,1,iTime)<=0) return(-1);

   MqlDateTime tm;
   TimeToStruct(iTime[0],tm);

   if(tm.day_of_week==SUNDAY) ybs++; // we found a Sunday bar so screw it. 
//---
   return(ybs);
  }
//+------------------------------------------------------------------+
//| TodaysBarShift() function                                        |
//+------------------------------------------------------------------+
int TodaysBarShift(const datetime &Time[],int shift)
  {
//--- return the bar shift for today
// i.e. not today.
   int idaybarshift=iBarShift(NULL,PERIOD_D1,Time[shift]);
   if(idaybarshift<0) return(-1);
   datetime iTime[1];
   if(CopyTime(NULL,PERIOD_D1,idaybarshift,1,iTime)<=0) return(-1);

   if(iTime[0]>Time[shift]) idaybarshift++;
//---   
   return(idaybarshift);
  }
//+------------------------------------------------------------------+
//| iBarShift() function                                             |
//+------------------------------------------------------------------+
int iBarShift(string symbol,ENUM_TIMEFRAMES timeframe,datetime time)
  {
//---
   if(time<0) return(-1);
   datetime Arr[],time1;

   time1=(datetime)SeriesInfoInteger(symbol,timeframe,SERIES_LASTBAR_DATE);

   if(CopyTime(symbol,timeframe,time,time1,Arr)>0)
     {
      int size=ArraySize(Arr);
      return(size-1);
     }
   else return(-1);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(PeriodSeconds(PERIOD_D1)/PeriodSeconds(PERIOD_CURRENT));
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtMapBuffer1,INDICATOR_DATA);
//--- shifting indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- shifting the starting point for drawing indicator 1 by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- indexing elements in the buffer as time series
   ArraySetAsSeries(ExtMapBuffer1,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,ExtMapBuffer2,INDICATOR_DATA);
//--- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//--- shifting the starting point for drawing indicator 2 by min_rates_total+1
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- indexing elements in the buffer as time series
   ArraySetAsSeries(ExtMapBuffer2,true);
//--- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"PrevDayAndFloatingPivot(",Shift,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // amount of history in bars at the current tick
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
//--- checking the number of bars to be enough for calculation
   if(rates_total<min_rates_total) return(0);
//--- declaration of local variables 
   int limit,bar;
   double iHigh[1],iLow[1],iClose[1],iOpen[1];
//--- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars
//--- indexing elements in arrays as timeseries  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- get the prev days pivot. Today's pivot.
      int ybs=PreviousNonSundayBarShift(time,bar);
      if(ybs<0) return(prev_calculated);
//---
      int tdbar=TodaysBarShift(time,bar);
      if(tdbar<0) return(prev_calculated);
      //---
      if(CopyOpen(NULL,PERIOD_D1,ybs,1,iOpen)<=0) return(prev_calculated);
      if(CopyLow(NULL,PERIOD_D1,ybs,1,iLow)<=0) return(prev_calculated);
      if(CopyHigh(NULL,PERIOD_D1,ybs,1,iHigh)<=0) return(prev_calculated);
      if(CopyClose(NULL,PERIOD_D1,tdbar,1,iClose)<=0) return(prev_calculated);
      //--- Prev day's pivot:
      double p=(iHigh[0]+iLow[0]+iClose[0]+iOpen[0])*0.25;
      double TH,TL;
//---
      if(TodaysHighestLowest(time,high,low,bar,TH,TL)<0) return(prev_calculated);
      double flp=(TH+TL+close[bar])*0.33333;
      ExtMapBuffer1[bar]=p;
      ExtMapBuffer2[bar]=flp;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
