//+------------------------------------------------------------------+
//|                                                  APEX_Config.mqh |
//|                        APEX Gold Destroyer - Configuration       |
//|                        Maximum Aggression XAUUSD EA              |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_CONFIG_MQH
#define APEX_CONFIG_MQH

//+------------------------------------------------------------------+
//| Enumerations                                                      |
//+------------------------------------------------------------------+
enum ENUM_APEX_REGIME
  {
   REGIME_BULL       = 0,   // Strong Bullish Trend
   REGIME_BEAR       = 1,   // Strong Bearish Trend
   REGIME_RANGE      = 2,   // Ranging / Consolidation
   REGIME_VOLATILE   = 3,   // High Volatility / Chaotic
   REGIME_TRANSITION = 4    // Regime Transitioning
  };

enum ENUM_APEX_STRATEGY
  {
   STRAT_TREND       = 0,   // Trend Follow + Pyramid
   STRAT_PULLBACK    = 1,   // Pullback Entry
   STRAT_BREAKOUT    = 2,   // BB Squeeze Breakout
   STRAT_MEANREV     = 3,   // Mean Reversion Grid
   STRAT_NEWS        = 4,   // News Spike Straddle
   STRAT_DOM_SCALP   = 5,   // DOM Scalp (Live Only)
   STRAT_GRID        = 6    // Grid Recovery
  };

enum ENUM_APEX_SIGNAL
  {
   SIGNAL_BUY        = 1,
   SIGNAL_SELL       = -1,
   SIGNAL_NONE       = 0
  };

enum ENUM_APEX_NEWS_STATE
  {
   NEWS_NONE         = 0,   // No Upcoming News
   NEWS_PRE          = 1,   // Pre-News (straddle zone)
   NEWS_DURING       = 2,   // During News (spike)
   NEWS_POST_FADE    = 3    // Post-News (fade zone)
  };

enum ENUM_HMM_STATE
  {
   HMM_BEAR          = 0,
   HMM_RANGE         = 1,
   HMM_BULL          = 2
  };

//+------------------------------------------------------------------+
//| Input Parameters - Risk & Aggression                              |
//+------------------------------------------------------------------+
sinput string           s1 = "═══════ RISK & AGGRESSION ═══════";  // ─── Risk Settings ───
input double            InpBaseRisk           = 5.0;     // Base Risk % Per Trade
input double            InpMaxRisk            = 12.0;    // Maximum Risk % Per Trade
input double            InpKellyFraction      = 0.25;    // Kelly Fraction (0.25 = Quarter Kelly)
input int               InpKellyMinTrades     = 20;      // Min Trades Before Kelly Activates
input int               InpKellyWindow        = 50;      // Kelly Rolling Window Size
input double            InpMaxDrawdown        = 50.0;    // Emergency Max Drawdown % (force close)
input int               InpMaxPositions       = 4;       // Max Simultaneous Positions
input double            InpMaxLotSize         = 1.0;     // Hard Max Lot Per Trade
input double            InpMaxTotalLots       = 3.0;     // Max Total Open Lots (all positions)
input int               InpLossStreakCooldown = 3;       // Pause After N Consecutive Losses
input int               InpCooldownMinutes    = 30;      // Cooldown Duration (minutes)
input bool              InpBiDirectional      = true;    // Allow Simultaneous Buy + Sell

//+------------------------------------------------------------------+
//| Input Parameters - Martingale                                     |
//+------------------------------------------------------------------+
sinput string           s2 = "═══════ MARTINGALE RECOVERY ═══════";
input bool              InpMartingaleEnabled  = true;    // Enable Martingale Recovery
input double            InpMartingaleMultiplier = 1.5;   // Martingale Lot Multiplier
input int               InpMartingaleMaxLevels = 2;      // Max Martingale Levels (1x→1.5x→2.25x)
input double            InpMartingaleMaxMult  = 3.0;     // Absolute Max Martingale Multiplier Cap
input int               InpMartingaleCooldown = 30;      // Cooldown Minutes After Max Level

