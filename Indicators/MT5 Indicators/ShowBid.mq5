//+------------------------------------------------------------------+
//|                                                      ShowBid.mq5 |
//|                                       Copyright 2014,Viktor Moss |
//|                           https://login.mql5.com/ru/users/vicmos |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014,Viktor Moss"
#property link      "https://login.mql5.com/ru/users/vicmos"
#property version   "1.10"
#property indicator_chart_window
#property indicator_plots 0

input color Color=clrYellow;  //Color
input int   Width=3;          //Size (1-5)
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|  Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0,"ShowBid");
   ChartRedraw();
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---

   SetLevelLeft(_Symbol);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Expert chart event function                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // event ID  
                  const long& lparam,   // event parameter of the long type
                  const double& dparam, // event parameter of the double type
                  const string& sparam) // event parameter of the string type
  {
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      SetLevelLeft(_Symbol);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetLevelLeft(string smb,long chid=0)
  {
   int np;
   datetime dt;
   double pr;
   ChartXYToTimePrice(chid,(int)ChartGetInteger(chid,CHART_WIDTH_IN_PIXELS),30,np,dt,pr);
   double PriceBid=SymbolInfoDouble(smb,SYMBOL_BID);
   if(ObjectFind(chid,"ShowBid")!=0)
     {
      ObjectCreate(chid,"ShowBid",OBJ_ARROW_LEFT_PRICE,0,dt,PriceBid);
      ObjectSetInteger(chid,"ShowBid",OBJPROP_WIDTH,Width);
      ObjectSetInteger(chid,"ShowBid",OBJPROP_COLOR,Color);
      return;
     }
   ObjectSetDouble(chid,"ShowBid",OBJPROP_PRICE,PriceBid);
   ObjectSetInteger(chid,"ShowBid",OBJPROP_TIME,dt);
   ObjectSetInteger(chid,"ShowBid",OBJPROP_COLOR,Color);
   ObjectSetInteger(chid,"ShowBid",OBJPROP_WIDTH,Width);
   ChartRedraw();
  }
//+------------------------------------------------------------------+
