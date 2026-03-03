//+------------------------------------------------------------------+ 
//|                                                  i-DayOfWeek.mq5 | 
//|                          Copyright © 2007, Kim Igor V. aka KimIV | 
//|                                              http://www.kimiv.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2007, Kim Igor V. aka KimIV"
#property link "http://www.kimiv.ru"
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- number of indicator buffers is 2
#property indicator_buffers 2 
//--- one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Indicator drawing parameters   |
//+-----------------------------------+
//--- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//--- the color of the indicator
#property indicator_color1  clrLightSkyBlue
//--- displaying the indicator label
#property indicator_label1  "i-DayOfWeek"
//+-----------------------------------+
//| declaration of constants          |
//+-----------------------------------+
#define RESET 0    // A constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//| declaration of enumerations       |
//+-----------------------------------+
enum dayOfWeek
  {
   Sunday=0,         // Sunday
   Monday=1,         // Monday
   Tuesday=2,        // Tuesday
   Wednesday=3,      // Wednesday
   Thursday=4,       // Thursday
   Friday=5,         // Friday
   Saturday=6        // Saturday
  };
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input dayOfWeek NumberDayOfWeek=Friday;   // Number for the day of the week
//+-----------------------------------+
//--- declaration of integer variables of data starting point
int  min_rates_total;
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double ExtABuffer[];
double ExtBBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=10;
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtABuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtABuffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,ExtBBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtBBuffer,true);
//--- shift the beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"i-DayOfWeek("+EnumToString(NumberDayOfWeek)+")");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- initialization end
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
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total) return(0);
//--- declaration of integer variables
   int limit;
   static int LastCountBar;
   double iHigh[1],iLow[1];
//--- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
   else limit=LastCountBar+rates_total-prev_calculated;  // starting index for the calculation of the new bars only
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(Time,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
//--- main calculation loop of the indicator
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      MqlDateTime tm0,tm1;
      TimeToStruct(Time[bar],tm0);
      TimeToStruct(Time[bar+1],tm1);
      //---
      if(tm0.day_of_week==NumberDayOfWeek)
        {
         //--- copy newly appeared data in the arrays
         if(CopyLow(Symbol(),PERIOD_D1,Time[bar],1,iLow)<=0) return(RESET);
         if(CopyHigh(Symbol(),PERIOD_D1,Time[bar],1,iHigh)<=0) return(RESET);
         //---
         if(tm1.day_of_week!=NumberDayOfWeek) LastCountBar=bar;
         //---
         ExtABuffer[bar]=iHigh[0];
         ExtBBuffer[bar]=iLow[0];
        }
      else
        {
         ExtABuffer[bar]=0.0;
         ExtBBuffer[bar]=0.0;
        }
     }
//---    
   return(rates_total);
  }
//+------------------------------------------------------------------+
