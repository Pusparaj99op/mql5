//+------------------------------------------------------------------+
//|                                                   GA_Orders.mqh  |
//|                   GoldAlgo Elite - Order Manager                   |
//|           Trade execution, trailing, breakeven, partial close      |
//+------------------------------------------------------------------+
#property copyright "GoldAlgo Elite"
#property strict

#ifndef __GA_ORDERS_MQH__
#define __GA_ORDERS_MQH__

#include "GA_Config.mqh"
#include "GA_Indicators.mqh"
#include "GA_Risk.mqh"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Position metadata tracked per-ticket (class for pointer support)  |
//+------------------------------------------------------------------+
class CPositionMeta
  {
public:
   ulong    ticket;
   double   entryPrice;
   double   entryATR;        // ATR at time of entry
   double   entryScore;      // Signal score at entry
   ENUM_MARKET_REGIME regime; // Regime at entry
   ENUM_SIGNAL_DIR direction; // Buy or sell
   bool     breakEvenApplied;
   bool     partialClosed;
   bool     isPartialDeal;   // Flag: last close was partial (for self-correction)
   datetime openTime;
   double   originalVolume;  // Volume at open, to detect partial closes

   CPositionMeta() : ticket(0), entryPrice(0), entryATR(0), entryScore(0),
                     regime(REGIME_UNKNOWN), direction(SIGNAL_NONE),
                     breakEvenApplied(false), partialClosed(false),
                     isPartialDeal(false), openTime(0), originalVolume(0) {}
  };

//+------------------------------------------------------------------+
//| COrderManager - Trade execution and position management           |
//+------------------------------------------------------------------+
class COrderManager
  {
private:
   CTrade            m_trade;
   CPositionInfo     m_posInfo;
   string            m_symbol;
   long              m_magic;
   CIndicatorEngine *m_ind;
   CRiskManager     *m_risk;

   // Position metadata storage
   CPositionMeta    *m_posMeta[];
   int               m_posMetaCount;

   // Helpers
   int               FindMetaIndex(ulong ticket);
   void              AddMeta(ulong ticket, double price, double atr, double score,
                             ENUM_MARKET_REGIME regime, ENUM_SIGNAL_DIR dir, double volume);
   void              RemoveMeta(ulong ticket);
   void              CleanupStaleMeta();

   // Stop level validation
   double            ValidateStopDistance(double distance);

public:
                     COrderManager();
                    ~COrderManager();

   bool              Init(string symbol, long magic, CIndicatorEngine *indEngine, CRiskManager *riskMgr);

   // Trade execution
   bool              ExecuteTrade(const TradeSignal &signal, double lots);

   // Position management (call every tick)
   void              ManagePositions();

   // Emergency close all
   void              CloseAllPositions(string reason);

   // Close profitable positions (session end)
   void              CloseProfitablePositions(string reason);

   // Get position count
   int               CountPositions();

   // Get metadata for reporting
   double            GetEntryScore(ulong ticket);
   ENUM_MARKET_REGIME GetEntryRegime(ulong ticket);
   ENUM_SIGNAL_DIR   GetEntryDirection(ulong ticket);
   double            GetOriginalVolume(ulong ticket);
   void              UpdateOriginalVolume(ulong ticket, double newVolume);
   bool              HasPositionInDirection(ENUM_SIGNAL_DIR dir);
  };

//+------------------------------------------------------------------+
COrderManager::COrderManager()
  {
   m_posMetaCount = 0;
   m_ind  = NULL;
   m_risk = NULL;
  }

//+------------------------------------------------------------------+
COrderManager::~COrderManager()
  {
   // Clean up allocated metadata objects
   for(int i = 0; i < m_posMetaCount; i++)
     {
      if(m_posMeta[i] != NULL)
        {
         delete m_posMeta[i];
         m_posMeta[i] = NULL;
        }
     }
   m_posMetaCount = 0;
  }

