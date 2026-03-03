//+------------------------------------------------------------------+
//|                                                        FibSR.mq5 |
//|                                      Copyright © 2006, Eli hayun |
//|                                          http://www.elihayun.com |
//+------------------------------------------------------------------+
//--- Copyright
#property copyright "Copyright © 2006, Eli hayun"
//--- link to the website of the author
#property link      "http://www.elihayun.com"
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- buffers are not used for indicator calculation and drawing
#property indicator_buffers 0
//--- no graphical constructions
#property indicator_plots   0
//+------------------------------------------------+ 
//|  Declaration of constants                      |
//+------------------------------------------------+
#define RESET     0            // A constant for returning the indicator recalculation command to the terminal
#define FIB_RES2 "FIB_RES_2"
#define FIB_RES1 "FIB_RES_1"
#define FIB_SUP1 "FIB_SUP_1"
#define FIB_SUP2 "FIB_SUP_2"
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input ENUM_TIMEFRAMES Timeframe=PERIOD_H6;  // Indicator timeframe for the indicator calculation
input color  Color_Res2 = clrLime;          // The color of the second resistance zone
input color  Color_Res1 = clrGreen;         // The color of the first resistance zone
input color  Color_Sup1 = clrRed;           // The color of the first support zone
input color  Color_Sup2 = clrMagenta;       // The color of the second support zone
//+------------------------------------------------------------------+
//|  Creating a rectangle object                                     |
//+------------------------------------------------------------------+
void CreateRectangle(long     chart_id,      // Chart ID
                     string   name,          // object name
                     int      nwin,          // window index
                     datetime time1,         // time 1
                     double   price1,        // price 1
                     datetime time2,         // time 2
                     double   price2,        // price 2
                     color    Color,         // line color
                     bool     background,    // line background display
                     string   text)          // text
  {
   ObjectCreate(chart_id,name,OBJ_RECTANGLE,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_FILL,true);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,background);
   ObjectSetString(chart_id,name,OBJPROP_TOOLTIP,"\n"); // tooltip disabling
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true); // background object
  }
//+------------------------------------------------------------------+
//|  Resetting the rectangle object                                  |
//+------------------------------------------------------------------+
void SetRectangle(long     chart_id,      // Chart ID
                  string   name,          // object name
                  int      nwin,          // window index
                  datetime time1,         // time 1
                  double   price1,        // price 1
                  datetime time2,         // time 2
                  double   price2,        // price 2
                  color    Color,         // line color
                  bool     background,    // line background display
                  string   text)          // text
  {
   if(ObjectFind(chart_id,name)==-1) CreateRectangle(chart_id,name,nwin,time1,price1,time2,price2,Color,background,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
     }
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---
   if(Period()>=Timeframe) return(INIT_FAILED);;
//--- Determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- Creating labels for displaying in DataWindow and the name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"FibSR");
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
   ObjectDelete(0,FIB_SUP1);
   ObjectDelete(0,FIB_SUP2);
   ObjectDelete(0,FIB_RES1);
   ObjectDelete(0,FIB_RES2);
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
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(prev_calculated==rates_total) return(rates_total);

   double iClose[1],iHigh[1],iLow[1];
   datetime iTime[1];
   int to_copy;

//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(time,true);

   to_copy=1;

   if(CopyTime(NULL,Timeframe,0,to_copy,iTime)<to_copy)return(RESET);
   if(CopyClose(NULL,Timeframe,1,to_copy,iClose)<to_copy)return(RESET);
   if(CopyHigh(NULL,Timeframe,1,to_copy,iHigh)<to_copy)return(RESET);
   if(CopyLow(NULL,Timeframe,1,to_copy,iLow)<to_copy)return(RESET);

   double C=iClose[0];
   double H=iHigh[0];
   double L=iLow[0];
   double R=(H-L);
//---
   C=(H+L+C)/3;
   double D=(R/2)+C;
   double B=C-(R/2);
   double E=R+C;
   double A=C-R;
//---
   double R1=R*1.382;
   double R2=R*0.618;
   double B1=C-R2;
   double A1=C-R1;
//---
   double D1=C+R2;
   double E1=C+R1;
//---
   SetRectangle(0,FIB_RES2,0,iTime[0],E,time[0],E1,Color_Res2,true,FIB_RES2);
   SetRectangle(0,FIB_RES1,0,iTime[0],D,time[0],D1,Color_Res1,true,FIB_RES1);
   SetRectangle(0,FIB_SUP1,0,iTime[0],B,time[0],B1,Color_Sup1,true,FIB_SUP1);
   SetRectangle(0,FIB_SUP2,0,iTime[0],A,time[0],A1,Color_Sup2,true,FIB_SUP2);
//---
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
