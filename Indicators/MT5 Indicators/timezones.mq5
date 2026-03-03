//+------------------------------------------------------------------+ 
//|                                                    TimeZones.mq5 |
//|                              Copyright © 2005. Alejandro Galindo | 
//|                                              http://elCactus.com | 
//+------------------------------------------------------------------+ 
//--- copyright
#property copyright "Copyright © 2005. Alejandro Galindo"
//--- a link to the website of the author
#property link "http://elCactus.com" 
//--- indicator version
#property version   "1.00"
#property description ""
//--- buffers are not used for indicator calculation and drawing
#property indicator_buffers 0
//--- no graphical constructions
#property indicator_plots   0
//+----------------------------------------------+ 
//| Indicator drawing parameters                 |
//+----------------------------------------------+ 
//--- drawing the indicator in the main window
#property indicator_chart_window 
//+----------------------------------------------+
//| declaration of constants                     |
//+----------------------------------------------+
#define RESET 0                     // A constant for returning the indicator recalculation command to the terminal
#define DAILY_PERIOD_SECOND  86400  // Number of seconds in a day period
#define WEEKLY_PERIOD_SECOND 604800 // Number of seconds in a week period including Sundays
//+----------------------------------------------+ 
//| declaration of enumerations                  |
//+----------------------------------------------+ 
enum ENUM_WIDTH //Type of constant
  {
   w_1 = 1,   //1
   w_2,       //2
   w_3,       //3
   w_4,       //4
   w_5        //5
  };
//+----------------------------------------------+
//| declaration of enumerations                  |
//+----------------------------------------------+
enum STYLE
  {
   SOLID_,       //Solid line
   DASH_,        //Dashed line
   DOT_,         //Dotted line
   DASHDOT_,     //Dot-dash line
   DASHDOTDOT_   // Dot-dash line with double dots
  };
