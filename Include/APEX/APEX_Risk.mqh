//+------------------------------------------------------------------+
//|                                                 APEX_Risk.mqh    |
//|        APEX Gold Destroyer - Aggressive Risk & Sizing Engine     |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_RISK_MQH
#define APEX_RISK_MQH

#include "APEX_Config.mqh"
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| Risk Engine - Maximum Aggression                                  |
//+------------------------------------------------------------------+
class CRiskEngine
  {
private:
   string            m_symbol;
   bool              m_initialized;

   // Account info
   CAccountInfo      m_account;
   CSymbolInfo       m_symbolInfo;

   // Trade history circular buffer
   ApexTradeRecord   m_tradeBuffer[];
   int               m_bufferSize;
   int               m_bufferIndex;
   int               m_totalTrades;

   // Performance metrics
   ApexRiskMetrics   m_metrics;

   // Equity tracking
   double            m_equityHistory[];
   int               m_equityHistIdx;
   int               m_equityHistSize;

   // Martingale state per direction
   int               m_martBuyLevel;
   int               m_martSellLevel;
   datetime          m_martBuyCooldownEnd;
   datetime          m_martSellCooldownEnd;
   ENUM_APEX_REGIME  m_martBuyRegime;
   ENUM_APEX_REGIME  m_martSellRegime;

   // Consecutive tracking
   int               m_consWins;
   int               m_consLosses;
   ENUM_APEX_SIGNAL  m_lastTradeDir;
   datetime          m_lossStreakCooldownEnd;  // v2: loss-streak cooldown

   // Regime blacklist
   bool              m_regimeBlacklist[5]; // One per ENUM_APEX_REGIME
   datetime          m_regimeBlacklistEnd[5];
   int               m_regimeConsLosses[5];

   // Internal methods
   double            ComputeKellyFraction();
   double            ComputeEquitySMAMultiplier();
   void              UpdateEquityHistory();

public:
                     CRiskEngine();
                    ~CRiskEngine();
   bool              Init(string symbol);
   void              Deinit();

   // Core lot calculation
   double            CalculateLots(const ApexSignal &signal, double slDistance);
   double            CalculateBaseLots(const ApexSignal &signal, double slDistance);  // v2: no mart/equity/conf

   // Can we trade?
   bool              CanTrade(ENUM_APEX_SIGNAL direction, ENUM_APEX_REGIME regime);
   bool              CanTradeWithLots(ENUM_APEX_SIGNAL direction, ENUM_APEX_REGIME regime, double requestedLots);  // v2
   bool              IsEmergencyStop();
   int               CountOpenPositions(long magic);
   int               CountByDirection(ENUM_APEX_SIGNAL dir, long magic);
   double            GetTotalOpenLots(long magic);  // v2: aggregate lot check

   // Record trade result (called from OnTradeTransaction)
   void              RecordTrade(double profit, double lots, ENUM_APEX_REGIME regime,
                                ENUM_APEX_STRATEGY strategy, ENUM_APEX_SIGNAL direction);

   // Accessors
   ApexRiskMetrics   GetMetrics()      { return m_metrics; }
   int               GetMartLevel(ENUM_APEX_SIGNAL dir);
   double            GetLotMultiplier()  { return m_metrics.lotMultiplier; }
   int               GetTotalTrades()    { return m_totalTrades; }
   double            GetWinRate();
   double            GetProfitFactor();

   // Pyramiding
   double            GetPyramidLots(int pyramidLevel, double baseLots);
   bool              CanPyramid(ENUM_APEX_SIGNAL dir, long magic);

   // Grid
   double            GetGridLots(int gridLevel, double baseLots);
  };

