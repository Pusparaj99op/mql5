//+------------------------------------------------------------------+ 
//|                                                      Pivot-2.mq5 | 
//|                                       Copyright © 2004, Aborigen | 
//|                                          http://forex.kbpauk.ru/ | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2004, Aborigen"
#property link "http://forex.kbpauk.ru/"
//--- Indicator version
#property version   "1.00"
#property description "Support and resistance lines"
//--- drawing the indicator in the main window
#property indicator_chart_window
//--- number of indicator buffers is 7
#property indicator_buffers 7 
//--- seven plots are used
#property indicator_plots   7
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET 0                      // A constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME "Pivot-2"     // A constant for the indicator name
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//--- the color of the indicator
#property indicator_color1  clrTeal
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- indicator 1 line width is equal to 2
#property indicator_width1  2
//--- displaying the indicator label
#property indicator_label1  "Res 3"
//+----------------------------------------------+
//|  Indicator 2 drawing parameters              |
//+----------------------------------------------+
//--- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//--- the color of the indicator
#property indicator_color2  clrDodgerBlue
//---- the indicator line is a continuous curve
#property indicator_style2  STYLE_SOLID
//--- indicator 2 line width is equal to 2
#property indicator_width2  2
//--- displaying the indicator label
#property indicator_label2  "Res 2"
//+----------------------------------------------+
//|  Indicator 3 drawing parameters              |
//+----------------------------------------------+
//--- drawing indicator 3 as a line
#property indicator_type3   DRAW_LINE
//--- the color of the indicator
#property indicator_color3  clrLime
//---- the indicator line is a continuous curve
#property indicator_style3  STYLE_SOLID
//--- indicator 3 line width is equal to 2
#property indicator_width3  2
//--- displaying the indicator label
#property indicator_label3  "Res 1"
//+----------------------------------------------+
//|  Indicator 4 drawing parameters              |
//+----------------------------------------------+
//--- drawing the indicator 4 as a line
#property indicator_type4   DRAW_LINE
//--- the color of the indicator
#property indicator_color4  clrBlueViolet
//---- the indicator line is a continuous curve
#property indicator_style4  STYLE_SOLID
//--- indicator 1 line width is equal to 4
#property indicator_width4  4
//--- displaying the indicator label
#property indicator_label4  "Pivot"
//+----------------------------------------------+
//|  Indicator 5 drawing parameters              |
//+----------------------------------------------+
//--- drawing the indicator 5 as a line
#property indicator_type5   DRAW_LINE
//--- the color of the indicator
#property indicator_color5  clrRed
//---- the indicator line is a continuous curve
#property indicator_style5  STYLE_SOLID
//--- indicator 5 line width is equal to 2
#property indicator_width5  2
//--- displaying the indicator label
#property indicator_label5  "Sup 1"
//+----------------------------------------------+
//|  Indicator 6 drawing parameters              |
//+----------------------------------------------+
//--- Drawing indicator 6 as line
#property indicator_type6   DRAW_LINE
//--- the color of the indicator
#property indicator_color6  clrMagenta
//---- the indicator line is a continuous curve
#property indicator_style6  STYLE_SOLID
//--- indicator 6 line width is equal to 2
#property indicator_width6  2
//--- displaying the indicator label
#property indicator_label6  "Sup 2"
//+----------------------------------------------+
//|  Indicator 7 drawing parameters              |
//+----------------------------------------------+
//--- drawing the indicator 7 as a line
#property indicator_type7   DRAW_LINE
//--- the color of the indicator
#property indicator_color7  clrBrown
//---- the indicator line is a continuous curve
#property indicator_style7  STYLE_SOLID
//--- indicator 7 line width is equal to 2
#property indicator_width7  2
//--- displaying the indicator label
#property indicator_label7  "Sup 3"
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input int Shift=0;                 // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double Ind1Buffer[];
double Ind2Buffer[];
double Ind3Buffer[];
double Ind4Buffer[];
double Ind5Buffer[];
double Ind6Buffer[];
double Ind7Buffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- Checking the correctness of the indicator timeframe
   if(!TimeFramesCheck(INDICATOR_NAME,Period())) return(INIT_FAILED);
//--- initialization of variables 
   min_rates_total=2*PeriodSeconds(PERIOD_D1)/PeriodSeconds(Period());
