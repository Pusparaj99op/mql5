//+------------------------------------------------------------------+
//|                                                    Arbitrage.mq5 |
//|                                          Copyright 2018, pipPod. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright  "Copyright 2018, pipPod."
#property link       "https://www.mql5.com/en/users/pippod"
#property description"Arbitrage"
#property version    "2.10"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//---
#property indicator_color1  clrLimeGreen,clrFireBrick
#property indicator_width1  2
#property indicator_color2  clrFireBrick
#property indicator_width2  2
//---
#property indicator_levelcolor clrLightSlateGray
//---
double indicator_level1=   0;
double indicator_level2=  .2;
double indicator_level4=  20;
double indicator_level6=  30;
double indicator_level8= 100;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum indicators
  {
   INDICATOR_MA,           //Moving Average
   INDICATOR_MACD,         //Moving Average Convergence/Divergence
   INDICATOR_STOCHASTIC,   //Stochastic Oscillator
   INDICATOR_RSI,          //Relative Strength Index
   INDICATOR_CCI,          //Commodity Channel Index
   INDICATOR_RVI,          //Relative Vigor Index
   INDICATOR_DEMARK,       //DeMarker Oscillator
   INDICATOR_TRIX          //Triple Exponential Average
  };
//--- indicator to show
input indicators  Indicator=INDICATOR_MA;
//--- indicator parameters
input string MA;
input ushort MAPeriod=14;                          //MA Period
input ENUM_MA_METHOD MAMethod=MODE_SMA;            //MA Method
input ENUM_APPLIED_PRICE MAPrice=PRICE_CLOSE;      //MA Price
//---
input string MACD;
input ushort FastEMA=12;                           //Fast EMA Period
input ushort SlowEMA=26;                           //Slow EMA Period
input ushort SignalSMA=9;                          //Signal SMA Period
input ENUM_APPLIED_PRICE MACDPrice=PRICE_CLOSE;    //MACD Price
//---
input string Stochastic;
input ushort Kperiod=7;                            //K Period
input ushort Dperiod=3;                            //D Period
input ushort Slowing=3;
input ENUM_STO_PRICE PriceField=STO_LOWHIGH;       //Price Field
//---
input string RSI;
input ushort RSIPeriod=14;                         //RSI Period
input ENUM_APPLIED_PRICE RSIPrice=PRICE_CLOSE;     //RSI Price
//---
input string CCI;
input ushort CCIPeriod=14;                         //CCI Period
input ENUM_APPLIED_PRICE CCIPrice=PRICE_CLOSE;     //CCI Price
//---
input string RVI;
input ushort RVIPeriod=14;                         //RVI Period
//---
input string DeMarker;
input ushort DeMarkerPeriod=14;                    //DeMarker Period
//---
input string TriX;
input ushort TrixPeriod=14;                        //TriX Period
input ENUM_APPLIED_PRICE TrixPrice=PRICE_CLOSE;    //TriX Price
input string _;   //---
input bool ColorBars=true;                         //Color Bars
input bool FillBuffers=true;                       //Fill Buffers
//--- index buffers for drawing
double   BaseBuffer[];
double   QuotBuffer[];
//--- currency variables for calculation
#define  USDJPY "USDJPY"
//---
string   base,
         quot,
         symbol1,
         symbol2,
         symbol3;
//---
double   Index1[],
         Index2[],
         Index3[],
         index1,
         index2,
         index3,
         baseIndex,
         quotIndex;
//---
bool     baseUSD=false,
         quotUSD=false,
         quotJPY=false,
         quotJPY1=false,
         quotJPY2=false,
         quotJPY3=false;
//---
string   shortName;
long     chartID;
short    window;     
//--- indicator handles
int      indHandle1,
         indHandle2,
         indHandle3;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---set index colors
   color colorBase=indicator_color1,
         colorQuot=indicator_color2;
