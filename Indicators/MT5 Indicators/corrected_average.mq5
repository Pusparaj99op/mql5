//+------------------------------------------------------------------+
//|                                            Corrected Average.mq5 |
//|    Copyright 2012, Prof. A.Uhl, FinGeR alias Alexander Piechotta |
//|                                  http://www.metatrader-wiki.com  |
//+------------------------------------------------------------------+

//Update Version 2.2 August 2012
//Corrected Average(CA) by A.Uhl

//+------------------------------------------------------------------+
//| The strengths of the corrected Average(CA) is that the current   |
//| value of the time series one of the current Volatility-dependent |
//| threshold must exceed that. so that the filter rises and falls,  |
//| allowing false signals be avoided in trend is weak phase.        |
//+------------------------------------------------------------------+

#property copyright "FinGeR alias Alexander Piechotta"
#property link      "http://www.metatrader-wiki.com"
#property version   "2.2"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1

//--- plot Corrected Average(CA)
#property indicator_label1  "Corrected Average (CA)"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGold
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- input parameters
input int                 Periode     =35;          //Averaging Period
input ENUM_MA_METHOD      Methode     =MODE_SMA;    //Smoothing Type
input ENUM_APPLIED_PRICE  appliedPrice=PRICE_CLOSE; //Type of Price
input int                 Shift       =0;           //Shift of indicator 

//--- indicator buffers
double               CABuffer[];
double               MABuffer[];
double               StdDevBuffer[];

//--- handles
int                  MA_handle,StdDev_handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,CABuffer,INDICATOR_DATA);
   IndicatorSetString(INDICATOR_SHORTNAME,"Corrected Average (CA) ("+DoubleToString(Periode,1)+")");

   SetIndexBuffer(1,MABuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,StdDevBuffer,INDICATOR_CALCULATIONS);

//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,Periode);
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);

//--- get MA handle
   MA_handle=iMA(Symbol(),Period(),Periode,Shift,Methode,appliedPrice);
   StdDev_handle=iStdDev(Symbol(),Period(),Periode,Shift,Methode,appliedPrice);

   ArraySetAsSeries(MABuffer,true);
   ArraySetAsSeries(CABuffer,true);
   ArraySetAsSeries(StdDevBuffer,true);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {

//--- check for data
   if(rates_total<Periode)
      return(0);

//--- not all data may be calculated
   int calculated=BarsCalculated(MA_handle);
   if(calculated<rates_total)
     {
      Print("Not all data of MA_handle is calculated (",calculated," bars ). Error",GetLastError());
      return(0);
     }

//--- not all data may be calculated
   calculated=BarsCalculated(StdDev_handle);
   if(calculated<rates_total)
     {
      Print("Not all data of StdDev_handle is calculated (",calculated," bars ). Error",GetLastError());
      return(0);
     }

//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }

//--- get MA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(MA_handle,0,0,to_copy,MABuffer)<=0)
     {
      Print("Getting fast MA failed! Error",GetLastError());
      return(0);
     }

//--- get StdDev buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(StdDev_handle,0,0,to_copy,StdDevBuffer)<=0)
     {
      Print("Getting StdDev failed! Error",GetLastError());
      return(0);
     }

   double v1,v2,k;

   int counted=prev_calculated;
   if(counted<0) return(-1);
   if(counted>0) counted--;
   int limit=Bars(Symbol(),Period())-counted;

//--- calculate
   for(int i=limit-1; i>=0 && !IsStopped(); i--)
     {
      if(i==Bars(Symbol(),Period())-1)
        {
         CABuffer[i]=MABuffer[i];
         continue;
        }

      v1=MathPow(StdDevBuffer[i],2);
      v2=MathPow(CABuffer[i+1] - MABuffer[i],2);

      //----
      k=0;
      if(v2<v1 || v2==0) k=0; else k=1-v1/v2;

      CABuffer[i]=CABuffer[i+1]+k*(MABuffer[i]-CABuffer[i+1]);

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
