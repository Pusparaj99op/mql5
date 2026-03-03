//+------------------------------------------------------------------+
//|                                                   Karacatica.mq5 |
//|                                       Copyright © 2005,  Dmitry  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//----two buffers are used for calculation and drawing of the indicator
#property indicator_buffers 2
//---- only two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- magenta color is used as the color of the bearish label of the indicator
#property indicator_color1  Magenta
//---- thickness of the indicator line 1 is equal to 4
#property indicator_width1  4
//---- displaying of the bearish label of the indicator
#property indicator_label1  "Karacatica Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- lime color is used as the color of the bullish label of the indicator
#property indicator_color2  Lime
//---- thickness of the indicator line 2 is equal to 4
#property indicator_width2  4
//---- displaying of the bullish label of the indicator
#property indicator_label2 "Karacatica Buy"

//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int iPeriod=70; //ATR period 
//+----------------------------------------------+

//---- declaration of dynamic arrays that further
//---- will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//----
double s;
int StartBars;
int ATR_Handle,ADX_Handle,ltr,ltr_;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables 
   s=1.5/2.0;
   StartBars=iPeriod+1;
//---- getting handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,iPeriod);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");
//---- getting handle of the ADX indicator
   ADX_Handle=iADX(NULL,0,iPeriod);
   if(ADX_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ADX indicator");

//---- turning a dynamic array into an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//---- creating a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Karacatica Sell");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,234);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellBuffer,true);

//---- turning a dynamic array into an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//---- creating a label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"Karacatica Buy");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,233);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyBuffer,true);

//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="Karacatica";
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
                const int &spread[]
                )
  {
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(ADX_Handle)<rates_total
      || rates_total<StartBars)
      return(0);

//---- declarations of local variables 
   int to_copy,limit,bar;
   double ADXP[],ADXM[],ATR[];

//---- calculations of the necessary amount of data to be copied and
//---- the limit starting number for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      to_copy=rates_total;         // calculated number of all bars
      limit=rates_total-StartBars; // starting number for calculation of all bars
     }
   else
     {
      to_copy=rates_total-prev_calculated+1; // calculated number of new bars only
      limit=rates_total-prev_calculated;     // starting number for calculation of new bars
     }

//---- copying newly appeared data in the arrays
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(0);
   if(CopyBuffer(ADX_Handle,1,0,to_copy,ADXP)<=0) return(0);
   if(CopyBuffer(ADX_Handle,2,0,to_copy,ADXM)<=0) return(0);

//---- indexing elements in arrays, as in timeseries  
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(ADXP,true);
   ArraySetAsSeries(ADXM,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//---- restore values of the variables
   ltr=ltr_;

//---- main loop of the indicator calculation
   for(bar=limit; bar>=0; bar--)
     {
      //---- memorize values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
         ltr_=ltr;

      SellBuffer[bar]=0.0;
      BuyBuffer[bar]=0.0;

      if(BuyBuffer[bar+1]!=0 && BuyBuffer[bar+1]!=EMPTY_VALUE)ltr=1;
      if(SellBuffer[bar+1]!=0 && SellBuffer[bar+1]!=EMPTY_VALUE)ltr=2;

      if(close[bar]>close[bar+iPeriod] && ADXP[bar]>ADXM[bar] && ltr!=1)BuyBuffer[bar]=low[bar]-ATR[bar]*s;
      if(close[bar]<close[bar+iPeriod] && ADXP[bar]<ADXM[bar] && ltr!=2)SellBuffer[bar]=high[bar]+ATR[bar]*s;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
