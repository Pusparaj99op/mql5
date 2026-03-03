//+------------------------------------------------------------------+
//|                                               GA_Indicators.mqh  |
//|                   GoldAlgo Elite - Indicator Engine                |
//|           All indicator handles + custom calculations              |
//+------------------------------------------------------------------+
#property copyright "GoldAlgo Elite"
#property strict

#ifndef __GA_INDICATORS_MQH__
#define __GA_INDICATORS_MQH__

#include "GA_Config.mqh"

//+------------------------------------------------------------------+
//| Kalman Filter State                                               |
//+------------------------------------------------------------------+
struct KalmanState
  {
   double   x;       // State estimate (smoothed price)
   double   P;       // Estimate error covariance
   double   v;       // Velocity (trend direction)
   double   xPrev;   // Previous state for velocity computation

   void Init(double initialPrice)
     {
      x     = initialPrice;
      P     = 1.0;
      v     = 0;
      xPrev = initialPrice;
     }

   void Update(double measurement, double Q, double R)
     {
      // Predict
      double P_pred = P + Q;
      // Update
      double K = P_pred / (P_pred + R);
      xPrev = x;
      x = x + K * (measurement - x);
      P = (1.0 - K) * P_pred;
      // Velocity
      v = x - xPrev;
     }
  };

