//+------------------------------------------------------------------+
//|                                             3ScreenElderNext.mq5 |
//|                                                          Sigma7i |
//|                                            sigma7iwork@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Sigma7i"
#property link      "sigma7iwork@gmail.com"
#property version   "1.01"




//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- two buffers are used for the indicator calculation and drawing
#property indicator_buffers 2
//---- two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- pink is used for the color of the bearish indicator line
#property indicator_color1  225,68,29
//---- thickness of the indicator line 1 is equal to 4
#property indicator_width1  1
//---- displaying of the bullish label of the indicator
#property indicator_label1  "ScreenElder Sell"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- green color is used for the color of the bullish line of the indicator
#property indicator_color2  DeepSkyBlue
//---- thickness of the indicator 2 line is equal to 4
#property indicator_width2  1
//---- displaying of the bearish label of the indicator
#property indicator_label2 "ScreenElder Buy"

enum Screens
  {
   ThreeScreens,
   TwoScreens,
   OneScreen,
  };

//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+

input   Screens           ShowScreens         = ThreeScreens;       //
input   ENUM_TIMEFRAMES   m_Screen01TimeFrame = PERIOD_D1;         // Timeframe of the first screen
input   int               m_Screen01IndicatorPeriod = 14;   // Period of the indicator of the first screen
   //---
input   ENUM_TIMEFRAMES   m_Screen02TimeFrame = PERIOD_H4;         // Timeframe of the second screen
input   int               m_Screen02IndicatorPeriod = 24;   // Period of the indicator of the second screen
   //---
input   ENUM_TIMEFRAMES   m_Screen03TimeFrame = PERIOD_H1;         // Timeframe of the third screen
input   int               m_Screen03IndicatorPeriod = 44;   // Period of the indicator of the third screen
//+----------------------------------------------+

//---- declaration of dynamic arrays that 
// will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//---
bool uptrend_,old;
int Indicator_Handle,Indicator_Handle2,Indicator_Handle3,ATR_Handle, StartBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables 
   StartBars=int(MathMax(10,15))+1;
//---- getting the indicator handle 
   Indicator_Handle=iCustom(NULL,m_Screen01TimeFrame,"Examples\\Custom Moving Average",m_Screen01IndicatorPeriod,0,MODE_EMA,PRICE_CLOSE);
   if(Indicator_Handle==INVALID_HANDLE)Print(" Failed to get the indicator handle ");
   
   Indicator_Handle2=iCustom(NULL,m_Screen02TimeFrame,"Examples\\Custom Moving Average",m_Screen02IndicatorPeriod,0,MODE_EMA,PRICE_CLOSE);
   if(Indicator_Handle2==INVALID_HANDLE)Print(" Failed to get the indicator handle ");
   
   Indicator_Handle3=iCustom(NULL,m_Screen03TimeFrame,"Examples\\Custom Moving Average",m_Screen03IndicatorPeriod,0,MODE_EMA,PRICE_CLOSE);
   if(Indicator_Handle3==INVALID_HANDLE)Print(" Failed to get the indicator handle ");
   
   //---- Getting the handle of the ATR indicator - for a proper display o th range between the price and arrows
   ATR_Handle=iATR(NULL,0,15);
   if(ATR_Handle==INVALID_HANDLE)Print(" Failed to get the ATR indicator handle");
   
//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- Shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//---- create a label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"ScreenElder Sell");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,234);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellBuffer,true);

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the starting point of the indicator 2 drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//---- create a label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"ScreenElder Buy");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,233);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyBuffer,true);

/ / ---- Setting the recording fidelity of the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- data window name and subwindow label 
   string short_name="ScreenElderIndicator";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
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


//---- declaration of local variables 
   int to_copy,limit,bar;
   double range,IND[],IND2[],IND3[],ATR[];
   bool uptrend,Buy,Sell;

