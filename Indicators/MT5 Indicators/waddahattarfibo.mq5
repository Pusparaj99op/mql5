//+------------------------------------------------------------------+
//|                                              WaddahAttarFibo.mq5 | 
//|                                   Copyright © 2007, Waddah Attar |
//|                             Waddah Attar waddahattar@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, Waddah Attar waddahattar@hotmail.com"
#property link      "waddahattar@hotmail.com"
#property description "Waddah Attar Fibo"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers 12
#property indicator_buffers 12 
//---- 12 graphical plots are used
#property indicator_plots   12
//+--------------------------------------------+
//|  Declaration of constants                  |
//+--------------------------------------------+
#define RESET 0                            // the constant for getting the command for the indicator recalculation back to the terminal
#define INDICATOR_NAME "Waddah Attar Fibo" // the constant for the indicator name
//+--------------------------------------------+
//|  Fibo levels drawing parameters            |
//+--------------------------------------------+
//---- drawing Fibo levels as lines
#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
#property indicator_type4   DRAW_ARROW
#property indicator_type5   DRAW_ARROW
#property indicator_type6   DRAW_ARROW
#property indicator_type7   DRAW_ARROW
#property indicator_type8   DRAW_ARROW
#property indicator_type9   DRAW_ARROW
#property indicator_type10   DRAW_ARROW
#property indicator_type11   DRAW_ARROW
#property indicator_type12   DRAW_ARROW
//---- selection of Fibo levels colors
#property indicator_color1  Indigo
#property indicator_color2  Indigo
#property indicator_color3  DarkSlateGray
#property indicator_color4  Purple
#property indicator_color5  Red
#property indicator_color6  Blue
#property indicator_color7  Blue
#property indicator_color8  Red
#property indicator_color9  Purple
#property indicator_color10  DarkSlateGray
#property indicator_color11  Indigo
#property indicator_color12  Indigo
//---- Fibo levels are dott-dash curves
#property indicator_style1 STYLE_DASHDOTDOT
#property indicator_style2 STYLE_DASHDOTDOT
#property indicator_style3 STYLE_DASHDOTDOT
#property indicator_style4 STYLE_DASHDOTDOT
#property indicator_style5 STYLE_DASHDOTDOT
#property indicator_style6 STYLE_DASHDOTDOT
#property indicator_style7 STYLE_DASHDOTDOT
#property indicator_style8 STYLE_DASHDOTDOT
#property indicator_style9 STYLE_DASHDOTDOT
#property indicator_style10 STYLE_DASHDOTDOT
#property indicator_style11 STYLE_DASHDOTDOT
#property indicator_style12 STYLE_DASHDOTDOT
//---- Fibo levels width is equal to 1
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  1
#property indicator_width9  1
#property indicator_width10 1
#property indicator_width11 1
#property indicator_width12 1
//---- display of Fibo levels labels
#property indicator_label1  "Fibo +0.764"
#property indicator_label2  "Fibo +0.618"
#property indicator_label3  "Fibo +0.50"
#property indicator_label4  "Fibo +0.382"
#property indicator_label5  "Fibo +0.236"
#property indicator_label6  "Fibo +0"
#property indicator_label7  "Fibo -0"
#property indicator_label8  "Fibo -0.236"
#property indicator_label9  "Fibo -0.382"
#property indicator_label10 "Fibo -0.50"
#property indicator_label11 "Fibo -0.618"
#property indicator_label12 "Fibo -0.764"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input ENUM_TIMEFRAMES TimeFrame=PERIOD_D1; // Chart period
input int Shift=0;                         // Horizontal shift of the indicator in bars
input int PriceShift=0;                    // Vertical shift of the indicator in points
//+-----------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as Fibo levels indicator buffers
double ExtLineBuffer0[],ExtLineBuffer1[],ExtLineBuffer2[],ExtLineBuffer3[];
double ExtLineBuffer4[],ExtLineBuffer5[],ExtLineBuffer6[],ExtLineBuffer7[];
double ExtLineBuffer8[],ExtLineBuffer9[],ExtLineBuffer10[],ExtLineBuffer11[];
//---- declaration of string variables
string Symbol_;
//---- declaration of the average vertical shift value variable
double dPriceShift;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of a variable for storing the indicator initialization result
bool Init;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
   Init=true;
//---- checking correctness of the chart periods
   if(TimeFrame<Period() && TimeFrame!=PERIOD_CURRENT)
     {
      Print("Waddah Attar Fibo indicator timeframe cannot be less than the current chart period");
      Init=false;
      return(1);
     }

