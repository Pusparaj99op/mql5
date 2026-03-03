//+------------------------------------------------------------------+
//|                                               DailyTurnPoint.mq5 | 
//|                                            Copyright © 2012, XXX | 
//|                                http://www.forex-instruments.info | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2012, Nikolay Kositsin"
#property link "http://www.forex-instruments.info"
#property description "Daily pivot point"
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers
#property indicator_buffers 1 
//---- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//---- blue-violet color is used as the color of the indicator line
#property indicator_color1 clrBlueViolet
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "DailyTurnPoint"

//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input int Shift=0; // horizontal shift of the indicator in bars
input int PriceShift=0; // vertical shift of the indicator in points
//+-----------------------------------+

//---- declaration of a dynamic array that further 
// be used as an indicator buffer
double IndBuffer[];

//---- Declaration of the average vertical shift value variable
double dPriceShift;
//---- Declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+   
//| DailyTurnPoint indicator initialization function                 | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=1+PeriodSeconds(PERIOD_D1)/PeriodSeconds(PERIOD_CURRENT);

//---- Initialization of the vertical shift
   dPriceShift=_Point*PriceShift;

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- shifting the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- shifting the starting point of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting values of the indicator that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"DailyTurnPoint");

//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- end of initialization
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   Comment("");
//----
  }
//+------------------------------------------------------------------+ 
//| DailyTurnPoint iteration function                                | 
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
//---- checking correctness of the chart period  
   if(Period()>=PERIOD_D1)
     {
      Comment("WARNING: Invalid timeframe! Valid value < D1!");
      return(0);
     }

//---- checking for the sufficiency of the number of bars for the calculation
   if(rates_total<min_rates_total) return(0);

//---- Declaration of variables  
   static double day_high; // daily high 
   static double day_low; // daily low 
   double yesterday_high=0; // maximum price of the previous day 
   double yesterday_low=0; // minimum price of the previous day 
   double yesterday_close=0; // close price of the previous day 
   double P=0.0,S,R;
   int first,bar;

//---- calculation of the starting number first for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) //checking for the first start of calculation of an indicator
     {
      first=min_rates_total; // starting index for calculation of all bars
      day_high=high[first-1];
      day_low=low[first-1];
      yesterday_high=day_high;
      yesterday_low=day_low;
      yesterday_close=close[first-1];
     }
   else first=prev_calculated-1; // starting index for the calculation of new bars

//---- Main calculation loop of the indicator
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      MqlDateTime tm0,tm1;
      TimeToStruct(time[bar],tm0);
      TimeToStruct(time[bar-1],tm1);

      if(tm1.day!=tm0.day)
        {
         yesterday_close= close[bar-1];
         yesterday_high = day_high;
         yesterday_low=day_low;
         P = (yesterday_high + yesterday_low + yesterday_close)/3;
         R = yesterday_high;
         S = yesterday_low;

         // as the new day began, then initialize max. and min. of (already) current day 
         day_high= high[bar];
         day_low = low[bar];
        }

      // continue to accumulate data 
      day_high= MathMax(day_high,high[bar]);
      day_low = MathMin(day_low,low[bar]);

      // draw pivot-line by value calculated by yesterday parameters        
      IndBuffer[bar]=P+dPriceShift;
     }

   P=(yesterday_high+yesterday_low+yesterday_close)/3;
   R = yesterday_high;
   S = yesterday_low;

   Comment("Current H=",DoubleToString(R,_Digits),", L=",DoubleToString(S,_Digits)
           ,", HLÑ/3=",DoubleToString(P,_Digits),", H-L=",DoubleToString((R-S)/_Point,_Digits));
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
