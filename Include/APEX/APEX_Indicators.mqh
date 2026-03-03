//+------------------------------------------------------------------+
//|                                            APEX_Indicators.mqh   |
//|              APEX Gold Destroyer - Custom Indicator Engine        |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_INDICATORS_MQH
#define APEX_INDICATORS_MQH

#include "APEX_Config.mqh"

//+------------------------------------------------------------------+
//| Kalman Filter State                                               |
//+------------------------------------------------------------------+
struct KalmanState
  {
   double            x;        // Estimated price
   double            P;        // Error covariance
   double            velocity; // Price velocity (x - x_prev)
   double            deviation;// Measurement - estimate
   double            x_prev;   // Previous estimate
  };

//+------------------------------------------------------------------+
//| Custom Indicator Engine                                           |
//+------------------------------------------------------------------+
class CIndicatorEngine
  {
private:
   string            m_symbol;
   bool              m_initialized;

   // Kalman state
   KalmanState       m_kalman;
   bool              m_kalmanReady;

   // Cached custom values
   double            m_hmaValue;
   double            m_hmaPrev;
   double            m_vwap;
   double            m_vwapDev;
   double            m_zScore;
   double            m_ofi;
   double            m_bbBandwidth;
   bool              m_bbSqueeze;
   bool              m_bbExpansion;
   bool              m_volumeSpike;
   double            m_volumeRatio;
   double            m_tickFlowBias;   // From CopyTicks analysis

   // Internal computation methods
   void              UpdateKalman(double price);
   double            CalcWMA(const double &data[], int period, int shift);
   void              CalcHMA(const double &close[], int len);
   void              CalcVWAP(const double &high[], const double &low[], const double &close[], const long &vol[], int len);
   void              CalcZScore(const double &close[], int period);
   void              CalcOFI(const double &open[], const double &high[], const double &low[], const double &close[], const long &vol[], int period);
   void              CalcBBMetrics(double upper, double middle, double lower, double prevUpper, double prevMiddle, double prevLower);
   void              CalcVolumeSpike(const long &vol[], int period);
   void              CalcTickFlow();

public:
                     CIndicatorEngine();
                    ~CIndicatorEngine();
   bool              Init(string symbol);
   void              Deinit();
   bool              Update(const double &open[], const double &high[], const double &low[],
                           const double &close[], const long &vol[], int bars,
                           double bbUpper, double bbMiddle, double bbLower,
                           double bbUpperPrev, double bbMiddlePrev, double bbLowerPrev);

   // Kalman accessors
   double            KalmanPrice()    { return m_kalman.x; }
   double            KalmanVelocity() { return m_kalman.velocity; }
   double            KalmanDeviation(){ return m_kalman.deviation; }
   bool              KalmanReady()    { return m_kalmanReady; }

   // Custom indicator accessors
   double            HMA()            { return m_hmaValue; }
   double            HMAPrev()        { return m_hmaPrev; }
   int               HMADirection()   { return (m_hmaValue > m_hmaPrev) ? +1 : ((m_hmaValue < m_hmaPrev) ? -1 : 0); }
   double            VWAP()           { return m_vwap; }
   double            VWAPDev()        { return m_vwapDev; }
   double            ZScore()         { return m_zScore; }
   double            OFI()            { return m_ofi; }
   double            BBBandwidth()    { return m_bbBandwidth; }
   bool              BBSqueeze()      { return m_bbSqueeze; }
   bool              BBExpansion()    { return m_bbExpansion; }
   bool              VolumeSpike()    { return m_volumeSpike; }
   double            VolumeRatio()    { return m_volumeRatio; }
   double            TickFlowBias()   { return m_tickFlowBias; }

   // Candlestick pattern detection
   int               DetectCandlePattern(double o1, double h1, double l1, double c1,
                                         double o2, double h2, double l2, double c2);
  };

