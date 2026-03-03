//+------------------------------------------------------------------+
//|                                                   Fisher RVI.mq5 |
//|                                                                  |
//| Fisher RVI                                                       |
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
//| Fisher RVI indicator drawing parameters      |
//+----------------------------------------------+
//---- drawing the indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- red color is used as the color of the indicator line
#property indicator_color1  Red
//---- the indicator 1 line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator 1 line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "Fisher RVI"
//+----------------------------------------------+
//| Trigger indicator drawing parameters         |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used for the indicator line
#property indicator_color2  Blue
//---- the indicator 2 line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator label
#property indicator_label2  "Trigger"
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1 0.0
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int Length=8;  // Indicator period 
input int Shift=0;   // Horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double FRVIBuffer[];
double TriggerBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of global variables
int Count1[],Count2[];
double RVI[],Value1[],Value2[],Value3[];
//+------------------------------------------------------------------+
//|  Recalculation of position of the newest element in the array    |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos1(int &CoArr[])// Return the current value of the price series by the link
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max1=Length-1;
   Max2=Length;

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
void Recount_ArrayZeroPos2 (int &CoArr[]) // Return the current value of the price series by the link
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max1=3;
   Max2=4;

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

//---- memory distribution for variables' arrays  
   ArrayResize(Count1,Length);
   ArrayResize(Value1,Length);
   ArrayResize(Value2,Length);
   ArrayResize(RVI,Length);
   ArrayResize(Count2,4);
   ArrayResize(Value3,4);

//---- set FRVIBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,FRVIBuffer,INDICATOR_DATA);
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
   StringConcatenate(shortname,"Fisher RVI(",Length,", ",Shift,")");
//---- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
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
   double Num,Denom,hh,ll,tmp,rvi,Value4;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first=3; // starting index for calculation of all bars
      for(int numb=0; numb<Length; numb++) Count1[numb]=numb;
      for(int numb=0; numb<4; numb++) Count2[numb]=numb;

     }
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- main indicator calculation loop
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      Value1[Count1[0]]=((close[bar]-open[bar])+
                         2.0 *(close[bar-1]-open[bar-1])+
                         2.0 *(close[bar-2] - open[bar-2]) +
                         (close[bar-3]-open[bar-3]))/6.0;

      Value2[Count1[0]]=((high[bar]-low[bar])+
                         2.0 * (high[bar-1] - low[bar-1]) +
                         2.0 * (high[bar-2] - low[bar-2]) +
                         (high[bar-3]-low[bar-3]))/6.0;

      if(bar<Length+4)
        {
         Recount_ArrayZeroPos1(Count1);
         Recount_ArrayZeroPos2(Count2);
         continue;
        }

      Num=0.0;
      Denom=0.0;

      for(int iii=0; iii<Length; iii++)
        {
         Num+=Value1[Count1[iii]];
         Denom+=Value2[Count1[iii]];
        }

      if(Denom!=0.0) rvi=Num/Denom;
      else rvi=0.0;

      RVI[Count1[0]]=rvi;
      hh = rvi;
      ll = rvi;

      for(int iii=0; iii<Length; iii++)
        {
         tmp= RVI[Count1[iii]];
         hh = MathMax(hh, tmp);
         ll = MathMin(ll, tmp);
        }

      if(hh != ll) Value3[Count2[0]] =(rvi-ll)/(hh-ll);
      else Value3[Count2[0]]= 0.0;

      Value4 = (4.0 * Value3[Count2[0]] + 3.0 * Value3[Count2[1]] + 2.0 * Value3[Count2[2]] + Value3[Count2[3]]) / 10.0;
      FRVIBuffer[bar] = 0.5 * MathLog((1.0 + 1.98 * (Value4 - 0.5)) / (1.0 - 1.98 * (Value4 - 0.5)));
      TriggerBuffer[bar] = FRVIBuffer[bar-1];

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
