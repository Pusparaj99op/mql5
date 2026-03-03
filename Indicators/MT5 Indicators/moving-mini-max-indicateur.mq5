//+------------------------------------------------------------------+
//|                                                MovingMiniMax.mq5 |
//|                                      Copyright 2011, Investeo.pl |
//|                                               http://Investeo.pl |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2011, Investeo.pl"
#property link        "http://Investeo.pl"

#property description "Moving Mini-Max indicator"
#property description "proposed by Z.K. Silagadze"
#property description "from Budker Institute of Nuclear Physics"
#property description "and Novosibirsk State University"
#property description "Original paper can be downloaded from:"
#property description "http://arxiv.org/abs/0802.0984"

#property version     "0.6"
#property indicator_separate_window

#property indicator_buffers 5
#property indicator_plots 3

#property indicator_type1 DRAW_COLOR_HISTOGRAM2
#property indicator_type2 DRAW_ARROW
#property indicator_type3 DRAW_ARROW

#property indicator_color1 Chartreuse, OrangeRed, Yellow
#property indicator_color2 RoyalBlue
#property indicator_color3 RoyalBlue

#property indicator_width1 5
#property indicator_width2 4
#property indicator_width3 4

input int m=5;   // Smoothing window width
input int n=300; // Time window width

double S[];

double sQiip1[],sQiim1[];
double sPiip1[],sPiim1[];
double dQiip1[],dQiim1[];
double dPiip1[],dPiim1[];

double sui[],dui[],uSi[],dSi[];

double upArrows[],dnArrows[];
double trend[];

int rCnt;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
//---
   rCnt=0;

   ArrayResize(S,n+2*m);
   ArrayResize(sQiip1,n);
   ArrayResize(sQiim1,n);
   ArrayResize(sPiip1,n);
   ArrayResize(sPiim1,n);
   ArrayResize(sui,n);

   ArrayResize(dQiip1,n);
   ArrayResize(dQiim1,n);
   ArrayResize(dPiip1,n);
   ArrayResize(dPiim1,n);
   ArrayResize(dui,n);

   ArraySetAsSeries(uSi,true);
   ArraySetAsSeries(dSi,true);
   ArraySetAsSeries(upArrows,true);
   ArraySetAsSeries(dnArrows,true);
   ArraySetAsSeries(trend,true);

   SetIndexBuffer(0,uSi,INDICATOR_DATA);
   SetIndexBuffer(1,dSi,INDICATOR_DATA);
   SetIndexBuffer(2,trend,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3,upArrows,INDICATOR_DATA);
   SetIndexBuffer(4,dnArrows,INDICATOR_DATA);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);

   PlotIndexSetInteger(1,PLOT_ARROW,234);
   PlotIndexSetInteger(2,PLOT_ARROW,233);

   PlotIndexSetInteger(0,PLOT_SHIFT,-(m-1));
   PlotIndexSetInteger(1,PLOT_SHIFT,-(m-1));
   PlotIndexSetInteger(2,PLOT_SHIFT,-(m-1));

   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

void calcQii()
  {
   int i,k;

   for(i=0; i<n; i++)
     {
      double sqiip1=0;
      double sqiim1=0;
      double dqiip1=0;
      double dqiim1=0;

      for(k=0; k<m; k++)
        {
         sqiip1 += MathExp(2*(S[m-1+i+k]-S[i])/(S[m-1+i+k]+S[i]));
         sqiim1 += MathExp(2*(S[m-1+i-k]-S[i])/(S[m-1+i-k]+S[i]));

         dqiip1 += MathExp(-2*(S[m-1+i+k]-S[i])/(S[m-1+i+k]+S[i]));
         dqiim1 += MathExp(-2*(S[m-1+i-k]-S[i])/(S[m-1+i-k]+S[i]));
        }
      sQiip1[i] = sqiip1;
      sQiim1[i] = sqiim1;
      dQiip1[i] = dqiip1;
      dQiim1[i] = dqiim1;

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcPii()
  {
   int i;

   for(i=0; i<n; i++)
     {
      sPiip1[i] = sQiip1[i] / (sQiip1[i] + sQiim1[i]);
      sPiim1[i] = sQiim1[i] / (sQiip1[i] + sQiim1[i]);
      dPiip1[i] = dQiip1[i] / (dQiip1[i] + dQiim1[i]);
      dPiim1[i] = dQiim1[i] / (dQiip1[i] + dQiim1[i]);

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcui()
  {
   int i;

   sui[0] = 1;
   dui[0] = 1;

   for(i=1; i<n; i++)
     {
      sui[i] = (sPiim1[i]/sPiip1[i])*sui[i-1];
      dui[i] = (dPiim1[i]/dPiip1[i])*dui[i-1];
     }

   double uSum = 0;
   double dSum = 0;

   ArrayInitialize(uSi, 0.0);
   ArrayInitialize(dSi, 0.0);

   for(i=0; i<n; i++) { uSum+=sui[i]; dSum+=dui[i]; }
   for(i=0; i<n; i++) { uSi[n-1-i] = sui[i] / uSum; dSi[n-1-i] = dui[i] / dSum; }

/* normalization verification
   double result=0;
   for(i=0; i<n; i++) { Print("i = "+i+" uSi = "+uSi[i]);  result+=uSi[i]; }

   Print("Result = "+DoubleToString(result));
   */
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setArrows()
  {
// set up and down arrows for local maximums and minimums
   int i;
   int upind=0,dnind=0;
   double upval=uSi[0],dnval=dSi[0];

   ArrayInitialize(upArrows, 0.0);
   ArrayInitialize(dnArrows, 0.0);

// find local minimum and maximum indexes
   for(i=1; i<n; i++)
     {
      if(dSi[i]>dnval) { dnval=dSi[i]; dnind=i; }
      if(uSi[i]>upval) { upval=uSi[i]; upind=i; }
     }

// plot arrows
   upArrows[dnind]=(dnval+uSi[dnind])/2.0;
   dnArrows[upind]=(upval+dSi[upind])/2.0;

   if(upind<dnind)
     {
      for(i=0; i<upind; i++) trend[i]=0;
      for(i=upind; i<dnind; i++) trend[i]=1;
      for(i=dnind; i<n; i++) trend[i]=0;
     }
   else
     {
      for(i=0; i<dnind; i++) trend[i]=1;
      for(i=dnind; i<upind; i++) trend[i]=0;
      for(i=upind; i<n; i++) trend[i]=1;
     }

   trend[upind] = 2;
   trend[dnind] = 2;
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
//--- return value of prev_calculated for next call
   long tickCnt[1];

   int ticks=CopyTickVolume(Symbol(), 0, 0, 1, tickCnt);
   if(ticks!=1) return(rates_total);

   if(prev_calculated==0 || tickCnt[0]==1)
     {
      rCnt=CopyClose(Symbol(),0,0,n+2*m,S);
      if(rCnt==n+2*m)
        {
         calcQii();
         calcPii();
         calcui();
         setArrows();
        }
      else Print(__FILE__+__FUNCTION__+" received values: ",rCnt);

     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
