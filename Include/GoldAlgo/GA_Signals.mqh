//+------------------------------------------------------------------+
//|                                                  GA_Signals.mqh  |
//|                   GoldAlgo Elite - Signal Generator                |
//|           Score-based multi-factor signal ensemble                 |
//+------------------------------------------------------------------+
#property copyright "GoldAlgo Elite"
#property strict

#ifndef __GA_SIGNALS_MQH__
#define __GA_SIGNALS_MQH__

#include "GA_Config.mqh"
#include "GA_Indicators.mqh"

//+------------------------------------------------------------------+
//| CSignalGenerator - Weighted ensemble signal engine                |
//+------------------------------------------------------------------+
class CSignalGenerator
  {
private:
   CIndicatorEngine *m_ind;        // Pointer to indicator engine
   string            m_symbol;
   ENUM_TIMEFRAMES   m_period;

   // Regime-dependent weight multipliers
   double            m_trendWeight;    // Weight for trend-following components
   double            m_revertWeight;   // Weight for mean-reversion components

   // Individual signal component evaluators
   double            ScoreEMA_Alignment(bool isBuy);
   double            ScoreEMA_TrendBias(bool isBuy);
   double            ScoreKalman(bool isBuy);
   double            ScoreMACD(bool isBuy);
   double            ScoreRSI(bool isBuy, ENUM_MARKET_REGIME regime);
   double            ScoreBollinger(bool isBuy);
   double            ScoreStochastic(bool isBuy);
   double            ScoreCCI(bool isBuy, ENUM_MARKET_REGIME regime);
   double            ScoreZScore(bool isBuy, ENUM_MARKET_REGIME regime);
   double            ScoreOrderFlow(bool isBuy);
   double            ScoreHMA(bool isBuy);
   double            ScoreVWAP(bool isBuy);

   // SL/TP computation
   void              ComputeSLTP(TradeSignal &signal, double totalScore);

public:
                     CSignalGenerator();
                    ~CSignalGenerator();

   bool              Init(CIndicatorEngine *indEngine, string symbol, ENUM_TIMEFRAMES period);
   TradeSignal       Evaluate();
  };

//+------------------------------------------------------------------+
CSignalGenerator::CSignalGenerator()
  {
   m_ind = NULL;
   m_trendWeight = 1.0;
   m_revertWeight = 1.0;
  }

//+------------------------------------------------------------------+
CSignalGenerator::~CSignalGenerator() {}

//+------------------------------------------------------------------+
bool CSignalGenerator::Init(CIndicatorEngine *indEngine, string symbol, ENUM_TIMEFRAMES period)
  {
   if(indEngine == NULL)
     {
      Print("[GA-SIG] ERROR: Indicator engine is NULL!");
      return false;
     }
   m_ind    = indEngine;
   m_symbol = symbol;
   m_period = period;
   Print("[GA-SIG] Signal generator initialized");
   return true;
  }

