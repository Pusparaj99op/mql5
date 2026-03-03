//+------------------------------------------------------------------+
//|                                                       KLines.mq5 |
//|                                        Copyright © 2005, Kalenzo |
//|                                      bartlomiej.gorski@gmail.com |
//+------------------------------------------------------------------+
//--- Copyright
#property copyright "Copyright © 2005, Kalenzo"
//--- link to the website of the author
#property link      "bartlomiej.gorski@gmail.com"
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- buffers are not used for indicator calculation and drawing
#property indicator_buffers 0
//--- graphical representations are not used
#property indicator_plots  0
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint KLPeriod=14;                       // Period for extremums
input uint TextSize=7;                        // Text size
input color UpColor=clrGreen;                 // Color of resistance
input color DnColor=clrRed;                   // Color of support
input ENUM_TIMEFRAMES Timeframe1=PERIOD_D1;   // Timeframe for calculation of 1
input ENUM_TIMEFRAMES Timeframe2=PERIOD_H4;   // Timeframe for calculation of 2
input ENUM_TIMEFRAMES Timeframe3=PERIOD_H1;   // Timeframe for calculation of 3
input ENUM_TIMEFRAMES Timeframe4=PERIOD_M30;  // Timeframe for calculation of 4
input ENUM_TIMEFRAMES Timeframe5=PERIOD_M15;  // Timeframe for calculation of 5
//+----------------------------------------------+
double iClose[];
string Lbh1,Lbh2,Lbh3,Lbh4,Lbh5,Lbl1,Lbl2,Lbl3,Lbl4,Lbl5;
//+------------------------------------------------------------------+
//|  Getting a timeframe as a line                                   |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {
   return(StringSubstr(EnumToString(timeframe),7,-1));
  }
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
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
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
//|  Text Label creation                                             |
//+------------------------------------------------------------------+
void CreateText(long chart_id,              // chart ID
                string   name,              // Object name
                int      nwin,              // Window index
                datetime time,              // Time of the price level
                double   price,             // Price level
                string   text,              // Label text
                color    Color,             // Label color
                string   Font,              // Label font
                int      Size,              // Size
                ENUM_ANCHOR_POINT point)    // Chart corner to position the label
  {
//---
   ObjectCreate(chart_id,name,OBJ_TEXT,nwin,time,price);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetString(chart_id,name,OBJPROP_FONT,Font);
   ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,Size);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,point);
//---
  }
//+------------------------------------------------------------------+
//|  Text Label reinstallation                                       |
//+------------------------------------------------------------------+
void SetText(long chart_id,              // Chart ID
             string   name,              // Object name
             int      nwin,              // Window index
             datetime time,              // Time of the price level
             double   price,             // Price level
             string   text,              // Label text
             color    Color,             // Label color
             string   Font,              // Label font
             int      Size,              // Size
             ENUM_ANCHOR_POINT point)    // Chart corner to position the label
  {
//---
   if(ObjectFind(chart_id,name)==-1) CreateText(chart_id,name,nwin,time,price,text,Color,Font,Size,point);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time,price);
     }
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- Determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
   Lbh1=GetStringTimeframe(Timeframe1)+"  Bar Highest Close";
   Lbh2=GetStringTimeframe(Timeframe2)+"  Bar Highest Close";
   Lbh3=GetStringTimeframe(Timeframe3)+"  Bar Highest Close";
   Lbh4=GetStringTimeframe(Timeframe4)+"  Bar Highest Close";
   Lbh5=GetStringTimeframe(Timeframe5)+"  Bar Highest Close";
   Lbl1=GetStringTimeframe(Timeframe1)+"  Bar Lowest Close";
   Lbl2=GetStringTimeframe(Timeframe2)+"  Bar Lowest Close";
   Lbl3=GetStringTimeframe(Timeframe3)+"  Bar Lowest Close";
   Lbl4=GetStringTimeframe(Timeframe4)+"  Bar Lowest Close";
   Lbl5=GetStringTimeframe(Timeframe5)+"  Bar Lowest Close";
//--- memory allocation for the variable array  
   if(ArrayResize(iClose,KLPeriod)!=KLPeriod) return(INIT_FAILED);
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(iClose,true);
//--- initialization end
   ChartRedraw(0);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
   ObjectDelete(0,"HH_1");
   ObjectDelete(0,"HH_2");
   ObjectDelete(0,"HH_3");
   ObjectDelete(0,"HH_4");
   ObjectDelete(0,"HH_5");
   ObjectDelete(0,"HH_1r");
   ObjectDelete(0,"HH_2r");
   ObjectDelete(0,"HH_3r");
   ObjectDelete(0,"HH_4r");
//---  
   ObjectDelete(0,"1 Bar Highest Close");
   ObjectDelete(0,"2 Bar Highest Close");
   ObjectDelete(0,"3 Bar Highest Close");
   ObjectDelete(0,"4 Bar Highest Close");
   ObjectDelete(0,"5 Bar Highest Close");
//---   
   ObjectDelete(0,"LL_1");
   ObjectDelete(0,"LL_2");
   ObjectDelete(0,"LL_3");
   ObjectDelete(0,"LL_4");
   ObjectDelete(0,"LL_5");
   ObjectDelete(0,"LL_1r");
   ObjectDelete(0,"LL_2r");
   ObjectDelete(0,"LL_3r");
   ObjectDelete(0,"LL_4r");
//---   
   ObjectDelete(0,"1 Bar Lowest Close");
   ObjectDelete(0,"2 Bar Lowest Close");
   ObjectDelete(0,"3 Bar Lowest Close");
   ObjectDelete(0,"4 Bar Lwest Close");
   ObjectDelete(0,"5 Bar Lowest Close");
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
//---
   if(rates_total<int(KLPeriod)) return(RESET);
