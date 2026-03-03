//------------------------------------------------------------------
#property copyright   "mladen"
#property link        "www.forex-tsd.com"
#property version     "1.00"
#property description "Original idea for the indicator by Nicolas"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2

#property indicator_label1  "mpb zone"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrGainsboro
#property indicator_label2  "Momentum pinball"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrSilver,clrLimeGreen,clrOrangeRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_minimum 0
#property indicator_maximum 100

//
//
//
//
//

enum enMaTypes
{
   avgSma,    // Simple moving average
   avgEma,    // Exponential moving average
   avgSmma,   // Smoothed MA
   avgLwma    // Linear weighted MA
};
input int       MomentumPeriod  = 14;       // Momentum period
input int       AvgPeriod       =  0;       // Momentum average period (0 -> same as momentum period
input enMaTypes AvgType         = avgEma;   // Momentum average method
input double    ZoneUp          = 70;       // Upper zone limit
input double    ZoneDown        = 30;       // Lower zone limit

//
//
//
//
//
//

double mom[],momc[],fup[],fdn[],diff[];

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
   SetIndexBuffer(0,fup,INDICATOR_DATA);
   SetIndexBuffer(1,fdn,INDICATOR_DATA);
   SetIndexBuffer(2,mom,INDICATOR_DATA);
   SetIndexBuffer(3,momc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,diff,INDICATOR_CALCULATIONS);
   IndicatorSetString(INDICATOR_SHORTNAME,"Momentum pinball ("+(string)MomentumPeriod+","+(string)AvgPeriod+")");
   return(0);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnCalculate(const int rates_total,
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
   int avgPeriod = AvgPeriod; if (avgPeriod<=1) avgPeriod = MomentumPeriod;
   
   //
   //
   //
   //
   //
   
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
   {
      if (i<=MomentumPeriod) { diff[i] = 0; iCustomMa(AvgType,0,avgPeriod,i,rates_total,0); iCustomMa(AvgType,0,avgPeriod,i,rates_total,1); continue; }
                  diff[i] = close[i]-close[i-MomentumPeriod];
                  double u=0,d=0;
                     if (diff[i]>diff[i-1]) u=diff[i]-diff[i-1];
                     if (diff[i]<diff[i-1]) d=diff[i-1]-diff[i];

                  //
                  //
                  //
                  //
                  //
                  
                  double avgu = iCustomMa(AvgType,u,avgPeriod,i,rates_total,0);
                  double avgd = iCustomMa(AvgType,d,avgPeriod,i,rates_total,1);
                  if (avgd!=0)
                        mom[i]  = 100.0-100.0/(1.0+(avgu/avgd));
                  else  mom[i]  = 50;            
                        fup[i]  = ZoneUp;
                        fdn[i]  = ZoneDown;
                        momc[i] = 0;
                        if (mom[i]>fup[i]) momc[i]=1;
                        if (mom[i]<fdn[i]) momc[i]=2;
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

#define _maInstances 2
#define _maWorkBufferx1 1*_maInstances
#define _maWorkBufferx2 2*_maInstances
#define _maWorkBufferx3 3*_maInstances
#define _maWorkBufferx4 4*_maInstances
#define _maWorkBufferx5 5*_maInstances

double iCustomMa(int mode, double price, double length, int r, int bars, int instanceNo=0)
{
   switch (mode)
   {
      case avgSma   : return(iSma(price,(int)length,r,bars,instanceNo));
      case avgEma   : return(iEma(price,length,r,bars,instanceNo));
      case avgSmma  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case avgLwma  : return(iLwma(price,(int)length,r,bars,instanceNo));
      default       : return(price);
   }
}

//
//
//
//
//

double workSma[][_maWorkBufferx2];
double iSma(double price, int period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workSma,0)!= _bars) ArrayResize(workSma,_bars); instanceNo *= 2; int k;

   //
   //
   //
   //
   //
      
   workSma[r][instanceNo+0] = price;
   workSma[r][instanceNo+1] = price; for(k=1; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo+0];  
   workSma[r][instanceNo+1] /= 1.0*k;
   return(workSma[r][instanceNo+1]);
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workEma,0)!= _bars) ArrayResize(workEma,_bars);

   //
   //
   //
   //
   //
      
   workEma[r][instanceNo] = price;
   double alpha = 2.0 / (1.0+period);
   if (r>0)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workSmma,0)!= _bars) ArrayResize(workSmma,_bars);

   //
   //
   //
   //
   //

   if (r<period)
         workSmma[r][instanceNo] = price;
   else  workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workLwma,0)!= _bars) ArrayResize(workLwma,_bars);
   
   //
   //
   //
   //
   //
   
   workLwma[r][instanceNo] = price;
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}