//+------------------------------------------------------------------+
//|                                     AR_Extrapolator_of_Price.mq5 |
//|                                                   Copyright gpwr |
//+------------------------------------------------------------------+
#property copyright "gpwr"
#property version   "1.00"
#property description "Extrapolation of open prices by autoregressive (AR) model"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- future model outputs
#property indicator_label1  "Modeled future"
#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- past model outputs
#property indicator_label2  "Modeled past"
#property indicator_type2   DRAW_LINE
#property indicator_color2  Blue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- indicator inputs
input bool   UseDiff =false; // Use price difference
input int    Ncoef   =150;   // Model coefficients (model order)
input int    Nfut    =100;   // Future bars
input double kPast   =3;     // Past bars in increments of Ncoef (must be >=1)
//--- global variables
int Npast,dN;
//--- indicator buffers
double ym[],xm[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- initialize global variables
   Npast=int(kPast*Ncoef);
   if(UseDiff) dN=1;
   else dN=0;

//--- indicator buffers mapping
   ArraySetAsSeries(xm,true);
   ArraySetAsSeries(ym,true);
   SetIndexBuffer(0,ym,INDICATOR_DATA);
   SetIndexBuffer(1,xm,INDICATOR_DATA);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   IndicatorSetString(INDICATOR_SHORTNAME,"AR("+string(Npast)+","+string(Ncoef)+")");
   PlotIndexSetInteger(0,PLOT_SHIFT,Nfut);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- check for insufficient data
   if(rates_total<Npast+1)
     {
      Print("Error: not enough bars in history!");
      return(0);
     }

//--- initialize indicator buffers to EMPTY_VALUE
   ArrayInitialize(xm,EMPTY_VALUE);
   ArrayInitialize(ym,EMPTY_VALUE);

//--- make all prices available
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   if(CopyRates(NULL,0,0,Npast+1,rates)<=0) return(0);

//--- Main cycle
//--- prepare model inputs
   double x[];
   ArrayResize(x,Npast);
   for(int i=0;i<Npast;i++) x[Npast-1-i]=rates[i].open-rates[i+1].open*dN;

//--- solve for AR model coefficients
   double a[];
   ArrayResize(a,Ncoef+1);
   Burg(x,Npast,Ncoef,a);

//--- calculate past and future predictions by fitted AR model
   for(int n=Ncoef;n<Npast+Nfut;n++)
     {
      double sum=0.0;
      for(int i=1;i<=Ncoef;i++)
        {
         if(n-i<Npast) sum-=a[i]*x[n-i];
         else sum-=a[i]*ym[Nfut+Npast-(n-i)];
        }
      if(n<Npast) xm[Npast-1-n]=sum;
      else ym[Nfut+Npast-n]=sum;
     }

//--- convert predictions from differences to prices
   if(UseDiff)
     {
      double tmp=xm[0];
      xm[0]=rates[0].open;
      for(int i=1;i<Npast-Ncoef;i++)
        {
         double tmp2=xm[i];
         xm[i]=xm[i-1]-tmp;
         tmp=tmp2;
        }
     }
   ym[Nfut]=xm[0];
   if(UseDiff)
     {
      for(int i=1;i<=Nfut;i++)
         ym[Nfut-i]+=ym[Nfut-i+1];
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Burg method                                                      |
//+------------------------------------------------------------------+
void Burg(double &x[],int n,int p,double &a[])
  {
   double df[],db[];
   ArrayResize(df,n);
   ArrayResize(db,n);
   double tmp,num,den,r;
   for(int i=0;i<n;i++)
     {
      df[i]=x[i];
      db[i]=x[i];
     }
//--- main loop
   for(int k=1;k<=p;k++)
     {
      //--- calculate reflection coefficient
      num=0.0;
      den=0.0;
      if(k==1)
        {
         for(int i=2;i<n;i++)
           {
            num+=x[i-1]*(x[i]+x[i-2]);
            den+=x[i-1]*x[i-1];
           }
         r=-num/den/2.0;
         if(r> 1.0) r= 1.0;
         if(r<-1.0) r=-1.0;
        }
      else
        {
         for(int i=k;i<n;i++)
           {
            num+=df[i]*db[i-1];
            den+=(df[i]*df[i]+db[i-1]*db[i-1]);
           }
         r=-2.0*num/den;
        }
      //--- calculate prediction coefficients
      a[k]=r;
      int kh=k/2;
      for(int i=1;i<=kh;i++)
        {
         int ki=k-i;
         tmp=a[i];
         a[i]+=r*a[ki];
         if(i!=ki) a[ki]+=r*tmp;
        }
      if(k<p)
         //--- calculate new residues
         for(int i=n-1;i>=k;i--)
           {
            tmp=df[i];
            df[i]+=r*db[i-1];
            db[i]=db[i-1]+r*tmp;
           }
     }
  }
//+------------------------------------------------------------------+
