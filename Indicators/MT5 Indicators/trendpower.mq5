//+------------------------------------------------------------------+
//|                                                  TrendPower.mq5  |
//|                                       Copyright © 2007, mandorr  |
//|                                                                  |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2007, mandorr"
//---- link to the website of the author
#property link ""
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- five buffers are used for calculation and drawing the indicator
#property indicator_buffers 5
//---- 5 graphical plots are used in total
#property indicator_plots   5
//+----------------------------------------------+
//|  Channel line drawing parameters             |
//+----------------------------------------------+
//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- use gray color for the indicator line
#property indicator_color1  clrGray
//---- indicator 1 line is a solid one
#property indicator_style1  STYLE_SOLID
//---- indicator 1 line width is equal to 2
#property indicator_width1  2
//---- displaying the indicator line label
#property indicator_label1  "Lower TrendPower"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used for the indicator line
#property indicator_color2  Blue
//---- the indicator 2 line is a dot-dash one
#property indicator_style2  STYLE_DASHDOTDOT
//---- indicator 2 line width is equal to 2
#property indicator_width2  2
//---- displaying the indicator line label
#property indicator_label2  "Upper TrendPower"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing indicator 3 as line
#property indicator_type3   DRAW_LINE
//---- medium violet red color is used for the indicator line
#property indicator_color3  MediumVioletRed
//---- the indicator 3 line is a dot-dash one
#property indicator_style3  STYLE_DASHDOTDOT
//---- indicator 3 line width is equal to 2
#property indicator_width3  2
//---- displaying the indicator line label
#property indicator_label3  "Lower TrendPower"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 4 as a label
#property indicator_type4   DRAW_ARROW
//---- deep sky blue color is used for the indicator
#property indicator_color4  DeepSkyBlue
//---- indicator 4 width is equal to 4
#property indicator_width4  4
//---- displaying the indicator label
#property indicator_label4  "Buy TrendPower"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 5 as a label
#property indicator_type5   DRAW_ARROW
//---- red color is used for the indicator
#property indicator_color5  Red
//---- indicator 5 width is equal to 4
#property indicator_width5  4
//---- displaying the indicator label
#property indicator_label5  "Sell TrendPower"

//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET  0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint   PeriodStep=10;                       // Moving averages period step;
input  ENUM_MA_METHOD   MAType=MODE_EMA;          // smoothing method
input ENUM_APPLIED_PRICE   MAPrice=PRICE_CLOSE;   // type of price
input int    Shift=0;                             // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double ExtMapBufferUp[];
double ExtMapBufferDown[];
double ExtMapBufferUp1[];
double ExtMapBufferDown1[];
double ExtMapLineBuffer[];
//---- declaration of integer variables for the indicators handles
int MA_Handle[6];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {

//---- getting handles of the MA indicator
   for(int numb=0; numb<6; numb++)
     {
      MA_Handle[numb]=iMA(NULL,0,(numb+1)*PeriodStep,0,MAType,MAPrice);
      if(MA_Handle[numb]==INVALID_HANDLE)
        {
         Print(" Failed to get handle of the MA indicator");
         return(1);
        }
     }

//---- initialization of variables of the start of data calculation
   min_rates_total=int(PeriodStep*6);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtMapLineBuffer,INDICATOR_DATA);
//---- shifting the indicator 0 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtMapLineBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set ExtMapBufferUp[] dynamic array as an indicator buffer
   SetIndexBuffer(1,ExtMapBufferUp,INDICATOR_DATA);
//---- shifting indicator 1 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtMapBufferUp,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set ExtMapBufferDown[] dynamic array as an indicator buffer
   SetIndexBuffer(2,ExtMapBufferDown,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtMapBufferDown,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set ExtMapBufferUp1[] dynamic array as an indicator buffer
   SetIndexBuffer(3,ExtMapBufferUp1,INDICATOR_DATA);
//---- shifting indicator 1 horizontally by Shift
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- shifting the start of drawing of the indicator 3
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtMapBufferUp1,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set ExtMapBufferDown1[] dynamic array as an indicator buffer
   SetIndexBuffer(4,ExtMapBufferDown1,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);
//---- shifting the start of drawing of the indicator 4
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtMapBufferDown1,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"TrendPower(",PeriodStep,", ",EnumToString(MAType),", ",EnumToString(MAPrice),", ",Shift,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//----
   return(0);
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
//---- checking the number of bars to be enough for the calculation    
   for(int numb=0; numb<6; numb++) if(BarsCalculated(MA_Handle[numb])<rates_total) return(RESET);
   if(rates_total<min_rates_total) return(RESET); 

//---- declaration of local variables 
   double MA1[],MA2[],MA3[],MA4[],MA5[],MA6[],h,l;
   int limit,to_copy,bar,trend;

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(MA1,true);
   ArraySetAsSeries(MA2,true);
   ArraySetAsSeries(MA3,true);
   ArraySetAsSeries(MA4,true);
   ArraySetAsSeries(MA5,true);
   ArraySetAsSeries(MA6,true);

//---- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1;               // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated;                 // starting index for calculation of new bars
     }

   to_copy=limit+1;
//---- copy newly appeared data into the arrays
   if(CopyBuffer(MA_Handle[0],0,0,to_copy,MA1)<=0) return(RESET);
   if(CopyBuffer(MA_Handle[1],0,0,to_copy,MA2)<=0) return(RESET);
   if(CopyBuffer(MA_Handle[2],0,0,to_copy,MA3)<=0) return(RESET);
   if(CopyBuffer(MA_Handle[3],0,0,to_copy,MA4)<=0) return(RESET);
   if(CopyBuffer(MA_Handle[4],0,0,to_copy,MA5)<=0) return(RESET);
   if(CopyBuffer(MA_Handle[5],0,0,to_copy,MA6)<=0) return(RESET);

//---- main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ExtMapBufferUp[bar]=EMPTY_VALUE;
      ExtMapBufferDown[bar]=EMPTY_VALUE;
      ExtMapBufferUp1[bar]=EMPTY_VALUE;
      ExtMapBufferDown1[bar]=EMPTY_VALUE;

      h=MA1[bar];
      l=MA1[bar];
      if (h<MA2[bar]) h=MA2[bar];
      if (h<MA3[bar]) h=MA3[bar];
      if (h<MA4[bar]) h=MA4[bar];
      if (h<MA5[bar]) h=MA5[bar];
      if (h<MA6[bar]) h=MA6[bar];
      
      if (h>MA2[bar]) h=MA2[bar];
      if (h>MA3[bar]) h=MA3[bar];
      if (h>MA4[bar]) h=MA4[bar];
      if (h>MA5[bar]) h=MA5[bar];
      if (h>MA6[bar]) h=MA6[bar];
      
      if (high[bar]>h) trend=+1;
      if (low [bar]<l) trend=-1;
      if (high[bar]>h && low[bar]<l) trend=0;

      if (trend<0) ExtMapBufferDown[bar]=h;
      if (trend>0) ExtMapBufferUp[bar]=l;
      
      ExtMapLineBuffer[bar]=(h+l)/2;

      if(ExtMapBufferUp[bar+1]==EMPTY_VALUE && ExtMapBufferUp[bar]!=EMPTY_VALUE) ExtMapBufferUp1[bar]=ExtMapBufferUp[bar];
      if(ExtMapBufferDown[bar+1]==EMPTY_VALUE && ExtMapBufferDown[bar]!=EMPTY_VALUE) ExtMapBufferDown1[bar]=ExtMapBufferDown[bar];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
