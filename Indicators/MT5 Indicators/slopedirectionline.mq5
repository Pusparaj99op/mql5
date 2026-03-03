//+------------------------------------------------------------------+
//|                                           SlopeDirectionLine.mq5 |
//|                                                        avoitenko |
//|                        https://login.mql5.com/en/users/avoitenko |
//+------------------------------------------------------------------+
#property copyright "avoitenko"
#property link      "https://login.mql5.com/en/users/avoitenko"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers   5
#property indicator_plots     1

//--- main line
#property indicator_type1  DRAW_COLOR_LINE
#property indicator_color1 clrBlue, clrRed
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2
#property indicator_label1 "SDL"

//---  include
#include <MovingAverages.mqh>

//---- input parameters 
input ushort               InpMAPeriod=80;           // Period
input ENUM_MA_METHOD       InpMAMethod       =  MODE_LWMA;     // Method
input ENUM_APPLIED_PRICE   InpAppliedPrice   =  PRICE_CLOSE;   // Apply to
input short                InpShift          =  0;             // Shift
input bool                 InpAlert          =  true;          // Alert        
input bool                 InpMail           =  true;          // Mail
input bool                 InpSound          =  true;          // Sound

//---- buffers 
double MABuffer[];
double MAColorBuffer[];
double vect[];
double wma1[];
double wma2[];

//--- global vars
int ma1_handle;
int ma2_handle;
int new_period;
int new_period_sqrt;
datetime time_alert;
int w;
string ind_name;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- periods
   new_period_sqrt=(int)fmax(MathSqrt(InpMAPeriod),1);
   new_period=(int)fmax((InpMAPeriod/2),1);

//--- handles
   ma1_handle=iMA(NULL,0,fmax(InpMAPeriod,2),0,InpMAMethod,InpAppliedPrice);
   ma2_handle=iMA(NULL,0,new_period,0,InpMAMethod,InpAppliedPrice);
   if(ma1_handle==INVALID_HANDLE || ma2_handle==INVALID_HANDLE)
     {
      Print("Error creating the indicator iMA");
      return(-1);
     }

//--- buffers
   SetIndexBuffer(0,MABuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MAColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,vect,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,wma1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,wma2,INDICATOR_CALCULATIONS);

//--- direction
   ArraySetAsSeries(MABuffer,true);
   ArraySetAsSeries(MAColorBuffer,true);
   ArraySetAsSeries(vect,true);
   ArraySetAsSeries(wma1,true);
   ArraySetAsSeries(wma2,true);

//--- main buffer properties
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod+new_period_sqrt+1);
   PlotIndexSetInteger(0,PLOT_SHIFT,InpShift);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetString(0,PLOT_LABEL,StringFormat("SDL(%u)",InpMAPeriod));

//--- indicator properties
   ind_name=StringFormat("Slope Direction Line (%u)",InpMAPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME,ind_name);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);

//---   
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
   ArraySetAsSeries(time,true);

//--- check for data
   if(rates_total<InpMAPeriod+1)return(0);

   int limit;
//--- calculate limit
   if(prev_calculated<0 || prev_calculated>rates_total)return(0);
   if(prev_calculated==0)
     {
      time_alert=time[0];
      limit=rates_total-InpMAPeriod-1;

      //--- clear buffers
      ArrayInitialize(MABuffer,0);
      ArrayInitialize(MAColorBuffer,0);
      ArrayInitialize(wma1,0);
      ArrayInitialize(wma2,0);
      ArrayInitialize(vect,0);

     }
   else limit=rates_total-prev_calculated;

//--- get data
   if(CopyBuffer(ma1_handle, 0, 0, limit+1, wma1) != limit+1)return(0);
   if(CopyBuffer(ma2_handle, 0, 0, limit+1, wma2) != limit+1)return(0);

   for(int i=limit; i>=0; i--)vect[i]=2*wma2[i]-wma1[i];

//---
   switch(InpMAMethod)
     {
      case  MODE_SMA:   SimpleMAOnBuffer(          rates_total, prev_calculated, 0, new_period_sqrt, vect, MABuffer); break;
      case  MODE_EMA:   ExponentialMAOnBuffer(     rates_total, prev_calculated, 0, new_period_sqrt, vect, MABuffer); break;
      case  MODE_SMMA:  SmoothedMAOnBuffer(        rates_total, prev_calculated, 0, new_period_sqrt, vect, MABuffer); break;
      case  MODE_LWMA:  LinearWeightedMAOnBuffer(  rates_total, prev_calculated, 0, new_period_sqrt, vect, MABuffer, w); break;
     }

//--- set colors
   for(int i=limit; i>=0; i--)
     {
      MAColorBuffer[i]=MAColorBuffer[i+1];
      if(MABuffer[i] > MABuffer[i+1]) MAColorBuffer[i]=0;
      if(MABuffer[i] < MABuffer[i+1]) MAColorBuffer[i]=1;
     }

//--- alerts
   if(time_alert!=time[0])
     {
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol,tick))return(0);

      if(MAColorBuffer[2]==0 && MAColorBuffer[1]==1)
        {
         string mask=StringFormat("%%.%df",_Digits);
         string msg=StringFormat("%s %s %s Signal SELL at "+mask,TimeToString(tick.time,TIME_DATE|TIME_SECONDS),_Symbol,PeriodToString(),tick.bid);
         if(InpAlert) Alert(msg);
         if(InpMail) SendMail(ind_name,msg);
         if(InpSound) PlaySound("alert.wav");
        }

      if(MAColorBuffer[2]==1 && MAColorBuffer[1]==0)
        {
         string mask=StringFormat("%%.%df",_Digits);
         string msg=StringFormat("%s %s %s Signal BUY at "+mask,TimeToString(tick.time,TIME_DATE|TIME_SECONDS),_Symbol,PeriodToString(),tick.ask);
         if(InpAlert) Alert(msg);
         if(InpMail) SendMail(ind_name,msg);
         if(InpSound) PlaySound("alert.wav");
        }

      time_alert=time[0];
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
//|   PeriodToString                                                 |
//+------------------------------------------------------------------+
string PeriodToString(ENUM_TIMEFRAMES period=PERIOD_CURRENT)
  {
   if(period==PERIOD_CURRENT)period=_Period;
   string str=EnumToString(period);
   if(StringLen(str)>7) return(StringSubstr(str,7));
   return("");
  }
//+------------------------------------------------------------------+
