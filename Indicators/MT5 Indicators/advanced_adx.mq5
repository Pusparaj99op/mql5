//+------------------------------------------------------------------+
//|                                                 Advanced_ADX.mq5 |
//|                              Copyright © 2006, Eng. Waddah Attar |
//|                                          waddahattar@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Waddah Attar"
#property link      "waddahattar@hotmail.com"
#property version   "1.00"
//---
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//---
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrGreen
#property indicator_width1  2
//---
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrRed
#property indicator_width2  2
//---
#define RESET 0
input uint ADXPeriod=13;  // ADX period
//---
double ExtBuffer1[],ExtBuffer2[];
int ADX_Handle;
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---
   min_rates_total=int(ADXPeriod+1);
//--- get handle of ADX
   ADX_Handle=iADX(NULL,0,ADXPeriod);
   if(ADX_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of ADX indicator");
      return(INIT_FAILED);
     }
//---
   SetIndexBuffer(0,ExtBuffer1,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   ArraySetAsSeries(ExtBuffer1,true);
//---
   SetIndexBuffer(1,ExtBuffer2,INDICATOR_DATA);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   ArraySetAsSeries(ExtBuffer2,true);
//---
   string shortname;
   StringConcatenate(shortname,"Advanced_ADX (",ADXPeriod,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double& price[])
  {
//--- check
   if(BarsCalculated(ADX_Handle)<rates_total|| rates_total<min_rates_total) return(RESET);
//--- local variables
   int limit,to_copy,bar;
   double pADX0[],pADX1[],pADX2[];
//--- set indexing 
   ArraySetAsSeries(pADX0,true);
   ArraySetAsSeries(pADX1,true);
   ArraySetAsSeries(pADX2,true);
//--- calculation of start index
   if(prev_calculated>rates_total || prev_calculated<=0) // first call check
     {
      limit=rates_total-1-min_rates_total; // starting index for all bars
     }
   else limit=rates_total-prev_calculated; // starting index for new bars
//---
   to_copy=limit+2;
//--- copy indicator data to array
   if(CopyBuffer(ADX_Handle,MAIN_LINE,0,to_copy,pADX0)<=0) return(RESET);
   if(CopyBuffer(ADX_Handle,PLUSDI_LINE,0,to_copy,pADX1)<=0) return(RESET);
   if(CopyBuffer(ADX_Handle,MINUSDI_LINE,0,to_copy,pADX2)<=0) return(RESET);
//--- main calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      double ADX0 = pADX0[bar];
      double ADX1 = pADX1[bar];
      double ADX2 = pADX2[bar];
      //---
      if(ADX1>=ADX2)
        {
         ExtBuffer1[bar] = ADX0;
         ExtBuffer2[bar] = 0;
        }
      else
        {
         ExtBuffer1[bar] = 0;
         ExtBuffer2[bar] = ADX0;
        }
     }
//---    
   return(rates_total);
  }
//+------------------------------------------------------------------+
