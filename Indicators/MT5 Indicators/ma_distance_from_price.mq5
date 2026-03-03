//+------------------------------------------------------------------+
//|                                       Ma_Distance_From_Price.mq5 |
//|                              Copyright © 2013, David W Honeywell | 
//|                                        transport.david@gmail.com | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013, David W Honeywell"
#property link "farria@mail.redcom.ru"
#property description "Ma_Distance_From_Price"
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
//---- orange color is used for the indicator bearish line
#property indicator_color1  clrOrange
//---- thickness of line of the indicator 1 is equal to 1
#property indicator_width1  1
//---- bullish indicator label display
#property indicator_label1  "Ma_Distance_From_Price Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- blue color is used for the indicator bullish line
#property indicator_color2  clrBlue
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- bearish indicator label display
#property indicator_label2 "Ma_Distance_From_Price Buy"

#define RESET 0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint                 MAPeriod=13;
input  ENUM_MA_METHOD      MAType=MODE_EMA;
input ENUM_APPLIED_PRICE   MAPrice=PRICE_CLOSE;
input int                  PipLevel=15; //trigger level from moving in points
//+----------------------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double SellBuffer[];
double BuyBuffer[];

double dPipLevel;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total,ATRPeriod;
//---- Declaration of integer variables for the indicator handles
int MA_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables   
   ATRPeriod=10;
   min_rates_total=int(MathMax(ATRPeriod,MAPeriod+1));
   dPipLevel=PipLevel*_Point;

//---- getting the iMA indicator handle
   MA_Handle=iMA(NULL,0,MAPeriod,0,MAType,MAPrice);
   if(MA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(SellBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(BuyBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="Ma_Distance_From_Price";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
  }
//+------------------------------------------------------------------+
//|  Get the offset width of extremum                                |
//+------------------------------------------------------------------+
double CountRange(const double &High[],const double &Low[],int period,int index)
  {
//----
   double AvgRange=0.0;
   for(int count=index+period-1; count>=index; count--) AvgRange+=MathAbs(High[count]-Low[count]);
   double Range=AvgRange/period;
   Range*=0.5;
//----
   return(Range);
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
   if(BarsCalculated(MA_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

//---- declaration of local variables 
   int to_copy,limit,bar;
   double Range,MA[];

//--- calculations of the necessary amount of data to be copied and
//the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total; // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(MA,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   
   to_copy=limit+1;
//---- copy newly appeared data into the arrays
   if(CopyBuffer(MA_Handle,0,0,to_copy,MA)<=0) return(RESET);

//---- main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      SellBuffer[bar]=0;
      BuyBuffer[bar]=0;

      if(MA[bar]>high[bar]+dPipLevel)
        {
         Range=CountRange(high,low,ATRPeriod,bar);
         SellBuffer[bar]=high[bar]+Range;
        }

      if(MA[bar]<low[bar]-dPipLevel)
        {
         Range=CountRange(high,low,ATRPeriod,bar);
         BuyBuffer[bar]=low[bar]-Range;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
