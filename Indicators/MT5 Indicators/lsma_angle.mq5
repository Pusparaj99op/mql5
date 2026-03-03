//+------------------------------------------------------------------+
//|                                                   LSMA_Angle.mq4 |
//|                                                           MrPip  |
//|                                                                  |
//| You can use this indicator to measure when the LSMA angle is     |
//| "near zero". AngleTreshold determines when the angle for the     |
//| LSMA is "about zero": This is when the value is between          |
//| [-AngleTreshold, AngleTreshold] (or when the histogram is red).  |
//|   LSMAPeriod: LSMA period                                        |
//|   AngleTreshold: The angle value is "about zero" when it is      |
//|     between the values [-AngleTreshold, AngleTreshold].          |      
//|   StartLSMAShift: The starting point to calculate the            |   
//|     angle. This is a shift value to the left from the            |
//|     observation point. Should be StartEMAShift > EndEMAShift.    | 
//|   EndLSMAShift: The ending point to calculate the                |
//|     angle. This is a shift value to the left from the            | 
//|     observation point. Should be StartEMAShift > EndEMAShift.    |
//|                                                                  |
//|   Modified by MrPip from EMAAngle by jpkfox                      |
//|       Red for down                                               |
//|       Yellow for near zero                                       |
//|       Green for up                                               |   
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Robert L. Hill aka MrPip"
#property link "" 
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window 
//--- number of indicator buffers is 2
#property indicator_buffers 2 
//--- one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Parameters of indicator drawing   |
//+-----------------------------------+
//---- drawing indicator as a four-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//--- the following colors are used in the four color histogram
#property indicator_color1 clrMagenta,clrViolet,clrGray,clrDodgerBlue,clrBlue
//--- Indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//--- indicator line width is 2
#property indicator_width1 2
//--- displaying the indicator label
#property indicator_label1 "LSMA_Angle"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input uint LSMAPeriod=25;
input int  AngleTreshold=15.0; // Trigger threshold
input uint StartLSMAShift=4;
input uint EndLSMAShift=0;
//+-----------------------------------+
double mFactor,dFactor,ShiftDif;
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double IndBuffer[],ColorIndBuffer[];
//+------------------------------------------------------------------+
//|  LSMA - Least Squares Moving Average function calculation        |
//+------------------------------------------------------------------+
double LSMA(int Rperiod,const double &Close[],int shift)
  {
//---
   int iii;
   double sum;
   int length;
   double lengthvar;
   double tmp;
   double wt;
//---
   length=Rperiod;
//--- 
   sum=0;
   for(iii=length; iii>=1; iii--)
     {
      lengthvar = length+1;
      lengthvar/= 3;
      tmp=(iii-lengthvar)*Close[length-iii+shift];
      sum+=tmp;
     }
   wt=sum*6/(length*(length+1));
//---
   return(wt);
  }
//+------------------------------------------------------------------+    
//| LSMA_Angle indicator initialization function                     | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables of data calculation start
   min_rates_total=int(MathMax(LSMAPeriod+StartLSMAShift,LSMAPeriod+EndLSMAShift));
   dFactor = 2*3.14159/180.0;
   mFactor = 100000.0;
   string Sym = StringSubstr(Symbol(),3,3);
   if (Sym == "JPY") mFactor = 1000.0;
   ShiftDif = StartLSMAShift-EndLSMAShift;
   mFactor /= ShiftDif; 
//---
   if(EndLSMAShift>=StartLSMAShift)
     {
      Print("Error: EndLSMAShift >= StartLSMAShift");
      return(INIT_FAILED);
     }
//--- Set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//--- Setting a dynamic array as a color index buffer   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"LSMA_Angle");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- the number of the indicator 9 horizontal levels   
   IndicatorSetInteger(INDICATOR_LEVELS,2);
//--- values of the indicator horizontal levels   
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,+AngleTreshold);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,-AngleTreshold);
//--- gray and magenta colors are used for horizontal levels lines  
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrTeal);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrTeal);
//--- Short dot-dash is used for the horizontal level line  
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DASHDOTDOT);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| LSMA_Angle iteration function                                    | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total) return(0);
//--- declarations of local variables 
   int limit,bar,clr;
   double fEndMA,fStartMA,fAngle;
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-1-min_rates_total; // starting index for the calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }   
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(close,true);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      fEndMA=LSMA(LSMAPeriod,close,bar+EndLSMAShift);
      fStartMA=LSMA(LSMAPeriod,close,bar+StartLSMAShift);
      fAngle=mFactor*(fEndMA-fStartMA)/2;
      IndBuffer[bar]=fAngle;
     }
   if(prev_calculated>rates_total || prev_calculated<=0) limit--;
//--- main cycle of the indicator coloring
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      clr=2;
      if(IndBuffer[bar]>AngleTreshold)
        {
         if(IndBuffer[bar]>IndBuffer[bar+1]) clr=4;
         if(IndBuffer[bar]<IndBuffer[bar+1]) clr=3;
        }
      if(IndBuffer[bar]<-AngleTreshold)
        {
         if(IndBuffer[bar]<IndBuffer[bar+1]) clr=0;
         if(IndBuffer[bar]>IndBuffer[bar+1]) clr=1;
        }
      ColorIndBuffer[bar]=clr;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
