//+------------------------------------------------------------------+
//|                                                 Ind_2 Line+1.mq5 |
//|                                 Copyright 2012, Evgeniy Trofimov |
//|                        https://login.mql5.com/ru/users/EvgeTrofi |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Evgeniy Trofimov"
#property link      "https://login.mql5.com/ru/users/EvgeTrofi"
#property version   "1.00"
#property description "Indicator of arbitration situations for the spread, which consists of two instruments."
#property description "The main idea is belong to traders leonid553 & Son_Of_Earth"
#property description "A huge THANK YOU to them for that!!!"
#property description " "
#property description "Holes in the history of the instruments for the current chart filled with previous values. This calculation conception is explained by the assumption that if the exchange of one instrument is not working that the price is frozen. Similar to the rate of the dollar on the Russian exchange."
#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots  3
#property indicator_type1  DRAW_LINE
#property indicator_type2  DRAW_LINE
#property indicator_type3  DRAW_COLOR_LINE
//#property indicator_type4  DRAW_SECTION
//#property indicator_label4 "Lot"
#property indicator_color1 clrLime
#property indicator_color2 clrDodgerBlue
#property indicator_color3 clrRed, clrDarkTurquoise
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 1

#include <MovingAverages.mqh>
#include <EvgeTrofi\MoneyManagment.mqh>

enum ENUM_VOL_TYPE{                //Mode to calculate the volumes of trade
   VOL_PRICE_OPEN = 1,             //by open prices
   VOL_VOL_OR_PRICE = 2,           //by volatility, and if it is impossible - by open prices
   VOL_VOL_AND_PRICE = 3           //by volatility (if it is possible) and open prices
};

input string Symbol1_Name = "EURUSD";     //Main instrument
input bool   Symbol1_Reverse = false;     //Reverse correlation 

input string Symbol2_Name = "GBPUSD";     //Indirect instrument
input bool   Symbol2_Reverse = false;     //Reverse correlation 

input bool   UseVolatility  = true ;      //Draw considering volatility

input ENUM_VOL_TYPE VOL_Mode = 3;         //Mode to calculate the volumes of trade
                                           
input int VOL_PeriodATR = 144;            //ATR averaging period 

input int MA_Slow = 21;                   //Slow MA period
input int MA_Fast = 8;                    //Fast MA period
input ENUM_MA_METHOD MA_Method=MODE_SMMA;  //method of approximation
                                           // - MODE_SMA=0 Simple Moving Average 
                                           // - MODE_EMA=1 Exponential Moving Average 
                                           // - MODE_SMMA=2 Smoothed Moving Average 
                                           // - MODE_LWMA=3 Linear Weighted Moving Average 
input ENUM_APPLIED_PRICE MA_Price=PRICE_WEIGHTED;            //Calculated price
                                           // - PRICE_CLOSE=0 Close price 
                                           // - PRICE_OPEN=1 Open price 
                                           // - PRICE_HIGH=2 Maximal price 
                                           // - PRICE_LOW=3 Minimal price 
                                           // - PRICE_MEDIAN=4 Average price, (high+low)/2 
                                           // - PRICE_TYPICAL=5 Typical price, (high+low+close)/3 
                                           // - PRICE_WEIGHTED=6 Weighted close price, (high+low+close+close)/4 
//input int Count_Equity = 144;               //The number of candlesticks to calculate a profit
//input int MA_Equity = 12;                 //Averaging of calculated lot

// Buffers for display data
double Buf1[];    // First instrument
double Buf2[];    // Second instrument
double BufW[];    // Channel width
double BufW_Clr[];// Channel color
//double BufLot[];  // Volume of indirect instrument
//double BufProfit[];  // Relation of the first instrument equity to the second instrument equity

double         bufPrice1[];
double         bufPrice2[];
MqlRates       tmpSymbol1[];
MqlRates       tmpSymbol2[];
datetime       curTime[];
double MAFastSym1[], MAFastSym2[], MASlowSym1[], MASlowSym2[];

// Global variables
const int EMPTY = -1;
string InpSymbol1, InpSymbol2;             // Instruments names without register
double kPrice1,kPrice2;                    // Weight coefficients of the price charts
double kVol1,kVol2;                        // Balance is changed if the instrument price is changed 
                                           // by the one in the quote currency with the volume as the one lot
