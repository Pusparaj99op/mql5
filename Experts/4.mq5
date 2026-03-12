//+------------------------------------------------------------------+
//|                                          GoldStrike_Scalper.mq5  |
//|                          Copyright 2024, GoldStrike Trading Lab  |
//|                              Aggressive XAUUSD Scalper EA v3.0   |
//+------------------------------------------------------------------+
#property copyright   "GoldStrike Trading Lab"
#property link        "https://goldstrike-ea.com"
#property version     "3.00"
#property description "Aggressive XAUUSD Scalper with Order Flow, Quant Analysis & Self-Correction"

//+------------------------------------------------------------------+
//| INCLUDES                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\Oscilators.mqh>
#include <Math\Stat\Math.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                      |
//+------------------------------------------------------------------+
enum ENUM_RISK_MODE
  {
   RISK_FIXED   = 0,   // Fixed Lot Size
   RISK_PERCENT = 1,   // Percentage of Balance
   RISK_KELLY   = 2,   // Kelly Criterion
   RISK_DYNAMIC = 3    // Dynamic (Adaptive)
  };

enum ENUM_ENTRY_MODE
  {
   ENTRY_AGGRESSIVE  = 0,  // Aggressive (All Signals)
   ENTRY_MODERATE    = 1,  // Moderate (Confirmed Signals)
   ENTRY_CONSERVATIVE= 2   // Conservative (Strong Signals Only)
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input group "=== GENERAL SETTINGS ==="
input string   InpSymbol          = "XAUUSD";       // Trading Symbol
input ENUM_TIMEFRAMES InpTimeframe= PERIOD_M5;      // Primary Timeframe
input ENUM_TIMEFRAMES InpHTF      = PERIOD_M15;     // Higher Timeframe Filter
input int      InpMagicNumber     = 777888;          // Magic Number
input string   InpTradeComment    = "GoldStrike_v3"; // Trade Comment

input group "=== TIME FILTER ==="
input int      InpStartHour       = 1;              // Start Hour (Server Time)
input int      InpEndHour         = 23;             // End Hour (Server Time)
input bool     InpTradeMonday     = true;           // Trade on Monday
input bool     InpTradeTuesday    = true;           // Trade on Tuesday
input bool     InpTradeWednesday  = true;           // Trade on Wednesday
input bool     InpTradeThursday   = true;           // Trade on Thursday
input bool     InpTradeFriday     = true;           // Trade on Friday

input group "=== RISK MANAGEMENT ==="
input ENUM_RISK_MODE InpRiskMode  = RISK_DYNAMIC;   // Risk Mode
input double   InpFixedLot        = 0.10;           // Fixed Lot Size
input double   InpRiskPercent     = 2.0;            // Risk Percent per Trade
input double   InpMaxDrawdownPct  = 15.0;           // Max Drawdown % (Pause Trading)
input double   InpMaxDailyLoss    = 5.0;            // Max Daily Loss %
input int      InpMaxOpenTrades   = 20;             // Max Simultaneous Open Trades
input double   InpMaxLotSize      = 5.0;            // Maximum Lot Size

input group "=== STOP LOSS & TAKE PROFIT ==="
input double   InpDefaultSL       = 150;            // Default SL (points)
input double   InpDefaultTP       = 200;            // Default TP (points)
input bool     InpUseATRSLTP      = true;           // Use ATR-Based SL/TP
input double   InpATRSLMultiplier = 1.5;            // ATR SL Multiplier
input double   InpATRTPMultiplier = 2.0;            // ATR TP Multiplier
input bool     InpUseTrailingStop = true;           // Use Trailing Stop
input double   InpTrailingStart   = 100;            // Trailing Start (points)
input double   InpTrailingStep    = 30;             // Trailing Step (points)
input bool     InpUseBreakeven    = true;           // Use Breakeven
input double   InpBreakevenStart  = 80;             // Breakeven Activation (points)
input double   InpBreakevenOffset = 10;             // Breakeven Offset (points)

input group "=== SCALPING PARAMETERS ==="
input ENUM_ENTRY_MODE InpEntryMode= ENTRY_AGGRESSIVE;// Entry Aggressiveness
input int      InpFastEMA         = 8;              // Fast EMA Period
input int      InpSlowEMA         = 21;             // Slow EMA Period
input int      InpSignalEMA       = 5;              // Signal EMA Period
input int      InpRSIPeriod       = 14;             // RSI Period
input int      InpRSIOverbought   = 70;             // RSI Overbought Level
input int      InpRSIOversold     = 30;             // RSI Oversold Level
input int      InpATRPeriod       = 14;             // ATR Period
input int      InpBBPeriod        = 20;             // Bollinger Bands Period
input double   InpBBDeviation     = 2.0;            // Bollinger Bands Deviation
input int      InpMACDFast        = 12;             // MACD Fast Period
input int      InpMACDSlow        = 26;             // MACD Slow Period
input int      InpMACDSignal      = 9;              // MACD Signal Period
input int      InpStochK          = 14;             // Stochastic %K Period
input int      InpStochD          = 3;              // Stochastic %D Period
input int      InpStochSlowing    = 3;              // Stochastic Slowing
input int      InpCCIPeriod       = 20;             // CCI Period
input int      InpADXPeriod       = 14;             // ADX Period
input double   InpADXMinStrength  = 20.0;           // ADX Minimum Trend Strength

input group "=== ORDER FLOW ANALYSIS ==="
input int      InpTickBufferSize  = 500;            // Tick Buffer Size
input double   InpVolImbalanceThreshold = 1.5;      // Volume Imbalance Threshold
input int      InpDeltaLookback   = 100;            // Delta Lookback Period
input bool     InpUseSpreadFilter = true;           // Use Spread Filter
input int      InpMaxSpread       = 30;             // Max Spread (points)

input group "=== QUANTITATIVE ANALYSIS ==="
input int      InpZScorePeriod    = 50;             // Z-Score Period
input double   InpZScoreThreshold = 2.0;            // Z-Score Entry Threshold
input int      InpHurstPeriod     = 100;            // Hurst Exponent Period
input int      InpCorrelationPeriod= 30;            // Correlation Period
input bool     InpUseRegression   = true;           // Use Linear Regression
input int      InpRegressionPeriod= 30;             // Regression Period

input group "=== SELF-CORRECTION ==="
input bool     InpSelfCorrect     = true;           // Enable Self-Correction
input int      InpPerformanceWindow= 20;            // Performance Window (trades)
input double   InpMinWinRate      = 0.40;           // Minimum Win Rate to Continue
input double   InpAdaptSpeed      = 0.1;            // Adaptation Speed (0.01-1.0)

input group "=== DISPLAY ==="
input bool     InpShowDashboard   = true;           // Show Dashboard on Chart
input bool     InpShowTradesOnChart= true;          // Show Open Trades on Chart
input color    InpBuyColor        = clrDodgerBlue;  // Buy Trade Color
input color    InpSellColor       = clrOrangeRed;   // Sell Trade Color
input color    InpDashBgColor     = C'20,20,35';    // Dashboard Background
input color    InpDashTextColor   = clrWhite;       // Dashboard Text Color
input int      InpDashFontSize    = 9;              // Dashboard Font Size

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;
COrderInfo     ordInfo;
CSymbolInfo    symInfo;
CAccountInfo   accInfo;

// Indicator handles
int h_FastEMA, h_SlowEMA, h_SignalEMA;
int h_RSI, h_ATR, h_BB, h_MACD;
int h_Stoch, h_CCI, h_ADX;
int h_Ichimoku, h_SAR;
int h_Volume;

// Order flow
MqlTick tickBuffer[];
double  cumulativeDelta;
double  buyVolume, sellVolume;
double  bidDepth, askDepth;

// Performance tracking
double  tradeResults[];
int     totalTrades, winTrades, lossTrades;
double  totalProfit, totalLoss;
double  currentWinRate;
double  dailyPnL;
datetime lastTradeDay;

// Self-correction parameters
double  adaptiveRiskMultiplier;
double  adaptiveEntryThreshold;
int     consecutiveLosses;
int     consecutiveWins;
double  avgWin, avgLoss;

// State variables
bool    isInitialized;
double  startBalance;
double  peakBalance;
double  currentDrawdown;
string  eaState;

// Dashboard objects
string  dashPrefix = "GS_";

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Validate symbol
   if(!SymbolSelect(InpSymbol, true))
     {
      // Try alternative names
      string altNames[] = {"XAUUSD", "Gold.i#", "GOLD", "XAUUSDm", "XAUUSD.i"};
      bool found = false;
      for(int i = 0; i < ArraySize(altNames); i++)
        {
         if(SymbolSelect(altNames[i], true))
           {
            Print("Symbol found: ", altNames[i]);
            found = true;
            break;
           }
        }
      if(!found)
        {
         Print("WARNING: Preferred symbol not found, using current chart symbol");
        }
     }

   symInfo.Name(Symbol());
   symInfo.Refresh();

   // Setup trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   // Initialize indicator handles
   if(!InitIndicators())
     {
      Print("ERROR: Failed to initialize indicators!");
      return INIT_FAILED;
     }

   // Initialize tracking arrays
   ArrayResize(tradeResults, 0);
   ArrayResize(tickBuffer, InpTickBufferSize);

   // Initialize state
   startBalance     = accInfo.Balance();
   peakBalance      = startBalance;
   dailyPnL         = 0;
   lastTradeDay     = 0;
   adaptiveRiskMultiplier = 1.0;
   adaptiveEntryThreshold = 0.5;
   consecutiveLosses = 0;
   consecutiveWins   = 0;
   totalTrades = 0;
   winTrades   = 0;
   lossTrades  = 0;
   totalProfit = 0;
   totalLoss   = 0;
   eaState     = "ACTIVE";
   cumulativeDelta = 0;
   isInitialized   = true;

   // Create dashboard
   if(InpShowDashboard)
      CreateDashboard();

   Print("GoldStrike Scalper v3.0 initialized successfully!");
   Print("Account Balance: ", DoubleToString(startBalance, 2));
   Print("Leverage: 1:", accInfo.Leverage());
   Print("Symbol: ", Symbol(), " | Point: ", symInfo.Point());

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Release indicator handles
   IndicatorRelease(h_FastEMA);
   IndicatorRelease(h_SlowEMA);
   IndicatorRelease(h_SignalEMA);
   IndicatorRelease(h_RSI);
   IndicatorRelease(h_ATR);
   IndicatorRelease(h_BB);
   IndicatorRelease(h_MACD);
   IndicatorRelease(h_Stoch);
   IndicatorRelease(h_CCI);
   IndicatorRelease(h_ADX);
   if(h_Ichimoku != INVALID_HANDLE) IndicatorRelease(h_Ichimoku);
   if(h_SAR != INVALID_HANDLE)      IndicatorRelease(h_SAR);

   // Clean dashboard
   DeleteDashboard();

   Print("GoldStrike Scalper deinitialized. Reason: ", reason);
  }