//+------------------------------------------------------------------+
//| CIndicatorEngine - Manages all indicators                         |
//+------------------------------------------------------------------+
class CIndicatorEngine
  {
private:
   // Standard indicator handles
   int               m_hEMA_Fast;
   int               m_hEMA_Mid;
   int               m_hEMA_Slow;
   int               m_hEMA_Trend;
   int               m_hRSI;
   int               m_hBB;
   int               m_hATR;
   int               m_hMACD;
   int               m_hStoch;
   int               m_hADX;
   int               m_hCCI;

   // Indicator buffers (bar 0 = current, bar 1 = prev, etc.)
   double            m_emaFast[];
   double            m_emaMid[];
   double            m_emaSlow[];
   double            m_emaTrend[];
   double            m_rsi[];
   double            m_bbUpper[];
   double            m_bbMiddle[];
   double            m_bbLower[];
   double            m_atr[];
   double            m_macdMain[];
   double            m_macdSignal[];
   double            m_stochK[];
   double            m_stochD[];
   double            m_adxMain[];
   double            m_adxPlus[];
   double            m_adxMinus[];
   double            m_cci[];

   // Price data
   double            m_close[];
   double            m_high[];
   double            m_low[];
   double            m_open[];
   long              m_tickVol[];

   // Kalman filter
   KalmanState       m_kalman;
   bool              m_kalmanInitialized;

   // Hull MA buffer (last 5 values)
   double            m_hma[5];

   // VWAP
   double            m_vwap;

   // Z-Score
   double            m_zscore;

   // Order Flow Imbalance
   double            m_ofi;           // Smoothed OFI (-1 to +1 scale)
   double            m_buyPressure;   // Raw buy pressure
   double            m_sellPressure;  // Raw sell pressure

   // ATR percentile tracking
   double            m_atrHistory[];  // For percentile calculation
   int               m_atrHistCount;

   // Working symbol & timeframe
   string            m_symbol;
   ENUM_TIMEFRAMES   m_period;
   int               m_bufferSize;

   // Private methods
   double            CalcWMA(const double &arr[], int period, int shift);
   void              CalcHullMA();
   void              CalcVWAP();
   void              CalcZScore();
   void              CalcOrderFlowImbalance();
   void              UpdateATRHistory();

public:
                     CIndicatorEngine();
                    ~CIndicatorEngine();

   bool              Init(string symbol, ENUM_TIMEFRAMES period);
   void              Deinit();
   bool              Update();

   // Standard indicator getters (bar index: 0=current, 1=prev, etc.)
   double            EMA_Fast(int i)    { return (i < ArraySize(m_emaFast))  ? m_emaFast[i]  : 0; }
   double            EMA_Mid(int i)     { return (i < ArraySize(m_emaMid))   ? m_emaMid[i]   : 0; }
   double            EMA_Slow(int i)    { return (i < ArraySize(m_emaSlow))  ? m_emaSlow[i]  : 0; }
   double            EMA_Trend(int i)   { return (i < ArraySize(m_emaTrend)) ? m_emaTrend[i] : 0; }
   double            RSI(int i)         { return (i < ArraySize(m_rsi))      ? m_rsi[i]      : 50; }
   double            BB_Upper(int i)    { return (i < ArraySize(m_bbUpper))  ? m_bbUpper[i]  : 0; }
   double            BB_Middle(int i)   { return (i < ArraySize(m_bbMiddle)) ? m_bbMiddle[i] : 0; }
   double            BB_Lower(int i)    { return (i < ArraySize(m_bbLower))  ? m_bbLower[i]  : 0; }
   double            ATR(int i)         { return (i < ArraySize(m_atr))      ? m_atr[i]      : 0; }
   double            MACD_Main(int i)   { return (i < ArraySize(m_macdMain)) ? m_macdMain[i] : 0; }
   double            MACD_Signal(int i) { return (i < ArraySize(m_macdSignal))? m_macdSignal[i]: 0; }
   double            MACD_Hist(int i)   { return MACD_Main(i) - MACD_Signal(i); }
   double            Stoch_K(int i)     { return (i < ArraySize(m_stochK))   ? m_stochK[i]   : 50; }
   double            Stoch_D(int i)     { return (i < ArraySize(m_stochD))   ? m_stochD[i]   : 50; }
   double            ADX(int i)         { return (i < ArraySize(m_adxMain))  ? m_adxMain[i]  : 0; }
   double            ADX_Plus(int i)    { return (i < ArraySize(m_adxPlus))  ? m_adxPlus[i]  : 0; }
   double            ADX_Minus(int i)   { return (i < ArraySize(m_adxMinus)) ? m_adxMinus[i] : 0; }
   double            CCI(int i)         { return (i < ArraySize(m_cci))      ? m_cci[i]      : 0; }

   // Price getters
   double            Close(int i)       { return (i < ArraySize(m_close))    ? m_close[i]    : 0; }
   double            High(int i)        { return (i < ArraySize(m_high))     ? m_high[i]     : 0; }
   double            Low(int i)         { return (i < ArraySize(m_low))      ? m_low[i]      : 0; }
   double            Open(int i)        { return (i < ArraySize(m_open))     ? m_open[i]     : 0; }
   long              TickVol(int i)     { return (i < ArraySize(m_tickVol))  ? m_tickVol[i]  : 0; }

   // Custom indicator getters
   double            KalmanPrice()      { return m_kalman.x; }
   double            KalmanVelocity()   { return m_kalman.v; }
   double            HMA(int i)         { return (i < 5) ? m_hma[i] : 0; }
   double            VWAP()             { return m_vwap; }
   double            ZScore()           { return m_zscore; }
   double            OFI()              { return m_ofi; }
   double            BuyPressure()      { return m_buyPressure; }
   double            SellPressure()     { return m_sellPressure; }

   // Bollinger Bandwidth (normalized)
   double            BB_Bandwidth(int i=1) { double mid = BB_Middle(i); return (mid > 0) ? (BB_Upper(i) - BB_Lower(i)) / mid : 0; }

   // ATR percentile (0-100)
   double            ATRPercentile();

   // Market Regime Detection
   ENUM_MARKET_REGIME DetectRegime(double &confidence);
  };

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CIndicatorEngine::CIndicatorEngine()
  {
   m_hEMA_Fast  = INVALID_HANDLE;
   m_hEMA_Mid   = INVALID_HANDLE;
   m_hEMA_Slow  = INVALID_HANDLE;
   m_hEMA_Trend = INVALID_HANDLE;
   m_hRSI       = INVALID_HANDLE;
   m_hBB        = INVALID_HANDLE;
   m_hATR       = INVALID_HANDLE;
   m_hMACD      = INVALID_HANDLE;
   m_hStoch     = INVALID_HANDLE;
   m_hADX       = INVALID_HANDLE;
   m_hCCI       = INVALID_HANDLE;
   m_kalmanInitialized = false;
   m_vwap       = 0;
   m_zscore     = 0;
   m_ofi        = 0;
   m_buyPressure= 0;
   m_sellPressure=0;
   m_atrHistCount = 0;
   m_bufferSize = 300;
   ArrayInitialize(m_hma, 0);
  }

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CIndicatorEngine::~CIndicatorEngine()
  {
   Deinit();
  }

