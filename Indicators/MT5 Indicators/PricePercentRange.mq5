

//+------------------------------------------------------------------+
//|                                            PricePercentRange.mq5 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                              https://www.mql5.com/en/users/3rjfx |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property copyright "https://www.mql5.com/en/users/3rjfx. ~ By 3rjfx ~ Created: 2016/01/16"
#property link      "http://www.mql5.com"
#property link      "https://www.mql5.com/en/users/3rjfx"
#property version   "2.00"
#property description "Price(%)Range is the indicator for the MT5, which calculates the Price movement"
#property description "based on percentage High (Highest) and Low (Lowest) Price on 100 bars."
//--
#include <MovingAverages.mqh>
//---
#property indicator_separate_window
#property indicator_buffers 17
#property indicator_plots   9
//--
#property indicator_type1   DRAW_NONE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_LINE
#property indicator_type8   DRAW_LINE
#property indicator_type9   DRAW_LINE
#property indicator_type10   DRAW_NONE
#property indicator_type11   DRAW_NONE
#property indicator_type12   DRAW_NONE
#property indicator_type13   DRAW_NONE
#property indicator_type14   DRAW_NONE
#property indicator_type15   DRAW_NONE
#property indicator_type16   DRAW_NONE
#property indicator_type17   DRAW_NONE
///--
#property indicator_style2  STYLE_SOLID
#property indicator_style3  STYLE_SOLID
#property indicator_style4  STYLE_SOLID
#property indicator_style5  STYLE_SOLID
#property indicator_style6  STYLE_SOLID
#property indicator_style7  STYLE_SOLID
#property indicator_style8  STYLE_SOLID
#property indicator_style9  STYLE_SOLID
//--
//---
input     ENUM_APPLIED_PRICE AppliedPrice = PRICE_TYPICAL; // AppliedPrice
input     bool               SoundAlerts  = true;
input     bool                  MsgAlerts = true;
input     bool                eMailAlerts = false;
input     string           SoundAlertFile = "alert.wav";
input     color               MoveUpColor = clrBlue;
input     color             MoveDownColor = clrRed;
input     color        WaitDirectionColor = clrYellow;
input     color             MoveLinkColor = clrAqua;
input     color                 TextColor = clrSnow;
input     color              RoundedColor = clrYellow;
input     color   BorderlineAppPricesRise = clrBlue;
input     color   BorderlineAppPricesDown = clrRed;
input     int               LineWidthSize = 1;
input     color    TrendLineDowntoUpColor = clrBlue;
input     color    TrendLineUptoDownColor = clrRed;
input     color         VerticalLineColor = clrGold;
input     ENUM_LINE_STYLE       LineStyle = STYLE_SOLID;
input     ENUM_ANCHOR_POINT  TextPosition = ANCHOR_RIGHT;
input     int                TextFontSize = 8;
input     string             TextFontName = "Arial Black"; //"Courier" //"Calibri" //"Cambria" //"Bodoni MT Black"
input     int            TopBottomDotSize = 15;
//---
//--
//--- the Main arrays buffers
double ExtCPRBuffer[];
double ExtHPRBuffer[];
double ExtMHPRBuffer[];
double ExtMDPBuffer[];
double ExtMLPRBuffer[];
double ExtLPRBuffer[];
double ExtEMABuffer[];
double ExtEMABuffUp[];
double ExtEMABuffDn[];
double ExtEMABuffWd[];
double ema04[];
double ema24[];
double ema39[];
//---
double cpr0;
double cpr1;
double cph;
double cpl;
//--
double tpb0p1;
double tpt0p1;
double tpb0p2;
double tpt0p2;
//--
datetime fb0p1;
datetime ft0p1;
datetime fb0p2;
datetime ft0p2;
//--
bool barUp;
bool barDn;
//--
//--- offset spacing & corner
int scaleYt=18;
int offsetX=150;
int offsetY=3;
int fontSize=9;
int corner=3;
color arrow;
//--- bars maximum for calculation
int DATA_barcnt;
int bigema=39;
int medema=24;
int smlema=4;
int hilo;
int pos;
int prvup;
int prvdn;
//--
int cal;
int pal;
int cmnt;
int pmnt;
//--
long chart_ID;
string short_name;
string alBase,alSubj,alMsg;
//--- MA handles
int ExtMa04Handle;
//--- Price handle
double open[];
double high[];
double low[];
double close[];
datetime time[];
//--
//---
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffer mapping
   chart_ID=ChartID();
   DATA_barcnt=135;
   hilo=100;
   pos=0;
   short_name="Price(%R,"+string(_Symbol)+","+"TF:"+strTF(_Period)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- set levels - color - levelstyle
   IndicatorSetInteger(INDICATOR_LEVELS,4);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,23.6);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,38.2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,61.8);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,3,76.4);
   //--
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrLightSlateGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrLightSlateGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,clrLightSlateGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,3,clrLightSlateGray);
   //--
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,STYLE_DOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,3,STYLE_DOT);
//--- set maximum and minimum for subwindow
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,100);
   //--
   //---
   SetIndexBuffer(0,ExtEMABuffer,INDICATOR_CALCULATIONS); // Moving Average 39
   SetIndexBuffer(1,ExtCPRBuffer,INDICATOR_DATA);  // Current Price%R value
   SetIndexBuffer(2,ExtHPRBuffer,INDICATOR_CALCULATIONS);  // High Price%R value
   SetIndexBuffer(3,ExtMHPRBuffer,INDICATOR_CALCULATIONS);  // Medium High Price%R value
   SetIndexBuffer(4,ExtMDPBuffer,INDICATOR_CALCULATIONS);  // Medium Price%R value
   SetIndexBuffer(5,ExtMLPRBuffer,INDICATOR_CALCULATIONS);  // Medium Low Price%R value
   SetIndexBuffer(6,ExtLPRBuffer,INDICATOR_CALCULATIONS);  // Low Price%R value
   SetIndexBuffer(7,ExtEMABuffUp,INDICATOR_DATA);  // Moving Average 39 Up
   SetIndexBuffer(8,ExtEMABuffDn,INDICATOR_DATA);  // Moving Average 39 Down
   SetIndexBuffer(9,ExtEMABuffWd,INDICATOR_CALCULATIONS);  // Moving Average 39 Waiting for direction
   SetIndexBuffer(10,ema04,INDICATOR_CALCULATIONS);  // Exponential Moving Average 4
   SetIndexBuffer(11,ema24,INDICATOR_CALCULATIONS);  // Exponential Moving Average 24
   SetIndexBuffer(12,ema39,INDICATOR_CALCULATIONS);  // Exponential Moving Average 39
   SetIndexBuffer(13,open,INDICATOR_CALCULATIONS);  // Open price buffers
   SetIndexBuffer(14,high,INDICATOR_CALCULATIONS);  // High price buffers
   SetIndexBuffer(15,low,INDICATOR_CALCULATIONS);  // Low price buffers
   SetIndexBuffer(16,close,INDICATOR_CALCULATIONS);  // Close price buffers
   //-- indicator drawing shape styles //
   PlotIndexSetInteger(1,PLOT_LINE_COLOR,MoveLinkColor);
   PlotIndexSetInteger(2,PLOT_LINE_COLOR,MoveUpColor);
   PlotIndexSetInteger(3,PLOT_LINE_COLOR,MoveUpColor);
   PlotIndexSetInteger(4,PLOT_LINE_COLOR,WaitDirectionColor);
   PlotIndexSetInteger(5,PLOT_LINE_COLOR,MoveDownColor);
   PlotIndexSetInteger(6,PLOT_LINE_COLOR,MoveDownColor);
   PlotIndexSetInteger(7,PLOT_LINE_COLOR,MoveUpColor);
   PlotIndexSetInteger(8,PLOT_LINE_COLOR,MoveDownColor);
   //--
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,LineWidthSize);
   PlotIndexSetInteger(2,PLOT_LINE_WIDTH,LineWidthSize);
   PlotIndexSetInteger(3,PLOT_LINE_WIDTH,LineWidthSize);
   PlotIndexSetInteger(4,PLOT_LINE_WIDTH,LineWidthSize);
   PlotIndexSetInteger(5,PLOT_LINE_WIDTH,LineWidthSize);
   PlotIndexSetInteger(6,PLOT_LINE_WIDTH,LineWidthSize);
   PlotIndexSetInteger(7,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(8,PLOT_LINE_WIDTH,2);
   //--
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,smlema);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,smlema);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,smlema);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,smlema);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,smlema);
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,smlema);
   PlotIndexSetInteger(7,PLOT_DRAW_BEGIN,smlema);
   PlotIndexSetInteger(8,PLOT_DRAW_BEGIN,smlema);
   //--
   PlotIndexSetString(0,PLOT_LABEL,NULL);
   PlotIndexSetString(1,PLOT_LABEL,"Price(%)R");
   PlotIndexSetString(2,PLOT_LABEL,NULL);
   PlotIndexSetString(3,PLOT_LABEL,NULL);
   PlotIndexSetString(4,PLOT_LABEL,NULL);
   PlotIndexSetString(5,PLOT_LABEL,NULL);
   PlotIndexSetString(6,PLOT_LABEL,NULL);
   PlotIndexSetString(7,PLOT_LABEL,"(%R)Ups");
   PlotIndexSetString(8,PLOT_LABEL,"(%R)Down");
   PlotIndexSetString(9,PLOT_LABEL,NULL);
   PlotIndexSetString(10,PLOT_LABEL,NULL);
   PlotIndexSetString(11,PLOT_LABEL,NULL);
   PlotIndexSetString(12,PLOT_LABEL,NULL);
   PlotIndexSetString(13,PLOT_LABEL,NULL);
   PlotIndexSetString(14,PLOT_LABEL,NULL);
   PlotIndexSetString(15,PLOT_LABEL,NULL);
   PlotIndexSetString(16,PLOT_LABEL,NULL);
   //--
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
   //--
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   //--
//---
   //--
   ArraySetAsSeries(ExtCPRBuffer,true);
   ArraySetAsSeries(ExtHPRBuffer,true);
   ArraySetAsSeries(ExtMHPRBuffer,true);
   ArraySetAsSeries(ExtMDPBuffer,true);
   ArraySetAsSeries(ExtMLPRBuffer,true);
   ArraySetAsSeries(ExtLPRBuffer,true);
   ArraySetAsSeries(ExtEMABuffer,true);
   ArraySetAsSeries(ExtEMABuffUp,true);
   ArraySetAsSeries(ExtEMABuffDn,true);
   ArraySetAsSeries(ExtEMABuffWd,true);
   ArraySetAsSeries(ema04,true);
   ArraySetAsSeries(ema24,true);
   ArraySetAsSeries(ema39,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);
   //--
