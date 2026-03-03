//+------------------------------------------------------------------+ 
//|                                                     RVI_BARS.mq5 | 
//|                                          Copyright © 2005, Perky | 
//|                                                Perky_z@yahoo.com | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2005, Perky"
#property link "Perky_z@yahoo.com" 
//--- indicator version number
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- number of indicator buffers 3
#property indicator_buffers 3 
//--- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//| Parameters of indicator drawing   |
//+-----------------------------------+
//--- drawing indicator as a four-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM2
//--- the following colors are used in the four color histogram
#property indicator_color1 clrRed,clrPurple,clrGray,clrMediumBlue,clrDodgerBlue
//--- Indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//--- indicator line width is 2
#property indicator_width1 2
//--- displaying the indicator label
#property indicator_label1 "RVI_BARS"
//+-----------------------------------+
//| Declaration of constants          |
//+-----------------------------------+
#define RESET  0 // a constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//| Indicator input parameters        |
//+-----------------------------------+
input   uint RVIPeriod=14;
//+-----------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double UpIndBuffer[],DnIndBuffer[],ColorIndBuffer[];
//--- declaration of the integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for indicators handles
int RVI_Handle;
//+------------------------------------------------------------------+    
//| RVI_BARS indicator initialization function                       | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(RVIPeriod);
//--- getting handle of the iRVI indicator
   RVI_Handle=iRVI(NULL,0,RVIPeriod);
   if(RVI_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the iRVI calculator");
      return(INIT_FAILED);
     }
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,UpIndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpIndBuffer,true);
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(1,DnIndBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnIndBuffer,true);
//--- set dynamic array as a color index buffer   
   SetIndexBuffer(2,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"RVI_BARS");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| RVI_BARS iteration function                                      | 
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
//--- checking the number of bars to be enough for the calculation
   if(BarsCalculated(RVI_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//--- declaration of local variables
   int to_copy,limit,bar;
   double RVI[],SIG[];
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
     }
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars

   to_copy=limit+1;
//--- indexing elements in arrays as time series  
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(RVI,true);
   ArraySetAsSeries(SIG,true);
//--- copy newly appeared data into the arrays
   if(CopyBuffer(RVI_Handle,MAIN_LINE,0,to_copy,RVI)<=0) return(RESET);
   if(CopyBuffer(RVI_Handle,SIGNAL_LINE,0,to_copy,SIG)<=0) return(RESET);
//--- The main loop of the indicator calculation
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
      if(RVI[bar]>SIG[bar])
        {
         if(Open[bar]<Close[bar]) clr=4;
         if(Open[bar]>Close[bar]) clr=3;
        }
      if(RVI[bar]<SIG[bar])
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
