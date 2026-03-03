//+------------------------------------------------------------------+
//|                                               i-MorningRange.mq5 |
//|                         Copyright © 2006, Kim Igor V. aka KimIV |
//|                                              http://www.kimiv.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Kim Igor V. aka KimIV"
#property link      "http://www.kimiv.ru"
#property description "the morning range indicator"
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers
#property indicator_buffers 2 
//---- only 2 plots are used
#property indicator_plots   2

//+--------------------------------------------------+
//|  Indicator level drawing parameters              |
//+--------------------------------------------------+
//---- drawing the levels as lines
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
//---- selection of levels colors
#property indicator_color1  clrBlue
#property indicator_color2  clrDarkOrange
//---- levels are solid curves
#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_SOLID
//---- levels width is equal to 2
#property indicator_width1  2
#property indicator_width2  2
//---- displaying labels of the levels
#property indicator_label1  "Upper Line"
#property indicator_label2  "Lower Line"

//+-----------------------------------+
//|  declaration of constants         |
//+-----------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input string CheckTime   ="08:00";  // Range check time
input bool   ShowHistory =true;     // Show levels in history
input int    NumberOfDays=5;        // Number of days in history
input bool   ShowComment =true;     // Show comments
input int    Shift=0;               // horizontal shift of the indicator in bars
input color Color1=clrBlue;         // resistance color
input color Color2=clrDarkOrange;   // support color
//+-----------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double ExtLineBuffer1[],ExtLineBuffer2[];

//---- Declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+   
//| i-MorningRange indicator initialization function                 | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=NumberOfDays*PeriodSeconds(PERIOD_D1)/PeriodSeconds(PERIOD_CURRENT);

//---- setting dynamic arrays as indicator buffers
   SetIndexBuffer(0,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLineBuffer2,INDICATOR_DATA);
//---- set the position, from which the levels drawing starts
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in buffers as in timeseries   
   ArraySetAsSeries(ExtLineBuffer1,true);
   ArraySetAsSeries(ExtLineBuffer2,true);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"i-MorningRange");

//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- end of initialization
  }
//+------------------------------------------------------------------+
//| i-MorningRange deinitialization function                         |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   Comment("");
   ObjectDelete(0,"HLine"+string(0));
   ObjectDelete(0,"HLine"+string(1));
//----
  }
//+------------------------------------------------------------------+ 
//| i-MorningRange iteration function                                | 
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
   if(rates_total<min_rates_total) return(RESET);

//---- Declaration of variables with a floating point  

//---- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

   int limit;

//---- calculation of the starting number limit for the bar nulling loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-1-min_rates_total; // starting index for the calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for the calculation of new bars
     }

//---- main cycle of calculation of the indicator
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ExtLineBuffer1[bar]=0.0;
      ExtLineBuffer2[bar]=0.0;
     }

   datetime t1,t2,dt;
   double   p1,p2;
   int      b1,b2,sd=0;
