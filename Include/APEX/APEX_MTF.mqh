//+------------------------------------------------------------------+
//|                                                    APEX_MTF.mqh  |
//|                 APEX Gold Destroyer - Multi-Timeframe Engine      |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_MTF_MQH
#define APEX_MTF_MQH

#include "APEX_Config.mqh"

//+------------------------------------------------------------------+
//| Multi-Timeframe Handle Container                                  |
//+------------------------------------------------------------------+
struct TFHandles
  {
   int               hEMA_F, hEMA_M, hEMA_S, hEMA_L;
   int               hRSI, hBB, hMACD;
   int               hStoch, hADX, hCCI, hATR;
   ENUM_TIMEFRAMES   tf;
  };

//+------------------------------------------------------------------+
//| Multi-Timeframe Data Engine                                       |
//+------------------------------------------------------------------+
class CMTFEngine
  {
private:
   string            m_symbol;
   TFHandles         m_handles[6];     // M1, M5, M15, H1, H4, D1
   ApexTFData        m_data[6];        // Cached data per TF
   ENUM_TIMEFRAMES   m_timeframes[6];
   bool              m_initialized;
   double            m_atrHistory[];   // For ATR percentile
   int               m_atrHistSize;

   int               TFIndex(ENUM_TIMEFRAMES tf);
   bool              CreateHandles(int idx);
   bool              CopyData(int idx);

public:
                     CMTFEngine();
                    ~CMTFEngine();
   bool              Init(string symbol);
   void              Deinit();
   bool              Update();

   // Accessors
   ApexTFData        GetData(ENUM_TIMEFRAMES tf);
   double            GetATR(ENUM_TIMEFRAMES tf);
   int               GetHTFBias();  // +1 bull, -1 bear, 0 flat
   int               GetTrend(ENUM_TIMEFRAMES tf); // +1, -1, 0
   double            GetATRPercentile();
   bool              IsHTFFlat();
   double            GetM5Close(int shift = 1);
   double            GetM5High(int shift = 1);
   double            GetM5Low(int shift = 1);
   double            GetM5Open(int shift = 1);
   long              GetM5Volume(int shift = 1);
   bool              GetM5Candles(double &open[], double &high[], double &low[], double &close[], long &volume[], int count);
  };

//+------------------------------------------------------------------+
CMTFEngine::CMTFEngine()
  {
   m_initialized = false;
   m_atrHistSize = 100;
   m_timeframes[0] = PERIOD_M1;
   m_timeframes[1] = PERIOD_M5;
   m_timeframes[2] = PERIOD_M15;
   m_timeframes[3] = PERIOD_H1;
   m_timeframes[4] = PERIOD_H4;
   m_timeframes[5] = PERIOD_D1;
  }

//+------------------------------------------------------------------+
CMTFEngine::~CMTFEngine()
  {
   Deinit();
  }

//+------------------------------------------------------------------+
int CMTFEngine::TFIndex(ENUM_TIMEFRAMES tf)
  {
   for(int i = 0; i < 6; i++)
      if(m_timeframes[i] == tf) return i;
   return 1; // Default M5
  }

//+------------------------------------------------------------------+
bool CMTFEngine::Init(string symbol)
  {
   m_symbol = symbol;
   bool ok = true;
   for(int i = 0; i < 6; i++)
     {
      m_handles[i].tf = m_timeframes[i];
      if(!CreateHandles(i))
        {
         PrintFormat("APEX MTF: Failed to create handles for TF[%d]=%s",
                     i, EnumToString(m_timeframes[i]));
         ok = false;
        }
     }
   ArrayResize(m_atrHistory, m_atrHistSize);
   ArrayInitialize(m_atrHistory, 0);
   m_initialized = ok;
   return ok;
  }

