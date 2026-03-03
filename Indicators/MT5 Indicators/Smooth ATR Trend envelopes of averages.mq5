//------------------------------------------------------------------
#property copyright   "mladen"
#property link        "mladenfx@gmail.com"
#property description "Smooth ATR Trend envelopes of averages"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4
#property indicator_label1  "Trend envelope up trend line"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  2
#property indicator_label2  "Trend envelope down trend line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrCrimson
#property indicator_width2  2
#property indicator_label3  "Trend envelope up trend start"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrDodgerBlue
#property indicator_width3  2
#property indicator_label4  "Trend envelope down trend start"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrCrimson
#property indicator_width4  2

//
//--- input parameters
//
enum enMaTypes
  {
   ma_sma,    // Simple moving average
   ma_ema,    // Exponential moving average
   ma_smma,   // Smoothed MA
   ma_lwma    // Linear weighted MA
  };

input int       inpAtrPeriod = 14;      // ATR period
input double    inpDeviation = 2;       // ATR multilication factor
input int       inpSmtPeriod = 14;      // Smoothing period (<=1 for no smoothing)
input enMaTypes inpMaMethod  = ma_sma;  // Smoothing method


//
//--- indicator buffers
//

double lineup[],linedn[],arrowup[],arrowdn[];

//
//--- custom structures
//

struct sTrendEnvelope
{
   double upline;
   double downline;
   int    trend;
   bool   trendChange;
};