//--- get MAs handles
   ExtMa04Handle=iMA(_Symbol,PERIOD_CURRENT,smlema,0,MODE_EMA,PRICE_TYPICAL);
   if(ExtMa04Handle==INVALID_HANDLE)
     {
       printf("Error creating EMA indicator for ",_Symbol);
       return(INIT_FAILED);
     }
   //--
//--- initialization done
//---
   return(INIT_SUCCEEDED);
  }
//-----//  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//----
   ObjectsDeleteAll(chart_ID,0,-1);
   GlobalVariablesDeleteAll();
//----
   return;
  }
//-----//
//+------------------------------------------------------------------+
//|  searching index of the highest bar                              |
//+------------------------------------------------------------------+
int iHighest(const double &array[],
             int timeframe,
             int depth,
             int startPos)
  {
   int index=startPos;
//--- start index validation
   if(startPos<0)
     {
      Print("Invalid parameter in the function iHighest, startPos =",startPos);
      return 0;
     }
   int size=ArraySize(array);
//---
   double max=array[startPos];
//--- start searching
   for(int i=depth; i>startPos; i--)
     {
      if(array[i]>max)
        {
         index=i;
         max=array[i];
        }
     }
//--- return index of the highest bar
   return(index);
  }
//-----//  
//+------------------------------------------------------------------+
//|  searching index of the lowest bar                               |
//+------------------------------------------------------------------+
int iLowest(const double &array[],
            int timeframe,
            int depth,
            int startPos)
  {
   int index=startPos;
//--- start index validation
   if(startPos<0)
     {
      Print("Invalid parameter in the function iLowest, startPos =",startPos);
      return 0;
     }
   int size=ArraySize(array);
//---
   double min=array[startPos];
//--- start searching
   for(int i=depth; i>startPos; i--)
     {
      if(array[i]<min)
        {
         index=i;
         min=array[i];
        }
     }
//--- return index of the lowest bar
   return(index);
  }
