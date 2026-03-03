//+------------------------------------------------------------------+
//|                                               BBands_Stop_v1.mq5 |
//|                           Copyright © 2006, TrendLaboratory Ltd. |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//|                                       E-mail: igorad2004@list.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, TrendLaboratory Ltd." 
//---- link to the website of the author
#property link "http://finance.groups.yahoo.com/group/TrendLaboratory"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- 6 buffers are used for calculation and drawing the indicator
#property indicator_buffers 6
//---- 6 graphical plots are used
#property indicator_plots   6
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- use orange color for the symbol
#property indicator_color1  Orange
//---- indicator 1 line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label 1
#property indicator_label1  "Sell Signal"
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- use orange color for the stop-loss symbols
#property indicator_color2  Orange
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator 2 label
#property indicator_label2 "Sell Stop Signal"
//---- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_LINE
//---- use orange color for the stop-loss line
#property indicator_color3  Orange
//---- indicator 3 line width is equal to 1
#property indicator_width3  1
//---- displaying the indicator 3 label
#property indicator_label3 "Sell Stop Line"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4   DRAW_ARROW
//---- chartreuse color is used for the input symbol
#property indicator_color4  Chartreuse
//---- indicator 4 line width is equal to 1
#property indicator_width4  1
//---- displaying the indicator label 4
#property indicator_label4  "Buy Signal"

//---- drawing the indicator 5 as a symbol
#property indicator_type5   DRAW_ARROW
//---- chartreuse color is used for the stop-losses symbols
#property indicator_color5  Chartreuse
//---- indicator 5 line width is equal to 1
#property indicator_width5  1
//---- displaying the indicator label 5
#property indicator_label5 "Buy Stop Signal"

//---- drawing the indicator 6 as a symbol
#property indicator_type6   DRAW_LINE
//---- chartreuse color is used for the stop-losses line
#property indicator_color6  Chartreuse
//---- indicator 6 line width is equal to 1
#property indicator_width6  1
//---- displaying the indicator label 6
#property indicator_label6 "Buy Stop Line"
//+----------------------------------------------+
//|  Declaration of enumerations                 |
//+----------------------------------------------+
enum DISPLAY_SIGNALS_MODE // Type of constant
  {
   OnlyStops= 0,          // Only Stops
   SignalsStops,          // Signals & Stops
   OnlySignals            // Only Signals
  };
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int Length=20;                            // Bollinger Bands period
input double Deviation=2;                       // Deviation
input double MoneyRisk=1.00;                    // Offset Factor
input DISPLAY_SIGNALS_MODE Signal=SignalsStops; // Display signals mode
input bool Line=true;
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double UpTrendBuffer[];
double DownTrendBuffer[];
double UpTrendSignal[];
double DownTrendSignal[];
double UpTrendLine[];
double DownTrendLine[];
//---- declaration of integer variables for the indicators handles
int BB_Handle;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of global variables
double MRisk;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- initialization of global variables 
   min_rates_total=Length+1;
   MRisk=0.5*(MoneyRisk-1);
//----
   BB_Handle=iBands(NULL,0,Length,0,Deviation,PRICE_CLOSE);
   if(BB_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iBands indicator");

//---- set DownTrendSignal[] dynamic array as an indicator buffer
   SetIndexBuffer(0,DownTrendSignal,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,108);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(DownTrendSignal,true);

//---- set DownTrendBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,DownTrendBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(DownTrendBuffer,true);

//---- set DownTrendLine[] dynamic array as an indicator buffer
   SetIndexBuffer(2,DownTrendLine,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(DownTrendLine,true);

//---- set UpTrendSignal[] dynamic array as an indicator buffer
   SetIndexBuffer(3,UpTrendSignal,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,108);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(UpTrendSignal,true);

//---- set UpTrendBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(4,UpTrendBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 5
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(4,PLOT_ARROW,159);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0.0);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(UpTrendBuffer,true);

//---- set UpTrendLine[] dynamic array as an indicator buffer
   SetIndexBuffer(5,UpTrendLine,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 6
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(UpTrendLine,true);

//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name;
   StringConcatenate(short_name,"BBands_Stop(",Length,", ",
                     DoubleToString(Deviation,2),", ",DoubleToString(MoneyRisk,2),")");
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
  }
//+------------------------------------------------------------------+
//| Bollinger Bands_Stop_v1                                          |
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
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(BB_Handle)<rates_total || rates_total<min_rates_total) return(0);

