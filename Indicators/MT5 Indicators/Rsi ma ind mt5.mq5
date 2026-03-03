//+------------------------------------------------------------------+
//|                                               Indicator: poo.mq5 |
//|                                       Created with EABuilder.com |
//|                                        https://www.eabuilder.com |
//+------------------------------------------------------------------+
#property copyright "*** Click here for more experts ***"
#property link      "https://www.google.com/search?q=forexeas+payhip&rlz=1C1CHBF_en-GBAU972AU972&sxsrf=APq-WBtD_BRErb2qCXBGJg8Yh8QJmO9hng%3A1647519330253&ei=YiYzYoH9DoK_4-EP78-ZuAw&ved=0ahUKEwiBtsLjj832AhWC3zgGHe9nBscQ4dUDCA4&uact=5&oq=forexeas+payhip&gs_lcp=Cgdnd3Mtd2l6EAMyBQghEKABMgUIIRCgAToHCAAQRxCwAzoICAAQCBANEB46BAgAEA06BggAEA0QHjoHCCEQChCgAUoECEEYAEoECEYYAFCZC1j6GGCuIGgBcAF4AIAB3QKIAYgQkgEFMi00LjOYAQCgAQHIAQjAAQE&sclient=gws-wiz"
#property version   "1.00"
#property description ""

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 4
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 4
#property indicator_color2 0x1212DE
#property indicator_label2 "Buy"

//--- indicator buffers
double Buffer1[];
double Buffer2[];

input int rsi = 14;
input double rsilvl = 30;
input double rsilvl2 = 70;
input int mabuy = 8;
input int masell = 8;
datetime time_alert; //used when sending alert
bool Send_Email = true;
bool Audible_Alerts = true;
bool Push_Notifications = true;
double myPoint; //initialized in OnInit
int RSI_handle;
double RSI[];
double Open[];
int MA_handle;
double MA[];
double Low[];
int MA_handle2;
double MA2[];
double High[];

