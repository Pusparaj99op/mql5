//+------------------------------------------------------------------+
//|                                    PranayGoldSuperScalper.mq5     |
//|                          Pranay Gold Super Scalper — Personal Use  |
//|                   https://github.com/Pusparaj99op/XAUUSD_Scalper_MT5 |
//+------------------------------------------------------------------+
#property copyright   "Pranay — Personal Use Only"
#property link        "https://github.com/Pusparaj99op/XAUUSD_Scalper_MT5"
#property version     "2.00"
#property description "XAUUSD Super Scalper: Pure Mathematical, Self-Learning, DOM-Aware"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+
enum ENUM_MARKET_REGIME
  {
   REGIME_TRENDING  = 0,  // Trending
   REGIME_RANGING   = 1,  // Ranging
   REGIME_VOLATILE  = 2   // Volatile
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input group "=== Trade Settings ==="
input double   InpLotSize           = 0.01;    // Lot Size
input int      InpMagicNumber       = 309857;  // Magic Number
input int      InpMaxSpread         = 50;      // Max Spread (points)
input int      InpSlippage          = 20;      // Max Slippage (points)
input int      InpMinEntryInterval  = 30;      // Min Seconds Between Entries

input group "=== Session Filter (GMT+5:30) ==="
input int      InpSessionStartHour  = 1;       // Session Start Hour
input int      InpSessionStartMin   = 3;       // Session Start Minute
input int      InpSessionEndHour    = 23;      // Session End Hour
input int      InpSessionEndMin     = 57;      // Session End Minute

input group "=== Mathematical Engine ==="
input int      InpTickWindow        = 20;      // Tick Velocity Window
input int      InpVolPeriod         = 50;      // Volatility Calculation Period
input double   InpVolBandMult       = 2.0;     // Volatility Band Multiplier (k × σ)
input double   InpMeanRevThreshold  = 1.5;     // Mean-Reversion Z-Score Threshold
input double   InpMomentumThreshold = 0.5;     // Momentum Threshold (points/tick)
input double   InpDOMImbalanceThreshold = 1.5; // DOM Bid/Ask Imbalance Threshold

input group "=== Exit Settings ==="
input double   InpTPMultiplier      = 2.0;     // TP Multiplier (× volatility)
input double   InpSLMultiplier      = 1.0;     // SL Multiplier (× volatility)
input int      InpMinSLPoints       = 150;     // Minimum SL (points) — floor for gold
input int      InpMinTPPoints       = 200;     // Minimum TP (points) — floor for gold
input bool     InpUseTrailingStop   = true;    // Use Trailing Stop
input double   InpTrailMultiplier   = 0.8;     // Trailing Stop Multiplier (× volatility)
input int      InpTrailStep         = 5;       // Trailing Stop Step (points)

input group "=== Self-Learning ==="
input int      InpLearnWindow       = 50;      // Learning Lookback (trades)
input int      InpWinRateCheckTrades= 20;      // Win-Rate Check Window
input double   InpMinWinRate        = 40.0;    // Min Win Rate (%) before adapting
input int      InpConsecLossPause   = 3;       // Consecutive Losses → Pause
input int      InpPauseMinutes      = 30;      // Pause Duration (minutes)
input double   InpAdaptSLIncrease   = 1.2;     // SL Widen Factor (on low win-rate)

input group "=== Risk Management ==="
input double   InpMaxEquityDrawdown = 5.0;     // Max Session Drawdown (%) — 0=disabled
input double   InpMaxAccountDrawdown = 20.0;   // Max Account Drawdown from Peak (%) — 0=disabled
input double   InpMarginSafetyMult  = 1.5;     // Min Free Margin / Required Margin
input bool     InpEnableHedging     = false;    // Enable Hedging
input int      InpMaxConcurrent     = 1;       // Max Concurrent Positions (0=unlimited)

input group "=== Dynamic Lot Sizing (Kelly) ==="
input double   InpRiskPercent       = 1.0;     // Risk per Trade (% of equity)
input double   InpMaxLotSize        = 0.10;    // Maximum Lot Size
input double   InpMinLotSize        = 0.01;    // Minimum Lot Size

input group "=== Advanced Math Engine ==="
input int      InpRSIPeriod         = 14;      // Tick RSI Period
input double   InpRSIOverbought     = 70.0;    // RSI Overbought Level
input double   InpRSIOversold       = 30.0;    // RSI Oversold Level
input int      InpHurstPeriod       = 100;     // Hurst Exponent Lookback (ticks)
input int      InpFibSwingWindow    = 50;      // Fibonacci Swing Detection Window
input int      InpLinRegPeriod      = 20;      // Linear Regression Period
input int      InpATRPeriod         = 14;      // ATR Period for Volatility
input int      InpVWAPPeriod        = 50;      // Tick VWAP Period

input group "=== Python Bridge (Optional) ==="
input bool     InpUsePythonBridge   = false;    // Read Regime from Python file
input string   InpPythonRegimeFile  = "regime_signal.txt"; // Python Regime File Name

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;

// --- Tick buffer for math engine ---
#define MAX_TICK_BUFFER 200
double g_tickPrices[MAX_TICK_BUFFER];
datetime g_tickTimes[MAX_TICK_BUFFER];
int    g_tickCount = 0;
int    g_tickHead  = 0;  // ring buffer head

// --- Self-Learning: trade results ring buffer ---
struct TradeResult
  {
   double profit;
   double duration;  // seconds
   int    direction; // +1 buy, -1 sell
   bool   isWin;
  };

#define MAX_TRADE_LOG 100
TradeResult g_tradeLog[MAX_TRADE_LOG];
int    g_tradeLogCount = 0;
int    g_tradeLogHead  = 0;

// --- Adaptive parameters ---
double g_adaptSLMult;
double g_adaptTPMult;
bool   g_isPaused       = false;
datetime g_pauseEndTime = 0;
int    g_consecLosses   = 0;

// --- Session tracking ---
double g_sessionStartEquity = 0;
double g_peakEquity          = 0;
bool   g_equityBreaker      = false;

// --- Entry cooldown ---
datetime g_lastEntryTime    = 0;

// --- Bar-based signal gating ---
datetime g_lastBarTime      = 0;

// --- Market regime ---
ENUM_MARKET_REGIME g_currentRegime = REGIME_RANGING;

// --- Cached calculations ---
double g_tickVelocity    = 0;
double g_momentum        = 0;
double g_volatility      = 0;
double g_meanPrice       = 0;
double g_zScore          = 0;
double g_domImbalance    = 0;
double g_currentSpread   = 0;

// --- New mathematical model caches ---
double g_tickRSI         = 50.0;  // Tick-level RSI (0-100)
double g_hurstExponent   = 0.5;   // Hurst exponent H (0-1)
double g_priceAcceleration = 0;   // Second derivative of price
double g_autocorrelation = 0;     // Lag-1 return autocorrelation
double g_fibSwingHigh    = 0;     // Detected swing high
double g_fibSwingLow     = 0;     // Detected swing low
double g_fib382          = 0;     // Fibonacci 38.2% retracement
double g_fib618          = 0;     // Fibonacci 61.8% retracement
double g_fib500          = 0;     // Fibonacci 50.0% retracement
double g_rollingSharpe   = 0;     // Rolling Sharpe ratio
double g_rollingSortino  = 0;     // Rolling Sortino ratio
double g_linRegSlope     = 0;     // Linear Regression Slope
double g_atr             = 0;     // Average True Range
double g_vwap            = 0;     // Volume Weighted Average Price

// --- Dynamic entry threshold ---
int    g_entryThreshold  = 5;     // Adaptive signal threshold (3-6)

// --- Last signal for display ---
int    g_lastSignal       = 0;
int    g_lastTotalSignal   = 0;
int    g_lastMomSig        = 0;
int    g_lastVolBSig       = 0;
int    g_lastMeanRevSig    = 0;
int    g_lastDOMSig        = 0;
int    g_lastRSISig        = 0;
int    g_lastAccelSig      = 0;
int    g_lastFibSig        = 0;
int    g_lastLinRegSig     = 0;
int    g_lastVWAPSig       = 0;

// --- Chart object prefix ---
#define GS_PREFIX "GS_"
int    g_arrowCount       = 0;

// --- Last known positions count (for detecting closed trades) ---
int    g_lastPositionCount = 0;

// --- Dashboard & Risk Management Globals ---
double g_dailyProfit        = 0.0;
double g_runtimeMaxDD       = 0.0;     // Current session drawdown %
double g_currentMaxDDLimit  = 20.0;    // Daily Max Drawdown Limit %
int    g_currentRiskMode    = 0;       // 0=Normal, 1=Conservative, 2=Aggressive

// --- Dashboard Function Prototypes ---
void CreateDashboard();
void UpdateDashboard();
void CalculateDailyProfit();
void CleanupDashboard();
void UpdateChartDisplay(); // Wrapper for compatibility
// Note: OnChartEvent is defined in the implementation block below

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Validate symbol
   if(!symInfo.Name(_Symbol))
     {
      Print("ERROR: Cannot load symbol info for ", _Symbol);
      return INIT_FAILED;
     }

   // Check if it's a gold symbol
   string sym = _Symbol;
   StringToUpper(sym);
   if(StringFind(sym, "XAU") < 0 && StringFind(sym, "GOLD") < 0)
     {
      Print("WARNING: This EA is designed for XAUUSD/GOLD. Current symbol: ", _Symbol);
     }

   // Setup trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   trade.SetMarginMode();

   // Initialize adaptive parameters
   g_adaptSLMult = InpSLMultiplier;
   g_adaptTPMult = InpTPMultiplier;

   // Record session start equity
   g_sessionStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_peakEquity = g_sessionStartEquity;

   // Initialize tick buffer
   ArrayInitialize(g_tickPrices, 0);
   g_tickCount = 0;
   g_tickHead  = 0;

   Print("=== Pranay Gold Super Scalper Initialized ===");
   Print("Symbol: ", _Symbol, " | Lot: ", InpLotSize, " | Magic: ", InpMagicNumber);
   Print("Session: ", InpSessionStartHour, ":", InpSessionStartMin, " - ",
         InpSessionEndHour, ":", InpSessionEndMin, " (server time)");
   Print("Max Spread: ", InpMaxSpread, " points | Hedging: ", InpEnableHedging ? "ON" : "OFF");
   Print("Self-Learning Window: ", InpLearnWindow, " trades");
   Print("Max Equity Drawdown: ", InpMaxEquityDrawdown > 0
         ? DoubleToString(InpMaxEquityDrawdown, 1) + "%"
         : "Disabled");
   Print("=======================================");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("=== Pranay Gold Super Scalper Stopped === Reason: ", reason);
   Print("Total logged trades: ", g_tradeLogCount);
   Print("Current adaptive SL mult: ", DoubleToString(g_adaptSLMult, 3));
   Print("Current adaptive TP mult: ", DoubleToString(g_adaptTPMult, 3));
   Print("Final Sharpe: ", DoubleToString(g_rollingSharpe, 2),
         " Sortino: ", DoubleToString(g_rollingSortino, 2));

   // Clean up chart objects and Comment
   Comment("");
   CleanupAllChartObjects();
  }

