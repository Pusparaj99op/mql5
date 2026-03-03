//+------------------------------------------------------------------+
//|                                                    RSI Trend.mq5 |
//|                                   Copyright 2017, Paran Software |
//+------------------------------------------------------------------+
#property copyright "2017, Paran Software"
#property description "RSI Trend";
#property version   "1.00"

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_color1  Blue, Red
#property indicator_width1  2

//--- input parameters
input int InpUpperRSI  = 65;     // Upper limit of RSI changes
input int InpLowerRSI  = 35;     // Lower limit of RSI changes
input int InpRSIPeriod = 14;     // RSI Period

//--- buffers
double LineBuffer[];
double ColorBuffer[];
double ExtRSIBuffer[];

//--- global variable
int      RSI_Handle;
double   prevVal = 0;
//+------------------------------------------------------------------+
//| Paran indicator initialization function                          |
//+------------------------------------------------------------------+
void OnInit()
{
   string short_name;
   
   //--- indicator buffers mapping
   SetIndexBuffer(0, LineBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, ExtRSIBuffer, INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_COLOR_SECTION);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 5);

   short_name = "RSI (" + string(InpUpperRSI) + " , " + string(InpLowerRSI) + ") Trend ";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   PlotIndexSetString(0, PLOT_LABEL, "RSI Trend");

   RSI_Handle = iRSI(NULL, 0, InpRSIPeriod, PRICE_CLOSE);
}

//+------------------------------------------------------------------+
//|  RSI Trend indicator                                             |
//+------------------------------------------------------------------+
 int OnCalculate (const int rates_total,     // size of input time series 
                 const int prev_calculated,  // bars handled in previous call 
                 const datetime& time[],     // Time 
                 const double& open[],       // Open 
                 const double& high[],       // High 
                 const double& low[],        // Low 
                 const double& close[],      // Close 
                 const long& tick_volume[],  // Tick Volume 
                 const long& volume[],       // Real Volume 
                 const int& spread[])        // Spread 
{
   int i, pos;

   //--- Check for Abnormal Starting
   if (rates_total < 2)
      return(0);
   //--- Data length
   int data_length;
   if(prev_calculated > rates_total || prev_calculated < 0)
      data_length = rates_total;
   else
   {
      data_length = rates_total - prev_calculated;
      if (prev_calculated > 0)
         data_length++;
   }
   data_length = CopyBuffer(RSI_Handle, 0, 0, data_length, ExtRSIBuffer);
   
//--- The Main Loop of Calculations
   pos = (prev_calculated == 0)?3:prev_calculated - 1;
   
   for(i = pos; i < rates_total - 1 && !IsStopped(); i++)
   {
      double diff1, diff2;
      diff1 = ExtRSIBuffer[i] - ExtRSIBuffer[i-1];
      diff2 = ExtRSIBuffer[i-1] - ExtRSIBuffer[i-2];
      if (diff1*diff2 < 0)
      {
         if (ExtRSIBuffer[i-1] > InpUpperRSI || ExtRSIBuffer[i-1] < InpLowerRSI)
         {
            double hi = MathMax(MathMax(high[i], high[i-1]), MathMax(high[i-2], high[i-3]));
            double lo = MathMin(MathMin(low[i], low[i-1]), MathMin(low[i-2], low[i-3]));

            LineBuffer[i] = (ExtRSIBuffer[i-1] > InpUpperRSI)?hi:lo;
            ColorBuffer[i] = (prevVal > LineBuffer[i])?1.0:0.0;
            prevVal = LineBuffer[i];
         }
      }
   }
   
   return(rates_total);
}