//-----//
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {  
//----
   //---
   ResetLastError();
   int bar;
   //--
   if(rates_total<DATA_barcnt)
      return(0);
//--- last counted bar will be recounted
   bar=rates_total;
   if(prev_calculated==0) bar=DATA_barcnt;
   if(prev_calculated>0) bar++;
   //--
   cal=0;
   int z;
   int i=0;
   int x=1;
   int ft0=-1;
   int fb0=-1;
   int scan=7;
   int stbar=0;
   int xbars=26;
   int xhilo=26;
   int tunebar=5;
   int tunstep=12;
   int xlimit=100;
   //--
   cph=0.0;
   cpl=0.0;
   double tpt0=0.0;
   double tpb0=0.0;
   double tpttest=0.0;
   double tpbtest=0.0;
   //--
   ArrayResize(ExtCPRBuffer,bar);
   ArrayResize(ExtHPRBuffer,bar);
   ArrayResize(ExtMHPRBuffer,bar);
   ArrayResize(ExtMDPBuffer,bar);
   ArrayResize(ExtMLPRBuffer,bar);
   ArrayResize(ExtLPRBuffer,bar);
   ArrayResize(ExtEMABuffer,bar);
   ArrayResize(ExtEMABuffUp,bar);
   ArrayResize(ExtEMABuffDn,bar);
   ArrayResize(ExtEMABuffWd,bar);
   ArrayResize(ema04,bar);
   ArrayResize(ema24,bar);
   ArrayResize(ema39,bar);
   ArrayResize(open,bar);
   ArrayResize(high,bar);
   ArrayResize(low,bar);
   ArrayResize(close,bar);
   ArrayResize(time,bar);
   //--
   //---
//---
   int calculated=BarsCalculated(ExtMa04Handle);
   //--- check if all data calculated
   if(BarsCalculated(ExtMa04Handle)<rates_total)
     {
       Print("Not all data of EMA 4 is calculated (",calculated,"bars ). Error",GetLastError());
       return(0);
     }
   //--
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0)
     {
       to_copy=rates_total;
     }
   else
     {
       to_copy=rates_total-prev_calculated;
       if(prev_calculated>0) to_copy++;
     }
   //--
//--- get EMA 4 buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtMa04Handle,0,0,to_copy,ema04)<=0)
     {
       Print("Getting EMA 4 buffers is failed! Error:",GetLastError());
       return(0);
     }
   //--
   int copyOpen=CopyOpen(_Symbol,PERIOD_CURRENT,0,calculated,open);
   int copyHigh=CopyHigh(_Symbol,PERIOD_CURRENT,0,calculated,high);
   int copyLow=CopyLow(_Symbol,PERIOD_CURRENT,0,calculated,low);
   int copyClose=CopyClose(_Symbol,PERIOD_CURRENT,0,calculated,close);
   int copyTime=CopyTime(_Symbol,PERIOD_CURRENT,0,calculated,time);
   //--
//---
//--- get EMA 24 buffers
   ExponentialMAOnBuffer(rates_total,prev_calculated,0,medema,ema04,ema24);
//--- get EMA 39 buffers
   ExponentialMAOnBuffer(rates_total,prev_calculated,0,bigema,ema24,ema39);
   //--
   int inH=iHighest(high,PERIOD_CURRENT,hilo,pos);
   int inL=iLowest(low,PERIOD_CURRENT,hilo,pos);
   if(inH!=-1) cph=high[inH];
   if(inL!=-1) cpl=low[inL];
   //--