//---currencies to show
   base = StringSubstr(_Symbol,0,3);  //Base currency name
   quot = StringSubstr(_Symbol,3,3);  //Quot currency name
   if(_Symbol=="EURUSD")
     {
      if(!SymbolSelect("EURJPY",true) ||
         !SymbolSelect(USDJPY,true))
         return(INIT_FAILED);
      colorBase=clrRoyalBlue;
      colorQuot=clrLimeGreen;
      quotUSD= true;
      symbol1 = _Symbol;
      symbol2 = "EURJPY";
      quotJPY2=true;
      symbol3=USDJPY;
      quotJPY3=true;
     }
   if(_Symbol=="EURJPY")
     {
      if(!SymbolSelect("EURUSD",true) ||
         !SymbolSelect(USDJPY,true))
         return(INIT_FAILED);
      colorBase=clrRoyalBlue;
      colorQuot=clrYellow;
      quotJPY= true;
      symbol1 = _Symbol;
      quotJPY1=true;
      symbol2 = "EURUSD";
      symbol3 = USDJPY;
      quotJPY3=true;
     }
   if(_Symbol=="GBPUSD")
     {
      if(!SymbolSelect("GBPJPY",true) ||
         !SymbolSelect(USDJPY,true))
         return(INIT_FAILED);
      colorBase=clrSilver;
      colorQuot=clrLimeGreen;
      quotUSD= true;
      symbol1 = _Symbol;
      symbol2 = "GBPJPY";
      quotJPY2=true;
      symbol3=USDJPY;
      quotJPY3=true;
     }
   if(_Symbol=="GBPJPY")
     {
      if(!SymbolSelect("GBPUSD",true) ||
         !SymbolSelect(USDJPY,true))
         return(INIT_FAILED);
      colorBase=clrSilver;
      colorQuot=clrYellow;
      quotJPY= true;
      symbol1 = _Symbol;
      quotJPY1=true;
      symbol2 = "GBPUSD";
      symbol3 = USDJPY;
      quotJPY3=true;
     }
   if(_Symbol=="USDCAD")
     {
      if(!SymbolSelect("CADJPY",true) ||
         !SymbolSelect(USDJPY,true))
         return(INIT_FAILED);
      colorBase=clrLimeGreen;
      colorQuot=clrWhiteSmoke;
      baseUSD = true;
      symbol1 = _Symbol;
      symbol2 = "CADJPY";
      quotJPY2=true;
      symbol3=USDJPY;
      quotJPY3=true;
     }
   if(_Symbol=="USDCHF")
     {
      if(!SymbolSelect("CHFJPY",true) ||
         !SymbolSelect(USDJPY,true))
         return(INIT_FAILED);
      colorBase=clrLimeGreen;
      colorQuot=clrFireBrick;
      baseUSD = true;
      symbol1 = _Symbol;
      symbol2 = "CHFJPY";
      quotJPY2=true;
      symbol3=USDJPY;
      quotJPY3=true;
     }
   if(_Symbol==USDJPY)
     {
      if(!SymbolSelect("EURUSD",true) ||
         !SymbolSelect("EURJPY",true))
         return(INIT_FAILED);
      colorBase=clrLimeGreen;
      colorQuot=clrYellow;
      quotJPY= true;
      symbol1 = _Symbol;
      quotJPY1=true;
      symbol2 = "EURUSD";
      symbol3 = "EURJPY";
      quotJPY3=true;
     }
