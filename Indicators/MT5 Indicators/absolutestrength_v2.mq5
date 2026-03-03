//+------------------------------------------------------------------+
//|                                          AbsoluteStrength_v2.mq4 |
//|                                Copyright © 2012, TrendLaboratory |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//|                                   E-mail: igorad2003@yahoo.co.uk |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, TrendLaboratory"
#property link      "http://finance.groups.yahoo.com/group/TrendLaboratory"


//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 12
#property indicator_plots   6

#property indicator_label1  "Bulls"
#property indicator_type1   DRAW_LINE
#property indicator_color1  DeepSkyBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "Bears"
#property indicator_type2   DRAW_LINE
#property indicator_color2  Tomato
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_label3  "Signal Bulls"
#property indicator_type3   DRAW_LINE
#property indicator_color3  DeepSkyBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "Signal Bears"
#property indicator_type4   DRAW_LINE
#property indicator_color4  Tomato
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

#property indicator_label5  "Strength Line"
#property indicator_type5   DRAW_LINE
#property indicator_color5  SlateGray
#property indicator_style5  STYLE_DOT
#property indicator_width5  1

#property indicator_label6  "Weakness Line"
#property indicator_type6   DRAW_LINE
#property indicator_color6  SlateGray
#property indicator_style6  STYLE_DOT
#property indicator_width6  1



enum ENUM_MATH_MODE
{
   RSI_method,          // RSI
   Stochastic_method,   // Stochastic
   DMI_method           // DMI
};

enum ENUM_LEVELS_MODE
{
   Standard,            // OverBought/OverSold 
   StdDevBands,         // StdDev Bands
   HighLowChannel,      // High/Low Channel
};

enum ENUM_SMOOTH_MODE
{
   sma,                 // SMA
   ema,                 // EMA
   wilder,              // Wilder
   lwma,                // LWMA
};

input ENUM_TIMEFRAMES      TimeFrame         =     0;
input ENUM_MATH_MODE       MathMode          =     0; // Math method
input ENUM_APPLIED_PRICE   Price             =  PRICE_CLOSE;   //Apply to
input int                  Length            =    10; // Period of Evaluation
input int                  PreSmooth         =     1; // Period of PreSmoothing
input int                  Smooth            =     1; // Period of Smoothing
input int                  Signal            =     1; // Period of Signal Line
input ENUM_SMOOTH_MODE     MA_Mode           =     1; // Moving Average Mode
input ENUM_LEVELS_MODE     LevelsMode        =     0;
input double               StrengthLevel     =    70; // Strength Level (ex.70)
input double               WeaknessLevel     =    30; // Weakness Level (ex.30)
input int                  LookBackPeriod    =    30; // LookBack Period for LevelsMode=2,3 
input double               UpperMultiplier   =     1; // Upper Band Multiplier for LevelsMode=2
input double               LowerMultiplier   =     1; // Lower Band Multiplier for LevelsMode=2


//--- indicator buffers
double Bulls[];
double Bears[];
double signalBulls[];
double signalBears[];
double strength[];
double weakness[];
double price[];
double loprice[];
double bulls[];
double bears[];
double lbulls[];
double lbears[];

