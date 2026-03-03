//+------------------------------------------------------------------+
//|                                                MultiCurrency.mq5 |
//|                               Copyright © 2012, Nikolay Kositsin |
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "2012,   Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
#property version   "1.00"

//---- drawing the indicator in the main window
#property indicator_chart_window
//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS     |
//+-----------------------------------+
input bool ShowIndicator1=true; //permission to display the indicator            
input string Symbol1="EURUSD"; //currency
input bool Direct1=true;//no chart inversion

input bool ShowIndicator2=true; //permission to display the indicator            
input string Symbol2="GBPUSD"; //currency
input bool Direct2=true;//no chart inversion

input bool ShowIndicator3=true; //permission to display the indicator            
input string Symbol3="AUDUSD"; //currency
input bool Direct3=true;//no chart inversion

input bool ShowIndicator4=true; //permission to display the indicator            
input string Symbol4="NZDUSD"; //currency
input bool Direct4=true;//no chart inversion

input bool ShowIndicator5=true; //permission to display the indicator            
input string Symbol5="USDCHF"; //currency
input bool Direct5=false;//no chart inversion

input bool ShowIndicator6=true; //permission to display the indicator            
input string Symbol6="USDJPY"; //currency
input bool Direct6=false;//no chart inversion

input bool ShowIndicator7=true; //permission to display the indicator            
input string Symbol7="USDCAD"; //currency
input bool Direct7=false;//no chart inversion

input bool ShowIndicator8=true; //permission to display the indicator            
input string Symbol8="XAUUSD"; //currency
input bool Direct8=true;//no chart inversion
//+------------------------------------------------------------------+
//| Include the CChart class in the Expert Advisor                        |
//+------------------------------------------------------------------+
#include <Charts\Chart.mqh>
//---- declaration of the global variable of the CChart type
CChart cchart[8];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- 
   int digit,InpInd_Handle,count=0;

//---- getting the indicator handle
   if(ShowIndicator1)
     {
      digit=int(SymbolInfoInteger(Symbol1,SYMBOL_DIGITS));
      InpInd_Handle=iCustom(Symbol(),PERIOD_CURRENT,"CrossIndex",Symbol1,clrRed,STYLE_SOLID,PRICE_CLOSE,digit,Direct1);
      if(InpInd_Handle==INVALID_HANDLE) Print(" Failed to get the CrossIndex indicator handle by ",Symbol1);
     }

//--- instruct the cchart object to work with the current (ID=0) chart where the Expert Advisor is launched
   cchart[count].Attach(0);

//--- reset the error code to zero
   ResetLastError();

//---- add the indicator to the chart  
   if(!cchart[count].IndicatorAdd(count+1,InpInd_Handle)) Print(" Failed to add the CrossIndex indicator by ",Symbol1);

//---- getting the indicator handle
   if(ShowIndicator2)
     {
      digit=int(SymbolInfoInteger(Symbol2,SYMBOL_DIGITS));
      InpInd_Handle=iCustom(Symbol(),PERIOD_CURRENT,"CrossIndex",Symbol2,clrRed,STYLE_SOLID,PRICE_CLOSE,digit,Direct2);
      if(InpInd_Handle==INVALID_HANDLE) Print(" Failed to get the CrossIndex indicator handle by ",Symbol2);
     }

   count++;

//--- instruct the cchart object to work with the current (ID=0) chart where the Expert Advisor is launched
   cchart[count].Attach(0);

//--- reset the error code to zero
   ResetLastError();

//---- add the indicator to the chart  
   if(!cchart[count].IndicatorAdd(count+1,InpInd_Handle)) Print(" Failed to add the CrossIndex indicator by ",Symbol2);

//---- getting the indicator handle
   if(ShowIndicator3)
     {
      digit=int(SymbolInfoInteger(Symbol3,SYMBOL_DIGITS));
      InpInd_Handle=iCustom(Symbol(),PERIOD_CURRENT,"CrossIndex",Symbol3,clrRed,STYLE_SOLID,PRICE_CLOSE,digit,Direct3);
      if(InpInd_Handle==INVALID_HANDLE) Print(" Failed to get the CrossIndex indicator handle by ",Symbol3);
     }

   count++;

//--- instruct the cchart object to work with the current (ID=0) chart where the Expert Advisor is launched
   cchart[count].Attach(0);

//--- reset the error code to zero
   ResetLastError();

//---- add the indicator to the chart  
   if(!cchart[count].IndicatorAdd(count+1,InpInd_Handle)) Print(" Failed to add the CrossIndex indicator by ",Symbol3);

