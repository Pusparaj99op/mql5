//+------------------------------------------------------------------+
//|                                                 Extrapolator.mq5 |
//|                                           Copyright © 2008, gpwr | 
//|                                               vlad1004@yahoo.com | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, gpwr"
#property link "vlad1004@yahoo.com"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- two buffers are used for calculation and drawing the indicator
#property indicator_buffers 2
//---- two plots are used
#property indicator_plots   2

//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- red color is used as the color of the indicator line
#property indicator_color1  Red
//---- line of the indicator 1 is a continuous line
#property indicator_style1  STYLE_SOLID
//---- thickness of line of the indicator 1 is equal to 1
#property indicator_width1  1
//---- displaying the indicator line label
#property indicator_label1  ""

//---- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used as the color of the indicator line
#property indicator_color2  Blue
//---- line of the indicator 2 is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- thickness of line of the indicator 2 is equal to 1
#property indicator_width2  1
//---- displaying a label of the indicator
#property indicator_label2  ""

//---- 
#define pi 3.141592653589793238462643383279502884197169399375105820974944592
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
enum Method_ //Type of constant
  {
   Extrapolation = 1, //Extrapolation Method
   Autocorrelation,   //Autocorrelation Method
   Weight,            //Weighted Burg Method
   Burg,              //Burg Method with Helme-Nikias weighting function
   Itakura,           //Itakura-Saito (geometric) method
   covariance         //Modified covariance method
  };

input Method_ Method   = 1;
input int     LastBar  = 30;
input int     PastBars = 300;
input double  LPOrder  = 0.6;
input int     FutBars  = 100;
input int     HarmNo   = 20;
input double  FreqTOL  = 0.0001;
input int     BurgWin  = 0;
//---- declaration of dynamic arrays that 
// will be used as indicator buffers
double FV_Buffer[];
double PV_Buffer[];

double ETA,INFTY,SMNO;
int np,nf,lb,no,it,StartBar;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of constants
   lb=LastBar;
   np=PastBars;
   no=int (LPOrder*PastBars);
   nf=FutBars;
   if(Method>1) nf=np-no-1;
//---- initialization of constants
   StartBar=PastBars;
//---- set MAMABuffer dynamic array as indicator buffer
   SetIndexBuffer(0,FV_Buffer,INDICATOR_DATA);
//---- create label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"");
//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBar);
//---- indexing elements in arrays as timeseries 
   ArraySetAsSeries(FV_Buffer,true);
//---- shifting the indicator horizontally by nf-lb
   PlotIndexSetInteger(0,PLOT_SHIFT,nf-lb);

//---- set FAMABuffer dynamic array as indicator buffer
   SetIndexBuffer(1,PV_Buffer,INDICATOR_DATA);
//---- create label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"");
//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBar);
//---- indexing elements in arrays as timeseries    
   ArraySetAsSeries(PV_Buffer,true);
//---- shifting the indicator horizontally by -lb
   PlotIndexSetInteger(1,PLOT_SHIFT,-lb);

//---- initializations of variable for indicator short name
   string shortname="Extrapolator";
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<StartBar) return(0);

   ArrayInitialize(PV_Buffer,EMPTY_VALUE);
   ArrayInitialize(FV_Buffer,EMPTY_VALUE);

