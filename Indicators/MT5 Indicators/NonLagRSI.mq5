//+------------------------------------------------------------------+
//|                                                    NonLagRSI.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                              https://www.mql5.com/en/users/3rjfx |
//+------------------------------------------------------------------+
#property copyright   "2009-2020, MetaQuotes Software Corp. ~ By 3rjfx ~ Created: 04/04/2020"
#property link        "http://www.mql5.com"
#property link        "https://www.mql5.com/en/users/3rjfx"
#property version     "1.00"
#property description "Non Lag Relative Strength Index"
#property description "Eliminates unnecessary preliminary calculations on the built-in RSI"
#property strict
//--
//--- indicator settings
#property indicator_separate_window
#property indicator_minimum    0
#property indicator_maximum    100
#property indicator_level1     30
#property indicator_level2     70
#property indicator_buffers    5
#property indicator_plots      1
#property indicator_type1      DRAW_LINE
#property indicator_color1     clrRed
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_SOLID
//---
//--
//--- input parameters
input int       InpPeriodRSI = 14;             // Period
//--
//--- indicator buffers
double    ExtRSIBuffer[];
double    ExtPosBuffer[];
double    ExtNegBuffer[];
double    diffup[];
double    diffdn[];
//--
//--- global variable
int       ExtPeriodRSI;
#define DATA_LIMIT  120
//---------//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input
   if(InpPeriodRSI<1)
     {
      ExtPeriodRSI=12;
      Print("Incorrect value for input variable InpPeriodRSI =",InpPeriodRSI,
            "Indicator will use value =",ExtPeriodRSI,"for calculations.");
     }
   else ExtPeriodRSI=InpPeriodRSI;
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtRSIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtPosBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,ExtNegBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,diffup,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,diffdn,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPeriodRSI);
//--- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"NonLagRSI("+string(ExtPeriodRSI)+")");
//--- initialization done
  }
//---------//
//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
    int limit,barc;
    double diff=0;
//--- check for rates total
   if(rates_total<DATA_LIMIT)
      return(0);
//--- last counted bar will be recounted
   limit=rates_total-prev_calculated;
   if(limit==0) limit=ExtPeriodRSI*2+2;
   if(prev_calculated>0) limit--;
   if(limit>Bars(Symbol(),0)) limit=Bars(Symbol(),0);
   barc=limit-ExtPeriodRSI+1;
   //--
   ArrayResize(ExtRSIBuffer,limit);
   ArrayResize(ExtPosBuffer,limit);
   ArrayResize(ExtNegBuffer,limit);
   ArrayResize(diffup,limit);
   ArrayResize(diffdn,limit);
   ArraySetAsSeries(ExtRSIBuffer,true);
   ArraySetAsSeries(ExtPosBuffer,true);
   ArraySetAsSeries(ExtNegBuffer,true);
   ArraySetAsSeries(diffup,true);
   ArraySetAsSeries(diffdn,true);
   ArraySetAsSeries(price,true);
   //---
   for(int i=barc-1; i>=0; i--)
     {
       diff=price[i]-price[i+1];
       if(diff>0)
          diffup[i]=diff;
       else
          diffdn[i]=-diff;
       //--
       ExtPosBuffer[i]=((ExtPosBuffer[i+1]*(ExtPeriodRSI-1))+(diffup[i]))/ExtPeriodRSI;
       ExtNegBuffer[i]=((ExtNegBuffer[i+1]*(ExtPeriodRSI-1))+(diffdn[i]))/ExtPeriodRSI;
       if(ExtNegBuffer[i]!=0.0)
          ExtRSIBuffer[i]=100.0-(100.0/(1+(ExtPosBuffer[i]/ExtNegBuffer[i])));
       else
        {
         if(ExtPosBuffer[i]!=0.0)
            ExtRSIBuffer[i]=100.0;
         else
            ExtRSIBuffer[i]=50.0;
        }
     }
   //---
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//---------//
//+------------------------------------------------------------------+