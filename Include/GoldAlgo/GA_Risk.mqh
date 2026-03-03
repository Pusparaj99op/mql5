//+------------------------------------------------------------------+
//|                                                     GA_Risk.mqh  |
//|                   GoldAlgo Elite - Risk & Adaptation Engine        |
//|           Position sizing, safety gates, self-correction           |
//+------------------------------------------------------------------+
#property copyright "GoldAlgo Elite"
#property strict

#ifndef __GA_RISK_MQH__
#define __GA_RISK_MQH__

#include "GA_Config.mqh"
#include "GA_Indicators.mqh"
#include <Trade\DealInfo.mqh>
#include <Trade\AccountInfo.mqh>

//+------------------------------------------------------------------+
//| CRiskManager - Full risk management & self-correction             |
//+------------------------------------------------------------------+
class CRiskManager
  {
private:
   string            m_symbol;
   long              m_magic;
   CIndicatorEngine *m_ind;

   // State tracking
   RiskMetrics       m_metrics;
   PerformanceStats  m_stats;

   // Trade history circular buffer
   TradeRecord       m_tradeHistory[];
   int               m_historySize;
   int               m_historyIndex;
   int               m_historyCount;

   // Equity tracking for peak & MA
   double            m_equityHistory[];
   int               m_equityHistSize;
   int               m_equityHistIdx;
   int               m_equityHistCount;

   // Daily tracking
   datetime          m_lastTradeDay;
   double            m_dayStartBalance;
   int               m_dailyTradeCount;

   // Regime blacklist (temporary suppression)
   datetime          m_regimeBlacklistUntil[5]; // One for each ENUM_MARKET_REGIME value
   int               m_regimeTradeCount[5];
   int               m_regimeWinCount[5];

   // Private helpers
   void              UpdatePerformanceStats();
   double            ComputeKellyFraction();
   double            ComputeEquityMA();
   void              UpdateEquityHistory();
   int               CountOpenPositions();
   int               CountDailyTrades();
   double            ComputeDailyPnL();

public:
                     CRiskManager();
                    ~CRiskManager();

   bool              Init(string symbol, long magic, CIndicatorEngine *indEngine);

   // Main risk check - call before each potential trade
   bool              CheckSafetyGates(RiskMetrics &metrics);

   // Position sizing
   double            ComputeLotSize(double slPoints);

   // Adaptation: call when a trade closes
   void              OnTradeClosed(double pnl, double entryScore, ENUM_MARKET_REGIME regime, ENUM_SIGNAL_DIR dir);

   // Get current stats
   PerformanceStats  GetStats()      { return m_stats; }
   RiskMetrics       GetMetrics()    { return m_metrics; }
   double            GetScoreAdj()   { return m_stats.scoreAdjustment; }
   double            GetLotMult()    { return m_stats.lotMultiplier; }

   // Regime blacklist check
   bool              IsRegimeBlacklisted(ENUM_MARKET_REGIME regime);

   // Daily reset
   void              CheckDayReset();
  };

//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
  {
   m_historySize    = 0;
   m_historyIndex   = 0;
   m_historyCount   = 0;
   m_equityHistSize = 50;
   m_equityHistIdx  = 0;
   m_equityHistCount= 0;
   m_lastTradeDay   = 0;
   m_dayStartBalance= 0;
   m_dailyTradeCount= 0;
   m_ind            = NULL;

   ArrayInitialize(m_regimeBlacklistUntil, 0);
   ArrayInitialize(m_regimeTradeCount, 0);
   ArrayInitialize(m_regimeWinCount, 0);
  }

//+------------------------------------------------------------------+
CRiskManager::~CRiskManager() {}

