//+------------------------------------------------------------------+
//|                                              APEX_Signals.mqh    |
//|           APEX Gold Destroyer - 20-Component Signal Engine       |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_SIGNALS_MQH
#define APEX_SIGNALS_MQH

#include "APEX_Config.mqh"
#include "APEX_MTF.mqh"
#include "APEX_Indicators.mqh"
#include "APEX_HMM.mqh"
#include "APEX_OrderFlow.mqh"

//+------------------------------------------------------------------+
//| Signal Engine - 20 Component Weighted Scoring                     |
//+------------------------------------------------------------------+
class CSignalEngine
  {
private:
   CMTFEngine        *m_mtf;
   CIndicatorEngine  *m_ind;
   CHMMEngine        *m_hmm;
   COrderFlowEngine  *m_flow;
   string            m_symbol;

   // Score breakdown
   double            m_componentScores[20];  // Individual scores
   string            m_componentNames[20];

   // Internal scoring methods
   double            ScoreHTFTrend(ENUM_APEX_SIGNAL dir);
   double            ScoreEMAStack(ENUM_APEX_SIGNAL dir, const ApexTFData &m5);
   double            ScoreEMACross(ENUM_APEX_SIGNAL dir, const ApexTFData &m5);
   double            ScoreKalmanVel(ENUM_APEX_SIGNAL dir);
   double            ScoreHMADir(ENUM_APEX_SIGNAL dir);
   double            ScoreMACDHist(ENUM_APEX_SIGNAL dir, const ApexTFData &m5);
   double            ScoreRSIMomentum(ENUM_APEX_SIGNAL dir, const ApexTFData &m5);
   double            ScoreRSIExtreme(ENUM_APEX_SIGNAL dir, const ApexTFData &m5);
   double            ScoreStochCross(ENUM_APEX_SIGNAL dir, const ApexTFData &m5);
   double            ScoreCCIExtreme(ENUM_APEX_SIGNAL dir, const ApexTFData &m5);
   double            ScoreBBTouch(ENUM_APEX_SIGNAL dir, const ApexTFData &m5, ENUM_APEX_REGIME regime);
   double            ScoreBBSqueeze(ENUM_APEX_SIGNAL dir, const ApexTFData &m5);
   double            ScoreZScore(ENUM_APEX_SIGNAL dir);
   double            ScoreVWAPCross(ENUM_APEX_SIGNAL dir, double price);
   double            ScoreOFICandle(ENUM_APEX_SIGNAL dir);
   double            ScoreDOMImbalance(ENUM_APEX_SIGNAL dir);
   double            ScoreVolSpike(ENUM_APEX_SIGNAL dir, const ApexTFData &m5);
   double            ScoreFootprint(ENUM_APEX_SIGNAL dir);
   double            ScoreHMMState(ENUM_APEX_SIGNAL dir);
   double            ScoreCandlePattern(ENUM_APEX_SIGNAL dir, double o1, double h1, double l1, double c1,
                                        double o2, double h2, double l2, double c2);

   double            ComputeWeightedScore(ENUM_APEX_SIGNAL dir, ENUM_APEX_REGIME regime);
   ENUM_APEX_STRATEGY DetermineStrategy(ENUM_APEX_REGIME regime, double buyScore, double sellScore,
                                         const ApexTFData &m5);

public:
                     CSignalEngine();
                    ~CSignalEngine();
   bool              Init(string symbol, CMTFEngine *mtf, CIndicatorEngine *ind,
                         CHMMEngine *hmm, COrderFlowEngine *flow);
   void              Deinit();

   ApexSignal        GenerateSignal(ApexRegime &regime);
   string            GetScoreBreakdown();
  };

