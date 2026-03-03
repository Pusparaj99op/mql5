//+------------------------------------------------------------------+
//|                                     Dynamic_trend_cleaned_up.mq5 |
//|                                 Copyright © 2004, OfficeFX Group |
//|                                           http:// officefx.nm.ru |
//+------------------------------------------------------------------+
//--- copyright
#property copyright "Copyright © 2004, OfficeFX Group"
//--- link to the website of the author
#property link      "http:// officefx.nm.ru"
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- three buffers are used for calculation of drawing of the indicator
#property indicator_buffers 3
//--- three plots are used
#property indicator_plots   3
//+-----------------------------------------------+
//| Line indicator drawing parameters             |
//+-----------------------------------------------+
//--- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//--- gold color is used as the color of the indicator line
#property indicator_color1 clrGold
//--- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- indicator line width is 1
#property indicator_width1  1
//--- displaying the indicator label
#property indicator_label1  "DynamicLine"
//+----------------------------------------------+
//| Parameters of drawing the bearish indicator  |
//+----------------------------------------------+
//--- drawing the indicator 2 as a symbol
#property indicator_type2   DRAW_ARROW
//--- pink is used for the color of the bearish indicator line
#property indicator_color2  clrMagenta
//--- indicator 2 line width is equal to 4
#property indicator_width2  4
//--- display of the indicator bullish label
#property indicator_label2  "Sell"
//+----------------------------------------------+
//| Bullish indicator drawing parameters         |
//+----------------------------------------------+
//--- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_ARROW
//--- green color is used as the color of the indicator bullish line
#property indicator_color3  clrLime
//--- indicator 3 line width is equal to 4
#property indicator_width3  4
//--- display of the bearish indicator label
#property indicator_label3 "Buy"
//+----------------------------------------------+
//| declaring constants                          |
//+----------------------------------------------+
#define RESET  0 // a constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint Percent=150;     // Percent dynamic channel
input uint MaxPeriod=50;    // Maximal period for calculate trend 
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double IndBuffer[];
double SellBuffer[];
double BuyBuffer[];
//---
double dPercent;
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int ATR_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialization of global variables
   int ATR_Period=15;
   min_rates_total=int(MaxPeriod)+5;
   min_rates_total=MathMax(ATR_Period,min_rates_total);  
   dPercent=Percent*_Point;
//--- Getting the handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the ATR indicator");
      return(INIT_FAILED);
     }
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,SellBuffer,INDICATOR_DATA);
//--- shifting the starting point of calculation of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//--- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,234);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellBuffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(2,BuyBuffer,INDICATOR_DATA);
//--- shifting the start of drawing of the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
//--- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,233);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyBuffer,true);
//--- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- name for the data window and the label for sub-windows 
   string short_name="Dynamic_trend_cleaned_upg";
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
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//--- declarations of local variables 
   int to_copy,limit,bar,bar2,bar3;
   double HH,LL,ATR[];
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(ATR,true);
//--- calculations of the necessary amount of data to be copied and
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total; // starting index for calculation of all bars
      IndBuffer[limit+1]=close[limit+1];
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }    
   to_copy=limit+1;
//--- copy newly appeared data in the arrays
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);   
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      HH=close[ArrayMaximum(close,bar+1,MaxPeriod)];
      LL=close[ArrayMinimum(close,bar+1,MaxPeriod)];
      //---
      if (close[bar]<IndBuffer[bar+1]) IndBuffer[bar]=HH-dPercent;
      else IndBuffer[bar]=LL+dPercent;
      //---
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
      //---
      bar2=bar+2;
      bar3=bar+3;
      if (close[bar2]>IndBuffer[bar2] && close[bar2]<IndBuffer[bar3]) BuyBuffer[bar]=low[bar]-ATR[bar]*3/8;
      if (close[bar2]<IndBuffer[bar2] && close[bar2]>IndBuffer[bar3]) SellBuffer[bar]=high[bar]+ATR[bar]*3/8;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
