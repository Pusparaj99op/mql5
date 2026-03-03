//+------------------------------------------------------------------+
//|                                                   pr_channel.mq5 |
//|                               Copyright 2013, Andrey Litvichenko |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, Andrey Litvichenko"
#property link      "http://www.mql5.com"
#property version   "1.00"
//---- plot in separate window
#property indicator_chart_window
//---- 4 indicator buffers
#property indicator_buffers 4
//---- 3 graphic plots
#property indicator_plots   3
//----  Plot parametrs
//--- plot trend
#property indicator_label1  "trend"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrRed,clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot h_line
#property indicator_label2  "h_line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrNavy
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot l_line
#property indicator_label3  "l_line"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrFireBrick
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//--- Indicator input parameters
input int      length=24;  //Channel length
//---- declaration of dynamic arrays, which will be used as indicator buffers
//--- indicator buffers
double         levelBuffer[];
double         m_lineBuffer[];
double         h_lineBuffer[];
double         l_lineBuffer[];
//--- declaration of the integer variable
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialization of variable origin data
   min_rates_total=length;
//--- indicator buffers mapping
   SetIndexBuffer(0,levelBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,m_lineBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,h_lineBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,l_lineBuffer,INDICATOR_DATA);
//--- setting position from which to start rendering buffers
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//--- prohibition on rendering empty values
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
//--- set precision
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- creating name to be displayed in a separate window and the tooltip
   string shortname="Price chennel trend("+string(length)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- end of initialization
   return(INIT_SUCCEEDED);
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
//--- declaration of integer variables
   int bar,first;

//--- checking the number of bars is sufficient to calculate
   if(min_rates_total>rates_total)
      return(0);

//--- calculation of the starting number for the first cycle of translation bars
   if(prev_calculated>rates_total || prev_calculated<=0) // checking the first start of calculation of the indicator
     {
      first=min_rates_total;
     }
   else
     {
      first=prev_calculated-1;
     }

//--- the main loop of the indicator calculation
   for(bar=first;bar<rates_total;bar++)
     {
      h_lineBuffer[bar]=high[ArrayMaximum(high,bar-length+1,length)];//---- Calculating high for length bars 
      l_lineBuffer[bar]=low[ArrayMinimum(low,bar-length+1,length)];//---- Calculating low for length bars

      m_lineBuffer[bar]=(h_lineBuffer[bar]+l_lineBuffer[bar])/2;//---- Calculating the median 

      levelBuffer[bar]=(h_lineBuffer[bar]+l_lineBuffer[bar]+close[bar])/3;//---- Calculating pivot level
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
