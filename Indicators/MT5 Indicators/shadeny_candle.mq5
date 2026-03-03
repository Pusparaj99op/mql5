//+------------------------------------------------------------------+
//|                                               ShadeNY_candle.mq5 |
//|                                         Copyright © 2006, sx ted |
//| Purpose: shade New York or other sessions for chart time frames  |
//|          M1 to H4 (at a push).                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, sx ted"
#property link      ""
//--- indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window
//--- number of indicator buffers is 2
#property indicator_buffers 6 
//--- three plots are used
#property indicator_plots   3
//+----------------------------------------------+
//| Indicator 1 drawing parameters               |
//+----------------------------------------------+
//--- drawing the indicator as a colored cloud
#property indicator_type1   DRAW_FILLING
//--- the color of the indicator
#property indicator_color1  clrLime,clrRed
//--- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//--- displaying the indicator label
#property indicator_label1  "Upper Shade"
//+----------------------------------------------+
//| Indicator 2 drawing parameters               |
//+----------------------------------------------+
//--- drawing the indicator as a colored cloud
#property indicator_type2   DRAW_FILLING
//--- the color of the indicator
#property indicator_color2  clrDeepSkyBlue,clrMagenta
//--- the indicator line is a continuous curve
#property indicator_style2  STYLE_SOLID
//--- displaying the indicator label
#property indicator_label2  "Body"
//+----------------------------------------------+
//| Indicator 3 drawing parameters               |
//+----------------------------------------------+
//--- drawing the indicator as a colored cloud
#property indicator_type3   DRAW_FILLING
//--- the color of the indicator
#property indicator_color3  clrLime,clrRed
//--- the indicator line is a continuous curve
#property indicator_style3  STYLE_SOLID
//--- displaying the indicator label
#property indicator_label3  "Lower Shade"
//+----------------------------------------------+
//| declaration of enumerations                  |
//+----------------------------------------------+
enum Hour //Type of constant
  {
   H00=0,    //00
   H01,      //01
   H02,      //02
   H03,      //03
   H04,      //04
   H05,      //05
   H06,      //06
   H07,      //07
   H08,      //08
   H09,      //09
   H10,      //10
   H11,      //11
   H12,      //12
   H13,      //13
   H14,      //14
   H15,      //15
   H16,      //16
   H17,      //17
   H18,      //18
   H19,      //19
   H20,      //20
   H21,      //21
   H22,      //22
   H23,      //23
  };
//+----------------------------------------------+
//|  declaration of enumerations                 |
//+----------------------------------------------+
enum Min //Type of constant
  {
   M00=0,    //00
   M01,      //01
   M02,      //02
   M03,      //03
   M04,      //04
   M05,      //05
   M06,      //06
   M07,      //07
   M08,      //08
   M09,      //09
   M10,      //10
   M11,      //11
   M12,      //12
   M13,      //13
   M14,      //14
   M15,      //15
   M16,      //16
   M17,      //17
   M18,      //18
   M19,      //19
   M20,      //20
   M21,      //21
   M22,      //22
   M23,      //23
   M24,      //24
   M25,      //25
   M26,      //26
   M27,      //27
   M28,      //28
   M29,      //29
   M30,      //30
   M31,      //31
   M32,      //32
   M33,      //33
   M34,      //34
   M35,      //35
   M36,      //36
   M37,      //37
   M38,      //38
   M39,      //39
   M40,      //40
   M41,      //41
   M42,      //42
   M43,      //43
   M44,      //44
   M45,      //45
   M46,      //46
   M47,      //47
   M48,      //48
   M49,      //49
   M50,      //50
   M51,      //51
   M52,      //52
   M53,      //53
   M54,      //54
   M55,      //55
   M56,      //56
   M57,      //57
   M58,      //58
   M59       //59
  };
