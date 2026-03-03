/*
 * Place the file
 * SmoothAlgorithms.mqh
 * to the MetaTrader\\MQL5\Include folder
 */
//+------------------------------------------------------------------+ 
//|                                                     MACD^RSI.mq5 | 
//|                               Copyright © 2010, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2010, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers 4
#property indicator_buffers 4 
//---- only three plots are used
#property indicator_plots   3
//+--------------------------------------------+
//|  Parameters of MACD drawing                |
//+--------------------------------------------+
//---- drawing the indicator as a histogram
#property indicator_type1 DRAW_HISTOGRAM
//---- blue violet color is used as the color of the diagrams of the MACD indicator
#property indicator_color1 BlueViolet
//---- the indicator line is a continuous curve
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the indicator label
#property indicator_label1 "MACD"
//+--------------------------------------------+
//|  Parameters of MACD signal line drawing    |
//+--------------------------------------------+
//---- drawing the indicator as a line
#property indicator_type2 DRAW_LINE
//---- magenta color is used as the color of the signal line
#property indicator_color2 Magenta
//---- the indicator line is a dash-dotted curve
#property indicator_style2 STYLE_DASHDOTDOT
//---- indicator line width is equal to 1
#property indicator_width2 1
//---- displaying the label of the signal line
#property indicator_label2  "Signal Line"
//+--------------------------------------------+
//|  RSI drawing parameters                    |
//+--------------------------------------------+
//---- drawing the indicator as a line
#property indicator_type3   DRAW_COLOR_LINE
//---- the indicator line is a continuous curve
#property indicator_style3 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width3 2
//---- displaying the label of the signal line
#property indicator_label3  "RSI"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
enum Applied_price_ //Type of constant
  {
   PRICE_CLOSE_ = 1,     //PRICE_CLOSE
   PRICE_OPEN_,          //PRICE_OPEN
   PRICE_HIGH_,          //PRICE_HIGH
   PRICE_LOW_,           //PRICE_LOW
   PRICE_MEDIAN_,        //PRICE_MEDIAN
   PRICE_TYPICAL_,       //PRICE_TYPICAL
   PRICE_WEIGHTED_,      //PRICE_WEIGHTED
   PRICE_SIMPL_,         //PRICE_SIMPL_
   PRICE_QUARTER_,       //PRICE_QUARTER_
   PRICE_TRENDFOLLOW0_, //PRICE_TRENDFOLLOW0_
   PRICE_TRENDFOLLOW1_  //PRICE_TRENDFOLLOW1_
  };
input int Fast_MA = 12;                         //Period of MACD fast moving average
input int Slow_MA = 26;                         //Depth of MACD slow moving average
input ENUM_MA_METHOD MA_Method_=MODE_EMA;       //Indicator averaging method
input int Signal_SMA=9;                         //Signal line period 
input Applied_price_ AppliedPrice_=PRICE_CLOSE_;//Price constant
/* , used for the indicator calculation ( 1-CLOSE, 2-OPEN, 3-HIGH, 4-LOW, 
  5-MEDIAN, 6-TYPICAL, 7-WEIGHTED, 8-SIMPLE, 9-QUARTER, 10-TRENDFOLLOW, 11-0.5 * TRENDFOLLOW.) */
input int RSIPeriod=14;   //RSI period 
input double caliber=4.0; //Scaling
//+-----------------------------------+
//---- indicator buffers
double MACDBuffer[],SignBuffer[],RSIBuffer[],ColorRSIBuffer[];
double positive_,negative_;
int macd_start,sig_start,rsi_start;
color ExtColor[3]={Gray,Lime,Red};
//+------------------------------------------------------------------+
// iPriceSeries function description                                 |
// Moving_Average class description                                  | 
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh> 
//+------------------------------------------------------------------+    
//| MACD indicator initialization function                           | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialization of variables of the start of data calculation  
   if(MA_Method_!=MODE_EMA)
      macd_start=MathMax(Fast_MA,Slow_MA);
   else macd_start=0;
   sig_start=macd_start+Signal_SMA;
   rsi_start=sig_start+RSIPeriod;

//---- set MACDBuffer dynamic array as indicator buffer
   SetIndexBuffer(0,MACDBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,macd_start);
