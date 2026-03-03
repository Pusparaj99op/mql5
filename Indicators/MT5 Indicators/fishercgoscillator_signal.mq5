//+----------------------------------------------------------------------+
//|                                        FisherCGOscillator_Signal.mq5 | 
//|                                   Copyright © 2014, Nikolay Kositsin | 
//|                                  Khabarovsk,   farria@mail.redcom.ru | 
//+----------------------------------------------------------------------+
//| For the indicator functioning, place the FisherCGOscillator.mq5 file |
//| to the terminal_data_folder\MQL5\Indicators and compile it           |
//+----------------------------------------------------------------------+
#property copyright "Copyright © 2014, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description ""
//--- indicator version
#property version   "1.60"
//--- drawing the indicator in a separate window
#property indicator_separate_window
//--- fixed height of the indicator subwindow in pixels 
#property indicator_height 20
//--- lower and upper scale limit of a separate indicator window
#property indicator_maximum +1.9
#property indicator_minimum +0.3
//+----------------------------------------------+
//| declaring constants                          |
//+----------------------------------------------+
#define RESET 0                                // A constant for returning the indicator recalculation command to the terminal
#define INDTOTAL 1                             // A constant for the number of displayed indicator
#define INDICATOR_NAME "FisherCGOscillator"    // A constant for the indicator name
//+----------------------------------------------+
//--- number of indicator buffers
#property indicator_buffers 4 // INDTOTAL*4
//--- total plots used
#property indicator_plots   2 // INDTOTAL*2
//+----------------------------------------------+
//| Indicator 1 drawing parameters               |
//+----------------------------------------------+
//--- drawing indicator 1 as a line
#property indicator_type1   DRAW_COLOR_LINE
//--- the following colors are used for the indicator line
#property indicator_color1 clrDarkOrange,clrGray,clrDodgerBlue
//--- the indicator line is dashed
#property indicator_style1  STYLE_SOLID
//--- indicator line width is 3
#property indicator_width1  3
//--- displaying the indicator label
#property indicator_label1  "Signal line"
//+----------------------------------------------+
//| Indicator 2 drawing parameters               |
//+----------------------------------------------+
//--- drawing the indicator as four-color labels
#property indicator_type2 DRAW_COLOR_ARROW
//--- colors of the five-color histogram are as follows
#property indicator_color2 clrDarkOrange,clrGray,clrDodgerBlue
//--- Indicator line is a solid one
#property indicator_style2 STYLE_SOLID
//--- indicator line width is 5
#property indicator_width2 5
//--- displaying the indicator label
#property indicator_label2  "Signal Arrow"
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4;   // Chart period
input uint Length=10;                        // Indicator period
//+----------------------------------------------+
//--- declaration of integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Getting a timeframe as a line                                    |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
//+------------------------------------------------------------------+
//| Indicator buffer class                                           |
//+------------------------------------------------------------------+  
class CIndBuffers
  {
   //---
public:
   double            m_LineBuffer[];
   double            m_ColorLineBuffer[];
   double            m_ArrowBuffer[];
   double            m_ColorArrowBuffer[];
   int               m_Handle;
   ENUM_TIMEFRAMES   m_TimeFrame;
   //---
  };
//--- declaration of dynamic arrays that will be used as indicator buffers
CIndBuffers Ind[INDTOTAL];
//+------------------------------------------------------------------+   
//| FisherCGOscillator indicator initialization function             | 
//+------------------------------------------------------------------+
bool IndInit(uint Number)
  {
//--- checking correctness of the chart periods
   if(Ind[Number].m_TimeFrame<Period() && Ind[Number].m_TimeFrame!=PERIOD_CURRENT)
     {
      Print("IndInit(",Number,"): The FisherCGOscillator indicator chart period cannot be less than the current chart period");
      return(false);
     }
//--- receiving indicator handles  
   Ind[Number].m_Handle=iCustom(Symbol(),Ind[Number].m_TimeFrame,"FisherCGOscillator",Length,0);
   if(Ind[Number].m_Handle==INVALID_HANDLE)
     {
      Print("IndInit(",Number,"): Failed to get the FisherCGOscillator indicator handle");
      return(false);
     }
//---
   uint BIndex=Number*4+0;
   uint PIndex=Number*2+0;
   InitTsIndBuffer(BIndex,PIndex,Ind[Number].m_LineBuffer,EMPTY_VALUE,min_rates_total);
   InitTsIndColorBuffer(BIndex+1,Ind[Number].m_ColorLineBuffer);
   InitTsIndArrBuffer(BIndex+2,PIndex+1,Ind[Number].m_ArrowBuffer,EMPTY_VALUE,min_rates_total);
   InitTsIndColorBuffer(BIndex+3,Ind[Number].m_ColorArrowBuffer);
//---   
   string tmf=GetStringTimeframe(Ind[Number].m_TimeFrame);
   PlotIndexSetString(PIndex+0,PLOT_LABEL,INDICATOR_NAME+"Line("+tmf+")");
   PlotIndexSetString(PIndex+1,PLOT_LABEL,INDICATOR_NAME+"Arrow("+tmf+")");
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
   PlotIndexSetInteger(Plot,PLOT_ARROW,159);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);