//+----------------------------------------------+
//| declaration of enumerations                  |
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
//| Indicator input parameters                   |
//+----------------------------------------------+ 
//--- Common Settings
input string LinesSirname="TimeZones";   // Line name
input uint WeeklyTotal=4;                // Number of weeks in the history for indexing
input uint FutureTotal=1;                // Number of lines in future for indexing
//--- settings for day bars
input color Line_Color_D=clrRed;         // Day line color
input STYLE Line_Style_D=SOLID_;         // Day line display style
input ENUM_WIDTH Line_Width_D=w_3;       // Day line width
input bool SetBackground_D=true;         // Background display of day lines
//--- settings for intraday GMT bars
input Hour GMT=H02; //
input color Line_Color_D1=clrDodgerBlue; // GMT line color
input STYLE Line_Style_D1=SOLID_;        // GMT line style
input ENUM_WIDTH Line_Width_D1=w_2;      // GMT line width
input bool SetBackground_D1=true;        // Background display of the GMT line
//--- settings for intraday MST bars
input Hour MST=H06; //
input color Line_Color_D2=clrLime;       // MST line color
input STYLE Line_Style_D2=SOLID_;        // MST line style
input ENUM_WIDTH Line_Width_D2=w_2;      // MST line width
input bool SetBackground_D2=true;        // Background display of the MST line
//--- settings for intraday EST bars
input Hour EST=H07; //
input color Line_Color_D3=clrDarkOrchid; // EST line color
input STYLE Line_Style_D3=SOLID_;        // EST line style
input ENUM_WIDTH Line_Width_D3=w_2;      // EST line width
input bool SetBackground_D3=true;        // Background display of the EST line
//+----------------------------------------------+
//--- declaration of dynamic arrays that will be used as ring buffers
uint Count_W[],Count_D0[],Count_D1[],Count_D2[],Count_D3[];
datetime VLineTime_W[],VLineTime_D0[],VLineTime_D1[],VLineTime_D2[],VLineTime_D3[];
//--- declaration of integer variables of data starting point
uint WeeklyTotal_,LinesTotal_D_,LinesTotal_D,FutureTotal_D;
//--- declaring variables of the line labels
string Sirname_W,Sirname_D[4];
//+------------------------------------------------------------------+
//| Checking the bar to set the day line                             |
//+------------------------------------------------------------------+   
bool CheckVLinePoint_D(datetime bartime1,datetime bartime0)
  {
//---
   MqlDateTime tm0,tm1;
   TimeToStruct(bartime0,tm0);
   TimeToStruct(bartime1,tm1);
   if(tm0.day_of_year!=tm1.day_of_year) return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Checking the bar to set the intraday line                        |
//+------------------------------------------------------------------+   
bool CheckVLinePoint_DN(datetime bartime1,datetime bartime0,uint hour)
  {
//---
   MqlDateTime tm0,tm1;
   TimeToStruct(bartime0,tm0);
   TimeToStruct(bartime1,tm1);
   if(tm1.hour!=hour && tm0.hour==hour) return(true);
   if(tm0.day_of_year!=tm1.day_of_year && tm0.hour==hour) return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Recalculation of position of the newest element in the array     |
//+------------------------------------------------------------------+   
bool CheckVLinePoint_W(int bar,datetime bartime)
  {
//---
   MqlDateTime tm;
   TimeToStruct(bartime,tm);
   if(tm.day_of_week==0 || tm.day_of_week==6) return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Recalculation of position of the newest element in the array     |
//+------------------------------------------------------------------+  
class CRecount_ArrayZeroPos
  {
public:
   void              Recount_ArrayZeroPos(int &CoArr[],// Return the current value of the price series by reference
                                          int Size)    // Number of the elements in the ring buffer
     {
      //---
      int numb,Max1,Max2;

      Max2=Size;
      Max1=Max2-1;

      m_count--;
      if(m_count<0) m_count=Max1;

      for(int iii=0; iii<Max2; iii++)
        {
         numb=iii+m_count;
         if(numb>Max1) numb-=Max2;
         CoArr[iii]=numb;
        }
      //---
     }
                     CRecount_ArrayZeroPos(){m_count=1;};
protected:
   int               m_count;
  };
//+------------------------------------------------------------------+
//| Renaming the vertical line                                       |
//+------------------------------------------------------------------+
bool RenameVline(long     chart_id,    // Chart ID
                 string   oldname,     // old object name
                 string   newname)     // new object name
  {
//---
   if(ObjectFind(chart_id,oldname)>0)
     {
      ObjectSetString(chart_id,oldname,OBJPROP_NAME,newname);
      return(true);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Create a vertical line                                           |
//+------------------------------------------------------------------+
void CreateVline(long     chart_id,      // Chart id
                 string   name,          // object name
                 int      nwin,          // window index
                 datetime time1,         // vertical level time
                 color    Color,         // line color
                 int      style,         // line style
                 int      width,         // line width
                 bool     background,    // line background display
                 string   text)          // text
  {
//---
   ObjectCreate(chart_id,name,OBJ_VLINE,nwin,time1,999999999);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,background);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
   ObjectSetString(chart_id,name,OBJPROP_TOOLTIP,"\n"); // tooltip disabling
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);   // background object
//---
  }
//+------------------------------------------------------------------+
//| Resetting the vertical line                                      |
//+------------------------------------------------------------------+
void SetVline(long     chart_id,      // chart id
              string   name,          // object name
              int      nwin,          // window index
              datetime time1,         // vertical level time
              color    Color,         // line color
              int      style,         // line style
              int      width,         // line width
              bool     background,    // line background display
              string   text)          // text
  {
//---
   if(ObjectFind(chart_id,name)==-1) CreateVline(chart_id,name,nwin,time1,Color,style,width,background,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,999999999);
     }
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+     
void Deinit()
  {
//---
   int total=ObjectsTotal(0,0,-1)-1;
   string name,sirname;

   for(int numb=total; numb>=0 && !IsStopped(); numb--)
     {
      name=ObjectName(0,numb,0,-1);
      sirname=StringSubstr(name,0,StringLen(LinesSirname));

      if(sirname==LinesSirname) ObjectDelete(0,name);
     }
//---
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//--- checking the chart period to be enough for the calculation
   if(Period()>PERIOD_H1) return;
   Deinit();
//--- initialization of variables of the start of data calculation
   WeeklyTotal_=WeeklyTotal+1;
//---
   LinesTotal_D=WeeklyTotal_*4;
   FutureTotal_D=FutureTotal;
   LinesTotal_D_=LinesTotal_D+FutureTotal_D;
//--- initialization of string labels 
   Sirname_W=LinesSirname+"_W_";
   Sirname_D[0]=LinesSirname+"_D0_";
   Sirname_D[1]=LinesSirname+"_D1_";
   Sirname_D[2]=LinesSirname+"_D2_";
   Sirname_D[3]=LinesSirname+"_D3_";
//---- memory distribution for variables' arrays  
   ArrayResize(Count_D0,LinesTotal_D_);
   ArrayResize(VLineTime_D0,LinesTotal_D_);
   ArrayResize(Count_D1,LinesTotal_D_);
   ArrayResize(VLineTime_D1,LinesTotal_D_);
   ArrayResize(Count_D2,LinesTotal_D_);
   ArrayResize(VLineTime_D2,LinesTotal_D_);
   ArrayResize(Count_D3,LinesTotal_D_);
   ArrayResize(VLineTime_D3,LinesTotal_D_);
//--- name for the data window and the label for sub-windows
   string shortname;
   StringConcatenate(shortname,"TimeZones(",LinesSirname,", ",WeeklyTotal,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---   
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
//--- checking the chart period to be enough for the calculation
   if(Period()>PERIOD_H1) return(RESET);
//--- checking if the number of bars is enough for the calculation
   if(rates_total<2) return(RESET);
   if(prev_calculated==rates_total) return(rates_total);
//--- declarations of local variables 
   string Name;
   datetime Time,TimeCur;
   int limit,bar;
   static datetime LastTime_D[4];
   static CRecount_ArrayZeroPos D0,D1,D2,D3;
   ArrayInitialize(LastTime_D,0);
//--- apply timeseries indexing to array elements 
   ArraySetAsSeries(time,true);
//--- Calculate the limit starting number for loop of bars recalculation and start initialization of variables
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      limit=rates_total-2; // Starting index for the calculation of all bars
      uint VLineCount_W=0;
      for(bar=0; bar<=limit && !IsStopped(); bar++)
         if(CheckVLinePoint_W(bar,(time[bar]+time[bar+1])/2))
           {
            VLineCount_W++;
            if(VLineCount_W>=WeeklyTotal) break;
           }
      if(bar<limit) limit=bar;
     }
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars
//--- indicator calculation loop on current bars
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- drawing the intraday GMT line on history
      if(CheckVLinePoint_DN(time[bar+1],time[bar],GMT))
        {
         Name=Sirname_D[1]+TimeToString(time[bar]);
         Time=VLineTime_D1[Count_D1[FutureTotal_D]];
         RenameVline(0,Sirname_D[1]+TimeToString(Time),Name);
         SetVline(0,Name,0,time[bar],Line_Color_D1,Line_Style_D1,Line_Width_D1,SetBackground_D1,"intraday GMT bar");
         VLineTime_D1[Count_D1[FutureTotal_D]]=time[bar];
         if(bar>0) D1.Recount_ArrayZeroPos(Count_D1,LinesTotal_D_);
         LastTime_D[1]=time[bar];
        }
      //--- drawing the intraday MST line on history
      if(CheckVLinePoint_DN(time[bar+1],time[bar],MST))
        {
         Name=Sirname_D[2]+TimeToString(time[bar]);
         Time=VLineTime_D2[Count_D2[FutureTotal_D]];
         RenameVline(0,Sirname_D[2]+TimeToString(Time),Name);
         SetVline(0,Name,0,time[bar],Line_Color_D2,Line_Style_D2,Line_Width_D2,SetBackground_D2,"intraday MST bar");
         VLineTime_D2[Count_D2[FutureTotal_D]]=time[bar];
         if(bar>0) D2.Recount_ArrayZeroPos(Count_D2,LinesTotal_D_);
         LastTime_D[2]=time[bar];
        }

      //--- drawing the intraday EST line on history
      if(CheckVLinePoint_DN(time[bar+1],time[bar],EST))
        {
         Name=Sirname_D[3]+TimeToString(time[bar]);
         Time=VLineTime_D3[Count_D3[FutureTotal_D]];
         RenameVline(0,Sirname_D[3]+TimeToString(Time),Name);
         SetVline(0,Name,0,time[bar],Line_Color_D3,Line_Style_D3,Line_Width_D3,SetBackground_D3,"intraday EST bar");
         VLineTime_D3[Count_D3[FutureTotal_D]]=time[bar];
         if(bar>0) D3.Recount_ArrayZeroPos(Count_D3,LinesTotal_D_);
         LastTime_D[3]=time[bar];
        }
      //--- building the day line on history data
      if(CheckVLinePoint_D(time[bar+1],time[bar]))
        {
         Name=Sirname_D[0]+TimeToString(time[bar]);
         Time=VLineTime_D0[Count_D0[FutureTotal_D]];
         RenameVline(0,Sirname_D[0]+TimeToString(Time),Name);
         SetVline(0,Name,0,time[bar],Line_Color_D,Line_Style_D,Line_Width_D,SetBackground_D,"day bar");
         VLineTime_D0[Count_D0[FutureTotal_D]]=time[bar];
         if(bar>0) D0.Recount_ArrayZeroPos(Count_D0,LinesTotal_D_);
         LastTime_D[0]=time[bar];
        }
     }
   TimeCur=TimeCurrent();
//--- indicator calculation loop in future (day and intraday lines)
   for(int numb=int(FutureTotal_D)-1; numb>=0 && !IsStopped(); numb--)
     {
      //--- drawing the intraday GMT line on future data
      Time=LastTime_D[1]+DAILY_PERIOD_SECOND*(FutureTotal_D-numb);
      if(TimeCur>=Time) Time+=DAILY_PERIOD_SECOND;
      if(TimeCur>=Time) Time+=DAILY_PERIOD_SECOND;
      Name=Sirname_D[1]+TimeToString(Time);
      RenameVline(0,Sirname_D[1]+TimeToString(VLineTime_D1[Count_D1[numb]]),Name);
      SetVline(0,Name,0,Time,Line_Color_D1,Line_Style_D1,Line_Width_D1,SetBackground_D1,"intraday GMT bar");
      VLineTime_D1[Count_D1[numb]]=Time;

      //--- drawing the intraday MST line on future data
      Time=LastTime_D[2]+DAILY_PERIOD_SECOND*(FutureTotal_D-numb);
      if(TimeCur>=Time) Time+=DAILY_PERIOD_SECOND;
      if(TimeCur>=Time) Time+=DAILY_PERIOD_SECOND;
      Name=Sirname_D[2]+TimeToString(Time);
      RenameVline(0,Sirname_D[2]+TimeToString(VLineTime_D2[Count_D2[numb]]),Name);
      SetVline(0,Name,0,Time,Line_Color_D2,Line_Style_D2,Line_Width_D2,SetBackground_D2,"внутридневный бар MST");
      VLineTime_D2[Count_D2[numb]]=Time;

      //--- drawing the intraday EST line on future data
      Time=LastTime_D[3]+DAILY_PERIOD_SECOND*(FutureTotal_D-numb);
      if(TimeCur>=Time) Time+=DAILY_PERIOD_SECOND;
      if(TimeCur>=Time) Time+=DAILY_PERIOD_SECOND;
      Name=Sirname_D[3]+TimeToString(Time);
      RenameVline(0,Sirname_D[3]+TimeToString(VLineTime_D3[Count_D3[numb]]),Name);
      SetVline(0,Name,0,Time,Line_Color_D3,Line_Style_D3,Line_Width_D3,SetBackground_D3,"внутридневный бар EST");
      VLineTime_D3[Count_D2[numb]]=Time;

      //--- drawing the 00:00 on future data
      Time=LastTime_D[0]+DAILY_PERIOD_SECOND*(FutureTotal_D-numb);
      if(TimeCur>=Time) Time+=DAILY_PERIOD_SECOND;
      if(TimeCur>=Time) Time+=DAILY_PERIOD_SECOND;
      Name=Sirname_D[0]+TimeToString(Time);
      RenameVline(0,Sirname_D[0]+TimeToString(VLineTime_D0[Count_D0[numb]]),Name);
      SetVline(0,Name,0,Time,Line_Color_D,Line_Style_D,Line_Width_D,SetBackground_D,"day bar");
      VLineTime_D0[Count_D0[numb]]=Time;
     }
//--- 
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
