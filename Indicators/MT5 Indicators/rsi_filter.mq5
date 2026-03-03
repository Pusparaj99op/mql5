//+------------------------------------------------------------------+
//|                                                   rsi filter.mq5 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "rsi filter"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrDeepSkyBlue,clrPaleVioletRed,clrDimGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_minimum -1.1
#property indicator_maximum +1.1

//
//
//
//
//

input int RsiPeriod = 14; // Rsi period :

//
//
//
//
//

double FltBuffer[];
double ClrBuffer[];

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,FltBuffer,INDICATOR_DATA); PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,3);
   SetIndexBuffer(1,ClrBuffer,INDICATOR_COLOR_INDEX); 
   IndicatorSetString(INDICATOR_SHORTNAME,"Rsi filter ("+(string)RsiPeriod+")");
      return(0);
}

//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

double RsiBuffer[];
double ChgBuffer[];
double TotBuffer[];
double TrnBuffer[];
double PrcBuffer[];
int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double& price[] )
{
   if (ArraySize(RsiBuffer)!=rates_total)
   {
      ArrayResize(RsiBuffer,rates_total);
      ArrayResize(ChgBuffer,rates_total);
      ArrayResize(TotBuffer,rates_total);
      ArrayResize(TrnBuffer,rates_total);
      ArrayResize(PrcBuffer,rates_total);
   }
   double alpha = 1.0 /(double)RsiPeriod;

   //
   //
   //
   //
   //

   for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total; i++)
   {
      PrcBuffer[i] = price[i]; if (price[i] == EMPTY_VALUE) PrcBuffer[i] = 0;
      if (i<RsiPeriod)
         {
            int k;double sum = 0; for (k=0; k<RsiPeriod && (i-k-1)>=0; k++) sum += MathAbs(PrcBuffer[i-k]-PrcBuffer[i-k-1]);
            if (k>0)
            {
               ChgBuffer[i] = (PrcBuffer[i]-PrcBuffer[0])/k;
               TotBuffer[i] = sum/k;
            }
         }
      else
         {
            double change = PrcBuffer[i]-PrcBuffer[i-1];
               ChgBuffer[i] = ChgBuffer[i-1] + alpha*(        change  - ChgBuffer[i-1]);
               TotBuffer[i] = TotBuffer[i-1] + alpha*(MathAbs(change) - TotBuffer[i-1]);
         }

      if (TotBuffer[i] != 0)
            RsiBuffer[i] = 50.0*((ChgBuffer[i]/TotBuffer[i])+1);
      else  RsiBuffer[i] = 0;
   
      //
      //
      //
      //
      //
 
      FltBuffer[i] = EMPTY_VALUE;
      TrnBuffer[i] = TrnBuffer[i-1];
        if (RsiBuffer[i] > 70) TrnBuffer[i] =  1;
        if (RsiBuffer[i] < 30) TrnBuffer[i] = -1;
        if (TrnBuffer[i] ==  1 && RsiBuffer[i] > 40) { FltBuffer[i] =  1; ClrBuffer[i] = 0; }
        if (TrnBuffer[i] == -1 && RsiBuffer[i] < 60) { FltBuffer[i] = -1; ClrBuffer[i] = 1; }
   }
   
   //
   //
   //
   //
   //

   return(rates_total);
}