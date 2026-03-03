//+----------------------------------------------------------------------+
//|                                                          Impulse.mq5 | 
//|                                                Copyright © 2006, Gep | 
//| http://www.arkworldmarket.ru/forum/showthread.php?t=966&page=2&pp=10 | 
//+----------------------------------------------------------------------+ 
#property copyright "Copyright © 2006, Gep"
#property link "http://www.arkworldmarket.ru/forum/showthread.php?t=966&page=2&pp=10"
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- number of indicator buffers
#property indicator_buffers 1 
//--- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//--- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//--- DodgerBlue color is used for the indicator line color
#property indicator_color1 clrDodgerBlue
//--- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- indicator line width is 2
#property indicator_width1  2
//--- displaying the indicator label
#property indicator_label1  "Impulse"
//+----------------------------------------------+
//| Parameters of displaying horizontal levels   |
//+----------------------------------------------+
#property indicator_level1 0.0
#property indicator_levelcolor clrMagenta
#property indicator_levelstyle STYLE_SOLID
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint Length=14;  // Period of calculation               
input int  Shift=0;    // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//--- declaration of a dynamic array that
//--- will be used as an indicator buffer
double IndBuffer[];
double LenPoint;
//--- declaration of integer variables for the start of data calculation
int min_rates_total,Len;
//+------------------------------------------------------------------+   
//| Impulse indicator initialization function                        | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//--- initialization of variables of data calculation start
   min_rates_total=int(Length+1);
   LenPoint=Length*_Point;
   Len=int(Length-1);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- shifting the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//--- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Impulse(",Length,", ",Shift,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- initialization end
  }
//+------------------------------------------------------------------+ 
//| Impulse iteration function                                       | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total) return(0);
//--- declaration of integer variables and getting already calculated bars
   int first,bar;
//--- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
      first=min_rates_total;     // starting index for calculation of all bars
   else first=prev_calculated-1; // starting number for calculation of new bars
//--- main indicator calculation loop
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      double dif=0;
      for(int i=bar-Len; i<=bar; i++) dif+=close[i]-open[i];
      IndBuffer[bar]=MathRound(dif/LenPoint);
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
