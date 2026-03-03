//+------------------------------------------------------------------+
//|                                                   GA_Config.mqh  |
//|                   GoldAlgo Elite - Configuration & Data Structures|
//|                          Advanced XAUUSD M5 Scalper               |
//+------------------------------------------------------------------+
#property copyright "GoldAlgo Elite"
#property link      ""
#property version   "1.00"
#property strict

#ifndef __GA_CONFIG_MQH__
#define __GA_CONFIG_MQH__

//+------------------------------------------------------------------+
//| Enumerations                                                      |
//+------------------------------------------------------------------+
enum ENUM_MARKET_REGIME
  {
   REGIME_TRENDING_UP   = 0,   // Strong Uptrend
   REGIME_TRENDING_DOWN = 1,   // Strong Downtrend
   REGIME_RANGING       = 2,   // Range-Bound
   REGIME_VOLATILE      = 3,   // High Volatility
   REGIME_UNKNOWN       = 4    // Indeterminate
  };

enum ENUM_SIGNAL_DIR
  {
   SIGNAL_NONE = 0,
   SIGNAL_BUY  = 1,
   SIGNAL_SELL = -1
  };

//+------------------------------------------------------------------+
//| Input Parameters - Symbol                                         |
//+------------------------------------------------------------------+
input group "=== Symbol Settings ==="
input string   InpSymbol           = "Gold.i#";     // Symbol Name (XM default)
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M5;      // Timeframe

//+------------------------------------------------------------------+
//| Input Parameters - Session                                        |
//+------------------------------------------------------------------+
input group "=== Session Settings ==="
input int      InpStartHour        = 8;              // Trading Start Hour (server time)
input int      InpEndHour           = 16;             // Trading End Hour (server time)
input bool     InpTradeMonday       = true;           // Trade on Monday
input bool     InpTradeTuesday      = true;           // Trade on Tuesday
input bool     InpTradeWednesday    = true;           // Trade on Wednesday
input bool     InpTradeThursday     = true;           // Trade on Thursday
input bool     InpTradeFriday       = true;           // Trade on Friday

//+------------------------------------------------------------------+
//| Input Parameters - Risk Management                                |
//+------------------------------------------------------------------+
input group "=== Risk Management ==="
input double   InpRiskPercent       = 0.8;            // Risk Per Trade (% of equity)
input double   InpMaxDailyLoss      = 3.5;            // Max Daily Loss (% of balance)
input double   InpMaxDrawdown       = 8.0;            // Max Drawdown (% from peak equity)
input int      InpMaxOpenPositions  = 1;              // Max Simultaneous Open Positions
input int      InpMaxDailyTrades    = 6;              // Max Trades Per Day
input int      InpMaxSpread         = 40;             // Max Allowed Spread (points)
input double   InpKellyFraction     = 0.25;           // Kelly Fraction (0.25 = quarter-Kelly)

//+------------------------------------------------------------------+
//| Input Parameters - Signal Thresholds                              |
//+------------------------------------------------------------------+
input group "=== Signal Thresholds ==="
input double   InpMinBuyScore       = 9.0;            // Min Buy Signal Score
input double   InpMinSellScore      = 9.0;            // Min Sell Signal Score
input double   InpMinRR             = 1.7;            // Minimum Reward:Risk Ratio
input double   InpMinScoreEdge      = 1.2;            // Min score gap between dominant/opposite side
input double   InpVolatileScoreEdge = 2.0;            // Min score gap in volatile regime
input double   InpMinRegimeConf     = 0.40;           // Min regime confidence to allow trades

//+------------------------------------------------------------------+
//| Input Parameters - SL/TP Configuration                            |
//+------------------------------------------------------------------+
input group "=== SL/TP Settings ==="
input double   InpSLMultiplier      = 1.6;            // SL = ATR x Multiplier
input double   InpTPMultiplier      = 2.8;            // TP = ATR x Multiplier
input double   InpTrailMultiplier   = 1.8;            // Trailing Stop = ATR x Multiplier
input double   InpBEMultiplier      = 2.2;            // Break-Even Trigger = ATR x Multiplier
input double   InpPartialMultiplier = 2.8;            // Partial Close Trigger = ATR x Multiplier
input double   InpPartialPercent    = 25.0;           // Partial Close Volume (%)
input int      InpMinSLPoints       = 50;             // Minimum SL (points)
input int      InpMaxSLPoints       = 3000;           // Maximum SL (points)

