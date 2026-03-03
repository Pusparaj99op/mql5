//+------------------------------------------------------------------+
//|                                              Color Parabolic.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "Parabolic Sar"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- 4 buffers are used for calculation and drawing the indicator
#property indicator_buffers 4
//---- 4 plots are used
#property indicator_plots   4
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- red color is used for the indicator
#property indicator_color1  Red
//---- indicator 1 width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "Lower Parabolic"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a label
#property indicator_type2   DRAW_ARROW
//---- medium blue color is used for the indicator
#property indicator_color2  MediumBlue
//---- indicator 2 width is equal to 1
#property indicator_width2  1
//---- displaying the indicator label
#property indicator_label2 "Upper Parabolic"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_ARROW
//---- deep pink color is used for the indicator
#property indicator_color3  DeepPink
//---- indicator 3 width is equal to 4
#property indicator_width3  4
//---- displaying the indicator label
#property indicator_label3  "Parabolic Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4   DRAW_ARROW
//---- use blue violet color for the indicator
#property indicator_color4  BlueViolet
//---- indicator 4 width is equal to 4
#property indicator_width4  4
//---- displaying the indicator label
#property indicator_label4 "Parabolic Buy"
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input double Step=0.02;    // Step
input double Maximum=0.2;  // Maximum
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double BuyBuffer[],SellBuffer[];
double UpSarBuffer[],DnSarBuffer[];
//---- declaration of integer variables for the indicators handles
int SAR_Handle;
//---- declaration of the integer variables for the start of data calculation
int  min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of variables    
   min_rates_total=2;

//---- getting handle of the iSAR indicator
   SAR_Handle=iSAR(NULL,PERIOD_CURRENT,Step,Maximum);
   if(SAR_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iSAR indicator");

//---- set UpSarBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,UpSarBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,158);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(UpSarBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- set DnSarBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,DnSarBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,158);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(DnSarBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- set SellBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(2,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,174);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(SellBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

//---- set BuyBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(3,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,174);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(BuyBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);

//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="Parabolic Sar";
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
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(SAR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//---- declarations of local variables 
   int limit,to_copy,bar;
   double SAR[];
//---- calculations of the necessary amount of data to be copied
//---- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total+1; // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars 
   to_copy=limit+2;
//---- copy newly appeared data in the SAR array
   if(CopyBuffer(SAR_Handle,0,0,to_copy,SAR)<=0) return(RESET);
//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(SAR,true);
   ArraySetAsSeries(open,true);
//---- first indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- zero out the contents of the indicator buffers for calculation
      DnSarBuffer[bar]=0.0;
      UpSarBuffer[bar]=0.0;

      if(open[bar]<SAR[bar]) UpSarBuffer[bar]=SAR[bar];
      else                   DnSarBuffer[bar]=SAR[bar];
     }
//---- recalculation of the starting index for calculation of all bars
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation     
      limit--;
//---- the second indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- zero out the contents of the indicator buffers for calculation
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;

      if(UpSarBuffer[bar+1]>0.0&&DnSarBuffer[bar]>0.0) BuyBuffer [bar]=SAR[bar];
      if(DnSarBuffer[bar+1]>0.0&&UpSarBuffer[bar]>0.0) SellBuffer[bar]=SAR[bar];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
