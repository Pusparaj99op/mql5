//+------------------------------------------------------------------+
//|                                               XM_PriceAction.mqh |
//|                        Support/Resistance & Order Block Detection|
//|                              Copyright 2024-2026, XM_XAUUSD Bot  |
//+------------------------------------------------------------------+
#property copyright "XM_XAUUSD Bot"
#property link      "https://github.com/Pusparaj99op/XM_XAUUSD"
#property version   "1.00"
#property strict

#ifndef XM_PRICEACTION_MQH
#define XM_PRICEACTION_MQH

#include "XM_Config.mqh"

//+------------------------------------------------------------------+
//| CPriceActionAnalyzer Class                                        |
//+------------------------------------------------------------------+
class CPriceActionAnalyzer
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   double            m_pointValue;

   // Storage for S/R levels
   SupportResistance m_supportLevels[];
   SupportResistance m_resistanceLevels[];
   int               m_maxSRLevels;

   // Storage for Order Blocks
   OrderBlock        m_bullishOBs[];
   OrderBlock        m_bearishOBs[];
   int               m_maxOrderBlocks;

   // Swing points
   double            m_swingHighs[];
   double            m_swingLows[];
   datetime          m_swingHighTimes[];
   datetime          m_swingLowTimes[];

   bool              m_initialized;