//+------------------------------------------------------------------+
//| Initialize all indicator handles                                  |
//+------------------------------------------------------------------+
bool CIndicatorEngine::Init(string symbol, ENUM_TIMEFRAMES period)
  {
   m_symbol = symbol;
   m_period = period;

   // EMA handles
   m_hEMA_Fast  = iMA(m_symbol, m_period, InpEMA_Fast,  0, MODE_EMA, PRICE_CLOSE);
   m_hEMA_Mid   = iMA(m_symbol, m_period, InpEMA_Mid,   0, MODE_EMA, PRICE_CLOSE);
   m_hEMA_Slow  = iMA(m_symbol, m_period, InpEMA_Slow,  0, MODE_EMA, PRICE_CLOSE);
   m_hEMA_Trend = iMA(m_symbol, m_period, InpEMA_Trend, 0, MODE_EMA, PRICE_CLOSE);

   // Oscillators
   m_hRSI   = iRSI(m_symbol, m_period, InpRSI_Period, PRICE_CLOSE);
   m_hBB    = iBands(m_symbol, m_period, InpBB_Period, 0, InpBB_Deviation, PRICE_CLOSE);
   m_hATR   = iATR(m_symbol, m_period, InpATR_Period);
   m_hMACD  = iMACD(m_symbol, m_period, InpMACD_Fast, InpMACD_Slow, InpMACD_Signal, PRICE_CLOSE);
   m_hStoch = iStochastic(m_symbol, m_period, InpStoch_K, InpStoch_D, InpStoch_Slowing, MODE_SMA, STO_LOWHIGH);
   m_hADX   = iADX(m_symbol, m_period, InpADX_Period);
   m_hCCI   = iCCI(m_symbol, m_period, InpCCI_Period, PRICE_TYPICAL);

   // Validate all handles
   if(m_hEMA_Fast == INVALID_HANDLE || m_hEMA_Mid == INVALID_HANDLE ||
      m_hEMA_Slow == INVALID_HANDLE || m_hEMA_Trend == INVALID_HANDLE ||
      m_hRSI == INVALID_HANDLE || m_hBB == INVALID_HANDLE ||
      m_hATR == INVALID_HANDLE || m_hMACD == INVALID_HANDLE ||
      m_hStoch == INVALID_HANDLE || m_hADX == INVALID_HANDLE ||
      m_hCCI == INVALID_HANDLE)
     {
      PrintFormat("[GA-IND] ERROR: Failed to create indicator handles! Last error: %d", GetLastError());
      Deinit();
      return false;
     }

   // Initialize ATR history array
   ArrayResize(m_atrHistory, 100);
   ArrayInitialize(m_atrHistory, 0);
   m_atrHistCount = 0;

   PrintFormat("[GA-IND] All %d indicator handles created successfully for %s %s",
               11, m_symbol, EnumToString(m_period));
   return true;
  }

