//+------------------------------------------------------------------+ 
//|                                                 Laguerre_ROC.mq5 | 
//|                           Copyright © 2005, Emerald King , MTE&I | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Emerald King , MTE&I"
#property link ""
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window 
//--- number of indicator buffers 3
#property indicator_buffers 3 
//--- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//| declaring constants                          |
//+----------------------------------------------+
#define RESET 0                        // A constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME "Laguerre_ROC"  // A constant for the indicator name
//+----------------------------------------------+
//| Indicator drawing parameters                 |
//+----------------------------------------------+
//--- drawing the indicator as a histogram
#property indicator_type1   DRAW_COLOR_HISTOGRAM2
//--- the following colors are used as the indicator colors
#property indicator_color1  clrDarkOrange,clrBrown,clrGray,clrBlue,clrDeepSkyBlue
//--- indicator 1 line width is equal to 5
#property indicator_width1  5
//--- displaying the indicator label
#property indicator_label1  INDICATOR_NAME
//+----------------------------------------------+
//| Indicator window borders parameters          |
//+----------------------------------------------+
#property indicator_maximum +1.1
#property indicator_minimum -0.1
//+----------------------------------------------+
//| Parameters of displaying horizontal levels   |
//+----------------------------------------------+
#property indicator_level1 0
#property indicator_levelcolor clrBlueViolet
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//| declaration of enumeration                   |
//+----------------------------------------------+  
enum WIDTH
  {
   Width_1=1, //1
   Width_2,   //2
   Width_3,   //3
   Width_4,   //4
   Width_5    //5
  };
//+----------------------------------------------+
//| declaration of enumeration                   |
//+----------------------------------------------+
enum STYLE
  {
   SOLID_,       // Solid line
   DASH_,        // Dashed line
   DOT_,         // Dotted line
   DASHDOT_,     // Dot-dash line
   DASHDOTDOT_   // Dot-dash line with double dots
  };
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint vPeriod=5;                 // Period
input double gamma=0.500;             // Averaging ratio                
input double UpLevel=0.75;            // Overbought level in %
input double DnLevel=0.25;            // Oversold level in %
input color UpLevelsColor=clrMagenta; // Overbought level color
input color DnLevelsColor=clrMagenta; // Oversold level color
input STYLE Levelstyle=DASH_;         // Style of levels
input WIDTH  LevelsWidth=Width_1;     // Width of levels
input int  Shift=0;                   // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as indicator buffers
double UpIndBuffer[],DnIndBuffer[],ColorIndBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables 
   min_rates_total=int(vPeriod+1);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,UpIndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpIndBuffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,DnIndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnIndBuffer,true);
//--- set dynamic array as a color index buffer   
   SetIndexBuffer(2,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,INDICATOR_NAME);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//--- line drawing parameters  
   IndicatorSetInteger(INDICATOR_LEVELS,3);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,UpLevel);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,UpLevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,Levelstyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,0,LevelsWidth);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,DnLevel);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,DnLevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,Levelstyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,1,LevelsWidth);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,0.5);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,clrGray);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,DASHDOTDOT_);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,2,0);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const int begin,          // number of beginning of reliable counting of bars
                const double &price[])    // price array for the indicator calculation
  {
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total+begin) return(RESET);
//--- declarations of static variables for storing real values of coefficients
   static double L0_,L1_,L2_,L3_,L0A_,L1A_,L2A_,L3A_;
//--- declarations of local variables 
   double L0,L1,L2,L3,L0A,L1A,L2A,L3A,CU,CD,ROC,LROC;
   int limit,bar,vbar,clr;
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1-begin; // starting index for calculation of all bars
      //--- starting initialization of calculated coefficients
      bar=limit+1;
      vbar=limit+int(vPeriod)+1;
      ROC=(price[bar]-price[vbar])/price[vbar]+_Point;
      L0_ = ROC;
      L1_ = ROC;
      L2_ = ROC;
      L3_ = ROC;
      L0A_ = ROC;
      L1A_ = ROC;
      L2A_ = ROC;
      L3A_ = ROC;
      //--- shifting the start of drawing the indicator 1
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total+begin);
     }
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars 
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(price,true);
//--- Restore values of the variables
   L0 = L0_;
   L1 = L1_;
   L2 = L2_;
   L3 = L3_;
   L0A = L0A_;
   L1A = L1A_;
   L2A = L2A_;
   L3A = L3A_;
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      L0A = L0;
      L1A = L1;
      L2A = L2;
      L3A = L3;
      vbar=bar+int(vPeriod);
      ROC=(price[bar]-price[vbar])/price[vbar]+_Point;
      //---
      L0 = (1 - gamma) * ROC + gamma * L0A;
      L1 = - gamma * L0 + L0A + gamma * L1A;
      L2 = - gamma * L1 + L1A + gamma * L2A;
      L3 = - gamma * L2 + L2A + gamma * L3A;
      //---
      CU = 0;
      CD = 0;
      //--- 
      if(L0 >= L1) CU  = L0 - L1; else CD  = L1 - L0;
      if(L1 >= L2) CU += L1 - L2; else CD += L2 - L1;
      if(L2 >= L3) CU += L2 - L3; else CD += L3 - L2;
      //---
      if(CU+CD!=0) LROC=CU/(CU+CD);
      //--- save values of the variables before running at the current bar
      if(bar==1)
        {
         L0_ = L0;
         L1_ = L1;
         L2_ = L2;
         L3_ = L3;
         L0A_ = L0A;
         L1A_ = L1A;
         L2A_ = L2A;
         L3A_ = L3A;
        }

      UpIndBuffer[bar]=LROC;
      DnIndBuffer[bar]=0.5;
      clr=2;
      if(LROC>UpLevel) clr=4;
      else if(LROC>0.5) clr=3;

      if(LROC<DnLevel) clr=0;
      else if(LROC<0.5) clr=1;

      ColorIndBuffer[bar]=clr;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
