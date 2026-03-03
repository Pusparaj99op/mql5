//+------------------------------------------------------------------+
//|                                                        NDuet.mq5 |
//|                                         Copyright © 2006, Tartan | 
//|                                                                  | 
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2006, Tartan"
//---- author of the indicator
#property link      ""
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- four buffers are used for calculation and drawing the indicator
#property indicator_buffers 4
//---- four plots are used
#property indicator_plots   4
//+----------------------------------------------+
//| Fast Line indicator drawing parameters       |
//+----------------------------------------------+
//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- red color is used as the color of the indicator basic line
#property indicator_color1  clrRed
//---- line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- thickness of line of the indicator 1 is equal to 1
#property indicator_width1  1
//---- displaying the indicator line label
#property indicator_label1  "NDuet Fast Line"
//+----------------------------------------------+
//| Slow Line indicator drawing parameters       |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used for the indicator signal line
#property indicator_color2  clrBlue
//---- the indicator 2 line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator line label
#property indicator_label2  "NDuet Slow Line"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_ARROW
//---- Lime color is used for the indicator
#property indicator_color3  clrLime
//---- the indicator 3 line width is equal to 4
#property indicator_width3  4
//---- indicator bullish label display
#property indicator_label3 "NDuet Buy"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4   DRAW_ARROW
//---- red color is used for the indicator
#property indicator_color4  clrRed
//---- thickness of the indicator 4 line is equal to 4
#property indicator_width4  4
//---- bearish indicator label display
#property indicator_label4  "NDuet Sell"

//+----------------------------------------------+
//|  Declaration of constants                    |
//+----------------------------------------------+
#define RESET 0  // the constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint FastPeriod=21;  //fast moving average period 
input uint SlowPeriod=55;  //slow moving average period
input uint CCIPeriod=14;   //CCI period
input int Shift=0;         //horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double FastBuffer[];
double SlowBuffer[];
double BuyBuffer[];
double SellBuffer[];
//---- declaration of integer variables for the indicators handles
int FsMA_Handle,SlMA_Handle,CCI_Handle;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total,ATRPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   ATRPeriod=10;
   min_rates_total=int(MathMax(MathMax(MathMax(FastPeriod+2,SlowPeriod+2),CCIPeriod),ATRPeriod));

//---- getting fast iMA indicator handle
   FsMA_Handle=iMA(NULL,0,FastPeriod,0,MODE_SMA,PRICE_CLOSE);
   if(FsMA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the fast iMA indicator");

//---- getting slow iMA indicator handle
   SlMA_Handle=iMA(NULL,0,SlowPeriod,0,MODE_SMA,PRICE_CLOSE);
   if(SlMA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- getting handle of the iCCI indicator
   CCI_Handle=iCCI(NULL,0,CCIPeriod,PRICE_CLOSE);
   if(CCI_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iCCI indicator");

//---- set FastBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,FastBuffer,INDICATOR_DATA);
//---- shifting indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- shifting the starting point of the indicator 1 drawing by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(FastBuffer,true);

//---- set SlowBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,SlowBuffer,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- shifting the starting point of the indicator 2 drawing by min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total+1);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(SlowBuffer,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(2,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,108);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(BuyBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(3,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,108);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(SellBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);

//---- initializations of variable for indicator short name
   string shortname="NDuet";
//---- creating name for displaying if separate sub-window and in tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determine the accuracy of displaying indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
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
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for calculation
   if(BarsCalculated(FsMA_Handle)<rates_total
      || BarsCalculated(SlMA_Handle)<rates_total
      || BarsCalculated(CCI_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);

//---- declaration of local variables 
   int limit,bar,trend,to_copy;
   double mas,maf,mstwo,mftwo,CCI[],Range,res;
   static int prev_trend;

//--- calculations of the necessary amount of data to be copied and
//the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total; // starting index for calculation of all bars
      to_copy=rates_total;
      prev_trend=0;
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
      to_copy=limit+1;
     }

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(CCI,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//--- copy newly appeared data in the array
   if(CopyBuffer(FsMA_Handle,0,0,to_copy,FastBuffer)<=0) return(RESET);
   if(CopyBuffer(SlMA_Handle,0,0,to_copy,SlowBuffer)<=0) return(RESET);
   if(CopyBuffer(CCI_Handle,0,0,to_copy,CCI)<=0) return(RESET);

//---- restoring the values of the variables   
   trend=prev_trend;

//---- main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
      mas=SlowBuffer[bar];
      mstwo=SlowBuffer[bar+2];
      maf=FastBuffer[bar];
      mftwo=FastBuffer[bar+2];

      res=(mas-maf)/_Point;

      if(trend!=-1 && mas>maf && +res<10 && mstwo<mftwo && CCI[bar]<0)
        {
         trend=-1;
         Range=CountRange(high,low,ATRPeriod,bar);
         SellBuffer[bar]=high[bar]+Range;
        }

      if(trend!=+1 && mas<maf && -res<10 && mstwo>mftwo && CCI[bar]>0)
        {
         trend=+1;
         Range=CountRange(high,low,ATRPeriod,bar);
         BuyBuffer[bar]=low[bar]-Range;
        }

      //---- saving values of variables 
      if(bar) prev_trend=trend;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