//+------------------------------------------------------------------+
bool CRiskManager::Init(string symbol, long magic, CIndicatorEngine *indEngine)
  {
   m_symbol = symbol;
   m_magic  = magic;
   m_ind    = indEngine;

   // Initialize trade history buffer
   m_historySize = InpLookbackTrades;
   ArrayResize(m_tradeHistory, m_historySize);
   m_historyIndex = 0;
   m_historyCount = 0;

   // Initialize equity history
   ArrayResize(m_equityHistory, m_equityHistSize);
   ArrayInitialize(m_equityHistory, 0);

   // Initialize metrics
   m_metrics.Reset();
   m_metrics.peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   m_stats.Reset();

   // Day tracking
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   m_lastTradeDay    = TimeCurrent() - dt.hour * 3600 - dt.min * 60 - dt.sec;
   m_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_dailyTradeCount = 0;

   PrintFormat("[GA-RISK] Risk manager initialized. Peak equity: %.2f, Risk: %.1f%%",
               m_metrics.peakEquity, InpRiskPercent);
   return true;
  }

//+------------------------------------------------------------------+
//| Check all safety gates before opening a trade                     |
//+------------------------------------------------------------------+
bool CRiskManager::CheckSafetyGates(RiskMetrics &metrics)
  {
   metrics.Reset();
   metrics.isTradingAllowed = true;

   CheckDayReset();
   UpdateEquityHistory();

   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   // Update peak equity
   if(equity > m_metrics.peakEquity)
      m_metrics.peakEquity = equity;

   //--- Gate 1: Session check
   if(!IsWithinTradingSession())
     {
      metrics.isTradingAllowed = false;
      metrics.haltReason = "Outside trading session";
      m_metrics = metrics;
      return false;
     }

   //--- Gate 2: Max drawdown from peak
   double dd = 0;
   if(m_metrics.peakEquity > 0)
      dd = (m_metrics.peakEquity - equity) / m_metrics.peakEquity * 100.0;
   metrics.currentDrawdown = dd;

   if(dd >= InpMaxDrawdown)
     {
      metrics.isTradingAllowed = false;
      metrics.haltReason = StringFormat("Max drawdown reached: %.1f%% >= %.1f%%", dd, InpMaxDrawdown);
      m_metrics = metrics;
      return false;
     }

   //--- Gate 3: Daily loss limit
   double dailyPnL = ComputeDailyPnL();
   metrics.dailyPnL = dailyPnL;

   double dailyLossPct = 0;
   if(m_dayStartBalance > 0)
      dailyLossPct = -dailyPnL / m_dayStartBalance * 100.0;

   if(dailyLossPct >= InpMaxDailyLoss)
     {
      metrics.isTradingAllowed = false;
      metrics.haltReason = StringFormat("Daily loss limit: %.1f%% >= %.1f%%", dailyLossPct, InpMaxDailyLoss);
      m_metrics = metrics;
      return false;
     }

   //--- Gate 4: Max open positions
   int openPos = CountOpenPositions();
   metrics.openPositions = openPos;

   if(openPos >= InpMaxOpenPositions)
     {
      metrics.isTradingAllowed = false;
      metrics.haltReason = StringFormat("Max positions: %d >= %d", openPos, InpMaxOpenPositions);
      m_metrics = metrics;
      return false;
     }

   //--- Gate 5: Max daily trades
   int dailyTrades = CountDailyTrades();
   metrics.dailyTrades = dailyTrades;

   if(dailyTrades >= InpMaxDailyTrades)
     {
      metrics.isTradingAllowed = false;
      metrics.haltReason = StringFormat("Max daily trades: %d >= %d", dailyTrades, InpMaxDailyTrades);
      m_metrics = metrics;
      return false;
     }

   //--- Gate 6: Spread check
   int spread = (int)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpread)
     {
      metrics.isTradingAllowed = false;
      metrics.haltReason = StringFormat("Spread too wide: %d > %d", spread, InpMaxSpread);
      m_metrics = metrics;
      return false;
     }

   //--- Gate 7: ATR filter (avoid dead or extreme markets)
   if(m_ind != NULL)
     {
      double atrPct = m_ind.ATRPercentile();
      if(atrPct < 15)
        {
         metrics.isTradingAllowed = false;
         metrics.haltReason = StringFormat("ATR too low (dead market): pct=%.0f%%", atrPct);
         m_metrics = metrics;
         return false;
        }
      if(atrPct > 90)
        {
         metrics.isTradingAllowed = false;
         metrics.haltReason = StringFormat("ATR too high (extreme volatility): pct=%.0f%%", atrPct);
         m_metrics = metrics;
         return false;
        }
     }

   //--- Gate 8: Cooldown check
   if(m_stats.cooldownUntil > TimeCurrent())
     {
      metrics.isTradingAllowed = false;
      int remaining = (int)(m_stats.cooldownUntil - TimeCurrent()) / 60;
      metrics.haltReason = StringFormat("Cooldown active: %d min remaining", remaining);
      m_metrics = metrics;
      return false;
     }

   //--- Gate 9: Free margin check (need at least 2x required margin)
   double lotMin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double marginRequired = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, m_symbol, lotMin, SymbolInfoDouble(m_symbol, SYMBOL_ASK), marginRequired))
      marginRequired = 0;

   if(marginRequired > 0 && freeMargin < marginRequired * 2)
     {
      metrics.isTradingAllowed = false;
      metrics.haltReason = StringFormat("Insufficient margin: free=%.2f, required=%.2f", freeMargin, marginRequired * 2);
      m_metrics = metrics;
      return false;
     }

   // Compute equity MA for reference
   metrics.equityMA = ComputeEquityMA();
   metrics.peakEquity = m_metrics.peakEquity;

   // Compute adjusted risk (considering drawdown and equity curve)
   double adjustedRisk = InpRiskPercent;

   // Drawdown-based scaling: aggressive progressive reduction
  if(dd > 2.0)
     {
    if(dd >= 8.0)
      adjustedRisk *= 0.15;      // Near halt: 85% reduction
    else if(dd >= 5.0)
      adjustedRisk *= 0.35;      // Heavy reduction
      else
      adjustedRisk *= (1.0 - (dd - 2.0) * 0.12);  // 12% per % DD above 2%
     }

   // Equity curve feedback
   double eqMA = ComputeEquityMA();
  if(eqMA > 0 && equity < eqMA)
    adjustedRisk *= 0.65;   // Below equity MA: reduce risk
   else if(eqMA > 0 && equity > eqMA * 1.05)
      adjustedRisk *= 1.2;    // Well above equity MA: slightly increase

   // Apply lot multiplier from self-correction
   adjustedRisk *= m_stats.lotMultiplier;

   // Clamp
  adjustedRisk = MathMax(adjustedRisk, 0.2);
  adjustedRisk = MathMin(adjustedRisk, InpRiskPercent * 1.2);

   metrics.adjustedRisk = adjustedRisk;
   m_metrics = metrics;

   return true;
  }

