//+------------------------------------------------------------------+
//|                    QuantGold_ScalperPro.mq5                      |
//|         Advanced XAUUSD M5 Scalping Algorithm v3.0               |
//|   Multi-Strategy Adaptive Quant Engine with Self-Correction      |
//|   Broker: XM360 | Symbol: XAUUSD (Gold.i#) | TF: M5             |
//+------------------------------------------------------------------+
#property copyright   "QuantGold ScalperPro v3.0"
#property link        ""
#property version     "3.00"
#property description "Advanced XAUUSD M5 Scalper | Adaptive Quant | Self-Correcting"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//===================================================================
// INPUT PARAMETERS
//===================================================================

input group "=== CORE INDICATORS ==="
input int    InpEMAFast        = 8;      // Fast EMA Period
input int    InpEMAMed         = 21;     // Medium EMA Period
input int    InpEMASlow        = 55;     // Slow EMA Period
input int    InpEMATrend       = 200;    // Trend EMA Period
input int    InpRSIPeriod      = 14;     // RSI Period
input int    InpBBPeriod       = 20;     // Bollinger Bands Period
input double InpBBDeviation    = 2.0;    // BB Standard Deviation
input int    InpATRPeriod      = 14;     // ATR Period
input int    InpMACDFast       = 12;     // MACD Fast Period
input int    InpMACDSlow       = 26;     // MACD Slow Period
input int    InpMACDSignal     = 9;      // MACD Signal Period
input int    InpStochK         = 5;      // Stochastic %K Period
input int    InpStochD         = 3;      // Stochastic %D Period
input int    InpStochSlowing   = 3;      // Stochastic Slowing
input int    InpCCIPeriod      = 14;     // CCI Period
input int    InpADXPeriod      = 14;     // ADX Period (regime detection)
input int    InpMomPeriod      = 10;     // Momentum Period
input int    InpZScorePeriod   = 20;     // Z-Score Lookback Period

input group "=== SIGNAL ENGINE ==="
input int    InpMinScore       = 5;      // Min Score to Enter Trade (1-10)
input double InpADXTrend       = 25.0;   // ADX threshold: Trending market
input double InpADXRange       = 20.0;   // ADX threshold: Ranging market
input double InpRSIBullish     = 55.0;   // RSI bullish threshold
input double InpRSIBearish     = 45.0;   // RSI bearish threshold
input double InpRSIOS          = 30.0;   // RSI oversold (mean revert buy)
input double InpRSIOB          = 70.0;   // RSI overbought (mean revert sell)
input double InpZScoreEntry    = 1.5;    // Z-Score threshold for entry

input group "=== RISK MANAGEMENT ==="
input double InpRiskPercent    = 1.0;    // Risk per Trade (% of Equity)
input double InpATRMultSL      = 1.5;    // SL = ATR x Multiplier
input double InpATRMultTP1     = 2.0;    // TP1 = ATR x Multiplier (partial close)
input double InpATRMultTP2     = 4.0;    // TP2 = ATR x Multiplier (final close)
input double InpPartialClosePct= 50.0;   // % of position to close at TP1
input double InpMaxDailyLoss   = 4.0;    // Max Daily Loss % (halt trading)
input double InpMaxDrawdown    = 12.0;   // Max Drawdown % (halt trading)
input int    InpMaxOpenTrades  = 5;      // Max Simultaneous Positions
input bool   InpBreakEvenOn    = true;   // Move SL to Breakeven after TP1
input bool   InpUseTrailing    = true;   // Enable Trailing Stop
input double InpTrailATRMult   = 1.2;    // Trailing Stop = ATR x Multiplier
input double InpMinLot         = 0.01;   // Minimum Lot Size
input double InpMaxLot         = 5.00;   // Maximum Lot Size

input group "=== SESSION & FILTERS ==="
input bool   InpUseSessionFilter = true; // Enable Session Filter
input int    InpSessionStart   = 8;      // Session Start Hour (Server Time)
input int    InpSessionEnd     = 22;     // Session End Hour (Server Time)
input bool   InpAvoidFriday    = true;   // Avoid Friday after 18:00
input bool   InpAvoidMonday    = false;  // Avoid Monday before 10:00
input double InpMaxSpread      = 40.0;   // Max Spread in Points
input double InpMinATR         = 0.3;    // Min ATR (avoid dead market)
input double InpMaxATR         = 25.0;   // Max ATR (avoid extreme volatility)

input group "=== KALMAN FILTER ==="
input bool   InpUseKalman      = true;   // Use Kalman Filter
input double InpKalmanQ        = 0.01;   // Kalman Process Noise (Q)
input double InpKalmanR        = 0.1;    // Kalman Measurement Noise (R)

input group "=== SELF-CORRECTION ENGINE ==="
input int    InpSCLookback     = 20;     // Self-Correction Trade Lookback
input double InpSCMinWinRate   = 40.0;   // Min Win Rate before score penalty
input double InpSCPFTarget     = 1.2;    // Target Profit Factor
input double InpSCSizePenalty  = 0.5;    // Position size multiplier when underperforming

