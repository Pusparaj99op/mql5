//+------------------------------------------------------------------+
//|                                                        Clock.mq5 |
//|                                       Copyright 2013,Viktor Moss |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013,Viktor Moss"
#property link      "https://login.mql5.com/users/vicmos"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum VT 
  {
   LocalTime  = 0,
   ServerTime = 1
  };

//--- input parameters
input VT Zone=LocalTime;   //Time
input int X=200; // Shift from the right edge
input color TextColor=clrMagenta;
MqlDateTime tt;
string Date,Time,Spread;
int Spr;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetMillisecondTimer(250);
   if(Zone==LocalTime) Time=TimeToString(TimeLocal(tt),TIME_SECONDS);
   else Time=TimeToString(TimeCurrent(tt),TIME_SECONDS);
   Date=DayOfWeek(tt.day_of_week)+" "+IntegerToString(tt.day)+" "+Month(tt.mon)+" "+IntegerToString(tt.year)+" ã.";
   Spread="Spread  "+IntegerToString(Spr);
   string St="  Stop level  "+IntegerToString(SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL));
   SetText("Clock_ind-2",Time,X,40,TextColor,11);
   SetText("Clock_ind-1",Date,X,60,TextColor,11);
   SetText("Clock_ind-3",Spread+St,X,80,TextColor,11);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   DelAllObjects("Clock_ind-");
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
   ArraySetAsSeries(spread,true);
//   Spr = spread[0];
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if(Zone==LocalTime) Time=TimeToString(TimeLocal(tt),TIME_SECONDS);
   else Time=TimeToString(TimeCurrent(tt),TIME_SECONDS);
   Date=DayOfWeek(tt.day_of_week)+" "+IntegerToString(tt.day)+" "+Month(tt.mon)+" "+IntegerToString(tt.year)+" ã.";
   Spr=(int)SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);// spread[0];
   Spread="Spread  "+IntegerToString(Spr);
   string St="   Stop level  "+IntegerToString(SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL));
   SetText("Clock_ind-2",Time,X,40,TextColor,11);
   SetText("Clock_ind-1",Date,X,60,TextColor,11);
   SetText("Clock_ind-3",Spread+St,X,80,TextColor,11);
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DayOfWeek(int i) 
  {
   string D[7]={"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"};
   return D[i];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Month(int i) 
  {
   string M[12]={"January","February","March","April","May","June","July","August","September","October","November","December"};
   return M[i-1];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetText(string name,string text,int xx,int yy,color col,int r=12) 
  {
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,xx);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,yy);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,r);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_LOWER);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DelAllObjects(string name) 
  {
   string vName;
   int tot=ObjectsTotal(0);
   for(int i=tot; i>=0; i--)
     {
      vName=ObjectName(0,i);
      if(StringSubstr(vName,0,StringLen(name))==name) ObjectDelete(0,vName);
     }
  }

//+------------------------------------------------------------------+