//+------------------------------------------------------------------+
CIndicatorEngine::CIndicatorEngine()
  {
   m_initialized = false;
   m_kalmanReady = false;
   m_hmaValue = 0; m_hmaPrev = 0;
   m_vwap = 0; m_vwapDev = 0;
   m_zScore = 0; m_ofi = 0;
   m_bbBandwidth = 0; m_bbSqueeze = false; m_bbExpansion = false;
   m_volumeSpike = false; m_volumeRatio = 1.0;
   m_tickFlowBias = 0;
   ZeroMemory(m_kalman);
  }

//+------------------------------------------------------------------+
CIndicatorEngine::~CIndicatorEngine()
  {
   Deinit();
  }

//+------------------------------------------------------------------+
bool CIndicatorEngine::Init(string symbol)
  {
   m_symbol = symbol;
   m_kalmanReady = false;
   m_kalman.x = 0;
   m_kalman.P = 1.0;
   m_kalman.velocity = 0;
   m_kalman.deviation = 0;
   m_kalman.x_prev = 0;
   m_initialized = true;
   return true;
  }

//+------------------------------------------------------------------+
void CIndicatorEngine::Deinit()
  {
   m_initialized = false;
  }

//+------------------------------------------------------------------+
bool CIndicatorEngine::Update(const double &open[], const double &high[], const double &low[],
                              const double &close[], const long &vol[], int bars,
                              double bbUpper, double bbMiddle, double bbLower,
                              double bbUpperPrev, double bbMiddlePrev, double bbLowerPrev)
  {
   if(!m_initialized || bars < InpZScore_Period + 5) return false;

   // Kalman filter on latest close
   UpdateKalman(close[1]);

   // Hull MA
   CalcHMA(close, bars);

   // VWAP
   CalcVWAP(high, low, close, vol, bars);

   // Z-Score
   CalcZScore(close, InpZScore_Period);

   // Order Flow Imbalance
   CalcOFI(open, high, low, close, vol, InpOFI_Period);

   // BB Bandwidth & Squeeze
   CalcBBMetrics(bbUpper, bbMiddle, bbLower, bbUpperPrev, bbMiddlePrev, bbLowerPrev);

   // Volume Spike
   CalcVolumeSpike(vol, InpVolSpike_Period);

   // Tick-level flow analysis
   CalcTickFlow();

   return true;
  }

//+------------------------------------------------------------------+
//| Scalar 1D Kalman Filter                                          |
//+------------------------------------------------------------------+
void CIndicatorEngine::UpdateKalman(double price)
  {
   if(!m_kalmanReady)
     {
      m_kalman.x = price;
      m_kalman.P = 1.0;
      m_kalman.x_prev = price;
      m_kalman.velocity = 0;
      m_kalman.deviation = 0;
      m_kalmanReady = true;
      return;
     }

   m_kalman.x_prev = m_kalman.x;

   // Predict
   double P_pred = m_kalman.P + InpKalman_Q;

   // Update
   double K = P_pred / (P_pred + InpKalman_R);
   m_kalman.deviation = price - m_kalman.x;
   m_kalman.x = m_kalman.x + K * m_kalman.deviation;
   m_kalman.P = (1.0 - K) * P_pred;

   // Velocity
   m_kalman.velocity = m_kalman.x - m_kalman.x_prev;
  }

//+------------------------------------------------------------------+
//| Weighted Moving Average helper                                    |
//+------------------------------------------------------------------+
double CIndicatorEngine::CalcWMA(const double &data[], int period, int shift)
  {
   if(ArraySize(data) < shift + period) return 0;
   double sum = 0, wSum = 0;
   for(int i = 0; i < period; i++)
     {
      double w = (double)(period - i);
      sum  += data[shift + i] * w;
      wSum += w;
     }
   return (wSum > 0) ? sum / wSum : 0;
  }

