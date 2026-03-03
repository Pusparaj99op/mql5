//+------------------------------------------------------------------+ 
//|                                          Laguerre_HTF_Signal.mq5 | 
//|                               Copyright © 2011, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//--- indicator version
#property version   "1.00"
//+----------------------------------------------+ 
//|  Indicator drawing parameters                |
//+----------------------------------------------+ 
//--- drawing the indicator in the main window
#property indicator_chart_window 
#property indicator_buffers 1
#property indicator_plots   1
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET  0 // the constant for getting the command for the indicator recalculation back to the terminal
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input string Symbol_="";                   // Financial asset
input ENUM_TIMEFRAMES Timeframe=PERIOD_H6; // Indicator timeframe for the indicator calculation
input double gamma=0.7;                    // Sensibility
input int HighLevel=85;                    // Overbought level
input int MiddleLevel=50;                  // Middle level
input int LowLevel=15;                     // Oversold level
//--- indicator display settings
input uint SignalBar=0;                                // Signal bar index, 0 is a current bar
input string Symbols_Sirname="Laguerre_Label_";        // Indicator labels name
input color UpSymbol_Color=Yellow;                     // Growth symbol color
input color DnSymbol_Color=Magenta;                    // Downfall symbol color
input color IndName_Color=DarkOrchid;                  // Indicator name color
input uint Symbols_Size=60;                            // Signal symbols size
input uint Font_Size=10;                               // Indicator name font size
input int X_1=5;                                       // Horizontal shift of the name
input int Y_1=-15;                                     // Vertical shift of the name
input bool ShowIndName=true;                           // Indicator name display
input ENUM_BASE_CORNER  WhatCorner=CORNER_RIGHT_UPPER; // Location corner
input uint X_=0;                                       // Horizontal shift
input uint Y_=20;                                      // Vertical shift
//+-----------------------------------+
//--- declaration of integer variables for the indicators handles
int Laguerre_Handle;
//--- declaration of the integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables of the indices horizontal and vertical location
uint X_0,Yn,X_1_,Y_1_;
//--- declaration of variables for labels names
string name0,name1,IndName,Symb;
//+------------------------------------------------------------------+
//|  Getting a timeframe as a line                                   |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {
//---
   return(StringSubstr(EnumToString(timeframe),7,-1));
//---
  }
//+------------------------------------------------------------------+
//|  Creation of a text label                                        |
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
  {
//---
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
//---
  }
//+------------------------------------------------------------------+
//|  Text label reinstallation                                       |
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
  {
//---
   if(ObjectFind(chart_id,name)==-1)
     {
      CreateTLabel(chart_id,name,nwin,corner,point,X,Y,text,Color,Font,Size);
     }
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,X);
      ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,Y);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
      ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,Size);
     }
//---
  }
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(10+SignalBar);
//--- initialization of variables
   if(Symbol_!="") Symb=Symbol_;
   else Symb=Symbol();
//---
   X_0=X_;
   Yn=Y_+5;
//---
   name0=Symbols_Sirname+"0";
   if(ShowIndName)
     {
      Y_1_=Yn+Y_1;
      X_1_=X_0+X_1;
      name1=Symbols_Sirname+"1";
      StringConcatenate(IndName,"Laguerre(",Symb," ",GetStringTimeframe(Timeframe),")");
     }
//--- getting handle of the Laguerre indicator
   Laguerre_Handle=iCustom(Symb,Timeframe,"ColorLaguerre",gamma,HighLevel,MiddleLevel,LowLevel);
   if(Laguerre_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the Laguerre indicator");
      return(INIT_FAILED);
     }
//--- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"Laguerre");
//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void Deinit()
  {
//---
   if(ObjectFind(0,name0)!=-1) ObjectDelete(0,name0);
   if(ObjectFind(0,name1)!=-1) ObjectDelete(0,name1);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//---
   Deinit();
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
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- checking the number of bars to be enough for the calculation
   if(BarsCalculated(Laguerre_Handle)<min_rates_total) return(RESET);
   if(BarsCalculated(Laguerre_Handle)<Bars(Symb,Timeframe)) return(prev_calculated);
//---
   int limit=rates_total-prev_calculated;
   if(limit<int(SignalBar) && limit>=0) return(rates_total);
//--- declaration of local variables
   double LEGUERRE[2];
   color Color0=clrNONE;
   string SignSymbol;
//--- copy newly appeared data in the array 
   if(CopyBuffer(Laguerre_Handle,1,SignalBar,2,LEGUERRE)<=0) return(RESET);
//---
   if(LEGUERRE[1]==1)
     {
      Color0=UpSymbol_Color;
      if(LEGUERRE[0]==2) SignSymbol="è";
      else               SignSymbol="â";
     }
//---
   if(LEGUERRE[1]==2)
     {
      Color0=DnSymbol_Color;
      if(LEGUERRE[0]==1) SignSymbol="ä";
      else               SignSymbol="â";
     }
//--- creation of trend symbols or deals signals
   if(ShowIndName)
      SetTLabel(0,name1,0,WhatCorner,ENUM_ANCHOR_POINT(2*WhatCorner),X_1_,Y_1_,IndName,IndName_Color,"Georgia",Font_Size);
   SetTLabel(0,name0,0,WhatCorner,ENUM_ANCHOR_POINT(2*WhatCorner),X_0,Yn,SignSymbol,Color0,"Wingdings 3",Symbols_Size);
//---
   ChartRedraw(0);
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
