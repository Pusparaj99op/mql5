//+------------------------------------------------------------------+
//|                                                      ALMA_v2.mq5 |
//|                   ALMA by Arnaud Legoux / Dimitris Kouzis-Loukas |
//|                                             www.arnaudlegoux.com |                     
//|                         Written by IgorAD,igorad2003@yahoo.co.uk |   
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |                                      
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010-12, TrendLaboratory"
#property link      "http://finance.groups.yahoo.com/group/TrendLaboratory"
#property description "Arnaud Legoux Moving Average"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  Silver,DeepSkyBlue,OrangeRed
#property indicator_width1  2

input ENUM_TIMEFRAMES      TimeFrame   =     0;
input ENUM_APPLIED_PRICE   Price       = PRICE_CLOSE; //Apply to
input int                  Length      =     9;       //Window Size  
input double               Sigma       =   6.0;       //Sigma parameter 
input double               Offset      =  0.85;       //Offset of Gaussian distribution (0...1)
input int                  Shift       =     0;       //Shift in Bars
input int                  ColorMode   =     0;       //Color Mode(0-off,1-on) 

double  alma[];
double  trend[];
double  price[];

ENUM_TIMEFRAMES  tf;
int      mtf_handle, Price_handle;
double   W[], mtf_alma[1], mtf_trend[1];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   if(TimeFrame <= Period()) tf = Period(); else tf = TimeFrame;   
//--- indicator buffers mapping 
   SetIndexBuffer(0, alma,        INDICATOR_DATA); PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,3);
   SetIndexBuffer(1,trend, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,price,INDICATOR_CALCULATIONS);
//--- 
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,Length+1);
//--- 
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- 
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- 
   string short_name = "ALMA_v2["+timeframeToString(TimeFrame)+"]("+priceToString(Price)+","+(string)Length+","+(string)Sigma+","+(string)Offset+")";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   PlotIndexSetString(0,PLOT_LABEL,"ALMA_v2["+timeframeToString(TimeFrame)+"]");
//---
   Price_handle = iMA(NULL,TimeFrame,1,0,0,Price);
   
   if(TimeFrame > 0) mtf_handle = iCustom(NULL,TimeFrame,"ALMA_v2",0,Price,Length,Sigma,Offset,Shift,ColorMode);
   else
   {
   ArrayResize(W,Length);
  
   double m = MathFloor(Offset*(Length - 1));
	double s = Length/Sigma;
	double wSum = 0;
	   for (int i=0;i < Length;i++) 
	   {
	   W[i] = MathExp(-((i-m)*(i-m))/(2*s*s));
      wSum += W[i];
      } 
   
      for (int i=0;i < Length;i++) W[i] = W[i]/wSum; 
   }
//--- initialization done
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double   &Open[],
                const double   &High[],
                const double   &Low[],
                const double   &Close[],
                const long     &TickVolume[],
                const long     &Volume[],
                const int      &Spread[])
{
   int x, y, shift, limit, mtflimit, copied = 0;
   datetime mtf_time;
//--- preliminary calculations
   if(prev_calculated == 0) 
   {
   limit  = 0; 
   mtflimit = rates_total - 1;
   ArrayInitialize(alma,EMPTY_VALUE);
   }
   else 
   {
   limit = rates_total - 1;
   mtflimit = rates_total - prev_calculated + PeriodSeconds(tf)/PeriodSeconds(Period());
   }
     
   copied = CopyBuffer(Price_handle,0,Time[rates_total-1],Time[0],price);
   
   if(copied < 0)
   {
   Print("not all prices copied. Will try on next tick Error =",GetLastError(),", copied =",copied);
   return(0);
   }

//--- the main loop of calculations
   if(tf > Period())
   { 
   ArraySetAsSeries(Time,true);   
  
      for(shift=0,y=0;shift<mtflimit;shift++)
      {
      if(Time[shift] < iTime(NULL,TimeFrame,y)) y++; 
      mtf_time = iTime(NULL,TimeFrame,y);
      
      copied = CopyBuffer(mtf_handle,0,mtf_time,mtf_time,mtf_alma);
      if(copied <= 0) return(0);
      x = rates_total - shift - 1;
      alma[x] = mtf_alma[0];
           
         if(ColorMode > 0)
         {
         copied = CopyBuffer(mtf_handle,1,mtf_time,mtf_time,mtf_trend);   
         if(copied <= 0) return(0);
         trend[x] = mtf_trend[0];   
         }
         else trend[x] = 0; 
      }
   }
   else
   {
      for(shift=limit;shift<rates_total;shift++)
      {
      if(shift < Length) continue;
      double sum = 0.0;
      for(int i = 0; i < Length; i++) sum += price[shift-(Length - 1 - i)]*W[i];
   
      alma[shift] = sum;
   
      if(shift < Length + 2) continue;
      
         if(shift > 0)
         {
         if(ColorMode > 0 && alma[shift-1] > 0)
            {
            trend[shift] = trend[shift-1];
            if(alma[shift] > alma[shift-1]) trend[shift] = 1;
            if(alma[shift] < alma[shift-1]) trend[shift] = 2;    
            }    
            else trend[shift] = 0; 
         }
      }
   } 
//--- done       
   return(rates_total);
}
//+------------------------------------------------------------------+
string timeframeToString(ENUM_TIMEFRAMES TF)
{
   switch(TF)
   {
   case PERIOD_CURRENT  : return("Current");
   case PERIOD_M1       : return("M1");   
   case PERIOD_M2       : return("M2");
   case PERIOD_M3       : return("M3");
   case PERIOD_M4       : return("M4");
   case PERIOD_M5       : return("M5");      
   case PERIOD_M6       : return("M6");
   case PERIOD_M10      : return("M10");
   case PERIOD_M12      : return("M12");
   case PERIOD_M15      : return("M15");
   case PERIOD_M20      : return("M20");
   case PERIOD_M30      : return("M30");
   case PERIOD_H1       : return("H1");
   case PERIOD_H2       : return("H2");
   case PERIOD_H3       : return("H3");
   case PERIOD_H4       : return("H4");
   case PERIOD_H6       : return("H6");
   case PERIOD_H8       : return("H8");
   case PERIOD_H12      : return("H12");
   case PERIOD_D1       : return("D1");
   case PERIOD_W1       : return("W1");
   case PERIOD_MN1      : return("MN1");      
   default              : return("Current");
   }
}

string priceToString(ENUM_APPLIED_PRICE app_price)
{
   switch(app_price)
   {
   case PRICE_CLOSE   :    return("Close");
   case PRICE_HIGH    :    return("High");
   case PRICE_LOW     :    return("Low");
   case PRICE_MEDIAN  :    return("Median");
   case PRICE_OPEN    :    return("Open");
   case PRICE_TYPICAL :    return("Typical");
   case PRICE_WEIGHTED:    return("Weighted");
   default            :    return("");
   }
}

datetime iTime(string symbol,ENUM_TIMEFRAMES TF,int index)
{
   if(index < 0) return(-1);
   static datetime timearray[];
   if(CopyTime(symbol,TF,index,1,timearray) > 0) return(timearray[0]); else return(-1);
}