//----
   t1=StringToTime(TimeToString(TimeCurrent(),TIME_DATE)+" 00:00");
   t2=StringToTime(TimeToString(TimeCurrent(),TIME_DATE)+" "+CheckTime);
   b1=iBarShift(NULL,0,t1);
   b2=iBarShift(NULL,0,t2);
   int res=b1-b2+1;
   p1=high[ArrayMaximum(high,b2,res)];
   p2=low[ArrayMinimum(low,b2,res)];

   int Width1=PlotIndexGetInteger(PLOT_LINE_WIDTH,0);
   int Style1=PlotIndexGetInteger(PLOT_LINE_STYLE,0);
   SetHline(0,"HLine"+string(0),0,p1,Color1,Style1,Width1,"HLine"+string(0));

   int Width2=PlotIndexGetInteger(PLOT_LINE_WIDTH,1);
   int Style2=PlotIndexGetInteger(PLOT_LINE_STYLE,1);
   SetHline(0,"HLine"+string(1),0,p2,Color2,Style2,Width2,"HLine"+string(1));

   if(ShowHistory)
     {
      dt=decDateTradeDay(TimeCurrent());

      for(int i=0; i<NumberOfDays; i++)
        {
         DrawLines(dt,high,low);
         dt=decDateTradeDay(dt);
         MqlDateTime tqq;
         TimeToStruct(dt,tqq);

         while(tqq.day_of_week<1 || tqq.day_of_week>5)
           {
            dt=decDateTradeDay(dt);
            TimeToStruct(dt,tqq);
           }
        }
     }
   if(ShowComment) Comment("CheckTime="+CheckTime);
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  Drawing all lines on the chart                                  |
//| Parameters:                                                      |
//|   dt - date of the trading day                                   |
//|   nd - day number (for objects numeration)                       |
//+------------------------------------------------------------------+
void DrawLines(datetime dt,const double &High[],const double &Low[])
  {
//----
   datetime t1,t2;
   double p1,p2;
   int b1,b2;
//----
   t1=StringToTime(TimeToString(dt,TIME_DATE)+" 00:00");
   t2=StringToTime(TimeToString(dt,TIME_DATE)+" "+CheckTime);
//----
   b1=iBarShift(NULL,0,t1);
   b2=iBarShift(NULL,0,t2);
//----   
   int res=b1-b2+1;
   p1=High[ArrayMaximum(High,b2,res)];
   p2=Low[ArrayMinimum(Low,b2,res)];
//----
   for(int rrr=b1; rrr>=b2; rrr--)
     {
      ExtLineBuffer1[rrr]=p1;
      ExtLineBuffer2[rrr]=p2;
     }
//----
  }
//+------------------------------------------------------------------+
//| Decrease date on one trading day                                 |
//| Parameters:                                                      |
//|   dt - date of the trading day                                   |
//+------------------------------------------------------------------+
datetime decDateTradeDay(datetime dt)
  {
//----
   MqlDateTime ttt;
   TimeToStruct(dt,ttt);
   int ty=ttt.year;
   int tm=ttt.mon;
   int td=ttt.day;
   int th=ttt.hour;
   int ti=ttt.min;
//----
   td--;
   if(td==0)
     {
      tm--;

      if(!tm)
        {
         ty--;
         tm=12;
        }

      if(tm==1 || tm==3 || tm==5 || tm==7 || tm==8 || tm==10 || tm==12) td=31;
      if(tm==2) if(!MathMod(ty,4)) td=29; else td=28;
      if(tm==4 || tm==6 || tm==9 || tm==11) td=30;
     }

   string text;
   StringConcatenate(text,ty,".",tm,".",td," ",th,":",ti);
//----
   return(StringToTime(text));
  }
//+------------------------------------------------------------------+   
//| iBarShift() function                                             |
//+------------------------------------------------------------------+  
int iBarShift(string symbol,ENUM_TIMEFRAMES timeframe,datetime time)

// iBarShift(symbol, timeframe, time)
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
  {
//----
   if(time<0) return(-1);
   datetime Arr[],time1;

   time1=(datetime)SeriesInfoInteger(symbol,timeframe,SERIES_LASTBAR_DATE);

   if(CopyTime(symbol,timeframe,time,time1,Arr)>0)
     {
      int size=ArraySize(Arr);
      return(size-1);
     }
   else return(-1);
//----
  }
//+------------------------------------------------------------------+
//|  Creating horizontal price level                                 |
//+------------------------------------------------------------------+
void CreateHline
(
 long   chart_id,      // chart ID
 string name,          // object name
 int    nwin,          // window index
 double price,         // price level
 color  Color,         // line color
 int    style,         // line style
 int    width,         // line width
 string text           // text
 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_HLINE,0,0,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//----
  }
//+------------------------------------------------------------------+
//|  Reinstallation of the horizontal price level                    |
//+------------------------------------------------------------------+
void SetHline
(
 long   chart_id,      // chart ID
 string name,          // object name
 int    nwin,          // window index
 double price,         // price level
 color  Color,         // line color
 int    style,         // line style
 int    width,         // line width
 string text           // text
 )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateHline(chart_id,name,nwin,price,Color,style,width,text);
   else
     {
      //ObjectSetDouble(chart_id,name,OBJPROP_PRICE,price);
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,0,price);
     }
//----
  }
//+------------------------------------------------------------------+