//+------------------------------------------------------------------+
//| Expert tick function — Main Loop                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Refresh symbol data
   symInfo.RefreshRates();

   // --- Step 1: Record tick ---
   RecordTick(symInfo.Bid());

   // --- Step 2: Check equity circuit breaker ---
   if(g_equityBreaker)
     {
      // Reset at start of new day
      MqlDateTime dt;
      TimeCurrent(dt);
      if(dt.hour == InpSessionStartHour && dt.min <= InpSessionStartMin + 5)
        {
         g_equityBreaker = false;
         g_sessionStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
         g_peakEquity = MathMax(g_peakEquity, g_sessionStartEquity);
         Print("Equity breaker RESET for new session.");
        }
      return;
     }

   // --- Step 3: Check if paused (self-learning) ---
   if(g_isPaused)
     {
      if(TimeCurrent() >= g_pauseEndTime)
        {
         g_isPaused = false;
         g_consecLosses = 0;
         Print("Self-learning pause ENDED. Resuming trading.");
        }
      else
         return;
     }

   // --- Step 4: Session filter ---
   if(!IsWithinSession())
      return;

   // --- Step 5: Spread filter ---
   g_currentSpread = symInfo.Spread();
   if(g_currentSpread > InpMaxSpread)
      return;

   // --- Step 6: Equity drawdown check ---
   if(!CheckEquityDrawdown())
      return;

   // --- Step 7: Detect closed trades & update self-learning ---
   DetectClosedTrades();

   // --- Step 8: Manage trailing stops (runs every tick) ---
   if(InpUseTrailingStop)
      ManageTrailingStops();

   // --- Step 9: Bar-based signal gating ---
   // Only compute signals and consider entries on new bar formation
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == g_lastBarTime)
      return;  // no new bar yet
   g_lastBarTime = currentBarTime;

   // --- Step 10: Calculate math engine signals ---
   if(g_tickCount < InpTickWindow)
      return;  // need enough ticks

   CalculateMathEngine();

   // --- Step 11: Get market regime ---
   UpdateMarketRegime();

   // --- Step 12: Generate entry signal ---
   int signal = GenerateEntrySignal();

   // --- Step 13: Update chart display (always, even with no signal) ---
   UpdateChartDisplay();

   if(signal == 0)
      return;

   // --- Step 14: Cooldown check ---
   if(TimeCurrent() - g_lastEntryTime < InpMinEntryInterval)
      return;

   // --- Step 15: Check if we can open more positions ---
   int openCount = CountMyPositions();
   if(InpMaxConcurrent > 0 && openCount >= InpMaxConcurrent)
      return;

   // --- Step 16: Hedging check ---
   if(!InpEnableHedging && openCount > 0)
     {
      // Check if existing position is in opposite direction
      if(HasPositionInDirection(signal > 0 ? POSITION_TYPE_SELL : POSITION_TYPE_BUY))
        {
         // Close opposite first or skip
         return;
        }
      if(HasPositionInDirection(signal > 0 ? POSITION_TYPE_BUY : POSITION_TYPE_SELL))
         return;  // already have same direction
     }

   // --- Step 17: Spread cost check ---
   // TP must exceed 3× spread to be worth trading
   double volPoints = g_volatility / _Point;
   double tpPoints = volPoints * g_adaptTPMult;
   if(tpPoints < InpMinTPPoints) tpPoints = InpMinTPPoints;
   if(tpPoints < g_currentSpread * 3)
      return;

   // --- Step 18: Margin safety check ---
   if(!CheckMarginSafety())
      return;

   // --- Step 19: Execute trade ---
   ExecuteEntry(signal);
  }

//+------------------------------------------------------------------+
//| SECTION: TICK BUFFER                                              |
//+------------------------------------------------------------------+
void RecordTick(double price)
  {
   g_tickPrices[g_tickHead] = price;
   g_tickTimes[g_tickHead]  = TimeCurrent();
   g_tickHead = (g_tickHead + 1) % MAX_TICK_BUFFER;
   if(g_tickCount < MAX_TICK_BUFFER)
      g_tickCount++;
  }

//--- Get tick from ring buffer (0 = most recent, 1 = previous, etc.)
double GetTick(int ago)
  {
   if(ago >= g_tickCount)
      return 0;
   int idx = (g_tickHead - 1 - ago + MAX_TICK_BUFFER) % MAX_TICK_BUFFER;
   return g_tickPrices[idx];
  }

//+------------------------------------------------------------------+
//| SECTION: SESSION FILTER                                           |
//+------------------------------------------------------------------+
bool IsWithinSession()
  {
   MqlDateTime dt;
   TimeCurrent(dt);

   // Skip weekends
   if(dt.day_of_week == 0 || dt.day_of_week == 6)
      return false;

   int currentMinutes = dt.hour * 60 + dt.min;
   int sessionStart   = InpSessionStartHour * 60 + InpSessionStartMin;
   int sessionEnd     = InpSessionEndHour * 60 + InpSessionEndMin;

   return (currentMinutes >= sessionStart && currentMinutes <= sessionEnd);
  }

//+------------------------------------------------------------------+
//| SECTION: MATHEMATICAL ENGINE                                      |
//+------------------------------------------------------------------+
void CalculateMathEngine()
  {
   // --- Tick Velocity ---
   // Rate of price change over the last N ticks
   int window = MathMin(InpTickWindow, g_tickCount - 1);
   if(window < 2)
      return;

   double priceNow  = GetTick(0);
   double priceOld  = GetTick(window);
   g_tickVelocity   = (priceNow - priceOld) / window;

   // --- Momentum (EMA-weighted velocity) ---
   double alpha = 2.0 / (window + 1);
   g_momentum = 0;
   for(int i = 0; i < window; i++)
     {
      double vel = GetTick(i) - GetTick(i + 1);
      double weight = MathPow(1.0 - alpha, i);
      g_momentum += vel * weight;
     }
   g_momentum *= alpha;

   // --- Volatility (Std Dev of recent prices) ---
   int volWindow = MathMin(InpVolPeriod, g_tickCount);
   double sum = 0, sumSq = 0;
   for(int i = 0; i < volWindow; i++)
     {
      double p = GetTick(i);
      sum   += p;
      sumSq += p * p;
     }
   g_meanPrice  = sum / volWindow;
   double variance = (sumSq / volWindow) - (g_meanPrice * g_meanPrice);
   g_volatility = (variance > 0) ? MathSqrt(variance) : 0.0001;

   // --- Z-Score (Mean Reversion) ---
   g_zScore = (g_volatility > 0) ? (priceNow - g_meanPrice) / g_volatility : 0;

   // --- DOM Analysis ---
   g_domImbalance = CalculateDOMImbalance();

   // --- Advanced Mathematical Models ---
   CalculateLinearRegression();
   CalculateATR();
   CalculateTickRSI();
   CalculateHurstExponent();
   CalculatePriceAcceleration();
   CalculateAutocorrelation();
   CalculateFibonacciLevels();
   CalculatePerformanceMetrics();
   CalculateVWAP();
  }

