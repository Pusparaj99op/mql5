//+------------------------------------------------------------------+
//|                                           DarvasBoxes_System.mq5 |
//|                               Copyright © 2013, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2013, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "The breakthrough system using the DarvasBoxes indicator"
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
//--- WhiteSmoke color is used for the indicator
#property indicator_color1  clrWhiteSmoke
//--- displaying the indicator label
#property indicator_label1  "DarvasBoxes"
//+----------------------------------------------+
//|  Indicator 2 drawing parameters              |
//+----------------------------------------------+
//--- drawing indicator 2 as a line
#property indicator_type2   DRAW_LINE
//--- MediumSeaGreen color is used as the color of the bullish line of the indicator
#property indicator_color2  clrMediumSeaGreen
//--- the line of the indicator 2 is a continuous curve
#property indicator_style2  STYLE_SOLID
//--- indicator 2 line width is equal to 2
#property indicator_width2  2
//--- display of the indicator bullish label
#property indicator_label2  "Upper DarvasBoxes"
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
#property indicator_label3  "Lower DarvasBoxes"
//+----------------------------------------------+
//|  Indicator 4 drawing parameters              |
//+----------------------------------------------+
//---- drawing indicator as a four-color histogram
#property indicator_type4 DRAW_COLOR_HISTOGRAM2
//--- the following colors are used in the four color histogram
#property indicator_color4 clrDeepPink,clrPurple,clrGray,clrMediumBlue,clrDodgerBlue
//--- Indicator line is a solid one
#property indicator_style4 STYLE_SOLID
//--- indicator line width is 2
#property indicator_width4 2
//--- displaying the indicator label
#property indicator_label4 "DarvasBoxes_BARS"
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input bool symmetry=true;
input uint   Shift=2;     //  
//+----------------------------------------------+
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double Up1Buffer[],Dn1Buffer[];
double Up2Buffer[],Dn2Buffer[];
double UpIndBuffer[],DnIndBuffer[],ColorIndBuffer[];
//--- declaration of the integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//--- initialization of variables of data calculation start
   min_rates_total=int(2+Shift);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,Up1Buffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Up1Buffer,true);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,Dn1Buffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Dn1Buffer,true);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(2,Up2Buffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Up2Buffer,true);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(3,Dn2Buffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Dn2Buffer,true);
//--- Set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(4,UpIndBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpIndBuffer,true);
//--- Set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(5,DnIndBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnIndBuffer,true);
//--- Setting a dynamic array as a color index buffer   
   SetIndexBuffer(6,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- shifting the starting point of the indicator 1 drawing by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- shifting the indicator 2 horizontally by Shift
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
   StringConcatenate(shortname,"DarvasBoxes(",Shift,")");
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
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
//--- declaration of integer variables
   int limit;
//---- declaration of static variables
   static int state,STATE;
   static double box_top,box_bottom,BOX_TOP,BOX_BUTTOM;
//--- calculations of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total; // starting index for calculation of all bars
      BOX_TOP=high[limit+1];
      BOX_BUTTOM=low[limit+1];
      STATE=1;
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }
//--- Restore values of the variables
   state=STATE;
   box_top=BOX_TOP;
   box_bottom=BOX_BUTTOM;
//--- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      switch(state)
        {
         case 1:  box_top=high[bar]; if(symmetry)box_bottom=low[bar]; break;
         case 2:  if(box_top<=high[bar]) box_top=high[bar]; break;
         case 3:  if(box_top>high[bar]) box_bottom=low[bar]; else box_top=high[bar]; break;
         case 4:  if(box_top > high[bar]) {if(box_bottom >= low[bar]) box_bottom=low[bar];} else box_top=high[bar]; break;
         case 5:  if(box_top > high[bar]) {if(box_bottom >= low[bar]) box_bottom=low[bar];} else box_top=high[bar]; state=0; break;
        }
      //---
      Up1Buffer[bar]=box_top;
      Dn1Buffer[bar]=box_bottom;
      Up2Buffer[bar]=box_top;
      Dn2Buffer[bar]=box_bottom;
      state++;
      //--- save values of the variables before running at the current bar
      if(bar==1)
        {
         STATE=state;
         BOX_TOP=box_top;
         BOX_BUTTOM=box_bottom;
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
      //---
      if(close[bar]>Up1Buffer[bar+Shift])
        {
         if(open[bar]<close[bar]) clr=4;
         else clr=3;
         UpIndBuffer[bar]=high[bar];
         DnIndBuffer[bar]=low[bar];
        }
      //---
      if(close[bar]<Dn1Buffer[bar+Shift])
        {
         if(open[bar]>close[bar]) clr=0;
         else clr=1;
         UpIndBuffer[bar]=high[bar];
         DnIndBuffer[bar]=low[bar];
        }
      ColorIndBuffer[bar]=clr;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
