//+------------------------------------------------------------------+
//|                                                  ADXCrossing.mq5 |
//|                                           Copyright © 2005, Amir |
//|                                                                  |
//+------------------------------------------------------------------+
//--- copyright
#property copyright "Copyright © 2005, Amir"
//--- a link to the website of the author
#property link      ""
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- two buffers are used for calculating and drawing the indicator
#property indicator_buffers 2
//--- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//| Drawing parameters of the bearish indicator  |
//+----------------------------------------------+
//--- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//--- clrMagenta is used for the color of the bearish indicator line
#property indicator_color1  clrMagenta
//--- indicator 1 line width is equal to 2
#property indicator_width1  2
//--- display of the indicator bullish label
#property indicator_label1  "ADXCrossing Sell"
//+----------------------------------------------+
//| Bullish indicator drawing parameters         |
//+----------------------------------------------+
//--- drawing the indicator 2 as a symbol
#property indicator_type2   DRAW_ARROW
//--- green color is used as the color of the indicator bullish line
#property indicator_color2  clrLime
//--- indicator 2 line width is equal to 2
#property indicator_width2  2
//--- display of the bearish indicator label
#property indicator_label2 "ADXCrossing Buy"
//+----------------------------------------------+
//| declaring constants                          |
//+----------------------------------------------+
#define RESET 0  // A constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint ADXPeriod=50;
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int ATR_Handle,ADX_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialization of global variables 
   int AtrPeriod=14;
   min_rates_total=int(ADXPeriod)+1;
   min_rates_total=int(MathMax(min_rates_total,AtrPeriod));
//--- getting the handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,AtrPeriod);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the ATR indicator");
      return(INIT_FAILED);
     }
//--- getting the handle of the iADX indicator
   ADX_Handle=iADX(NULL,0,ADXPeriod);
   if(ADX_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the iADX indicator");
      return(INIT_FAILED);
     }
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//--- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,108);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellBuffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//--- shifting the starting point of calculation of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,108);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyBuffer,true);
//--- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- data window name and subwindow label 
   string short_name="ADXCrossing";
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
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(ADX_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);
//--- declarations of local variables 
   int to_copy,limit,bar;
   double ATR[],Up[],Dn[];
//--- calculations of the necessary amount of data to be copied and
//--- the limit starting index for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total; // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }
   to_copy=limit+1;
//--- copy newly appeared data in the arrays
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
   to_copy++;
   if(CopyBuffer(ADX_Handle,1,0,to_copy,Up)<=0) return(RESET);
   if(CopyBuffer(ADX_Handle,2,0,to_copy,Dn)<=0) return(RESET);
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(Up,true);
   ArraySetAsSeries(Dn,true);
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
      //---
      if(Up[bar]>Dn[bar] &&  Up[bar+1]<=Dn[bar+1]) BuyBuffer[bar]=low[bar]-ATR[bar]*3/8;
      if(Up[bar]<Dn[bar] &&  Up[bar+1]>=Dn[bar+1]) SellBuffer[bar]=high[bar]+ATR[bar]*3/8;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
