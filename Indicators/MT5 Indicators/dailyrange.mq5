//+------------------------------------------------------------------+
//|                                                   DailyRange.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_type1 DRAW_LINE
#property indicator_color1 Red
#property indicator_label1 "Daily Range Up"

#property indicator_type2 DRAW_LINE
#property indicator_color2 Blue
#property indicator_label2 "Daily Range Down"

double up[],dn[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,up,INDICATOR_DATA);
   SetIndexBuffer(1,dn,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,2);
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
   //-- house keeping 
   int limit,copied;
   datetime start=D'2010.1.1';
   if(prev_calculated==0)
      limit=0;
   else limit=prev_calculated-1;
   
   //--copy data
   datetime dayTime[];
   double dayHigh[],dayLow[];
   copied=CopyTime(_Symbol,PERIOD_D1,start,time[rates_total-1],dayTime);
   if(copied<=0) return -1;
   copied=CopyHigh(_Symbol,PERIOD_D1,start,time[rates_total-1],dayHigh);
   if(copied<=0) return -1;
   copied=CopyLow(_Symbol,PERIOD_D1,start,time[rates_total-1],dayLow);
   if(copied<=0) return -1;

   //-- calculate indicators
   MqlDateTime mdtDay,mdt;
   for(int i=limit; i<rates_total; i++)
     {
      TimeToStruct(time[i],mdt);
      for(int j=0; j<copied; j++)
        {
         TimeToStruct(dayTime[j],mdtDay);
         if(mdtDay.day==mdt.day)
           {
            up[i] = dayHigh[j];
            dn[i] = dayLow[j];
           }
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