//+------------------------------------------------------------------+
CSignalEngine::CSignalEngine()
  {
   m_mtf = NULL; m_ind = NULL; m_hmm = NULL; m_flow = NULL;
   m_componentNames[0]  = "HTF_Trend";
   m_componentNames[1]  = "EMA_Stack";
   m_componentNames[2]  = "EMA_Cross";
   m_componentNames[3]  = "Kalman_Vel";
   m_componentNames[4]  = "HMA_Dir";
   m_componentNames[5]  = "MACD_Hist";
   m_componentNames[6]  = "RSI_Mom";
   m_componentNames[7]  = "RSI_Ext";
   m_componentNames[8]  = "Stoch_X";
   m_componentNames[9]  = "CCI_Ext";
   m_componentNames[10] = "BB_Touch";
   m_componentNames[11] = "BB_Squeeze";
   m_componentNames[12] = "ZScore";
   m_componentNames[13] = "VWAP";
   m_componentNames[14] = "OFI_Cdl";
   m_componentNames[15] = "DOM_Imb";
   m_componentNames[16] = "Vol_Spike";
   m_componentNames[17] = "Footprint";
   m_componentNames[18] = "HMM_State";
   m_componentNames[19] = "Candle_Pat";
   ArrayInitialize(m_componentScores, 0);
  }

//+------------------------------------------------------------------+
CSignalEngine::~CSignalEngine() { Deinit(); }

//+------------------------------------------------------------------+
bool CSignalEngine::Init(string symbol, CMTFEngine *mtf, CIndicatorEngine *ind,
                         CHMMEngine *hmm, COrderFlowEngine *flow)
  {
   m_symbol = symbol;
   m_mtf  = mtf;
   m_ind  = ind;
   m_hmm  = hmm;
   m_flow = flow;
   return (m_mtf != NULL && m_ind != NULL);
  }

//+------------------------------------------------------------------+
void CSignalEngine::Deinit() { }

//+------------------------------------------------------------------+
//| CORE: Generate Signal with full 20-component scoring              |
//+------------------------------------------------------------------+
ApexSignal CSignalEngine::GenerateSignal(ApexRegime &regime)
  {
   ApexSignal sig;
   ZeroMemory(sig);
   sig.direction = SIGNAL_NONE;
   sig.regime = regime.state;

   // Compute scores for both directions
   double buyScore  = ComputeWeightedScore(SIGNAL_BUY, regime.state);
   double sellScore = ComputeWeightedScore(SIGNAL_SELL, regime.state);

   // Apply entropy discount
   if(m_hmm != NULL && m_hmm.IsHighEntropy())
     {
      buyScore  *= InpEntropyDiscount;
      sellScore *= InpEntropyDiscount;
     }

   // Apply counter-HTF penalty
   int htfBias = m_mtf.GetHTFBias();
   if(htfBias > 0)   sellScore += InpCounterHTFPenalty;  // Penalty for selling in bull HTF
   if(htfBias < 0)   buyScore  += InpCounterHTFPenalty;  // Penalty for buying in bear HTF

   // Determine direction
   double minBuy  = InpMinBuyScore;
   double minSell = InpMinSellScore;

   bool buyValid  = (buyScore >= minBuy);
   bool sellValid = (sellScore >= minSell);

   if(buyValid && sellValid)
     {
      // Both valid - pick stronger
      sig.direction = (buyScore >= sellScore) ? SIGNAL_BUY : SIGNAL_SELL;
      sig.score = MathMax(buyScore, sellScore);
     }
   else if(buyValid)
     {
      sig.direction = SIGNAL_BUY;
      sig.score = buyScore;
     }
   else if(sellValid)
     {
      sig.direction = SIGNAL_SELL;
      sig.score = sellScore;
     }
   else
     {
      sig.direction = SIGNAL_NONE;
      sig.score = MathMax(buyScore, sellScore);
      return sig;
     }

   // Normalize score to 0-100
   double maxPossibleScore = 50.0; // Approximate max weighted score
   sig.normalizedScore = MathMin(sig.score / maxPossibleScore * 100.0, 100.0);
   sig.confidence = sig.normalizedScore / 100.0;

   // Determine strategy
   ApexTFData m5 = m_mtf.GetData(PERIOD_M5);
   sig.strategy = DetermineStrategy(regime.state, buyScore, sellScore, m5);

   // Compute SL/TP based on ATR
   double atr = m_mtf.GetATR(PERIOD_M5);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);

   if(sig.direction == SIGNAL_BUY)
     {
      sig.sl  = ask - atr * InpSL_ATR_Mult;
      sig.tp1 = ask + atr * InpTP1_ATR_Mult;
      sig.tp2 = (sig.normalizedScore >= InpHighConfScore)
                ? ask + atr * InpTP_HighConf_Mult
                : ask + atr * InpTP2_ATR_Mult;
     }
   else
     {
      sig.sl  = bid + atr * InpSL_ATR_Mult;
      sig.tp1 = bid - atr * InpTP1_ATR_Mult;
      sig.tp2 = (sig.normalizedScore >= InpHighConfScore)
                ? bid - atr * InpTP_HighConf_Mult
                : bid - atr * InpTP2_ATR_Mult;
     }

   sig.components = GetScoreBreakdown();
   return sig;
  }