//+------------------------------------------------------------------+
//| Compute lot size from risk-in-dollars and SL distance             |
//+------------------------------------------------------------------+
double CRiskManager::ComputeLotSize(double slPoints)
  {
   if(slPoints <= 0) return 0;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskPct = m_metrics.adjustedRisk;

   //--- Method 1: Fixed percentage risk
   double riskDollars = equity * riskPct / 100.0;

   //--- Method 2: Kelly Criterion
   double kellyRisk = equity * ComputeKellyFraction() / 100.0;

   //--- Use conservative envelope (minimum of both)
   if(kellyRisk > 0 && m_stats.totalTrades >= 15)
      riskDollars = MathMin(riskDollars, kellyRisk);

   //--- Convert to lots
   double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   double point     = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   if(tickValue <= 0 || tickSize <= 0 || point <= 0)
     {
      PrintFormat("[GA-RISK] WARNING: Invalid tick data: value=%.5f, size=%.5f, point=%.5f",
                  tickValue, tickSize, point);
      return SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
     }

   // SL in price distance
   double slPrice = slPoints * point;
   // Value of SL per lot
   double slValuePerLot = slPrice * tickValue / tickSize;

   double lots = 0;
   if(slValuePerLot > 0)
      lots = riskDollars / slValuePerLot;

   //--- Apply lot constraints
   double lotMin  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double lotMax  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);

   if(lotStep <= 0) lotStep = 0.01;

   // Round to step
   lots = MathFloor(lots / lotStep) * lotStep;

   // Clamp
   lots = MathMax(lots, lotMin);
   lots = MathMin(lots, lotMax);

   // Final margin check
   double marginReq = 0;
   if(OrderCalcMargin(ORDER_TYPE_BUY, m_symbol, lots, SymbolInfoDouble(m_symbol, SYMBOL_ASK), marginReq))
     {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      while(lots > lotMin && marginReq > freeMargin * 0.5)
        {
         lots -= lotStep;
         lots = MathMax(lots, lotMin);
         OrderCalcMargin(ORDER_TYPE_BUY, m_symbol, lots, SymbolInfoDouble(m_symbol, SYMBOL_ASK), marginReq);
        }
     }

   m_metrics.kellyLotSize = lots;
   return NormalizeDouble(lots, 2);
  }