//---
   indHandle1 = INVALID_HANDLE;
   indHandle2 = INVALID_HANDLE;
   indHandle3 = INVALID_HANDLE;
   switch(Indicator)
     {
      case INDICATOR_MA:
         indHandle1 = iMA(symbol1,_Period,MAPeriod,MAMethod,0,MACDPrice);
         indHandle2 = iMA(symbol2,_Period,MAPeriod,MAMethod,0,MACDPrice);
         indHandle3 = iMA(symbol3,_Period,MAPeriod,MAMethod,0,MACDPrice);
         shortName=StringFormat("Arbitrage %s(%d)",
                                StringSubstr(EnumToString((ENUM_MA_METHOD)MAMethod),5),MAPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,5);
         IndicatorSetInteger(INDICATOR_LEVELS,1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         break;
      case INDICATOR_MACD:
         indHandle1 = iMACD(symbol1,_Period,FastEMA,SlowEMA,SignalSMA,MACDPrice);
         indHandle2 = iMACD(symbol2,_Period,FastEMA,SlowEMA,SignalSMA,MACDPrice);
         indHandle3 = iMACD(symbol3,_Period,FastEMA,SlowEMA,SignalSMA,MACDPrice);
         shortName=StringFormat("Arbitrage MACD(%d,%d,%d)",
                                FastEMA,SlowEMA,SignalSMA);
         IndicatorSetInteger(INDICATOR_DIGITS,5);
         IndicatorSetInteger(INDICATOR_LEVELS,1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         break;
      case INDICATOR_STOCHASTIC:
         indHandle1 = iStochastic(symbol1,_Period,Kperiod,Dperiod,Slowing,MODE_SMA,PriceField);
         indHandle2 = iStochastic(symbol2,_Period,Kperiod,Dperiod,Slowing,MODE_SMA,PriceField);
         indHandle3 = iStochastic(symbol3,_Period,Kperiod,Dperiod,Slowing,MODE_SMA,PriceField);
         shortName=StringFormat("Arbitrage Stochastic(%d,%d,%d)",
                                Kperiod,Dperiod,Slowing);
         IndicatorSetInteger(INDICATOR_DIGITS,0);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0, indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1, indicator_level6);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level6);
         break;
      case INDICATOR_RSI:
         indHandle1 = iRSI(symbol1,_Period,RSIPeriod,RSIPrice);
         indHandle2 = iRSI(symbol2,_Period,RSIPeriod,RSIPrice);
         indHandle3 = iRSI(symbol3,_Period,RSIPeriod,RSIPrice);
         shortName=StringFormat("Arbitrage RSI(%d)",
                                RSIPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,0);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0, indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1, indicator_level4);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level4);
         break;
      case INDICATOR_CCI:
         indHandle1 = iCCI(symbol1,_Period,CCIPeriod,CCIPrice);
         indHandle2 = iCCI(symbol2,_Period,CCIPeriod,CCIPrice);
         indHandle3 = iCCI(symbol3,_Period,CCIPeriod,CCIPrice);
         shortName=StringFormat("Arbitrage CCI(%d)",
                                CCIPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,0);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0, indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1, indicator_level8);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level8);
         break;
      case INDICATOR_RVI:
         indHandle1 = iRVI(symbol1,_Period,RVIPeriod);
         indHandle2 = iRVI(symbol2,_Period,RVIPeriod);
         indHandle3 = iRVI(symbol3,_Period,RVIPeriod);
         shortName=StringFormat("Arbitrage RVI(%d)",
                                RVIPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,3);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0, indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1, indicator_level2);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level2);
         break;
      case INDICATOR_DEMARK:
         indHandle1 = iDeMarker(symbol1,_Period,DeMarkerPeriod);
         indHandle2 = iDeMarker(symbol2,_Period,DeMarkerPeriod);
         indHandle3 = iDeMarker(symbol3,_Period,DeMarkerPeriod);
         shortName=StringFormat("Arbitrage DeMarker(%d)",
                                DeMarkerPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,3);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0, indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1, indicator_level2);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level2);
         break;
      case INDICATOR_TRIX:
         indHandle1 = iTriX(symbol1,_Period,TrixPeriod,TrixPrice);
         indHandle2 = iTriX(symbol2,_Period,TrixPeriod,TrixPrice);
         indHandle3 = iTriX(symbol3,_Period,TrixPeriod,TrixPrice);
         shortName=StringFormat("Arbitrage TriX(%d)",
                                TrixPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,5);
         IndicatorSetInteger(INDICATOR_LEVELS,1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
     }
   if(indHandle1==INVALID_HANDLE ||
      indHandle2==INVALID_HANDLE ||
      indHandle3==INVALID_HANDLE)
      return(INIT_FAILED);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,shortName);
   chartID=ChartID();
   window=(short)ChartWindowFind(chartID,shortName);
   uchar xStart=4;       //label coordinates
   uchar xIncrement=25;
   uchar yStart=16;
   ObjectCreate(base,xStart,yStart,colorBase);
   xStart+=xIncrement;
   ObjectCreate(quot,xStart,yStart,colorQuot);
//--- set buffers as series
   ArraySetAsSeries(Index1,true);
   ArraySetAsSeries(Index2,true);
   ArraySetAsSeries(Index3,true);
//--- index buffers
   SetIndexBuffer(0,BaseBuffer);
   ArraySetAsSeries(BaseBuffer,true);
   SetIndexBuffer(1,QuotBuffer);
   ArraySetAsSeries(QuotBuffer,true);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- DRAW_FILLING / DRAW_LINE
   if(FillBuffers)
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_FILLING);
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,colorBase);
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,colorQuot);
      PlotIndexSetString(0,PLOT_LABEL,base+";"+quot);
     }
   else
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,colorBase);
      PlotIndexSetInteger(1,PLOT_LINE_COLOR,colorQuot);
      PlotIndexSetString(0,PLOT_LABEL,base);
      PlotIndexSetString(1,PLOT_LABEL,quot);
     }
