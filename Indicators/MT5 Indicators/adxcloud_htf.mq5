//+------------------------------------------------------------------+ 
//|                                                 ADXCloud_HTF.mq5 | 
//|                               Copyright © 2013, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2013, Nikolay Kositsin"
#property link "arria@mail.redcom.ru"
//--- indicator version
#property version   "1.60"
#property description "ADXCloud with the timeframe selection option available in input parameters"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- number of indicator buffers is 2
#property indicator_buffers 2 
//--- one plot is used
#property indicator_plots   1
//+-------------------------------------+
//| Declaration of constants            |
//+-------------------------------------+
#define RESET 0                    // A constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME "ADXCloud"  // A constant for the indicator name
#define SIZE 1                     // A constant for the number of calls of the CountIndicator function in the code
//+-------------------------------------+
//| Indicator drawing parameters        |
//+-------------------------------------+
//--- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//--- the following colors are used for the indicator cloud
#property indicator_color1  clrLime,clrRed
//--- displaying the indicator label
#property indicator_label1  "Di Plus; Di Minus"
//+-------------------------------------+
//| Indicator input parameters          |
//+-------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4; // Indicator chart period (timeframe)
input uint   period = 5;
input double alpha1 = 0.25;
input double alpha2 = 0.33;
input int Shift=0;                         // Horizontal shift of the indicator in bars
//+-------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double UpIndBuffer[];
double DnIndBuffer[];
//--- declaration of integer variables of data starting point
int min_rates_total;
//--- declaration of integer variables for the indicator handles
int Ind_Handle;
//+------------------------------------------------------------------+
//| Getting a timeframe as string                                    |
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
//--- getting the handle of the ADXCloud indicator
   Ind_Handle=iCustom(Symbol(),TimeFrame,"ADXCloud",period,alpha1,alpha2);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the ADXCloud indicator");
      return(INIT_FAILED);
     }
//--- initialize indicator buffers
   IndInit(0,UpIndBuffer,INDICATOR_DATA);
   IndInit(1,DnIndBuffer,INDICATOR_DATA);
//--- initialization of indicators
   PlotInit(0,0.0,0,Shift);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
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
   if(!CountIndicator(0,NULL,TimeFrame,Ind_Handle,
     0,UpIndBuffer,1,DnIndBuffer,time,rates_total,prev_calculated,min_rates_total)) return(RESET);
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Indicator buffer initialization                                  |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[],ENUM_INDEXBUFFER_TYPE Type)
  {
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(Number,Buffer,Type);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Buffer,true);
//---
  }
//+------------------------------------------------------------------+
//| Indicator initialization                                         |
//+------------------------------------------------------------------+    
void PlotInit(int Number,double Empty_Value,int Draw_Begin,int nShift)
  {
//--- shift the beginning of indicator drawing
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//--- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//---
  }
//+------------------------------------------------------------------+
//| CountIndicator                                                   |
//+------------------------------------------------------------------+
bool CountIndicator(uint     Numb,            // the number of the CountLine function in the list in the indicator code (starting number - 0)
                    string   Symb,            // chart symbol
                    ENUM_TIMEFRAMES TFrame,   // chart period
                    int      IndHandle,       // the handle of the processed indicator
                    uint     UpBuffNumb,      // the number of the buffer of the processed indicator for the cloud
                    double&  UpIndBuf[],      // receiving upper buffer of the indicator for the cloud
                    uint     DnBuffNumb,      // the number of the buffer of the processed indicator for the cloud
                    double&  DnIndBuf[],      // receiving lower buffer of the indicator for the cloud
                    const datetime& iTime[],  // timeseries of time
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
      limit=Rates_Total-Min_Rates_Total-1; // starting index for the calculation of all bars
      LastCountBar[Numb]=limit;
     }
   else limit=LastCountBar[Numb]+Rates_Total-Prev_Calculated; // starting index for calculation of new bars 
//--- main calculation loop of the indicator
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- copy new data to the IndTime array
      if(CopyTime(Symbol(),TFrame,iTime[bar],1,IndTime)<=0) return(RESET);
      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double UpArr[1],DnArr[1];
         //--- copy newly appeared data in the arrays
         if(CopyBuffer(IndHandle,UpBuffNumb,iTime[bar],1,UpArr)<=0) return(RESET);
         if(CopyBuffer(IndHandle,DnBuffNumb,iTime[bar],1,DnArr)<=0) return(RESET);

         UpIndBuf[bar]=UpArr[0];
         DnIndBuf[bar]=DnArr[0]+0.00000001;
        }
      else
        {
         UpIndBuf[bar]=UpIndBuf[bar+1];
         DnIndBuf[bar]=DnIndBuf[bar+1];
        }
     }
//---     
   return(true);
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(string IndName,
                     ENUM_TIMEFRAMES TFrame) // Indicator chart period (timeframe)
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
