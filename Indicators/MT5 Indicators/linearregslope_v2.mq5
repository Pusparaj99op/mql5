//+------------------------------------------------------------------+
//|                                            LinearRegSlope_V2.mq5 | 
//|                  Linear regression value  - time series forecast |
//|                       Linear regression value - tsf with Trigger |
//|                                                           mladen |
//|                                                                  |
//|             Modified from Linear regression value - tsf by Toshi |
//|                                  http://toshi52583.blogspot.com/ |
//+------------------------------------------------------------------+
//| Place the SmoothAlgorithms.mqh file                              |
//| to the directory: terminal_data_folder\\MQL5\Include             |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, mladen"
#property link      "mladenfx@gmail.com"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers 2
#property indicator_buffers 2 
//---- only two plots are used
#property indicator_plots   2
//+-----------------------------------+
//|  Indicator 1 drawing parameters   |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//---- dodger blue color is used for the indicator line
#property indicator_color1 DodgerBlue
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "Linear Reg Slope line"
//+-----------------------------------+
//|  Indicator 2 drawing parameters   |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type2   DRAW_LINE
//---- coral color is used for the indicator line
#property indicator_color2 Coral
//---- the indicator line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator label
#property indicator_label2  "Trigger line"
//+-----------------------------------+
//|  CXMA class description           |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//---- declaration of the CXMA class variables from the SmoothAlgorithms.mqh file
CXMA XMA1;
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_      // Type of constant
  {
   PRICE_CLOSE_ = 1,     // Close
   PRICE_OPEN_,          // Open
   PRICE_HIGH_,          // High
   PRICE_LOW_,           // Low
   PRICE_MEDIAN_,        // Median Price (HL/2)
   PRICE_TYPICAL_,       // Typical Price (HLC/3)
   PRICE_WEIGHTED_,      // Weighted Close (HLCC/4)
   PRICE_SIMPLE,         // Simple Price (OC/2)
   PRICE_QUARTER_,       // Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  // TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   // TrendFollow_2 Price 
  };
/*enum Smooth_Method - enumeration is declared in the SmoothAlgorithms.mqh file
  {
   MODE_SMA_,  // SMA
   MODE_EMA_,  // EMA
   MODE_SMMA_, // SMMA
   MODE_LWMA_, // LWMA
   MODE_JJMA,  // JJMA
   MODE_JurX,  // JurX
   MODE_ParMA, // ParMA
   MODE_T3,    // T3
   MODE_VIDYA, // VIDYA
   MODE_AMA,   // AMA
  }; */
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input Smooth_Method SlMethod=MODE_SMA; // Smoothing method
input int SlLength=12;                 // Smoothing depth                    
input int SlPhase=15;                  // Smoothing parameter
input Applied_price_ IPC=PRICE_CLOSE;  // Price constant
input int Shift=0;                     // Horizontal shift of the indicator in bars
input int TriggerShift=1;              // Bar shift for the trigger
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of dynamic arrays that 
//---- will be used as indicator buffers
double RegSlopeBuffer[],TriggerBuffer[];
//---- declaration of global variables
int TriggerShift_,TrigShift,TrigShift_;
double SumX,Divisor;
//---- declaration of dynamic arrays that
//---- will be used as ring buffers
int Count[];
double Smooth[];
//+------------------------------------------------------------------+
//|  Recalculation of position of the newest element in the array    |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[], // return the current value of the price series by the link
                          int Size)     // number of the elements in the ring buffer
  {
//----
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
//----
  }
//+------------------------------------------------------------------+   
//| XMA indicator initialization function                            | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=XMA1.GetStartBars(SlMethod,1,SlPhase)+SlLength+TriggerShift;

//---- setting up alerts for unacceptable values of external variables
   XMA1.XMALengthCheck("SlLength", SlLength);
   XMA1.XMAPhaseCheck("SlPhase", SlPhase, SlMethod);
   if(TriggerShift>SlLength-2)
     {
      Print("TriggerShift input parameter value cannot exceed SlLength-2");
      TrigShift=1;
      TrigShift_=SlLength-2;
     }
   else
     {
      TrigShift=SlLength-1-TriggerShift;
      TrigShift_=TriggerShift;
     }

//---- initialization of variables   
   SumX=SlLength *(SlLength-1)*0.5;
   double SumXSqr=(SlLength-1.0)*SlLength *(2.0*SlLength-1.0)/6.0;
   Divisor=SumX*SumX-SlLength*SumXSqr;
   TriggerShift_=int(min_rates_total);

//---- memory distribution for variables' arrays  
   ArrayResize(Count,SlLength);
   ArrayResize(Smooth,SlLength);

//---- initialization of the variables arrays
   ArrayInitialize(Count,0);
   ArrayInitialize(Smooth,0.0);

//---- set RegSlopeBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,RegSlopeBuffer,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set TriggerBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,TriggerBuffer,INDICATOR_DATA);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- initializations of a variable for the indicator short name
   string shortname;
   string Smooth1=XMA1.GetString_MA_Method(SlMethod);
   StringConcatenate(shortname,"Linear Reg Slope(",SlLength,", ",Smooth1,")");
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//---- determination of accuracy of displaying the indicator values
//---- IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- initialization end
  }
//+------------------------------------------------------------------+ 
//| XMA iteration function                                           | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,     // number of bars in history at the current tick
                const int prev_calculated, // number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<min_rates_total) return(0);

//---- declaration of variables with a floating point  
   double price_,SumY,SumXY,Intercept,Slope;
//---- declaration of integer variables and getting already calculated bars
   int first,bar,iii;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
      first=0;                    // starting index for calculation of all bars
   else first=prev_calculated-1;  // starting index for calculation of new bars

//---- main indicator calculation loop
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      //---- call of the PriceSeries function to get the input price 'price_'
      price_=PriceSeries(IPC,bar,open,low,high,close);
      Smooth[Count[0]]=XMA1.XMASeries(0,prev_calculated,rates_total,SlMethod,SlPhase,SlLength,price_,bar,false);

      SumY=0;
      SumXY=0;

      for(iii=0; iii<SlLength; iii++)
        {
         SumY+=Smooth[Count[iii]];
         SumXY+=iii*Smooth[Count[iii]];
        }

      if(Divisor!=0) Slope=(SlLength*SumXY-SumX*SumY)/Divisor;
      else           Slope=EMPTY_VALUE;

      if(bar>=SlLength)
        {
         Intercept=(SumY-Slope*SumX)/SlLength;
         RegSlopeBuffer[bar]=Intercept+Slope*TrigShift;
        }

      if(bar>TriggerShift_) TriggerBuffer[bar]=2.0*RegSlopeBuffer[bar]-RegSlopeBuffer[bar-TrigShift_];
      else                  TriggerBuffer[bar]=EMPTY_VALUE;

      //---- recalculation of the elements positions in the Smooth[] ring buffer
      if(bar<rates_total-1) Recount_ArrayZeroPos(Count,SlLength);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