//+------------------------------------------------------------------+
//| Release all indicator handles                                     |
//+------------------------------------------------------------------+
void CIndicatorEngine::Deinit()
  {
   if(m_hEMA_Fast  != INVALID_HANDLE) { IndicatorRelease(m_hEMA_Fast);  m_hEMA_Fast  = INVALID_HANDLE; }
   if(m_hEMA_Mid   != INVALID_HANDLE) { IndicatorRelease(m_hEMA_Mid);   m_hEMA_Mid   = INVALID_HANDLE; }
   if(m_hEMA_Slow  != INVALID_HANDLE) { IndicatorRelease(m_hEMA_Slow);  m_hEMA_Slow  = INVALID_HANDLE; }
   if(m_hEMA_Trend != INVALID_HANDLE) { IndicatorRelease(m_hEMA_Trend); m_hEMA_Trend = INVALID_HANDLE; }
   if(m_hRSI       != INVALID_HANDLE) { IndicatorRelease(m_hRSI);       m_hRSI       = INVALID_HANDLE; }
   if(m_hBB        != INVALID_HANDLE) { IndicatorRelease(m_hBB);        m_hBB        = INVALID_HANDLE; }
   if(m_hATR       != INVALID_HANDLE) { IndicatorRelease(m_hATR);       m_hATR       = INVALID_HANDLE; }
   if(m_hMACD      != INVALID_HANDLE) { IndicatorRelease(m_hMACD);      m_hMACD      = INVALID_HANDLE; }
   if(m_hStoch     != INVALID_HANDLE) { IndicatorRelease(m_hStoch);     m_hStoch     = INVALID_HANDLE; }
   if(m_hADX       != INVALID_HANDLE) { IndicatorRelease(m_hADX);       m_hADX       = INVALID_HANDLE; }
   if(m_hCCI       != INVALID_HANDLE) { IndicatorRelease(m_hCCI);       m_hCCI       = INVALID_HANDLE; }
  }

//+------------------------------------------------------------------+
//| Update all indicator buffers (call on new bar)                    |
//+------------------------------------------------------------------+
bool CIndicatorEngine::Update()
  {
   int copied = 0;
   int required = m_bufferSize;

   // Copy price data
   ArraySetAsSeries(m_close,   true);
   ArraySetAsSeries(m_high,    true);
   ArraySetAsSeries(m_low,     true);
   ArraySetAsSeries(m_open,    true);
   ArraySetAsSeries(m_tickVol, true);

   if(CopyClose(m_symbol, m_period, 0, required, m_close)   < required) return false;
   if(CopyHigh(m_symbol, m_period, 0, required, m_high)     < required) return false;
   if(CopyLow(m_symbol, m_period, 0, required, m_low)       < required) return false;
   if(CopyOpen(m_symbol, m_period, 0, required, m_open)     < required) return false;
   if(CopyTickVolume(m_symbol, m_period, 0, required, m_tickVol) < required) return false;

   // Copy standard indicator buffers
   ArraySetAsSeries(m_emaFast,   true);
   ArraySetAsSeries(m_emaMid,    true);
   ArraySetAsSeries(m_emaSlow,   true);
   ArraySetAsSeries(m_emaTrend,  true);
   ArraySetAsSeries(m_rsi,       true);
   ArraySetAsSeries(m_bbUpper,   true);
   ArraySetAsSeries(m_bbMiddle,  true);
   ArraySetAsSeries(m_bbLower,   true);
   ArraySetAsSeries(m_atr,       true);
   ArraySetAsSeries(m_macdMain,  true);
   ArraySetAsSeries(m_macdSignal,true);
   ArraySetAsSeries(m_stochK,    true);
   ArraySetAsSeries(m_stochD,    true);
   ArraySetAsSeries(m_adxMain,   true);
   ArraySetAsSeries(m_adxPlus,   true);
   ArraySetAsSeries(m_adxMinus,  true);
   ArraySetAsSeries(m_cci,       true);

   int minBars = 50;

   if(CopyBuffer(m_hEMA_Fast,  0, 0, required, m_emaFast)   < minBars) return false;
   if(CopyBuffer(m_hEMA_Mid,   0, 0, required, m_emaMid)    < minBars) return false;
   if(CopyBuffer(m_hEMA_Slow,  0, 0, required, m_emaSlow)   < minBars) return false;
   if(CopyBuffer(m_hEMA_Trend, 0, 0, required, m_emaTrend)  < minBars) return false;
   if(CopyBuffer(m_hRSI,       0, 0, required, m_rsi)       < minBars) return false;
   if(CopyBuffer(m_hBB,        1, 0, required, m_bbUpper)   < minBars) return false;  // Buffer 1 = Upper
   if(CopyBuffer(m_hBB,        0, 0, required, m_bbMiddle)  < minBars) return false;  // Buffer 0 = Base
   if(CopyBuffer(m_hBB,        2, 0, required, m_bbLower)   < minBars) return false;  // Buffer 2 = Lower
   if(CopyBuffer(m_hATR,       0, 0, required, m_atr)       < minBars) return false;
   if(CopyBuffer(m_hMACD,      0, 0, required, m_macdMain)  < minBars) return false;  // Buffer 0 = Main
   if(CopyBuffer(m_hMACD,      1, 0, required, m_macdSignal)< minBars) return false;  // Buffer 1 = Signal
   if(CopyBuffer(m_hStoch,     0, 0, required, m_stochK)    < minBars) return false;  // Buffer 0 = %K
   if(CopyBuffer(m_hStoch,     1, 0, required, m_stochD)    < minBars) return false;  // Buffer 1 = %D
   if(CopyBuffer(m_hADX,       0, 0, required, m_adxMain)   < minBars) return false;  // Buffer 0 = ADX
   if(CopyBuffer(m_hADX,       1, 0, required, m_adxPlus)   < minBars) return false;  // Buffer 1 = +DI
   if(CopyBuffer(m_hADX,       2, 0, required, m_adxMinus)  < minBars) return false;  // Buffer 2 = -DI
   if(CopyBuffer(m_hCCI,       0, 0, required, m_cci)       < minBars) return false;

   // Update Kalman filter (use bar 1 = last confirmed bar)
   if(!m_kalmanInitialized && ArraySize(m_close) > 1)
     {
      m_kalman.Init(m_close[1]);
      m_kalmanInitialized = true;
     }
   else if(m_kalmanInitialized)
     {
      m_kalman.Update(m_close[1], InpKalman_Q, InpKalman_R);
     }

   // Calculate custom indicators
   CalcHullMA();
   CalcVWAP();
   CalcZScore();
   CalcOrderFlowImbalance();
   UpdateATRHistory();

   return true;
  }