input group "=== DISPLAY ==="
input bool   InpShowPanel      = true;   // Show Dashboard Panel
input color  InpBuyColor       = clrDodgerBlue;
input color  InpSellColor      = clrOrangeRed;

//===================================================================
// GLOBAL VARIABLES & STRUCTURES
//===================================================================

CTrade         trade;
CPositionInfo  posInfo;
CAccountInfo   accInfo;
CSymbolInfo    symInfo;

// Indicator handles
int hEMAFast, hEMAMed, hEMASlow, hEMATrend;
int hRSI, hBB, hATR, hMACD, hStoch, hCCI, hADX, hMom;

// Struct: trade record for self-correction
struct TradeRecord {
   double profit;
   double pips;
   bool   isWin;
   int    signal;  // 1=buy, -1=sell
};

TradeRecord g_history[];
int         g_historyCount = 0;
int         g_totalDeals   = 0;

// Kalman Filter state
double g_kalmanX   = 0.0;
double g_kalmanP   = 1.0;
bool   g_kalmanInit= false;

// Adaptive variables (self-correction outputs)
double g_sizeMultiplier = 1.0;   // Applied to lot size
int    g_scoreBonus     = 0;     // Adjustment to min score requirement
double g_winRate        = 50.0;
double g_profitFactor   = 1.5;

// Daily P&L tracking
double g_dayStartBalance = 0;
double g_dayStartEquity  = 0;
datetime g_lastDayCheck  = 0;
bool   g_haltTrading     = false;

// Peak equity for drawdown tracking
double g_peakEquity = 0;

// Timing
datetime g_lastBarTime = 0;
datetime g_lastSignalTime = 0;

// Market regime: 0=unknown,1=strong up trend,2=strong dn trend,3=ranging
int g_regime = 0;

// Statistics for dashboard
int    g_totalBuy  = 0;
int    g_totalSell = 0;
double g_totalPnL  = 0;

//===================================================================
// INITIALIZATION
//===================================================================

