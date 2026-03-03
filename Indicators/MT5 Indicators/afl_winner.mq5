//+------------------------------------------------------------------+
//|                                                   AFL_Winner.mq5 |
//|                                                        avoitenko |
//|                        https://login.mql5.com/en/users/avoitenko |
//+------------------------------------------------------------------+
#property copyright  "avoitenko"
#property link       "https://login.mql5.com/en/users/avoitenko"
#property version    "2.00"

#property indicator_separate_window

#property indicator_level1 0
#property indicator_level2 100

#property indicator_minimum -10
#property indicator_maximum 110

#property indicator_buffers 8
#property indicator_plots   1

//--- color histogram
#property indicator_type1  DRAW_COLOR_HISTOGRAM2
#property indicator_color1 clrDodgerBlue, clrOrangeRed
#property indicator_width1 5
#property indicator_label1 "High;Low"

//--- include
#include <MovingAverages.mqh>

//--- input parameters
input ushort InpPeriods = 10; // Period
input ushort InpAverage = 5;  // Average

//--- buffers
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtColorBuffer[];
double cost[];
double pa5[];
double rsv[];
double pak[];
double pad[];

//--- global variables
double pa;
double scost5;
long svolume5;
int w1,w2;
int offset;
double min,max;
ushort periods;
ushort average;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- check input parameters
   periods = (ushort)fmax(2,InpPeriods);
   average = (ushort)fmax(2,InpAverage);
   offset=periods+average*average+1;

//--- set indicator buffers
   SetIndexBuffer(0,ExtHighBuffer);
   SetIndexBuffer(1,ExtLowBuffer);
   SetIndexBuffer(2,ExtColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(3,cost,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,pa5,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,rsv,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,pak,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,pad,INDICATOR_CALCULATIONS);

//--- set direction
   ArraySetAsSeries(ExtHighBuffer,true);
   ArraySetAsSeries(ExtLowBuffer,true);
   ArraySetAsSeries(ExtColorBuffer,true);
   ArraySetAsSeries(cost,true);
   ArraySetAsSeries(pa5,true);
   ArraySetAsSeries(rsv,true);
   ArraySetAsSeries(pak,true);
   ArraySetAsSeries(pad,true);

//--- set begin draw
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,offset);

//--- set indicator properties
   IndicatorSetString(INDICATOR_SHORTNAME,StringFormat("AFL Winner (%u, %u)",periods,average));
   IndicatorSetInteger(INDICATOR_DIGITS,2);

//--- done
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- set direction   
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(tick_volume,true);

   if(rates_total<=offset)return(0);

   int limit;
//--- first calc
   if(rates_total<prev_calculated || prev_calculated<=0)
     {
      limit=rates_total-offset;
      ArrayInitialize(ExtHighBuffer,EMPTY_VALUE);
      ArrayInitialize(ExtLowBuffer,EMPTY_VALUE);
      ArrayInitialize(ExtColorBuffer,0);
     }
   else limit=rates_total-prev_calculated;

//--- main cycle
   for(int i=limit; i>=0 && !_StopFlag; i--)
     {
      pa=(2*close[i]+high[i]+low[i])/4;
      cost[i]=pa*tick_volume[i];

      scost5=Sum(cost,i,average);
      svolume5=Sum(tick_volume,i,average);

      if(svolume5==0)continue;
      pa5[i]=scost5/svolume5;

      max = pa5[ArrayMaximum(pa5,i,periods)];
      min = pa5[ArrayMinimum(pa5,i,periods)];

      rsv[i]=((pa5[i]-min)/fmax((max-min),_Point))*100;
     }

//--- wma
   LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,average,rsv,pak,w1);
   LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,average,pak,pad,w2);

//--- draw histogram
   for(int i=limit; i>=0 && !_StopFlag; i--)
     {
      ExtHighBuffer[i]  = pak[i];
      ExtLowBuffer[i]   = pad[i];
      ExtColorBuffer[i] = 0;
      if(pak[i]<pad[i])ExtColorBuffer[i]=1;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|   Sum                                                            |
//+------------------------------------------------------------------+
template<typename T>
T Sum(const T &buffer[],uint index,uint count)
  {
   T sum=0;
   int total=ArraySize(buffer);
   for(uint i=index; i<fmin(total,index+count); i++)
      sum+=buffer[i];
   return(sum);
  }
//+------------------------------------------------------------------+
