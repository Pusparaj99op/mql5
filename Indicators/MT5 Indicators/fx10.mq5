//+------------------------------------------------------------------+
//|                                                         Fx10.mq5 |
//|                                   Copyright © 2000-2007, palanka |
//|                                         http://www.metaquotes.ru |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2000-2007, palanka"
//---- link to the website of the author
#property link      ""
//---- indicator version
#property version   "1.01"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- two buffers are used for calculation and drawing the indicator
#property indicator_buffers 2
//---- only two plots are used
#property indicator_plots   2
//+----------------------------------------------+ 
//|  Declaration of constants                    |
//+----------------------------------------------+ 
#define RESET  0 // the constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- Magenta color is used for the indicator
#property indicator_color1  Magenta
//---- indicator 1 line width is equal to 4
#property indicator_width1  4
//---- displaying the indicator label
#property indicator_label1  "Fx10 Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- Lime color is used for the indicator
#property indicator_color2  Lime
//---- indicator 2 line width is equal to 4
#property indicator_width2  4
//---- displaying the indicator label
#property indicator_label2 "Fx10 Buy"
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input double ParmMult=2.0; // multiply the standard parameters by this scale factor
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of integer variables for the indicators handles
int MA5_Handle,MA10_Handle,RSI_Handle,STO_Handle,MACD_Handle,ATR_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables 
   min_rates_total=int(ParmMult*26+1);

//---- getting handle of the MA5 indicator
   MA5_Handle=iMA(NULL,0,int(ParmMult*5),0,MODE_LWMA,PRICE_CLOSE);
   if(MA5_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA5 indicator");

//---- getting handle of the MA10 indicator
   MA10_Handle=iMA(NULL,0,int(ParmMult*10),0,MODE_SMA,PRICE_CLOSE);
   if(MA10_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA10 indicator");

//---- getting handle of the RSI indicator
   RSI_Handle=iRSI(NULL,0,int(ParmMult*14),PRICE_CLOSE);
   if(RSI_Handle==INVALID_HANDLE)Print(" Failed to get handle of the iRSI indicator");

//---- getting handle of the Stochastic indicator
   STO_Handle=iStochastic(NULL,0,int(5*ParmMult),int(3*ParmMult),int(3*ParmMult),MODE_SMA,STO_LOWHIGH);
   if(STO_Handle==INVALID_HANDLE)Print(" Failed to get handle of the iStochastic indicator");

//---- getting handle of the MACD indicator
   MACD_Handle=iMACD(NULL,0,int(12*ParmMult),int(26*ParmMult),int(9*ParmMult),PRICE_CLOSE);
   if(MACD_Handle==INVALID_HANDLE)Print(" Failed to get handle of the iMACD indicator");

//---- getting handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,15);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");

//---- set SellBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,119);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(SellBuffer,true);

//---- set BuyBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,119);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(BuyBuffer,true);

//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for tooltips 
   string short_name="Fx10";
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
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(MA5_Handle)<rates_total
      || BarsCalculated(MA10_Handle)<rates_total
      || BarsCalculated(RSI_Handle)<rates_total
      || BarsCalculated(STO_Handle)<rates_total
      || BarsCalculated(MACD_Handle)<rates_total
      || BarsCalculated(ATR_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declarations of local variables 
   int to_copy,limit,bar;
   double MA5[],MA10[],RSI[],STO[],MACD[],STOS[],MACDS[],ATR[];
   bool RsiUp,RsiDn,StochUp,StochDn,MacdUp,MacdDn;

//---- calculations of the necessary amount of data to be copied and
//---- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total;   // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars    
   to_copy=limit+1;

//---- copy newly appeared data in the arrays
   if(CopyBuffer(MA5_Handle,0,0,to_copy,MA5)<=0) return(RESET);
   if(CopyBuffer(MA10_Handle,0,0,to_copy,MA10)<=0) return(RESET);
   if(CopyBuffer(RSI_Handle,0,0,to_copy,RSI)<=0) return(RESET);
   if(CopyBuffer(STO_Handle,0,0,to_copy,STO)<=0) return(RESET);
   if(CopyBuffer(STO_Handle,1,0,to_copy,STOS)<=0) return(RESET);
   if(CopyBuffer(MACD_Handle,0,0,to_copy,MACD)<=0) return(RESET);
   if(CopyBuffer(MACD_Handle,1,0,to_copy,MACDS)<=0) return(RESET);
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(MA5,true);
   ArraySetAsSeries(MA10,true);
   ArraySetAsSeries(RSI,true);
   ArraySetAsSeries(STO,true);
   ArraySetAsSeries(STOS,true);
   ArraySetAsSeries(MACD,true);
   ArraySetAsSeries(MACDS,true);
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;

      if(MA5[bar]>MA10[bar])
        {
         RsiUp=RSI[bar]>=55.0;
         StochUp=STO[bar]>STOS[bar];
         MacdUp=MACD[bar]>MACDS[bar];
         if(StochUp && RsiUp && MacdUp) BuyBuffer[bar]=low[bar]-ATR[bar]*3/8;
        }

      if(MA5[bar]<MA10[bar])
        {
         RsiDn=RSI[bar]<=45.0;
         StochDn=STO[bar]<STOS[bar];
         MacdDn=MACD[bar]<MACDS[bar];
         if(StochDn && RsiDn && MacdDn) SellBuffer[bar]=high[bar]+ATR[bar]*3/8;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