//---- getting the indicator handle
   if(ShowIndicator4)
     {
      digit=int(SymbolInfoInteger(Symbol4,SYMBOL_DIGITS));
      InpInd_Handle=iCustom(Symbol(),PERIOD_CURRENT,"CrossIndex",Symbol4,clrRed,STYLE_SOLID,PRICE_CLOSE,digit,Direct4);
      if(InpInd_Handle==INVALID_HANDLE) Print(" Failed to get the CrossIndex indicator handle by ",Symbol4);
     }

   count++;

//--- instruct the cchart object to work with the current (ID=0) chart where the Expert Advisor is launched
   cchart[count].Attach(0);

//--- reset the error code to zero
   ResetLastError();

//---- add the indicator to the chart  
   if(!cchart[count].IndicatorAdd(count+1,InpInd_Handle)) Print(" Failed to add the CrossIndex indicator by ",Symbol4);

//---- getting the indicator handle
   if(ShowIndicator5)
     {
      digit=int(SymbolInfoInteger(Symbol5,SYMBOL_DIGITS));
      InpInd_Handle=iCustom(Symbol(),PERIOD_CURRENT,"CrossIndex",Symbol5,clrRed,STYLE_SOLID,PRICE_CLOSE,digit,Direct5);
      if(InpInd_Handle==INVALID_HANDLE) Print(" Failed to get the CrossIndex indicator handle by ",Symbol5);
     }

   count++;

//--- instruct the cchart object to work with the current (ID=0) chart where the Expert Advisor is launched
   cchart[count].Attach(0);

//--- reset the error code to zero
   ResetLastError();

//---- add the indicator to the chart  
   if(!cchart[count].IndicatorAdd(count+1,InpInd_Handle)) Print(" Failed to add the CrossIndex indicator by ",Symbol5);

//---- getting the indicator handle
   if(ShowIndicator6)
     {
      digit=int(SymbolInfoInteger(Symbol6,SYMBOL_DIGITS));
      InpInd_Handle=iCustom(Symbol(),PERIOD_CURRENT,"CrossIndex",Symbol6,clrRed,STYLE_SOLID,PRICE_CLOSE,digit,Direct6);
      if(InpInd_Handle==INVALID_HANDLE) Print(" Failed to get the CrossIndex indicator handle by ",Symbol6);
     }

   count++;

//--- instruct the cchart object to work with the current (ID=0) chart where the Expert Advisor is launched
   cchart[count].Attach(0);

//--- reset the error code to zero
   ResetLastError();

//---- add the indicator to the chart  
   if(!cchart[count].IndicatorAdd(count+1,InpInd_Handle)) Print(" Failed to add the CrossIndex indicator by ",Symbol6);

//---- getting the indicator handle
   if(ShowIndicator7)
     {
      digit=int(SymbolInfoInteger(Symbol7,SYMBOL_DIGITS));
      InpInd_Handle=iCustom(Symbol(),PERIOD_CURRENT,"CrossIndex",Symbol7,clrRed,STYLE_SOLID,PRICE_CLOSE,digit,Direct7);
      if(InpInd_Handle==INVALID_HANDLE) Print(" Failed to get the CrossIndex indicator handle by ",Symbol7);
     }

   count++;

//--- instruct the cchart object to work with the current (ID=0) chart where the Expert Advisor is launched
   cchart[count].Attach(0);

//--- reset the error code to zero
   ResetLastError();

//---- add the indicator to the chart  
   if(!cchart[count].IndicatorAdd(count+1,InpInd_Handle)) Print(" Failed to add the CrossIndex indicator by ",Symbol7);

//---- getting the indicator handle
   if(ShowIndicator8)
     {
      digit=int(SymbolInfoInteger(Symbol8,SYMBOL_DIGITS));
      InpInd_Handle=iCustom(Symbol(),PERIOD_CURRENT,"CrossIndex",Symbol8,clrRed,STYLE_SOLID,PRICE_CLOSE,digit,Direct8);
      if(InpInd_Handle==INVALID_HANDLE) Print(" Failed to get the CrossIndex indicator handle by ",Symbol8);
     }

   count++;

//--- instruct the cchart object to work with the current (ID=0) chart where the Expert Advisor is launched
   cchart[count].Attach(0);

//--- reset the error code to zero
   ResetLastError();

//---- add the indicator to the chart  
   if(!cchart[count].IndicatorAdd(count+1,InpInd_Handle)) Print(" Failed to add the CrossIndex indicator by ",Symbol8);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // history in bars at the current tick
                const int prev_calculated,// history in bars at the previous tick
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
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
