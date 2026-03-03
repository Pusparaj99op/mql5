//+------------------------------------------------------------------+
//|                                                         Flat.mq5 |
//|                                                      Pedro Puado |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
//--- copyright
#property copyright "Pedro Puado"
//--- link to the website of the author
#property link      "http://www.metaquotes.net" 
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- three buffers are used for calculation of drawing of the indicator
#property indicator_buffers 3
//--- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//| Indicator 1 drawing parameters               |
//+----------------------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//--- use gray color for the indicator line
#property indicator_color1  clrGray
//--- the line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- indicator 1 line width is equal to 1
#property indicator_width1  1
//--- bearish indicator label display
#property indicator_label1  "Line"
//+----------------------------------------------+
//| Indicator 2 drawing parameters               |
//+----------------------------------------------+
//--- drawing indicator 2 as a line
#property indicator_type2   DRAW_COLOR_ARROW
//--- the following colors are used as the indicator colors
#property indicator_color2  clrGray,clrBlue,clrMagenta,clrRed
//--- the line of the indicator 2 is a continuous curve
#property indicator_style2  STYLE_SOLID
//--- indicator 2 line width is equal to 3
#property indicator_width2  3
//--- bearish indicator label display
#property indicator_label2  "Arrows"
//+----------------------------------------------+
//| declaring constants                          |
//+----------------------------------------------+
#define RESET 0     // A constant for returning the indicator recalculation command to the terminal
//+----------------------------------------------+
//| declaration of enumerations                  |
//+----------------------------------------------+
enum ENUM_WIDTH // Type of constant
  {
   w_1=0,       // 1
   w_2,         // 2
   w_3,         // 3
   w_4,         // 4
   w_5          // 5
  };
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint Smooth=10;                                // Smoothing period
input ENUM_MA_METHOD      ma_method=MODE_SMA;        // Smoothing type
input ENUM_APPLIED_PRICE  applied_price=PRICE_CLOSE; // Price type
input uint HLRef=100;
input int Shift=0;                                   // Horizontal shift of the indicator in bars
input uint ExtraHighLevel=60;                        // Maximum trend level
input uint HighLevel=40;                             // Strong trend level
input uint LowLevel=20;                              // Weak trend level
input ENUM_LINE_STYLE LevelStyle=STYLE_DASHDOTDOT;   // Style of level lines
input color LevelColor=clrBlue;                      // Color of levels
input ENUM_WIDTH LevelWidth=w_1;                     // Width of levels
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double Ind1Buffer[];
double Ind2Buffer[];
double ColorInd2Buffer[];
//--- declaration of integer variables for the indicators handles
int Ind_Handle;
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of global variables
int Count[];
double Value[];
//+------------------------------------------------------------------+
//| Recalculation of position of the newest element in the array     |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[],// Return the current value of the price series by reference
                          int Size)
  {
//---
   int numb,Max1,Max2;
   static int count=1;

   Max2=Size;
   Max1=Max2-1;

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//---  
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(2*Smooth);
//--- getting the handle of the iStdDev indicator
   Ind_Handle=iStdDev(NULL,0,Smooth,0,ma_method,applied_price);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the iStdDev indicator");
      return(INIT_FAILED);
     }
//--- memory distribution for variables' arrays  
   ArrayResize(Count,HLRef);
   ArrayResize(Value,HLRef);
   ArrayInitialize(Count,0);
   ArrayInitialize(Value,0.0);
//--- indexing elements in the array as timeseries
   ArraySetAsSeries(Value,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,Ind1Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Ind1Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,Ind2Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Ind2Buffer,true);
//--- setting a dynamic array as a color index buffer   
   SetIndexBuffer(2,ColorInd2Buffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorInd2Buffer,true);
//--- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- shifting the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- shifting the starting point of calculation of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- shifting the indicator 1 horizontally
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//--- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Flat( ",Smooth,", ",HLRef,", ",Shift," )");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- indicator levels drawing parameters
   IndicatorSetInteger(INDICATOR_LEVELS,3);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,ExtraHighLevel);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,HighLevel);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,LowLevel);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,LevelColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,LevelStyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,0,LevelWidth);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,LevelColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,LevelStyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,1,LevelWidth);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,LevelColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,LevelStyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,2,LevelWidth);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &Time[],
                const double &Open[],
                const double& High[],     // price array of maximums of price for the indicator calculation
                const double& Low[],      // price array of minimum of price for the indicator calculation
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(BarsCalculated(Ind_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//--- declarations of local variables 
   int to_copy,limit,bar;
   double Std[],Sum,sStd,HH,LL,Range;
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(Std,true);
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=int(rates_total-1-Smooth);   // starting index for the calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }
   to_copy=int(limit+1+Smooth);
//--- copy newly appeared data in the arrays
   if(CopyBuffer(Ind_Handle,0,0,to_copy,Std)<=0) return(RESET);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Sum=0;
      for(int iii=0; iii<int(Smooth); iii++) Sum+=Std[bar+iii];
      sStd=Sum/Smooth;
      //---
      Sum=0;
      for(int iii=0; iii<int(Smooth); iii++) Sum+=MathAbs((Std[bar+iii]-sStd)*2);
      Value[Count[0]]=MathSqrt(Sum/Smooth);
      //---
      HH=Value[ArrayMaximum(Value,0,HLRef)];
      LL=Value[ArrayMinimum(Value,0,HLRef)];
      //---
      Range=HH-LL;
      if(Range) Ind1Buffer[bar]=100*(Value[Count[0]]-LL)/Range;
      else Ind1Buffer[bar]=100.0;
      Ind2Buffer[bar]=Ind1Buffer[bar];
      if(bar) Recount_ArrayZeroPos(Count,HLRef);
     }
//--- main cycle of the indicator coloring
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ColorInd2Buffer[bar]=1;
      if(Ind1Buffer[bar]>ExtraHighLevel) ColorInd2Buffer[bar]=3;
      else if(Ind1Buffer[bar]>HighLevel) ColorInd2Buffer[bar]=2;
      else if(Ind1Buffer[bar]<LowLevel)  ColorInd2Buffer[bar]=0;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