int OnInit() {
   // Validate symbol
   symInfo.Name(_Symbol);
   symInfo.RefreshRates();

   // Initialize CTrade
   trade.SetExpertMagicNumber(202412);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   trade.LogLevel(LOG_LEVEL_ERRORS);

   // Create indicator handles
   hEMAFast  = iMA(_Symbol, PERIOD_M5, InpEMAFast,  0, MODE_EMA, PRICE_CLOSE);
   hEMAMed   = iMA(_Symbol, PERIOD_M5, InpEMAMed,   0, MODE_EMA, PRICE_CLOSE);
   hEMASlow  = iMA(_Symbol, PERIOD_M5, InpEMASlow,  0, MODE_EMA, PRICE_CLOSE);
   hEMATrend = iMA(_Symbol, PERIOD_M5, InpEMATrend, 0, MODE_EMA, PRICE_CLOSE);
   hRSI      = iRSI(_Symbol, PERIOD_M5, InpRSIPeriod, PRICE_CLOSE);
   hBB       = iBands(_Symbol, PERIOD_M5, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   hATR      = iATR(_Symbol, PERIOD_M5, InpATRPeriod);
   hMACD     = iMACD(_Symbol, PERIOD_M5, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   hStoch    = iStochastic(_Symbol, PERIOD_M5, InpStochK, InpStochD, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
   hCCI      = iCCI(_Symbol, PERIOD_M5, InpCCIPeriod, PRICE_TYPICAL);
   hADX      = iADX(_Symbol, PERIOD_M5, InpADXPeriod);
   hMom      = iMomentum(_Symbol, PERIOD_M5, InpMomPeriod, PRICE_CLOSE);

   if (hEMAFast==INVALID_HANDLE || hEMAMed==INVALID_HANDLE || hEMASlow==INVALID_HANDLE ||
       hEMATrend==INVALID_HANDLE || hRSI==INVALID_HANDLE || hBB==INVALID_HANDLE ||
       hATR==INVALID_HANDLE || hMACD==INVALID_HANDLE || hStoch==INVALID_HANDLE ||
       hCCI==INVALID_HANDLE || hADX==INVALID_HANDLE || hMom==INVALID_HANDLE) {
      Print("ERROR: Failed to create one or more indicator handles!");
      return INIT_FAILED;
   }

   // Initialize trade history array
   ArrayResize(g_history, 500);

   // Initialize daily tracking
   g_dayStartBalance = accInfo.Balance();
   g_dayStartEquity  = accInfo.Equity();
   g_peakEquity      = accInfo.Equity();
   g_lastDayCheck    = TimeCurrent();

   if (InpShowPanel) CreatePanel();

   Print("QuantGold ScalperPro v3.0 initialized. Symbol: ", _Symbol);
   return INIT_SUCCEEDED;
}

void OnDeinit(int reason) {
   // Release handles
   IndicatorRelease(hEMAFast);  IndicatorRelease(hEMAMed);
   IndicatorRelease(hEMASlow);  IndicatorRelease(hEMATrend);
   IndicatorRelease(hRSI);      IndicatorRelease(hBB);
   IndicatorRelease(hATR);      IndicatorRelease(hMACD);
   IndicatorRelease(hStoch);    IndicatorRelease(hCCI);
   IndicatorRelease(hADX);      IndicatorRelease(hMom);
   ObjectsDeleteAll(0, "QG_");
}

//===================================================================
// MAIN TICK
//===================================================================

void OnTick() {
   // Only process on new M5 bar
   datetime barTime = iTime(_Symbol, PERIOD_M5, 0);
   if (barTime == g_lastBarTime) {
      // Still manage open trades on every tick
      ManageOpenTrades();
      if (InpShowPanel) UpdatePanel();
      return;
   }
   g_lastBarTime = barTime;

   // --- Daily reset ---
   CheckDailyReset();

   // --- Safety checks ---
   if (g_haltTrading) {
      if (InpShowPanel) UpdatePanel();
      return;
   }
   if (!CheckDailyLossLimit()) { g_haltTrading = true; return; }
   if (!CheckDrawdownLimit())  { g_haltTrading = true; return; }

   // --- Update peak equity ---
   double equity = accInfo.Equity();
   if (equity > g_peakEquity) g_peakEquity = equity;

   // --- Session filter ---
   if (InpUseSessionFilter && !IsSessionActive()) return;

   // --- Market environment checks ---
   double atr  = GetIndicatorValue(hATR, 1);
   double spread = symInfo.Spread() * symInfo.Point();
   if (atr < InpMinATR || atr > InpMaxATR) return;
   if ((double)symInfo.Spread() > InpMaxSpread) return;

   // --- Load indicator data ---
   IndicatorData data;
   if (!LoadIndicators(data)) return;

   // --- Kalman filter price ---
   double kPrice = InpUseKalman ? KalmanFilter(data.close) : data.close;

   // --- Detect market regime ---
   g_regime = DetectRegime(data);

   // --- Self-correction update (runs every bar) ---
   UpdateSelfCorrection();

   // --- Generate entry signals ---
   int signal   = 0;
   int score    = 0;
   GenerateSignal(data, kPrice, signal, score);

   // --- Execute trade if conditions met ---
   int minScore = InpMinScore + g_scoreBonus;
   if (MathAbs(score) >= minScore && signal != 0) {
      if (CountOpenPositions() < InpMaxOpenTrades) {
         double lotSize = CalculateLotSize(atr, data.close);
         lotSize = lotSize * g_sizeMultiplier;
         lotSize = NormalizeLot(lotSize);
         if (lotSize >= InpMinLot) {
            OpenTrade(signal, lotSize, atr, data.close, score);
         }
      }
   }

   // --- Update panel ---
   if (InpShowPanel) UpdatePanel();
}

//===================================================================
// INDICATOR DATA STRUCTURE
//===================================================================

struct IndicatorData {
   double close, open, high, low;
   double emaFast, emaMed, emaSlow, emaTrend;
   double rsi, rsiPrev;
   double bbUpper, bbMid, bbLower;
   double macdMain, macdSignal, macdHist, macdHistPrev;
   double stochMain, stochSignal, stochPrev;
   double cci;
   double adx, plusDI, minusDI;
   double mom;
   double zScore;
};

bool LoadIndicators(IndicatorData &d) {
   // Price data
   d.close  = iClose(_Symbol, PERIOD_M5, 1);
   d.open   = iOpen(_Symbol,  PERIOD_M5, 1);
   d.high   = iHigh(_Symbol,  PERIOD_M5, 1);
   d.low    = iLow(_Symbol,   PERIOD_M5, 1);
   if (d.close <= 0) return false;

   // EMAs
   d.emaFast  = GetIndicatorValue(hEMAFast,  1);
   d.emaMed   = GetIndicatorValue(hEMAMed,   1);
   d.emaSlow  = GetIndicatorValue(hEMASlow,  1);
   d.emaTrend = GetIndicatorValue(hEMATrend, 1);

   // RSI
   d.rsi     = GetIndicatorValue(hRSI, 1);
   d.rsiPrev = GetIndicatorValue(hRSI, 2);

   // Bollinger Bands
   d.bbUpper = GetIndicatorBand(hBB, 1, UPPER_BAND);
   d.bbMid   = GetIndicatorBand(hBB, 1, BASE_BAND);
   d.bbLower = GetIndicatorBand(hBB, 1, LOWER_BAND);

   // MACD
   d.macdMain      = GetIndicatorValue(hMACD, 1, 0); // MAIN_LINE
   d.macdSignal    = GetIndicatorValue(hMACD, 1, 1); // SIGNAL_LINE
   d.macdHist      = d.macdMain - d.macdSignal;
   d.macdHistPrev  = GetIndicatorValue(hMACD, 2, 0) - GetIndicatorValue(hMACD, 2, 1);

   // Stochastic
   d.stochMain   = GetIndicatorValue(hStoch, 1, 0); // MAIN_LINE
   d.stochSignal = GetIndicatorValue(hStoch, 1, 1); // SIGNAL_LINE
   d.stochPrev   = GetIndicatorValue(hStoch, 2, 0);

   // CCI
   d.cci = GetIndicatorValue(hCCI, 1);

   // ADX
   d.adx     = GetIndicatorValue(hADX, 1, 0); // MAIN_LINE
   d.plusDI  = GetIndicatorValue(hADX, 1, 1); // +DI
   d.minusDI = GetIndicatorValue(hADX, 1, 2); // -DI

   // Momentum
   d.mom = GetIndicatorValue(hMom, 1);

   // Z-Score of close vs mean
   d.zScore = CalculateZScore(InpZScorePeriod);

   return true;
}

//===================================================================
// KALMAN FILTER
//===================================================================

double KalmanFilter(double measurement) {
   if (!g_kalmanInit) {
      g_kalmanX    = measurement;
      g_kalmanP    = 1.0;
      g_kalmanInit = true;
      return measurement;
   }
   // Prediction
   double pPred = g_kalmanP + InpKalmanQ;
   // Update
   double K     = pPred / (pPred + InpKalmanR);
   g_kalmanX    = g_kalmanX + K * (measurement - g_kalmanX);
   g_kalmanP    = (1.0 - K) * pPred;
   return g_kalmanX;
}

//===================================================================
// MARKET REGIME DETECTION
//===================================================================

int DetectRegime(const IndicatorData &d) {
   // 1 = Strong Uptrend, 2 = Strong Downtrend, 3 = Ranging, 0 = Mixed
   bool isTrending = (d.adx > InpADXTrend);
   bool isRanging  = (d.adx < InpADXRange);

   if (isTrending) {
      if (d.plusDI > d.minusDI && d.close > d.emaTrend) return 1; // Up
      if (d.minusDI > d.plusDI && d.close < d.emaTrend) return 2; // Down
   }
   if (isRanging) return 3;
   return 0;
}

//===================================================================
// SIGNAL SCORING ENGINE (0-10 scale per direction)
//===================================================================

void GenerateSignal(const IndicatorData &d, double kPrice, int &signal, int &score) {
   signal = 0;
   int buyScore  = 0;
   int sellScore = 0;

   // --- [1] EMA RIBBON (max 2 pts) ---
   // All EMAs aligned = 2 pts, partial = 1 pt
   bool emaAllBull = (d.emaFast > d.emaMed && d.emaMed > d.emaSlow && d.close > d.emaTrend);
   bool emaAllBear = (d.emaFast < d.emaMed && d.emaMed < d.emaSlow && d.close < d.emaTrend);
   bool emaPartBull= (d.emaFast > d.emaMed && d.emaMed > d.emaSlow);
   bool emaPartBear= (d.emaFast < d.emaMed && d.emaMed < d.emaSlow);

   if (emaAllBull)       buyScore  += 2;
   else if (emaPartBull) buyScore  += 1;
   if (emaAllBear)       sellScore += 2;
   else if (emaPartBear) sellScore += 1;

   // --- [2] RSI (max 2 pts) ---
   // Trend mode: RSI > 55 = bullish, RSI < 45 = bearish
   // Mean revert mode: RSI < 30 = buy signal, RSI > 70 = sell signal
   if (g_regime == 3) { // Ranging
      if (d.rsi < InpRSIOS && d.rsi > d.rsiPrev)  buyScore  += 2; // Oversold bounce
      if (d.rsi > InpRSIOB && d.rsi < d.rsiPrev)  sellScore += 2; // Overbought fade
   } else {
      if (d.rsi > InpRSIBullish)  buyScore  += 2;
      else if (d.rsi > 50.0)      buyScore  += 1;
      if (d.rsi < InpRSIBearish)  sellScore += 2;
      else if (d.rsi < 50.0)      sellScore += 1;
   }

   // --- [3] MACD (max 2 pts) ---
   // Histogram cross + direction
   bool macdBullCross = (d.macdHist > 0 && d.macdHistPrev <= 0);
   bool macdBearCross = (d.macdHist < 0 && d.macdHistPrev >= 0);
   bool macdBull      = (d.macdHist > 0 && d.macdMain > d.macdSignal);
   bool macdBear      = (d.macdHist < 0 && d.macdMain < d.macdSignal);

   if (macdBullCross)      buyScore  += 2;
   else if (macdBull)      buyScore  += 1;
   if (macdBearCross)      sellScore += 2;
   else if (macdBear)      sellScore += 1;

   // --- [4] STOCHASTIC (max 1 pt) ---
   bool stochBullCross = (d.stochMain > d.stochSignal && d.stochPrev <= d.stochSignal);
   bool stochBearCross = (d.stochMain < d.stochSignal && d.stochPrev >= d.stochSignal);

   if (stochBullCross && d.stochMain < 50)  buyScore  += 1;
   if (stochBearCross && d.stochMain > 50)  sellScore += 1;
   if (d.stochMain < 20)                    buyScore  += 1;
   if (d.stochMain > 80)                    sellScore += 1;

   // --- [5] BOLLINGER BANDS (max 1 pt) ---
   double bbWidth = (d.bbUpper - d.bbLower) / d.bbMid;
   bool bbSqueeze = (bbWidth < 0.01); // Consolidation
   if (d.close < d.bbLower)  buyScore  += 1; // Below BB lower
   if (d.close > d.bbUpper)  sellScore += 1; // Above BB upper
   if (kPrice > d.bbMid && d.close > d.bbMid && !bbSqueeze) buyScore  += 1;
   if (kPrice < d.bbMid && d.close < d.bbMid && !bbSqueeze) sellScore += 1;

   // --- [6] CCI (max 1 pt) ---
   if (d.cci > 100)   buyScore  += 1;
   if (d.cci < -100)  sellScore += 1;

   // --- [7] MOMENTUM (max 1 pt) ---
   if (d.mom > 100.5) buyScore  += 1;
   if (d.mom < 99.5)  sellScore += 1;

   // --- [8] Z-SCORE MEAN REVERSION (max 2 pts bonus) ---
   if (g_regime == 3) { // Only in ranging market
      if (d.zScore < -InpZScoreEntry) buyScore  += 2; // Oversold
      if (d.zScore > InpZScoreEntry)  sellScore += 2; // Overbought
   }

   // --- [9] KALMAN TREND CONFIRMATION (max 1 pt) ---
   if (InpUseKalman) {
      double kPrev = KalmanGetPrevX();
      if (kPrice > kPrev) buyScore  += 1;
      if (kPrice < kPrev) sellScore += 1;
   }

   // --- [10] ADX+DI CONFIRMATION (max 1 pt) ---
   if (d.adx > InpADXTrend) {
      if (d.plusDI > d.minusDI)  buyScore  += 1;
      if (d.minusDI > d.plusDI)  sellScore += 1;
   }

   // --- Anti-whipsaw: require opposite side to be lower ---
   // Add regime-based weighting
   if (g_regime == 1) { buyScore += 1; }        // In uptrend, boost buys
   if (g_regime == 2) { sellScore += 1; }       // In downtrend, boost sells
   if (g_regime == 3 && buyScore == sellScore) { // Ranging, no bias
      buyScore = 0; sellScore = 0;
   }

   // Cap scores at 10
   buyScore  = MathMin(buyScore,  10);
   sellScore = MathMin(sellScore, 10);

   // Final signal selection: prefer higher score, must exceed min
   if (buyScore > sellScore && buyScore > 0) {
      signal = 1;
      score  = buyScore;
   } else if (sellScore > buyScore && sellScore > 0) {
      signal = -1;
      score  = sellScore;
   } else {
      signal = 0;
      score  = 0;
   }
}

//===================================================================
// TRADE EXECUTION
//===================================================================

void OpenTrade(int signal, double lots, double atr, double price, int score) {
   symInfo.RefreshRates();
   double ask = symInfo.Ask();
   double bid = symInfo.Bid();
   double pt  = symInfo.Point();

   // Normalize ATR to price levels
   double slDist  = atr * InpATRMultSL;
   double tp1Dist = atr * InpATRMultTP1;
   double tp2Dist = atr * InpATRMultTP2;

   double entryPrice, sl, tp;

   if (signal == 1) { // BUY
      entryPrice = ask;
      sl         = NormalizeDouble(entryPrice - slDist, _Digits);
      tp         = NormalizeDouble(entryPrice + tp2Dist, _Digits);

      // Safety: ensure SL below current price
      if (sl >= entryPrice) sl = NormalizeDouble(entryPrice - symInfo.StopsLevel() * pt * 2, _Digits);

      if (trade.Buy(lots, _Symbol, entryPrice, sl, tp, "QGS_BUY_" + IntegerToString(score))) {
         Print("BUY opened: Lots=", lots, " SL=", sl, " TP=", tp, " Score=", score, " Regime=", g_regime);
         g_totalBuy++;
         // Store TP1 level in comment field via a separate tracking mechanism
         StoreTP1(trade.ResultOrder(), entryPrice + tp1Dist, signal);
      } else {
         Print("BUY failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      }
   } else { // SELL
      entryPrice = bid;
      sl         = NormalizeDouble(entryPrice + slDist, _Digits);
      tp         = NormalizeDouble(entryPrice - tp2Dist, _Digits);

      if (sl <= entryPrice) sl = NormalizeDouble(entryPrice + symInfo.StopsLevel() * pt * 2, _Digits);

      if (trade.Sell(lots, _Symbol, entryPrice, sl, tp, "QGS_SELL_" + IntegerToString(score))) {
         Print("SELL opened: Lots=", lots, " SL=", sl, " TP=", tp, " Score=", score, " Regime=", g_regime);
         g_totalSell++;
         StoreTP1(trade.ResultOrder(), entryPrice - tp1Dist, signal);
      } else {
         Print("SELL failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      }
   }
}

//===================================================================
// TP1 LEVEL TRACKING (for partial close & break-even)
//===================================================================

struct TP1Record {
   ulong  ticket;
   double tp1Level;
   bool   partialDone;
   bool   breakEvenDone;
   int    direction;
};

TP1Record g_tp1Records[];
int       g_tp1Count = 0;

void StoreTP1(ulong ticket, double tp1, int dir) {
   if (g_tp1Count >= ArraySize(g_tp1Records)) {
      ArrayResize(g_tp1Records, g_tp1Count + 20);
   }
   g_tp1Records[g_tp1Count].ticket       = ticket;
   g_tp1Records[g_tp1Count].tp1Level     = tp1;
   g_tp1Records[g_tp1Count].partialDone  = false;
   g_tp1Records[g_tp1Count].breakEvenDone= false;
   g_tp1Records[g_tp1Count].direction    = dir;
   g_tp1Count++;
}

int FindTP1Record(ulong ticket) {
   for (int i = 0; i < g_tp1Count; i++) {
      if (g_tp1Records[i].ticket == ticket) return i;
   }
   return -1;
}

//===================================================================
// OPEN TRADE MANAGEMENT (every tick)
//===================================================================

void ManageOpenTrades() {
   double ask    = symInfo.Ask();
   double bid    = symInfo.Bid();
   double atr    = GetIndicatorValue(hATR, 1);

   for (int i = PositionsTotal()-1; i >= 0; i--) {
      if (!posInfo.SelectByIndex(i)) continue;
      if (posInfo.Symbol() != _Symbol) continue;
      if (posInfo.Magic() != 202412)   continue;

      ulong  ticket    = posInfo.Ticket();
      int    dir       = (posInfo.PositionType() == POSITION_TYPE_BUY) ? 1 : -1;
      double openPrice = posInfo.PriceOpen();
      double curSL     = posInfo.StopLoss();
      double curTP     = posInfo.TakeProfit();
      double curPrice  = (dir == 1) ? bid : ask;
      double lots      = posInfo.Volume();
      double pt        = symInfo.Point();

      int idx = FindTP1Record(ticket);
      if (idx < 0) continue;

      double tp1 = g_tp1Records[idx].tp1Level;

      // --- PARTIAL CLOSE at TP1 ---
      if (!g_tp1Records[idx].partialDone) {
         bool tp1Hit = (dir == 1 && curPrice >= tp1) || (dir == -1 && curPrice <= tp1);
         if (tp1Hit) {
            double closeLots = NormalizeLot(lots * InpPartialClosePct / 100.0);
            if (closeLots >= InpMinLot) {
               if (trade.PositionClosePartial(ticket, closeLots)) {
                  g_tp1Records[idx].partialDone = true;
                  Print("Partial close at TP1: Ticket=", ticket, " Lots=", closeLots);
               }
            }
         }
      }

      // --- BREAK-EVEN after partial close ---
      if (InpBreakEvenOn && g_tp1Records[idx].partialDone && !g_tp1Records[idx].breakEvenDone) {
         double newSL;
         bool   needUpdate = false;
         double minStop    = symInfo.StopsLevel() * pt;

         if (dir == 1 && curSL < openPrice - minStop) {
            newSL = NormalizeDouble(openPrice + pt * 2, _Digits);
            needUpdate = true;
         } else if (dir == -1 && curSL > openPrice + minStop) {
            newSL = NormalizeDouble(openPrice - pt * 2, _Digits);
            needUpdate = true;
         }
         if (needUpdate) {
            if (trade.PositionModify(ticket, newSL, curTP)) {
               g_tp1Records[idx].breakEvenDone = true;
               Print("Break-even set: Ticket=", ticket, " NewSL=", newSL);
            }
         }
      }

      // --- TRAILING STOP ---
      if (InpUseTrailing && atr > 0) {
         double trailDist = atr * InpTrailATRMult;
         double newSL     = 0;
         bool   doUpdate  = false;
         double minStop   = symInfo.StopsLevel() * pt;

         if (dir == 1) {
            newSL = NormalizeDouble(curPrice - trailDist, _Digits);
            if (newSL > curSL + pt && newSL > openPrice && (curPrice - newSL) > minStop) {
               doUpdate = true;
            }
         } else {
            newSL = NormalizeDouble(curPrice + trailDist, _Digits);
            if (newSL < curSL - pt && newSL < openPrice && (newSL - curPrice) > minStop) {
               doUpdate = true;
            }
         }
         if (doUpdate) {
            trade.PositionModify(ticket, newSL, curTP);
         }
      }
   }
}

//===================================================================
// LOT SIZE CALCULATION (risk-based)
//===================================================================

double CalculateLotSize(double atr, double price) {
   double equity      = accInfo.Equity();
   double riskAmount  = equity * InpRiskPercent / 100.0;
   double slDist      = atr * InpATRMultSL;  // In price units
   double tickValue   = symInfo.TickValue();
   double tickSize    = symInfo.TickSize();

   if (tickSize <= 0 || tickValue <= 0 || slDist <= 0) return InpMinLot;

   // lotSize = riskAmount / (slDistance / tickSize * tickValue)
   double pipsRisk    = slDist / tickSize;
   double lotSize     = riskAmount / (pipsRisk * tickValue);

   return lotSize;
}

double NormalizeLot(double lots) {
   double lotStep = symInfo.LotsStep();
   if (lotStep <= 0) lotStep = 0.01;
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(lots, InpMinLot);
   lots = MathMin(lots, InpMaxLot);
   return NormalizeDouble(lots, 2);
}

//===================================================================
// SELF-CORRECTION ENGINE
//===================================================================

void UpdateSelfCorrection() {
   // Pull recent closed trades from history
   int    recentDeals = HistoryDealsTotal();
   if (recentDeals == g_totalDeals) return; // Nothing new
   g_totalDeals = recentDeals;

   // Reset counters and recalculate from history
   int wins = 0, losses = 0;
   double grossProfit = 0, grossLoss = 0;

   // Reload last InpSCLookback trades with our magic
   HistorySelect(TimeCurrent() - 30*24*3600, TimeCurrent());
   int total = HistoryDealsTotal();
   int count = 0;

   for (int i = total-1; i >= 0 && count < InpSCLookback; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if (HistoryDealGetInteger(ticket, DEAL_MAGIC) != 202412) continue;
      if (HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      double pnl = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      if (pnl > 0) { wins++; grossProfit += pnl; }
      else         { losses++; grossLoss  += MathAbs(pnl); }
      count++;
   }

   if (count == 0) return;

   g_winRate     = (count > 0) ? (double)wins / count * 100.0 : 50.0;
   g_profitFactor= (grossLoss > 0) ? grossProfit / grossLoss : (grossProfit > 0 ? 99.0 : 1.0);

   // Adaptive response
   if (g_winRate < InpSCMinWinRate || g_profitFactor < InpSCPFTarget) {
      // Underperforming: reduce size, raise score bar
      g_sizeMultiplier = InpSCSizePenalty;
      g_scoreBonus     = 2; // Require higher score
      Print("SELF-CORRECTION: Reducing size to ", g_sizeMultiplier, " WinRate=", DoubleToString(g_winRate,1), "% PF=", DoubleToString(g_profitFactor,2));
   } else if (g_winRate > 55.0 && g_profitFactor > InpSCPFTarget * 1.5) {
      // Outperforming: restore normal/boosted size
      g_sizeMultiplier = 1.2;
      g_scoreBonus     = 0;
   } else {
      // Normal performance
      g_sizeMultiplier = 1.0;
      g_scoreBonus     = 0;
   }
}

//===================================================================
// DAILY P&L MONITORING
//===================================================================

void CheckDailyReset() {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   MqlDateTime dtLast;
   TimeToStruct(g_lastDayCheck, dtLast);

   if (dt.day != dtLast.day) {
      g_dayStartBalance = accInfo.Balance();
      g_dayStartEquity  = accInfo.Equity();
      g_haltTrading     = false; // Reset halt on new day
      g_lastDayCheck    = TimeCurrent();
      Print("New trading day. Balance reset: ", g_dayStartBalance);
   }
}

bool CheckDailyLossLimit() {
   double curEquity   = accInfo.Equity();
   double loss        = (g_dayStartBalance - curEquity);
   double lossPct     = (g_dayStartBalance > 0) ? loss / g_dayStartBalance * 100.0 : 0;
   if (lossPct >= InpMaxDailyLoss) {
      Print("DAILY LOSS LIMIT REACHED: ", DoubleToString(lossPct, 2), "% >= ", InpMaxDailyLoss, "% - Halting.");
      return false;
   }
   return true;
}

bool CheckDrawdownLimit() {
   if (g_peakEquity <= 0) return true;
   double curEquity  = accInfo.Equity();
   double ddPct      = (g_peakEquity - curEquity) / g_peakEquity * 100.0;
   if (ddPct >= InpMaxDrawdown) {
      Print("MAX DRAWDOWN REACHED: ", DoubleToString(ddPct, 2), "% >= ", InpMaxDrawdown, "% - Halting.");
      return false;
   }
   return true;
}

//===================================================================
// SESSION FILTER
//===================================================================

bool IsSessionActive() {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour;
   int dow  = dt.day_of_week; // 0=Sun, 5=Fri, 6=Sat

   // Avoid weekends
   if (dow == 0 || dow == 6) return false;

   // Avoid Friday evening
   if (InpAvoidFriday && dow == 5 && hour >= 18) return false;

   // Avoid Monday opening (if enabled)
   if (InpAvoidMonday && dow == 1 && hour < 10) return false;

   // Check session window
   if (hour < InpSessionStart || hour >= InpSessionEnd) return false;

   return true;
}

//===================================================================
// Z-SCORE CALCULATION
//===================================================================

double CalculateZScore(int period) {
   double prices[];
   ArraySetAsSeries(prices, true);
   if (CopyClose(_Symbol, PERIOD_M5, 1, period, prices) < period) return 0;

   double mean = 0, variance = 0;
   for (int i = 0; i < period; i++) mean += prices[i];
   mean /= period;
   for (int i = 0; i < period; i++) variance += MathPow(prices[i] - mean, 2);
   double stdDev = MathSqrt(variance / period);
   if (stdDev < 0.0001) return 0;
   return (prices[0] - mean) / stdDev;
}

//===================================================================
// UTILITY FUNCTIONS
//===================================================================

double GetIndicatorValue(int handle, int shift, int bufferIndex = 0) {
   double arr[];
   ArraySetAsSeries(arr, true);
   if (CopyBuffer(handle, bufferIndex, shift, 1, arr) < 1) return 0;
   return arr[0];
}

double GetIndicatorBand(int handle, int shift, int band) {
   // band: 0=BASE, 1=UPPER, 2=LOWER in iBands (UPPER_BAND=1, BASE_BAND=0, LOWER_BAND=2)
   return GetIndicatorValue(handle, shift, band);
}

int CountOpenPositions() {
   int count = 0;
   for (int i = 0; i < PositionsTotal(); i++) {
      if (posInfo.SelectByIndex(i)) {
         if (posInfo.Symbol() == _Symbol && posInfo.Magic() == 202412) count++;
      }
   }
   return count;
}

// Store previous Kalman value for direction
double g_kalmanPrevX = 0;
double KalmanGetPrevX() { return g_kalmanPrevX; }

// Update g_kalmanPrevX each bar
double KalmanFilterWithPrev(double measurement) {
   g_kalmanPrevX = g_kalmanX;
   return KalmanFilter(measurement);
}

//===================================================================
// ON TRADE EVENT (for self-correction P&L tracking)
//===================================================================

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &request,
                        const MqlTradeResult      &result) {
   if (trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      ulong dealTicket = trans.deal;
      if (!HistoryDealSelect(dealTicket)) return;
      if (HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != 202412) return;
      if (HistoryDealGetInteger(dealTicket, DEAL_ENTRY) != DEAL_ENTRY_OUT) return;

      double pnl = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
      g_totalPnL += pnl;

      // Update self-correction record
      UpdateSelfCorrection();
   }
}

//===================================================================
// DASHBOARD PANEL
//===================================================================

void CreatePanel() {
   string prefix = "QG_";
   // Background
   ObjectCreate(0, prefix+"BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, prefix+"BG", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, prefix+"BG", OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, prefix+"BG", OBJPROP_XSIZE, 260);
   ObjectSetInteger(0, prefix+"BG", OBJPROP_YSIZE, 245);
   ObjectSetInteger(0, prefix+"BG", OBJPROP_BGCOLOR, C'15,15,35');
   ObjectSetInteger(0, prefix+"BG", OBJPROP_BORDER_COLOR, C'0,120,200');
   ObjectSetInteger(0, prefix+"BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, prefix+"BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void UpdatePanel() {
   if (!InpShowPanel) return;
   string prefix = "QG_";

   double eq     = accInfo.Equity();
   double bal    = accInfo.Balance();
   double dd     = (g_peakEquity > 0) ? (g_peakEquity - eq) / g_peakEquity * 100.0 : 0;
   double dayPnL = eq - g_dayStartEquity;

   string lines[9];
   lines[0] = "  QuantGold ScalperPro v3.0";
   lines[1] = "  Symbol : " + _Symbol;
   lines[2] = "  Equity : $" + DoubleToString(eq, 2);
   lines[3] = "  Day PnL: $" + DoubleToString(dayPnL, 2) + " | DD: " + DoubleToString(dd, 1) + "%";
   lines[4] = "  Regime : " + RegimeToString(g_regime);
   lines[5] = "  Trades : B=" + IntegerToString(g_totalBuy) + " S=" + IntegerToString(g_totalSell);
   lines[6] = "  WinRate: " + DoubleToString(g_winRate, 1) + "% | PF: " + DoubleToString(g_profitFactor, 2);
   lines[7] = "  SizeMul: " + DoubleToString(g_sizeMultiplier, 2) + " | ScoreAdj: " + IntegerToString(g_scoreBonus);
   lines[8] = g_haltTrading ? "  ** TRADING HALTED **" : "  Status : ACTIVE";

   color lineColors[9];
   lineColors[0] = C'0,200,255';
   lineColors[1] = clrSilver;
   lineColors[2] = clrWhite;
   lineColors[3] = (dayPnL >= 0) ? clrLimeGreen : clrOrangeRed;
   lineColors[4] = clrYellow;
   lineColors[5] = clrSilver;
   lineColors[6] = (g_winRate >= InpSCMinWinRate) ? clrLimeGreen : clrOrangeRed;
   lineColors[7] = clrSilver;
   lineColors[8] = g_haltTrading ? clrRed : clrLimeGreen;

   for (int i = 0; i < 9; i++) {
      string name = prefix + "L" + IntegerToString(i);
      if (ObjectFind(0, name) < 0) {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
         ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
      }
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 12);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 28 + i*24);
      ObjectSetString(0, name, OBJPROP_TEXT, lines[i]);
      ObjectSetInteger(0, name, OBJPROP_COLOR, lineColors[i]);
   }
   ChartRedraw(0);
}

string RegimeToString(int r) {
   switch(r) {
      case 1:  return "Strong Uptrend";
      case 2:  return "Strong Downtrend";
      case 3:  return "Ranging";
      default: return "Mixed";
   }
}

//===================================================================
// STRATEGY TESTER OPTIMIZATION PASS
//===================================================================
// These are not separate functions—the EA runs identically in tester.
// Recommended tester settings:
//   Date range : Last 1 year (Feb 2024 – Feb 2025)
//   Model      : Every tick based on real ticks (best quality)
//   Optimization: Off for single pass; Grid for parameter optimization
//   Parameters to optimize: InpEMAFast, InpEMAMed, InpRSIPeriod,
//                           InpATRMultSL, InpATRMultTP1, InpATRMultTP2,
//                           InpRiskPercent, InpMinScore

//===================================================================
// EOF
//===================================================================