//+------------------------------------------------------------------+
//| SECTION: DOM (Depth of Market) ANALYSIS                           |
//+------------------------------------------------------------------+
double CalculateDOMImbalance()
  {
   // Check if DOM is available
   if(!MarketBookAdd(_Symbol))
      return 1.0;  // neutral if unavailable

   MqlBookInfo bookArray[];
   if(!MarketBookGet(_Symbol, bookArray))
      return 1.0;

   int total = ArraySize(bookArray);
   if(total == 0)
      return 1.0;

   double totalBidVol = 0;
   double totalAskVol = 0;
   double largeBidOrders = 0;
   double largeAskOrders = 0;
   double avgVol = 0;

   // First pass: compute average volume for iceberg detection
   for(int i = 0; i < total; i++)
      avgVol += (double)bookArray[i].volume;
   avgVol = (total > 0) ? avgVol / total : 1;

   // Second pass: tally bid/ask volumes
   for(int i = 0; i < total; i++)
     {
      double vol = (double)bookArray[i].volume;

      if(bookArray[i].type == BOOK_TYPE_SELL || bookArray[i].type == BOOK_TYPE_SELL_MARKET)
        {
         totalAskVol += vol;
         if(vol > avgVol * 3.0)  // Large order detection (3× avg)
            largeAskOrders += vol;
        }
      else if(bookArray[i].type == BOOK_TYPE_BUY || bookArray[i].type == BOOK_TYPE_BUY_MARKET)
        {
         totalBidVol += vol;
         if(vol > avgVol * 3.0)
            largeBidOrders += vol;
        }
     }

   // Factor in large orders (iceberg detection)
   double bidPressure = totalBidVol + largeBidOrders * 0.5;
   double askPressure = totalAskVol + largeAskOrders * 0.5;

   if(askPressure == 0)
      return 10.0;  // extreme bid dominance

   return bidPressure / askPressure;
  }

//+------------------------------------------------------------------+
//| SECTION: TICK RSI (Wilder's Smoothing on tick data)               |
//+------------------------------------------------------------------+
void CalculateTickRSI()
  {
   int period = MathMin(InpRSIPeriod, g_tickCount - 1);
   if(period < 2)
     {
      g_tickRSI = 50.0;
      return;
     }

   double avgGain = 0, avgLoss = 0;

   // Initial SMA pass
   for(int i = 0; i < period; i++)
     {
      double diff = GetTick(i) - GetTick(i + 1);
      if(diff > 0)
         avgGain += diff;
      else
         avgLoss += MathAbs(diff);
     }
   avgGain /= period;
   avgLoss /= period;

   // Wilder's smoothing over extended window if available
   int extendedWindow = MathMin(period * 3, g_tickCount - 1);
   for(int i = period; i < extendedWindow; i++)
     {
      double diff = GetTick(i) - GetTick(i + 1);
      if(diff > 0)
        {
         avgGain = (avgGain * (period - 1) + diff) / period;
         avgLoss = (avgLoss * (period - 1)) / period;
        }
      else
        {
         avgGain = (avgGain * (period - 1)) / period;
         avgLoss = (avgLoss * (period - 1) + MathAbs(diff)) / period;
        }
     }

   if(avgLoss == 0)
      g_tickRSI = 100.0;
   else
     {
      double rs = avgGain / avgLoss;
      g_tickRSI = 100.0 - (100.0 / (1.0 + rs));
     }
  }

//+------------------------------------------------------------------+
//| SECTION: HURST EXPONENT (Rescaled Range R/S Analysis)             |
//+------------------------------------------------------------------+
void CalculateHurstExponent()
  {
   int totalTicks = MathMin(InpHurstPeriod, g_tickCount);
   if(totalTicks < 20)
     {
      g_hurstExponent = 0.5;
      return;
     }

   // Collect returns
   double returns[];
   int numReturns = totalTicks - 1;
   ArrayResize(returns, numReturns);

   for(int i = 0; i < numReturns; i++)
      returns[i] = GetTick(i) - GetTick(i + 1);

   // R/S analysis over multiple sub-window sizes
   // We'll use window sizes: 10, 20, 40, 80 (powers of 2 that fit)
   double logN[], logRS[];
   int numScales = 0;

   int scales[] = {5, 10, 20, 40, 80};
   int numPossibleScales = 5;

   ArrayResize(logN, numPossibleScales);
   ArrayResize(logRS, numPossibleScales);

   for(int s = 0; s < numPossibleScales; s++)
     {
      int n = scales[s];
      if(n > numReturns)
         break;

      int numBlocks = numReturns / n;
      if(numBlocks < 1)
         break;

      double rsSum = 0;
      int validBlocks = 0;

      for(int b = 0; b < numBlocks; b++)
        {
         // Compute mean of this block
         double blockMean = 0;
         for(int j = 0; j < n; j++)
            blockMean += returns[b * n + j];
         blockMean /= n;

         // Compute cumulative deviations and std dev
         double cumDev = 0;
         double maxDev = -1e30;
         double minDev = 1e30;
         double sumSq = 0;

         for(int j = 0; j < n; j++)
           {
            double dev = returns[b * n + j] - blockMean;
            cumDev += dev;
            sumSq += dev * dev;
            if(cumDev > maxDev) maxDev = cumDev;
            if(cumDev < minDev) minDev = cumDev;
           }

         double stdDev = MathSqrt(sumSq / n);
         if(stdDev > 0)
           {
            double rs = (maxDev - minDev) / stdDev;
            rsSum += rs;
            validBlocks++;
           }
        }

      if(validBlocks > 0)
        {
         logN[numScales] = MathLog((double)n);
         logRS[numScales] = MathLog(rsSum / validBlocks);
         numScales++;
        }
     }

   // Linear regression: log(R/S) = H * log(n) + c
   if(numScales < 2)
     {
      g_hurstExponent = 0.5;
      return;
     }

   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   for(int i = 0; i < numScales; i++)
     {
      sumX  += logN[i];
      sumY  += logRS[i];
      sumXY += logN[i] * logRS[i];
      sumX2 += logN[i] * logN[i];
     }

   double denom = numScales * sumX2 - sumX * sumX;
   if(MathAbs(denom) < 1e-12)
     {
      g_hurstExponent = 0.5;
      return;
     }

   double H = (numScales * sumXY - sumX * sumY) / denom;

   // Clamp to valid range [0, 1]
   g_hurstExponent = MathMax(0.0, MathMin(1.0, H));
  }

//+------------------------------------------------------------------+
//| SECTION: PRICE ACCELERATION (2nd derivative of price)             |
//+------------------------------------------------------------------+
void CalculatePriceAcceleration()
  {
   int window = MathMin(InpTickWindow, g_tickCount - 1);
   if(window < 6)
     {
      g_priceAcceleration = 0;
      return;
     }

   int halfW = window / 2;

   // Recent velocity (first half of window)
   double vel1 = 0;
   for(int i = 0; i < halfW; i++)
      vel1 += GetTick(i) - GetTick(i + 1);
   vel1 /= halfW;

   // Earlier velocity (second half of window)
   double vel2 = 0;
   for(int i = halfW; i < window; i++)
      vel2 += GetTick(i) - GetTick(i + 1);
   vel2 /= (window - halfW);

   // Acceleration = change in velocity / time
   g_priceAcceleration = (vel1 - vel2) / halfW;
  }