//+------------------------------------------------------------------+
//| Input Parameters - Pyramiding                                     |
//+------------------------------------------------------------------+
sinput string           s3 = "═══════ PYRAMIDING ═══════";
input bool              InpPyramidEnabled     = true;    // Enable Pyramiding Into Winners
input int               InpPyramidMaxAdds     = 3;       // Max Pyramid Additions
input double            InpPyramidSizeDecay   = 0.5;     // Each Add = This × Previous Lot
input double            InpPyramidPullbackATR = 0.5;     // Add On Pullback of N × ATR
input double            InpPyramidMinProfitATR= 0.5;     // Min Profit in ATR Before Pyramid

//+------------------------------------------------------------------+
//| Input Parameters - Grid                                           |
//+------------------------------------------------------------------+
sinput string           s4 = "═══════ GRID TRADING ═══════";
input bool              InpGridEnabled        = true;    // Enable Grid Recovery
input double            InpGridSpacingATR     = 0.5;     // Grid Spacing in ATR Units
input int               InpGridMaxLevels      = 3;       // Max Grid Levels
input double            InpGridLotMultiplier  = 1.2;     // Grid Lot Progression Multiplier

//+------------------------------------------------------------------+
//| Input Parameters - Signal Scoring                                 |
//+------------------------------------------------------------------+
sinput string           s5 = "═══════ SIGNAL ENGINE ═══════";
input double            InpMinBuyScore        = 12.0;    // Minimum Score To Open Buy
input double            InpMinSellScore       = 10.0;    // Minimum Score To Open Sell
input double            InpHighConfScore      = 80.0;    // High Confidence Score (wider TP)
input double            InpCounterHTFPenalty  = -5.0;    // Counter-HTF Direction Penalty
input double            InpEntropyThreshold   = 0.85;    // Max Entropy (>= means noisy)
input double            InpEntropyDiscount    = 0.3;     // Score Multiplier When High Entropy

//+------------------------------------------------------------------+
//| Input Parameters - Indicators                                     |
//+------------------------------------------------------------------+
sinput string           s6 = "═══════ INDICATORS ═══════";
input int               InpEMA_Fast           = 8;       // EMA Fast Period
input int               InpEMA_Mid            = 21;      // EMA Mid Period
input int               InpEMA_Slow           = 55;      // EMA Slow Period
input int               InpEMA_Long           = 200;     // EMA Long Period
input int               InpRSI_Period         = 14;      // RSI Period
input int               InpBB_Period          = 20;      // Bollinger Bands Period
input double            InpBB_Deviation       = 2.0;     // Bollinger Bands Deviation
input int               InpMACD_Fast          = 12;      // MACD Fast
input int               InpMACD_Slow          = 26;      // MACD Slow
input int               InpMACD_Signal        = 9;       // MACD Signal
input int               InpStoch_K            = 5;       // Stochastic K
input int               InpStoch_D            = 3;       // Stochastic D
input int               InpStoch_Slowing      = 3;       // Stochastic Slowing
input int               InpADX_Period         = 14;      // ADX Period
input int               InpCCI_Period         = 20;      // CCI Period
input int               InpATR_Period         = 14;      // ATR Period

//+------------------------------------------------------------------+
//| Input Parameters - Kalman Filter                                  |
//+------------------------------------------------------------------+
sinput string           s7 = "═══════ KALMAN FILTER ═══════";
input double            InpKalman_Q           = 0.005;   // Kalman Process Noise (Q)
input double            InpKalman_R           = 0.05;    // Kalman Measurement Noise (R)

//+------------------------------------------------------------------+
//| Input Parameters - HMM                                            |
//+------------------------------------------------------------------+
sinput string           s8 = "═══════ HMM REGIME DETECTION ═══════";
input int               InpHMM_States         = 3;       // HMM Number of States
input int               InpHMM_Window         = 500;     // HMM Training Window (bars)
input int               InpHMM_RetrainBars    = 100;     // Retrain Every N Bars
input int               InpHMM_EMIterations   = 20;      // EM Algorithm Iterations
input double            InpHMM_WeightFusion   = 0.4;     // HMM Weight in Regime Fusion (0-1)