//---
   //--
   double ma24d[],ma04d[];
   ArrayResize(ma24d,calculated);
   ArrayResize(ma04d,calculated);
   ArraySetAsSeries(ma24d,true);
   ArraySetAsSeries(ma04d,true);
   //---
   if(!IsStopped())
     {
     for(z=0; z<tunstep && xhilo<xlimit; z++)
       {
         //--
         ft0=iHighest(high,PERIOD_CURRENT,xhilo,stbar);
         fb0=iLowest(low,PERIOD_CURRENT,xhilo,stbar);
         if(ft0!=-1) tpttest=high[ft0];
         if(fb0!=-1) tpbtest=low[fb0];
         //--
         if((tpttest>=high[iHighest(high,PERIOD_CURRENT,scan,ft0+1)])&&(tpbtest<=low[iLowest(low,PERIOD_CURRENT,scan,fb0+1)]))
           {
             tpt0=high[ft0];
             tpb0=low[fb0];
             break;
           }
         else {xhilo=xbars+(tunebar*z);}
         //--
       }
     }
   //--
   //--
   if(ft0<fb0)
     {
       //--
       barDn=true;
       barUp=false;
       fb0p1=time[fb0];
       tpb0p1=tpb0;
       ft0p1=time[ft0];
       tpt0p1=tpt0;
       prvdn=1;
       //--
       string objnameDn10_=short_name+": VerticalLineSwingBarsUp1_";
       string objnameDn20_=short_name+": VerticalLineSwingBarsUp2_";
       string objname10=short_name+": TrendSwingBarsUp";
       string objname20=short_name+": SwingBarsPosTop0";
       string objname30=short_name+": SwingBarsPosBottom0";
       //--
       ObjectDelete(chart_ID,objname10);
       ObjectDelete(chart_ID,objname20);
       ObjectDelete(chart_ID,objname30);
       ObjectDelete(chart_ID,objnameDn10_);
       ObjectDelete(chart_ID,objnameDn20_);
       //---
       CreateObjectVLine(chart_ID,
                         objnameDn10_,
                         time[fb0],
                         VerticalLineColor,
                         LineStyle,
                         LineWidthSize,
                         true);
       //---
       CreateObjectVLine(chart_ID,
                         objnameDn20_,
                         time[ft0],
                         VerticalLineColor,
                         LineStyle,
                         LineWidthSize,
                         true);
       //---
       CreateObjectTrend(chart_ID,
                         objname10,
                         time[fb0],
                         tpb0,
                         time[ft0],
                         tpt0,
                         TrendLineDowntoUpColor,
                         LineStyle,
                         LineWidthSize,
                         false,
                         true);
       //---
       CreateObjectText(chart_ID,
                        objname20,
                        time[ft0],
                        tpt0,
                        CharToString(119),
                        "Wingdings",
                        TopBottomDotSize,
                        TrendLineUptoDownColor,
                        ANCHOR_CENTER,
                        true);
       //---
       CreateObjectText(chart_ID,
                        objname30,
                        time[fb0],
                        tpb0,
                        CharToString(119),
                        "Wingdings",
                        TopBottomDotSize,
                        TrendLineDowntoUpColor,
                        ANCHOR_CENTER,
                        true);
       //---
       //---
       if((barDn)&&(prvup==1))
         {
           prvup=0;
           //--
           string objnameUp10p=short_name+": VerticalLineSwingBarsDn1-"+string(TimeToString(fb0p2,TIME_DATE|TIME_MINUTES));
           string objnameUp20p=short_name+": VerticalLineSwingBarsDn2-"+string(TimeToString(ft0p2,TIME_DATE|TIME_MINUTES));
           string objname10p=short_name+": TrendSwingBarsDown2"+string(TimeToString(ft0p2,TIME_DATE|TIME_MINUTES));
           string objname20p=short_name+": SwingBarsPosTop0p"+string(TimeToString(ft0p2,TIME_DATE|TIME_MINUTES));
           string objname30p=short_name+": SwingBarsPosBottom0p"+string(TimeToString(fb0p2,TIME_DATE|TIME_MINUTES));
           //--
           CreateObjectVLine(chart_ID,
                             objnameUp10p,
                             fb0p2,
                             VerticalLineColor,
                             LineStyle,
                             LineWidthSize,
                             true);
           //--
           CreateObjectVLine(chart_ID,
                             objnameUp20p,
                             ft0p2,
                             VerticalLineColor,
                             LineStyle,
                             LineWidthSize,
                             true);
           //--
           CreateObjectTrend(chart_ID,
                             objname10p,
                             ft0p2,
                             tpt0p2,
                             fb0p2,
                             tpb0p2,
                             TrendLineUptoDownColor,
                             LineStyle,
                             LineWidthSize,
                             false,
                             true);
           //--
           CreateObjectText(chart_ID,
                            objname20p,
                            ft0p2,
                            tpt0p2,
                            CharToString(119),
                            "Wingdings",
                            TopBottomDotSize,
                            TrendLineUptoDownColor,
                            ANCHOR_CENTER,
                            true);
           //--
           CreateObjectText(chart_ID,
                            objname30p,
                            fb0p2,
                            tpb0p2,
                            CharToString(119),
                            "Wingdings",
                            TopBottomDotSize,
                            TrendLineDowntoUpColor,
                            ANCHOR_CENTER,
                            true);
           //--
         }
     //---
     }
   //---
   //---
   if(ft0>fb0)
     {
       //--
       barUp=true;
       barDn=false;
       fb0p2=time[fb0];
       tpb0p2=tpb0;
       ft0p2=time[ft0];
       tpt0p2=tpt0;
       prvup=1;
       //--
       string objnameUp10_=short_name+": VerticalLineSwingBarsDn1_";
       string objnameUp20_=short_name+": VerticalLineSwingBarsDn2_";
       string objname11=short_name+": TrendSwingBarsDown";
       string objname21=short_name+": SwingBarsPosTop1";
       string objname31=short_name+": SwingBarsPosBottom1";
       //--
       ObjectDelete(chart_ID,objname11);
       ObjectDelete(chart_ID,objname21);
       ObjectDelete(chart_ID,objname31);
       ObjectDelete(chart_ID,objnameUp10_);
       ObjectDelete(chart_ID,objnameUp20_);
       //---
       CreateObjectVLine(chart_ID,
                         objnameUp10_,
                         time[ft0],
                         VerticalLineColor,
                         LineStyle,
                         LineWidthSize,
                         true);
       //---
       CreateObjectVLine(chart_ID,
                         objnameUp20_,
                         time[fb0],
                         VerticalLineColor,
                         LineStyle,
                         LineWidthSize,
                         true);
       //---
       CreateObjectTrend(chart_ID,
                         objname11,
                         time[ft0],
                         tpt0,
                         time[fb0],
                         tpb0,
                         TrendLineUptoDownColor,
                         LineStyle,
                         LineWidthSize,
                         false,
                         true);
       //---
       CreateObjectText(chart_ID,
                        objname21,
                        time[ft0],
                        tpt0,
                        CharToString(119),
                        "Wingdings",
                        TopBottomDotSize,
                        TrendLineUptoDownColor,
                        ANCHOR_CENTER,
                        true);
       //---
       CreateObjectText(chart_ID,
                        objname31,
                        time[fb0],
                        tpb0,
                        CharToString(119),
                        "Wingdings",
                        TopBottomDotSize,
                        TrendLineDowntoUpColor,
                        ANCHOR_CENTER,
                        true);
       //---
       //---
       if((barUp)&&(prvdn==1))
         {
           //--
           prvdn=0;
           //--
           string objnameDn1p=short_name+": VerticalLineSwingBarsUp1-"+string(TimeToString(fb0p1,TIME_DATE|TIME_MINUTES));
           string objnameDn2p=short_name+": VerticalLineSwingBarsUp2-"+string(TimeToString(ft0p1,TIME_DATE|TIME_MINUTES));
           string objname11p=short_name+": TrendSwingBarsUp1"+string(TimeToString(fb0p1,TIME_DATE|TIME_MINUTES));
           string objname21p=short_name+": SwingBarsPosTop1p"+string(TimeToString(ft0p1,TIME_DATE|TIME_MINUTES));
           string objname31p=short_name+": SwingBarsPosBottom1p"+string(TimeToString(fb0p1,TIME_DATE|TIME_MINUTES));
           //--
           CreateObjectVLine(chart_ID,
                             objnameDn1p,
                             fb0p1,
                             VerticalLineColor,
                             LineStyle,
                             LineWidthSize,
                             true);
           //--
           CreateObjectVLine(chart_ID,
                             objnameDn2p,
                             ft0p1,
                             VerticalLineColor,
                             LineStyle,
                             LineWidthSize,
                             true);
           //--
           CreateObjectTrend(chart_ID,
                             objname11p,
                             fb0p1,
                             tpb0p1,
                             ft0p1,
                             tpt0p1,
                             TrendLineDowntoUpColor,
                             LineStyle,
                             LineWidthSize,
                             false,
                             true);
           //--
           CreateObjectText(chart_ID,
                            objname21p,
                            ft0p1,
                            tpt0p1,
                            CharToString(119),
                            "Wingdings",
                            TopBottomDotSize,
                            TrendLineUptoDownColor,
                            ANCHOR_CENTER,
                            true);
           //--
           CreateObjectText(chart_ID,
                            objname31p,
                            fb0p1,
                            tpb0p1,
                            CharToString(119),
                            "Wingdings",
                            TopBottomDotSize,
                            TrendLineDowntoUpColor,
                            ANCHOR_CENTER,
                            true);
           //--
         }
     //---
     }
   //---
