//+------------------------------------------------------------------+
//|                                            MultiCandleSignal.mq5 | 
//|                             Copyright © 2013,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2013, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description ""
//--- indicator version
#property version   "1.10"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- fixed height of the indicator subwindow in pixels 
#property indicator_height 90
//--- lower and upper scale limit of a separate indicator window
#property indicator_maximum +7.9
#property indicator_minimum +0.3
//+-----------------------------------+
//| Declaration of constants          |
//+-----------------------------------+
#define RESET 0          // A constant for returning the indicator recalculation command to the terminal
#define INDTOTAL 7       // A constant for the number of displayed indicator
//+-----------------------------------+
//--- number of indicator buffers
#property indicator_buffers 28 // INDTOTAL*4
//--- total plots used
#property indicator_plots   21 // INDTOTAL*3
//+-----------------------------------+
//| Indicator 1 drawing parameters    |
//+-----------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_COLOR_LINE
//--- the following colors are used for the indicator line
#property indicator_color1 clrGray,clrMagenta,clrGreen
//--- the indicator line is dashed
#property indicator_style1  STYLE_SOLID
//--- indicator line width is 3
#property indicator_width1  3
//--- displaying the indicator label
#property indicator_label1  "Signal line 1"
//+-----------------------------------+
//| Indicator 1 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 1 as a label
#property indicator_type2   DRAW_ARROW
//--- the color used as a label color
#property indicator_color2 clrLime
//--- indicator line width is 3
#property indicator_width2  3
//--- displaying the indicator label
#property indicator_label2  "Up Candle 1"
//+-----------------------------------+
//| Indicator 1 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 1 as a label
#property indicator_type3   DRAW_ARROW
//--- the color used as a label color
#property indicator_color3 clrRed
//--- indicator line width is 3
#property indicator_width3  3
//--- displaying the indicator label
#property indicator_label3  "Down Candle 1"
//+-----------------------------------+
//| Indicator 2 drawing parameters    |
//+-----------------------------------+
//--- drawing indicator 2 as a line
#property indicator_type4   DRAW_COLOR_LINE
//--- the following colors are used for the indicator line
#property indicator_color4 clrGray,clrMagenta,clrGreen
//--- the indicator line is dashed
#property indicator_style4  STYLE_SOLID
//--- indicator line width is 3
#property indicator_width4  3
//--- displaying the indicator label
#property indicator_label4  "Signal line 2"
//+-----------------------------------+
//|  Indicator 2 drawing parameters   |
//+-----------------------------------+
//--- drawing the indicator 2 as a label
#property indicator_type5   DRAW_ARROW
//--- the color used as a label color
#property indicator_color5 clrLime
//--- indicator line width is 3
#property indicator_width5  3
//--- displaying the indicator label
#property indicator_label5  "Up Candle 2"
//+-----------------------------------+
//| Indicator 2 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 2 as a label
#property indicator_type6   DRAW_ARROW
//--- the color used as a label color
#property indicator_color6 clrRed
//--- indicator line width is 3
#property indicator_width6  3
//--- displaying the indicator label
#property indicator_label6  "Down Candle 2"
//+-----------------------------------+
//| Indicator 3 drawing parameters    |
//+-----------------------------------+
//--- drawing indicator 3 as a line
#property indicator_type7   DRAW_COLOR_LINE
//--- the following colors are used for the indicator line
#property indicator_color7 clrGray,clrMagenta,clrGreen
//--- the indicator line is dashed
#property indicator_style7  STYLE_SOLID
//--- indicator line width is 3
#property indicator_width7  3
//--- displaying the indicator label
#property indicator_label7  "Signal line 3"
//+-----------------------------------+
//| Indicator 3 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 3 as a label
#property indicator_type8   DRAW_ARROW
//--- the color used as a label color
#property indicator_color8 clrLime
//--- indicator line width is 5
#property indicator_width8  5
//--- displaying the indicator label
#property indicator_label8  "Up Candle 3"
//+-----------------------------------+
//| Indicator 3 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 3 as a label
#property indicator_type9   DRAW_ARROW
//--- the color used as a label color
#property indicator_color9 clrRed
//--- indicator line width is 3
#property indicator_width9  3
//--- displaying the indicator label
#property indicator_label9  "Down Candle 3"
//+-----------------------------------+
//| Indicator 4 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 4 as a line
#property indicator_type10   DRAW_COLOR_LINE
//--- the following colors are used for the indicator line
#property indicator_color10 clrGray,clrMagenta,clrGreen
//--- the indicator line is dashed
#property indicator_style10 STYLE_SOLID
//--- indicator line width is 3
#property indicator_width10  3
//--- displaying the indicator label
#property indicator_label10  "Signal line 4"
//+-----------------------------------+
//| Indicator 4 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 4 as a label
#property indicator_type11   DRAW_ARROW
//--- the color used as a label color
#property indicator_color11 clrLime
//--- indicator line width is 3
#property indicator_width11  3
//--- displaying the indicator label
#property indicator_label11  "Up Candle 4"
//+-----------------------------------+
//| Indicator 4 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 4 as a label
#property indicator_type12   DRAW_ARROW
//--- the color used as a label color
#property indicator_color12 clrRed
//--- indicator line width is 3
#property indicator_width12  3
//--- displaying the indicator label
#property indicator_label12  "Down Candle 4"
//+-----------------------------------+
//| Indicator 5 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 5 as a line
#property indicator_type13   DRAW_COLOR_LINE
//--- the following colors are used for the indicator line
#property indicator_color13 clrGray,clrMagenta,clrGreen
//--- the indicator line is dashed
#property indicator_style13 STYLE_SOLID
//--- indicator line width is 3
#property indicator_width13  3
//--- displaying the indicator label
#property indicator_label13  "Signal line 5"
//+-----------------------------------+
//| Indicator 5 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 5 as a label
#property indicator_type14   DRAW_ARROW
//--- the color used as a label color
#property indicator_color14 clrLime
//--- indicator line width is 3
#property indicator_width14  3
//--- displaying the indicator label
#property indicator_label14  "Up Candle 5"
//+-----------------------------------+
//| Indicator 5 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 5 as a label
#property indicator_type15   DRAW_ARROW
//--- the color used as a label color
#property indicator_color15 clrRed
//--- indicator line width is 3
#property indicator_width15  3
//--- displaying the indicator label
#property indicator_label15  "Down Candle 5"
//+-----------------------------------+
//|  Indicator 6 drawing parameters   |
//+-----------------------------------+
//--- Drawing indicator 6 as line
#property indicator_type16   DRAW_COLOR_LINE
//--- the following colors are used for the indicator line
#property indicator_color16 clrGray,clrMagenta,clrGreen
//--- the indicator line is dashed
#property indicator_style16 STYLE_SOLID
//--- indicator line width is 3
#property indicator_width16  3
//--- displaying the indicator label
#property indicator_label16  "Signal line 6"
//+-----------------------------------+
//|  Indicator 6 drawing parameters   |
//+-----------------------------------+
//--- drawing the indicator 6 as a label
#property indicator_type17   DRAW_ARROW
//--- the color used as a label color
#property indicator_color17 clrLime
//--- indicator line width is 3
#property indicator_width17  3
//--- displaying the indicator label
#property indicator_label17  "Up Candle 6"
//+-----------------------------------+
//|  Indicator 6 drawing parameters   |
//+-----------------------------------+
//--- drawing the indicator 6 as a label
#property indicator_type18   DRAW_ARROW
//--- the color used as a label color
#property indicator_color18 clrRed
//--- indicator line width is 3
#property indicator_width18  3
//--- displaying the indicator label
#property indicator_label18  "Down Candle 6"
//+-----------------------------------+
//|  Indicator 7 drawing parameters   |
//+-----------------------------------+
//--- drawing the indicator 7 as a line
#property indicator_type19   DRAW_COLOR_LINE
//--- the following colors are used for the indicator line
#property indicator_color19 clrGray,clrMagenta,clrGreen
//--- the indicator line is dashed
#property indicator_style19 STYLE_SOLID
//--- indicator line width is 3
#property indicator_width19  3
//--- displaying the indicator label
#property indicator_label19  "Signal line 7"
//+-----------------------------------+
//| Indicator 7 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 7 as a label
#property indicator_type20   DRAW_ARROW
//--- the color used as a label color
#property indicator_color20 clrLime
//--- indicator line width is 3
#property indicator_width20  3
//--- displaying the indicator label
#property indicator_label20  "Up Candle 7"
//+-----------------------------------+
//| Indicator 7 drawing parameters    |
//+-----------------------------------+
//--- drawing the indicator 7 as a label
#property indicator_type21   DRAW_ARROW
//--- the color used as a label color
#property indicator_color21 clrRed
//--- indicator line width is 3
#property indicator_width21  3
//--- displaying the indicator label
#property indicator_label21  "Down Candle 7"
//+-----------------------------------+
//| Indicator input parameters        |
//+-----------------------------------+
input ENUM_TIMEFRAMES TimeFrame0=PERIOD_D1;  //1 Chart period
input ENUM_TIMEFRAMES TimeFrame1=PERIOD_H12; //2 Chart period
input ENUM_TIMEFRAMES TimeFrame2=PERIOD_H8;  //3 Chart period
input ENUM_TIMEFRAMES TimeFrame3=PERIOD_H6;  //4 Chart period
input ENUM_TIMEFRAMES TimeFrame4=PERIOD_H4;  //5 Chart period
input ENUM_TIMEFRAMES TimeFrame5=PERIOD_H3;  //6 Chart period
input ENUM_TIMEFRAMES TimeFrame6=PERIOD_H1;  //7 Chart period
//+-----------------------------------+
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//|  Getting timeframe as string                                     |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {
//---
   return(StringSubstr(EnumToString(timeframe),7,-1));