//+------------------------------------------------------------------+
//| Input Parameters - Custom Indicators                              |
//+------------------------------------------------------------------+
sinput string           s9 = "═══════ CUSTOM INDICATORS ═══════";
input int               InpHMA_Period         = 21;      // Hull MA Period
input int               InpZScore_Period      = 50;      // Z-Score Lookback
input int               InpOFI_Period         = 10;      // OFI Lookback Bars
input double            InpOFI_Decay          = 0.3;     // OFI Exponential Decay Rate
input int               InpVWAP_ResetBars     = 288;     // VWAP Reset Period (bars)
input int               InpVolSpike_Period    = 20;      // Volume Spike MA Period
input double            InpVolSpike_Mult      = 2.0;     // Volume Spike Threshold (× SMA)
input double            InpBBSqueeze_Thresh   = 0.01;    // BB Squeeze Bandwidth Threshold

//+------------------------------------------------------------------+
//| Input Parameters - Trade Management                               |
//+------------------------------------------------------------------+
sinput string           s10 = "═══════ TRADE MANAGEMENT ═══════";
input double            InpSL_ATR_Mult        = 2.0;     // Stop Loss = ATR × This
input double            InpTP1_ATR_Mult       = 2.0;     // Take Profit 1 = ATR × This
input double            InpTP2_ATR_Mult       = 4.0;     // Take Profit 2 (Final) = ATR × This
input double            InpTP_HighConf_Mult   = 6.0;     // TP2 For High-Confidence Signals
input double            InpPartialClosePercent= 30.0;    // Partial Close % at TP1
input double            InpTrailATR_Mult      = 1.0;     // Chandelier Trail = ATR × This
input int               InpTrailBars          = 5;       // Chandelier Lookback Bars
input double            InpBE_ATR_Mult        = 0.9;     // Break-Even Trigger = ATR × This
input double            InpBE_PlusPoints      = 5.0;     // Break-Even Lock Profit Points
input int               InpStaleHours         = 4;       // Close Stale Positions After Hours
input double            InpStaleMinProfitATR  = 0.3;     // Stale Position Min Profit (ATR)

//+------------------------------------------------------------------+
//| Input Parameters - News Trading                                   |
//+------------------------------------------------------------------+
sinput string           s11 = "═══════ NEWS EXPLOITATION ═══════";
input bool              InpNewsEnabled        = true;    // Enable News Trading
input int               InpNewsPreMinutes     = 5;       // Pre-News Straddle Minutes
input int               InpNewsDuringMinutes  = 2;       // During-News Window Minutes
input int               InpNewsPostMinutes    = 15;      // Post-News Fade Window Minutes
input double            InpNewsStraddleATR    = 1.0;     // Straddle Distance (ATR ×)
input double            InpNewsSL_ATR         = 0.5;     // News SL (tight, ATR ×)
input double            InpNewsTP_ATR         = 5.0;     // News TP (wide, ATR ×)
input double            InpNewsFadeThreshATR  = 2.0;     // Fade After Spike > This × ATR
input string            InpNewsCurrency       = "USD";   // Calendar Currency Filter

//+------------------------------------------------------------------+
//| Input Parameters - Sessions                                       |
//+------------------------------------------------------------------+
sinput string           s12 = "═══════ SESSION FILTER ═══════";
input bool              InpSessionFilter      = true;    // Enable Session Filter
input int               InpLondonStart        = 7;       // London Session Start Hour
input int               InpLondonEnd          = 12;      // London Session End Hour
input int               InpNYStart            = 13;      // New York Session Start Hour
input int               InpNYEnd              = 18;      // New York Session End Hour
input bool              InpAsiaEnabled        = false;   // Trade Asia Session (low liquidity)
input int               InpAsiaStart          = 0;       // Asia Start Hour
input int               InpAsiaEnd            = 6;       // Asia End Hour
input int               InpSkipSessionOpen    = 15;      // Skip First N Minutes Of Session

//+------------------------------------------------------------------+
//| Input Parameters - DOM / Order Flow                               |
//+------------------------------------------------------------------+
sinput string           s13 = "═══════ ORDER FLOW & DOM ═══════";
input bool              InpDOMEnabled         = true;    // Enable DOM Analysis (Live Only)
input double            InpDOMThresholdMild   = 0.3;     // DOM Imbalance Mild Threshold
input double            InpDOMThresholdStrong = 0.6;     // DOM Imbalance Strong Threshold
input double            InpDOMWallMultiplier  = 3.0;     // DOM Wall Detection (× avg volume)
input int               InpTickFootprintCount = 1000;    // Ticks For Footprint Analysis
input int               InpDOMScalpMaxActive  = 2;       // Max Active DOM Scalp Positions

