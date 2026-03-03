//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright   "Money-Meter (by Transcendreamer)"
#property description "Chart evaluation in deposit currency"
#property strict
#property indicator_chart_window
#property indicator_plots 0
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double            grid_step_value=100;
input double            lot_size=0.1;
input double            lot_divider=1;
input double            total_levels=50;
input double            zero_price=0;
enum  PROGRESSION       {none,equal,linear,fibo,martin};
input PROGRESSION       progression=none;
input double            multiplicator=2;
input color             lines_color=clrMagenta;
input int               lines_width=1;
input ENUM_LINE_STYLE   lines_style=STYLE_SOLID;
input bool              lines_prices=false;
input int               text_shift_bars=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   clean_all();
   make_grid();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   clean_all();
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void clean_all()
  {
   for(int k=ObjectsTotal(0,0,OBJ_HLINE)-1; k>=0; k--)
     {
      string name=ObjectName(0,k,0,OBJ_HLINE);
      if(StringFind(name,"GRID_LEVEL_")!=-1)
         ObjectDelete(0,name);
     }
   for(int k=ObjectsTotal(0,0,OBJ_TEXT)-1; k>=0; k--)
     {
      string name=ObjectName(0,k,0,OBJ_TEXT);
      if(StringFind(name,"GRID_TEXT_")!=-1)
         ObjectDelete(0,name);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void make_grid()
  {
   double ts=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tv=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double step=grid_step_value/tv*ts/lot_size/lot_divider;
   double zero=zero_price?zero_price:iClose(NULL,0,0);
//---
   datetime time;
   if(text_shift_bars>=0)
      time=iTime(NULL,0,text_shift_bars);
   else
      time=iTime(NULL,0,0)-PeriodSeconds(PERIOD_CURRENT)*text_shift_bars;
//---
   put_level("GRID_LEVEL_ZERO",zero,"(ZERO)");
   put_text("GRID_TEXT_ZERO",zero,time,"(ZERO)");
   for(int n=1; n<=total_levels; n++)
     {
      double value=grid_step_value*get_progression(n);
      string text=DoubleToString(value,2);
      put_level("GRID_LEVEL_UP"+string(n),zero+step*n,"+"+text);
      put_level("GRID_LEVEL_DN"+string(n),zero-step*n,"-"+text);
      put_text("GRID_TEXT_UP"+string(n),zero+step*n,time,"+"+text);
      put_text("GRID_TEXT_DN"+string(n),zero-step*n,time,"-"+text);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_progression(int n)
  {
   if(progression==none) return(n);
   double sum=0;
   for(int k=1; k<=n; k++)
      sum+=(n-k+1)*get_member(k);
   return(sum);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_member(int k)
  {
   if(progression==equal)
     {
      return(1);
     }
   else if(progression==fibo)
     {
      if(k<3) return(1);
      int f=1,s=1;
      while(k>2) { f=f+s*2; s=f-s; f=f-s; k--; }
      return(s);
     }
   else if(progression==martin)
     {
      return(MathPow(multiplicator,k-1));
     }
   else if(progression==linear)
     {
      return(k);
     }
   return(1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void put_level(string name,double price,string text)
  {
   ObjectCreate(0,name,OBJ_HLINE,0,0,0);
   ObjectSetDouble(0,name,OBJPROP_PRICE,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,lines_color);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,lines_width);
   ObjectSetInteger(0,name,OBJPROP_STYLE,lines_style);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,!lines_prices);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void put_text(string name,double price,datetime time,string text)
  {
   ObjectCreate(0,name,OBJ_TEXT,0,0,0);
   ObjectSetDouble(0,name,OBJPROP_PRICE,price);
   ObjectSetInteger(0,name,OBJPROP_TIME,0,time);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,"Verdana");
   ObjectSetInteger(0,name,OBJPROP_COLOR,lines_color);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
  }
//+------------------------------------------------------------------+
