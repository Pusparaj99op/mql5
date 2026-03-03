//+------------------------------------------------------------------+
//|                                                   quantile bands |
//+------------------------------------------------------------------+
#property link      "www.forex-tsd.com"
#property copyright "www.forex-tsd.com"

#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   5
#property indicator_label1  "upper filling"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'182,237,182'
#property indicator_label2  "lower filling"
#property indicator_type2   DRAW_FILLING
#property indicator_color2  C'251,220,196'
#property indicator_label3  "Upper band"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrLimeGreen,clrSandyBrown
#property indicator_width3  3
#property indicator_label4  "Lower band"
#property indicator_type4   DRAW_COLOR_LINE
#property indicator_color4  clrLimeGreen,clrSandyBrown
#property indicator_width4  3
#property indicator_label5  "Middle value"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrDarkGray
#property indicator_width5  2

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

input int             Periods           = 35;             // Quantile period
input enPrices        PriceUp           = pr_high;        // Price to use for high quantile value
input enPrices        PriceMid          = pr_median;      // Price to use for middle quantile value
input enPrices        PriceDown         = pr_low;         // Price to use for low quantile value
input double          UpperBandPercent  = 90;             // Upper band percent
input double          LowerBandPercent  = 10;             // Lower band percent
input double          MedianBandPercent = 50;             // Median percent

//
//
//
//
//

double bufferUp[];
double bufferUpc[];
double bufferDn[];
double bufferDnc[];
double bufferMe[],fupu[],fupd[],fdnd[],fdnu[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,fupu,INDICATOR_DATA);      SetIndexBuffer(1,fupd,INDICATOR_DATA);
   SetIndexBuffer(2,fdnu,INDICATOR_DATA);      SetIndexBuffer(3,fdnd,INDICATOR_DATA);
   SetIndexBuffer(4,bufferUp ,INDICATOR_DATA); SetIndexBuffer(5,bufferUpc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,bufferDn ,INDICATOR_DATA); SetIndexBuffer(7,bufferDnc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(8,bufferMe ,INDICATOR_DATA);
   return(0);
}
void OnDeinit(const int reason) { return; }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const datetime& time[],
                 const double& open[],
                 const double& high[],
                 const double& low[],
                 const double& close[],
                 const long& tick_volume[],
                 const long& volume[],
                 const int& spread[])
{
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
   {
      bufferUp[i] = iQuantile(getPrice(PriceUp  ,open,close,high,low,i,rates_total,0),Periods,UpperBandPercent ,i,rates_total,0);
      bufferDn[i] = iQuantile(getPrice(PriceDown,open,close,high,low,i,rates_total,1),Periods,LowerBandPercent ,i,rates_total,1);
      bufferMe[i] = iQuantile(getPrice(PriceMid ,open,close,high,low,i,rates_total,2),Periods,MedianBandPercent,i,rates_total,2);
      fupd[i]     = bufferMe[i]; fupu[i] = bufferUp[i]; 
      fdnu[i]     = bufferMe[i]; fdnd[i] = bufferDn[i]; 
      if (i>0)
      {
         bufferUpc[i] = bufferUpc[i-1];
         bufferDnc[i] = bufferDnc[i-1];

         //
         //
         //
         //
         //
                           
         if (bufferUp[i]>bufferUp[i-1]) bufferUpc[i] = 0;
         if (bufferUp[i]<bufferUp[i-1]) bufferUpc[i] = 1;
         if (bufferDn[i]>bufferDn[i-1]) bufferDnc[i] = 0;
         if (bufferDn[i]<bufferDn[i-1]) bufferDnc[i] = 1;
      }                     
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
//

#define quantileInstances 3
double quantileValues[][quantileInstances];
double quantileArray[];
double iQuantile(double value, int period, double qp, int i, int bars, int instanceNo=0)
{
   if (ArrayRange(quantileArray ,0)!=period) ArrayResize(quantileArray ,period);
   if (ArrayRange(quantileValues,0)!=bars)   ArrayResize(quantileValues,bars);
                  quantileValues[i][instanceNo] = value;
                        for(int k=0; k<period && (i-k)>=0; k++) quantileArray[k] = quantileValues[i-k][instanceNo];
       ArraySort(quantileArray);

   //
   //
   //
   //
   //
   
   double index = (period-1)*qp/100.00;
   int    ind   = (int)index;
   double delta = index - ind;
   if (ind == NormalizeDouble(index,5))
         return(            quantileArray[ind]);
   else  return((1.0-delta)*quantileArray[ind]+delta*quantileArray[ind+1]);
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

#define priceInstances 3
double workHa[][priceInstances*4];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i,int bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars); instanceNo*=4; int r = i;
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (r>0)
                haOpen  = (workHa[r-1][instanceNo+2] + workHa[r-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[r][instanceNo+0] = haLow;  workHa[r][instanceNo+1] = haHigh; } 
         else                 { workHa[r][instanceNo+0] = haHigh; workHa[r][instanceNo+1] = haLow;  } 
                                workHa[r][instanceNo+2] = haOpen;
                                workHa[r][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (tprice)
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
   
   switch (tprice)
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