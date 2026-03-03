//+------------------------------------------------------------------+
//|                                                 TrendManager.mq5 |
//|                             Copyright © 2006,  Alejandro Galindo |
//|                                              http://elCactus.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006,  Alejandro Galindo"
#property link      "http://elCactus.com/"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers 3
#property indicator_buffers 3 
//---- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a histogram 2
#property indicator_type1 DRAW_COLOR_HISTOGRAM2
//---- the following colors are used for the indicator
#property indicator_color1 Gray,DeepPink,DarkTurquoise
//---- indicator line width is equal to 2
#property indicator_width1  2
//---- displaying the indicator label
#property indicator_label1  "Trend Manager"
//+-----------------------------------+ 
//|  Declaration of constants         |
//+-----------------------------------+ 
#define RESET 0 // the constant for getting the command for the indicator recalculation back to the terminal
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input uint DVLimit=70;                          // Limit in points
input uint Fast_Period=23;                      // Fast MA period
input ENUM_APPLIED_PRICE Fast_Price=PRICE_OPEN; // Fast MA price type
input ENUM_MA_METHOD Fast_Method=MODE_SMA;      // Fast MA smoothing method
input uint Slow_Period=84;                      // Slow MA period
input ENUM_APPLIED_PRICE Slow_Price=PRICE_OPEN; // Slow MA price type
input ENUM_MA_METHOD Slow_Method=MODE_SMA;      // Slow MA smoothing method
input int  Shift=0;                             // Horizontal shift of the indicator in bars 
//+-----------------------------------+
double dDVLimit;
//---- declaration of integer variables for the indicators handles
int MAa_Handle,MAb_Handle;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total,min_rates_total1,min_rates_total2;
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double SpanA_Buffer[],SpanB_Buffer[], Color_Buffer[];
//+------------------------------------------------------------------+   
//| TSI indicator initialization function                            | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=int(MathMax(Fast_Period,Slow_Period));
//---- initialization of variables  
   dDVLimit=DVLimit*_Point;
//---- getting handle of the MA a indicator
   MAa_Handle=iMA(NULL,0,Fast_Period,0,Fast_Method,Fast_Price);
   if(MAa_Handle==INVALID_HANDLE) Print(" Failed to get handle of the MA a indicator");
//---- getting handle of the MA b indicator
   MAb_Handle=iMA(NULL,0,Slow_Period,0,Slow_Method,Slow_Price);
   if(MAb_Handle==INVALID_HANDLE) Print(" Failed to get handle of the MA b indicator");
//---- set SpanA_Buffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,SpanA_Buffer,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(SpanA_Buffer,true);

//---- set SpanB_Buffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,SpanB_Buffer,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(SpanB_Buffer,true);
   
//---- set Color_Buffer[] dynamic array as a color index buffer
   SetIndexBuffer(2,Color_Buffer,INDICATOR_COLOR_INDEX);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(Color_Buffer,true);

//---- initializations of a variable for the indicator short name
   string shortname="Trend Manager";
//--- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- initialization end
  }
//+------------------------------------------------------------------+ 
//| Indicator iteration function                                     | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(MAa_Handle)<rates_total
      || BarsCalculated(MAb_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declarations of local variables 
   int to_copy,limit,bar;
   double MAA[],MAB[],D;

//---- calculations of the necessary amount of data to be copied
//---- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
     }
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

   to_copy=limit+1;

//--- copy newly appeared data in the arrays
   if(CopyBuffer(MAa_Handle,0,0,to_copy,MAA)<=0) return(RESET);
   if(CopyBuffer(MAb_Handle,0,0,to_copy,MAB)<=0) return(RESET);

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(MAA,true);
   ArraySetAsSeries(MAB,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(High,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      D=MAA[bar]-MAB[bar];

      SpanA_Buffer[bar]=0.0;
      SpanB_Buffer[bar]=0.0;
      Color_Buffer[bar]=0;

      if(D>=+dDVLimit)
        {
         SpanA_Buffer[bar]=High[bar];
         SpanB_Buffer[bar]=High[bar]+(D-dDVLimit);
         Color_Buffer[bar]=2;
        }

      if(D<=-dDVLimit)
        {
         SpanA_Buffer[bar]=Low[bar];
         SpanB_Buffer[bar]=Low[bar]+(D-dDVLimit);
         Color_Buffer[bar]=1;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
