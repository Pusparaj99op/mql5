//+------------------------------------------------------------------+
//|                                              SpeedOscillator.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
//#property indicator_minimum -100
//#property indicator_maximum 100
#property indicator_buffers 4
#property indicator_plots   1
//--- plot draws

#property indicator_label1  "SO"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- input parameters
input int      InpMAperiod=24;                  // MA period
input ENUM_MA_METHOD InpMAmethod=MODE_SMA;      // MA mode
input int      InpSPeriod=170;                  // Speed averaging-period (positive and negative)

//--- indicator buffers
double         AvgPosBuffer[];
double         AvgNegBuffer[];
double         SO[];
double         ExtMABuffer[];
//--- handles
int            ExtMAHandle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,SO,INDICATOR_DATA);
   SetIndexBuffer(1,AvgPosBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,AvgNegBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtMABuffer,INDICATOR_CALCULATIONS);
   ExtMAHandle=iMA(NULL,0,InpMAperiod,0,InpMAmethod,PRICE_CLOSE);
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

   if(rates_total<InpSPeriod)
      return(0);

   if(IsStopped())
      return(0);
   if(CopyBuffer(ExtMAHandle,0,0,rates_total,ExtMABuffer)<=0)
     {
      Print("getting ExtMAHandle is failed! Error ",GetLastError());
      return(0);
     }

//--- SpeedOscillator
   int i;
   int pos_count = 0;
   int neg_count = 0;
   double pos_sum = 0;
   double neg_sum = 0;
   int j = 1;

//--- One-time calculations, all rates history.
   if(prev_calculated==0)
     {

      for(i=InpSPeriod+1; i<rates_total && !IsStopped(); i++)
        {
         pos_count = 0;
         neg_count = 0;
         pos_sum = 0;
         neg_sum = 0;
         j = i;

         while((pos_count<InpSPeriod || neg_count<InpSPeriod) && j>1)
           {
            j--;
            double diff = ExtMABuffer[j] - ExtMABuffer[j-1];
            if(diff>0 && pos_count<InpSPeriod)
              {
               pos_count++;
               pos_sum += diff;
              }
            if(diff<0 && neg_count<InpSPeriod)
              {
               neg_count++;
               neg_sum += diff;
              }

            //Print("Time: " + time[j] + "diff: " + diff);     // DEBUG LINE
           }
         AvgPosBuffer[i] = pos_sum/InpSPeriod;
         AvgNegBuffer[i] = neg_sum/InpSPeriod;
         if(ExtMABuffer[i] - ExtMABuffer[i-1]>0)
         {
            SO[i] = (ExtMABuffer[i]-ExtMABuffer[i-1]) / AvgPosBuffer[i];
         }
         else if(ExtMABuffer[i] - ExtMABuffer[i-1]<0)
         {
            SO[i] = -((ExtMABuffer[i]-ExtMABuffer[i-1]) / AvgNegBuffer[i]);
            
         }
         else 
         {
            SO[i] = 0;
         }
        }
     }
//--- Main calculations, i.e. every tick thereafter, calculate current tick's values [rates_total-1]
   else
     {
      for(i=rates_total-1; i<rates_total && !IsStopped(); i++)
        {
         pos_count = 0;
         neg_count = 0;
         pos_sum = 0;
         neg_sum = 0;
         j = i;

         while((pos_count<InpSPeriod || neg_count<InpSPeriod) && j>1)
           {

            j--;
            double diff = ExtMABuffer[j] - ExtMABuffer[j-1];
            if(diff>0 && pos_count<InpSPeriod)
              {
               pos_count++;
               pos_sum += diff;
              }
            if(diff<0 && neg_count<InpSPeriod)
              {
               neg_count++;
               neg_sum += diff;
              }

            //Print("Time: " + time[j] + "diff: " + diff);     // DEBUG LINE
           }
         AvgPosBuffer[i] = pos_sum/InpSPeriod;
         AvgNegBuffer[i] = neg_sum/InpSPeriod;
         
         if(ExtMABuffer[i] - ExtMABuffer[i-1]>0)
         {
            SO[i] = (ExtMABuffer[i]-ExtMABuffer[i-1]) / AvgPosBuffer[i];
         }
         else if(ExtMABuffer[i] - ExtMABuffer[i-1]<0)
         {
            SO[i] = -((ExtMABuffer[i]-ExtMABuffer[i-1]) / AvgNegBuffer[i]);
         }
         else 
         {
            SO[i] = 0;
         }
        }
      //Print("Time: " + time[j] + "pos_sum: " + pos_sum);     // DEBUG LINE
      //Print("Time: " + time[j] + "neg_sum: " + neg_sum);     // DEBUG LINE
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
