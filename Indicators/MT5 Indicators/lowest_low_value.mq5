//+------------------------------------------------------------------+
//|                                             LOWEST_LOW_VALUE.mq5 |
//|                               Copyright © 2014, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2014, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//--- indicator version
#property version   "1.00"
#property description "Price minimum for the period specified in inputs"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- no indicator buffers
#property indicator_buffers 0
//--- no graphical constructions
#property indicator_plots   0
//+------------------------------------------------+ 
//| Enumeration for the level width                |
//+------------------------------------------------+ 
enum ENUM_WIDTH //Type of constant
  {
   w_1 = 1,   //1
   w_2,       //2
   w_3,       //3
   w_4,       //4
   w_5        //5
  };
//+------------------------------------------------+ 
//| Enumeration for the level actuation indication |
//+------------------------------------------------+ 
enum ENUM_ALERT_MODE // Type of constant
  {
   OnlySound,   // only sound
   OnlyAlert    // only alert
  };
//+------------------------------------------------+
//| Indicator input parameters                     |
//+------------------------------------------------+
input string level_name="Price_LOWEST_LOW_VALUE_1";  // Level name
input string level_comment="trigger level";   // A comment to the level
input uint   level_period=5;                         // Level search period
input uint   level_start=0;                          // The number of the starting bar
input color level_color=clrRed;                      // Level color
input ENUM_LINE_STYLE level_style=STYLE_SOLID;       // The style of the trigger level
input ENUM_WIDTH level_width=w_3;                    // The width of the trigger level
input bool Deletelevel=true;                         // Deleting the level
//+------------------------------------------------+
//--- declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+
//|  Creating the horizontal line                                   |
//+------------------------------------------------------------------+
void CreateHline(long     chart_id,      // chart ID
                 string   name,          // object name
                 int      nwin,          // window index
                 double   price,         // horizontal level price
                 color    Color,         // line color
                 int      style,         // line style
                 int      width,         // line width
                 bool     background,    // line background display
                 string   text)          // text
  {
//---
   ObjectCreate(chart_id,name,OBJ_HLINE,nwin,0,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,background);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,true);
//---
  }
//+------------------------------------------------------------------+
//|  Resetting the horizontal line                                   |
//+------------------------------------------------------------------+
void SetHline(long     chart_id,      // chart ID
              string   name,          // object name
              int      nwin,          // window index
              double   price,         // horizontal level price
              color    Color,         // line color
              int      style,         // line style
              int      width,         // line width
              bool     background,    // line background display
              string   text)          // text
  {
//---
   if(ObjectFind(chart_id,name)==-1) CreateHline(chart_id,name,nwin,price,Color,style,width,background,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,0,price);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
   min_rates_total=int(level_start+level_period);
//--- create a level if it does not exist
   if(ObjectFind(0,level_name)==-1) CreateHline(0,level_name,0,0,level_color,level_style,level_width,false,level_comment);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//--- delete the level, if necessary
   if(Deletelevel) ObjectDelete(0,level_name);
//---
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
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
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total) return(0);
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(low,true);
//--- search for extremum
   double LL=low[ArrayMinimum(low,level_start,level_period)];
//--- check the level shift
   SetHline(0,level_name,0,LL,level_color,level_style,level_width,false,level_comment);
//---
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
