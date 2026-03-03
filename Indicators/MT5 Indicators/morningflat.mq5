//+------------------------------------------------------------------+
//|                                                  MorningFlat.mq5 |
//|                                      Copyright © 2006, Scriptong |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Scriptong"
#property link      " "
#property description "Morning flat"
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers
#property indicator_buffers 4 
//---- only 4 plots are used
#property indicator_plots   4

//+--------------------------------------------------+
//|  Indicator level drawing parameters              |
//+--------------------------------------------------+
//---- drawing the levels as lines
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
//---- selection of levels colors
#property indicator_color1  clrBlue
#property indicator_color2  clrRed
#property indicator_color3  clrTeal
#property indicator_color4  clrMagenta
//---- levels are solid curves
#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_SOLID
#property indicator_style4 STYLE_SOLID
//---- levels width is equal to 1
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
//---- displaying labels of the levels
#property indicator_label1  "Upper Line"
#property indicator_label2  "Lower Line"
#property indicator_label3  "Target Upper Line"
#property indicator_label4  "Target Lower Line"
//+--------------------------------------------------+
//|  declaration of enumerations                     |
//+--------------------------------------------------+
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

//+--------------------------------------------------+
//|  declaration of constants                        |
//+--------------------------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
//+--------------------------------------------------+
//|  INDICATOR INPUT PARAMETERS                      |
//+--------------------------------------------------+
input uint BarsTotal=500;
input Hour StartHour=H00;
input Hour EndHour=H08;
input double TargetLevel=161.8;
input color UpColor = clrBlue;
input color DnColor = clrRed;
input color TargetUpColor = clrTeal;
input color TargetDnColor = clrMagenta;
//+--------------------------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double Up[];
double Down[];
double TargetUp[];
double TargetDn[];

datetime LastDay;
//---- Declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+   
//| MorningFlat indicator initialization function                    | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- 
   if(Period()>PERIOD_H1)
     {
      Comment("The indicator works at all timeframes less than H2!");
      return;
     }
//---- Initialization of variables of data calculation starting point
   min_rates_total=2*PeriodSeconds(PERIOD_D1)/PeriodSeconds(PERIOD_CURRENT);

//---- setting dynamic arrays as indicator buffers
   SetIndexBuffer(0,Up,INDICATOR_DATA);
   SetIndexBuffer(1,Down,INDICATOR_DATA);
   SetIndexBuffer(2,TargetUp,INDICATOR_DATA);
   SetIndexBuffer(3,TargetDn,INDICATOR_DATA);
//---- set the position, from which the levels drawing starts
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
//---- indexing the elements in buffers as in timeseries   
   ArraySetAsSeries(Up,true);
   ArraySetAsSeries(Down,true);
   ArraySetAsSeries(TargetUp,true);
   ArraySetAsSeries(TargetDn,true);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"MorningFlat");

//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- end of initialization
  }
//+------------------------------------------------------------------+
//| MorningFlat deinitialization function                            |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   Comment("");

   int total;
   string name,sirname;

   total=ObjectsTotal(0,0,-1)-1;

   for(int numb=total; numb>=0 && !IsStopped(); numb--)
     {
      name=ObjectName(0,numb,0,-1);
      sirname=StringSubstr(name,0,StringLen("Lab"));

      if(sirname=="Lab") ObjectDelete(0,name);
     }
//----
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+ 
//| MorningFlat iteration function                                   | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- checking for the sufficiency of the number of bars for the calculation
   if(rates_total<min_rates_total || Period()>PERIOD_H1) return(RESET);

//----
   Comment("");

//---- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

   int limit;
   string Name,Text;
   LastDay=0;

//---- calculation of the starting number limit for the bar nulling loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      for(int bar=rates_total-1; bar>=0 && !IsStopped(); bar--)
        {
         TargetUp[bar]=0.0;
         TargetDn[bar]=0.0;
         Up[bar]=0.0;
         Down[bar]=0.0;
        }
      limit=rates_total-1-min_rates_total; // starting index for the calculation of all bars     
      limit=int(MathMin(BarsTotal,limit));
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for the calculation of new bars
     }

