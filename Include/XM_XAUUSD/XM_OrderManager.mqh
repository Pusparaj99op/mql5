//+------------------------------------------------------------------+
//|                                              XM_OrderManager.mqh |
//|                        Order Execution & Trade Management        |
//|                              Copyright 2024-2026, XM_XAUUSD Bot  |
//+------------------------------------------------------------------+
#property copyright "XM_XAUUSD Bot"
#property link      "https://github.com/Pusparaj99op/XM_XAUUSD"
#property version   "1.00"
#property strict

#ifndef XM_ORDERMANAGER_MQH
#define XM_ORDERMANAGER_MQH

#include "XM_Config.mqh"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

//+------------------------------------------------------------------+
//| COrderManager Class                                               |
//+------------------------------------------------------------------+
class COrderManager
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   int               m_magicNumber;
   string            m_comment;

   CTrade            m_trade;
   CPositionInfo     m_positionInfo;
   COrderInfo        m_orderInfo;
   CSymbolInfo       m_symbolInfo;
   CAccountInfo      m_accountInfo;

   double            m_pointValue;
   double            m_lotStep;
   double            m_minLot;
   double            m_maxLot;
   int               m_digits;
   double            m_tickSize;
   double            m_tickValue;
   double            m_contractSize;

   // Trade history tracking
   int               m_totalTrades;
   int               m_winningTrades;
   int               m_losingTrades;
   int               m_consecutiveWins;
   int               m_consecutiveLosses;
   double            m_totalProfit;
   double            m_totalLoss;
   datetime          m_lastTradeTime;
   double            m_lastTradeProfit;

   bool              m_initialized;

public:
   //--- Constructor/Destructor
                     COrderManager();
                    ~COrderManager();

   //--- Initialization
   bool              Initialize(string symbol, ENUM_TIMEFRAMES tf, int magic, string comment);

   //--- Order operations
   bool              OpenBuy(double lots, double sl, double tp, string reason = "");
   bool              OpenSell(double lots, double sl, double tp, string reason = "");
   bool              ModifyPosition(ulong ticket, double sl, double tp);
   bool              ClosePosition(ulong ticket);
   bool              CloseAllPositions();
   bool              ClosePositionPartial(ulong ticket, double lots);

   //--- Position management
   int               CountOpenPositions();
   int               CountBuyPositions();
   int               CountSellPositions();
   double            GetTotalOpenVolume();
   double            GetOpenPnL();
   ulong             GetLastPositionTicket();
   bool              HasOpenPosition();

   //--- SL/TP calculations
   double            CalculateSL(ENUM_SIGNAL_TYPE direction, double entryPrice, double atr);
   double            CalculateTP(ENUM_SIGNAL_TYPE direction, double entryPrice, double atr);
   double            CalculateDynamicSL(ENUM_SIGNAL_TYPE direction, double entryPrice, double atr, double srLevel);
   double            CalculateDynamicTP(ENUM_SIGNAL_TYPE direction, double entryPrice, double atr, double srLevel);

   //--- Lot size calculations
   double            CalculateLotSize(double riskPercent, double slPips);
   double            CalculateLotSizeByRisk(double riskAmount, double slPips);
   double            NormalizeLotSize(double lots);

   //--- Trailing stop & breakeven
   void              ManageTrailingStop();
   void              ManageBreakeven();
   void              TrailPosition(ulong ticket, double trailPoints);
   void              MoveToBreakeven(ulong ticket, double plusPips);

   //--- Trade history
   void              UpdateTradeHistory();
   int               GetTotalTrades() { return m_totalTrades; }
   int               GetWinningTrades() { return m_winningTrades; }
   int               GetLosingTrades() { return m_losingTrades; }
   int               GetConsecutiveWins() { return m_consecutiveWins; }
   int               GetConsecutiveLosses() { return m_consecutiveLosses; }
   double            GetWinRate();
   double            GetProfitFactor();
   double            GetLastTradeProfit() { return m_lastTradeProfit; }

   //--- Utility
   double            PipsToPrice(double pips);
   double            PriceToPoints(double price);
   double            GetSpread();
   bool              IsSpreadOK();
   bool              IsMarketOpen();
   double            GetContractSize() { return m_contractSize; }
   double            GetTickValue() { return m_tickValue; }

   //--- Price normalization
   double            NormalizePrice(double price);
   double            NormalizeVolume(double volume);

   //--- Chart Drawing
   void              DrawTradeOnChart(ENUM_SIGNAL_TYPE direction, double entryPrice, double sl, double tp, double lots, string reason);
   void              UpdateTradeLines();
   void              DrawTradeClose(ulong ticket, double closePrice, double profit);
   void              CleanupTradeDrawings();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
