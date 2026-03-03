//+------------------------------------------------------------------+
//|                                           Camarilla Equation.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2011, Nikolay Kositsin"
//---- link to the website of the author
#property link "farria@mail.redcom.ru"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- number of indicator buffers 10
#property indicator_buffers 10 
//---- 10 graphical plots are used in total
#property indicator_plots   10
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type1   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color1 Green
//---- the width of the indicator label
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "Camarilla H5"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type2   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color2 DarkSlateGray
//---- the width of the indicator label
#property indicator_width2  2
//---- displaying the indicator label
#property indicator_label2  "Camarilla H4"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type3   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color3 Lime
//---- the width of the indicator label
#property indicator_width3  1
//---- displaying the indicator label
#property indicator_label3  "Camarilla H3"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type4   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color4 Green
//---- the width of the indicator label
#property indicator_width4  1
//---- displaying the indicator label
#property indicator_label4  "Camarilla H2"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type5   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color5 DarkSlateGray
//---- the width of the indicator label
#property indicator_width5  1
//---- displaying the indicator label
#property indicator_label5  "Camarilla H1"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type6   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color6 Purple
//---- the width of the indicator label
#property indicator_width6  1
//---- displaying the indicator label
#property indicator_label6  "Camarilla L1"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type7   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color7 Crimson
//---- the width of the indicator label
#property indicator_width7  1
//---- displaying the indicator label
#property indicator_label7  "Camarilla L2"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type8   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color8 Red
//---- the width of the indicator label
#property indicator_width8  1
//---- displaying the indicator label
#property indicator_label8  "Camarilla L3"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type9   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color9 Crimson
//---- the width of the indicator label
#property indicator_width9  2
//---- displaying the indicator label
#property indicator_label9  "Camarilla 4"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a label
#property indicator_type10   DRAW_ARROW
//---- the following color is used for the indicator label
#property indicator_color10 Brown
//---- the width of the indicator label
#property indicator_width10  1
//---- displaying the indicator label
#property indicator_label10  "Camarilla L5"
//+-----------------------------------+
//|  enumeration declaration          |
//+-----------------------------------+
enum STYLE
  {
   STYLE_SOLID_,     // Solid line
   STYLE_DASH_,      // Dashed line
   STYLE_DOT_,       // Dotted line
   STYLE_DASHDOT_,   // Dot-dash line
   STYLE_DASHDOTDOT_ // Dot-dash line with double dots
  };
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input ENUM_TIMEFRAMES CPeriod=PERIOD_D1;
//----
input int  Symbol_H5 = 119;   // H5 level label
input int  Symbol_H4 = 167;   // H4 level label
input int  Symbol_H3 = 108;   // H3 level label
input int  Symbol_H2 = 158;   // H2 level label
input int  Symbol_H1 = 158;   // H1 level label
input int  Symbol_L1 = 158;   // L1 level label
input int  Symbol_L2 = 158;   // L2 level label
input int  Symbol_L3 = 108;   // L3 level label
input int  Symbol_L4 = 167;   // L4 level label
input int  Symbol_L5 = 119;   // L5 level label
//+-----------------------------------+
//---- declaration of dynamic arrays that 
//---- further will be used as indicator buffers
double H1_Buffer[],H2_Buffer[],H3_Buffer[],H4_Buffer[],H5_Buffer[];
double L1_Buffer[],L2_Buffer[],L3_Buffer[],L4_Buffer[],L5_Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- set dynamic arrays as indicator buffers
   SetIndexBuffer(0,H5_Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,H4_Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,H3_Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,H2_Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,H1_Buffer,INDICATOR_DATA);

   SetIndexBuffer(5,L1_Buffer,INDICATOR_DATA);
   SetIndexBuffer(6,L2_Buffer,INDICATOR_DATA);
   SetIndexBuffer(7,L3_Buffer,INDICATOR_DATA);
   SetIndexBuffer(8,L4_Buffer,INDICATOR_DATA);
   SetIndexBuffer(9,L5_Buffer,INDICATOR_DATA);

