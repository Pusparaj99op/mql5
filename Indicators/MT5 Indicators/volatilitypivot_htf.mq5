//+------------------------------------------------------------------+ 
//|                                          VolatilityPivot_HTF.mq5 | 
//|                               Copyright © 2013, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2013, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//--- indicator version
#property version   "1.61"
#property description "The VolatilityPivot indicator with timeframe selection option available in input parameters"
//--- drawing the indicator in the main window
#property indicator_chart_window
//--- number of indicator buffers 4
#property indicator_buffers 4 
//--- four plots are used
#property indicator_plots   4
//+----------------------------------------------+
//| declaration of constants                     |
//+----------------------------------------------+
#define RESET 0                             // A constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME " VolatilityPivot"   // A constant for the indicator name
#define SIZE  1                             // A constant for the number of calls of the CountIndicator function in the code
#define EMPTYVALUE EMPTY_VALUE              // A constant for undisplayed indicator values
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//--- blue color is used for the indicator line
#property indicator_color1  clrBlue
//--- the indicator 1 line is a dot-dash one
#property indicator_style1  STYLE_DASHDOTDOT
//--- indicator 1 line width is equal to 2
#property indicator_width1  2
//---- displaying of the the indicator label
#property indicator_label1  "Upper VolatilityPivot"
//+----------------------------------------------+
//|  Drawing parameters of the bearish indicator |
//+----------------------------------------------+
//--- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//--- HotPink color is used for the indicator line
#property indicator_color2  clrHotPink
//--- the indicator 2 line is a dot-dash one
#property indicator_style2  STYLE_DASHDOTDOT
//--- indicator 2 line width is equal to 2
#property indicator_width2  2
//---- displaying of the the indicator label
#property indicator_label2  "Lower VolatilityPivot"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//--- drawing the indicator 3 as a label
#property indicator_type3   DRAW_ARROW
//--- DeepSkyBlue color is used for the indicator
#property indicator_color3  clrDeepSkyBlue
//--- indicator 3 width is equal to 4
#property indicator_width3  4
//--- displaying the indicator label
#property indicator_label3  "Buy VolatilityPivot"
//+----------------------------------------------+
//|  Drawing parameters of the bearish indicator |
//+----------------------------------------------+
//--- drawing the indicator 4 as a label
#property indicator_type4   DRAW_ARROW
//--- red color is used for the indicator
#property indicator_color4  clrRed
//--- indicator 4 width is equal to 4
#property indicator_width4  4
//--- displaying the indicator label
#property indicator_label4  "Sell VolatilityPivot"
//+----------------------------------------------+
//|  declaration of enumeration                     |
//+----------------------------------------------+
enum Mode_
  {
   Mode_ATR=0,   //ATR
   Mode_Price    //price deviation
  };
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4;  // Indicator chart period
input uint   atr_range=100;
input uint   ima_range=10;
input double atr_factor=3;
input Mode_  Mode=Mode_ATR;
input  uint  DeltaPrice=200;
input int    Shift=0;  // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double Ind1Buffer[];
double Ind2Buffer[];
double Ind3Buffer[];
double Ind4Buffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of integer variables for the indicators handles
int Ind_Handle;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- checking correctness of the chart periods
   if(!TimeFramesCheck(INDICATOR_NAME,TimeFrame)) return(INIT_FAILED);
//--- initialization of variables 
   min_rates_total=2;
//--- getting the handle of the VolatilityPivot indicator
   Ind_Handle=iCustom(Symbol(),TimeFrame,"VolatilityPivot",atr_range,ima_range,atr_factor,Mode,DeltaPrice,0);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get the handle of VolatilityPivot");
      return(INIT_FAILED);
     }
//--- Initialize indicator buffers
   IndInit(0,Ind1Buffer,EMPTYVALUE,min_rates_total,Shift);
   IndInit(1,Ind2Buffer,EMPTYVALUE,min_rates_total,Shift);
   IndInit(2,Ind3Buffer,EMPTYVALUE,min_rates_total,Shift);
   IndInit(3,Ind4Buffer,EMPTYVALUE,min_rates_total,Shift);
//--- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,118);
   PlotIndexSetInteger(3,PLOT_ARROW,118);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",EnumToString(TimeFrame),")");
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
   if(!CountIndicator(0,Symbol(),TimeFrame,Ind_Handle,
      0,Ind1Buffer,1,Ind2Buffer,2,Ind3Buffer,3,Ind4Buffer,
      time,rates_total,prev_calculated,min_rates_total)) return(RESET);
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
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//--- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Buffer,true);
//---
  }
//+------------------------------------------------------------------+
//| CountIndicator                                                   |
//+------------------------------------------------------------------+
bool CountIndicator(uint     Numb,            // The number of the CountLine function in the list in the indicator code (starting number - 0)
                    string   Symb,            // Chart symbol
                    ENUM_TIMEFRAMES TFrame,   // Chart period
                    int      IndHandle,       // The handle of the processed indicator
                    uint     UpBuffNumb,      // The number of the buffer of the processed indicator for an uptrend
                    double&  UpIndBuf[],      // Receiving buffer of the indicator for an uptrend
                    uint     DnBuffNumb,      // The number of the buffer of the processed indicator for a downtrend
                    double&  DnIndBuf[],      // Receiving buffer of the indicator for a downtrend
                    uint     BuyBuffNumb,     // The number of the buffer of the processed indicator for buy signals
                    double&  BuyIndBuf[],     // The receiving buffer of the indicator for buy signals
                    uint     SellBuffNumb,    // The number of the buffer of the processed indicator for sell signals
                    double&  SellIndBuf[],    // The receiving buffer of the indicator for sell signals
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
      UpIndBuf[bar]=EMPTYVALUE;
      DnIndBuf[bar]=EMPTYVALUE;
      BuyIndBuf[bar]=EMPTYVALUE;
      SellIndBuf[bar]=EMPTYVALUE;
      //--- Copy new data to the IndTime array
      if(CopyTime(Symbol(),TFrame,iTime[bar],1,IndTime)<=0) return(RESET);
      //---
      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double Arr[1];
         //--- Copy new data to the Arr array
         if(CopyBuffer(IndHandle,UpBuffNumb,iTime[bar],1,Arr)<=0) return(RESET); UpIndBuf[bar]=Arr[0];
         if(CopyBuffer(IndHandle,DnBuffNumb,iTime[bar],1,Arr)<=0) return(RESET); DnIndBuf[bar]=Arr[0];
         if(CopyBuffer(IndHandle,BuyBuffNumb,iTime[bar],1,Arr)<=0) return(RESET); BuyIndBuf[bar]=Arr[0];
         if(CopyBuffer(IndHandle,SellBuffNumb,iTime[bar],1,Arr)<=0) return(RESET); SellIndBuf[bar]=Arr[0];
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
                     ENUM_TIMEFRAMES TFrame) // Indicator 1 chart period (smallest timeframe)
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