//+------------------------------------------------------------------+
//| Compute weighted score for a direction                            |
//+------------------------------------------------------------------+
double CSignalEngine::ComputeWeightedScore(ENUM_APEX_SIGNAL dir, ENUM_APEX_REGIME regime)
  {
   // Get weight profile for current regime
   ApexWeightProfile wp;
   GetWeightProfile(regime, wp);

   ApexTFData m5 = m_mtf.GetData(PERIOD_M5);
   double price = m_mtf.GetM5Close(1);

   // Get candle data for pattern detection
   double o1 = m_mtf.GetM5Open(1);
   double h1 = m_mtf.GetM5High(1);
   double l1 = m_mtf.GetM5Low(1);
   double c1 = m_mtf.GetM5Close(1);
   double o2 = m_mtf.GetM5Open(2);
   double h2 = m_mtf.GetM5High(2);
   double l2 = m_mtf.GetM5Low(2);
   double c2 = m_mtf.GetM5Close(2);

   // Score all 20 components
   m_componentScores[0]  = ScoreHTFTrend(dir)                           * wp.htfTrend;
   m_componentScores[1]  = ScoreEMAStack(dir, m5)                       * wp.emaStack;
   m_componentScores[2]  = ScoreEMACross(dir, m5)                       * wp.emaCross;
   m_componentScores[3]  = ScoreKalmanVel(dir)                          * wp.kalmanVel;
   m_componentScores[4]  = ScoreHMADir(dir)                             * wp.hmaDir;
   m_componentScores[5]  = ScoreMACDHist(dir, m5)                       * wp.macdHist;
   m_componentScores[6]  = ScoreRSIMomentum(dir, m5)                    * wp.rsiMomentum;
   m_componentScores[7]  = ScoreRSIExtreme(dir, m5)                     * wp.rsiExtreme;
   m_componentScores[8]  = ScoreStochCross(dir, m5)                     * wp.stochCross;
   m_componentScores[9]  = ScoreCCIExtreme(dir, m5)                     * wp.cciExtreme;
   m_componentScores[10] = ScoreBBTouch(dir, m5, regime)                * wp.bbTouch;
   m_componentScores[11] = ScoreBBSqueeze(dir, m5)                      * wp.bbSqueeze;
   m_componentScores[12] = ScoreZScore(dir)                             * wp.zScore;
   m_componentScores[13] = ScoreVWAPCross(dir, price)                   * wp.vwapCross;
   m_componentScores[14] = ScoreOFICandle(dir)                          * wp.ofiCandle;
   m_componentScores[15] = ScoreDOMImbalance(dir)                       * wp.domImbalance;
   m_componentScores[16] = ScoreVolSpike(dir, m5)                       * wp.volSpike;
   m_componentScores[17] = ScoreFootprint(dir)                          * wp.footprint;
   m_componentScores[18] = ScoreHMMState(dir)                           * wp.hmmState;
   m_componentScores[19] = ScoreCandlePattern(dir, o1,h1,l1,c1, o2,h2,l2,c2) * wp.candlePattern;

   // Sum all scores (only count positives for direction scoring)
   double total = 0;
   for(int i = 0; i < 20; i++)
      total += m_componentScores[i];

   return total;
  }

