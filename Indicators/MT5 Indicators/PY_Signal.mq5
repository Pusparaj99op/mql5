//+------------------------------------------------------------------+
//|                                                    PY_Signal.mq5 |
//|                                              I Made Purnama Yasa |
//|                                      imade.purnamayasa@gmail.com |
//+------------------------------------------------------------------+
#property copyright "I Made Purnama Yasa"
#property link      "imade.purnamayasa@gmail.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//---
int b,s,n;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- indicator buffers mapping
   //---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   //---
   b=0;s=0;n=0;
   //---
   int x,y;
   //---
   x=190;
   y=12;
   GuiHeader(PERIOD_M5,x=x-20,y);
   GuiHeader(PERIOD_M15,x=x-20,y);
   GuiHeader(PERIOD_M30,x=x-20,y);
   GuiHeader(PERIOD_H1,x=x-20,y);
   GuiHeader(PERIOD_H4,x=x-20,y);
   GuiHeader(PERIOD_D1,x=x-20,y);
   GuiHeader(PERIOD_W1,x=x-20,y);
   GuiHeader(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   Price(PERIOD_M5,x=x-20,y);
   Price(PERIOD_M15,x=x-20,y);
   Price(PERIOD_M30,x=x-20,y);
   Price(PERIOD_H1,x=x-20,y);
   Price(PERIOD_H4,x=x-20,y);
   Price(PERIOD_D1,x=x-20,y);
   Price(PERIOD_W1,x=x-20,y);
   Price(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   SMA5(PERIOD_M5,x=x-20,y);
   SMA5(PERIOD_M15,x=x-20,y);
   SMA5(PERIOD_M30,x=x-20,y);
   SMA5(PERIOD_H1,x=x-20,y);
   SMA5(PERIOD_H4,x=x-20,y);
   SMA5(PERIOD_D1,x=x-20,y);
   SMA5(PERIOD_W1,x=x-20,y);
   SMA5(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   SMA10(PERIOD_M5,x=x-20,y);
   SMA10(PERIOD_M15,x=x-20,y);
   SMA10(PERIOD_M30,x=x-20,y);
   SMA10(PERIOD_H1,x=x-20,y);
   SMA10(PERIOD_H4,x=x-20,y);
   SMA10(PERIOD_D1,x=x-20,y);
   SMA10(PERIOD_W1,x=x-20,y);
   SMA10(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   SMA20(PERIOD_M5,x=x-20,y);
   SMA20(PERIOD_M15,x=x-20,y);
   SMA20(PERIOD_M30,x=x-20,y);
   SMA20(PERIOD_H1,x=x-20,y);
   SMA20(PERIOD_H4,x=x-20,y);
   SMA20(PERIOD_D1,x=x-20,y);
   SMA20(PERIOD_W1,x=x-20,y);
   SMA20(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   SMA50(PERIOD_M5,x=x-20,y);
   SMA50(PERIOD_M15,x=x-20,y);
   SMA50(PERIOD_M30,x=x-20,y);
   SMA50(PERIOD_H1,x=x-20,y);
   SMA50(PERIOD_H4,x=x-20,y);
   SMA50(PERIOD_D1,x=x-20,y);
   SMA50(PERIOD_W1,x=x-20,y);
   SMA50(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   SMA100(PERIOD_M5,x=x-20,y);
   SMA100(PERIOD_M15,x=x-20,y);
   SMA100(PERIOD_M30,x=x-20,y);
   SMA100(PERIOD_H1,x=x-20,y);
   SMA100(PERIOD_H4,x=x-20,y);
   SMA100(PERIOD_D1,x=x-20,y);
   SMA100(PERIOD_W1,x=x-20,y);
   SMA100(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   SMA200(PERIOD_M5,x=x-20,y);
   SMA200(PERIOD_M15,x=x-20,y);
   SMA200(PERIOD_M30,x=x-20,y);
   SMA200(PERIOD_H1,x=x-20,y);
   SMA200(PERIOD_H4,x=x-20,y);
   SMA200(PERIOD_D1,x=x-20,y);
   SMA200(PERIOD_W1,x=x-20,y);
   SMA200(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   STO(PERIOD_M5,x=x-20,y);
   STO(PERIOD_M15,x=x-20,y);
   STO(PERIOD_M30,x=x-20,y);
   STO(PERIOD_H1,x=x-20,y);
   STO(PERIOD_H4,x=x-20,y);
   STO(PERIOD_D1,x=x-20,y);
   STO(PERIOD_W1,x=x-20,y);
   STO(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   RSI(PERIOD_M5,x=x-20,y);
   RSI(PERIOD_M15,x=x-20,y);
   RSI(PERIOD_M30,x=x-20,y);
   RSI(PERIOD_H1,x=x-20,y);
   RSI(PERIOD_H4,x=x-20,y);
   RSI(PERIOD_D1,x=x-20,y);
   RSI(PERIOD_W1,x=x-20,y);
   RSI(PERIOD_MN1,x=x-20,y);
   //---
   x=190;
   y=y+12;
   GuiFooter(PERIOD_M5,x=x-20,y);
   //GuiFooter(PERIOD_M15,x=x-20,y);
   //GuiFooter(PERIOD_M30,x=x-20,y);
   //GuiFooter(PERIOD_H1,x=x-20,y);
   //GuiFooter(PERIOD_H4,x=x-20,y);
   //GuiFooter(PERIOD_D1,x=x-20,y);
   //GuiFooter(PERIOD_W1,x=x-20,y);
   //GuiFooter(PERIOD_MN1,x=x-20,y);
   //--- return value of prev_calculated for next call
   return(rates_total);
}

void GuiHeader(ENUM_TIMEFRAMES period,int x,int y){
   string basename="TIME";
   string name=basename+EnumToString(period);
   string label=EnumToString(period);
   StringReplace(label,"PERIOD_","");
   LabelDelete(0,name);
   LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,label,"Arial",7,clrYellow,0,ANCHOR_LEFT_UPPER);
}

void GuiFooter(ENUM_TIMEFRAMES period,int x,int y)
{
   string basenameb="TOTALB";
   string nameb=basenameb+EnumToString(period);
   y=y+12;
   LabelDelete(0,nameb);
   LabelCreate(0,nameb,0,x,y,CORNER_RIGHT_UPPER,(string)b,"Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   LabelDelete(0,basenameb);
   LabelCreate(0,basenameb,0,225,y,CORNER_RIGHT_UPPER,"TOTAL(B)","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
   
   string basenames="TOTALS";
   string names=basenames+EnumToString(period);
   y=y+12;
   LabelDelete(0,names);
   LabelCreate(0,names,0,x,y,CORNER_RIGHT_UPPER,(string)s,"Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   LabelDelete(0,basenames);
   LabelCreate(0,basenames,0,225,y,CORNER_RIGHT_UPPER,"TOTAL(S)","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
   
   string basenamen="TOTALN";
   string namen=basenamen+EnumToString(period);
   y=y+12;
   LabelDelete(0,namen);
   LabelCreate(0,namen,0,x,y,CORNER_RIGHT_UPPER,(string)n,"Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   LabelDelete(0,basenamen);
   LabelCreate(0,basenamen,0,225,y,CORNER_RIGHT_UPPER,"TOTAL(N)","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
}

void Price(ENUM_TIMEFRAMES period,int x,int y)
{
   string basename="PRICE";
   string name=basename+EnumToString(period);
   MqlRates rates[2];
   CopyRates(Symbol(),period,0,2,rates);
   if(rates[0].open<rates[0].close){
      b++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"B","Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   }else if(rates[0].open>rates[0].close){
      LabelDelete(0,name);
      s++;
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"S","Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   }else{
      n++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"N","Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   }
   LabelDelete(0,basename);
   LabelCreate(0,basename,0,225,y,CORNER_RIGHT_UPPER,"PRICE","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
}

void SMA5(ENUM_TIMEFRAMES period,int x,int y)
{
   string basename="SMA5";
   string name=basename+EnumToString(period);
   MqlRates rates[1];
   CopyRates(Symbol(),period,0,1,rates);
   int handle;
   double ma[1];
   handle=iMA(Symbol(),period,5,0,MODE_SMA,PRICE_CLOSE);
   CopyBuffer(handle,0,0,1,ma);
   if(rates[0].close>ma[0]){
      b++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"B","Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   }else if(rates[0].close<ma[0]){
      s++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"S","Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   }else{
      n++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"N","Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   }
   LabelDelete(0,basename);
   LabelCreate(0,basename,0,225,y,CORNER_RIGHT_UPPER,"SMA(5)","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
}

void SMA10(ENUM_TIMEFRAMES period,int x,int y)
{
   string basename="SMA10";
   string name=basename+EnumToString(period);
   MqlRates rates[1];
   CopyRates(Symbol(),period,0,1,rates);
   int handle;
   double ma[1];
   handle=iMA(Symbol(),period,10,0,MODE_SMA,PRICE_CLOSE);
   CopyBuffer(handle,0,0,1,ma);
   if(rates[0].close>ma[0]){
      b++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"B","Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   }else if(rates[0].close<ma[0]){
      s++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"S","Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   }else{
      n++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"N","Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   }
   LabelDelete(0,basename);
   LabelCreate(0,basename,0,225,y,CORNER_RIGHT_UPPER,"SMA(10)","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
}

void SMA20(ENUM_TIMEFRAMES period,int x,int y)
{
   string basename="SMA20";
   string name=basename+EnumToString(period);
   MqlRates rates[1];
   CopyRates(Symbol(),period,0,1,rates);
   int handle;
   double ma[1];
   handle=iMA(Symbol(),period,20,0,MODE_SMA,PRICE_CLOSE);
   CopyBuffer(handle,0,0,1,ma);
   if(rates[0].close>ma[0]){
      b++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"B","Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   }else if(rates[0].close<ma[0]){
      s++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"S","Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   }else{
      n++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"N","Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   }
   LabelDelete(0,basename);
   LabelCreate(0,basename,0,225,y,CORNER_RIGHT_UPPER,"SMA(20)","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
}

void SMA50(ENUM_TIMEFRAMES period,int x,int y)
{
   string basename="SM50";
   string name=basename+EnumToString(period);
   MqlRates rates[1];
   CopyRates(Symbol(),period,0,1,rates);
   int handle;
   double ma[1];
   handle=iMA(Symbol(),period,50,0,MODE_SMA,PRICE_CLOSE);
   CopyBuffer(handle,0,0,1,ma);
   if(rates[0].close>ma[0]){
      b++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"B","Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   }else if(rates[0].close<ma[0]){
      s++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"S","Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   }else{
      n++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"N","Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   }
   LabelDelete(0,basename);
   LabelCreate(0,basename,0,225,y,CORNER_RIGHT_UPPER,"SMA(50)","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
}

void SMA100(ENUM_TIMEFRAMES period,int x,int y)
{
   string basename="SM100";
   string name=basename+EnumToString(period);
   MqlRates rates[1];
   CopyRates(Symbol(),period,0,1,rates);
   int handle;
   double ma[1];
   handle=iMA(Symbol(),period,100,0,MODE_SMA,PRICE_CLOSE);
   CopyBuffer(handle,0,0,1,ma);
   if(rates[0].close>ma[0]){
      b++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"B","Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   }else if(rates[0].close<ma[0]){
      s++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"S","Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   }else{
      n++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"N","Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   }
   LabelDelete(0,basename);
   LabelCreate(0,basename,0,225,y,CORNER_RIGHT_UPPER,"SMA(100)","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
}

void SMA200(ENUM_TIMEFRAMES period,int x,int y)
{
   string basename="SM5200";
   string name=basename+EnumToString(period);
   MqlRates rates[1];
   CopyRates(Symbol(),period,0,1,rates);
   int handle;
   double ma[1];
   handle=iMA(Symbol(),period,200,0,MODE_SMA,PRICE_CLOSE);
   CopyBuffer(handle,0,0,1,ma);
   if(rates[0].close>ma[0]){
      b++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"B","Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   }else if(rates[0].close<ma[0]){
      s++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"S","Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   }else{
      n++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"N","Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   }
   LabelDelete(0,basename);
   LabelCreate(0,basename,0,225,y,CORNER_RIGHT_UPPER,"SMA(200)","Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
}

void STO(ENUM_TIMEFRAMES period,int x,int y)
{
   string basename="STO";
   string name=basename+EnumToString(period);
   int handle;
   double sto[1];
   handle=iStochastic(Symbol(),period,14,3,3,MODE_SMA,STO_LOWHIGH);
   CopyBuffer(handle,SIGNAL_LINE,0,1,sto);
   if(sto[0]<20){
      b++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"B","Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   }else if(sto[0]>80){
      s++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"S","Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   }else{
      n++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"N","Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   }
   LabelDelete(0,basename);
   LabelCreate(0,basename,0,225,y,CORNER_RIGHT_UPPER,basename,"Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
} 

void RSI(ENUM_TIMEFRAMES period,int x,int y)
{
   string basename="RSI";
   string name=basename+EnumToString(period);
   int handle;
   double rsi[1];
   handle=iRSI(Symbol(),period,14,PRICE_CLOSE);
   CopyBuffer(handle,SIGNAL_LINE,0,1,rsi);
   if(rsi[0]<30){
      b++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"B","Arial",7,clrBlue,0,ANCHOR_LEFT_UPPER);
   }else if(rsi[0]>70){
      s++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"S","Arial",7,clrRed,0,ANCHOR_LEFT_UPPER);
   }else{
      n++;
      LabelDelete(0,name);
      LabelCreate(0,name,0,x,y,CORNER_RIGHT_UPPER,"N","Arial",7,clrWhite,0,ANCHOR_LEFT_UPPER);
   }
   LabelDelete(0,basename);
   LabelCreate(0,basename,0,225,y,CORNER_RIGHT_UPPER,basename,"Arial",7,clrAqua,0,ANCHOR_LEFT_UPPER);
} 
  
//+------------------------------------------------------------------+
//| Create a text label                                              |
//+------------------------------------------------------------------+
bool LabelCreate(const long              chart_ID=0,               // chart's ID
                 const string            name="Label",             // label name
                 const int               sub_window=0,             // subwindow index
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                 const string            text="Label",             // text
                 const string            font="Arial",             // font
                 const int               font_size=10,             // font size
                 const color             clr=clrRed,               // color
                 const double            angle=0.0,                // text slope
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                 const bool              back=false,               // in the background
                 const bool              selection=false,          // highlight to move
                 const bool              hidden=true,              // hidden in the object list
                 const long              z_order=0)                // priority for mouse click
  {
   //--- reset the error value
   ResetLastError();
   //--- create a text label
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      return(false);
     }
   //--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   //--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
   //--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   //--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   //--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   //--- set the slope angle of the text
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
   //--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
   //--- set color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   //--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   //--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   //--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   //--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   //--- successful execution
   return(true);
}

//+------------------------------------------------------------------+
//| Delete a text label                                              |
//+------------------------------------------------------------------+
bool LabelDelete(const long   chart_ID=0,   // chart's ID
                 const string name="Label") // label name
{
   //--- reset the error value
   ResetLastError();
   //--- delete the label
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete a text label! Error code = ",GetLastError());
      return(false);
     }
   //--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