COrderManager::COrderManager()
{
   m_symbol = "";
   m_timeframe = PERIOD_M5;
   m_magicNumber = 0;
   m_comment = "";
   m_initialized = false;

   m_totalTrades = 0;
   m_winningTrades = 0;
   m_losingTrades = 0;
   m_consecutiveWins = 0;
   m_consecutiveLosses = 0;
   m_totalProfit = 0;
   m_totalLoss = 0;
   m_lastTradeTime = 0;
   m_lastTradeProfit = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
COrderManager::~COrderManager()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool COrderManager::Initialize(string symbol, ENUM_TIMEFRAMES tf, int magic, string comment)
{
   m_symbol = symbol;
   m_timeframe = tf;
   m_magicNumber = magic;
   m_comment = comment;

   // Initialize symbol info
   if(!m_symbolInfo.Name(m_symbol))
   {
      Print("Error: Symbol ", m_symbol, " not found");
      return false;
   }

   m_symbolInfo.RefreshRates();

   m_pointValue = m_symbolInfo.Point();
   m_digits = (int)m_symbolInfo.Digits();
   m_lotStep = m_symbolInfo.LotsStep();
   m_minLot = m_symbolInfo.LotsMin();
   m_maxLot = m_symbolInfo.LotsMax();
   m_tickSize = m_symbolInfo.TickSize();
   m_tickValue = m_symbolInfo.TickValue();
   m_contractSize = m_symbolInfo.ContractSize();

   // Setup trade object
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetDeviationInPoints(10);
   m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   m_trade.SetAsyncMode(false);

   // Update trade history from past trades
   UpdateTradeHistory();

   m_initialized = true;
   Print("Order Manager initialized for ", m_symbol);
   Print("Lot Min: ", m_minLot, " Max: ", m_maxLot, " Step: ", m_lotStep);
   Print("Point: ", m_pointValue, " Tick Value: ", m_tickValue);

   return true;
}

//+------------------------------------------------------------------+
//| Open Buy Position                                                 |
//+------------------------------------------------------------------+
bool COrderManager::OpenBuy(double lots, double sl, double tp, string reason = "")
{
   if(!m_initialized) return false;

   m_symbolInfo.RefreshRates();

   // Validate spread
   if(!IsSpreadOK())
   {
      Print("Spread too high, buy rejected");
      return false;
   }

   double ask = m_symbolInfo.Ask();
   lots = NormalizeLotSize(lots);
   sl = NormalizePrice(sl);
   tp = NormalizePrice(tp);

   string fullComment = m_comment;
   if(reason != "") fullComment += " " + reason;

   if(m_trade.Buy(lots, m_symbol, ask, sl, tp, fullComment))
   {
      Print("Buy order opened: ", lots, " lots at ", ask);
      Print("SL: ", sl, " TP: ", tp);
      Print("Reason: ", reason);
      m_lastTradeTime = TimeCurrent();
      return true;
   }
   else
   {
      Print("Buy order failed: ", m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Open Sell Position                                                |
//+------------------------------------------------------------------+
bool COrderManager::OpenSell(double lots, double sl, double tp, string reason = "")
{
   if(!m_initialized) return false;

   m_symbolInfo.RefreshRates();

   // Validate spread
   if(!IsSpreadOK())
   {
      Print("Spread too high, sell rejected");
      return false;
   }

   double bid = m_symbolInfo.Bid();
   lots = NormalizeLotSize(lots);
   sl = NormalizePrice(sl);
   tp = NormalizePrice(tp);

   string fullComment = m_comment;
   if(reason != "") fullComment += " " + reason;

   if(m_trade.Sell(lots, m_symbol, bid, sl, tp, fullComment))
   {
      Print("Sell order opened: ", lots, " lots at ", bid);
      Print("SL: ", sl, " TP: ", tp);
      Print("Reason: ", reason);
      m_lastTradeTime = TimeCurrent();
      return true;
   }
   else
   {
      Print("Sell order failed: ", m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Modify Position SL/TP                                             |
//+------------------------------------------------------------------+
bool COrderManager::ModifyPosition(ulong ticket, double sl, double tp)
{
   sl = NormalizePrice(sl);
   tp = NormalizePrice(tp);

   if(m_trade.PositionModify(ticket, sl, tp))
   {
      Print("Position ", ticket, " modified. New SL: ", sl, " TP: ", tp);
      return true;
   }
   else
   {
      Print("Position modify failed: ", m_trade.ResultRetcode());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Close Position                                                    |
//+------------------------------------------------------------------+
bool COrderManager::ClosePosition(ulong ticket)
{
   if(m_trade.PositionClose(ticket))
   {
      Print("Position ", ticket, " closed");
      UpdateTradeHistory();
      return true;
   }
   else
   {
      Print("Position close failed: ", m_trade.ResultRetcode());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Close All Positions                                               |
//+------------------------------------------------------------------+
bool COrderManager::CloseAllPositions()
{
   bool allClosed = true;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_positionInfo.SelectByIndex(i))
      {
         if(m_positionInfo.Symbol() == m_symbol && m_positionInfo.Magic() == m_magicNumber)
         {
            if(!ClosePosition(m_positionInfo.Ticket()))
               allClosed = false;
         }
      }
   }

   return allClosed;
}

//+------------------------------------------------------------------+
//| Close Position Partially                                          |
//+------------------------------------------------------------------+
bool COrderManager::ClosePositionPartial(ulong ticket, double lots)
{
   if(!m_positionInfo.SelectByTicket(ticket))
      return false;

   lots = NormalizeLotSize(lots);

   if(lots >= m_positionInfo.Volume())
      return ClosePosition(ticket);

   if(m_trade.PositionClosePartial(ticket, lots))
   {
      Print("Partial close: ", lots, " lots from position ", ticket);
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Count Open Positions                                              |
//+------------------------------------------------------------------+
int COrderManager::CountOpenPositions()
{
   int count = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(m_positionInfo.SelectByIndex(i))
      {
         if(m_positionInfo.Symbol() == m_symbol && m_positionInfo.Magic() == m_magicNumber)
            count++;
      }
   }

   return count;
}

//+------------------------------------------------------------------+
//| Count Buy Positions                                               |
//+------------------------------------------------------------------+
int COrderManager::CountBuyPositions()
{
   int count = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(m_positionInfo.SelectByIndex(i))
      {
         if(m_positionInfo.Symbol() == m_symbol &&
            m_positionInfo.Magic() == m_magicNumber &&
            m_positionInfo.PositionType() == POSITION_TYPE_BUY)
            count++;
      }
   }

   return count;
}

//+------------------------------------------------------------------+
//| Count Sell Positions                                              |
//+------------------------------------------------------------------+
int COrderManager::CountSellPositions()
{
   int count = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(m_positionInfo.SelectByIndex(i))
      {
         if(m_positionInfo.Symbol() == m_symbol &&
            m_positionInfo.Magic() == m_magicNumber &&
            m_positionInfo.PositionType() == POSITION_TYPE_SELL)
            count++;
      }
   }

   return count;
}

//+------------------------------------------------------------------+
//| Get Total Open Volume                                             |
//+------------------------------------------------------------------+
double COrderManager::GetTotalOpenVolume()
{
   double volume = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(m_positionInfo.SelectByIndex(i))
      {
         if(m_positionInfo.Symbol() == m_symbol && m_positionInfo.Magic() == m_magicNumber)
            volume += m_positionInfo.Volume();
      }
   }

   return volume;
}

//+------------------------------------------------------------------+
//| Get Open P&L                                                      |
//+------------------------------------------------------------------+
double COrderManager::GetOpenPnL()
{
   double pnl = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(m_positionInfo.SelectByIndex(i))
      {
         if(m_positionInfo.Symbol() == m_symbol && m_positionInfo.Magic() == m_magicNumber)
            pnl += m_positionInfo.Profit() + m_positionInfo.Swap() + m_positionInfo.Commission();
      }
   }

   return pnl;
}

//+------------------------------------------------------------------+
//| Get Last Position Ticket                                          |
//+------------------------------------------------------------------+
ulong COrderManager::GetLastPositionTicket()
{
   ulong ticket = 0;
   datetime lastTime = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(m_positionInfo.SelectByIndex(i))
      {
         if(m_positionInfo.Symbol() == m_symbol && m_positionInfo.Magic() == m_magicNumber)
         {
            if(m_positionInfo.Time() > lastTime)
            {
               lastTime = m_positionInfo.Time();
               ticket = m_positionInfo.Ticket();
            }
         }
      }
   }

   return ticket;
}

//+------------------------------------------------------------------+
//| Has Open Position                                                 |
//+------------------------------------------------------------------+
bool COrderManager::HasOpenPosition()
{
   return CountOpenPositions() > 0;
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                               |
//+------------------------------------------------------------------+
double COrderManager::CalculateSL(ENUM_SIGNAL_TYPE direction, double entryPrice, double atr)
{
   double slDistance = atr * InpSLMultiplier;

   // Apply min/max constraints
   double minSL = InpMinSLPips * m_pointValue * 10;
   double maxSL = InpMaxSLPips * m_pointValue * 10;

   slDistance = MathMax(slDistance, minSL);
   slDistance = MathMin(slDistance, maxSL);

   if(direction == SIGNAL_BUY)
      return NormalizePrice(entryPrice - slDistance);
   else if(direction == SIGNAL_SELL)
      return NormalizePrice(entryPrice + slDistance);

   return 0;
}

//+------------------------------------------------------------------+
//| Calculate Take Profit                                             |
//+------------------------------------------------------------------+
double COrderManager::CalculateTP(ENUM_SIGNAL_TYPE direction, double entryPrice, double atr)
{
   double tpDistance = atr * InpTPMultiplier;

   // Apply min/max constraints
   double minTP = InpMinTPPips * m_pointValue * 10;
   double maxTP = InpMaxTPPips * m_pointValue * 10;

   tpDistance = MathMax(tpDistance, minTP);
   tpDistance = MathMin(tpDistance, maxTP);

   if(direction == SIGNAL_BUY)
      return NormalizePrice(entryPrice + tpDistance);
   else if(direction == SIGNAL_SELL)
      return NormalizePrice(entryPrice - tpDistance);

   return 0;
}

//+------------------------------------------------------------------+
//| Calculate Dynamic SL using S/R                                    |
//+------------------------------------------------------------------+
double COrderManager::CalculateDynamicSL(ENUM_SIGNAL_TYPE direction, double entryPrice, double atr, double srLevel)
{
   double atrSL = CalculateSL(direction, entryPrice, atr);

   if(srLevel <= 0)
      return atrSL;

   double buffer = 10 * m_pointValue * 10; // 10 pips buffer beyond S/R

   if(direction == SIGNAL_BUY)
   {
      // SL below support
      double srSL = srLevel - buffer;
      // Use the closer one (less risk)
      return NormalizePrice(MathMax(atrSL, srSL));
   }
   else if(direction == SIGNAL_SELL)
   {
      // SL above resistance
      double srSL = srLevel + buffer;
      // Use the closer one (less risk)
      return NormalizePrice(MathMin(atrSL, srSL));
   }

   return atrSL;
}

//+------------------------------------------------------------------+
//| Calculate Dynamic TP using S/R                                    |
//+------------------------------------------------------------------+
double COrderManager::CalculateDynamicTP(ENUM_SIGNAL_TYPE direction, double entryPrice, double atr, double srLevel)
{
   double atrTP = CalculateTP(direction, entryPrice, atr);

   if(srLevel <= 0)
      return atrTP;

   double buffer = 5 * m_pointValue * 10; // 5 pips buffer before S/R

   if(direction == SIGNAL_BUY)
   {
      // TP at resistance
      double srTP = srLevel - buffer;
      // Check if S/R target is better than ATR target
      if(srTP > entryPrice && srTP < atrTP)
         return NormalizePrice(srTP);
   }
   else if(direction == SIGNAL_SELL)
   {
      // TP at support
      double srTP = srLevel + buffer;
      // Check if S/R target is better than ATR target
      if(srTP < entryPrice && srTP > atrTP)
         return NormalizePrice(srTP);
   }

   return atrTP;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk Percent                          |
//+------------------------------------------------------------------+
double COrderManager::CalculateLotSize(double riskPercent, double slPips)
{
   if(slPips <= 0) return m_minLot;

   double accountBalance = m_accountInfo.Balance();
   double riskAmount = accountBalance * riskPercent / 100.0;

   return CalculateLotSizeByRisk(riskAmount, slPips);
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk Amount                           |
//+------------------------------------------------------------------+
double COrderManager::CalculateLotSizeByRisk(double riskAmount, double slPips)
{
   if(slPips <= 0 || riskAmount <= 0) return m_minLot;

   m_symbolInfo.RefreshRates();

   // For Gold: 1 standard lot = 100 oz, 1 pip = 0.01
   // Calculate pip value per lot
   double pipValue = m_tickValue * (m_pointValue * 10 / m_tickSize);

   if(pipValue <= 0)
   {
      // Fallback calculation for Gold
      // 1 pip = $1 per 0.01 lot typically
      pipValue = 1.0; // Approximate for Gold
   }

   double lots = riskAmount / (slPips * pipValue);

   return NormalizeLotSize(lots);
}

//+------------------------------------------------------------------+
//| Normalize Lot Size                                                |
//+------------------------------------------------------------------+
double COrderManager::NormalizeLotSize(double lots)
{
   lots = MathMax(lots, m_minLot);
   lots = MathMin(lots, m_maxLot);
   lots = MathMin(lots, InpMaxLotSize);
   lots = MathMax(lots, InpMinLotSize);

   // Round to lot step
   lots = MathFloor(lots / m_lotStep) * m_lotStep;

   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Manage Trailing Stop for All Positions                            |
//+------------------------------------------------------------------+
void COrderManager::ManageTrailingStop()
{
   if(!InpUseTrailingStop) return;

   m_symbolInfo.RefreshRates();
   double trailStart = InpTrailingStartPips * m_pointValue * 10;
   double trailStep = InpTrailingStepPips * m_pointValue * 10;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(!m_positionInfo.SelectByIndex(i)) continue;
      if(m_positionInfo.Symbol() != m_symbol) continue;
      if(m_positionInfo.Magic() != m_magicNumber) continue;

      double openPrice = m_positionInfo.PriceOpen();
      double currentSL = m_positionInfo.StopLoss();
      double currentTP = m_positionInfo.TakeProfit();

      if(m_positionInfo.PositionType() == POSITION_TYPE_BUY)
      {
         double currentPrice = m_symbolInfo.Bid();
         double profit = currentPrice - openPrice;

         if(profit >= trailStart)
         {
            double newSL = currentPrice - trailStep;
            if(newSL > currentSL && newSL < currentPrice)
            {
               ModifyPosition(m_positionInfo.Ticket(), NormalizePrice(newSL), currentTP);
            }
         }
      }
      else if(m_positionInfo.PositionType() == POSITION_TYPE_SELL)
      {
         double currentPrice = m_symbolInfo.Ask();
         double profit = openPrice - currentPrice;

         if(profit >= trailStart)
         {
            double newSL = currentPrice + trailStep;
            if(newSL < currentSL || currentSL == 0)
            {
               if(newSL > currentPrice)
               {
                  ModifyPosition(m_positionInfo.Ticket(), NormalizePrice(newSL), currentTP);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage Breakeven for All Positions                                |
//+------------------------------------------------------------------+
void COrderManager::ManageBreakeven()
{
   if(!InpUseBreakeven) return;

   m_symbolInfo.RefreshRates();
   double beLevel = InpBreakevenPips * m_pointValue * 10;
   double bePlus = InpBreakevenPlusPips * m_pointValue * 10;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(!m_positionInfo.SelectByIndex(i)) continue;
      if(m_positionInfo.Symbol() != m_symbol) continue;
      if(m_positionInfo.Magic() != m_magicNumber) continue;

      double openPrice = m_positionInfo.PriceOpen();
      double currentSL = m_positionInfo.StopLoss();
      double currentTP = m_positionInfo.TakeProfit();

      if(m_positionInfo.PositionType() == POSITION_TYPE_BUY)
      {
         double currentPrice = m_symbolInfo.Bid();
         double profit = currentPrice - openPrice;

         // Move to breakeven if in profit and SL is still below entry
         if(profit >= beLevel && currentSL < openPrice)
         {
            double newSL = openPrice + bePlus;
            ModifyPosition(m_positionInfo.Ticket(), NormalizePrice(newSL), currentTP);
            Print("Buy position moved to breakeven + ", bePlus / m_pointValue / 10, " pips");
         }
      }
      else if(m_positionInfo.PositionType() == POSITION_TYPE_SELL)
      {
         double currentPrice = m_symbolInfo.Ask();
         double profit = openPrice - currentPrice;

         // Move to breakeven if in profit and SL is still above entry
         if(profit >= beLevel && (currentSL > openPrice || currentSL == 0))
         {
            double newSL = openPrice - bePlus;
            ModifyPosition(m_positionInfo.Ticket(), NormalizePrice(newSL), currentTP);
            Print("Sell position moved to breakeven + ", bePlus / m_pointValue / 10, " pips");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trail Single Position                                             |
//+------------------------------------------------------------------+
void COrderManager::TrailPosition(ulong ticket, double trailPoints)
{
   if(!m_positionInfo.SelectByTicket(ticket)) return;

   m_symbolInfo.RefreshRates();
   double trailDistance = trailPoints * m_pointValue;

   double openPrice = m_positionInfo.PriceOpen();
   double currentSL = m_positionInfo.StopLoss();
   double currentTP = m_positionInfo.TakeProfit();

   if(m_positionInfo.PositionType() == POSITION_TYPE_BUY)
   {
      double currentPrice = m_symbolInfo.Bid();
      double newSL = currentPrice - trailDistance;

      if(newSL > currentSL && newSL < currentPrice)
         ModifyPosition(ticket, NormalizePrice(newSL), currentTP);
   }
   else if(m_positionInfo.PositionType() == POSITION_TYPE_SELL)
   {
      double currentPrice = m_symbolInfo.Ask();
      double newSL = currentPrice + trailDistance;

      if(newSL < currentSL || currentSL == 0)
         ModifyPosition(ticket, NormalizePrice(newSL), currentTP);
   }
}

//+------------------------------------------------------------------+
//| Move Position to Breakeven                                        |
//+------------------------------------------------------------------+
void COrderManager::MoveToBreakeven(ulong ticket, double plusPips)
{
   if(!m_positionInfo.SelectByTicket(ticket)) return;

   double openPrice = m_positionInfo.PriceOpen();
   double currentTP = m_positionInfo.TakeProfit();
   double plusDistance = plusPips * m_pointValue * 10;

   double newSL;
   if(m_positionInfo.PositionType() == POSITION_TYPE_BUY)
      newSL = openPrice + plusDistance;
   else
      newSL = openPrice - plusDistance;

   ModifyPosition(ticket, NormalizePrice(newSL), currentTP);
}

//+------------------------------------------------------------------+
//| Update Trade History                                              |
//+------------------------------------------------------------------+
void COrderManager::UpdateTradeHistory()
{
   // Reset counters
   m_totalTrades = 0;
   m_winningTrades = 0;
   m_losingTrades = 0;
   m_totalProfit = 0;
   m_totalLoss = 0;

   // Get history for last N days
   datetime fromDate = TimeCurrent() - 30 * 24 * 60 * 60; // Last 30 days

   if(!HistorySelect(fromDate, TimeCurrent()))
      return;

   int totalDeals = HistoryDealsTotal();
   double lastDealProfit = 0;
   datetime lastDealTime = 0;
   bool lastWasWin = false;

   for(int i = 0; i < totalDeals; i++)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0) continue;

      string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
      long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
      ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

      if(dealSymbol != m_symbol || dealMagic != m_magicNumber)
         continue;

      // Only count closed deals (exits)
      if(dealEntry != DEAL_ENTRY_OUT && dealEntry != DEAL_ENTRY_INOUT)
         continue;

      double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
      profit += HistoryDealGetDouble(dealTicket, DEAL_SWAP);
      profit += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);

      datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);

      m_totalTrades++;

      if(profit >= 0)
      {
         m_winningTrades++;
         m_totalProfit += profit;
      }
      else
      {
         m_losingTrades++;
         m_totalLoss += MathAbs(profit);
      }

      // Track last deal for consecutive wins/losses
      if(dealTime > lastDealTime)
      {
         lastDealTime = dealTime;
         lastDealProfit = profit;
      }
   }

   m_lastTradeProfit = lastDealProfit;

   // Calculate consecutive wins/losses (simplified - last N trades)
   m_consecutiveWins = 0;
   m_consecutiveLosses = 0;

   // Look at recent trades
   int lookback = MathMin(InpLookbackTrades, totalDeals);
   for(int i = totalDeals - 1; i >= totalDeals - lookback && i >= 0; i--)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0) continue;

      string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
      long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
      ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

      if(dealSymbol != m_symbol || dealMagic != m_magicNumber)
         continue;

      if(dealEntry != DEAL_ENTRY_OUT && dealEntry != DEAL_ENTRY_INOUT)
         continue;

      double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);

      if(profit >= 0)
      {
         if(m_consecutiveLosses > 0) break;
         m_consecutiveWins++;
      }
      else
      {
         if(m_consecutiveWins > 0) break;
         m_consecutiveLosses++;
      }
   }
}

//+------------------------------------------------------------------+
//| Get Win Rate                                                      |
//+------------------------------------------------------------------+
double COrderManager::GetWinRate()
{
   if(m_totalTrades == 0) return 0;
   return (double)m_winningTrades / (double)m_totalTrades * 100.0;
}

//+------------------------------------------------------------------+
//| Get Profit Factor                                                 |
//+------------------------------------------------------------------+
double COrderManager::GetProfitFactor()
{
   if(m_totalLoss == 0) return (m_totalProfit > 0) ? 999.0 : 0.0;
   return m_totalProfit / m_totalLoss;
}

//+------------------------------------------------------------------+
//| Convert Pips to Price Distance                                    |
//+------------------------------------------------------------------+
double COrderManager::PipsToPrice(double pips)
{
   return pips * m_pointValue * 10;
}

//+------------------------------------------------------------------+
//| Convert Price Distance to Points                                  |
//+------------------------------------------------------------------+
double COrderManager::PriceToPoints(double price)
{
   return price / m_pointValue;
}

//+------------------------------------------------------------------+
//| Get Current Spread                                                |
//+------------------------------------------------------------------+
double COrderManager::GetSpread()
{
   m_symbolInfo.RefreshRates();
   return m_symbolInfo.Ask() - m_symbolInfo.Bid();
}

//+------------------------------------------------------------------+
//| Check if Spread is OK                                             |
//+------------------------------------------------------------------+
bool COrderManager::IsSpreadOK()
{
   int spreadPoints = (int)((GetSpread() / m_pointValue));
   return spreadPoints <= InpMaxSpread;
}

//+------------------------------------------------------------------+
//| Check if Market is Open                                           |
//+------------------------------------------------------------------+
bool COrderManager::IsMarketOpen()
{
   datetime serverTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);

   // Check if weekend
   if(dt.day_of_week == 0 || dt.day_of_week == 6)
      return false;

   // Market should be open during weekdays
   return true;
}

//+------------------------------------------------------------------+
//| Normalize Price                                                   |
//+------------------------------------------------------------------+
double COrderManager::NormalizePrice(double price)
{
   return NormalizeDouble(price, m_digits);
}

//+------------------------------------------------------------------+
//| Normalize Volume                                                  |
//+------------------------------------------------------------------+
double COrderManager::NormalizeVolume(double volume)
{
   return NormalizeLotSize(volume);
}

//+------------------------------------------------------------------+
//| Draw Trade Entry on Chart                                         |
//+------------------------------------------------------------------+
void COrderManager::DrawTradeOnChart(ENUM_SIGNAL_TYPE direction, double entryPrice, double sl, double tp, double lots, string reason)
{
   if(!InpDrawTradeArrows && !InpDrawSLTPLines) return;

   datetime now = TimeCurrent();
   string ticketStr = IntegerToString((long)now);

   // Draw entry arrow
   if(InpDrawTradeArrows)
   {
      string arrowName = "XM_TRADE_Arrow_" + ticketStr;
      if(direction == SIGNAL_BUY)
      {
         ObjectCreate(0, arrowName, OBJ_ARROW_BUY, 0, now, entryPrice);
         ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrDodgerBlue);
      }
      else
      {
         ObjectCreate(0, arrowName, OBJ_ARROW_SELL, 0, now, entryPrice);
         ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrOrangeRed);
      }
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, arrowName, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, arrowName, OBJPROP_TOOLTIP,
         StringFormat("%s | Lots: %.2f | Entry: %.2f\nSL: %.2f | TP: %.2f\n%s",
            (direction == SIGNAL_BUY ? "BUY" : "SELL"), lots, entryPrice, sl, tp, reason));

      // Trade info text near entry
      string textName = "XM_TRADE_Info_" + ticketStr;
      double textPrice = (direction == SIGNAL_BUY) ? entryPrice + 50 * m_pointValue : entryPrice - 50 * m_pointValue;
      ObjectCreate(0, textName, OBJ_TEXT, 0, now, textPrice);
      ObjectSetString(0, textName, OBJPROP_TEXT,
         StringFormat("%s %.2f lots @ %.2f  SL:%.2f  TP:%.2f  RR:1:%.1f",
            (direction == SIGNAL_BUY ? "BUY" : "SELL"), lots, entryPrice, sl, tp,
            (MathAbs(entryPrice - sl) > 0 ? MathAbs(tp - entryPrice) / MathAbs(entryPrice - sl) : 0)));
      ObjectSetString(0, textName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, textName, OBJPROP_COLOR, (direction == SIGNAL_BUY) ? clrDodgerBlue : clrOrangeRed);
      ObjectSetInteger(0, textName, OBJPROP_ANCHOR, ANCHOR_LEFT);
   }

   // Draw SL/TP lines
   if(InpDrawSLTPLines)
   {
      // SL line
      string slName = "XM_SL_" + ticketStr;
      ObjectCreate(0, slName, OBJ_HLINE, 0, 0, sl);
      ObjectSetInteger(0, slName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, slName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, slName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, slName, OBJPROP_BACK, true);
      ObjectSetInteger(0, slName, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, slName, OBJPROP_TOOLTIP, StringFormat("SL: %.2f", sl));

      // SL label
      string slLblName = "XM_SL_Lbl_" + ticketStr;
      ObjectCreate(0, slLblName, OBJ_TEXT, 0, now, sl);
      ObjectSetString(0, slLblName, OBJPROP_TEXT, StringFormat("SL %.2f", sl));
      ObjectSetString(0, slLblName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, slLblName, OBJPROP_FONTSIZE, 7);
      ObjectSetInteger(0, slLblName, OBJPROP_COLOR, clrRed);

      // TP line
      string tpName = "XM_TP_" + ticketStr;
      ObjectCreate(0, tpName, OBJ_HLINE, 0, 0, tp);
      ObjectSetInteger(0, tpName, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, tpName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, tpName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, tpName, OBJPROP_BACK, true);
      ObjectSetInteger(0, tpName, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, tpName, OBJPROP_TOOLTIP, StringFormat("TP: %.2f", tp));

      // TP label
      string tpLblName = "XM_TP_Lbl_" + ticketStr;
      ObjectCreate(0, tpLblName, OBJ_TEXT, 0, now, tp);
      ObjectSetString(0, tpLblName, OBJPROP_TEXT, StringFormat("TP %.2f", tp));
      ObjectSetString(0, tpLblName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, tpLblName, OBJPROP_FONTSIZE, 7);
      ObjectSetInteger(0, tpLblName, OBJPROP_COLOR, clrLime);
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Update SL/TP Lines for Open Trades                                |
//+------------------------------------------------------------------+
void COrderManager::UpdateTradeLines()
{
   if(!InpDrawSLTPLines) return;

   // Remove old SL/TP lines first
   ObjectsDeleteAll(0, "XM_SL_");
   ObjectsDeleteAll(0, "XM_TP_");

   // Redraw for each open position
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(!m_positionInfo.SelectByIndex(i)) continue;
      if(m_positionInfo.Symbol() != m_symbol || m_positionInfo.Magic() != m_magicNumber) continue;

      ulong ticket = m_positionInfo.Ticket();
      string ticketStr = IntegerToString((long)ticket);
      double sl = m_positionInfo.StopLoss();
      double tp = m_positionInfo.TakeProfit();
      datetime openTime = m_positionInfo.Time();

      if(sl > 0)
      {
         string slName = "XM_SL_" + ticketStr;
         ObjectCreate(0, slName, OBJ_HLINE, 0, 0, sl);
         ObjectSetInteger(0, slName, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, slName, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, slName, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, slName, OBJPROP_BACK, true);
         ObjectSetInteger(0, slName, OBJPROP_SELECTABLE, false);
         ObjectSetString(0, slName, OBJPROP_TOOLTIP, StringFormat("SL: %.2f (#%d)", sl, ticket));

         string slLblName = "XM_SL_Lbl_" + ticketStr;
         ObjectCreate(0, slLblName, OBJ_TEXT, 0, openTime, sl);
         ObjectSetString(0, slLblName, OBJPROP_TEXT, StringFormat("SL %.2f", sl));
         ObjectSetString(0, slLblName, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, slLblName, OBJPROP_FONTSIZE, 7);
         ObjectSetInteger(0, slLblName, OBJPROP_COLOR, clrRed);
      }

      if(tp > 0)
      {
         string tpName = "XM_TP_" + ticketStr;
         ObjectCreate(0, tpName, OBJ_HLINE, 0, 0, tp);
         ObjectSetInteger(0, tpName, OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, tpName, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, tpName, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, tpName, OBJPROP_BACK, true);
         ObjectSetInteger(0, tpName, OBJPROP_SELECTABLE, false);
         ObjectSetString(0, tpName, OBJPROP_TOOLTIP, StringFormat("TP: %.2f (#%d)", tp, ticket));

         string tpLblName = "XM_TP_Lbl_" + ticketStr;
         ObjectCreate(0, tpLblName, OBJ_TEXT, 0, openTime, tp);
         ObjectSetString(0, tpLblName, OBJPROP_TEXT, StringFormat("TP %.2f", tp));
         ObjectSetString(0, tpLblName, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, tpLblName, OBJPROP_FONTSIZE, 7);
         ObjectSetInteger(0, tpLblName, OBJPROP_COLOR, clrLime);
      }
   }
}

//+------------------------------------------------------------------+
//| Draw Trade Close Marker on Chart                                  |
//+------------------------------------------------------------------+
void COrderManager::DrawTradeClose(ulong ticket, double closePrice, double profit)
{
   if(!InpDrawTradeArrows) return;

   datetime now = TimeCurrent();
   string ticketStr = IntegerToString((long)ticket);

   string closeName = "XM_TRADE_Close_" + ticketStr;
   if(profit >= 0)
   {
      ObjectCreate(0, closeName, OBJ_ARROW_CHECK, 0, now, closePrice);
      ObjectSetInteger(0, closeName, OBJPROP_COLOR, clrLime);
   }
   else
   {
      ObjectCreate(0, closeName, OBJ_ARROW_STOP, 0, now, closePrice);
      ObjectSetInteger(0, closeName, OBJPROP_COLOR, clrRed);
   }
   ObjectSetInteger(0, closeName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, closeName, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, closeName, OBJPROP_TOOLTIP,
      StringFormat("Close #%d | P&L: %s$%.2f", ticket, (profit >= 0 ? "+" : ""), profit));

   // P&L text
   string plName = "XM_TRADE_PL_" + ticketStr;
   double textPrice = (profit >= 0) ? closePrice + 30 * m_pointValue : closePrice - 30 * m_pointValue;
   ObjectCreate(0, plName, OBJ_TEXT, 0, now, textPrice);
   ObjectSetString(0, plName, OBJPROP_TEXT,
      StringFormat("%s$%.2f", (profit >= 0 ? "+" : ""), profit));
   ObjectSetString(0, plName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, plName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, plName, OBJPROP_COLOR, (profit >= 0) ? clrLime : clrRed);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Cleanup All Trade Chart Drawings                                  |
//+------------------------------------------------------------------+
void COrderManager::CleanupTradeDrawings()
{
   ObjectsDeleteAll(0, "XM_SL_");
   ObjectsDeleteAll(0, "XM_TP_");
   ObjectsDeleteAll(0, "XM_TRADE_");
}

#endif // XM_ORDERMANAGER_MQH
//+------------------------------------------------------------------+
