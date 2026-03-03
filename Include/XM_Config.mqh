//+------------------------------------------------------------------+
//|                                                    XM_Config.mqh |
//|                        Advanced XAUUSD Scalper Configuration     |
//|                              Copyright 2024-2026, XM_XAUUSD Bot  |
//+------------------------------------------------------------------+
#property copyright "XM_XAUUSD Bot"
#property link      "https://github.com/Pusparaj99op/XM_XAUUSD"
#property version   "1.00"
#property strict

#ifndef XM_CONFIG_MQH
#define XM_CONFIG_MQH

//+------------------------------------------------------------------+
//| BROKER & SYMBOL SETTINGS                                          |
//+------------------------------------------------------------------+
input group "═══════════════ BROKER SETTINGS ═══════════════"
input string   InpSymbol              = "Gold.i#";        // Symbol (XM Gold)
input ENUM_TIMEFRAMES InpTimeframe    = PERIOD_M5;        // Timeframe
input double   InpLeverage            = 1000.0;           // Leverage (1000:1)
input double   InpStartingBalance     = 1000.0;           // Starting Balance ($)
input int      InpMaxSpread           = 70;               // Max Spread (points) - Gold typically 20-40

//+------------------------------------------------------------------+
//| RISK MANAGEMENT SETTINGS                                          |
//+------------------------------------------------------------------+
input group "═══════════════ RISK MANAGEMENT ═══════════════"
input double   InpRiskPercent         = 3.0;              // Risk Per Trade (%)
input double   InpMaxRiskPercent      = 5.0;              // Maximum Risk Per Trade (%)
input double   InpDailyDrawdownLimit  = 5.0;              // Daily Drawdown Limit (%)
input double   InpWeeklyDrawdownLimit = 10.0;             // Weekly Drawdown Limit (%)
input double   InpMaxMarginUsage      = 30.0;             // Max Margin Usage (%)
input int      InpMaxOpenTrades       = 5;                // Max Simultaneous Trades
input double   InpMinLotSize          = 0.01;             // Minimum Lot Size
input double   InpMaxLotSize          = 10.0;             // Maximum Lot Size

//+------------------------------------------------------------------+
//| STOP LOSS & TAKE PROFIT SETTINGS                                  |
//+------------------------------------------------------------------+
input group "═══════════════ SL/TP SETTINGS ═══════════════"
input double   InpSLMultiplier        = 1.5;              // SL ATR Multiplier
input double   InpTPMultiplier        = 2.5;              // TP ATR Multiplier (Risk:Reward)
input double   InpMinSLPips           = 30.0;             // Minimum SL (pips)
input double   InpMaxSLPips           = 150.0;            // Maximum SL (pips)
input double   InpMinTPPips           = 45.0;             // Minimum TP (pips)
input double   InpMaxTPPips           = 300.0;            // Maximum TP (pips)
input bool     InpUseTrailingStop     = true;             // Use Trailing Stop
input double   InpTrailingStartPips   = 30.0;             // Trailing Start (pips profit)
input double   InpTrailingStepPips    = 15.0;             // Trailing Step (pips)
input bool     InpUseBreakeven        = true;             // Use Breakeven
input double   InpBreakevenPips       = 25.0;             // Breakeven Trigger (pips)
input double   InpBreakevenPlusPips   = 5.0;              // Breakeven + (pips)

//+------------------------------------------------------------------+
//| INDICATOR SETTINGS - RSI                                          |
//+------------------------------------------------------------------+
input group "═══════════════ RSI SETTINGS ═══════════════"
input int      InpRSIPeriod           = 14;               // RSI Period
input int      InpRSIOverbought       = 60;               // RSI Overbought Level
input int      InpRSIOversold         = 40;               // RSI Oversold Level
input int      InpRSIExtremeOB        = 80;               // RSI Extreme Overbought
input int      InpRSIExtremeOS        = 20;               // RSI Extreme Oversold
input ENUM_APPLIED_PRICE InpRSIPrice  = PRICE_CLOSE;      // RSI Applied Price

