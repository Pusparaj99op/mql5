//+------------------------------------------------------------------+
//|                                               ant_GUBreakout.mq5 |
//|                                                        avoitenko |
//|                        https://login.mql5.com/en/users/avoitenko |
//+------------------------------------------------------------------+
#property copyright "avoitenko"
#property link      "https://login.mql5.com/en/users/avoitenko"
#property version   "1.041"//0.4.1
//---
#property indicator_chart_window
#property indicator_buffers   8
#property indicator_plots     5 
//---
#property indicator_type1  DRAW_FILLING
#property indicator_color1 clrDodgerBlue
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1
#property indicator_label1 "Area"
//---
#property indicator_type2  DRAW_FILLING
#property indicator_color2 clrBlue
#property indicator_style2 STYLE_SOLID
#property indicator_width2 1
#property indicator_label2 "Offset Upper"
//---
#property indicator_type3  DRAW_FILLING
#property indicator_color3 clrBlue
#property indicator_style3 STYLE_SOLID
#property indicator_width3 1
#property indicator_label3 "Offset Lower"
//---
#property indicator_type4  DRAW_LINE
#property indicator_color4 clrWhite
#property indicator_style4 STYLE_SOLID
#property indicator_width4 2
#property indicator_label4 "Line Upper"
//---
#property indicator_type5  DRAW_LINE
#property indicator_color5 clrWhite
#property indicator_style5 STYLE_SOLID
#property indicator_width5 2
#property indicator_label5 "Line Lower"

#define PREFIX "Text_"

//--- input parameters
input ushort   InpUniqueNumber=0;          // Unique Number
input string   time_options="---- Time Setting ---";// Time Setting
input int      InpGMTShift    =  0;          // GMT Shift (hours)
input ushort   InpStartHour   =  12;         // Time Start Hour (box)
input ushort   InpStartMinute =  00;         // Time Start Minute (box)
input ushort   InpStopHour    =  16;         // Time Stop Hour (box)
input ushort   InpStopMinute  =  00;         // Time Stop Minute (box)
input ushort   InpEndHour     =  21;         // Time End Hour (line)
input ushort   InpEndMinute   =  00;         // Time End Minute (line)
//---
input string   display_options="--- Display Setting ---";// Display Setting
input ushort   InpDays        =  6;          // Days Number
input ushort   InpOffsetPips  =  5;          // Offset Pips
input bool     InpShowLabels  =  true;       // Show Labels
input string   InpFontName    =  "Arial";    // Font Name
input ushort   InpFontSize    =  8;          // Font Size
input color    InpTextColor   =  clrWhite;   // Text Color

//--- buffers
double AreaUpperBuffer[];
double AreaLowerBuffer[];
double OffsetUpper1Buffer[];
double OffsetUpper2Buffer[];
double OffsetLower1Buffer[];
double OffsetLower2Buffer[];
double LineUpperBuffer[];
double LineLowerBuffer[];

//--- global vars
double min,max;
int coef;
bool increment;
string prefix;
datetime Days[];
int days_count;
datetime time_start,time_stop,time_end;
int index_start,index_stop,index_end;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   coef=1;
   if(_Digits==3 || _Digits==5)coef=10;

   prefix=PREFIX+IntegerToString(InpUniqueNumber);

//--- chart to the foreground
   ChartSetInteger(0,CHART_FOREGROUND,true);

//--- set buffers
   SetIndexBuffer(0,AreaUpperBuffer);
   SetIndexBuffer(1,AreaLowerBuffer);
   SetIndexBuffer(2,OffsetUpper1Buffer);
   SetIndexBuffer(3,OffsetUpper2Buffer);
   SetIndexBuffer(4,OffsetLower1Buffer);
   SetIndexBuffer(5,OffsetLower2Buffer);
   SetIndexBuffer(6,LineUpperBuffer);
   SetIndexBuffer(7,LineLowerBuffer);