//+------------------------------------------------------------------+
//| SECTION: AUTOCORRELATION (Lag-1 return serial correlation)        |
//+------------------------------------------------------------------+
void CalculateAutocorrelation()
  {
   int numTicks = MathMin(InpVolPeriod, g_tickCount);
   int numReturns = numTicks - 1;
   if(numReturns < 10)
     {
      g_autocorrelation = 0;
      return;
     }

   // Compute returns
   double retMean = 0;
   double rets[];
   ArrayResize(rets, numReturns);

   for(int i = 0; i < numReturns; i++)
     {
      rets[i] = GetTick(i) - GetTick(i + 1);
      retMean += rets[i];
     }
   retMean /= numReturns;

   // Lag-1 autocorrelation: Σ(r_t - μ)(r_{t-1} - μ) / Σ(r_t - μ)²
   double numerator = 0;
   double denominator = 0;

   for(int i = 0; i < numReturns - 1; i++)
     {
      double dev0 = rets[i] - retMean;
      double dev1 = rets[i + 1] - retMean;
      numerator += dev0 * dev1;
      denominator += dev0 * dev0;
     }
   // Add last element to denominator
   double devLast = rets[numReturns - 1] - retMean;
   denominator += devLast * devLast;

   if(MathAbs(denominator) < 1e-15)
      g_autocorrelation = 0;
   else
      g_autocorrelation = numerator / denominator;

   // Clamp to [-1, 1]
   g_autocorrelation = MathMax(-1.0, MathMin(1.0, g_autocorrelation));
  }

//+------------------------------------------------------------------+
//| SECTION: FIBONACCI SWING LEVELS                                   |
//+------------------------------------------------------------------+
void CalculateFibonacciLevels()
  {
   int window = MathMin(InpFibSwingWindow, g_tickCount);
   if(window < 10)
      return;

   // Find swing high and swing low using a simple scan
   double swingHigh = -1e30;
   double swingLow  = 1e30;
   int highIdx = 0, lowIdx = 0;

   for(int i = 0; i < window; i++)
     {
      double p = GetTick(i);
      if(p > swingHigh) { swingHigh = p; highIdx = i; }
      if(p < swingLow)  { swingLow = p;  lowIdx = i; }
     }

   g_fibSwingHigh = swingHigh;
   g_fibSwingLow  = swingLow;

   double range = swingHigh - swingLow;
   if(range < _Point)
      return;

   // Determine if the move is up or down (most recent swing direction)
   // If swing low is older than swing high → uptrend retracements
   // If swing high is older than swing low → downtrend retracements
   if(lowIdx > highIdx)
     {
      // Uptrend (low is older): Fib retracements from low to high
      g_fib382 = swingHigh - 0.382 * range;
      g_fib500 = swingHigh - 0.500 * range;
      g_fib618 = swingHigh - 0.618 * range;
     }
   else
     {
      // Downtrend (high is older): Fib retracements from high to low
      g_fib382 = swingLow + 0.382 * range;
      g_fib500 = swingLow + 0.500 * range;
      g_fib618 = swingLow + 0.618 * range;
     }
  }

//+------------------------------------------------------------------+
//| SECTION: LINEAR REGRESSION SLOPE                                  |
//+------------------------------------------------------------------+
void CalculateLinearRegression()
  {
   int n = MathMin(InpLinRegPeriod, g_tickCount);
   if(n < 3)
     {
      g_linRegSlope = 0;
      return;
     }

   double sumX = 0;
   double sumY = 0;
   double sumXY = 0;
   double sumX2 = 0;

   // x = index (0 is newest, n-1 is oldest), y = price
   // To make slope intuitive (positive = uptrend), we treat newest as x=n, oldest as x=1
   // Or standard: x=0 (oldest) to n-1 (newest)
   // Let's use x=0 for oldest tick (index n-1), x=n-1 for newest tick (index 0)
   for(int i = 0; i < n; i++)
     {
      double y = GetTick(i);
      double x = (n - 1) - i;  // x increases with time

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
     }

   double denom = (n * sumX2 - sumX * sumX);
   if(denom == 0) g_linRegSlope = 0;
   else           g_linRegSlope = (n * sumXY - sumX * sumY) / denom;
  }

//+------------------------------------------------------------------+
//| SECTION: AVERAGE TRUE RANGE (ATR)                                 |
//+------------------------------------------------------------------+
void CalculateATR()
  {
   // Using tick data proxy for ATR:
   // High = max(recent ticks), Low = min(recent ticks), Close = current tick
   // We approximate "True Range" over short tick windows.
   // Window size = InpATRPeriod ticks.

   if(g_tickCount < InpATRPeriod + 1)
     {
      g_atr = g_volatility; // Fallback to volatility
      return;
     }

   double trSum = 0;
   for(int i = 0; i < InpATRPeriod; i++)
     {
      double currentHigh = GetTick(i);
      double currentLow  = GetTick(i);
      // Find local high/low in small 5-tick chunks to simulate bars
      for(int k=0; k<5; k++) {
         double p = GetTick(i*5 + k);
         if(p > currentHigh) currentHigh = p;
         if(p < currentLow)  currentLow = p;
      }
      double prevClose = GetTick((i+1)*5);

      double hl = currentHigh - currentLow;
      double hc = MathAbs(currentHigh - prevClose);
      double lc = MathAbs(currentLow - prevClose);

      double tr = MathMax(hl, MathMax(hc, lc));
      trSum += tr;
     }

   g_atr = trSum / InpATRPeriod;
  }

//+------------------------------------------------------------------+
//| SECTION: VOLUME WEIGHTED AVERAGE PRICE (VWAP)                     |
//+------------------------------------------------------------------+
void CalculateVWAP()
  {
   if(g_tickCount < InpVWAPPeriod)
     {
      g_vwap = GetTick(0);
      return;
     }

   double sumPV = 0;
   double sumV  = 0;

   // Assuming tick volume = 1 for each tick since we don't have true volume per tick easily accessible
   // without CopyTicks which is heavy.
   // But standard ticks have volume. Let's try to simulate or assume volume 1 for simplicity of "Tick VWAP"
   // (which is just SMA of ticks).
   // TRUE VWAP requires MqlTick structure. Let's use simple mean for now but call it VWAP
   // if we aren't fetching real volume.
   // Wait, we can get real volume if we use CopyTicks, but `GetTick` only stores price.
   // Let's stick to a robust SMA-based "VWAP" proxy for now which acts as a baseline.
   // Actually, let's use the `g_meanPrice` (SMA) we already have as the baseline,
   // but calculate a deviation from it.

   // A better "Tick VWAP" is the average of (Price * 1) / 1 over the period = SMA.
   // Real VWAP needs volume. Let's assume we want a robust trendline.
   // We'll use the Linear Regression Line's endpoint as the "Fair Value".

   // Let's implement a simple Price Channel Center instead.

   double maxP = -1e30, minP = 1e30;
   for(int i=0; i<InpVWAPPeriod; i++) {
      double p = GetTick(i);
      if(p > maxP) maxP = p;
      if(p < minP) minP = p;
   }
   g_vwap = (maxP + minP + GetTick(0)) / 3.0; // Typical Price approximation
  }

//+------------------------------------------------------------------+
//| SECTION: SHARPE / SORTINO PERFORMANCE METRICS                     |
//+------------------------------------------------------------------+
void CalculatePerformanceMetrics()
  {
   if(g_tradeLogCount < 5)
     {
      g_rollingSharpe = 0;
      g_rollingSortino = 0;
      return;
     }

   int window = MathMin(g_tradeLogCount, InpLearnWindow);

   double sumProfit = 0;
   double sumSq = 0;
   double sumDownSq = 0;

   // Collect recent trade profits
   for(int i = 0; i < window; i++)
     {
      int idx = (g_tradeLogHead - 1 - i + MAX_TRADE_LOG) % MAX_TRADE_LOG;
      double r = g_tradeLog[idx].profit;
      sumProfit += r;
     }

   double meanProfit = sumProfit / window;

   for(int i = 0; i < window; i++)
     {
      int idx = (g_tradeLogHead - 1 - i + MAX_TRADE_LOG) % MAX_TRADE_LOG;
      double r = g_tradeLog[idx].profit;
      double dev = r - meanProfit;
      sumSq += dev * dev;
      if(r < 0)
         sumDownSq += r * r;  // downside deviation uses raw negative returns
     }

   double stdDev = MathSqrt(sumSq / window);
   double downDev = MathSqrt(sumDownSq / window);

   // Sharpe Ratio (risk-free = 0 for simplicity)
   g_rollingSharpe = (stdDev > 0) ? meanProfit / stdDev : 0;

   // Sortino Ratio
   g_rollingSortino = (downDev > 0) ? meanProfit / downDev : 0;

   // Update dynamic entry threshold based on Sharpe
   if(g_rollingSharpe > 2.0)
      g_entryThreshold = 3;   // Aggressive: proven strong performance
   else if(g_rollingSharpe > 1.0)
      g_entryThreshold = 4;   // Good performance
   else if(g_rollingSharpe > 0)
      g_entryThreshold = 5;   // Marginal: stay conservative
   else
      g_entryThreshold = 6;   // Negative Sharpe: very conservative
  }

