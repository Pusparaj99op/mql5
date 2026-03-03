//+--------------------------------------------------------------------+
//|                                                       Phoenix5.mq5 |
//|                                     Copyright © 2006, fryk@tlen.pl | 
//|This indicator is based on Phoenix_v4_2_CONTEST.mq4 © 2006 Hendrick | 
//+--------------------------------------------------------------------+
#property copyright "Copyright © 2006, fryk@tlen.pl"
#property link ""
#property description ""
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- two buffers are used for calculation of drawing of the indicator
#property indicator_buffers 2
//---- only two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- magenta color is used as the color of the bearish indicator line
#property indicator_color1  clrMagenta
//---- indicator 1 line width is equal to 4
#property indicator_width1  4
//---- bullish indicator label display
#property indicator_label1  "Phoenix5 Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- blue color is used for the indicator bullish line
#property indicator_color2  clrBlue
//---- indicator 2 line width is equal to 4
#property indicator_width2  4
//---- bearish indicator label display
#property indicator_label2 "Phoenix5 Buy"

#define RESET 0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint        iSMAPeriod          =7;
input uint        iSMA2Bars           =14;
input double      iPercent            =0.0032;
input uint        iEnvelopePeriod     =2;
input uint        iOSMAFast           =5;
input uint        iOSMASlow           =30;
input uint        iOSMASignal         =2;
//----
input uint        iFast_Period        =25;
input ENUM_APPLIED_PRICE  iFast_Price =PRICE_OPEN;
input uint        iSlow_Period        =15;
input ENUM_APPLIED_PRICE  iSlow_Price =PRICE_OPEN;
input double      iDVBuySell          =0.003;
input double      iDVStayOut          =0.024;
input bool        iPrefSettings       =true;
//+----------------------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- Declaration of integer variables for the indicator handles
int SMA_Handle,FsMA_Handle,SlMA_Handle,Env_Handle,OsMA_Handle;
//----
double Percent,DVBuySell,DVStayOut;
uint SMAPeriod,SMA2Bars,EnvelopePeriod,OSMAFast;
uint OSMASlow,OSMASignal,Fast_Period,Slow_Period;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables
   SMAPeriod=iSMAPeriod;
   SMA2Bars=iSMA2Bars;
   Percent=iPercent;
   EnvelopePeriod=iEnvelopePeriod;
   OSMAFast=iOSMAFast;
   OSMASlow=iOSMASlow;
   OSMASignal=iOSMASignal;
   Fast_Period=iFast_Period;
   Slow_Period=iSlow_Period;
   DVBuySell=iDVBuySell;
   DVStayOut=iDVStayOut;

   if(iPrefSettings==true)
     {
      if((Symbol()=="USDJPY") || (Symbol()=="USDJPYm"))
        {
         Percent             =0.0032;
         EnvelopePeriod      =2;
         SMAPeriod           =2;
         SMA2Bars            =18;
         OSMAFast            =5;
         OSMASlow            =22;
         OSMASignal          =2;
         Fast_Period         =25;
         Slow_Period         =15;
         DVBuySell           =0.0029;
         DVStayOut           =0.024;
        }
      if((Symbol()=="EURJPY") || (Symbol()=="EURJPYm"))
        {
         Percent             =0.007;
         EnvelopePeriod      =2;
         SMAPeriod           =4;
         SMA2Bars            =16;
         OSMAFast            =11;
         OSMASlow            =20;
         OSMASignal          =14;
         Fast_Period         =20;
         Slow_Period         =10;
         DVBuySell           =0.0078;
         DVStayOut           =0.026;
        }
      if((Symbol()=="GBPJPY") || (Symbol()=="GBPJPYm"))
        {
         Percent             =0.0072;
         EnvelopePeriod      =2;
         SMAPeriod           =8;
         SMA2Bars            =12;
         OSMAFast            =5;
         OSMASlow            =36;
         OSMASignal          =10;
         Fast_Period         =17;
         Slow_Period         =28;
         DVBuySell           =0.0034;
         DVStayOut           =0.063;
        }
      if((Symbol()=="USDCHF") || (Symbol()=="USDCHFm"))
        {
         Percent             =0.0056;
         EnvelopePeriod      =10;
         SMAPeriod           =5;
         SMA2Bars            =9;
         OSMAFast            =5;
         OSMASlow            =12;
         OSMASignal          =11;
         Fast_Period         =5;
         Slow_Period         =20;
         DVBuySell           =0.00022;
         DVStayOut           =0.0015;
        }
      if((Symbol()=="GBPUSD") || (Symbol()=="GBPUSDm"))
        {
         Percent             =0.0023;
         EnvelopePeriod      =6;
         SMAPeriod           =3;
         SMA2Bars            =14;
         OSMAFast            =23;
         OSMASlow            =17;
         OSMASignal          =15;
         Fast_Period         =25;
         Slow_Period         =37;
         DVBuySell           =0.00042;
         DVStayOut           =0.05;
        }
     }

   uint min_rates_OsMA=uint(MathMax(OSMAFast,OSMASlow)+OSMASignal+2);
   uint min_rates_MA=uint(MathMax(MathMax(SMAPeriod+SMA2Bars,Fast_Period),Slow_Period));
   min_rates_total=int(MathMax(MathMax(EnvelopePeriod+1,min_rates_OsMA),min_rates_MA));

