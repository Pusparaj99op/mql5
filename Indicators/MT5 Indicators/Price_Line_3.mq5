//+------------------------------------------------------------------+
//|                                                  Price_Line3.mq5 |
//|                                       Copyright 2023, Dark Ryd3r |
//|                                   https://twitter.com/DarkrRyd3r |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Dark Ryd3r"
#property link      "https://twitter.com/DarkrRyd3r"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

bool AllowZoom=true;
enum TimeSelect {
   Current,
   GMT,
   Local
};

string _SymbolName  = "SymbolPriceLine",StringSymbolList[],Value,text,left,gmt,c_htext,c_ltext,htext,ltext,lines_tag="viewport_lines_";        // Namespacing the Symbol Background...
input color inpTextColorPositive = C'86,211,158';      // Positive Color
input color inpTextColorNegative = clrDeepPink;         // Negative Color
input TimeSelect CurrentTime = Local;

int             inpFontSize=12;                                 // Symbol Font size
int             inpXOffSet=-35;                                   // Reposition Symbol Offset on X axis (+/-)
int             inpYOffSet=20;                                   // Reposition Symbol Offset on Y axis (+/-)

datetime m_prev_bars=0,tm,time_0;
double symID,symTotal,Calc2,last,copen,prevCl,space_hl,space_cl,hrange,lrange;
int hix,lix,lvb,_fvb,_clb,fvb=-1,clb=-1,_CurWindowWidth,NumSymbols=0,scale=0;