//--- color bars
   if(ColorBars)
     {
      if(ChartGetInteger(0,CHART_COLOR_CANDLE_BULL)!=colorBase)
        {
         ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,colorBase);
         ChartSetInteger(0,CHART_COLOR_CHART_UP,colorBase);
        }
      if(ChartGetInteger(0,CHART_COLOR_CANDLE_BEAR)!=colorQuot)
        {
         ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,colorQuot);
         ChartSetInteger(0,CHART_COLOR_CHART_DOWN,colorQuot);
        }
     }
//---
   return(INIT_SUCCEEDED);
  }
//---
#define INVERT -1
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
//---
   ArraySetAsSeries(time,true);
   int limit=rates_total-prev_calculated;
   if(prev_calculated>rates_total || prev_calculated<=0)
     {
      int barsWindow=(int)ChartGetInteger(chartID,CHART_VISIBLE_BARS)+20;
      if(iBars(symbol1,_Period)<=barsWindow || BarsCalculated(indHandle1)<barsWindow ||
         iBars(symbol2,_Period)<=barsWindow || BarsCalculated(indHandle2)<barsWindow ||
         iBars(symbol3,_Period)<=barsWindow || BarsCalculated(indHandle3)<barsWindow)
         return(0);
      ArrayInitialize(BaseBuffer,EMPTY_VALUE);
      ArrayInitialize(QuotBuffer,EMPTY_VALUE);
      limit=barsWindow-2;
     }
   int toCopy=limit+2,copied=0;
//--- get data
   if((copied = CopyBuffer(indHandle1,0,time[0],toCopy,Index1)) != toCopy ||
      (copied = CopyBuffer(indHandle2,0,time[0],toCopy,Index2)) != toCopy ||
      (copied = CopyBuffer(indHandle3,0,time[0],toCopy,Index3)) != toCopy)
     {
      printf("Error: %d",_LastError); 
      return(!prev_calculated?0:rates_total-1);
     }
//--- main loop for calculation
   for(int i=limit;i>=0 && !_StopFlag;i--)
     {
      index1 = Index1[i];
      index2 = Index2[i];
      index3 = Index3[i];
      switch(Indicator)
        {
         case INDICATOR_MA:
            index1 -= Index1[i+1];
            if(quotJPY1)
               index1/=100;
            index2 -= Index2[i+1];
            if(quotJPY2)
               index2/=100;
            index3 -= Index3[i+1];
            if(quotJPY3)
               index3/=100;
            break;
         case INDICATOR_MACD:
            if(quotJPY1)
               index1/=100;
            if(quotJPY2)
               index2/=100;
            if(quotJPY3)
               index3/=100;
            break;
         case INDICATOR_STOCHASTIC:
         case INDICATOR_RSI:
            index1 -= 50;
            index2 -= 50;
            index3 -= 50;
            break;
         case INDICATOR_DEMARK:
            index1 -= .5;
            index2 -= .5;
            index3 -= .5;
            break;
         default:
            break;
        }
      //---
      if(quotUSD)
        {
         baseIndex=(index1+index2)/2;
         index1*=INVERT;
         quotIndex=(index1+index3)/2;
        }
      if(quotJPY)
        {
         if(_Symbol==USDJPY)
            index2*=INVERT;
         baseIndex=(index1+index2)/2;
         index1 *= INVERT;
         index3 *= INVERT;
         quotIndex=(index1+index3)/2;
        }
      if(baseUSD)
        {
         baseIndex=(index1+index3)/2;
         index1*=INVERT;
         quotIndex=(index1+index2)/2;
        }
      //---
      BaseBuffer[i] = baseIndex;
      QuotBuffer[i] = quotIndex;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
// delete labels
   ObjectDelete(chartID,base+string(window));
   ObjectDelete(chartID,quot+string(window));
// release indicators
   IndicatorRelease(indHandle1);
   IndicatorRelease(indHandle2);
   IndicatorRelease(indHandle3);
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectCreate(const string &currency,
                  uchar x,
                  uchar y,
                  color clr)
  {
   string name=currency+string(window);
   ObjectCreate(chartID,name,OBJ_LABEL,window,0,0);
   ObjectSetString(chartID,name,OBJPROP_TEXT,currency);
   ObjectSetString(chartID,name,OBJPROP_FONT,"Arial Bold");
   ObjectSetInteger(chartID,name,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(chartID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chartID,name,OBJPROP_YDISTANCE,y);
  }
//-------------------------------------------------------------------+