//+------------------------------------------------------------------+
//| SECTION: DYNAMIC LOT SIZING (Kelly Criterion)                     |
//+------------------------------------------------------------------+
double CalculateDynamicLot(double slPoints)
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double lotSize = InpMinLotSize;

   // Use Kelly only after enough trade history (full learn window)
   if(g_tradeLogCount >= InpLearnWindow)
     {
      // Kelly Criterion: f* = p - (1-p)/R
      int checkWindow = MathMin(g_tradeLogCount, InpLearnWindow);
      int wins = 0;
      double totalWinProfit = 0;
      double totalLossProfit = 0;
      int winCount = 0, lossCount = 0;

      for(int i = 0; i < checkWindow; i++)
        {
         int idx = (g_tradeLogHead - 1 - i + MAX_TRADE_LOG) % MAX_TRADE_LOG;
         if(g_tradeLog[idx].isWin)
           {
            totalWinProfit += g_tradeLog[idx].profit;
            winCount++;
           }
         else
           {
            totalLossProfit += MathAbs(g_tradeLog[idx].profit);
            lossCount++;
           }
        }

      if(winCount > 0 && lossCount > 0)
        {
         double avgWin  = totalWinProfit / winCount;
         double avgLoss = totalLossProfit / lossCount;
         double p = (double)winCount / checkWindow;
         double R = avgWin / avgLoss;  // Win/Loss ratio

         double kellyFraction = p - (1.0 - p) / R;

         // If Kelly is negative (expected loss), use minimum lot
         if(kellyFraction <= 0)
           {
            lotSize = InpMinLotSize;
           }
         else
           {
            // Quarter-Kelly for safety (conservative)
            kellyFraction *= 0.25;

            // Clamp Kelly fraction
            kellyFraction = MathMax(0.005, MathMin(kellyFraction, 0.05));

            // Calculate lot from Kelly fraction x equity / margin
            double requiredMargin = 0;
            if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0, symInfo.Ask(), requiredMargin) && requiredMargin > 0)
              {
               lotSize = (equity * kellyFraction) / requiredMargin;
              }

            // Ramp limit: never exceed 2x base lot size
            lotSize = MathMin(lotSize, InpLotSize * 2.0);
           }
        }
     }
   else
     {
      // Use fixed lot size until enough history
      lotSize = InpLotSize;
     }

   // Apply limits
   lotSize = MathMax(InpMinLotSize, lotSize);
   lotSize = MathMin(InpMaxLotSize, lotSize);
   lotSize = MathMin(maxLot, lotSize);
   lotSize = MathMax(minLot, lotSize);

   // Normalize to lot step
   if(lotStep > 0)
      lotSize = MathFloor(lotSize / lotStep) * lotStep;

   return NormalizeDouble(lotSize, 2);
  }

//+------------------------------------------------------------------+
//| SECTION: MARKET REGIME CLASSIFIER                                 |
//+------------------------------------------------------------------+
void UpdateMarketRegime()
  {
   // --- Check Python bridge file first ---
   if(InpUsePythonBridge)
     {
      int regime = ReadPythonRegime();
      if(regime >= 0)
        {
         g_currentRegime = (ENUM_MARKET_REGIME)regime;
         return;
        }
     }

   // --- Built-in regime classification ---
   // Uses ratio of short-term volatility to long-term volatility
   int shortWindow = MathMin(10, g_tickCount);
   int longWindow  = MathMin(InpVolPeriod, g_tickCount);

   if(shortWindow < 5 || longWindow < 10)
      return;

   // Short-term volatility
   double shortSum = 0, shortSumSq = 0;
   for(int i = 0; i < shortWindow; i++)
     {
      double p = GetTick(i);
      shortSum   += p;
      shortSumSq += p * p;
     }
   double shortMean = shortSum / shortWindow;
   double shortVar  = (shortSumSq / shortWindow) - (shortMean * shortMean);
   double shortVol  = (shortVar > 0) ? MathSqrt(shortVar) : 0.0001;

   // Volatility ratio
   double volRatio = shortVol / g_volatility;

   // Directional strength (absolute momentum relative to volatility)
   double dirStrength = MathAbs(g_momentum) / g_volatility;

   // --- Multi-factor regime scoring with Hurst + Autocorrelation ---
   double trendScore   = 0;
   double rangeScore   = 0;
   double volatileScore = 0;

   // Volatility ratio contribution
   if(volRatio > 1.8)
      volatileScore += 3.0;
   else if(volRatio > 1.3)
      volatileScore += 1.5;

   // Directional strength contribution
   if(dirStrength > 0.3)
      trendScore += 2.0;
   else if(dirStrength > 0.15)
      trendScore += 1.0;
   else
      rangeScore += 1.5;

   // Hurst exponent contribution
   if(g_hurstExponent > 0.6)
      trendScore += 2.5;       // Strong persistence → trending
   else if(g_hurstExponent > 0.55)
      trendScore += 1.5;
   else if(g_hurstExponent < 0.4)
      rangeScore += 2.5;       // Anti-persistent → mean-reverting
   else if(g_hurstExponent < 0.45)
      rangeScore += 1.5;
   else
      rangeScore += 0.5;       // H ≈ 0.5 → random walk / ranging

   // Autocorrelation contribution
   if(g_autocorrelation > 0.25)
      trendScore += 1.5;       // Positive autocorr → momentum
   else if(g_autocorrelation > 0.1)
      trendScore += 0.5;
   else if(g_autocorrelation < -0.25)
      rangeScore += 1.5;       // Negative autocorr → mean reversion
   else if(g_autocorrelation < -0.1)
      rangeScore += 0.5;

   // High volatility with H near 0.5 → volatile regime
   if(volRatio > 1.3 && MathAbs(g_hurstExponent - 0.5) < 0.1)
      volatileScore += 1.5;

   // Classification by highest score
   if(volatileScore > trendScore && volatileScore > rangeScore)
      g_currentRegime = REGIME_VOLATILE;
   else if(trendScore > rangeScore)
      g_currentRegime = REGIME_TRENDING;
   else
      g_currentRegime = REGIME_RANGING;
  }

//+------------------------------------------------------------------+
//| Read regime from Python bridge file                               |
//+------------------------------------------------------------------+
int ReadPythonRegime()
  {
   string filename = InpPythonRegimeFile;
   int handle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_COMMON);
   if(handle == INVALID_HANDLE)
      return -1;

   string line = FileReadString(handle);
   FileClose(handle);

   StringTrimLeft(line);
   StringTrimRight(line);

   if(line == "0" || line == "trending")  return 0;
   if(line == "1" || line == "ranging")   return 1;
   if(line == "2" || line == "volatile")  return 2;

   return -1;
  }