ENUM_TIMEFRAMES  tf;
int      fLength, Price_handle, Lo_handle,  mtf_handle;
double   HiArray[], LoArray[], ema[6][2], _point;
double   mtf_bulls[1], mtf_bears[1], mtf_sigbulls[1], mtf_sigbears[1], mtf_strength[1], mtf_weakness[1];
datetime prevtime, ptime[6]; 
bool     ftime[6];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   if(TimeFrame <= Period()) tf = Period(); else tf = TimeFrame; 
//--- indicator buffers mapping
   SetIndexBuffer(0,      Bulls,INDICATOR_DATA);
   SetIndexBuffer(1,      Bears,INDICATOR_DATA);
   SetIndexBuffer(2,signalBulls,INDICATOR_DATA);
   SetIndexBuffer(3,signalBears,INDICATOR_DATA);
   SetIndexBuffer(4,   strength,INDICATOR_DATA);
   SetIndexBuffer(5,   weakness,INDICATOR_DATA);
   
   SetIndexBuffer(6,      price,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,    loprice,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,      bulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,      bears,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,    lbulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,    lbears,INDICATOR_CALCULATIONS);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- 
   string math_name, ma_name;
   
   switch(MathMode)
   {
   case 0 : math_name = "RSI"  ; break;
   case 1 : math_name = "Stoch"; break;
   case 2 : math_name = "DMI"  ; break;
   }
   
   switch(MA_Mode)
   {
   case 0 : ma_name = "SMA"   ; break;
   case 1 : ma_name = "EMA"   ; break;
   case 2 : ma_name = "Wilder"; break;
   case 3 : ma_name = "LWMA"  ; break;
   } 
   
   string short_name = "AbsoluteStrength_v2("+ math_name + "," + priceToString(Price) + "," + (string)Length + "," + (string)PreSmooth + "," + (string)Smooth + "," + (string)Signal + "," + ma_name +")";
      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- 
   fLength = LookBackPeriod;
   int draw_begin = Length + PreSmooth + Smooth + Signal + fLength;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,draw_begin);
//---
   
   Price_handle = iMA(NULL,0,PreSmooth,0,(ENUM_MA_METHOD)MA_Mode,Price);
   if(MathMode == 2) Lo_handle = iMA(NULL,0,PreSmooth,0,(ENUM_MA_METHOD)MA_Mode,PRICE_LOW);   
    
   ArrayResize(HiArray,LookBackPeriod);
   ArrayResize(LoArray,LookBackPeriod);
   
   _point   = _Point*MathPow(10,_Digits%2);
   
   if(TimeFrame > 0) mtf_handle = iCustom(Symbol(),TimeFrame,"AbsoluteStrength_v2",0,MathMode,Price,Length,PreSmooth,Smooth,
                Signal,MA_Mode,LevelsMode,StrengthLevel,WeaknessLevel,LookBackPeriod,UpperMultiplier,LowerMultiplier);
   
