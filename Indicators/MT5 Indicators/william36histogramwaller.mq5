//+------------------------------------------------------------------+ 
//|                                     William36HistogramWaller.mq5 | 
//|                                            Copyright © 2005, NNN | 
//|                                                                  | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, NNN"
#property link ""
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers is 2
#property indicator_buffers 2 
//--- one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET 0                                     // A constant for returning the indicator recalculation command to the terminal
#define INDICATOR_NAME "William36HistogramWaller"   // A constant for the indicator name
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//--- drawing the indicator as a histogram
#property indicator_type1   DRAW_COLOR_HISTOGRAM
//---- the following colors are used as the indicator colors
#property indicator_color1  clrMagenta,clrBrown,clrGray,clrTeal,clrLime
//--- indicator 1 line width is equal to 5
#property indicator_width1  5
//---- indicator bullish label display
#property indicator_label1  INDICATOR_NAME
//+----------------------------------------------+
//|  Indicator window borders parameters         |
//+----------------------------------------------+
#property indicator_maximum +50
#property indicator_minimum -50
//+----------------------------------------------+
//| Parameters of displaying horizontal levels   |
//+----------------------------------------------+
#property indicator_level1 0
#property indicator_levelcolor clrBlueViolet
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  declaration of enumerations                 |
//+----------------------------------------------+  
enum WIDTH
  {
   Width_1=1, // 1
   Width_2,   // 2
   Width_3,   // 3
   Width_4,   // 4
   Width_5    // 5
  };
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
input uint per=40;                  // Extrema finding period                        
input int UpLevel=+15;              // Overbought level (%)
input int DnLevel=-15;              // Oversold level (%)
input color UpLevelsColor=clrBlue;  // Overbought level color
input color DnLevelsColor=clrBlue;  // Oversold level color
input STYLE Levelstyle=DASH_;       // Style of the levels
input WIDTH  LevelsWidth=Width_1;   // Width of the levels
input int  Shift=0;                 // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//--- declaration of dynamic arrays that
//--- will be used as indicator buffers
double IndBuffer[],ColorIndBuffer[];
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- initialization of variables 
   min_rates_total=int(per);
//--- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//--- set dynamic array as a color index buffer   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);
//--- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,INDICATOR_NAME);
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- line drawing parameters  
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,UpLevel);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,UpLevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,Levelstyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,0,LevelsWidth);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,DnLevel);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,DnLevelsColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,Levelstyle);
   IndicatorSetInteger(INDICATOR_LEVELWIDTH,1,LevelsWidth);
//--- initialization end
   return(INIT_SUCCEEDED);
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
//--- declarations of local variables 
   double HH,LL,range,res;
   int limit,bar,clr;
//--- calculations of the necessary amount of data to be copied and
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
     }
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars 
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(close,true);
//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      HH=high[ArrayMaximum(high,bar,per)];
      LL=low[ArrayMinimum(low,bar,per)];
      range=HH-LL;
      if(range) res=50+(-100)*(HH-close[bar])/range;
      else res=0.0;
      IndBuffer[bar]=res;
      clr=2;
      if(res>UpLevel) clr=4;
      else if(res>0)  clr=3;

      if(res<DnLevel) clr=0;
      else if(res<0)  clr=1;

      ColorIndBuffer[bar]=clr;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