//+------------------------------------------------------------------+
//| Weighted Moving Average helper                                    |
//+------------------------------------------------------------------+
double CIndicatorEngine::CalcWMA(const double &arr[], int period, int shift)
  {
   if(ArraySize(arr) < shift + period)
      return 0;

   double sum = 0;
   double weightSum = 0;
   for(int i = 0; i < period; i++)
     {
      double weight = (double)(period - i);
      sum += arr[shift + i] * weight;
      weightSum += weight;
     }
   return (weightSum > 0) ? sum / weightSum : 0;
  }

//+------------------------------------------------------------------+
//| Hull Moving Average: HMA = WMA(2*WMA(n/2) - WMA(n), sqrt(n))    |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcHullMA()
  {
   int n = InpHMA_Period;
   int halfN = n / 2;
   int sqrtN = (int)MathRound(MathSqrt((double)n));

   if(ArraySize(m_close) < n + sqrtN + 5)
     {
      ArrayInitialize(m_hma, 0);
      return;
     }

   // Compute intermediate series for several shifts
   double intermediate[];
   ArrayResize(intermediate, sqrtN + 5);

   for(int s = 0; s < sqrtN + 5; s++)
     {
      double wmaHalf = CalcWMA(m_close, halfN, s);
      double wmaFull = CalcWMA(m_close, n, s);
      intermediate[s] = 2.0 * wmaHalf - wmaFull;
     }

   // Final WMA on intermediate series for last 5 shifts
   for(int i = 0; i < 5; i++)
     {
      if(ArraySize(intermediate) < i + sqrtN)
        {
         m_hma[i] = 0;
         continue;
        }
      double sum = 0, wsum = 0;
      for(int j = 0; j < sqrtN; j++)
        {
         double w = (double)(sqrtN - j);
         sum += intermediate[i + j] * w;
         wsum += w;
        }
      m_hma[i] = (wsum > 0) ? sum / wsum : 0;
     }
  }

