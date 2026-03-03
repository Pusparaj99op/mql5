//+------------------------------------------------------------------+ 
//|                                                           HL.mq5 | 
//|                                           Copyright © 2007, KCBT | 
//|                              http://www.kcbt.ru/forum/index.php? | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2007, KCBT"
#property link "http://www.kcbt.ru/forum/index.php?"
//--- indicator version
#property version   "1.00"
#property description "Resistance and support levels at a fixed timeframe"
//--- drawing the indicator in the main window
#property indicator_chart_window
//--- number of indicator buffers 3
#property indicator_buffers 3 
//---- three plots are used
#property indicator_plots   3
//+----------------------------------------------+
//| declaration of constants                     |
//+----------------------------------------------+
#define RESET 0     // A constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| Indicator 1 drawing parameters               |
//+----------------------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//--- the color of the indicator
#property indicator_color1  clrTeal
//--- indicator 1 line width is equal to 2
#property indicator_width1  2
//--- displaying the indicator label
#property indicator_label1  "HL Up"
//+----------------------------------------------+
//| Indicator 2 drawing parameters               |
//+----------------------------------------------+
//--- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//--- the color of the indicator
#property indicator_color2  clrDodgerBlue
//--- indicator 2 line width is equal to 2
#property indicator_width2  2
//--- displaying the indicator label
#property indicator_label2  "HL Pivot"
//+----------------------------------------------+
//| Indicator 3 drawing parameters               |
//+----------------------------------------------+
//--- drawing indicator 3 as a line
#property indicator_type3   DRAW_LINE
//--- the color of the indicator
#property indicator_color3  clrMagenta
//--- indicator 2 line width is equal to 2
#property indicator_width3  2
//--- displaying the indicator label
#property indicator_label3  "HL Down"
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_D1; // Chart period for calculating the levels
input bool ShowComment=true;               // Whether to draw comments
input int  Shift=0;                        // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double Ind1Buffer[];
double Ind2Buffer[];
double Ind3Buffer[];
//--- declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- Checking the correctness of the indicator timeframe
   if(!TimeFramesCheck("HL",TimeFrame,Period())) return(INIT_FAILED);
//--- initialization of variables 
   min_rates_total=2;
//--- Initialize indicator buffers
   IndInit(0,Ind1Buffer,0.0,min_rates_total,Shift);
   IndInit(1,Ind2Buffer,0.0,min_rates_total,Shift);
   IndInit(2,Ind3Buffer,0.0,min_rates_total,Shift);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   string shortname;
   StringConcatenate(shortname,"HL(",EnumToString(TimeFrame),")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//---
   Comment("");
//---
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
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
   if(rates_total<min_rates_total) return(RESET);
//--- declaration of integer variables
   int limit,bar;
//--- declaration of variables with a floating point  
   double last_close,last_high,last_low,P,R,S;
   datetime iTime[1];
   static uint LastCountBar;
   static double prev_low,prev_high;
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
      LastCountBar=rates_total;
      prev_low=999999999;
      prev_high=0.0;
     }
   else limit=int(LastCountBar)+rates_total-prev_calculated; // starting index for the calculation of new bars 
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//--- main calculation loop of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Ind1Buffer[bar]=0.0;
      Ind2Buffer[bar]=0.0;
      Ind3Buffer[bar]=0.0;
      //--- copy newly appeared data in the array
      if(CopyTime(Symbol(),TimeFrame,time[bar],1,iTime)<=0) return(RESET);
      //---
      if(time[bar]>=iTime[0] && time[bar+1]<iTime[0])
        {
         LastCountBar=bar;
         Ind1Buffer[bar+1]=0.0;
         Ind2Buffer[bar+1]=0.0;
         Ind3Buffer[bar+1]=0.0;
         //---
         last_close=close[bar+1];
         last_high=prev_high;
         last_low=prev_low;
         P=(last_high+last_low )/2;
         R=last_high;
         S=last_low;
         prev_high=high[bar];
         prev_low=low[bar];
        }
      //---
      prev_high=MathMax(prev_high,high[bar]);
      prev_low=MathMin(prev_low,low[bar]);
      //--- Loading the obtained values in the indicator buffers
      Ind1Buffer[bar]=R;
      Ind2Buffer[bar]=P;
      Ind3Buffer[bar]=S;
     }
//---
   if(ShowComment)
     {
      Comment("Current H=",DoubleToString(R,_Digits),
              ", L=",DoubleToString(S,_Digits),
              ", HL/2=",DoubleToString(P,_Digits),
              ", H-L=",DoubleToString((R-S)/_Point,0));
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Indicator buffer initialization                                  |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[],double Empty_Value,int Draw_Begin,int nShift)
  {
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(Number,Buffer,INDICATOR_DATA);
//--- shift the beginning of indicator drawing
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Buffer,true);
//---
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(string IndName,
                     ENUM_TIMEFRAMES inTFrame,  //Chart period for indicator calculation
                     ENUM_TIMEFRAMES outTFrame) //Indicator chart period
  {
//--- checking correctness of the chart periods
   if(inTFrame<=outTFrame)
     {
      Print("Chart period for indicator "+IndName+" cannot be less than ",GetStringTimeframe(inTFrame));
      return(RESET);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Getting a timeframe as a line                                    |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {
//---
   return(StringSubstr(EnumToString(timeframe),7,-1));
//---
  }
//+------------------------------------------------------------------+