//---- main cycle of calculation of the indicator
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      MqlDateTime tqq;
      TimeToStruct(time[bar],tqq);

      if(tqq.hour>=EndHour)
        {
         datetime iTime[1];
         if(CopyTime(Symbol(),PERIOD_D1,time[bar],1,iTime)<=0) return(RESET);  // Calculation of the day start time
         datetime BeginDay=iTime[0];
         datetime NextDay=BeginDay+86400;  // Calculation of the beginning of the next day
         if(LastDay>=BeginDay) continue; // If the levels were already drawn this day, we will continue the main cycle

         int maxbar=rates_total-1-min_rates_total;
         int StartBar= MathMin(maxbar,iBarShift(Symbol(),0,BeginDay+StartHour*3600));   // Bar, corresponding to the beginning of the day plus shift in hours
         int FinishBar = MathMin(maxbar,iBarShift(Symbol(),0,BeginDay+EndHour*3600)+1); // Bar, corresponding to the last bar of the "morning flat"
         uint BarX=MathMin(StartBar-FinishBar+1,maxbar);

         if(int(BarX+FinishBar)>rates_total-1) continue;
         double LowV=NormalizeDouble(low[MathMax(0,ArrayMinimum(low,FinishBar,BarX))],_Digits);  // The lower boundary
         double HighV=NormalizeDouble(high[MathMax(0,ArrayMaximum(high,FinishBar,BarX))],_Digits); // The upper boundary
         double TargetU = NormalizeDouble((HighV-LowV)*(TargetLevel-100)/100+HighV,_Digits);
         double TargetD = NormalizeDouble(LowV-(HighV-LowV)*(TargetLevel-100)/100,_Digits);
         // The channel of the "morning flat"
         for(int kkk=StartBar; kkk>=FinishBar; kkk--)
           {
            Up[kkk]=HighV;
            Down[kkk]=LowV;
            TargetUp[kkk]=0.0;
            TargetDn[kkk]=0.0;
           }
         // -----------------------
         // Expected targets at the breakthrough of the flat  
         for(int fff=FinishBar; fff>=0 && time[fff]<NextDay; fff--)
           {
            TargetUp[fff] = TargetU;
            TargetDn[fff] = TargetD;
            Up[fff]=0.0;
            Down[fff]=0.0;
           }
         // -------------------  

         datetime TB=time[iBarShift(Symbol(),0,BeginDay)];

         Name="Lab"+DoubleToString(TB,0)+"U";
         SetArrowLeftPrice(0,Name,0,TB,HighV,UpColor,1);

         Name="Lab"+DoubleToString(TB,0)+"D";
         SetArrowLeftPrice(0,Name,0,TB,LowV,DnColor,1);

         Name="Lab"+DoubleToString(TB,0)+"U1";
         SetArrowLeftPrice(0,Name,0,time[FinishBar],TargetU,TargetUpColor,1);

         Name="Lab"+DoubleToString(TB,0)+"D1";
         SetArrowLeftPrice(0,Name,0,time[FinishBar],TargetD,TargetDnColor,1);

         Name="LabWidth"+string(TB);
         Text=DoubleToString(MathRound((HighV-LowV)/_Point),0);

         CreateText(0,Name,0,(time[FinishBar]-TB)/2+TB,HighV,Text,clrMagenta,"Georgia",10,ANCHOR_UPPER);

         //LastDay=BeginDay;  // Note, if the levels were already drawn this day
        }
     }
//----     
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+   
//| iBarShift() function                                             |
//+------------------------------------------------------------------+  
int iBarShift(string symbol,ENUM_TIMEFRAMES timeframe,datetime time)

// iBarShift(symbol, timeframe, time)
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
  {
//----
   if(time<0) return(-1);
   datetime Arr[],time1;

   time1=(datetime)SeriesInfoInteger(symbol,timeframe,SERIES_LASTBAR_DATE);

   if(CopyTime(symbol,timeframe,time,time1,Arr)>0)
     {
      int size=ArraySize(Arr);
      return(size-1);
     }
   else return(-1);
//----
  }
//+------------------------------------------------------------------+
//|  Creating a text label                                           |
//+------------------------------------------------------------------+
void CreateArrowLeftPrice //CreateArrowLeftPrice(0,"",0,Time,Price,Color,Size)
(
 long   chart_id,         // chart ID
 string name,             // object name
 int    nwin,             // window index
 datetime Time,           // price label time
 double Price,            // the price label location on a vertical
 color  Color,            // text color
 uint    Size             // font size
 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_ARROW_LEFT_PRICE,nwin,Time,Price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,Size);
//ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//----
  }
//+------------------------------------------------------------------+
//|  A text label shift                                              |
//+------------------------------------------------------------------+
void SetArrowLeftPrice //SetArrowLeftPrice(chart_id,name,nwin,Time,Price,Color,Size)
(
 long   chart_id,         // chart ID
 string name,             // object name
 int    nwin,             // window index
 datetime Time,           // price label time
 double Price,            // the price label location on a vertical
 color  Color,            // text color
 uint    Size             // font size
 )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateArrowLeftPrice(chart_id,name,nwin,Time,Price,Color,Size);
   else ObjectMove(chart_id,name,0,Time,Price);
//----
  }
//+------------------------------------------------------------------+
//|  Text Label creation                                             |
//+------------------------------------------------------------------+
void CreateText(long chart_id,// chart ID
                string   name,              // object name
                int      nwin,              // window index
                datetime time,              // price level time
                double   price,             // price level
                string   text,              // Labels text
                color    Color,             // Text color
                string   Font,              // Text font
                int      Size,              // Text size
                ENUM_ANCHOR_POINT point     // The chart corner to Which an text is attached
                )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_TEXT,nwin,time,price);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetString(chart_id,name,OBJPROP_FONT,Font);
   ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,Size);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,point);
//----
  }
//+------------------------------------------------------------------+
//|  Text Label reinstallation                                       |
//+------------------------------------------------------------------+
void SetText(long chart_id,// chart ID
             string   name,              // object name
             int      nwin,              // window index
             datetime time,              // price level time
             double   price,             // price level
             string   text,              // Labels text
             color    Color,             // Text color
             string   Font,              // Text font
             int      Size,              // Text size
             ENUM_ANCHOR_POINT point     // The chart corner to Which an text is attached
             )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateText(chart_id,name,nwin,time,price,text,Color,Font,Size,point);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time,price);
     }
//----
  }
//+------------------------------------------------------------------+
