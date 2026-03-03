//+------------------------------------------------------------------+
//|                                           3_Level_ZZ_Semafor.mq5 |
//|                                      Copyright 2000, asystem2000 |
//|                                            asystem2000@yandex.ru |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "2000, asystem2000"
//---- link to the author's website
#property link      "asystem2000@yandex.ru"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- six buffers are used for calculation and drawing the indicator
#property indicator_buffers 6
//---- six plots are used
#property indicator_plots   6
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- use aqua color
#property indicator_color1  Aqua
//---- thickness of the indicator line is equal to 1
#property indicator_width1  1
//---- displaying the indicator bullish symbol label
#property indicator_label1  "Low"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a symbol
#property indicator_type2   DRAW_ARROW
//---- use magenta color
#property indicator_color2  Magenta
//---- thickness of the indicator 2 line is equal to 1
#property indicator_width2  1
//---- displaying the indicator bearish symbol label
#property indicator_label2 "High"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3 DRAW_ARROW
//---- aqua color is used as a symbol color
#property indicator_color3  Aqua
//---- thickness of the indicator line 3 is equal to 1
#property indicator_width3  1
//---- displaying the indicator bullish symbol label
#property indicator_label3  "Low"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4 DRAW_ARROW
//---- magenta color is used as a symbol color
#property indicator_color4 Magenta
//---- thickness of the indicator line 4 is equal to 1
#property indicator_width4  1
//---- displaying the indicator bearish symbol label
#property indicator_label4 "High"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 5 as a symbol
#property indicator_type5 DRAW_ARROW
//---- aqua color is used as a symbol color
#property indicator_color5 Aqua 
//---- thickness of the indicator line 5 is equal to 1
#property indicator_width5  1
//---- displaying the indicator bullish symbol label
#property indicator_label5  "Low"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 6 as a symbol
#property indicator_type6 DRAW_ARROW
//---- magenta color is used as a symbol color
#property indicator_color6 Magenta
//---- thickness of the indicator line 4 is equal to 1
#property indicator_width6  1
//---- displaying of the bearish label of the indicator
#property indicator_label6 "High"
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int Period1=5;
input int Deviation1=1;
input int Backstep1=3;
input int HighSymbol1=159;
input int LowSymbol1=159;

input int Period2=13;
input int Deviation2=8;
input int Backstep2=5;
input int HighSymbol2=108;
input int LowSymbol2=108;

input int Period3=34;
input int Deviation3=21;
input int Backstep3=12;
input int HighSymbol3=163;
input int LowSymbol3=163;
//+----------------------------------------------+
//---- declaration of dynamic arrays that
// will be used as indicator buffers
double HighBuffer1[],LowBuffer1[];
double HighBuffer2[],LowBuffer2[];
double HighBuffer3[],LowBuffer3[];
//---- declaration of the integer variables for the start of data calculation
int StartBar1,StartBar2,StartBar3,StartBar;
//---- declaration of variables for storing indicators handles
int Handle1,Handle2,Handle3;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialize constants
   StartBar1=Period1+Deviation1+Backstep1+1;
   StartBar2=Period2+Deviation2+Backstep2+1;
   StartBar3=Period3+Deviation3+Backstep3+1;
   StartBar=(int)MathMax(StartBar1,MathMax(StartBar2,StartBar3));

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,LowBuffer1,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Low1");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,LowSymbol1);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(LowBuffer1,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,HighBuffer1,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"High1");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,HighSymbol1);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(HighBuffer1,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(2,LowBuffer2,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(2,PLOT_LABEL,"Low2");
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,LowSymbol2);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(LowBuffer2,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(3,HighBuffer2,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(3,PLOT_LABEL,"High2");
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,HighSymbol2);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(HighBuffer2,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(4,LowBuffer3,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 5
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(4,PLOT_LABEL,"Low3");
//---- indicator symbol
   PlotIndexSetInteger(4,PLOT_ARROW,LowSymbol3);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(LowBuffer3,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(5,HighBuffer3,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 6
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,0);
//---- create a label to display in DataWindow
   PlotIndexSetString(5,PLOT_LABEL,"High3");
//---- indicator symbol
   PlotIndexSetInteger(5,PLOT_ARROW,HighSymbol3);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(HighBuffer3,true);

//---- initializations of a variable for the indicator short name
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"3_Level_ZZ_Semafor");
//---- determination of accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//---- Get indicator's handle
   Handle1=iCustom(NULL,0,"Examples\ZigZag",Period1,Deviation1,Backstep1);
   if(Handle1==INVALID_HANDLE) Print(" Failed to get handle of the ZigZag1 indicator");
//---- Get indicator's handle
   Handle2=iCustom(NULL,0,"Examples\ZigZag",Period2,Deviation2,Backstep2);
   if(Handle2==INVALID_HANDLE) Print(" Failed to get handle of the ZigZag2 indicator");
//---- Get indicator's handle
   Handle3=iCustom(NULL,0,"Examples\ZigZag",Period3,Deviation3,Backstep3);
   if(Handle3==INVALID_HANDLE) Print(" Failed to get handle of the ZigZag3 indicator");
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<StartBar) return(0);

//---- declarations of local variables 
   int limit,to_copy1,to_copy2,to_copy3;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      limit=rates_total-StartBar;  // starting index for calculation of all bars
      to_copy1=rates_total;
      to_copy2=rates_total;
      to_copy3=rates_total;
     }
   else
     {
      limit=rates_total-prev_calculated;
      to_copy1=limit+StartBar1;
      to_copy2=limit+StartBar2;
      to_copy3=limit+StartBar3;
     }

//---- copy the newly appeared data in the indicator buffers
   if(CopyBuffer(Handle1,1,0,to_copy1,HighBuffer1)<=0) return(0);
   if(CopyBuffer(Handle1,2,0,to_copy1,LowBuffer1)<=0) return(0);
   if(CopyBuffer(Handle2,1,0,to_copy2,HighBuffer2)<=0) return(0);
   if(CopyBuffer(Handle2,2,0,to_copy2,LowBuffer2)<=0) return(0);
   if(CopyBuffer(Handle3,1,0,to_copy3,HighBuffer3)<=0) return(0);
   if(CopyBuffer(Handle3,2,0,to_copy3,LowBuffer3)<=0) return(0);
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