//+------------------------------------------------------------------+
//| Called when a trade closes - feeds self-correction engine          |
//+------------------------------------------------------------------+
void CRiskManager::OnTradeClosed(double pnl, double entryScore, ENUM_MARKET_REGIME regime, ENUM_SIGNAL_DIR dir)
  {
   // Store in circular buffer
   TradeRecord rec;
   rec.openTime   = 0;
   rec.closeTime  = TimeCurrent();
   rec.pnl        = pnl;
   rec.isWin      = (pnl > 0);
   rec.entryScore = entryScore;
   rec.regime     = regime;
   rec.direction  = dir;

   m_tradeHistory[m_historyIndex] = rec;
   m_historyIndex = (m_historyIndex + 1) % m_historySize;
   if(m_historyCount < m_historySize)
      m_historyCount++;

   // Update consecutive counters
   if(pnl > 0)
     {
      m_stats.consecutiveWins++;
      m_stats.consecutiveLosses = 0;
     }
   else
     {
      m_stats.consecutiveLosses++;
      m_stats.consecutiveWins = 0;
     }

   // Track regime performance
   int regIdx = (int)regime;
   if(regIdx >= 0 && regIdx < 5)
     {
      m_regimeTradeCount[regIdx]++;
      if(pnl > 0) m_regimeWinCount[regIdx]++;

      // Check if regime should be blacklisted
      if(m_regimeTradeCount[regIdx] >= 15)
        {
         double regimeWR = (double)m_regimeWinCount[regIdx] / (double)m_regimeTradeCount[regIdx] * 100.0;
         if(regimeWR < 25.0)
           {
            m_regimeBlacklistUntil[regIdx] = TimeCurrent() + 7200; // 2 hour blacklist
            PrintFormat("[GA-RISK] REGIME BLACKLISTED: %s (WR: %.1f%% over %d trades) for 2 hours",
                        EnumToString(regime), regimeWR, m_regimeTradeCount[regIdx]);
            // Reset regime counters
            m_regimeTradeCount[regIdx] = 0;
            m_regimeWinCount[regIdx]   = 0;
           }
         else if(m_regimeTradeCount[regIdx] >= 30)
           {
            // Reset counters periodically to keep them fresh
            m_regimeTradeCount[regIdx] = m_regimeTradeCount[regIdx] / 2;
            m_regimeWinCount[regIdx]   = m_regimeWinCount[regIdx] / 2;
           }
        }
     }

   // Cooldown trigger: consecutive losses
  if(m_stats.consecutiveLosses >= InpMaxConsecLoss)
     {
    int extraLosses = m_stats.consecutiveLosses - InpMaxConsecLoss;
    int cooldownMinutes = (int)(InpCooldownMinutes * MathMin(3.0, 1.0 + extraLosses * 0.5));
    m_stats.cooldownUntil = TimeCurrent() + cooldownMinutes * 60;
    PrintFormat("[GA-RISK] COOLDOWN ACTIVATED: %d consecutive losses. Pausing for %d minutes.",
            m_stats.consecutiveLosses, cooldownMinutes);
     }

   // Update all performance stats
   UpdatePerformanceStats();

   m_dailyTradeCount++;

   PrintFormat("[GA-RISK] Trade closed: PnL=%.2f | WR=%.1f%% | PF=%.2f | ConsecW=%d ConsecL=%d | LotMult=%.2f | ScoreAdj=%.1f",
               pnl, m_stats.winRate, m_stats.profitFactor,
               m_stats.consecutiveWins, m_stats.consecutiveLosses,
               m_stats.lotMultiplier, m_stats.scoreAdjustment);
  }