//--- input parameters of the script
input int               InpFontSize=10;          // Font size
input double            InpAngle=0.0;           // Slope angle in degrees
input ENUM_ANCHOR_POINT InpAnchor=ANCHOR_CENTER;   // Anchor type
input bool              InpBack=false;           // Background object
input bool              InpSelection=false;      // Highlight to move
input bool              InpHidden=true;          // Hidden in the object list
input long              InpZOrder=0;             // Priority for mouse click
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   scale=(int)ChartGetInteger(ChartID(),CHART_SCALE);
   ChartSetInteger(ChartID(),CHART_EVENT_MOUSE_WHEEL,true);
   ChartSetInteger(ChartID(),CHART_MOUSE_SCROLL,false);
   ChartSetInteger(ChartID(),CHART_EVENT_MOUSE_MOVE,true);


   symID = GlobalVariableGet("SymbolID");
   symTotal = GlobalVariableGet("SymbolTotal");

   ObjectsDeleteAll(ChartID(),lines_tag);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit( const int reason ) {
   ObjectDelete( 0, _SymbolName );
   ObjectDelete( 0, "PriceTime" );
   ObjectDelete( 0, "ltp" );
   ObjectsDeleteAll(ChartID(),lines_tag,-1,OBJ_TEXT);
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
                const int &spread[]) {
//---
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(open,true);


   time_0=time[rates_total-1];
   m_prev_bars=time_0;


   if(CurrentTime==Current) {
      tm=TimeCurrent();
      gmt = TimeToString(tm,TIME_SECONDS);
   }
   if(CurrentTime==GMT) {
      tm=TimeGMT();
      gmt = TimeToString(tm,TIME_SECONDS);
   }
   if(CurrentTime==Local) {
      tm=TimeLocal();
      gmt = TimeToString(tm,TIME_SECONDS);
   }

   last = close[0];
   copen = open[0];

   prevCl = iClose(NULL,PERIOD_M1,1440);

   if(last>0 && prevCl>0) {

      Calc2 = -(prevCl-last)/(prevCl)*100;
      Value = DoubleToString(Calc2,2);

      if(prevCl < last) {
         ObjectCreate(     0, _SymbolName, OBJ_LABEL, 0, 0, 0);
         ObjectSetString(  0, _SymbolName, OBJPROP_TEXT, Value +"%\r "  + gmt + " "+ IntegerToString((int)symID) + "/\r\r\r"+ IntegerToString((int)symTotal));
         ObjectSetInteger( 0, _SymbolName, OBJPROP_COLOR, inpTextColorPositive );
         ObjectSetInteger( 0, _SymbolName, OBJPROP_FONTSIZE, inpFontSize );
         ObjectSetInteger( 0, _SymbolName, OBJPROP_BACK,false);

      } else {
         ObjectCreate(     0, _SymbolName, OBJ_LABEL, 0, 0, 0);
         ObjectSetString(  0, _SymbolName, OBJPROP_TEXT, Value +"%\r "  + gmt + " "+ IntegerToString((int)symID) + "/\r\r\r"+ IntegerToString((int)symTotal));
         ObjectSetInteger( 0, _SymbolName, OBJPROP_COLOR, inpTextColorNegative );
         ObjectSetInteger( 0, _SymbolName, OBJPROP_FONTSIZE, inpFontSize );
         ObjectSetInteger( 0, _SymbolName, OBJPROP_BACK,false);
      }

   }

   ObjectSetString(  0, _SymbolName, OBJPROP_FONT, "Arial Black" );
   ObjectSetInteger( 0, _SymbolName, OBJPROP_CORNER, CORNER_RIGHT_UPPER );
   ObjectSetInteger( 0, _SymbolName, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER );
   ObjectSetInteger( 0, _SymbolName, OBJPROP_XDISTANCE, inpXOffSet );
   ObjectSetInteger( 0, _SymbolName, OBJPROP_YDISTANCE, inpYOffSet);


   text =  DoubleToString(last,_Digits);
   left=IntegerToString(m_prev_bars+PeriodSeconds(PERIOD_CURRENT)-tm);
   if(copen < last) {
      if(!TextCreate(0,"PriceTime",0,TimeGMT(),last,"    "+text + "  " + _Symbol  + "\r" + "  " + left +" \r"+ GetTimeFrame(Period()) +"\r ","Arial Black",inpFontSize,
                     inpTextColorPositive,0,ANCHOR_LEFT_LOWER,true,false,true,0)) {
         return 0;
      }

      if(!HLineCreate(0,"ltp",0,last,inpTextColorPositive,STYLE_SOLID,1,true,
                      false,true,0)) {
         return 0;
      }

   } else {
      if(!TextCreate(0,"PriceTime",0,TimeGMT(),last,"    "+text + "  " + _Symbol + "\r" + "  " + left +" \r"+ GetTimeFrame(Period()) +"\r ","Arial Black",inpFontSize,
                     inpTextColorNegative,0,ANCHOR_LEFT_LOWER,true,false,true,0)) {
         return 0;
      }

      if(!HLineCreate(0,"ltp",0,last,inpTextColorNegative,STYLE_SOLID,1,true,
                      false,true,0)) {
         return 0;
      }

   }

//--- return value of prev_calculated for next call
   return(rates_total);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) {

   if (id==CHARTEVENT_CHART_CHANGE) {
      _fvb=(int)ChartGetInteger(ChartID(),CHART_FIRST_VISIBLE_BAR,0);
      _clb=(int)ChartGetInteger(ChartID(),CHART_WIDTH_IN_BARS,0);
      if (_fvb>0 &&(_fvb!=fvb||_clb!=clb)) {
         if(ObjectGetInteger(0, lines_tag, OBJPROP_TYPE) == OBJ_TEXT)
            ObjectsDeleteAll(ChartID(),lines_tag,-1,OBJ_TEXT);

         lvb=_fvb-(_clb-1);
         if (lvb<0) {
            lvb=0;
         }
         hix= iHighest(_Symbol,_Period,MODE_HIGH,(_fvb-lvb),lvb);
         lix= iLowest(_Symbol,_Period,MODE_LOW,(_fvb-lvb),lvb);

         htext = " H";
         ltext = " L";
         space_hl = 10;

         hrange = iHigh(_Symbol,_Period,hix)+(iHigh(_Symbol,_Period,hix)-iLow(_Symbol,_Period,hix))*space_hl/100;
         lrange = iLow(_Symbol,_Period,lix)-(iHigh(_Symbol,_Period,lix)-iLow(_Symbol,_Period,lix))*space_hl/100;

         if(!TextCreate(0,lines_tag+"_H",0,iTime(_Symbol,_Period,hix),hrange,DoubleToString(iHigh(_Symbol,_Period,hix),_Digits)+htext,"Verdana",InpFontSize,
                        clrDeepPink,InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder)) {
            return;
         }
         if(!TextCreate(0,lines_tag+"_L",0,iTime(_Symbol,_Period,lix),lrange,DoubleToString(iLow(_Symbol,_Period,lix),_Digits)+ltext,"Verdana",InpFontSize,
                        clrLimeGreen,InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder)) {
            return;
         }

         ChartRedraw();
         fvb=_fvb;
         clb=_clb;
      }
   }

   if(id==CHARTEVENT_KEYDOWN) {

      switch(int(lparam)) {
      case 37:
         PrevSymbol();
         break;
      case 39:
         NextSymbol();
         break;
      }

   }

   if(id==CHARTEVENT_MOUSE_WHEEL&&AllowZoom) {
      //wheel up
      if(dparam>0) {
         scale++;
         if(scale>5) {
            scale=5;
         }
         ChartSetInteger(ChartID(),CHART_SCALE,scale);
         ChartRedraw(ChartID());
         ChartSetInteger(ChartID(),CHART_MOUSE_SCROLL,true);
      }
      //wheel down
      if(dparam<0) {
         scale--;
         if(scale<0) {
            scale=0;
         }
         ChartSetInteger(ChartID(),CHART_SCALE,scale);
         ChartRedraw(ChartID());
         ChartSetInteger(ChartID(),CHART_MOUSE_SCROLL,true);
      }
   }
}

