//+------------------------------------------------------------------+
//|                                                TrendlinesDay.mq5 |
//|                                        Copyright © 2006, nsi2000 |
//|                                      http://www.expert-mt4.nm.ru |
//+------------------------------------------------------------------+
//---- Copyright
#property copyright "Copyright © 2006, nsi2000"
//---- link to the website of the author
#property link      "http://www.expert-mt4.nm.ru"
//---- indicator description
#property description ""
//---- Indicator version
#property version   "1.00"
//---- Drawing the indicator in the main window
#property indicator_chart_window
//--- buffers are not used for indicator calculation and drawing
#property indicator_buffers 0
//--- no graphical constructions
#property indicator_plots   0
//+----------------------------------------------+
//|  Declaring constants                         |
//+----------------------------------------------+
#define RESET 0 // the constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint  nPeriod=10;
input uint  Limit=350;
input color UpChannelColor=clrTeal;
input color DnChannelColor=clrRed;
//+----------------------------------------------+
//--- declaration of the integer variables for the start of data calculation
int min_rates_total,barshift;
//+------------------------------------------------------------------+
//|  Trend line creation                                             |
//+------------------------------------------------------------------+
void CreateTline(long     chart_id,      // Chart ID
                 string   name,          // object name
                 int      nwin,          // window index
                 datetime time1,         // price level time 1
                 double   price1,        // price level 1
                 datetime time2,         // price level time 2
                 double   price2,        // price level 2
                 color    Color,         // line color
                 int      style,         // line style
                 int      width,         // line width
                 string   text)          // text
  {
//---
   ObjectCreate(chart_id,name,OBJ_TREND,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);
//---
  }
//+------------------------------------------------------------------+
//|  Resetting a trend line                                          |
//+------------------------------------------------------------------+
void SetTline(long     chart_id,      // Chart ID
              string   name,          // object name
              int      nwin,          // window index
              datetime time1,         // price level time 1
              double   price1,        // price level 1
              datetime time2,         // price level time 2
              double   price2,        // price level 2
              color    Color,         // line color
              int      style,         // line style
              int      width,         // line width
              string   text)          // text
  {
//---
   if(ObjectFind(chart_id,name)==-1) CreateTline(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
     }
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(Limit+1);
   barshift=int((nPeriod-1)/2);
//--- initializations of a variable for the indicator short name
   string shortname="trendlinesDay";
//--- Creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- Determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- initialization end
  }
//+------------------------------------------------------------------+
//| DelObj                                                           |
//+------------------------------------------------------------------+
void DelObj()
  {
//---
   ObjectDelete(0,"Upper CHN");
   ObjectDelete(0,"Lower CHN");
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+     
void OnDeinit(const int reason)
  {
//---
   DelObj();
//---
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total) return(RESET);

   static double r1=0,r2=0,s1=0,s2=0;
   static int rt1=0,rt2=0,st1=0,st2=0;

//---- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(Time,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);

   for(int nCurBar=int(Limit); nCurBar>0; nCurBar--)
     {
      int barX=nCurBar+barshift;
      double LL=Low[ArrayMinimum(Low,nCurBar,nPeriod)];
      double HH=High[ArrayMaximum(High,nCurBar,nPeriod)];

      if(Low[barX]==LL)
        {
         s2=s1;
         s1=Low[barX];
         st2=st1;
         st1=barX;
        }

      if(High[barX]==HH)
        {
         r2=r1;
         r1=High[barX];
         rt2=rt1;
         rt1=barX;
        }
     }

   SetTline(0,"Upper CHN",0,Time[rt2],r2,Time[rt1],r1,UpChannelColor,STYLE_SOLID,2,"Upper CHN");
   SetTline(0,"Lower CHN",0,Time[st2],s2,Time[st1],s1,DnChannelColor,STYLE_SOLID,2,"Lower CHN");
//---    
   return(rates_total);
  }
//+------------------------------------------------------------------+
