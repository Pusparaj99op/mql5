//+------------------------------------------------------------------+
//|                                         EMA-Crossover_Signal.mq5 |
//|         Copyright © 2005, Jason Robinson (jnrtrading)            |
//|                   http://www.jnrtading.co.uk                     |
//+------------------------------------------------------------------+
/*
  +------------------------------------------------------------------+
  | Allows you to enter two ema periods and it will then show you at |
  | Which point they crossed over. It is more usful on the shorter   |
  | periods that get obscured by the bars / candlesticks and when    |
  | the zoom level is out. Also allows you then to remove the emas   |
  | from the chart. (emas are initially set at 5 and 6)              |
  +------------------------------------------------------------------+
*/
#property copyright "Copyright © 2005, Jason Robinson (jnrtrading)"
#property link "http://www.jnrtading.co.uk"
#property description "EMA-Crossover_Signal"
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
//---- pink color is used as the color of the bearish indicator
#property indicator_color1  clrMagenta
//---- indicator 1 width is equal to 1
#property indicator_width1  1
//---- bullish indicator label display
#property indicator_label1  "EMA-Crossover_Signal Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- blue color is used as the color of the bullish indicator
#property indicator_color2  clrBlue
//---- indicator 2 width is equal to 1
#property indicator_width2  1
//---- bearish indicator label display
#property indicator_label2 "EMA-Crossover_Signal Buy"

//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET  0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint FasterMA=5;
input uint SlowerMA=6;
input  ENUM_MA_METHOD   MAType=MODE_LWMA;
input ENUM_APPLIED_PRICE   MAPrice=PRICE_CLOSE;
//+----------------------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- Declaration for the indicator handles
int FsMA_Handle,SlMA_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables   
   min_rates_total=int(MathMax(FasterMA,SlowerMA)+3);

//---- getting the iMA indicator handle
   FsMA_Handle=iMA(NULL,0,FasterMA,0,MAType,MAPrice);
   if(FsMA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- getting the iMA indicator handle
   SlMA_Handle=iMA(NULL,0,SlowerMA,0,MAType,MAPrice);
   if(SlMA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,119);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(SellBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,119);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(BuyBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="EMA-Crossover_Signal";
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
   if(BarsCalculated(FsMA_Handle)<rates_total
      || BarsCalculated(SlMA_Handle)<rates_total
      || rates_total<min_rates_total)return(RESET);

//---- declaration of local variables 
   int to_copy,limit,bar;
   double AvgRange,Range,FsMA[],SlMA[];

//--- calculations of the necessary amount of data to be copied and
//the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(FsMA,true);
   ArraySetAsSeries(SlMA,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

   to_copy=limit+3;

//---- copy newly appeared data into the arrays
   if(CopyBuffer(FsMA_Handle,0,0,to_copy,FsMA)<=0) return(RESET);
   if(CopyBuffer(SlMA_Handle,0,0,to_copy,SlMA)<=0) return(RESET);

//---- main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      AvgRange=0.0;
      for(int count=bar+9; count>=bar; count--) AvgRange+=MathAbs(high[count]-low[count]);
      Range=AvgRange/10;
      //----
      SellBuffer[bar]=0.0;
      BuyBuffer[bar]=0.0;
      //----
      if(FsMA[bar+1]>SlMA[bar+1] && FsMA[bar+2]<SlMA[bar+2] && FsMA[bar]>SlMA[bar]) BuyBuffer[bar]=low[bar]-Range*0.5;
      else if(FsMA[bar+1]<SlMA[bar+1] && FsMA[bar+2]>SlMA[bar+2] && FsMA[bar]<SlMA[bar]) SellBuffer[bar]=high[bar]+Range*0.5;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
