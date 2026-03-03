//+------------------------------------------------------------------+ 
//|                                          i-IntradayFibonacci.mq5 | 
//|                         Copyright © 2007, Kim Igor V. aka KimIV  | 
//|                                              http://www.kimiv.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2007, Kim Igor V. aka KimIV"
#property link "http://www.kimiv.ru"
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- number of indicator buffers 8
#property indicator_buffers 8 
//---- 8 graphical plots are used in total
#property indicator_plots   8
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME "i-IntradayFibonacci" // The constant for the indicator name
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing the indicators as lines
#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
#property indicator_type4   DRAW_ARROW
#property indicator_type5   DRAW_ARROW
#property indicator_type6   DRAW_ARROW
#property indicator_type7   DRAW_ARROW
#property indicator_type8   DRAW_ARROW
//---- the following colors are used as the indicator colors
#property indicator_color1 clrBlue
#property indicator_color2 clrLime
#property indicator_color3 clrOrange
#property indicator_color4 clrDeepPink
#property indicator_color5 clrDeepPink
#property indicator_color6 clrOrange
#property indicator_color7 clrLime
#property indicator_color8 clrBlue
//---- width of the indicator lines is equal to 1
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  1
//---- displaying the indicator label
#property indicator_label1  INDICATOR_NAME+" +0.764"
#property indicator_label2  INDICATOR_NAME+" +0.618"
#property indicator_label3  INDICATOR_NAME+" +0.382"
#property indicator_label4  INDICATOR_NAME+" +0.236"
#property indicator_label1  INDICATOR_NAME+" -0.236"
#property indicator_label2  INDICATOR_NAME+" -0.382"
#property indicator_label3  INDICATOR_NAME+" -0.618"
#property indicator_label4  INDICATOR_NAME+" -0.764"

//+-------------------------------------+
//|  INDICATOR INPUT PARAMETERS         |
//+-------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_D1; // Chart period
input int Shift=0; // horizontal shift of the indicator in bars
input int PriceShift=0; // vertical shift of the indicator in points
//+-------------------------------------+
//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double IndBuffer1[],IndBuffer2[],IndBuffer3[],IndBuffer4[];
double IndBuffer5[],IndBuffer6[],IndBuffer7[],IndBuffer8[];
//---- Declaration of a variable for storing the indicator initialization result
bool Init;
//---- Declaration of strings
string Symbol_;
//---- Declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
void IndInit(int Number,double& Arrow[],int DRAW_BEGIN_,double EMPTY_VALUE_)
  {
//---- set dynamic array as an indicator buffer
   SetIndexBuffer(Number,Arrow,INDICATOR_DATA);
//---- shifting the starting point of the indicator drawing
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,DRAW_BEGIN_);
//---- setting values of the indicator that won't be visible on a chart
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,EMPTY_VALUE_);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Arrow,true);
//----
  }
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
void OnInit()
  {
   Init=true;
//---- checking correctness of the chart periods
   if(TimeFrame<Period() && TimeFrame!=PERIOD_CURRENT)
     {
      Print("The chart period cannot be less than the current chart period");
      Init=false;
      return;
     }

//---- Initialization of variables 
   min_rates_total=int(PeriodSeconds(TimeFrame)/PeriodSeconds(PERIOD_CURRENT)+1);
   Symbol_=Symbol();

//----
   IndInit(0,IndBuffer1,min_rates_total,0.0);
   IndInit(1,IndBuffer2,min_rates_total,0.0);
   IndInit(2,IndBuffer3,min_rates_total,0.0);
   IndInit(3,IndBuffer4,min_rates_total,0.0);
   IndInit(4,IndBuffer5,min_rates_total,0.0);
   IndInit(5,IndBuffer6,min_rates_total,0.0);
   IndInit(6,IndBuffer7,min_rates_total,0.0);
   IndInit(7,IndBuffer8,min_rates_total,0.0);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,INDICATOR_NAME);
//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- end of initialization
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
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
//---- checking for the sufficiency of the number of bars for the calculation
   if(rates_total<min_rates_total || !Init) return(RESET);

//---- declaration of local variables 
   double iHigh[2],iLow[2];
   int limit,bar;
   datetime iTime[1];
   static uint LastCountBar;

//---- calculations of the necessary amount of data to be copied and
//the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
      LastCountBar=rates_total;
     }
   else limit=int(LastCountBar)+rates_total-prev_calculated; // starting index for the calculation of new bars 

//---- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(time,true);

//---- main cycle of calculation of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- copy new data to the iTime array
      if(CopyTime(Symbol_,TimeFrame,time[bar],1,iTime)<=0) return(RESET);

      if(time[bar]>=iTime[0] && time[bar+1]<iTime[0])
        {
         LastCountBar=bar;

         //---- copy newly appeared data into the arrays
         if(CopyLow(Symbol_,TimeFrame,time[bar],2,iLow)<=0) return(RESET);
         if(CopyHigh(Symbol_,TimeFrame,time[bar],2,iHigh)<=0) return(RESET);

         double Range=iHigh[0]-iLow[0];
         IndBuffer1[bar]=iHigh[0]+Range*0.764;
         IndBuffer2[bar]=iHigh[0]+Range*0.618;
         IndBuffer3[bar]=iHigh[0]+Range*0.382;
         IndBuffer4[bar]=iHigh[0]+Range*0.236;
         IndBuffer5[bar]=iLow[0]-Range*0.236;
         IndBuffer6[bar]=iLow[0]-Range*0.382;
         IndBuffer7[bar]=iLow[0]-Range*0.618;
         IndBuffer8[bar]=iLow[0]-Range*0.764;
        }
      else
        {
         IndBuffer1[bar]=IndBuffer1[bar+1];
         IndBuffer2[bar]=IndBuffer2[bar+1];
         IndBuffer3[bar]=IndBuffer3[bar+1];
         IndBuffer4[bar]=IndBuffer4[bar+1];
         IndBuffer5[bar]=IndBuffer5[bar+1];
         IndBuffer6[bar]=IndBuffer6[bar+1];
         IndBuffer7[bar]=IndBuffer7[bar+1];
         IndBuffer8[bar]=IndBuffer8[bar+1];
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
