//+------------------------------------------------------------------+
//|                                                 pos_size.mq[4|5] |
//|                                       Copyright 2018, Silverapex |
//|                                         https://silverapex.co.uk |
//|                                                                  |
//| 2.01 Both MT4 and MT5, and small tweaks.         Chris Plewright |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Silverapex"
#property link      "https://silverapex.co.uk"
#property version   "2.01"
#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   0

input int               InpATRperiod=14;         // ATR Periods
input double            InpRiskPC=2.0;           // Risk Size %
input double            InpSLfactor=1.5;         // Stop Loss as a factor of ATR
input double            InpTPfactor=1.0;         // Take Profit as a factor of ATR
input int               InpFontSize=9;           // Font size
input color             InpColor=clrMagenta;     // Color
input ENUM_BASE_CORNER  InpBaseCorner=CORNER_RIGHT_UPPER; // Corner
input double            InpFixedATR=0;           // Fixed ATR points
input bool              InpBack=false;           // Background object
input bool              InpSelection=false;      // Highlight to move
input bool              InpHidden=true;          // Hidden in the object list
input long              InpZOrder=0;             // Priority for mouse click

string AccntC=AccountInfoString(ACCOUNT_CURRENCY); //Currency of Acount eg USD,GBP,EUR
string CounterC=StringSubstr(_Symbol,3,3);        //The Count Currency eg GBPUSD is USD
string ExC=AccntC+CounterC;                        //Create the Pair for account eg USDGBP

double    ExtATRBuffer[];
double    ExtTRBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   int l=0;
   text_init(ChartID(),"textATR",InpFontSize,(InpFontSize*3)*l++,InpColor,InpFontSize);
   text_init(ChartID(),"textBAL",InpFontSize,(InpFontSize*3)*l++,InpColor,InpFontSize);
   text_init(ChartID(),"textRISK",InpFontSize,(InpFontSize*3)*l++,InpColor,InpFontSize);
   text_init(ChartID(),"texttimeleft",InpFontSize,(InpFontSize*3)*l++,InpColor,InpFontSize);
   text_init(ChartID(),"textBuySL",InpFontSize,(InpFontSize*3)*l++,InpColor,InpFontSize);
   text_init(ChartID(),"textBuyTP",InpFontSize,(InpFontSize*3)*l++,InpColor,InpFontSize);
   text_init(ChartID(),"textSellSL",InpFontSize,(InpFontSize*3)*l++,InpColor,InpFontSize);
   text_init(ChartID(),"textSellTP",InpFontSize,(InpFontSize*3)*l++,InpColor,InpFontSize);
   text_init(ChartID(),"textlotsize",InpFontSize,(InpFontSize*3)*l++,InpColor,InpFontSize);

//--- ATR indicator buffers mapping
   SetIndexBuffer(0,ExtATRBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtTRBuffer,INDICATOR_CALCULATIONS);
//---
   // IndicatorSetInteger(INDICATOR_DIGITS,_Digits);


   return(INIT_SUCCEEDED);
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
//---
   double ExCRate=1;                                              //Assume Account is same as counter so ExCRate=1
   AccntC=AccountInfoString(ACCOUNT_CURRENCY);                    //Currency of Acount eg USD,GBP,EUR
   CounterC=StringSubstr(_Symbol,3,3);                           //The Count Currency eg GBPUSD is USD
   ExC=AccntC+CounterC;                                           //Create the Pair for account eg USDGBP
   if(AccntC!=CounterC)
      ExCRate= SymbolInfoDouble(ExC,SYMBOL_ASK);                  //Get the correct FX rate for the Account to Counter conversion
   if(ExCRate ==0) ExCRate=1.0;                                      // this part may be buggy - still need to test/fix it.
   
   double ATRPrice = AverageTrueRange(rates_total,prev_calculated,high,low,close);
   double ATRPoints = ATRPrice / _Point;                         //Get the ATR in points to calc SL and TP
   
   if(InpFixedATR!=0)
      ATRPoints=InpFixedATR;                                      //Override ATR for times when you have had a Flash crash

   double riskVAccntC=AccountInfoDouble(ACCOUNT_EQUITY)*(InpRiskPC/100);
   double riskvalue=(ExCRate/1)*riskVAccntC;                      //Risk in Account Currency
   double slpoints=(ATRPoints*InpSLfactor);                      //Risk in Counter Currency
   double riskperpoint=(riskvalue/slpoints);
   double lotSize=riskperpoint;                                  //Risk in currency per point

   // Explanation of the conventions used in this script 
   // for PIPs and MetaTrader's Points:
   // PIP (Points In Percent) in FX for most currencies 
   // is conventionally understood as 4 digits after the decimal point, 
   // ie; 0.0001 is one pip. The exception to the rule is 0.01 JPY is one pip. 
   // (because JPY has more significant digits before the decimal point.)
   // However, complicating this is that MetaTrader allow brokers to quote prices 
   // with additional digits, so JPY could be in either 2 or 3 "_Digits", 
   // and other currencies could be quoted in either 4 or 5 "_Digits" after the decimal place.
   // MetaTrader MQL sees points as the smallest amount of change in the quoted price, 
   // so a point might be either 1 or 10 pips, depending on how the broker quotes the prices.  
   // So, the way that this scripts resolves the variation is by performing the following mapping;
   // when _Digits = 5 then MTPointsPerPip = 10
   // when _Digits = 4 then MTPointsPerPip = 1
   // when _Digits = 3 then MTPointsPerPip = 10
   // when _Digits = 2 then MTPointsPerPip = 1
   
   int MTPointsPerPip = ( (_Digits == 3 || _Digits == 5) ? 10 : 1 );
   
   if(CounterC=="JPY") {
      lotSize=riskperpoint/100;
   }
   double ATRpips=MathCeil(ATRPoints/MTPointsPerPip);

