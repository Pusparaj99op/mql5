//+------------------------------------------------------------------+ 
//|                                                   PowerTrend.mq5 | 
//|                                           Copyright © 2007, SVS. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, SVS."
#property link      ""
//---- indicator version
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers 4
#property indicator_buffers 4 
//---- only four plots are used
#property indicator_plots   4
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a histogram
#property indicator_type1 DRAW_HISTOGRAM
#property indicator_type2 DRAW_HISTOGRAM
#property indicator_type3 DRAW_HISTOGRAM
#property indicator_type4 DRAW_HISTOGRAM
//---- the following colors are used in the indicator histogram
#property indicator_color1 MediumSeaGreen
#property indicator_color2 Blue
#property indicator_color3 Red
#property indicator_color4 Black
//---- the indicator line is a continuous one
#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_SOLID
#property indicator_style4 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 2
//---- displaying the indicator label
#property indicator_label1 "PowerTrend"
#property indicator_label2 "PowerTrend"
#property indicator_label3 "PowerTrend"
#property indicator_label4 "PowerTrend"
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1 0.0
#property indicator_levelcolor Magenta
#property indicator_levelstyle STYLE_DASHDOTDOT
//---- declaration of the constant for getting the command for the indicator recalculation back to the terminal
#define RESET 0
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum BandsMode     // Type of constant
  {
   BASE_LINE_ = 0, // Base line
   UPPER_BAND_,    // Upper band
   LOWER_BAND_     // Lower band
  };
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int Power_Period=6;                         // Indicator period
input ENUM_MA_METHOD Power_Method=MODE_LWMA;      // Smoothing method
input ENUM_APPLIED_PRICE Power_Price=PRICE_CLOSE; // Indicators price
//---- indicator buffers
double ExtMapBuffer1[],ExtMapBuffer2[],ExtMapBuffer3[],ExtMapBuffer4[];
//---- declaration of integer variables for the indicators periods values storage
int p1,p2;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- declaration of variables for the indicators handles
int MA0_Handle[];
//+------------------------------------------------------------------+    
//| PowerTrend indicator initialization function                     | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=Power_Period*2+1;
//---- initialization of variables  
   p2=Power_Period*2;
   p1=Power_Period*1;
//---- memory distribution for variables' arrays   
   ArrayResize(MA0_Handle,p2);
//---- get indicator's handle
   for(int count=0; count<p2; count++)
     {
      MA0_Handle[count]=iMA(NULL,0,count+1,0,Power_Method,Power_Price);
      if(MA0_Handle[count]==INVALID_HANDLE) Print(" Failed to get the handle of the iMA0 indicator");
     }
//---- set ExtMapBuffer1[] dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtMapBuffer1,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(ExtMapBuffer1,true);

//---- set ExtMapBuffer2[] dynamic array as an indicator buffer
   SetIndexBuffer(1,ExtMapBuffer2,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(ExtMapBuffer2,true);

//---- set ExtMapBuffer3[] dynamic array as an indicator buffer
   SetIndexBuffer(2,ExtMapBuffer3,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(ExtMapBuffer3,true);

//---- set ExtMapBuffer4[] dynamic array as an indicator buffer
   SetIndexBuffer(3,ExtMapBuffer4,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(ExtMapBuffer4,true);

//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"PowerTrend( ",
                     Power_Period,", ",EnumToString(Power_Method),", ",EnumToString(Power_Price)," )");
//---- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- initialization end
  }
//+------------------------------------------------------------------+  
//| PowerTrend iteration function                                    | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const int begin,          // bars reliable counting beginning index
                const double &price[])    // price array for the indicator calculation
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<min_rates_total)
      return(RESET);

   for(int count=0; count<p2; count++)
      if(BarsCalculated(MA0_Handle[count])<rates_total)
         return(RESET);
//---- declaration of integer variables
   int limit,bar;
//---- declaration of variables with a floating point  
   double vt0=0.0,vt1=0.0,vts,MA[];
   double vj1,vk1,vd1;
//---- calculations of the necessary amount of data to be copied and
//---- the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-1-begin-min_rates_total; // starting index for calculation of all bars

      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total+begin);
      PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total+begin);
      PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total+begin);
      PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total+begin);
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }
//---- indexing elements in the array as timeseries
   ArraySetAsSeries(price,true);
   ArraySetAsSeries(MA,true);
//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      vts=0;
      for(int c=1;c<=p2;c++)
        {
         if(CopyBuffer(MA0_Handle[c-1],0,bar,1,MA)<=0)return(RESET);
         vts+=MA[0];
         if(c==p1) vt0=(vts/p1)-MA[0];
         if(c==p2) vt1=(vts/p2)-MA[0];
        }

      vk1=(vt0+vt1)/2;
      vd1=(vt0/2);
      vj1=(vt1-vd1);

      ExtMapBuffer1[bar]=vt1;
      ExtMapBuffer2[bar]=vk1;
      ExtMapBuffer3[bar]=vd1;
      ExtMapBuffer4[bar]=vj1;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
