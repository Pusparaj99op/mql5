//+------------------------------------------------------------------+
//|                                           IshimokuOscillator.mq5 |
//|                                              Copyright 2010, Alf |
//|                                      http://forum.liteforex.org/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Alf"
#property link      "http://forum.liteforex.org/"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   2
//--- plot Fist
#property indicator_label1  "Fist"
#property indicator_type1   DRAW_LINE
#property indicator_color1  Yellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Second
#property indicator_label2  "Second"
#property indicator_type2   DRAW_LINE
#property indicator_color2  Red
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      Tankan_sen=9;
input int      Kijun_sen=26;
input int      Senkou_snap_B=52;
//--- indicator buffers
double         FistBuffer[];
double         SecondBuffer[];
double         b1[];
double         b2[];
double         b3[];
double         b4[];
int ish;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,FistBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SecondBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,b1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,b2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,b3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,b4,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(1,PLOT_SHIFT,Kijun_sen);
   ish=iIchimoku(_Symbol,0,Tankan_sen,Kijun_sen,Senkou_snap_B);
   Print("i=",ish);
//---
   return(0);
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
   if(rates_total<Senkou_snap_B)
      return(0);
   int calculated=BarsCalculated(ish);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtFastMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }

   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }

   if(CopyBuffer(ish,0,0,to_copy,b1)<=0)
     {
      Print("ER1 ",to_copy);
      return(0);
     }
   if(CopyBuffer(ish,1,0,to_copy,b2)<=0)
     {
      Print("ER2 ",to_copy);
      return(0);
     }
   if(CopyBuffer(ish,2,0-Kijun_sen,to_copy,b3)<=0)
     {
      Print("ER3 ",to_copy);
      return(0);
     }
   if(CopyBuffer(ish,3,0-Kijun_sen,to_copy,b4)<=0)
     {
      Print("ER4",to_copy);
      return(0);
     }

   for(int i=0;i<rates_total;i++)
     {
      FistBuffer[i]=b1[i]-b2[i];
      SecondBuffer[i]=b3[i]-b4[i];
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
