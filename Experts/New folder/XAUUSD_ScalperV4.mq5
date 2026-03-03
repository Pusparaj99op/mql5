//+------------------------------------------------------------------+
//|                                         XAUUSD_ScalperV4.mq5     |
//|                        XAUUSD Aggressive Scalper EA v4.0          |
//|                        Broker: XM360 | Instrument: XAUUSD        |
//+------------------------------------------------------------------+
#property copyright "XAUUSD Scalper V4"
#property version   "4.00"
// MQL5 does not use #property strict (MQL4 only)

//--- Includes
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Constants
#define EA_NAME    "XAUUSD_ScalperV4"
#define EA_VERSION "4.0"
#define EA_MAGIC   20260101
#define EPSILON    1e-10
#define OBJ_PREFIX "XSv4_"
#define MAX_COMPONENTS 20
#define PERF_BUFFER    50

//+------------------------------------------------------------------+
//| ENUMS                                                             |
//+------------------------------------------------------------------+
enum ENUM_RISK_MODE
{
   RISK_FIXED   = 0, // Fixed Lot
   RISK_PERCENT = 1, // Percent Risk
   RISK_KELLY   = 2, // Kelly Criterion
   RISK_DYNAMIC = 3  // Dynamic (Percent + Kelly blend)
};

enum ENUM_ENTRY_MODE
{
   ENTRY_AGGRESSIVE   = 0, // Aggressive (35)
   ENTRY_MODERATE     = 1, // Moderate (55)
   ENTRY_CONSERVATIVE = 2  // Conservative (70)
};

enum ENUM_VOL_REGIME
{
   VOL_CALM    = 0,
   VOL_NORMAL  = 1,
   VOL_HIGH    = 2,
   VOL_EXTREME = 3
};

//+------------------------------------------------------------------+
//| STRUCTS                                                           |
//+------------------------------------------------------------------+
struct SSignal
{
   int      direction;     // +1 BUY, -1 SELL, 0 NONE
   double   score;         // 0.0 - 100.0
   double   entryPrice;
   double   sl;
   double   tp;
   string   reason;
   datetime generatedAt;
   double   componentScores[MAX_COMPONENTS]; // per-component scores for self-opt
};

struct SMarketState
{
   double   atr;
   double   atrNorm;
   double   atrPips;
   double   spread;
   double   spreadPips;
   int      trend;            // +1 UP, -1 DOWN, 0 RANGE
   int      volatilityRegime; // ENUM_VOL_REGIME
   double   hurstExponent;
   double   zscore;
   double   regressionSlope;
   bool     sessionLondon;
   bool     sessionNewYork;
   bool     sessionOverlap;
   bool     sessionAsian;
   double   sessionWeight;
   double   sessionTPMult;
   double   sessionSLMult;
   double   domImbalance;
   double   tickDeltaRatio;
   double   volumeImbalance;
};

struct SRiskMetrics
{
   double   balance;
   double   equity;
   double   dailyStartBalance;
   double   dailyPnL;
   double   dailyDrawdownPct;
   double   totalDrawdownPct;
   double   peakEquity;
   int      consecutiveLosses;
   int      consecutiveWins;
   double   winRate20;
   double   avgWin;
   double   avgLoss;
   double   expectancy;
   double   kellyFraction;
   double   adaptiveRiskMult;
   double   adaptiveEntryThresh;
   bool     tradingHalted;
   string   haltReason;
   datetime haltUntil;
};

