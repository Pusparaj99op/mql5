//+------------------------------------------------------------------+
//|                                                 XM_RiskGuard.mqh |
//|                        Risk Management & Self-Correction Engine  |
//|                              Copyright 2024-2026, XM_XAUUSD Bot  |
//+------------------------------------------------------------------+
#property copyright "XM_XAUUSD Bot"
#property link      "https://github.com/Pusparaj99op/XM_XAUUSD"
#property version   "1.00"
#property strict

#ifndef XM_RISKGUARD_MQH
#define XM_RISKGUARD_MQH

#include "XM_Config.mqh"
#include "XM_OrderManager.mqh"
#include <Trade\AccountInfo.mqh>

//+------------------------------------------------------------------+
//| CRiskGuard Class                                                  |
//+------------------------------------------------------------------+
class CRiskGuard
{
private:
   string            m_symbol;
   COrderManager*    m_orderManager;
   CAccountInfo      m_accountInfo;

   // Balance tracking
   double            m_dailyStartBalance;
   double            m_weeklyStartBalance;
   double            m_monthlyStartBalance;
   double            m_highWaterMark;
   datetime          m_dailyResetTime;
   datetime          m_weeklyResetTime;

   // Risk metrics
   RiskMetrics       m_currentMetrics;

   // Self-correction state
   double            m_lotMultiplier;
   int               m_recentWins;
   int               m_recentLosses;
   bool              m_isCoolingDown;
   datetime          m_cooldownEndTime;

   // Kelly Criterion
   double            m_kellyFraction;

   bool              m_initialized;

public:
   //--- Constructor/Destructor
                     CRiskGuard();
                    ~CRiskGuard();

   //--- Initialization
   bool              Initialize(string symbol, COrderManager* orderMgr);
   void              SetOrderManager(COrderManager* orderMgr) { m_orderManager = orderMgr; }

   //--- Main check functions
   bool              CanOpenNewTrade();
   bool              IsDrawdownLimitReached();
   bool              IsMarginSafe();
   bool              IsTradingHoursOK();
   bool              IsDayAllowed();

   //--- Risk calculations
   double            GetCurrentDrawdown();
   double            GetDailyDrawdown();
   double            GetWeeklyDrawdown();
   double            GetMaxDrawdown();
   double            CalculateOptimalLotSize(double slPips);
   double            GetAdjustedRiskPercent();
   double            CalculateKellyFraction();

   //--- Self-correction methods
   void              UpdateSelfCorrection();
   double            GetLotMultiplier();
   void              TriggerCooldown(int minutes);
   bool              IsCoolingDown();
   void              ResetAfterDrawdown();

   //--- Metrics
   void              UpdateMetrics();
   RiskMetrics       GetMetrics() { return m_currentMetrics; }
   void              ResetDailyMetrics();
   void              ResetWeeklyMetrics();

   //--- Daily/Weekly tracking
   void              CheckDailyReset();
   void              CheckWeeklyReset();
   double            GetDailyPnL();
   double            GetWeeklyPnL();

   //--- Position sizing
   double            CalculatePositionSize(double riskPercent, double slPips);
   double            GetMaxAllowableLots();