//----
   for(i=calculated-2; i>=pos && !IsStopped(); i--)
     {
       //---
       switch(AppliedPrice)
         {
           case PRICE_CLOSE:
               cpr0=close[i];
               cpr1=close[i+1];
               break;
           case PRICE_OPEN:
               cpr0=open[i];
               cpr1=open[i+1];
               break;
           case PRICE_HIGH:  
               cpr0=high[i];
               cpr1=high[i+1];
               break;
           case PRICE_LOW:
               cpr0=low[i];
               cpr1=low[i+1];
               break;
           case PRICE_MEDIAN:
               cpr0=(high[i]+low[i])/2;
               cpr1=(high[i+1]+low[i+1])/2;
               break;
           case PRICE_TYPICAL:
               cpr0=(high[i]+low[i]+close[i])/3;
               cpr1=(high[i+1]+low[i+1]+close[i+1])/3;
               break;
           case PRICE_WEIGHTED:
               cpr0=(high[i]+low[i]+close[i]+close[i])/4;
               cpr1=(high[i+1]+low[i+1]+close[i+1]+close[i+1])/4;
               break;
         }
       //---
       ExtCPRBuffer[i]=((cpr0-cpl)/(cph-cpl))*100;
       ExtEMABuffer[i]=((ema39[i]-cpl)/(cph-cpl))*100;
       ma24d[i]=((ema24[i]-cpl)/(cph-cpl))*100;
       ma04d[i]=((ema04[i]-cpl)/(cph-cpl))*100;
       //--
       if(ma24d[i]>ExtEMABuffer[i])
         {
           ExtEMABuffUp[i]=ExtEMABuffer[i];
           ExtEMABuffDn[i]=EMPTY_VALUE;
           ExtEMABuffWd[i]=EMPTY_VALUE;
           arrow=MoveUpColor;
         }
       if(ma24d[i]<ExtEMABuffer[i])
         {
           ExtEMABuffDn[i]=ExtEMABuffer[i];
           ExtEMABuffUp[i]=EMPTY_VALUE;
           ExtEMABuffWd[i]=EMPTY_VALUE;
           arrow=MoveDownColor;
         }
       if((ma24d[i]>ExtEMABuffer[i])&&(ma04d[i]>ma04d[i+1]))
         {
           ExtEMABuffUp[i]=ExtEMABuffer[i];
           ExtEMABuffDn[i]=EMPTY_VALUE;
           ExtEMABuffWd[i]=EMPTY_VALUE;
           arrow=MoveUpColor;
         }
       if((ma24d[i]<ExtEMABuffer[i])&&(ma04d[i]<ma04d[i+1]))
         {
           ExtEMABuffDn[i]=ExtEMABuffer[i];
           ExtEMABuffUp[i]=EMPTY_VALUE;
           ExtEMABuffWd[i]=EMPTY_VALUE;
           arrow=MoveDownColor;
         }
       //--
       if((ma24d[i]>=ExtEMABuffer[i])&&(ExtCPRBuffer[i]>ExtEMABuffer[i]))
         {
           ExtEMABuffUp[i]=ExtEMABuffer[i];
           ExtEMABuffDn[i]=EMPTY_VALUE;
           ExtEMABuffWd[i]=ExtEMABuffer[i];
           arrow=WaitDirectionColor;
         }
       if((ma24d[i]<=ExtEMABuffer[i])&&(ExtCPRBuffer[i]<ExtEMABuffer[i]))
         {
           ExtEMABuffDn[i]=ExtEMABuffer[i];
           ExtEMABuffUp[i]=EMPTY_VALUE;
           ExtEMABuffWd[i]=ExtEMABuffer[i];
           arrow=WaitDirectionColor;
         }
       //---
       //--
       if((ExtCPRBuffer[i]>=76.4)&&(ExtCPRBuffer[i]<100.0))
         {
           ExtHPRBuffer[i]=ExtCPRBuffer[i];
           ExtMHPRBuffer[i]=EMPTY_VALUE;
           ExtMDPBuffer[i]=EMPTY_VALUE;
           ExtMLPRBuffer[i]=EMPTY_VALUE;
           ExtLPRBuffer[i]=EMPTY_VALUE;
         }
       else if((ExtCPRBuffer[i]>=61.8)&&(ExtCPRBuffer[i]<76.4))
         {
           ExtHPRBuffer[i]=EMPTY_VALUE;
           ExtMHPRBuffer[i]=ExtCPRBuffer[i];
           ExtMDPBuffer[i]=EMPTY_VALUE;
           ExtMLPRBuffer[i]=EMPTY_VALUE;
           ExtLPRBuffer[i]=EMPTY_VALUE;
         }
       else if((ExtCPRBuffer[i]>=38.2)&&(ExtCPRBuffer[i]<61.8))
         {
           ExtHPRBuffer[i]=EMPTY_VALUE;
           ExtMHPRBuffer[i]=EMPTY_VALUE;
           ExtMDPBuffer[i]=ExtCPRBuffer[i];
           ExtMLPRBuffer[i]=EMPTY_VALUE;
           ExtLPRBuffer[i]=EMPTY_VALUE;
         }
       else if((ExtCPRBuffer[i]>=23.6)&&(ExtCPRBuffer[i]<38.2))
         {
           ExtHPRBuffer[i]=EMPTY_VALUE;
           ExtMHPRBuffer[i]=EMPTY_VALUE;
           ExtMDPBuffer[i]=EMPTY_VALUE;
           ExtMLPRBuffer[i]=ExtCPRBuffer[i];
           ExtLPRBuffer[i]=EMPTY_VALUE;
         }
       else if((ExtCPRBuffer[i]>=0.0)&&(ExtCPRBuffer[i]<23.6))
         {
           ExtHPRBuffer[i]=EMPTY_VALUE;
           ExtMHPRBuffer[i]=EMPTY_VALUE;
           ExtMDPBuffer[i]=EMPTY_VALUE;
           ExtMLPRBuffer[i]=EMPTY_VALUE;
           ExtLPRBuffer[i]=ExtCPRBuffer[i];
         }
       //--
       //---
       if(i==0)
         {
           //---
           if(ExtCPRBuffer[i]>ExtCPRBuffer[i+1])
             {
               //--
               string name1="txCons"+string(x);
               string name2="txCons"+string(x)+"a";
               string name3="txCons"+string(x)+"a"+"1";
               //--
               ObjectDelete(chart_ID,name1);
               ObjectDelete(chart_ID,name2);
               ObjectDelete(chart_ID,name3);
               //--
               CreateObjectLable(chart_ID,name1,"Wingdings",CharToString(164),27,RoundedColor,corner,offsetX-6,scaleYt+offsetY+29,true);
               //--
               CreateObjectLable(chart_ID,name2,"Wingdings",CharToString(217),20,arrow,corner,offsetX-10,scaleYt+offsetY+15,true);
               //--
               if(cpr0>cpr1)
                 {
                   CreateObjectLable(chart_ID,name3,"Bodoni MT Black","UP",7,TextColor,corner,offsetX-15,scaleYt+offsetY+62,true);
                 }
               //--
               else
                 {
                   CreateObjectLable(chart_ID,name3,"Bodoni MT Black","WAIT",7,TextColor,corner,offsetX-7,scaleYt+offsetY+62,true);
                 }
             }
           //---
           else if(ExtCPRBuffer[i]<ExtCPRBuffer[i+1])
             {
               //--
               string name1="txCons"+string(x);
               string name2="txCons"+string(x)+"a";
               string name3="txCons"+string(x)+"a"+"1";
               //--
               ObjectDelete(chart_ID,name1);
               ObjectDelete(chart_ID,name2);
               ObjectDelete(chart_ID,name3);
               //--
               CreateObjectLable(chart_ID,name1,"Wingdings",CharToString(164),27,RoundedColor,corner,offsetX-6,scaleYt+offsetY+29,true);
               //--
               CreateObjectLable(chart_ID,name2,"Wingdings",CharToString(218),20,arrow,corner,offsetX-10,3*scaleYt+offsetY+16,true);
               //--
               if(cpr0<cpr1)
                 {
                   CreateObjectLable(chart_ID,name3,"Bodoni MT Black","DOWN",7,TextColor,corner,offsetX-6,scaleYt+offsetY+21,true);
                 }
               //--
               else
                 {
                   CreateObjectLable(chart_ID,name3,"Bodoni MT Black","WAIT",7,TextColor,corner,offsetX-8,scaleYt+offsetY+21,true);
                 }
             }
           //---
           if((ma04d[i+1]<=ExtEMABuffer[i+1])&&(ma04d[i]>ExtEMABuffer[i])&&(cpr0>cpr1)&&(ExtEMABuffUp[i]!=EMPTY_VALUE)) {cal=391;}
           if((ma04d[i+1]>=ExtEMABuffer[i+1])&&(ma04d[i]<ExtEMABuffer[i])&&(cpr0<cpr1)&&(ExtEMABuffDn[i]!=EMPTY_VALUE)) {cal=390;}
           if((ma04d[i]>ExtEMABuffer[i])&&(ExtCPRBuffer[i]<80.0)&&(cpr0>cpr1)&&(ma04d[i]>ma04d[i+1])&&(ExtEMABuffUp[i]!=EMPTY_VALUE)) {cal=393;}
           if((ma04d[i]<ExtEMABuffer[i])&&(ExtCPRBuffer[i]>20.0)&&(cpr0<cpr1)&&(ma04d[i]<ma04d[i+1])&&(ExtEMABuffDn[i]!=EMPTY_VALUE)) {cal=392;}
           if((ExtCPRBuffer[i+1]<23.6)&&(ExtCPRBuffer[i]>23.6)&&(ExtEMABuffer[i]>38.2)&&(cpr0>cpr1)) {cal=395;}
           if((ExtCPRBuffer[i+1]>76.4)&&(ExtCPRBuffer[i]<76.4)&&(ExtEMABuffer[i]<61.8)&&(cpr0<cpr1)) {cal=394;}
           if((ExtCPRBuffer[i]<23.6)&&(inL<inH)&&(ExtEMABuffer[i]>61.8)&&(ma04d[i]>ma04d[i+1])&&(cpr0>cpr1)) {cal=397;}
           if((ExtCPRBuffer[i]>76.4)&&(inH<inL)&&(ExtEMABuffer[i]<38.2)&&(ma04d[i]<ma04d[i+1])&&(cpr0<cpr1)) {cal=396;}
           //---
         }
       //---
     }
  //---
  ChartRedraw(chart_ID);
  p_alerts(cal);
  //---