//---- declarations of local variables 
   int limit,bar,trend,to_copy,maxbar;
   double smax0,smin0,bsmax0,bsmin0;
   double UpBB[],DnBB[],dsize;

//---- memory variables declarations  
   static int trend_;
   static double smax1,smin1,bsmax1,bsmin1;

//---- calculations of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars

      smax1=-999999999;
      smin1=+999999999;
      bsmax1=-999999999;
      bsmin1=+999999999;
      trend_=0;

      for(bar=rates_total-1; bar>limit; bar--)
        {
         UpTrendBuffer[bar]=0;
         DownTrendBuffer[bar]=0;
         UpTrendSignal[bar]=EMPTY_VALUE;
         DownTrendSignal[bar]=EMPTY_VALUE;
         UpTrendLine[bar]=0;
         DownTrendLine[bar]=0;
        }
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }

//---- indexing elements in arrays as timeseries
   ArraySetAsSeries(UpBB,true);
   ArraySetAsSeries(DnBB,true);
   ArraySetAsSeries(close,true);
   to_copy=limit+1;
   maxbar=rates_total-min_rates_total-1;

//--- copy newly appeared data in the array
   if(CopyBuffer(BB_Handle,1,0,to_copy,UpBB)<=0) return(0);
   if(CopyBuffer(BB_Handle,2,0,to_copy,DnBB)<=0) return(0);

//---- restore values of the variables
   trend=trend_;

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         trend_=trend;
        }

      smax0=UpBB[bar];
      smin0=DnBB[bar];
      UpTrendBuffer[bar]=0;
      DownTrendBuffer[bar]=0;
      UpTrendSignal[bar]=EMPTY_VALUE;
      DownTrendSignal[bar]=EMPTY_VALUE;
      UpTrendLine[bar]=0;
      DownTrendLine[bar]=0;

      if(bar>maxbar)
        {
         smin1=smin0;
         smax1=smax0;
         bsmax1=smax1+MRisk*(smax1-smin1);
         bsmin1=smin1-MRisk*(smax1-smin1);
         continue;
        }

      if(close[bar]>smax1) trend=1;
      if(close[bar]<smin1) trend=-1;

      if(trend>0 && smin0<smin1) smin0=smin1;
      if(trend<0 && smax0>smax1) smax0=smax1;

      dsize=MRisk*(smax0-smin0);
      bsmax0=smax0+dsize;
      bsmin0=smin0-dsize;

      if(trend>0 && bsmin0<bsmin1) bsmin0=bsmin1;
      if(trend<0 && bsmax0>bsmax1) bsmax0=bsmax1;

      if(trend>0)
        {
         if(Signal && !UpTrendBuffer[bar+1])
           {
            UpTrendSignal[bar]=bsmin0;
            UpTrendBuffer[bar]=bsmin0;
            if(Line) UpTrendLine[bar]=bsmin0;
           }
         else
           {
            UpTrendBuffer[bar]=bsmin0;
            if(Line) UpTrendLine[bar]=bsmin0;
            UpTrendSignal[bar]=EMPTY_VALUE;
           }

         if(Signal==OnlySignals) UpTrendBuffer[bar]=0;
         DownTrendSignal[bar]=EMPTY_VALUE;
         DownTrendBuffer[bar]=0;
         DownTrendLine[bar]=0;
        }

      if(trend<0)
        {
         if(Signal && !DownTrendBuffer[bar+1])
           {
            DownTrendSignal[bar]=bsmax0;
            DownTrendBuffer[bar]=bsmax0;
            if(Line) DownTrendLine[bar]=bsmax0;
           }
         else
           {
            DownTrendBuffer[bar]=bsmax0;
            if(Line) DownTrendLine[bar]=bsmax0;
            DownTrendSignal[bar]=EMPTY_VALUE;
           }
         if(Signal==OnlySignals) DownTrendBuffer[bar]=0;
         UpTrendSignal[bar]=EMPTY_VALUE;
         UpTrendBuffer[bar]=0;
         UpTrendLine[bar]=0;
        }

      if(bar>0)
        {
         smax1=smax0;
         smin1=smin0;
         bsmax1=bsmax0;
         bsmin1=bsmin0;
        }

     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