struct SPositionInfo
{
   ulong    ticket;
   int      direction;
   double   openPrice;
   double   sl;
   double   tp;
   double   lots;
   double   profit;
   double   profitPips;
   datetime openTime;
   bool     breakevenMoved;
   bool     partialClosed;
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS — Section 3                                      |
//+------------------------------------------------------------------+

//--- === GENERAL ===
input string          InpSymbol              = "Gold.i#";         // Symbol (XM360)
input ENUM_TIMEFRAMES InpTF                  = PERIOD_M5;         // Primary Timeframe (M5)
input ENUM_TIMEFRAMES InpEntryTF             = PERIOD_M1;         // Entry Trigger Timeframe (M1)
input ENUM_TIMEFRAMES InpHTF                 = PERIOD_H1;         // Higher Timeframe (H1)
input int             InpMagicNumber         = 20260101;          // Magic Number
input string          InpTradeComment        = "XAUUSD_ScalperV4";// Trade Comment
input bool            InpDebugMode           = false;             // Debug Mode

//--- === SESSION FILTER ===
input int  InpStartHour              = 1;     // Session Start Hour
input int  InpEndHour                = 23;    // Session End Hour
input bool InpTradeMonday            = true;  // Trade Monday
input bool InpTradeTuesday           = true;  // Trade Tuesday
input bool InpTradeWednesday         = true;  // Trade Wednesday
input bool InpTradeThursday          = true;  // Trade Thursday
input bool InpTradeFriday            = true;  // Trade Friday
input bool InpUseSessionWeighting    = true;  // Use Session Score Weighting

//--- === RISK MANAGEMENT ===
input ENUM_RISK_MODE InpRiskMode     = RISK_DYNAMIC; // Risk Mode
input double InpFixedLot             = 0.10;  // Fixed Lot Size
input double InpRiskPercent          = 1.5;   // Risk % per Trade [OPTIMIZE]
input double InpKellyFraction        = 0.25;  // Kelly Fraction Cap [OPTIMIZE]
input double InpMinLot               = 0.01;  // Minimum Lot
input double InpMaxLot               = 50.0;  // Maximum Lot
input double InpMaxDailyDrawdown     = 5.0;   // Max Daily Drawdown %
input double InpMaxTotalDrawdown     = 15.0;  // Max Total Drawdown %
input int    InpEmergencyLosses      = 7;     // Emergency Halt After N Consecutive Losses
input int    InpPerformanceWindow    = 20;    // Performance Window (trades)
input double InpMinExpectedValue     = 0.0;   // Min Expected Value (pips)

//--- === ENTRY THRESHOLDS ===
input ENUM_ENTRY_MODE InpEntryMode   = ENTRY_AGGRESSIVE; // Entry Mode
input int  InpMinSignalScore         = 35;    // Min Signal Score [OPTIMIZE]
input int  InpHTFConfirmRequired     = 1;     // HTF Confirmation Required (0=off, 1=on)

//--- === STOP LOSS & TAKE PROFIT ===
input bool   InpUseATRSLTP           = true;  // Use ATR-based SL/TP
input double InpATRMultSL            = 1.5;   // ATR Multiplier for SL [OPTIMIZE]
input double InpATRMultTP            = 2.5;   // ATR Multiplier for TP [OPTIMIZE]
input int    InpFixedSL_Points       = 150;   // Fixed SL (points)
input int    InpFixedTP_Points       = 250;   // Fixed TP (points)
input bool   InpUseDynamicRR         = true;  // Use Dynamic R:R
input double InpMinRR                = 1.0;   // Minimum R:R Ratio
input bool   InpUsePartialTP         = true;  // Use Partial Take Profit
input double InpPartialTPPercent     = 70.0;  // Partial TP Close %
input double InpPartialTPTrigger     = 0.7;   // Partial TP Trigger (fraction of TP) [OPTIMIZE]
input bool   InpUseTrailingStop      = true;  // Use Trailing Stop
input int    InpTrailStart_Points    = 100;   // Trail Start (points)
input int    InpTrailStep_Points     = 20;    // Trail Step (points)
input bool   InpUseBreakeven         = true;  // Use Breakeven
input int    InpBreakevenAt_Points   = 80;    // Breakeven Trigger (points) [OPTIMIZE]
input int    InpBreakevenOffset      = 5;     // Breakeven Offset (points)
input int    InpStaleTradeMaxMins    = 60;    // Stale Trade Max Minutes

//--- === INDICATOR PERIODS ===
input int    InpEMAFast              = 8;     // Fast EMA Period
input int    InpEMAMid               = 21;    // Mid EMA Period
input int    InpEMASlow              = 55;    // Slow EMA Period
input int    InpHTF_EMA50            = 50;    // H1 EMA 50 Period
input int    InpHTF_EMA200           = 200;   // H1 EMA 200 Period
input int    InpRSIPeriod            = 14;    // RSI Period
input double InpRSIOverbought        = 70.0;  // RSI Overbought
input double InpRSIOversold          = 30.0;  // RSI Oversold
input int    InpATRPeriod            = 14;    // ATR Period
input int    InpBBPeriod             = 20;    // Bollinger Bands Period
input double InpBBDeviation          = 2.0;   // Bollinger Bands Deviation
input int    InpMACDFast             = 12;    // MACD Fast
input int    InpMACDSlow             = 26;    // MACD Slow
input int    InpMACDSignal           = 9;     // MACD Signal
input int    InpStochK               = 5;     // Stochastic %K
input int    InpStochD               = 3;     // Stochastic %D
input int    InpStochSlowing         = 3;     // Stochastic Slowing
input int    InpCCIPeriod            = 14;    // CCI Period
input int    InpADXPeriod            = 14;    // ADX Period
input double InpADXMinStrength       = 20.0;  // ADX Min Strength
input int    InpWilliamsPeriod       = 14;    // Williams %R Period
input int    InpMomentumPeriod       = 10;    // Momentum Period

//--- === ORDER FLOW ===
input bool   InpUseDOMIfAvailable    = true;  // Use DOM if Available
input int    InpDOMLevels            = 10;    // DOM Levels
input double InpDOMImbalanceThresh   = 0.18;  // DOM Imbalance Threshold
input int    InpTickBufferSize       = 500;   // Tick Buffer Size
input double InpTickDeltaThresh      = 0.55;  // Tick Delta Threshold
input int    InpVolumeSMAPeriod      = 20;    // Volume SMA Period
input double InpVolSpikeThresh       = 1.5;   // Volume Spike Threshold

//--- === QUANTITATIVE ANALYSIS ===
input int    InpZScorePeriod         = 50;    // Z-Score Period
input double InpZScoreThreshold      = 2.0;   // Z-Score Threshold [OPTIMIZE]
input int    InpHurstPeriod          = 100;   // Hurst Exponent Period [OPTIMIZE]
input int    InpRegressionPeriod     = 30;    // Linear Regression Period
input int    InpEVLookback           = 50;    // Expected Value Lookback

//--- === CANDLE PATTERNS ===
input bool   InpUseCandlePatterns    = true;  // Use Candle Patterns
input double InpEngulfingMinBody     = 1.5;   // Engulfing Min Body Ratio
input double InpPinBarWickRatio      = 2.5;   // Pin Bar Wick Ratio
input bool   InpPatternAsBoost       = true;  // Patterns as Score Boosters

//--- === POSITION CLUSTERING ===
input bool   InpPreventClustering    = true;  // Prevent Position Clustering
input double InpClusterZonePips      = 20.0;  // Cluster Zone (pips)

//--- === VOLATILITY REGIME ===
input double InpATRCalmThreshPips    = 5.0;   // CALM Threshold (ATR pips)
input double InpATRHighThreshPips    = 25.0;  // HIGH Threshold (ATR pips)
input double InpATRExtremeThreshPips = 50.0;  // EXTREME Threshold (ATR pips)
input bool   InpSwitchToHoldOnHigh   = true;  // Switch to Hold Mode on HIGH+trending
input double InpHighVolTPMult        = 1.5;   // HIGH Vol TP Multiplier
input bool   InpPauseOnExtreme       = true;  // Pause on EXTREME Volatility

//--- === SAFETY GUARDS ===
input int    InpMaxSpreadPoints      = 350;   // Max Spread (points)
input int    InpMinATRPoints         = 80;    // Min ATR (points)
input int    InpMaxATRPoints         = 2000;  // Max ATR (points)
input bool   InpNewsFilterEnabled    = false; // News Filter (placeholder)
input int    InpNewsMinsBefore       = 15;    // News Minutes Before
input int    InpNewsMinsAfter        = 15;    // News Minutes After

//--- === CORRELATION SIZING ===
input bool   InpUseCorrelationSizing = true;  // Use Correlation Sizing
input string InpCorrelationSymbol    = "USDJPY"; // Correlation Symbol

//--- === DISPLAY ===
input bool   InpShowDashboard        = true;  // Show Dashboard
input bool   InpShowTrades           = true;  // Show Trade Lines
input bool   InpDrawSRLines          = true;  // Draw S/R Lines
input int    InpDashboardCorner      = 0;     // Dashboard Corner (0-3)
input int    InpDashX                = 10;    // Dashboard X Offset
input int    InpDashY                = 15;    // Dashboard Y Offset
input color  InpDashBgColor          = C'12,12,22';    // Dashboard BG Color
input color  InpDashBorderColor      = clrDodgerBlue;  // Dashboard Border Color
input int    InpDashFontSize         = 9;     // Dashboard Font Size

//--- === BACKTESTING ===
input bool   InpIsOptimizing         = false; // Is Optimizing
input int    InpMinTradesForScore    = 20;    // Min Trades for Tester Score

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+

//--- Trade objects
CTrade         Trade;
CPositionInfo  PosInfo;
CSymbolInfo    SymInfo;
CAccountInfo   AccInfo;

//--- Core state
SSignal        g_signal;
SMarketState   g_market;
SRiskMetrics   g_risk;
string         g_symbol;
double         g_point;
int            g_digits;
double         g_lotStep;
double         g_lotMin;
double         g_lotMax;
double         g_tickValue;
double         g_tickSize;
int            g_stopsLevel;
bool           g_isTester;

//--- Indicator handles
int h_emaFast, h_emaMid, h_emaSlow;
int h_htfEMA50, h_htfEMA200;
int h_rsi, h_atr, h_bb, h_macd;
int h_stoch, h_cci, h_adx, h_wpr, h_mom;
int h_sar, h_ichi;
int h_m1EmaFast, h_m1EmaMid;
bool g_sarOK = false, g_ichiOK = false;

//--- Indicator buffers
double bufEMAFast[], bufEMAMid[], bufEMASlow[];
double bufHTF_EMA50[], bufHTF_EMA200[];
double bufRSI[], bufATR[];
double bufBBUpper[], bufBBMid[], bufBBLower[];
double bufMACDMain[], bufMACDSignal[];
double bufStochK[], bufStochD[];
double bufCCI[], bufADXMain[], bufADXPlus[], bufADXMinus[];
double bufWPR[], bufMomentum[];
double bufSAR[];
double bufIchiTenkan[], bufIchiKijun[];
double bufM1EmaFast[], bufM1EmaMid[];

//--- Bar tracking
datetime g_lastM5Bar = 0;
datetime g_lastM1Bar = 0;
int      g_tickCount = 0;
datetime g_lastTickTime = 0;

//--- Entry trigger state
bool     g_entryArmed = false;
int      g_armedDirection = 0;
double   g_armedScore = 0;
datetime g_armedAt = 0;
int      g_armedBarCount = 0;
double   g_armedComponentScores[MAX_COMPONENTS];

//--- Order flow: DOM
bool     g_domOK = false;

//--- Order flow: Tick delta ring buffer
struct STickData { double price; double bid; double ask; long volume; int side; };
STickData g_tickBuf[];
int       g_tickBufIdx = 0;
int       g_tickBufCount = 0;

//--- Spread ring buffer for microstructure
double g_spreadBuf[50];
int    g_spreadBufIdx = 0;
int    g_spreadBufCount = 0;

//--- Performance ring buffer
double g_perfBuf[];
int    g_perfBufIdx = 0;
int    g_perfBufCount = 0;
int    g_totalTrades = 0;

//--- Component weight self-optimisation
string g_componentNames[MAX_COMPONENTS];
double g_componentWeights[MAX_COMPONENTS];
double g_componentNetPips[MAX_COMPONENTS];
int    g_componentTradeCount = 0;
int    g_numComponents = 0;

//--- Position tracking
SPositionInfo g_positions[];
int           g_posCount = 0;

//--- Chop filter
int      g_chopOscCount = 0;
datetime g_chopLastTime = 0;
double   g_chopLastMid = 0;
bool     g_chopDetected = false;
datetime g_chopDelayUntil = 0;

//--- Daily tracking
int      g_lastDay = -1;

//--- S/R levels (simple fractal-based)
double g_srLevels[];
int    g_srCount = 0;

//+------------------------------------------------------------------+
//| SECTION 22: OnInit                                                |
//+------------------------------------------------------------------+
int OnInit()
{
   g_isTester = (bool)MQLInfoInteger(MQL_TESTER);

   //--- Symbol resolution (Section 1.1)
   string trySymbols[] = {InpSymbol, "XAUUSD", "GOLD", "XAUUSDm", "XAUUSD.i"};
   g_symbol = "";
   for(int i = 0; i < ArraySize(trySymbols); i++)
   {
      if(SymbolSelect(trySymbols[i], true) && SymbolInfoDouble(trySymbols[i], SYMBOL_BID) > 0)
      {
         g_symbol = trySymbols[i];
         break;
      }
   }
   if(g_symbol == "")
   {
      Print("FATAL: No valid XAUUSD symbol found!");
      return INIT_PARAMETERS_INCORRECT;
   }

   //--- Validate symbol (Section 1.2)
   if(!SymInfo.Name(g_symbol))
   {
      Print("FATAL: Cannot set symbol info for ", g_symbol);
      return INIT_PARAMETERS_INCORRECT;
   }
   SymInfo.RefreshRates();

   g_point     = SymbolInfoDouble(g_symbol, SYMBOL_POINT);
   g_digits    = (int)SymbolInfoInteger(g_symbol, SYMBOL_DIGITS);
   g_lotStep   = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_STEP);
   g_lotMin    = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MIN);
   g_lotMax    = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MAX);
   g_tickValue = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_VALUE);
   g_tickSize  = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);
   g_stopsLevel= (int)SymbolInfoInteger(g_symbol, SYMBOL_TRADE_STOPS_LEVEL);

   if(g_point == 0 || g_digits < 1 || g_lotStep <= 0)
   {
      Print("FATAL: Invalid symbol properties. point=", g_point, " digits=", g_digits, " lotStep=", g_lotStep);
      return INIT_PARAMETERS_INCORRECT;
   }

   string profitCurr = SymbolInfoString(g_symbol, SYMBOL_CURRENCY_PROFIT);
   if(profitCurr != "USD")
      Print("WARNING: Profit currency is ", profitCurr, " (expected USD)");

   //--- Setup trade object (Section 2.3)
   Trade.SetExpertMagicNumber(InpMagicNumber);
   Trade.SetDeviationInPoints(50);
   Trade.SetTypeFilling(ORDER_FILLING_IOC);

   //--- Init indicator handles (Section 4)
   if(!InitIndicators())
   {
      Print("FATAL: Failed to initialise indicators");
      return INIT_FAILED;
   }

   //--- Init DOM (Section 7.1)
   if(InpUseDOMIfAvailable && !g_isTester)
   {
      g_domOK = MarketBookAdd(g_symbol);
      if(!g_domOK)
         Print("WARNING: DOM not available for ", g_symbol);
   }

   //--- Init tick buffer
   ArrayResize(g_tickBuf, InpTickBufferSize);
   g_tickBufIdx = 0;
   g_tickBufCount = 0;

   //--- Init performance buffer
   ArrayResize(g_perfBuf, PERF_BUFFER);
   g_perfBufIdx = 0;
   g_perfBufCount = 0;

   //--- Init risk metrics
   g_risk.balance           = AccInfo.Balance();
   g_risk.equity            = AccInfo.Equity();
   g_risk.dailyStartBalance = g_risk.balance;
   g_risk.peakEquity        = g_risk.equity;
   g_risk.adaptiveRiskMult  = 1.0;
   g_risk.adaptiveEntryThresh = InpMinSignalScore;
   g_risk.tradingHalted     = false;
   g_risk.haltReason        = "";
   g_risk.haltUntil         = 0;
   g_risk.consecutiveLosses = 0;
   g_risk.consecutiveWins   = 0;

   //--- Init component weights
   InitComponentWeights();

   //--- Init S/R
   ArrayResize(g_srLevels, 0);
   g_srCount = 0;

   //--- Print startup info
   Print("═══════════════════════════════════════════════");
   Print("  ", EA_NAME, " v", EA_VERSION, " INITIALISED");
   Print("  Symbol  : ", g_symbol);
   Print("  Point   : ", g_point, "  Digits: ", g_digits);
   Print("  Magic   : ", InpMagicNumber);
   Print("  Balance : ", DoubleToString(AccInfo.Balance(), 2));
   Print("  Entry   : ", EnumToString(InpEntryMode), " (threshold=", InpMinSignalScore, ")");
   Print("  Risk    : ", EnumToString(InpRiskMode));
   Print("═══════════════════════════════════════════════");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release indicator handles
   if(h_emaFast   != INVALID_HANDLE) IndicatorRelease(h_emaFast);
   if(h_emaMid    != INVALID_HANDLE) IndicatorRelease(h_emaMid);
   if(h_emaSlow   != INVALID_HANDLE) IndicatorRelease(h_emaSlow);
   if(h_htfEMA50  != INVALID_HANDLE) IndicatorRelease(h_htfEMA50);
   if(h_htfEMA200 != INVALID_HANDLE) IndicatorRelease(h_htfEMA200);
   if(h_rsi       != INVALID_HANDLE) IndicatorRelease(h_rsi);
   if(h_atr       != INVALID_HANDLE) IndicatorRelease(h_atr);
   if(h_bb        != INVALID_HANDLE) IndicatorRelease(h_bb);
   if(h_macd      != INVALID_HANDLE) IndicatorRelease(h_macd);
   if(h_stoch     != INVALID_HANDLE) IndicatorRelease(h_stoch);
   if(h_cci       != INVALID_HANDLE) IndicatorRelease(h_cci);
   if(h_adx       != INVALID_HANDLE) IndicatorRelease(h_adx);
   if(h_wpr       != INVALID_HANDLE) IndicatorRelease(h_wpr);
   if(h_mom       != INVALID_HANDLE) IndicatorRelease(h_mom);
   if(g_sarOK  && h_sar  != INVALID_HANDLE) IndicatorRelease(h_sar);
   if(g_ichiOK && h_ichi != INVALID_HANDLE) IndicatorRelease(h_ichi);
   if(h_m1EmaFast != INVALID_HANDLE) IndicatorRelease(h_m1EmaFast);
   if(h_m1EmaMid  != INVALID_HANDLE) IndicatorRelease(h_m1EmaMid);

   //--- Release DOM
   if(g_domOK) MarketBookRelease(g_symbol);

   //--- Remove chart objects
   ObjectsDeleteAll(0, OBJ_PREFIX, -1, -1);

   Print(EA_NAME, " v", EA_VERSION, " removed. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| InitIndicators — Section 4                                        |
//+------------------------------------------------------------------+
bool InitIndicators()
{
   //--- Primary TF indicators
   h_emaFast  = iMA(g_symbol, InpTF, InpEMAFast,  0, MODE_EMA, PRICE_CLOSE);
   h_emaMid   = iMA(g_symbol, InpTF, InpEMAMid,   0, MODE_EMA, PRICE_CLOSE);
   h_emaSlow  = iMA(g_symbol, InpTF, InpEMASlow,  0, MODE_EMA, PRICE_CLOSE);
   h_rsi      = iRSI(g_symbol, InpTF, InpRSIPeriod, PRICE_CLOSE);
   h_atr      = iATR(g_symbol, InpTF, InpATRPeriod);
   h_bb       = iBands(g_symbol, InpTF, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   h_macd     = iMACD(g_symbol, InpTF, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   h_stoch    = iStochastic(g_symbol, InpTF, InpStochK, InpStochD, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
   h_cci      = iCCI(g_symbol, InpTF, InpCCIPeriod, PRICE_TYPICAL);
   h_adx      = iADX(g_symbol, InpTF, InpADXPeriod);
   h_wpr      = iWPR(g_symbol, InpTF, InpWilliamsPeriod);
   h_mom      = iMomentum(g_symbol, InpTF, InpMomentumPeriod, PRICE_CLOSE);

   //--- HTF indicators
   h_htfEMA50  = iMA(g_symbol, InpHTF, InpHTF_EMA50,  0, MODE_EMA, PRICE_CLOSE);
   h_htfEMA200 = iMA(g_symbol, InpHTF, InpHTF_EMA200, 0, MODE_EMA, PRICE_CLOSE);

   //--- M1 entry trigger EMAs
   h_m1EmaFast = iMA(g_symbol, InpEntryTF, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
   h_m1EmaMid  = iMA(g_symbol, InpEntryTF, InpEMAMid,  0, MODE_EMA, PRICE_CLOSE);

   //--- Validate required handles
   if(h_emaFast == INVALID_HANDLE || h_emaMid  == INVALID_HANDLE || h_emaSlow == INVALID_HANDLE ||
      h_rsi    == INVALID_HANDLE || h_atr     == INVALID_HANDLE || h_bb     == INVALID_HANDLE ||
      h_macd   == INVALID_HANDLE || h_stoch   == INVALID_HANDLE || h_cci    == INVALID_HANDLE ||
      h_adx    == INVALID_HANDLE || h_wpr     == INVALID_HANDLE || h_mom    == INVALID_HANDLE ||
      h_htfEMA50 == INVALID_HANDLE || h_htfEMA200 == INVALID_HANDLE ||
      h_m1EmaFast == INVALID_HANDLE || h_m1EmaMid == INVALID_HANDLE)
   {
      Print("InitIndicators: FAILED — one or more handles are INVALID");
      return false;
   }

   //--- Optional: SAR (fail gracefully)
   h_sar = iSAR(g_symbol, InpTF, 0.02, 0.2);
   g_sarOK = (h_sar != INVALID_HANDLE);
   if(!g_sarOK) Print("WARNING: SAR indicator not available");

   //--- Optional: Ichimoku (fail gracefully)
   h_ichi = iIchimoku(g_symbol, InpTF, 9, 26, 52);
   g_ichiOK = (h_ichi != INVALID_HANDLE);
   if(!g_ichiOK) Print("WARNING: Ichimoku indicator not available");

   //--- Set arrays as series
   ArraySetAsSeries(bufEMAFast, true);  ArraySetAsSeries(bufEMAMid, true);
   ArraySetAsSeries(bufEMASlow, true);  ArraySetAsSeries(bufHTF_EMA50, true);
   ArraySetAsSeries(bufHTF_EMA200, true);
   ArraySetAsSeries(bufRSI, true);      ArraySetAsSeries(bufATR, true);
   ArraySetAsSeries(bufBBUpper, true);  ArraySetAsSeries(bufBBMid, true);
   ArraySetAsSeries(bufBBLower, true);
   ArraySetAsSeries(bufMACDMain, true); ArraySetAsSeries(bufMACDSignal, true);
   ArraySetAsSeries(bufStochK, true);   ArraySetAsSeries(bufStochD, true);
   ArraySetAsSeries(bufCCI, true);
   ArraySetAsSeries(bufADXMain, true);  ArraySetAsSeries(bufADXPlus, true);
   ArraySetAsSeries(bufADXMinus, true);
   ArraySetAsSeries(bufWPR, true);      ArraySetAsSeries(bufMomentum, true);
   if(g_sarOK)  ArraySetAsSeries(bufSAR, true);
   if(g_ichiOK) { ArraySetAsSeries(bufIchiTenkan, true); ArraySetAsSeries(bufIchiKijun, true); }
   ArraySetAsSeries(bufM1EmaFast, true); ArraySetAsSeries(bufM1EmaMid, true);

   return true;
}

//+------------------------------------------------------------------+
//| InitComponentWeights — Section 12.5                               |
//+------------------------------------------------------------------+
void InitComponentWeights()
{
   g_numComponents = 19;
   string names[] = {"EMA_Align","H1_Trend","RSI","MACD","Stoch","CCI","WPR",
                     "Momentum","BB","ADX","SAR","SR_Breakout","DOM","TickDelta",
                     "VolSpike","ZScore","Hurst","LinReg","CandlePattern"};
   for(int i = 0; i < g_numComponents; i++)
   {
      g_componentNames[i]    = names[i];
      g_componentWeights[i]  = 1.0;
      g_componentNetPips[i]  = 0.0;
   }
   g_componentTradeCount = 0;
}

//+------------------------------------------------------------------+
//| RefreshIndicators — Layer A (Data)                                |
//+------------------------------------------------------------------+
bool RefreshIndicators()
{
   int bars = 5;
   if(CopyBuffer(h_emaFast,  0, 0, bars, bufEMAFast)  < bars) { Print("RefreshIndicators: CopyBuffer emaFast FAILED h=", h_emaFast); return false; }
   if(CopyBuffer(h_emaMid,   0, 0, bars, bufEMAMid)   < bars) { Print("RefreshIndicators: CopyBuffer emaMid FAILED h=", h_emaMid); return false; }
   if(CopyBuffer(h_emaSlow,  0, 0, bars, bufEMASlow)  < bars) { Print("RefreshIndicators: CopyBuffer emaSlow FAILED h=", h_emaSlow); return false; }
   if(CopyBuffer(h_rsi,      0, 0, bars, bufRSI)      < bars) { Print("RefreshIndicators: CopyBuffer RSI FAILED h=", h_rsi); return false; }
   if(CopyBuffer(h_atr,      0, 0, bars, bufATR)      < bars) { Print("RefreshIndicators: CopyBuffer ATR FAILED h=", h_atr); return false; }
   if(CopyBuffer(h_bb,       1, 0, bars, bufBBUpper)   < bars) return false;
   if(CopyBuffer(h_bb,       0, 0, bars, bufBBMid)     < bars) return false;
   if(CopyBuffer(h_bb,       2, 0, bars, bufBBLower)   < bars) return false;
   if(CopyBuffer(h_macd,     0, 0, bars, bufMACDMain)  < bars) return false;
   if(CopyBuffer(h_macd,     1, 0, bars, bufMACDSignal)< bars) return false;
   if(CopyBuffer(h_stoch,    0, 0, bars, bufStochK)    < bars) return false;
   if(CopyBuffer(h_stoch,    1, 0, bars, bufStochD)    < bars) return false;
   if(CopyBuffer(h_cci,      0, 0, bars, bufCCI)       < bars) return false;
   if(CopyBuffer(h_adx,      0, 0, bars, bufADXMain)   < bars) return false;
   if(CopyBuffer(h_adx,      1, 0, bars, bufADXPlus)   < bars) return false;
   if(CopyBuffer(h_adx,      2, 0, bars, bufADXMinus)  < bars) return false;
   if(CopyBuffer(h_wpr,      0, 0, bars, bufWPR)       < bars) return false;
   if(CopyBuffer(h_mom,      0, 0, bars, bufMomentum)  < bars) return false;

   //--- HTF
   if(CopyBuffer(h_htfEMA50,  0, 0, 3, bufHTF_EMA50)  < 3) return false;
   if(CopyBuffer(h_htfEMA200, 0, 0, 3, bufHTF_EMA200) < 3) return false;

   //--- Optional
   if(g_sarOK) { if(CopyBuffer(h_sar, 0, 0, bars, bufSAR) < bars) g_sarOK = false; }
   if(g_ichiOK)
   {
      if(CopyBuffer(h_ichi, 0, 0, bars, bufIchiTenkan) < bars) g_ichiOK = false;
      if(g_ichiOK && CopyBuffer(h_ichi, 1, 0, bars, bufIchiKijun) < bars) g_ichiOK = false;
   }

   //--- M1 EMAs
   if(CopyBuffer(h_m1EmaFast, 0, 0, 3, bufM1EmaFast) < 3) return false;
   if(CopyBuffer(h_m1EmaMid,  0, 0, 3, bufM1EmaMid)  < 3) return false;

   return true;
}

//+------------------------------------------------------------------+
//| UpdateMarketState — Layer B (Analysis)                            |
//+------------------------------------------------------------------+
void UpdateMarketState()
{
   double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double close0 = iClose(g_symbol, InpTF, 0);

   //--- ATR and volatility
   g_market.atr       = bufATR[1];
   g_market.atrPips   = g_market.atr / (g_point * 10.0 + EPSILON);
   g_market.atrNorm   = g_market.atr / (close0 + EPSILON) * 10000.0;
   g_market.spread    = ask - bid;
   g_market.spreadPips= g_market.spread / (g_point * 10.0 + EPSILON);

   //--- H1 Trend (Section 5.1)
   if(bufHTF_EMA50[0] > bufHTF_EMA200[0] && close0 > bufHTF_EMA50[0])
      g_market.trend = 1;  // UP
   else if(bufHTF_EMA50[0] < bufHTF_EMA200[0] && close0 < bufHTF_EMA50[0])
      g_market.trend = -1; // DOWN
   else
      g_market.trend = 0;  // RANGE

   //--- Volatility Regime (Section 16)
   if(g_market.atrPips < InpATRCalmThreshPips)
      g_market.volatilityRegime = VOL_CALM;
   else if(g_market.atrPips < InpATRHighThreshPips)
      g_market.volatilityRegime = VOL_NORMAL;
   else if(g_market.atrPips < InpATRExtremeThreshPips)
      g_market.volatilityRegime = VOL_HIGH;
   else
      g_market.volatilityRegime = VOL_EXTREME;

   //--- Session Detection (Section 17)
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;
   g_market.sessionLondon  = (h >= 7 && h < 16);
   g_market.sessionNewYork = (h >= 13 && h < 22);
   g_market.sessionOverlap = (h >= 13 && h < 16);
   g_market.sessionAsian   = (h >= 0 && h < 7);

   //--- Session weight multiplier (Section 17.2)
   g_market.sessionWeight = 1.0;
   g_market.sessionTPMult = 1.0;
   g_market.sessionSLMult = 1.0;
   if(InpUseSessionWeighting)
   {
      if(g_market.sessionOverlap)
      {
         g_market.sessionWeight = 1.25;
         g_market.sessionTPMult = 1.10;
      }
      else if(g_market.sessionLondon)
         g_market.sessionWeight = 1.10;
      else if(g_market.sessionNewYork)
         g_market.sessionWeight = 1.10;
      else if(g_market.sessionAsian)
      {
         g_market.sessionWeight = 0.85;
         g_market.sessionSLMult = 0.90;
         g_market.sessionTPMult = 0.80;
      }
      else
         g_market.sessionWeight = 0.90;
   }

   //--- Hurst Exponent (Section 8.2)
   g_market.hurstExponent = CalcHurstExponent();

   //--- Z-Score (Section 8.1)
   g_market.zscore = CalcZScore();

   //--- Linear Regression slope (Section 8.3)
   g_market.regressionSlope = CalcLinRegSlope();

   //--- Order flow metrics (updated elsewhere via tick/DOM)
}

//+------------------------------------------------------------------+
//| CalcHurstExponent — R/S Analysis (Section 8.2)                    |
//+------------------------------------------------------------------+
double CalcHurstExponent()
{
   int period = InpHurstPeriod;
   double closes[];
   if(CopyClose(g_symbol, InpTF, 0, period + 1, closes) < period + 1)
      return 0.5;
   ArraySetAsSeries(closes, true);

   //--- Calculate returns
   double returns[];
   ArrayResize(returns, period);
   for(int i = 0; i < period; i++)
      returns[i] = MathLog(closes[i] / (closes[i+1] + EPSILON) + EPSILON);

   //--- R/S analysis at multiple sub-periods
   double logRS[], logN[];
   int sizes[] = {10, 20, 40, 50};
   int validCount = 0;
   ArrayResize(logRS, 4);
   ArrayResize(logN, 4);

   for(int s = 0; s < 4; s++)
   {
      int n = sizes[s];
      if(n > period) continue;
      int numBlocks = period / n;
      if(numBlocks < 1) continue;

      double rsSum = 0;
      int blockCount = 0;
      for(int b = 0; b < numBlocks; b++)
      {
         int start = b * n;
         double mean = 0;
         for(int i = 0; i < n; i++) mean += returns[start + i];
         mean /= n;

         double cumDev = 0, maxCum = -1e100, minCum = 1e100;
         double sumSq = 0;
         for(int i = 0; i < n; i++)
         {
            double dev = returns[start + i] - mean;
            cumDev += dev;
            if(cumDev > maxCum) maxCum = cumDev;
            if(cumDev < minCum) minCum = cumDev;
            sumSq += dev * dev;
         }
         double R = maxCum - minCum;
         double S = MathSqrt(sumSq / (n + EPSILON));
         if(S > EPSILON)
         {
            rsSum += R / S;
            blockCount++;
         }
      }
      if(blockCount > 0)
      {
         logRS[validCount] = MathLog(rsSum / blockCount + EPSILON);
         logN[validCount]  = MathLog((double)n);
         validCount++;
      }
   }

   if(validCount < 2) return 0.5;

   //--- Linear regression of log(R/S) on log(n) => slope = H
   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   for(int i = 0; i < validCount; i++)
   {
      sumX  += logN[i];
      sumY  += logRS[i];
      sumXY += logN[i] * logRS[i];
      sumX2 += logN[i] * logN[i];
   }
   double denom = validCount * sumX2 - sumX * sumX;
   if(MathAbs(denom) < EPSILON) return 0.5;
   double H = (validCount * sumXY - sumX * sumY) / denom;
   return MathMax(0.0, MathMin(1.0, H));
}

//+------------------------------------------------------------------+
//| CalcZScore — Section 8.1                                          |
//+------------------------------------------------------------------+
double CalcZScore()
{
   double closes[];
   if(CopyClose(g_symbol, InpTF, 0, InpZScorePeriod + 1, closes) < InpZScorePeriod + 1)
      return 0.0;
   ArraySetAsSeries(closes, true);

   double sum = 0, sumSq = 0;
   for(int i = 1; i <= InpZScorePeriod; i++)
   {
      sum   += closes[i];
      sumSq += closes[i] * closes[i];
   }
   double mean = sum / InpZScorePeriod;
   double var  = sumSq / InpZScorePeriod - mean * mean;
   double sd   = MathSqrt(MathMax(0, var));
   if(sd < EPSILON) return 0.0;
   return (closes[0] - mean) / sd;
}

//+------------------------------------------------------------------+
//| CalcLinRegSlope — Section 8.3                                     |
//+------------------------------------------------------------------+
double CalcLinRegSlope()
{
   double closes[];
   if(CopyClose(g_symbol, InpTF, 0, InpRegressionPeriod, closes) < InpRegressionPeriod)
      return 0.0;
   ArraySetAsSeries(closes, true);

   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   int n = InpRegressionPeriod;
   for(int i = 0; i < n; i++)
   {
      double x = (double)(n - 1 - i);
      sumX  += x;
      sumY  += closes[i];
      sumXY += x * closes[i];
      sumX2 += x * x;
   }
   double denom = n * sumX2 - sumX * sumX;
   if(MathAbs(denom) < EPSILON) return 0.0;
   double slope = (n * sumXY - sumX * sumY) / denom;
   //--- Normalise by ATR
   if(g_market.atr > EPSILON)
      return slope / g_market.atr * 100.0;
   return 0.0;
}

//+------------------------------------------------------------------+
//| UpdateTickBuffer — Section 7.2                                    |
//+------------------------------------------------------------------+
void UpdateTickBuffer()
{
   MqlTick tick;
   if(!SymbolInfoTick(g_symbol, tick)) return;

   //--- Detect tick gap (reconnect detection, Section 23.5)
   if(g_lastTickTime > 0 && tick.time - g_lastTickTime > 60)
   {
      g_tickBufCount = 0;
      g_tickBufIdx   = 0;
      g_domOK        = false;
      if(InpUseDOMIfAvailable && !g_isTester)
         g_domOK = MarketBookAdd(g_symbol);
      Print("WARNING: Tick gap > 60s detected — buffers reset");
   }
   g_lastTickTime = tick.time;

   //--- Classify tick side
   int side = 0;
   if(g_tickBufCount > 0)
   {
      int prevIdx = (g_tickBufIdx - 1 + InpTickBufferSize) % InpTickBufferSize;
      if(tick.last >= g_tickBuf[prevIdx].ask) side = 1;   // Buy
      else if(tick.last <= g_tickBuf[prevIdx].bid) side = -1; // Sell
   }

   //--- Store
   g_tickBuf[g_tickBufIdx].price  = tick.last > 0 ? tick.last : tick.bid;
   g_tickBuf[g_tickBufIdx].bid    = tick.bid;
   g_tickBuf[g_tickBufIdx].ask    = tick.ask;
   g_tickBuf[g_tickBufIdx].volume = (long)tick.volume;
   g_tickBuf[g_tickBufIdx].side   = side;
   g_tickBufIdx = (g_tickBufIdx + 1) % InpTickBufferSize;
   if(g_tickBufCount < InpTickBufferSize) g_tickBufCount++;

   //--- Compute tick delta ratio
   double buyVol = 0, sellVol = 0;
   for(int i = 0; i < g_tickBufCount; i++)
   {
      if(g_tickBuf[i].side > 0)  buyVol  += (double)g_tickBuf[i].volume;
      if(g_tickBuf[i].side < 0)  sellVol += (double)g_tickBuf[i].volume;
   }
   g_market.tickDeltaRatio = buyVol / (buyVol + sellVol + EPSILON);

   //--- Update spread ring buffer (Section 15)
   double currentSpread = tick.ask - tick.bid;
   g_spreadBuf[g_spreadBufIdx] = currentSpread;
   g_spreadBufIdx = (g_spreadBufIdx + 1) % 50;
   if(g_spreadBufCount < 50) g_spreadBufCount++;

   //--- Chop detection (Section 15.3)
   double mid = (tick.bid + tick.ask) / 2.0;
   if(g_chopLastTime > 0 && tick.time == g_chopLastTime)
   {
      if(MathAbs(mid - g_chopLastMid) > EPSILON && ((mid > g_chopLastMid && g_chopOscCount > 0) || g_chopOscCount == 0))
         g_chopOscCount++;
   }
   else
   {
      if(g_chopOscCount >= 3)
      {
         g_chopDetected = true;
         //--- Delay entry by 1 M1 bar
         g_chopDelayUntil = TimeCurrent() + PeriodSeconds(InpEntryTF);
      }
      g_chopOscCount = 0;
   }
   g_chopLastMid  = mid;
   g_chopLastTime = tick.time;
}

//+------------------------------------------------------------------+
//| UpdateVolumeImbalance — Section 7.3                               |
//+------------------------------------------------------------------+
void UpdateVolumeImbalance()
{
   long volumes[];
   if(CopyTickVolume(g_symbol, InpTF, 0, InpVolumeSMAPeriod + 1, volumes) < InpVolumeSMAPeriod + 1)
   {
      g_market.volumeImbalance = 0;
      return;
   }
   ArraySetAsSeries(volumes, true);

   double smaVol = 0;
   for(int i = 1; i <= InpVolumeSMAPeriod; i++)
      smaVol += (double)volumes[i];
   smaVol /= InpVolumeSMAPeriod;

   g_market.volumeImbalance = (double)volumes[0] / (smaVol + EPSILON);
}

//+------------------------------------------------------------------+
//| UpdateSRLevels — Simple fractal S/R detection                     |
//+------------------------------------------------------------------+
void UpdateSRLevels()
{
   double highs[], lows[];
   int lookback = 100;
   if(CopyHigh(g_symbol, InpTF, 0, lookback, highs) < lookback) return;
   if(CopyLow(g_symbol, InpTF, 0, lookback, lows)   < lookback) return;
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);

   ArrayResize(g_srLevels, 0);
   g_srCount = 0;

   for(int i = 2; i < lookback - 2; i++)
   {
      //--- Resistance (fractal high)
      if(highs[i] > highs[i-1] && highs[i] > highs[i-2] &&
         highs[i] > highs[i+1] && highs[i] > highs[i+2])
      {
         int sz = ArraySize(g_srLevels);
         ArrayResize(g_srLevels, sz + 1);
         g_srLevels[sz] = highs[i];
         g_srCount++;
      }
      //--- Support (fractal low)
      if(lows[i] < lows[i-1] && lows[i] < lows[i-2] &&
         lows[i] < lows[i+1] && lows[i] < lows[i+2])
      {
         int sz = ArraySize(g_srLevels);
         ArrayResize(g_srLevels, sz + 1);
         g_srLevels[sz] = lows[i];
         g_srCount++;
      }
   }
}

//+------------------------------------------------------------------+
//| RunScoringEngine — Section 6 (19 components)                      |
//+------------------------------------------------------------------+
void RunScoringEngine()
{
   double rawScore = 0;
   double maxPossible = 0;
   double close0 = iClose(g_symbol, InpTF, 1);
   double close1 = iClose(g_symbol, InpTF, 2);
   ArrayInitialize(g_signal.componentScores, 0);

   //--- 1. EMA Alignment (±15)
   double emaScore = 0;
   maxPossible += 15;
   if(bufEMAFast[1] > bufEMAMid[1] && bufEMAMid[1] > bufEMASlow[1])
      emaScore = 15.0;
   else if(bufEMAFast[1] < bufEMAMid[1] && bufEMAMid[1] < bufEMASlow[1])
      emaScore = -15.0;
   //--- ADX suppression (Section 4.4)
   if(bufADXMain[1] < 15) emaScore *= 0.5;
   emaScore *= g_componentWeights[0];
   g_signal.componentScores[0] = emaScore;
   rawScore += emaScore;

   //--- 2. H1 Trend Confirmation (±12)
   double htfScore = 0;
   maxPossible += 12;
   if(g_market.trend == 1) htfScore = 12.0;
   else if(g_market.trend == -1) htfScore = -12.0;
   htfScore *= g_componentWeights[1];
   g_signal.componentScores[1] = htfScore;
   rawScore += htfScore;

   //--- 3. RSI (±15)
   double rsiScore = 0;
   maxPossible += 15;
   double rsi = bufRSI[1], rsiPrev = bufRSI[2];
   if(rsiPrev < InpRSIOversold && rsi >= InpRSIOversold) rsiScore = 10.0;
   else if(rsiPrev > InpRSIOverbought && rsi <= InpRSIOverbought) rsiScore = -10.0;
   if(rsi >= 40 && rsi <= 60) rsiScore += (rsi > 50 ? 5.0 : -5.0);
   rsiScore = MathMax(-15.0, MathMin(15.0, rsiScore));
   rsiScore *= g_componentWeights[2];
   g_signal.componentScores[2] = rsiScore;
   rawScore += rsiScore;

   //--- 4. MACD Crossover + Histogram (±20)
   double macdScore = 0;
   maxPossible += 20;
   double macdMain0 = bufMACDMain[1], macdSig0 = bufMACDSignal[1];
   double macdMain1 = bufMACDMain[2], macdSig1 = bufMACDSignal[2];
   double hist0 = macdMain0 - macdSig0, hist1 = macdMain1 - macdSig1;
   if(macdMain1 < macdSig1 && macdMain0 >= macdSig0) macdScore = 15.0;
   else if(macdMain1 > macdSig1 && macdMain0 <= macdSig0) macdScore = -15.0;
   if(MathAbs(hist0) > MathAbs(hist1)) macdScore += (hist0 > 0 ? 5.0 : -5.0);
   macdScore = MathMax(-20.0, MathMin(20.0, macdScore));
   macdScore *= g_componentWeights[3];
   g_signal.componentScores[3] = macdScore;
   rawScore += macdScore;

   //--- 5. Stochastic Crossover (±10)
   double stochScore = 0;
   maxPossible += 10;
   if(bufStochK[2] < bufStochD[2] && bufStochK[1] >= bufStochD[1] && bufStochK[1] < 20)
      stochScore = 10.0;
   else if(bufStochK[2] > bufStochD[2] && bufStochK[1] <= bufStochD[1] && bufStochK[1] > 80)
      stochScore = -10.0;
   stochScore *= g_componentWeights[4];
   g_signal.componentScores[4] = stochScore;
   rawScore += stochScore;

   //--- 6. CCI (±8)
   double cciScore = 0;
   maxPossible += 8;
   if(bufCCI[2] < -100 && bufCCI[1] >= -100) cciScore = 8.0;
   else if(bufCCI[2] > 100 && bufCCI[1] <= 100) cciScore = -8.0;
   cciScore *= g_componentWeights[5];
   g_signal.componentScores[5] = cciScore;
   rawScore += cciScore;

   //--- 7. Williams %R (±5)
   double wprScore = 0;
   maxPossible += 5;
   if(bufWPR[1] < -80) wprScore = 5.0;
   else if(bufWPR[1] > -20) wprScore = -5.0;
   wprScore *= g_componentWeights[6];
   g_signal.componentScores[6] = wprScore;
   rawScore += wprScore;

   //--- 8. Momentum (±5)
   double momScore = 0;
   maxPossible += 5;
   if(bufMomentum[1] > 100) momScore = 5.0;
   else if(bufMomentum[1] < 100) momScore = -5.0;
   momScore *= g_componentWeights[7];
   g_signal.componentScores[7] = momScore;
   rawScore += momScore;

   //--- 9. BB Position + Expansion (±18)
   double bbScore = 0;
   maxPossible += 18;
   if(close0 < bufBBLower[1] && bufRSI[1] < 35) bbScore = 12.0;
   else if(close0 > bufBBUpper[1] && bufRSI[1] > 65) bbScore = -12.0;
   double bbWidth0 = bufBBUpper[1] - bufBBLower[1];
   double bbWidth1 = bufBBUpper[2] - bufBBLower[2];
   if(bbWidth0 > bbWidth1 * 1.1 && g_market.volumeImbalance > InpVolSpikeThresh)
   {
      if(close0 > bufBBUpper[1]) bbScore = 18.0;
      else if(close0 < bufBBLower[1]) bbScore = -18.0;
   }
   bbScore = MathMax(-18.0, MathMin(18.0, bbScore));
   bbScore *= g_componentWeights[8];
   g_signal.componentScores[8] = bbScore;
   rawScore += bbScore;

   //--- 10. ADX Trend Strength Bonus (+5)
   double adxScore = 0;
   maxPossible += 5;
   if(bufADXMain[1] > 30) adxScore = 5.0;
   adxScore *= g_componentWeights[9];
   g_signal.componentScores[9] = adxScore;
   rawScore += adxScore;

   //--- 11. SAR Confirmation (±5)
   double sarScore = 0;
   maxPossible += 5;
   if(g_sarOK)
   {
      if(close0 > bufSAR[1]) sarScore = 5.0;
      else sarScore = -5.0;
   }
   sarScore *= g_componentWeights[10];
   g_signal.componentScores[10] = sarScore;
   rawScore += sarScore;

   //--- 12. S/R Breakout (±20)
   double srScore = CalcSRScore(close0, close1);
   maxPossible += 20;
   srScore *= g_componentWeights[11];
   g_signal.componentScores[11] = srScore;
   rawScore += srScore;

   //--- 13. DOM Imbalance (±15) — Section 7.1
   double domScore = 0;
   maxPossible += 15;
   if(g_domOK)
   {
      if(g_market.domImbalance > InpDOMImbalanceThresh) domScore = 15.0;
      else if(g_market.domImbalance < -InpDOMImbalanceThresh) domScore = -15.0;
   }
   domScore *= g_componentWeights[12];
   g_signal.componentScores[12] = domScore;
   rawScore += domScore;

   //--- 14. Tick Delta (±12) — Section 7.2
   double tdScore = 0;
   maxPossible += 12;
   if(g_tickBufCount > 10)
   {
      if(g_market.tickDeltaRatio > InpTickDeltaThresh) tdScore = 12.0;
      else if(g_market.tickDeltaRatio < (1.0 - InpTickDeltaThresh)) tdScore = -12.0;
   }
   tdScore *= g_componentWeights[13];
   g_signal.componentScores[13] = tdScore;
   rawScore += tdScore;

   //--- 15. Volume Spike (±10) — Section 7.3
   double volScore = 0;
   maxPossible += 10;
   if(g_market.volumeImbalance > InpVolSpikeThresh)
   {
      double open0 = iOpen(g_symbol, InpTF, 1);
      if(close0 > open0) volScore = 10.0;
      else if(close0 < open0) volScore = -10.0;
   }
   volScore *= g_componentWeights[14];
   g_signal.componentScores[14] = volScore;
   rawScore += volScore;

   //--- 16. Z-Score Mean Reversion (±12, INVERTED) — Section 8.1
   double zScore = 0;
   maxPossible += 12;
   if(g_market.zscore < -InpZScoreThreshold) zScore = 12.0;
   else if(g_market.zscore > InpZScoreThreshold) zScore = -12.0;
   zScore *= g_componentWeights[15];
   g_signal.componentScores[15] = zScore;
   rawScore += zScore;

   //--- 17. Hurst Regime Modifier (±8) — Section 8.2
   double hurstMod = 0;
   maxPossible += 8;
   if(g_market.hurstExponent > 0.55)
   {
      //--- Trending: boost EMA signals
      if(emaScore != 0) hurstMod = (emaScore > 0 ? 8.0 : -8.0);
   }
   else if(g_market.hurstExponent < 0.45)
   {
      //--- Mean-reverting: boost Z-Score/BB
      if(zScore != 0 || bbScore != 0) hurstMod = ((zScore + bbScore) > 0 ? 8.0 : -8.0);
   }
   hurstMod *= g_componentWeights[16];
   g_signal.componentScores[16] = hurstMod;
   rawScore += hurstMod;

   //--- 18. Linear Regression (±10) — Section 8.3
   double lrScore = 0;
   maxPossible += 10;
   if(g_market.regressionSlope > 5.0) lrScore = 10.0;
   else if(g_market.regressionSlope < -5.0) lrScore = -10.0;
   else if(rawScore > 0 && g_market.regressionSlope < -2.0) lrScore = -5.0;
   else if(rawScore < 0 && g_market.regressionSlope > 2.0) lrScore = 5.0;
   lrScore *= g_componentWeights[17];
   g_signal.componentScores[17] = lrScore;
   rawScore += lrScore;

   //--- 19. Candle Pattern Overlay (±10) — Section 19
   double candleScore = CalcCandlePatternScore();
   maxPossible += 10;
   candleScore *= g_componentWeights[18];
   g_signal.componentScores[18] = candleScore;
   rawScore += candleScore;

   //--- Hurst random walk penalty (Section 8.2)
   if(g_market.hurstExponent >= 0.45 && g_market.hurstExponent <= 0.55)
      rawScore *= 0.80;

   //--- Ichimoku optional modifier
   if(g_ichiOK)
   {
      if(bufIchiTenkan[2] < bufIchiKijun[2] && bufIchiTenkan[1] >= bufIchiKijun[1])
         rawScore += 8.0;
      else if(bufIchiTenkan[2] > bufIchiKijun[2] && bufIchiTenkan[1] <= bufIchiKijun[1])
         rawScore -= 8.0;
   }

   //--- Session weight multiplier (Section 17.2)
   rawScore *= g_market.sessionWeight;

   //--- Inside Bar compression suppression (Section 19.5)
   if(InpUseCandlePatterns)
   {
      double h0 = iHigh(g_symbol, InpTF, 1), h1 = iHigh(g_symbol, InpTF, 2);
      double l0 = iLow(g_symbol, InpTF, 1),  l1 = iLow(g_symbol, InpTF, 2);
      if(h0 < h1 && l0 > l1 && MathAbs(rawScore) / (maxPossible + EPSILON) * 100.0 < 80)
         rawScore *= 0.85;
   }

   //--- Normalise
   double scorePct = MathAbs(rawScore) / (maxPossible + EPSILON) * 100.0;
   scorePct = MathMin(100.0, scorePct);

   g_signal.direction   = (rawScore > 0) ? 1 : (rawScore < 0 ? -1 : 0);
   g_signal.score       = scorePct;
   g_signal.generatedAt = TimeCurrent();
   g_signal.reason      = BuildSignalReason();
}

//+------------------------------------------------------------------+
//| CalcSRScore — S/R Breakout scoring                                |
//+------------------------------------------------------------------+
double CalcSRScore(double close0, double close1)
{
   double score = 0;
   double buffer = g_market.atr * 0.3;
   for(int i = 0; i < g_srCount; i++)
   {
      double level = g_srLevels[i];
      if(close1 < level && close0 > level + buffer) { score = 20.0; break; }
      if(close1 > level && close0 < level - buffer) { score = -20.0; break; }
   }
   return MathMax(-20.0, MathMin(20.0, score));
}

//+------------------------------------------------------------------+
//| CalcCandlePatternScore — Section 19                               |
//+------------------------------------------------------------------+
double CalcCandlePatternScore()
{
   if(!InpUseCandlePatterns) return 0;

   double o0 = iOpen(g_symbol, InpTF, 1),  c0 = iClose(g_symbol, InpTF, 1);
   double h0 = iHigh(g_symbol, InpTF, 1),  l0 = iLow(g_symbol, InpTF, 1);
   double o1 = iOpen(g_symbol, InpTF, 2),  c1 = iClose(g_symbol, InpTF, 2);
   double h1 = iHigh(g_symbol, InpTF, 2),  l1 = iLow(g_symbol, InpTF, 2);

   double body0 = MathAbs(c0 - o0);
   double body1 = MathAbs(c1 - o1);
   double upperWick0 = h0 - MathMax(o0, c0);
   double lowerWick0 = MathMin(o0, c0) - l0;

   //--- Bullish Engulfing
   if(c0 > o0 && c1 < o1 && body0 >= body1 * InpEngulfingMinBody &&
      c0 > o1 && o0 < c1)
      return 10.0;

   //--- Bearish Engulfing
   if(c0 < o0 && c1 > o1 && body0 >= body1 * InpEngulfingMinBody &&
      c0 < o1 && o0 > c1)
      return -10.0;

   //--- Bullish Pin Bar (Hammer)
   if(body0 > EPSILON && lowerWick0 >= body0 * InpPinBarWickRatio && upperWick0 < body0)
      return 10.0;

   //--- Bearish Pin Bar (Shooting Star)
   if(body0 > EPSILON && upperWick0 >= body0 * InpPinBarWickRatio && lowerWick0 < body0)
      return -10.0;

   return 0;
}

//+------------------------------------------------------------------+
//| BuildSignalReason                                                 |
//+------------------------------------------------------------------+
string BuildSignalReason()
{
   string reason = "";
   for(int i = 0; i < g_numComponents; i++)
   {
      if(g_signal.componentScores[i] != 0)
      {
         if(reason != "") reason += ",";
         reason += g_componentNames[i];
      }
   }
   return reason;
}

//+------------------------------------------------------------------+
//| CalcCorrelation — Section 9.3                                     |
//+------------------------------------------------------------------+
double CalcCorrelation()
{
   if(!InpUseCorrelationSizing) return 0;
   string corrSym = InpCorrelationSymbol;
   if(!SymbolSelect(corrSym, true)) return 0;
   if(SymbolInfoDouble(corrSym, SYMBOL_BID) == 0) return 0;

   double x[], y[];
   int n = 20;
   if(CopyClose(g_symbol, InpTF, 0, n, x) < n) return 0;
   if(CopyClose(corrSym, InpTF, 0, n, y) < n) return 0;

   double sumX=0,sumY=0,sumXY=0,sumX2=0,sumY2=0;
   for(int i=0;i<n;i++)
   {
      sumX+=x[i]; sumY+=y[i]; sumXY+=x[i]*y[i];
      sumX2+=x[i]*x[i]; sumY2+=y[i]*y[i];
   }
   double denom=MathSqrt((n*sumX2-sumX*sumX)*(n*sumY2-sumY*sumY));
   if(denom<EPSILON) return 0;
   return (n*sumXY-sumX*sumY)/denom;
}

//+------------------------------------------------------------------+
//| CanTrade — Section 13 (13 Safety Guards)                          |
//+------------------------------------------------------------------+
bool CanTrade(int direction)
{
   double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);

   //--- 13.1 Spread
   double spreadPts = (ask - bid) / g_point;
   if(spreadPts > InpMaxSpreadPoints)
   { if(InpDebugMode) Print("CanTrade: BLOCKED — spread ", spreadPts, " > ", InpMaxSpreadPoints); return false; }

   //--- 13.2 ATR range
   double atrPts = g_market.atr / g_point;
   if(atrPts < InpMinATRPoints)
   { if(InpDebugMode) Print("CanTrade: BLOCKED — ATR ", atrPts, " < min ", InpMinATRPoints); return false; }
   if(atrPts > InpMaxATRPoints)
   { if(InpDebugMode) Print("CanTrade: BLOCKED — ATR ", atrPts, " > max ", InpMaxATRPoints); return false; }

   //--- 13.3 Session
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
   { if(InpDebugMode) Print("CanTrade: BLOCKED — outside session hours"); return false; }
   if(dt.day_of_week == 0 || dt.day_of_week == 6)
   { if(InpDebugMode) Print("CanTrade: BLOCKED — weekend"); return false; }
   bool dayAllowed = true;
   switch(dt.day_of_week)
   {
      case 1: dayAllowed = InpTradeMonday; break;
      case 2: dayAllowed = InpTradeTuesday; break;
      case 3: dayAllowed = InpTradeWednesday; break;
      case 4: dayAllowed = InpTradeThursday; break;
      case 5: dayAllowed = InpTradeFriday; break;
   }
   if(!dayAllowed)
   { if(InpDebugMode) Print("CanTrade: BLOCKED — day disabled"); return false; }

   //--- 13.4 Daily drawdown
   if(g_risk.dailyDrawdownPct >= InpMaxDailyDrawdown)
   { Print("CanTrade: BLOCKED — daily DD ", g_risk.dailyDrawdownPct, "% >= ", InpMaxDailyDrawdown, "%"); return false; }

   //--- 13.5 Total drawdown
   if(g_risk.totalDrawdownPct >= InpMaxTotalDrawdown)
   {
      Print("CanTrade: BLOCKED — total DD ", g_risk.totalDrawdownPct, "% — EMERGENCY CLOSE ALL");
      CloseAllPositions();
      g_risk.tradingHalted = true;
      g_risk.haltReason = "Max total drawdown exceeded";
      return false;
   }

   //--- 13.6 Consecutive losses
   if(g_risk.consecutiveLosses >= InpEmergencyLosses)
   {
      if(g_risk.haltUntil == 0 || TimeCurrent() < g_risk.haltUntil)
      {
         if(g_risk.haltUntil == 0) g_risk.haltUntil = TimeCurrent() + 3600;
         Print("CanTrade: BLOCKED — ", g_risk.consecutiveLosses, " consecutive losses, paused 1hr");
         return false;
      }
      else { g_risk.consecutiveLosses = 0; g_risk.haltUntil = 0; }
   }

   //--- 13.7 Free margin
   double marginReq = 0;
   if(!OrderCalcMargin(direction > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, g_symbol, InpMinLot, ask, marginReq))
      marginReq = 100;
   if(AccInfo.FreeMargin() < marginReq * 2.0)
   { Print("CanTrade: BLOCKED — insufficient free margin"); return false; }

   //--- 13.8 Trade allowed
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   { Print("CanTrade: BLOCKED — trading not allowed"); return false; }

   //--- 13.9 Cluster zone conflict (Section 18)
   if(InpPreventClustering && HasClusterConflict(direction))
   { if(InpDebugMode) Print("CanTrade: BLOCKED — cluster zone conflict"); return false; }

   //--- 13.10 News (placeholder)
   // if(InpNewsFilterEnabled) { /* placeholder */ }

   //--- 13.11 Extreme volatility
   if(g_market.volatilityRegime == VOL_EXTREME && InpPauseOnExtreme)
   { Print("CanTrade: BLOCKED — EXTREME volatility regime"); return false; }

   //--- 13.12 Expected value
   if(g_risk.expectancy < InpMinExpectedValue && g_perfBufCount >= 10)
   { if(InpDebugMode) Print("CanTrade: BLOCKED — EV ", g_risk.expectancy, " < ", InpMinExpectedValue); return false; }

   //--- 13.13 Halted
   if(g_risk.tradingHalted)
   { Print("CanTrade: BLOCKED — halted: ", g_risk.haltReason); return false; }

   return true;
}

//+------------------------------------------------------------------+
//| HasClusterConflict — Section 18                                   |
//+------------------------------------------------------------------+
bool HasClusterConflict(int direction)
{
   double entryPrice = (direction > 0) ?
      SymbolInfoDouble(g_symbol, SYMBOL_ASK) : SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double zoneDist = InpClusterZonePips * g_point * 10;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PosInfo.SelectByIndex(i)) continue;
      if(PosInfo.Symbol() != g_symbol || PosInfo.Magic() != InpMagicNumber) continue;

      double openP = PosInfo.PriceOpen();
      if(MathAbs(entryPrice - openP) < zoneDist)
      {
         int posDir = (PosInfo.PositionType() == POSITION_TYPE_BUY) ? 1 : -1;
         if(posDir == direction)
         { if(InpDebugMode) Print("Cluster: same-direction position within zone"); return true; }
         else
         { Print("Cluster: Opposing cluster detected — deferring."); return true; }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| CalculateLotSize — Section 9                                      |
//+------------------------------------------------------------------+
double CalculateLotSize(double slPoints)
{
   double lots = InpFixedLot;
   double equity = AccInfo.Equity();
   double pointVal = g_tickValue / (g_tickSize + EPSILON) * g_point;

   switch(InpRiskMode)
   {
      case RISK_FIXED:
         lots = InpFixedLot;
         break;
      case RISK_PERCENT:
         lots = (equity * InpRiskPercent / 100.0) / (slPoints * pointVal + EPSILON);
         break;
      case RISK_KELLY:
         if(g_perfBufCount >= 20 && g_risk.kellyFraction > 0)
            lots = g_risk.kellyFraction * InpKellyFraction * equity / (slPoints * pointVal + EPSILON);
         else
            lots = (equity * InpRiskPercent / 100.0) / (slPoints * pointVal + EPSILON);
         break;
      case RISK_DYNAMIC:
         if(g_perfBufCount < 20)
            lots = (equity * InpRiskPercent / 100.0) / (slPoints * pointVal + EPSILON);
         else
         {
            double lotPct = (equity * InpRiskPercent / 100.0) / (slPoints * pointVal + EPSILON);
            double lotKelly = g_risk.kellyFraction * InpKellyFraction * equity / (slPoints * pointVal + EPSILON);
            lots = lotPct * 0.6 + MathMax(0, lotKelly) * 0.4;
         }
         break;
   }

   //--- Volatility adjustment (Section 9.2)
   if(g_market.atrPips > 20) lots *= 0.75;
   else if(g_market.atrPips < 6) lots *= 1.15;
   lots *= g_risk.adaptiveRiskMult;

   //--- Regime adjustment (Section 16.2)
   if(g_market.volatilityRegime == VOL_CALM) lots *= 0.75;

   //--- Correlation sizing (Section 9.3)
   if(InpUseCorrelationSizing && g_signal.direction != 0)
   {
      double corr = CalcCorrelation();
      if(g_signal.direction > 0) // BUY
      {
         if(corr > 0.5) lots *= 0.8;
         else if(corr < -0.5) lots *= 1.1;
      }
      else // SELL (mirror)
      {
         if(corr < -0.5) lots *= 0.8;
         else if(corr > 0.5) lots *= 1.1;
      }
   }

   //--- Hard constraints (Section 9.4)
   lots = MathFloor(lots / g_lotStep) * g_lotStep;
   lots = NormalizeDouble(lots, 2);
   lots = MathMax(InpMinLot, MathMin(InpMaxLot, lots));
   if(lots > g_lotMax) lots = g_lotMax;
   if(lots < g_lotMin) lots = g_lotMin;

   //--- Free margin check
   double marginReq = 0;
   ENUM_ORDER_TYPE ot = (g_signal.direction > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(OrderCalcMargin(ot, g_symbol, lots, SymbolInfoDouble(g_symbol, SYMBOL_ASK), marginReq))
   {
      if(marginReq > AccInfo.FreeMargin() * 0.90)
         lots = MathFloor(AccInfo.FreeMargin() * 0.85 / (marginReq / lots + EPSILON) / g_lotStep) * g_lotStep;
   }

   lots = MathMax(g_lotMin, lots);
   return lots;
}

//+------------------------------------------------------------------+
//| CalculateSLTP — Section 10                                        |
//+------------------------------------------------------------------+
void CalculateSLTP(int direction, double &slDist, double &tpDist)
{
   if(InpUseATRSLTP)
   {
      slDist = g_market.atr * InpATRMultSL;
      tpDist = g_market.atr * InpATRMultTP;
   }
   else
   {
      slDist = InpFixedSL_Points * g_point;
      tpDist = InpFixedTP_Points * g_point;
   }

   //--- Snap SL to nearest S/R if closer (Section 10.1)
   double entryP = (direction > 0) ? SymbolInfoDouble(g_symbol, SYMBOL_ASK)
                                   : SymbolInfoDouble(g_symbol, SYMBOL_BID);
   for(int i = 0; i < g_srCount; i++)
   {
      double lvl = g_srLevels[i];
      double dist = 0;
      if(direction > 0 && lvl < entryP)
         dist = entryP - lvl + g_market.atr * 0.1;
      else if(direction < 0 && lvl > entryP)
         dist = lvl - entryP + g_market.atr * 0.1;

      if(dist > 0 && dist < slDist && dist > 30 * g_point)
         slDist = dist;
   }

   //--- Minimum SL (Section 10.1)
   if(slDist < 30 * g_point) slDist = 30 * g_point;

   //--- TP regime scaling (Section 10.2)
   if(g_market.volatilityRegime == VOL_HIGH || g_market.volatilityRegime == VOL_EXTREME)
      tpDist *= InpHighVolTPMult;
   if(g_market.hurstExponent > 0.55) tpDist *= 1.3;
   else if(g_market.hurstExponent < 0.45) tpDist *= 0.8;
   if(bufADXMain[1] > 30) tpDist *= 1.1;

   //--- Session multipliers (Section 17.3)
   tpDist *= g_market.sessionTPMult;
   slDist *= g_market.sessionSLMult;

   //--- Calm regime TP reduction
   if(g_market.volatilityRegime == VOL_CALM) tpDist *= 0.80;

   //--- HIGH regime SL widening
   if(g_market.volatilityRegime == VOL_HIGH) slDist *= 1.2;

   //--- Enforce min R:R (Section 10.2)
   if(InpUseDynamicRR && tpDist < InpMinRR * slDist)
      tpDist = InpMinRR * slDist;

   //--- Respect SYMBOL_TRADE_STOPS_LEVEL (Section 10.3)
   double minDist = g_stopsLevel * g_point;
   if(slDist < minDist) slDist = minDist;
   if(tpDist < minDist) tpDist = minDist;
}

//+------------------------------------------------------------------+
//| ExecuteTrade — Layer D (Execution)                                 |
//+------------------------------------------------------------------+
bool ExecuteTrade(int direction, double slDist, double tpDist, double lots)
{
   double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double entry = (direction > 0) ? ask : bid;
   double sl, tp;

   if(direction > 0)
   {
      sl = NormalizeDouble(entry - slDist, g_digits);
      tp = NormalizeDouble(entry + tpDist, g_digits);
   }
   else
   {
      sl = NormalizeDouble(entry + slDist, g_digits);
      tp = NormalizeDouble(entry - tpDist, g_digits);
   }

   ENUM_ORDER_TYPE ot = (direction > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   string comment = InpTradeComment + " S:" + DoubleToString(g_signal.score, 1);

   bool result = Trade.PositionOpen(g_symbol, ot, lots, entry, sl, tp, comment);

   //--- Error handling (Section 23.1)
   if(!result)
   {
      uint retcode = Trade.ResultRetcode();
      if(retcode == TRADE_RETCODE_REQUOTE || retcode == TRADE_RETCODE_PRICE_CHANGED)
      {
         Print("ExecuteTrade: Retcode ", retcode, " — retrying once");
         SymInfo.RefreshRates();
         entry = (direction > 0) ? SymInfo.Ask() : SymInfo.Bid();
         if(direction > 0) { sl = NormalizeDouble(entry - slDist, g_digits); tp = NormalizeDouble(entry + tpDist, g_digits); }
         else              { sl = NormalizeDouble(entry + slDist, g_digits); tp = NormalizeDouble(entry - tpDist, g_digits); }
         result = Trade.PositionOpen(g_symbol, ot, lots, entry, sl, tp, comment);
      }
      if(!result)
      {
         Print("ExecuteTrade: FAILED — retcode=", Trade.ResultRetcode(), " desc=", Trade.ResultRetcodeDescription());
         return false;
      }
   }

   g_signal.entryPrice = entry;
   g_signal.sl = sl;
   g_signal.tp = tp;

   Print("TRADE OPENED: ", (direction > 0 ? "BUY" : "SELL"),
         " lots=", DoubleToString(lots, 2),
         " entry=", DoubleToString(entry, g_digits),
         " SL=", DoubleToString(sl, g_digits),
         " TP=", DoubleToString(tp, g_digits),
         " score=", DoubleToString(g_signal.score, 1),
         " reason=", g_signal.reason);

   return true;
}

//+------------------------------------------------------------------+
//| ManagePositions — Section 11 (Every OnTick)                       |
//+------------------------------------------------------------------+
void ManagePositions()
{
   double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PosInfo.SelectByIndex(i)) continue;
      if(PosInfo.Symbol() != g_symbol || PosInfo.Magic() != InpMagicNumber) continue;

      ulong ticket = PosInfo.Ticket();
      double openP = PosInfo.PriceOpen();
      double curSL = PosInfo.StopLoss();
      double curTP = PosInfo.TakeProfit();
      double lots  = PosInfo.Volume();
      double profit = PosInfo.Profit();
      ENUM_POSITION_TYPE ptype = PosInfo.PositionType();
      int dir = (ptype == POSITION_TYPE_BUY) ? 1 : -1;

      double tpDist = MathAbs(curTP - openP);
      double profitDist = (dir > 0) ? (bid - openP) : (openP - ask);

      //--- Check if this position has flags (stored via comment parsing)
      string cmt = PosInfo.Comment();
      bool beMoved = (StringFind(cmt, "BE") >= 0);
      bool partialDone = (StringFind(cmt, "PT") >= 0);

      //--- 11.1 Partial Take Profit
      if(InpUsePartialTP && !partialDone && tpDist > 0)
      {
         if(profitDist >= InpPartialTPTrigger * tpDist)
         {
            double closeLots = NormalizeDouble(lots * InpPartialTPPercent / 100.0, 2);
            closeLots = MathFloor(closeLots / g_lotStep) * g_lotStep;
            if(closeLots >= g_lotMin && closeLots < lots)
            {
               if(Trade.PositionClosePartial(ticket, closeLots))
               {
                  Print("PARTIAL TP: ticket=", ticket, " closed=", closeLots);
                  //--- Move SL to breakeven
                  double newSL = NormalizeDouble(openP + InpBreakevenOffset * g_point * dir, g_digits);
                  Trade.PositionModify(ticket, newSL, curTP);
               }
            }
         }
      }

      //--- 11.3 Breakeven (before trailing so trail can further improve)
      if(InpUseBreakeven && !beMoved)
      {
         if(dir > 0 && bid > openP + InpBreakevenAt_Points * g_point)
         {
            double newSL = NormalizeDouble(openP + InpBreakevenOffset * g_point, g_digits);
            if(newSL > curSL)
            {
               Trade.PositionModify(ticket, newSL, curTP);
               if(InpDebugMode) Print("BREAKEVEN: ticket=", ticket);
            }
         }
         else if(dir < 0 && ask < openP - InpBreakevenAt_Points * g_point)
         {
            double newSL = NormalizeDouble(openP - InpBreakevenOffset * g_point, g_digits);
            if(newSL < curSL || curSL == 0)
            {
               Trade.PositionModify(ticket, newSL, curTP);
               if(InpDebugMode) Print("BREAKEVEN: ticket=", ticket);
            }
         }
      }

      //--- 11.2 Trailing Stop
      if(InpUseTrailingStop)
      {
         if(dir > 0)
         {
            if(bid >= openP + InpTrailStart_Points * g_point)
            {
               double newSL = NormalizeDouble(bid - InpTrailStart_Points * g_point, g_digits);
               if(newSL > curSL + InpTrailStep_Points * g_point)
                  Trade.PositionModify(ticket, newSL, curTP);
            }
         }
         else
         {
            if(ask <= openP - InpTrailStart_Points * g_point)
            {
               double newSL = NormalizeDouble(ask + InpTrailStart_Points * g_point, g_digits);
               if(newSL < curSL - InpTrailStep_Points * g_point || curSL == 0)
                  Trade.PositionModify(ticket, newSL, curTP);
            }
         }
      }

      //--- 11.4 Stale Trade Cleanup
      datetime openTime = PosInfo.Time();
      int durMins = (int)((TimeCurrent() - openTime) / 60);
      if(durMins > InpStaleTradeMaxMins)
      {
         //--- Adjust stale timeout per regime (Section 16.3)
         int staleLimit = InpStaleTradeMaxMins;
         if(g_market.volatilityRegime == VOL_CALM && g_market.hurstExponent > 0.55 && InpSwitchToHoldOnHigh)
            staleLimit = 120;
         if(g_market.volatilityRegime == VOL_HIGH && g_market.hurstExponent < 0.45)
            staleLimit = 20;

         if(durMins > staleLimit)
         {
            double avgWinRef = (g_risk.avgWin > 0) ? g_risk.avgWin : 50;
            if(MathAbs(profit) < 0.1 * avgWinRef)
            {
               Trade.PositionClose(ticket);
               Print("STALE CLOSE: ticket=", ticket, " duration=", durMins, "min profit=", profit);
            }
         }
      }
   }

   //--- 11.5 Emergency Full Close
   if(g_risk.totalDrawdownPct >= InpMaxTotalDrawdown)
   {
      Print("EMERGENCY: Total drawdown ", g_risk.totalDrawdownPct, "% — closing ALL");
      CloseAllPositions();
      g_risk.tradingHalted = true;
      g_risk.haltReason = "Max total drawdown exceeded";
   }

   //--- HIGH regime: close partials if floating profit (Section 16.2)
   if(g_market.volatilityRegime == VOL_EXTREME && InpPauseOnExtreme)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(!PosInfo.SelectByIndex(i)) continue;
         if(PosInfo.Symbol() != g_symbol || PosInfo.Magic() != InpMagicNumber) continue;
         if(PosInfo.Profit() > 0)
         {
            double closeLots = NormalizeDouble(PosInfo.Volume() * 0.5, 2);
            closeLots = MathFloor(closeLots / g_lotStep) * g_lotStep;
            if(closeLots >= g_lotMin)
               Trade.PositionClosePartial(PosInfo.Ticket(), closeLots);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| CloseAllPositions                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PosInfo.SelectByIndex(i)) continue;
      if(PosInfo.Symbol() != g_symbol || PosInfo.Magic() != InpMagicNumber) continue;
      Trade.PositionClose(PosInfo.Ticket());
   }
}

//+------------------------------------------------------------------+
//| UpdateRiskMetrics — Section 12                                    |
//+------------------------------------------------------------------+
void UpdateRiskMetrics()
{
   g_risk.balance = AccInfo.Balance();
   g_risk.equity  = AccInfo.Equity();

   //--- Daily reset
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.day != g_lastDay)
   {
      g_risk.dailyStartBalance = g_risk.balance;
      g_lastDay = dt.day;
      //--- Unhalte daily-halted
      if(g_risk.tradingHalted && g_risk.haltReason == "Daily drawdown exceeded")
      {
         g_risk.tradingHalted = false;
         g_risk.haltReason = "";
         Print("Daily reset — trading resumed");
      }
   }

   g_risk.dailyPnL = g_risk.equity - g_risk.dailyStartBalance;
   g_risk.dailyDrawdownPct = (-g_risk.dailyPnL) / (g_risk.dailyStartBalance + EPSILON) * 100.0;
   if(g_risk.dailyDrawdownPct < 0) g_risk.dailyDrawdownPct = 0;

   if(g_risk.equity > g_risk.peakEquity)
      g_risk.peakEquity = g_risk.equity;
   g_risk.totalDrawdownPct = (g_risk.peakEquity - g_risk.equity) / (g_risk.peakEquity + EPSILON) * 100.0;
   if(g_risk.totalDrawdownPct < 0) g_risk.totalDrawdownPct = 0;

   //--- Daily DD halt (Section 12.4)
   if(g_risk.dailyDrawdownPct >= InpMaxDailyDrawdown && !g_risk.tradingHalted)
   {
      g_risk.tradingHalted = true;
      g_risk.haltReason = "Daily drawdown exceeded";
      Print("HALT: Daily drawdown ", g_risk.dailyDrawdownPct, "% hit limit");
   }

   //--- Recalculate performance metrics from ring buffer
   if(g_perfBufCount > 0)
   {
      int wins = 0;
      double sumWin = 0, sumLoss = 0;
      int wCount = 0, lCount = 0;
      for(int i = 0; i < g_perfBufCount; i++)
      {
         if(g_perfBuf[i] > 0) { wins++; sumWin += g_perfBuf[i]; wCount++; }
         else { sumLoss += MathAbs(g_perfBuf[i]); lCount++; }
      }
      g_risk.winRate20 = (double)wins / g_perfBufCount;
      g_risk.avgWin  = (wCount > 0) ? sumWin / wCount : 0;
      g_risk.avgLoss = (lCount > 0) ? sumLoss / lCount : 0;

      double lossRate = 1.0 - g_risk.winRate20;
      g_risk.expectancy = g_risk.winRate20 * g_risk.avgWin - lossRate * g_risk.avgLoss;

      //--- Kelly (Section 8.4)
      double B = g_risk.avgWin / (g_risk.avgLoss + EPSILON);
      g_risk.kellyFraction = (g_risk.winRate20 * B - lossRate) / (B + EPSILON);
      g_risk.kellyFraction = MathMax(0, MathMin(0.25, g_risk.kellyFraction));
   }
}

//+------------------------------------------------------------------+
//| OnTradeClose — Self-correction update (Section 12)                |
//+------------------------------------------------------------------+
void OnTradeClose(double profitPips, double &componentScores[])
{
   //--- Store in perf ring buffer
   g_perfBuf[g_perfBufIdx] = profitPips;
   g_perfBufIdx = (g_perfBufIdx + 1) % PERF_BUFFER;
   if(g_perfBufCount < PERF_BUFFER) g_perfBufCount++;
   g_totalTrades++;

   //--- Consecutive tracking
   if(profitPips > 0) { g_risk.consecutiveWins++; g_risk.consecutiveLosses = 0; }
   else               { g_risk.consecutiveLosses++; g_risk.consecutiveWins = 0; }

   //--- Adaptive risk mult (Section 12.2)
   if(profitPips <= 0)
      g_risk.adaptiveRiskMult = MathMax(0.1, g_risk.adaptiveRiskMult * 0.92);
   else
      g_risk.adaptiveRiskMult = MathMin(2.0, g_risk.adaptiveRiskMult * 1.05);

   //--- Adaptive entry threshold (Section 12.3)
   if(g_perfBufCount >= 5)
   {
      int recentWins = 0;
      for(int i = 0; i < MathMin(5, g_perfBufCount); i++)
      {
         int idx = (g_perfBufIdx - 1 - i + PERF_BUFFER) % PERF_BUFFER;
         if(g_perfBuf[idx] > 0) recentWins++;
      }
      double wr5 = (double)recentWins / MathMin(5, g_perfBufCount);
      if(wr5 < 0.30)
         g_risk.adaptiveEntryThresh = MathMin(InpMinSignalScore + 25, g_risk.adaptiveEntryThresh + 5);
      else if(wr5 > 0.65)
         g_risk.adaptiveEntryThresh = MathMax(InpMinSignalScore - 10, g_risk.adaptiveEntryThresh - 3);
   }

   //--- Component weight self-optimisation (Section 12.5)
   for(int i = 0; i < g_numComponents; i++)
      g_componentNetPips[i] += componentScores[i] != 0 ? profitPips : 0;
   g_componentTradeCount++;

   if(g_componentTradeCount >= 20)
   {
      Print("=== COMPONENT WEIGHT UPDATE ===");
      for(int i = 0; i < g_numComponents; i++)
      {
         if(g_componentNetPips[i] < -5)
         {
            g_componentWeights[i] *= 0.5;
            Print("  ", g_componentNames[i], " weight HALVED → ", DoubleToString(g_componentWeights[i], 3));
         }
         else if(g_componentNetPips[i] > 5)
         {
            g_componentWeights[i] *= 1.2;
            Print("  ", g_componentNames[i], " weight +20% → ", DoubleToString(g_componentWeights[i], 3));
         }
         g_componentNetPips[i] = 0;
      }
      g_componentTradeCount = 0;
      Print("===============================");
   }
}

//+------------------------------------------------------------------+
//| CheckSpreadForEntry — Section 15 (Microstructure)                 |
//+------------------------------------------------------------------+
bool CheckSpreadForEntry()
{
   if(g_spreadBufCount < 10) return true; // Not enough data

   //--- Calculate mean spread
   double sumSpread = 0;
   for(int i = 0; i < g_spreadBufCount; i++)
      sumSpread += g_spreadBuf[i];
   double meanSpread = sumSpread / g_spreadBufCount;

   double currentSpread = SymbolInfoDouble(g_symbol, SYMBOL_ASK) - SymbolInfoDouble(g_symbol, SYMBOL_BID);

   //--- Spread expansion: defer (Section 15.1)
   if(currentSpread > meanSpread * 1.5)
      return false;

   //--- Check for chop delay (Section 15.3)
   if(g_chopDetected && TimeCurrent() < g_chopDelayUntil)
      return false;
   g_chopDetected = false;

   //--- Sub-tick precision: prefer median spread or better (Section 15.2)
   double sortedSpreads[];
   ArrayResize(sortedSpreads, g_spreadBufCount);
   for(int i = 0; i < g_spreadBufCount; i++)
      sortedSpreads[i] = g_spreadBuf[i];
   ArraySort(sortedSpreads);
   double medianSpread = sortedSpreads[g_spreadBufCount / 2];
   if(currentSpread > medianSpread * 1.2)
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| CheckM1EntryTrigger — Section 5.3                                 |
//+------------------------------------------------------------------+
bool CheckM1EntryTrigger(int direction)
{
   double m1High1 = iHigh(g_symbol, InpEntryTF, 1);
   double m1Low1  = iLow(g_symbol, InpEntryTF, 1);
   double m1High2 = iHigh(g_symbol, InpEntryTF, 2);
   double m1Low2  = iLow(g_symbol, InpEntryTF, 2);
   double m1Close = iClose(g_symbol, InpEntryTF, 1);

   if(CopyBuffer(h_m1EmaFast, 0, 0, 3, bufM1EmaFast) < 3) return false;
   if(CopyBuffer(h_m1EmaMid,  0, 0, 3, bufM1EmaMid)  < 3) return false;

   if(direction > 0)
   {
      //--- BUY: M1 closes above prior M1 high AND EMA8 > EMA21 on M1
      if(m1Close > m1High2 && bufM1EmaFast[1] > bufM1EmaMid[1])
         return true;
   }
   else
   {
      //--- SELL: M1 closes below prior M1 low AND EMA8 < EMA21 on M1
      if(m1Close < m1Low2 && bufM1EmaFast[1] < bufM1EmaMid[1])
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| OnTick — Section 22 (Main Loop)                                   |
//+------------------------------------------------------------------+
void OnTick()
{
   SymInfo.RefreshRates();
   double ask = SymInfo.Ask();
   double bid = SymInfo.Bid();
   if(ask == 0 || bid == 0) return;

   g_tickCount++;

   //--- Step 1: Refresh tick buffer, update microstructure (Section 15)
   UpdateTickBuffer();

   //--- Step 6: Position management every tick (Section 11)
   ManagePositions();

   //--- Update risk metrics
   UpdateRiskMetrics();

   //--- Step 2: Check new M5 bar
   datetime curM5Bar = iTime(g_symbol, InpTF, 0);
   bool newM5 = (curM5Bar != g_lastM5Bar && g_lastM5Bar != 0);
   if(g_lastM5Bar == 0) g_lastM5Bar = curM5Bar; // First run

   if(newM5)
   {
      g_lastM5Bar = curM5Bar;

      //--- Step 3: Refresh indicators, update state, run scoring
      if(!RefreshIndicators()) return;
      UpdateVolumeImbalance();
      UpdateSRLevels();
      UpdateMarketState();
      RunScoringEngine();

      //--- Check entry gate (Section 6.2)
      double threshold = g_risk.adaptiveEntryThresh;
      if(g_signal.score >= threshold && g_signal.direction != 0)
      {
         //--- HTF confirmation check (Section 5.1)
         bool htfOK = true;
         if(InpHTFConfirmRequired > 0)
         {
            if(g_signal.direction != g_market.trend)
            {
               if(g_market.trend == 0)
               {
                  //--- H1 is RANGE: allow if RSI extreme
                  if(bufRSI[1] < 25 || bufRSI[1] > 75)
                     htfOK = true;
                  else
                     htfOK = false;
               }
               else
                  htfOK = false; // True counter-trend, block
            }
         }

         if(htfOK)
         {
            //--- Arm M1 entry trigger (Section 5.3)
            g_entryArmed = true;
            g_armedDirection = g_signal.direction;
            g_armedScore = g_signal.score;
            g_armedAt = TimeCurrent();
            g_armedBarCount = 0;
            ArrayCopy(g_armedComponentScores, g_signal.componentScores);

            if(InpDebugMode)
               Print("ENTRY ARMED: dir=", g_armedDirection, " score=", DoubleToString(g_armedScore, 1));
         }
      }

      //--- Step 9: Self-correction refresh on new M5
      UpdateRiskMetrics();
   }

   //--- Step 4: Check new M1 bar
   datetime curM1Bar = iTime(g_symbol, InpEntryTF, 0);
   bool newM1 = (curM1Bar != g_lastM1Bar && g_lastM1Bar != 0);
   if(g_lastM1Bar == 0) g_lastM1Bar = curM1Bar;

   if(newM1)
   {
      g_lastM1Bar = curM1Bar;

      //--- Step 5: Check armed entry trigger
      if(g_entryArmed)
      {
         g_armedBarCount++;

         //--- Timeout: discard if > 5 M1 bars
         if(g_armedBarCount > 5)
         {
            g_entryArmed = false;
            if(InpDebugMode) Print("Entry trigger TIMEOUT — discarded");
         }
         else if(CheckM1EntryTrigger(g_armedDirection))
         {
            //--- Microstructure spread check (Section 15)
            if(CheckSpreadForEntry())
            {
               //--- Safety check (Section 13)
               if(CanTrade(g_armedDirection))
               {
                  //--- Calculate SL/TP (Section 10)
                  double slDist, tpDist;
                  CalculateSLTP(g_armedDirection, slDist, tpDist);

                  //--- Calculate lots (Section 9)
                  double slPoints = slDist / g_point;
                  double lots = CalculateLotSize(slPoints);

                  //--- Execute! (Section 22 / Layer D)
                  ExecuteTrade(g_armedDirection, slDist, tpDist, lots);
               }
            }
            g_entryArmed = false;
         }
      }
   }

   //--- Step 7: Dashboard update every 5th tick (Section 14)
   if(g_tickCount % 5 == 0 && !g_isTester)
      UpdateDashboard();

   //--- Step 8: Draw trade lines (Section 14.1)
   if(!g_isTester && InpShowTrades)
      DrawTradeLines();
}

//+------------------------------------------------------------------+
//| OnBookEvent — Section 7.1 (DOM Update)                            |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
{
   if(symbol != g_symbol || !g_domOK) return;

   MqlBookInfo book[];
   if(!MarketBookGet(g_symbol, book) || ArraySize(book) == 0)
      return;

   double totalBid = 0, totalAsk = 0;
   int levels = MathMin(InpDOMLevels, ArraySize(book));
   for(int i = 0; i < levels; i++)
   {
      if(book[i].type == BOOK_TYPE_BUY || book[i].type == BOOK_TYPE_BUY_MARKET)
         totalBid += book[i].volume_real;
      else if(book[i].type == BOOK_TYPE_SELL || book[i].type == BOOK_TYPE_SELL_MARKET)
         totalAsk += book[i].volume_real;
   }

   g_market.domImbalance = (totalBid - totalAsk) / (totalBid + totalAsk + 1.0);
}

//+------------------------------------------------------------------+
//| OnTradeTransaction — Section 22 (Close detection)                 |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   //--- Detect trade close (deal added for a position close)
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
      {
         //--- Check if this is a close deal for our EA
         ulong dealTicket = trans.deal;
         if(dealTicket == 0) return;

         if(HistoryDealSelect(dealTicket))
         {
            long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
            string sym = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
            long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

            if(magic == InpMagicNumber && sym == g_symbol && entry == DEAL_ENTRY_OUT)
            {
               double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
               double profitPips = profit / (g_tickValue + EPSILON); // Approximate

               OnTradeClose(profitPips, g_armedComponentScores);

               if(InpDebugMode)
                  Print("TRADE CLOSED: deal=", dealTicket, " profit=", profit, " pips≈", DoubleToString(profitPips, 1));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| OnTester — Section 20 (Custom Optimisation Objective)             |
//+------------------------------------------------------------------+
double OnTester()
{
   double pf     = TesterStatistics(STAT_PROFIT_FACTOR);
   double trades = TesterStatistics(STAT_TRADES);
   double ddPct  = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   double profit = TesterStatistics(STAT_PROFIT);
   double sharpe = TesterStatistics(STAT_SHARPE_RATIO);

   if(trades < InpMinTradesForScore) return 0.0;
   if(pf < 1.0)     return 0.0;
   if(ddPct > 25.0)  return 0.0;

   return (profit * pf * MathSqrt(trades) * (sharpe + 1.0)) / (ddPct + 1.0);
}

//+------------------------------------------------------------------+
//| UpdateDashboard — Section 14 (8 Panels)                           |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!InpShowDashboard) return;
   if(g_isTester) return;

   int x = InpDashX, y = InpDashY;
   int w = 280, rowH = 16, fs = InpDashFontSize;
   color txtCol = clrWhite;
   color valCol = clrCyan;

   //--- Background panel
   CreateRectLabel(OBJ_PREFIX + "BG", x - 2, y - 2, w + 4, rowH * 32 + 10, InpDashBgColor, InpDashBorderColor);

   int row = 0;

   //--- Panel 1: Header
   DashLabel("P1_Title", x + 4, y + row * rowH, EA_NAME + " v" + EA_VERSION, clrGold, fs + 1); row++;
   DashLabel("P1_Sym",   x + 4, y + row * rowH, "Symbol: " + g_symbol + "  TF: " + EnumToString(InpTF) + "  Magic: " + IntegerToString(InpMagicNumber), txtCol, fs); row++;
   row++; // spacer

   //--- Panel 2: Account
   DashLabel("P2_Hdr",  x + 4, y + row * rowH, "── ACCOUNT ──", clrDodgerBlue, fs); row++;
   DashLabel("P2_Bal",  x + 4, y + row * rowH, "Balance: " + DoubleToString(g_risk.balance, 2), txtCol, fs); row++;
   DashLabel("P2_Eq",   x + 4, y + row * rowH, "Equity:  " + DoubleToString(g_risk.equity, 2), txtCol, fs); row++;
   color pnlCol = (g_risk.dailyPnL >= 0) ? clrLime : clrRed;
   DashLabel("P2_PnL",  x + 4, y + row * rowH, "Daily P&L: " + DoubleToString(g_risk.dailyPnL, 2) + " (" + DoubleToString(g_risk.dailyDrawdownPct, 1) + "%)", pnlCol, fs); row++;
   color ddCol = (g_risk.totalDrawdownPct < 5) ? clrWhite : (g_risk.totalDrawdownPct < 10 ? clrYellow : clrRed);
   DashLabel("P2_DD",   x + 4, y + row * rowH, "Drawdown: " + DoubleToString(g_risk.totalDrawdownPct, 1) + "%", ddCol, fs); row++;
   DashLabel("P2_FM",   x + 4, y + row * rowH, "Free Margin: " + DoubleToString(AccInfo.FreeMargin(), 2), txtCol, fs); row++;
   row++;

   //--- Panel 3: Performance
   DashLabel("P3_Hdr",  x + 4, y + row * rowH, "── PERFORMANCE ──", clrDodgerBlue, fs); row++;
   DashLabel("P3_Trd",  x + 4, y + row * rowH, "Trades: " + IntegerToString(g_totalTrades) + "  Win%: " + DoubleToString(g_risk.winRate20 * 100, 1), txtCol, fs); row++;
   DashLabel("P3_EV",   x + 4, y + row * rowH, "EV: " + DoubleToString(g_risk.expectancy, 1) + " pips  CW/CL: " + IntegerToString(g_risk.consecutiveWins) + "/" + IntegerToString(g_risk.consecutiveLosses), txtCol, fs); row++;
   DashLabel("P3_Mult", x + 4, y + row * rowH, "Lot Mult: " + DoubleToString(g_risk.adaptiveRiskMult, 3) + "  Thresh: " + DoubleToString(g_risk.adaptiveEntryThresh, 0), valCol, fs); row++;
   row++;

   //--- Panel 4: Market
   DashLabel("P4_Hdr",  x + 4, y + row * rowH, "── MARKET ──", clrDodgerBlue, fs); row++;
   string regimeStr[] = {"CALM", "NORMAL", "HIGH", "EXTREME"};
   color regimeCol[] = {clrAqua, clrLime, clrOrange, clrRed};
   int ri = MathMax(0, MathMin(3, g_market.volatilityRegime));
   DashLabel("P4_ATR",  x + 4, y + row * rowH, "ATR: " + DoubleToString(g_market.atrPips, 1) + " pips  Regime: " + regimeStr[ri], regimeCol[ri], fs); row++;
   color spCol = (g_market.spreadPips < 3) ? clrLime : (g_market.spreadPips < 5 ? clrYellow : clrRed);
   DashLabel("P4_Spr",  x + 4, y + row * rowH, "Spread: " + DoubleToString(g_market.spreadPips, 1) + " pips", spCol, fs); row++;
   DashLabel("P4_HZ",   x + 4, y + row * rowH, "Hurst: " + DoubleToString(g_market.hurstExponent, 3) + "  Z: " + DoubleToString(g_market.zscore, 2), txtCol, fs); row++;
   string trendStr = (g_market.trend == 1) ? "UP" : (g_market.trend == -1 ? "DOWN" : "RANGE");
   string sessStr = g_market.sessionOverlap ? "Overlap" : (g_market.sessionLondon ? "London" : (g_market.sessionNewYork ? "NY" : (g_market.sessionAsian ? "Asian" : "Off")));
   DashLabel("P4_Trnd", x + 4, y + row * rowH, "H1: " + trendStr + "  Sess: " + sessStr + " (x" + DoubleToString(g_market.sessionWeight, 2) + ")", txtCol, fs); row++;
   row++;

   //--- Panel 5: Order Flow
   DashLabel("P5_Hdr",  x + 4, y + row * rowH, "── ORDER FLOW ──", clrDodgerBlue, fs); row++;
   DashLabel("P5_DOM",  x + 4, y + row * rowH, "DOM: " + (g_domOK ? DoubleToString(g_market.domImbalance, 3) : "N/A"), txtCol, fs); row++;
   DashLabel("P5_TD",   x + 4, y + row * rowH, "Tick Delta: " + DoubleToString(g_market.tickDeltaRatio * 100, 1) + "%  Vol: " + DoubleToString(g_market.volumeImbalance, 1) + "x", txtCol, fs); row++;
   row++;

   //--- Panel 6: Signal
   DashLabel("P6_Hdr",  x + 4, y + row * rowH, "── SIGNAL ──", clrDodgerBlue, fs); row++;
   string dirStr = (g_signal.direction == 1) ? "▲ BUY" : (g_signal.direction == -1 ? "▼ SELL" : "— NONE");
   color dirCol = (g_signal.direction == 1) ? clrLime : (g_signal.direction == -1 ? clrRed : clrGray);
   DashLabel("P6_Dir",  x + 4, y + row * rowH, dirStr + "  Score: " + DoubleToString(g_signal.score, 1) + "/100", dirCol, fs + 2); row++;
   //--- Score bar (Section 14.2)
   int barW = (int)(g_signal.score / 100.0 * (w - 20));
   color barCol = (g_signal.direction == 1) ? clrGreen : (g_signal.direction == -1 ? clrFireBrick : clrGray);
   CreateRectLabel(OBJ_PREFIX + "ScoreBar", x + 8, y + row * rowH, MathMax(1, barW), 10, barCol, barCol);
   CreateRectLabel(OBJ_PREFIX + "ScoreBg",  x + 8 + barW, y + row * rowH, MathMax(1, w - 20 - barW), 10, C'30,30,50', C'30,30,50');
   row++;
   row++;

   //--- Panel 7: Active Trade
   DashLabel("P7_Hdr",  x + 4, y + row * rowH, "── ACTIVE TRADE ──", clrDodgerBlue, fs); row++;
   bool hasPos = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PosInfo.SelectByIndex(i)) continue;
      if(PosInfo.Symbol() != g_symbol || PosInfo.Magic() != InpMagicNumber) continue;
      hasPos = true;
      string pDir = (PosInfo.PositionType() == POSITION_TYPE_BUY) ? "BUY" : "SELL";
      double pPnL = PosInfo.Profit();
      color pCol = (pPnL >= 0) ? clrLime : clrRed;
      int dur = (int)((TimeCurrent() - PosInfo.Time()) / 60);
      DashLabel("P7_Pos", x + 4, y + row * rowH,
         "#" + IntegerToString((long)PosInfo.Ticket()) + " " + pDir + " " +
         DoubleToString(PosInfo.Volume(), 2) + " @ " +
         DoubleToString(PosInfo.PriceOpen(), g_digits) + " P&L: " +
         DoubleToString(pPnL, 2), pCol, fs);
      row++;
      DashLabel("P7_Det", x + 4, y + row * rowH,
         "SL: " + DoubleToString(PosInfo.StopLoss(), g_digits) +
         " TP: " + DoubleToString(PosInfo.TakeProfit(), g_digits) +
         " Dur: " + IntegerToString(dur) + "m", txtCol, fs);
      row++;
      break; // Show only latest
   }
   if(!hasPos)
   {
      DashLabel("P7_Pos", x + 4, y + row * rowH, "No active positions", clrGray, fs); row++;
      DashLabel("P7_Det", x + 4, y + row * rowH, "", txtCol, fs); row++;
   }
   row++;

   //--- Panel 8: Status
   DashLabel("P8_Hdr",  x + 4, y + row * rowH, "── STATUS ──", clrDodgerBlue, fs); row++;
   string statusStr = g_risk.tradingHalted ? "HALTED" : (g_entryArmed ? "ARMED" : "ACTIVE");
   color statusCol = g_risk.tradingHalted ? clrRed : (g_entryArmed ? clrYellow : clrLime);
   DashLabel("P8_Stat", x + 4, y + row * rowH, statusStr + (g_risk.tradingHalted ? (" — " + g_risk.haltReason) : ""), statusCol, fs); row++;
   DashLabel("P8_Time", x + 4, y + row * rowH, "Server: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS), clrSilver, fs);
}

//+------------------------------------------------------------------+
//| Helper: Create/update rectangle label                             |
//+------------------------------------------------------------------+
void CreateRectLabel(string name, int x, int y, int w, int h, color bgCol, color borderCol)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, InpDashboardCorner);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgCol);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderCol);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Helper: Create/update text label                                  |
//+------------------------------------------------------------------+
void DashLabel(string suffix, int x, int y, string text, color col, int fontSize)
{
   string name = OBJ_PREFIX + suffix;
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, InpDashboardCorner);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name,  OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
}

//+------------------------------------------------------------------+
//| DrawTradeLines — Section 14.1                                     |
//+------------------------------------------------------------------+
void DrawTradeLines()
{
   //--- First remove old lines for positions that no longer exist
   string prefix = OBJ_PREFIX + "TL_";
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string objName = ObjectName(0, i);
      if(StringFind(objName, prefix) == 0)
      {
         //--- Extract ticket from name
         string tickStr = StringSubstr(objName, StringLen(prefix));
         int undIdx = StringFind(tickStr, "_");
         if(undIdx > 0) tickStr = StringSubstr(tickStr, 0, undIdx);
         long tick = StringToInteger(tickStr);
         bool found = false;
         for(int j = PositionsTotal() - 1; j >= 0; j--)
         {
            if(PosInfo.SelectByIndex(j) && PosInfo.Ticket() == (ulong)tick &&
               PosInfo.Symbol() == g_symbol && PosInfo.Magic() == InpMagicNumber)
            { found = true; break; }
         }
         if(!found) ObjectDelete(0, objName);
      }
   }

   //--- Draw lines for each open position
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PosInfo.SelectByIndex(i)) continue;
      if(PosInfo.Symbol() != g_symbol || PosInfo.Magic() != InpMagicNumber) continue;

      ulong ticket = PosInfo.Ticket();
      string tStr = IntegerToString((long)ticket);
      double openP = PosInfo.PriceOpen();
      double sl = PosInfo.StopLoss();
      double tp = PosInfo.TakeProfit();
      bool isBuy = (PosInfo.PositionType() == POSITION_TYPE_BUY);
      double pnl = PosInfo.Profit();

      //--- Entry line (dashed, blue=BUY, red=SELL)
      DrawHLine(prefix + tStr + "_Entry", openP, isBuy ? clrDodgerBlue : clrCrimson, STYLE_DASH);

      //--- SL line (dotted red)
      if(sl > 0) DrawHLine(prefix + tStr + "_SL", sl, clrRed, STYLE_DOT);

      //--- TP line (dotted green)
      if(tp > 0) DrawHLine(prefix + tStr + "_TP", tp, clrLimeGreen, STYLE_DOT);

      //--- Partial TP line (dotted orange)
      if(tp > 0 && InpUsePartialTP)
      {
         double partialLevel;
         if(isBuy) partialLevel = openP + (tp - openP) * InpPartialTPTrigger;
         else      partialLevel = openP - (openP - tp) * InpPartialTPTrigger;
         DrawHLine(prefix + tStr + "_PT", partialLevel, clrOrange, STYLE_DOT);
      }

      //--- Text label
      string labelText = "#" + tStr + " " + (isBuy ? "BUY" : "SELL") +
                          " | " + DoubleToString(PosInfo.Volume(), 2) +
                          " | " + DoubleToString(pnl, 2);
      string lblName = prefix + tStr + "_Lbl";
      if(ObjectFind(0, lblName) < 0)
         ObjectCreate(0, lblName, OBJ_TEXT, 0, TimeCurrent(), openP);
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, pnl >= 0 ? clrLime : clrRed);
      ObjectSetString(0, lblName, OBJPROP_TEXT, labelText);
      ObjectSetString(0, lblName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
      ObjectSetDouble(0, lblName, OBJPROP_PRICE, openP);
      ObjectSetInteger(0, lblName, OBJPROP_TIME, TimeCurrent());
   }
}

//+------------------------------------------------------------------+
//| Helper: Draw horizontal line                                      |
//+------------------------------------------------------------------+
void DrawHLine(string name, double price, color col, ENUM_LINE_STYLE style)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
}
//+------------------------------------------------------------------+