//+------------------------------------------------------------------+
//| Create the horizontal line                                       |
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0) {       // priority for mouse click
//--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=iClose(NULL,PERIOD_M1,0);


//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price)) {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
   }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);

//--- successful execution
   return(true);
}

//+------------------------------------------------------------------+
//| Creating Text object                                             |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // chart's ID
                const string            name="Text",              // object name
                const int               sub_window=0,             // subwindow index
                datetime                time=0,                   // anchor point time
                double                  price=0,                  // anchor point price
                const string            text2="Text",              // the text itself
                const string            font="Arial",             // font
                const int               font_size=10,             // font size
                const color             clr=clrRed,               // color
                const double            angle=0.0,                // text slope
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                const bool              back=false,               // in the background
                const bool              selection=false,          // highlight to move
                const bool              hidden=true,              // hidden in the object list
                const long              z_order=0) {              // priority for mouse click
//--- set anchor point coordinates if they are not set
//--- reset the error value
   ResetLastError();
//--- create Text object
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price)) {
      Print(__FUNCTION__,
            ": failed to create \"Text\" object! Error code = ",GetLastError());
      return(false);
   }
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text2);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution

   return(true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string  GetTimeFrame( ENUM_TIMEFRAMES  lPeriod) {
   switch (lPeriod) {
   case  PERIOD_M1 :
      return ( "M1" );
   case  PERIOD_M2 :
      return ( "M2" );
   case  PERIOD_M3 :
      return ( "M3" );
   case  PERIOD_M4 :
      return ( "M4" );
   case  PERIOD_M5 :
      return ( "M5" );
   case  PERIOD_M6 :
      return ( "M6" );
   case  PERIOD_M10 :
      return ( "M10" );
   case  PERIOD_M12 :
      return ( "M12" );
   case  PERIOD_M15 :
      return ( "M15" );
   case  PERIOD_M20 :
      return ( "M20" );
   case  PERIOD_M30 :
      return ( "M30" );
   case  PERIOD_H1 :
      return ( "H1" );
   case  PERIOD_H2 :
      return ( "H2" );
   case  PERIOD_H3 :
      return ( "H3" );
   case  PERIOD_H4 :
      return ( "H4" );
   case  PERIOD_H6 :
      return ( "H6" );
   case  PERIOD_H8 :
      return ( "H8" );
   case  PERIOD_H12 :
      return ( "H12" );
   case  PERIOD_D1 :
      return ( "D1" );
   case  PERIOD_W1 :
      return ( "W1" );
   case  PERIOD_MN1 :
      return ( "MN1" );
   }
   return  EnumToString (lPeriod);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PrevSymbol() {
   int currentIndex;
   GetSymbols();
   currentIndex=GetIndex();
   currentIndex--;

   if(currentIndex<0) {
      currentIndex=NumSymbols-1;
      ChartSetSymbolPeriod(0,StringSymbolList[currentIndex],0);
   } else {
      ChartSetSymbolPeriod(0,StringSymbolList[currentIndex],0);
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void NextSymbol() {
   int currentIndex;
   GetSymbols();
   currentIndex=GetIndex();
   currentIndex++;

   if(currentIndex>=NumSymbols) {
      ChartSetSymbolPeriod(0,StringSymbolList[0],0);
   } else {
      ChartSetSymbolPeriod(0,StringSymbolList[currentIndex],0);

   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetSymbols() {
   int numSymbolsMarketWatch=SymbolsTotal(true);
   NumSymbols=numSymbolsMarketWatch;
   ArrayResize(StringSymbolList,numSymbolsMarketWatch);
   for(int i=0; i<numSymbolsMarketWatch; i++) {
      StringSymbolList[i]=SymbolName(i,true);
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetIndex() {
   int index=0;
   for(int i=0; i<NumSymbols; i++) {
      if(_Symbol==StringSymbolList[i]) {
         index=i;

         break;
      }
   }
   return index;
}
//+------------------------------------------------------------------+