//---- indexing elements in arrays as timeseries 
   ArraySetAsSeries(open,true);

   double a[],x[],av=0.0;
   for(int i=0;i<np;i++) av+=open[i+lb];
   av/=np;

   if(Method==1)
     {
      for(int i=0;i<np;i++)
        {
         PV_Buffer[i]=av;
         if(i<=nf) FV_Buffer[i]=av;
        }
     }
   else
     {
      ArrayResize(a,no+1);
      ArrayResize(x,np);
      for(int i=0;i<np;i++) x[np-1-i]=open[i+lb]-av;
     }

   switch(Method)
     {
      case 1:
        {
         double w,m,c,s;
         for(int harm=0;harm<HarmNo;harm++)
           {
            Freq(w,m,c,s,open);
            for(int i=0;i<np;i++)
              {
               PV_Buffer[i]+=m+c*MathCos(w*i)+s*MathSin(w*i);
               if(i<=nf) FV_Buffer[i]+=m+c*MathCos(w*i)-s*MathSin(w*i);
              }
           }
         break;
        }

      case 2: ACF(x,no,a);break;
      case 3: WBurg(x,no,BurgWin,a);break;
      case 4: HNBurg(x,no,a);break;
      case 5: Geom(x,no,a);break;
      case 6:
        {
         bool stop=0;
         MCov(x,no,a,stop);
         if(stop==1)
           {
            Print(__FUNCTION__,"(): Early stop");
            return(0);
           }
         for(int i=no;i>=1;i--) a[i]=a[i-1];
        }
     }

   if(Method>1)
     {
      for(int n=no;n<np+nf;n++)
        {
         double sum=0.0;
         for(int i=1;i<=no;i++)
            if(n-i<np) sum-=a[i]*x[n-i];
         else sum-=a[i]*FV_Buffer[n-i-np+1];

         if(n<np) PV_Buffer[np-1-n]=sum;
         else FV_Buffer[n-np+1]=sum;
        }

      FV_Buffer[0]=PV_Buffer[0];

      for(int i=0;i<np-no;i++)
        {
         PV_Buffer[i]+=av;
         FV_Buffer[i]+=av;
        }
     }

   double tmp;
   for(int i=0;i<=(nf-1)/2.0;i++)
     {
      tmp=FV_Buffer[i];
      FV_Buffer[i]=FV_Buffer[nf-i];
      FV_Buffer[nf-i]=tmp;
     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ACF function                                                     |
//+------------------------------------------------------------------+ 
void Freq(double &w,double &m,double &c,double &s,const double &Open[])
  {
//----
   double z[],num,den;
   ArrayResize(z,np);
   double a=0.0;
   double b=2.0;
   z[0]=Open[lb]-PV_Buffer[0];
   while(MathAbs(a-b)>FreqTOL)
     {
      a=b;
      z[1]=Open[1+lb]-PV_Buffer[1]+a*z[0];
      num=z[0]*z[1];
      den=z[0]*z[0];
      for(int i=2;i<np;i++)
        {
         z[i]=Open[i+lb]-PV_Buffer[i]+a*z[i-1]-z[i-2];
         num+=z[i-1]*(z[i]+z[i-2]);
         den+=z[i-1]*z[i-1];
        }
      b=num/den;
     }
   w=MathArccos(b/2.0);
   Fit(w,m,c,s,Open);
   return;
//----
  }
//+------------------------------------------------------------------+
//| ACF function                                                     |
//+------------------------------------------------------------------+ 
void Fit(double w,double &m,double &c,double &s,const double &Open[])
  {
//----
   double Sc=0.0;
   double Ss=0.0;
   double Scc=0.0;
   double Sss=0.0;
   double Scs=0.0;
   double Sx=0.0;
   double Sxx=0.0;
   double Sxc=0.0;
   double Sxs=0.0;
   for(int i=0;i<np;i++)
     {
      double cos=MathCos(w*i);
      double sin=MathSin(w*i);
      Sc+=cos;
      Ss+=sin;
      Scc+=cos*cos;
      Sss+=sin*sin;
      Scs+=cos*sin;
      Sx+=(Open[i+lb]-PV_Buffer[i]);
      Sxx+=MathPow(Open[i+lb]-PV_Buffer[i],2);
      Sxc+=(Open[i+lb]-PV_Buffer[i])*cos;
      Sxs+=(Open[i+lb]-PV_Buffer[i])*sin;
     }
   Sc/=np;
   Ss/=np;
   Scc/=np;
   Sss/=np;
   Scs/=np;
   Sx/=np;
   Sxx/=np;
   Sxc/=np;
   Sxs/=np;

   if(w==0.0)
     {
      m=Sx;
      c=0.0;
      s=0.0;
     }
   else
     {
      double den=MathPow(Scs-Sc*Ss,2)-(Scc-Sc*Sc)*(Sss-Ss*Ss);
      c=((Sxs-Sx*Ss)*(Scs-Sc*Ss)-(Sxc-Sx*Sc)*(Sss-Ss*Ss))/den;
      s=((Sxc-Sx*Sc)*(Scs-Sc*Ss)-(Sxs-Sx*Ss)*(Scc-Sc*Sc))/den;
      m=Sx-c*Sc-s*Ss;
     }
   return;
//----
  }
//+------------------------------------------------------------------+
//| ACF function                                                     |
//+------------------------------------------------------------------+ 
void ACF(double &x[],int p,double &a[])
  {
//----
   int n=ArraySize(x);
   double rxx[],r,E,tmp;
   ArrayResize(rxx,p+1);
   int i,j,k,kh,ki;

   for(j=0;j<=p;j++)
     {
      rxx[j]=0.0;
      for(i=j;i<n;i++) rxx[j]+=x[i]*x[i-j];
     }
   E=rxx[0];

   for(k=1;k<=p;k++)
     {
      r=-rxx[k];
      for(i=1;i<k;i++) r-=a[i]*rxx[k-i];
      r/=E;
      a[k]=r;
      kh=k/2;
      for(i=1;i<=kh;i++)
        {
         ki=k-i;
         tmp=a[i];
         a[i]+=r*a[ki];
         if(i!=ki) a[ki]+=r*tmp;
        }

      E*=(1-r*r);
     }
//----
  }
//+------------------------------------------------------------------+
//| WBurg function                                                   |
//+------------------------------------------------------------------+ 
void WBurg(double &x[],int p,int w,double &a[])
  {
//----
   int n=ArraySize(x);
   double df[],db[];
   ArrayResize(df,n);
   ArrayResize(db,n);
   int i,k,kh,ki;
   double tmp,num,den,r;
   for(i=0;i<n;i++)
     {
      df[i]=x[i];
      db[i]=x[i];
     }

   for(k=1;k<=p;k++)
     {
      num=0.0;
      den=0.0;
      if(k==1)
        {
         for(i=2;i<n;i++)
           {
            num+=win(i,2,n,w)*x[i-1]*(x[i]+x[i-2]);
            den+=win(i,2,n,w)*x[i-1]*x[i-1];
           }
         r=-num/den/2.0;
         if(r>1) r=1.0;
         if(r<-1.0) r=-1.0;
        }
      else
        {
         for(i=k;i<n;i++)
           {
            num+=win(i,k,n,w)*df[i]*db[i-1];
            den+=win(i,k,n,w)*(df[i]*df[i]+db[i-1]*db[i-1]);
           }
         r=-2.0*num/den;
        }

      a[k]=r;
      kh=k/2;
      for(i=1;i<=kh;i++)
        {
         ki=k-i;
         tmp=a[i];
         a[i]+=r*a[ki];
         if(i!=ki) a[ki]+=r*tmp;
        }
      if(k<p)
         for(i=n-1;i>=k;i--)
           {
            tmp=df[i];
            df[i]+=r*db[i-1];
            db[i]=db[i-1]+r*tmp;
           }
     }
//----
  }
//+------------------------------------------------------------------+
//| win function                                                     |
//+------------------------------------------------------------------+ 
double win(int i,int k,int n,int w)
  {
//----
   if(w==0) return(1.0);
   if(w==1) return(0.54-0.46*MathCos(pi*(2.0*(i-k)+1.0)/(n-k)));
   if(w==2) return(6.0*(i-k+1.0)*(n-i)/(n-k)/(n-k+1.0)/(n-k+2.0));
//----
   return(0.0);
  }
//+------------------------------------------------------------------+
//| HNBurg function                                                  |
//+------------------------------------------------------------------+ 
void HNBurg(double &x[],int p,double &a[])
  {
//----
   int n=ArraySize(x);
   double df[],db[];
   ArrayResize(df,n);
   ArrayResize(db,n);
   int i,k,kh,ki;
   double w,tmp,num,den,r;
   for(i=0;i<n;i++)
     {
      df[i]=x[i];
      db[i]=x[i];
     }

   for(k=1;k<=p;k++)
     {
      num=0.0;
      den=0.0;
      if(k==1)
        {
         for(i=2;i<n;i++)
           {
            w=x[i-1]*x[i-1];
            num+=w*x[i-1]*(x[i]+x[i-2]);
            den+=w*x[i-1]*x[i-1];
           }
         r=-num/den/2.0;
         if(r>1) r=1.0;
         if(r<-1.0) r=-1.0;
        }
      else
        {
         w=0.0;
         for(i=1;i<k;i++) w+=x[i]*x[i];
         for(i=k;i<n;i++)
           {
            num+=w*df[i]*db[i-1];
            den+=w*(df[i]*df[i]+db[i-1]*db[i-1]);
            w=w+x[i]*x[i]-x[i-k+1]*x[i-k+1];
           }
         r=-2.0*num/den;
        }

      a[k]=r;
      kh=k/2;
      for(i=1;i<=kh;i++)
        {
         ki=k-i;
         tmp=a[i];
         a[i]+=r*a[ki];
         if(i!=ki) a[ki]+=r*tmp;
        }
      if(k<p)
         for(i=n-1;i>=k;i--)
           {
            tmp=df[i];
            df[i]+=r*db[i-1];
            db[i]=db[i-1]+r*tmp;
           }
     }
//----
  }
//+------------------------------------------------------------------+
//|  Geom function                                                   |
//+------------------------------------------------------------------+ 
void Geom(double &x[],int p,double &a[])
  {
//----
   int n=ArraySize(x);
   double df[],db[];
   ArrayResize(df,n);
   ArrayResize(db,n);
   int i,k,kh,ki;
   double tmp,num,denf,denb,r;
   for(i=0;i<n;i++)
     {
      df[i]=x[i];
      db[i]=x[i];
     }

   for(k=1;k<=p;k++)
     {
      num=0.0;
      denf=0.0;
      denb=0.0;
      for(i=k;i<n;i++)
        {
         num+=df[i]*db[i-1];
         denf+=df[i]*df[i];
         denb+=db[i-1]*db[i-1];
        }
      r=-num/MathSqrt(denf)/MathSqrt(denb);
      a[k]=r;
      kh=k/2;
      for(i=1;i<=kh;i++)
        {
         ki=k-i;
         tmp=a[i];
         a[i]+=r*a[ki];
         if(i!=ki) a[ki]+=r*tmp;
        }
      if(k<p)
         for(i=n-1;i>=k;i--)
           {
            tmp=df[i];
            df[i]+=r*db[i-1];
            db[i]=db[i-1]+r*tmp;
           }
     }
//----
  }
//+------------------------------------------------------------------+
//| MCov function                                                    |
//+------------------------------------------------------------------+ 
void MCov(double &x[],int ip,double &a[],bool &stop)
  {
//----
   int n=ArraySize(x);
   double c[],d[],r[],v;
   ArrayResize(c,ip+1);
   ArrayResize(d,ip+1);
   ArrayResize(r,ip);
   int k,m,mk;
   double r1,r2,r3,r4,r5,delta,gamma,lambda,theta,psi,xi;
   double save1,save2,save3,save4,c1,c2,c3,c4,ef,eb;
   r1=0.0;
   for(k=1;k<n-1;k++) r1+=2.0*x[k]*x[k];
   r2=x[n-1]*x[n-1];
   r3=x[0]*x[0];
   r4=1.0/(r1+2.0*(r2+r3));
   v=r1+r2+r3;
   delta=1.0-r2*r4;
   gamma=1.0-r3*r4;
   lambda=x[0]*x[n-1]*r4;
   c[0]=x[0]*r4;
   d[0]=x[n-1]*r4;

   for(m=0;;m++)
     {
      save1=0.0;
      for(k=m+1;k<n;k++) save1+=x[n-1-k]*x[n-k+m];
      save1*=2.0;
      r[m]=save1;
      theta=x[0]*d[0];
      psi=x[0]*c[0];
      xi=x[n-1]*d[0];
      if(m>0)
        {
         for(k=1;k<=m;k++)
           {
            theta+=x[k]*d[k];
            psi+=x[k]*c[k];
            xi+=x[n-1-k]*d[k];
            r[k-1]-=(x[m]*x[m-k]+x[n-1-m]*x[n-1-m+k]);
            save1+=r[k-1]*a[m-k];
           }
        }

      c1=-save1/v;
      a[m]=c1;
      v*=(1.0-c1*c1);

      if(m>0)
        {
         for(k=0;k<(m+1)/2;k++)
           {
            mk=m-k-1;
            save1=a[k];
            a[k]=save1+c1*a[mk];
            if(k!=mk) a[mk]+=c1*save1;
           }
        }

      if(m==ip-1)
        {
         v*=(0.5/(n-1-m));
         break;
        }

      r1=1.0/(delta*gamma-lambda*lambda);
      c1=(theta*lambda+psi*delta)*r1;
      c2=(psi*lambda+theta*gamma)*r1;
      c3=(xi*lambda+theta*delta)*r1;
      c4=(theta*lambda+xi*gamma)*r1;
      for(k=0;k<=m/2;k++)
        {
         mk=m-k;
         save1=c[k];
         save2=d[k];
         save3=c[mk];
         save4=d[mk];
         c[k]+=(c1*save3+c2*save4);
         d[k]+=(c3*save3+c4*save4);
         if(k!=mk)
           {
            c[mk]+=(c1*save1+c2*save2);
            d[mk]+=(c3*save1+c4*save2);
           }
        }
      r2=psi*psi;
      r3=theta*theta;
      r4=xi*xi;
      r5=gamma-(r2*delta+r3*gamma+2.0*psi*lambda*theta)*r1;
      r2=delta-(r3*delta+r4*gamma+2.*theta*lambda*xi)*r1;
      gamma=r5;
      delta=r2;
      lambda+=(c3*psi+c4*theta);
      if(v<=0.0)
        {
         Print(__FUNCTION__,"(): Error! : Negative or zero value of the v variable");
         stop=true;
         return;
        }
      if(delta<=0.0 || delta>1.0 || gamma<=0.0 || gamma>1.0)
        {
         Print(__FUNCTION__,"(): (): Error! : delta and gamma variables values out of the range (0,1)");
         stop=true;
         return;
        }

      r1=1.0/v;
      r2=1.0/(delta*gamma-lambda*lambda);
      ef=x[n-m-2];
      eb=x[m+1];
      for(k=0;k<=m;k++)
        {
         ef+=a[k]*x[n-1-m+k];
         eb+=a[k]*x[m-k];
        }
      c1=eb*r1;
      c2=ef*r1;
      c3=(eb*delta+ef*lambda)*r2;
      c4=(ef*gamma+eb*lambda)*r2;
      for(k=m;k>=0;k--)
        {
         save1=a[k];
         a[k]=save1+c3*c[k]+c4*d[k];
         c[k+1]=c[k]+c1*save1;
         d[k+1]=d[k]+c2*save1;
        }
      c[0]=c1;
      d[0]=c2;
      r3=eb*eb;
      r4=ef*ef;
      v-=(r3*delta+r4*gamma+2.0*ef*eb*lambda)*r2;
      delta-=r4*r1;
      gamma-=r3*r1;
      lambda+=ef*eb*r1;
      if(v<=0.0)
        {
         Print(__FUNCTION__,"(): Error! : Negative or zero value of the v variable");
         stop=true;
         return;
        }
      if(delta<=0.0 || delta>1.0 || gamma<=0.0 || gamma>1.0)
        {
         Print(__FUNCTION__,"(): (): Error! : delta and gamma variables values out of the range (0,1)");
         stop=true;
         return;
        }
     }
//----
  }
//+------------------------------------------------------------------+