//+------------------------------------------------------------------+
//| Input Parameters - Dashboard                                      |
//+------------------------------------------------------------------+
sinput string           s14 = "═══════ DASHBOARD ═══════";
input bool              InpDashboard          = true;    // Show On-Chart Dashboard
input ENUM_BASE_CORNER  InpDashCorner         = CORNER_LEFT_UPPER; // Dashboard Corner
input int               InpDashFontSize       = 8;       // Dashboard Font Size
input color             InpDashBG             = C'20,20,30';  // Dashboard Background
input color             InpDashText           = clrWhite;     // Dashboard Text Color
input color             InpDashBull           = clrLime;      // Bull Color
input color             InpDashBear           = clrRed;       // Bear Color
input color             InpDashNeutral        = clrYellow;    // Neutral Color

//+------------------------------------------------------------------+
//| Input Parameters - General                                        |
//+------------------------------------------------------------------+
sinput string           s15 = "═══════ GENERAL ═══════";
input long              InpMagic              = 20260215;     // Magic Number
input int               InpSlippage           = 50;           // Max Slippage Points
input string            InpComment            = "APEX";       // Order Comment Prefix

//+------------------------------------------------------------------+
//| Data Structures                                                   |
//+------------------------------------------------------------------+
struct ApexSignal
  {
   ENUM_APEX_SIGNAL     direction;      // Buy / Sell / None
   double               score;          // Raw score (0-100)
   double               normalizedScore;// Normalized 0-100
   ENUM_APEX_STRATEGY   strategy;       // Recommended strategy
   double               sl;             // Stop Loss price
   double               tp1;            // Take Profit 1 (partial)
   double               tp2;            // Take Profit 2 (final)
   double               lots;           // Computed lot size
   ENUM_APEX_REGIME     regime;         // Current regime
   double               confidence;     // Signal confidence 0-1
   string               components;     // Score breakdown string
  };

struct ApexRegime
  {
   ENUM_APEX_REGIME     state;          // Current regime state
   ENUM_HMM_STATE       hmmState;       // HMM decoded state
   double               confidence;     // Regime confidence 0-1
   double               entropy;        // Shannon entropy
   double               adxValue;       // Current ADX
   double               bbBandwidth;    // BB bandwidth
   double               atrPercentile;  // ATR percentile rank
   double               kalmanVelocity; // Kalman velocity
  };

struct ApexRiskMetrics
  {
   double               equity;         // Current equity
   double               balance;        // Current balance
   double               peakEquity;     // Peak equity reached
   double               drawdown;       // Current DD from peak (%)
   double               winRate;        // Rolling win rate
   double               profitFactor;   // Rolling profit factor
   double               kellyFraction;  // Computed Kelly fraction
   double               avgWin;         // Average win amount
   double               avgLoss;        // Average loss amount
   int                  consecutiveWins; // Current consecutive wins
   int                  consecutiveLosses;// Current consecutive losses
   double               equitySMA;      // Equity moving average
   double               lotMultiplier;  // Current lot multiplier
   int                  martingaleLevel;// Current martingale level
  };

struct ApexTradeRecord
  {
   datetime             closeTime;      // Trade close time
   double               profit;         // Trade profit
   double               lots;           // Lot size
   ENUM_APEX_REGIME     regime;         // Regime at entry
   ENUM_APEX_STRATEGY   strategy;       // Strategy used
   ENUM_APEX_SIGNAL     direction;      // Trade direction
   bool                 isWin;          // Was profitable
  };

struct ApexPositionMeta
  {
   ulong                ticket;         // Position ticket
   double               score;          // Entry signal score
   ENUM_APEX_REGIME     regime;         // Entry regime
   ENUM_APEX_STRATEGY   strategy;       // Strategy type
   ENUM_APEX_SIGNAL     direction;      // Direction
   int                  pyramidLevel;   // Pyramid level (0 = initial)
   int                  martingaleLevel;// Martingale level (0 = none)
   int                  gridLevel;      // Grid level (0 = none)
   bool                 partialDone;    // TP1 partial executed
   double               entryATR;       // ATR at entry time
   double               entryPrice;     // Entry price
   datetime             entryTime;      // Entry time
   double               initialVolume;  // Initial volume before partial
  };

