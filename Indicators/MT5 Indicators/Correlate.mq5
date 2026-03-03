//+------------------------------------------------------------------+
//|                                                    Correlate.mq5 |
//|                                           Copyright 2020, ernst. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright  "Copyright 2020, ernst."
#property link       "https://www.mql5.com/en/users/pippod"
#property version    "1.77"
#resource "\\Indicators\\OnTick.ex5"
#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots   9
//--- plot AUD
#property indicator_label1  "AUD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot CAD
#property indicator_label2  "CAD"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrAqua
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot CHF
#property indicator_label3  "CHF"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrFireBrick
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//--- plot EUR
#property indicator_label4  "EUR"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRoyalBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
//--- plot GBP
#property indicator_label5  "GBP"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrSilver
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2
//--- plot JPY
#property indicator_label6  "JPY"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrSaddleBrown
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2
//--- plot NZD
#property indicator_label7  "NZD"
#property indicator_type7   DRAW_LINE
#property indicator_color7  clrDarkViolet
#property indicator_style7  STYLE_SOLID
#property indicator_width7  2
//--- plot XAU
#property indicator_label8  "XAU"
#property indicator_type8   DRAW_LINE
#property indicator_color8  clrGold
#property indicator_style8  STYLE_SOLID
#property indicator_width8  2
//--- plot USD
#property indicator_label9  "USD"
#property indicator_type9   DRAW_LINE
#property indicator_color9  clrLimeGreen
#property indicator_style9  STYLE_SOLID
#property indicator_width9  2
//---
#define indicator_handles 8
//---
#property indicator_levelcolor clrLightSlateGray
double indicator_level1=  0;
double indicator_level2= .2;
double indicator_level3= 20;
double indicator_level4= 30;
double indicator_level5=100;
//+------------------------------------------------------------------+
//| Class for indicator and index buffers                            |
//+------------------------------------------------------------------+
class CSymbol
  {
private:
   string            m_symbol;
   int               m_handle,m_tick;
   int               m_size;
   double            m_buffer[];
   //int               m_tick;
public:
   //---             constructor
                     CSymbol(string symbol):m_symbol(symbol),m_handle(INVALID_HANDLE),m_tick(INVALID_HANDLE) {  ArraySetAsSeries(true);  }
   //---             destructor
                    ~CSymbol(void)  {  IndicatorRelease();  }
   //---             set indicator handle
   bool              Handle(int handle,int index)   {  return((m_handle=handle)!=INVALID_HANDLE&&(m_tick=iCustom(m_symbol,_Period,"::Indicators\\OnTick.ex5",ChartID(),index,Pips))!=INVALID_HANDLE);   }
   //---             get symbol/indicator value
   double            operator[](int index)  const {  return(index>=0 && index<m_size ? this.m_buffer[index]:0.0); }
   //---             copy symbol/indicator data
   int               CopyBuffer(const int start,const int count)  {  return(m_size=::CopyBuffer(m_handle,0,start,count,m_buffer));  }
   //---             rates total
   int               Bars; 
   //---             previously calculated bars
   bool              BarsCalculated(void) {  return(::BarsCalculated(m_handle)>=(Bars=::iBars(m_symbol,_Period)));   }
   //---             release indicator handles
   bool              IndicatorRelease(void)  {  return(::IndicatorRelease(m_handle)&&::IndicatorRelease(m_tick)); }
   //---             index buffer series flag
   bool              ArraySetAsSeries(bool flag) { return(ArraySetAsSeries(m_buffer,flag));   }
//---
  }*indicator[indicator_handles],*ind;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CBuffer
  {
private:
   int               m_size;
   //---             buffers
   double            m_buffer[];
public:
   //---             constructor
                     CBuffer(void) {  ArraySetAsSeries(true); }
   //---             destructor
                    ~CBuffer(void)  {}
   //---             assign index buffers
   bool              SetIndexBuffer(int index,ENUM_INDEXBUFFER_TYPE buffer_mode=INDICATOR_DATA) {  return(::SetIndexBuffer(index,m_buffer,buffer_mode));   }
   //---             index buffer series flag
   bool              ArraySetAsSeries(bool flag)   {  return(ArraySetAsSeries(m_buffer,flag));  }
   //---             initialize index buffers 
   int               ArrayInitialize(double value) {  return(::ArrayInitialize(m_buffer,value));  }
   //---             detach index buffers
   void              ArrayFree(void)   {  ArrayFree(m_buffer); return;  }
   //---             set index buffer value
   double            Close(int index,double value) { return(this.m_buffer[index]=value); }
   //---             indicator value
   double            close;
//---
  }*currency[indicator_buffers],*cur;
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
   INDICATOR_RVI,          //Relative Vigour Index
   INDICATOR_DEMARKER,     //DeMarker Oscillator
   INDICATOR_MOMENTUM,     //Momentum Oscillator
   INDICATOR_TRIX,         //Triple Exponential Average
   INDICATOR_MFI,          //Money Flow Index
  };