//--- initialization done
}
//+------------------------------------------------------------------+
//| AbsoluteStrength_v2                                              |
//+------------------------------------------------------------------+
int OnCalculate(const int      rates_total,
                const int      prev_calculated,
                const datetime &Time[],
                const double   &Open[],
                const double   &High[],
                const double   &Low[],
                const double   &Close[],
                const long     &TickVolume[],
                const long     &Volume[],
                const int      &Spread[])
{
   int i, x, y, shift, limit, mtflimit, len, copied;
   double up, lo, upPivot, dnPivot;
   datetime mtf_time;
//--- preliminary calculations
   if(prev_calculated == 0) 
   {
   limit = 0; 
   mtflimit = rates_total - 1;
   ArrayInitialize(Bulls,EMPTY_VALUE);
   ArrayInitialize(Bears,EMPTY_VALUE);
   ArrayInitialize(signalBulls,EMPTY_VALUE);
   ArrayInitialize(signalBears,EMPTY_VALUE);
   ArrayInitialize(strength,0);
   ArrayInitialize(weakness,0);
   }
   else 
   {
   limit = prev_calculated-1;
   mtflimit = PeriodSeconds(tf)/PeriodSeconds(Period());
   }
   
   copied = CopyBuffer(Price_handle,0,0,rates_total - 1,price);
   
   if(copied<0)
   {
   Print("not all prices copied. Will try on next tick Error =",GetLastError(),", copied =",copied);
   return(0);
   }
   
   if(MathMode == 2)
   {
   copied = CopyBuffer(Lo_handle,0,0,rates_total - 1,loprice);
   
      if(copied<0)
      {
      Print("not all prices copied. Will try on next tick Error =",GetLastError(),", copied =",copied);
      return(0);
      }
   }
//--- the main loop of calculations
   if(tf > Period())
   {
   ArraySetAsSeries(Time,true);   
  
      for(shift=0,y=0;shift<mtflimit;shift++)
      {
      if(Time[shift] < iTime(NULL,TimeFrame,y)) y++; 
      mtf_time = iTime(NULL,TimeFrame,y);
      
      x = rates_total - shift - 1;
      
      copied = CopyBuffer(mtf_handle,0,mtf_time,mtf_time,mtf_bulls);
      if(copied <= 0) return(0);
      copied = CopyBuffer(mtf_handle,1,mtf_time,mtf_time,mtf_bears);
      if(copied <= 0) return(0);
      
      Bulls[x] = mtf_bulls[0];
      Bears[x] = mtf_bears[0];
      
         if(Signal > 1)
         {
         copied = CopyBuffer(mtf_handle,2,mtf_time,mtf_time,mtf_sigbulls);
         if(copied <= 0) return(0);
         copied = CopyBuffer(mtf_handle,3,mtf_time,mtf_time,mtf_sigbears);
         if(copied <= 0) return(0);
         
         signalBulls[x] = mtf_sigbulls[0];
         signalBears[x] = mtf_sigbears[0];
         }
      
      copied = CopyBuffer(mtf_handle,4,mtf_time,mtf_time,mtf_strength);
      if(copied <= 0) return(0);
      copied = CopyBuffer(mtf_handle,5,mtf_time,mtf_time,mtf_weakness);
      if(copied <= 0) return(0);
      
      strength[x] = mtf_strength[0];
      weakness[x] = mtf_weakness[0];
      }
   }
   else
   for(shift=limit;shift<rates_total;shift++)
   {
      if(shift > Length)
      {
         
         switch(MathMode)
         {
         case 0:     bulls[shift] = 0.5*(MathAbs(price[shift] - price[shift-1]) + (price[shift] - price[shift-1]))/_point;
                     bears[shift] = 0.5*(MathAbs(price[shift] - price[shift-1]) - (price[shift] - price[shift-1]))/_point;
                     break;
           
         case 1:     up = 0; lo = 10000000000;
                        for(i=0;i<Length;i++)
                        {   
                        up = MathMax(up,High[shift-i]);
                        lo = MathMin(lo,Low [shift-i]);
                        }
                                         
                     bulls[shift] = (price[shift] - lo)/_point;
                     bears[shift] = (up - price[shift])/_point;
                     break;
            
         case 2:     bulls[shift] = MathMax(0,0.5*(MathAbs(price[shift]     - price[shift-1]) + (price[shift]     - price[shift-1])))/_point;
                     bears[shift] = MathMax(0,0.5*(MathAbs(loprice[shift-1] - loprice[shift]) + (loprice[shift-1] - loprice[shift])))/_point;
      
                     if (bulls[shift] > bears[shift]) bears[shift] = 0;
                     else 
                     if (bulls[shift] < bears[shift]) bulls[shift] = 0;
                     else
                     if (bulls[shift] == bears[shift]) {bulls[shift] = 0; bears[shift] = 0;}
                     break;
         }
         
         
      if(MathMode == 1) len = 1; else len = Length; 
      
      if(shift < len) continue;
      
      lbulls[shift] = mAverage(0,MA_Mode,bulls,len,Time[shift],shift); 
      lbears[shift] = mAverage(1,MA_Mode,bears,len,Time[shift],shift);  
           
      if(shift < len + Smooth) continue;
      
      Bulls[shift] = mAverage(2,MA_Mode,lbulls,Smooth,Time[shift],shift); 
      Bears[shift] = mAverage(3,MA_Mode,lbears,Smooth,Time[shift],shift);  
     
      if(shift < len + Smooth + Signal) continue;
          
         if(Signal > 1)
         {   
         signalBulls[shift] = mAverage(4,MA_Mode,Bulls,Signal,Time[shift],shift); 
         signalBears[shift] = mAverage(5,MA_Mode,Bears,Signal,Time[shift],shift);  
         }
      
         if(LevelsMode == 0)
         {
         if(StrengthLevel > 0) strength[shift] = StrengthLevel/100*(Bulls[shift] + Bears[shift]);
         if(WeaknessLevel > 0) weakness[shift] = WeaknessLevel/100*(Bulls[shift] + Bears[shift]);
         }
         else
         if(LevelsMode == 1 && shift > len + Smooth + LookBackPeriod)
         {
            for(int j = 0; j < LookBackPeriod; j++)
            { 
            HiArray[j] = MathMax(Bulls[shift-j],Bears[shift-j]);  
            LoArray[j] = MathMin(Bulls[shift-j],Bears[shift-j]); 
            }      
         
         if(UpperMultiplier > 0) strength[shift] = SMA(HiArray,LookBackPeriod,LookBackPeriod-1) + UpperMultiplier*stdDev(HiArray,LookBackPeriod); 
         if(LowerMultiplier > 0) weakness[shift] = SMA(LoArray,LookBackPeriod,LookBackPeriod-1) - LowerMultiplier*stdDev(LoArray,LookBackPeriod);
         }
         else
         if(LevelsMode == 2 && shift > len + Smooth + LookBackPeriod)
         {
            for(int j = 0; j < LookBackPeriod; j++)
            { 
            HiArray[j] = MathMax(Bulls[shift-j],Bears[shift-j]);  
            LoArray[j] = MathMin(Bulls[shift-j],Bears[shift-j]); 
            }   
                  
         upPivot = getPivots(0,HiArray,LookBackPeriod);
         dnPivot = getPivots(1,LoArray,LookBackPeriod);
       
         strength[shift] = upPivot - (upPivot - dnPivot)*(1 - StrengthLevel/100);
         weakness[shift] = dnPivot + (upPivot - dnPivot)*WeaknessLevel/100;
         }
      }   
   }      
  
//--- done
   return(rates_total);
}
//+------------------------------------------------------------------+