void myAlert(string type, string message)
  {
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | poo @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
   else if(type == "indicator")
     {
      if(Audible_Alerts) Alert(type+" | poo @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Send_Email) SendMail("poo", type+" | poo @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      if(Push_Notifications) SendNotification(type+" | poo @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
  }

double CandlestickBodyLength(ENUM_TIMEFRAMES timeframe, int shift)
  {
   double cOpen[];
   CopyOpen(Symbol(), timeframe, shift, 1, cOpen);
   ArraySetAsSeries(cOpen, true);
   double cClose[];
   CopyClose(Symbol(), timeframe, shift, 1, cClose);
   ArraySetAsSeries(cClose, true);
   return(MathAbs(cOpen[0] - cClose[0]));
  }

double CandlestickUpperWick(ENUM_TIMEFRAMES timeframe, int shift)
  {
   double cHigh[];
   CopyHigh(Symbol(), timeframe, shift, 1, cHigh);
   ArraySetAsSeries(cHigh, true);
   double cOpen[];
   CopyOpen(Symbol(), timeframe, shift, 1, cOpen);
   ArraySetAsSeries(cOpen, true);
   double cClose[];
   CopyClose(Symbol(), timeframe, shift, 1, cClose);
   ArraySetAsSeries(cClose, true);
   return(cHigh[0] - MathMax(cOpen[0], cClose[0]));
  }

double CandlestickLowerWick(ENUM_TIMEFRAMES timeframe, int shift)
  {
   double cLow[];
   CopyLow(Symbol(), timeframe, shift, 1, cLow);
   ArraySetAsSeries(cLow, true);
   double cOpen[];
   CopyOpen(Symbol(), timeframe, shift, 1, cOpen);
   ArraySetAsSeries(cOpen, true);
   double cClose[];
   CopyClose(Symbol(), timeframe, shift, 1, cClose);
   ArraySetAsSeries(cClose, true);
   return(MathMin(cOpen[0], cClose[0]) - cLow[0]);
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   SetIndexBuffer(0, Buffer1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_ARROW, 241);
   SetIndexBuffer(1, Buffer2);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(1, PLOT_ARROW, 242);
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
     }
   RSI_handle = iRSI(NULL, PERIOD_CURRENT, rsi, PRICE_CLOSE);
   if(RSI_handle < 0)
     {
      Print("The creation of iRSI has failed: RSI_handle=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   MA_handle = iMA(NULL, PERIOD_CURRENT, mabuy, 0, MODE_SMA, PRICE_CLOSE);
   if(MA_handle < 0)
     {
      Print("The creation of iMA has failed: MA_handle=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   MA_handle2 = iMA(NULL, PERIOD_CURRENT, masell, 0, MODE_SMA, PRICE_CLOSE);
   if(MA_handle2 < 0)
     {
      Print("The creation of iMA has failed: MA_handle2=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   ArraySetAsSeries(Buffer2, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
      ArrayInitialize(Buffer2, EMPTY_VALUE);
     }
   else
      limit++;
   datetime Time[];
   
   if(BarsCalculated(RSI_handle) <= 0) 
      return(0);
   if(CopyBuffer(RSI_handle, 0, 0, rates_total, RSI) <= 0) return(rates_total);
   ArraySetAsSeries(RSI, true);
   if(CopyOpen(Symbol(), PERIOD_CURRENT, 0, rates_total, Open) <= 0) return(rates_total);
   ArraySetAsSeries(Open, true);
   if(BarsCalculated(MA_handle) <= 0) 
      return(0);
   if(CopyBuffer(MA_handle, 0, 0, rates_total, MA) <= 0) return(rates_total);
   ArraySetAsSeries(MA, true);
   if(CopyLow(Symbol(), PERIOD_CURRENT, 0, rates_total, Low) <= 0) return(rates_total);
   ArraySetAsSeries(Low, true);
   if(BarsCalculated(MA_handle2) <= 0) 
      return(0);
   if(CopyBuffer(MA_handle2, 0, 0, rates_total, MA2) <= 0) return(rates_total);
   ArraySetAsSeries(MA2, true);
   if(CopyHigh(Symbol(), PERIOD_CURRENT, 0, rates_total, High) <= 0) return(rates_total);
   ArraySetAsSeries(High, true);
   if(CopyTime(Symbol(), Period(), 0, rates_total, Time) <= 0) return(rates_total);
   ArraySetAsSeries(Time, true);
   //--- main loop
   for(int i = limit-1; i >= 0; i--)
     {
      if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      
      //Indicator Buffer 1
      if(RSI[i] < rsilvl //Relative Strength Index < fixed value
      && RSI[1+i] <= RSI[2+i] //Relative Strength Index <= Relative Strength Index
      && CandlestickUpperWick(PERIOD_CURRENT, 1+i) >= CandlestickBodyLength(PERIOD_CURRENT, 1+i) //Candlestick Upper Wick >= Candlestick Body
      && Open[1+i] >= MA[i] //Candlestick Open >= Moving Average
      )
        {
         Buffer1[i] = Low[i]; //Set indicator value at Candlestick Low
         if(i == 1 && Time[1] != time_alert) myAlert("indicator", "Buy"); //Alert on next bar open
         time_alert = Time[1];
        }
      else
        {
         Buffer1[i] = EMPTY_VALUE;
        }
      //Indicator Buffer 2
      if(RSI[i] > rsilvl2 //Relative Strength Index > fixed value
      && RSI[1+i] >= RSI[2+i] //Relative Strength Index >= Relative Strength Index
      && CandlestickLowerWick(PERIOD_CURRENT, 1+i) >= CandlestickBodyLength(PERIOD_CURRENT, 1+i) //Candlestick Lower Wick >= Candlestick Body
      && Open[1+i] <= MA2[i] //Candlestick Open <= Moving Average
      )
        {
         Buffer2[i] = High[i]; //Set indicator value at Candlestick High
         if(i == 1 && Time[1] != time_alert) myAlert("indicator", "Buy"); //Alert on next bar open
         time_alert = Time[1];
        }
      else
        {
         Buffer2[i] = EMPTY_VALUE;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+