//+------------------------------------------------------------------+
//| Volume-Weighted Average Price (session-based)                     |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcVWAP()
  {
   int lookback = MathMin((int)InpVWAP_ResetBars, ArraySize(m_close));
   if(lookback < 5)
     {
      m_vwap = 0;
      return;
     }

   double cumPV = 0;  // Cumulative price * volume
   double cumV  = 0;  // Cumulative volume

   for(int i = lookback - 1; i >= 0; i--)
     {
      double typicalPrice = (m_high[i] + m_low[i] + m_close[i]) / 3.0;
      double vol = (double)m_tickVol[i];
      if(vol <= 0) vol = 1;

      cumPV += typicalPrice * vol;
      cumV  += vol;
     }

   m_vwap = (cumV > 0) ? cumPV / cumV : m_close[0];
  }

//+------------------------------------------------------------------+
//| Z-Score: (price - SMA) / StdDev                                  |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcZScore()
  {
   int period = MathMin((int)InpZScore_Period, ArraySize(m_close));
   if(period < 10)
     {
      m_zscore = 0;
      return;
     }

   // Calculate SMA
   double sum = 0;
   for(int i = 0; i < period; i++)
      sum += m_close[i];
   double sma = sum / period;

   // Calculate StdDev
   double sumSq = 0;
   for(int i = 0; i < period; i++)
     {
      double diff = m_close[i] - sma;
      sumSq += diff * diff;
     }
   double stddev = MathSqrt(sumSq / period);

   m_zscore = (stddev > 0) ? (m_close[0] - sma) / stddev : 0;
  }

//+------------------------------------------------------------------+
//| Order Flow Imbalance from candle geometry                         |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcOrderFlowImbalance()
  {
   int smooth = MathMin((int)InpOFI_Smooth, ArraySize(m_close));
   if(smooth < 2)
     {
      m_ofi = 0;
      m_buyPressure = 0.5;
      m_sellPressure = 0.5;
      return;
     }

   double sumBuyP  = 0;
   double sumSellP = 0;
   int validBars = 0;

   for(int i = 0; i < smooth; i++)
     {
      double range = m_high[i] - m_low[i];
      if(range <= 0) continue;

      double bp = (m_close[i] - m_low[i]) / range;    // Buy pressure: how close to high
      double sp = (m_high[i] - m_close[i]) / range;    // Sell pressure: how close to low

      // Weight by volume
      double volWeight = (double)m_tickVol[i];
      if(volWeight <= 0) volWeight = 1;

      // Weight recent bars more (exponential decay)
      double timeWeight = MathExp(-0.3 * i);

      sumBuyP  += bp * volWeight * timeWeight;
      sumSellP += sp * volWeight * timeWeight;
      validBars++;
     }

   if(validBars > 0 && (sumBuyP + sumSellP) > 0)
     {
      double total = sumBuyP + sumSellP;
      m_buyPressure  = sumBuyP / total;
      m_sellPressure = sumSellP / total;
      m_ofi = m_buyPressure - m_sellPressure;  // Range: -1 to +1
     }
   else
     {
      m_buyPressure = 0.5;
      m_sellPressure = 0.5;
      m_ofi = 0;
     }
  }

//+------------------------------------------------------------------+
//| Update ATR history for percentile calculation                     |
//+------------------------------------------------------------------+
void CIndicatorEngine::UpdateATRHistory()
  {
   if(ArraySize(m_atr) < 1) return;

   // Circular buffer of last 100 ATR values
   int idx = m_atrHistCount % 100;
   m_atrHistory[idx] = m_atr[0];
   m_atrHistCount++;
  }

