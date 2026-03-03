//+------------------------------------------------------------------+
//|                                                super-signals.mq5 |
//|                Copyright © 2006, Nick Bilak, beluck[AT]gmail.com | 
//|                                        http://www.forex-tsd.com/ | 
//+------------------------------------------------------------------+
#property copyright "CCopyright © 2006, Nick Bilak, beluck[AT]gmail.com"
#property link "http://www.forex-tsd.com/"
#property description "super-signals"
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
//---- DeepPink color is used for the indicator bearish line
#property indicator_color1  clrDeepPink
//---- indicator 1 line width is equal to 4
#property indicator_width1  4
//---- bullish indicator label display
#property indicator_label1  "super-signals Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- DodgerBlue color is used as the color of the bullish line of the indicator
#property indicator_color2  clrDodgerBlue
//---- indicator 2 line width is equal to 4
#property indicator_width2  4
//---- bearish indicator label display
#property indicator_label2 "super-signals Buy"

#define RESET 0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint dist=24;
//+----------------------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total,ATRPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables   
   ATRPeriod=10;
   min_rates_total=int(MathMax(dist+1,ATRPeriod));

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"super-signals Sell");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,108);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(SellBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- Create label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"super-signals Buy");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,108);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(BuyBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="super-signals";
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
   if(rates_total<min_rates_total) return(RESET);

//---- declaration of local variables 
   int limit;

//--- calculations of the necessary amount of data to be copied and
//the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total; // starting index for calculation of all bars
   else limit=int(rates_total-prev_calculated+dist/2); // starting index for calculation of new bars

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);

//---- main loop of the indicator calculation
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      double AvgRange=0.0;
      for(int count=bar; count<=bar+ATRPeriod; count++) AvgRange+=MathAbs(high[count]-low[count]);
      double Range=AvgRange/ATRPeriod;
      Range/=3;

      SellBuffer[bar]=0;
      BuyBuffer[bar]=0;

      uint barX=bar-dist/2;
      int HH=ArrayMaximum(high,barX,dist);
      int LL=ArrayMinimum(low,barX,dist);

      if(bar==HH) SellBuffer[bar]=high[HH]+Range;
      if(bar==LL) BuyBuffer[bar]=low[LL]-Range;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