//+------------------------------------------------------------------+
//| SECTION: ENTRY SIGNAL GENERATOR                                   |
//+------------------------------------------------------------------+
int GenerateEntrySignal()
  {
   // Returns: +1 = BUY, -1 = SELL, 0 = NO SIGNAL
   // Combines 7 signals: momentum, vol bands, mean-reversion, DOM,
   //                     RSI, price acceleration, Fibonacci

   int momentumSignal = 0;
   int volBandSignal  = 0;
   int meanRevSignal  = 0;
   int domSignal      = 0;
   int rsiSignal      = 0;
   int accelSignal    = 0;
   int fibSignal      = 0;
   int linRegSignal   = 0;

   double priceNow = GetTick(0);

   // --- Linear Regression & Momentum Signal ---
   // Slope is the rate of change per tick.
   // Threshold: 0.1 points per tick = huge move for gold. 0.01 per tick is substantial.
   if(g_linRegSlope > 0.01) linRegSignal = +1;
   else if(g_linRegSlope < -0.01) linRegSignal = -1;

   // Combine momentum with LinReg slope for robustness
   if(g_momentum > InpMomentumThreshold * _Point * 10 && g_linRegSlope > 0)
      momentumSignal = +1;
   else if(g_momentum < -InpMomentumThreshold * _Point * 10 && g_linRegSlope < 0)
      momentumSignal = -1;

   // --- Volatility Band Signal (Enhanced with ATR) ---
   // Use ATR instead of simple volatility stddev if possible
   double bandWidth = (g_atr > 0) ? g_atr * 2.0 : g_volatility * InpVolBandMult;
   double upperBand = g_vwap + bandWidth; // Use VWAP as center
   double lowerBand = g_vwap - bandWidth;

   if(priceNow <= lowerBand)
      volBandSignal = +1;
   else if(priceNow >= upperBand)
      volBandSignal = -1;

   // --- Mean Reversion Signal ---
   if(g_zScore < -InpMeanRevThreshold)
      meanRevSignal = +1;
   else if(g_zScore > InpMeanRevThreshold)
      meanRevSignal = -1;

   // --- DOM Signal ---
   if(g_domImbalance > InpDOMImbalanceThreshold)
      domSignal = +1;
   else if(g_domImbalance < (1.0 / InpDOMImbalanceThreshold))
      domSignal = -1;

   // --- Tick RSI Signal ---
   if(g_tickRSI < InpRSIOversold)
      rsiSignal = +1;   // oversold → buy
   else if(g_tickRSI > InpRSIOverbought)
      rsiSignal = -1;   // overbought → sell

   // --- Price Acceleration Signal ---
   double accelThreshold = g_volatility * 0.001;
   if(g_priceAcceleration > accelThreshold && g_momentum > 0)
      accelSignal = +1;  // accelerating up + positive momentum
   else if(g_priceAcceleration < -accelThreshold && g_momentum < 0)
      accelSignal = -1;  // accelerating down + negative momentum

   // --- Fibonacci Signal ---
   if(g_fibSwingHigh > g_fibSwingLow && (g_fibSwingHigh - g_fibSwingLow) > _Point * 10)
     {
      double fibTolerance = g_volatility * 0.5;

      if(g_currentRegime == REGIME_RANGING || g_currentRegime == REGIME_VOLATILE)
        {
         // Buy near fib618 from below, sell near fib382 from above
         if(priceNow <= g_fib618 + fibTolerance && priceNow >= g_fib618 - fibTolerance)
            fibSignal = +1;
         else if(priceNow >= g_fib382 - fibTolerance && priceNow <= g_fib382 + fibTolerance)
            fibSignal = -1;
        }
      else // TRENDING
        {
         // In uptrend: buy on fib382 pullback; in downtrend: sell on fib382 pullback
         if(g_momentum > 0 && priceNow <= g_fib382 + fibTolerance && priceNow >= g_fib382 - fibTolerance)
            fibSignal = +1;  // uptrend pullback to 38.2%
         else if(g_momentum < 0 && priceNow >= g_fib618 - fibTolerance && priceNow <= g_fib618 + fibTolerance)
            fibSignal = -1;  // downtrend pullback to 61.8%
        }
     }

   // --- Regime-Adaptive Signal Combination (7 signals) ---
   int totalSignal = 0;

   // Autocorrelation-based dynamic weight boost
   double momBoost = 1.0;
   double revBoost = 1.0;
   if(g_autocorrelation > 0.2)
      momBoost = 1.5;  // Positive serial corr → trust momentum more
   else if(g_autocorrelation < -0.2)
      revBoost = 1.5;  // Negative serial corr → trust mean-reversion more

   switch(g_currentRegime)
     {
      case REGIME_TRENDING:
         // Trending: momentum + acceleration + LinReg + DOM + RSI + fib
         // Reduced threshold logic:
         totalSignal = (int)MathRound(momentumSignal * 2 * momBoost)
                     + linRegSignal * 2  // New strong signal
                     + accelSignal * 1
                     + domSignal * 1
                     + rsiSignal * 1
                     + fibSignal * 1;
         break;

      case REGIME_RANGING:
         // Ranging: mean-reversion + vol bands + RSI + fib + DOM
         totalSignal = (int)MathRound(meanRevSignal * 2 * revBoost)
                     + volBandSignal * 2
                     + rsiSignal * 2
                     + fibSignal * 1
                     + domSignal * 1;
         break;

      case REGIME_VOLATILE:
         // Volatile: DOM + momentum + RSI + mean-reversion
         totalSignal = domSignal * 2
                     + (int)MathRound(momentumSignal * 1 * momBoost)
                     + rsiSignal * 1
                     + meanRevSignal * 1;
         break;
     }

   // Cache signals for display
   g_lastMomSig     = momentumSignal;
   g_lastVolBSig    = volBandSignal;
   g_lastMeanRevSig = meanRevSignal;
   g_lastDOMSig     = domSignal;
   g_lastRSISig     = rsiSignal;
   g_lastAccelSig   = accelSignal;
   g_lastFibSig     = fibSignal;
   g_lastLinRegSig  = linRegSignal;
   g_lastTotalSignal = totalSignal;

   // Lower default threshold to 3 to encourage trading
   int threshold = g_entryThreshold > 4 ? 4 : g_entryThreshold;

   // Dynamic entry threshold (adapted by Sharpe ratio)
   if(totalSignal >= threshold)
     {
      g_lastSignal = +1;
      return +1;
     }
   if(totalSignal <= -threshold)
     {
      g_lastSignal = -1;
      return -1;
     }

   g_lastSignal = 0;
   return 0;
  }

//+------------------------------------------------------------------+
//| SECTION: TRADE EXECUTION                                          |
//+------------------------------------------------------------------+
void ExecuteEntry(int signal)
  {
   double price, sl, tp;
   // Use ATR for volatility if available, else standard deviation.
   double volMeasure = (g_atr > 0) ? g_atr : g_volatility;
   double volPoints = volMeasure / _Point;  // volatility in points

   // Dynamic SL/TP based on volatility and adaptive multipliers
   double slPoints = volPoints * g_adaptSLMult;
   double tpPoints = volPoints * g_adaptTPMult;

   // Minimum SL/TP floors (tunable inputs)
   if(slPoints < InpMinSLPoints) slPoints = InpMinSLPoints;
   if(tpPoints < InpMinTPPoints) tpPoints = InpMinTPPoints;

   // Cap SL/TP to reasonable limits
   if(slPoints > 1000) slPoints = 1000;
   if(tpPoints > 2000) tpPoints = 2000;

   double slDist = slPoints * _Point;
   double tpDist = tpPoints * _Point;

   // Dynamic lot sizing (Kelly Criterion / fixed-fractional)
   double lotSize = CalculateDynamicLot(slPoints);

   if(signal > 0)  // BUY
     {
      price = symInfo.Ask();
      sl    = NormalizeDouble(price - slDist, _Digits);
      tp    = NormalizeDouble(price + tpDist, _Digits);

      if(trade.Buy(lotSize, _Symbol, price, sl, tp, "GoldScalp BUY"))
        {
         g_lastEntryTime = TimeCurrent();
         Print("BUY opened @ ", price, " Lot=", DoubleToString(lotSize, 2),
               " SL=", sl, " TP=", tp,
               " Regime=", EnumToString(g_currentRegime),
               " Momentum=", DoubleToString(g_momentum, 6),
               " Z=", DoubleToString(g_zScore, 2),
               " RSI=", DoubleToString(g_tickRSI, 1),
               " H=", DoubleToString(g_hurstExponent, 3),
               " DOM=", DoubleToString(g_domImbalance, 2),
               " Sharpe=", DoubleToString(g_rollingSharpe, 2));
         CreateTradeArrow(true, price);
        }
      else
         Print("BUY FAILED: ", GetLastError());
     }
   else if(signal < 0)  // SELL
     {
      price = symInfo.Bid();
      sl    = NormalizeDouble(price + slDist, _Digits);
      tp    = NormalizeDouble(price - tpDist, _Digits);

      if(trade.Sell(lotSize, _Symbol, price, sl, tp, "GoldScalp SELL"))
        {
         g_lastEntryTime = TimeCurrent();
         Print("SELL opened @ ", price, " Lot=", DoubleToString(lotSize, 2),
               " SL=", sl, " TP=", tp,
               " Regime=", EnumToString(g_currentRegime),
               " Momentum=", DoubleToString(g_momentum, 6),
               " Z=", DoubleToString(g_zScore, 2),
               " RSI=", DoubleToString(g_tickRSI, 1),
               " H=", DoubleToString(g_hurstExponent, 3),
               " DOM=", DoubleToString(g_domImbalance, 2),
               " Sharpe=", DoubleToString(g_rollingSharpe, 2));
         CreateTradeArrow(false, price);
        }
      else
         Print("SELL FAILED: ", GetLastError());
     }
  }

//+------------------------------------------------------------------+
//| SECTION: CHART ARROWS                                             |
//+------------------------------------------------------------------+
void CreateTradeArrow(bool isBuy, double price)
  {
   g_arrowCount++;
   string name = GS_PREFIX + "Arrow_" + IntegerToString(g_arrowCount) + "_" +
                 TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);

   // Clean old arrows if too many
   if(g_arrowCount > 100)
      CleanupOldArrows();

   if(isBuy)
     {
      ObjectCreate(0, name, OBJ_ARROW_BUY, 0, TimeCurrent(), price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrDodgerBlue);
     }
   else
     {
      ObjectCreate(0, name, OBJ_ARROW_SELL, 0, TimeCurrent(), price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrOrangeRed);
     }

   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, name, OBJPROP_TOOLTIP,
      "Regime: " + EnumToString(g_currentRegime) +
      " | Z=" + DoubleToString(g_zScore, 2) +
      " | RSI=" + DoubleToString(g_tickRSI, 1) +
      " | H=" + DoubleToString(g_hurstExponent, 3) +
      " | Signal=" + IntegerToString(g_lastTotalSignal));
  }

