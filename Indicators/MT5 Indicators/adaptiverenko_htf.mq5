//+------------------------------------------------------------------+ 
//|                                            AdaptiveRenko_HTF.mq5 | 
//|                               Copyright © 2013, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2013, Nikolay Kositsin"
#property link "arria@mail.redcom.ru"
//--- indicator version
#property version   "1.00"
#property description "AdaptiveRenko with the timeframe selection option available in input parameters"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//--- number of indicator buffers 4
#property indicator_buffers 4 
//--- three plots are used
#property indicator_plots   3
//+----------------------------------------------+
//| declaring constants                          |
//+----------------------------------------------+
#define RESET 0                        // A constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME "AdaptiveRenko" // A constant for the indicator name
#define SIZE 1                         // A constant for the number of calls of the CountIndicator function in the code
//+----------------------------------------------+
//| Indicator 1 drawing parameters               |
//+----------------------------------------------+
//--- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//--- the following colors are used as the indicator colors
#property indicator_color1  clrPaleTurquoise
//--- displaying the indicator label
#property indicator_label1 "Channel"
//+----------------------------------------------+
//| Indicator 2 drawing parameters               |
//+----------------------------------------------+
//--- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//--- lime color is used for the indicator
#property indicator_color2  clrLime
//--- Indicator line is a solid one
#property indicator_style2 STYLE_SOLID
//--- indicator 2 width is equal to 4
#property indicator_width2  4
//--- display of the indicator bullish label
#property indicator_label2  "Support"
//+----------------------------------------------+
//| Indicator 3 drawing parameters               |
//+----------------------------------------------+
//--- drawing indicator 3 as a line
#property indicator_type3   DRAW_LINE
//--- Red color is used as the indicator color
#property indicator_color3  clrRed
//--- Indicator line is a solid one
#property indicator_style3 STYLE_SOLID
//--- indicator 3 width is equal to 4
#property indicator_width3  4
//--- display of the bearish indicator label
#property indicator_label3 "Resistance"
//+----------------------------------------------+
//| declaration of enumeration                   |
//+----------------------------------------------+
enum IndMode  //Constant type
  {
   ATR,       //ATR indicator
   StDev      //StDev indicator
  };
//+----------------------------------------------+
//| declaration of enumeration                   |
//+----------------------------------------------+
enum PriceMode //Constant type
  {
   HighLow_,   //High/Low
   Close_      //Close
  };
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4;  // Indicator chart period (timeframe)
input double K=1;                           // Modifier
input IndMode Indicator=ATR;                // An indicator for calculation
input uint VltPeriod=10;                    // Volatility period
input PriceMode Price=Close_;               // Price calculation method
input uint WideMin=2;                       // Minimum brick width in points
input int Shift=0;                          // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double UpIndBuffer[];
double DnIndBuffer[];
double UpChIndBuffer[];
double DnChIndBuffer[];
//--- declaration of integer variables of data starting point
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int Ind_Handle;
//+------------------------------------------------------------------+
//|  Getting a timeframe as string                                   |
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
//--- getting the handle of the AdaptiveRenko indicator
   Ind_Handle=iCustom(Symbol(),TimeFrame,"AdaptiveRenko",K,Indicator,VltPeriod,Price,WideMin);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of the AdaptiveRenko indicator");
      return(INIT_FAILED);
     }
//--- initialize indicator buffers
   IndInit(0,UpChIndBuffer,INDICATOR_DATA);
   IndInit(1,DnChIndBuffer,INDICATOR_DATA);
   IndInit(2,UpIndBuffer,INDICATOR_DATA);
   IndInit(3,DnIndBuffer,INDICATOR_DATA);
//--- initialization of indicators
   PlotInit(0,0.0,0,Shift);
   PlotInit(1,0.0,0,Shift);
   PlotInit(2,0.0,0,Shift);
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
   if(!CountIndicator(0,NULL,TimeFrame,Ind_Handle,
      0,UpChIndBuffer,1,DnChIndBuffer,2,UpIndBuffer,3,DnIndBuffer,
      time,rates_total,prev_calculated,min_rates_total))
      return(RESET);
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
bool CountIndicator(uint     Numb,            // The number of the CountLine function in the list in the indicator code (starting number - 0)
                    string   Symb,            // Chart symbol
                    ENUM_TIMEFRAMES TFrame,   // Chart period
                    int      IndHandle,       // The handle of the processed indicator
                    uint     UpChBuffNumb,    // The index of the upper buffer of the processed indicator for the cloud 
                    double&  UpChIndBuf[],    // Receiving upper buffer of the indicator for the cloud
                    uint     DnChBuffNumb,    // The index of the lower buffer of the processed indicator for the cloud
                    double&  DnChIndBuf[],    // Receiving lower buffer of the indicator for the cloud
                    uint     UpBuffNumb,      // The index of the buffer of the processed indicator
                    double&  UpIndBuf[],      // Receiving upper buffer of the indicator
                    uint     DnBuffNumb,      // The index of the buffer of the processed indicator
                    double&  DnIndBuf[],      // Receiving lower buffer of the indicator
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
      limit=Rates_Total-Min_Rates_Total-1; // starting index for the calculation of all bars
      LastCountBar[Numb]=limit;
     }
   else limit=LastCountBar[Numb]+Rates_Total-Prev_Calculated; // starting index for calculation of new bars 
//--- main calculation loop of the indicator
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- zero out the contents of the indicator buffers for the calculation
      UpChIndBuf[bar]=0.0;
      DnChIndBuf[bar]=0.0;
      UpIndBuf[bar]=0.0;
      DnIndBuf[bar]=0.0;
      //--- copy new data to the IndTime array
      if(CopyTime(Symbol(),TFrame,iTime[bar],1,IndTime)<=0) return(RESET);
      //---
      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double UpChArr[1],DnChArr[1],UpArr[1],DnArr[1];
         //--- copy newly appeared data in the arrays
         if(CopyBuffer(IndHandle,UpChBuffNumb,iTime[bar],1,UpChArr)<=0) return(RESET);
         if(CopyBuffer(IndHandle,DnChBuffNumb,iTime[bar],1,DnChArr)<=0) return(RESET);
         if(CopyBuffer(IndHandle,UpBuffNumb,iTime[bar],1,UpArr)<=0) return(RESET);
         if(CopyBuffer(IndHandle,DnBuffNumb,iTime[bar],1,DnArr)<=0) return(RESET);
         //---
         UpChIndBuf[bar]=UpChArr[0];
         DnChIndBuf[bar]=DnChArr[0];
         UpIndBuf[bar]=UpArr[0];
         DnIndBuf[bar]=DnArr[0];
        }
      else
        {
         UpChIndBuf[bar]=UpChIndBuf[bar+1];
         DnChIndBuf[bar]=DnChIndBuf[bar+1];
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
