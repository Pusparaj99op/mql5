//+------------------------------------------------------------------+
//|                                          Value Charts Single.mq5 |
//|                                       Copyright 2015, MagicTech. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2015, written by JJ MagicTech."
#property link      "http://www.jandersonfferreira.info"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_width1  2
#property indicator_label1  "Value"
//--- indicator levels
#property indicator_level1 8
#property indicator_level2 10
#property indicator_level3 -10
#property indicator_level4 -8
#property indicator_level5 12
#property indicator_level6 -12
#property indicator_levelcolor clrGold
//--- indicator include
#include <MovingAverages.mqh>
//--- indicator input parameters
input int   Periode     = 5;
input int   Trigger     = 8;
input bool  Show_Arrow  = true;
input int   Arrow_Width = 5;
input color Arrow_Up    = clrGreen;
input color Arrow_Down  = clrRed;
//--- indicator buffers
double ExtOBuffer[];
double ExtHBuffer[];
double ExtLBuffer[];
double ExtCBuffer[];
double ExtColorBuffer[];
double RangeAverage[];
double MiddleAverage[];

#define DATA_LIMIT Periode 
double _AValue;
double _BValue;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping 
   SetIndexBuffer(0,ExtCBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,RangeAverage,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,MiddleAverage,INDICATOR_CALCULATIONS);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   IndicatorSetString(INDICATOR_SHORTNAME,"Value Chart Single "+IntegerToString(Periode));
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ClearMyObjects();
   Print("Deinit Value Chart, reason = "+IntegerToString(reason));
  }
//+------------------------------------------------------------------+
//| Value Chart                                                      | 
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
   int i,limit;
//--- check for bars count
   if(rates_total<DATA_LIMIT)
      return(0);// not enough bars for calculation

//--- set first bar from what calculation will start
   if(prev_calculated<DATA_LIMIT)
      limit=DATA_LIMIT;
   else
      limit=prev_calculated-1;
//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      RangeAverage[i]=High[i]-Low[i];
      _AValue=0.2*SimpleMA(i,Periode,RangeAverage);
      MiddleAverage[i]=(High[i]+Low[i])/2.0;
      _BValue=SimpleMA(i,Periode,MiddleAverage);
      
      if (_AValue !=0)
         ExtCBuffer[i]=((Close[i]- _BValue) / _AValue);

      //--- set color for candle

     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  Trace Arrow Function                                            |
//+------------------------------------------------------------------+
void Trace(string name,int sens,double price,datetime time,color couleur)
  {
   ObjectCreate(0,name,OBJ_ARROW,0,time,price);
   if(sens==1)
      ObjectSetInteger(0,name,OBJPROP_ARROWCODE,233);
   if(sens==-1)
      ObjectSetInteger(0,name,OBJPROP_ARROWCODE,234);
   ObjectSetInteger(0,name,OBJPROP_COLOR,couleur);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,Arrow_Width);
  }
//+------------------------------------------------------------------+
//|   Delete Arrow Function                                          |
//+------------------------------------------------------------------+  
void ClearMyObjects()
  {
   string name;
   for(int i=ObjectsTotal(0,0); i>=0; i--)
     {
      name=ObjectName(0,i);
      if(StringSubstr(name,0,5)=="Value") ObjectDelete(0,name);
     }
  }
//+------------------------------------------------------------------+