struct ApexGridState
  {
   bool                 active;         // Grid is active
   double               basePrice;      // Grid base price
   ENUM_APEX_SIGNAL     direction;      // Grid direction
   int                  filledLevels;   // Number of filled levels
   double               totalLots;      // Total grid lots
   double               avgPrice;       // Average entry price
   double               netProfit;      // Current net floating P&L
  };

struct ApexTFData
  {
   double               emaFast;        // EMA fast value
   double               emaMid;         // EMA mid value
   double               emaSlow;        // EMA slow value
   double               emaLong;        // EMA long value
   double               rsi;            // RSI value
   double               bbUpper;        // BB upper
   double               bbMiddle;       // BB middle
   double               bbLower;        // BB lower
   double               macdMain;       // MACD main line
   double               macdSignal;     // MACD signal line
   double               macdHist;       // MACD histogram
   double               stochK;         // Stochastic %K
   double               stochD;         // Stochastic %D
   double               adxMain;        // ADX main
   double               adxPlus;        // +DI
   double               adxMinus;       // -DI
   double               cci;            // CCI value
   double               atr;            // ATR value
  };

struct ApexNewsEvent
  {
   datetime             eventTime;      // Event time
   string               eventName;      // Event name
   string               currency;       // Currency
   int                  importance;     // 1=low, 2=medium, 3=high
   double               preEventPrice;  // Price before event
  };

//+------------------------------------------------------------------+
//| Constants                                                         |
//+------------------------------------------------------------------+
#define APEX_MAX_POSITIONS      100     // Max meta array size
#define APEX_TRADE_BUFFER_SIZE  200     // Circular buffer size
#define APEX_MAX_GRID_LEVELS    10      // Max grid levels
#define APEX_MAX_NEWS_EVENTS    20      // Max cached news events
#define APEX_DASH_PREFIX        "APEX_" // Dashboard object prefix
#define APEX_VERSION            "1.00"  // EA Version

//+------------------------------------------------------------------+
//| Signal Component Weight Structure                                 |
//+------------------------------------------------------------------+
struct ApexWeightProfile
  {
   double               htfTrend;       // #1  HTF consensus
   double               emaStack;       // #2  M5 EMA stack
   double               emaCross;       // #3  EMA crossover
   double               kalmanVel;      // #4  Kalman velocity
   double               hmaDir;         // #5  HMA direction
   double               macdHist;       // #6  MACD histogram
   double               rsiMomentum;    // #7  RSI momentum
   double               rsiExtreme;     // #8  RSI extreme
   double               stochCross;     // #9  Stoch cross
   double               cciExtreme;     // #10 CCI extreme
   double               bbTouch;        // #11 BB touch/breakout
   double               bbSqueeze;      // #12 BB squeeze
   double               zScore;         // #13 Z-Score
   double               vwapCross;      // #14 VWAP cross
   double               ofiCandle;      // #15 OFI candle-based
   double               domImbalance;   // #16 DOM imbalance
   double               volSpike;       // #17 Volume spike
   double               footprint;      // #18 Footprint bias
   double               hmmState;       // #19 HMM state
   double               candlePattern;  // #20 Candlestick pattern
  };

