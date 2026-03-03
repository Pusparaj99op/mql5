//+------------------------------------------------------------------+
//|                                                          RSO.mq5 |
//|               RSI Copyright 2009-2017, MetaQuotes Software Corp. |
//|                              RSO Copyright 2017, Paran Softwares |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2017, MetaQuotes Software Corp, Modification by Paran (2017)"
#property link        "http://www.mql5.com"
#property description "Relative Strength Oscillator"
#property description "Convertion of RS Index to Oscillator by Reza Anvari, Tehran"

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2

#property indicator_minimum   -50
#property indicator_maximum   50
#property indicator_level1    -20
#property indicator_level2    0
#property indicator_level3    20
#property indicator_levelcolor Black

#property indicator_type1   DRAW_LINE
#property indicator_color1  MediumBlue
#property indicator_width1    1

#property indicator_type2     DRAW_COLOR_HISTOGRAM
#property indicator_color2    LightGreen, Red
#property indicator_width2    2

//--- input parameters
input int InpPeriodRSO = 14;        // RSO Period
//--- indicator buffers
double   ExtRSOBuffer[];
double   ExtPosBuffer[];
double   ExtNegBuffer[];
double   ExtBufferBars[];
double   ExtBufferColors[];
//--- global variable
int      ExtPeriodRSO;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
//--- check for input
   if(InpPeriodRSO<1)
   {
      ExtPeriodRSO = 12;
      Print("Incorrect value for input variable InpPeriodRSO = ",InpPeriodRSO,
            "Indicator will use value = ",ExtPeriodRSO,"for calculations.");
   }
   else ExtPeriodRSO = InpPeriodRSO;
//--- indicator buffers mapping
   SetIndexBuffer(0, ExtRSOBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtBufferBars, INDICATOR_DATA);
   SetIndexBuffer(2, ExtBufferColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3, ExtPosBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, ExtNegBuffer, INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS, 2);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, ExtPeriodRSO);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, ExtPeriodRSO);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME, "RSO("+string(ExtPeriodRSO)+")");
   PlotIndexSetString(0, PLOT_LABEL, "RSO("+string(ExtPeriodRSO)+")");
   PlotIndexSetString(1, PLOT_LABEL, "RSO Bars");
}
//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   int    i;
   double diff;
//--- check for rates count
   if(rates_total <= ExtPeriodRSO)
      return(0);
//--- preliminary calculations
   int pos = prev_calculated - 1;
   if(pos <= ExtPeriodRSO)
   {
      //--- first RSOPeriod values of the indicator are not calculated
      ExtRSOBuffer[0] = 0.0;
      ExtPosBuffer[0] = 0.0;
      ExtNegBuffer[0] = 0.0;
      double SumP = 0.0;
      double SumN = 0.0;
      for(i = 1; i <= ExtPeriodRSO; i++)
      {
         ExtRSOBuffer[i] = 0.0;
         ExtPosBuffer[i] = 0.0;
         ExtNegBuffer[i] = 0.0;
         diff = price[i]-price[i-1];
         SumP += (diff > 0)?diff:0;
         SumN += (diff < 0)?-diff:0;
      }
      //--- calculate first visible value
      ExtPosBuffer[ExtPeriodRSO] = SumP/ExtPeriodRSO;
      ExtNegBuffer[ExtPeriodRSO] = SumN/ExtPeriodRSO;
      if(ExtNegBuffer[ExtPeriodRSO] != 0.0)
         ExtRSOBuffer[ExtPeriodRSO] = 100.0-(100.0/(1.0+ExtPosBuffer[ExtPeriodRSO]/ExtNegBuffer[ExtPeriodRSO]));
      else
      {
         if(ExtPosBuffer[ExtPeriodRSO] != 0.0)
            ExtRSOBuffer[ExtPeriodRSO] = 100.0;
         else
            ExtRSOBuffer[ExtPeriodRSO] = 50.0;
      }

      pos = ExtPeriodRSO+1;
   }
//--- the main loop of calculations
   for(i = pos; i < rates_total && !IsStopped(); i++)
   {
      diff = price[i]-price[i-1];
      ExtPosBuffer[i] = (ExtPosBuffer[i-1]*(ExtPeriodRSO-1) + (diff>0.0?diff:0.0))/ExtPeriodRSO;
      ExtNegBuffer[i] = (ExtNegBuffer[i-1]*(ExtPeriodRSO-1) + (diff<0.0?-diff:0.0))/ExtPeriodRSO;
      if(ExtNegBuffer[i] != 0.0)
         ExtRSOBuffer[i] = 50.0-100.0/(1 + ExtPosBuffer[i]/ExtNegBuffer[i]);
      else
      {
         if(ExtPosBuffer[i] != 0.0)
            ExtRSOBuffer[i] = 50.0;
         else
            ExtRSOBuffer[i] = 0.0;
      }
      ExtBufferBars[i] = 0.9*ExtRSOBuffer[i];
      ExtBufferColors[i] = (ExtRSOBuffer[i] - ExtRSOBuffer[i-1] >= 0)?0.0:1.0;
   }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
}
//+------------------------------------------------------------------+
