//+------------------------------------------------------------------+
//|                                              SpeedOscillator.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "2.30"

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
//--- input parameters
input int            InpMAperiod = 100;          // Moving average period
input ENUM_MA_METHOD InpMAmethod = MODE_SMA;    // Moving average mode
input int            InpSPeriod  = 400;          // Backward-sampling period
//--- indicator buffers
double         AvgPosBuffer[];
double         AvgNegBuffer[];
double         SO[];
double         ExtMABuffer[];
double         Distance[];
//--- handles
int            ExtMAHandle;

//+------------------------------------------------------------------+
//| Speed Oscillator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, SO, INDICATOR_DATA);
   SetIndexBuffer(1, Distance, INDICATOR_DATA);
   SetIndexBuffer(2, AvgPosBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, AvgNegBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, ExtMABuffer, INDICATOR_CALCULATIONS);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpSPeriod);
//--- get MA handles
   ExtMAHandle = iMA(NULL, 0, InpMAperiod, 0, InpMAmethod, PRICE_CLOSE);
//--- name for DataWindow and indicator subwindow label
   PlotIndexSetString(0, PLOT_LABEL, "Speed(" + string(InpMAperiod) + ")");
   PlotIndexSetString(1, PLOT_LABEL, "Distance(%)");
   IndicatorSetString(INDICATOR_SHORTNAME, "SO(" + string(InpMAperiod) + ")");
//--- sets drawing line to empty value
   PlotIndexSetDouble (0, PLOT_EMPTY_VALUE ,0.0);
   PlotIndexSetDouble (1, PLOT_EMPTY_VALUE ,0.0);
  }

//+------------------------------------------------------------------+
//| Speed Oscillator iteration function                              |
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
//--- get ma buffers
   if(CopyBuffer(ExtMAHandle, 0, 0, rates_total-1, ExtMABuffer) <=0)
     {
      Print("not all MA copied. Will try on next tick Error =", GetLastError());
      return(0);
     }
   if(prev_calculated == 0)
     {
      ArrayInitialize(AvgPosBuffer, 0);
      ArrayInitialize(AvgNegBuffer, 0);
      ArrayInitialize(SO, 0);
     }
//--- SpeedOscillator
   int i;
   int pos_count = 0;
   int neg_count = 0;
   double pos_sum = 0;
   double neg_sum = 0;
   int j = 1;
//--- One-time calculations, all rates history.
   if(prev_calculated == 0)
     {
      for(i = InpSPeriod + 1; i < rates_total && !IsStopped(); i++)
        {
         pos_count = 0;
         neg_count = 0;
         pos_sum = 0;
         neg_sum = 0;
         j = i;       
         while((pos_count < InpSPeriod || neg_count < InpSPeriod) && j > 1)
           {
            j--;
            double diff = ExtMABuffer[j] - ExtMABuffer[j - 1];
            if(diff > 0 && pos_count < InpSPeriod)
              {
               pos_count++;
               pos_sum += diff;
              }
            if(diff < 0 && neg_count < InpSPeriod)
              {
               neg_count++;
               neg_sum += diff;
              }
           }
           
         AvgPosBuffer[i] = pos_sum / InpSPeriod;
         AvgNegBuffer[i] = neg_sum / InpSPeriod;
         if(ExtMABuffer[i] - ExtMABuffer[i - 1] > 0)
           {
            SO[i] = (ExtMABuffer[i] - ExtMABuffer[i - 1]) / AvgPosBuffer[i];
           }
         else
            if(ExtMABuffer[i] - ExtMABuffer[i - 1] < 0)
              {
               SO[i] = -((ExtMABuffer[i] - ExtMABuffer[i - 1]) / AvgNegBuffer[i]);
              }
            else
              {
               SO[i] = 0;
              }
         Distance[i] = ((close[i] - ExtMABuffer[i]) / close[i]) * 100;
        }
     }
//--- Main calculations, i.e. every tick thereafter, calculate current tick's values [rates_total-1]
   else
     {
      for(i = rates_total - 1; i < rates_total && !IsStopped(); i++)
        {
         pos_count = 0;
         neg_count = 0;
         pos_sum = 0;
         neg_sum = 0;
         j = i;
         while((pos_count < InpSPeriod || neg_count < InpSPeriod) && j > 1)
           {
            j--;
            double diff = ExtMABuffer[j] - ExtMABuffer[j - 1];
            if(diff > 0 && pos_count < InpSPeriod)
              {
               pos_count++;
               pos_sum += diff;
              }
            if(diff < 0 && neg_count < InpSPeriod)
              {
               neg_count++;
               neg_sum += diff;
              }
           }
           
         AvgPosBuffer[i] = pos_sum / InpSPeriod;
         AvgNegBuffer[i] = neg_sum / InpSPeriod;
         if(ExtMABuffer[i] - ExtMABuffer[i - 1] > 0)
           {
            SO[i] = (ExtMABuffer[i] - ExtMABuffer[i - 1]) / AvgPosBuffer[i];
           }
         else
            if(ExtMABuffer[i] - ExtMABuffer[i - 1] < 0)
              {
               SO[i] = -((ExtMABuffer[i] - ExtMABuffer[i - 1]) / AvgNegBuffer[i]);
              }
            else
              {
               SO[i] = 0;
              }
        }
     }
     
//--- always do current tick's distance
   Distance[rates_total - 1] = ((close[rates_total - 1] - ExtMABuffer[rates_total - 1]) / close[rates_total - 1]) * 100;
   
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