//+------------------------------------------------------------------+
//| Main signal evaluation - called once per new bar                  |
//+------------------------------------------------------------------+
TradeSignal CSignalGenerator::Evaluate()
  {
   TradeSignal sig;
   sig.Reset();

   // Detect regime first
   double regConf = 0;
   ENUM_MARKET_REGIME regime = m_ind.DetectRegime(regConf);
   sig.regime = regime;
   sig.regimeConfidence = regConf;

   // Adjust regime-dependent weights
   switch(regime)
     {
      case REGIME_TRENDING_UP:
      case REGIME_TRENDING_DOWN:
         m_trendWeight  = 1.5;
         m_revertWeight = 0.5;
         break;
      case REGIME_RANGING:
         m_trendWeight  = 0.5;
         m_revertWeight = 1.5;
         break;
      case REGIME_VOLATILE:
         m_trendWeight  = 1.0;
         m_revertWeight = 0.8;
         break;
      default:
         m_trendWeight  = 1.0;
         m_revertWeight = 1.0;
         break;
     }

   string buyComponents  = "";
   string sellComponents = "";

   //--- Evaluate all components for BUY ---
   double buyScore = 0;
   double s;

   s = ScoreEMA_Alignment(true) * m_trendWeight;
   if(s > 0) { buyScore += s; buyComponents += "EMA+"; }

   s = ScoreEMA_TrendBias(true) * m_trendWeight;
   if(s > 0) { buyScore += s; buyComponents += "Trend+"; }

   s = ScoreKalman(true) * m_trendWeight;
   if(s > 0) { buyScore += s; buyComponents += "Kal+"; }

   s = ScoreMACD(true) * m_trendWeight;
   if(s > 0) { buyScore += s; buyComponents += "MACD+"; }

   s = ScoreRSI(true, regime);
   if(s > 0) { buyScore += s; buyComponents += "RSI+"; }

   s = ScoreBollinger(true);
   if(s > 0) { buyScore += s; buyComponents += "BB+"; }

   s = ScoreStochastic(true);
   if(s > 0) { buyScore += s; buyComponents += "Stoch+"; }

   s = ScoreCCI(true, regime) * m_trendWeight;
   if(s > 0) { buyScore += s; buyComponents += "CCI+"; }

   s = ScoreZScore(true, regime) * m_revertWeight;
   if(s > 0) { buyScore += s; buyComponents += "ZS+"; }

   s = ScoreOrderFlow(true);
   if(s > 0) { buyScore += s; buyComponents += "OFI+"; }

   s = ScoreHMA(true) * m_trendWeight;
   if(s > 0) { buyScore += s; buyComponents += "HMA+"; }

   s = ScoreVWAP(true);
   if(s > 0) { buyScore += s; buyComponents += "VWAP+"; }

   //--- Evaluate all components for SELL ---
   double sellScore = 0;

   s = ScoreEMA_Alignment(false) * m_trendWeight;
   if(s > 0) { sellScore += s; sellComponents += "EMA+"; }

   s = ScoreEMA_TrendBias(false) * m_trendWeight;
   if(s > 0) { sellScore += s; sellComponents += "Trend+"; }

   s = ScoreKalman(false) * m_trendWeight;
   if(s > 0) { sellScore += s; sellComponents += "Kal+"; }

   s = ScoreMACD(false) * m_trendWeight;
   if(s > 0) { sellScore += s; sellComponents += "MACD+"; }

   s = ScoreRSI(false, regime);
   if(s > 0) { sellScore += s; sellComponents += "RSI+"; }

   s = ScoreBollinger(false);
   if(s > 0) { sellScore += s; sellComponents += "BB+"; }

   s = ScoreStochastic(false);
   if(s > 0) { sellScore += s; sellComponents += "Stoch+"; }

   s = ScoreCCI(false, regime) * m_trendWeight;
   if(s > 0) { sellScore += s; sellComponents += "CCI+"; }

   s = ScoreZScore(false, regime) * m_revertWeight;
   if(s > 0) { sellScore += s; sellComponents += "ZS+"; }

   s = ScoreOrderFlow(false);
   if(s > 0) { sellScore += s; sellComponents += "OFI+"; }

   s = ScoreHMA(false) * m_trendWeight;
   if(s > 0) { sellScore += s; sellComponents += "HMA+"; }

   s = ScoreVWAP(false);
   if(s > 0) { sellScore += s; sellComponents += "VWAP+"; }

   //--- Block counter-trend signals: don't fight the dominant trend
   if(regime == REGIME_TRENDING_UP)
      sellScore = 0;
   else if(regime == REGIME_TRENDING_DOWN)
      buyScore = 0;

   // Store raw scores
   sig.buyScore  = buyScore;
   sig.sellScore = sellScore;

   // Determine direction: take the stronger signal, net of the other
   double netBuy  = buyScore - sellScore * 0.3;   // Penalize conflicting signals
   double netSell = sellScore - buyScore * 0.3;

  // Require directional dominance to avoid marginal/choppy entries
  double scoreEdge = MathAbs(buyScore - sellScore);
  if(scoreEdge < InpMinScoreEdge)
    return sig;

  // Regime confidence filter: skip unclear regime context
  if(regConf < InpMinRegimeConf)
    return sig;

  // In volatile conditions, require stronger directional edge
  if(regime == REGIME_VOLATILE && scoreEdge < InpVolatileScoreEdge)
    return sig;

   // In volatile regime, require higher threshold
   double volBonus = (regime == REGIME_VOLATILE) ? 2.0 : 0;

   if(netBuy > netSell && buyScore >= (InpMinBuyScore + volBonus))
     {
      sig.direction = SIGNAL_BUY;
      sig.source = "BUY[" + buyComponents + "] s=" + DoubleToString(buyScore, 1);
      ComputeSLTP(sig, buyScore);
     }
   else if(netSell > netBuy && sellScore >= (InpMinSellScore + volBonus))
     {
      sig.direction = SIGNAL_SELL;
      sig.source = "SELL[" + sellComponents + "] s=" + DoubleToString(sellScore, 1);
      ComputeSLTP(sig, sellScore);
     }

   return sig;
  }

