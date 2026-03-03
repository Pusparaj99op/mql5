//+------------------------------------------------------------------+
//|                                    Instantaneous_TrendFilter.mq5 |
//|                         Copyright © 2006, Luis Guilherme Damiani |
//|                                      http://www.damianifx.com.br |
//+------------------------------------------------------------------+
//--- copyright
#property copyright "Copyright © 2006, Luis Guilherme Damiani"
//--- link
#property link      "http://www.damianifx.com.br"
//--- indicator version number
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window
//--- number of indicator buffers 2
#property indicator_buffers 2 
//--- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  ITrend indicator drawing parameters         |
//+----------------------------------------------+
//--- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//--- the following colors are used as the indicator colors
#property indicator_color1  clrMagenta,clrBlue
//--- displaying the indicator label
#property indicator_label1  "Instantaneous_TrendFilter"
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input double Alpha=0.07;  // Indicator ratio
input int Shift=0;        // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//--- declaration of dynamic arrays which will be used as indicator buffers
double ITrendBuffer[];
double TriggerBuffer[];
//--- declaration of the integer variables for the start of data calculation
int min_rates_total;
//--- declaration of global variables
double K0,K1,K2,K3,K4;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=4;
//--- initialization of variables
   double A2=Alpha*Alpha;
   K0=Alpha-A2/4.0;
   K1=0.5*A2;
   K2=Alpha-0.75*A2;
   K3=2.0 *(1.0 - Alpha);
   K4=MathPow((1.0 - Alpha),2);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,ITrendBuffer,INDICATOR_DATA);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,TriggerBuffer,INDICATOR_DATA);
//--- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Instantaneous_TrendFilter(",Alpha,", ",Shift,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- define the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const int begin,          // number of beginning of reliable counting of bars
                const double &price[])    // price array for the indicator calculation
  {
//--- checking the number of bars to be enough for the calculation
   if(rates_total<min_rates_total+begin) return(0);
//--- declaration of local variables 
   int first,bar;
   double price0,price1,price2;
//--- calculation of the 'first' starting number for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=min_rates_total+begin; // starting index for calculation of all bars
      //--- shifting the start of drawing of the indicator
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total+begin);
      for(bar=0; bar<first && !IsStopped(); bar++) ITrendBuffer[bar]=price[bar];
     }
   else first=prev_calculated-1; // starting number for calculation of new bars
//--- The main loop of the indicator calculation
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price0=price[bar];
      price1=price[bar-1];
      price2=price[bar-2];
      //---
      if(bar<min_rates_total) ITrendBuffer[bar]=(price0+2.0*price1+price2)/4.0;
      else ITrendBuffer[bar]=K0*price0+K1*price1-K2*price2+K3*ITrendBuffer[bar-1]-K4*ITrendBuffer[bar-2];
      //---
      TriggerBuffer[bar]=2.0*ITrendBuffer[bar]-ITrendBuffer[bar-2];
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