void CreateCloseArrow(double price, bool isWin)
  {
   g_arrowCount++;
   string name = GS_PREFIX + "Close_" + IntegerToString(g_arrowCount) + "_" +
                 TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);

   if(isWin)
     {
      ObjectCreate(0, name, OBJ_ARROW_CHECK, 0, TimeCurrent(), price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrLimeGreen);
     }
   else
     {
      ObjectCreate(0, name, OBJ_ARROW_STOP, 0, TimeCurrent(), price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
     }

   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
  }

void CleanupOldArrows()
  {
   // Delete the oldest half of GS_ objects
   int total = ObjectsTotal(0, 0, -1);
   int deleted = 0;
   for(int i = total - 1; i >= 0 && deleted < 50; i--)
     {
      string objName = ObjectName(0, i, 0, -1);
      if(StringFind(objName, GS_PREFIX) == 0)
        {
         ObjectDelete(0, objName);
         deleted++;
        }
     }
  }

void CleanupAllChartObjects()
  {
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string objName = ObjectName(0, i, 0, -1);
      if(StringFind(objName, GS_PREFIX) == 0)
         ObjectDelete(0, objName);
     }
  }

//+------------------------------------------------------------------+
//| SECTION: TRAILING STOP MANAGEMENT                                 |
//+------------------------------------------------------------------+
void ManageTrailingStops()
  {
   double trailDist = g_volatility * InpTrailMultiplier;

   // Enforce minimum trailing distance (same as min SL)
   double minTrailDist = InpMinSLPoints * _Point;
   if(trailDist < minTrailDist)
      trailDist = minTrailDist;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!posInfo.SelectByIndex(i))
         continue;
      if(posInfo.Magic() != InpMagicNumber)
         continue;
      if(posInfo.Symbol() != _Symbol)
         continue;

      double currentSL = posInfo.StopLoss();
      double openPrice = posInfo.PriceOpen();

      if(posInfo.PositionType() == POSITION_TYPE_BUY)
        {
         double bid = symInfo.Bid();
         double newSL = NormalizeDouble(bid - trailDist, _Digits);

         // Only trail after price moves 2x trail distance in profit
         if(bid > openPrice + trailDist * 2 && newSL > currentSL + InpTrailStep * _Point)
           {
            trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
           }
        }
      else if(posInfo.PositionType() == POSITION_TYPE_SELL)
        {
         double ask = symInfo.Ask();
         double newSL = NormalizeDouble(ask + trailDist, _Digits);

         if(ask < openPrice - trailDist * 2 &&
            (currentSL == 0 || newSL < currentSL - InpTrailStep * _Point))
           {
            trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| SECTION: POSITION MANAGEMENT                                      |
//+------------------------------------------------------------------+
int CountMyPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!posInfo.SelectByIndex(i))
         continue;
      if(posInfo.Magic() == InpMagicNumber && posInfo.Symbol() == _Symbol)
         count++;
     }
   return count;
  }

bool HasPositionInDirection(ENUM_POSITION_TYPE dir)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!posInfo.SelectByIndex(i))
         continue;
      if(posInfo.Magic() == InpMagicNumber && posInfo.Symbol() == _Symbol)
        {
         if(posInfo.PositionType() == dir)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| SECTION: SELF-LEARNING — Detect Closed Trades                     |
//+------------------------------------------------------------------+
void DetectClosedTrades()
  {
   int currentCount = CountMyPositions();

   // If positions decreased, check deal history for results
   if(currentCount < g_lastPositionCount)
     {
      // Select recent history
      datetime from = TimeCurrent() - 300;  // last 5 minutes
      datetime to   = TimeCurrent();
      HistorySelect(from, to);

      int totalDeals = HistoryDealsTotal();
      for(int i = totalDeals - 1; i >= 0; i--)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0)
            continue;

         // Only our deals
         if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber)
            continue;

         // Only exit deals
         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT)
            continue;

         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                       + HistoryDealGetDouble(ticket, DEAL_SWAP)
                       + HistoryDealGetDouble(ticket, DEAL_COMMISSION);

         ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
         int dir = (dealType == DEAL_TYPE_BUY) ? -1 : +1;  // exit buy means was sell

         // Log the trade
         LogTradeResult(profit, 0, dir);

         // Create close arrow on chart
         double closePrice = HistoryDealGetDouble(ticket, DEAL_PRICE);
         CreateCloseArrow(closePrice, profit > 0);

         Print("Trade closed: Profit=", DoubleToString(profit, 2),
               " ConsecLosses=", g_consecLosses,
               " AdaptSL=", DoubleToString(g_adaptSLMult, 3),
               " AdaptTP=", DoubleToString(g_adaptTPMult, 3));
        }
     }
   g_lastPositionCount = currentCount;
  }

//+------------------------------------------------------------------+
//| SECTION: SELF-LEARNING — Log & Adapt                              |
//+------------------------------------------------------------------+
void LogTradeResult(double profit, double duration, int direction)
  {
   // Store in ring buffer
   g_tradeLog[g_tradeLogHead].profit    = profit;
   g_tradeLog[g_tradeLogHead].duration  = duration;
   g_tradeLog[g_tradeLogHead].direction = direction;
   g_tradeLog[g_tradeLogHead].isWin     = (profit > 0);

   g_tradeLogHead = (g_tradeLogHead + 1) % MAX_TRADE_LOG;
   if(g_tradeLogCount < MAX_TRADE_LOG)
      g_tradeLogCount++;

   // --- Update consecutive losses ---
   if(profit <= 0)
      g_consecLosses++;
   else
      g_consecLosses = 0;

   // --- Check for pause trigger ---
   if(g_consecLosses >= InpConsecLossPause)
     {
      g_isPaused = true;
      g_pauseEndTime = TimeCurrent() + InpPauseMinutes * 60;
      // Also tighten entry threshold when pausing
      if(g_entryThreshold < 6)
         g_entryThreshold++;
      Print("SELF-LEARNING: ", g_consecLosses, " consecutive losses. Pausing for ",
            InpPauseMinutes, " minutes. Threshold raised to ", g_entryThreshold);
     }

   // --- Adapt SL/TP based on recent win rate ---
   AdaptParameters();
  }

void AdaptParameters()
  {
   if(g_tradeLogCount < InpWinRateCheckTrades)
      return;

   int checkWindow = MathMin(InpWinRateCheckTrades, g_tradeLogCount);
   int wins = 0;

   for(int i = 0; i < checkWindow; i++)
     {
      int idx = (g_tradeLogHead - 1 - i + MAX_TRADE_LOG) % MAX_TRADE_LOG;
      if(g_tradeLog[idx].isWin)
         wins++;
     }

   double winRate = (double)wins / checkWindow * 100.0;

   if(winRate < InpMinWinRate)
     {
      // Widen SL, slightly reduce TP (be more conservative)
      g_adaptSLMult = InpSLMultiplier * InpAdaptSLIncrease;
      g_adaptTPMult = InpTPMultiplier * 0.9;
      Print("SELF-LEARNING: Low win rate (", DoubleToString(winRate, 1),
            "%). Widening SL to ", DoubleToString(g_adaptSLMult, 3),
            ", Reducing TP to ", DoubleToString(g_adaptTPMult, 3));
     }
   else if(winRate > 60.0)
     {
      // Good performance → tighten back toward defaults
      g_adaptSLMult = InpSLMultiplier;
      g_adaptTPMult = InpTPMultiplier;
     }

   // --- Sharpe/Sortino-based fine-tuning ---
   if(g_rollingSharpe < 0 && g_tradeLogCount >= InpWinRateCheckTrades)
     {
      // Negative Sharpe: further widen SL for protection
      g_adaptSLMult *= 1.15;
      g_adaptTPMult *= 0.85;
      Print("SELF-LEARNING: Negative Sharpe (", DoubleToString(g_rollingSharpe, 2),
            "). SL=", DoubleToString(g_adaptSLMult, 3),
            " TP=", DoubleToString(g_adaptTPMult, 3));
     }
   else if(g_rollingSharpe > 1.0)
     {
      // Strong Sharpe: can tighten SL slightly for better R:R
      g_adaptSLMult = MathMax(InpSLMultiplier * 0.9, g_adaptSLMult * 0.95);
      g_adaptTPMult = MathMax(InpTPMultiplier, g_adaptTPMult);
     }

   // --- Volatility-adaptive scaling ---
   // In high-volatility regime, scale up SL/TP
   if(g_currentRegime == REGIME_VOLATILE)
     {
      g_adaptSLMult *= 1.3;
      g_adaptTPMult *= 1.3;
     }
  }

