//+------------------------------------------------------------------+
//|                                             FisherCyberCycle.mq5 |
//|                                                                  |
//| Fisher Cyber Cycle                                               |
//|                                                                  |
//| Algorithm taken from book                                        |
//|     "Cybernetics Analysis for Stock and Futures"                 |
//| by John F. Ehlers                                                |
//|                                                                  |
//|                                              contact@mqlsoft.com |
//|                                          http://www.mqlsoft.com/ |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Coded by Witold Wozniak"
//---- author of the indicator
#property link      "www.mqlsoft.com"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- two buffers are used for calculation and drawing the indicator
#property indicator_buffers 2
//---- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Cyber Cycle indicator drawing parameters    |
//+----------------------------------------------+
//---- drawing the indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- red color is used as the color of the indicator bullish line
#property indicator_color1  Red
//---- the indicator 1 line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator 1 line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator line label
#property indicator_label1  "Fisher Cyber Cycle"
//+----------------------------------------------+
//|  Trigger indicator drawing parameters        |
//+----------------------------------------------+
//---- dawing the indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used for the indicator line
#property indicator_color2  Blue
//---- the indicator 2 line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator line label
#property indicator_label2  "Trigger"
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1 +0.7
#property indicator_level2  0.0
#property indicator_level3 -0.7
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input double Alpha=0.07; // Indicator ratio 
input int Length=8;      // Indicator period 
input int Shift=0;       // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double FishCCBuffer[];
double TriggerBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of global variables
int Count1[],Count2[];
double K0,K1,K2,K3,Smooth[],Cycle[],Value1[],Price[];
//+------------------------------------------------------------------+
//|  Recalculation of position of a newest element in the array      |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos1(int &CoArr[])// return the current value of the price series by the link
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max1=Length+1;
   Max2=Length+2;

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//----
  }
//+------------------------------------------------------------------+
//|  Recalculation of position of the newest element in the array    |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos2(int &CoArr[])// return the current value of the price series by the link
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max1=Length+2;
   Max2=Length+3;

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=Length+3;

//---- initialization of variables
   K0=MathPow((1.0 - 0.5*Alpha),2);
   K1=2.0;
   K2=2.0 *(1.0 - Alpha);
   K3=MathPow((1.0 - Alpha),2);

//---- memory distribution for variables' arrays  
   ArrayResize(Count1,Length+2);
   ArrayResize(Cycle,Length+2);
   ArrayResize(Count2,Length+3);
   ArrayResize(Value1,Length+3);
   ArrayResize(Price,Length+3);
   ArrayResize(Smooth,Length+3);

//---- set FishCCBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,FishCCBuffer,INDICATOR_DATA);
//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- performing shift of the beginning of counting of drawing the indicator 1 by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//---- set TriggerBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,TriggerBuffer,INDICATOR_DATA);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- performing shift of the beginning of counting of drawing the indicator 2 by min_rates_total+1
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total+1);

//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Fisher Cyber Cycle(",DoubleToString(Alpha,4),", ",Length,", ",Shift,")");
//---- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<min_rates_total) return(0);

//---- declarations of local variables 
   int first,bar;
   double hh,ll,tmp;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first=3; // starting index for calculation of all bars
      for(int numb=0; numb<Length+2; numb++) Count1[numb]=numb;
      for(int numb=0; numb<Length+3; numb++) Count2[numb]=numb;

     }
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- main indicator calculation loop
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      Price[Count2[0]]=(high[bar]+low[bar])/2.0;
      Smooth[Count2[0]]=(Price[Count2[0]]+2.0*Price[Count2[1]]+2.0*Price[Count2[2]]+Price[Count2[3]])/6.0;

      if(bar<3)
        {
         Recount_ArrayZeroPos1(Count1);
         Recount_ArrayZeroPos2(Count2);
         continue;
        }

      if(bar<min_rates_total) Cycle[Count1[0]]=(Price[Count1[0]]+2.0*Price[Count2[1]]+Price[Count2[2]])/4.0;
      else Cycle[Count1[0]]=K0*(Smooth[Count2[0]]-K1*Smooth[Count2[1]]+Smooth[Count2[2]])+K2*Cycle[Count1[1]]-K3*Cycle[Count1[2]];

      hh = Cycle[Count1[0]];
      ll = Cycle[Count1[0]];

      for(int iii=0; iii<Length; iii++)
        {
         tmp= Cycle[Count1[iii]];
         hh = MathMax(hh, tmp);
         ll = MathMin(ll, tmp);
        }

      if(hh!=ll) Value1[Count2[0]]=(Cycle[Count1[0]]-ll)/(hh-ll);
      else Value1[Count2[0]]=0.0;

      FishCCBuffer[bar]=(4.0*Value1[Count2[0]]+3.0*Value1[Count2[1]]+2.0*Value1[Count2[2]]+Value1[Count2[3]])/10.0;
      FishCCBuffer[bar] = 0.5 * MathLog((1.0 + 1.98 * (FishCCBuffer[bar] - 0.5)) / (1.0 - 1.98 * (FishCCBuffer[bar] - 0.5)));
      TriggerBuffer[bar]= FishCCBuffer[bar-1];

      if(bar<rates_total-1)
        {
         Recount_ArrayZeroPos1(Count1);
         Recount_ArrayZeroPos2(Count2);
        }

     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