//--- set direction buffers
   ArraySetAsSeries(AreaUpperBuffer,true);
   ArraySetAsSeries(AreaLowerBuffer,true);
   ArraySetAsSeries(OffsetUpper1Buffer,true);
   ArraySetAsSeries(OffsetUpper2Buffer,true);
   ArraySetAsSeries(OffsetLower1Buffer,true);
   ArraySetAsSeries(OffsetLower2Buffer,true);
   ArraySetAsSeries(LineUpperBuffer,true);
   ArraySetAsSeries(LineLowerBuffer,true);
   ArraySetAsSeries(Days,true);

//---
   IndicatorSetString(INDICATOR_SHORTNAME,"ant_GUBreakout("+IntegerToString(InpUniqueNumber)+")");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   return(0);
  }
//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- delete all my objects
   int total= ObjectsTotal(0);
   for(int i=total-1; i>=0; i--)
     {
      string obj_name=ObjectName(0,i);
      if(StringFind(obj_name,prefix)==0) ObjectDelete(0,obj_name);
     }
//---     
   ChartRedraw();
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
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
//---
   int limit;
   if(rates_total<prev_calculated || prev_calculated<=0)
     {
      limit=rates_total-1;
      ArrayInitialize(AreaUpperBuffer,0);
      ArrayInitialize(AreaLowerBuffer,0);
      ArrayInitialize(OffsetUpper1Buffer,0);
      ArrayInitialize(OffsetUpper2Buffer,0);
      ArrayInitialize(OffsetLower1Buffer,0);
      ArrayInitialize(OffsetLower2Buffer,0);
      ArrayInitialize(LineUpperBuffer,EMPTY_VALUE);
      ArrayInitialize(LineLowerBuffer,EMPTY_VALUE);
      min=DBL_MAX;
      max=0;
     }
   else limit=rates_total-prev_calculated;

   if(limit<2) days_count=1;
   else days_count=InpDays;

   if(CopyTime(_Symbol,PERIOD_D1,0,days_count,Days)!=days_count) return(0);

