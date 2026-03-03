//+------------------------------------------------------------------+
//|                                             Pivot_RS_session.mq5 |
//|                                      Copyright © 2006, DVYU inc. |
//|                                                     dvyu@mail.ru |
//+------------------------------------------------------------------+
//--- Copyright
#property copyright "Copyright © 2006, DVYU inc."
//--- link to the website of the author
#property link      "dvyu@mail.ru"
//--- Indicator version
#property version   "1.00"
//--- drawing the indicator in the main window
#property indicator_chart_window 
//---- no buffers are used for the calculation and drawing of the indicator
#property indicator_buffers 0
//--- 0 graphical plots are used
#property indicator_plots   0
//+----------------------------------------------+
//|  declaration of enumerations                 |
//+----------------------------------------------+
enum Hour    //Type of constant
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
//+-----------------------------------+
//|  declaration of enumeration       |
//+-----------------------------------+  
enum Width
  {
   Width_1=1, //1
   Width_2,   //2
   Width_3,   //3
   Width_4,   //4
   Width_5    //5
  };
//+-----------------------------------+
//|  declaration of enumeration       |
//+-----------------------------------+
enum STYLE
  {
   SOLID_,       // Solid line
   DASH_,        // Dashed line
   DOT_,         // Dotted line
   DASHDOT_,     // Dot-dash line
   DASHDOTDOT_   // Dot-dash line with double dots
  };
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input Hour   StartHour=H08;              // Hour of session start
input Min    StartMinute=M00;            // Minute of session start
input uint   SessionTime=400;            // Session time in minutes
input color  Color_Session = clrPlum;    // Session color
input color  Color_Res = clrBlue;        // Color of resistance
input color  Color_R30 = clrGreen;       // Color of level R30
input color  Color_R20 = clrGreen;       // Color of level R20
input color  Color_R10 = clrGreen;       // Color of level R10
input color    Color_P=clrDarkOrchid;    // Color of level P
input color  Color_S10 = clrRed;         // Color of level S10
input color  Color_S20 = clrRed;         // Color of level S20
input color  Color_S30 = clrRed;         // Color of level S30
input color  Color_Sup = clrMagenta;     // Color of support
//---
input STYLE  Style_Res = SOLID_;         // Resistance line style
input STYLE  Style_R30 = SOLID_;         // Line style of level R30
input STYLE  Style_R20 = SOLID_;         // Line style of level R20
input STYLE  Style_R10 = SOLID_;         // Line style of level R10
input STYLE    Style_P = DASH_;          // Line style of level P
input STYLE  Style_S10 = SOLID_;         // Line style of level S10
input STYLE  Style_S20 = SOLID_;         // Line style of level S20
input STYLE  Style_S30 = SOLID_;         // Line style of level S30
input STYLE  Style_Sup = SOLID_;         // Support line style
//---
input Width  Width_Res = Width_2;        // Resistance line width
input Width  Width_R30 = Width_1;        // Line width of level R30
input Width  Width_R20 = Width_2;        // Line width of level R20
input Width  Width_R10 = Width_3;        // Line width of level R10
input Width    Width_P = Width_1;        // Line width of level P
input Width  Width_S10 = Width_3;        // Line width of level S10
input Width  Width_S20 = Width_2;        // Line width of level S20
input Width  Width_S30 = Width_1;        // Line width of level S30
input Width  Width_Sup = Width_2;        // Support line width
//+----------------------------------------------+
int  StartHourSec,StartMinuteSec,SessionTimeSec;
//+------------------------------------------------------------------+
//|  Creating horizontal price level                                 |
//+------------------------------------------------------------------+
void CreateHline(long   chart_id,      // Chart ID
                 string name,          // object name
                 int    nwin,          // window index
                 double price,         // price level
                 color  Color,         // line color
                 int    style,         // line style
                 int    width,         // line width
                 string text)          // text
  {
//---
   ObjectCreate(chart_id,name,OBJ_HLINE,0,0,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//---
  }
//+------------------------------------------------------------------+
//|  Reinstallation of the horizontal price level                    |
//+------------------------------------------------------------------+
void SetHline(long   chart_id,// chart ID
              string name,          // object name
              int    nwin,          // window index
              double price,         // price level
              color  Color,         // line color
              int    style,         // line style
              int    width,         // line width
              string text)          // text
  {
//---
   if(ObjectFind(chart_id,name)==-1) CreateHline(chart_id,name,nwin,price,Color,style,width,text);
   else
     {
      //ObjectSetDouble(chart_id,name,OBJPROP_PRICE,price);
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,0,price);
     }
//---
  }
//+------------------------------------------------------------------+
//|  Creating an equidistant channel                                 |
//+------------------------------------------------------------------+
void CreateChannel(long     chart_id,      // Chart ID
                   string   name,          // object name
                   int      nwin,          // window index
                   datetime time1,         // time 1
                   double   price1,        // price 1
                   datetime time2,         // time 2
                   double   price2,        // price 2
                   datetime time3,         // time 3
                   double   price3,        // price 3
                   color    Color,         // channel color 
                   bool     background,    // line background display
                   string   text)          // text
  {
//---
   ObjectCreate(chart_id,name,OBJ_CHANNEL,nwin,time1,price1,time2,price2,time3,price3);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_FILL,true);       //color filling of the object 
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,background); //object in the background
   ObjectSetString(chart_id,name,OBJPROP_TOOLTIP,"\n");     //tooltip disabled
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);       //object in the background
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_LEFT,true);   //beam continues to the left
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);  //beam continues to the right
//---
  }