//---- initialization of variables
   Symbol_=Symbol();
   string shortname=INDICATOR_NAME+" indicator: "+Symbol_+StringSubstr(EnumToString(_Period),7,-1);

//---- initialization of variables of the start of data calculation
   min_rates_total=int(2*PeriodSeconds(TimeFrame)/PeriodSeconds());

//---- initialization of the vertical shift
   dPriceShift=_Point*PriceShift;

//---- set dynamic arrays as indicator buffers
   SetIndexBuffer(0,ExtLineBuffer0,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLineBuffer2,INDICATOR_DATA);
   SetIndexBuffer(3,ExtLineBuffer3,INDICATOR_DATA);
   SetIndexBuffer(4,ExtLineBuffer4,INDICATOR_DATA);
   SetIndexBuffer(5,ExtLineBuffer5,INDICATOR_DATA);
   SetIndexBuffer(6,ExtLineBuffer6,INDICATOR_DATA);
   SetIndexBuffer(7,ExtLineBuffer7,INDICATOR_DATA);
   SetIndexBuffer(8,ExtLineBuffer8,INDICATOR_DATA);
   SetIndexBuffer(9,ExtLineBuffer9,INDICATOR_DATA);
   SetIndexBuffer(10,ExtLineBuffer10,INDICATOR_DATA);
   SetIndexBuffer(11,ExtLineBuffer11,INDICATOR_DATA);

//---- set the position, from which Fibo levels drawing starts
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(7,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(8,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(9,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(10,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(11,PLOT_DRAW_BEGIN,min_rates_total);

//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- horizontal shift of the indicator
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(5,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(6,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(7,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(8,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(9,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(10,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(11,PLOT_SHIFT,Shift);

//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(ExtLineBuffer0,true);
   ArraySetAsSeries(ExtLineBuffer1,true);
   ArraySetAsSeries(ExtLineBuffer2,true);
   ArraySetAsSeries(ExtLineBuffer3,true);
   ArraySetAsSeries(ExtLineBuffer4,true);
   ArraySetAsSeries(ExtLineBuffer5,true);
   ArraySetAsSeries(ExtLineBuffer6,true);
   ArraySetAsSeries(ExtLineBuffer7,true);
   ArraySetAsSeries(ExtLineBuffer8,true);
   ArraySetAsSeries(ExtLineBuffer9,true);
   ArraySetAsSeries(ExtLineBuffer10,true);
   ArraySetAsSeries(ExtLineBuffer11,true);

//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- initialization end
   return(0);
  }
//+------------------------------------------------------------------+ 
//| Custom iteration function                                        | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
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
//---- checking the number of bars to be enough for the calculation
   if(rates_total<min_rates_total || !Init) return(RESET);

//---- declarations of local variables 
   double iHigh[2],iLow[2],Range;
   int limit,bar;

//---- calculations of the necessary number of copied data and limit starting index for the  bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars 

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(iHigh,true);
   ArraySetAsSeries(iLow,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- copy newly appeared data in the arrays
      if(CopyHigh(Symbol_,TimeFrame,time[bar],2,iHigh)<=0) return(RESET);
      if(CopyLow(Symbol_,TimeFrame,time[bar],2,iLow)<=0) return(RESET);
      Range=iHigh[0]-iLow[0];
      //----       
      ExtLineBuffer0[bar]=iHigh[0]+Range*0.764+dPriceShift;
      ExtLineBuffer1[bar]=iHigh[0]+Range*0.618+dPriceShift;
      ExtLineBuffer2[bar]=iHigh[0]+Range*0.500+dPriceShift;
      ExtLineBuffer3[bar]=iHigh[0]+Range*0.382+dPriceShift;
      ExtLineBuffer4[bar]=iHigh[0]+Range*0.236+dPriceShift;
      ExtLineBuffer5[bar]=iHigh[0]+dPriceShift;
      ExtLineBuffer6[bar]=iLow[0]+dPriceShift;
      ExtLineBuffer7[bar]=iLow[0]-Range*0.236+dPriceShift;
      ExtLineBuffer8[bar]=iLow[0]-Range*0.382+dPriceShift;
      ExtLineBuffer9[bar]=iLow[0]-Range*0.500+dPriceShift;
      ExtLineBuffer10[bar]=iLow[0]-Range*0.618+dPriceShift;
      ExtLineBuffer11[bar]=iLow[0]-Range*0.764+dPriceShift;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
