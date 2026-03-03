//+------------------------------------------------------------------+
//|                                               VHPChannel_01.mq5  |
//+------------------------------------------------------------------+
#property description "VHPChannel"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4
//---- plot ExtAMABuffer
#property indicator_label1  "VHPChannel"
#property indicator_type1   DRAW_LINE
#property indicator_color1  Gold
#property indicator_type2   DRAW_LINE
#property indicator_color2  LightSlateGray
#property indicator_style2  3
#property indicator_type3   DRAW_LINE
#property indicator_color3  DarkOrange
#property indicator_type4   DRAW_LINE
#property indicator_color4  DarkOrange
//--- input parameters
input int InpHPPeriodFast=21;    // HP Fast Period (4...32)
input int InpHPPeriodSlow=144;   // HP Slow Period (48...256)
//--- indicator buffers
double HP[],HPSlow[],Dev1[],Dev2[];
//--- global variables
int HPPeriodFast,HPPeriodSlow;
double Lambda,Lambda2;
string ShortName;
//+------------------------------------------------------------------+
//| Indicator initialization function                                |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- check for input values
   if(InpHPPeriodFast<4 || InpHPPeriodFast>32)
     {
      printf("Input parameter InpHPPeriodFast has incorrect value (%d). Indicator will use value 21 for calculations.",InpHPPeriodFast);
      HPPeriodFast=21;
     }
   else HPPeriodFast=InpHPPeriodFast;
   if(InpHPPeriodSlow<48 || InpHPPeriodSlow>256)
     {
      printf("Input parameter InpHPPeriodSlow has incorrect value (%d). Indicator will use value 144 for calculations.",InpHPPeriodSlow);
      HPPeriodSlow=144;
     }
   else HPPeriodSlow=InpHPPeriodSlow;
//--- indicator buffers mapping
   SetIndexBuffer(0,HP,INDICATOR_DATA);
   ArraySetAsSeries(HP,true);
   SetIndexBuffer(1,HPSlow,INDICATOR_DATA);
   ArraySetAsSeries(HPSlow,true);
   SetIndexBuffer(2,Dev1,INDICATOR_DATA);
   ArraySetAsSeries(Dev1,true);
   SetIndexBuffer(3,Dev2,INDICATOR_DATA);
   ArraySetAsSeries(Dev2,true);
//--- set shortname and change label
   ShortName="VHPChannel("+IntegerToString(HPPeriodFast)+","+IntegerToString(HPPeriodSlow)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,ShortName);
   PlotIndexSetString(0,PLOT_LABEL,"HP");
   PlotIndexSetString(1,PLOT_LABEL,"HPSlow");
   PlotIndexSetString(2,PLOT_LABEL,"Dev1");
   PlotIndexSetString(3,PLOT_LABEL,"Dev2");
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//
   Lambda=0.0625/MathPow(MathSin(M_PI/HPPeriodFast),4);   // коэфф. сглаживания быстрой HP
   Lambda2=0.0625/MathPow(MathSin(M_PI/HPPeriodSlow),4);  // коэфф. сглаживания медленной HP            

   ObjectCreate(0,ShortName,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,ShortName,OBJPROP_ANCHOR,ANCHOR_RIGHT_LOWER);
   ObjectSetInteger(0,ShortName,OBJPROP_CORNER,CORNER_RIGHT_LOWER);
   ObjectSetInteger(0,ShortName,OBJPROP_XDISTANCE,32);
   ObjectSetInteger(0,ShortName,OBJPROP_YDISTANCE,28);
   ObjectSetInteger(0,ShortName,OBJPROP_FONTSIZE,11);
   ObjectSetInteger(0,ShortName,OBJPROP_COLOR,LimeGreen);
   ObjectSetInteger(0,ShortName,OBJPROP_SELECTABLE,true);

   ObjectSetString(0,ShortName,OBJPROP_FONT,"Tahoma");

   return(0);
  }
//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(0,ShortName);
  }
//+------------------------------------------------------------------+
//| Indicator iteration function                                     |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
   int i;
   double InpDat[],disp,dev,val;

   if(rates_total<HPPeriodSlow+1) return(0);
   if(rates_total!=prev_calculated)
     {
      i=Bars(Symbol(),0)-HPPeriodSlow;
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,i);
      PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,i);
      PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,i);
      PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,i);
     }
   ArraySetAsSeries(Close,true);
   ArrayResize(InpDat,HPPeriodSlow);
   ArraySetAsSeries(InpDat,true);
   for(i=0;i<HPPeriodSlow;i++) InpDat[i]=Close[i];
//-----------------------------------HP fast-------------
   HPF(HPPeriodSlow,Lambda,InpDat,HP);
//-----------------------------------HP slow-------------
   HPF(HPPeriodSlow,Lambda2,HP,HPSlow);
//-----------------------------------Std    -------------
   disp=0.0;
   for(i=0;i<HPPeriodSlow;i++) disp+=(HP[i]-HPSlow[i])*(HP[i]-HPSlow[i]);
   disp=disp/(HPPeriodSlow-1);
   dev=MathSqrt(disp)*2.0;
   for(i=0;i<HPPeriodSlow;i++) 
   {
   Dev1[i]=HPSlow[i]+dev; 
   Dev2[i]=HPSlow[i]-dev;
   }
//-------------------------------------------------------
   val=dev/HPSlow[0]*200;
   ObjectSetString(0,ShortName,OBJPROP_TEXT,"Channel="+DoubleToString(val,2)+"%");

   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Hodrick-Prescott Filter                                          |
//+------------------------------------------------------------------+
void HPF(int nobs,double lambda,double &x[],double &y[])
  {
   double a[],b[],c[],H1=0,H2=0,H3=0,H4=0,H5=0,HH1=0,HH2=0,HH3=0,HH5=0,HB=0,HC=0,Z=0;
   int i;

   ArrayResize(a,nobs);
   ArrayResize(b,nobs);
   ArrayResize(c,nobs);

   ZeroMemory(a);
   ZeroMemory(b);
   ZeroMemory(c);
   
   a[0]=1.0+lambda;
   b[0]=-2.0*lambda;
   c[0]=lambda;
   for(i=1;i<nobs-2;i++)
     {
      a[i]=6.0*lambda+1.0;
      b[i]=-4.0*lambda;
      c[i]=lambda;
     }
   a[1]=5.0*lambda+1;
   a[nobs-1]=1.0+lambda;
   a[nobs-2]=5.0*lambda+1.0;
   b[nobs-2]=-2.0*lambda;
   b[nobs-1]=0.0;
   c[nobs-2]=0.0;
   c[nobs-1]=0.0;
//--- forward
   for(i=0;i<nobs;i++)
     {
      Z=a[i]-H4*H1-HH5*HH2;
      HB=b[i];
      HH1=H1;
      H1=(HB-H4*H2)/Z;
      b[i]=H1;
      HC=c[i];
      HH2=H2;
      H2=HC/Z;
      c[i]=H2;
      a[i]=(x[i]-HH3*HH5-H3*H4)/Z;
      HH3=H3;
      H3=a[i];
      H4=HB-H5*HH1;
      HH5=H5; H5=HC;
     }
//Backward 
   H2=0;
   H1=a[nobs-1];
   y[nobs-1]=H1;
   for(i=nobs-2;i>=0;i--)
     {
      y[i]=a[i]-b[i]*H1-c[i]*H2;
      H2=H1;
      H1=y[i]; 
     }
  }
//-----------------------------------------------------------------------------