//+------------------------------------------------------------------+
//| Input Parameters - Self-Correction / Adaptation                   |
//+------------------------------------------------------------------+
input group "=== Adaptation Settings ==="
input int      InpLookbackTrades    = 30;             // Lookback Trades for Adaptation
input int      InpMaxConsecLoss     = 2;              // Consecutive Losses Before Cooldown
input int      InpCooldownMinutes   = 240;            // Cooldown Duration (minutes)
input double   InpWinRateBoost      = 58.0;           // Win Rate % to Boost Sizing
input double   InpWinRateReduce     = 47.0;           // Win Rate % to Reduce Sizing

//+------------------------------------------------------------------+
//| Input Parameters - Trade Control                                  |
//+------------------------------------------------------------------+
input group "=== Trade Control ==="
input int      InpCooldownBars      = 8;              // Bars Between Entries (8 = 40min on M5)
input int      InpMinHoldSeconds    = 600;            // Min Hold Before BE/Trail (seconds)

//+------------------------------------------------------------------+
//| Input Parameters - Indicator Periods                              |
//+------------------------------------------------------------------+
input group "=== Indicator Settings ==="
input int      InpEMA_Fast          = 8;              // EMA Fast Period
input int      InpEMA_Mid           = 21;             // EMA Mid Period
input int      InpEMA_Slow          = 55;             // EMA Slow Period
input int      InpEMA_Trend         = 200;            // EMA Trend Period
input int      InpRSI_Period        = 14;             // RSI Period
input int      InpBB_Period         = 20;             // Bollinger Bands Period
input double   InpBB_Deviation      = 2.0;            // Bollinger Bands Deviation
input int      InpATR_Period        = 14;             // ATR Period
input int      InpMACD_Fast         = 12;             // MACD Fast EMA
input int      InpMACD_Slow         = 26;             // MACD Slow EMA
input int      InpMACD_Signal       = 9;              // MACD Signal Period
input int      InpStoch_K           = 5;              // Stochastic %K Period
input int      InpStoch_D           = 3;              // Stochastic %D Period
input int      InpStoch_Slowing     = 3;              // Stochastic Slowing
input int      InpADX_Period        = 14;             // ADX Period
input int      InpCCI_Period        = 20;             // CCI Period

//+------------------------------------------------------------------+
//| Input Parameters - Kalman Filter                                  |
//+------------------------------------------------------------------+
input group "=== Kalman Filter ==="
input double   InpKalman_Q          = 0.01;           // Process Noise (Q)
input double   InpKalman_R          = 0.1;            // Measurement Noise (R)

//+------------------------------------------------------------------+
//| Input Parameters - Advanced                                       |
//+------------------------------------------------------------------+
input group "=== Advanced ==="
input int      InpHMA_Period        = 21;             // Hull MA Period
input int      InpZScore_Period     = 50;             // Z-Score Lookback Period
input int      InpOFI_Smooth        = 5;              // Order Flow Imbalance Smoothing
input int      InpVWAP_ResetBars    = 288;            // VWAP Session Length (bars, 288=24h on M5)

//+------------------------------------------------------------------+
//| Input Parameters - EA Identity                                    |
//+------------------------------------------------------------------+
input group "=== EA Identity ==="
input long     InpMagicNumber       = 20260215;       // Magic Number

//+------------------------------------------------------------------+
//| Data Structures                                                   |
//+------------------------------------------------------------------+
struct TradeSignal
  {
   ENUM_SIGNAL_DIR   direction;        // BUY / SELL / NONE
   double            buyScore;         // Raw buy score
   double            sellScore;        // Raw sell score
   double            slPoints;         // Stop loss in points
   double            tpPoints;         // Take profit in points
   ENUM_MARKET_REGIME regime;          // Current market regime
   double            regimeConfidence; // Regime confidence 0-1
   string            source;           // Signal description label

   void Reset()
     {
      direction        = SIGNAL_NONE;
      buyScore         = 0;
      sellScore        = 0;
      slPoints         = 0;
      tpPoints         = 0;
      regime           = REGIME_UNKNOWN;
      regimeConfidence = 0;
      source           = "";
     }
  };