//--- done!
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//---------//

void CreateObjectVLine(long     chart_id, 
                       string   vline_name, 
                       datetime vline_time,
                       color    vline_color,
                       int      vline_style,
                       int      vline_width,
                       bool     vline_hidden)
  { 
//---
    if(ObjectCreate(chart_id,vline_name,OBJ_VLINE,0,vline_time,0))
      { 
        ObjectSetInteger(chart_id,vline_name,OBJPROP_COLOR,vline_color);
        ObjectSetInteger(chart_id,vline_name,OBJPROP_STYLE,vline_style);
        ObjectSetInteger(chart_id,vline_name,OBJPROP_WIDTH,vline_width);
        ObjectSetInteger(chart_id,vline_name,OBJPROP_HIDDEN,vline_hidden);
      } 
    else 
      {Print("Failed to create the object OBJ_VLINE ",vline_name,", Error code = ", GetLastError());}
  }
//---------//

void CreateObjectTrend(long     chart_id, 
                       string   trend_name, 
                       datetime trend_time1,
                       double   trend_price1,
                       datetime trend_time2,
                       double   trend_price2,
                       color    trend_color,
                       int      trend_style,
                       int      trend_width,
                       bool     trend_ray_r,
                       bool     trend_hidden)
  { 
//---
    if(ObjectCreate(chart_id,trend_name,OBJ_TREND,0,trend_time1,trend_price1,trend_time2,trend_price2))
      { 
        ObjectSetInteger(chart_id,trend_name,OBJPROP_COLOR,trend_color);
        ObjectSetInteger(chart_id,trend_name,OBJPROP_STYLE,trend_style);
        ObjectSetInteger(chart_id,trend_name,OBJPROP_WIDTH,trend_width);
        ObjectSetInteger(chart_id,trend_name,OBJPROP_RAY_RIGHT,trend_ray_r);
        ObjectSetInteger(chart_id,trend_name,OBJPROP_HIDDEN,trend_hidden);
      } 
    else 
      {Print("Failed to create the object OBJ_TREND ",trend_name,", Error code = ", GetLastError());}
  }
