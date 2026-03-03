//+------------------------------------------------------------------+
//|                                               XM_Indicators.mqh |
//|                        Advanced Indicator Calculations           |
//|                              Copyright 2024-2026, XM_XAUUSD Bot  |
//+------------------------------------------------------------------+
#property copyright "XM_XAUUSD Bot"
#property link      "https://github.com/Pusparaj99op/XM_XAUUSD"
#property version   "1.00"
#property strict

#ifndef XM_INDICATORS_MQH
#define XM_INDICATORS_MQH

#include "XM_Config.mqh"

//+------------------------------------------------------------------+
//| CIndicatorManager Class                                           |
//+------------------------------------------------------------------+
class CIndicatorManager
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;

   // Indicator handles
   int               m_handleRSI;
   int               m_handleBB;
   int               m_handleMACD;
   int               m_handleATR;
   int               m_handleMAFast;
   int               m_handleMASlow;
   int               m_handleMATrend;
   int               m_handleStoch;
   int               m_handleADX;
   int               m_handleCCI;

   // H1 trend filter handles
   int               m_handleH1MA;
   int               m_handleH1RSI;

   // Buffers for indicator values
   double            m_rsiBuffer[];
   double            m_bbUpperBuffer[];
   double            m_bbMiddleBuffer[];
   double            m_bbLowerBuffer[];
   double            m_macdMainBuffer[];
   double            m_macdSignalBuffer[];
   double            m_atrBuffer[];
   double            m_maFastBuffer[];
   double            m_maSlowBuffer[];
   double            m_maTrendBuffer[];
   double            m_stochKBuffer[];
   double            m_stochDBuffer[];
   double            m_adxBuffer[];
   double            m_cciBuffer[];
   double            m_h1MABuffer[];
   double            m_h1RSIBuffer[];

   bool              m_initialized;