//+------------------------------------------------------------------+
bool COrderManager::Init(string symbol, long magic, CIndicatorEngine *indEngine, CRiskManager *riskMgr)
  {
   m_symbol = symbol;
   m_magic  = magic;
   m_ind    = indEngine;
   m_risk   = riskMgr;

   // Configure CTrade
   m_trade.SetExpertMagicNumber((ulong)magic);
   m_trade.SetDeviationInPoints(30);
   m_trade.SetTypeFillingBySymbol(m_symbol);

   // Initialize meta array
   ArrayResize(m_posMeta, 20);
   m_posMetaCount = 0;

   PrintFormat("[GA-ORD] Order manager initialized for %s, magic=%I64d", m_symbol, magic);
   return true;
  }

//+------------------------------------------------------------------+
//| Execute a trade based on signal                                   |
//+------------------------------------------------------------------+
bool COrderManager::ExecuteTrade(const TradeSignal &signal, double lots)
  {
   if(signal.direction == SIGNAL_NONE || lots <= 0)
      return false;

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   if(point <= 0) return false;

   double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);

   if(ask <= 0 || bid <= 0)
     {
      Print("[GA-ORD] ERROR: Invalid price data");
      return false;
     }

   double slDist = signal.slPoints * point;
   double tpDist = signal.tpPoints * point;

   // Validate stop distances against broker minimum
   slDist = ValidateStopDistance(slDist);
   tpDist = ValidateStopDistance(tpDist);

   double entryPrice, sl, tp;
   string comment;
   bool result = false;

   if(signal.direction == SIGNAL_BUY)
     {
      entryPrice = ask;
      sl = NormalizeDouble(entryPrice - slDist, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS));
      tp = NormalizeDouble(entryPrice + tpDist, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS));
      comment = StringFormat("GA_B|%.1f|%s", signal.buyScore, EnumToString(signal.regime));

      result = m_trade.Buy(lots, m_symbol, entryPrice, sl, tp, comment);
     }
   else if(signal.direction == SIGNAL_SELL)
     {
      entryPrice = bid;
      sl = NormalizeDouble(entryPrice + slDist, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS));
      tp = NormalizeDouble(entryPrice - tpDist, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS));
      comment = StringFormat("GA_S|%.1f|%s", signal.sellScore, EnumToString(signal.regime));

      result = m_trade.Sell(lots, m_symbol, entryPrice, sl, tp, comment);
     }

   if(result)
     {
      // Use ResultDeal to get deal ticket, then resolve position ID
      ulong dealTicket = m_trade.ResultDeal();
      ulong posTicket = 0;
      if(dealTicket > 0 && HistoryDealSelect(dealTicket))
         posTicket = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
      if(posTicket == 0)
         posTicket = m_trade.ResultOrder(); // Fallback

      double atr = (m_ind != NULL) ? m_ind.ATR(0) : 0;
      double score = (signal.direction == SIGNAL_BUY) ? signal.buyScore : signal.sellScore;

      AddMeta(posTicket, entryPrice, atr, score, signal.regime, signal.direction, lots);

      PrintFormat("[GA-ORD] %s opened: ticket=%I64u, lots=%.2f, entry=%.2f, SL=%.2f, TP=%.2f, score=%.1f, regime=%s",
                  (signal.direction == SIGNAL_BUY) ? "BUY" : "SELL",
                  posTicket, lots, entryPrice, sl, tp, score, EnumToString(signal.regime));
     }
   else
     {
      PrintFormat("[GA-ORD] Trade FAILED: %s, retcode=%d",
                  signal.source, m_trade.ResultRetcode());
     }

   return result;
  }