//--- indicator to display
input indicators  Indicator=INDICATOR_RSI;
//--- indicator parameters
input group "";                                 //---
input int BarsToCount=500;                      //Bars to count
input string Sfix="";                           //Symbol Suffix
//---
input group "MA";
input ushort MAPeriod=14;                       //MA Period
input ENUM_MA_METHOD MAMethod=MODE_SMA;         //MA Method
input ENUM_APPLIED_PRICE MAPrice=PRICE_CLOSE;   //MA Price
//---
input group "MACD";
input ushort FastEMA=12;                        //Fast EMA Period
input ushort SlowEMA=26;                        //Slow EMA Period
input ENUM_APPLIED_PRICE MACDPrice=PRICE_CLOSE; //MACD Price
//---
input group "Stochastic";
input ushort Kperiod=7;                         //K Period
input ushort Slowing=3;
input ENUM_STO_PRICE PriceField=STO_LOWHIGH;    //Price Field
//---
input group "RSI";
input ushort RSIPeriod=14;                      //RSI Period
input ENUM_APPLIED_PRICE RSIPrice=PRICE_CLOSE;  //RSI Price
//---
input group "CCI";
input ushort CCIPeriod=14;                      //CCI Period
input ENUM_APPLIED_PRICE CCIPrice=PRICE_CLOSE;  //CCI Price
//---
input group "RVI";
input ushort RVIPeriod=14;                      //RVI Period
//---
input group "DeMarker";
input ushort DeMarkerPeriod=14;                 //DeMarker Period
//---
input group "Momentum";
input ushort MomentumPeriod=14;                 //Momentum Period
input ENUM_APPLIED_PRICE MomentumPrice=PRICE_CLOSE;   //Momentum Price
//---
input group "TriX";
input ushort TrixPeriod=14;                     //TriX Period
input ENUM_APPLIED_PRICE TrixPrice=PRICE_CLOSE; //TriX Price
//---
input group "MFI";
input ushort MFIPeriod=14;                      //MFI Period
input ENUM_APPLIED_VOLUME MFIVolume=VOLUME_TICK;//MFI Volume
//--- currencies to display
input group "Currencies";
input bool Auto=false;                          //Display chart currencies
input bool bAUD=true;                           //Display Aussie
input bool bCAD=true;                           //Display Loonie
input bool bCHF=true;                           //Display Swissy
input bool bEUR=true;                           //Display Fiber
input bool bGBP=true;                           //Display Sterling
input bool bJPY=true;                           //Display Yen
input bool bNZD=true;                           //Display Kiwi
input bool bXAU=true;                           //Display Gold
input bool bUSD=true;                           //Display Greenback
input string __;                                //---
input bool Pips=true;                           //Ticks on pip change only
//--- chart properties
long chartID;
int windowNo;
//--- symbols to use
string Symbols[indicator_handles]={"AUDUSD","USDCAD","USDCHF","EURUSD","GBPUSD","USDJPY","NZDUSD","XAUUSD"};
//--- currency names
string Currency[indicator_buffers];
//--- visibility flags
bool  IsVisible[indicator_buffers];
//---
#include <ChartObjects\ChartObjectsTxtControls.mqh>
CChartObjectLabel *lbl;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- symbols for indicators
   string Symbol[indicator_handles];
   chartID=ChartID();
//--- get necessary symbols
   for(int i=0;i<indicator_handles;i++)
     {
      Symbol[i]=Symbols[i]+Sfix;
      if(!SymbolSelect(Symbol[i],true) /*||  
         !SymbolIsSynchronized(Symbol[i])*/)
        {
         Alert(Symbol[i]," not available in Market Watch.\nInitialization Failed.");
         return(INIT_FAILED);
        }
     }
   string shortName;
