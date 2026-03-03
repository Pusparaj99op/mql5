//+------------------------------------------------------------------+
//|                                                Bubbles_Drops.mq5 |
//|                                              Maxaxa Angry Hunter |
//|                                                        mg@dsr.ru |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Maxaxa Angry Hunter"
#property link      "mg@dsr.ru"
//---- description of the indicator
#property description "Bubbles&Drops"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//----two buffers are used for calculation of drawing of the indicator
#property indicator_buffers 2
//---- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//| Bubbles indicator drawing parameters         |
//+----------------------------------------------+
//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_LINE
//---- red color is used as the color of the bullish line of the indicator
#property indicator_color1  Red
//---- line of the indicator 1 is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- thickness of line of the indicator 1 is equal to 1
#property indicator_width1  1
//---- displaying of the bullish label of the indicator
#property indicator_label1  "Bubbles"
//+----------------------------------------------+
//| Drops indicator drawing parameters           |
//+----------------------------------------------+
//---- dawing the indicator 2 as a line
#property indicator_type2   DRAW_LINE
//---- blue color is used for the indicator bearish line
#property indicator_color2  Blue
//---- the indicator 2 line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying of the bearish label of the indicator
#property indicator_label2  "Drops"
//+----------------------------------------------+
//|  Declaration of constants                    |
//+----------------------------------------------+
#define RESET 0 // the constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input uint historyDeep=100; // Number of bars in history
input uint future=10;       // How many bars are shown after the chart
//+----------------------------------------------+
//---- declaration of dynamic arrays that further 
//---- will be used as indicator buffers
double Buffer[];
double FutBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- Declaration of global variables
double temp[];
double divider=10000;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=int(historyDeep+future+1);
   divider=MathPow(10,_Digits);

//---- Memory distribution for variables' arrays  
   ArrayResize(temp,min_rates_total);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,Buffer,INDICATOR_DATA);
//---- performing shift of the beginning of counting of drawing the indicator 1 by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Buffer,true);
//---- moving the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,FutBuffer,INDICATOR_DATA);
//---- performing shift of the beginning of counting of drawing the indicator 2 by min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(FutBuffer,true);
//---- shifting the indicator 2 horizontally
   PlotIndexSetInteger(1,PLOT_SHIFT,future);

//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Bubbles&Drops(",historyDeep,", ",future,")");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//----
  }
//+------------------------------------------------------------------+   
//|splash function                                                   | 
//+------------------------------------------------------------------+ 
void splash(int length,const double &Open[],const double &Close[])
  {
//----
   ArrayInitialize(temp,0.0);
   double ampl=MathRound((Open[length]-Close[length])*divider);
   if(!ampl) for(int i=0; i<=length+int(future); i++) temp[i]=attenuation(ampl,(i+1))/divider;
//----
  }
//+------------------------------------------------------------------+   
//| attenuation function                                             | 
//+------------------------------------------------------------------+ 
double attenuation(double a,double x)
  {
//----
   if(!a)
     {
      if(a<0) return( (MathAbs(a)-100/(x)*MathSin(x/100*MathAbs(a)))); // sin(exp(cos($x)));
      if(a>0) return(-(MathAbs(a)-100/(x)*MathSin(x/100*MathAbs(a)))); // sin(exp(cos($x)));
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of price lows for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- checking the number of bars to be enough for calculation
   if(rates_total<min_rates_total) return(RESET);

//---- Declaration of integer variables
   int limit;

//--- calculations of the necessary amount of data to be copied and
//----the limit starting number for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
     }
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars
   
   for(int bar=limit; bar>=int(historyDeep) && !IsStopped(); bar--)
     {
      Buffer[bar]=0.0;
      FutBuffer[bar]=0.0;
     }

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);

   for(int j=0; j<int(historyDeep); j++)
     {
      Buffer[j]=open[j];
      FutBuffer[j]=open[j];
     }

//---- Main cycle of calculation of the indicator
   for(int j=0; j<int(historyDeep) && !IsStopped(); j++)
     {
      splash(historyDeep-j,open,close);
      for(int i=0; i<=int(historyDeep)-j; i++) Buffer[historyDeep-j-i]+=temp[i];
      for(int i=0; i<=int(future); i++) FutBuffer[future-i]+=temp[historyDeep-j+i];
      for(int i=int(future); i<int(historyDeep+future); i++) FutBuffer[i]=Buffer[i-future];
     }

   FutBuffer[0]=FutBuffer[1];
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
