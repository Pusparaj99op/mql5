//+------------------------------------------------------------------+
//|                                        Trendsignal Indicator.mq5 |
//|                                    Copyright 2015, Pankaj Bhaban |
//|                                     http://www.trendsignal.co.in |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Pankaj Bhaban"
#property link      "http://www.trendsignal.co.in"


input int RISK=3; // signal sensitivity control
input int SSP=9;  // signal displacement

int NumberofAlerts=2;

double SellBuffer[];
double BuyBuffer[];

int K;
int counter=0;
bool pre,BT;

#property version   "1.00"
#property indicator_chart_window 
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_ARROW
#property indicator_color1  Red
#property indicator_width1  2
#property indicator_label1  "Trendsignal Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  Lime
#property indicator_width2  2
#property indicator_label2 "Trendsignal Buy"

int StartBars;
//+------------------------------------------------------------------+
//| Initialization and checking for input parameters                 |
//+------------------------------------------------------------------+
void OnInit()
  {

   StartBars=SSP+1;
SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
PlotIndexSetString(1,PLOT_LABEL,"Trendsignal Buy");
PlotIndexSetInteger(1,PLOT_ARROW,233);
ArraySetAsSeries(BuyBuffer,true);
   
SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
PlotIndexSetString(0,PLOT_LABEL,"Trendsignal Sell");
PlotIndexSetInteger(0,PLOT_ARROW,234);
ArraySetAsSeries(SellBuffer,true);
IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
string short_name="Trendsignal";
IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   
  }

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

   if(rates_total<StartBars) return(0);


   int limit;
   double Range,AvgRange,smin,smax,SsMax,SsMin,price;
   bool uptrend;

   if(prev_calculated>rates_total || prev_calculated<=0)
     {
      K=33-RISK;
      limit=rates_total-StartBars;      
     }
   else
     {
      limit=rates_total-prev_calculated; 
     }


   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);


   uptrend=BT;


   for(int bar=limit; bar>=0; bar--)
     {
     
      if(rates_total!=prev_calculated && bar==0)
        {
         BT=uptrend;
        }

      Range=0;
      AvgRange=0;
      for(int iii=bar; iii<=bar+SSP; iii++) AvgRange=AvgRange+MathAbs(high[iii]-low[iii]);
      Range=AvgRange/(SSP+1);
      //----
      SsMax=low[bar];
      SsMin=close[bar];

      for(int kkk=bar; kkk<=bar+SSP-1; kkk++)
        {
         price=high[kkk];
         if(SsMax<price) SsMax=price;
         price=low[kkk];
         if(SsMin>=price) SsMin=price;
        }

      smin=SsMin+(SsMax-SsMin)*K/100;
      smax=SsMax-(SsMax-SsMin)*K/100;

      SellBuffer[bar]=0;
      BuyBuffer[bar]=0;

      if(close[bar]<smin) uptrend=false;
      if(close[bar]>smax) uptrend=true;

      if(uptrend!=pre && uptrend==true)
        {
         BuyBuffer[bar]=low[bar]-Range*0.5;

         if(bar==0)
           {
            if(counter<=NumberofAlerts)
              {
               Alert("Trendsignal ",EnumToString(Period())," ",Symbol()," BUY");
               counter++;
              }
           }
         else counter=0;
        }
      if(uptrend!=pre && uptrend==false)
        {
         SellBuffer[bar]=high[bar]+Range*0.5;

         if(bar==0)
           {
            if(counter<=NumberofAlerts)
              {
               Alert("Trendsignal ",EnumToString(Period())," ",Symbol()," SELL");
               counter++;
              }
           }
         else counter=0;
        }

      if(bar>0) pre=uptrend;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