//+------------------------------------------------------------------+
//| #1 HTF Trend Consensus (H1 + H4)                                 |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreHTFTrend(ENUM_APEX_SIGNAL dir)
  {
   int bias = m_mtf.GetHTFBias();
   if(dir == SIGNAL_BUY  && bias > 0)  return 2.0;
   if(dir == SIGNAL_SELL && bias < 0)  return 2.0;
   if(dir == SIGNAL_BUY  && bias < 0)  return -1.0;
   if(dir == SIGNAL_SELL && bias > 0)  return -1.0;
   return 0;
  }

//+------------------------------------------------------------------+
//| #2 M5 EMA Stack Alignment (8 > 21 > 55 > 200)                    |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreEMAStack(ENUM_APEX_SIGNAL dir, const ApexTFData &m5)
  {
   bool bullStack = (m5.emaFast > m5.emaMid && m5.emaMid > m5.emaSlow && m5.emaSlow > m5.emaLong);
   bool bearStack = (m5.emaFast < m5.emaMid && m5.emaMid < m5.emaSlow && m5.emaSlow < m5.emaLong);

   if(dir == SIGNAL_BUY  && bullStack)  return 2.0;
   if(dir == SIGNAL_SELL && bearStack)  return 2.0;
   if(dir == SIGNAL_BUY  && bearStack)  return -1.0;
   if(dir == SIGNAL_SELL && bullStack)  return -1.0;

   // Partial alignment
   bool partBull = (m5.emaFast > m5.emaMid && m5.emaMid > m5.emaSlow);
   bool partBear = (m5.emaFast < m5.emaMid && m5.emaMid < m5.emaSlow);
   if(dir == SIGNAL_BUY  && partBull)  return 1.0;
   if(dir == SIGNAL_SELL && partBear)  return 1.0;

   return 0;
  }

//+------------------------------------------------------------------+
//| #3 EMA Crossover (Fast/Mid)                                       |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreEMACross(ENUM_APEX_SIGNAL dir, const ApexTFData &m5)
  {
   // Check if fast just crossed above/below mid
   double buf_f[], buf_m[];
   ArraySetAsSeries(buf_f, true);
   ArraySetAsSeries(buf_m, true);

   int idxM5 = 1; // TFIndex for M5
   // Use current vs previous bar relationship
   bool fastAboveMid = (m5.emaFast > m5.emaMid);

   if(dir == SIGNAL_BUY  && fastAboveMid && m5.emaFast > m5.emaSlow)  return 1.5;
   if(dir == SIGNAL_SELL && !fastAboveMid && m5.emaFast < m5.emaSlow) return 1.5;
   if(dir == SIGNAL_BUY  && fastAboveMid)  return 0.5;
   if(dir == SIGNAL_SELL && !fastAboveMid) return 0.5;
   return 0;
  }

//+------------------------------------------------------------------+
//| #4 Kalman Velocity Direction                                      |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreKalmanVel(ENUM_APEX_SIGNAL dir)
  {
   if(!m_ind.KalmanReady()) return 0;
   double vel = m_ind.KalmanVelocity();
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double normVel = vel / (point * 10); // Normalize to pips

   if(dir == SIGNAL_BUY  && normVel > 2.0) return 2.0;
   if(dir == SIGNAL_BUY  && normVel > 0.5) return 1.0;
   if(dir == SIGNAL_SELL && normVel < -2.0) return 2.0;
   if(dir == SIGNAL_SELL && normVel < -0.5) return 1.0;
   if(dir == SIGNAL_BUY  && normVel < -1.0) return -0.5;
   if(dir == SIGNAL_SELL && normVel > 1.0)  return -0.5;
   return 0;
  }

//+------------------------------------------------------------------+
//| #5 HMA Direction                                                  |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreHMADir(ENUM_APEX_SIGNAL dir)
  {
   int hmaDir = m_ind.HMADirection();
   if(dir == SIGNAL_BUY  && hmaDir > 0)  return 1.5;
   if(dir == SIGNAL_SELL && hmaDir < 0)  return 1.5;
   if(dir == SIGNAL_BUY  && hmaDir < 0)  return -0.5;
   if(dir == SIGNAL_SELL && hmaDir > 0)  return -0.5;
   return 0;
  }