//+------------------------------------------------------------------+
//| Hull Moving Average: HMA(n) = WMA(√n, 2×WMA(n/2) - WMA(n))     |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcHMA(const double &close[], int len)
  {
   int period = InpHMA_Period;
   int halfN  = period / 2;
   int sqrtN  = (int)MathSqrt((double)period);
   if(sqrtN < 1) sqrtN = 1;

   int need = period + sqrtN + 5;
   if(len < need) return;

   // Build intermediate series: 2*WMA(halfN) - WMA(period)
   double intermediate[];
   int intLen = sqrtN + 3;
   ArrayResize(intermediate, intLen);

   for(int i = 0; i < intLen; i++)
     {
      double wmaHalf = CalcWMA(close, halfN, i + 1);
      double wmaFull = CalcWMA(close, period, i + 1);
      intermediate[i] = 2.0 * wmaHalf - wmaFull;
     }

   // Save previous before updating
   m_hmaPrev = m_hmaValue;

   // Final WMA of intermediate series
   double sum = 0, wSum = 0;
   for(int i = 0; i < sqrtN; i++)
     {
      double w = (double)(sqrtN - i);
      sum  += intermediate[i] * w;
      wSum += w;
     }
   m_hmaValue = (wSum > 0) ? sum / wSum : close[1];
  }

//+------------------------------------------------------------------+
//| VWAP = Σ(TP × Vol) / Σ(Vol)                                     |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcVWAP(const double &high[], const double &low[], const double &close[],
                                const long &vol[], int len)
  {
   int period = MathMin(InpVWAP_ResetBars, len - 1);
   double sumTPV = 0, sumV = 0;
   double sumDev2 = 0;

   for(int i = 1; i <= period; i++)
     {
      double tp = (high[i] + low[i] + close[i]) / 3.0;
      double v  = (double)vol[i];
      if(v < 1) v = 1;
      sumTPV += tp * v;
      sumV   += v;
     }

   m_vwap = (sumV > 0) ? sumTPV / sumV : close[1];

   // VWAP deviation
   for(int i = 1; i <= period; i++)
     {
      double tp = (high[i] + low[i] + close[i]) / 3.0;
      double v  = (double)vol[i];
      if(v < 1) v = 1;
      sumDev2 += v * (tp - m_vwap) * (tp - m_vwap);
     }
   m_vwapDev = (sumV > 0) ? MathSqrt(sumDev2 / sumV) : 0;
  }

//+------------------------------------------------------------------+
//| Z-Score = (close - SMA) / StdDev                                 |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcZScore(const double &close[], int period)
  {
   if(ArraySize(close) < period + 2) { m_zScore = 0; return; }

   double sum = 0;
   for(int i = 1; i <= period; i++)
      sum += close[i];
   double mean = sum / period;

   double sumSq = 0;
   for(int i = 1; i <= period; i++)
      sumSq += (close[i] - mean) * (close[i] - mean);
   double sd = MathSqrt(sumSq / period);

   m_zScore = (sd > 0) ? (close[1] - mean) / sd : 0;
  }

//+------------------------------------------------------------------+
//| Order Flow Imbalance (candle geometry + exponential decay)        |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcOFI(const double &open[], const double &high[], const double &low[],
                               const double &close[], const long &vol[], int period)
  {
   int count = MathMin(period, ArraySize(close) - 2);
   if(count < 1) { m_ofi = 0; return; }

   double sumBP = 0, sumSP = 0;
   for(int i = 1; i <= count; i++)
     {
      double range = high[i] - low[i];
      if(range < SymbolInfoDouble(m_symbol, SYMBOL_POINT)) continue;

      double buyPressure  = (close[i] - low[i]) / range;
      double sellPressure = (high[i] - close[i]) / range;
      double weight = (double)vol[i] * MathExp(-InpOFI_Decay * (double)(i - 1));

      sumBP += buyPressure * weight;
      sumSP += sellPressure * weight;
     }

   double total = sumBP + sumSP;
   m_ofi = (total > 0) ? (sumBP - sumSP) / total : 0;
  }

//+------------------------------------------------------------------+
//| Bollinger Bandwidth & Squeeze Detection                          |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcBBMetrics(double upper, double middle, double lower,
                                     double prevUpper, double prevMiddle, double prevLower)
  {
   m_bbBandwidth = (middle > 0) ? (upper - lower) / middle : 0;

   double prevBW = (prevMiddle > 0) ? (prevUpper - prevLower) / prevMiddle : 0;

   m_bbSqueeze   = (m_bbBandwidth < InpBBSqueeze_Thresh);
   m_bbExpansion = (m_bbBandwidth > prevBW * 1.2 && prevBW < InpBBSqueeze_Thresh * 1.5);
  }

