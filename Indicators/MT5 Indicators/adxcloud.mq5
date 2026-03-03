//+------------------------------------------------------------------+
//|                                                     ADXCloud.mq5 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
//--- copyright
#property copyright "Copyright © 2007, MetaQuotes Software Corp."
//--- a link to the website of the author
#property link      "http://www.metaquotes.net"
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- two buffers are used for calculating and drawing the indicator
#property indicator_buffers 2
//--- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_FILLING
//--- the following colors are used for the indicator cloud
#property indicator_color1  clrLime,clrRed
//--- display of the indicator bullish label
#property indicator_label1  "Di Plus;Di Minus"
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET  0 // a constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input int    period = 5;
input double alpha1 = 0.25;
input double alpha2 = 0.33;
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double DiPlusBuffer[];
double DiMinusBuffer[];
//--- declaration of integer variables for the indicators handles
int ADX_Handle;
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- getting handle of the ADX indicator
   ADX_Handle=iADX(NULL,0,period);
   if(ADX_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the ADX indicator!");
      return(INIT_FAILED);
     }
//--- initialization of variables of data calculation start
   min_rates_total=period+1;
//--- set the DiPlusBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,DiPlusBuffer,INDICATOR_DATA);
//---- Indexing buffer elements as timeseries   
   ArraySetAsSeries(DiPlusBuffer,true);
//--- set DiMinusBuffer dynamic array as an indicator buffer
   SetIndexBuffer(1,DiMinusBuffer,INDICATOR_DATA);
//---- Indexing buffer elements as timeseries   
   ArraySetAsSeries(DiMinusBuffer,true);
//---- shifting the starting point of the indicator 1 drawing by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"ADXCloud(",period,")smothed");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---
   return(INIT_SUCCEEDED);
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
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(ADX_Handle)<rates_total || rates_total<min_rates_total) return(0);
//--- declarations of local variables 
   int limit,to_copy,bar;
   double DIP[],DIM[],DiPlus,DiMinus,DDiPlus,DDiMinus;
   static double DiPlus_,DiMinus_,DDiPlus_,DDiMinus_;
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(DIP,true);
   ArraySetAsSeries(DIM,true);
//--- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      limit=rates_total-2; // starting index for calculation of all bars
      DiPlus_=0.0;
      DiMinus_=0.0;
      DDiPlus_=0.0;
      DDiMinus_=0.0;
      DiPlusBuffer[rates_total-1]=0.0;
      DiMinusBuffer[rates_total-1]=0.0;
     }
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars
   to_copy=limit+2;
//--- copy newly appeared data in the arrays
   if(CopyBuffer(ADX_Handle,1,0,to_copy,DIP)<=0) return(RESET);
   if(CopyBuffer(ADX_Handle,2,0,to_copy,DIM)<=0) return(RESET);
//--- Restore values of the variables
   DiPlus=DiPlus_;
   DiMinus=DiMinus_;
   DDiPlus=DDiPlus_;
   DDiMinus=DDiMinus_;
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      DiPlus=2*DIP[bar]+(alpha1-2)*DIP[bar+1]+(1-alpha1)*DiPlus;
      DiMinus=2*DIM[bar]+(alpha1-2)*DIM[bar+1]+(1-alpha1)*DiMinus;

      DDiPlus=alpha2*DiPlus+(1-alpha2)*DDiPlus_;
      DDiMinus=alpha2*DiMinus+(1-alpha2)*DDiMinus_;

      DiPlusBuffer[bar]=DDiPlus-DDiMinus;
      DiMinusBuffer[bar]=0.0;
      //--- save values of the variables before running at the current bar
      if(bar)
        {
         DiPlus_=DiPlus;
         DiMinus_=DiMinus;
         DDiPlus_=DDiPlus;
         DDiMinus_=DDiMinus;
        }
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
