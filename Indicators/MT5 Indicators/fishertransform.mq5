//+------------------------------------------------------------------+
//|                                              FisherTransform.mq5 |
//|                                                                  |
//| Fisher Transform                                                 |
//|                                                                  |
//| Algorithm taken from book                                        |
//|     "Cybernetics Analysis for Stock and Futures"                 |
//| by John F. Ehlers                                                |
//|                                                                  |
//|                                              contact@mqlsoft.com |
//|                                          http://www.mqlsoft.com/ |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Coded by Witold Wozniak"
//---- author of the indicator
#property link      "www.mqlsoft.com"
//---- indicator version
#property version   "1.10"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- two buffers are used for calculation and drawing the indicator
#property indicator_buffers 2
//---- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Fisher indicator drawing parameters         |
//+----------------------------------------------+
//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- red color is used as the color of the indicator line
#property indicator_color1  clrRed
//---- the indicator 1 line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator 1 line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator line label
#property indicator_label1  "Fisher"
//+----------------------------------------------+
//|  Trigger indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used for the indicator line
#property indicator_color2  clrBlue
//---- the indicator 2 line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator line label
#property indicator_label2  "Trigger"
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1 0.0
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int Length=10;  // Indicator period 
input int Shift=0;    // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double FisherBuffer[];
double TriggerBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- set FisherBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,FisherBuffer,INDICATOR_DATA);
//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing shift of the beginning of counting of drawing the indicator 1 by Length
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,Length);

//---- set TriggerBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,TriggerBuffer,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- performing shift of the beginning of counting of drawing the indicator 2 by Length
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,Length);

//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"FisherTransform(",Length,", ",Shift,")");
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
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
   if(rates_total<Length) return(0);

//---- declarations of local variables 
   int first,bar,kkk;
   double price,price1,MaxH,MinL,Value;
   static double Value_;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first=Length-1; // starting index for calculation of all bars
      Value_=0.0;
     }
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- restore values of the variables
   Value=Value_;

//---- main indicator calculation loop
   for(bar=first; bar<rates_total; bar++)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==rates_total-1)
         Value_=Value;

      price=(high[bar]+low[bar])/2.0;
      MaxH = price;
      MinL = price;

      for(int iii=0; iii<Length; iii++)
        {
         kkk=bar-iii;
         price1=(high[kkk]+low[kkk])/2.0;
         if(price1 > MaxH) MaxH = price1;
         if(price1 < MinL) MinL = price1;
        }

      double res=MaxH-MinL;
      if(res) Value=0.5*2.0 *((price-MinL)/res-0.5)+0.5*Value;
      else Value=0.0;

      if(Value>+0.9999) Value=+0.9999;
      if(Value<-0.9999) Value=-0.9999;

      FisherBuffer[bar]=0.25*MathLog((1+Value)/(1-Value))+0.5*FisherBuffer[bar-1];
      TriggerBuffer[bar]=FisherBuffer[bar-1];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
