//+------------------------------------------------------------------+
//|                                              EasyTrendVisualizer |
//|                                 Copyright © 2009-2011, EarnForex |
//|                                        http://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009-2011, EarnForex"
#property link      "http://www.earnforex.com"

#property description "Easy Trend Visualizer - displays trend strength, direction and"
#property description "support and resistance levels."
#property description "Alerts (set UseAlert = true):"
#property description " * ERV-HL - Horizontal line"
#property description " * ERV-AU - Arrow up"
#property description " * ERV-AD - Arrow down"

//---- indicator version number
#property version   "1.20"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers
#property indicator_buffers 2 
//---- only one plot is used
#property indicator_plots   1

//+-----------------------------------+
//|  declaration of constants         |
//+-----------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
#define Alvl  35.0
#define Alvl2 30.0

//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   4
#property indicator_color1 clrRed,clrLime
#property indicator_width1 2
#property indicator_color2 clrMediumSeaGreen
#property indicator_color3 clrRed
#property indicator_color4 clrIndigo
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 2
#property indicator_type1   DRAW_COLOR_HISTOGRAM2
#property indicator_style1  STYLE_SOLID
#property indicator_type2   DRAW_ARROW
#property indicator_style2  STYLE_SOLID
#property indicator_type3   DRAW_ARROW
#property indicator_style3  STYLE_SOLID
#property indicator_type4   DRAW_LINE
#property indicator_style4  STYLE_SOLID

//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input int ADXperiod1 = 10;
input int ADXperiod2 = 14;
input int ADXperiod3 = 20;
//+-----------------------------------+
//--
int MxP,MnP,MdP;

//---- buffers
double To[];
double Tc[];
double Color[];
double Up[];
double Dn[];
double Ex[];

//---- declaration of the integer variables for the start of data calculation
int min_rates_total;

//---- Declaration of integer variables for the indicator handles
int ADX1_Handle,ADX2_Handle,ADX3_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//----
   MxP = MathMax(MathMax(ADXperiod1, ADXperiod2), ADXperiod3);
   MnP = MathMin(MathMin(ADXperiod1, ADXperiod2), ADXperiod3);
   if(MxP==ADXperiod1) MdP=MathMax(ADXperiod2,ADXperiod3);
   else if(MxP==ADXperiod2) MdP=MathMax(ADXperiod1,ADXperiod3);
   else MdP=MathMax(ADXperiod2,ADXperiod1);

   min_rates_total=MxP+1;

//---- getting handle of the ADX indicator
   ADX1_Handle=iADX(Symbol(),PERIOD_CURRENT,MnP);
   if(ADX1_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the ADX 1 indicator");
      return;
     }

//---- getting handle of the ADX 2 indicator 
   ADX2_Handle=iADX(Symbol(),PERIOD_CURRENT,MdP);
   if(ADX2_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the ADX 2 indicator");
      return;
     }

//---- getting handle of the ADX 3 indicator
   ADX3_Handle=iADX(Symbol(),PERIOD_CURRENT,MxP);
   if(ADX3_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the ADX 3 indicator");
      return;
     }

   IndicatorSetString(INDICATOR_SHORTNAME,"ETV("+IntegerToString(MnP)+"/"+IntegerToString(MdP)+"/"+IntegerToString(MxP)+")");

   SetIndexBuffer(0,To,INDICATOR_DATA);
   SetIndexBuffer(1,Tc,INDICATOR_DATA);
   SetIndexBuffer(2,Color,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3,Up,INDICATOR_DATA);
   SetIndexBuffer(4,Dn,INDICATOR_DATA);
   SetIndexBuffer(5,Ex,INDICATOR_DATA);

   ArraySetAsSeries(To,true);
   ArraySetAsSeries(Tc,true);
   ArraySetAsSeries(Color,true);
   ArraySetAsSeries(Up,true);
   ArraySetAsSeries(Dn,true);
   ArraySetAsSeries(Ex,true);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);

   PlotIndexSetInteger(1,PLOT_ARROW,225);
   PlotIndexSetInteger(2,PLOT_ARROW,226);

   PlotIndexSetString(1,PLOT_LABEL,"Up");
   PlotIndexSetString(2,PLOT_LABEL,"Down");
   PlotIndexSetString(3,PLOT_LABEL,"End");
//----
  }
//+------------------------------------------------------------------+
//| Custom Easy Trend Visualizer                                     |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking for the sufficiency of the number of bars for the calculation
   if(BarsCalculated(ADX1_Handle)<rates_total
      || BarsCalculated(ADX2_Handle)<rates_total
      || BarsCalculated(ADX3_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);

   double ADXArray1[],ADXArray2[],ADXArray3[],ADXArray1_1[],ADXArray1_2[];
   int limit,bar,to_copy;

//---- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total; // starting index for the calculation of all bars
     }
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars

//---- calculation of the necessary amount of data to be copied
   to_copy=limit+2;

//---- copy newly appeared data into the arrays
   if(CopyBuffer(ADX1_Handle,MAIN_LINE,0,to_copy,ADXArray1)<=0) return(RESET);
   if(CopyBuffer(ADX1_Handle,PLUSDI_LINE,0,to_copy,ADXArray1_1)<=0) return(RESET);
   if(CopyBuffer(ADX1_Handle,MINUSDI_LINE,0,to_copy,ADXArray1_2)<=0) return(RESET);
   if(CopyBuffer(ADX2_Handle,MAIN_LINE,0,to_copy,ADXArray2)<=0) return(RESET);
   if(CopyBuffer(ADX3_Handle,MAIN_LINE,0,to_copy,ADXArray3)<=0) return(RESET);

   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(ADXArray1,true);
   ArraySetAsSeries(ADXArray2,true);
   ArraySetAsSeries(ADXArray3,true);
   ArraySetAsSeries(ADXArray1_1,true);
   ArraySetAsSeries(ADXArray1_2,true);

//---- main cycle of calculation of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      bool f1=false,f2=false,f3=false;

      To[bar]=0;
      Tc[bar]=0;
      Up[bar]=0;
      Dn[bar]=0;
      Ex[bar]=0;

      int bar1=bar+1;

      if(ADXArray1[bar1]<ADXArray1[bar]) f1=true;
      if(ADXArray2[bar1]<ADXArray2[bar]) f2=true;
      if(ADXArray3[bar1]<ADXArray3[bar]) f3=true;

      if(f1 && f2 && f3 && ADXArray1[bar]>Alvl && ADXArray2[bar]>Alvl2)
        {
         double di = ADXArray1_1[bar]-ADXArray1_2[bar];
         double hi = MathMax(Open[bar],Close[bar]);
         double lo = MathMin(Open[bar],Close[bar]);
         double op = Open[bar];

         if(di>0)
           {
            To[bar]=lo;
            Tc[bar]=hi;
            if(!To[bar1]) Up[bar]=op;
            Color[bar]=1;
           }
         else
           {
            To[bar]=hi;
            Tc[bar]=lo;
            if(!To[bar1]) Dn[bar]=op;
            Color[bar]=0;
           }
        }
      else
        {
         if(To[bar1]) Ex[bar]=Close[bar+1];
         else Ex[bar]=Ex[bar1];
        }
     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
