//+------------------------------------------------------------------+
//|                                             McGinley_Dynamic.mq5 |
//|                                  Copyright 2018, Samuel Williams |
//|                          https://www.mql5.com/en/users/sambo3261 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Samuel Williams"
#property link      "https://www.mql5.com/en/users/sambo3261"
#property version   "1.1"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot MD
#property indicator_label1  "MD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      MD_smooth=125; //Smoothing parameter (60% of equivalent MA period)
//--- indicator buffers
double         MDBuffer[];
double         EMABuffer[];
//---External Indicator handles
int            EMAHandle;

//---Copied result
int            CopiedEMA=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,MDBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,EMABuffer,INDICATOR_CALCULATIONS);
//---Copying external indicator to handle 
   int periodTemp=MathRound(MD_smooth*0.6);
   EMAHandle=iMA(_Symbol,_Period,periodTemp,0,MODE_EMA,PRICE_CLOSE);
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
   int i,start;
//--Copy external handle to buffer
   CopiedEMA=CopyBuffer(EMAHandle,0,0,rates_total,EMABuffer);
   if(CopiedEMA<0)
     {
      PrintFormat("Error in copy EMA buffer, code %d",GetLastError());
     }
//---check for rates total
   if(rates_total<2)
     {
      return(0);
     }
   if(prev_calculated==0)
     {
      //--- First values are not calculated
      double firstMD=0.0;
      for(i=1;i<=2;i++)
        {
         MDBuffer[i]=EMABuffer[i];
         firstMD+=(close[i]-EMABuffer[i-1])/(MD_smooth*close[i]/EMABuffer[i-1]);
        }
      start=2+1;
     }
   else start=prev_calculated-1;
   for(i=start;i<rates_total && !IsStopped();i++)
     {
      MDBuffer[i]=MDBuffer[i-1]+(close[i]-MDBuffer[i-1])/(MD_smooth*(close[i]/MDBuffer[i-1]));
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