public:
   //--- Constructor/Destructor
                     CPriceActionAnalyzer();
                    ~CPriceActionAnalyzer();

   //--- Initialization
   bool              Initialize(string symbol, ENUM_TIMEFRAMES tf);

   //--- Analysis methods
   void              UpdateAnalysis();
   void              DetectSupportResistance();
   void              DetectOrderBlocks();
   void              DetectSwingPoints();

   //--- Get levels
   double            GetNearestSupport(double price);
   double            GetNearestResistance(double price);
   double            GetStrongestSupport(double price, double range);
   double            GetStrongestResistance(double price, double range);

   //--- Order block methods
   bool              IsPriceInBullishOB(double price);
   bool              IsPriceInBearishOB(double price);
   OrderBlock        GetNearestBullishOB(double price);
   OrderBlock        GetNearestBearishOB(double price);

   //--- Signal generation
   ENUM_SIGNAL_TYPE  GetPriceActionSignal();
   ENUM_SIGNAL_TYPE  GetSRBreakoutSignal();
   ENUM_SIGNAL_TYPE  GetOrderBlockSignal();

   //--- Chart Drawing
   void              DrawSupportResistanceLevels();
   void              DrawOrderBlocks();
   void              DrawSwingPoints();
   void              CleanupDrawings();

   //--- Candlestick patterns
   bool              IsBullishEngulfing(int shift = 0);
   bool              IsBearishEngulfing(int shift = 0);
   bool              IsPinBarBullish(int shift = 0);
   bool              IsPinBarBearish(int shift = 0);
   bool              IsMorningStar(int shift = 0);
   bool              IsEveningStar(int shift = 0);
   bool              IsDoji(int shift = 0);
   bool              IsHammer(int shift = 0);
   bool              IsShootingStar(int shift = 0);

   //--- Utility
   double            CalculateSLFromSR(ENUM_SIGNAL_TYPE direction);
   double            CalculateTPFromSR(ENUM_SIGNAL_TYPE direction);
   int               GetSupportCount() { return ArraySize(m_supportLevels); }
   int               GetResistanceCount() { return ArraySize(m_resistanceLevels); }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CPriceActionAnalyzer::CPriceActionAnalyzer()
{
   m_symbol = "";
   m_timeframe = PERIOD_M5;
   m_maxSRLevels = 10;
   m_maxOrderBlocks = 5;
   m_initialized = false;
   m_pointValue = 0.01;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CPriceActionAnalyzer::~CPriceActionAnalyzer()
{
   ArrayFree(m_supportLevels);
   ArrayFree(m_resistanceLevels);
   ArrayFree(m_bullishOBs);
   ArrayFree(m_bearishOBs);
   ArrayFree(m_swingHighs);
   ArrayFree(m_swingLows);
   ArrayFree(m_swingHighTimes);
   ArrayFree(m_swingLowTimes);
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::Initialize(string symbol, ENUM_TIMEFRAMES tf)
{
   m_symbol = symbol;
   m_timeframe = tf;
   m_pointValue = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   ArrayResize(m_supportLevels, 0);
   ArrayResize(m_resistanceLevels, 0);
   ArrayResize(m_bullishOBs, 0);
   ArrayResize(m_bearishOBs, 0);
   ArrayResize(m_swingHighs, 0);
   ArrayResize(m_swingLows, 0);
   ArrayResize(m_swingHighTimes, 0);
   ArrayResize(m_swingLowTimes, 0);

   m_initialized = true;
   Print("Price Action Analyzer initialized");
   return true;
}

//+------------------------------------------------------------------+
//| Update all analysis                                               |
//+------------------------------------------------------------------+
void CPriceActionAnalyzer::UpdateAnalysis()
{
   if(!m_initialized) return;

   DetectSwingPoints();
   DetectSupportResistance();
   DetectOrderBlocks();
}

//+------------------------------------------------------------------+
//| Detect Swing Points                                               |
//+------------------------------------------------------------------+
void CPriceActionAnalyzer::DetectSwingPoints()
{
   ArrayResize(m_swingHighs, 0);
   ArrayResize(m_swingLows, 0);
   ArrayResize(m_swingHighTimes, 0);
   ArrayResize(m_swingLowTimes, 0);

   int lookback = InpSRLookback;
   int swingStrength = 3; // Bars on each side to confirm swing

   for(int i = swingStrength; i < lookback - swingStrength; i++)
   {
      double high = iHigh(m_symbol, m_timeframe, i);
      double low = iLow(m_symbol, m_timeframe, i);
      datetime time = iTime(m_symbol, m_timeframe, i);

      bool isSwingHigh = true;
      bool isSwingLow = true;

      // Check if it's a swing high
      for(int j = 1; j <= swingStrength; j++)
      {
         if(iHigh(m_symbol, m_timeframe, i - j) >= high ||
            iHigh(m_symbol, m_timeframe, i + j) >= high)
         {
            isSwingHigh = false;
            break;
         }
      }

      // Check if it's a swing low
      for(int j = 1; j <= swingStrength; j++)
      {
         if(iLow(m_symbol, m_timeframe, i - j) <= low ||
            iLow(m_symbol, m_timeframe, i + j) <= low)
         {
            isSwingLow = false;
            break;
         }
      }

      if(isSwingHigh)
      {
         int size = ArraySize(m_swingHighs);
         ArrayResize(m_swingHighs, size + 1);
         ArrayResize(m_swingHighTimes, size + 1);
         m_swingHighs[size] = high;
         m_swingHighTimes[size] = time;
      }

      if(isSwingLow)
      {
         int size = ArraySize(m_swingLows);
         ArrayResize(m_swingLows, size + 1);
         ArrayResize(m_swingLowTimes, size + 1);
         m_swingLows[size] = low;
         m_swingLowTimes[size] = time;
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Support and Resistance Levels                              |
//+------------------------------------------------------------------+
void CPriceActionAnalyzer::DetectSupportResistance()
{
   ArrayResize(m_supportLevels, 0);
   ArrayResize(m_resistanceLevels, 0);

   double zonePips = InpSRZoneSize * m_pointValue * 10;
   double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);

   // Analyze swing lows for support
   for(int i = 0; i < ArraySize(m_swingLows); i++)
   {
      double level = m_swingLows[i];

      // Skip if too far from current price
      if(MathAbs(level - currentPrice) > 500 * m_pointValue * 10)
         continue;

      // Check if this level already exists
      bool found = false;
      for(int j = 0; j < ArraySize(m_supportLevels); j++)
      {
         if(MathAbs(m_supportLevels[j].level - level) < zonePips)
         {
            m_supportLevels[j].touches++;
            m_supportLevels[j].lastTouch = m_swingLowTimes[i];
            m_supportLevels[j].strength = MathMin(1.0, m_supportLevels[j].touches * 0.25);
            found = true;
            break;
         }
      }

      if(!found && level < currentPrice)
      {
         int size = ArraySize(m_supportLevels);
         if(size < m_maxSRLevels)
         {
            ArrayResize(m_supportLevels, size + 1);
            m_supportLevels[size].level = level;
            m_supportLevels[size].touches = 1;
            m_supportLevels[size].isSupport = true;
            m_supportLevels[size].lastTouch = m_swingLowTimes[i];
            m_supportLevels[size].strength = 0.25;
         }
      }
   }

   // Analyze swing highs for resistance
   for(int i = 0; i < ArraySize(m_swingHighs); i++)
   {
      double level = m_swingHighs[i];

      // Skip if too far from current price
      if(MathAbs(level - currentPrice) > 500 * m_pointValue * 10)
         continue;

      // Check if this level already exists
      bool found = false;
      for(int j = 0; j < ArraySize(m_resistanceLevels); j++)
      {
         if(MathAbs(m_resistanceLevels[j].level - level) < zonePips)
         {
            m_resistanceLevels[j].touches++;
            m_resistanceLevels[j].lastTouch = m_swingHighTimes[i];
            m_resistanceLevels[j].strength = MathMin(1.0, m_resistanceLevels[j].touches * 0.25);
            found = true;
            break;
         }
      }

      if(!found && level > currentPrice)
      {
         int size = ArraySize(m_resistanceLevels);
         if(size < m_maxSRLevels)
         {
            ArrayResize(m_resistanceLevels, size + 1);
            m_resistanceLevels[size].level = level;
            m_resistanceLevels[size].touches = 1;
            m_resistanceLevels[size].isSupport = false;
            m_resistanceLevels[size].lastTouch = m_swingHighTimes[i];
            m_resistanceLevels[size].strength = 0.25;
         }
      }
   }

   // Filter by minimum touches
   for(int i = ArraySize(m_supportLevels) - 1; i >= 0; i--)
   {
      if(m_supportLevels[i].touches < InpSRMinTouches)
      {
         for(int j = i; j < ArraySize(m_supportLevels) - 1; j++)
            m_supportLevels[j] = m_supportLevels[j + 1];
         ArrayResize(m_supportLevels, ArraySize(m_supportLevels) - 1);
      }
   }

   for(int i = ArraySize(m_resistanceLevels) - 1; i >= 0; i--)
   {
      if(m_resistanceLevels[i].touches < InpSRMinTouches)
      {
         for(int j = i; j < ArraySize(m_resistanceLevels) - 1; j++)
            m_resistanceLevels[j] = m_resistanceLevels[j + 1];
         ArrayResize(m_resistanceLevels, ArraySize(m_resistanceLevels) - 1);
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Order Blocks                                               |
//+------------------------------------------------------------------+
void CPriceActionAnalyzer::DetectOrderBlocks()
{
   ArrayResize(m_bullishOBs, 0);
   ArrayResize(m_bearishOBs, 0);

   double minSize = InpOrderBlockMinSize * m_pointValue * 10;
   int lookback = InpOrderBlockLookback;
   double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);

   for(int i = 2; i < lookback; i++)
   {
      double open1 = iOpen(m_symbol, m_timeframe, i);
      double close1 = iClose(m_symbol, m_timeframe, i);
      double high1 = iHigh(m_symbol, m_timeframe, i);
      double low1 = iLow(m_symbol, m_timeframe, i);

      double open2 = iOpen(m_symbol, m_timeframe, i - 1);
      double close2 = iClose(m_symbol, m_timeframe, i - 1);
      double high2 = iHigh(m_symbol, m_timeframe, i - 1);
      double low2 = iLow(m_symbol, m_timeframe, i - 1);

      // Bullish Order Block: Bearish candle followed by strong bullish move
      if(close1 < open1 && close2 > open2 && close2 > high1)
      {
         double obSize = high1 - low1;
         if(obSize >= minSize)
         {
            int size = ArraySize(m_bullishOBs);
            if(size < m_maxOrderBlocks && low1 < currentPrice)
            {
               ArrayResize(m_bullishOBs, size + 1);
               m_bullishOBs[size].high = high1;
               m_bullishOBs[size].low = low1;
               m_bullishOBs[size].isBullish = true;
               m_bullishOBs[size].time = iTime(m_symbol, m_timeframe, i);
               m_bullishOBs[size].isValid = true;
            }
         }
      }

      // Bearish Order Block: Bullish candle followed by strong bearish move
      if(close1 > open1 && close2 < open2 && close2 < low1)
      {
         double obSize = high1 - low1;
         if(obSize >= minSize)
         {
            int size = ArraySize(m_bearishOBs);
            if(size < m_maxOrderBlocks && high1 > currentPrice)
            {
               ArrayResize(m_bearishOBs, size + 1);
               m_bearishOBs[size].high = high1;
               m_bearishOBs[size].low = low1;
               m_bearishOBs[size].isBullish = false;
               m_bearishOBs[size].time = iTime(m_symbol, m_timeframe, i);
               m_bearishOBs[size].isValid = true;
            }
         }
      }
   }

   // Invalidate order blocks that have been violated
   for(int i = 0; i < ArraySize(m_bullishOBs); i++)
   {
      // Check if price has closed below the OB
      for(int j = 0; j < 10; j++)
      {
         if(iClose(m_symbol, m_timeframe, j) < m_bullishOBs[i].low)
         {
            m_bullishOBs[i].isValid = false;
            break;
         }
      }
   }

   for(int i = 0; i < ArraySize(m_bearishOBs); i++)
   {
      // Check if price has closed above the OB
      for(int j = 0; j < 10; j++)
      {
         if(iClose(m_symbol, m_timeframe, j) > m_bearishOBs[i].high)
         {
            m_bearishOBs[i].isValid = false;
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get Nearest Support Level                                         |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::GetNearestSupport(double price)
{
   double nearest = 0;
   double minDist = DBL_MAX;

   for(int i = 0; i < ArraySize(m_supportLevels); i++)
   {
      if(m_supportLevels[i].level < price)
      {
         double dist = price - m_supportLevels[i].level;
         if(dist < minDist)
         {
            minDist = dist;
            nearest = m_supportLevels[i].level;
         }
      }
   }

   return nearest;
}

//+------------------------------------------------------------------+
//| Get Nearest Resistance Level                                      |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::GetNearestResistance(double price)
{
   double nearest = 0;
   double minDist = DBL_MAX;

   for(int i = 0; i < ArraySize(m_resistanceLevels); i++)
   {
      if(m_resistanceLevels[i].level > price)
      {
         double dist = m_resistanceLevels[i].level - price;
         if(dist < minDist)
         {
            minDist = dist;
            nearest = m_resistanceLevels[i].level;
         }
      }
   }

   return nearest;
}

//+------------------------------------------------------------------+
//| Get Strongest Support within range                                |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::GetStrongestSupport(double price, double range)
{
   double strongest = 0;
   double maxStrength = 0;

   for(int i = 0; i < ArraySize(m_supportLevels); i++)
   {
      double dist = price - m_supportLevels[i].level;
      if(dist > 0 && dist <= range)
      {
         if(m_supportLevels[i].strength > maxStrength)
         {
            maxStrength = m_supportLevels[i].strength;
            strongest = m_supportLevels[i].level;
         }
      }
   }

   return strongest;
}

//+------------------------------------------------------------------+
//| Get Strongest Resistance within range                             |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::GetStrongestResistance(double price, double range)
{
   double strongest = 0;
   double maxStrength = 0;

   for(int i = 0; i < ArraySize(m_resistanceLevels); i++)
   {
      double dist = m_resistanceLevels[i].level - price;
      if(dist > 0 && dist <= range)
      {
         if(m_resistanceLevels[i].strength > maxStrength)
         {
            maxStrength = m_resistanceLevels[i].strength;
            strongest = m_resistanceLevels[i].level;
         }
      }
   }

   return strongest;
}

//+------------------------------------------------------------------+
//| Check if price is in bullish order block                          |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsPriceInBullishOB(double price)
{
   for(int i = 0; i < ArraySize(m_bullishOBs); i++)
   {
      if(m_bullishOBs[i].isValid &&
         price >= m_bullishOBs[i].low &&
         price <= m_bullishOBs[i].high)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if price is in bearish order block                          |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsPriceInBearishOB(double price)
{
   for(int i = 0; i < ArraySize(m_bearishOBs); i++)
   {
      if(m_bearishOBs[i].isValid &&
         price >= m_bearishOBs[i].low &&
         price <= m_bearishOBs[i].high)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Get nearest bullish order block                                   |
//+------------------------------------------------------------------+
OrderBlock CPriceActionAnalyzer::GetNearestBullishOB(double price)
{
   OrderBlock nearest;
   nearest.isValid = false;
   double minDist = DBL_MAX;

   for(int i = 0; i < ArraySize(m_bullishOBs); i++)
   {
      if(m_bullishOBs[i].isValid && m_bullishOBs[i].high < price)
      {
         double dist = price - m_bullishOBs[i].high;
         if(dist < minDist)
         {
            minDist = dist;
            nearest = m_bullishOBs[i];
         }
      }
   }

   return nearest;
}

//+------------------------------------------------------------------+
//| Get nearest bearish order block                                   |
//+------------------------------------------------------------------+
OrderBlock CPriceActionAnalyzer::GetNearestBearishOB(double price)
{
   OrderBlock nearest;
   nearest.isValid = false;
   double minDist = DBL_MAX;

   for(int i = 0; i < ArraySize(m_bearishOBs); i++)
   {
      if(m_bearishOBs[i].isValid && m_bearishOBs[i].low > price)
      {
         double dist = m_bearishOBs[i].low - price;
         if(dist < minDist)
         {
            minDist = dist;
            nearest = m_bearishOBs[i];
         }
      }
   }

   return nearest;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern: Bullish Engulfing                            |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsBullishEngulfing(int shift)
{
   double open1 = iOpen(m_symbol, m_timeframe, shift + 1);
   double close1 = iClose(m_symbol, m_timeframe, shift + 1);
   double open2 = iOpen(m_symbol, m_timeframe, shift);
   double close2 = iClose(m_symbol, m_timeframe, shift);

   // First candle bearish, second candle bullish
   if(close1 < open1 && close2 > open2)
   {
      // Second candle body engulfs first candle body
      if(open2 <= close1 && close2 >= open1)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern: Bearish Engulfing                            |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsBearishEngulfing(int shift)
{
   double open1 = iOpen(m_symbol, m_timeframe, shift + 1);
   double close1 = iClose(m_symbol, m_timeframe, shift + 1);
   double open2 = iOpen(m_symbol, m_timeframe, shift);
   double close2 = iClose(m_symbol, m_timeframe, shift);

   // First candle bullish, second candle bearish
   if(close1 > open1 && close2 < open2)
   {
      // Second candle body engulfs first candle body
      if(open2 >= close1 && close2 <= open1)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern: Bullish Pin Bar                              |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsPinBarBullish(int shift)
{
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);

   double body = MathAbs(close - open);
   double range = high - low;
   double lowerWick = MathMin(open, close) - low;
   double upperWick = high - MathMax(open, close);

   // Pin bar: Long lower wick, small body at top
   if(range > 0 && lowerWick / range > 0.6 && body / range < 0.3 && upperWick / range < 0.2)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern: Bearish Pin Bar                              |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsPinBarBearish(int shift)
{
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);

   double body = MathAbs(close - open);
   double range = high - low;
   double lowerWick = MathMin(open, close) - low;
   double upperWick = high - MathMax(open, close);

   // Pin bar: Long upper wick, small body at bottom
   if(range > 0 && upperWick / range > 0.6 && body / range < 0.3 && lowerWick / range < 0.2)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern: Morning Star (3-candle bullish reversal)     |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsMorningStar(int shift)
{
   // First candle: Strong bearish
   double open1 = iOpen(m_symbol, m_timeframe, shift + 2);
   double close1 = iClose(m_symbol, m_timeframe, shift + 2);
   double body1 = MathAbs(close1 - open1);

   // Second candle: Small body (doji-like)
   double open2 = iOpen(m_symbol, m_timeframe, shift + 1);
   double close2 = iClose(m_symbol, m_timeframe, shift + 1);
   double body2 = MathAbs(close2 - open2);

   // Third candle: Strong bullish
   double open3 = iOpen(m_symbol, m_timeframe, shift);
   double close3 = iClose(m_symbol, m_timeframe, shift);
   double body3 = MathAbs(close3 - open3);

   if(close1 < open1 &&                      // First bearish
      body2 < body1 * 0.3 &&                 // Second is small
      close3 > open3 &&                       // Third bullish
      close3 > (open1 + close1) / 2)          // Third closes above midpoint of first
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern: Evening Star (3-candle bearish reversal)     |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsEveningStar(int shift)
{
   // First candle: Strong bullish
   double open1 = iOpen(m_symbol, m_timeframe, shift + 2);
   double close1 = iClose(m_symbol, m_timeframe, shift + 2);
   double body1 = MathAbs(close1 - open1);

   // Second candle: Small body (doji-like)
   double open2 = iOpen(m_symbol, m_timeframe, shift + 1);
   double close2 = iClose(m_symbol, m_timeframe, shift + 1);
   double body2 = MathAbs(close2 - open2);

   // Third candle: Strong bearish
   double open3 = iOpen(m_symbol, m_timeframe, shift);
   double close3 = iClose(m_symbol, m_timeframe, shift);
   double body3 = MathAbs(close3 - open3);

   if(close1 > open1 &&                      // First bullish
      body2 < body1 * 0.3 &&                 // Second is small
      close3 < open3 &&                       // Third bearish
      close3 < (open1 + close1) / 2)          // Third closes below midpoint of first
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern: Doji                                         |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsDoji(int shift)
{
   double open = iOpen(m_symbol, m_timeframe, shift);
   double close = iClose(m_symbol, m_timeframe, shift);
   double high = iHigh(m_symbol, m_timeframe, shift);
   double low = iLow(m_symbol, m_timeframe, shift);

   double body = MathAbs(close - open);
   double range = high - low;

   // Doji: Very small body compared to range
   if(range > 0 && body / range < 0.1)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Candlestick Pattern: Hammer                                       |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsHammer(int shift)
{
   return IsPinBarBullish(shift);
}

//+------------------------------------------------------------------+
//| Candlestick Pattern: Shooting Star                                |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsShootingStar(int shift)
{
   return IsPinBarBearish(shift);
}

//+------------------------------------------------------------------+
//| Get Price Action Signal                                           |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CPriceActionAnalyzer::GetPriceActionSignal()
{
   double price = SymbolInfoDouble(m_symbol, SYMBOL_BID);

   // Check candlestick patterns
   bool bullishPattern = IsBullishEngulfing(1) || IsPinBarBullish(1) ||
                         IsMorningStar(1) || IsHammer(1);
   bool bearishPattern = IsBearishEngulfing(1) || IsPinBarBearish(1) ||
                         IsEveningStar(1) || IsShootingStar(1);

   // Check S/R context
   double nearestSupport = GetNearestSupport(price);
   double nearestResistance = GetNearestResistance(price);

   double distToSupport = (nearestSupport > 0) ? price - nearestSupport : DBL_MAX;
   double distToResistance = (nearestResistance > 0) ? nearestResistance - price : DBL_MAX;

   double zonePips = InpSRZoneSize * m_pointValue * 10;

   // Strong signal: Price near support with bullish pattern
   if(bullishPattern && distToSupport < zonePips)
      return SIGNAL_BUY;

   // Strong signal: Price near resistance with bearish pattern
   if(bearishPattern && distToResistance < zonePips)
      return SIGNAL_SELL;

   // Weak signal: Pattern alone without S/R proximity (more trades)
   if(bullishPattern)
      return SIGNAL_BUY;

   if(bearishPattern)
      return SIGNAL_SELL;

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get S/R Breakout Signal                                           |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CPriceActionAnalyzer::GetSRBreakoutSignal()
{
   double close = iClose(m_symbol, m_timeframe, 0);
   double closePrev = iClose(m_symbol, m_timeframe, 1);

   // Check for resistance breakout
   for(int i = 0; i < ArraySize(m_resistanceLevels); i++)
   {
      if(closePrev < m_resistanceLevels[i].level && close > m_resistanceLevels[i].level)
      {
         // Confirmed breakout above resistance
         return SIGNAL_BUY;
      }
   }

   // Check for support breakdown
   for(int i = 0; i < ArraySize(m_supportLevels); i++)
   {
      if(closePrev > m_supportLevels[i].level && close < m_supportLevels[i].level)
      {
         // Confirmed breakdown below support
         return SIGNAL_SELL;
      }
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get Order Block Signal                                            |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CPriceActionAnalyzer::GetOrderBlockSignal()
{
   double price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double close = iClose(m_symbol, m_timeframe, 0);
   double open = iOpen(m_symbol, m_timeframe, 0);

   // Check if entering bullish order block
   if(IsPriceInBullishOB(price))
   {
      // Accept any bullish candle in OB zone (relaxed from engulfing/pinbar only)
      if(close > open || IsBullishEngulfing(0) || IsPinBarBullish(0))
         return SIGNAL_BUY;
   }

   // Check if entering bearish order block
   if(IsPriceInBearishOB(price))
   {
      // Accept any bearish candle in OB zone (relaxed from engulfing/pinbar only)
      if(close < open || IsBearishEngulfing(0) || IsPinBarBearish(0))
         return SIGNAL_SELL;
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Calculate SL based on S/R levels                                  |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::CalculateSLFromSR(ENUM_SIGNAL_TYPE direction)
{
   double price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double buffer = 10 * m_pointValue * 10; // 10 pips buffer

   if(direction == SIGNAL_BUY)
   {
      double support = GetNearestSupport(price);
      if(support > 0)
         return support - buffer;
   }
   else if(direction == SIGNAL_SELL)
   {
      double resistance = GetNearestResistance(price);
      if(resistance > 0)
         return resistance + buffer;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| Calculate TP based on S/R levels                                  |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::CalculateTPFromSR(ENUM_SIGNAL_TYPE direction)
{
   double price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double buffer = 5 * m_pointValue * 10; // 5 pips buffer before level

   if(direction == SIGNAL_BUY)
   {
      double resistance = GetNearestResistance(price);
      if(resistance > 0)
         return resistance - buffer;
   }
   else if(direction == SIGNAL_SELL)
   {
      double support = GetNearestSupport(price);
      if(support > 0)
         return support + buffer;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| Draw Support/Resistance Levels on Chart                           |
//+------------------------------------------------------------------+
void CPriceActionAnalyzer::DrawSupportResistanceLevels()
{
   // Clean old S/R drawings
   ObjectsDeleteAll(0, "XM_SR_");

   // Draw support levels
   for(int i = 0; i < ArraySize(m_supportLevels); i++)
   {
      string name = "XM_SR_Sup_" + IntegerToString(i);
      double level = m_supportLevels[i].level;
      int touches = m_supportLevels[i].touches;

      ObjectCreate(0, name, OBJ_HLINE, 0, 0, level);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, (touches >= 3) ? 2 : 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, name, OBJPROP_TOOLTIP,
         StringFormat("Support: %.2f | Touches: %d | Str: %.0f%%", level, touches, m_supportLevels[i].strength * 100));

      // Price label
      string lblName = "XM_SR_SupLbl_" + IntegerToString(i);
      ObjectCreate(0, lblName, OBJ_TEXT, 0, TimeCurrent(), level);
      ObjectSetString(0, lblName, OBJPROP_TEXT, StringFormat("S %.2f (%d)", level, touches));
      ObjectSetString(0, lblName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   }

   // Draw resistance levels
   for(int i = 0; i < ArraySize(m_resistanceLevels); i++)
   {
      string name = "XM_SR_Res_" + IntegerToString(i);
      double level = m_resistanceLevels[i].level;
      int touches = m_resistanceLevels[i].touches;

      ObjectCreate(0, name, OBJ_HLINE, 0, 0, level);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrCrimson);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, (touches >= 3) ? 2 : 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, name, OBJPROP_TOOLTIP,
         StringFormat("Resistance: %.2f | Touches: %d | Str: %.0f%%", level, touches, m_resistanceLevels[i].strength * 100));

      // Price label
      string lblName = "XM_SR_ResLbl_" + IntegerToString(i);
      ObjectCreate(0, lblName, OBJ_TEXT, 0, TimeCurrent(), level);
      ObjectSetString(0, lblName, OBJPROP_TEXT, StringFormat("R %.2f (%d)", level, touches));
      ObjectSetString(0, lblName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, clrCrimson);
      ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   }
}

//+------------------------------------------------------------------+
//| Draw Order Blocks on Chart                                        |
//+------------------------------------------------------------------+
void CPriceActionAnalyzer::DrawOrderBlocks()
{
   // Clean old OB drawings
   ObjectsDeleteAll(0, "XM_OB_");

   // Draw bullish order blocks
   for(int i = 0; i < ArraySize(m_bullishOBs); i++)
   {
      if(!m_bullishOBs[i].isValid) continue;

      string name = "XM_OB_Bull_" + IntegerToString(i);
      datetime t1 = m_bullishOBs[i].time;
      datetime t2 = TimeCurrent();

      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, m_bullishOBs[i].high, t2, m_bullishOBs[i].low);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrForestGreen);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetString(0, name, OBJPROP_TOOLTIP,
         StringFormat("Bullish OB: %.2f - %.2f", m_bullishOBs[i].low, m_bullishOBs[i].high));
   }

   // Draw bearish order blocks
   for(int i = 0; i < ArraySize(m_bearishOBs); i++)
   {
      if(!m_bearishOBs[i].isValid) continue;

      string name = "XM_OB_Bear_" + IntegerToString(i);
      datetime t1 = m_bearishOBs[i].time;
      datetime t2 = TimeCurrent();

      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, m_bearishOBs[i].high, t2, m_bearishOBs[i].low);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrIndianRed);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetString(0, name, OBJPROP_TOOLTIP,
         StringFormat("Bearish OB: %.2f - %.2f", m_bearishOBs[i].low, m_bearishOBs[i].high));
   }
}

//+------------------------------------------------------------------+
//| Draw Swing Points on Chart                                        |
//+------------------------------------------------------------------+
void CPriceActionAnalyzer::DrawSwingPoints()
{
   // Clean old swing drawings
   ObjectsDeleteAll(0, "XM_SW_");

   // Draw swing highs (down arrow / Wingding 234)
   for(int i = 0; i < ArraySize(m_swingHighs); i++)
   {
      string name = "XM_SW_H_" + IntegerToString(i);
      ObjectCreate(0, name, OBJ_ARROW, 0, m_swingHighTimes[i], m_swingHighs[i]);
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 234); // Down arrow
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrOrangeRed);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, name, OBJPROP_TOOLTIP,
         StringFormat("Swing High: %.2f", m_swingHighs[i]));
   }

   // Draw swing lows (up arrow / Wingding 233)
   for(int i = 0; i < ArraySize(m_swingLows); i++)
   {
      string name = "XM_SW_L_" + IntegerToString(i);
      ObjectCreate(0, name, OBJ_ARROW, 0, m_swingLowTimes[i], m_swingLows[i]);
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 233); // Up arrow
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_TOP);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, name, OBJPROP_TOOLTIP,
         StringFormat("Swing Low: %.2f", m_swingLows[i]));
   }
}

//+------------------------------------------------------------------+
//| Cleanup All Chart Drawings                                        |
//+------------------------------------------------------------------+
void CPriceActionAnalyzer::CleanupDrawings()
{
   ObjectsDeleteAll(0, "XM_SR_");
   ObjectsDeleteAll(0, "XM_OB_");
   ObjectsDeleteAll(0, "XM_SW_");
}

#endif // XM_PRICEACTION_MQH
//+------------------------------------------------------------------+