//+----------------------------------------------+
//| declaring constants                          |
//+----------------------------------------------+
#define RESET 0 // the constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input Hour   StartHour=H07;       // Session start hour
input Min    StartMinute=M00;     // Session start minute
input Hour   EndHour=H13;         // Session end hour
input Min    EndMinute=M00;       // Session start minute
input uint   Shift=0;             // Horizontal shift of the channel in bars
//+-----------------------------------+
//--- declaration of integer variables for the start of data calculation
int  min_rates_total;
//--- declaration of dynamic arrays that will be used as indicator buffers
double ExtA1Buffer[];
double ExtB1Buffer[];
double ExtA2Buffer[];
double ExtB2Buffer[];
double ExtA3Buffer[];
double ExtB3Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- checking the chart period
   if(Period()>PERIOD_H1)
     {
      Print("The ShadeNY requires timeframe below H2!");
      return(INIT_FAILED);
     }
//--- initialization of variables of data calculation start
   min_rates_total=int(PeriodSeconds(PERIOD_D1)/PeriodSeconds(PERIOD_CURRENT)+1);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtA1Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtA1Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(1,ExtB1Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtB1Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(2,ExtA2Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtA2Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(3,ExtB2Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtB2Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(4,ExtA3Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtA3Buffer,true);
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(5,ExtB3Buffer,INDICATOR_DATA);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ExtB3Buffer,true);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,2);
//--- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,2);
//--- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,2);
//--- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"ShadeNY");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total) return(RESET);
//--- declaration of variables with a floating point  
   double iHigh,iLow,iOpen,iClose;
//--- declaration of integer variables
   int limit;
   static int start;
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-2; // starting index for calculation of all bars
      start=0;
     }
   else limit=rates_total-prev_calculated;  // starting index for calculation of new bars only
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(Time,true);
//---
   start+=limit;
//--- main indicator calculation loop
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ExtA1Buffer[bar]=0.0;
      ExtB1Buffer[bar]=0.0;
      ExtA2Buffer[bar]=0.0;
      ExtB2Buffer[bar]=0.0;
      ExtA3Buffer[bar]=0.0;
      ExtB3Buffer[bar]=0.0;

      MqlDateTime tm0,tm1,tmx;
      TimeToStruct(Time[bar],tm0);
      TimeToStruct(Time[bar+1],tm1);
      TimeToStruct(Time[MathMax(bar-1,0)],tmx);

      if((tm0.hour==StartHour && tm0.min==StartMinute)
         || (tm0.hour==StartHour && tm0.min>StartMinute && (tm1.hour!=StartHour || (tm1.hour==StartHour && tm1.min<StartMinute)))
         ||(tm0.hour>StartHour && tm1.hour==StartHour && tm1.min<StartMinute)
         ||(tm0.hour>StartHour && tm0.day!=tm1.day))
        {
         start=bar;
         iOpen=Open[bar];
        }

      if(((tm0.hour==StartHour && tm0.min>=StartMinute) || tm0.hour>StartHour)
         && ((tm0.hour==EndHour && tm0.min<=EndMinute) || tm0.hour<EndHour))
        {
         if(!bar || tmx.hour>EndHour || (tmx.hour==EndHour && (tmx.min>EndMinute || tm0.day!=tmx.day)))
           {
            iHigh=High[ArrayMaximum(High,bar,start-bar+1)];
            iLow=Low[ArrayMinimum(Low,bar,start-bar+1)];
            iClose=Close[bar];

            if(iClose>=iOpen)
              {
               for(int index=start; index>=bar; index--)
                 {
                  ExtA1Buffer[index]=iHigh;
                  ExtB1Buffer[index]=iClose;
                  ExtA2Buffer[index]=iClose;
                  ExtB2Buffer[index]=iOpen;
                  ExtA3Buffer[index]=iOpen;
                  ExtB3Buffer[index]=iLow;
                 }
              }
             else
              {
               for(int index=start; index>=bar; index--)
                 {
                  ExtB1Buffer[index]=iHigh;
                  ExtA1Buffer[index]=iClose;
                  ExtA2Buffer[index]=iClose;
                  ExtB2Buffer[index]=iOpen;
                  ExtB3Buffer[index]=iOpen;
                  ExtA3Buffer[index]=iLow;
                 }
              }
           }
        }
     }
//---    
   return(rates_total);
  }
//+------------------------------------------------------------------+
