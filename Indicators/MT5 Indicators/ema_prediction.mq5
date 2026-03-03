//+------------------------------------------------------------------+
//|                                               EMA_Prediction.mq5 |
//|                                     Copyright © 2008, Codersguru |
//|                                         http://www.forex-tsd.com |
//+------------------------------------------------------------------+
//--- Copyright
#property copyright "Copyright © 2008, Codersguru"
//--- link to the website of the author
#property link      "http://www.forex-tsd.com"
//--- Indicator version number
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//---two buffers are used for calculating and drawing the indicator
#property indicator_buffers 2
//--- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//--- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//--- Magenta is used for the color of the bearish indicator line
#property indicator_color1  clrMagenta
//--- thickness of the indicator line 1 is equal to 4
#property indicator_width1  4
//--- indicator bullish label display
#property indicator_label1  "EMA_Prediction Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//--- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//--- lime color is used as the color of the indicator bullish line
#property indicator_color2  clrLime
//--- thickness of the indicator 2 line is equal to 4
#property indicator_width2  4
//--- bearish indicator label display
#property indicator_label2 "EMA_Prediction Buy"
//+----------------------------------------------+
//| declaring constants                          |
//+----------------------------------------------+
#define RESET  0 // the constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint               FastMAPeriod=1;
input  ENUM_MA_METHOD    FastMAType=MODE_EMA;
input ENUM_APPLIED_PRICE FastMAPrice=PRICE_CLOSE;
input uint               SlowMAPeriod=2;
input  ENUM_MA_METHOD    SlowMAType=MODE_EMA;
input ENUM_APPLIED_PRICE SlowMAPrice=PRICE_CLOSE;
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//--- declaration of the integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for indicators handles
int ATR_Handle,FsMA_Handle,SlMA_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialization of global variables
   int ATR_Period=12;
   min_rates_total=int(MathMax(MathMax(FastMAPeriod,SlowMAPeriod),ATR_Period))+1;
//--- getting the handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the iATR indicator handle!");
      return(INIT_FAILED);
     }
//--- getting the handle of the Fast iMA indicator
   FsMA_Handle=iMA(NULL,0,FastMAPeriod,0,FastMAType,FastMAPrice);
   if(FsMA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the Fast iMA indicator");
      return(INIT_FAILED);
     }
//--- getting the handle of the Slow iMA indicator
   SlMA_Handle=iMA(NULL,0,SlowMAPeriod,0,SlowMAType,SlowMAPrice);
   if(SlMA_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the Slow iMA indicator");
      return(INIT_FAILED);
     }
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//--- Shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"EMA_Prediction Sell");
//--- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,234);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellBuffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//--- shifting the starting point of calculation of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- create a label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"EMA_Prediction Buy");
//--- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,233);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyBuffer,true);
//--- setting the indicator display accuracy format
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- name for the data window and the label for sub-windows
   string short_name="EMA_Prediction";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- initialization end
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
//--- checking the number of bars to be enough for the calculation
   if(BarsCalculated(FsMA_Handle)<rates_total
      || BarsCalculated(SlMA_Handle)<rates_total
      || BarsCalculated(ATR_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);
//--- declaration of local variables 
   int to_copy,limit,bar;
   double ATR[],FsMA[],SlMA[];
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }
   to_copy=limit+1;
//--- copy newly appeared data into the arrays
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
   to_copy++;
   if(CopyBuffer(FsMA_Handle,0,0,to_copy,FsMA)<=0) return(RESET);
   if(CopyBuffer(SlMA_Handle,0,0,to_copy,SlMA)<=0) return(RESET);
//--- indexing elements in arrays as in timeseries
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(FsMA,true);
   ArraySetAsSeries(SlMA,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
//--- the main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
      //---
      if(FsMA[bar+1]<SlMA[bar+1] && FsMA[bar]>SlMA[bar] && open[bar]<close[bar]) BuyBuffer[bar]=low[bar]-ATR[bar]*3/8;
      if(FsMA[bar+1]>SlMA[bar+1] && FsMA[bar]<SlMA[bar] && open[bar]>close[bar]) SellBuffer[bar]=high[bar]+ATR[bar]*3/8;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
