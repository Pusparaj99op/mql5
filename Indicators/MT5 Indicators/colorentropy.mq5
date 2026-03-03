//+------------------------------------------------------------------+
//|                                                 ColorEntropy.mq5 |
//|                                        Copyright © 2008,   Korey | 
//|                                                                  | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, Korey"
#property link ""
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers 2
#property indicator_buffers 2 
//---- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing indicator as a five-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- five colors are used in the histogram
#property indicator_color1 Gray,Lime,Green,Red,IndianRed
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying label of the signal line
#property indicator_label1  "Entropy"
//+----------------------------------------------+
//| Input parameters of the indicator            |
//+----------------------------------------------+
input int Period_=15; // period of the indicator 
input int Shift=0;    // horizontal shift of the indicator in bars 
//+----------------------------------------------+
//---- declaration of dynamic arrays that further
//---- will be used as indicator buffers
double ExtBuffer[],ColorExtBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- transformation of the dynamic array ExtBuffer into an indicator buffer
   SetIndexBuffer(0,ExtBuffer,INDICATOR_DATA);
//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Entropy(",Period_,")");
//---- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- create label to display in Data Window
   PlotIndexSetString(0,PLOT_LABEL,shortname);
//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,Period_);
//---- creating name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+4);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- turning a dynamic array into a color index buffer   
   SetIndexBuffer(1,ColorExtBuffer,INDICATOR_COLOR_INDEX);
//---- shifting the start of drawing of the indicator
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,Period_);
//---- shifting the indicator horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<Period_+begin+1) return(0);

//---- declarations of local variables 
   int first1,first2,bar,kkk;
//---- declaration of variables with a floating point                 
   double sumx,sumx2,avgx,rmsx,Price0,Price1,fPrice,P,G;

//---- calculation of the starting number 'first' for the cycle of recalculation of bars
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first1=Period_+begin; // starting number for calculation of all bars
      first2=first1+1;
     }
   else
     {
      first1=prev_calculated-1; // starting number for calculation of new bars
      first2=first1;
     }

//---- main cycle of calculation of the indicator
   for(bar=first1; bar<rates_total; bar++)
     {
      sumx=0;
      sumx2=0;
      //---       
      for(int jjj=0; jjj<Period_; jjj++)
        {
         kkk=bar-jjj;
         Price0 = price[kkk];
         Price1 = price[kkk - 1];

         fPrice=MathLog(Price0/Price1);
         sumx+=fPrice;
         sumx2+=fPrice*fPrice;
        }
      //----       
      avgx = sumx / Period_;
      rmsx = MathSqrt(sumx2/Period_);
      //----      
      P = (1.0 + avgx/rmsx)/2.0;
      G = P * MathLog(1.0 + rmsx) + (1.0 - P) * MathLog(1.0 - rmsx);
      ExtBuffer[bar]=G;
     }

//---- Main cycle of the indicator coloring
   for(bar=first2; bar<rates_total; bar++)
     {
      ColorExtBuffer[bar]=0;

      if(ExtBuffer[bar]>0)
        {
         if(ExtBuffer[bar]>ExtBuffer[bar-1]) ColorExtBuffer[bar]=1;
         if(ExtBuffer[bar]<ExtBuffer[bar-1]) ColorExtBuffer[bar]=2;
        }

      if(ExtBuffer[bar]<0)
        {
         if(ExtBuffer[bar]<ExtBuffer[bar-1]) ColorExtBuffer[bar]=3;
         if(ExtBuffer[bar]>ExtBuffer[bar-1]) ColorExtBuffer[bar]=4;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
