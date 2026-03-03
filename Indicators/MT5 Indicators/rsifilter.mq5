//+------------------------------------------------------------------+ 
//|                                                    RSIFilter.mq5 | 
//|                                  Copyright © 2006, Forex-TSD.com |
//|                         Written by IgorAD,igorad2003@yahoo.co.uk |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Forex-TSD.com "
#property link      "http://www.forex-tsd.com/"
//--- indicator version number
#property version   "1.00"
//--- drawing indicator in a separate window
#property indicator_separate_window
//--- number of indicator buffers 2
#property indicator_buffers 2 
//--- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//| Parameters of indicator drawing   |
//+-----------------------------------+
//--- drawing the indicator as a color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//--- colors of the five-color histogram are as follows
#property indicator_color1 clrMagenta,clrBrown,clrDarkGray,clrTeal,clrLime
//--- Indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//--- indicator line width is equal to 5
#property indicator_width1 5
//--- displaying the indicator label
#property indicator_label1 "RSIFilter"
//+-----------------------------------+
//| Scale limits of indicator window  |
//+-----------------------------------+
#property indicator_maximum 1.1   // The upper scale limit of a separate indicator window
#property indicator_minimum 0     // The lower scale limit of a separate indicator window
//+-----------------------------------+
//| Declaration of constants          |
//+-----------------------------------+
#define RESET  0 // the constant for getting the command for the indicator recalculation back to the terminal
//+-----------------------------------+
//| Indicator input parameters        |
//+-----------------------------------+
input uint                 RSIPeriod=14;         // Indicator period
input ENUM_APPLIED_PRICE   RSIPrice=PRICE_CLOSE; // Price
input uint                 HighLevel=55;         // Overbought level
input uint                 LowLevel=45;          // Oversold level
//+-----------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double IndBuffer[],ColorIndBuffer[];
//--- declaration of integer variables of data starting point
int min_rates_total;
//--- declaration of integer variables for indicators handles
int RSI_Handle;
//+------------------------------------------------------------------+    
//| RSIFilter indicator initialization function                      | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(RSIPeriod);
//--- getting the handle of the iRSI indicator
   RSI_Handle=iRSI(NULL,0,RSIPeriod,RSIPrice);
   if(RSI_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the iRSI indicator");
      return(INIT_FAILED);
     }
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//--- setting a dynamic array as a color index buffer   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"RSIFilter");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| RSIFilter iteration function                                     | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- checking the number of bars to be enough for calculation
   if(BarsCalculated(RSI_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//--- declaration of local variables
   int to_copy,limit,bar;
   double RSI[];
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
     }
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars
//---
   to_copy=limit+1;
//--- Indexing elements in arrays as time series  
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(RSI,true);
//--- copy newly appeared data into the arrays
   if(CopyBuffer(RSI_Handle,0,0,to_copy,RSI)<=0) return(RESET);
//--- the main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--) IndBuffer[bar]=1;
   if(prev_calculated>rates_total || prev_calculated<=0) limit--;
//--- main indicator coloring loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      int clr=2;

      if(RSI[bar]>HighLevel)
        {
         if(Open[bar]<Close[bar]) clr=4;
         if(Open[bar]>Close[bar]) clr=3;
        }

      if(RSI[bar]<LowLevel)
        {
         if(Open[bar]>Close[bar]) clr=0;
         if(Open[bar]<Close[bar]) clr=1;
        }
      ColorIndBuffer[bar]=clr;
     }  
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