   //--- Utility
   string            GetTradingStatus();
   string            GetPauseReason();
   bool              ShouldReduceExposure();
   void              EmergencyCloseAll();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CRiskGuard::CRiskGuard()
{
   m_symbol = "";
   m_orderManager = NULL;
   m_dailyStartBalance = 0;
   m_weeklyStartBalance = 0;
   m_monthlyStartBalance = 0;
   m_highWaterMark = 0;
   m_dailyResetTime = 0;
   m_weeklyResetTime = 0;
   m_lotMultiplier = 1.0;
   m_recentWins = 0;
   m_recentLosses = 0;
   m_isCoolingDown = false;
   m_cooldownEndTime = 0;
   m_kellyFraction = 0.5;
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CRiskGuard::~CRiskGuard()
{
   m_orderManager = NULL;
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CRiskGuard::Initialize(string symbol, COrderManager* orderMgr)
{
   m_symbol = symbol;
   m_orderManager = orderMgr;

   // Initialize balance tracking
   m_dailyStartBalance = m_accountInfo.Balance();
   m_weeklyStartBalance = m_dailyStartBalance;
   m_monthlyStartBalance = m_dailyStartBalance;
   m_highWaterMark = m_dailyStartBalance;

   // Set reset times
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   m_dailyResetTime = StructToTime(dt);

   // Weekly reset on Monday
   int daysToMonday = (dt.day_of_week == 0) ? 1 : (8 - dt.day_of_week) % 7;
   m_weeklyResetTime = m_dailyResetTime + daysToMonday * 24 * 60 * 60;

   m_lotMultiplier = 1.0;
   m_isCoolingDown = false;

   UpdateMetrics();

   m_initialized = true;
   Print("Risk Guard initialized");
   Print("Daily Start Balance: ", m_dailyStartBalance);
   Print("Daily DD Limit: ", InpDailyDrawdownLimit, "%");
   Print("Weekly DD Limit: ", InpWeeklyDrawdownLimit, "%");

   return true;
}

//+------------------------------------------------------------------+
//| Check if Can Open New Trade                                       |
//+------------------------------------------------------------------+
bool CRiskGuard::CanOpenNewTrade()
{
   UpdateMetrics();

   // Check cooldown
   if(IsCoolingDown())
   {
      m_currentMetrics.tradingEnabled = false;
      m_currentMetrics.pauseReason = "Cooling down after losses";
      return false;
   }

   // Check drawdown limits
   if(IsDrawdownLimitReached())
   {
      m_currentMetrics.tradingEnabled = false;
      return false;
   }

   // Check margin
   if(!IsMarginSafe())
   {
      m_currentMetrics.tradingEnabled = false;
      m_currentMetrics.pauseReason = "Margin usage too high";
      return false;
   }

   // Check trading hours
   if(!IsTradingHoursOK())
   {
      m_currentMetrics.tradingEnabled = false;
      m_currentMetrics.pauseReason = "Outside trading hours";
      return false;
   }

   // Check day filter
   if(!IsDayAllowed())
   {
      m_currentMetrics.tradingEnabled = false;
      m_currentMetrics.pauseReason = "Trading not allowed today";
      return false;
   }

   // Check max open positions
   if(m_orderManager != NULL && m_orderManager.CountOpenPositions() >= InpMaxOpenTrades)
   {
      m_currentMetrics.tradingEnabled = false;
      m_currentMetrics.pauseReason = "Max positions reached";
      return false;
   }

   m_currentMetrics.tradingEnabled = true;
   m_currentMetrics.pauseReason = "";
   return true;
}

//+------------------------------------------------------------------+
//| Check if Drawdown Limit Reached                                   |
//+------------------------------------------------------------------+
bool CRiskGuard::IsDrawdownLimitReached()
{
   double dailyDD = GetDailyDrawdown();
   double weeklyDD = GetWeeklyDrawdown();

   if(dailyDD >= InpDailyDrawdownLimit)
   {
      m_currentMetrics.pauseReason = StringFormat("Daily drawdown limit reached: %.2f%%", dailyDD);
      Print(m_currentMetrics.pauseReason);
      return true;
   }

   if(weeklyDD >= InpWeeklyDrawdownLimit)
   {
      m_currentMetrics.pauseReason = StringFormat("Weekly drawdown limit reached: %.2f%%", weeklyDD);
      Print(m_currentMetrics.pauseReason);
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if Margin is Safe                                           |
//+------------------------------------------------------------------+
bool CRiskGuard::IsMarginSafe()
{
   double equity = m_accountInfo.Equity();
   double margin = m_accountInfo.Margin();

   if(equity <= 0) return false;

   double marginUsage = (margin / equity) * 100.0;

   return marginUsage < InpMaxMarginUsage;
}

//+------------------------------------------------------------------+
//| Check Trading Hours                                               |
//+------------------------------------------------------------------+
bool CRiskGuard::IsTradingHoursOK()
{
   if(!InpUseTradingHours) return true;

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   int hour = dt.hour;

   // Friday special handling
   if(dt.day_of_week == 5 && hour >= InpFridayCloseHour)
      return false;

   // Regular hours check
   if(hour < InpTradingStartHour || hour >= InpTradingEndHour)
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Check if Day is Allowed                                           |
//+------------------------------------------------------------------+
bool CRiskGuard::IsDayAllowed()
{
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   switch(dt.day_of_week)
   {
      case 0: return false; // Sunday
      case 1: return InpTradeMonday;
      case 2: return InpTradeTuesday;
      case 3: return InpTradeWednesday;
      case 4: return InpTradeThursday;
      case 5: return InpTradeFriday;
      case 6: return false; // Saturday
   }

   return false;
}

//+------------------------------------------------------------------+
//| Get Current Drawdown from High Water Mark                         |
//+------------------------------------------------------------------+
double CRiskGuard::GetCurrentDrawdown()
{
   double equity = m_accountInfo.Equity();

   // Update high water mark
   if(equity > m_highWaterMark)
      m_highWaterMark = equity;

   if(m_highWaterMark <= 0) return 0;

   return ((m_highWaterMark - equity) / m_highWaterMark) * 100.0;
}

//+------------------------------------------------------------------+
//| Get Daily Drawdown                                                |
//+------------------------------------------------------------------+
double CRiskGuard::GetDailyDrawdown()
{
   CheckDailyReset();

   double equity = m_accountInfo.Equity();

   if(m_dailyStartBalance <= 0) return 0;

   double dd = ((m_dailyStartBalance - equity) / m_dailyStartBalance) * 100.0;
   return MathMax(0, dd);
}

//+------------------------------------------------------------------+
//| Get Weekly Drawdown                                               |
//+------------------------------------------------------------------+
double CRiskGuard::GetWeeklyDrawdown()
{
   CheckWeeklyReset();

   double equity = m_accountInfo.Equity();

   if(m_weeklyStartBalance <= 0) return 0;

   double dd = ((m_weeklyStartBalance - equity) / m_weeklyStartBalance) * 100.0;
   return MathMax(0, dd);
}

//+------------------------------------------------------------------+
//| Get Max Drawdown (all time)                                       |
//+------------------------------------------------------------------+
double CRiskGuard::GetMaxDrawdown()
{
   return GetCurrentDrawdown();
}

//+------------------------------------------------------------------+
//| Calculate Optimal Lot Size                                        |
//+------------------------------------------------------------------+
double CRiskGuard::CalculateOptimalLotSize(double slPips)
{
   double riskPercent = GetAdjustedRiskPercent();
   return CalculatePositionSize(riskPercent, slPips);
}

//+------------------------------------------------------------------+
//| Get Adjusted Risk Percent based on Self-Correction                |
//+------------------------------------------------------------------+
double CRiskGuard::GetAdjustedRiskPercent()
{
   double baseRisk = InpRiskPercent;

   if(!InpUseSelfCorrection)
      return baseRisk;

   // Apply lot multiplier from self-correction
   double adjustedRisk = baseRisk * m_lotMultiplier;

   // Apply Kelly fraction if available
   if(m_kellyFraction > 0 && m_kellyFraction < 1.0)
   {
      // Use half-Kelly for safety
      double kellyAdjusted = baseRisk * m_kellyFraction * 0.5;
      adjustedRisk = MathMin(adjustedRisk, kellyAdjusted);
   }

   // Apply drawdown-based reduction
   double currentDD = GetCurrentDrawdown();
   if(currentDD > 5.0)
   {
      // Reduce risk as drawdown increases
      double ddFactor = 1.0 - (currentDD / 100.0);
      adjustedRisk *= ddFactor;
   }

   // Clamp to min/max
   adjustedRisk = MathMax(adjustedRisk, 0.5); // Minimum 0.5%
   adjustedRisk = MathMin(adjustedRisk, InpMaxRiskPercent);

   return adjustedRisk;
}

//+------------------------------------------------------------------+
//| Calculate Kelly Fraction                                          |
//+------------------------------------------------------------------+
double CRiskGuard::CalculateKellyFraction()
{
   if(m_orderManager == NULL) return 0.5;

   double winRate = m_orderManager.GetWinRate() / 100.0;
   double profitFactor = m_orderManager.GetProfitFactor();

   if(winRate <= 0 || winRate >= 1.0) return 0.5;
   if(profitFactor <= 1.0) return 0.25; // Reduce size if not profitable

   // Average win/loss ratio
   double avgWinLossRatio = profitFactor; // Approximation

   // Kelly formula: f* = (bp - q) / b
   // where b = avg win/loss ratio, p = win probability, q = 1-p
   double kellyF = (avgWinLossRatio * winRate - (1.0 - winRate)) / avgWinLossRatio;

   // Clamp Kelly to reasonable range
   kellyF = MathMax(0.1, kellyF);
   kellyF = MathMin(0.5, kellyF); // Never risk more than 50% Kelly

   m_kellyFraction = kellyF;
   return kellyF;
}

//+------------------------------------------------------------------+
//| Update Self-Correction State                                      |
//+------------------------------------------------------------------+
void CRiskGuard::UpdateSelfCorrection()
{
   if(!InpUseSelfCorrection) return;
   if(m_orderManager == NULL) return;

   // Update trade history
   m_orderManager.UpdateTradeHistory();

   int consecWins = m_orderManager.GetConsecutiveWins();
   int consecLosses = m_orderManager.GetConsecutiveLosses();

   // Reduce size after consecutive losses
   if(consecLosses >= InpConsecLossReduce)
   {
      // Progressive reduction
      int lossesOverThreshold = consecLosses - InpConsecLossReduce + 1;
      m_lotMultiplier = InpLossReductionFactor;

      // Further reduction for extended losing streak
      for(int i = 1; i < lossesOverThreshold && i < 3; i++)
         m_lotMultiplier *= InpLossReductionFactor;

      // Apply floor
      m_lotMultiplier = MathMax(m_lotMultiplier, InpMinSizeMultiplier);

      Print("Self-Correction: ", consecLosses, " consecutive losses. Lot multiplier: ", m_lotMultiplier);

      // Trigger cooldown after significant losses
      if(consecLosses >= InpConsecLossReduce * 2)
      {
         TriggerCooldown(30); // 30 minute cooldown
      }
   }
   // Increase size after consecutive wins
   else if(consecWins >= InpConsecWinIncrease)
   {
      // Progressive increase
      int winsOverThreshold = consecWins - InpConsecWinIncrease + 1;
      m_lotMultiplier = InpWinIncreaseFactor;

      // Further increase for winning streak
      for(int i = 1; i < winsOverThreshold && i < 2; i++)
         m_lotMultiplier *= InpWinIncreaseFactor;

      // Apply cap
      m_lotMultiplier = MathMin(m_lotMultiplier, InpMaxSizeMultiplier);

      Print("Self-Correction: ", consecWins, " consecutive wins. Lot multiplier: ", m_lotMultiplier);
   }
   else
   {
      // Gradually return to normal
      if(m_lotMultiplier < 1.0)
         m_lotMultiplier = MathMin(1.0, m_lotMultiplier * 1.1);
      else if(m_lotMultiplier > 1.0)
         m_lotMultiplier = MathMax(1.0, m_lotMultiplier * 0.9);
   }

   // Update Kelly fraction
   CalculateKellyFraction();
}

//+------------------------------------------------------------------+
//| Get Current Lot Multiplier                                        |
//+------------------------------------------------------------------+
double CRiskGuard::GetLotMultiplier()
{
   return m_lotMultiplier;
}

//+------------------------------------------------------------------+
//| Trigger Cooldown Period                                           |
//+------------------------------------------------------------------+
void CRiskGuard::TriggerCooldown(int minutes)
{
   m_isCoolingDown = true;
   m_cooldownEndTime = TimeCurrent() + minutes * 60;
   Print("Cooldown triggered for ", minutes, " minutes until ", TimeToString(m_cooldownEndTime));
}

//+------------------------------------------------------------------+
//| Check if Currently in Cooldown                                    |
//+------------------------------------------------------------------+
bool CRiskGuard::IsCoolingDown()
{
   if(!m_isCoolingDown) return false;

   if(TimeCurrent() >= m_cooldownEndTime)
   {
      m_isCoolingDown = false;
      Print("Cooldown ended. Trading resumed.");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Reset After Drawdown                                              |
//+------------------------------------------------------------------+
void CRiskGuard::ResetAfterDrawdown()
{
   m_lotMultiplier = InpMinSizeMultiplier;
   m_isCoolingDown = false;
   Print("Reset after drawdown. Starting with minimum lot multiplier.");
}

//+------------------------------------------------------------------+
//| Update All Metrics                                                |
//+------------------------------------------------------------------+
void CRiskGuard::UpdateMetrics()
{
   CheckDailyReset();
   CheckWeeklyReset();

   m_currentMetrics.accountBalance = m_accountInfo.Balance();
   m_currentMetrics.accountEquity = m_accountInfo.Equity();
   m_currentMetrics.accountMargin = m_accountInfo.Margin();
   m_currentMetrics.freeMargin = m_accountInfo.FreeMargin();

   m_currentMetrics.dailyPnL = GetDailyPnL();
   m_currentMetrics.weeklyPnL = GetWeeklyPnL();
   m_currentMetrics.dailyDrawdown = GetDailyDrawdown();
   m_currentMetrics.weeklyDrawdown = GetWeeklyDrawdown();
   m_currentMetrics.maxDrawdown = GetMaxDrawdown();

   if(m_orderManager != NULL)
   {
      m_currentMetrics.totalTrades = m_orderManager.GetTotalTrades();
      m_currentMetrics.winningTrades = m_orderManager.GetWinningTrades();
      m_currentMetrics.losingTrades = m_orderManager.GetLosingTrades();
      m_currentMetrics.winRate = m_orderManager.GetWinRate();
      m_currentMetrics.consecutiveWins = m_orderManager.GetConsecutiveWins();
      m_currentMetrics.consecutiveLosses = m_orderManager.GetConsecutiveLosses();
   }

   m_currentMetrics.currentLotMultiplier = m_lotMultiplier;
}

//+------------------------------------------------------------------+
//| Reset Daily Metrics                                               |
//+------------------------------------------------------------------+
void CRiskGuard::ResetDailyMetrics()
{
   m_dailyStartBalance = m_accountInfo.Balance();

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   m_dailyResetTime = StructToTime(dt) + 24 * 60 * 60; // Next day

   Print("Daily metrics reset. New start balance: ", m_dailyStartBalance);
}

//+------------------------------------------------------------------+
//| Reset Weekly Metrics                                              |
//+------------------------------------------------------------------+
void CRiskGuard::ResetWeeklyMetrics()
{
   m_weeklyStartBalance = m_accountInfo.Balance();

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   int daysToMonday = (8 - dt.day_of_week) % 7;
   if(daysToMonday == 0) daysToMonday = 7;

   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   m_weeklyResetTime = StructToTime(dt) + daysToMonday * 24 * 60 * 60;

   Print("Weekly metrics reset. New start balance: ", m_weeklyStartBalance);
}

//+------------------------------------------------------------------+
//| Check and Perform Daily Reset                                     |
//+------------------------------------------------------------------+
void CRiskGuard::CheckDailyReset()
{
   if(TimeCurrent() >= m_dailyResetTime)
   {
      ResetDailyMetrics();
   }
}

//+------------------------------------------------------------------+
//| Check and Perform Weekly Reset                                    |
//+------------------------------------------------------------------+
void CRiskGuard::CheckWeeklyReset()
{
   if(TimeCurrent() >= m_weeklyResetTime)
   {
      ResetWeeklyMetrics();
   }
}

//+------------------------------------------------------------------+
//| Get Daily P&L                                                     |
//+------------------------------------------------------------------+
double CRiskGuard::GetDailyPnL()
{
   return m_accountInfo.Equity() - m_dailyStartBalance;
}

//+------------------------------------------------------------------+
//| Get Weekly P&L                                                    |
//+------------------------------------------------------------------+
double CRiskGuard::GetWeeklyPnL()
{
   return m_accountInfo.Equity() - m_weeklyStartBalance;
}

//+------------------------------------------------------------------+
//| Calculate Position Size                                           |
//+------------------------------------------------------------------+
double CRiskGuard::CalculatePositionSize(double riskPercent, double slPips)
{
   if(m_orderManager == NULL) return InpMinLotSize;

   double lots = m_orderManager.CalculateLotSize(riskPercent, slPips);

   // Apply lot multiplier
   lots *= m_lotMultiplier;

   // Check against max allowable
   double maxLots = GetMaxAllowableLots();
   lots = MathMin(lots, maxLots);

   return m_orderManager.NormalizeLotSize(lots);
}

//+------------------------------------------------------------------+
//| Get Maximum Allowable Lots Based on Margin                        |
//+------------------------------------------------------------------+
double CRiskGuard::GetMaxAllowableLots()
{
   double freeMargin = m_accountInfo.FreeMargin();
   double equity = m_accountInfo.Equity();

   // Don't use more than configured margin percentage
   double maxMarginToUse = equity * (InpMaxMarginUsage / 100.0);
   double currentMargin = m_accountInfo.Margin();
   double availableMargin = maxMarginToUse - currentMargin;

   if(availableMargin <= 0) return 0;

   // Calculate lots based on margin requirement
   // This is approximate - margin per lot varies by broker
   double marginPerLot = SymbolInfoDouble(m_symbol, SYMBOL_MARGIN_INITIAL);
   if(marginPerLot <= 0) marginPerLot = 1000; // Fallback

   double maxLots = availableMargin / marginPerLot;

   return MathMin(maxLots, InpMaxLotSize);
}

//+------------------------------------------------------------------+
//| Get Trading Status String                                         |
//+------------------------------------------------------------------+
string CRiskGuard::GetTradingStatus()
{
   if(!m_currentMetrics.tradingEnabled)
      return "PAUSED: " + m_currentMetrics.pauseReason;

   return StringFormat("ACTIVE | DD: %.2f%% | Mult: %.2f",
                       m_currentMetrics.dailyDrawdown,
                       m_lotMultiplier);
}

//+------------------------------------------------------------------+
//| Get Pause Reason                                                  |
//+------------------------------------------------------------------+
string CRiskGuard::GetPauseReason()
{
   return m_currentMetrics.pauseReason;
}

//+------------------------------------------------------------------+
//| Check if Should Reduce Exposure                                   |
//+------------------------------------------------------------------+
bool CRiskGuard::ShouldReduceExposure()
{
   // Reduce exposure if approaching daily limit
   double dailyDD = GetDailyDrawdown();
   if(dailyDD > InpDailyDrawdownLimit * 0.7)
      return true;

   // Reduce if consecutive losses
   if(m_orderManager != NULL && m_orderManager.GetConsecutiveLosses() >= 2)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Emergency Close All Positions                                     |
//+------------------------------------------------------------------+
void CRiskGuard::EmergencyCloseAll()
{
   if(m_orderManager != NULL)
   {
      Print("EMERGENCY: Closing all positions!");
      m_orderManager.CloseAllPositions();
      TriggerCooldown(60); // 1 hour cooldown
   }
}

#endif // XM_RISKGUARD_MQH
//+------------------------------------------------------------------+