//---- create label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"MACD");
//---- setting values of the indicator that won't be visible on the chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set SignBuffer dynamic array as indicator buffer
   SetIndexBuffer(1,SignBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,sig_start);
//---- create label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"Signal SMA");
//---- setting values of the indicator that won't be visible on the chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- set RSIBuffer dynamic array as indicator buffer
   SetIndexBuffer(2,RSIBuffer,INDICATOR_DATA);
//---- shifting the start of drawing the indicator
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,rsi_start+1);
//---- create label to display in DataWindow
   PlotIndexSetString(2,PLOT_LABEL,"RSI");
//---- setting values of the indicator that won't be visible on the chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   
//---- set dynamic array as colored index buffer   
   SetIndexBuffer(3,ColorRSIBuffer,INDICATOR_COLOR_INDEX);
//---- shifting the start of drawing the indicator
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,rsi_start+1);  
//---- set colors quantity 3 for the color buffer
   PlotIndexSetInteger(2,PLOT_COLOR_INDEXES,3);
//---- set colors for the color buffer
   for(int i=0; i<3; i++)
      PlotIndexSetInteger(2,PLOT_LINE_COLOR,i,ExtColor[i]);

//---- initializations of a variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"MACD( ",Fast_MA,", ",Slow_MA,", ",Signal_SMA," )");
//---- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- initialization end
  }
//+------------------------------------------------------------------+  
//| MACD iteration function                                          | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- Checking the number of bars to be enough for the calculation
   if(rates_total<rsi_start) return(0);

//---- Declaration of integer variables
   int first,bar;
//---- Declaration of variables with a floating point  
   double positive,negative;
   double price_,fast_ma,slow_ma,sumn,sump,rel;

//---- calculation of the 'first' starting index for the loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of the indicator
     {
      first=0; // starting index for calculation of all bars
     }
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- declaration of variables of the CMoving_Average class from the MASeries_Cls.mqh file
   static CMoving_Average MA1,MA2,MA3;

//---- Main loop of the MACD indicator calculation
   for(bar=first; bar<rates_total; bar++)
     {
      price_=PriceSeries(AppliedPrice_,bar,open,low,high,close);
      fast_ma = MA1.MASeries(0, prev_calculated, rates_total, Fast_MA, MA_Method_, price_, bar, false);
      slow_ma = MA2.MASeries(0, prev_calculated, rates_total, Slow_MA, MA_Method_, price_, bar, false);
      MACDBuffer[bar] = fast_ma - slow_ma;
      SignBuffer[bar] = MA3.SMASeries(macd_start, prev_calculated, rates_total, Signal_SMA, MACDBuffer[bar], bar, false);
     }

//---- calculate the first starting index for loop of bars recalculation and variables start initialization
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of the indicator
     {
      first=macd_start+1;
      sumn=0.0;
      sump=0.0;

      for(bar=first; bar<first+RSIPeriod; bar++)
        {
         rel=MACDBuffer[bar]-MACDBuffer[bar-1];
         if(rel>0) sump+=rel;
         else      sumn-=rel;
        }
      positive_=sump/RSIPeriod;
      negative_=sumn/RSIPeriod;

      first+=RSIPeriod; // starting index for calculation of all bars
     }
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- restore values of the variables
   positive=positive_;
   negative=negative_;

//---- Main loop of the RSI indicator calculation
   for(bar=first; bar<rates_total; bar++)
     {
      //---- storing values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         positive_=positive;
         negative_=negative;
        }
     
      sump=0.0;
      sumn=0.0;
      rel=MACDBuffer[bar]-MACDBuffer[bar-1];
      if(rel>0) sump=+rel;
      else      sumn=-rel;

      positive=(positive*(RSIPeriod-1)+sump)/RSIPeriod;
      negative=(negative*(RSIPeriod-1)+sumn)/RSIPeriod;

      if(negative==0.0)
           RSIBuffer[bar]=0.0;
      else RSIBuffer[bar]=caliber*_Point*(50.0-100.0/(1+positive/negative));
      
      ColorRSIBuffer[bar]=0;
      if(RSIBuffer[bar]>SignBuffer[bar]) ColorRSIBuffer[bar]=1;
      if(RSIBuffer[bar]<SignBuffer[bar]) ColorRSIBuffer[bar]=2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+ 