//+------------------------------------------------------------------+
//| #6 MACD Histogram Momentum                                       |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreMACDHist(ENUM_APEX_SIGNAL dir, const ApexTFData &m5)
  {
   double hist = m5.macdHist;
   if(dir == SIGNAL_BUY  && hist > 0)  return MathMin(hist * 500, 2.0);
   if(dir == SIGNAL_SELL && hist < 0)  return MathMin(MathAbs(hist) * 500, 2.0);
   if(dir == SIGNAL_BUY  && hist < 0)  return -0.5;
   if(dir == SIGNAL_SELL && hist > 0)  return -0.5;
   return 0;
  }

//+------------------------------------------------------------------+
//| #7 RSI Momentum (30-70 zone)                                      |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreRSIMomentum(ENUM_APEX_SIGNAL dir, const ApexTFData &m5)
  {
   double rsi = m5.rsi;
   if(dir == SIGNAL_BUY  && rsi > 50 && rsi < 70)  return 1.0;
   if(dir == SIGNAL_BUY  && rsi >= 38 && rsi <= 50) return 0.5; // Pullback zone
   if(dir == SIGNAL_SELL && rsi < 50 && rsi > 30)   return 1.0;
   if(dir == SIGNAL_SELL && rsi >= 50 && rsi <= 62)  return 0.5;
   return 0;
  }

//+------------------------------------------------------------------+
//| #8 RSI Extreme Reversal (< 20 or > 80)                           |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreRSIExtreme(ENUM_APEX_SIGNAL dir, const ApexTFData &m5)
  {
   double rsi = m5.rsi;
   if(dir == SIGNAL_BUY  && rsi < 20)  return 2.0;  // Extremely oversold
   if(dir == SIGNAL_BUY  && rsi < 30)  return 1.5;  // Oversold
   if(dir == SIGNAL_SELL && rsi > 80)  return 2.0;  // Extremely overbought
   if(dir == SIGNAL_SELL && rsi > 70)  return 1.5;  // Overbought
   return 0;
  }

//+------------------------------------------------------------------+
//| #9 Stochastic Cross                                               |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreStochCross(ENUM_APEX_SIGNAL dir, const ApexTFData &m5)
  {
   bool bullCross = (m5.stochK > m5.stochD && m5.stochK < 30);
   bool bearCross = (m5.stochK < m5.stochD && m5.stochK > 70);

   if(dir == SIGNAL_BUY  && bullCross) return 1.5;
   if(dir == SIGNAL_SELL && bearCross) return 1.5;

   // Non-extreme cross
   if(dir == SIGNAL_BUY  && m5.stochK > m5.stochD) return 0.5;
   if(dir == SIGNAL_SELL && m5.stochK < m5.stochD) return 0.5;
   return 0;
  }

//+------------------------------------------------------------------+
//| #10 CCI Extreme                                                   |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreCCIExtreme(ENUM_APEX_SIGNAL dir, const ApexTFData &m5)
  {
   if(dir == SIGNAL_BUY  && m5.cci < -100) return 1.5;
   if(dir == SIGNAL_BUY  && m5.cci < -200) return 2.0;
   if(dir == SIGNAL_SELL && m5.cci > 100)  return 1.5;
   if(dir == SIGNAL_SELL && m5.cci > 200)  return 2.0;
   return 0;
  }

//+------------------------------------------------------------------+
//| #11 BB Touch/Breakout (regime-dependent interpretation)           |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreBBTouch(ENUM_APEX_SIGNAL dir, const ApexTFData &m5, ENUM_APEX_REGIME regime)
  {
   double price = m_mtf.GetM5Close(1);

   if(regime == REGIME_RANGE)
     {
      // Bounce mode: buy at lower band, sell at upper band
      if(dir == SIGNAL_BUY  && price <= m5.bbLower) return 2.0;
      if(dir == SIGNAL_SELL && price >= m5.bbUpper) return 2.0;
     }
   else
     {
      // Breakout mode: buy above upper, sell below lower
      if(dir == SIGNAL_BUY  && price > m5.bbUpper) return 1.5;
      if(dir == SIGNAL_SELL && price < m5.bbLower) return 1.5;
     }

   // Price near middle band = neutral
   return 0;
  }

