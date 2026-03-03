//+------------------------------------------------------------------+
//|                                                TradeBreakOut.mq5 |
//|                                  Copyright © 2013, Andriy Moraru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013, Andriy Moraru"
#property link      "http://www.earnforex.com"
#property version   "1.0"

#property description "Red line crossing 0 from above is a support breakout signal."
#property description "Green line crossing 0 from below is a resistance breakout signal."

//---- indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers 2
#property indicator_buffers 2
//---- only 2 plots are used
#property indicator_plots   2

//+---------------------------------------------+
//|  declaring constants                        |
//+---------------------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal

//+---------------------------------------------+
//|  Indicator levels drawing parameters        |
//+---------------------------------------------+
//---- drawing the levels as lines
#property indicator_type1   DRAW_LINE
//---- indicator line width is equal to 1
#property indicator_width1 1
//---- selection of levels colors
#property indicator_color1  clrRed
//---- displaying labels of the levels
#property indicator_label1  "Resistance Breakout"

//+---------------------------------------------+
//|  Indicator levels drawing parameters        |
//+---------------------------------------------+
//---- drawing the levels as lines
#property indicator_type2   DRAW_LINE
//---- indicator line width is equal to 1
#property indicator_width2 1
//---- selection of levels colors
#property indicator_color2  clrTeal
//---- displaying labels of the levels
#property indicator_label2  "Support Breakout"
//+----------------------------------------------+
//| Parameters of displaying horizontal levels   |
//+----------------------------------------------+
#property indicator_level1 0.0
#property indicator_levelcolor clrBlue
#property indicator_levelstyle STYLE_SOLID
#property indicator_levelwidth 2
//+----------------------------------------------+
//|  declaration of enumerations                 |
//+----------------------------------------------+
enum price_type
  {
   Close,         // by close prices
   HighLow  // by extremums
  };
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint L = 50;                    // Period
input price_type PriceType = HighLow; // price calculation
//+----------------------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double ExtLineBuffer1[],ExtLineBuffer2[];

//---- Declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+   
//| TradeBreakOut indicator initialization function                  | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=int(L);

//---- setting dynamic arrays as indicator buffers
   SetIndexBuffer(0,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLineBuffer2,INDICATOR_DATA);

//---- set the position, from which the Bollinger Bands drawing starts
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);

//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- indexing the elements in buffers as in timeseries   
   ArraySetAsSeries(ExtLineBuffer1,true);
   ArraySetAsSeries(ExtLineBuffer2,true);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"TradeBreakOut");

//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- end of initialization
  }
//+------------------------------------------------------------------+ 
//| TradeBreakOut iteration function                                 | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
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
//---- checking for the sufficiency of the number of bars for the calculation
   if(rates_total<min_rates_total) return(RESET);

//---- declaration of local variables 
   int limit,bar;
   double HH,LL,HC,LC;

//---- indexing elements in arrays as in timeseries  
   if(PriceType==Close) ArraySetAsSeries(close,true);
   else
     {
      ArraySetAsSeries(high,true);
      ArraySetAsSeries(low,true);
     }

//---- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
      for(bar=rates_total-1; bar>limit && !IsStopped(); bar--)
        {
         ExtLineBuffer1[bar]=0.0;
         ExtLineBuffer2[bar]=0.0;
        }

     }
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars

//---- main cycle of calculation of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {

      if(PriceType==Close)
        {
         HC=close[ArrayMaximum(close,bar,L)];
         LC=close[ArrayMinimum(close,bar,L)];
         ExtLineBuffer2[bar]=(close[bar]-HC)/HC;
         ExtLineBuffer1[bar]=(close[bar]-LC)/LC;
        }
      else
        {
         HH=high[ArrayMaximum(high,bar,L)];
         LL=low[ArrayMinimum(low,bar,L)];
         ExtLineBuffer2[bar]=(high[bar]-HH)/HH;
         ExtLineBuffer1[bar]=(low[bar]-LL)/LL;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