//--- set indicator properties
   switch(Indicator)
     {
      case INDICATOR_MA:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iMA(Symbol[i],0,MAPeriod,PERIOD_CURRENT,MAMethod,MAPrice),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 %s(%d)",StringSubstr(EnumToString(MAMethod),5),MAPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,5);
         IndicatorSetInteger(INDICATOR_LEVELS,1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         break;
      case INDICATOR_MACD:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iMACD(Symbol[i],PERIOD_CURRENT,FastEMA,SlowEMA,9,MACDPrice),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 MACD(%d,%d)",FastEMA,SlowEMA);
         IndicatorSetInteger(INDICATOR_DIGITS,5);
         IndicatorSetInteger(INDICATOR_LEVELS,1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         break;
      case INDICATOR_STOCHASTIC:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iStochastic(Symbol[i],PERIOD_CURRENT,Kperiod,2,Slowing,MODE_SMA,PriceField),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 Stochastic(%d,%d)",Kperiod,Slowing);
         IndicatorSetInteger(INDICATOR_DIGITS,1);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1,indicator_level4);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level4);
         break;
      case INDICATOR_RSI:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iRSI(Symbol[i],PERIOD_CURRENT,RSIPeriod,RSIPrice),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 RSI(%d)",RSIPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,1);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1,indicator_level3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level3);
         break;
      case INDICATOR_CCI:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iCCI(Symbol[i],PERIOD_CURRENT,CCIPeriod,CCIPrice),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 CCI(%d)",CCIPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,0);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1,indicator_level5);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level5);
         break;
      case INDICATOR_RVI:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iRVI(Symbol[i],PERIOD_CURRENT,RVIPeriod),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 RVI(%d)",RVIPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,3);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1,indicator_level2);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level2);
         break;
      case INDICATOR_DEMARKER:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iDeMarker(Symbol[i],PERIOD_CURRENT,DeMarkerPeriod),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 DeMarker(%d)",DeMarkerPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,3);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1,indicator_level2);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level2);
         break;
      case INDICATOR_MOMENTUM:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iMomentum(Symbol[i],PERIOD_CURRENT,MomentumPeriod,MomentumPrice),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 Momentum(%d)",MomentumPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,3);
         IndicatorSetInteger(INDICATOR_LEVELS,1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         break;
      case INDICATOR_TRIX:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iTriX(Symbol[i],PERIOD_CURRENT,TrixPeriod,TrixPrice),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 TriX(%d)",TrixPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,5);
         IndicatorSetInteger(INDICATOR_LEVELS,1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         break;
      case INDICATOR_MFI:
         for(int i=0;i<indicator_handles;i++)
            if(!CheckPointer(indicator[i]=new CSymbol(Symbol[i])) || !indicator[i].Handle(iMFI(Symbol[i],PERIOD_CURRENT,MFIPeriod,MFIVolume),i))
               return(INIT_FAILED);
         shortName=StringFormat("Correl8 MFI(%d)",MFIPeriod);
         IndicatorSetInteger(INDICATOR_DIGITS,1);
         IndicatorSetInteger(INDICATOR_LEVELS,3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,0,indicator_level1);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,1,indicator_level3);
         IndicatorSetDouble(INDICATOR_LEVELVALUE,2,-indicator_level3);
     }
//--- set name & create labels
   IndicatorSetString(INDICATOR_SHORTNAME,shortName);
   windowNo=ChartWindowFind();
//--- indicator buffers mapping
   for(int i=0;i<indicator_buffers;i++)
     {
      if((currency[i]=new CBuffer)==NULL)
         return(INIT_FAILED);
      currency[i].SetIndexBuffer(i,INDICATOR_DATA);
      currency[i].ArraySetAsSeries(true);
      PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,EMPTY_VALUE);
     }
//--- currency labels
   string label;
   Currency[0]=label=indicator_label1;
   Currency[1]=label=indicator_label2;
   Currency[2]=label=indicator_label3;
   Currency[3]=label=indicator_label4;
   Currency[4]=label=indicator_label5;
   Currency[5]=label=indicator_label6;
   Currency[6]=label=indicator_label7;
   Currency[7]=label=indicator_label8;
   Currency[8]=label=indicator_label9;