//------------------------------------------------------------------
// Custom indicator initialization function
//------------------------------------------------------------------
int OnInit()
{
   SetIndexBuffer(0,lineup,INDICATOR_DATA);
   SetIndexBuffer(1,linedn,INDICATOR_DATA);
   SetIndexBuffer(2,arrowup,INDICATOR_DATA); PlotIndexGetInteger(2,PLOT_ARROW,159);
   SetIndexBuffer(3,arrowdn,INDICATOR_DATA); PlotIndexGetInteger(3,PLOT_ARROW,159);
   return(INIT_SUCCEEDED);
}
//------------------------------------------------------------------
// Custom indicator de-initialization function
//------------------------------------------------------------------
void OnDeinit(const int reason) { return; }
//------------------------------------------------------------------
// Custom iteration function
//------------------------------------------------------------------
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
   if (Bars(_Symbol,_Period)<rates_total) return(-1);
   
   //
   //---
   //

   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !_StopFlag; i++)
   {
      double _atr  = iSmooth((i>0) ? MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]) : high[i]-low[i],inpAtrPeriod,0,i,rates_total);
      double _high = iCustomMa(inpMaMethod,high[i],inpSmtPeriod,i,rates_total,0);
      double _low  = iCustomMa(inpMaMethod,low[i] ,inpSmtPeriod,i,rates_total,1);
      sTrendEnvelope _result = iTrendEnvelope(_high,_low,close[i],_atr*inpDeviation,i,rates_total);
         lineup[i]  = _result.upline;
         linedn[i]  = _result.downline;
         arrowup[i] = (_result.trendChange && _result.trend== 1) ? lineup[i] : EMPTY_VALUE;
         arrowdn[i] = (_result.trendChange && _result.trend==-1) ? linedn[i] : EMPTY_VALUE;
   }          
   return(rates_total);
}
//------------------------------------------------------------------
// Custom functions
//------------------------------------------------------------------
#define _smoothInstances     1
#define _smoothInstancesSize 10
double m_wrk[][_smoothInstances*_smoothInstancesSize];
int    m_size=0;
//
//---
//
double iSmooth(double price,double length,double phase,int r,int bars,int instanceNo=0)
  {
   #define bsmax  5
   #define bsmin  6
   #define volty  7
   #define vsum   8
   #define avolty 9

   if(ArrayRange(m_wrk,0)!=bars) ArrayResize(m_wrk,bars); if(ArrayRange(m_wrk,0)!=bars) return(price); instanceNo*=_smoothInstancesSize;
   if(r==0 || length<=1) { int k=0; for(; k<7; k++) m_wrk[r][instanceNo+k]=price; for(; k<10; k++) m_wrk[r][instanceNo+k]=0; return(price); }

//
//---
//

   double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
   double pow1   = MathMax(len1-2.0,0.5);
   double del1   = price - m_wrk[r-1][instanceNo+bsmax];
   double del2   = price - m_wrk[r-1][instanceNo+bsmin];
   int    forBar = MathMin(r,10);

   m_wrk[r][instanceNo+volty]=0;
   if(MathAbs(del1) > MathAbs(del2)) m_wrk[r][instanceNo+volty] = MathAbs(del1);
   if(MathAbs(del1) < MathAbs(del2)) m_wrk[r][instanceNo+volty] = MathAbs(del2);
   m_wrk[r][instanceNo+vsum]=m_wrk[r-1][instanceNo+vsum]+(m_wrk[r][instanceNo+volty]-m_wrk[r-forBar][instanceNo+volty])*0.1;

//
//---
//

   m_wrk[r][instanceNo+avolty]=m_wrk[r-1][instanceNo+avolty]+(2.0/(MathMax(4.0*length,30)+1.0))*(m_wrk[r][instanceNo+vsum]-m_wrk[r-1][instanceNo+avolty]);
   double dVolty=(m_wrk[r][instanceNo+avolty]>0) ? m_wrk[r][instanceNo+volty]/m_wrk[r][instanceNo+avolty]: 0;
   if(dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
   if(dVolty < 1)                      dVolty = 1.0;

//
//---
//

   double pow2 = MathPow(dVolty, pow1);
   double len2 = MathSqrt(0.5*(length-1))*len1;
   double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

   if(del1 > 0) m_wrk[r][instanceNo+bsmax] = price; else m_wrk[r][instanceNo+bsmax] = price - Kv*del1;
   if(del2 < 0) m_wrk[r][instanceNo+bsmin] = price; else m_wrk[r][instanceNo+bsmin] = price - Kv*del2;

//
//---
//

   double corr  = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
   double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
   double alpha = MathPow(beta,pow2);

   m_wrk[r][instanceNo+0] = price + alpha*(m_wrk[r-1][instanceNo+0]-price);
   m_wrk[r][instanceNo+1] = (price - m_wrk[r][instanceNo+0])*(1-beta) + beta*m_wrk[r-1][instanceNo+1];
   m_wrk[r][instanceNo+2] = (m_wrk[r][instanceNo+0] + corr*m_wrk[r][instanceNo+1]);
   m_wrk[r][instanceNo+3] = (m_wrk[r][instanceNo+2] - m_wrk[r-1][instanceNo+4])*MathPow((1-alpha),2) + MathPow(alpha,2)*m_wrk[r-1][instanceNo+3];
   m_wrk[r][instanceNo+4] = (m_wrk[r-1][instanceNo+4] + m_wrk[r][instanceNo+3]);

//
//---
//

   return(m_wrk[r][instanceNo+4]);

   #undef bsmax
   #undef bsmin
   #undef volty
   #undef vsum
   #undef avolty
  }    
//
//---
//
#define _maInstances 2
#define _maWorkBufferx1 _maInstances
//
//---
//
double iCustomMa(int mode,double price,double length,int r,int bars,int instanceNo=0)
  {
   switch(mode)
     {
      case ma_sma   : return(iSma(price,(int)length,r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)length,r,bars,instanceNo));
      default       : return(price);
     }
  }
//
//---
//
double workSma[][_maWorkBufferx1];
//
//---
//
double iSma(double price,int period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workSma,0)!=_bars) ArrayResize(workSma,_bars);

   workSma[r][instanceNo]=price;
   double avg=price; int k=1; for(; k<period && (r-k)>=0; k++) avg+=workSma[r-k][instanceNo];
   return(avg/(double)k);
  }
