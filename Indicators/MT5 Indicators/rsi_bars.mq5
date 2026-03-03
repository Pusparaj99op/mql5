//+------------------------------------------------------------------+ 
//|                                                     RSI_BARS.mq5 | 
//|                               Copyright © 2013, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2013, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- number of indicator buffers 3
#property indicator_buffers 3 
//--- one plot is used
#property indicator_plots   1
//+-----------------------------------+
//| Parameters of indicator drawing   |
//+-----------------------------------+
//--- drawing indicator as a four-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM2
//--- colors of the five-color histogram are as follows
#property indicator_color1 clrMagenta,clrBrown,clrGray,clrTeal,clrDarkTurquoise
//--- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//--- indicator line width is 2
#property indicator_width1 2
//--- displaying the indicator label
#property indicator_label1 "RSI_BARS"
//+-----------------------------------+
//| Declaration of constants          |
//+-----------------------------------+
#define RESET  0 // a constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//| Indicator input parameters        |
//+-----------------------------------+
input uint                 RSIPeriod=14;         // Indicator period
input ENUM_APPLIED_PRICE   RSIPrice=PRICE_CLOSE; // Price
input uint                 HighLevel=60;         // Overbought level
input uint                 LowLevel=40;          // Oversold level
//+-----------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double UpIndBuffer[],DnIndBuffer[],ColorIndBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int RSI_Handle;
//+------------------------------------------------------------------+    
//| RSI_BARS indicator initialization function                       | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of data calculation start
   min_rates_total=int(RSIPeriod);
//--- getting the handle of the iRSI indicator
   RSI_Handle=iRSI(NULL,0,RSIPeriod,RSIPrice);
   if(RSI_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the iRSI indicator");
      return(INIT_FAILED);
     }
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,UpIndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpIndBuffer,true);
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(1,DnIndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnIndBuffer,true);
//--- setting a dynamic array as a color index buffer   
   SetIndexBuffer(2,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI_BARS");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| RSI_BARS iteration function                                      | 
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
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(RSI_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//--- declarations of local variables
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
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(RSI,true);
//--- copy newly appeared data in the arrays
   if(CopyBuffer(RSI_Handle,0,0,to_copy,RSI)<=0) return(RESET);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      UpIndBuffer[bar]=High[bar];
      DnIndBuffer[bar]=Low[bar];
     }
   if(prev_calculated>rates_total || prev_calculated<=0) limit--;
//--- main cycle of the indicator coloring
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

      if(clr!=2)
        {
         UpIndBuffer[bar]=High[bar];
         DnIndBuffer[bar]=Low[bar];
        }
      else
        {
         UpIndBuffer[bar]=0.0;
         DnIndBuffer[bar]=0.0;
        }

      ColorIndBuffer[bar]=clr;
     }  
//---
   return(rates_total);
  }
//+------------------------------------------------------------------+