//+------------------------------------------------------------------+
//| INDICATOR SETTINGS - BOLLINGER BANDS                              |
//+------------------------------------------------------------------+
input group "═══════════════ BOLLINGER BANDS ═══════════════"
input int      InpBBPeriod            = 20;               // BB Period
input double   InpBBDeviation         = 2.0;              // BB Deviation
input ENUM_APPLIED_PRICE InpBBPrice   = PRICE_CLOSE;      // BB Applied Price

//+------------------------------------------------------------------+
//| INDICATOR SETTINGS - MACD                                         |
//+------------------------------------------------------------------+
input group "═══════════════ MACD SETTINGS ═══════════════"
input int      InpMACDFastEMA         = 12;               // MACD Fast EMA
input int      InpMACDSlowEMA         = 26;               // MACD Slow EMA
input int      InpMACDSignalSMA       = 9;                // MACD Signal SMA
input ENUM_APPLIED_PRICE InpMACDPrice = PRICE_CLOSE;      // MACD Applied Price

//+------------------------------------------------------------------+
//| INDICATOR SETTINGS - ATR                                          |
//+------------------------------------------------------------------+
input group "═══════════════ ATR SETTINGS ═══════════════"
input int      InpATRPeriod           = 14;               // ATR Period
input double   InpATRVolatilityHigh   = 2.0;              // ATR High Volatility Multiplier
input double   InpATRVolatilityLow    = 0.5;              // ATR Low Volatility Multiplier

//+------------------------------------------------------------------+
//| INDICATOR SETTINGS - MOVING AVERAGES                              |
//+------------------------------------------------------------------+
input group "═══════════════ MA SETTINGS ═══════════════"
input int      InpMAFastPeriod        = 10;               // Fast MA Period
input int      InpMASlowPeriod        = 50;               // Slow MA Period
input int      InpMATrendPeriod       = 200;              // Trend MA Period
input ENUM_MA_METHOD InpMAMethod      = MODE_EMA;         // MA Method
input ENUM_APPLIED_PRICE InpMAPrice   = PRICE_CLOSE;      // MA Applied Price

//+------------------------------------------------------------------+
//| INDICATOR SETTINGS - STOCHASTIC                                   |
//+------------------------------------------------------------------+
input group "═══════════════ STOCHASTIC SETTINGS ═══════════════"
input int      InpStochKPeriod        = 14;               // Stochastic K Period
input int      InpStochDPeriod        = 3;                // Stochastic D Period
input int      InpStochSlowing        = 3;                // Stochastic Slowing
input int      InpStochOverbought     = 70;               // Stochastic Overbought
input int      InpStochOversold       = 30;               // Stochastic Oversold

//+------------------------------------------------------------------+
//| PRICE ACTION SETTINGS                                             |
//+------------------------------------------------------------------+
input group "═══════════════ PRICE ACTION ═══════════════"
input int      InpSRLookback          = 50;               // S/R Lookback Bars
input double   InpSRZoneSize          = 80.0;             // S/R Zone Size (pips)
input int      InpSRMinTouches        = 1;                // Min Touches for Valid S/R
input int      InpOrderBlockLookback  = 20;               // Order Block Lookback
input double   InpOrderBlockMinSize   = 30.0;             // Order Block Min Size (pips)

//+------------------------------------------------------------------+
//| ENSEMBLE STRATEGY SETTINGS                                        |
//+------------------------------------------------------------------+
input group "═══════════════ ENSEMBLE STRATEGY ═══════════════"
input int      InpMinSignalsRequired  = 1;                // Min Signals Required (1-4)
input bool     InpUseIndicatorSignal  = true;             // Use Indicator Confluence Signal
input bool     InpUsePriceAction      = true;             // Use Price Action Signal
input bool     InpUseVolatilityBreak  = true;             // Use Volatility Breakout Signal
input bool     InpUseTrendFilter      = false;            // Use H1 Trend Filter
input bool     InpVolBreakMedium      = true;             // Allow Volatility Breakout in Medium Vol
input double   InpIndicatorWeight     = 1.0;              // Indicator Signal Weight
input double   InpPriceActionWeight   = 1.2;              // Price Action Signal Weight
input double   InpVolatilityWeight    = 0.8;              // Volatility Signal Weight