//+------------------------------------------------------------------+
//| Volume Spike Detection                                           |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcVolumeSpike(const long &vol[], int period)
  {
   int count = MathMin(period, ArraySize(vol) - 2);
   if(count < 2) { m_volumeSpike = false; m_volumeRatio = 1.0; return; }

   double sum = 0;
   for(int i = 2; i <= count + 1; i++)
      sum += (double)vol[i];
   double avg = sum / count;

   m_volumeRatio = (avg > 0) ? (double)vol[1] / avg : 1.0;
   m_volumeSpike = (m_volumeRatio >= InpVolSpike_Mult);
  }

//+------------------------------------------------------------------+
//| Tick-Level Flow Analysis using CopyTicks                         |
//+------------------------------------------------------------------+
void CIndicatorEngine::CalcTickFlow()
  {
   MqlTick ticks[];
   int copied = CopyTicks(m_symbol, ticks, COPY_TICKS_ALL, 0, InpTickFootprintCount);
   if(copied < 50)
     {
      m_tickFlowBias = 0;
      return;
     }

   double buyTicks = 0, sellTicks = 0;
   for(int i = 1; i < copied; i++)
     {
      // Uptick = last traded at ask or higher
      if(ticks[i].last >= ticks[i].ask)
         buyTicks += 1.0;
      // Downtick = last traded at bid or lower
      else if(ticks[i].last <= ticks[i].bid)
         sellTicks += 1.0;
      else
        {
         // Classify by price change direction
         if(ticks[i].last > ticks[i-1].last)
            buyTicks += 0.5;
         else if(ticks[i].last < ticks[i-1].last)
            sellTicks += 0.5;
        }
     }

   double total = buyTicks + sellTicks;
   m_tickFlowBias = (total > 0) ? (buyTicks - sellTicks) / total : 0;
  }

//+------------------------------------------------------------------+
//| Candlestick Pattern Detection                                    |
//| Returns +1 for bullish, -1 for bearish, 0 for none               |
//+------------------------------------------------------------------+
int CIndicatorEngine::DetectCandlePattern(double o1, double h1, double l1, double c1,
                                          double o2, double h2, double l2, double c2)
  {
   double body1 = MathAbs(c1 - o1);
   double body2 = MathAbs(c2 - o2);
   double range1 = h1 - l1;
   double range2 = h2 - l2;
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   if(point == 0) point = 0.01;

   // Bullish Engulfing: prev bearish, current bullish, body engulfs
   if(c2 < o2 && c1 > o1 && o1 <= c2 && c1 >= o2 && body1 > body2)
      return +1;

   // Bearish Engulfing: prev bullish, current bearish, body engulfs
   if(c2 > o2 && c1 < o1 && o1 >= c2 && c1 <= o2 && body1 > body2)
      return -1;

   // Bullish Pin Bar: small body at top, long lower shadow
   double lowerShadow1 = MathMin(o1, c1) - l1;
   double upperShadow1 = h1 - MathMax(o1, c1);
   if(range1 > 0 && lowerShadow1 > body1 * 2.0 && upperShadow1 < body1 * 0.5 && range1 > point * 50)
      return +1;

   // Bearish Pin Bar: small body at bottom, long upper shadow
   if(range1 > 0 && upperShadow1 > body1 * 2.0 && lowerShadow1 < body1 * 0.5 && range1 > point * 50)
      return -1;

   // Bullish Hammer (after down move: c2 < o2)
   if(c2 < o2 && lowerShadow1 > body1 * 2.0 && c1 > o1)
      return +1;

   // Shooting Star (after up move: c2 > o2)
   if(c2 > o2 && upperShadow1 > body1 * 2.0 && c1 < o1)
      return -1;

   // Strong Momentum Candle (large body, small shadows)
   if(body1 > range1 * 0.7 && range1 > point * 80)
     {
      if(c1 > o1) return +1;
      if(c1 < o1) return -1;
     }

   return 0;
  }

#endif // APEX_INDICATORS_MQH