//---------//

void CreateObjectText(long     chart_id, 
                      string   text_name, 
                      datetime text_time1,
                      double   text_price1,
                      string   text_obj_text,
                      string   text_font_model,
                      int      text_font_size,
                      color    text_color,
                      int      text_anchor,
                      bool     text_hidden)
  { 
//---
    if(ObjectCreate(chart_ID,text_name,OBJ_TEXT,0,text_time1,text_price1))
      { 
        ObjectSetString(chart_id,text_name,OBJPROP_TEXT,text_obj_text);
        ObjectSetString(chart_id,text_name,OBJPROP_FONT,text_font_model);
        ObjectSetInteger(chart_id,text_name,OBJPROP_FONTSIZE,text_font_size);
        ObjectSetInteger(chart_id,text_name,OBJPROP_COLOR,text_color);
        ObjectSetInteger(chart_id,text_name,OBJPROP_ANCHOR,text_anchor);
        ObjectSetInteger(chart_id,text_name,OBJPROP_HIDDEN,text_hidden);
      } 
    else 
      {Print("Failed to create the object OBJ_TEXT ",text_name,", Error code = ", GetLastError());}
  }
//---------//

void CreateObjectLable(long     chart_id, 
                       string   lable_name, 
                       string   lable_font_model,
                       string   lable_obj_text,
                       int      lable_font_size,
                       color    lable_color,
                       int      lable_corner,
                       int      lable_xdist,
                       int      lable_ydist,
                       bool     lable_hidden)
  { 
//---
    if(ObjectCreate(chart_id,lable_name,OBJ_LABEL,1,0,0))
      { 
        ObjectSetString(chart_id,lable_name,OBJPROP_FONT,lable_font_model);
        ObjectSetString(chart_id,lable_name,OBJPROP_TEXT,lable_obj_text);
        ObjectSetInteger(chart_id,lable_name,OBJPROP_FONTSIZE,lable_font_size);
        ObjectSetInteger(chart_id,lable_name,OBJPROP_COLOR,lable_color);
        ObjectSetInteger(chart_id,lable_name,OBJPROP_CORNER,lable_corner);
        ObjectSetInteger(chart_id,lable_name,OBJPROP_XDISTANCE,lable_xdist);
        ObjectSetInteger(chart_id,lable_name,OBJPROP_YDISTANCE,lable_ydist);
        ObjectSetInteger(chart_id,lable_name,OBJPROP_HIDDEN,lable_hidden);
      } 
    else 
      {Print("Failed to create the object OBJ_LABEL ",lable_name,", Error code = ", GetLastError());}
  }