//+------------------------------------------------------------------+
//|  Resetting the equidistant channel                               |
//+------------------------------------------------------------------+
void SetChannel(long     chart_id,      // Chart ID
                string   name,          // object name
                int      nwin,          // window index
                datetime time1,         // time 1
                double   price1,        // price 1
                datetime time2,         // time 2
                double   price2,        // price 2
                datetime time3,         // time 3
                double   price3,        // price 3
                color    Color,         // channel color
                bool     background,    // line background display
                string   text)          // text
  {
//---
   if(ObjectFind(chart_id,name)==-1) CreateChannel(chart_id,name,nwin,time1,price1,time2,price2,time3,price3,Color,background,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
      ObjectMove(chart_id,name,2,time3,price3);
     }
//---
  }
//+------------------------------------------------------------------+   
//| iBarShift() function                                             |
//+------------------------------------------------------------------+  
int iBarShift(string symbol,ENUM_TIMEFRAMES timeframe,datetime time)
  {
//---
   if(time<0) return(-1);
   datetime Arr[],time1;

   time1=(datetime)SeriesInfoInteger(symbol,timeframe,SERIES_LASTBAR_DATE);

   if(CopyTime(symbol,timeframe,time,time1,Arr)>0)
     {
      int size=ArraySize(Arr);
      return(size-1);
     }
   else return(-1);
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---
   StartHourSec=int(StartHour)*60*60;
   StartMinuteSec=int(StartMinute)*60;
   SessionTimeSec=int(SessionTime)*60;
//--- Determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- Creating labels for displaying in DataWindow and the name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"Pivot_RS_session");
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void Deinit()
  {
//---
   ObjectDelete(0,"Pivot_Line");
   ObjectDelete(0,"Sup");
   ObjectDelete(0,"Res");
   ObjectDelete(0,"R1.0_Line");
   ObjectDelete(0,"R2.0_Line");
   ObjectDelete(0,"R3.0_Line");
   ObjectDelete(0,"S1.0_Line");
   ObjectDelete(0,"S2.0_Line");
   ObjectDelete(0,"S3.0_Line");
   ObjectDelete(0,"Session");
//---
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//---
   Deinit();
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
//---
   datetime iTime[1];
//--- copy newly appeared data in the array
   if(CopyTime(Symbol(),PERIOD_D1,time[0],1,iTime)<=0) return(0);
//---
   datetime StartTime=datetime(iTime[0]+StartHourSec+StartMinuteSec);
   datetime EndTime=datetime(StartTime+SessionTimeSec);
//---
   if(StartTime>TimeCurrent())
     {
      Deinit();
      return(0);
     }
//---
   int StartBar=iBarShift(NULL,PERIOD_CURRENT,StartTime);
   int EndBar=MathMax(iBarShift(NULL,PERIOD_CURRENT,EndTime),0);
   int Count=StartBar-EndBar;
//---
   double H=high[ArrayMaximum(high,EndBar,Count)];
   double L=low[ArrayMinimum(low,EndBar,Count)];
   double C=close[StartBar];
//---
   double P=NormalizeDouble((L+H+C)/3,_Digits);
//---
   double R10=NormalizeDouble(2*P-L,_Digits);
   double S10=NormalizeDouble(2*P-H,_Digits);
   double R20=NormalizeDouble(P+(H-L),_Digits);
   double R30=NormalizeDouble(2*P-2*L+H,_Digits);
   double S20=NormalizeDouble(P-H+L,_Digits);
   double S30=NormalizeDouble(2*P-2*H+L,_Digits);
//---
   SetChannel(0,"Session",0,StartTime,C,StartTime,0.0,EndTime,0.0,Color_Session,true,"Session");
//---
   SetHline(0,"Res",0,H,Color_Res,Style_Res,Width_Res,"Res "+string(H));
   SetHline(0,"R3.0_Line",0,R30,Color_R30,Style_R30,Width_R30,"Pivot "+string(R10));
   SetHline(0,"R2.0_Line",0,R20,Color_R20,Style_R20,Width_R20,"Pivot "+string(R20));
   SetHline(0,"R1.0_Line",0,R10,Color_R10,Style_R10,Width_R10,"Pivot "+string(R10));
   SetHline(0,"Pivot_Line",0,P,Color_P,Style_P,Width_P,"Pivot "+string(P));
   SetHline(0,"S1.0_Line",0,S10,Color_S10,Style_S10,Width_S10,"Pivot "+string(S10));
   SetHline(0,"S2.0_Line",0,S20,Color_S20,Style_S20,Width_S20,"Pivot "+string(S20));
   SetHline(0,"S3.0_Line",0,S30,Color_S30,Style_S30,Width_S30,"Pivot "+string(S30));
   SetHline(0,"Sup",0,L,Color_Sup,Style_Sup,Width_Sup,"Sup "+string(L));
//---
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