//+------------------------------------------------------------------+
//| Manage all open positions (call every tick)                       |
//+------------------------------------------------------------------+
void COrderManager::ManagePositions()
  {
   if(m_ind == NULL) return;

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   if(point <= 0) return;

   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

   // Clean up metadata for closed positions
   CleanupStaleMeta();

   // Check if near session end
   bool nearEnd = IsNearSessionEnd(5);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetInteger(POSITION_MAGIC) != m_magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;

      double posOpen   = PositionGetDouble(POSITION_PRICE_OPEN);
      double posSL     = PositionGetDouble(POSITION_SL);
      double posTP     = PositionGetDouble(POSITION_TP);
      double posVolume = PositionGetDouble(POSITION_VOLUME);
      long   posType   = PositionGetInteger(POSITION_TYPE);
      double posProfit = PositionGetDouble(POSITION_PROFIT);

      double currentAsk = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double currentBid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double currentPrice = (posType == POSITION_TYPE_BUY) ? currentBid : currentAsk;

      // Get entry metadata
      int metaIdx = FindMetaIndex(ticket);
      double entryATR = (metaIdx >= 0) ? m_posMeta[metaIdx].entryATR : m_ind.ATR(0);
      if(entryATR <= 0) entryATR = m_ind.ATR(0);

      bool beDone      = (metaIdx >= 0) ? m_posMeta[metaIdx].breakEvenApplied : false;
      bool partialDone = (metaIdx >= 0) ? m_posMeta[metaIdx].partialClosed : false;

      // Calculate profit in price distance
      double profitDist = 0;
      if(posType == POSITION_TYPE_BUY)
         profitDist = currentPrice - posOpen;
      else
         profitDist = posOpen - currentPrice;

      //--- Session-end close (profitable positions only)
      if(nearEnd && posProfit > 0)
        {
         m_trade.PositionClose(ticket, 30);
         PrintFormat("[GA-ORD] Session-end close: ticket=%I64u, profit=%.2f", ticket, posProfit);
         continue;
        }

      //--- Minimum hold time before BE/trailing/partial (prevent instant exits)
      datetime posOpenTime = (metaIdx >= 0) ? m_posMeta[metaIdx].openTime : 0;
      bool holdTimeMet = (posOpenTime == 0) || ((int)(TimeCurrent() - posOpenTime) >= InpMinHoldSeconds);

      //--- Partial Close: only after substantial move (ATR threshold AND progress to TP)
      double tpDist = MathAbs(posTP - posOpen);
      double partialTrigger = entryATR * InpPartialMultiplier;
      if(tpDist > 0)
        partialTrigger = MathMax(partialTrigger, tpDist * 0.55);

      if(holdTimeMet && !partialDone && profitDist >= partialTrigger)
        {
         double closeLots = NormalizeDouble(posVolume * InpPartialPercent / 100.0, 2);
         double lotMin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
         double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);

         // Ensure we close at least minimum and leave at least minimum
         closeLots = MathFloor(closeLots / lotStep) * lotStep;
         if(closeLots >= lotMin && (posVolume - closeLots) >= lotMin)
           {
            if(m_trade.PositionClosePartial(ticket, closeLots, 30))
              {
               if(metaIdx >= 0) m_posMeta[metaIdx].partialClosed = true;
               PrintFormat("[GA-ORD] Partial close: ticket=%I64u, closed=%.2f lots, remaining=%.2f",
                           ticket, closeLots, posVolume - closeLots);
              }
           }
         else
           {
            // Can't partial close properly, mark as done to avoid retry
            if(metaIdx >= 0) m_posMeta[metaIdx].partialClosed = true;
           }
        }

      //--- Break-Even: at ATR * InpBEMultiplier profit
      if(holdTimeMet && !beDone && profitDist >= entryATR * InpBEMultiplier)
        {
         double newSL = 0;
         if(posType == POSITION_TYPE_BUY)
          newSL = NormalizeDouble(posOpen + point * 5, digits); // +5 points above entry
         else
          newSL = NormalizeDouble(posOpen - point * 5, digits);

         // Only move SL if it's better than current
         bool shouldMove = false;
         if(posType == POSITION_TYPE_BUY && (posSL < newSL || posSL == 0))
            shouldMove = true;
         if(posType == POSITION_TYPE_SELL && (posSL > newSL || posSL == 0))
            shouldMove = true;

         if(shouldMove)
           {
            if(m_trade.PositionModify(ticket, newSL, posTP))
              {
               if(metaIdx >= 0) m_posMeta[metaIdx].breakEvenApplied = true;
               PrintFormat("[GA-ORD] Break-even: ticket=%I64u, new SL=%.2f", ticket, newSL);
              }
           }
         else
           {
            if(metaIdx >= 0) m_posMeta[metaIdx].breakEvenApplied = true;
           }
        }

      //--- Trailing Stop: ATR * InpTrailMultiplier (only after break-even and extra progress)
      if(holdTimeMet && beDone && profitDist >= entryATR * (InpBEMultiplier + 0.4))
        {
         double trailDist = entryATR * InpTrailMultiplier;
         double newTrailSL = 0;

         if(posType == POSITION_TYPE_BUY)
           {
            newTrailSL = NormalizeDouble(currentPrice - trailDist, digits);
            // Only tighten (move SL up), never widen
            if(newTrailSL > posSL && newTrailSL > posOpen)
              {
               m_trade.PositionModify(ticket, newTrailSL, posTP);
              }
           }
         else
           {
            newTrailSL = NormalizeDouble(currentPrice + trailDist, digits);
            // Only tighten (move SL down), never widen
            if((newTrailSL < posSL || posSL == 0) && newTrailSL < posOpen)
              {
               m_trade.PositionModify(ticket, newTrailSL, posTP);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Close all positions (emergency)                                   |
//+------------------------------------------------------------------+
void COrderManager::CloseAllPositions(string reason)
  {
   PrintFormat("[GA-ORD] CLOSING ALL POSITIONS: %s", reason);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetInteger(POSITION_MAGIC) != m_magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;

      m_trade.PositionClose(ticket, 50);
     }
  }

//+------------------------------------------------------------------+
//| Close only profitable positions                                   |
//+------------------------------------------------------------------+
void COrderManager::CloseProfitablePositions(string reason)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetInteger(POSITION_MAGIC) != m_magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;

      double profit = PositionGetDouble(POSITION_PROFIT)
                    + PositionGetDouble(POSITION_SWAP);

      // Add small buffer to account for commission not visible on open position
      if(profit > 1.0)
        {
         m_trade.PositionClose(ticket, 30);
         PrintFormat("[GA-ORD] Closed profitable position: ticket=%I64u, profit=%.2f (%s)",
                     ticket, profit, reason);
        }
     }
  }