double mAverage(int index,int mode,double& array[],int length,datetime time,int bar)
{
   double ma = 0;
   
   switch(mode)
   {
   case 1:  ma = EMA (index,array[bar],length    ,time,bar); break;
   case 2:  ma = EMA (index,array[bar],2*length-1,time,bar); break;
   case 3:  ma = LWMA(array,length,bar); break;   
   case 0:  ma = SMA (array,length,bar); break;   
   }
   
   return(ma);
} 

// SMA - Simple Moving Average
double SMA(double& array[],int length,int bar)
{
   int i;
   double sum = 0;
   for(i = 0;i < length;i++) sum += array[bar-i];
   
   return(sum/length);
}

// EMA - Exponential Moving Average
double EMA(int index,double _price,int length,datetime time,int bar)
{
   if(ptime[index] < time) {ema[index][1] = ema[index][0]; ptime[index] = time;} 
   
   if(ftime[index]) {ema[index][0] = _price; ftime[index] = false;}
   else 
   ema[index][0] = ema[index][1] + 2.0/(1+length)*(_price - ema[index][1]); 
   
   return(ema[index][0]);
}

// LWMA - Linear Weighted Moving Average 
double LWMA(double& array[],int length,int bar)
{
   double lwma, sum = 0, weight = 0;
   
      for(int i = 0;i < length;i++)
      { 
      weight+= (length - i);
      sum += array[bar-i]*(length - i);
      }
   
   if(weight > 0) lwma = sum/weight; else lwma = 0; 
   
   return(lwma);
} 
// stdDev - Standard Deviation 
double stdDev(double& array[],int length)
{
   int i;
   double avg = 0;
   for (i=0;i<length;i++) avg += array[i]/length;
        
   double sum = 0;
   for (i=0;i<length;i++) sum += MathPow(array[i] - avg,2);
   return(MathSqrt(sum/length));
}       

double getPivots(int type,double& array[],int len)
{
   int i;
   double max = 0, min = 100000000;
       
   for(i=0;i<len;i++)
   { 
      if(type == 0 && array[i] > max && array[i] < 1000000) max = array[i];  
      if(type == 1 && array[i] < min ) min = array[i];   
   }
 
   if(type == 0) return(max); 
   if(type == 1) return(min); 
      
   return(0);  
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
  