int hATR1;                                 // ATR indicator handle for the instrument 1
int hATR2;                                 // ATR indicator handle for the instrument 2
string Label_Name = "label";  
string Indic_Name = "Ind_2 Line+1";
input color  Label_Color = clrTeal;
int wndNum;                                // number of indicator subwindow
string wndName;                            // window name

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(){
  CMoneyManagment MM;
  
  // The names of instruments are made insensitive to register
  InpSymbol1=StringUpper(Symbol1_Name);
  InpSymbol2=StringUpper(Symbol2_Name);

  // Determining a balance coefficients of each instrument
  if(SymbolInfoDouble(InpSymbol1,SYMBOL_TRADE_TICK_SIZE)==0) {
     Print("The zero TICK_SIZE value for the instrument ", InpSymbol1,". Perhaps the instrument is specified incorrectly!");
     return(-1);
  }
  kVol1=MM.TickValue(InpSymbol1)/SymbolInfoDouble(InpSymbol1,SYMBOL_TRADE_TICK_SIZE);
  //Print("TickValue("+InpSymbol1+") = ", DoubleToString(MM.TickValue(InpSymbol1)));
  //Print("TickSize("+InpSymbol1+") = ", DoubleToString(SymbolInfoDouble(InpSymbol1,SYMBOL_TRADE_TICK_SIZE)));
  if(SymbolInfoDouble(InpSymbol2,SYMBOL_TRADE_TICK_SIZE)==0) {
     Print("The zero TICK_SIZE value for the instrument ", InpSymbol2,". Perhaps the instrument is specified incorrectly!");
     return(-1);
  }
  kVol2=MM.TickValue(InpSymbol2)/SymbolInfoDouble(InpSymbol2,SYMBOL_TRADE_TICK_SIZE);
  //Print("TickValue("+InpSymbol2+") = ", DoubleToString(MM.TickValue(InpSymbol2)));
  //Print("TickSize("+InpSymbol2+") = ", DoubleToString(SymbolInfoDouble(InpSymbol2,SYMBOL_TRADE_TICK_SIZE)));
  //Print("kVol = ", kVol1,", kVol2 = ", kVol2);

//--- indicator buffers mapping
   SetIndexBuffer(0,Buf1,INDICATOR_DATA);
   SetIndexBuffer(1,Buf2,INDICATOR_DATA);
   SetIndexBuffer(2,BufW,INDICATOR_DATA);
   SetIndexBuffer(3,BufW_Clr,INDICATOR_COLOR_INDEX);
//   SetIndexBuffer(4,BufLot,INDICATOR_DATA);
   SetIndexBuffer(4,bufPrice1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,bufPrice2,INDICATOR_CALCULATIONS);   
   SetIndexBuffer(6,MAFastSym1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,MAFastSym2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,MASlowSym1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,MASlowSym2,INDICATOR_CALCULATIONS);
//   SetIndexBuffer(11,BufProfit,INDICATOR_CALCULATIONS);
   
   
   IndicatorSetString(INDICATOR_SHORTNAME, Indic_Name);
   PlotIndexSetString(0, PLOT_LABEL, InpSymbol1);
   PlotIndexSetString(1, PLOT_LABEL, InpSymbol2);
   PlotIndexSetString(2, PLOT_LABEL, "Width");   
   //ArrayInitialize(curTime,0);
   //ArrayInitialize(bufTime2,0);
   //ArrayInitialize(tmpPrice,0);
   
   hATR1 = iATR(InpSymbol1, Period(), VOL_PeriodATR);
   hATR2 = iATR(InpSymbol2, Period(), VOL_PeriodATR);
//---
   return(0);
}//OnInit()
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
  DeleteObject(InpSymbol1);
  DeleteObject(InpSymbol2); 
  DeleteObject(Label_Name);
}//OnDeinit()
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[]){
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//---
   if(CopyTime(Symbol(), Period(), 0, to_copy, curTime)<=0){
      Print("Getting Time "+Symbol()+" is failed! Error ",GetLastError());
      return(0);
   }
   if(IsStopped()) return(0); //Checking for stop flag
   int i = ArraySize(curTime)-1; //The oldest candle in the array of dates
   if(CopyRates(InpSymbol1, Period(), curTime[0], curTime[i], tmpSymbol1)<=0){
      Print("Getting Rates "+InpSymbol1+" is failed! Error ",GetLastError());
      return(0);
   }
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyRates(InpSymbol2, Period(), curTime[0], curTime[i], tmpSymbol2)<=0){
      Print("Getting Rates "+InpSymbol2+" is failed! Error ",GetLastError());
      return(0);
   }
   if(IsStopped()) return(0); //Checking for stop flag
   double ATR1[], ATR2[];
   if(CopyBuffer(hATR1, 0, 1, 1, ATR1)<=0){
      Print("Failed to load the ATR indicator for the symbol "+InpSymbol1);
      return(0);
   }
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(hATR2, 0, 1, 1, ATR2)<=0){
      Print("Failed to load the ATR indicator for the symbol "+InpSymbol2);
      return(0);
   }   
   if(IsStopped()) return(0); //Checking for stop flag
