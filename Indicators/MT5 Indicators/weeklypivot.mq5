//+------------------------------------------------------------------+
//|                                                  WeeklyPivot.mq5 | 
//|                                            Copyright © 2007, XXX | 
//|                                                                  | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, XXX"
#property link "WeeklyPivot"
#property description "WeeklyPivot"
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers
#property indicator_buffers 7 
//---- only one plot is used
#property indicator_plots   7
//+--------------------------------------------+
//|  Declaration of constants                  |
//+--------------------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
//+--------------------------------------------+
//|  Levels indicator drawing parameters       |
//+--------------------------------------------+
//---- drawing the levels as
#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
#property indicator_type4   DRAW_ARROW
#property indicator_type5   DRAW_ARROW
#property indicator_type6   DRAW_ARROW
#property indicator_type7   DRAW_ARROW
//---- selection of levels colors
#property indicator_color1  clrPurple
#property indicator_color2  clrRed
#property indicator_color3  clrBlue
#property indicator_color4  clrBlueViolet
#property indicator_color5  clrBlue
#property indicator_color6  clrRed
#property indicator_color7  clrPurple
//---- levels width is equal to
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  3
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
//---- display levels labels
#property indicator_label1  "Res3"
#property indicator_label2  "Res2"
#property indicator_label3  "Res1"
#property indicator_label4  "WeeklyPivot"
#property indicator_label5  "Sup1"
#property indicator_label6  "Sup2"
#property indicator_label7  "Sup3"

//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input double Deviation = 1.0; // deviationÿ
input int    Shift=0;         // horizontal shift of the indicator in bars
//+-----------------------------------+
//---- declaration of dynamic arrays that will further be 
//---- will be used as Bollinger Bands indicator buffers
double ExtLineBuffer0[],ExtLineBuffer1[],ExtLineBuffer2[],ExtLineBuffer3[],ExtLineBuffer4[],ExtLineBuffer5[],ExtLineBuffer6[];

//---- Declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+   
//| WeeklyPivot indicator initialization function                    | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=int(PeriodSeconds(PERIOD_W1)/PeriodSeconds(PERIOD_CURRENT)+1);

//---- setting dynamic arrays as indicator buffers
   SetIndexBuffer(0,ExtLineBuffer0,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLineBuffer2,INDICATOR_DATA);
   SetIndexBuffer(3,ExtLineBuffer3,INDICATOR_DATA);
   SetIndexBuffer(4,ExtLineBuffer4,INDICATOR_DATA);
   SetIndexBuffer(5,ExtLineBuffer5,INDICATOR_DATA);
   SetIndexBuffer(6,ExtLineBuffer6,INDICATOR_DATA);

//---- set the position, from which the levels drawing starts
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,min_rates_total);

//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- indexing buffer elements as time series
   ArraySetAsSeries(ExtLineBuffer0,true);
   ArraySetAsSeries(ExtLineBuffer1,true);
   ArraySetAsSeries(ExtLineBuffer2,true);
   ArraySetAsSeries(ExtLineBuffer3,true);
   ArraySetAsSeries(ExtLineBuffer4,true);
   ArraySetAsSeries(ExtLineBuffer5,true);
   ArraySetAsSeries(ExtLineBuffer6,true);

//---- shifting the indicators horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(5,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(6,PLOT_SHIFT,Shift);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"WeeklyPivot");

//--- determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- end of initialization
  }
//+------------------------------------------------------------------+ 
//| WeeklyPivot iteration function                                   | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- checking the number of bars to be enough for calculation
   if(rates_total<min_rates_total) return(RESET);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(open,true);

//---- declaration of local variables 
   int limit,bar;
   datetime wTime[1];
   double this_week_open,last_week_close;
   static double last_week_high,last_week_low,P,S1,R1,S2,R2,S3,R3;

//---- calculations of the necessary amount of data to be copied and
//the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
      
      last_week_low=low[limit+1];
      last_week_high=high[limit+1];
      P=EMPTY_VALUE;
      R1=EMPTY_VALUE;
      S1=EMPTY_VALUE;
      R2=EMPTY_VALUE;
      S2=EMPTY_VALUE;
      R3=EMPTY_VALUE;
      S3=EMPTY_VALUE;
     }
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars 

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- copy newly appeared data in the array
      if(CopyTime(Symbol(),PERIOD_W1,time[bar],1,wTime)<=0) return(RESET);

      if(time[bar]>=wTime[0] && time[bar+1]<wTime[0])
        {         
         last_week_close=close[bar+1];
         this_week_open=open[bar];
         P=(last_week_high+last_week_low+this_week_open+last_week_close)/4;
         double Range=(last_week_high-last_week_low);
         R1=P+Range*Deviation;
         S1=P-Range*Deviation;
         R2=P+2*Range*Deviation;
         S2=P-2*Range*Deviation;
         R3=P+3*Range*Deviation;
         S3=P-3*Range*Deviation;
         if(bar) last_week_low=low[bar];
         if(bar) last_week_high=high[bar];
        }

      ExtLineBuffer0[bar]=R3;
      ExtLineBuffer1[bar]=R2;
      ExtLineBuffer2[bar]=R1;
      ExtLineBuffer3[bar]=P;
      ExtLineBuffer4[bar]=S1;
      ExtLineBuffer5[bar]=S2;
      ExtLineBuffer6[bar]=S3;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