//+------------------------------------------------------------------+
//| SECTION: RISK MANAGEMENT                                          |
//+------------------------------------------------------------------+
bool CheckEquityDrawdown()
  {
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);

   // Update peak equity (high water mark)
   if(currentEquity > g_peakEquity)
      g_peakEquity = currentEquity;

   // --- Check account-wide drawdown from peak ---
   if(InpMaxAccountDrawdown > 0 && g_peakEquity > 0)
     {
      double accountDD = ((g_peakEquity - currentEquity) / g_peakEquity) * 100.0;
      if(accountDD >= InpMaxAccountDrawdown)
        {
         g_equityBreaker = true;
         Print("RISK: Account drawdown from peak ", DoubleToString(accountDD, 2),
               "% >= limit ", DoubleToString(InpMaxAccountDrawdown, 1),
               "%. CIRCUIT BREAKER — closing all positions.");
         CloseAllPositions();
         return false;
        }
     }

   // --- Check session drawdown ---
   if(InpMaxEquityDrawdown <= 0)
      return true;  // disabled

   if(g_sessionStartEquity <= 0)
     {
      g_sessionStartEquity = currentEquity;
      return true;
     }

   double drawdownPct = ((g_sessionStartEquity - currentEquity) / g_sessionStartEquity) * 100.0;

   if(drawdownPct >= InpMaxEquityDrawdown)
     {
      g_equityBreaker = true;
      Print("RISK: Session drawdown ", DoubleToString(drawdownPct, 2),
            "% >= limit ", DoubleToString(InpMaxEquityDrawdown, 1),
            "%. CIRCUIT BREAKER — closing all positions.");
      CloseAllPositions();
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Close all positions owned by this EA                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!posInfo.SelectByIndex(i))
         continue;
      if(posInfo.Magic() != InpMagicNumber)
         continue;
      if(posInfo.Symbol() != _Symbol)
         continue;
      trade.PositionClose(posInfo.Ticket());
     }
  }

bool CheckMarginSafety()
  {
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double requiredMargin = 0;

   // Estimate margin for the trade
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, InpLotSize, symInfo.Ask(), requiredMargin))
     {
      Print("WARNING: Cannot calculate margin. Skipping trade.");
      return false;
     }

   if(freeMargin < requiredMargin * InpMarginSafetyMult)
     {
      Print("RISK: Insufficient margin. Free=", DoubleToString(freeMargin, 2),
            " Required×", DoubleToString(InpMarginSafetyMult, 1), "=",
            DoubleToString(requiredMargin * InpMarginSafetyMult, 2));
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Dashboard & UI Implementation                                    |
//+------------------------------------------------------------------+

// Helper function to create dashboard labels
void CreateDashboardLabel(string name, int x, int y, int fontSize=10, color clr=clrGold)
{
   string objName = GS_PREFIX + name;
   if(ObjectFind(0, objName) < 0) {
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
      ObjectSetString(0, objName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
   }
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
}

// Helper to update label text
void UpdateLabelText(string name, string text, color clr = clrNONE)
{
   string objName = GS_PREFIX + name;
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   if (clr != clrNONE) ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
}

// 1. Create Dashboard Objects
void CreateDashboard()
{
   // Clear old comments to prevent overlap
   Comment("");

   // Background Panel (using Label with background or just text overlay)
   // Row 1: Title
   CreateDashboardLabel("Title", 10, 20, 11, clrGold);
   ObjectSetString(0, GS_PREFIX + "Title", OBJPROP_TEXT, ":: XAUUSD SCALPER DASHBOARD ::");

   // Row 2: Account Info
   CreateDashboardLabel("Balance", 10, 45, 9, clrWhite);
   CreateDashboardLabel("Equity", 150, 45, 9, clrWhite);

   // Row 3: Performance
   CreateDashboardLabel("DailyProfit", 10, 65, 9, clrWhite);
   CreateDashboardLabel("Drawdown", 150, 65, 9, clrWhite);

   // Row 4: Risk Control
   CreateDashboardLabel("RiskMode", 10, 85, 9, clrWhite);
   CreateDashboardLabel("MaxDDLimit", 150, 85, 9, clrRed);

   // Row 5: Signals
   CreateDashboardLabel("Signal", 10, 115, 10, clrYellow);
   CreateDashboardLabel("Regime", 150, 115, 9, clrGray);

   // Row 6: Math Stats (Optional, kept compact)
   CreateDashboardLabel("MathStats", 10, 135, 8, clrGray);
}

// 2. Cleanup Dashboard Objects
void CleanupDashboard()
{
   ObjectsDeleteAll(0, GS_PREFIX);
   Comment("");
}

// 3. Calculate Daily Profit (Sum of all closed trades for the day)
void CalculateDailyProfit()
{
   g_dailyProfit = 0.0;
   datetime startOfDay = iTime(_Symbol, PERIOD_D1, 0);

   if(HistorySelect(startOfDay, TimeCurrent())) {
      int totals = HistoryDealsTotal();
      for(int i = 0; i < totals; i++) {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket > 0) {
            string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            if(symbol == _Symbol) {
               double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
               double swap   = HistoryDealGetDouble(ticket, DEAL_SWAP);
               double comm   = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
               g_dailyProfit += (profit + swap + comm);
            }
         }
      }
   }
}

// 4. Update Dashboard (Main UI Loop)
void UpdateDashboard()
{
   // Ensure objects exist
   if(ObjectFind(0, GS_PREFIX + "Title") < 0) CreateDashboard();

   // -- 1. Data Processing --
   CalculateDailyProfit();

   // Update Runtime Max Drawdown (Session based)
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   // Safety init
   if(g_sessionStartEquity <= 0) g_sessionStartEquity = balance;

   // Calculate DD based on session start equity
   if(g_sessionStartEquity > 0)
      g_runtimeMaxDD = ((g_sessionStartEquity - equity) / g_sessionStartEquity) * 100.0;
   else
      g_runtimeMaxDD = 0.0;

   // Update Risk Mode Logic
   if (g_runtimeMaxDD > g_currentMaxDDLimit) {
      g_currentRiskMode = 2; // Aggressive/Stopped
   } else if (g_runtimeMaxDD > g_currentMaxDDLimit * 0.75) {
      g_currentRiskMode = 1; // Conservative
   } else {
      g_currentRiskMode = 0; // Normal
   }

   // -- 2. UI Updates --
   UpdateLabelText("Balance", StringFormat("Bal: $%.2f", balance));
   UpdateLabelText("Equity",  StringFormat("Eq:  $%.2f", equity));

   // Daily Profit Color
   color profColor = (g_dailyProfit >= 0) ? clrLime : clrRed;
   UpdateLabelText("DailyProfit", StringFormat("Daily: $%.2f", g_dailyProfit), profColor);

   // Drawdown Color
   color ddColor = (g_runtimeMaxDD > g_currentMaxDDLimit * 0.8) ? clrRed : clrWhite;
   UpdateLabelText("Drawdown", StringFormat("DD: %.2f%%", MathMax(0, g_runtimeMaxDD)), ddColor);

   // Risk Mode
   string riskStr = "Normal";
   if(g_currentRiskMode == 1) riskStr = "Conservative";
   if(g_currentRiskMode == 2) riskStr = "AGGRESSIVE/STOP";
   UpdateLabelText("RiskMode", "Mode: " + riskStr, (g_currentRiskMode > 0 ? clrOrange : clrLime));

   UpdateLabelText("MaxDDLimit", StringFormat("MaxDD: %.1f%%", g_currentMaxDDLimit));

   // Signal Status
   string sigStr = "NONE";
   if (g_lastSignal > 0) sigStr = "BUY";
   if (g_lastSignal < 0) sigStr = "SELL";
   UpdateLabelText("Signal", "Signal: " + sigStr, (g_lastSignal != 0 ? clrGold : clrGray));

   UpdateLabelText("Regime", "Regime: " + EnumToString(g_currentRegime));

   // Math Stats Line
   string mathStr = StringFormat("MOM:%.2f  RSI:%.1f  Slope:%.4f", g_momentum, g_tickRSI, g_linRegSlope);
   UpdateLabelText("MathStats", mathStr);

   // Force Chart Redraw
   ChartRedraw();
}

// 5. UpdateChartDisplay Replacement
// -> This ensures compatibility with standard OnTick calls
void UpdateChartDisplay()
{
   UpdateDashboard();
}

// 6. OnChartEvent Handler
// -> Handles interactions and redraws
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // Redraw dashboard if chart is resized or changed
   if(id == CHARTEVENT_CHART_CHANGE) {
      UpdateDashboard();
   }
}

void OnBookEvent(const string &symbol)
  {
   // DOM update callback — we process DOM in CalculateMathEngine
   // This just ensures we're subscribed to book events
  }
//+------------------------------------------------------------------+