//--- Synchronization of history data
   int limit;
   int j, k;
   if(prev_calculated==0)
      limit=0;
   else limit=prev_calculated-1;
   j=limit;
   k=limit;
   for(i=limit;i<rates_total && !IsStopped();i++){ //The movement from the old candle to the new of the current chart
      if(j>=ArraySize(tmpSymbol1)) break;
      while(curTime[i]>tmpSymbol1[j].time && !IsStopped() && j<ArraySize(tmpSymbol1)-1){
         j++; //Hole in the history of the current chart
      }
      if(k>=ArraySize(tmpSymbol2)) break;
      while(curTime[i]>tmpSymbol2[k].time && !IsStopped() && k<ArraySize(tmpSymbol2)-1){
         k++; //Hole in the history of the current chart
      }
      if(curTime[i]<tmpSymbol1[j].time) {
         if(i>0) //Hole in the instrument 1history
            bufPrice1[i]=bufPrice1[i-1];
         else
            bufPrice1[i]=0;
      }else{
         bufPrice1[i]=CalcPrice(MA_Price, tmpSymbol1[j].open, tmpSymbol1[j].close, tmpSymbol1[j].high, tmpSymbol1[j].low);
      }
      if(curTime[i]<tmpSymbol2[k].time) {
         if(i>0) //Hole in the instrument 2 history
            bufPrice2[i]=bufPrice2[i-1];
         else
            bufPrice2[i]=0;
      }else{
         bufPrice2[i]=CalcPrice(MA_Price, tmpSymbol2[k].open, tmpSymbol2[k].close, tmpSymbol2[k].high, tmpSymbol2[k].low);
      }
   }//Next i
//--- Calculation of the zero candle
   j = ArraySize(tmpSymbol1)-1;
   k = ArraySize(tmpSymbol2)-1;
   bufPrice1[rates_total-1]=CalcPrice(MA_Price, tmpSymbol1[j].open, tmpSymbol1[j].close, tmpSymbol1[j].high, tmpSymbol1[j].low);
   bufPrice2[rates_total-1]=CalcPrice(MA_Price, tmpSymbol2[k].open, tmpSymbol2[k].close, tmpSymbol2[k].high, tmpSymbol2[k].low);
