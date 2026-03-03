//+---------------------------------------------------------------------+
//|                                                 TrendTriggerMod.mq5 |
//|                                          Copyright © 2004, Shimodax |
//|                                     http://www.strategybuilder.com/ | 
//+---------------------------------------------------------------------+
//| Place the SmoothAlgorithms.mqh file                                 |
//| in the directory: terminal_data_folder\MQL5\Include                 |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2004, Shimodax"
#property link      "http://www.strategybuilder.com/"
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- two buffers are used for calculation and drawing the indicator
#property indicator_buffers 2
//--- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//| Indicator drawing parameters      |
//+-----------------------------------+
//--- drawing the indicator as a line
#property indicator_type1   DRAW_COLOR_HISTOGRAM
//--- the following colors are used in the three color histogram
#property indicator_color1  Gray,Magenta,SpringGreen
//--- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- indicator line width is equal to 2
#property indicator_width1  2
//--- displaying the indicator label
#property indicator_label1  "Trend Trigger Mod"
//+-----------------------------------+
//| Declaration of enumerations       |
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
//+-----------------------------------+
//| Indicator input parameters        |
//+-----------------------------------+
input uint Regress=15;                 // Extremums searching period
input uint TLength=5;                  // JMA smoothing depth
input  int TPhase=-100;                // JMA smoothing parameter
input Applied_price_ IPC=PRICE_CLOSE_; // Applied price
input int Shift=0;                     // Horizontal shift of the indicator in bars
input int UpTriggerLevel= +50;         // Overbought level
input int DnTriggerLevel= -50;         // Oversold level
//+-----------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double ExtLineBuffer[];
double ColorExtLineBuffer[];
//--- declaration of a variable for storing the number of calculated bars
int min_rates_r,min_rates_total;
//+------------------------------------------------------------------+
//| The iPriceSeries() function description                          |
//| iPriceSeriesAlert() function description                         |
//| CJJMA class description                                          |
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh>  
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//--- initialization of variables 
   min_rates_r=int(Regress+Regress+1);
   min_rates_total=min_rates_r+30;
//--- set ExtLineBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//--- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtLineBuffer,true);
//--- set ColorExtLineBuffer[] dynamic array as an indicator buffer   
   SetIndexBuffer(1,ColorExtLineBuffer,INDICATOR_COLOR_INDEX);
//--- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//--- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ColorExtLineBuffer,true);
//--- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Trend Trigger Mod(",TLength," ,",TPhase,")");
//--- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- declaration of a CJJMA class variable from the JJMASeries_Cls.mqh file
   CJJMA JMA;
//--- setting up alerts for unacceptable values of external variables
   JMA.JJMALengthCheck("TLength", TLength);
   JMA.JJMAPhaseCheck("TPhase", TPhase);
//--- the number of the indicator 3 horizontal levels   
   IndicatorSetInteger(INDICATOR_LEVELS,3);
//--- values of the indicator horizontal levels   
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,UpTriggerLevel);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,DnTriggerLevel);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,0);
//--- Blue and Brown colors are used for horizontal levels lines  
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,Blue);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,Blue);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,Brown);
//--- short dot-dash is used for the horizontal level line  
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,STYLE_DASHDOTDOT);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- checking the number of bars to be enough for the calculation
   if(rates_total<min_rates_total)
      return(0);
//--- declarations of local variables 
   int limit,bar,maxbar;
   double HHR,LLR,HHO,LLO,BuyPower,SellPower,TTF;
//--- indexing elements in arrays as timeseries  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   maxbar=rates_total-min_rates_r-1;
//--- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_r-1;   // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }
//--- declaration of a CJJMA class variable from the JJMASeries_Cls.mqh file
   static CJJMA JMA;
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      HHR=high[ArrayMaximum(high,bar,Regress)];
      HHO=high[ArrayMaximum(high,bar+Regress,Regress)];
      LLR=low[ArrayMinimum(low,bar,Regress)];
      LLO=low[ArrayMinimum(low,bar+Regress,Regress)];

      BuyPower=HHR-LLO;
      SellPower=HHO-LLR;
      TTF=100*(BuyPower-SellPower)*2/(BuyPower+SellPower);
      //--- one call of the JJMASeries function. 
      //--- Phase and Length parameters are not changed at every bar (Din = 0) 
      ExtLineBuffer[bar]=JMA.JJMASeries(maxbar,prev_calculated,rates_total,0,TPhase,TLength,TTF,bar,true);
      //--- ExtLineBuffer[bar]=TTF;
      ColorExtLineBuffer[bar]=0;
      if(ExtLineBuffer[bar]>UpTriggerLevel) ColorExtLineBuffer[bar]=2;
      if(ExtLineBuffer[bar]<DnTriggerLevel) ColorExtLineBuffer[bar]=1;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
