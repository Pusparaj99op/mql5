//+------------------------------------------------------------------+
//|                                               MFCS GridLines.mq5 |
//|            Copyright 2015, Mansukh Patidar, All rights reserved. |
//|                                    http://www.mansukhpatidar.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Mansukh Patidar, All rights reserved."
#property link      "http://www.mansukhpatidar.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0
//--- input parameters
input int      lines=100;
input int      interval=200;
input ENUM_LINE_STYLE   line_style=STYLE_DOT;
input int   line_width = 1;
input color line_color = C'128, 50, 50';
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClearExistingGridLines()
  {
   int index = 0;
   for(index = 0; index < lines*5; index++)
     {
      string n1 = _Symbol + "_MFCS_GRID_LINES_ABOVE_" + (string)index;
      string n2 = _Symbol + "_MFCS_GRID_LINES_BELOW_" + (string)index;
      ObjectDelete(0,n1);
      int e1=ObjectFind(0,n1);
      ObjectDelete(0,n2);
      int e2=ObjectFind(0,n1);
      //---
      if(e1>=0 || e2>=0)
        {
         printf("error in removing gridlines");
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ClearExistingGridLines();
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ClearExistingGridLines();
//---
   MqlTick last_tick;  //structure for last tick
   SymbolInfoTick(_Symbol,last_tick); //filling last_tick with recent prices
//---
   double base_price= last_tick.ask;
   double pip_value = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   int multipler=(int) pow(10,SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
//---
   long temp_price=(long)(base_price*multipler);
   temp_price=temp_price-temp_price%1000;
//---
   base_price=temp_price*pip_value;
//---
   int index = 0;
   for(index = 0; index < lines; index++)
     {
      double p1 = base_price + index * interval * pip_value;
      double p2 = base_price - index * interval * pip_value;
      string n1 = _Symbol + "_MFCS_GRID_LINES_ABOVE_" + (string)index;
      string n2 = _Symbol + "_MFCS_GRID_LINES_BELOW_" + (string)index;
      //---
      ObjectCreate(0,n1,OBJ_HLINE,0,0,p1);
      ObjectCreate(0,n2,OBJ_HLINE,0,0,p2);
      //---
      bool back=false;
      //--- set line color
      ObjectSetInteger(0,n1,OBJPROP_COLOR,line_color);
      //--- set line display style
      ObjectSetInteger(0,n1,OBJPROP_STYLE,line_style);
      //--- set line width
      ObjectSetInteger(0,n1,OBJPROP_WIDTH,line_width);
      //--- display in the foreground (false) or background (true)
      ObjectSetInteger(0,n1,OBJPROP_BACK,back);
      //--- set line color
      ObjectSetInteger(0,n2,OBJPROP_COLOR,line_color);
      //--- set line display style
      ObjectSetInteger(0,n2,OBJPROP_STYLE,line_style);
      //--- set line width
      ObjectSetInteger(0,n2,OBJPROP_WIDTH,line_width);
      //--- display in the foreground (false) or background (true)
      ObjectSetInteger(0,n2,OBJPROP_BACK,back);
     }
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
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