//---- calculations of the necessary amount of data to be copied and
//the limit starting number for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      to_copy=rates_total; // calculated number of all bars
      limit=rates_total-StartBars; // starting number for calculation of all bars
      uptrend_=false;
      old=false;
     }
   else
     {
      to_copy=rates_total-prev_calculated+1; // calculated number of new bars
      limit=rates_total-prev_calculated; // starting index for the calculation of new bars
     }

//---- copy new data to the arrays of the indicator and ATR[]
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(0);

//---- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(IND,true);
   ArraySetAsSeries(IND2,true);
   ArraySetAsSeries(IND3,true);
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(time,true);
   //---
   
//---- Restore values of the variables
   uptrend=uptrend_;

//---- main cycle of calculation of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         uptrend_=uptrend;
        }
      
      range=ATR[bar]*3/8;  // is not used in the logic

      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
 

 //+------------------------------------------------------------------+
 //|   A block with the display logic                                 |
 //+------------------------------------------------------------------+
   
// To show indicators from different timeframes  (with different array size)
// copy starting with time

   if(CopyBuffer(Indicator_Handle,0,time[bar],3,IND)<=0) return(0);
   if(CopyBuffer(Indicator_Handle2,0,time[bar],3,IND2)<=0) return(0);
   if(CopyBuffer(Indicator_Handle3,0,time[bar],3,IND3)<=0) return(0);

 // calculate indicators on formed bars[1]
      Buy  = GetBuySignal(IND[1],IND2[1],IND3[1],IND[2],IND2[2],IND3[2]);
      Sell = GetSellSignal(IND[1],IND2[1],IND3[1],IND[2],IND2[2],IND3[2]);
 
 
      if(Sell)     uptrend=false;
      if(Buy)      uptrend=true;
      
  //+------------------------------------------------------------------+     

      if(!old &&  uptrend) BuyBuffer [bar]=low [bar]-range;
      if( old && !uptrend) SellBuffer[bar]=high[bar]+range;

      if(bar) old=uptrend;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|    Check for a buy signal                                        |
//+------------------------------------------------------------------+

bool GetBuySignal(const double &indicator_1,const double &indicator_2, const double &indicator_3,const double &PrevIndicator_1,const double &PrevIndicator_2, const double &PrevIndicator_3)
  {
//--- A BUY SIGNAL: the current value of the indicators on completed bars

//--- Conditions for one timeframe
   if(ShowScreens==OneScreen)
     {
      if(indicator_1>PrevIndicator_1)
         return(true);
     }

//--- Conditions for two timeframes
   if(ShowScreens==TwoScreens)
     {
      if(indicator_1>PrevIndicator_1 && 
         indicator_2>PrevIndicator_2)
         return(true);
     }

//--- Conditions for three timeframes
   if(ShowScreens==ThreeScreens)
     {
      if(indicator_1>PrevIndicator_1 && 
         indicator_2>PrevIndicator_2 && 
         indicator_3>PrevIndicator_3
         )
         return(true);
     }

   return(false);
  }
  
  //+------------------------------------------------------------------+
//|      Check for a sell signal                                       |
//+------------------------------------------------------------------+

bool GetSellSignal(const double &indicator_1,const double &indicator_2, const double &indicator_3,const double &PrevIndicator_1,const double &PrevIndicator_2, const double &PrevIndicator_3)
  {

//--- A SELL SIGNAL: the current value of the indicators on completed bars
//--- Conditions for one timeframe
   if(ShowScreens==OneScreen)
     {
      if(indicator_1<PrevIndicator_1)
         return(true);
     }

//--- Conditions for two timeframes
   if(ShowScreens==TwoScreens)
     {
      if(indicator_1<PrevIndicator_1 && 
         indicator_2<PrevIndicator_2)
         return(true);
     }
 
//--- Conditions for three time frames
   if(ShowScreens==ThreeScreens)
     {
      if(indicator_1<PrevIndicator_1 && 
         indicator_2<PrevIndicator_2 && 
         indicator_3<PrevIndicator_3
         )
         return(true);
     }
   return(false);
  }