//+------------------------------------------------------------------+
CRiskEngine::CRiskEngine()
  {
   m_initialized = false;
   m_bufferSize = APEX_TRADE_BUFFER_SIZE;
   m_bufferIndex = 0;
   m_totalTrades = 0;
   m_equityHistSize = 20;
   m_equityHistIdx = 0;
   m_martBuyLevel = 0;
   m_martSellLevel = 0;
   m_martBuyCooldownEnd = 0;
   m_martSellCooldownEnd = 0;
   m_martBuyRegime = REGIME_RANGE;
   m_martSellRegime = REGIME_RANGE;
   m_consWins = 0;
   m_consLosses = 0;
   m_lastTradeDir = SIGNAL_NONE;
   m_lossStreakCooldownEnd = 0;

   ZeroMemory(m_metrics);
   m_metrics.lotMultiplier = 1.0;

   for(int i = 0; i < 5; i++)
     {
      m_regimeBlacklist[i] = false;
      m_regimeBlacklistEnd[i] = 0;
      m_regimeConsLosses[i] = 0;
     }
  }

//+------------------------------------------------------------------+
CRiskEngine::~CRiskEngine() { Deinit(); }

//+------------------------------------------------------------------+
bool CRiskEngine::Init(string symbol)
  {
   m_symbol = symbol;
   m_symbolInfo.Name(m_symbol);

   ArrayResize(m_tradeBuffer, m_bufferSize);
   ArrayResize(m_equityHistory, m_equityHistSize);
   ArrayInitialize(m_equityHistory, 0);

   m_metrics.equity = m_account.Equity();
   m_metrics.balance = m_account.Balance();
   m_metrics.peakEquity = m_metrics.equity;
   m_metrics.equitySMA = m_metrics.equity;

   m_initialized = true;
   return true;
  }

//+------------------------------------------------------------------+
void CRiskEngine::Deinit()
  {
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Core lot calculation with all multipliers                         |
//+------------------------------------------------------------------+
double CRiskEngine::CalculateLots(const ApexSignal &signal, double slDistance)
  {
   if(!m_initialized || slDistance <= 0) return 0;

   m_symbolInfo.RefreshRates();
   double equity = m_account.Equity();
   m_metrics.equity = equity;
   m_metrics.balance = m_account.Balance();

   // Track peak equity
   if(equity > m_metrics.peakEquity)
      m_metrics.peakEquity = equity;

   // Update equity SMA
   UpdateEquityHistory();

   // ═══ Step 1: Determine base risk percentage ═══
   double riskPercent = InpBaseRisk;

   // After enough trades, switch to Kelly criterion
   if(m_totalTrades >= InpKellyMinTrades)
     {
      double kelly = ComputeKellyFraction();
      if(kelly > 0)
        {
         riskPercent = kelly * InpKellyFraction * 100.0;
         riskPercent = MathMax(riskPercent, 5.0);  // Min 5%
         riskPercent = MathMin(riskPercent, InpMaxRisk); // Cap at max
        }
     }

   // ═══ Step 2: Compute base lots ═══
   double tickValue = m_symbolInfo.TickValue();
   double tickSize  = m_symbolInfo.TickSize();
   if(tickValue <= 0 || tickSize <= 0) return 0;

   double riskAmount = equity * riskPercent / 100.0;
   double lots = riskAmount / (slDistance * tickValue / tickSize);

   // ═══ Step 3: Apply martingale multiplier ═══
   if(InpMartingaleEnabled)
     {
      int martLevel = 0;
      if(signal.direction == SIGNAL_BUY) martLevel = m_martBuyLevel;
      else martLevel = m_martSellLevel;

      if(martLevel > 0)
        {
         double martMult = MathPow(InpMartingaleMultiplier, martLevel);
         martMult = MathMin(martMult, InpMartingaleMaxMult);  // v2: hard cap
         lots *= martMult;
        }
      m_metrics.martingaleLevel = MathMax(m_martBuyLevel, m_martSellLevel);
     }

   // ═══ Step 4: Equity curve feedback ═══
   double equityMult = ComputeEquitySMAMultiplier();
   lots *= equityMult;
   m_metrics.lotMultiplier = equityMult;

   // ═══ Step 5: Signal confidence bonus ═══
   if(signal.normalizedScore >= InpHighConfScore)
      lots *= 1.3;  // 30% boost for high confidence signals

   // ═══ Step 6: Self-correction adjustment ═══
   if(m_totalTrades >= 20)
     {
      double winRate = GetWinRate();
      double pf = GetProfitFactor();

      if(winRate > 0.60 && pf > 1.5)
         lots *= 1.2;  // Hot streak - press the advantage
      else if(winRate < 0.40 || pf < 0.8)
         lots *= 0.6;  // Cold streak - reduce exposure
     }

   // ═══ Step 7: Normalize lots ═══
   double minLot   = m_symbolInfo.LotsMin();
   double maxLot   = m_symbolInfo.LotsMax();
   double lotStep  = m_symbolInfo.LotsStep();
   if(lotStep <= 0) lotStep = 0.01;

   // v2: Hard user-defined max lot cap BEFORE broker normalization
   lots = MathMin(lots, InpMaxLotSize);

   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);

   // ═══ Step 8: Margin check ═══
   double margin = 0;
   ENUM_ORDER_TYPE orderType = (signal.direction == SIGNAL_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!OrderCalcMargin(orderType, m_symbol, lots, m_symbolInfo.Ask(), margin))
      return minLot;

   double freeMargin = m_account.FreeMargin();
   if(margin > freeMargin * 0.9)
     {
      // Reduce lots to fit margin
      lots = lots * (freeMargin * 0.8) / margin;
      lots = MathFloor(lots / lotStep) * lotStep;
      lots = MathMax(lots, minLot);
     }

   return lots;
  }