//+------------------------------------------------------------------+
//| #12 BB Squeeze → Expansion                                       |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreBBSqueeze(ENUM_APEX_SIGNAL dir, const ApexTFData &m5)
  {
   if(!m_ind.BBExpansion()) return 0;

   // Squeeze breakout — direction from price vs middle band
   double price = m_mtf.GetM5Close(1);
   if(dir == SIGNAL_BUY  && price > m5.bbMiddle) return 2.0;
   if(dir == SIGNAL_SELL && price < m5.bbMiddle) return 2.0;
   return 0.5; // Expansion but no clear direction yet
  }

//+------------------------------------------------------------------+
//| #13 Z-Score Mean Reversion                                        |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreZScore(ENUM_APEX_SIGNAL dir)
  {
   double z = m_ind.ZScore();
   // Buy when Z < -2 (oversold), sell when Z > 2 (overbought)
   if(dir == SIGNAL_BUY  && z < -2.0) return 2.0;
   if(dir == SIGNAL_BUY  && z < -1.5) return 1.0;
   if(dir == SIGNAL_SELL && z > 2.0)  return 2.0;
   if(dir == SIGNAL_SELL && z > 1.5)  return 1.0;
   // Contrarian penalty
   if(dir == SIGNAL_BUY  && z > 2.5)  return -1.0;
   if(dir == SIGNAL_SELL && z < -2.5) return -1.0;
   return 0;
  }

//+------------------------------------------------------------------+
//| #14 VWAP Cross / Proximity                                        |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreVWAPCross(ENUM_APEX_SIGNAL dir, double price)
  {
   double vwap = m_ind.VWAP();
   if(vwap <= 0) return 0;
   double dist = (price - vwap) / vwap;

   if(dir == SIGNAL_BUY  && price > vwap && MathAbs(dist) < 0.002) return 1.5;
   if(dir == SIGNAL_SELL && price < vwap && MathAbs(dist) < 0.002) return 1.5;
   if(dir == SIGNAL_BUY  && price > vwap) return 0.5;
   if(dir == SIGNAL_SELL && price < vwap) return 0.5;
   return 0;
  }

//+------------------------------------------------------------------+
//| #15 OFI Candle-based                                              |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreOFICandle(ENUM_APEX_SIGNAL dir)
  {
   double ofi = m_ind.OFI();
   if(dir == SIGNAL_BUY  && ofi > 0.5) return 2.0;
   if(dir == SIGNAL_BUY  && ofi > 0.2) return 1.0;
   if(dir == SIGNAL_SELL && ofi < -0.5) return 2.0;
   if(dir == SIGNAL_SELL && ofi < -0.2) return 1.0;
   return 0;
  }

//+------------------------------------------------------------------+
//| #16 DOM Imbalance                                                 |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreDOMImbalance(ENUM_APEX_SIGNAL dir)
  {
   if(m_flow == NULL || !m_flow.IsDOMActive()) return 0;
   double imb = m_flow.GetDOMImbalance();

   if(dir == SIGNAL_BUY  && imb > InpDOMThresholdStrong)  return 2.0;
   if(dir == SIGNAL_BUY  && imb > InpDOMThresholdMild)    return 1.0;
   if(dir == SIGNAL_SELL && imb < -InpDOMThresholdStrong)  return 2.0;
   if(dir == SIGNAL_SELL && imb < -InpDOMThresholdMild)    return 1.0;
   return 0;
  }

