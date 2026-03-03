//+---------------------------------------------------------------------+ 
//|                                                        Fish_HTF.mq5 | 
//|                                  Copyright © 2012, Nikolay Kositsin | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
#property copyright "Copyright © 2012, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//--- indicator version
#property version   "1.00"
#property description "Fish"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- number of indicator buffers is 2
#property indicator_buffers 2 
//--- one plot is used
#property indicator_plots   1
//+-------------------------------------+
//| Declaration of constants            |
//+-------------------------------------+
#define RESET 0                 // A constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME "Fish"   // A constant for the indicator name
#define SIZE 1                  // A constant for the number of calls of the CountIndicator function in the code
//+-------------------------------------+
//| Indicator drawing parameters        |
//+-------------------------------------+
//--- drawing indicator as a four-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//--- the following colors are used in the four color histogram
#property indicator_color1 clrDarkOrange,clrViolet,clrGray,clrDeepSkyBlue,clrLimeGreen
//--- Indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//--- indicator line width is 2
#property indicator_width1 2
#property indicator_label1  "Fish HTF"
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4;  // Indicator chart period (timeframe)
//+-------------------------------------+
//| Indicator input parameters          |
//+-------------------------------------+
input   uint period=10;
input int    Shift=0;                       // Horizontal shift of the indicator in bars
//+-------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double IndBuffer[];
double ColorIndBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int Ind_Handle;
//+------------------------------------------------------------------+
//| Getting a timeframe as a string                                  |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- checking correctness of the chart periods
   if(!TimeFramesCheck(INDICATOR_NAME,TimeFrame)) return(INIT_FAILED);
//--- initialization of variables 
   min_rates_total=int(period*(PeriodSeconds(TimeFrame)/PeriodSeconds(PERIOD_CURRENT)+1));
//--- getting the handle of the Fish indicator
   Ind_Handle=iCustom(Symbol(),TimeFrame,"Fish",period);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of Fish");
      return(INIT_FAILED);
     }
//--- Initialize indicator buffers
   IndInit(0,IndBuffer,0.0,min_rates_total,Shift);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_DATA);
   ArraySetAsSeries(ColorIndBuffer,true);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
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
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(time,true);
//---
   if(!CountIndicator(0,NULL,TimeFrame,Ind_Handle,0,IndBuffer,1,ColorIndBuffer,time,rates_total,prev_calculated,min_rates_total))
      return(RESET);
//---     
   return(rates_total);
  }
//---
//+------------------------------------------------------------------+
//| Indicator buffer initialization                                  |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[],double Empty_Value,int Draw_Begin,int nShift)
  {
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(Number,Buffer,INDICATOR_DATA);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//--- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Buffer,true);
//---
  }
//+------------------------------------------------------------------+
//| CountLine                                                        |
//+------------------------------------------------------------------+
bool CountIndicator(uint     Numb,            // The number of the CountLine function in the list in the indicator code (starting number - 0)
                    string   Symb,            // Chart symbol
                    ENUM_TIMEFRAMES TFrame,   // Chart period
                    int      IndHandle,       // The handle of the processed indicator
                    uint     BuffNumb,        // The number of the buffer of the processed indicator
                    double&  IndBuf[],        // receiving buffer of the indicator
                    uint     ColorBuffNumb,   // The number of the buffer of the processed indicator
                    double&  ColorIndBuf[],   // Receiving color buffer of the indicator
                    const datetime& iTime[],  // Timeseries of time
                    const int Rates_Total,    // Amount of history in bars on the current tick
                    const int Prev_Calculated,// amount of history in bars at the previous tick
                    const int Min_Rates_Total)// minimum amount of history in bars for calculation
  {
//---
   static int LastCountBar[SIZE];
   datetime IndTime[1];
   int limit;
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=Rates_Total-Min_Rates_Total-1; // Starting index for calculation of all bars
      LastCountBar[Numb]=limit;
     }
   else limit=LastCountBar[Numb]+Rates_Total-Prev_Calculated; // Starting index for calculation of new bars 
//--- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- reset the contents of the indicator buffers for calculation
      IndBuf[bar]=0.0;
      //--- Copy new data to the IndTime array
      if(CopyTime(Symbol(),TFrame,iTime[bar],1,IndTime)<=0) return(RESET);

      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double Arr[1],CArr[1];
         //--- Copy new data to the Arr array
         if(CopyBuffer(IndHandle,BuffNumb,iTime[bar],1,Arr)<=0) return(RESET);
         if(CopyBuffer(IndHandle,ColorBuffNumb,iTime[bar],1,CArr)<=0) return(RESET);

         IndBuf[bar]=Arr[0];
         ColorIndBuf[bar]=CArr[0];
        }
      else
        {
         IndBuf[bar]=IndBuf[bar+1];
         ColorIndBuf[bar]=ColorIndBuf[bar+1];
        }
     }
//---     
   return(true);
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(string IndName,
                     ENUM_TIMEFRAMES TFrame) //Indicator chart period (timeframe)
  {
//--- Checking correctness of the chart periods
   if(TFrame<Period() && TFrame!=PERIOD_CURRENT)
     {
      Print("Chart period for the "+IndName+" indicator cannot be less than the period of the current chart!");
      Print ("You must change the indicator input parameters!");
      return(RESET);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