//--- currencies to display
   IsVisible[0]=bAUD;
   IsVisible[1]=bCAD;
   IsVisible[2]=bCHF;
   IsVisible[3]=bEUR;
   IsVisible[4]=bGBP;
   IsVisible[5]=bJPY;
   IsVisible[6]=bNZD;
   IsVisible[7]=bXAU;
   IsVisible[8]=bUSD;
//--- display chart currencies
   if(Auto)
     {
      for(int i=0;i<indicator_plots;i++)
        { 
         IsVisible[i]=false;
         if(StringFind(_Symbol,Currency[i])!=-1)
            IsVisible[i]=true;
        }
     }
   if(!CheckPointer(lbl=new CChartObjectLabel))
      return(INIT_FAILED);
   CreateLabels();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---
   int toCount=(rates_total!=prev_calculated)?rates_total-prev_calculated:1;
//--- 
   if(!prev_calculated)
     {
//--- set initial bars to count and get bars/indicator calculated
      int barsTotal=MathMin(BarsToCount,rates_total),result=0;
      for(int i=0;i<indicator_handles;i++)
        { 
         if(!CheckPointer(ind=indicator[i]) || !ind.BarsCalculated())
            result++;
         if(barsTotal>ind.Bars)
            barsTotal=ind.Bars;
        }
      if(barsTotal<100 || result>0)
         return(0);
      for(int i=0;i<indicator_buffers;i++)
         if(CheckPointer(currency[i]))
            currency[i].ArrayInitialize(EMPTY_VALUE);
      toCount=barsTotal-1;
     }
//--- elements to copy/copied
   if(OnTick(toCount)!=toCount)
      return(0);
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- delete labels
   ObjectsDeleteAll(chartID,windowNo,OBJ_LABEL);
   if(CheckPointer(lbl))
      delete lbl;
//--- release OnTick indicators and delete pointers
   for(int i=0;i<indicator_handles;i++)
      if(CheckPointer(indicator[i]))
         delete indicator[i];
//--- delete currency pointers
   for(int i=0;i<indicator_buffers;i++)
      if(CheckPointer(currency[i]))
         delete currency[i];
//---
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define USDCAD 1
#define USDCHF 2
#define USDJPY 5
#define XAUUSD 7
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnTick(int to_count)
  {
   //--- copy indicator values to arrays
   for(int i=0;i<indicator_handles;i++)
      if(!CheckPointer(ind=indicator[i]) || ind.CopyBuffer(0,to_count+1)!=to_count+1)
        {
         printf("CopyBuffer for %s failed",Symbols[i]);
         return(0);
        }
//--- main loop for indicator calculation
   CBuffer *usd=currency[indicator_handles];
   for(int i=to_count-1,h;i>=0 && !_StopFlag;i--)
     {
      usd.close=0.0;
      for(h=0;h<indicator_handles;h++)
        {
         cur=currency[h];
         switch(Indicator)
           {
            case INDICATOR_MA:
              {
               double curClose=indicator[h][i],preClose=indicator[h][i+1];
               //--- get value for USDJPY
               if(h==USDJPY)
                  usd.close+=cur.close=curClose&&preClose?(preClose-curClose)/100:0.0;
               //--- get value for XAUUSD
               else if(h==XAUUSD)
                  usd.close+=cur.close=curClose&&preClose?(1000/preClose-1000/curClose):0.0;
               //--- invert USD based values
               else if(h==USDCAD || h==USDCHF)
                  usd.close+=cur.close=curClose&&preClose?(preClose-curClose):0.0;
               else
                  usd.close+=cur.close=curClose&&preClose?(1/preClose-1/curClose):0.0;
               break;
              }
            case INDICATOR_MACD:
               //--- get value for USDJPY
               if(h==USDJPY)
                  usd.close+=cur.close=-indicator[h][i]/100;
               //--- get value for XAUUSD
               else if(h==XAUUSD)
                  usd.close+=cur.close=indicator[h][i]/10000;
               //--- invert USD based values
               else if(h==USDCAD || h==USDCHF)
                  usd.close+=cur.close=-indicator[h][i];
               else   
                  usd.close+=cur.close=indicator[h][i];
               break;
            case INDICATOR_STOCHASTIC:
            case INDICATOR_RSI:
            case INDICATOR_MFI:
               //--- invert USD based values
               if(h==USDCAD || h==USDCHF || h==USDJPY)
                  usd.close+=cur.close=-(indicator[h][i]-50);
               //--- get value for each symbol
               else
                  usd.close+=cur.close=indicator[h][i]-50;
               break;
            case INDICATOR_CCI:
            case INDICATOR_RVI:
               //--- invert USD based values
               if(h==USDCAD || h==USDCHF || h==USDJPY)
                  usd.close+=cur.close=-indicator[h][i];
               //--- get value for each symbol
               else   
                  usd.close+=cur.close=indicator[h][i];
               break;
            case INDICATOR_DEMARKER:
               //--- invert USD based values
               if(h==USDCAD || h==USDCHF || h==USDJPY)
                  usd.close+=cur.close=-(indicator[h][i]-.50);
               //--- get value for each symbol
               else
                  usd.close+=cur.close=indicator[h][i]-.50;
               break;
            case INDICATOR_MOMENTUM:
               //--- invert USD based values
               if(h==USDCAD || h==USDCHF || h==USDJPY)
                  usd.close+=cur.close=-(indicator[h][i]-100);
               //--- get value for each symbol
               else
                  usd.close+=cur.close=indicator[h][i]-100;
               break;
            case INDICATOR_TRIX:
               //--- invert USD based values
               if(h==USDCAD || h==USDCHF || h==USDJPY)
                  usd.close+=cur.close=-indicator[h][i]*100;
               //--- get value for each symbol
               else
                  usd.close+=cur.close=indicator[h][i]*100;
           }
        }
      //--- calculate each currency's value
      for(h=0;h<indicator_handles;h++)
        {
         cur=currency[h]; 
         cur.close+=(usd.close-cur.close)/-(indicator_handles-1);
        }
      usd.close/=-indicator_handles;
      //--- assign currency value to buffer
      for(h=0;h<indicator_buffers;h++)
        { 
         cur=currency[h];
         cur.Close(i,IsVisible[h]?cur.close:EMPTY_VALUE);
        }
     }
//---
   return(to_count);
  }
