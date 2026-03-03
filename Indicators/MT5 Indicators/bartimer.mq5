//+------------------------------------------------------------------+
//|                                                     BarTimer.mq4 |
//|                               Copyright © 2008, Art Royal s.r.o. |
//|                                           Author: Vasyl Gumenyak |  
//|                                           http://www.jiport.com/ |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2008, Art Royal s.r.o."
//---- link to the website of the author
#property link      "http://www.jiport.com/"
//---- indicator version
#property version   "1.0"
//---- drawing the indicator in the main window
#property indicator_chart_window 
#property indicator_buffers 1 
#property indicator_plots   1 
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input ENUM_BASE_CORNER  Corner=CORNER_LEFT_LOWER; // Location corner 
input string FontType="Arial";                    // Font type
input int FontSize=14;                            // Font size
input color FontColor=Red;                        // Text color
input int XDistance=250;                          // X distance from the reference angle
input int YDistance=0;                            // Y distance from the reference angle
//+----------------------------------------------+
int lenbase;
string s_base=":...:...:...:...:";                // the string for the informer with a slider
//+------------------------------------------------------------------+
//|  Create the text box                                             |
//+------------------------------------------------------------------+
void CreateTLabel(long   chart_id,         // chart ID
                  string name,             // object name
                  int    nwin,             // window index
                  ENUM_BASE_CORNER corner, // base corner location
                  ENUM_ANCHOR_POINT point, // anchor point location
                  int    X,                // the distance from the base corner along the X-axis in pixels
                  int    Y,                // the distance from the base corner along the Y-axis in pixels
                  string text,             // text
                  color  Color,            // text color
                  string Font,             // text font
                  int    Size)             // font size
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(chart_id,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,point);
   ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,X);
   ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,Y);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetString(chart_id,name,OBJPROP_FONT,Font);
   ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,Size);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//----
  }
//+------------------------------------------------------------------+
//|  Setting the text box                                            |
//+------------------------------------------------------------------+
void SetTLabel(long   chart_id,         // chart ID
               string name,             // object name
               int    nwin,             // window index
               ENUM_BASE_CORNER corner, // base corner location
               ENUM_ANCHOR_POINT point, // anchor point location
               int    X,                // the distance from the base corner along the X-axis in pixels
               int    Y,                // the distance from the base corner along the Y-axis in pixels
               string text,             // text
               color  Color,            // text color
               string Font,             // text font
               int    Size)             // font size
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateTLabel(chart_id,name,nwin,corner,point,X,Y,text,Color,Font,Size);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,X);
      ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,Y);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//----
   lenbase=StringLen(s_base);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   if(ObjectFind(0,"BarTimer")!=-1) ObjectDelete(0,"BarTimer");
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of minimums of price for the calculation of indicator
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- 
   int i=0,sec=0;
   double pc=0.0;
   string Time="",s_end="",s_beg="";

   sec=int (TimeCurrent()-time[rates_total-1]); // the time in seconds from a bar beginning
   i=(lenbase-1)*sec/(PeriodSeconds());         // slider position
   pc=100.0*sec/(PeriodSeconds());              // the time from the bar beginning in percents
   if(i>lenbase-1) i=lenbase-1;                 // border control (possibly, excessive)
   if(i>0) s_beg=StringSubstr(s_base,0,i);
   if(i<lenbase-1) s_end=StringSubstr(s_base,i+1,lenbase-i-1);
   StringConcatenate(Time,s_beg,"|",s_end,"  ",DoubleToString(pc,0),"%");
   SetTLabel(0,"BarTimer",0,Corner,ENUM_ANCHOR_POINT(2*Corner),XDistance,YDistance,Time,FontColor,FontType,FontSize);
//----
   ChartRedraw(0);
//----   
   return(rates_total);
  }
//+------------------------------------------------------------------+