//+------------------------------------------------------------------+
bool CMTFEngine::CreateHandles(int idx)
  {
   ENUM_TIMEFRAMES tf = m_handles[idx].tf;

   m_handles[idx].hEMA_F = iMA(m_symbol, tf, InpEMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   m_handles[idx].hEMA_M = iMA(m_symbol, tf, InpEMA_Mid,  0, MODE_EMA, PRICE_CLOSE);
   m_handles[idx].hEMA_S = iMA(m_symbol, tf, InpEMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   m_handles[idx].hEMA_L = iMA(m_symbol, tf, InpEMA_Long, 0, MODE_EMA, PRICE_CLOSE);
   m_handles[idx].hRSI   = iRSI(m_symbol, tf, InpRSI_Period, PRICE_CLOSE);
   m_handles[idx].hBB    = iBands(m_symbol, tf, InpBB_Period, 0, InpBB_Deviation, PRICE_CLOSE);
   m_handles[idx].hMACD  = iMACD(m_symbol, tf, InpMACD_Fast, InpMACD_Slow, InpMACD_Signal, PRICE_CLOSE);
   m_handles[idx].hStoch = iStochastic(m_symbol, tf, InpStoch_K, InpStoch_D, InpStoch_Slowing, MODE_SMA, STO_LOWHIGH);
   m_handles[idx].hADX   = iADX(m_symbol, tf, InpADX_Period);
   m_handles[idx].hCCI   = iCCI(m_symbol, tf, InpCCI_Period, PRICE_TYPICAL);
   m_handles[idx].hATR   = iATR(m_symbol, tf, InpATR_Period);

   // Validate all handles
   if(m_handles[idx].hEMA_F == INVALID_HANDLE || m_handles[idx].hEMA_M == INVALID_HANDLE ||
      m_handles[idx].hEMA_S == INVALID_HANDLE || m_handles[idx].hEMA_L == INVALID_HANDLE ||
      m_handles[idx].hRSI   == INVALID_HANDLE || m_handles[idx].hBB    == INVALID_HANDLE ||
      m_handles[idx].hMACD  == INVALID_HANDLE || m_handles[idx].hStoch == INVALID_HANDLE ||
      m_handles[idx].hADX   == INVALID_HANDLE || m_handles[idx].hCCI   == INVALID_HANDLE ||
      m_handles[idx].hATR   == INVALID_HANDLE)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
void CMTFEngine::Deinit()
  {
   for(int i = 0; i < 6; i++)
     {
      if(m_handles[i].hEMA_F != INVALID_HANDLE) IndicatorRelease(m_handles[i].hEMA_F);
      if(m_handles[i].hEMA_M != INVALID_HANDLE) IndicatorRelease(m_handles[i].hEMA_M);
      if(m_handles[i].hEMA_S != INVALID_HANDLE) IndicatorRelease(m_handles[i].hEMA_S);
      if(m_handles[i].hEMA_L != INVALID_HANDLE) IndicatorRelease(m_handles[i].hEMA_L);
      if(m_handles[i].hRSI   != INVALID_HANDLE) IndicatorRelease(m_handles[i].hRSI);
      if(m_handles[i].hBB    != INVALID_HANDLE) IndicatorRelease(m_handles[i].hBB);
      if(m_handles[i].hMACD  != INVALID_HANDLE) IndicatorRelease(m_handles[i].hMACD);
      if(m_handles[i].hStoch != INVALID_HANDLE) IndicatorRelease(m_handles[i].hStoch);
      if(m_handles[i].hADX   != INVALID_HANDLE) IndicatorRelease(m_handles[i].hADX);
      if(m_handles[i].hCCI   != INVALID_HANDLE) IndicatorRelease(m_handles[i].hCCI);
      if(m_handles[i].hATR   != INVALID_HANDLE) IndicatorRelease(m_handles[i].hATR);
      m_handles[i].hEMA_F = m_handles[i].hEMA_M = m_handles[i].hEMA_S = m_handles[i].hEMA_L = INVALID_HANDLE;
      m_handles[i].hRSI = m_handles[i].hBB = m_handles[i].hMACD = INVALID_HANDLE;
      m_handles[i].hStoch = m_handles[i].hADX = m_handles[i].hCCI = m_handles[i].hATR = INVALID_HANDLE;
     }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
bool CMTFEngine::Update()
  {
   if(!m_initialized) return false;
   bool ok = true;
   for(int i = 0; i < 6; i++)
     {
      if(!CopyData(i))
        {
         ok = false;
        }
     }
   return ok;
  }

//+------------------------------------------------------------------+
bool CMTFEngine::CopyData(int idx)
  {
   double buf1[], buf2[], buf3[];
   ArraySetAsSeries(buf1, true);
   ArraySetAsSeries(buf2, true);
   ArraySetAsSeries(buf3, true);

   // EMA Fast
   if(CopyBuffer(m_handles[idx].hEMA_F, 0, 0, 3, buf1) < 3) return false;
   m_data[idx].emaFast = buf1[1];

   // EMA Mid
   if(CopyBuffer(m_handles[idx].hEMA_M, 0, 0, 3, buf1) < 3) return false;
   m_data[idx].emaMid = buf1[1];

   // EMA Slow
   if(CopyBuffer(m_handles[idx].hEMA_S, 0, 0, 3, buf1) < 3) return false;
   m_data[idx].emaSlow = buf1[1];

   // EMA Long
   if(CopyBuffer(m_handles[idx].hEMA_L, 0, 0, 3, buf1) < 3) return false;
   m_data[idx].emaLong = buf1[1];

   // RSI
   if(CopyBuffer(m_handles[idx].hRSI, 0, 0, 3, buf1) < 3) return false;
   m_data[idx].rsi = buf1[1];

   // Bollinger Bands (0=middle, 1=upper, 2=lower)
   if(CopyBuffer(m_handles[idx].hBB, 0, 0, 3, buf1) < 3) return false;
   if(CopyBuffer(m_handles[idx].hBB, 1, 0, 3, buf2) < 3) return false;
   if(CopyBuffer(m_handles[idx].hBB, 2, 0, 3, buf3) < 3) return false;
   m_data[idx].bbMiddle = buf1[1];
   m_data[idx].bbUpper  = buf2[1];
   m_data[idx].bbLower  = buf3[1];

   // MACD (0=main, 1=signal)
   if(CopyBuffer(m_handles[idx].hMACD, 0, 0, 3, buf1) < 3) return false;
   if(CopyBuffer(m_handles[idx].hMACD, 1, 0, 3, buf2) < 3) return false;
   m_data[idx].macdMain   = buf1[1];
   m_data[idx].macdSignal = buf2[1];
   m_data[idx].macdHist   = buf1[1] - buf2[1];

   // Stochastic (0=main, 1=signal)
   if(CopyBuffer(m_handles[idx].hStoch, 0, 0, 3, buf1) < 3) return false;
   if(CopyBuffer(m_handles[idx].hStoch, 1, 0, 3, buf2) < 3) return false;
   m_data[idx].stochK = buf1[1];
   m_data[idx].stochD = buf2[1];

   // ADX (0=main, 1=+DI, 2=-DI)
   if(CopyBuffer(m_handles[idx].hADX, 0, 0, 3, buf1) < 3) return false;
   if(CopyBuffer(m_handles[idx].hADX, 1, 0, 3, buf2) < 3) return false;
   if(CopyBuffer(m_handles[idx].hADX, 2, 0, 3, buf3) < 3) return false;
   m_data[idx].adxMain  = buf1[1];
   m_data[idx].adxPlus  = buf2[1];
   m_data[idx].adxMinus = buf3[1];

   // CCI
   if(CopyBuffer(m_handles[idx].hCCI, 0, 0, 3, buf1) < 3) return false;
   m_data[idx].cci = buf1[1];

   // ATR
   if(CopyBuffer(m_handles[idx].hATR, 0, 0, 3, buf1) < 3) return false;
   m_data[idx].atr = buf1[1];

   return true;
  }

//+------------------------------------------------------------------+
ApexTFData CMTFEngine::GetData(ENUM_TIMEFRAMES tf)
  {
   return m_data[TFIndex(tf)];
  }

//+------------------------------------------------------------------+
double CMTFEngine::GetATR(ENUM_TIMEFRAMES tf)
  {
   return m_data[TFIndex(tf)].atr;
  }

//+------------------------------------------------------------------+
int CMTFEngine::GetTrend(ENUM_TIMEFRAMES tf)
  {
   int idx = TFIndex(tf);
   ApexTFData d = m_data[idx];
   if(d.emaFast > d.emaMid && d.emaMid > d.emaSlow) return +1;
   if(d.emaFast < d.emaMid && d.emaMid < d.emaSlow) return -1;
   return 0;
  }

//+------------------------------------------------------------------+
bool CMTFEngine::IsHTFFlat()
  {
   // H1 EMAs too close together = choppy
   ApexTFData h1 = m_data[TFIndex(PERIOD_H1)];
   double spread = MathAbs(h1.emaFast - h1.emaMid);
   return (spread < h1.atr * 0.05);
  }

//+------------------------------------------------------------------+
int CMTFEngine::GetHTFBias()
  {
   // NEXUS-style hard gate: H1 AND H4 must agree
   int h1Trend = GetTrend(PERIOD_H1);
   int h4Trend = GetTrend(PERIOD_H4);

   // Flatness filter
   if(IsHTFFlat()) return 0;

   // Both must agree for strong bias
   if(h1Trend > 0 && h4Trend > 0) return +1;
   if(h1Trend < 0 && h4Trend < 0) return -1;

   // H1 alone with H4 EMA fast > slow
   ApexTFData h4 = m_data[TFIndex(PERIOD_H4)];
   if(h1Trend > 0 && h4.emaFast > h4.emaSlow) return +1;
   if(h1Trend < 0 && h4.emaFast < h4.emaSlow) return -1;

   return 0;
  }

//+------------------------------------------------------------------+
double CMTFEngine::GetATRPercentile()
  {
   // Compute ATR percentile rank from M5 ATR over 100 bars
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   int idx = TFIndex(PERIOD_M5);
   if(CopyBuffer(m_handles[idx].hATR, 0, 0, m_atrHistSize, atrBuf) < m_atrHistSize)
      return 0.5; // Default middle

   double currentATR = atrBuf[1];
   int below = 0;
   for(int i = 1; i < m_atrHistSize; i++)
     {
      if(atrBuf[i] < currentATR) below++;
     }
   return (double)below / (double)(m_atrHistSize - 1);
  }

//+------------------------------------------------------------------+
double CMTFEngine::GetM5Close(int shift)
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyClose(m_symbol, PERIOD_M5, 0, shift + 1, buf) < shift + 1) return 0;
   return buf[shift];
  }

//+------------------------------------------------------------------+
double CMTFEngine::GetM5High(int shift)
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyHigh(m_symbol, PERIOD_M5, 0, shift + 1, buf) < shift + 1) return 0;
   return buf[shift];
  }

