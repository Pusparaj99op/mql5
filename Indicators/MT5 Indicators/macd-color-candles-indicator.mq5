//+------------------------------------------------------------------+
//|                                              MACD - original.mq5 |
//+------------------------------------------------------------------+
#property description "Moving Average Convergence/Divergence"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrDimGray, clrLimeGreen, clrGreen, clrRed, clrFireBrick
#property indicator_color2  clrDimGray, clrLimeGreen, clrGreen, clrRed, clrFireBrick
#property indicator_label1  "MACD"

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased   // Heiken ashi trend biased price
};

input int      InpFastEMA      = 8;    // Macd fast period
input int      InpSlowEMA      = 17;    // Macd slow period
input enPrices InpAppliedPrice = pr_close; // Price to use

//
//
//
//
//

double  ExtMacdBuffer[];
double  candleH[],candleL[],candleO[],candleC[];
double  Colors[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
void OnInit()
{
   SetIndexBuffer(0,candleO      ,INDICATOR_DATA);
   SetIndexBuffer(1,candleH      ,INDICATOR_DATA);
   SetIndexBuffer(2,candleL      ,INDICATOR_DATA);
   SetIndexBuffer(3,candleC      ,INDICATOR_DATA);
   SetIndexBuffer(4,Colors       ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,ExtMacdBuffer,INDICATOR_CALCULATIONS);
}
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
{

   //
   //
   //
   //
   //
   
      for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
      {
         double price = getPrice(InpAppliedPrice,Open,Close,High,Low,rates_total,i);
         ExtMacdBuffer[i]   = iEma(price,InpFastEMA,i,rates_total,0)-iEma(price,InpSlowEMA,i,rates_total,0);
         if (i>0)
         {
            if (ExtMacdBuffer[i]>0)
            {
               if (ExtMacdBuffer[i]>ExtMacdBuffer[i-1]) Colors[i] = 1;
               if (ExtMacdBuffer[i]<ExtMacdBuffer[i-1]) Colors[i] = 2;
            }
            if (ExtMacdBuffer[i]<0)
            {
               if (ExtMacdBuffer[i]<ExtMacdBuffer[i-1]) Colors[i] = 3;
               if (ExtMacdBuffer[i]>ExtMacdBuffer[i-1]) Colors[i] = 4;
            }
         }         
         candleO[i] = Open[i];
         candleH[i] = High[i];
         candleL[i] = Low[i];
         candleC[i] = Close[i];
      }         
      return(rates_total);
}
  
//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//

double workEma[][2];
double iEma(double price, double period, int r, int totalBars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= totalBars) ArrayResize(workEma,totalBars);

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
   workEma[r][instanceNo] = price;
   if (r>0)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//
//


double workHa[][4];
double getPrice(int price, const double& open[], const double& close[], const double& high[], const double& low[], int bars, int i,  int instanceNo=0)
{
  if (price>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars);
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][instanceNo+2] + workHa[i-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][instanceNo+0] = haLow;  workHa[i][instanceNo+1] = haHigh; } 
         else                 { workHa[i][instanceNo+0] = haHigh; workHa[i][instanceNo+1] = haLow;  } 
                                workHa[i][instanceNo+2] = haOpen;
                                workHa[i][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (price)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (price)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
   }
   return(0);
}