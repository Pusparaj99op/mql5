//+------------------------------------------------------------------+ 
//|                                     TSD_PP_MACD_FORCE_Ind_v1.mq5 | 
//|                                    Copyright © 2005, Bob O'Brien | 
//|                                                                  | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Bob O'Brien"
#property link ""
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers is 2
#property indicator_buffers 2 
//--- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET 0                                   // A constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME "TSD_PP_MACD_FORCE_Ind_v1" // A constant for the indicator name
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//--- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_COLOR_HISTOGRAM
//---- the following colors are used as the indicator colors
#property indicator_color1  clrRed,clrGray,clrLime
//--- indicator 1 line width is equal to 5
#property indicator_width1  5
//---- indicator bullish label display
#property indicator_label1  INDICATOR_NAME
//+----------------------------------------------+
//|  Indicator window borders parameters         |
//+----------------------------------------------+
#property indicator_minimum -0.3
#property indicator_maximum +1.8
//+-------------------------------------+
//| Indicator input parameters          |
//+-------------------------------------+ 
input uint Force=2;
input ENUM_APPLIED_VOLUME Applied_Volume=VOLUME_TICK; // Volume type for calculation
input uint FastMA=12;
input uint SlowMA=26;
input uint Signal=9;
input int  Shift=0;                                   // Horizontal shift of the indicator in bars
//+-------------------------------------+
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double IndBuffer[],ColorIndBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int MACD_Handle,Fr_Handle;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- Checking the correctness of the indicator timeframe
   if(Period()>=PERIOD_D1)
     {
      Print("Chart period for indicator "+INDICATOR_NAME+" cannot be greater than PERIOD_D1!");
      return(INIT_FAILED);
     }
//--- initialization of variables 
   int min_rates_1=int(MathMax(FastMA,SlowMA)+Signal);
   int min_rates_2=int(Force*PeriodSeconds(PERIOD_D1)/PeriodSeconds(PERIOD_CURRENT));
   int min_rates_3=int(PeriodSeconds(PERIOD_W1)/PeriodSeconds(PERIOD_CURRENT));
   min_rates_total=int(MathMax(min_rates_1,min_rates_2)+min_rates_3);
//--- getting the handle of iMACD
   MACD_Handle=iMACD(NULL,0,FastMA,SlowMA,Signal,PRICE_CLOSE);
   if(MACD_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of iMACD");
      return(INIT_FAILED);
     }
//--- getting the handle of the iForce indicator
   Fr_Handle=iForce(NULL,PERIOD_D1,Force,MODE_EMA,Applied_Volume);
   if(Fr_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of iForce");
      return(INIT_FAILED);
     }
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//--- set dynamic array as a color index buffer   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,INDICATOR_NAME);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total || BarsCalculated(MACD_Handle)<rates_total) return(RESET);
//--- declarations of local variables 
   double Force_[1],MACD[2];
   int limit,bar,nWeek,nDay;
   datetime dSun,iTimeW[1],iTime[1];
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
     }
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars 
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(time,true);
//--- copy newly appeared data in the array
   if(CopyTime(Symbol(),PERIOD_W1,0,1,iTimeW)<=0) return(RESET);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      MqlDateTime tm;
      TimeToStruct(time[bar],tm);
      dSun=StringToTime(TimeToString(time[bar]-tm.day_of_week*86400,TIME_DATE));
      nWeek=int(((iTimeW[0]-dSun)/86400)/7);
      //--- copy newly appeared data in the array
      if(CopyBuffer(MACD_Handle,MAIN_LINE,nWeek+1,2,MACD)<=0) return(RESET);

      if(Period()==PERIOD_D1) nDay=bar;
      else
        {
         int nWeek5=nWeek*5; //number of days since 
         dSun=StringToTime(TimeToString(time[bar],TIME_DATE));
         //--- copy newly appeared data in the array
         if(CopyTime(Symbol(),PERIOD_D1,nWeek5,1,iTime)<=0) return(RESET);
         int i=int(MathAbs(iTime[0]-dSun)/86400);
         nDay=MathMax(nWeek5-i,0);
        }
      //--- copy newly appeared data in the array
      if(CopyBuffer(Fr_Handle,MAIN_LINE,nDay+1,1,Force_)<=0) return(RESET);
      IndBuffer[bar]=1.0;
      ColorIndBuffer[bar]=1;
      if(MACD[1] > MACD[0] && Force_[0] > 0) ColorIndBuffer[bar]=2;
      if(MACD[1] < MACD[0] && Force_[0] < 0) ColorIndBuffer[bar]=0;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
