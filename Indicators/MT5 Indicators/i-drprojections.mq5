//+------------------------------------------------------------------+ 
//|                                              i-DRProjections.mq5 | 
//|                         Copyright © 2005, Ким Игорь В. aka KimIV | 
//|                                              http://www.kimiv.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2005, Kim Igor V. aka KimIV"
#property link "http://www.kimiv.ru"
#property description "The indicator predicts daily price ranges"
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- number of indicator buffers is 2
#property indicator_buffers 2 
//--- one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator drawing parameters   |
//+-----------------------------------+
//--- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//--- the color of the indicator
#property indicator_color1  clrPaleTurquoise
//--- displaying the indicator label
#property indicator_label1  "i-DRProjections"
//+-----------------------------------+
//| Перечисление для толщины уровня   |
//+-----------------------------------+
enum ENUM_WIDTH //Type of constant
  {
   w_1 = 1,   //1
   w_2,       //2
   w_3,       //3
   w_4,       //4
   w_5        //5
  };
//+-----------------------------------+
//| объявление констант               |
//+-----------------------------------+
#define RESET 0
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input string level_name="i-DRProjections";         // The name of the trigger level
input bool ShowTomorrow=true;                      // Show tomorrow
input color up_level_color=clrLime;                // The color of the resistance level
input ENUM_LINE_STYLE up_level_style=STYLE_SOLID;  // The style of the resistance level
input ENUM_WIDTH up_level_width=w_2;               // The width of the resistance level
input color dn_level_color=clrRed;                 // The color of the resistance level
input ENUM_LINE_STYLE dn_level_style=STYLE_SOLID;  // The style of the resistance level
input ENUM_WIDTH dn_level_width=w_2;               // The width of the resistance level
//+-----------------------------------+
string upname,dnname;
//--- declaration of integer variables of data starting point
int  min_rates_total;
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double ExtABuffer[];
double ExtBBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- checking correctness of the chart periods
   if(!TimeFramesCheck(_Period)) return(INIT_FAILED);
//--- initialization of variables of the start of data calculation
   min_rates_total=10;
   upname=level_name+" upper";
   dnname=level_name+" lower";
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtABuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtABuffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,ExtBBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtBBuffer,true);

//--- shift the beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"i-DRProjections");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//--- delete the level, if necessary
   ObjectDelete(0,upname);
   ObjectDelete(0,dnname);
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
//--- declaration of variables with a floating point 
   double x,iOpen[1],iLow[1],iHigh[1],iClose[1];
   static int LastCountBar;
   int limit;
//--- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
     }
   else limit=LastCountBar+rates_total-prev_calculated;  // starting index for the calculation of the new bars only
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(Time,true);
//--- main calculation loop of the indicator
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      int bar1=bar+1;
      MqlDateTime tm0,tm1;
      TimeToStruct(Time[bar],tm0);
      TimeToStruct(Time[bar1],tm1);
      //---
      if(tm1.day_of_week!=tm0.day_of_week)
        {
         LastCountBar=bar;
         ExtABuffer[bar1]=0.0;
         ExtBBuffer[bar1]=0.0;
         //---
         if(CopyOpen(Symbol(),PERIOD_D1,Time[bar1],1,iOpen)<=0) return(RESET);
         if(CopyHigh(Symbol(),PERIOD_D1,Time[bar1],1,iHigh)<=0) return(RESET);
         if(CopyLow(Symbol(),PERIOD_D1,Time[bar1],1,iLow)<=0) return(RESET);
         if(CopyClose(Symbol(),PERIOD_D1,Time[bar1],1,iClose)<=0) return(RESET);
         //---
         x=(iHigh[0]+iLow[0]+iClose[0])/2;
         if(iClose[0]<iOpen[0]) x+=iLow[0]/2;
         if(iClose[0]>iOpen[0]) x+=iHigh[0]/2;
         if(iClose[0]==iOpen[0]) x+=iClose[0]/2;
         //---
         ExtABuffer[bar]=x-iLow[0];
         ExtBBuffer[bar]=x-iHigh[0];
        }
      else
        {
         ExtABuffer[bar]=ExtABuffer[bar1];
         ExtBBuffer[bar]=ExtBBuffer[bar1];
        }
     }
//---
   if(ShowTomorrow)
     {
      if(CopyOpen(Symbol(),PERIOD_D1,Time[0],1,iOpen)<=0) return(RESET);
      if(CopyHigh(Symbol(),PERIOD_D1,Time[0],1,iHigh)<=0) return(RESET);
      if(CopyLow(Symbol(),PERIOD_D1,Time[0],1,iLow)<=0) return(RESET);
      if(CopyClose(Symbol(),PERIOD_D1,Time[0],1,iClose)<=0) return(RESET);
      //---
      x=(iHigh[0]+iLow[0]+iClose[0])/2;
      if(iClose[0]<iOpen[0]) x+=iLow[0]/2;
      if(iClose[0]>iOpen[0]) x+=iHigh[0]/2;
      if(iClose[0]==iOpen[0]) x+=iClose[0]/2;
      double Min=x-iLow[0];
      double Max=x-iHigh[0];
      //---
      SetTline(0,upname,0,Time[1],Min,TimeCurrent(),Min,up_level_color,up_level_style,up_level_width,upname);
      SetTline(0,dnname,0,Time[1],Max,TimeCurrent(),Max,dn_level_color,dn_level_style,dn_level_width,dnname);
     }
//---
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Creating a trend line                                            |
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
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,true);
//---
  }
//+------------------------------------------------------------------+
//| Resetting a trend line                                           |
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
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//---
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(ENUM_TIMEFRAMES TFrame) //Indicator chart period
  {
//--- checking correctness of the chart periods
   if(TFrame>PERIOD_H12)
     {
      Print("Chart period cannot be greater than H12!");
      Print ("You must change the indicator input parameters!");
      return(RESET);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
