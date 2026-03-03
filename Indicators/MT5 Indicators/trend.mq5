//+------------------------------------------------------------------+
//|                                                        Trend.mq5 |
//|                                        Copyright © 2008, Ramdass | 
//|                                                                  | 
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2008, Ramdass"
//---- link to the website of the author
#property link ""
//---- indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//---- two buffers are used for the indicator calculation and drawing
#property indicator_buffers 2
//---- one plot is used
#property indicator_plots   1
//+-----------------------------------+ 
//|  Declaration of constants         |
//+-----------------------------------+ 
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//|  Filling drawing parameters       |
//+-----------------------------------+
//---- drawing indicator as a filling between two lines
#property indicator_type1   DRAW_FILLING
//---- green and magenta colors are used as the indicator filling colors
#property indicator_color1  Lime, Magenta
//---- displaying the indicator label
#property indicator_label1 "Trend"

//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum MODE
  {
   MODE_MAIN=0, //main line
   MODE_HIGH,   //high line
   MODE_LOW     //low line
  };
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input MODE                Bands_Mode=MODE_MAIN;    // BB line for the calculation 
input int                 bands_period=20;         // BB averaging period
input double              bands_deviation=2.0;     // BB deviation
input ENUM_APPLIED_PRICE  bands_price=PRICE_CLOSE; // BB price
input int                 power_period=13;         // period of averaging

//+----------------------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double BullsBuffer[];
double BearsBuffer[];
//---- Declaration of integer variables of data starting point
int min_rates_total;
//---- Declaration of integer variables for the indicator handles
int Bands_Handle,Bulls_Handle,Bears_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=MathMax(bands_period,power_period);

//---- getting the Bands indicator handle
   Bands_Handle=iBands(NULL,0,bands_period,0,bands_deviation,bands_price);
   if(Bands_Handle==INVALID_HANDLE) Print(" Failed to get handle of Bands indicator");

//---- getting the BullsPower indicator handle
   Bulls_Handle=iBullsPower(NULL,0,power_period);
   if(Bulls_Handle==INVALID_HANDLE) Print(" Failed to get handle of the BullsPower indicator");

//---- getting the BearsPower indicator handle
   Bears_Handle=iBearsPower(NULL,0,power_period);
   if(Bears_Handle==INVALID_HANDLE) Print(" Failed to get handle of the BearsPower indicator");

//---- transformation of the dynamic array BullsBuffer into an indicator buffer
   SetIndexBuffer(0,BullsBuffer,INDICATOR_DATA);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(BullsBuffer,true);

//---- transformation of the BearsBuffer dynamic array into an indicator buffer
   SetIndexBuffer(1,BearsBuffer,INDICATOR_DATA);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(BearsBuffer,true);

//---- shifting the starting point for drawing indicator 1 by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//---- initializations of variable for indicator short name
   string shortname="Trend";
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const int begin,          // number of beginning of reliable counting of bars
                const double &price[]     // price array for calculation of the indicator
                )
  {
//---- checking the number of bars to be enough for calculation
   if(BarsCalculated(Bands_Handle)<rates_total
      || BarsCalculated(Bulls_Handle)<rates_total
      || BarsCalculated(Bears_Handle)<rates_total
      || rates_total<min_rates_total+begin)
      return(RESET);

//---- declaration of local variables 
   int to_copy,limit,bar;
   double Bands[],Bulls[],Bears[];

//---- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-1-min_rates_total-begin; // starting index for the calculation of all bars
      //---- shifting the starting point for drawing indicator 1 by min_rates_total
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total+begin);
     }
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars
//----   
   to_copy=limit+1;
//---- copy newly appeared data into the arrays
   if(CopyBuffer(Bands_Handle,Bands_Mode,0,to_copy,Bands)<=0) return(RESET);
   if(CopyBuffer(Bulls_Handle,Bands_Mode,0,to_copy,Bulls)<=0) return(RESET);
   if(CopyBuffer(Bears_Handle,Bands_Mode,0,to_copy,Bears)<=0) return(RESET);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(Bands,true);
   ArraySetAsSeries(Bulls,true);
   ArraySetAsSeries(Bears,true);
   ArraySetAsSeries(price,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      BullsBuffer[bar]=price[bar]-Bands[bar];
      BearsBuffer[bar]=-(Bears[bar]+Bulls[bar]);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