//+------------------------------------------------------------------+
//| #17 Volume Spike                                                  |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreVolSpike(ENUM_APEX_SIGNAL dir, const ApexTFData &m5)
  {
   if(!m_ind.VolumeSpike()) return 0;
   // Volume spike + direction from candle
   double price = m_mtf.GetM5Close(1);
   double open  = m_mtf.GetM5Open(1);
   if(dir == SIGNAL_BUY  && price > open) return 1.5;
   if(dir == SIGNAL_SELL && price < open) return 1.5;
   return 0.5; // Spike with ambiguous direction
  }

//+------------------------------------------------------------------+
//| #18 Footprint Bias                                                |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreFootprint(ENUM_APEX_SIGNAL dir)
  {
   if(m_flow == NULL) return 0;
   double bias = m_flow.GetFootprintBias();
   if(dir == SIGNAL_BUY  && bias > 0.4) return 2.0;
   if(dir == SIGNAL_BUY  && bias > 0.2) return 1.0;
   if(dir == SIGNAL_SELL && bias < -0.4) return 2.0;
   if(dir == SIGNAL_SELL && bias < -0.2) return 1.0;
   return 0;
  }

//+------------------------------------------------------------------+
//| #19 HMM State                                                     |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreHMMState(ENUM_APEX_SIGNAL dir)
  {
   if(m_hmm == NULL || !m_hmm.IsTrained()) return 0;
   ENUM_HMM_STATE state = m_hmm.GetState();
   double conf = m_hmm.GetConfidence();

   if(dir == SIGNAL_BUY && state == HMM_BULL)
      return 1.0 + conf;  // Up to 2.0
   if(dir == SIGNAL_SELL && state == HMM_BEAR)
      return 1.0 + conf;
   if(dir == SIGNAL_BUY && state == HMM_BEAR)
      return -1.0;
   if(dir == SIGNAL_SELL && state == HMM_BULL)
      return -1.0;
   return 0;
  }

//+------------------------------------------------------------------+
//| #20 Candlestick Pattern                                           |
//+------------------------------------------------------------------+
double CSignalEngine::ScoreCandlePattern(ENUM_APEX_SIGNAL dir, double o1, double h1, double l1, double c1,
                                         double o2, double h2, double l2, double c2)
  {
   int pattern = m_ind.DetectCandlePattern(o1, h1, l1, c1, o2, h2, l2, c2);
   if(dir == SIGNAL_BUY  && pattern > 0) return 1.5;
   if(dir == SIGNAL_SELL && pattern < 0) return 1.5;
   if(dir == SIGNAL_BUY  && pattern < 0) return -0.5;
   if(dir == SIGNAL_SELL && pattern > 0) return -0.5;
   return 0;
  }

//+------------------------------------------------------------------+
//| Determine best strategy for the signal                            |
//+------------------------------------------------------------------+
ENUM_APEX_STRATEGY CSignalEngine::DetermineStrategy(ENUM_APEX_REGIME regime, double buyScore,
                                                     double sellScore, const ApexTFData &m5)
  {
   switch(regime)
     {
      case REGIME_BULL:
      case REGIME_BEAR:
         if(m_ind.BBExpansion() && m_ind.VolumeSpike())
            return STRAT_BREAKOUT;
         return STRAT_TREND;

      case REGIME_RANGE:
         if(MathAbs(m_ind.ZScore()) > 1.5)
            return STRAT_MEANREV;
         if(InpGridEnabled)
            return STRAT_GRID;
         return STRAT_MEANREV;

      case REGIME_VOLATILE:
         if(m_ind.BBExpansion())
            return STRAT_BREAKOUT;
         return STRAT_TREND;

      case REGIME_TRANSITION:
         return STRAT_PULLBACK;

      default:
         return STRAT_TREND;
     }
  }

//+------------------------------------------------------------------+
//| Get human-readable score breakdown string                         |
//+------------------------------------------------------------------+
string CSignalEngine::GetScoreBreakdown()
  {
   string result = "";
   for(int i = 0; i < 20; i++)
     {
      if(MathAbs(m_componentScores[i]) > 0.01)
        {
         if(StringLen(result) > 0) result += "|";
         result += StringFormat("%s:%.1f", m_componentNames[i], m_componentScores[i]);
        }
     }
   return result;
  }

#endif // APEX_SIGNALS_MQH