//---- getting handle of the iOsMA indicator
   OsMA_Handle=iOsMA(Symbol(),PERIOD_CURRENT,OSMASlow,OSMAFast,OSMASignal,PRICE_CLOSE);
   if(OsMA_Handle==INVALID_HANDLE)Print(" Failed to get handle of the iOsMA indicator");

//---- getting the iMA indicator handle
   SMA_Handle=iMA(Symbol(),PERIOD_CURRENT,SMAPeriod,0,MODE_SMA,PRICE_MEDIAN);
   if(SMA_Handle==INVALID_HANDLE)Print(" Failed to get handle of the iMA indicator");

//---- getting the iMA indicator handle
   FsMA_Handle=iMA(Symbol(),PERIOD_CURRENT,Fast_Period,0,MODE_SMA,iFast_Price);
   if(FsMA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- getting the iMA indicator handle
   SlMA_Handle=iMA(Symbol(),PERIOD_CURRENT,Slow_Period,0,MODE_SMA,iSlow_Price);
   if(SlMA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- getting the iEnvelopes indicator handle
   Env_Handle=iEnvelopes(Symbol(),PERIOD_CURRENT,EnvelopePeriod,0,MODE_SMA,PRICE_CLOSE,Percent);
   if(Env_Handle==INVALID_HANDLE) Print(" Failed to get handle of iEnvelopes indicator");

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,159);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(SellBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(BuyBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="Phoenix5";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
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
//---- checking for the sufficiency of bars for the calculation
   if(BarsCalculated(Env_Handle)<rates_total
      || BarsCalculated(SMA_Handle)<rates_total
      || BarsCalculated(FsMA_Handle)<rates_total
      || BarsCalculated(SlMA_Handle)<rates_total
      || BarsCalculated(OsMA_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declaration of local variables 
   int limit,bar,to_copy;
   double UpEnv[],DnEnv[],SMA[],FsMA[],SlMA[],OsMA[];
   double Range,AvgRange;

//--- calculations of the necessary amount of data to be copied and
//the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total; // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

   to_copy=limit+1;

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(UpEnv,true);
   ArraySetAsSeries(DnEnv,true);
   ArraySetAsSeries(SMA,true);
   ArraySetAsSeries(FsMA,true);
   ArraySetAsSeries(SlMA,true);
   ArraySetAsSeries(OsMA,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//---- copy newly appeared data into the arrays
   to_copy++;
   if(CopyBuffer(FsMA_Handle,0,0,to_copy,FsMA)<=0) return(RESET);
   if(CopyBuffer(SlMA_Handle,0,0,to_copy,SlMA)<=0) return(RESET);
   if(CopyBuffer(Env_Handle,UPPER_LINE,0,to_copy,UpEnv)<=0) return(RESET);
   if(CopyBuffer(Env_Handle,LOWER_LINE,0,to_copy,DnEnv)<=0) return(RESET);
   to_copy++;
   if(CopyBuffer(OsMA_Handle,0,0,to_copy,OsMA)<=0) return(RESET);
   to_copy=int(limit+1+SMA2Bars);
   if(CopyBuffer(SMA_Handle,0,0,to_copy,SMA)<=0) return(RESET);

   bool BuySignal1,BuySignal2,BuySignal3,SellSignal1,SellSignal2,SellSignal3,BuySignal4,SellSignal4;
   double HighEnvelope1,LowEnvelope1,CloseBar1,OsMABar1,OsMABar2,SMA1,SMA2,diverge;

//---- main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Range=0.0;
      AvgRange=0.0;
      for(int count=bar; count<=bar+9; count++) AvgRange=AvgRange+MathAbs(high[count]-low[count]);
      Range=AvgRange/(10*4);

      BuySignal1=false;
      SellSignal1=false;
      HighEnvelope1=UpEnv[bar+1];
      LowEnvelope1=DnEnv[bar+1];
      CloseBar1=close[bar+1];
      if(CloseBar1>HighEnvelope1) SellSignal1=true;
      if(CloseBar1<LowEnvelope1) BuySignal1=true;

      BuySignal2=false;
      SellSignal2=false;
      SMA1=SMA[bar+1];
      SMA2=SMA[bar+SMA2Bars];
      if(SMA2-SMA1>0) BuySignal2 =true;
      if(SMA2-SMA1<0) SellSignal2=true;

      BuySignal3=false;
      SellSignal3=false;
      OsMABar2=OsMA[bar+2];
      OsMABar1=OsMA[bar+1];
      if(OsMABar2>OsMABar1) SellSignal3=true;
      if(OsMABar2<OsMABar1) BuySignal3=true;

      BuySignal4=false;
      SellSignal4=false;

      diverge=FsMA[bar+1]-SlMA[bar+1];
      if(diverge>=DVBuySell && diverge<=DVStayOut) BuySignal4=true;
      if(diverge<=DVBuySell*(-1) && diverge>=DVStayOut*(-1)) SellSignal4=true;
      
      BuyBuffer[bar]=0;
      SellBuffer[bar]=0;
      if(BuySignal1 && BuySignal2 && BuySignal3 && BuySignal4) BuyBuffer[bar]=low[bar]-Range;
      if(SellSignal1 && SellSignal2 && SellSignal3 && SellSignal4) SellBuffer[bar]=high[bar]+Range;    
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