//+------------------------------------------------------------------+
//| SELF-CORRECTION SETTINGS                                          |
//+------------------------------------------------------------------+
input group "═══════════════ SELF-CORRECTION ═══════════════"
input bool     InpUseSelfCorrection   = true;             // Enable Self-Correction
input int      InpLookbackTrades      = 10;               // Lookback Trades for Analysis
input int      InpConsecLossReduce    = 3;                // Consecutive Losses to Reduce Size
input double   InpLossReductionFactor = 0.5;              // Loss Reduction Factor (0.5 = 50%)
input int      InpConsecWinIncrease   = 3;                // Consecutive Wins to Increase Size
input double   InpWinIncreaseFactor   = 1.2;              // Win Increase Factor (1.2 = 120%)
input double   InpMaxSizeMultiplier   = 1.5;              // Max Size Multiplier Cap
input double   InpMinSizeMultiplier   = 0.3;              // Min Size Multiplier Floor

//+------------------------------------------------------------------+
//| TRADING HOURS SETTINGS                                            |
//+------------------------------------------------------------------+
input group "═══════════════ TRADING HOURS ═══════════════"
input bool     InpUseTradingHours     = true;             // Enable Trading Hours Filter
input int      InpTradingStartHour    = 2;                // Trading Start Hour (Server Time)
input int      InpTradingEndHour      = 22;               // Trading End Hour (Server Time)
input bool     InpTradeMonday         = true;             // Trade on Monday
input bool     InpTradeTuesday        = true;             // Trade on Tuesday
input bool     InpTradeWednesday      = true;             // Trade on Wednesday
input bool     InpTradeThursday       = true;             // Trade on Thursday
input bool     InpTradeFriday         = true;             // Trade on Friday (careful near close)
input int      InpFridayCloseHour     = 20;               // Friday Close Hour (stop trading)

//+------------------------------------------------------------------+
//| NEWS FILTER SETTINGS                                              |
//+------------------------------------------------------------------+
input group "═══════════════ NEWS FILTER ═══════════════"
input bool     InpUseNewsFilter       = true;             // Enable News Filter
input int      InpNewsMinutesBefore   = 15;               // Pause Minutes Before News
input int      InpNewsMinutesAfter    = 15;               // Pause Minutes After News
input string   InpNewsAPIEndpoint     = "";               // News API Endpoint (optional)
input bool     InpFilterHighImpact    = true;             // Filter High Impact News
input bool     InpFilterMediumImpact  = false;            // Filter Medium Impact News

//+------------------------------------------------------------------+
//| TELEGRAM SETTINGS                                                 |
//+------------------------------------------------------------------+
input group "═══════════════ TELEGRAM ═══════════════"
input bool     InpUseTelegram         = false;            // Enable Telegram Notifications
input string   InpTelegramBotToken    = "";               // Telegram Bot Token
input string   InpTelegramChatID      = "";               // Telegram Chat ID
input bool     InpTelegramTradeAlerts = true;             // Trade Open/Close Alerts
input bool     InpTelegramDailySummary= true;             // Daily Summary
input bool     InpTelegramDrawdownAlert=true;             // Drawdown Alerts

//+------------------------------------------------------------------+
//| JSON EXPORT SETTINGS                                              |
//+------------------------------------------------------------------+
input group "═══════════════ JSON EXPORT ═══════════════"
input bool     InpEnableJsonExport    = true;             // Enable JSON Export
input int      InpJsonUpdateSeconds   = 5;                // JSON Update Interval (seconds)
input string   InpJsonFilename        = "xauusd_live.json";// JSON Filename

//+------------------------------------------------------------------+
//| DEBUG & LOGGING                                                   |
//+------------------------------------------------------------------+
input group "═══════════════ DEBUG ═══════════════"
input bool     InpDebugMode           = false;            // Enable Debug Mode
input bool     InpLogToFile           = true;             // Log Trades to File
input bool     InpShowDashboard       = true;             // Show On-Chart Dashboard

