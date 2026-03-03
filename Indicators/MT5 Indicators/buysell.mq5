//+------------------------------------------------------------------+
//|                                                      BuySell.mq5 |
//|                                          Copyright © 2008, bobik | 
//|                                             bobik@trah.guchka.eu | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, bobik"
#property link "bobik@trah.guchka.eu"
#property description "BuySell "
//---- indicator version
#property version   "1.00"
//---- plot in a separate window
#property indicator_chart_window 
//---- indicator buffers
#property indicator_buffers 4
//---- indicator plots
#property indicator_plots   4
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing type
#property indicator_type1   DRAW_ARROW
//---- color - Red
#property indicator_color1  Red
//---- width
#property indicator_width1  1
//---- label
#property indicator_label1  "Lower BuySell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing type
#property indicator_type2   DRAW_ARROW
//---- color - LightSeaGreen
#property indicator_color2  LightSeaGreen
//---- width
#property indicator_width2  1
//---- label
#property indicator_label2 "Upper BuySell"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing type
#property indicator_type3   DRAW_ARROW
//---- color - DeepPink
#property indicator_color3  DeepPink
//---- width 
#property indicator_width3  4
//---- label
#property indicator_label3  "BuySell Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing type
#property indicator_type4   DRAW_ARROW
//---- color - LightSeaGreen
#property indicator_color4  LightSeaGreen
//---- width
#property indicator_width4  4
//---- label
#property indicator_label4 "BuySell Buy"
//+-----------------------------------+
//|  constants                        |
//+-----------------------------------+
#define RESET 0 // constants

//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint MA_Period=14;
input ENUM_MA_METHOD MA_Method=MODE_SMA;        // Smoothing method
input ENUM_APPLIED_PRICE MA_Price=PRICE_CLOSE;  // Price
input uint ATR_Period=60;
//+----------------------------------------------+
//---- declaration of dynamic arrays, used as indicator buffers
double BuyBuffer[],SellBuffer[];
double UpBuffer[],DnBuffer[];
//---- declaration of integer variables, used for handles
int MA_Handle,ATR_Handle;
//---- 
int  min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- initialization of variables
   min_rates_total=int(MA_Period+ATR_Period);

//---- get handle of iMA indicator
   MA_Handle=iMA(NULL,0,MA_Period,0,MA_Method,MA_Price);
   if(MA_Handle==INVALID_HANDLE) {Print(" Error in creation of iMA indicator"); return(1);}

//---- get handle of iATR indicator
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE) {Print(" Error in creation of iATR indicator"); return(1);}

//---- set UpBuffer[] dynamic array as indicator buffer
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//---- set plot draw begin
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- define char code, used for drawing
   PlotIndexSetInteger(0,PLOT_ARROW,158);
//---- set indexing as time series
   ArraySetAsSeries(UpBuffer,true);
//---- define empty value (not shown at chart)
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- set DnBuffer[] dynamic array as indicator buffer
   SetIndexBuffer(1,DnBuffer,INDICATOR_DATA);
//---- set plot draw begin
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- define char code, used for drawing
   PlotIndexSetInteger(1,PLOT_ARROW,158);
//---- set indexing as time series
   ArraySetAsSeries(DnBuffer,true);
//---- define empty value (not shown at chart)
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- set SellBuffer[] dynamic array as indicator buffer
   SetIndexBuffer(2,SellBuffer,INDICATOR_DATA);
//---- set plot draw begin
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- define char code, used for drawing
   PlotIndexSetInteger(2,PLOT_ARROW,167);
//---- set indexing as time series
   ArraySetAsSeries(SellBuffer,true);
//---- define empty value (not shown at chart)
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

//---- set BuyBuffer[] dynamic array as indicator buffer
   SetIndexBuffer(3,BuyBuffer,INDICATOR_DATA);
//---- set plot draw begin
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- define char code, used for drawing
   PlotIndexSetInteger(3,PLOT_ARROW,167);
//---- set indexing as time series
   ArraySetAsSeries(BuyBuffer,true);
//---- define empty value (not shown at chart)
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);

//---- set precision
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- set indicator short name
   string short_name="BuySell";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----
   return(0);
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
//---- checking of bars, needed for calculation
   if(BarsCalculated(MA_Handle)<rates_total
      || BarsCalculated(ATR_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);

//---- declaration of local variables
   int limit,to_copy,bar;
   double MA[],ATR[];

//---- set starting bar index limit
   if(prev_calculated>rates_total || prev_calculated<=0)// checking of first call
      limit=rates_total-min_rates_total-2; // starting bar index for all bars
   else limit=rates_total-prev_calculated; // starting bar index for new bars
   to_copy=limit+2;

//---- copy new data to arrays
   if(CopyBuffer(MA_Handle,0,0,to_copy,MA)<=0) return(RESET);
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);

//---- set indexing as time series
   ArraySetAsSeries(MA,true);
   ArraySetAsSeries(ATR,true);

//---- first calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- set buffers to zero
      DnBuffer[bar]=0.0;
      UpBuffer[bar]=0.0;

      if(MA[bar]>MA[bar+1]) DnBuffer[bar]=MA[bar]-ATR[bar];
      if(MA[bar]<MA[bar+1]) UpBuffer[bar]=MA[bar]+ATR[bar];
     }

//---- recalculation of starting bar index for new bars
   if(prev_calculated>rates_total || prev_calculated<=0)// checking of first call
      limit--;

//---- second calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- set buffers to zero
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;

      if(UpBuffer[bar+1]&&DnBuffer[bar]) BuyBuffer [bar]=DnBuffer[bar];
      if(DnBuffer[bar+1]&&UpBuffer[bar]) SellBuffer[bar]=UpBuffer[bar];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