//+------------------------------------------------------------------+
//| Check if we can trade                                             |
//+------------------------------------------------------------------+
bool CRiskEngine::CanTrade(ENUM_APEX_SIGNAL direction, ENUM_APEX_REGIME regime)
  {
   if(!m_initialized) return false;

   // Emergency drawdown check
   if(IsEmergencyStop())
     {
      Print("APEX Risk: EMERGENCY STOP - Max drawdown exceeded!");
      return false;
     }

   // Max positions check
   if(CountOpenPositions(InpMagic) >= InpMaxPositions) return false;

   // v2: Loss-streak cooldown check
   datetime now = TimeCurrent();
   if(now < m_lossStreakCooldownEnd)
     {
      return false;
     }

   // Martingale cooldown check
   if(direction == SIGNAL_BUY && now < m_martBuyCooldownEnd) return false;
   if(direction == SIGNAL_SELL && now < m_martSellCooldownEnd) return false;

   // Regime blacklist check
   int regimeIdx = (int)regime;
   if(regimeIdx >= 0 && regimeIdx < 5)
     {
      if(m_regimeBlacklist[regimeIdx])
        {
         if(now >= m_regimeBlacklistEnd[regimeIdx])
           {
            m_regimeBlacklist[regimeIdx] = false;
            m_regimeConsLosses[regimeIdx] = 0;
           }
         else
            return false;
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| v2: Can trade with lot-size-aware aggregate exposure check        |
//+------------------------------------------------------------------+
bool CRiskEngine::CanTradeWithLots(ENUM_APEX_SIGNAL direction, ENUM_APEX_REGIME regime, double requestedLots)
  {
   if(!CanTrade(direction, regime)) return false;

   // v2: Aggregate lot exposure check
   double totalLots = GetTotalOpenLots(InpMagic);
   if(totalLots + requestedLots > InpMaxTotalLots)
     {
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
bool CRiskEngine::IsEmergencyStop()
  {
   double equity = m_account.Equity();
   if(m_metrics.peakEquity <= 0) return false;
   double dd = (m_metrics.peakEquity - equity) / m_metrics.peakEquity * 100.0;
   m_metrics.drawdown = dd;
   return (dd >= InpMaxDrawdown);
  }

//+------------------------------------------------------------------+
int CRiskEngine::CountOpenPositions(long magic)
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == magic &&
         PositionGetString(POSITION_SYMBOL) == m_symbol)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
int CRiskEngine::CountByDirection(ENUM_APEX_SIGNAL dir, long magic)
  {
   int count = 0;
   ENUM_POSITION_TYPE ptype = (dir == SIGNAL_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == magic &&
         PositionGetString(POSITION_SYMBOL) == m_symbol &&
         (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == ptype)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| v2: Get total open lot exposure across all positions              |
//+------------------------------------------------------------------+
double CRiskEngine::GetTotalOpenLots(long magic)
  {
   double total = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == magic &&
         PositionGetString(POSITION_SYMBOL) == m_symbol)
         total += PositionGetDouble(POSITION_VOLUME);
     }
   return total;
  }

//+------------------------------------------------------------------+
//| Record trade result for self-correction                           |
//+------------------------------------------------------------------+
void CRiskEngine::RecordTrade(double profit, double lots, ENUM_APEX_REGIME regime,
                              ENUM_APEX_STRATEGY strategy, ENUM_APEX_SIGNAL direction)
  {
   // Add to circular buffer
   m_tradeBuffer[m_bufferIndex].closeTime = TimeCurrent();
   m_tradeBuffer[m_bufferIndex].profit    = profit;
   m_tradeBuffer[m_bufferIndex].lots      = lots;
   m_tradeBuffer[m_bufferIndex].regime    = regime;
   m_tradeBuffer[m_bufferIndex].strategy  = strategy;
   m_tradeBuffer[m_bufferIndex].direction = direction;
   m_tradeBuffer[m_bufferIndex].isWin     = (profit > 0);

   m_bufferIndex = (m_bufferIndex + 1) % m_bufferSize;
   m_totalTrades++;

   // Update consecutive tracking
   if(profit > 0)
     {
      m_consWins++;
      m_consLosses = 0;

      // Reset martingale on win
      if(direction == SIGNAL_BUY) m_martBuyLevel = 0;
      else m_martSellLevel = 0;
     }
   else
     {
      m_consLosses++;
      m_consWins = 0;

      // Advance martingale on loss
      if(InpMartingaleEnabled)
        {
         if(direction == SIGNAL_BUY)
           {
            // Only advance if same regime
            if(regime == m_martBuyRegime || m_martBuyLevel == 0)
              {
               m_martBuyLevel = MathMin(m_martBuyLevel + 1, InpMartingaleMaxLevels);
               m_martBuyRegime = regime;
               if(m_martBuyLevel >= InpMartingaleMaxLevels)
                 {
                  m_martBuyCooldownEnd = TimeCurrent() + InpMartingaleCooldown * 60;
                  m_martBuyLevel = 0;
                 }
              }
            else
              {
               m_martBuyLevel = 1;
               m_martBuyRegime = regime;
              }
           }
         else
           {
            if(regime == m_martSellRegime || m_martSellLevel == 0)
              {
               m_martSellLevel = MathMin(m_martSellLevel + 1, InpMartingaleMaxLevels);
               m_martSellRegime = regime;
               if(m_martSellLevel >= InpMartingaleMaxLevels)
                 {
                  m_martSellCooldownEnd = TimeCurrent() + InpMartingaleCooldown * 60;
                  m_martSellLevel = 0;
                 }
              }
            else
              {
               m_martSellLevel = 1;
               m_martSellRegime = regime;
              }
           }
        }
     }

   // Regime blacklisting
   int regimeIdx = (int)regime;
   if(regimeIdx >= 0 && regimeIdx < 5)
     {
      if(profit <= 0)
        {
         m_regimeConsLosses[regimeIdx]++;
         if(m_regimeConsLosses[regimeIdx] >= 5)
           {
            m_regimeBlacklist[regimeIdx] = true;
            m_regimeBlacklistEnd[regimeIdx] = TimeCurrent() + 30 * 60; // 30 min blacklist
            PrintFormat("APEX Risk: Regime %s BLACKLISTED for 30min after %d consecutive losses",
                        EnumToString(regime), m_regimeConsLosses[regimeIdx]);
           }
        }
      else
         m_regimeConsLosses[regimeIdx] = 0;
     }

   m_lastTradeDir = direction;
   m_metrics.consecutiveWins = m_consWins;
   m_metrics.consecutiveLosses = m_consLosses;

   // v2: Loss-streak cooldown
   if(m_consLosses >= InpLossStreakCooldown)
     {
      m_lossStreakCooldownEnd = TimeCurrent() + InpCooldownMinutes * 60;
      PrintFormat("APEX Risk: %d consecutive losses - COOLDOWN %d min",
                  m_consLosses, InpCooldownMinutes);
     }
  }

//+------------------------------------------------------------------+
//| Compute optimal Kelly fraction from trade history                 |
//+------------------------------------------------------------------+
double CRiskEngine::ComputeKellyFraction()
  {
   int count = MathMin(m_totalTrades, InpKellyWindow);
   if(count < InpKellyMinTrades) return InpBaseRisk / 100.0;

   double wins = 0, losses = 0;
   double totalWin = 0, totalLoss = 0;
   int startIdx = (m_bufferIndex - count + m_bufferSize) % m_bufferSize;

   for(int i = 0; i < count; i++)
     {
      int idx = (startIdx + i) % m_bufferSize;
      if(m_tradeBuffer[idx].profit > 0)
        {
         wins++;
         totalWin += m_tradeBuffer[idx].profit;
        }
      else if(m_tradeBuffer[idx].profit < 0)
        {
         losses++;
         totalLoss += MathAbs(m_tradeBuffer[idx].profit);
        }
     }

   if(losses == 0 || wins == 0) return InpBaseRisk / 100.0;

   double winRate = wins / (wins + losses);
   double avgWin = totalWin / wins;
   double avgLoss = totalLoss / losses;
   double winLossRatio = avgWin / avgLoss;

   m_metrics.winRate = winRate;
   m_metrics.avgWin = avgWin;
   m_metrics.avgLoss = avgLoss;

   // Kelly formula: f* = W - (1-W)/R
   double kelly = winRate - (1.0 - winRate) / winLossRatio;
   m_metrics.kellyFraction = MathMax(kelly, 0);

   return MathMax(kelly, 0);
  }

//+------------------------------------------------------------------+
//| Equity curve momentum multiplier                                  |
//+------------------------------------------------------------------+
double CRiskEngine::ComputeEquitySMAMultiplier()
  {
   double equity = m_account.Equity();
   if(m_metrics.equitySMA <= 0) return 1.0;

   // If equity above SMA → hot streak → press
   if(equity > m_metrics.equitySMA)
      return 1.3;
   // If equity below SMA → cold streak → reduce
   else
      return 0.7;
  }

//+------------------------------------------------------------------+
void CRiskEngine::UpdateEquityHistory()
  {
   double equity = m_account.Equity();
   m_equityHistory[m_equityHistIdx] = equity;
   m_equityHistIdx = (m_equityHistIdx + 1) % m_equityHistSize;

   // Compute SMA
   double sum = 0;
   int count = 0;
   for(int i = 0; i < m_equityHistSize; i++)
     {
      if(m_equityHistory[i] > 0)
        {
         sum += m_equityHistory[i];
         count++;
        }
     }
   m_metrics.equitySMA = (count > 0) ? sum / count : equity;
  }

//+------------------------------------------------------------------+
double CRiskEngine::GetWinRate()
  {
   int count = MathMin(m_totalTrades, InpKellyWindow);
   if(count == 0) return 0.5;

   int wins = 0;
   int startIdx = (m_bufferIndex - count + m_bufferSize) % m_bufferSize;
   for(int i = 0; i < count; i++)
     {
      int idx = (startIdx + i) % m_bufferSize;
      if(m_tradeBuffer[idx].isWin) wins++;
     }
   m_metrics.winRate = (double)wins / count;
   return m_metrics.winRate;
  }

//+------------------------------------------------------------------+
double CRiskEngine::GetProfitFactor()
  {
   int count = MathMin(m_totalTrades, InpKellyWindow);
   if(count == 0) return 1.0;

   double totalWin = 0, totalLoss = 0;
   int startIdx = (m_bufferIndex - count + m_bufferSize) % m_bufferSize;
   for(int i = 0; i < count; i++)
     {
      int idx = (startIdx + i) % m_bufferSize;
      if(m_tradeBuffer[idx].profit > 0)
         totalWin += m_tradeBuffer[idx].profit;
      else
         totalLoss += MathAbs(m_tradeBuffer[idx].profit);
     }
   m_metrics.profitFactor = (totalLoss > 0) ? totalWin / totalLoss : 99.0;
   return m_metrics.profitFactor;
  }

//+------------------------------------------------------------------+
int CRiskEngine::GetMartLevel(ENUM_APEX_SIGNAL dir)
  {
   return (dir == SIGNAL_BUY) ? m_martBuyLevel : m_martSellLevel;
  }

//+------------------------------------------------------------------+
//| Pyramid lot sizing: each add = decay × previous                   |
//+------------------------------------------------------------------+
double CRiskEngine::GetPyramidLots(int pyramidLevel, double baseLots)
  {
   double lots = baseLots * MathPow(InpPyramidSizeDecay, pyramidLevel);
   double minLot = m_symbolInfo.LotsMin();
   double lotStep = m_symbolInfo.LotsStep();
   if(lotStep <= 0) lotStep = 0.01;
   lots = MathMin(lots, InpMaxLotSize);  // v2: hard cap
   lots = MathFloor(lots / lotStep) * lotStep;
   return MathMax(lots, minLot);
  }

//+------------------------------------------------------------------+
bool CRiskEngine::CanPyramid(ENUM_APEX_SIGNAL dir, long magic)
  {
   if(!InpPyramidEnabled) return false;
   int dirCount = CountByDirection(dir, magic);
   return (dirCount > 0 && dirCount <= InpPyramidMaxAdds);
  }

//+------------------------------------------------------------------+
//| Grid lot sizing: progressive multiplier per level                 |
//+------------------------------------------------------------------+
double CRiskEngine::GetGridLots(int gridLevel, double baseLots)
  {
   double lots = baseLots * MathPow(InpGridLotMultiplier, gridLevel);
   double minLot = m_symbolInfo.LotsMin();
   double maxLot = m_symbolInfo.LotsMax();
   double lotStep = m_symbolInfo.LotsStep();
   if(lotStep <= 0) lotStep = 0.01;
   lots = MathMin(lots, InpMaxLotSize);  // v2: hard cap
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   return lots;
  }

//+------------------------------------------------------------------+
//| v2: Base-only lot calculation (no martingale/equity/confidence)   |
//| Used for pyramid and grid entries to prevent compounding          |
//+------------------------------------------------------------------+
double CRiskEngine::CalculateBaseLots(const ApexSignal &signal, double slDistance)
  {
   if(!m_initialized || slDistance <= 0) return 0;

   m_symbolInfo.RefreshRates();
   double equity = m_account.Equity();

   // Step 1: Determine base risk percentage (no Kelly override here)
   double riskPercent = InpBaseRisk;

   // Step 2: Compute base lots
   double tickValue = m_symbolInfo.TickValue();
   double tickSize  = m_symbolInfo.TickSize();
   if(tickValue <= 0 || tickSize <= 0) return 0;

   double riskAmount = equity * riskPercent / 100.0;
   double lots = riskAmount / (slDistance * tickValue / tickSize);

   // Step 3: Skip martingale (intentionally omitted)
   // Step 4: Skip equity curve feedback (intentionally omitted)
   // Step 5: Skip confidence bonus (intentionally omitted)
   // Step 6: Skip self-correction (intentionally omitted)

   // Step 7: Normalize lots with hard cap
   double minLot   = m_symbolInfo.LotsMin();
   double maxLot   = m_symbolInfo.LotsMax();
   double lotStep  = m_symbolInfo.LotsStep();
   if(lotStep <= 0) lotStep = 0.01;

   lots = MathMin(lots, InpMaxLotSize);  // v2: hard cap

   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);

   // Step 8: Margin check
   double margin = 0;
   ENUM_ORDER_TYPE orderType = (signal.direction == SIGNAL_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!OrderCalcMargin(orderType, m_symbol, lots, m_symbolInfo.Ask(), margin))
      return minLot;

   double freeMargin = m_account.FreeMargin();
   if(margin > freeMargin * 0.9)
     {
      lots = lots * (freeMargin * 0.8) / margin;
      lots = MathFloor(lots / lotStep) * lotStep;
      lots = MathMax(lots, minLot);
     }

   return lots;
  }

#endif // APEX_RISK_MQH
