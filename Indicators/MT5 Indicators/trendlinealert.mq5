//+------------------------------------------------------------------+
//|                                               TrendLineAlert.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
//---- author of the indicator
#property copyright "Copyright © 2011, Nikolay Kositsin"
//---- link to the website of the author
#property link "farria@mail.redcom.ru" 
//---- indicator version
#property version   "1.00"
#property description "The indicator gives signals in case of a trend line breakout"
//---- drawing the indicator in the main window
#property indicator_chart_window 
#property indicator_buffers 1
#property indicator_plots   1
//+------------------------------------------------+ 
//| Enumeration for the level width                |
//+------------------------------------------------+ 
enum ENUM_WIDTH // type of constant
  {
   w_1 = 1,   // 1
   w_2,       // 2
   w_3,       // 3
   w_4,       // 4
   w_5        // 5
  };
//+------------------------------------------------+ 
//| Enumeration for the level actuation indication |
//+------------------------------------------------+ 
enum ENUM_ALERT_MODE // type of constant
  {
   OnlySound,   // only sound
   OnlyAlert    // only alert
  };
//+------------------------------------------------+
//| Indicator input parameters                     |
//+------------------------------------------------+
input string level_name="Trend_Level_1";        // Actuation level name
input string level_comment="trend level"; // Actuation level comment
input color active_level_color=Red;             // Active level color
input color inactive_level_color=Gray;          // Inactive level color
input ENUM_LINE_STYLE level_style=STYLE_SOLID;  // Actuation level style
input ENUM_WIDTH level_width=w_3;               // Actuation level width
input ENUM_ALERT_MODE alert_mode=OnlyAlert;     // Actuation indication version
input uint AlertTotal=10;                       // Number of alerts
input bool Deletelevel=true;                    // Level deletion
//+----------------------------------------------+

//+------------------------------------------------------------------+
//|  Trend line creation                                             |
//+------------------------------------------------------------------+
void CreateTline(long     chart_id,      // chart ID
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
//----
   ObjectCreate(chart_id,name,OBJ_TREND,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,true);
//----
  }
//+------------------------------------------------------------------+
//|  Trend line reinstallation                                       |
//+------------------------------------------------------------------+
void SetTline(long     chart_id,      // chart ID
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
//----
   if(ObjectFind(chart_id,name)==-1)
     {
      CreateTline(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,text);
     }
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//----
  }
//+------------------------------------------------------------------+
//|  Checking the trend line for moving                              |
//+------------------------------------------------------------------+
bool TlineMoveCheck(long      chart_id,      // chart ID
                    string    name,          // object name
                    int       nwin,          // window index
                    datetime& time1,         // price level time 1
                    double&   price1,        // price level 1
                    datetime& time2,         // price level time 2
                    double&   price2)        // price level 2
  {
//----
   static double price1_=0,price2_=0;
   static datetime time1_=0,time2_=0;
//----
   if(ObjectFind(chart_id,name)!=-1)
     {
      time1=datetime(ObjectGetInteger(chart_id,name,OBJPROP_TIME,0));
      time2=datetime(ObjectGetInteger(chart_id,name,OBJPROP_TIME,1));
      price1=ObjectGetDouble(chart_id,name,OBJPROP_PRICE,0);
      price2=ObjectGetDouble(chart_id,name,OBJPROP_PRICE,1);

      if(time1!=time1_ || time2!=time2_ || price1!=price1_ || price2!=price2_)
        {
         time1_=time1;
         time2_=time2;
         price1_=price1;
         price2_=price2;
         return(true);
        }
     }
//----
   return(false);
  }
//+------------------------------------------------------------------+
//|  Searching a bar by the opening time                             |
//+------------------------------------------------------------------+
int FindBar(int endtbar,            // initial bar (the latest)
            int startbar,           // end bar (the oldest)
            datetime bartime,       // bar time
            const datetime &time[]) // time[] time series
  {
//----
   for(int bar=startbar; bar>=endtbar; bar--)
     {
      if(time[bar]<=bartime) return(bar);
     }
//----
   return(endtbar);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//----
   if(ObjectFind(0,level_name)==-1)
     {
      SetTline(0,level_name,0,0,0,0,0,inactive_level_color,level_style,level_width,level_comment);
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   if(Deletelevel) ObjectDelete(0,level_name);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<20) return(0);

//---- declarations of local variables 
   double level,price0;
   int bar0;

   static double price2,price1,K;
   static datetime time1,time2;
   static uint count;
   static int bar1,bar2,dbar,startpos;

   if(ObjectFind(0,level_name)==-1)
     {
      if(count) SetTline(0,level_name,0,time1,price1,time2,price2,active_level_color,level_style,level_width,level_comment);
      else SetTline(0,level_name,0,time1,price1,time2,price2,inactive_level_color,level_style,level_width,level_comment);
     }

   bar0=rates_total-1;
   price0=close[bar0];

   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      TlineMoveCheck(0,level_name,0,time1,price1,time2,price2);

      if(!price1 || !price2 || !time1 || !time2)
        {
         bar1=rates_total-20;
         bar2=rates_total-1;
         time1=time[bar1];
         time2=time[bar2];
         price1=close[bar1];
         price2=close[bar2];
         SetTline(0,level_name,0,time1,price1,time2,price2,inactive_level_color,level_style,level_width,level_comment);
         TlineMoveCheck(0,level_name,0,time1,price1,time2,price2);
         count=0;
        }
     }

   if(TlineMoveCheck(0,level_name,0,time1,price1,time2,price2))
     {
      bar1=FindBar(0,bar0,time1,time);
      time1=time[bar1];

      bar2=FindBar(0,bar0,time2,time);
      time2=time[bar2];

      SetTline(0,level_name,0,time1,price1,time2,price2,active_level_color,level_style,level_width,level_comment);
      count=AlertTotal;

      dbar=bar2-bar1;
      if(!dbar) dbar=1;
      K=(price2-price1)/dbar;

      level=K*(bar0-bar1)+price1;
      if(price0>level) startpos=+1;
      else             startpos=-1;
     }

   level=K*(bar0-bar1)+price1;

   if(count)
      if(price0>=level && startpos<0 || price0<=level && startpos>0)
        {
         if(alert_mode==OnlyAlert) Alert("Trend line breakout at the level "+DoubleToString(level,_Digits));
         if(alert_mode==OnlySound) PlaySound("alert.wav");
         count--;
         if(!count) SetTline(0,level_name,0,time1,price1,time2,price2,inactive_level_color,level_style,level_width,level_comment);
        }

//----   
   return(rates_total);
  }
//+------------------------------------------------------------------+