//--- prices is synchronized. Turn to the main calculation of the indicator
  //------------------------------------------------------------------ 
  // Define the parameters of window of the indicator
  wndNum=ChartWindowFind(0, Indic_Name);
  wndName=Indic_Name+IntegerToString(wndNum); 
  // Calculation of price coefficients by scaling
  // inverse proportion to the current price
  kPrice1=100; 
  kPrice2=kPrice1/tmpSymbol2[k].open*tmpSymbol1[j].open; 
  // If the price chart is reversible to other instruments 
  // (for example, falls when other instruments are growing)
  // then unwrap it.
  int kP1=1;
  int kP2=1;
  
  if(Symbol1_Reverse)  kP1=-1;
  if(Symbol2_Reverse)  kP2=-1;
  kPrice1=kP1*kPrice1;
  kPrice2=kP2*kPrice2;
  //--------------------------------------------------------------------  
  // Calculation of volume ratios to trade.
  // There is calculated the relative (not absolute) values, which given
  // to the first instrument. In determining the absolute volumes, based
  // on the selected model of money managment, it is should be to save 
  // the calculated proportions.
  
  double volA1=1, volA2=EMPTY,     // Volume, calculated by volatility
         volP1=1, volP2=EMPTY,     // Volume, calculated by open price
         var1;
   
   //Protection of indicator from the critical error of division by zero (zero divide)
   if(kVol2==0 || ATR2[0]==0 || tmpSymbol2[k].open==0) return(0);
   
  // If the volatility will be used, calculate the volumes by it
  if((VOL_Mode==VOL_VOL_OR_PRICE || VOL_Mode==VOL_VOL_AND_PRICE) && 
     Bars(InpSymbol1,Period())>VOL_PeriodATR &&     // If there are enough bars in history for calculation of volatility?
     Bars(InpSymbol2,Period())>VOL_PeriodATR) {
    var1=volA1*kVol1*ATR1[0];
    volA2=var1/kVol2/ATR2[0];
  }
  // If the opening price will be used, calculate the volumes by it
  if(VOL_Mode==VOL_PRICE_OPEN || VOL_Mode==VOL_VOL_AND_PRICE || volA2==EMPTY) {
    var1=volP1*kVol1*tmpSymbol1[j].open;
    volP2=var1/kVol2/tmpSymbol2[k].open;
  } 
  
  //------------------------------------------------------------------ 
  // Calculation of moving averages
   if(IsStopped()) return(0); //Checking for stop flag
   static int weightfast1,weightfast2,weightslow1,weightslow2; //,weightprofit;
   AverageOnArray(MA_Method, rates_total, prev_calculated, 0, MA_Fast, bufPrice1, MAFastSym1, weightfast1);
   AverageOnArray(MA_Method, rates_total, prev_calculated, 0, MA_Slow, bufPrice1, MASlowSym1, weightslow1);
   AverageOnArray(MA_Method, rates_total, prev_calculated, 0, MA_Fast, bufPrice2, MAFastSym2, weightfast2);
   AverageOnArray(MA_Method, rates_total, prev_calculated, 0, MA_Slow, bufPrice2, MASlowSym2, weightslow2);
   // drawing a price lines
   for(i=limit;i<rates_total && !IsStopped();i++){
    // The first price chart
      Buf1[i] = kPrice1 * (MAFastSym1[i] - MASlowSym1[i]);
    // Calculation of equity chart by the Count_Equity candles
    /*
      if(i>=Count_Equity) {
         BufProfit[i]=(kP1*(MathAbs(bufPrice1[i]-bufPrice1[i-Count_Equity]))*kVol1)/
                      (kP2*(MathAbs(bufPrice2[i]-bufPrice2[i-Count_Equity]))*kVol2);
         if(MathAbs(BufProfit[i])>10) BufProfit[i]=1;
      } else {
         BufProfit[i]=1;                      
      }
    */
    // The second price chart
      if (!UseVolatility) {
         Buf2[i] = kPrice2 * (MAFastSym2[i] - MASlowSym2[i]);
      }else if(volA2!=EMPTY){
         Buf2[i] = kPrice2 * volA2 * (MAFastSym2[i]-MASlowSym2[i]);
      }                   
                          
    // Chart of the price channel width
      BufW[i] = Buf1[i] - Buf2[i];
    // Share the channel to ascending and descending channels
      if(i>0){
         if(MathAbs(BufW[i])>MathAbs(BufW[i-1])) {
            BufW_Clr[i]=1;
         } else {
            BufW_Clr[i]=0;
         }
      }
   } // End of the block of price lines drawing
   //AverageOnArray(MA_Method, rates_total, prev_calculated, 0, MA_Equity, BufProfit, BufLot, weightprofit);
 //------------------------------------------------------------------------
   if(MQL5InfoInteger(MQL5_OPTIMIZATION)) return(rates_total);
   i = rates_total-1;
   // Drawing of chart objects
   // Write a comment on the indicator window to the right
   string sVolA1="",sVolA2="",sVolP1="",sVolP2="";
   if(volP2!=EMPTY) { //Volume by open price
    sVolP1=DoubleToString(volP1,2)+"= ";
    sVolP2=DoubleToString(volP2,2)+"= ";
   }
   if(volA2!=EMPTY) { //Volume by volatility
    sVolA1=" ="+DoubleToString(volA1,2);
    sVolA2=" ="+DoubleToString(volA2,2);
   }
   
   DrawLabel(InpSymbol1, sVolP1+InpSymbol1+sVolA1, 10, PlotIndexGetInteger(0, PLOT_LINE_COLOR), 5);
   DrawLabel(InpSymbol2, sVolP2+InpSymbol2+sVolA2, 10, PlotIndexGetInteger(1, PLOT_LINE_COLOR),18);
   
   // Display the convergence, divergence and flat lines                       
   string label;                     
   // Define the convergence-divergence by the three consistent formed bars
   if(MathAbs(BufW[i-2])>MathAbs(BufW[i-1]) && MathAbs(BufW[i-3])>MathAbs(BufW[i-2]))     // convergence
      label = "Convergence";
   else if(MathAbs(BufW[i-2])<MathAbs(BufW[i-1]) && MathAbs(BufW[i-3])<MathAbs(BufW[i-2])) // divergence
      label = "Divergence";
   else 
      label = "Flat";                       // flat
   DrawLabel(Label_Name, label, 9, Label_Color, 31); 
   
