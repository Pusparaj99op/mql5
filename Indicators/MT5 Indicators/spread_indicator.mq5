//+------------------------------------------------------------------+
//|                             Spread Indicator                     |
//|                             Copyright © 2013, Mirza Baig         |
//+------------------------------------------------------------------+
#property copyright           "Copyright © 2013, Mirza Baig"
#property version             "1.00"
#property description         "Spread Indicator - displays current spread in the chart window"
#property description         "Changeable font parameters, display location on chart, normalization of pips and points, and alert"

#property indicator_chart_window
#property indicator_plots 0

input color                   font_color           = White;
input int                     font_size            = 20;
input string                  font_face            = "Arial";
input ENUM_ANCHOR_POINT       corner               = ANCHOR_LEFT_UPPER;
input int                     spread_distance_x    = 10;
input int                     spread_distance_y    = 130;
input bool                    normalize=false;       // normalize - If true then the spread is normalized to traditional pips
input double                  AlertIfSpreadAbove=0;  // AlertIfSpreadAbove - If > 0 alert will sound when spread is above the value specified

double Poin;
int n_digits=0;
double divider=1;
bool alert_done=false;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
   IndicatorSetString(INDICATOR_SHORTNAME,"Spread");
//--- checking for unconvetional Point digits number
   if(_Point==0.00001) Poin=0.0001; //5 digits
   else if(_Point==0.001) Poin=0.01; //3 digits
   else Poin=_Point; //Normal
//---
   ObjectCreate(0,"Spread",OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,"Spread",OBJPROP_ANCHOR,corner);
   ObjectSetInteger(0,"Spread",OBJPROP_XDISTANCE,spread_distance_x);
   ObjectSetInteger(0,"Spread",OBJPROP_YDISTANCE,spread_distance_y);
   double spread=(double)SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);
//---
   if((Poin>_Point) && (normalize))
     {
      divider=10.0;
      n_digits=1;
     }
//---
   ObjectSetString(0,"Spread",OBJPROP_TEXT,"Spread: "+DoubleToString(NormalizeDouble(spread/divider,1),n_digits)+" points.");
   ObjectSetString(0,"Spread",OBJPROP_FONT,font_face);
   ObjectSetInteger(0,"Spread",OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(0,"Spread",OBJPROP_COLOR,font_color);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0,"Spread");
  }
//+------------------------------------------------------------------+
//| Data Calculation Function for Indicator                          |
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
   double myspread=(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
//---
   ObjectSetString(0,"Spread",OBJPROP_TEXT,"Spread: "+DoubleToString(NormalizeDouble(myspread/divider,1),n_digits)+" points.");
   ObjectSetString(0,"Spread",OBJPROP_FONT,font_face);
   ObjectSetInteger(0,"Spread",OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(0,"Spread",OBJPROP_COLOR,font_color);
//---
   if(AlertIfSpreadAbove>0)
     {
      if(NormalizeDouble(myspread/divider,1)<AlertIfSpreadAbove) alert_done=false;
      else if(!alert_done)
        {
         PlaySound("alert.wav");
         alert_done=true;
        }
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
