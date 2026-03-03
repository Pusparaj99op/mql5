//+------------------------------------------------------------------+
//|                                    AbsoluteStrengthMarket_v1.mq4 |
//|                                Copyright © 2013, TrendLaboratory |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//|                                   E-mail: igorad2003@yahoo.co.uk |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013, TrendLaboratory"
#property link      "http://finance.groups.yahoo.com/group/TrendLaboratory"


//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 16
#property indicator_plots   6

#property indicator_label1  "Bull Market"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  DeepSkyBlue
#property indicator_width1  4

#property indicator_label2  "Bear Market"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  Red
#property indicator_width2  4

#property indicator_label3  "Correction "
#property indicator_type3   DRAW_ARROW
#property indicator_color3  LightSkyBlue
#property indicator_width3  2

#property indicator_label4  "Bear Market Rally"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  LightSalmon
#property indicator_width4  2

#property indicator_label5  "Choppy Market"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  Gold
#property indicator_width5  2

#property indicator_label6  "Sideways Market"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  Gray
#property indicator_width6  0

#property indicator_maximum 2
#property indicator_minimum 0

enum ENUM_MATH_MODE
{
   RSI_method,          // RSI
   Stochastic_method,   // Stochastic
   DMI_method           // DMI
};

enum ENUM_SMOOTH_MODE
{
   sma,                 // SMA
   ema,                 // EMA
   wilder,              // Wilder
   lwma,                // LWMA
};

input ENUM_TIMEFRAMES      TimeFrame         =        0;       //
input ENUM_MATH_MODE       MathMode          =        0;       // Math method
input ENUM_APPLIED_PRICE   Price             =  PRICE_CLOSE;   // Apply to
input int                  Length            =       10;       // Period of Evaluation
input int                  PreSmooth         =        1;       // Period of PreSmoothing
input int                  Smooth            =        5;       // Period of Smoothing
input int                  Signal            =        5;       // Period of Signal Line
input ENUM_SMOOTH_MODE     MA_Mode           =        3;       // Moving Average Mode
input double               IndicatorValue    =        1;       // Indicator Value (ex.1.0)
input int                  ArrowCode         =      167;       // Arrow Code in Wingdings
input int                  AlertMode         =        0;       // Alert Mode: 0-off,1-on
input bool                 ShowName          =     true;
input bool                 ShowTimeFrame     =     true;
input string               FontName          =  "Arial";
input int                  FontSize          =        8;
input color                TextColor         =    Black;
input string               UniqueName        = "Market";


//--- indicator buffers
double BullMarket[];
double BearMarket[];
double Correction[];
double BearRally[];
double Choppy[];
double Sideways[];

double Bulls[];
double Bears[];
double signalBulls[];
double signalBears[];
double price[];
double loprice[];
double bulls[];
double bears[];
double lbulls[];
double lbears[];

ENUM_TIMEFRAMES  tf;
int      Price_handle, Lo_handle,  mtf_handle;
double   ema[6][2], _point;
double   mtf_bullmarket[1], mtf_bearmarket[1], mtf_correction[1], mtf_bearrally[1], mtf_choppy[1], mtf_sideways[1];
datetime prevAlertTime, ptime[6]; 
bool     ftime[6];
string short_name;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   if(TimeFrame <= Period()) tf = Period(); else tf = TimeFrame; 
//--- indicator buffers mapping
   SetIndexBuffer( 0, BullMarket,INDICATOR_DATA); PlotIndexSetInteger(0,PLOT_ARROW,ArrowCode);
   SetIndexBuffer( 1, BearMarket,INDICATOR_DATA); PlotIndexSetInteger(1,PLOT_ARROW,ArrowCode);
   SetIndexBuffer( 2, Correction,INDICATOR_DATA); PlotIndexSetInteger(2,PLOT_ARROW,ArrowCode);
   SetIndexBuffer( 3,  BearRally,INDICATOR_DATA); PlotIndexSetInteger(3,PLOT_ARROW,ArrowCode);
   SetIndexBuffer( 4,     Choppy,INDICATOR_DATA); PlotIndexSetInteger(4,PLOT_ARROW,ArrowCode);
   SetIndexBuffer( 5,   Sideways,INDICATOR_DATA); PlotIndexSetInteger(5,PLOT_ARROW,ArrowCode);
   SetIndexBuffer( 6,      Bulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer( 7,      Bears,INDICATOR_CALCULATIONS);
   SetIndexBuffer( 8,signalBulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer( 9,signalBears,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,      price,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,    loprice,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,      bulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,      bears,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,     lbulls,INDICATOR_CALCULATIONS);
   SetIndexBuffer(15,     lbears,INDICATOR_CALCULATIONS);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,1);
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
   
   if(ShowName)
   short_name = "AbsoluteStrengthMarket_v1["+timeframeToString(tf)+"]("+ math_name + "," + priceToString(Price) + "," + (string)Length + "," + (string)PreSmooth + "," + (string)Smooth + "," + (string)Signal + "," + ma_name +")";
   else short_name = " ";
      
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- 
   int draw_begin = Length + PreSmooth + Smooth + Signal;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,draw_begin);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,draw_begin);