//---
  }
//+------------------------------------------------------------------+
//| Indicator buffer class                                           |
//+------------------------------------------------------------------+  
class CIndBuffers
  {
   //---
public:
   double            m_UpBuffer[];
   double            m_DnBuffer[];
   double            m_LineBuffer[];
   double            m_ColorLineBuffer[];
   ENUM_TIMEFRAMES   m_TimeFrame;
   //--- 
  };
//--- declaration of dynamic arrays that will be used as indicator buffers
CIndBuffers Ind[INDTOTAL];
//+------------------------------------------------------------------+
//| Candle indicator initialization function                         | 
//+------------------------------------------------------------------+ 
bool IndInit(uint Number)
  {
//--- checking correctness of the chart periods
   if(Ind[Number].m_TimeFrame<Period() && Ind[Number].m_TimeFrame!=PERIOD_CURRENT)
     {
      Print("IndInit(",Number,"): The Candle indicator chart period cannot be less than the current chart period");
      return(false);
     }
   uint BIndex=Number*4+0;
   uint PIndex=Number*3+0;
   InitTsIndBuffer(BIndex,PIndex,Ind[Number].m_LineBuffer,EMPTY_VALUE,min_rates_total);
   InitTsIndColorBuffer(BIndex+1,PIndex,Ind[Number].m_ColorLineBuffer,min_rates_total);
   InitTsIndArrBuffer(BIndex+2,PIndex+1,Ind[Number].m_UpBuffer,EMPTY_VALUE,min_rates_total);
   InitTsIndArrBuffer(BIndex+3,PIndex+2,Ind[Number].m_DnBuffer,EMPTY_VALUE,min_rates_total);
//--- end of initialization of one indicator
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialization of time series indicator buffer                   |
//+------------------------------------------------------------------+  
void InitTsIndBuffer(uint Number,uint Plot,double &IndBuffer[],double Empty_Value,uint Draw_Begin)
  {
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(Number,IndBuffer,INDICATOR_DATA);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(Plot,PLOT_DRAW_BEGIN,Draw_Begin);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(Plot,PLOT_EMPTY_VALUE,Empty_Value);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//---
  }
//+------------------------------------------------------------------+
//| Initialization of time series indicator buffer                   |
//+------------------------------------------------------------------+  
void InitTsIndArrBuffer(uint Number,uint Plot,double &IndBuffer[],double Empty_Value,uint Draw_Begin)
  {
//--- set dynamic array as an indicator buffer
   SetIndexBuffer(Number,IndBuffer,INDICATOR_DATA);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(Plot,PLOT_DRAW_BEGIN,Draw_Begin);
//--- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(Plot,PLOT_EMPTY_VALUE,Empty_Value);
//--- selecting symbol for drawing
   PlotIndexSetInteger(Plot,PLOT_ARROW,167);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//---
  }
//+------------------------------------------------------------------+
//|  Initialization of time series color indicator buffer            |
//+------------------------------------------------------------------+  
void InitTsIndColorBuffer(uint Number,uint Plot,double &IndColorBuffer[],uint Draw_Begin)
  {
//--- set dynamic array as a color index buffer   
   SetIndexBuffer(Number,IndColorBuffer,INDICATOR_COLOR_INDEX);
//--- shifting the start of drawing of the indicator
   PlotIndexSetInteger(Plot,PLOT_DRAW_BEGIN,Draw_Begin);
//--- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndColorBuffer,true);
//---
  }
//+------------------------------------------------------------------+ 
//| Candle iteration function                                        | 
//+------------------------------------------------------------------+ 
bool IndOnCalculate(uint Number,uint Limit,const datetime &Time[],uint Rates_Total,uint Prev_Calculated)
  {
//--- declaration of integer variables
   uint limit_;
//--- declaration of variables with a floating point  
   double iOpen[1],iClose[1];
   datetime Time_[1],Time0;
   static uint LastCountBar[INDTOTAL];
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// checking for the first start of the indicator calculation
     {
      LastCountBar[Number]=Rates_Total;
      limit_=Limit;
     }
   else limit_=int(LastCountBar[Number])+Limit; // starting index for the calculation of new bars 
//--- main indicator calculation loop
   for(int bar=int(limit_); bar>=0 && !IsStopped(); bar--)
     {
      //--- reset the contents of the indicator buffers for calculation
      Ind[Number].m_UpBuffer[bar]=EMPTY_VALUE;
      Ind[Number].m_DnBuffer[bar]=EMPTY_VALUE;
      
      Ind[Number].m_LineBuffer[bar]=Number+1.0;
      
      Ind[Number].m_ColorLineBuffer[bar]=0;
      Time0=Time[bar];
      //--- copy newly appeared data in the array
      if(CopyTime(Symbol(),Ind[Number].m_TimeFrame,Time0,1,Time_)<=0) return(RESET);

      if(Time0>=Time_[0] && Time[bar+1]<Time_[0])
        {
         LastCountBar[Number]=bar;
         //--- copy newly appeared data in the arrays
         if(CopyOpen(Symbol(),Ind[Number].m_TimeFrame,Time0,1,iOpen)<=0) return(RESET);
         if(CopyClose(Symbol(),Ind[Number].m_TimeFrame,Time0,1,iClose)<=0) return(RESET);

         if(iClose[0]>iOpen[0])
           {
            Ind[Number].m_UpBuffer[bar]=Number+1.0;
            Ind[Number].m_ColorLineBuffer[bar]=2;
           }
           
         if(iClose[0]<iOpen[0])
           {
            Ind[Number].m_DnBuffer[bar]=Number+1.0;
            Ind[Number].m_ColorLineBuffer[bar]=1;
           }
        }

      if(Ind[Number].m_ColorLineBuffer[bar+1] && !Ind[Number].m_ColorLineBuffer[bar])
         Ind[Number].m_ColorLineBuffer[bar]=Ind[Number].m_ColorLineBuffer[bar+1];
     }
//--- end of calculation of one indicator    
   return(true);
  }
//+------------------------------------------------------------------+   
//| Candle indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//--- initialization of variables of data calculation start
   min_rates_total=3;
//--- initialization of variables 
   Ind[0].m_TimeFrame=TimeFrame0;
   Ind[1].m_TimeFrame=TimeFrame1;
   Ind[2].m_TimeFrame=TimeFrame2;
   Ind[3].m_TimeFrame=TimeFrame3;
   Ind[4].m_TimeFrame=TimeFrame4;
   Ind[5].m_TimeFrame=TimeFrame5;
   Ind[6].m_TimeFrame=TimeFrame6;
//--- initialization of indicator buffers
   for(int count=0; count<INDTOTAL; count++) if(!IndInit(count)) return(INIT_FAILED);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"MultiCandleSignal");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+ 
//| Candle iteration function                                        | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- checking if the number of bars is enough for the calculation
   if(rates_total<min_rates_total) return(RESET);
//--- declaration of integer variables
   int limit;
//--- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total-1; // Starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars 
//--- apply timeseries indexing to array elements  
   ArraySetAsSeries(time,true);
   for(int count=0; count<INDTOTAL; count++) if(!IndOnCalculate(count,limit,time,rates_total,prev_calculated)) return(RESET);
//---   
   return(rates_total);
  }
//+------------------------------------------------------------------+
