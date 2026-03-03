//+------------------------------------------------------------------+
//|                                                ParabolicSAR_.mq5 |
//+------------------------------------------------------------------+

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_color1  Red//Yellow
#property indicator_color2  Blue

//--- input parameters
input int ParabolicSARPeriod=10; // Period
//--- indicator buffers
double    ExtHighBuffer[];
double    ExtLowBuffer[];

double max,min;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {

   SetIndexBuffer(0,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLowBuffer,INDICATOR_DATA);
 
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ParabolicSARPeriod);

   PlotIndexSetInteger(0,PLOT_SHIFT,2);
   PlotIndexSetInteger(1,PLOT_SHIFT,2);

   IndicatorSetString(INDICATOR_SHORTNAME,"Parabolic("+string(ParabolicSARPeriod)+")");
   PlotIndexSetString(0,PLOT_LABEL,"Channel("+string(ParabolicSARPeriod)+") max" );
  PlotIndexSetString(1,PLOT_LABEL," Channel("+string(ParabolicSARPeriod)+") min");
 
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);

  }
//+------------------------------------------------------------------+
//| get highest value for range                                      |
//+------------------------------------------------------------------+
double Highest(const double &array[],int range,int fromIndex)
  {
   double res;
   int i;
//---
   res=array[fromIndex];
   for(i=fromIndex;i>fromIndex-range && i>=0;i--)
     {
      if(res<array[i]) res=array[i];
     }
//---
   return(res);
  }
//+------------------------------------------------------------------+
//| get lowest value for range                                       |
//+------------------------------------------------------------------+
double Lowest(const double &array[],int range,int fromIndex)
  {
   double res;
   int i;
//---
   res=array[fromIndex];
   for(i=fromIndex;i>fromIndex-range && i>=0;i--)
     {
      if(res>array[i]) res=array[i];
     }
//---
   return(res);
  }
//+------------------------------------------------------------------+
//| Price Channell                                                   |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
   int i,limit;
//--- check for rates
   if(rates_total<ParabolicSARPeriod)
      return(0);
//--- preliminary calculations
   if(prev_calculated==0)
      limit=ParabolicSARPeriod;
   else limit=prev_calculated-1;
//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
     
   max=0;
   min=0;
   
   // ---main cycle  
  for(int j=1; j<=ParabolicSARPeriod; j++)
     {
   
    max=max+Highest(High,j,i)/ParabolicSARPeriod;
    
    min=min+Lowest(Low,j,i)/ParabolicSARPeriod;
     
   }
  
max= NormalizeDouble(max,_Digits);
min= NormalizeDouble(min,_Digits);
  
          
      ExtHighBuffer[i]=max;
      ExtLowBuffer[i]=min;
     
     }
//--- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
