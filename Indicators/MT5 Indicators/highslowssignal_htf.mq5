//+------------------------------------------------------------------+ 
//|                                          HighsLowsSignal_HTF.mq5 | 
//|                               Copyright © 2014, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2014, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//--- indicator version
#property version   "1.60"
#property description "The HighsLowsSignal indicator with the timeframe selection option available in input parameters"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- number of indicator buffers is 2
#property indicator_buffers 2
//--- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//| declaration of constants                     |
//+----------------------------------------------+
#define RESET 0                          // A constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME "HighsLowsSignal" // A constant for the indicator name
#define SIZE 1                           // A constant for the number of calls of the CountIndicator function in the code
#define EMPTYVALUE 0.0                   // A constant for undisplayed indicator values
//+----------------------------------------------+
//| Indicator 1 drawing parameters               |
//+----------------------------------------------+
//--- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//--- pink is used for the color of the bearish indicator line
#property indicator_color1  clrMagenta
//--- indicator 1 line width is equal to 5
#property indicator_width1  5
//--- displaying the indicator label
#property indicator_label1  "HighsLowsSignal Sell"
//+----------------------------------------------+
//| Indicator 2 drawing parameters               |
//+----------------------------------------------+
//--- drawing the indicator 2 as a symbol
#property indicator_type2   DRAW_ARROW
//--- light blue is used as the color of the bullish line of the indicator
#property indicator_color2  clrBlue
//--- indicator 2 line width is equal to 5
#property indicator_width2  5
//--- displaying the indicator label
#property indicator_label2  "HighsLowsSignal Buy"
//+-------------------------------------+
//| Indicator input parameters                   |
//+-------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4; // Indicator chart period
input uint HowManyCandles=3;               // The number of candlesticks of a directed price change
input int  Shift=0;                        // Horizontal shift of the indicator in bars
input uint SellSymb=171;                   // Sell symbol
input uint BuySymb=171;                    // Buy symbol
//+-------------------------------------+
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double DnBuffer[];
double UpBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int Ind_Handle;
//+------------------------------------------------------------------+
//|  Getting a timeframe as a line                                   |
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
   min_rates_total=2;
//--- getting the handle of the HighsLowsSignal indicator
   Ind_Handle=iCustom(Symbol(),TimeFrame,"HighsLowsSignal",HowManyCandles);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of HighsLowsSignal");
      return(INIT_FAILED);
     }
//--- Initialize indicator buffers
   IndInit(0,DnBuffer,EMPTYVALUE,min_rates_total,Shift,SellSymb);
   IndInit(1,UpBuffer,EMPTYVALUE,min_rates_total,Shift,BuySymb);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),", ",HowManyCandles,")");
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
   if(BarsCalculated(Ind_Handle)<Bars(Symbol(),TimeFrame)) return(prev_calculated);
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(time,true);
//---
   if(!CountIndicator(0,NULL,TimeFrame,Ind_Handle,0,DnBuffer,1,UpBuffer,time,rates_total,prev_calculated,min_rates_total)) return(RESET);
//---     
   return(rates_total);
  }
//---
//+------------------------------------------------------------------+
//| Indicator buffer initialization                                  |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[],double Empty_Value,int Draw_Begin,int nShift,int Symb)
  {
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(Number,Buffer,INDICATOR_DATA);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//--- indicator symbol
   PlotIndexSetInteger(Number,PLOT_ARROW,Symb);
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
                    uint     BuffNumb1,       // The number of the buffer of the processed indicator
                    double&  IndBuf1[],       // Receiving buffer of the indicator
                    uint     BuffNumb2,       // The number of the buffer of the processed indicator
                    double&  IndBuf2[],       // Receiving buffer of the indicator
                    const datetime& iTime[],  // Timeseries of time
                    const int Rates_Total,    // amount of history in bars on the current tick
                    const int Prev_Calculated,// amount of history in bars at the previous tick
                    const int Min_Rates_Total)// minimum amount of history in bars for calculation
  {
//---
   static int LastCountBar[SIZE];
   datetime IndTime[1];
   int limit;
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=Rates_Total-Min_Rates_Total-1; // starting index for calculation of all bars
      LastCountBar[Numb]=limit;
     }
   else limit=LastCountBar[Numb]+Rates_Total-Prev_Calculated; // Starting index for calculation of new bars 
//--- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- reset the contents of the indicator buffers for calculation
      IndBuf1[bar]=EMPTYVALUE;
      IndBuf2[bar]=EMPTYVALUE;
      //--- Copy new data to the IndTime array
      if(CopyTime(Symbol(),TFrame,iTime[bar],1,IndTime)<=0) return(RESET);
      //---
      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double Arr1[1],Arr2[1];
         //--- Copy new data to the Arr array
         if(CopyBuffer(IndHandle,BuffNumb1,iTime[bar],1,Arr1)<=0) return(RESET);
         if(CopyBuffer(IndHandle,BuffNumb2,iTime[bar],1,Arr2)<=0) return(RESET);
         IndBuf1[bar]=Arr1[0];
         IndBuf2[bar]=Arr2[0];
        }
     }
//---     
   return(true);
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(string IndName,
                     ENUM_TIMEFRAMES TFrame) //Indicator chart period
  {
//--- checking correctness of the chart periods
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