//+------------------------------------------------------------------+
//| Initialize all indicators                                         |
//+------------------------------------------------------------------+
bool InitIndicators()
  {
   h_FastEMA   = iMA(Symbol(), InpTimeframe, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   h_SlowEMA   = iMA(Symbol(), InpTimeframe, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   h_SignalEMA = iMA(Symbol(), InpTimeframe, InpSignalEMA, 0, MODE_EMA, PRICE_CLOSE);
   h_RSI       = iRSI(Symbol(), InpTimeframe, InpRSIPeriod, PRICE_CLOSE);
   h_ATR       = iATR(Symbol(), InpTimeframe, InpATRPeriod);
   h_BB        = iBands(Symbol(), InpTimeframe, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   h_MACD      = iMACD(Symbol(), InpTimeframe, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   h_Stoch     = iStochastic(Symbol(), InpTimeframe, InpStochK, InpStochD, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
   h_CCI       = iCCI(Symbol(), InpTimeframe, InpCCIPeriod, PRICE_TYPICAL);
   h_ADX       = iADX(Symbol(), InpTimeframe, InpADXPeriod);
   h_Ichimoku  = iIchimoku(Symbol(), InpTimeframe, 9, 26, 52);
   h_SAR       = iSAR(Symbol(), InpTimeframe, 0.02, 0.2);

   if(h_FastEMA == INVALID_HANDLE || h_SlowEMA == INVALID_HANDLE ||
      h_RSI == INVALID_HANDLE || h_ATR == INVALID_HANDLE ||
      h_BB == INVALID_HANDLE || h_MACD == INVALID_HANDLE ||
      h_Stoch == INVALID_HANDLE || h_CCI == INVALID_HANDLE ||
      h_ADX == INVALID_HANDLE)
     {
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!isInitialized) return;

   // Refresh symbol info
   symInfo.Refresh();

   // Update order flow data
   UpdateOrderFlow();

   // Check time filter
   if(!IsTradeTimeAllowed())
     {
      eaState = "OUTSIDE HOURS";
      if(InpShowDashboard) UpdateDashboard();
      return;
     }

   // Check daily reset
   CheckDailyReset();

   // Check drawdown limits
   if(!CheckDrawdownLimits())
     {
      eaState = "DD LIMIT HIT";
      if(InpShowDashboard) UpdateDashboard();
      return;
     }

   // Check spread filter
   if(InpUseSpreadFilter && (int)symInfo.Spread() > InpMaxSpread)
     {
      eaState = "HIGH SPREAD";
      if(InpShowDashboard) UpdateDashboard();
      return;
     }

   eaState = "ACTIVE";

   // Manage existing positions
   ManageOpenTrades();

   // Only check for new signals on new bar
   static datetime lastBar = 0;
   datetime currentBar = iTime(Symbol(), InpTimeframe, 0);
   if(currentBar == lastBar)
     {
      if(InpShowDashboard) UpdateDashboard();
      if(InpShowTradesOnChart) DrawTradesOnChart();
      return;
     }
   lastBar = currentBar;

   // Self-correction analysis
   if(InpSelfCorrect)
      PerformSelfCorrection();

   // Generate trading signals
   int signal = GenerateSignal();

   // Execute trade if signal is valid
   if(signal != 0 && CountOpenPositions() < InpMaxOpenTrades)
     {
      ExecuteTrade(signal);
     }

   // Update display
   if(InpShowDashboard) UpdateDashboard();
   if(InpShowTradesOnChart) DrawTradesOnChart();
  }

//+------------------------------------------------------------------+
//| OnTrade event - track results                                     |
//+------------------------------------------------------------------+
void OnTrade()
  {
   // Check for newly closed trades
   static int lastDeals = 0;

   HistorySelect(0, TimeCurrent());
   int totalDeals = HistoryDealsTotal();

   if(totalDeals > lastDeals)
     {
      for(int i = lastDeals; i < totalDeals; i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket > 0)
           {
            long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);

            if(magic == InpMagicNumber && entry == DEAL_ENTRY_OUT)
              {
               double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                               HistoryDealGetDouble(ticket, DEAL_SWAP) +
                               HistoryDealGetDouble(ticket, DEAL_COMMISSION);

               int size = ArraySize(tradeResults);
               ArrayResize(tradeResults, size + 1);
               tradeResults[size] = profit;

               totalTrades++;
               dailyPnL += profit;

               if(profit >= 0)
                 {
                  winTrades++;
                  totalProfit += profit;
                  consecutiveWins++;
                  consecutiveLosses = 0;
                 }
               else
                 {
                  lossTrades++;
                  totalLoss += MathAbs(profit);
                  consecutiveLosses++;
                  consecutiveWins = 0;
                 }

               currentWinRate = (totalTrades > 0) ? (double)winTrades / totalTrades : 0;
               avgWin  = (winTrades > 0) ? totalProfit / winTrades : 0;
               avgLoss = (lossTrades > 0) ? totalLoss / lossTrades : 0;
              }
           }
        }
      lastDeals = totalDeals;
     }
  }

//+------------------------------------------------------------------+
//| ORDER FLOW ANALYSIS                                               |
//+------------------------------------------------------------------+
void UpdateOrderFlow()
  {
   MqlTick lastTick;
   if(!SymbolInfoTick(Symbol(), lastTick)) return;

   // Calculate tick-based order flow
   static MqlTick prevTick;
   static bool hasPrev = false;

   if(hasPrev)
     {
      double tickDelta = 0;

      // Classify tick as buy or sell
      if(lastTick.last >= lastTick.ask)
        {
         // Aggressive buyer
         buyVolume += (double)lastTick.volume;
         tickDelta = (double)lastTick.volume;
        }
      else if(lastTick.last <= lastTick.bid)
        {
         // Aggressive seller
         sellVolume += (double)lastTick.volume;
         tickDelta = -(double)lastTick.volume;
        }
      else
        {
         // Mid-price: classify by direction
         if(lastTick.last > prevTick.last)
           {
            buyVolume += (double)lastTick.volume;
            tickDelta = (double)lastTick.volume;
           }
         else if(lastTick.last < prevTick.last)
           {
            sellVolume += (double)lastTick.volume;
            tickDelta = -(double)lastTick.volume;
           }
        }

      cumulativeDelta += tickDelta;
     }

   prevTick = lastTick;
   hasPrev = true;
  }

//+------------------------------------------------------------------+
//| Calculate Volume Imbalance                                        |
//+------------------------------------------------------------------+
double GetVolumeImbalance()
  {
   double totalVol = buyVolume + sellVolume;
   if(totalVol == 0) return 0;

   double imbalance = (buyVolume - sellVolume) / totalVol;
   return imbalance; // +1 = all buying, -1 = all selling
  }

//+------------------------------------------------------------------+
//| Calculate Order Flow Score (-1 to +1)                             |
//+------------------------------------------------------------------+
double GetOrderFlowScore()
  {
   double score = 0;

   // Volume imbalance component
   double imbalance = GetVolumeImbalance();
   score += imbalance * 0.4;

   // Delta divergence component
   double price = symInfo.Last();
   static double prevPrice = 0;
   static double prevDelta = 0;

   if(prevPrice > 0)
     {
      double priceChange = price - prevPrice;
      double deltaChange = cumulativeDelta - prevDelta;

      // Bullish divergence: price down, delta up
      if(priceChange < 0 && deltaChange > 0)
         score += 0.3;
      // Bearish divergence: price up, delta down
      else if(priceChange > 0 && deltaChange < 0)
         score -= 0.3;
      // Confirmation
      else if(priceChange > 0 && deltaChange > 0)
         score += 0.2;
      else if(priceChange < 0 && deltaChange < 0)
         score -= 0.2;
     }

   prevPrice = price;
   prevDelta = cumulativeDelta;

   // Bid-ask pressure
   double spread = symInfo.Ask() - symInfo.Bid();
   if(spread > 0)
     {
      double midPrice = (symInfo.Ask() + symInfo.Bid()) / 2.0;
      double lastPrice = symInfo.Last();
      double pressure = (lastPrice - midPrice) / (spread / 2.0);
      score += MathMax(-0.3, MathMin(0.3, pressure * 0.3));
     }

   return MathMax(-1.0, MathMin(1.0, score));
  }

//+------------------------------------------------------------------+
//| QUANTITATIVE ANALYSIS                                             |
//+------------------------------------------------------------------+

//--- Z-Score Calculation
double CalculateZScore(int period)
  {
   double closes[];
   if(CopyClose(Symbol(), InpTimeframe, 0, period, closes) < period)
      return 0;

   double sum = 0, sumSq = 0;
   for(int i = 0; i < period; i++)
     {
      sum += closes[i];
      sumSq += closes[i] * closes[i];
     }

   double mean = sum / period;
   double variance = (sumSq / period) - (mean * mean);
   double stdDev = MathSqrt(MathMax(variance, 0));

   if(stdDev == 0) return 0;

   return (closes[period - 1] - mean) / stdDev;
  }

//--- Hurst Exponent (R/S Analysis)
double CalculateHurstExponent(int period)
  {
   double closes[];
   if(CopyClose(Symbol(), InpTimeframe, 0, period, closes) < period)
      return 0.5;

   // Calculate returns
   double returns[];
   ArrayResize(returns, period - 1);
   for(int i = 1; i < period; i++)
      returns[i-1] = MathLog(closes[i] / closes[i-1]);

   int n = ArraySize(returns);
   if(n < 10) return 0.5;

   // Calculate R/S for different sub-periods
   double logRS[], logN[];
   int sizes[] = {10, 20, 30, 50};
   int count = 0;

   ArrayResize(logRS, 4);
   ArrayResize(logN, 4);

   for(int s = 0; s < 4; s++)
     {
      int subSize = sizes[s];
      if(subSize >= n) break;

      int numSubs = n / subSize;
      double rsSum = 0;

      for(int j = 0; j < numSubs; j++)
        {
         int start = j * subSize;

         // Mean of sub-period
         double subMean = 0;
         for(int k = start; k < start + subSize; k++)
            subMean += returns[k];
         subMean /= subSize;

         // Cumulative deviation and std dev
         double cumDev = 0, maxDev = -1e10, minDev = 1e10;
         double sumDev2 = 0;
         for(int k = start; k < start + subSize; k++)
           {
            cumDev += (returns[k] - subMean);
            if(cumDev > maxDev) maxDev = cumDev;
            if(cumDev < minDev) minDev = cumDev;
            sumDev2 += (returns[k] - subMean) * (returns[k] - subMean);
           }

         double range = maxDev - minDev;
         double stdDev = MathSqrt(sumDev2 / subSize);

         if(stdDev > 0)
            rsSum += range / stdDev;
        }

      if(numSubs > 0)
        {
         logRS[count] = MathLog(rsSum / numSubs);
         logN[count] = MathLog((double)subSize);
         count++;
        }
     }

   if(count < 2) return 0.5;

   // Linear regression to find H
   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   for(int i = 0; i < count; i++)
     {
      sumX += logN[i];
      sumY += logRS[i];
      sumXY += logN[i] * logRS[i];
      sumX2 += logN[i] * logN[i];
     }

   double denominator = count * sumX2 - sumX * sumX;
   if(denominator == 0) return 0.5;

   double H = (count * sumXY - sumX * sumY) / denominator;
   return MathMax(0.0, MathMin(1.0, H));
  }

//--- Linear Regression Slope
double CalculateRegressionSlope(int period)
  {
   double closes[];
   if(CopyClose(Symbol(), InpTimeframe, 0, period, closes) < period)
      return 0;

   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   for(int i = 0; i < period; i++)
     {
      sumX += i;
      sumY += closes[i];
      sumXY += i * closes[i];
      sumX2 += (double)i * i;
     }

   double denominator = period * sumX2 - sumX * sumX;
   if(denominator == 0) return 0;

   double slope = (period * sumXY - sumX * sumY) / denominator;
   return slope;
  }

//--- Regression Channel Deviation
double CalculateRegressionDeviation(int period)
  {
   double closes[];
   if(CopyClose(Symbol(), InpTimeframe, 0, period, closes) < period)
      return 0;

   double slope = CalculateRegressionSlope(period);

   // Calculate intercept
   double sumX = 0, sumY = 0;
   for(int i = 0; i < period; i++)
     {
      sumX += i;
      sumY += closes[i];
     }
   double intercept = (sumY - slope * sumX) / period;

   // Calculate standard deviation from regression line
   double sumDev2 = 0;
   for(int i = 0; i < period; i++)
     {
      double predicted = intercept + slope * i;
      double dev = closes[i] - predicted;
      sumDev2 += dev * dev;
     }

   double stdDev = MathSqrt(sumDev2 / period);
   double lastPredicted = intercept + slope * (period - 1);

   if(stdDev == 0) return 0;
   return (closes[period-1] - lastPredicted) / stdDev;
  }

//--- Volatility Ratio (current vs historical)
double CalculateVolatilityRatio(int shortPeriod, int longPeriod)
  {
   double atrShort[], atrLong[];

   if(CopyBuffer(h_ATR, 0, 0, longPeriod, atrLong) < longPeriod)
      return 1.0;

   double avgShort = 0, avgLong = 0;
   for(int i = longPeriod - shortPeriod; i < longPeriod; i++)
      avgShort += atrLong[i];
   avgShort /= shortPeriod;

   for(int i = 0; i < longPeriod; i++)
      avgLong += atrLong[i];
   avgLong /= longPeriod;

   if(avgLong == 0) return 1.0;
   return avgShort / avgLong;
  }

//+------------------------------------------------------------------+
//| SIGNAL GENERATION (Multi-Factor Scoring)                          |
//+------------------------------------------------------------------+
int GenerateSignal()
  {
   double score = 0;  // -100 to +100
   int factors = 0;

   //=== 1. EMA CROSSOVER (Weight: 15) ===
   double fastEMA[], slowEMA[], sigEMA[];
   if(CopyBuffer(h_FastEMA, 0, 0, 3, fastEMA) >= 3 &&
      CopyBuffer(h_SlowEMA, 0, 0, 3, slowEMA) >= 3 &&
      CopyBuffer(h_SignalEMA, 0, 0, 3, sigEMA) >= 3)
     {
      if(fastEMA[2] > slowEMA[2] && fastEMA[1] <= slowEMA[1])
         score += 15;
      else if(fastEMA[2] < slowEMA[2] && fastEMA[1] >= slowEMA[1])
         score -= 15;
      else if(fastEMA[2] > slowEMA[2])
         score += 7;
      else
         score -= 7;
      factors++;
     }

   //=== 2. RSI (Weight: 12) ===
   double rsi[];
   if(CopyBuffer(h_RSI, 0, 0, 3, rsi) >= 3)
     {
      if(rsi[2] < InpRSIOversold)
         score += 12;
      else if(rsi[2] > InpRSIOverbought)
         score -= 12;
      else if(rsi[2] < 45)
         score += 4;
      else if(rsi[2] > 55)
         score -= 4;

      // RSI divergence detection
      double close1 = iClose(Symbol(), InpTimeframe, 1);
      double close2 = iClose(Symbol(), InpTimeframe, 2);
      if(close1 < close2 && rsi[2] > rsi[1])
         score += 6; // Bullish divergence
      if(close1 > close2 && rsi[2] < rsi[1])
         score -= 6; // Bearish divergence
      factors++;
     }

   //=== 3. BOLLINGER BANDS (Weight: 12) ===
   double bbUpper[], bbMiddle[], bbLower[];
   if(CopyBuffer(h_BB, 1, 0, 2, bbUpper) >= 2 &&
      CopyBuffer(h_BB, 0, 0, 2, bbMiddle) >= 2 &&
      CopyBuffer(h_BB, 2, 0, 2, bbLower) >= 2)
     {
      double lastClose = iClose(Symbol(), InpTimeframe, 0);
      double bbWidth = (bbUpper[1] - bbLower[1]) / bbMiddle[1];

      if(lastClose <= bbLower[1])
         score += 12;
      else if(lastClose >= bbUpper[1])
         score -= 12;

      // Squeeze detection (low volatility = breakout imminent)
      if(bbWidth < 0.005)
        {
         // Direction based on price relative to middle
         if(lastClose > bbMiddle[1])
            score += 5;
         else
            score -= 5;
        }
      factors++;
     }

   //=== 4. MACD (Weight: 12) ===
   double macdMain[], macdSignal[], macdHist[];
   if(CopyBuffer(h_MACD, 0, 0, 3, macdMain) >= 3 &&
      CopyBuffer(h_MACD, 1, 0, 3, macdSignal) >= 3)
     {
      double hist2 = macdMain[2] - macdSignal[2];
      double hist1 = macdMain[1] - macdSignal[1];

      if(hist2 > 0 && hist1 <= 0)
         score += 12; // Bullish crossover
      else if(hist2 < 0 && hist1 >= 0)
         score -= 12; // Bearish crossover
      else if(hist2 > hist1 && hist2 > 0)
         score += 5;  // Increasing bullish momentum
      else if(hist2 < hist1 && hist2 < 0)
         score -= 5;  // Increasing bearish momentum
      factors++;
     }

   //=== 5. STOCHASTIC (Weight: 10) ===
   double stochK[], stochD[];
   if(CopyBuffer(h_Stoch, 0, 0, 3, stochK) >= 3 &&
      CopyBuffer(h_Stoch, 1, 0, 3, stochD) >= 3)
     {
      if(stochK[2] < 20 && stochK[2] > stochD[2] && stochK[1] <= stochD[1])
         score += 10;
      else if(stochK[2] > 80 && stochK[2] < stochD[2] && stochK[1] >= stochD[1])
         score -= 10;
      else if(stochK[2] < 30)
         score += 4;
      else if(stochK[2] > 70)
         score -= 4;
      factors++;
     }

   //=== 6. CCI (Weight: 8) ===
   double cci[];
   if(CopyBuffer(h_CCI, 0, 0, 2, cci) >= 2)
     {
      if(cci[1] < -100)
         score += 8;
      else if(cci[1] > 100)
         score -= 8;
      factors++;
     }

   //=== 7. ADX Trend Strength (Weight: 8) ===
   double adxMain[], adxPlus[], adxMinus[];
   if(CopyBuffer(h_ADX, 0, 0, 2, adxMain) >= 2 &&
      CopyBuffer(h_ADX, 1, 0, 2, adxPlus) >= 2 &&
      CopyBuffer(h_ADX, 2, 0, 2, adxMinus) >= 2)
     {
      if(adxMain[1] >= InpADXMinStrength)
        {
         if(adxPlus[1] > adxMinus[1])
            score += 8;
         else
            score -= 8;
        }
      factors++;
     }

   //=== 8. ORDER FLOW (Weight: 15) ===
   double ofScore = GetOrderFlowScore();
   score += ofScore * 15;
   factors++;

   //=== 9. Z-SCORE (Weight: 10) ===
   double zScore = CalculateZScore(InpZScorePeriod);
   if(MathAbs(zScore) > InpZScoreThreshold)
     {
      // Mean reversion signal
      if(zScore > InpZScoreThreshold)
         score -= 10; // Overbought -> sell
      else if(zScore < -InpZScoreThreshold)
         score += 10; // Oversold -> buy
     }
   factors++;

   //=== 10. HURST EXPONENT (Weight: modifier) ===
   double hurst = CalculateHurstExponent(InpHurstPeriod);
   // H > 0.5: trending, amplify trend signals
   // H < 0.5: mean-reverting, amplify reversal signals
   if(hurst > 0.6)
      score *= 1.2; // Amplify trend-following signals
   else if(hurst < 0.4)
      score *= 0.8; // Dampen trend signals (mean reversion)

   //=== 11. LINEAR REGRESSION (Weight: 8) ===
   if(InpUseRegression)
     {
      double regSlope = CalculateRegressionSlope(InpRegressionPeriod);
      double regDev = CalculateRegressionDeviation(InpRegressionPeriod);

      if(regSlope > 0 && regDev < -1.5)
         score += 8; // Uptrend but oversold from regression
      else if(regSlope < 0 && regDev > 1.5)
         score -= 8; // Downtrend but overbought from regression
      else if(regSlope > 0)
         score += 3;
      else
         score -= 3;
      factors++;
     }

   //=== 12. SAR CONFIRMATION ===
   double sar[];
   if(h_SAR != INVALID_HANDLE && CopyBuffer(h_SAR, 0, 0, 2, sar) >= 2)
     {
      double lastClose = iClose(Symbol(), InpTimeframe, 0);
      if(lastClose > sar[1])
         score += 5;
      else
         score -= 5;
     }

   //=== 13. VOLATILITY FILTER ===
   double volRatio = CalculateVolatilityRatio(5, 50);
   if(volRatio > 2.0)
     {
      // Very high volatility - reduce position but allow trading
      score *= 0.7;
     }
   else if(volRatio < 0.5)
     {
      // Very low volatility - might squeeze, slightly boost
      score *= 1.1;
     }

   //=== APPLY SELF-CORRECTION THRESHOLD ===
   double threshold = 25.0;

   switch(InpEntryMode)
     {
      case ENTRY_AGGRESSIVE:   threshold = 20.0; break;
      case ENTRY_MODERATE:     threshold = 35.0; break;
      case ENTRY_CONSERVATIVE: threshold = 50.0; break;
     }

   // Adjust threshold based on self-correction
   threshold *= adaptiveEntryThreshold / 0.5;
   threshold = MathMax(15.0, MathMin(60.0, threshold));

   // Generate signal
   if(score >= threshold) return 1;  // BUY
   if(score <= -threshold) return -1; // SELL

   return 0; // NO SIGNAL
  }

//+------------------------------------------------------------------+
//| EXECUTE TRADE                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal)
  {
   double lotSize = CalculateLotSize(signal);

   double sl = 0, tp = 0;
   double ask = symInfo.Ask();
   double bid = symInfo.Bid();
   double point = symInfo.Point();

   // Calculate SL and TP
   double slPoints, tpPoints;

   if(InpUseATRSLTP)
     {
      double atr[];
      if(CopyBuffer(h_ATR, 0, 0, 2, atr) >= 2)
        {
         slPoints = atr[1] * InpATRSLMultiplier / point;
         tpPoints = atr[1] * InpATRTPMultiplier / point;
        }
      else
        {
         slPoints = InpDefaultSL;
         tpPoints = InpDefaultTP;
        }
     }
   else
     {
      slPoints = InpDefaultSL;
      tpPoints = InpDefaultTP;
     }

   // Ensure minimum SL/TP
   slPoints = MathMax(slPoints, 50);
   tpPoints = MathMax(tpPoints, 50);

   if(signal == 1) // BUY
     {
      sl = ask - slPoints * point;
      tp = ask + tpPoints * point;

      sl = NormalizeDouble(sl, symInfo.Digits());
      tp = NormalizeDouble(tp, symInfo.Digits());

      if(!trade.Buy(lotSize, Symbol(), ask, sl, tp, InpTradeComment))
        {
         Print("BUY order failed: ", trade.ResultRetcodeDescription());
        }
      else
        {
         Print("BUY ", lotSize, " lots at ", ask, " SL:", sl, " TP:", tp);
        }
     }
   else if(signal == -1) // SELL
     {
      sl = bid + slPoints * point;
      tp = bid - tpPoints * point;

      sl = NormalizeDouble(sl, symInfo.Digits());
      tp = NormalizeDouble(tp, symInfo.Digits());

      if(!trade.Sell(lotSize, Symbol(), bid, sl, tp, InpTradeComment))
        {
         Print("SELL order failed: ", trade.ResultRetcodeDescription());
        }
      else
        {
         Print("SELL ", lotSize, " lots at ", bid, " SL:", sl, " TP:", tp);
        }
     }
  }

//+------------------------------------------------------------------+
//| DYNAMIC LOT SIZE CALCULATION                                      |
//+------------------------------------------------------------------+
double CalculateLotSize(int signal)
  {
   double lotSize = InpFixedLot;
   double balance = accInfo.Balance();

   switch(InpRiskMode)
     {
      case RISK_FIXED:
         lotSize = InpFixedLot;
         break;

      case RISK_PERCENT:
        {
         double atr[];
         double slPoints = InpDefaultSL;
         if(CopyBuffer(h_ATR, 0, 0, 2, atr) >= 2)
            slPoints = atr[1] * InpATRSLMultiplier / symInfo.Point();

         double tickValue = symInfo.TickValue();
         double tickSize  = symInfo.TickSize();

         if(tickValue > 0 && tickSize > 0)
           {
            double riskAmount = balance * InpRiskPercent / 100.0;
            double slValue = slPoints * (tickValue / (tickSize / symInfo.Point()));
            if(slValue > 0)
               lotSize = riskAmount / slValue;
           }
        }
         break;

      case RISK_KELLY:
        {
         // Kelly Criterion: f* = (bp - q) / b
         // b = avg win / avg loss, p = win probability, q = 1 - p
         if(totalTrades >= 10)
           {
            double p = currentWinRate;
            double q = 1.0 - p;
            double b = (avgLoss > 0) ? avgWin / avgLoss : 1.0;

            double kelly = (b * p - q) / b;
            kelly = MathMax(0, MathMin(kelly, 0.25)); // Cap at 25%
            kelly *= 0.5; // Half-Kelly for safety

            double tickValue = symInfo.TickValue();
            if(tickValue > 0)
              {
               double riskAmount = balance * kelly;
               double slValue = InpDefaultSL * tickValue;
               if(slValue > 0)
                  lotSize = riskAmount / slValue;
              }
           }
        }
         break;

      case RISK_DYNAMIC:
        {
         // Dynamic: combines Kelly with volatility and streak adjustments
         double baseRisk = InpRiskPercent / 100.0;

         // Adjust for consecutive results
         if(consecutiveLosses > 0)
            baseRisk *= MathMax(0.3, 1.0 - consecutiveLosses * 0.15);
         if(consecutiveWins > 2)
            baseRisk *= MathMin(1.5, 1.0 + (consecutiveWins - 2) * 0.1);

         // Apply Kelly if enough data
         if(totalTrades >= 10)
           {
            double p = currentWinRate;
            double b = (avgLoss > 0) ? avgWin / avgLoss : 1.0;
            double kelly = (b * p - (1.0 - p)) / b;
            kelly = MathMax(0.005, MathMin(kelly, 0.15));

            baseRisk = baseRisk * 0.6 + kelly * 0.4; // Blend
           }

         // Volatility adjustment
         double volRatio = CalculateVolatilityRatio(5, 50);
         if(volRatio > 1.5)
            baseRisk *= 0.7;
         else if(volRatio < 0.7)
            baseRisk *= 1.2;

         // Apply adaptive risk multiplier from self-correction
         baseRisk *= adaptiveRiskMultiplier;

         double riskAmount = balance * baseRisk;

         double atr[];
         double slPoints = InpDefaultSL;
         if(CopyBuffer(h_ATR, 0, 0, 2, atr) >= 2)
            slPoints = atr[1] * InpATRSLMultiplier / symInfo.Point();

         double tickValue = symInfo.TickValue();
         double tickSize  = symInfo.TickSize();
         if(tickValue > 0 && tickSize > 0)
           {
            double slValue = slPoints * (tickValue / (tickSize / symInfo.Point()));
            if(slValue > 0)
               lotSize = riskAmount / slValue;
           }
        }
         break;
     }

   // Normalize and clamp lot size
   double minLot  = symInfo.LotsMin();
   double maxLot  = MathMin(symInfo.LotsMax(), InpMaxLotSize);
   double lotStep = symInfo.LotsStep();

   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = NormalizeDouble(lotSize, 2);

   return lotSize;
  }

//+------------------------------------------------------------------+
//| MANAGE OPEN TRADES                                                |
//+------------------------------------------------------------------+
void ManageOpenTrades()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != InpMagicNumber) continue;
      if(posInfo.Symbol() != Symbol()) continue;

      double openPrice = posInfo.PriceOpen();
      double currentPrice = posInfo.PriceCurrent();
      double sl = posInfo.StopLoss();
      double tp = posInfo.TakeProfit();
      double point = symInfo.Point();
      ulong ticket = posInfo.Ticket();

      //--- Breakeven Management
      if(InpUseBreakeven)
        {
         if(posInfo.PositionType() == POSITION_TYPE_BUY)
           {
            double profitPoints = (currentPrice - openPrice) / point;
            if(profitPoints >= InpBreakevenStart && sl < openPrice)
              {
               double newSL = openPrice + InpBreakevenOffset * point;
               newSL = NormalizeDouble(newSL, symInfo.Digits());
               trade.PositionModify(ticket, newSL, tp);
              }
           }
         else if(posInfo.PositionType() == POSITION_TYPE_SELL)
           {
            double profitPoints = (openPrice - currentPrice) / point;
            if(profitPoints >= InpBreakevenStart && (sl > openPrice || sl == 0))
              {
               double newSL = openPrice - InpBreakevenOffset * point;
               newSL = NormalizeDouble(newSL, symInfo.Digits());
               trade.PositionModify(ticket, newSL, tp);
              }
           }
        }

      //--- Trailing Stop Management
      if(InpUseTrailingStop)
        {
         if(posInfo.PositionType() == POSITION_TYPE_BUY)
           {
            double profitPoints = (currentPrice - openPrice) / point;
            if(profitPoints >= InpTrailingStart)
              {
               double newSL = currentPrice - InpTrailingStep * point;
               newSL = NormalizeDouble(newSL, symInfo.Digits());
               if(newSL > sl)
                  trade.PositionModify(ticket, newSL, tp);
              }
           }
         else if(posInfo.PositionType() == POSITION_TYPE_SELL)
           {
            double profitPoints = (openPrice - currentPrice) / point;
            if(profitPoints >= InpTrailingStart)
              {
               double newSL = currentPrice + InpTrailingStep * point;
               newSL = NormalizeDouble(newSL, symInfo.Digits());
               if(newSL < sl || sl == 0)
                  trade.PositionModify(ticket, newSL, tp);
              }
           }
        }

      //--- Partial Close at 70% of TP
      double tpDist = 0;
      if(posInfo.PositionType() == POSITION_TYPE_BUY && tp > 0)
         tpDist = (tp - openPrice);
      else if(posInfo.PositionType() == POSITION_TYPE_SELL && tp > 0)
         tpDist = (openPrice - tp);

      if(tpDist > 0)
        {
         double currentDist = 0;
         if(posInfo.PositionType() == POSITION_TYPE_BUY)
            currentDist = currentPrice - openPrice;
         else
            currentDist = openPrice - currentPrice;

         if(currentDist >= tpDist * 0.7 && posInfo.Volume() > symInfo.LotsMin() * 2)
           {
            double closeLot = NormalizeDouble(posInfo.Volume() * 0.5, 2);
            closeLot = MathMax(closeLot, symInfo.LotsMin());
            trade.PositionClosePartial(ticket, closeLot);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| SELF-CORRECTION ENGINE                                            |
//+------------------------------------------------------------------+
void PerformSelfCorrection()
  {
   int resultCount = ArraySize(tradeResults);
   if(resultCount < 5) return; // Need minimum data

   // Analyze recent performance window
   int windowSize = MathMin(InpPerformanceWindow, resultCount);
   int windowStart = resultCount - windowSize;

   double recentWins = 0, recentLosses = 0;
   double recentProfit = 0;

   for(int i = windowStart; i < resultCount; i++)
     {
      if(tradeResults[i] >= 0)
        {
         recentWins++;
         recentProfit += tradeResults[i];
        }
      else
        {
         recentLosses++;
         recentProfit += tradeResults[i];
        }
     }

   double recentWinRate = recentWins / windowSize;

   //--- Adjust Risk Multiplier
   if(recentWinRate > 0.65)
     {
      // Performing well - slightly increase risk
      adaptiveRiskMultiplier += InpAdaptSpeed * 0.5;
      adaptiveRiskMultiplier = MathMin(1.5, adaptiveRiskMultiplier);
     }
   else if(recentWinRate < InpMinWinRate)
     {
      // Performing poorly - reduce risk
      adaptiveRiskMultiplier -= InpAdaptSpeed;
      adaptiveRiskMultiplier = MathMax(0.3, adaptiveRiskMultiplier);
     }
   else
     {
      // Normal performance - drift toward 1.0
      adaptiveRiskMultiplier += (1.0 - adaptiveRiskMultiplier) * InpAdaptSpeed * 0.3;
     }

   //--- Adjust Entry Threshold
   if(recentProfit < 0 && windowSize >= 10)
     {
      // Losing period - be more selective
      adaptiveEntryThreshold += InpAdaptSpeed * 0.5;
      adaptiveEntryThreshold = MathMin(0.9, adaptiveEntryThreshold);
     }
   else if(recentWinRate > 0.6)
     {
      // Winning period - can be slightly more aggressive
      adaptiveEntryThreshold -= InpAdaptSpeed * 0.3;
      adaptiveEntryThreshold = MathMax(0.3, adaptiveEntryThreshold);
     }
   else
     {
      adaptiveEntryThreshold += (0.5 - adaptiveEntryThreshold) * InpAdaptSpeed * 0.2;
     }

   //--- Emergency Stop: If severely underperforming
   if(consecutiveLosses >= 7)
     {
      // Pause for a few bars
      adaptiveRiskMultiplier = 0.2;
      adaptiveEntryThreshold = 0.9;
      Print("SELF-CORRECTION: Emergency mode - 7+ consecutive losses");
     }
  }

//+------------------------------------------------------------------+
//| TIME FILTER                                                       |
//+------------------------------------------------------------------+
bool IsTradeTimeAllowed()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // Day of week filter
   switch(dt.day_of_week)
     {
      case 0: return false; // Sunday
      case 1: if(!InpTradeMonday) return false; break;
      case 2: if(!InpTradeTuesday) return false; break;
      case 3: if(!InpTradeWednesday) return false; break;
      case 4: if(!InpTradeThursday) return false; break;
      case 5: if(!InpTradeFriday) return false; break;
      case 6: return false; // Saturday
     }

   // Hour filter
   if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| DRAWDOWN CHECK                                                    |
//+------------------------------------------------------------------+
bool CheckDrawdownLimits()
  {
   double balance = accInfo.Balance();
   double equity  = accInfo.Equity();

   // Update peak balance
   if(balance > peakBalance)
      peakBalance = balance;

   // Calculate current drawdown
   if(peakBalance > 0)
      currentDrawdown = (peakBalance - equity) / peakBalance * 100.0;

   // Check max drawdown
   if(currentDrawdown >= InpMaxDrawdownPct)
     {
      Print("MAX DRAWDOWN REACHED: ", DoubleToString(currentDrawdown, 2), "%");
      return false;
     }

   // Check daily loss limit
   if(dailyPnL < 0 && MathAbs(dailyPnL) >= balance * InpMaxDailyLoss / 100.0)
     {
      Print("MAX DAILY LOSS REACHED: ", DoubleToString(dailyPnL, 2));
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| DAILY RESET                                                       |
//+------------------------------------------------------------------+
void CheckDailyReset()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(IntegerToString(dt.year) + "." +
                                  IntegerToString(dt.mon) + "." +
                                  IntegerToString(dt.day));

   if(today != lastTradeDay)
     {
      dailyPnL = 0;
      buyVolume = 0;
      sellVolume = 0;
      cumulativeDelta = 0;
      lastTradeDay = today;
     }
  }

//+------------------------------------------------------------------+
//| COUNT OPEN POSITIONS                                              |
//+------------------------------------------------------------------+
int CountOpenPositions()
  {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(posInfo.SelectByIndex(i))
        {
         if(posInfo.Magic() == InpMagicNumber && posInfo.Symbol() == Symbol())
            count++;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| DRAW TRADES ON CHART                                              |
//+------------------------------------------------------------------+
void DrawTradesOnChart()
  {
   // Clean old trade objects
   string prefix = dashPrefix + "TRADE_";
   int totalObj = ObjectsTotal(0, 0);
   for(int i = totalObj - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
     }

   // Draw current positions
   int tradeIdx = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != InpMagicNumber) continue;
      if(posInfo.Symbol() != Symbol()) continue;

      double openPrice = posInfo.PriceOpen();
      double sl = posInfo.StopLoss();
      double tp = posInfo.TakeProfit();
      double profit = posInfo.Profit();
      double lots = posInfo.Volume();
      bool isBuy = (posInfo.PositionType() == POSITION_TYPE_BUY);
      datetime openTime = (datetime)posInfo.Time();

      color tradeColor = isBuy ? InpBuyColor : InpSellColor;
      string typeStr = isBuy ? "BUY" : "SELL";
      string profitStr = (profit >= 0) ? "+" + DoubleToString(profit, 2) : DoubleToString(profit, 2);

      // Entry line
      string entryName = prefix + "ENTRY_" + IntegerToString(tradeIdx);
      ObjectCreate(0, entryName, OBJ_HLINE, 0, 0, openPrice);
      ObjectSetInteger(0, entryName, OBJPROP_COLOR, tradeColor);
      ObjectSetInteger(0, entryName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, entryName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, entryName, OBJPROP_BACK, true);
      ObjectSetString(0, entryName, OBJPROP_TEXT,
         typeStr + " " + DoubleToString(lots, 2) + " @ " +
         DoubleToString(openPrice, (int)symInfo.Digits()) + " [" + profitStr + "$]");

      // SL line
      if(sl > 0)
        {
         string slName = prefix + "SL_" + IntegerToString(tradeIdx);
         ObjectCreate(0, slName, OBJ_HLINE, 0, 0, sl);
         ObjectSetInteger(0, slName, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, slName, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, slName, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, slName, OBJPROP_BACK, true);
         ObjectSetString(0, slName, OBJPROP_TEXT, "SL: " + DoubleToString(sl, (int)symInfo.Digits()));
        }

      // TP line
      if(tp > 0)
        {
         string tpName = prefix + "TP_" + IntegerToString(tradeIdx);
         ObjectCreate(0, tpName, OBJ_HLINE, 0, 0, tp);
         ObjectSetInteger(0, tpName, OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, tpName, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, tpName, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, tpName, OBJPROP_BACK, true);
         ObjectSetString(0, tpName, OBJPROP_TEXT, "TP: " + DoubleToString(tp, (int)symInfo.Digits()));
        }

      // Arrow at entry
      string arrowName = prefix + "ARROW_" + IntegerToString(tradeIdx);
      ObjectCreate(0, arrowName, OBJ_ARROW, 0, openTime, openPrice);
      ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, isBuy ? 233 : 234);
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, tradeColor);
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);

      // Profit label
      string labelName = prefix + "LABEL_" + IntegerToString(tradeIdx);
      ObjectCreate(0, labelName, OBJ_TEXT, 0, TimeCurrent(), openPrice);
      ObjectSetString(0, labelName, OBJPROP_TEXT, "  " + profitStr + "$ | " + typeStr + " " + DoubleToString(lots, 2));
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, profit >= 0 ? clrLime : clrRed);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);

      tradeIdx++;
     }
  }