//+------------------------------------------------------------------+
//| ATR Percentile (0-100) - where current ATR ranks                  |
//+------------------------------------------------------------------+
double CIndicatorEngine::ATRPercentile()
  {
   int count = MathMin(m_atrHistCount, 100);
   if(count < 10) return 50.0;  // Not enough data, assume median

   double currentATR = m_atr[0];
   int below = 0;

   for(int i = 0; i < count; i++)
     {
      if(m_atrHistory[i] < currentATR)
         below++;
     }

   return (double)below / (double)count * 100.0;
  }

//+------------------------------------------------------------------+
//| Market Regime Detection                                           |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME CIndicatorEngine::DetectRegime(double &confidence)
  {
   confidence = 0;

   if(ArraySize(m_adxMain) < 3 || ArraySize(m_atr) < 3)
      return REGIME_UNKNOWN;

   double adx       = m_adxMain[1];     // Use bar 1 (confirmed)
   double plusDI     = m_adxPlus[1];
   double minusDI   = m_adxMinus[1];
   double bbWidth    = BB_Bandwidth();
   double atrPct    = ATRPercentile();
   double kalVel    = KalmanVelocity();

   // Scoring system for regime
   double trendUpScore   = 0;
   double trendDownScore = 0;
   double rangeScore     = 0;
   double volatileScore  = 0;

   //--- ADX-based regime (primary signal)
   if(adx > 25)
     {
      if(plusDI > minusDI)
         trendUpScore += 3.0;
      else
         trendDownScore += 3.0;
     }
   else if(adx < 20)
     {
      rangeScore += 2.5;
     }
   else
     {
      // Transitional zone
      if(plusDI > minusDI)
         trendUpScore += 1.0;
      else
         trendDownScore += 1.0;
      rangeScore += 1.0;
     }

   //--- Bollinger bandwidth
   if(bbWidth < 0.01)     // Tight squeeze
      rangeScore += 2.0;
   else if(bbWidth > 0.03) // Wide bands = volatile
      volatileScore += 2.0;

   //--- ATR percentile
   if(atrPct > 85)
      volatileScore += 2.0;
   else if(atrPct < 15)
      rangeScore += 1.5;

   //--- Kalman velocity direction
   if(kalVel > 0)
      trendUpScore += 1.5;
   else if(kalVel < 0)
      trendDownScore += 1.5;

   //--- EMA alignment
   double emaF = EMA_Fast(1);
   double emaM = EMA_Mid(1);
   double emaS = EMA_Slow(1);

   if(emaF > emaM && emaM > emaS)
      trendUpScore += 1.5;
   else if(emaF < emaM && emaM < emaS)
      trendDownScore += 1.5;
   else
      rangeScore += 1.0;

   // Find dominant regime
   double scores[4];
   scores[0] = trendUpScore;
   scores[1] = trendDownScore;
   scores[2] = rangeScore;
   scores[3] = volatileScore;

   double maxScore = 0;
   int maxIdx = 4;  // UNKNOWN
   double totalScore = 0;

   for(int i = 0; i < 4; i++)
     {
      totalScore += scores[i];
      if(scores[i] > maxScore)
        {
         maxScore = scores[i];
         maxIdx = i;
        }
     }

   // Confidence = dominant score / total score
   confidence = (totalScore > 0) ? maxScore / totalScore : 0;

   // Require minimum score to declare a regime
   if(maxScore < 3.0)
     {
      confidence *= 0.5;
      return REGIME_UNKNOWN;
     }

   // Volatile regime overrides if extreme
   if(volatileScore >= 3.5)
     {
      confidence = volatileScore / totalScore;
      return REGIME_VOLATILE;
     }

   switch(maxIdx)
     {
      case 0: return REGIME_TRENDING_UP;
      case 1: return REGIME_TRENDING_DOWN;
      case 2: return REGIME_RANGING;
      case 3: return REGIME_VOLATILE;
      default: return REGIME_UNKNOWN;
     }
  }

#endif // __GA_INDICATORS_MQH__