//calculate time left this period

   datetime bar_times[]; // array storing the bar time
   ArraySetAsSeries(bar_times,true);
   //--- copy time from bars
   CopyTime(_Symbol,_Period,0,2,bar_times);

   int bar_span_seconds = PeriodSeconds(_Period);

   datetime last_bar_close_time = bar_times[0];
   datetime this_bar_close_time = last_bar_close_time + bar_span_seconds;
   
   MqlDateTime now_mdt;
   datetime now = TimeGMT(now_mdt);
   
   if( _Period > PERIOD_D1 ){
       this_bar_close_time -=  (60*60*24);  // Friday Close
   }

   long seconds_remaining = this_bar_close_time - now; // total seconds remaining in the current bar 
   
   long days_remaining = seconds_remaining / (60*60*24); //integer (int/long) division (/) truncates the remainder
   seconds_remaining %= (60*60*24);            //integer (int/long) mod (%) gets the remainder of the integer division
   
   long hours_remaining = seconds_remaining / (60*60);
   seconds_remaining %= (60*60);
   
   long minutes_remaining = seconds_remaining / 60;
   seconds_remaining %= 60;
   
   string lstrTimeLeft; 
   if( _Period > PERIOD_D1 )
      lstrTimeLeft = StringFormat("Time Left: %2.1d days, %2.2d:%2.2d:%2.2d",days_remaining,hours_remaining,minutes_remaining,seconds_remaining);
   else if( _Period <= PERIOD_H1 )
      lstrTimeLeft = StringFormat("Time Left: %2.2d:%2.2d",minutes_remaining,seconds_remaining); 
   else
      lstrTimeLeft = StringFormat("Time Left: %2.2d:%2.2d:%2.2d",hours_remaining,minutes_remaining,seconds_remaining);
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK)/_Point;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID)/_Point;

   double buySLPoints = -1*ATRPoints*InpSLfactor;
   double buySLPrice = (ask + buySLPoints)*_Point;
   double buyTPPoints = ATRPoints * InpTPfactor;
   double buyTPPrice = (ask + buyTPPoints)*_Point;
   
   double sellSLPoints = ATRPoints*InpSLfactor;
   double sellSLPrice = (ask + sellSLPoints)*_Point;
   double sellTPPoints = -1*ATRPoints*InpTPfactor;
   double sellTPPrice = (ask + sellTPPoints)*_Point; 
   
   string lstrATR    = ( InpFixedATR != 0 ? "*FIXED*" : "") + StringFormat("ATR(%.0f): %.0f pips", InpATRperiod,ATRpips );
   string lstrBAL    = StringFormat("Equity: %.2f %s",AccountInfoDouble(ACCOUNT_EQUITY),AccntC);
   string lstrRISK   = StringFormat("Risk %.1f%%: %.2f %s",InpRiskPC,riskVAccntC,AccntC);
   string lstrBuySL  = StringFormat("Buy SL: %s",DoubleToString( buySLPrice, _Digits ));
   string lstrBuyTP  = StringFormat("Buy TP: %s",DoubleToString( buyTPPrice, _Digits ));
   string lstrSellSL = StringFormat("Sell SL: %s",DoubleToString( sellSLPrice, _Digits ));
   string lstrSellTP = StringFormat("Sell TP: %s",DoubleToString( sellTPPrice, _Digits ));
   string lstrVolume = StringFormat("Volume: %.2f",lotSize);

   ObjectSetString(ChartID(),"texttimeleft",OBJPROP_TEXT, lstrTimeLeft );   
   ObjectSetString(ChartID(),"textATR",OBJPROP_TEXT, lstrATR);
   ObjectSetString(ChartID(),"textBAL",OBJPROP_TEXT, lstrBAL);
   ObjectSetString(ChartID(),"textRISK",OBJPROP_TEXT, lstrRISK);
   ObjectSetString(ChartID(),"textBuySL",OBJPROP_TEXT, lstrBuySL);
   ObjectSetString(ChartID(),"textBuyTP",OBJPROP_TEXT, lstrBuyTP);
   ObjectSetString(ChartID(),"textSellSL",OBJPROP_TEXT, lstrSellSL);
   ObjectSetString(ChartID(),"textSellTP",OBJPROP_TEXT, lstrSellTP);
   ObjectSetString(ChartID(),"textlotsize",OBJPROP_TEXT, lstrVolume);