//+------------------------------------------------------------------+
//| Score: EMA Alignment (0-2 points)                                 |
//| Buy: Price > EMA8 > EMA21 > EMA55                                |
//| Sell: Price < EMA8 < EMA21 < EMA55                               |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreEMA_Alignment(bool isBuy)
  {
   double price = m_ind.Close(1);  // Bar 1 (confirmed)
   double ema8  = m_ind.EMA_Fast(1);
   double ema21 = m_ind.EMA_Mid(1);
   double ema55 = m_ind.EMA_Slow(1);

   if(ema8 == 0 || ema21 == 0 || ema55 == 0) return 0;

   if(isBuy)
     {
      int aligned = 0;
      if(price > ema8)  aligned++;
      if(ema8 > ema21)  aligned++;
      if(ema21 > ema55) aligned++;

      if(aligned >= 3) return 2.0;
      if(aligned >= 2) return 1.0;
      return 0;
     }
   else
     {
      int aligned = 0;
      if(price < ema8)  aligned++;
      if(ema8 < ema21)  aligned++;
      if(ema21 < ema55) aligned++;

      if(aligned >= 3) return 2.0;
      if(aligned >= 2) return 1.0;
      return 0;
     }
  }

//+------------------------------------------------------------------+
//| Score: EMA 55/200 Trend Bias (0-1 point)                         |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreEMA_TrendBias(bool isBuy)
  {
   double ema55  = m_ind.EMA_Slow(1);
   double ema200 = m_ind.EMA_Trend(1);
   if(ema55 == 0 || ema200 == 0) return 0;

   if(isBuy && ema55 > ema200) return 1.0;
   if(!isBuy && ema55 < ema200) return 1.0;
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: Kalman Velocity (0-1.5 points)                             |
//| Buy: velocity > 0 and accelerating                                |
//| Sell: velocity < 0 and decelerating                               |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreKalman(bool isBuy)
  {
   double vel = m_ind.KalmanVelocity();
   double price = m_ind.Close(1);
   double kalPrice = m_ind.KalmanPrice();

   if(isBuy)
     {
      if(vel > 0)
        {
         double score = 0.75;
         // Bonus if price is above Kalman (momentum confirmation)
         if(price > kalPrice) score += 0.75;
         return score;
        }
     }
   else
     {
      if(vel < 0)
        {
         double score = 0.75;
         if(price < kalPrice) score += 0.75;
         return score;
        }
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: MACD Histogram (0-1.5 points)                              |
//| Buy: histogram > 0 and increasing                                 |
//| Sell: histogram < 0 and decreasing                                |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreMACD(bool isBuy)
  {
   double hist0 = m_ind.MACD_Hist(1);  // Current confirmed bar
   double hist1 = m_ind.MACD_Hist(2);  // Previous bar

   if(isBuy)
     {
      // Bullish crossover (histogram turns positive) — highest priority
      if(hist0 > 0 && hist1 <= 0) return 1.5;
      // Positive and rising histogram
      if(hist0 > 0)
        {
         double score = 0.75;
         if(hist0 > hist1) score += 0.75;
         return score;
        }
     }
   else
     {
      // Bearish crossover (histogram turns negative)
      if(hist0 < 0 && hist1 >= 0) return 1.5;
      // Negative and falling histogram
      if(hist0 < 0)
        {
         double score = 0.75;
         if(hist0 < hist1) score += 0.75;
         return score;
        }
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: RSI (0-1 point) - regime-dependent                         |
//| Trend: Buy if RSI > 55, Sell if RSI < 45                         |
//| Range: Buy if RSI crosses above 30, Sell if crosses below 70     |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreRSI(bool isBuy, ENUM_MARKET_REGIME regime)
  {
   double rsi0 = m_ind.RSI(1);
   double rsi1 = m_ind.RSI(2);

   bool isTrending = (regime == REGIME_TRENDING_UP || regime == REGIME_TRENDING_DOWN);

   if(isBuy)
     {
      if(isTrending)
        {
         // In trend: momentum confirmation
         if(rsi0 > 55 && rsi0 < 75) return 1.0;
        }
      else
        {
         // In range: oversold bounce
         if(rsi0 > 30 && rsi1 <= 30) return 1.0;  // Crossing up from oversold
         if(rsi0 < 35 && rsi0 > rsi1) return 0.7;  // Recovering from oversold
        }
     }
   else
     {
      if(isTrending)
        {
         if(rsi0 < 45 && rsi0 > 25) return 1.0;
        }
      else
        {
         if(rsi0 < 70 && rsi1 >= 70) return 1.0;   // Crossing down from overbought
         if(rsi0 > 65 && rsi0 < rsi1) return 0.7;   // Declining from overbought
        }
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: Bollinger Bands (0-1 point)                                |
//| Squeeze breakout or band bounce                                   |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreBollinger(bool isBuy)
  {
   double price = m_ind.Close(1);
   double upper = m_ind.BB_Upper(1);
   double mid   = m_ind.BB_Middle(1);
   double lower = m_ind.BB_Lower(1);
   double bw    = m_ind.BB_Bandwidth(1);
   double prevBw = m_ind.BB_Bandwidth(2);

   bool squeezeExpanding = (bw > prevBw && prevBw > 0 && prevBw < 0.015);

   if(isBuy)
     {
      // Squeeze breakout above middle
      if(squeezeExpanding && price > mid) return 1.0;
      // Price bouncing off lower band
      if(price <= lower * 1.001 && m_ind.Close(0) > m_ind.Close(1)) return 0.7;
     }
   else
     {
      // Squeeze breakout below middle
      if(squeezeExpanding && price < mid) return 1.0;
      // Price bouncing off upper band
      if(price >= upper * 0.999 && m_ind.Close(0) < m_ind.Close(1)) return 0.7;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: Stochastic Crossover (0-1 point)                           |
//| Buy: %K crosses above %D below 20                                 |
//| Sell: %K crosses below %D above 80                                |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreStochastic(bool isBuy)
  {
   double k0 = m_ind.Stoch_K(1);
   double d0 = m_ind.Stoch_D(1);
   double k1 = m_ind.Stoch_K(2);
   double d1 = m_ind.Stoch_D(2);

   if(isBuy)
     {
      // Bullish crossover in oversold zone
      if(k0 > d0 && k1 <= d1 && k0 < 25)
         return 1.0;
      // Already crossed, still in lower zone
      if(k0 > d0 && k0 < 30 && k0 > k1)
         return 0.5;
     }
   else
     {
      // Bearish crossover in overbought zone
      if(k0 < d0 && k1 >= d1 && k0 > 75)
         return 1.0;
      if(k0 < d0 && k0 > 70 && k0 < k1)
         return 0.5;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: CCI (0-1 point) - trend regime                             |
//| Buy: CCI > +100 (strong momentum)                                 |
//| Sell: CCI < -100                                                   |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreCCI(bool isBuy, ENUM_MARKET_REGIME regime)
  {
   double cci0 = m_ind.CCI(1);
   double cci1 = m_ind.CCI(2);

   bool isTrending = (regime == REGIME_TRENDING_UP || regime == REGIME_TRENDING_DOWN);

   if(isBuy)
     {
      if(isTrending && cci0 > 100) return 1.0;
      // CCI crossing above -100 from below (reversal)
      if(!isTrending && cci0 > -100 && cci1 <= -100) return 0.8;
     }
   else
     {
      if(isTrending && cci0 < -100) return 1.0;
      if(!isTrending && cci0 < 100 && cci1 >= 100) return 0.8;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: Z-Score Mean Reversion (0-1.5 points) - range regime only  |
//| Buy: Z-Score < -1.5 (price significantly below mean)              |
//| Sell: Z-Score > +1.5                                               |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreZScore(bool isBuy, ENUM_MARKET_REGIME regime)
  {
   double zs = m_ind.ZScore();

   // Mean reversion signals strongest in ranging markets
   bool isRange = (regime == REGIME_RANGING || regime == REGIME_UNKNOWN);

   if(isBuy)
     {
      if(zs < -2.0) return isRange ? 1.5 : 0.5;
      if(zs < -1.5) return isRange ? 1.0 : 0.3;
     }
   else
     {
      if(zs > 2.0) return isRange ? 1.5 : 0.5;
      if(zs > 1.5) return isRange ? 1.0 : 0.3;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: Order Flow Imbalance (0-1.5 points)                        |
//| Buy: Buy pressure exceeds sell pressure by > 0.3                  |
//| Sell: Sell pressure exceeds buy pressure by > 0.3                 |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreOrderFlow(bool isBuy)
  {
   double ofi = m_ind.OFI();

   if(isBuy)
     {
      if(ofi > 0.4) return 1.5;
      if(ofi > 0.3) return 1.0;
      if(ofi > 0.15) return 0.5;
     }
   else
     {
      if(ofi < -0.4) return 1.5;
      if(ofi < -0.3) return 1.0;
      if(ofi < -0.15) return 0.5;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: Hull MA Direction (0-1 point)                              |
//| Buy: HMA rising (current > 2 bars ago)                           |
//| Sell: HMA falling                                                  |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreHMA(bool isBuy)
  {
   double hma0 = m_ind.HMA(0);
   double hma2 = m_ind.HMA(2);

   if(hma0 == 0 || hma2 == 0) return 0;

   if(isBuy && hma0 > hma2) return 1.0;
   if(!isBuy && hma0 < hma2) return 1.0;
   return 0;
  }

//+------------------------------------------------------------------+
//| Score: VWAP Position (0-1 point)                                  |
//| Buy: Price above VWAP with recent retest                          |
//| Sell: Price below VWAP with recent retest                         |
//+------------------------------------------------------------------+
double CSignalGenerator::ScoreVWAP(bool isBuy)
  {
   double vwap  = m_ind.VWAP();
   double price = m_ind.Close(1);
   double prevPrice = m_ind.Close(2);

   if(vwap == 0) return 0;

   if(isBuy)
     {
      // Price above VWAP, confirming upward bias
      if(price > vwap)
        {
         // Recently retested VWAP from above (dipped close then bounced)
         double distPct = (price - vwap) / vwap * 100;
         if(distPct < 0.15 && price > prevPrice) return 1.0;
         if(price > vwap && prevPrice <= vwap)    return 1.0;  // Just crossed above
         if(distPct < 0.3) return 0.5;
        }
     }
   else
     {
      if(price < vwap)
        {
         double distPct = (vwap - price) / vwap * 100;
         if(distPct < 0.15 && price < prevPrice) return 1.0;
         if(price < vwap && prevPrice >= vwap)    return 1.0;  // Just crossed below
         if(distPct < 0.3) return 0.5;
        }
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Compute SL/TP based on ATR and signal strength                    |
//+------------------------------------------------------------------+
void CSignalGenerator::ComputeSLTP(TradeSignal &signal, double totalScore)
  {
   double atr = m_ind.ATR(1);
   if(atr <= 0) atr = m_ind.ATR(0);
   if(atr <= 0)
     {
      signal.direction = SIGNAL_NONE;
      return;
     }

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   if(point <= 0) point = 0.01;

   // Base SL in points
   double slPoints = (atr * InpSLMultiplier) / point;

   // Base TP in points - enhanced by signal strength
   // Stronger signals allow wider TP (higher confidence in direction)
   double minScore = (signal.direction == SIGNAL_BUY) ? InpMinBuyScore : InpMinSellScore;
   double tpBonus = 1.0 + MathMin((totalScore - minScore) * 0.1, 0.5);  // Up to +50% TP bonus
   double tpPoints = (atr * InpTPMultiplier * tpBonus) / point;

   // Clamp SL
   slPoints = MathMax(slPoints, (double)InpMinSLPoints);
   slPoints = MathMin(slPoints, (double)InpMaxSLPoints);

   // Enforce minimum R:R
   double rr = tpPoints / slPoints;
   if(rr < InpMinRR)
     {
      tpPoints = slPoints * InpMinRR;  // Widen TP to meet minimum R:R
     }

   // Check broker's minimum stops level
   int stopsLevel = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   if(stopsLevel > 0)
     {
      if(slPoints < stopsLevel) slPoints = (double)stopsLevel + 5;
      if(tpPoints < stopsLevel) tpPoints = (double)stopsLevel + 5;
     }

   signal.slPoints = slPoints;
   signal.tpPoints = tpPoints;
  }

#endif // __GA_SIGNALS_MQH__