//--- Initialize indicator buffers
   IndInit(0,Ind1Buffer,0.0,min_rates_total,Shift);
   IndInit(1,Ind2Buffer,0.0,min_rates_total,Shift);
   IndInit(2,Ind3Buffer,0.0,min_rates_total,Shift);
   IndInit(3,Ind4Buffer,0.0,min_rates_total,Shift);
   IndInit(4,Ind5Buffer,0.0,min_rates_total,Shift);
   IndInit(5,Ind6Buffer,0.0,min_rates_total,Shift);
   IndInit(6,Ind7Buffer,0.0,min_rates_total,Shift);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",Shift,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//---
   Comment("");
//---
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
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
   if(rates_total<min_rates_total) return(RESET);
//--- declaration of integer variables
   int limit,bar;
//--- declaration of variables with a floating point  
   double P,S1,R1,S2,R2,S3,R3;
   static double LastHigh,LastLow;
//---    
   datetime iTime[1];
   static uint LastCountBar;
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
      LastCountBar=rates_total;
      LastHigh=0;
      LastLow=999999999;
     }
   else limit=int(LastCountBar)+rates_total-prev_calculated; // starting index for calculation of new bars 
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(open,true);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Ind1Buffer[bar]=0.0;
      Ind2Buffer[bar]=0.0;
      Ind3Buffer[bar]=0.0;
      Ind4Buffer[bar]=0.0;
      Ind5Buffer[bar]=0.0;
      Ind6Buffer[bar]=0.0;
      Ind7Buffer[bar]=0.0;

      if(high[bar+1]>LastHigh) LastHigh=high[bar+1];
      if(low[bar+1]<LastLow) LastLow=low[bar+1];
      //--- copy newly appeared data in the array
      if(CopyTime(Symbol(),PERIOD_D1,time[bar],1,iTime)<=0) return(RESET);

      if(time[bar]>=iTime[0] && time[bar+1]<iTime[0])
        {
         LastCountBar=bar;
         Ind1Buffer[bar+1]=0.0;
         Ind2Buffer[bar+1]=0.0;
         Ind3Buffer[bar+1]=0.0;
         Ind4Buffer[bar+1]=0.0;
         Ind5Buffer[bar+1]=0.0;
         Ind6Buffer[bar+1]=0.0;
         Ind7Buffer[bar+1]=0.0;

         P=(LastHigh+LastLow+close[bar+1])/3;
         double P2=2*P;
         R1=P2-LastLow;
         S1=P2-LastHigh;
         double diff=LastHigh-LastLow;
         R2=P+diff;
         S2=P-diff;
         R3=P2+(LastHigh-2*LastLow);
         S3=P2-(2*LastHigh-LastLow);
         LastLow=open[bar];
         LastHigh=open[bar];
         //--- Loading the obtained values in the indicator buffers
         Ind1Buffer[bar]=R3;
         Ind2Buffer[bar]=R2;
         Ind3Buffer[bar]=R1;
         Ind4Buffer[bar]=P;
         Ind5Buffer[bar]=S1;
         Ind6Buffer[bar]=S2;
         Ind7Buffer[bar]=S3;
         //--- печать комментария
         Comment("\n",
                 "Res3=",DoubleToString(R3,_Digits),"\n",
                 "Res2=",DoubleToString(R2,_Digits),"\n",
                 "Res1=",DoubleToString(R1,_Digits),"\n",
                 "Pivot=",DoubleToString(P,_Digits),"\n",
                 "Sup1=",DoubleToString(S1,_Digits),"\n",
                 "Sup2=",DoubleToString(S2,_Digits),"\n",
                 "Sup3=",DoubleToString(S3,_Digits));
        }
      if(Ind1Buffer[bar+1] && !Ind1Buffer[bar])
        {
         Ind1Buffer[bar]=Ind1Buffer[bar+1];
         Ind2Buffer[bar]=Ind2Buffer[bar+1];
         Ind3Buffer[bar]=Ind3Buffer[bar+1];
         Ind4Buffer[bar]=Ind4Buffer[bar+1];
         Ind5Buffer[bar]=Ind5Buffer[bar+1];
         Ind6Buffer[bar]=Ind6Buffer[bar+1];
         Ind7Buffer[bar]=Ind7Buffer[bar+1];
        }
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Indicator buffer initialization                                  |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[],double Empty_Value,int Draw_Begin,int nShift)
  {
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(Number,Buffer,INDICATOR_DATA);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//---- shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Buffer,true);
//---
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(string IndName,
                     ENUM_TIMEFRAMES TFrame)//Indicator chart period
  {
//--- Checking correctness of the chart periods
   if(TFrame>=PERIOD_H12)
     {
      Print("Chart period for indicator "+IndName+" cannot be greater than H12");
      return(RESET);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