//
//---
//
double workEma[][_maWorkBufferx1];
//
//---
//
double iEma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workEma,0)!=_bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo]=price;
   if(r>0 && period>1)
      workEma[r][instanceNo]=workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
  }
//
//---
//
double workSmma[][_maWorkBufferx1];
//
//---
//
double iSmma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workSmma,0)!=_bars) ArrayResize(workSmma,_bars);

   workSmma[r][instanceNo]=price;
   if(r>1 && period>1)
      workSmma[r][instanceNo]=workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
  }
//
//---
//
double workLwma[][_maWorkBufferx1];
//
//---
//
double iLwma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workLwma,0)!=_bars) ArrayResize(workLwma,_bars);

   workLwma[r][instanceNo] = price; if(period<1) return(price);
   double sumw = period;
   double sum  = period*price;

   for(int k=1; k<period && (r-k)>=0; k++)
     {
      double weight=period-k;
      sumw  += weight;
      sum   += weight*workLwma[r-k][instanceNo];
     }
   return(sum/sumw);
  }
//
//---
//
#define _trendEnvelopesInstances 1
#define _trendEnvelopesInstancesSize 3
double workTrendEnvelopes[][_trendEnvelopesInstances*_trendEnvelopesInstancesSize];
#define _teSmin  0
#define _teSmax  1 
#define _teTrend 2

//
//---
//

sTrendEnvelope iTrendEnvelope(double valueh, double valuel, double value, double deviation, int i, int bars, int instanceNo=0)
{
   if (ArrayRange(workTrendEnvelopes,0)!=bars) ArrayResize(workTrendEnvelopes,bars); instanceNo*=_trendEnvelopesInstancesSize;
   
   //
   //---
   //
   
   workTrendEnvelopes[i][instanceNo+_teSmax]  = valueh+deviation;
   workTrendEnvelopes[i][instanceNo+_teSmin]  = valuel-deviation;
	workTrendEnvelopes[i][instanceNo+_teTrend] = (i>0) ? (value>workTrendEnvelopes[i-1][instanceNo+_teSmax]) ? 1 : (value<workTrendEnvelopes[i-1][instanceNo+_teSmin]) ? -1 : workTrendEnvelopes[i-1][instanceNo+_teTrend] : 0;
   	if (i>0 && workTrendEnvelopes[i][instanceNo+_teTrend]>0 && workTrendEnvelopes[i][instanceNo+_teSmin]<workTrendEnvelopes[i-1][instanceNo+_teSmin]) workTrendEnvelopes[i][instanceNo+_teSmin] = workTrendEnvelopes[i-1][instanceNo+_teSmin];
	   if (i>0 && workTrendEnvelopes[i][instanceNo+_teTrend]<0 && workTrendEnvelopes[i][instanceNo+_teSmax]>workTrendEnvelopes[i-1][instanceNo+_teSmax]) workTrendEnvelopes[i][instanceNo+_teSmax] = workTrendEnvelopes[i-1][instanceNo+_teSmax];
   
      //
      //---
      //
      
      sTrendEnvelope _result;
	                  _result.trend       = (int)workTrendEnvelopes[i][instanceNo+_teTrend];
                     _result.trendChange = (i>0) ? ( workTrendEnvelopes[i][instanceNo+_teTrend]!=workTrendEnvelopes[i-1][instanceNo+_teTrend]) : false;
                     _result.upline      = (workTrendEnvelopes[i][instanceNo+_teTrend]== 1) ? workTrendEnvelopes[i][instanceNo+_teSmin] : EMPTY_VALUE;
                     _result.downline    = (workTrendEnvelopes[i][instanceNo+_teTrend]==-1) ? workTrendEnvelopes[i][instanceNo+_teSmax] : EMPTY_VALUE;
      return(_result);                  
};