//+------------------------------------------------------------------+
//| On chart event function                                          |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         
                  const long &lparam,   
                  const double &dparam, 
                  const string &sparam) 
  {
//--- check for incoming ticks
   if(id>=CHARTEVENT_CUSTOM)
     { 
      OnTick(int(lparam+1));
      if(lbl!=NULL)
         lbl.SetString(OBJPROP_TEXT,sparam);
      ChartRedraw(chartID);
     }
//---
  }
//+-------------------------------------------------------------------+
//| Create colored currency labels                                    |
//+-------------------------------------------------------------------+
void CreateLabels()
  {
//--- currency colors
   color Color[indicator_buffers]=
     {
      indicator_color1,indicator_color2,indicator_color3,
      indicator_color4,indicator_color5,indicator_color6,
      indicator_color7,indicator_color8,indicator_color9
     };
//--- x coordinates
   int xStart=4;
   int xIncrement=24;
//--- y coordinates
   int yStart=16;
   int yIncrement=0;
//--- create all labels
   for(int i=0;i<indicator_buffers;i++)
     {
      if(!IsVisible[i])
        { 
         PlotIndexSetInteger(i,PLOT_SHOW_DATA,false);
         continue; 
        }  
      PlotIndexSetInteger(i,PLOT_SHOW_DATA,true);
      ObjectCreate(Currency[i],xStart,yStart,Color[i]);
      xStart += xIncrement;
      yStart += yIncrement;
     }
//---
   lbl.Create(chartID,"Symbol",windowNo,5,20);
   lbl.Corner(CORNER_LEFT_LOWER);
   lbl.Color(clrWhite);
   lbl.SetString(OBJPROP_TEXT," ");
   lbl.Font("Arial Bold");
   lbl.FontSize(10);
  }
//+------------------------------------------------------------------+
//| Create label objects at coordinates                              |
//+------------------------------------------------------------------+
void ObjectCreate(string label,int x,int y,int clr)
  {
   string name=label+(string)windowNo;
   ObjectDelete(chartID,name);
   ObjectCreate(chartID,name,OBJ_LABEL,windowNo,0,0);
   ObjectSetString(chartID,name,OBJPROP_TEXT,label);
   ObjectSetString(chartID,name,OBJPROP_FONT,"Arial Bold");
   ObjectSetInteger(chartID,name,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(chartID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chartID,name,OBJPROP_YDISTANCE,y);
  }
//+------------------------------------------------------------------+
