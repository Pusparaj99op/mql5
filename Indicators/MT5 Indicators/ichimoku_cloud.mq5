//+------------------------------------------------------------------+ 
//|                                               Ichimoku Cloud.mq5 | 
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- number of indicator buffers 2
#property indicator_buffers 2 
//---- one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//---- the following colors are used for the indicator
#property indicator_color1  PaleGreen,Thistle
//---- displaying the indicator label
#property indicator_label1  "Senkou Span A;Senkou Span B"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int InpTenkan=9;  // Tenkan-sen
input int InpKijun=26;  // Kijun-sen
input int InpSenkou=52; // Senkou Span
//+-----------------------------------+
//---- declaration of the integer variables for the start of data calculation
int  min_rates_total;
//---- declaration of dynamic arrays that 
//---- will be used as indicator buffers
double ExtSpanABuffer[];
double ExtSpanBBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=MathMax(InpTenkan,MathMax(InpKijun,InpSenkou));
//---- set ExtSpanABuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtSpanABuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- shifting the indicator horizontally by InpKijun
   PlotIndexSetInteger(0,PLOT_SHIFT,InpKijun);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(ExtSpanABuffer,true);

//---- set ExtSpanBBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,ExtSpanBBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- shifting the indicator horizontally by -InpKijun
   PlotIndexSetInteger(1,PLOT_SHIFT,-InpKijun);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(ExtSpanBBuffer,true);

//---- initializations of a variable for the indicator short name
   string shortname="ZerolagStochs";
//---- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"Senkou Span A;Senkou Span B("+string(InpSenkou)+")");
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- initialization end
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
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
   if(rates_total<min_rates_total) return(0);

//---- declaration of variables with a floating point  
   double HH,LL,ExtTenkan,ExtKijun;
//---- declaration of integer variables
   int limit;

//---- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
        limit=rates_total-min_rates_total-1;            // starting index for calculation of all bars
   else limit=rates_total-prev_calculated;              // starting index for calculation of new bars

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);   
   
//---- main indicator calculation loop
   for(int bar=limit; bar>=0; bar--)
     {
      HH=High[ArrayMaximum(High,bar,InpTenkan)];
      LL=Low [ArrayMinimum(Low, bar,InpTenkan)];
      ExtTenkan=(HH+LL)/2.0;
      
      //--- Kijun Sen
      HH=High[ArrayMaximum(High,bar,InpKijun)];
      LL=Low [ArrayMinimum(Low, bar,InpKijun)];
      ExtKijun=(HH+LL)/2.0;
      
      //--- Senkou Span a
      ExtSpanABuffer[bar]=(ExtTenkan+ExtKijun)/2.0;
      
      //--- Senkou Span b
      HH=High[ArrayMaximum(High,bar,InpSenkou)];
      LL=Low [ArrayMinimum(Low, bar,InpSenkou)];
      ExtSpanBBuffer[bar]=(HH+LL)/2.0;
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