public:
   //--- Constructor/Destructor
                     CIndicatorManager();
                    ~CIndicatorManager();

   //--- Initialization
   bool              Initialize(string symbol, ENUM_TIMEFRAMES tf);
   void              Deinitialize();

   //--- Update all indicators
   bool              UpdateIndicators();

   //--- Get indicator values
   double            GetRSI(int shift = 0);
   double            GetBBUpper(int shift = 0);
   double            GetBBMiddle(int shift = 0);
   double            GetBBLower(int shift = 0);
   double            GetBBWidth(int shift = 0);
   double            GetMACDMain(int shift = 0);
   double            GetMACDSignalLine(int shift = 0);
   double            GetMACDHistogram(int shift = 0);
   double            GetATR(int shift = 0);
   double            GetMAFast(int shift = 0);
   double            GetMASlow(int shift = 0);
   double            GetMATrend(int shift = 0);
   double            GetStochK(int shift = 0);
   double            GetStochD(int shift = 0);
   double            GetADX(int shift = 0);
   double            GetCCI(int shift = 0);
   double            GetH1MA(int shift = 0);
   double            GetH1RSI(int shift = 0);

   //--- Signal generation
   ENUM_SIGNAL_TYPE  GetRSISignal();
   ENUM_SIGNAL_TYPE  GetBollingerSignal();
   ENUM_SIGNAL_TYPE  GetMACDSignal();
   ENUM_SIGNAL_TYPE  GetMASignal();
   ENUM_SIGNAL_TYPE  GetStochSignal();
   ENUM_TREND_TYPE   GetH1Trend();
   ENUM_VOLATILITY_STATE GetVolatilityState();

   //--- Confluence signal
   TradeSignal       GetConfluenceSignal();

   //--- Market state
   bool              FillMarketState(MarketState &state);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CIndicatorManager::CIndicatorManager()
{
   m_symbol = "";
   m_timeframe = PERIOD_M5;
   m_handleRSI = INVALID_HANDLE;
   m_handleBB = INVALID_HANDLE;
   m_handleMACD = INVALID_HANDLE;
   m_handleATR = INVALID_HANDLE;
   m_handleMAFast = INVALID_HANDLE;
   m_handleMASlow = INVALID_HANDLE;
   m_handleMATrend = INVALID_HANDLE;
   m_handleStoch = INVALID_HANDLE;
   m_handleADX = INVALID_HANDLE;
   m_handleCCI = INVALID_HANDLE;
   m_handleH1MA = INVALID_HANDLE;
   m_handleH1RSI = INVALID_HANDLE;
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CIndicatorManager::~CIndicatorManager()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize all indicators                                         |
//+------------------------------------------------------------------+
bool CIndicatorManager::Initialize(string symbol, ENUM_TIMEFRAMES tf)
{
   m_symbol = symbol;
   m_timeframe = tf;

   // Create RSI indicator
   m_handleRSI = iRSI(m_symbol, m_timeframe, InpRSIPeriod, InpRSIPrice);
   if(m_handleRSI == INVALID_HANDLE)
   {
      Print("Error creating RSI indicator: ", GetLastError());
      return false;
   }

   // Create Bollinger Bands
   m_handleBB = iBands(m_symbol, m_timeframe, InpBBPeriod, 0, InpBBDeviation, InpBBPrice);
   if(m_handleBB == INVALID_HANDLE)
   {
      Print("Error creating Bollinger Bands indicator: ", GetLastError());
      return false;
   }

   // Create MACD
   m_handleMACD = iMACD(m_symbol, m_timeframe, InpMACDFastEMA, InpMACDSlowEMA, InpMACDSignalSMA, InpMACDPrice);
   if(m_handleMACD == INVALID_HANDLE)
   {
      Print("Error creating MACD indicator: ", GetLastError());
      return false;
   }

   // Create ATR
   m_handleATR = iATR(m_symbol, m_timeframe, InpATRPeriod);
   if(m_handleATR == INVALID_HANDLE)
   {
      Print("Error creating ATR indicator: ", GetLastError());
      return false;
   }

   // Create Moving Averages
   m_handleMAFast = iMA(m_symbol, m_timeframe, InpMAFastPeriod, 0, InpMAMethod, InpMAPrice);
   m_handleMASlow = iMA(m_symbol, m_timeframe, InpMASlowPeriod, 0, InpMAMethod, InpMAPrice);
   m_handleMATrend = iMA(m_symbol, m_timeframe, InpMATrendPeriod, 0, InpMAMethod, InpMAPrice);

   if(m_handleMAFast == INVALID_HANDLE || m_handleMASlow == INVALID_HANDLE || m_handleMATrend == INVALID_HANDLE)
   {
      Print("Error creating MA indicators: ", GetLastError());
      return false;
   }

   // Create Stochastic
   m_handleStoch = iStochastic(m_symbol, m_timeframe, InpStochKPeriod, InpStochDPeriod, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
   if(m_handleStoch == INVALID_HANDLE)
   {
      Print("Error creating Stochastic indicator: ", GetLastError());
      return false;
   }

   // Create ADX
   m_handleADX = iADX(m_symbol, m_timeframe, 14);
   if(m_handleADX == INVALID_HANDLE)
   {
      Print("Error creating ADX indicator: ", GetLastError());
      return false;
   }

   // Create CCI
   m_handleCCI = iCCI(m_symbol, m_timeframe, 14, PRICE_TYPICAL);
   if(m_handleCCI == INVALID_HANDLE)
   {
      Print("Error creating CCI indicator: ", GetLastError());
      return false;
   }

   // Create H1 trend indicators
   m_handleH1MA = iMA(m_symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   m_handleH1RSI = iRSI(m_symbol, PERIOD_H1, 14, PRICE_CLOSE);

   if(m_handleH1MA == INVALID_HANDLE || m_handleH1RSI == INVALID_HANDLE)
   {
      Print("Error creating H1 indicators: ", GetLastError());
      return false;
   }

   // Set buffer as series
   ArraySetAsSeries(m_rsiBuffer, true);
   ArraySetAsSeries(m_bbUpperBuffer, true);
   ArraySetAsSeries(m_bbMiddleBuffer, true);
   ArraySetAsSeries(m_bbLowerBuffer, true);
   ArraySetAsSeries(m_macdMainBuffer, true);
   ArraySetAsSeries(m_macdSignalBuffer, true);
   ArraySetAsSeries(m_atrBuffer, true);
   ArraySetAsSeries(m_maFastBuffer, true);
   ArraySetAsSeries(m_maSlowBuffer, true);
   ArraySetAsSeries(m_maTrendBuffer, true);
   ArraySetAsSeries(m_stochKBuffer, true);
   ArraySetAsSeries(m_stochDBuffer, true);
   ArraySetAsSeries(m_adxBuffer, true);
   ArraySetAsSeries(m_cciBuffer, true);
   ArraySetAsSeries(m_h1MABuffer, true);
   ArraySetAsSeries(m_h1RSIBuffer, true);

   m_initialized = true;
   Print("Indicators initialized successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize indicators                                           |
//+------------------------------------------------------------------+
void CIndicatorManager::Deinitialize()
{
   if(m_handleRSI != INVALID_HANDLE) IndicatorRelease(m_handleRSI);
   if(m_handleBB != INVALID_HANDLE) IndicatorRelease(m_handleBB);
   if(m_handleMACD != INVALID_HANDLE) IndicatorRelease(m_handleMACD);
   if(m_handleATR != INVALID_HANDLE) IndicatorRelease(m_handleATR);
   if(m_handleMAFast != INVALID_HANDLE) IndicatorRelease(m_handleMAFast);
   if(m_handleMASlow != INVALID_HANDLE) IndicatorRelease(m_handleMASlow);
   if(m_handleMATrend != INVALID_HANDLE) IndicatorRelease(m_handleMATrend);
   if(m_handleStoch != INVALID_HANDLE) IndicatorRelease(m_handleStoch);
   if(m_handleADX != INVALID_HANDLE) IndicatorRelease(m_handleADX);
   if(m_handleCCI != INVALID_HANDLE) IndicatorRelease(m_handleCCI);
   if(m_handleH1MA != INVALID_HANDLE) IndicatorRelease(m_handleH1MA);
   if(m_handleH1RSI != INVALID_HANDLE) IndicatorRelease(m_handleH1RSI);

   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Update all indicator values                                       |
//+------------------------------------------------------------------+
bool CIndicatorManager::UpdateIndicators()
{
   if(!m_initialized) return false;

   int copied = 0;

   // Copy RSI values
   copied = CopyBuffer(m_handleRSI, 0, 0, 10, m_rsiBuffer);
   if(copied <= 0) return false;

   // Copy Bollinger Bands
   copied = CopyBuffer(m_handleBB, 0, 0, 10, m_bbMiddleBuffer);
   if(copied <= 0) return false;
   copied = CopyBuffer(m_handleBB, 1, 0, 10, m_bbUpperBuffer);
   if(copied <= 0) return false;
   copied = CopyBuffer(m_handleBB, 2, 0, 10, m_bbLowerBuffer);
   if(copied <= 0) return false;

   // Copy MACD
   copied = CopyBuffer(m_handleMACD, 0, 0, 10, m_macdMainBuffer);
   if(copied <= 0) return false;
   copied = CopyBuffer(m_handleMACD, 1, 0, 10, m_macdSignalBuffer);
   if(copied <= 0) return false;

   // Copy ATR
   copied = CopyBuffer(m_handleATR, 0, 0, 10, m_atrBuffer);
   if(copied <= 0) return false;

   // Copy Moving Averages
   copied = CopyBuffer(m_handleMAFast, 0, 0, 10, m_maFastBuffer);
   if(copied <= 0) return false;
   copied = CopyBuffer(m_handleMASlow, 0, 0, 10, m_maSlowBuffer);
   if(copied <= 0) return false;
   copied = CopyBuffer(m_handleMATrend, 0, 0, 10, m_maTrendBuffer);
   if(copied <= 0) return false;

   // Copy Stochastic
   copied = CopyBuffer(m_handleStoch, 0, 0, 10, m_stochKBuffer);
   if(copied <= 0) return false;
   copied = CopyBuffer(m_handleStoch, 1, 0, 10, m_stochDBuffer);
   if(copied <= 0) return false;

   // Copy ADX
   copied = CopyBuffer(m_handleADX, 0, 0, 10, m_adxBuffer);
   if(copied <= 0) return false;

   // Copy CCI
   copied = CopyBuffer(m_handleCCI, 0, 0, 10, m_cciBuffer);
   if(copied <= 0) return false;

   // Copy H1 indicators
   copied = CopyBuffer(m_handleH1MA, 0, 0, 5, m_h1MABuffer);
   if(copied <= 0) return false;
   copied = CopyBuffer(m_handleH1RSI, 0, 0, 5, m_h1RSIBuffer);
   if(copied <= 0) return false;

   return true;
}

//+------------------------------------------------------------------+
//| Get indicator values                                              |
//+------------------------------------------------------------------+
double CIndicatorManager::GetRSI(int shift)        { return (shift < ArraySize(m_rsiBuffer)) ? m_rsiBuffer[shift] : 50.0; }
double CIndicatorManager::GetBBUpper(int shift)    { return (shift < ArraySize(m_bbUpperBuffer)) ? m_bbUpperBuffer[shift] : 0.0; }
double CIndicatorManager::GetBBMiddle(int shift)   { return (shift < ArraySize(m_bbMiddleBuffer)) ? m_bbMiddleBuffer[shift] : 0.0; }
double CIndicatorManager::GetBBLower(int shift)    { return (shift < ArraySize(m_bbLowerBuffer)) ? m_bbLowerBuffer[shift] : 0.0; }
double CIndicatorManager::GetBBWidth(int shift)    { return GetBBUpper(shift) - GetBBLower(shift); }
double CIndicatorManager::GetMACDMain(int shift)   { return (shift < ArraySize(m_macdMainBuffer)) ? m_macdMainBuffer[shift] : 0.0; }
double CIndicatorManager::GetMACDSignalLine(int shift) { return (shift < ArraySize(m_macdSignalBuffer)) ? m_macdSignalBuffer[shift] : 0.0; }
double CIndicatorManager::GetMACDHistogram(int shift) { return GetMACDMain(shift) - GetMACDSignalLine(shift); }
double CIndicatorManager::GetATR(int shift)        { return (shift < ArraySize(m_atrBuffer)) ? m_atrBuffer[shift] : 0.0; }
double CIndicatorManager::GetMAFast(int shift)     { return (shift < ArraySize(m_maFastBuffer)) ? m_maFastBuffer[shift] : 0.0; }
double CIndicatorManager::GetMASlow(int shift)     { return (shift < ArraySize(m_maSlowBuffer)) ? m_maSlowBuffer[shift] : 0.0; }
double CIndicatorManager::GetMATrend(int shift)    { return (shift < ArraySize(m_maTrendBuffer)) ? m_maTrendBuffer[shift] : 0.0; }
double CIndicatorManager::GetStochK(int shift)     { return (shift < ArraySize(m_stochKBuffer)) ? m_stochKBuffer[shift] : 50.0; }
double CIndicatorManager::GetStochD(int shift)     { return (shift < ArraySize(m_stochDBuffer)) ? m_stochDBuffer[shift] : 50.0; }
double CIndicatorManager::GetADX(int shift)        { return (shift < ArraySize(m_adxBuffer)) ? m_adxBuffer[shift] : 0.0; }
double CIndicatorManager::GetCCI(int shift)        { return (shift < ArraySize(m_cciBuffer)) ? m_cciBuffer[shift] : 0.0; }
double CIndicatorManager::GetH1MA(int shift)       { return (shift < ArraySize(m_h1MABuffer)) ? m_h1MABuffer[shift] : 0.0; }
double CIndicatorManager::GetH1RSI(int shift)      { return (shift < ArraySize(m_h1RSIBuffer)) ? m_h1RSIBuffer[shift] : 50.0; }

//+------------------------------------------------------------------+
//| Get RSI Signal                                                    |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CIndicatorManager::GetRSISignal()
{
   double rsi = GetRSI(0);
   double rsiPrev = GetRSI(1);

   // Oversold with upturn = Buy
   if(rsi < InpRSIOversold && rsi > rsiPrev)
      return SIGNAL_BUY;

   // Overbought with downturn = Sell
   if(rsi > InpRSIOverbought && rsi < rsiPrev)
      return SIGNAL_SELL;

   // Extreme levels with reversal confirmation
   if(rsiPrev <= InpRSIExtremeOS && rsi > InpRSIExtremeOS)
      return SIGNAL_BUY;

   if(rsiPrev >= InpRSIExtremeOB && rsi < InpRSIExtremeOB)
      return SIGNAL_SELL;

   // Momentum mode: RSI rising from 40-50 zone = weak buy
   if(rsi > 40 && rsi < 50 && rsi > rsiPrev && rsiPrev < rsi)
      return SIGNAL_BUY;

   // Momentum mode: RSI falling from 50-60 zone = weak sell
   if(rsi > 50 && rsi < 60 && rsi < rsiPrev && rsiPrev > rsi)
      return SIGNAL_SELL;

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get Bollinger Bands Signal                                        |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CIndicatorManager::GetBollingerSignal()
{
   double close = iClose(m_symbol, m_timeframe, 0);
   double closePrev = iClose(m_symbol, m_timeframe, 1);
   double open = iOpen(m_symbol, m_timeframe, 0);

   double bbUpper = GetBBUpper(0);
   double bbLower = GetBBLower(0);
   double bbMiddle = GetBBMiddle(0);

   // Touch lower band with bullish candle = Buy
   if(closePrev <= bbLower && close > closePrev && close > open)
      return SIGNAL_BUY;

   // Touch upper band with bearish candle = Sell
   if(closePrev >= bbUpper && close < closePrev && close < open)
      return SIGNAL_SELL;

   // Price returning from outside bands
   double lowPrev = iLow(m_symbol, m_timeframe, 1);
   double highPrev = iHigh(m_symbol, m_timeframe, 1);

   if(lowPrev < bbLower && close > bbLower)
      return SIGNAL_BUY;

   if(highPrev > bbUpper && close < bbUpper)
      return SIGNAL_SELL;

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get MACD Signal                                                   |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CIndicatorManager::GetMACDSignal()
{
   double macdMain = GetMACDMain(0);
   double macdSignal = GetMACDSignalLine(0);
   double macdMainPrev = GetMACDMain(1);
   double macdSignalPrev = GetMACDSignalLine(1);

   double histogram = GetMACDHistogram(0);
   double histogramPrev = GetMACDHistogram(1);

   // Bullish crossover
   if(macdMainPrev < macdSignalPrev && macdMain > macdSignal)
      return SIGNAL_BUY;

   // Bearish crossover
   if(macdMainPrev > macdSignalPrev && macdMain < macdSignal)
      return SIGNAL_SELL;

   // Histogram divergence confirmation
   if(histogram > 0 && histogram > histogramPrev && macdMain < 0)
      return SIGNAL_BUY;

   if(histogram < 0 && histogram < histogramPrev && macdMain > 0)
      return SIGNAL_SELL;

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get MA Signal                                                     |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CIndicatorManager::GetMASignal()
{
   double maFast = GetMAFast(0);
   double maSlow = GetMASlow(0);
   double maFastPrev = GetMAFast(1);
   double maSlowPrev = GetMASlow(1);
   double maTrend = GetMATrend(0);
   double close = iClose(m_symbol, m_timeframe, 0);

   // Bullish: Fast crosses above Slow, price above trend MA
   if(maFastPrev < maSlowPrev && maFast > maSlow && close > maTrend)
      return SIGNAL_BUY;

   // Bearish: Fast crosses below Slow, price below trend MA
   if(maFastPrev > maSlowPrev && maFast < maSlow && close < maTrend)
      return SIGNAL_SELL;

   // Momentum mode: Price above both MAs and they slope up
   if(close > maFast && maFast > maSlow && maFast > maFastPrev && maSlow > maSlowPrev)
      return SIGNAL_BUY;

   // Momentum mode: Price below both MAs and they slope down
   if(close < maFast && maFast < maSlow && maFast < maFastPrev && maSlow < maSlowPrev)
      return SIGNAL_SELL;

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get Stochastic Signal                                             |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CIndicatorManager::GetStochSignal()
{
   double stochK = GetStochK(0);
   double stochD = GetStochD(0);
   double stochKPrev = GetStochK(1);
   double stochDPrev = GetStochD(1);

   // Oversold bullish crossover
   if(stochKPrev < stochDPrev && stochK > stochD && stochK < InpStochOversold + 15)
      return SIGNAL_BUY;

   // Overbought bearish crossover
   if(stochKPrev > stochDPrev && stochK < stochD && stochK > InpStochOverbought - 15)
      return SIGNAL_SELL;

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get H1 Trend                                                      |
//+------------------------------------------------------------------+
ENUM_TREND_TYPE CIndicatorManager::GetH1Trend()
{
   double h1MA = GetH1MA(0);
   double h1RSI = GetH1RSI(0);
   double h1Close = iClose(m_symbol, PERIOD_H1, 0);

   // Strong uptrend: Price above MA, RSI > 50
   if(h1Close > h1MA && h1RSI > 50)
      return TREND_UP;

   // Strong downtrend: Price below MA, RSI < 50
   if(h1Close < h1MA && h1RSI < 50)
      return TREND_DOWN;

   return TREND_NONE;
}

//+------------------------------------------------------------------+
//| Get Volatility State                                              |
//+------------------------------------------------------------------+
ENUM_VOLATILITY_STATE CIndicatorManager::GetVolatilityState()
{
   double atr = GetATR(0);

   // Calculate average ATR over last 50 bars
   double avgATR = 0;
   for(int i = 0; i < 50 && i < ArraySize(m_atrBuffer); i++)
   {
      if(i < ArraySize(m_atrBuffer))
         avgATR += m_atrBuffer[i];
   }
   avgATR /= 50;

   if(atr > avgATR * InpATRVolatilityHigh)
      return VOL_HIGH;
   else if(atr < avgATR * InpATRVolatilityLow)
      return VOL_LOW;

   return VOL_NORMAL;
}

//+------------------------------------------------------------------+
//| Get Confluence Signal                                             |
//+------------------------------------------------------------------+
TradeSignal CIndicatorManager::GetConfluenceSignal()
{
   TradeSignal signal;
   signal.direction = SIGNAL_NONE;
   signal.strength = 0.0;
   signal.entryPrice = 0.0;
   signal.stopLoss = 0.0;
   signal.takeProfit = 0.0;
   signal.reason = "";
   signal.signalTime = TimeCurrent();
   signal.signalCount = 0;

   int buySignals = 0;
   int sellSignals = 0;
   double totalWeight = 0.0;
   string reasons = "";

   // Get all signals
   ENUM_SIGNAL_TYPE rsiSignal = GetRSISignal();
   ENUM_SIGNAL_TYPE bbSignal = GetBollingerSignal();
   ENUM_SIGNAL_TYPE macdSignal = GetMACDSignal();
   ENUM_SIGNAL_TYPE maSignal = GetMASignal();
   ENUM_SIGNAL_TYPE stochSignal = GetStochSignal();

   // Count signals with weights
   if(rsiSignal == SIGNAL_BUY)
   {
      buySignals++;
      totalWeight += InpIndicatorWeight;
      reasons += "RSI_OversoldReversal ";
   }
   else if(rsiSignal == SIGNAL_SELL)
   {
      sellSignals++;
      totalWeight += InpIndicatorWeight;
      reasons += "RSI_OverboughtReversal ";
   }

   if(bbSignal == SIGNAL_BUY)
   {
      buySignals++;
      totalWeight += InpIndicatorWeight;
      reasons += "BB_LowerBandBounce ";
   }
   else if(bbSignal == SIGNAL_SELL)
   {
      sellSignals++;
      totalWeight += InpIndicatorWeight;
      reasons += "BB_UpperBandReject ";
   }

   if(macdSignal == SIGNAL_BUY)
   {
      buySignals++;
      totalWeight += InpIndicatorWeight;
      reasons += "MACD_BullishCross ";
   }
   else if(macdSignal == SIGNAL_SELL)
   {
      sellSignals++;
      totalWeight += InpIndicatorWeight;
      reasons += "MACD_BearishCross ";
   }

   if(maSignal == SIGNAL_BUY)
   {
      buySignals++;
      totalWeight += InpIndicatorWeight * 0.8;
      reasons += "MA_BullishCross ";
   }
   else if(maSignal == SIGNAL_SELL)
   {
      sellSignals++;
      totalWeight += InpIndicatorWeight * 0.8;
      reasons += "MA_BearishCross ";
   }

   if(stochSignal == SIGNAL_BUY)
   {
      buySignals++;
      totalWeight += InpIndicatorWeight * 0.7;
      reasons += "Stoch_OversoldCross ";
   }
   else if(stochSignal == SIGNAL_SELL)
   {
      sellSignals++;
      totalWeight += InpIndicatorWeight * 0.7;
      reasons += "Stoch_OverboughtCross ";
   }

   // Check H1 trend filter
   ENUM_TREND_TYPE h1Trend = GetH1Trend();

   // Determine final signal
   if(buySignals >= InpMinSignalsRequired && buySignals > sellSignals)
   {
      // Apply trend filter if enabled
      if(InpUseTrendFilter && h1Trend == TREND_DOWN)
      {
         // Soften: reduce strength instead of blocking
         totalWeight *= 0.5;
         reasons += "[TrendPenalty] ";
      }

      signal.direction = SIGNAL_BUY;
      signal.signalCount = buySignals;
      signal.strength = MathMin(1.0, totalWeight / 5.0);
      signal.reason = reasons;
      signal.entryPrice = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   }
   else if(sellSignals >= InpMinSignalsRequired && sellSignals > buySignals)
   {
      // Apply trend filter if enabled
      if(InpUseTrendFilter && h1Trend == TREND_UP)
      {
         // Soften: reduce strength instead of blocking
         totalWeight *= 0.5;
         reasons += "[TrendPenalty] ";
      }

      signal.direction = SIGNAL_SELL;
      signal.signalCount = sellSignals;
      signal.strength = MathMin(1.0, totalWeight / 5.0);
      signal.reason = reasons;
      signal.entryPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Fill Market State Structure                                       |
//+------------------------------------------------------------------+
bool CIndicatorManager::FillMarketState(MarketState &state)
{
   if(!UpdateIndicators())
      return false;

   state.bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   state.ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   state.currentPrice = (state.bid + state.ask) / 2;
   state.spread = state.ask - state.bid;

   state.atr = GetATR(0);
   state.rsi = GetRSI(0);
   state.bbUpper = GetBBUpper(0);
   state.bbMiddle = GetBBMiddle(0);
   state.bbLower = GetBBLower(0);
   state.macdMain = GetMACDMain(0);
   state.macdSignal = GetMACDSignalLine(0);
   state.macdHistogram = GetMACDHistogram(0);
   state.maFast = GetMAFast(0);
   state.maSlow = GetMASlow(0);
   state.maTrend = GetMATrend(0);
   state.stochK = GetStochK(0);
   state.stochD = GetStochD(0);

   state.trend = GetH1Trend();
   state.volatility = GetVolatilityState();

   // Determine market session based on server time
   datetime serverTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);
   int hour = dt.hour;

   if(hour >= 0 && hour < 8)
      state.session = SESSION_ASIAN;
   else if(hour >= 8 && hour < 13)
      state.session = SESSION_LONDON;
   else if(hour >= 13 && hour < 17)
      state.session = SESSION_OVERLAP;
   else
      state.session = SESSION_NEWYORK;

   return true;
}

#endif // XM_INDICATORS_MQH
//+------------------------------------------------------------------+
