//+------------------------------------------------------------------+
//|                                             LineBreakOnChart.mq5 |
//|                                            Copyright 2012, Rone. |
//|                                            rone.sergey@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Rone."
#property link      "rone.sergey@gmail.com"
#property version   "1.00"
#property description "Indicator of three-linear reversal on the main chart"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot Series
#property indicator_label1  "Series"
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input datetime InpStartDate = D'2010.01.01 00:00:00'; // Date of calculation start
input int      InpLines = 3;                          // Number of reversal lines
input int      InpMinBoxSize = 0;                     // Min. box size
input color    InpUpColor = clrSteelBlue;             // Up-boxes color
input color    InpDnColor = clrIndianRed;             // Down-boxes color
//--- indicator buffers
double         SeriesBuffer[];
//--- global variables
double         minBoxSize;
double         linesPrices[];
int            seriesData[];
datetime       startDate;
int            lines;
//+------------------------------------------------------------------+
//| Class CPoint                                                     |
//+------------------------------------------------------------------+
class CPoint {
   public:
      double price;
      datetime time;
   public:
      CPoint();
      CPoint(const double p, const datetime t);
      ~CPoint() {};
      void setPoint(const double p, const datetime t);
      void setPrice(const double p);
      void setTime(const datetime t);
      bool operator==(const CPoint &other) const;
      bool operator!=(const CPoint &other) const;
      void operator=(const CPoint &other);
      double getPrice() const;
      datetime getTime() const;
};
//---
CPoint::CPoint(void) {
   price = 0;
   time = 0;
}
//---
CPoint::CPoint(const double p, const datetime t) {
   price = p;
   time = t;
}
//---
void CPoint::setPoint(const double p, const datetime t) {
   price = p;
   time = t;
}
//---
void CPoint::setPrice(const double p) {
   price = p;
}
//--- 
void CPoint::setTime(const datetime t) {
   time = t;
}
//---
bool CPoint::operator==(const CPoint &other) const {
   return price == other.price && time == other.time;
}
//---
bool CPoint::operator!=(const CPoint &other) const {
   return !operator==(other);
}
//---
void CPoint::operator=(const CPoint &other) {
   price = other.price;
   time = other.time;
}
//---
double CPoint::getPrice(void) const {
   return(price);
}
//---
datetime CPoint::getTime(void) const {
   return(time);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPoint leftPoint, rightPoint, prevLeftPoint, prevRightPoint;
CPoint curLeftPoint, curRightPoint;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//---
   startDate = InpStartDate;
   if ( startDate < D'2001.01.01 00:00:00' ) {
      startDate = D'2001.01.01 00:00:00';
      Print("Incorrect date parameter. The indicator wil be calculated since ", startDate);
   }
//---
   lines = InpLines;
   if ( lines < 1 ) {
      lines = 3;
      Print("Incorrect parameter of the reversal lines number. The indicator will be calculated with a value of  ", lines);
   }
//---
   if ( InpMinBoxSize < 0 ) {
      minBoxSize = 0;
      Print("Incorrect  parameter of the minimal box size. The indicator will be calculated with a value of  ", minBoxSize);
   } else {
      minBoxSize = InpMinBoxSize *_Point;
   }
//--- indicator buffers mapping
   SetIndexBuffer(0,SeriesBuffer,INDICATOR_DATA);
//---
   ObjectsDeleteAll(0, 0, OBJ_RECTANGLE);
//---
   ArrayResize(linesPrices, lines+1);
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   ObjectsDeleteAll(0, 0, OBJ_RECTANGLE);
//---
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
   int startBar, lastBar;
   color objColor;
//---
   if ( prev_calculated > rates_total || prev_calculated <= 0 ) {
      startBar = rates_total - iBarShift(startDate);
      for ( int bar = 0; bar < startBar; bar++ ) {
         SeriesBuffer[bar] = 0;
      }
      for ( int i = 1; i <= lines; i++ ) {
         linesPrices[i] = close[startBar-1];
      }
      linesPrices[0] = close[startBar];
   } else {
      startBar = prev_calculated - 1;
   }
//---
   lastBar = rates_total - 1;
   for ( int bar = startBar; bar < lastBar; bar++ ) {
      int prevBar = bar - 1;
      double seriesValue = SeriesBuffer[bar] = SeriesBuffer[prevBar];
      //--- Up Trend
      if ( seriesValue > 0.0 ) {
         objColor = InpUpColor;
         if ( close[bar] > linesPrices[0] + minBoxSize ) {
            trendContinue(close[bar], time[bar], leftPoint, rightPoint);
            addNewLineToArray(close[bar]);
            SeriesBuffer[bar] += 1;
         } else if( close[bar] < linesPrices[lines] ) {
            trendReverse(close[bar], time[bar], leftPoint, rightPoint);
            objColor = InpDnColor;
            SeriesBuffer[bar] = -1;
         } else {
            rightPoint.setTime(time[bar]);
         }
      } else if ( seriesValue < 0.0 ) {
         objColor = InpDnColor;
         if ( close[bar] < linesPrices[0] - minBoxSize ) {
            trendContinue(close[bar], time[bar], leftPoint, rightPoint);
            addNewLineToArray(close[bar]);
            SeriesBuffer[bar] -= 1;
         } else if ( close[bar] > linesPrices[lines] ) {
            trendReverse(close[bar], time[bar], leftPoint, rightPoint);
            objColor = InpUpColor;
            SeriesBuffer[bar] = 1;
         } else {
            rightPoint.setTime(time[bar]);
         }
      } else { // Down Trend
         if ( close[bar] >= close[prevBar] ) {
            objColor = InpUpColor;
            SeriesBuffer[bar] = 1;
         } else {
            objColor = InpDnColor;
            SeriesBuffer[bar] = -1;
         }
         addNewLineToArray(close[bar]);
         leftPoint.setPoint(close[prevBar], time[prevBar]);
         rightPoint.setPoint(close[bar], time[bar]);
      }
      drawRectangle(TimeToString(leftPoint.getTime()), leftPoint, rightPoint, objColor);
   }
//--- Process current bar
   double seriesValue = SeriesBuffer[lastBar] = SeriesBuffer[lastBar-1];
   double lastPrice = close[lastBar];
   //---
   if ( seriesValue > 0.0 ) {
      objColor = InpUpColor;
      if ( lastPrice > linesPrices[0] + minBoxSize ) {
         curLeftPoint = rightPoint;
         curRightPoint.setPoint(lastPrice, time[lastBar]);
         SeriesBuffer[lastBar] = SeriesBuffer[lastBar] + 1;
      } else if ( lastPrice < linesPrices[lines] ) {
         curLeftPoint.setPoint(leftPoint.getPrice(), rightPoint.getTime());
         curRightPoint.setPoint(lastPrice, time[lastBar]);
         objColor = InpDnColor;
         SeriesBuffer[lastBar] = -1;
      } else {
         curLeftPoint.setPoint(leftPoint.getPrice(), rightPoint.getTime());
         curRightPoint.setPoint(rightPoint.getPrice(), time[lastBar]);
      }
   } else {
      objColor = InpDnColor;
      if ( lastPrice < linesPrices[0] - minBoxSize ) {
         curLeftPoint = rightPoint;
         curRightPoint.setPoint(lastPrice, time[lastBar]);
         SeriesBuffer[lastBar] = SeriesBuffer[lastBar] - 1;
      } else if ( lastPrice > linesPrices[lines] ) {
         curLeftPoint.setPoint(leftPoint.getPrice(), rightPoint.getTime());
         curRightPoint.setPoint(lastPrice, time[lastBar]);
         objColor = InpUpColor;
         SeriesBuffer[lastBar] = 1;
      } else {
         curLeftPoint.setPoint(leftPoint.getPrice(), rightPoint.getTime());
         curRightPoint.setPoint(rightPoint.getPrice(), time[lastBar]);
      }
   }
   drawRectangle("Current", curLeftPoint, curRightPoint, objColor);
   ChartRedraw();
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| iBarShift function                                               |
//+------------------------------------------------------------------+
int iBarShift(datetime startTime) {
//---
   if ( startTime < 0 ) {
      return(-1); 
   }
//---
   datetime array[], curTime;
   CopyTime(_Symbol, _Period, 0, 1, array);
   curTime = array[0];
   //Print("CurTime: ", curTime);
   if ( CopyTime(_Symbol, _Period, startTime, curTime, array) > 0 ) {
      if ( ArraySize(array) > 2 ) {
         return(ArraySize(array));
      }
   }
//---
   return(-1);
}
//+------------------------------------------------------------------+
//| Add price to lines prices array function                         |
//+------------------------------------------------------------------+
void addNewLineToArray(double price) {
//---
   for ( int i = lines; i >= 1; i-- ) {
      linesPrices[i] = linesPrices[i-1];
   }
   linesPrices[0] = price;
//---
}
//+------------------------------------------------------------------+
//| Draw rectangle function                                          |
//+------------------------------------------------------------------+
void drawRectangle(string name, CPoint &left, CPoint &right, color clr) {
//---
   ObjectDelete(0, name);
//---
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, right.getTime(), right.getPrice(), left.getTime(), left.getPrice());
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
//---
}
//+------------------------------------------------------------------+
//| Set parameters if trend continues function                       |
//+------------------------------------------------------------------+
void trendContinue(double price, datetime time, CPoint &left, CPoint &right) {
//---
   left = right;
   right.setPoint(price, time);
//---
}
//+------------------------------------------------------------------+
//| Set parameters if trend continues function                       |
//+------------------------------------------------------------------+
void trendReverse(double price, datetime time, CPoint &left, CPoint &right ) {
//---
   left.setTime(right.getTime());
   right.setPoint(price, time);
   for ( int i = 1; i <= lines; i++ ) {
      linesPrices[i] = linesPrices[0];
   }
   addNewLineToArray(price);
//---
}
//+------------------------------------------------------------------+