struct RiskMetrics
  {
   double   currentDrawdown;     // Current drawdown % from peak
   double   dailyPnL;            // Today's closed P&L in account currency
   int      openPositions;       // Number of open positions with our magic
   int      dailyTrades;         // Number of trades opened today
   double   equityMA;            // Equity moving average over lookback
   double   peakEquity;          // Peak equity observed
   double   kellyLotSize;        // Kelly-optimal lot size
   double   adjustedRisk;        // Risk after all adjustments
   bool     isTradingAllowed;    // Final gate: can we trade?
   string   haltReason;          // Why trading is halted

   void Reset()
     {
      currentDrawdown  = 0;
      dailyPnL         = 0;
      openPositions    = 0;
      dailyTrades      = 0;
      equityMA         = 0;
      peakEquity       = 0;
      kellyLotSize     = 0;
      adjustedRisk     = InpRiskPercent;
      isTradingAllowed = true;
      haltReason       = "";
     }
  };

struct PerformanceStats
  {
   double   winRate;             // Win rate 0-100
   double   profitFactor;        // Gross profit / gross loss
   int      consecutiveWins;     // Current consecutive wins
   int      consecutiveLosses;   // Current consecutive losses
   double   avgWin;              // Average winning trade P&L
   double   avgLoss;             // Average losing trade P&L (positive)
   int      totalTrades;         // Total trades in lookback window
   double   kellyFraction;       // Computed Kelly fraction
   double   lotMultiplier;       // Adaptation lot multiplier (0.3 - 1.5)
   double   scoreAdjustment;     // Signal score threshold adjustment (-3 to +3)
   datetime cooldownUntil;       // Timestamp when cooldown expires

   void Reset()
     {
      winRate          = 50.0;
      profitFactor     = 1.0;
      consecutiveWins  = 0;
      consecutiveLosses= 0;
      avgWin           = 0;
      avgLoss          = 0;
      totalTrades      = 0;
      kellyFraction    = 0;
      lotMultiplier    = 1.0;
      scoreAdjustment  = 0;
      cooldownUntil    = 0;
     }
  };

struct TradeRecord
  {
   datetime openTime;
   datetime closeTime;
   double   pnl;                 // Profit/loss in account currency
   bool     isWin;               // pnl > 0
   double   entryScore;          // Signal score at entry
   ENUM_MARKET_REGIME regime;    // Regime at entry
   ENUM_SIGNAL_DIR direction;    // Buy or sell
  };

//+------------------------------------------------------------------+
//| Global Working Symbol                                             |
//+------------------------------------------------------------------+
string g_workingSymbol = "";     // Resolved actual symbol name

//+------------------------------------------------------------------+
//| Symbol Resolution - Fallback Chain                                |
//+------------------------------------------------------------------+
bool ResolveSymbol()
  {
   // Try user's input first
   string candidates[];
   int count = 0;

   // Build candidate list
   ArrayResize(candidates, 6);
   candidates[count++] = InpSymbol;
   candidates[count++] = "Gold.i#";
   candidates[count++] = "XAUUSD";
   candidates[count++] = "Gold";
   candidates[count++] = "GOLD";
   candidates[count++] = _Symbol;  // Current chart symbol as last resort

   for(int i = 0; i < count; i++)
     {
      if(candidates[i] == "")
         continue;
      if(SymbolSelect(candidates[i], true))
        {
         // Verify the symbol has valid data
         double bid = SymbolInfoDouble(candidates[i], SYMBOL_BID);
         if(bid > 0)
           {
            g_workingSymbol = candidates[i];
            PrintFormat("[GA] Symbol resolved: %s (bid=%.2f)", g_workingSymbol, bid);
            return true;
           }
        }
     }

   Print("[GA] ERROR: Could not resolve any valid gold symbol!");
   return false;
  }

//+------------------------------------------------------------------+
//| Session & Day Validation                                          |
//+------------------------------------------------------------------+
bool IsWithinTradingSession()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // Check day of week
   switch(dt.day_of_week)
     {
      case 1: if(!InpTradeMonday)    return false; break;
      case 2: if(!InpTradeTuesday)   return false; break;
      case 3: if(!InpTradeWednesday) return false; break;
      case 4: if(!InpTradeThursday)  return false; break;
      case 5: if(!InpTradeFriday)    return false; break;
      default: return false; // Saturday/Sunday
     }

   // Check hour window
   if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Check if near session end (for closing profitable trades)         |
//+------------------------------------------------------------------+
bool IsNearSessionEnd(int minutesBefore = 5)
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int minutesLeft = (InpEndHour * 60) - (dt.hour * 60 + dt.min);
   return (minutesLeft <= minutesBefore && minutesLeft > 0);
  }

#endif // __GA_CONFIG_MQH__