//--- forced chart redraw
   ChartRedraw(ChartID());

//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+  
//| Generalized Average True Range - works in BOTH mt4 and mt5.      |
//+------------------------------------------------------------------+  
double AverageTrueRange(
                const int rates_total,
                const int prev_calculated,
                const double &high[],
                const double &low[],
                const double &close[] )
  {
   int i,limit;
//--- check for bars count
   if(rates_total<=InpATRperiod)
      return(0); // not enough bars for calculation
//--- counting from 0 to rates_total
   ArraySetAsSeries(ExtATRBuffer,false);
   ArraySetAsSeries(ExtTRBuffer,false);
   ArraySetAsSeries(high,false);
   ArraySetAsSeries(low,false);
   ArraySetAsSeries(close,false);
//--- preliminary calculations
   if(prev_calculated==0)
     {
      ExtTRBuffer[0]=0.0;
      ExtATRBuffer[0]=0.0;
      //--- filling out the array of True Range values for each period
      for(i=1;i<rates_total && !IsStopped();i++)
         ExtTRBuffer[i]=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      //--- first AtrPeriod values of the indicator are not calculated
      double firstValue=0.0;
      for(i=1;i<=InpATRperiod;i++)
        {
         ExtATRBuffer[i]=0.0;
         firstValue+=ExtTRBuffer[i];
        }
      //--- calculating the first value of the indicator
      firstValue/=InpATRperiod;
      ExtATRBuffer[InpATRperiod]=firstValue;
      limit=InpATRperiod+1;
     }
   else 
     limit=prev_calculated-1;
//--- the main loop of calculations
   for(i=limit; i<rates_total && !IsStopped(); i++)
     {
      ExtTRBuffer[i]=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      ExtATRBuffer[i]=ExtATRBuffer[i-1]+(ExtTRBuffer[i]-ExtTRBuffer[i-InpATRperiod])/InpATRperiod;
     }
//--- return the latest calculated ATR
   return(ExtATRBuffer[ ArraySize(ExtATRBuffer)-1]);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDelete(ChartID(),"textATR");
   ObjectDelete(ChartID(),"textBAL");
   ObjectDelete(ChartID(),"textRISK");
   ObjectDelete(ChartID(),"texttimeleft");
   ObjectDelete(ChartID(),"textBuySL");
   ObjectDelete(ChartID(),"textBuyTP");
   ObjectDelete(ChartID(),"textSellSL");
   ObjectDelete(ChartID(),"textSellTP");
   ObjectDelete(ChartID(),"textlotsize");
  }
//Function to create a text field in the main Window
// Example call --- text_init(ChartID(),"textATR",1000,30,clrRed,12);
int text_init(const long current_chart_id,const string obj_label,const int x_dist,const int y_dist,const int text_color,const int font_size)
  {
//--- creating label object (it does not have time/price coordinates)
   if(!ObjectCreate(current_chart_id,obj_label,OBJ_LABEL ,0,0,0))  
     {
      Print("Error: can't create label! code #",GetLastError());
      return(0);
     }
//--- set properties
   ObjectSetInteger(current_chart_id, obj_label, OBJPROP_CORNER, InpBaseCorner); // Center of coordinates
   
   int chart_height=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0); 
   int chart_width=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0); 

   int y_pos = y_dist;
   int x_pos = x_dist;
   
   switch(InpBaseCorner)
     {
      case CORNER_LEFT_UPPER : 
        { 
         y_pos += 50;
         ObjectSetInteger( current_chart_id, obj_label, OBJPROP_ALIGN , ALIGN_LEFT );
         ObjectSetInteger( current_chart_id, obj_label, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER );
        }; break;
      case CORNER_RIGHT_UPPER : 
        { 
         ObjectSetInteger( current_chart_id, obj_label, OBJPROP_ALIGN , ALIGN_RIGHT );
         ObjectSetInteger( current_chart_id, obj_label, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER );
        }; break;
      case CORNER_LEFT_LOWER : 
        { 
         y_pos = 27 * font_size - y_pos;
         ObjectSetInteger( current_chart_id, obj_label, OBJPROP_ALIGN , ALIGN_LEFT );
         ObjectSetInteger( current_chart_id, obj_label, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER );
        }; break;
      case CORNER_RIGHT_LOWER : 
        { 
         y_pos = 27 * font_size - y_pos;
         ObjectSetInteger( current_chart_id, obj_label, OBJPROP_ALIGN , ALIGN_RIGHT );
         ObjectSetInteger( current_chart_id, obj_label, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER );
        }; break;
     }
   
   ObjectSetInteger( current_chart_id, obj_label, OBJPROP_XDISTANCE, x_pos ); 
   ObjectSetInteger( current_chart_id, obj_label, OBJPROP_YDISTANCE, y_pos ); 
   ObjectSetInteger( current_chart_id, obj_label, OBJPROP_COLOR, text_color );
   ObjectSetInteger( current_chart_id, obj_label, OBJPROP_FONTSIZE, font_size );
      
   return(0);
  }
//+------------------------------------------------------------------+