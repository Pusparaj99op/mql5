//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_ARROW
#property indicator_color1  clrPaleVioletRed,clrLimeGreen

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
   pr_average     // Average
};

input double   SARStep    = 0.02;    // Step
input double   SARMaximum = 0.2;     // Maximum
input enPrices PriceHigh  = pr_high; // Price high
input enPrices PriceLow   = pr_low;  // Price low

double sar[];
double colors[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//

void OnInit()
{
   SetIndexBuffer(0,sar); PlotIndexSetInteger(0,PLOT_ARROW,159);
   SetIndexBuffer(1,colors,INDICATOR_COLOR_INDEX);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tickVolume[],
                const long &volume[],
                const int &spread[])
{
   //
   //
   //
   //
   //
   
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      double sarOpen;
      double sarPosition;
      double sarChange;
      double pHigh = getPrice(PriceHigh,open,close,high,low,i,rates_total);
      double pLow  = getPrice(PriceLow ,open,close,high,low,i,rates_total);
         sar[i] = iParabolic(pHigh,pLow,SARStep,SARMaximum,sarOpen,sarPosition,sarChange,i,rates_total);
         if (sarPosition==1)
               colors[i] = 1;
         else  colors[i] = 0;
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

double workSar[][7];
#define _high     0
#define _low      1
#define _ohigh    2
#define _olow     3
#define _open     4
#define _position 5
#define _af       6


double iParabolic(double high, double low, double step, double limit, double& pOpen, double& pPosition, double& pChange, int i, int total)
{
   if (ArrayRange(workSar,0)!=total) ArrayResize(workSar,total);
   
   //
   //
   //
   //
   //
   
   if (high<low) { double temp = high; high = low; low  = temp;}             
   double pClose  = high;
          pChange = 0;
               workSar[i][_ohigh] = high;
               workSar[i][_olow]  = low;
               if (i<1)
               {
                  workSar[i][_high]     = high;
                  workSar[i][_low]      = low;
                  workSar[i][_open]     = high;
                  workSar[i][_position] = -1;
                     return(EMPTY_VALUE);
               }
               workSar[i][_open]     = workSar[i-1][_open];
               workSar[i][_af]       = workSar[i-1][_af];
               workSar[i][_position] = workSar[i-1][_position];
               workSar[i][_high]     = MathMax(workSar[i-1][_high],high);
               workSar[i][_low]      = MathMin(workSar[i-1][_low] ,low );
      
   //
   //
   //
   //
   //
            
   if (workSar[i][_position] == 1)
      if (low<=workSar[i][_open])
         {
            workSar[i][_position] = -1;
               pChange = -1;
               pClose  = workSar[i][_high];
                         workSar[i][_high] = high;
                         workSar[i][_low]  = low;
                         workSar[i][_af]   = step;
                         workSar[i][_open] = pClose + workSar[i][_af]*(workSar[i][_low]-pClose);
                            if (workSar[i][_open]<workSar[i  ][_ohigh]) workSar[i][_open] = workSar[i  ][_ohigh];
                            if (workSar[i][_open]<workSar[i-1][_ohigh]) workSar[i][_open] = workSar[i-1][_ohigh];
         }
      else
         {
               pClose = workSar[i][_open];
                    if (workSar[i][_high]>workSar[i-1][_high] && workSar[i][_af]<limit) workSar[i][_af] = MathMin(workSar[i][_af]+step,limit);
                        workSar[i][_open] = pClose + workSar[i][_af]*(workSar[i][_high]-pClose);
                            if (workSar[i][_open]>workSar[i  ][_olow]) workSar[i][_open] = workSar[i  ][_olow];
                            if (workSar[i][_open]>workSar[i-1][_olow]) workSar[i][_open] = workSar[i-1][_olow];
         }
   else
      if (high>=workSar[i][_open])
         {
            workSar[i][_position] = 1;
               pChange = 1;
               pClose  = workSar[i][_low];
                         workSar[i][_low]  = low;
                         workSar[i][_high] = high;
                         workSar[i][_af]   = step;
                         workSar[i][_open] = pClose + workSar[i][_af]*(workSar[i][_high]-pClose);
                            if (workSar[i][_open]>workSar[i  ][_olow]) workSar[i][_open] = workSar[i  ][_olow];
                            if (workSar[i][_open]>workSar[i-1][_olow]) workSar[i][_open] = workSar[i-1][_olow];
         }
      else
         {
               pClose = workSar[i][_open];
               if (workSar[i][_low]<workSar[i-1][_low] && workSar[i][_af]<limit) workSar[i][_af] = MathMin(workSar[i][_af]+step,limit);
                   workSar[i][_open] = pClose + workSar[i][_af]*(workSar[i][_low]-pClose);
                            if (workSar[i][_open]<workSar[i  ][_ohigh]) workSar[i][_open] = workSar[i  ][_ohigh];
                            if (workSar[i][_open]<workSar[i-1][_ohigh]) workSar[i][_open] = workSar[i-1][_ohigh];
         }

   //
   //
   //
   //
   //
   
   pOpen     = workSar[i][_open];
   pPosition = workSar[i][_position];
   return(pClose);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//


double getPrice(enPrices price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars)
{
   switch (price)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
   }
   return(0);
}