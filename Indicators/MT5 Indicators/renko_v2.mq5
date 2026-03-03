//+------------------------------------------------------------------+
//|                                                     Renko_v2.mq5 |
//|                           Copyright © 2005, TrendLaboratory Ltd. |
//|                                       E-mail: igorad2004@list.ru |
//|                                            Many Thanks To Konkop |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, TrendLaboratory Ltd."
#property link      "E-mail: igorad2004@list.ru"
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window
//---seven buffers are used for calculation of drawing of the indicator
#property indicator_buffers 7
//--- four plots are used
#property indicator_plots   4
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
//--- drawing the indicator as a one-color cloud
#property indicator_type1   DRAW_FILLING
//--- lavender color is used for the indicator
#property indicator_color1  clrLavender
//--- displaying the indicator label
#property indicator_label1  "Renko_v2"
//+----------------------------------------------+
//|  Indicator 2 drawing parameters              |
//+----------------------------------------------+
//--- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//--- BlueViolet color is used as the color of the bullish line of the indicator
#property indicator_color2  clrBlueViolet
//--- the line of the indicator 2 is a continuous curve
#property indicator_style2  STYLE_SOLID
//--- indicator 2 line width is equal to 2
#property indicator_width2  2
//--- display of the indicator bullish label
#property indicator_label2  "Upper Renko"
//+----------------------------------------------+
//|  Indicator 3 drawing parameters              |
//+----------------------------------------------+
//--- drawing indicator 3 as a line
#property indicator_type3   DRAW_LINE
//--- Magenta is used for the color of the bearish indicator line
#property indicator_color3  clrMagenta
//--- the line of the indicator 3 is a continuous curve
#property indicator_style3  STYLE_SOLID
//--- indicator 3 line width is equal to 2
#property indicator_width3  2
//--- display of the bearish indicator label
#property indicator_label3  "Lower Renko"
//+----------------------------------------------+
//|  Indicator 4 drawing parameters              |
//+----------------------------------------------+
//---- drawing indicator as a four-color histogram
#property indicator_type4 DRAW_COLOR_HISTOGRAM2
//--- the following colors are used in the four color histogram
#property indicator_color4 clrRed,clrPurple,clrGray,clrTeal,clrLime
//--- Indicator line is a solid one
#property indicator_style4 STYLE_SOLID
//--- indicator line width is 2
#property indicator_width4 2
//--- displaying the indicator label
#property indicator_label4 "Renko_BARS"
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint PeriodATR=10;
input double Katr=1.00;
input uint   Shift=1;   // Horizontal shift of the channel in bars 
//+----------------------------------------------+
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double Up1Buffer[],Dn1Buffer[];
double Up2Buffer[],Dn2Buffer[];
double UpIndBuffer[],DnIndBuffer[],ColorIndBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=int(PeriodATR+Shift);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,Up1Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Up1Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,Dn1Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Dn1Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(2,Up2Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Up2Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(3,Dn2Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Dn2Buffer,true);
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(4,UpIndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpIndBuffer,true);
//--- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(5,DnIndBuffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnIndBuffer,true);
//--- set dynamic array as a color index buffer   
   SetIndexBuffer(6,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- shifting the starting point of the indicator 1 drawing by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- shifting the starting point of the indicator 2 drawing by min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- shifting the indicator 3 horizontally by Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//--- shifting the starting point of the indicator 3 drawing by min_rates_total
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//--- shifting the indicator 3 horizontally by Shift
   PlotIndexSetInteger(3,PLOT_SHIFT,0);
//--- shifting the starting point of the indicator 4 drawing by min_rates_total
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
//--- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"Renko(",PeriodATR,", ",DoubleToString(Katr,4),", ",Shift,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &Open[],
                const double& High[],     // price array of price maximums for the indicator calculation
                const double& Low[],      // price array of price minimums for the indicator calculation
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total) return(0);
//--- declarations of local variables 
   int limit;
   double Up,Dn,Brick,AvgRange,dK,ATR;
   static double Up_,Dn_,Brick_;
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
      Up_=High[limit];
      Dn_=Low[limit];
      Brick_=Katr*(High[limit]-Low[limit]);
     }
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars
//--- indexing elements in arrays as in timeseries
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
//--- restoring the values of the variables
   Up=Up_;
   Dn=Dn_;
   Brick=Brick_;
//--- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      AvgRange=0;
      for(int iii=int(PeriodATR-1); iii>=0; iii--)
        {
         dK=1;
         AvgRange+=dK*MathAbs(High[bar+iii]-Low[bar+iii]);
        }
      ATR=AvgRange/PeriodATR;

      if(Close[bar]>Up+Brick)
        {
         if(Brick) Up+=MathRound((Close[bar]-Up)/Brick)*Brick;
         Brick=Katr*ATR;
         Dn=Up-Brick;
        }

      if(Close[bar]<Dn-Brick)
        {
         if(Brick) Dn-=MathRound((Dn-Close[bar])/Brick)*Brick;
         Brick=Katr*ATR;
         Up=Dn+Brick;
        }
      //---
      Up1Buffer[bar]=Up;
      Dn1Buffer[bar]=Dn;
      //---
      Up2Buffer[bar]=Up;
      Dn2Buffer[bar]=Dn;
      //--- saving values of variables
      if(bar)
        {
         Up_=Up;
         Dn_=Dn;
         Brick_=Brick;
        }
     }
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) limit-=int(Shift);
//--- the main loop of indicator bar coloring
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      int clr=2;
      UpIndBuffer[bar]=0.0;
      DnIndBuffer[bar]=0.0;

      if(Close[bar]>Up1Buffer[bar+Shift])
        {
         if(Open[bar]<Close[bar]) clr=4;
         else clr=3;
         UpIndBuffer[bar]=High[bar];
         DnIndBuffer[bar]=Low[bar];
        }
      //---
      if(Close[bar]<Dn1Buffer[bar+Shift])
        {
         if(Open[bar]>Close[bar]) clr=0;
         else clr=1;
         UpIndBuffer[bar]=High[bar];
         DnIndBuffer[bar]=Low[bar];
        }
      ColorIndBuffer[bar]=clr;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