//---
  }
//+------------------------------------------------------------------+
//| Initialization of time series color indicator buffer             |
//+------------------------------------------------------------------+  
void InitTsIndColorBuffer(uint Number,double &IndColorBuffer[])
  {
//--- set dynamic array as a color index buffer   
   SetIndexBuffer(Number,IndColorBuffer,INDICATOR_COLOR_INDEX);
//--- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndColorBuffer,true);
//---
  }
//+------------------------------------------------------------------+ 
//| IndOnCalculate                                                   | 
//+------------------------------------------------------------------+ 
bool IndOnCalculate(int Number,int Limit,const datetime &Time[],uint Rates_Total,uint Prev_Calculated)
  {
//--- declaration of integer variables
   int limit_;
//--- declaration of local variables
   datetime Time_[1],Time0;
   static int LastCountBar[INDTOTAL];
//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// checking for the first start of the indicator calculation
     {
      limit_=Limit;
      LastCountBar[Number]=limit_;
     }
   else limit_=int(MathMin(LastCountBar[Number]+Limit,Rates_Total-2)); // starting index for calculating new bars
//--- main indicator calculation loop
   for(int bar=int(limit_); bar>=0 && !IsStopped(); bar--)
     {
      //--- reset the contents of the indicator buffers for calculation
      Ind[Number].m_LineBuffer[bar]=Number+1.0;
      Ind[Number].m_ArrowBuffer[bar]=EMPTY_VALUE;
      Ind[Number].m_ColorLineBuffer[bar]=EMPTY_VALUE;
      //---
      Time0=Time[bar];
      //--- copy newly appeared data in the array
      if(CopyTime(Symbol(),Ind[Number].m_TimeFrame,Time0,1,Time_)<=0) return(RESET);
      //---
      if(Time0>=Time_[0] && Time[bar+1]<Time_[0])
        {
         LastCountBar[Number]=bar;
         Ind[Number].m_ArrowBuffer[bar]=Number+1.0;
         Ind[Number].m_ColorLineBuffer[bar]=1;
         //---
         double Main[1],Sign[1];
         //--- copy newly appeared data in the arrays
         if(CopyBuffer(Ind[Number].m_Handle,0,Time0,1,Main)<=0) return(RESET);
         if(CopyBuffer(Ind[Number].m_Handle,1,Time0,1,Sign)<=0) return(RESET);
         //---
         if(Main[0]>Sign[0]) Ind[Number].m_ColorLineBuffer[bar]=2;
         if(Main[0]<Sign[0]) Ind[Number].m_ColorLineBuffer[bar]=0;
         Ind[Number].m_ColorArrowBuffer[bar]=Ind[Number].m_ColorLineBuffer[bar];
        }
      if(Ind[Number].m_ColorLineBuffer[bar+1]!=EMPTY_VALUE && Ind[Number].m_ColorLineBuffer[bar]==EMPTY_VALUE)
        {
         Ind[Number].m_ColorLineBuffer[bar]=Ind[Number].m_ColorLineBuffer[bar+1];
        }
     }
//--- end of calculation of one indicator    
   return(true);
  }
//+------------------------------------------------------------------+   
//| FisherCGOscillator indicator initialization function             | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//--- initialization of variables of data calculation start
   min_rates_total=3;
//--- initialization of variables 
   Ind[0].m_TimeFrame=TimeFrame;
//--- Initialization of indicator buffers
   for(int count=0; count<INDTOTAL; count++) if(!IndInit(count)) return(INIT_FAILED);
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"FisherCGOscillator("+GetStringTimeframe(Ind[0].m_TimeFrame)+")");
//--- determining the accuracy of the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+ 
//| FisherCGOscillator iteration function                            | 
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
   for(int count=0; count<INDTOTAL; count++)
      if(BarsCalculated(Ind[count].m_Handle)<Bars(Symbol(),Ind[count].m_TimeFrame))
         return(prev_calculated);
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
