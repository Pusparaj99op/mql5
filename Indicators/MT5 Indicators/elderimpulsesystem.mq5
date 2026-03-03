//+------------------------------------------------------------------+
//|                                           ElderImpulseSystem.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "Elder Impuls System"
//---- indicator version
#property version   "1.00"
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- five buffers are used for calculation and drawing the indicator
#property indicator_buffers 5
//---- only one plot is used
#property indicator_plots   1
//---- color candlesticks are used as an indicator
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  Blue,Red,Green
//---- displaying the indicator label
#property indicator_label1  "Open; High; Low; Close"
//+-----------------------------------+
//|  declaration of constants         |
//+-----------------------------------+
#define RESET  0 // the constant for getting the command for the indicator recalculation back to the terminal
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int ma_period=13;          // Period of MA
input int fast_ema_period = 12;  // MACD fast period 
input int slow_ema_period = 26;  // MACD slow period
input int signal_period=9;       // MACD signal period
//+-----------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
double ExtColorBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of integer variables for the indicators handles
int MA_Handle,MACD_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=MathMax(ma_period,signal_period+1)+2;

//---- getting handle of the iMA indicator
   MA_Handle=iMA(NULL,0,ma_period,0,MODE_EMA,PRICE_CLOSE);
   if(MA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- getting handle of the iMACD indicator
   MACD_Handle=iMACD(NULL,0,fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   if(MACD_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");

//---- set dynamic arrays as indicator buffers
   SetIndexBuffer(0,ExtOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtCloseBuffer,INDICATOR_DATA);

//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(ExtOpenBuffer,true);
   ArraySetAsSeries(ExtHighBuffer,true);
   ArraySetAsSeries(ExtLowBuffer,true);
   ArraySetAsSeries(ExtCloseBuffer,true);
   ArraySetAsSeries(ExtColorBuffer,true);

//---- set ExtColorBuffer[] dynamic array as an indicator buffer   
   SetIndexBuffer(4,ExtColorBuffer,INDICATOR_COLOR_INDEX);

//---- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);

//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//---- name for the data window and the label for sub-windows
   string short_name;
   StringConcatenate(short_name,"Elder Impuls System(",
                     ma_period,", ",fast_ema_period,", ",slow_ema_period,", ",signal_period,")");
//---- creating a name for displaying in a separate sub-window and in a tooltip
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
   if(BarsCalculated(MA_Handle)<rates_total
      || BarsCalculated(MACD_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declarations of local variables 
   int to_copy,limit,bar;
   double MA[],MACDM[],MACDS[];
   double dma,dmacd0,dmacd1;

//---- calculations of the necessary number of copied data and limit starting index for the  bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-1-min_rates_total; // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated;   // starting index for calculation of new bars
     }

   to_copy=limit+2;

//--- copy newly appeared data in the arrays
   if(CopyBuffer(MA_Handle,0,0,to_copy,MA)<=0) return(RESET);
   if(CopyBuffer(MACD_Handle,0,0,to_copy,MACDM)<=0) return(RESET);
   if(CopyBuffer(MACD_Handle,1,0,to_copy,MACDS)<=0) return(RESET);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(MA,true);
   ArraySetAsSeries(MACDM,true);
   ArraySetAsSeries(MACDS,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ExtOpenBuffer [bar]=open[bar];
      ExtCloseBuffer[bar]=close[bar];
      ExtHighBuffer [bar]=high[bar];
      ExtLowBuffer  [bar]=low[bar];

      dma=MA[bar]-MA[bar+1];
      dmacd0=MACDM[bar]-MACDS[bar];
      dmacd1=MACDM[bar+1]-MACDS[bar+1];

      if(dma>0 && dmacd0 > dmacd1 && dmacd0>0) ExtColorBuffer[bar]=2;
      if(dma<0 && dmacd0 < dmacd1 && dmacd0<0) ExtColorBuffer[bar]=1;

      if(MA[bar]<=MA[bar+1] && dmacd0>0 || dma<=0 && dmacd0>dmacd1 || dma>=0 && dmacd0<0 || dma>=0 && dmacd0<dmacd1)
         ExtColorBuffer[bar]=0;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