//+------------------------------------------------------------------+
//| CHART DRAWING SETTINGS                                            |
//+------------------------------------------------------------------+
input group "═══════════════ CHART DRAWING ═══════════════"
input bool     InpDrawTradeArrows     = true;             // Draw Buy/Sell Arrows on Chart
input bool     InpDrawSLTPLines       = true;             // Draw SL/TP Horizontal Lines
input bool     InpDrawSRLevels        = true;             // Draw Support/Resistance Levels
input bool     InpDrawOrderBlocks     = true;             // Draw Order Block Zones
input bool     InpDrawSwingPoints     = true;             // Draw Swing High/Low Markers
input bool     InpChartInfoPanel      = true;             // Show Trade Info Panel on Chart

//+------------------------------------------------------------------+
//| MAGIC NUMBER                                                      |
//+------------------------------------------------------------------+
input group "═══════════════ IDENTIFICATION ═══════════════"
input int      InpMagicNumber         = 2026021301;       // Magic Number (unique EA ID)
input string   InpEAComment           = "XM_XAUUSD_v1";   // Trade Comment

//+------------------------------------------------------------------+
//| GLOBAL CONSTANTS                                                  |
//+------------------------------------------------------------------+
#define EA_NAME           "XM XAUUSD Advanced Scalper"
#define EA_VERSION        "1.00"
#define EA_COPYRIGHT      "2024-2026"
#define POINT_FACTOR      10                              // For 5-digit brokers

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                      |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE
{
   SIGNAL_NONE = 0,           // No signal
   SIGNAL_BUY = 1,            // Buy signal
   SIGNAL_SELL = -1           // Sell signal
};

enum ENUM_TREND_TYPE
{
   TREND_NONE = 0,            // No clear trend
   TREND_UP = 1,              // Uptrend
   TREND_DOWN = -1            // Downtrend
};

enum ENUM_VOLATILITY_STATE
{
   VOL_LOW = 0,               // Low volatility
   VOL_NORMAL = 1,            // Normal volatility
   VOL_HIGH = 2               // High volatility
};

enum ENUM_MARKET_SESSION
{
   SESSION_ASIAN = 0,         // Asian session
   SESSION_LONDON = 1,        // London session
   SESSION_NEWYORK = 2,       // New York session
   SESSION_OVERLAP = 3        // London-NY overlap
};

//+------------------------------------------------------------------+
//| STRUCTURES                                                        |
//+------------------------------------------------------------------+
struct TradeSignal
{
   ENUM_SIGNAL_TYPE  direction;
   double            strength;           // 0.0 to 1.0
   double            entryPrice;
   double            stopLoss;
   double            takeProfit;
   string            reason;
   datetime          signalTime;
   int               signalCount;        // Number of confirming signals
};

struct MarketState
{
   double            currentPrice;
   double            bid;
   double            ask;
   double            spread;
   double            atr;
   double            rsi;
   double            bbUpper;
   double            bbMiddle;
   double            bbLower;
   double            macdMain;
   double            macdSignal;
   double            macdHistogram;
   double            maFast;
   double            maSlow;
   double            maTrend;
   double            stochK;
   double            stochD;
   ENUM_TREND_TYPE   trend;
   ENUM_VOLATILITY_STATE volatility;
   ENUM_MARKET_SESSION session;
};

struct RiskMetrics
{
   double            accountBalance;
   double            accountEquity;
   double            accountMargin;
   double            freeMargin;
   double            dailyPnL;
   double            weeklyPnL;
   double            dailyDrawdown;
   double            weeklyDrawdown;
   double            maxDrawdown;
   int               totalTrades;
   int               winningTrades;
   int               losingTrades;
   double            winRate;
   int               consecutiveWins;
   int               consecutiveLosses;
   double            currentLotMultiplier;
   bool              tradingEnabled;
   string            pauseReason;
};

struct SupportResistance
{
   double            level;
   int               touches;
   bool              isSupport;
   datetime          lastTouch;
   double            strength;
};

struct OrderBlock
{
   double            high;
   double            low;
   bool              isBullish;
   datetime          time;
   bool              isValid;
};

#endif // XM_CONFIG_MQH
//+------------------------------------------------------------------+