//+------------------------------------------------------------------+
//| Count our open positions                                          |
//+------------------------------------------------------------------+
int COrderManager::CountPositions()
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
//| Validate stop distance against broker minimum                     |
//+------------------------------------------------------------------+
double COrderManager::ValidateStopDistance(double distance)
  {
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int stopsLevel = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist = stopsLevel * point;

   if(stopsLevel > 0 && distance < minDist)
      return minDist + 5 * point;  // Add 5-point buffer

   return distance;
  }

//+------------------------------------------------------------------+
//| Find metadata index for a ticket (-1 if not found)                |
//+------------------------------------------------------------------+
int COrderManager::FindMetaIndex(ulong ticket)
  {
   for(int i = 0; i < m_posMetaCount; i++)
     {
      if(m_posMeta[i] != NULL && m_posMeta[i].ticket == ticket)
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| Add metadata for a new position                                   |
//+------------------------------------------------------------------+
void COrderManager::AddMeta(ulong ticket, double price, double atr, double score,
                             ENUM_MARKET_REGIME regime, ENUM_SIGNAL_DIR dir, double volume)
  {
   // Ensure capacity
   if(m_posMetaCount >= ArraySize(m_posMeta))
      ArrayResize(m_posMeta, m_posMetaCount + 10);

   m_posMeta[m_posMetaCount] = new CPositionMeta();
   m_posMeta[m_posMetaCount].ticket           = ticket;
   m_posMeta[m_posMetaCount].entryPrice       = price;
   m_posMeta[m_posMetaCount].entryATR         = atr;
   m_posMeta[m_posMetaCount].entryScore       = score;
   m_posMeta[m_posMetaCount].regime           = regime;
   m_posMeta[m_posMetaCount].direction        = dir;
   m_posMeta[m_posMetaCount].breakEvenApplied = false;
   m_posMeta[m_posMetaCount].partialClosed    = false;
   m_posMeta[m_posMetaCount].openTime         = TimeCurrent();
   m_posMeta[m_posMetaCount].originalVolume   = volume;
   m_posMetaCount++;
  }

//+------------------------------------------------------------------+
//| Remove metadata for a closed position                             |
//+------------------------------------------------------------------+
void COrderManager::RemoveMeta(ulong ticket)
  {
   for(int i = 0; i < m_posMetaCount; i++)
     {
      if(m_posMeta[i] != NULL && m_posMeta[i].ticket == ticket)
        {
         delete m_posMeta[i];
         // Shift remaining entries
         for(int j = i; j < m_posMetaCount - 1; j++)
            m_posMeta[j] = m_posMeta[j + 1];
         m_posMeta[m_posMetaCount - 1] = NULL;
         m_posMetaCount--;
         return;
        }
     }
  }

//+------------------------------------------------------------------+
//| Clean up metadata for positions that no longer exist              |
//+------------------------------------------------------------------+
void COrderManager::CleanupStaleMeta()
  {
   for(int i = m_posMetaCount - 1; i >= 0; i--)
     {
      if(m_posMeta[i] == NULL)
        {
         RemoveMeta(0);
         continue;
        }
      ulong metaTicket = m_posMeta[i].ticket;
      bool found = false;

      for(int j = PositionsTotal() - 1; j >= 0; j--)
        {
         if(PositionGetTicket(j) == metaTicket)
           {
            found = true;
            break;
           }
        }

      if(!found)
        {
         // Position closed — remove metadata
         RemoveMeta(metaTicket);
        }
     }
  }

//+------------------------------------------------------------------+
//| Get entry score for a given ticket                                |
//+------------------------------------------------------------------+
double COrderManager::GetEntryScore(ulong ticket)
  {
   int idx = FindMetaIndex(ticket);
   return (idx >= 0) ? m_posMeta[idx].entryScore : 0;
  }

//+------------------------------------------------------------------+
//| Get entry regime for a given ticket                               |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME COrderManager::GetEntryRegime(ulong ticket)
  {
   int idx = FindMetaIndex(ticket);
   return (idx >= 0) ? m_posMeta[idx].regime : REGIME_UNKNOWN;
  }

//+------------------------------------------------------------------+
//| Get entry direction for a given ticket                            |
//+------------------------------------------------------------------+
ENUM_SIGNAL_DIR COrderManager::GetEntryDirection(ulong ticket)
  {
   int idx = FindMetaIndex(ticket);
   return (idx >= 0) ? m_posMeta[idx].direction : SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| Get original volume at entry                                      |
//+------------------------------------------------------------------+
double COrderManager::GetOriginalVolume(ulong ticket)
  {
   int idx = FindMetaIndex(ticket);
   return (idx >= 0) ? m_posMeta[idx].originalVolume : 0;
  }

//+------------------------------------------------------------------+
//| Update original volume (after partial close)                      |
//+------------------------------------------------------------------+
void COrderManager::UpdateOriginalVolume(ulong ticket, double newVolume)
  {
   int idx = FindMetaIndex(ticket);
   if(idx >= 0 && m_posMeta[idx] != NULL)
      m_posMeta[idx].originalVolume = newVolume;
  }

//+------------------------------------------------------------------+
//| Check if a position exists in the given direction                 |
//+------------------------------------------------------------------+
bool COrderManager::HasPositionInDirection(ENUM_SIGNAL_DIR dir)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != m_magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      long posType = PositionGetInteger(POSITION_TYPE);
      if(dir == SIGNAL_BUY && posType == POSITION_TYPE_BUY) return true;
      if(dir == SIGNAL_SELL && posType == POSITION_TYPE_SELL) return true;
     }
   return false;
  }

#endif // __GA_ORDERS_MQH__
