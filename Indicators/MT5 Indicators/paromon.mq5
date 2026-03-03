//+------------------------------------------------------------------+
//|                                                      Paromon.mq5 |
//|                                        Copyright © 2005, Danilla |
//|                                                                  |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2005, Danilla"
//---- link to the website of the author
#property link      ""
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//+-----------------------------------+
//|  enumeration declaration          |
//+-----------------------------------+
enum Number
  {
   Number_0,
   Number_1,
   Number_2,
   Number_3
  };
//+-----------------------------------+
//|  enumeration declaration          |
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
//|  enumeration declaration          |
//+-----------------------------------+
enum STYLE
  {
   SOLID_,//Solid line
   DASH_,//Dashed line
   DOT_,//Dotted line
   DASHDOT_,//Dot-dash line
   DASHDOTDOT_   //Dot-dash line with double dots
  };
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET       0 // The constant for returning the indicator recalculation command to the terminal
#define DAYSSIZE    60*60*24 // The constant for the number of seconds in a day
#define SIZE10HOURS 60*60*10 // The constant for the number of seconds in 10 hours
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input string  IndicatorSirname="Paromon";
//----
input color  Up_Color = clrLime; //upper level color
input color  Md_Color = clrBlue; //medium level color
input color  Dn_Color=clrMagenta; //lower level color
input color  DayColor=clrRed; //R15 level color
//----
input STYLE  Up_Style = SOLID_;      //style of the upper level
input STYLE  Md_Style = DASHDOTDOT_; //style of the medium level
input STYLE  Dn_Style = SOLID_;      //style of the lower level
input STYLE  DayStyle = SOLID_;      //style of the R15 level line
//----
input Width  Up_Width = Width_2; //upper level width
input Width  Md_Width = Width_1; //medium level width
input Width  Dn_Width = Width_2; //lower level width
input Width  DayWidth = Width_2; //R15 line level width

//+----------------------------------------------+
//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
//----
int DayExtremumsOffset=3600;
string UpLineName,MiddleLineName,DownLineName,DayLineName;
//+------------------------------------------------------------------+
//|  Creating horizontal price level                                 |
//+------------------------------------------------------------------+
void CreateHline
(
 long   chart_id,      // chart ID
 string name,          // object name
 int    nwin,          // window index
 double price,         // price level
 color  Color,         // line color
 int    style,         // line style
 int    width,         // line width
 string text           // text
 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_HLINE,0,0,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//----
  }
//+------------------------------------------------------------------+
//|  Reinstallation of the horizontal price level                    |
//+------------------------------------------------------------------+
void SetHline
(
 long   chart_id,      // chart ID
 string name,          // object name
 int    nwin,          // window index
 double price,         // price level
 color  Color,         // line color
 int    style,         // line style
 int    width,         // line width
 string text           // text
 )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateHline(chart_id,name,nwin,price,Color,style,width,text);
   else
     {
      //ObjectSetDouble(chart_id,name,OBJPROP_PRICE,price);
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,0,price);
     }
//----
  }
//+------------------------------------------------------------------+
//|  Vertical line creation                                          |
//+------------------------------------------------------------------+
void CreateVline
(
 long     chart_id,      // chart ID
 string   name,          // object name
 int      nwin,          // window index
 datetime time1,         // vertical level time
 color    Color,         // line color
 int      style,         // line style
 int      width,         // line width
 bool     background,// line background display
 string   text           // text
 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_VLINE,nwin,time1,999999999);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,background);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
   ObjectSetString(chart_id,name,OBJPROP_TOOLTIP,"\n"); //tooltip disabling
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true); //background object
//----
  }
//+------------------------------------------------------------------+
//|  Vertical line reinstallation                                    |
//+------------------------------------------------------------------+
void SetVline
(
 long     chart_id,      // chart ID
 string   name,          // object name
 int      nwin,          // window index
 datetime time1,         // vertical level time
 color    Color,         // line color
 int      style,         // line style
 int      width,         // line width
 bool     background,// line background display
 string   text           // text
 )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateVline(chart_id,name,nwin,time1,Color,style,width,background,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,999999999);
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//----
   UpLineName=IndicatorSirname+" UpLine";
   MiddleLineName=IndicatorSirname+" MiddleLine";
   DownLineName=IndicatorSirname+" DownLine";
   DayLineName=IndicatorSirname+" DayLine";
//---- creating labels for displaying in DataWindow and the name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"Paromon");
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectDelete(0,UpLineName);
   ObjectDelete(0,MiddleLineName);
   ObjectDelete(0,DownLineName);
   ObjectDelete(0,DayLineName);
//----
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of price lows for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
//----  
   double lowprice,highprice,avprice;
   int DayExtremumsBarOffset=0;
   datetime iTime[];
//----   

//---- copy newly appeared data in the iTime[] array
   if(CopyTime(Symbol(),PERIOD_D1,0,1,iTime)<=0) return(RESET);
   
   int bar=0;
   while(time[bar]>=iTime[0]) bar++;
   if(bar) bar--;
//----
   if(TimeCurrent()%DAYSSIZE>SIZE10HOURS)
     {
      while(time[0]-time[DayExtremumsBarOffset]<DayExtremumsOffset && time[DayExtremumsBarOffset]%DAYSSIZE>SIZE10HOURS)
         DayExtremumsBarOffset++;

      if(DayExtremumsBarOffset) DayExtremumsBarOffset--;
     }
//----  
    lowprice=low[ArrayMinimum(low,DayExtremumsBarOffset,bar-DayExtremumsBarOffset)];
    highprice=high[ArrayMaximum(high,DayExtremumsBarOffset,bar-DayExtremumsBarOffset)];
   avprice=(highprice+lowprice)/2;
//----
   SetHline(0,UpLineName,0,highprice,Up_Color,Up_Style,Up_Width,UpLineName+DoubleToString(highprice,_Digits));
   SetHline(0,MiddleLineName,0,avprice,Md_Color,Md_Style,Md_Width,MiddleLineName+DoubleToString(avprice,_Digits));
   SetHline(0,DownLineName,0,lowprice,Dn_Color,Dn_Style,Dn_Width,DownLineName+DoubleToString(lowprice,_Digits));
   SetVline(0,DayLineName,0,time[bar],DayColor,DayStyle,DayWidth,true,"дневной бар");
//----
   ChartRedraw(0);
//----   
   return(rates_total);
  }
//+------------------------------------------------------------------+
