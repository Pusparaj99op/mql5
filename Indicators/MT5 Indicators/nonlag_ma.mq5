//+------------------------------------------------------------------+
//|                                                    NonLag ma.mq5 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_label1  "NonLag ma"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  DeepSkyBlue,PaleVioletRed,DimGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//
//
//
//
//

input int Length = 25;

//
//
//
//
//

double nonlagma[];
double colorBuffer[];

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
   SetIndexBuffer(0,nonlagma,INDICATOR_DATA); PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,3);
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
   IndicatorSetString(INDICATOR_SHORTNAME,"NonLag ma ("+string(Length)+")");
   return(0);
}

//
//
//
//
//

int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double& price[] )
{
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      nonlagma[i] = iNoLagMa(price[i],Length,i,0);
      if (i>0)
      {
         colorBuffer[i] = 2;
            if (nonlagma[i]>nonlagma[i-1]) colorBuffer[i]=0;
            if (nonlagma[i]<nonlagma[i-1]) colorBuffer[i]=1;
      }
   }      
   return(rates_total);
}


  
//+------------------------------------------------------------------
//|                                                                  
//+------------------------------------------------------------------
//
//
//
//
//

#define Pi       3.14159265358979323846264338327950288
#define _length  0
#define _len     1
#define _weight  2

#define numOfSeparateCalculations 1
double  nlm_values[3][numOfSeparateCalculations];
double  nlm_prices[ ][numOfSeparateCalculations];
double  nlm_alphas[ ][numOfSeparateCalculations];

//
//
//
//
//

double iNoLagMa(double price, int length, int r, int forValue=0)
{
   if (ArrayRange(nlm_prices,0) != Bars(Symbol(),0)) ArrayResize(nlm_prices,Bars(Symbol(),0));
                               nlm_prices[r][forValue]=price;
   if (length<3 || r<3) return(nlm_prices[r][forValue]);
   
   //
   //
   //
   //
   //
   
   if (nlm_values[_length][forValue] != length)
   {
      double Cycle = 4.0;
      double Coeff = 3.0*Pi;
      int    Phase = length-1;
      
         nlm_values[_length][forValue] = length;
         nlm_values[_len   ][forValue] = length*4 + Phase;  
         nlm_values[_weight][forValue] = 0;

         if (ArrayRange(nlm_alphas,0) < nlm_values[_len][forValue]) ArrayResize(nlm_alphas,(int)nlm_values[_len][forValue]);
         for (int k=0; k<nlm_values[_len][forValue]; k++)
         {
            double t;
            if (k<=Phase-1) 
                 t = 1.0 * k/(Phase-1);
            else t = 1.0 + (k-Phase+1)*(2.0*Cycle-1.0)/(Cycle*length-1.0); 
            double beta = MathCos(Pi*t);
            double g = 1.0/(Coeff*t+1); if (t <= 0.5 ) g = 1;
      
            nlm_alphas[k][forValue]        = g * beta;
            nlm_values[_weight][forValue] += nlm_alphas[k][forValue];
         }
   }
   
   //
   //
   //
   //
   //
   
   if (nlm_values[_weight][forValue]>0)
   {
      double sum = 0;
           for (int k=0; k < nlm_values[_len][forValue] && (r-k)>=0; k++) sum += nlm_alphas[k][forValue]*nlm_prices[r-k][forValue];
           return( sum / nlm_values[_weight][forValue]);
   }
   else return(0);           
}