//---
   
   Price_handle = iMA(NULL,0,PreSmooth,0,(ENUM_MA_METHOD)MA_Mode,Price);
   if(MathMode == 2) Lo_handle = iMA(NULL,0,PreSmooth,0,(ENUM_MA_METHOD)MA_Mode,PRICE_LOW);   
     
   
   _point   = _Point*MathPow(10,_Digits%2);
   
   if(TimeFrame > 0) mtf_handle = iCustom(Symbol(),TimeFrame,"AbsoluteStrengthMarket_v1",0,MathMode,Price,Length,PreSmooth,Smooth,
                Signal,MA_Mode,IndicatorValue,ArrowCode,AlertMode);
   
//--- initialization done
}

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit( const int reason )
{
//---- 
   deleteObj (UniqueName + timeframeToString(tf));
   Comment("");
//----
   return;
}
//+------------------------------------------------------------------+
//| AbsoluteStrengthMarket_v1                                        |
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
   int i, x, y, shift, limit, mtflimit, len, copied, window;
   double up, lo;
   datetime mtf_time;
   string message;
//--- preliminary calculations
   if(prev_calculated == 0) 
   {
   limit = 0; 
   mtflimit = rates_total - 1;
   ArrayInitialize(BullMarket,EMPTY_VALUE);
   ArrayInitialize(BearMarket,EMPTY_VALUE);
   ArrayInitialize(Correction,EMPTY_VALUE);
   ArrayInitialize(BearRally ,EMPTY_VALUE);
   ArrayInitialize(Choppy    ,EMPTY_VALUE);
   ArrayInitialize(Sideways  ,EMPTY_VALUE);
   }
   else 
   {
   limit = prev_calculated-1;
   mtflimit = PeriodSeconds(tf)/PeriodSeconds(Period());
   }
   
   window = ChartWindowFind();
   ArraySetAsSeries(Time,true); 
   
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
      for(shift=0,y=0;shift<mtflimit;shift++)
      {
      if(Time[shift] < iTime(NULL,TimeFrame,y)) y++; 
      mtf_time = iTime(NULL,TimeFrame,y);
      
      x = rates_total - shift - 1;
      
      copied = CopyBuffer(mtf_handle,0,mtf_time,mtf_time,mtf_bullmarket);
      if(copied <= 0) return(0);
      
      BullMarket[x] = mtf_bullmarket[0];
      
      copied = CopyBuffer(mtf_handle,1,mtf_time,mtf_time,mtf_bearmarket);
      if(copied <= 0) return(0);
            
      BearMarket[x] = mtf_bearmarket[0];
         
      copied = CopyBuffer(mtf_handle,2,mtf_time,mtf_time,mtf_correction);
      if(copied <= 0) return(0);
      
      Correction[x] = mtf_correction[0];
      
      copied = CopyBuffer(mtf_handle,3,mtf_time,mtf_time,mtf_bearrally);
      if(copied <= 0) return(0);
         
      BearRally[x] = mtf_bearrally[0];
      
      copied = CopyBuffer(mtf_handle,4,mtf_time,mtf_time,mtf_choppy);
      if(copied <= 0) return(0);
      
      Choppy[x] = mtf_choppy[0];
      
      copied = CopyBuffer(mtf_handle,5,mtf_time,mtf_time,mtf_sideways);
      if(copied <= 0) return(0);
            
      Sideways[x] = mtf_sideways[0];
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
         else
         {
         signalBulls[shift] = Bulls[shift-1];
         signalBears[shift] = Bears[shift-1];
         }
         
      BullMarket[shift] = EMPTY_VALUE;
      BearMarket[shift] = EMPTY_VALUE;
      Correction[shift] = EMPTY_VALUE;
      BearRally[shift]  = EMPTY_VALUE;
      Choppy[shift]     = EMPTY_VALUE;
      Sideways[shift]   = EMPTY_VALUE;
      
     
         if(Bulls[shift] > signalBulls[shift] && Bulls[shift] > Bears[shift] && (Bears[shift] <= signalBears[shift] || Bears[shift] == 0)) BullMarket[shift] = IndicatorValue;
         else
         if(Bears[shift] > signalBears[shift] && Bears[shift] > Bulls[shift] && (Bulls[shift] <= signalBulls[shift] || Bulls[shift] == 0)) BearMarket[shift] = IndicatorValue;
         else
         if(Bulls[shift] < signalBulls[shift] && Bulls[shift] > Bears[shift] && Bears[shift] >= signalBears[shift]) Correction[shift] = IndicatorValue;
         else
         if(Bears[shift] < signalBears[shift] && Bears[shift] > Bulls[shift] && Bulls[shift] >= signalBulls[shift]) BearRally[shift]  = IndicatorValue;
         else
         if(Bears[shift] > signalBears[shift] && Bulls[shift] > signalBulls[shift]) Choppy[shift] = IndicatorValue;
         else
         if((Bears[shift] < signalBears[shift] || Bears[shift] == 0) && (Bulls[shift] < signalBulls[shift] || Bulls[shift] == 0)) Sideways[shift] = IndicatorValue;
      
     message = " " + Symbol() + " " + timeframeToString(tf) + " ";         
        
         if(shift == rates_total - 1 && AlertMode > 0)
         {
         if(BullMarket[shift-1] > 0 && BullMarket[shift-1] != EMPTY_VALUE && BullMarket[shift-2] == EMPTY_VALUE && Time[0] != prevAlertTime) {Alert(message + "Bull Market Begins!"    ); prevAlertTime = Time[0];}   
         if(BearMarket[shift-1] > 0 && BearMarket[shift-1] != EMPTY_VALUE && BearMarket[shift-2] == EMPTY_VALUE && Time[0] != prevAlertTime) {Alert(message + "Bear Market Begins!"    ); prevAlertTime = Time[0];}   
         if(Correction[shift-1] > 0 && Correction[shift-1] != EMPTY_VALUE && Correction[shift-2] == EMPTY_VALUE && Time[0] != prevAlertTime) {Alert(message + "Correction Begins!"     ); prevAlertTime = Time[0];}   
         if(BearRally [shift-1] > 0 && BearRally [shift-1] != EMPTY_VALUE && BearRally [shift-2] == EMPTY_VALUE && Time[0] != prevAlertTime) {Alert(message + "BearRally  Begins!"     ); prevAlertTime = Time[0];}   
         if(Choppy    [shift-1] > 0 && Choppy    [shift-1] != EMPTY_VALUE && Choppy    [shift-2] == EMPTY_VALUE && Time[0] != prevAlertTime) {Alert(message + "Choppy Market Begins!"  ); prevAlertTime = Time[0];}   
         if(Sideways  [shift-1] > 0 && Sideways  [shift-1] != EMPTY_VALUE && Sideways  [shift-2] == EMPTY_VALUE && Time[0] != prevAlertTime) {Alert(message + "Sideways Market Begins!"); prevAlertTime = Time[0];}   
         } 	     
      }   
   }
   
   if(ShowTimeFrame)
   {
   datetime timedelta = (Time[0] - Time[1])*4;
   string name = UniqueName + timeframeToString(tf) + " text ";
   ObjectDelete    (0,name);
   ObjectCreate    (0,name,OBJ_TEXT,window,Time[0]+timedelta,IndicatorValue+0.1);
   ObjectSetString (0,name,OBJPROP_TEXT    ,timeframeToString(tf)); 
   ObjectSetString (0,name,OBJPROP_FONT    ,FontName ); 
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,FontSize );
   ObjectSetInteger(0,name,OBJPROP_COLOR   ,TextColor);
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

datetime iTime(string symbol,ENUM_TIMEFRAMES TF,int index)
{
   if(index < 0) return(-1);
   static datetime timearray[];
   if(CopyTime(symbol,TF,index,1,timearray) > 0) return(timearray[0]); else return(-1);
}


void deleteObj (string prefix)
{	
	string	name	= "";
	int		total	= ObjectsTotal(0) - 1;
	
	for(int i=total;i>=0;i--)
	{
	name = ObjectName(0,i);
	if(StringFind(name,prefix) >= 0) {ObjectDelete(0,name);}
	}
}
  