//--- return value of prev_calculated for next call
   return(rates_total);
}//OnCalculate()
//+------------------------------------------------------------------+
// Convert the string to uppercase
string StringUpper(string s) {
  int i, k=StringLen(s);
  ushort c, n;
  for (i=0; i<k; i++) {
    n=0;
    c=StringGetCharacter(s, i);
    if (c>96 && c<123) n=c-32;    // a-z -> A-Z
    if (c>223 && c<256) n=c-32;   // à-ÿ -> À-ß
    if (c==184) n=168;            //  ¸  ->  ¨
    if (n>0) StringSetCharacter(s, i, n);
  }
  return(s);
}//StringUpper()
//+------------------------------------------------------------------+
// Calculate the right price, depending on the MA_Price version
double CalcPrice(ENUM_APPLIED_PRICE inType, double inOpen=0, double inClose=0, double inHigh=0, double inLow=0){
   switch(inType){
      case PRICE_CLOSE:
        return(inClose);
      case PRICE_HIGH:
        return(inHigh);
      case PRICE_OPEN:
        return(inOpen);
      case PRICE_LOW:
        return(inLow);
      case PRICE_MEDIAN:
        return((inHigh+inLow)/2);
      case PRICE_TYPICAL:
        return((inHigh+inLow+inClose)/3);
      case PRICE_WEIGHTED:
        return((inHigh+inLow+inOpen+inClose)/4);
      default:
        return(0);
   }
}//CalcPrice()
//+------------------------------------------------------------------+
// Draw label
void DrawLabel(string aName, string aText, int aFontSize, color aColor, int aValue) {
   string objName=aName+wndName;
   //ObjectDelete(0, objName);
   if(ObjectFind(0 ,objName)<0){
      ObjectCreate(0, objName, OBJ_LABEL, wndNum, 0, 0);
      ObjectSetString(0, objName, OBJPROP_FONT, "Verdana");
      ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, 150);
   }
   ObjectSetString(0, objName, OBJPROP_TEXT, aText);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, aFontSize);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, aColor);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, aValue); 
}
// Delete the chart object
void DeleteObject(string name) {
  ObjectDelete(0, name+wndName);
}
//+------------------------------------------------------------------+
//| calculate average on array                                       |
//+------------------------------------------------------------------+
void AverageOnArray(const int mode,const int rates_total,const int prev_calculated,const int begin,
                    const int period,const double& source[],double& destination[],int &weightsum)
  {
   switch(mode)
     {
      case MODE_EMA:
         ExponentialMAOnBuffer(rates_total,prev_calculated,begin,period,source,destination);
         break;
      case MODE_SMMA:
         SmoothedMAOnBuffer(rates_total,prev_calculated,begin,period,source,destination);
         break;
      case MODE_LWMA:
         LinearWeightedMAOnBuffer(rates_total,prev_calculated,begin,period,source,destination,weightsum);
         break;
      default:
         SimpleMAOnBuffer(rates_total,prev_calculated,begin,period,source,destination);
     }
  }
