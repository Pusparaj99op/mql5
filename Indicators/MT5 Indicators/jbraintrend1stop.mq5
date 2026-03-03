//+------------------------------------------------------------------+
//|                                             JBrainTrend1Stop.mq5 |
//|                               Copyright © 2005, BrainTrading Inc |
//|                                      http://www.braintrading.com |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2005, BrainTrading Inc."
//---- link to the website of the author
#property link      "http://www.braintrading.com/"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- 4 buffers are used for calculation and drawing the indicator
#property indicator_buffers 4
//---- 4 plots are used
#property indicator_plots   4
//+----------------------------------------------+
//|  Declaration of constants                    |
//+----------------------------------------------+
#define RESET 0 // the constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- use orange color for the indicator
#property indicator_color1  Orange
//---- indicator 1 line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "JBrain1 Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- use SpringGreen color for the indicator
#property indicator_color2  SpringGreen
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator label
#property indicator_label2 "JBrain1 Buy"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_LINE
//---- use orange color for the indicator
#property indicator_color3  Orange
//---- indicator 3 line width is equal to 1
#property indicator_width3  1
//---- indicator line is a solid one
#property indicator_style3 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width3 2
//---- displaying the indicator label
#property indicator_label3  "JBrain1 Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4   DRAW_LINE
//---- use SpringGreen color for the indicator
#property indicator_color4  SpringGreen
//---- indicator 4 line width is equal to 1
#property indicator_width4  1
//---- indicator line is a solid one
#property indicator_style4 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width4 2
//---- displaying the indicator label
#property indicator_label4 "JBrain1 Buy"
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int ATR_Period=7;                        // ATR period 
input int STO_Period=9;                        // Stochastic period
input ENUM_MA_METHOD MA_Method = MODE_SMA;     // Smoothing method
input ENUM_STO_PRICE STO_Price = STO_LOWHIGH;  // Prices calculation method 
input int Stop_dPeriod=3;                      // Period expansion for a stop
input int Length_=7;                           // JMA smoothing depth                   
input int Phase_=100;                          // JMA smoothing parameter
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double SellStopBuffer[];
double BuyStopBuffer[];
double SellStopBuffer_[];
double BuyStopBuffer_[];
//---
double d,s,r,R_;
int p,x1,x2,P_,min_rates_total;
//---- declaration of integer variables for the indicators handles
int ATR_Handle,ATR1_Handle,STO_Handle,JH_Handle,JL_Handle,JC_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- initialization of global variables 
   d=2.3;
   s=1.5;
   x1 = 53;
   x2 = 47;
   min_rates_total=int(MathMax(MathMax(MathMax(ATR_Period,STO_Period),ATR_Period+Stop_dPeriod),30)+2);

//---- getting handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get handle of the ATR indicator");

//---- getting handle of the ATR indicator
   ATR1_Handle=iATR(NULL,0,ATR_Period+Stop_dPeriod);
   if(ATR1_Handle==INVALID_HANDLE)Print(" Failed to get handle of the indicator ATR1");

//---- getting handle of the Stochastic indicator
   STO_Handle=iStochastic(NULL,0,STO_Period,STO_Period,1,MA_Method,STO_Price);
   if(STO_Handle==INVALID_HANDLE)Print(" Failed to get handle of the Stochastic indicator");

//---- getting handle of the JMA indicator
   JL_Handle=iCustom(NULL,0,"JMA",Length_,Phase_,4,0,0);
   if(JL_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the indicator JMA");
      return(1);
     }

//---- getting handle of the JMA indicator
   JC_Handle=iCustom(NULL,0,"JMA",Length_,Phase_,1,0,0);
   if(JC_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the indicator JMA");
      return(1);
     }

//---- getting handle of the JMA indicator
   JH_Handle=iCustom(NULL,0,"JMA",Length_,Phase_,3,0,0);
   if(JH_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the indicator JMA");
      return(1);
     }

//---- set SellStopBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,SellStopBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,159);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(SellStopBuffer,true);

//---- set BuyStopBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyStopBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(BuyStopBuffer,true);

//---- set SellStopBuffer_[] dynamic array as an indicator buffer
   SetIndexBuffer(2,SellStopBuffer_,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(SellStopBuffer_,true);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);

//---- set BuyStopBuffer_[] dynamic array as an indicator buffer
   SetIndexBuffer(3,BuyStopBuffer_,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(BuyStopBuffer_,true);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);

//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="JBrainTrend1Stop";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
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
   if(BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(ATR1_Handle)<rates_total
      || BarsCalculated(STO_Handle)<rates_total
      || BarsCalculated(JH_Handle)<rates_total
      || BarsCalculated(JL_Handle)<rates_total
      || BarsCalculated(JC_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declarations of local variables 
   int to_copy,limit,bar;
   double range,range1,val1,val2,val3;
   double value2[],Range[],Range1[],JH[],JL[],JC[],value3,value4,value5;

//---- calculations of the necessary amount of data to be copied
//---- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total;   // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars    
   to_copy=limit+1;

//--- copy newly appeared data in the arrays
   if(CopyBuffer(ATR_Handle,0,0,to_copy,Range)<=0) return(RESET);
   if(CopyBuffer(STO_Handle,0,0,to_copy,value2)<=0) return(RESET);
   if(CopyBuffer(ATR1_Handle,0,0,to_copy,Range1)<=0) return(RESET);
   if(CopyBuffer(JH_Handle,0,0,to_copy,JH)<=0) return(RESET);
   if(CopyBuffer(JL_Handle,0,0,to_copy,JL)<=0) return(RESET);
   if(CopyBuffer(JC_Handle,0,0,to_copy+2,JC)<=0) return(RESET);

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(Range,true);
   ArraySetAsSeries(Range1,true);
   ArraySetAsSeries(value2,true);
   ArraySetAsSeries(JH,true);
   ArraySetAsSeries(JL,true);
   ArraySetAsSeries(JC,true);

//---- restore values of the variables
   p=P_;
   r=R_;

//---- main indicator calculation loop
   for(bar=limit; bar>=0; bar--)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         P_=p;
         R_=r;
        }
      range=Range[bar]/d;
      range1=Range1[bar]*s;

      val1 = 0.0;
      val2 = 0.0;
      val3=MathAbs(NormalizeDouble(JC[bar],_Digits)-NormalizeDouble(JC[bar+2],_Digits));

      SellStopBuffer[bar]=0.0;
      BuyStopBuffer[bar]=0.0;
      SellStopBuffer_[bar]=0.0;
      BuyStopBuffer_[bar]=0.0;

      if(val3>range)
        {
         if(value2[bar]<x2 && p!=1)
           {
            value3=JH[bar]+range1/4;
            val1=value3;
            p = 1;
            r = val1;
            SellStopBuffer[bar]=val1;
            SellStopBuffer_[bar]=val1;
           }

         if(value2[bar]>x1 && p!=2)
           {
            value3=JL[bar]-range1/4;
            val2=value3;
            p = 2;
            r = val2;
            BuyStopBuffer[bar]=val2;
            BuyStopBuffer_[bar]=val2;
           }
        }

      value4 = JH[bar] + range1;
      value5 = JL[bar] - range1;

      if(val1==0 && val2==0)
        {
         if(p==1)
           {
            if(value4<r) r=value4;
            SellStopBuffer[bar]=r;
            SellStopBuffer_[bar]=r;
           }

         if(p==2)
           {
            if(value5>r) r=value5;
            BuyStopBuffer[bar]=r;
            BuyStopBuffer_[bar]=r;
           }
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