//+------------------------------------------------------------------+
//| Update performance stats from trade history buffer                |
//+------------------------------------------------------------------+
void CRiskManager::UpdatePerformanceStats()
  {
   if(m_historyCount == 0) return;

   int wins = 0, losses = 0;
   double grossProfit = 0, grossLoss = 0;
   double sumWin = 0, sumLoss = 0;

   int count = MathMin(m_historyCount, m_historySize);

   for(int i = 0; i < count; i++)
     {
      if(m_tradeHistory[i].isWin)
        {
         wins++;
         grossProfit += m_tradeHistory[i].pnl;
         sumWin += m_tradeHistory[i].pnl;
        }
      else
        {
         losses++;
         grossLoss += MathAbs(m_tradeHistory[i].pnl);
         sumLoss += MathAbs(m_tradeHistory[i].pnl);
        }
     }

   m_stats.totalTrades = count;
   m_stats.winRate = (count > 0) ? (double)wins / (double)count * 100.0 : 50.0;
   m_stats.profitFactor = (grossLoss > 0) ? grossProfit / grossLoss : (grossProfit > 0 ? 99.0 : 1.0);
   m_stats.avgWin  = (wins > 0)   ? sumWin / wins : 0;
   m_stats.avgLoss = (losses > 0) ? sumLoss / losses : 0;

   //--- Kelly Criterion computation
   m_stats.kellyFraction = ComputeKellyFraction();

   //--- Adaptive lot multiplier (0.3 - 1.5)
   if(m_stats.winRate < InpWinRateReduce)
     {
      // Poor performance: scale down progressively
      double factor = 1.0 - (InpWinRateReduce - m_stats.winRate) / 100.0;
      m_stats.lotMultiplier = MathMax(0.3, factor);
     }
   else if(m_stats.winRate > InpWinRateBoost && m_stats.profitFactor > 1.5)
     {
      // Strong performance: scale up cautiously
      double factor = 1.0 + (m_stats.winRate - InpWinRateBoost) / 200.0;
      m_stats.lotMultiplier = MathMin(1.5, factor);
     }
   else
     {
      // Gradually return to 1.0
      m_stats.lotMultiplier = m_stats.lotMultiplier * 0.9 + 1.0 * 0.1;
     }

   // Consecutive loss penalty
   if(m_stats.consecutiveLosses > 0)
     {
      double penalty = MathPow(0.85, m_stats.consecutiveLosses);
      m_stats.lotMultiplier *= MathMax(penalty, 0.3);
     }

   // Consecutive win bonus (smaller)
   if(m_stats.consecutiveWins >= 3)
     {
      m_stats.lotMultiplier *= MathMin(1.0 + m_stats.consecutiveWins * 0.05, 1.3);
     }

  // Expectancy guardrail: when payoff quality degrades, scale down
  if(m_stats.profitFactor < 1.05 || (m_stats.avgWin > 0 && m_stats.avgLoss > m_stats.avgWin))
    m_stats.lotMultiplier *= 0.85;

   // Final clamp
   m_stats.lotMultiplier = MathMax(0.3, MathMin(1.5, m_stats.lotMultiplier));

   //--- Adaptive score adjustment (-3 to +3)
   if(m_stats.winRate < InpWinRateReduce)
     {
      // Tighten: raise minimum score threshold
      m_stats.scoreAdjustment = MathMin(3.0, (InpWinRateReduce - m_stats.winRate) / 8.0);
     }
   else if(m_stats.winRate > InpWinRateBoost && m_stats.profitFactor > 1.2)
     {
      // Loosen: lower minimum score threshold
      m_stats.scoreAdjustment = MathMax(-0.5, -(m_stats.winRate - InpWinRateBoost) / 25.0);
     }
   else
     {
      // Gradually decay toward 0
      m_stats.scoreAdjustment *= 0.9;
     }
  }