//---- indicator symbols
   PlotIndexSetInteger(0,PLOT_ARROW,Symbol_H5);
   PlotIndexSetInteger(1,PLOT_ARROW,Symbol_H4);
   PlotIndexSetInteger(2,PLOT_ARROW,Symbol_H3);
   PlotIndexSetInteger(3,PLOT_ARROW,Symbol_H2);
   PlotIndexSetInteger(4,PLOT_ARROW,Symbol_H1);
   PlotIndexSetInteger(5,PLOT_ARROW,Symbol_L1);
   PlotIndexSetInteger(6,PLOT_ARROW,Symbol_L2);
   PlotIndexSetInteger(7,PLOT_ARROW,Symbol_L3);
   PlotIndexSetInteger(8,PLOT_ARROW,Symbol_L4);
   PlotIndexSetInteger(9,PLOT_ARROW,Symbol_L5);

   for(int iii=0; iii>5; iii++)
     {
      //---- create label to display in DataWindow
      PlotIndexSetString(iii,PLOT_LABEL,"Camarilla "+"L"+string(iii+1));
      //---- restriction to draw empty values for the indicator
      PlotIndexSetDouble(iii,PLOT_EMPTY_VALUE,EMPTY_VALUE);
     }

   for(int iii=5; iii>10; iii++)
     {
      //---- create label to display in DataWindow
      PlotIndexSetString(iii,PLOT_LABEL,"Camarilla "+"H"+string(iii+1));
      //---- restriction to draw empty values for the indicator
      PlotIndexSetDouble(iii,PLOT_EMPTY_VALUE,EMPTY_VALUE);
     }

//---- name for the data window and the label for tooltips 
   IndicatorSetString(INDICATOR_SHORTNAME,"Camarilla Equation");
//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking correctness of the chart period
   if(Period()>=CPeriod)
     {
      Print("The chart period is more than necessary!!!");
      return(0);
     }

//---- checking the number of bars to be enough for the calculation
   if(rates_total<1) return(0);

//---- declaration of local variables
   int first;
   double iClose[],iHigh[],iLow[];
   double Level_H1,Level_H2,Level_H3,Level_H4,Level_H5;
   double Level_L1,Level_L2,Level_L3,Level_L4,Level_L5;

//---- indexing elements in arrays as timeseries  
//ArraySetAsSeries(iClose,true);
//ArraySetAsSeries(iHigh,true);
//ArraySetAsSeries(iLow,true);

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated==0) // checking for the first start of the indicator calculation
     {
      first=0; // starting index for calculation of all bars
     }
   else first=prev_calculated-1; // starting index for calculation of new bars
//---- main indicator calculation loop
   for(int bar=first; bar<rates_total; bar++)
     {
      //---- copy data from a day time frame to the variables arrays
      if(CopyClose(NULL,CPeriod,time[bar],2,iClose)<1)return(0);
      if(CopyHigh(NULL,CPeriod,time[bar],2,iHigh)<1)return(0);
      if(CopyLow(NULL,CPeriod,time[bar],2,iLow)<1)return(0);

      //---- calculation of Camarilla Equation levels
      Level_H1=iClose[0]+(iHigh[0]-iLow[0])*1.1/12;
      Level_H2=iClose[0]+(iHigh[0]-iLow[0])*1.1 /6;
      Level_H3=iClose[0]+(iHigh[0]-iLow[0])*1.1 /4;
      Level_H4=iClose[0]+(iHigh[0]-iLow[0])*1.1 /2;
      Level_H5=(iHigh[0]/iLow[0])*iClose[0];

      //---- calculation of Camarilla Equation levels
      Level_L1=iClose[0]-(iHigh[0]-iLow[0])*1.1 /12;
      Level_L2=iClose[0]-(iHigh[0]-iLow[0])*1.1 /6;
      Level_L3=iClose[0]-(iHigh[0]-iLow[0])*1.1 /4;
      Level_L4=iClose[0]-(iHigh[0]-iLow[0])*1.1 /2;
      Level_L5=iClose[0]-(Level_H5-iClose[0]);

      //---- loading the obtained values in the indicator buffers
      H1_Buffer[bar]=Level_H1;
      H2_Buffer[bar]=Level_H2;
      H3_Buffer[bar]=Level_H3;
      H4_Buffer[bar]=Level_H4;
      H5_Buffer[bar]=Level_H5;

      //---- loading the obtained values in the indicator buffers
      L1_Buffer[bar]=Level_L1;
      L2_Buffer[bar]=Level_L2;
      L3_Buffer[bar]=Level_L3;
      L4_Buffer[bar]=Level_L4;
      L5_Buffer[bar]=Level_L5;
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