//---
   if(CopyClose(Symbol(),Timeframe1,1,KLPeriod,iClose)<=0) return(RESET);
   double hhmd1=iClose[ArrayMaximum(iClose,0,KLPeriod)];
   double llmd1=iClose[ArrayMinimum(iClose,0,KLPeriod)];
//---
   if(CopyClose(Symbol(),Timeframe2,1,KLPeriod,iClose)<=0) return(RESET);
   double hhmd2=iClose[ArrayMaximum(iClose,0,KLPeriod)];
   double llmd2=iClose[ArrayMinimum(iClose,0,KLPeriod)];
//---
   if(CopyClose(Symbol(),Timeframe3,1,KLPeriod,iClose)<=0) return(RESET);
   double hhmd3=iClose[ArrayMaximum(iClose,0,KLPeriod)];
   double llmd3=iClose[ArrayMinimum(iClose,0,KLPeriod)];
//---
   if(CopyClose(Symbol(),Timeframe4,1,KLPeriod,iClose)<=0) return(RESET);
   double hhmd4=iClose[ArrayMaximum(iClose,0,KLPeriod)];
   double llmd4=iClose[ArrayMinimum(iClose,0,KLPeriod)];
//---
   if(CopyClose(Symbol(),Timeframe5,1,KLPeriod,iClose)<=0) return(RESET);
   double hhmd5=iClose[ArrayMaximum(iClose,0,KLPeriod)];
   double llmd5=iClose[ArrayMinimum(iClose,0,KLPeriod)];
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(time,true);
//---
   SetTline(0,"HH_1",0,time[50],hhmd1,time[40],hhmd1,UpColor,0,4,"HH_1");
   SetTline(0,"HH_2",0,time[40],hhmd2,time[30],hhmd2,UpColor,0,4,"HH_2");
   SetTline(0,"HH_3",0,time[30],hhmd3,time[20],hhmd3,UpColor,0,4,"HH_3");
   SetTline(0,"HH_4",0,time[20],hhmd4,time[10],hhmd4,UpColor,0,4,"HH_4");
   SetTline(0,"HH_5",0,time[10],hhmd5,time[00],hhmd5,UpColor,0,4,"HH_5");
//---
   SetTline(0,"HH_1r",0,time[40],hhmd1,time[0],hhmd1,UpColor,1,0,"HH_1r");
   SetTline(0,"HH_2r",0,time[30],hhmd2,time[0],hhmd2,UpColor,1,0,"HH_2r");
   SetTline(0,"HH_3r",0,time[20],hhmd3,time[0],hhmd3,UpColor,1,0,"HH_3r");
   SetTline(0,"HH_4r",0,time[10],hhmd4,time[0],hhmd4,UpColor,1,0,"HH_4r");
//---
   CreateText(0,"1 Bar Highest Close",0,time[45],hhmd1,Lbh1,UpColor,"Georgia",TextSize,ANCHOR_LOWER);
   CreateText(0,"2 Bar Highest Close",0,time[35],hhmd2,Lbh2,UpColor,"Georgia",TextSize,ANCHOR_LOWER);
   CreateText(0,"3 Bar Highest Close",0,time[25],hhmd3,Lbh3,UpColor,"Georgia",TextSize,ANCHOR_LOWER);
   CreateText(0,"4 Bar Highest Close",0,time[15],hhmd4,Lbh4,UpColor,"Georgia",TextSize,ANCHOR_LOWER);
   CreateText(0,"5 Bar Highest Close",0,time[05],hhmd5,Lbh5,UpColor,"Georgia",TextSize,ANCHOR_LOWER);
//---
   SetTline(0,"LL_1",0,time[50],llmd1,time[40],llmd1,DnColor,0,4,"LL_1");
   SetTline(0,"LL_2",0,time[40],llmd2,time[30],llmd2,DnColor,0,4,"LL_2");
   SetTline(0,"LL_3",0,time[30],llmd3,time[20],llmd3,DnColor,0,4,"LL_3");
   SetTline(0,"LL_4",0,time[20],llmd4,time[10],llmd4,DnColor,0,4,"LL_4");
   SetTline(0,"LL_5",0,time[10],llmd5,time[00],llmd5,DnColor,0,4,"LL_5");
//---
   SetTline(0,"LL_1r",0,time[40],llmd1,time[0],llmd1,DnColor,1,0,"LL_1r");
   SetTline(0,"LL_2r",0,time[30],llmd2,time[0],llmd2,DnColor,1,0,"LL_2r");
   SetTline(0,"LL_3r",0,time[20],llmd3,time[0],llmd3,DnColor,1,0,"LL_3r");
   SetTline(0,"LL_4r",0,time[10],llmd4,time[0],llmd4,DnColor,1,0,"LL_4r");
//---
   CreateText(0,"1 Bar Lowest Close",0,time[45],llmd1,Lbl1,DnColor,"Georgia",TextSize,ANCHOR_LOWER);
   CreateText(0,"2 Bar Lowest Close",0,time[35],llmd2,Lbl2,DnColor,"Georgia",TextSize,ANCHOR_LOWER);
   CreateText(0,"3 Bar Lowest Close",0,time[25],llmd3,Lbl3,DnColor,"Georgia",TextSize,ANCHOR_LOWER);
   CreateText(0,"4 Bar Lowest Close",0,time[15],llmd4,Lbl4,DnColor,"Georgia",TextSize,ANCHOR_LOWER);
   CreateText(0,"5 Bar Lowest Close",0,time[05],llmd5,Lbl5,DnColor,"Georgia",TextSize,ANCHOR_LOWER);
//---
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+