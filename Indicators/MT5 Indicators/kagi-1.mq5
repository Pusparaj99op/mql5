//+------------------------------------------------------------------+
//|                                                       KAGI-1.mq5 |
//|                           Copyright © 2005, Инструменты трейдера |
//|                                   http://www.traderstools.h15.ru |
//+------------------------------------------------------------------+
//--- Copyright
#property copyright "Copyright © 2005, traderstools"
//--- link to the website of the author
#property link      "http://www.traderstools.h15.ru" 
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- number of indicator buffers 3
#property indicator_buffers 3 
//---- one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing the indicator as a multicolored line
#property indicator_type1   DRAW_COLOR_LINE
//---- the following colors are used in a three-color line
#property indicator_color1  clrMagenta,clrTeal
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- indicator line width is 2
#property indicator_width1  2
//--- displaying the indicator label
#property indicator_label1  "KAGI-1"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input bool Percent=true;
input uint Threshold=1;
input uint Size=12;
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double KagiBuffer[];
double IndBuffer[];
double ColorIndBuffer[];
double dThreshold;
//--- declaration of the integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//--- initialization of constants
   min_rates_total=2;
   dThreshold=Threshold/_Point;
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(2,KagiBuffer,INDICATOR_CALCULATIONS);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(KagiBuffer,true);
//--- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- initializations of a variable for the indicator short name
   string shortname="KAGI-1";
//--- Creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- Determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- initialization end
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
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

//--- declaration of variables with a floating point  
   double;

//--- declaration of integer variables
   int i,j,Ind,size1,Threshold1,KagiBuffShift=0;

//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(close,true);
   KagiBuffer[KagiBuffShift]=close[rates_total-1];

   for(int bar=rates_total-2; bar>=0; bar--)
     {
      if(Percent) Threshold1=int(close[bar]/100*dThreshold);
      else Threshold1=int(Threshold);
      //---
      if(!KagiBuffShift)
        {
         if(close[bar]>=KagiBuffer[KagiBuffShift]+Threshold1*_Point)
           {
            KagiBuffShift++;
            KagiBuffer[KagiBuffShift]=close[bar];
           }
         //---
         if(close[bar]<=KagiBuffer[KagiBuffShift]-Threshold1*_Point)
           {
            KagiBuffShift++;
            KagiBuffer[KagiBuffShift]=close[bar];
           }
        }
      //---
      if(KagiBuffShift>0)
        {
         if(KagiBuffer[KagiBuffShift]>KagiBuffer[KagiBuffShift-1])
           {
            if(close[bar]>KagiBuffer[KagiBuffShift]) KagiBuffer[KagiBuffShift]=close[bar];
            //---
            if(close[bar]<=KagiBuffer[KagiBuffShift]-Threshold1*_Point)
              {
               KagiBuffShift++;
               KagiBuffer[KagiBuffShift]=close[bar];
              }
           }
         //---
         if(KagiBuffer[KagiBuffShift]<KagiBuffer[KagiBuffShift-1])
           {
            if(close[bar]<KagiBuffer[KagiBuffShift]) KagiBuffer[KagiBuffShift]=close[bar];
            //---
            if(close[bar]>=KagiBuffer[KagiBuffShift]+Threshold1*_Point)
              {
               KagiBuffShift++;
               KagiBuffer[KagiBuffShift]=close[bar];
              }
           }
        }
     }
//--- 
   size1=int(MathMin(MathMax(3,Size),50));
//---
   for(i=rates_total-1; i>=0; i--) IndBuffer[i]=0.0;
//---
   for(i=0; i<=KagiBuffShift; i++) for(j=0; j<size1; j++)
     {
      int barX=MathMin(MathMax((KagiBuffShift-i)*size1-j,0),rates_total-1);
      IndBuffer[barX]=KagiBuffer[i];
      ColorIndBuffer[barX]=0;
     }
//---    
   if(KagiBuffer[0]<KagiBuffer[1]) Ind=1;
   else Ind=2;
//---    
   for(i=0; i<2; i++) for(j=0; j<size1; j++) if(Ind==1 || Ind==2)
     {
      int barX=MathMin(MathMax((KagiBuffShift-i)*size1-j,0),rates_total-1);
      ColorIndBuffer[barX]=1;
     }
//---
   for(i=2; i<=KagiBuffShift; i++)
     {
      if(Ind==2 && KagiBuffer[i]>KagiBuffer[i-1] && KagiBuffer[i]>KagiBuffer[i-2])
        {
         int barX=MathMin(MathMax((KagiBuffShift-i)*size1+1,0),rates_total-1);
         ColorIndBuffer[barX]=1;
         Ind=1;
        }

      if(Ind==1 && KagiBuffer[i]<KagiBuffer[i-1] && KagiBuffer[i]<KagiBuffer[i-2])
        {
         int barX=MathMin(MathMax((KagiBuffShift-i)*size1,0),rates_total-1);
         ColorIndBuffer[barX]=1;
         Ind=2;
        }

      if(Ind==1) for(j=0; j<size1; j++)
        {
         int barX=MathMin(MathMax((KagiBuffShift-i)*size1-j,0),rates_total-1);
         ColorIndBuffer[barX]=1;
        }
     }
//---    
   return(rates_total);
  }
//+------------------------------------------------------------------+
