//+------------------------------------------------------------------+
//|                                       Magnified Market Price.mq5 |
//|                                         Copyright © 2005, Habeeb |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2005, Habeeb"
//---- link to the website of the author
#property link      "http://www.metaquotes.net/"
//---- indicator version
#property version   "1.5"
//---- drawing the indicator in the main window
#property indicator_chart_window 
#property indicator_buffers 1
#property indicator_plots 1
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum type_price // displayed price type
  {
   MODE_BID,     // Bid
   MODE_ASK      // Ask
  };

enum type_font // font type
  {
   Font0, // Arial
   Font1, // Arial Black
   Font2, // Arial Bold
   Font3, // Arial Bold Italic
   Font4, // Arial Italic
   Font5, // Comic Sans MS Bold
   Font6, // Courier
   Font7, // Courier New
   Font8, // Courier New Bold
   Font9, // Courier New Bold Italic
   Font10, // Courier New Italic
   Font11, // Estrangelo Edessa
   Font12, // Franklin Gothic Medium
   Font13, // Gautami
   Font14, // Georgia
   Font15, // Georgia Bold
   Font16, // Georgia Bold Italic
   Font17, // Georgia Italic
   Font18, // Georgia Italic Impact
   Font19, // Latha
   Font20, // Lucida Console
   Font21, // Lucida Sans Unicode
   Font22, // Modern MS Sans Serif
   Font23, // MS Sans Serif
   Font24, // Mv Boli
   Font25, // Palatino Linotype
   Font26, // Palatino Linotype Bold
   Font27, // Palatino Linotype Italic
   Font28, // Roman
   Font29, // Script
   Font30, // Small Fonts
   Font31, // Symbol
   Font32, // Tahoma
   Font33, // Tahoma Bold
   Font34, // Times New Roman
   Font35, // Times New Roman Bold
   Font36, // Times New Roman Bold Italic
   Font37, // Times New Roman Italic
   Font38, // Trebuchet MS
   Font39, // Trebuchet MS Bold
   Font40, // Trebuchet MS Bold Italic
   Font41, // Trebuchet MS Italic
   Font42, // Tunga
   Font43, // Verdana
   Font44, // Verdana Bold
   Font45, // Verdana Bold Italic
   Font46, // Verdana Italic
   Font47, // Webdings
   Font48, // Westminster
   Font49, // Wingdings
   Font50, // WST_Czech
   Font51, // WST_Engl
   Font52, // WST_Fren
   Font53, // WST_Germ
   Font54, // WST_Ital
   Font55, // WST_Span
   Font56  // WST_Swed
  };
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input type_price PriceType=MODE_BID;                  // Displayed price type
input bool   CutPrice=false;                          // Last figure removal flag
input bool   ResetColors=true;                        // Colors reset flag
input color  UpPriceColor=Lime;                       // Rising price color
input color  PriceColor=Gray;                         // Unchanged price color
input color  DnPriceColor=Magenta;                    // Falling price color
input int    FontSize=24;                             // Font size
input type_font FontType=Font7;                       // Font type
input ENUM_BASE_CORNER  WhatCorner=CORNER_LEFT_LOWER; // Location corner 
//+----------------------------------------------+
double Old_Price;
color  PriceColor_;
string sFontType;
//+------------------------------------------------------------------+
//|  Creation of a text label                                        |
//+------------------------------------------------------------------+
void CreateTLabel(long   chart_id,         // chart ID
                  string name,             // object name
                  int    nwin,             // window index
                  ENUM_BASE_CORNER corner, // base corner location
                  ENUM_ANCHOR_POINT point, // anchor point location
                  int    X,                // the distance from the base corner along the X-axis in pixels
                  int    Y,                // the distance from the base corner along the Y-axis in pixels
                  string text,             // text
                  color  Color,            // text color
                  string Font,             // text font
                  int    Size)             // font size
  {
//----
   ObjectCreate(chart_id,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(chart_id,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,point);
   ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,X);
   ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,Y);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetString(chart_id,name,OBJPROP_FONT,Font);
   ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,Size);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//----
  }
//+------------------------------------------------------------------+
//|  Text label reinstallation                                       |
//+------------------------------------------------------------------+
void SetTLabel(long   chart_id,         // chart ID
               string name,             // object name
               int    nwin,             // window index
               ENUM_BASE_CORNER corner, // base corner location
               ENUM_ANCHOR_POINT point, // anchor point location
               int    X,                // the distance from the base corner along the X-axis in pixels
               int    Y,                // the distance from the base corner along the Y-axis in pixels
               string text,             // text
               color  Color,            // text color
               string Font,             // text font
               int    Size)             // font size
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateTLabel(chart_id,name,nwin,corner,point,X,Y,text,Color,Font,Size);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,X);
      ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,Y);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//----
   PriceColor_=PriceColor;

   string FontTypes[]=
     {
      "Arial",
      "Arial Black",
      "Arial Bold",
      "Arial Bold Italic",
      "Arial Italic",
      "Comic Sans MS Bold",
      "Courier",
      "Courier New",
      "Courier New Bold",
      "Courier New Bold Italic",
      "Courier New Italic",
      "Estrangelo Edessa",
      "Franklin Gothic Medium",
      "Gautami",
      "Georgia",
      "Georgia Bold",
      "Georgia Bold Italic",
      "Georgia Italic",
      "Georgia Italic Impact",
      "Latha",
      "Lucida Console",
      "Lucida Sans Unicode",
      "Modern MS Sans Serif",
      "MS Sans Serif",
      "Mv Boli",
      "Palatino Linotype",
      "Palatino Linotype Bold",
      "Palatino Linotype Italic",
      "Roman",
      "Script",
      "Small Fonts",
      "Symbol",
      "Tahoma",
      "Tahoma Bold",
      "Times New Roman",
      "Times New Roman Bold",
      "Times New Roman Bold Italic",
      "Times New Roman Italic",
      "Trebuchet MS",
      "Trebuchet MS Bold",
      "Trebuchet MS Bold Italic",
      "Trebuchet MS Italic",
      "Tunga",
      "Verdana",
      "Verdana Bold",
      "Verdana Bold Italic",
      "Verdana Italic",
      "Webdings",
      "Westminster",
      "Wingdings",
      "WST_Czech",
      "WST_Engl",
      "WST_Fren",
      "WST_Germ",
      "WST_Ital",
      "WST_Span",
      "WST_Swed"
     };

   sFontType=FontTypes[int(FontType)];
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectDelete(0,"Market_Price_Label");
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of minimums of price for the calculation of indicator
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- 
   double price=close[rates_total-1]+int(PriceType)*_Point*spread[rates_total-1];

   if(ResetColors==true)
     {
      PriceColor_=PriceColor;
      if(price > Old_Price) PriceColor_=UpPriceColor;
      if(price < Old_Price) PriceColor_=DnPriceColor;
      Old_Price=price;
     }

   string Market_Price=DoubleToString(price,_Digits-CutPrice);
   SetTLabel(0,"Market_Price_Label",0,WhatCorner,ENUM_ANCHOR_POINT(2*WhatCorner),5,1,Market_Price,PriceColor_,sFontType,FontSize);
//----
   ChartRedraw(0);
//----   
   return(rates_total);
  }
//+------------------------------------------------------------------+
