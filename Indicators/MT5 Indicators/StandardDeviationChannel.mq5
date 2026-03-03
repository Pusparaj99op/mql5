//+------------------------------------------------------------------+
//|                                     StandardDeviationChannel.mq5 |
//|                                          Copyright 2014,fxMeter. |
//|                            https://www.mql5.com/en/users/fxmeter |
//+------------------------------------------------------------------+
//2017-07-21 15:37:03 an error found. Updated.
/*
line 137:
midBuffer[i]=A*(CalcBars-i-1)+B;
should be
midBuffer[i]=A*(StarBar+CalcBars-i-1)+B;
*/
//2017-05-17 17:44:17 coded
#property copyright "Copyright 2017,fxMeter."
#property link      "https://www.mql5.com/en/users/fxmeter"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5
//--- plot mid
#property indicator_label1  "mid"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDeepSkyBlue
#property indicator_style1  STYLE_DOT
#property indicator_width1  1
//--- plot top
#property indicator_label2  "top"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDeepSkyBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot btm
#property indicator_label3  "btm"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDeepSkyBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot top2
#property indicator_label4  "top2"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDeepSkyBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot bmt2
#property indicator_label5  "bmt2"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrDeepSkyBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1


input int InputStarBar = 0;//StarBar
input int InputCalcBars = 120;//Bars for Calculation
input double f1=1.0;//Inner Channel Multiplier
input double f2=2.0;//Outer Channel Multiplier



//--- indicator buffers
double         midBuffer[];
double         topBuffer[];
double         btmBuffer[];
double         topBuffer2[];
double         btmBuffer2[];
double         sample[];//sample data for calculating linear regression
//---
int   StarBar  = 0;
int   CalcBars = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,midBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,topBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,btmBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,topBuffer2,INDICATOR_DATA);
   SetIndexBuffer(4,btmBuffer2,INDICATOR_DATA);
   
   for(int i=0;i<5;i++)PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,0.0);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   
   ArraySetAsSeries(midBuffer,true);
   ArraySetAsSeries(topBuffer,true);
   ArraySetAsSeries(btmBuffer,true);
   ArraySetAsSeries(topBuffer2,true);
   ArraySetAsSeries(btmBuffer2,true);
   
   StarBar  = InputStarBar;
   CalcBars = InputCalcBars;
   if(CalcBars<2)CalcBars=120;
   if(StarBar<0)StarBar=0;
   ArrayResize(sample,CalcBars);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   int i;
             
      double A=0.0,B=0.0,stdev=0.0;
      
      if(StarBar+CalcBars>rates_total-1)return(0);    
      
      //explicitly initialize array buffer to zero
      if(prev_calculated==0)
      {
            ArrayInitialize(midBuffer,0.0);
            ArrayInitialize(topBuffer,0.0);
            ArrayInitialize(btmBuffer,0.0);
            ArrayInitialize(topBuffer2,0.0);
            ArrayInitialize(btmBuffer2,0.0);
      }    
    
      //--- copy close data to sample array
      if(CopyClose(Symbol(),PERIOD_CURRENT,StarBar,CalcBars,sample)!=CalcBars)return(0);
       
      //--- use sample data to calculate linear regression,to get the coefficient a and b      
      CalcAB(sample,CalcBars,A,B);        
     for(i=StarBar;i<StarBar+CalcBars&&i<rates_total;i++)
     { 
       midBuffer[i]=A*(StarBar+CalcBars-i-1)+B;    // y =f(x) =a*x+b;    
     }
    
    //--- draw channel 
    stdev = GetStdDev(sample,CalcBars); //calculate standand deviation  
    for(i=StarBar;i<StarBar+CalcBars&&i<rates_total;i++)
     {
       topBuffer[i]=midBuffer[i]+stdev*f1;
       btmBuffer[i]=midBuffer[i]-stdev*f1;  
       topBuffer2[i]=midBuffer[i]+stdev*f2;
       btmBuffer2[i]=midBuffer[i]-stdev*f2;           
     }
    
    //---if a new bar occurs,the last value should be set to EMPTY VALUE
    static int LastTotalBars = 0;
    if(i<rates_total && LastTotalBars!=rates_total)
    {
     midBuffer[i]=0.0;
     topBuffer[i]=0.0;
     btmBuffer[i]=0.0;
     topBuffer2[i]=0.0;
     btmBuffer2[i]=0.0;
     LastTotalBars = rates_total;
    }       
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+


//Linear Regression Calculation for sample data: arr[]
//line equation  y = f(x)  = ax + b
void CalcAB(const double& arr[],int size,double& a,double& b)
{     
     a=0.0;b=0.0; 
    if(size<2)return; 
    
    double sumxy=0.0,sumx=0.0,sumy=0.0,sumx2=0.0; 
    for(int i=0;i<size;i++)
    {
         sumxy+=i*arr[i];
         sumy+=arr[i];
         sumx+=i;
         sumx2+=i*i;        
    }
    
    double M = size*sumx2-sumx*sumx;
    if(M==0.0)return;
    a = (size*sumxy-sumx*sumy)/M;
    b = (sumy-a*sumx)/size;    
}

double GetStdDev(const double &arr[],int size) 
{
    if(size<2)return(0.0);
    
    double sum = 0.0;
    for(int i=0;i<size;i++)
    { 
      sum = sum + arr[i]; 
    } 
        
      sum = sum/size;     
    
    double sum2 = 0.0;
    for(int i=0;i<size;i++) 
    {
      sum2 = sum2 + (arr[i]- sum) * (arr[i]- sum); 
    }  
      
      sum2 = sum2/(size-1);      
      sum2 = MathSqrt(sum2);
      
      return(sum2);
}