//+------------------------------------------------------------------+
//| Default Weight Profiles Per Regime                                |
//+------------------------------------------------------------------+
void GetWeightProfile(ENUM_APEX_REGIME regime, ApexWeightProfile &wp)
  {
   // Base weights
   wp.htfTrend     = 3.0;
   wp.emaStack     = 2.0;
   wp.emaCross     = 1.5;
   wp.kalmanVel    = 1.5;
   wp.hmaDir       = 1.0;
   wp.macdHist     = 1.5;
   wp.rsiMomentum  = 1.0;
   wp.rsiExtreme   = 1.5;
   wp.stochCross   = 1.0;
   wp.cciExtreme   = 1.0;
   wp.bbTouch      = 1.5;
   wp.bbSqueeze    = 1.5;
   wp.zScore       = 1.0;
   wp.vwapCross    = 1.0;
   wp.ofiCandle    = 1.5;
   wp.domImbalance = 2.0;
   wp.volSpike     = 1.0;
   wp.footprint    = 1.5;
   wp.hmmState     = 2.0;
   wp.candlePattern= 1.0;

   // Regime-specific multipliers
   switch(regime)
     {
      case REGIME_BULL:
      case REGIME_BEAR:
         wp.htfTrend     *= 1.5;
         wp.emaStack     *= 1.5;
         wp.emaCross     *= 1.5;
         wp.kalmanVel    *= 1.2;
         wp.hmaDir       *= 1.3;
         wp.macdHist     *= 1.3;
         wp.rsiMomentum  *= 1.0;
         wp.rsiExtreme   *= 0.3;   // Extremes less reliable in trends
         wp.stochCross   *= 0.8;
         wp.cciExtreme   *= 0.5;
         wp.bbTouch      *= 1.2;   // Breakout mode
         wp.bbSqueeze    *= 1.0;
         wp.zScore       *= 0.3;   // Mean reversion dangerous in trends
         wp.vwapCross    *= 1.0;
         wp.ofiCandle    *= 1.2;
         wp.domImbalance *= 1.5;
         wp.volSpike     *= 1.5;
         wp.footprint    *= 1.2;
         wp.hmmState     *= 1.5;
         wp.candlePattern*= 1.0;
         break;

      case REGIME_RANGE:
         wp.htfTrend     *= 0.5;
         wp.emaStack     *= 0.5;
         wp.emaCross     *= 0.3;
         wp.kalmanVel    *= 0.8;
         wp.hmaDir       *= 0.7;
         wp.macdHist     *= 0.5;
         wp.rsiMomentum  *= 1.5;
         wp.rsiExtreme   *= 2.0;   // Extremes very reliable in ranges
         wp.stochCross   *= 1.5;
         wp.cciExtreme   *= 1.5;
         wp.bbTouch      *= 1.5;   // Bounce mode
         wp.bbSqueeze    *= 0.5;
         wp.zScore       *= 2.0;   // Mean reversion king in ranges
         wp.vwapCross    *= 1.5;
         wp.ofiCandle    *= 1.0;
         wp.domImbalance *= 1.5;
         wp.volSpike     *= 0.5;
         wp.footprint    *= 1.0;
         wp.hmmState     *= 1.0;
         wp.candlePattern*= 1.0;
         break;

      case REGIME_VOLATILE:
         wp.htfTrend     *= 1.0;
         wp.emaStack     *= 1.0;
         wp.emaCross     *= 1.0;
         wp.kalmanVel    *= 1.0;
         wp.hmaDir       *= 1.0;
         wp.macdHist     *= 1.0;
         wp.rsiMomentum  *= 0.8;
         wp.rsiExtreme   *= 1.5;
         wp.stochCross   *= 0.8;
         wp.cciExtreme   *= 1.0;
         wp.bbTouch      *= 1.5;
         wp.bbSqueeze    *= 2.0;   // Squeeze breakouts huge in volatile
         wp.zScore       *= 0.5;
         wp.vwapCross    *= 0.5;
         wp.ofiCandle    *= 1.0;
         wp.domImbalance *= 1.5;
         wp.volSpike     *= 2.0;
         wp.footprint    *= 1.5;
         wp.hmmState     *= 0.5;
         wp.candlePattern*= 1.0;
         break;

      case REGIME_TRANSITION:
         // Reduce everything during transition - be cautious
         wp.htfTrend     *= 0.8;
         wp.emaStack     *= 0.7;
         wp.emaCross     *= 0.7;
         wp.kalmanVel    *= 0.8;
         wp.hmaDir       *= 0.7;
         wp.macdHist     *= 0.7;
         wp.rsiMomentum  *= 0.8;
         wp.rsiExtreme   *= 1.0;
         wp.stochCross   *= 0.8;
         wp.cciExtreme   *= 0.8;
         wp.bbTouch      *= 0.8;
         wp.bbSqueeze    *= 0.8;
         wp.zScore       *= 0.8;
         wp.vwapCross    *= 0.8;
         wp.ofiCandle    *= 0.8;
         wp.domImbalance *= 1.0;
         wp.volSpike     *= 1.0;
         wp.footprint    *= 1.0;
         wp.hmmState     *= 0.8;
         wp.candlePattern*= 0.8;
         break;
     }
  }

#endif // APEX_CONFIG_MQH