//+------------------------------------------------------------------+
double CMTFEngine::GetM5Low(int shift)
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyLow(m_symbol, PERIOD_M5, 0, shift + 1, buf) < shift + 1) return 0;
   return buf[shift];
  }

//+------------------------------------------------------------------+
double CMTFEngine::GetM5Open(int shift)
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   if(CopyOpen(m_symbol, PERIOD_M5, 0, shift + 1, buf) < shift + 1) return 0;
   return buf[shift];
  }

//+------------------------------------------------------------------+
long CMTFEngine::GetM5Volume(int shift)
  {
   long buf[];
   ArraySetAsSeries(buf, true);
   if(CopyTickVolume(m_symbol, PERIOD_M5, 0, shift + 1, buf) < shift + 1) return 0;
   return buf[shift];
  }

//+------------------------------------------------------------------+
bool CMTFEngine::GetM5Candles(double &open[], double &high[], double &low[], double &close[], long &volume[], int count)
  {
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(volume, true);
   if(CopyOpen(m_symbol, PERIOD_M5, 0, count, open) < count) return false;
   if(CopyHigh(m_symbol, PERIOD_M5, 0, count, high) < count) return false;
   if(CopyLow(m_symbol, PERIOD_M5, 0, count, low) < count) return false;
   if(CopyClose(m_symbol, PERIOD_M5, 0, count, close) < count) return false;
   if(CopyTickVolume(m_symbol, PERIOD_M5, 0, count, volume) < count) return false;
   return true;
  }

#endif // APEX_MTF_MQH
