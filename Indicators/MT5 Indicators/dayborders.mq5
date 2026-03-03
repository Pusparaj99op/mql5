//+------------------------------------------------------------------+
//|                                                   DayBorders.mq5 |
//|                          Copyright © 2008, Aleksandr Pak, Almaty | 
//|                                                   ekr-ap@mail.ru | 
//+------------------------------------------------------------------+
/*
 * The indicator draws borders of the last calendar day.
 * Vertical lines of the last day with fixed names DayTimeOpen DayTimeClose
 * Horizontal lines with fixed names DayOpen DayClose
 * Colors of lines of borders are set at compilation.

 * The indicator draws borders of the last calendar day.
 * Vertical lines of the last day with fixed names DayTimeOpen DayTimeClose
 * Horizontal lines with fixed names DayOpen DayClose
 * Colors of lines of borders are set at compilation.
 */
//---- author of the indicator
#property copyright "Copyright © 2008, Aleksandr Pak, Almaty"
//---- link to the website of the author
#property link "ekr-ap@mail.ru" 
//---- indicator version number
#property version   "1.00"

//---- number of indicator buffers
#property indicator_buffers 0 
//---- 0 graphical plots are used in total
#property indicator_plots   0
//---- drawing the indicator in the main window
#property indicator_chart_window 
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
//| Enumeration for the level style                |
//+------------------------------------------------+ 
enum STYLE
  {
   SOLID_,//Solid line
   DASH_,//Dashed line
   DOT_,//Dotted line
   DASHDOT_,//Dot-dash line
   DASHDOTDOT_   //Dot-dash line with double dots
  };
//+------------------------------------------------+ 
//| Enumeration for the level width                |
//+------------------------------------------------+ 
enum ENUM_MODE //Type of constant
  {
   OPEN_CLOSE = 1,   //Open/Close
   HIGHLOW           //High/Low
  };
//+------------------------------------------------+
//| Indicator input parameters                     |
//+------------------------------------------------+
input ENUM_MODE Mode=OPEN_CLOSE; //type of prices for calculation

input color Open_level_color=clrRed; //color of the open price level
input color Close_level_color=clrDodgerBlue; //color of the close price level
input ENUM_LINE_STYLE levels_style=STYLE_SOLID;//price levels style
input ENUM_WIDTH levels_width=w_2;//price levels width

input color Start_Line_Color=clrDarkOrange; //color of the start line
input STYLE Start_Line_Style=SOLID_; //style of the start line
input ENUM_WIDTH Start_Line_Width=w_3; //width of the start line

input color End_Line_Color=clrDarkViolet; //color of the end line
input STYLE End_Line_Style=SOLID_; //style of the end line
input ENUM_WIDTH End_Line_Width=w_3; //width of the end line
//+----------------------------------------------+

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//----

//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//---- delete the level, if necessary
   ObjectDelete(0,"DayTimeClose");
   ObjectDelete(0,"DayTimeOpen");
   ObjectDelete(0,"DayOpen");
   ObjectDelete(0,"DayClose");
   ObjectDelete(0,"DayHigh");
   ObjectDelete(0,"DayLow");
//----
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of minimums of price for the calculation of indicator
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- declaration of local variables
   datetime iTime[2];
   static datetime LastTime;

//---- copy newly appeared data into the arrays
   if(CopyTime(Symbol(),PERIOD_D1,0,2,iTime)<=0) return(0);

//---- Make the calculation only on the new, daily bars   
   if(LastTime==iTime[0]) return(rates_total);
   LastTime=iTime[0];

//---- declaration of local variables
   string trendinfo;
   double iOpen[2],iClose[1];

//---- copy newly appeared data into the arrays 
   if(CopyOpen(Symbol(),PERIOD_D1,1,1,iOpen)<=0) return(0);
   if(CopyClose(Symbol(),PERIOD_D1,1,1,iClose)<=0) return(0);

   if(iOpen[0]<iClose[0]) trendinfo="Growth";
   else trendinfo="Falling";

   if(Mode==OPEN_CLOSE)
     {
      SetHline(0,"DayOpen",0,iOpen[0],Open_level_color,levels_style,levels_width,false,trendinfo);
      SetHline(0,"DayClose",0,iClose[0],Close_level_color,levels_style,levels_width,false,trendinfo);
     }
   else
     {
      double iHigh[1],iLow[1];
      //---- copy newly appeared data into the arrays
      if(CopyLow(Symbol(),PERIOD_D1,1,1,iLow)<=0) return(0);
      if(CopyHigh(Symbol(),PERIOD_D1,1,1,iHigh)<=0) return(0);

      SetHline(0,"DayHigh",0,iHigh[0],Open_level_color,levels_style,levels_width,false,trendinfo);
      SetHline(0,"DayLow",0,iLow[0],Close_level_color,levels_style,levels_width,false,trendinfo);
     }

   CreateVline(0,"DayTimeOpen",0,iTime[1],Start_Line_Color,Start_Line_Style,Start_Line_Width,true,"Start level");
   CreateVline(0,"DayTimeClose",0,iTime[0],End_Line_Color,End_Line_Style,End_Line_Width,true,"End level");

//----
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  Creating the horizontal line                                    |
//+------------------------------------------------------------------+
void CreateHline
(
 long     chart_id,      // chart ID.
 string   name,          // object name
 int      nwin,          // window index
 double   price,         // horizontal level price
 color    Color,         // color of the line
 int      style,         // style of the line
 int      width,         // width of the line
 bool     background,// line background display
 string   text           // text
 )
//---- 
  {
//----
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
//----
  }
//+------------------------------------------------------------------+
//|  Horizontal line redrawing                                       |
//+------------------------------------------------------------------+
void SetHline
(
 long     chart_id,      // chart ID.
 string   name,          // object name
 int      nwin,          // window index
 double   price,         // horizontal level price
 color    Color,         // color of the line
 int      style,         // style of the line
 int      width,         // width of the line
 bool     background,// line background display
 string   text           // text
 )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateHline(chart_id,name,nwin,price,Color,style,width,background,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,0,price);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//----
  }
//+------------------------------------------------------------------+
//|  Creating the vertical line                                      |
//+------------------------------------------------------------------+
void CreateVline
(
 long     chart_id,      // chart ID.
 string   name,          // object name
 int      nwin,          // window index
 datetime time1,         // vertical level time
 color    Color,         // color of the line
 int      style,         // style of the line
 int      width,         // width of the line
 bool     background,// line background display
 string   text           // text
 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_VLINE,nwin,time1,999999999);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,background);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
//----
  }
//+------------------------------------------------------------------+
//|  Vertical line redrawing                                         |
//+------------------------------------------------------------------+
void SetVline
(
 long     chart_id,      // chart ID.
 string   name,          // object name
 int      nwin,          // window index
 datetime time1,         // vertical level time
 color    Color,         // color of the line
 int      style,         // style of the line
 int      width,         // width of the line
 bool     background,// line background display
 string   text           // text
 )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateVline(chart_id,name,nwin,time1,Color,style,width,background,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,999999999);
     }
//----
  }
//+------------------------------------------------------------------+