//+------------------------------------------------------------------+
//| CREATE DASHBOARD                                                  |
//+------------------------------------------------------------------+
void CreateDashboard()
  {
   int x = 10, y = 30;
   int width = 320, height = 520;

   // Background rectangle
   CreateRect(dashPrefix + "BG", x, y, width, height, InpDashBgColor);

   // Title
   CreateLabel(dashPrefix + "TITLE", x + 10, y + 5, "⚡ GOLDSTRIKE SCALPER v3.0 ⚡",
               clrGold, 11, "Arial Bold");
   CreateLabel(dashPrefix + "LINE1", x + 10, y + 22, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
               clrDarkGoldenrod, 7, "Arial");
  }

//+------------------------------------------------------------------+
//| UPDATE DASHBOARD                                                  |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   int x = 10, y = 30;
   int lineHeight = 16;
   int startY = y + 40;
   int col1 = x + 10;
   int col2 = x + 160;
   int row = 0;

   double balance = accInfo.Balance();
   double equity  = accInfo.Equity();
   double freeMargin = accInfo.FreeMargin();
   double marginLevel = accInfo.MarginLevel();

   color stateColor = (eaState == "ACTIVE") ? clrLime :
                      (eaState == "OUTSIDE HOURS") ? clrYellow : clrRed;

   // Account Info Section
   UpdateLabel(dashPrefix + "S1", col1, startY + row * lineHeight, "── ACCOUNT ──", clrDodgerBlue); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Balance:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               "$" + DoubleToString(balance, 2), clrGold); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Equity:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               "$" + DoubleToString(equity, 2), equity >= balance ? clrLime : clrOrangeRed); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Free Margin:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               "$" + DoubleToString(freeMargin, 2), InpDashTextColor); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Margin Level:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               DoubleToString(marginLevel, 1) + "%", marginLevel > 500 ? clrLime : clrRed); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Profit Today:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               (dailyPnL >= 0 ? "+" : "") + DoubleToString(dailyPnL, 2), dailyPnL >= 0 ? clrLime : clrRed); row++;

   row++;
   // Trading Stats Section
   UpdateLabel(dashPrefix + "S2", col1, startY + row * lineHeight, "── PERFORMANCE ──", clrDodgerBlue); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Total Trades:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               IntegerToString(totalTrades), InpDashTextColor); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Win Rate:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               DoubleToString(currentWinRate * 100, 1) + "%", currentWinRate > 0.5 ? clrLime : clrOrangeRed); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Win/Loss:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               IntegerToString(winTrades) + "/" + IntegerToString(lossTrades), InpDashTextColor); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Open Positions:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               IntegerToString(CountOpenPositions()) + "/" + IntegerToString(InpMaxOpenTrades), clrYellow); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Drawdown:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               DoubleToString(currentDrawdown, 2) + "%", currentDrawdown < 5 ? clrLime : (currentDrawdown < 10 ? clrYellow : clrRed)); row++;

   row++;
   // Adaptive Parameters
   UpdateLabel(dashPrefix + "S3", col1, startY + row * lineHeight, "── SELF-CORRECTION ──", clrDodgerBlue); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Risk Multiplier:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               DoubleToString(adaptiveRiskMultiplier, 3), InpDashTextColor); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Entry Threshold:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               DoubleToString(adaptiveEntryThreshold, 3), InpDashTextColor); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Consec. Wins:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               IntegerToString(consecutiveWins), clrLime); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Consec. Losses:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               IntegerToString(consecutiveLosses), consecutiveLosses > 3 ? clrRed : InpDashTextColor); row++;

   row++;
   // Market Analysis
   UpdateLabel(dashPrefix + "S4", col1, startY + row * lineHeight, "── MARKET ANALYSIS ──", clrDodgerBlue); row++;

   double zs = CalculateZScore(InpZScorePeriod);
   double hurst = CalculateHurstExponent(InpHurstPeriod);
   double ofScore = GetOrderFlowScore();

   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Z-Score:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               DoubleToString(zs, 3), MathAbs(zs) > 2 ? clrYellow : InpDashTextColor); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Hurst Exp:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               DoubleToString(hurst, 3) + (hurst > 0.5 ? " [TREND]" : " [REVERT]"),
               hurst > 0.5 ? clrLime : clrOrangeRed); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Order Flow:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               DoubleToString(ofScore, 3) + (ofScore > 0.3 ? " BULLISH" : (ofScore < -0.3 ? " BEARISH" : " NEUTRAL")),
               ofScore > 0.3 ? clrLime : (ofScore < -0.3 ? clrRed : clrYellow)); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "Spread:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               IntegerToString((int)symInfo.Spread()) + " pts",
               (int)symInfo.Spread() > InpMaxSpread ? clrRed : clrLime); row++;

   row++;
   // Status
   UpdateLabel(dashPrefix + "S5", col1, startY + row * lineHeight, "── STATUS ──", clrDodgerBlue); row++;
   UpdateLabel(dashPrefix + "R" + IntegerToString(row), col1, startY + row * lineHeight,
               "EA State:", InpDashTextColor);
   UpdateLabel(dashPrefix + "V" + IntegerToString(row), col2, startY + row * lineHeight,
               eaState, stateColor); row++;

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Helper: Create Rectangle Label                                    |
//+------------------------------------------------------------------+
void CreateRect(string name, int x, int y, int width, int height, color bgColor)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrDarkSlateGray);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
//| Helper: Create/Update Label                                       |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize=9, string font="Consolas")
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
  }

void UpdateLabel(string name, int x, int y, string text, color clr)
  {
   CreateLabel(name, x, y, text, clr, InpDashFontSize);
  }

//+------------------------------------------------------------------+
//| DELETE DASHBOARD                                                  |
//+------------------------------------------------------------------+
void DeleteDashboard()
  {
   int totalObj = ObjectsTotal(0, 0);
   for(int i = totalObj - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i);
      if(StringFind(name, dashPrefix) == 0)
         ObjectDelete(0, name);
     }
  }
//+------------------------------------------------------------------+