//+------------------------------------------------------------------+
//| Compute Kelly fraction for position sizing                        |
//+------------------------------------------------------------------+
double CRiskManager::ComputeKellyFraction()
  {
   if(m_stats.totalTrades < 10 || m_stats.avgLoss <= 0)
      return InpRiskPercent;  // Not enough data, use default

   double W = m_stats.winRate / 100.0;       // Win probability
   double L = 1.0 - W;                        // Loss probability
   double R = m_stats.avgWin / m_stats.avgLoss; // Win/Loss ratio

   // Kelly formula: f* = (W * R - L) / R
   double kelly = (W * R - L) / R;

   // Apply fraction (quarter-Kelly for safety)
   kelly *= InpKellyFraction;

   // Convert to percentage and clamp
   kelly *= 100.0;
   kelly = MathMax(kelly, 0.3);     // Minimum 0.3%
   kelly = MathMin(kelly, InpRiskPercent * 2.0);  // Cap at 2x base risk

   return kelly;
  }

//+------------------------------------------------------------------+
//| Equity MA for curve feedback                                      |
//+------------------------------------------------------------------+
double CRiskManager::ComputeEquityMA()
  {
   int count = MathMin(m_equityHistCount, m_equityHistSize);
   if(count < 5) return 0;

   double sum = 0;
   for(int i = 0; i < count; i++)
      sum += m_equityHistory[i];

   return sum / count;
  }

//+------------------------------------------------------------------+
//| Update equity history buffer                                      |
//+------------------------------------------------------------------+
void CRiskManager::UpdateEquityHistory()
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   m_equityHistory[m_equityHistIdx] = equity;
   m_equityHistIdx = (m_equityHistIdx + 1) % m_equityHistSize;
   if(m_equityHistCount < m_equityHistSize)
      m_equityHistCount++;
  }

//+------------------------------------------------------------------+
//| Count open positions with our magic number                        |
//+------------------------------------------------------------------+
int CRiskManager::CountOpenPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == m_magic &&
         PositionGetString(POSITION_SYMBOL) == m_symbol)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Count trades opened today with our magic number                   |
//+------------------------------------------------------------------+
int CRiskManager::CountDailyTrades()
  {
   datetime dayStart = m_lastTradeDay;
   int count = 0;

   if(!HistorySelect(dayStart, TimeCurrent()))
      return m_dailyTradeCount;  // Fallback to our counter

   int total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == m_magic &&
         HistoryDealGetString(ticket, DEAL_SYMBOL) == m_symbol &&
         HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Compute today's closed P&L                                        |
//+------------------------------------------------------------------+
double CRiskManager::ComputeDailyPnL()
  {
   datetime dayStart = m_lastTradeDay;
   double totalPnL = 0;

   if(!HistorySelect(dayStart, TimeCurrent()))
      return 0;

   int total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == m_magic &&
         HistoryDealGetString(ticket, DEAL_SYMBOL) == m_symbol &&
         HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         totalPnL += HistoryDealGetDouble(ticket, DEAL_PROFIT)
                   + HistoryDealGetDouble(ticket, DEAL_SWAP)
                   + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        }
     }
   return totalPnL;
  }

//+------------------------------------------------------------------+
//| Check if a specific regime is blacklisted                         |
//+------------------------------------------------------------------+
bool CRiskManager::IsRegimeBlacklisted(ENUM_MARKET_REGIME regime)
  {
   int idx = (int)regime;
   if(idx < 0 || idx >= 5) return false;

   if(m_regimeBlacklistUntil[idx] > TimeCurrent())
      return true;

   return false;
  }

//+------------------------------------------------------------------+
//| Daily reset check                                                 |
//+------------------------------------------------------------------+
void CRiskManager::CheckDayReset()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = TimeCurrent() - dt.hour * 3600 - dt.min * 60 - dt.sec;

   if(today != m_lastTradeDay)
     {
      m_lastTradeDay    = today;
      m_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_dailyTradeCount = 0;
      PrintFormat("[GA-RISK] Day reset. Starting balance: %.2f", m_dayStartBalance);
     }
  }

#endif // __GA_RISK_MQH__