//--- main cycle
   for(int day=days_count-1; day>=0 && !_StopFlag; day--)
     {

      //--- calc time
      time_start  =  BuildTime(Days[day], InpStartHour, InpStartMinute, InpGMTShift);
      time_stop   =  BuildTime(Days[day], InpStopHour,  InpStopMinute, InpGMTShift);
      time_end    =  BuildTime(Days[day], InpEndHour,   InpEndMinute, InpGMTShift);


      //--- recacl time
      if(time_start>time_stop)
        {
         time_stop += PeriodSeconds(PERIOD_D1);
         time_end  += PeriodSeconds(PERIOD_D1);
        }
      time_end=fmax(time_stop,time_end);

      if(limit>1 || (time[0]>=time_start && time[0]<=time_end))
        {

         index_start = iBarShift(_Symbol,_Period,time_start);
         index_stop  = iBarShift(_Symbol,_Period,time_stop);
         index_end   = iBarShift(_Symbol,_Period,time_end);

         int count=index_start-index_stop+1;
         if(index_start<0 || index_stop<0 || count<1) return(0);

         int index_max = ArrayMaximum(high,index_stop, count);
         int index_min = ArrayMinimum(low, index_stop, count);
         if(index_max<0 || index_min<0) return(0);

         max = high[index_max];
         min = low[index_min];

         //--- draw box
         for(int i=index_start; i>=index_stop; i--)
           {
            if(InpOffsetPips>0)
              {
               if(max-min<=InpOffsetPips*coef*_Point*2)
                 {
                  AreaUpperBuffer[i]    = 0;
                  AreaLowerBuffer[i]    = 0;
                  OffsetUpper1Buffer[i] = max;
                  OffsetUpper2Buffer[i] = min;
                  OffsetLower1Buffer[i] = 0;
                  OffsetLower2Buffer[i] = 0;
                 }
               else
                 {
                  AreaUpperBuffer[i]    = max - InpOffsetPips*coef*_Point;
                  AreaLowerBuffer[i]    = min + InpOffsetPips*coef*_Point;

                  OffsetUpper1Buffer[i] = max;
                  OffsetUpper2Buffer[i] = max - InpOffsetPips*coef*_Point;

                  OffsetLower1Buffer[i] = min + InpOffsetPips*coef*_Point;
                  OffsetLower2Buffer[i] = min;
                 }
              }
            else
              {
               AreaUpperBuffer[i]    = max;
               AreaLowerBuffer[i]    = min;
               OffsetUpper1Buffer[i] = 0;
               OffsetUpper2Buffer[i] = 0;
               OffsetLower1Buffer[i] = 0;
               OffsetLower2Buffer[i] = 0;
              }
           }

         //--- draw line
         for(int i=index_start; i>=index_end; i--)
           {
            LineUpperBuffer[i] = max;
            LineLowerBuffer[i] = min;
           }

         //--- clear one previous line value
         LineUpperBuffer[index_start + 1] = EMPTY_VALUE;
         LineLowerBuffer[index_start + 1] = EMPTY_VALUE;

         //--- draw label
         if(InpShowLabels && count>1)
           {
            string mask=StringFormat("H:[%%.%df]  L:[%%.%df]  R:[%%d]",_Digits,_Digits);
            string text=StringFormat(mask,max,min,(int)((max-min)/_Point/coef));
            SetText(IntegerToString(Days[day]),time[index_start],max,text);
           }
        }
      else //--- clear all for current bar
        {
         AreaUpperBuffer[0]    = 0;
         AreaLowerBuffer[0]    = 0;
         OffsetUpper1Buffer[0] = 0;
         OffsetUpper2Buffer[0] = 0;
         OffsetLower1Buffer[0] = 0;
         OffsetLower2Buffer[0] = 0;
         LineUpperBuffer[0]    = EMPTY_VALUE;
         LineLowerBuffer[0]    = EMPTY_VALUE;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|   BuildTime                                                      |
//+------------------------------------------------------------------+
datetime BuildTime(datetime date,int hour,int minute,int offset)
  {
   datetime new_time;
   MqlDateTime dt;
   TimeToStruct(date,dt);

   dt.hour = hour;
   dt.min  = minute;
   new_time = StructToTime(dt);
   new_time+= PeriodSeconds(PERIOD_H1)*offset;

   return(new_time);
  }
//+------------------------------------------------------------------+
//|   SetText                                                        |
//+------------------------------------------------------------------+
void SetText(string sufix,datetime time,double price,string caption)
  {
//--- text
   string name=prefix+sufix;
   if(ObjectFind(0,name)==0 || ObjectCreate(0,name,OBJ_TEXT,0,time,price))
     {
      ObjectSetDouble(0,name,OBJPROP_PRICE,price);
      ObjectSetInteger(0,name,OBJPROP_TIME,time);
      ObjectSetString(0,name,OBJPROP_FONT,InpFontName);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,InpFontSize);
      ObjectSetInteger(0,name,OBJPROP_COLOR,InpTextColor);
      ObjectSetString(0,name,OBJPROP_TEXT,caption);
     }
  }
//+------------------------------------------------------------------+
//|   iBarShift                                                      |
//+------------------------------------------------------------------+
int iBarShift(string symbol,ENUM_TIMEFRAMES tf,datetime time)
  {
   if(time<0) return(-1);
   datetime Arr[];
   CopyTime(symbol,tf,0,1,Arr);
   datetime time1=Arr[0];
   if(CopyTime(symbol,tf,time,time1,Arr)>0)
     {
      if(ArraySize(Arr)>2) return(ArraySize(Arr)-1);
      if(time<time1) return(1);
      else return(0);
     }
   else return(-1);
  }
//+------------------------------------------------------------------+