//---------//

enum TimeReturn
  {
    year        = 0,   // Year 
    mon         = 1,   // Month 
    day         = 2,   // Day 
    hour        = 3,   // Hour 
    min         = 4,   // Minutes 
    sec         = 5,   // Seconds 
    day_of_week = 6,   // Day of week (0-Sunday, 1-Monday, ... ,6-Saturday) 
    day_of_year = 7    // Day number of the year (January 1st is assigned the number value of zero) 
  };
//---------//

int MqlReturnDateTime(datetime reqtime,
                      const int mode) 
  {
    MqlDateTime mqltm;
    TimeToStruct(reqtime,mqltm);
    int valdate=0;
    //--
    switch(mode)
      {
        case 0: valdate=mqltm.year; break;        // Return Year 
        case 1: valdate=mqltm.mon;  break;        // Return Month 
        case 2: valdate=mqltm.day;  break;        // Return Day 
        case 3: valdate=mqltm.hour; break;        // Return Hour 
        case 4: valdate=mqltm.min;  break;        // Return Minutes 
        case 5: valdate=mqltm.sec;  break;        // Return Seconds 
        case 6: valdate=mqltm.day_of_week; break; // Return Day of week (0-Sunday, 1-Monday, ... ,6-Saturday) 
        case 7: valdate=mqltm.day_of_year; break; // Return Day number of the year (January 1st is assigned the number value of zero) 
      }
    return(valdate);
  }
//---------//

void Do_Alerts(string msgText,string eMailSub)
  {
    //--
    if(MsgAlerts) Alert(msgText);
    if(SoundAlerts) PlaySound(SoundAlertFile);
    if(eMailAlerts) SendMail(eMailSub,msgText);
    //--
  }
//---------//

//---/
string strTF(ENUM_TIMEFRAMES tf)
  {
     switch(tf)
       {
         case PERIOD_M1: return "M1";
         case PERIOD_M5: return "M5";
         case PERIOD_M15: return "M15";
         case PERIOD_M30: return "M30";
         case PERIOD_H1: return "H1";
         case PERIOD_H4: return "H4";
         case PERIOD_D1: return "D1";
         case PERIOD_W1: return "W1";
         case PERIOD_MN1: return "MN1";
       }
     return "Unknown TF";
    //--
  }
//---------//

void p_alerts(int alert)
   {
     //--
     cmnt=MqlReturnDateTime(TimeCurrent(),TimeReturn(min));
     if(cmnt!=pmnt)
       {
         //---
         //--
         if((cal!=pal)&&(alert==391))
            {    
              alBase=short_name+" @ "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
              alSubj=alBase+". The Price Goes Up,";
              alMsg=alSubj+" Action: Open BUY.!!";
              pmnt=cmnt;
              pal=cal;
              Do_Alerts(alMsg,alSubj);
            }
         //--
         if((cal!=pal)&&(alert==390))
            {    
              alBase=short_name+" @ "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
              alSubj=alBase+". The Price Goes Down,";
              alMsg=alSubj+" Action: Open SELL.!!";
              pmnt=cmnt;
              pal=cal;
              Do_Alerts(alMsg,alSubj);
            }
         //--
         if((cal!=pal)&&(alert==393))
            {    
              alBase=short_name+" @ "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
              alSubj=alBase+". The Price Goes Up,";
              alMsg=alSubj+" Action: Open BUY.!!";
              pmnt=cmnt;
              pal=cal;
              Do_Alerts(alMsg,alSubj);
            }
         //--
         if((cal!=pal)&&(alert==392))
            {    
              alBase=short_name+" @ "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
              alSubj=alBase+". The Price Goes Down,";
              alMsg=alSubj+" Action: Open SELL.!!";
              pmnt=cmnt;
              pal=cal;
              Do_Alerts(alMsg,alSubj);
            }
         //--
         if((cal!=pal)&&(alert==395))
            {    
              alBase=short_name+" @ "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
              alSubj=alBase+". The Price Goes Up,";
              alMsg=alSubj+" Action: Open BUY.!!";
              pmnt=cmnt;
              pal=cal;
              Do_Alerts(alMsg,alSubj);
            }
         //--
         if((cal!=pal)&&(alert==394))
            {    
              alBase=short_name+" @ "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
              alSubj=alBase+". The Price Goes Down,";
              alMsg=alSubj+" Action: Open SELL.!!";
              pmnt=cmnt;
              pal=cal;
              Do_Alerts(alMsg,alSubj);
            }
         //--
         if((cal!=pal)&&(alert==397))
            {    
              alBase=short_name+" @ "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
              alSubj=alBase+". The Price Goes Up,";
              alMsg=alSubj+" Action: Open BUY.!!";
              pmnt=cmnt;
              pal=cal;
              Do_Alerts(alMsg,alSubj);
            }
         //--
         if((cal!=pal)&&(alert==396))
            {    
              alBase=short_name+" @ "+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
              alSubj=alBase+". The Price Goes Down,";
              alMsg=alSubj+" Action: Open SELL.!!";
              pmnt=cmnt;
              pal=cal;
              Do_Alerts(alMsg,alSubj);
            }
         //--
         //---
       }
     //--
     return;
     //--
   //----
   } //-end p_alerts()
//---------//
//+------------------------------------------------------------------+