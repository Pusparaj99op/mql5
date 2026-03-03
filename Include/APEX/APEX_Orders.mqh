//+------------------------------------------------------------------+
//|                                               APEX_Orders.mqh    |
//|       APEX Gold Destroyer - Hedge-Mode Order Execution Engine    |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_ORDERS_MQH
#define APEX_ORDERS_MQH

#include "APEX_Config.mqh"
#include "APEX_Risk.mqh"
#include "APEX_MTF.mqh"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Order Execution & Trade Management Engine                         |
//+------------------------------------------------------------------+
class COrderEngine
  {
private:
   string            m_symbol;
   bool              m_initialized;
   CTrade            m_trade;
   CPositionInfo     m_pos;
   CRiskEngine       *m_risk;
   CMTFEngine        *m_mtf;

   // Position metadata tracking
   ApexPositionMeta  m_meta[];
   int               m_metaCount;
   int               m_metaMaxSize;

   // Grid state
   ApexGridState     m_gridBuy;
   ApexGridState     m_gridSell;

   // Internal methods
   int               FindMeta(ulong ticket);
   void              AddMeta(ulong ticket, const ApexSignal &sig, int pyramidLvl, int martLvl, int gridLvl, double lots);
   void              RemoveMeta(ulong ticket);

   // Trade management internals
   void              ManageChandelierTrail(ulong ticket, ENUM_POSITION_TYPE ptype);
   void              ManageBreakEven(ulong ticket, ENUM_POSITION_TYPE ptype);
   void              ManagePartialClose(ulong ticket, ENUM_POSITION_TYPE ptype);
   void              ManageStalePositions();
   void              ManagePyramiding(ENUM_APEX_SIGNAL dir, double currentATR);
   void              ManageGrid(ENUM_APEX_SIGNAL dir, double currentATR);

public:
                     COrderEngine();
                    ~COrderEngine();
   bool              Init(string symbol, CRiskEngine *risk, CMTFEngine *mtf);
   void              Deinit();

   // Entry execution
   bool              ExecuteSignal(const ApexSignal &signal);
   bool              ExecuteNewsStraddle(double buyStopPrice, double sellStopPrice,
                                         double sl, double tp, double lots);
   bool              CancelPendingOrders();

   // Trade management (called every tick)
   void              ManageOpenPositions();

   // Grid management
   bool              OpenGridTrade(ENUM_APEX_SIGNAL dir, double price, int level, double lots, double atr);
   void              CloseGrid(ENUM_APEX_SIGNAL dir);
   bool              IsGridActive(ENUM_APEX_SIGNAL dir) { return (dir == SIGNAL_BUY) ? m_gridBuy.active : m_gridSell.active; }
   ApexGridState     GetGridState(ENUM_APEX_SIGNAL dir);

   // Position queries
   int               GetPositionCount()   { return m_metaCount; }
   ApexPositionMeta  GetMeta(int idx)     { if(idx >= 0 && idx < m_metaCount) return m_meta[idx]; ApexPositionMeta empty; ZeroMemory(empty); return empty; }

   // Cleanup (called from OnTradeTransaction when trade closes)
   void              OnPositionClosed(ulong ticket);

   // Close all positions
   void              CloseAll();
   void              CloseByDirection(ENUM_APEX_SIGNAL dir);

   // Pyramid check
   bool              FindPyramidOpportunity(ENUM_APEX_SIGNAL dir, double currentATR,
                                             double &entryPrice, int &nextLevel);
  };

//+------------------------------------------------------------------+
COrderEngine::COrderEngine()
  {
   m_initialized = false;
   m_risk = NULL;
   m_mtf = NULL;
   m_metaCount = 0;
   m_metaMaxSize = APEX_MAX_POSITIONS;
   ZeroMemory(m_gridBuy);
   ZeroMemory(m_gridSell);
  }

//+------------------------------------------------------------------+
COrderEngine::~COrderEngine() { Deinit(); }

//+------------------------------------------------------------------+
bool COrderEngine::Init(string symbol, CRiskEngine *risk, CMTFEngine *mtf)
  {
   m_symbol = symbol;
   m_risk = risk;
   m_mtf = mtf;

   ArrayResize(m_meta, m_metaMaxSize);

   // Configure CTrade
   m_trade.SetExpertMagicNumber(InpMagic);
   m_trade.SetDeviationInPoints(InpSlippage);
   m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   m_trade.SetMarginMode();

   m_initialized = true;
   return true;
  }

//+------------------------------------------------------------------+
void COrderEngine::Deinit()
  {
   m_initialized = false;
   m_metaCount = 0;
  }

//+------------------------------------------------------------------+
//| Execute a signal - open market order                               |
//+------------------------------------------------------------------+
bool COrderEngine::ExecuteSignal(const ApexSignal &signal)
  {
   if(!m_initialized || signal.direction == SIGNAL_NONE) return false;
   if(signal.lots <= 0) return false;

   double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);

   string comment = StringFormat("%s|%.1f|%s|%s",
                                 InpComment,
                                 signal.score,
                                 EnumToString(signal.regime),
                                 EnumToString(signal.strategy));

   bool result = false;

   if(signal.direction == SIGNAL_BUY)
     {
      result = m_trade.Buy(signal.lots, m_symbol, ask, signal.sl, signal.tp2, comment);
     }
   else
     {
      result = m_trade.Sell(signal.lots, m_symbol, bid, signal.sl, signal.tp2, comment);
     }

   if(result)
     {
      ulong ticket = m_trade.ResultOrder();
      if(ticket > 0)
        {
         // Wait for position to appear
         if(PositionSelectByTicket(ticket))
           {
            ticket = PositionGetInteger(POSITION_TICKET);
           }
         else
           {
            // For hedge accounts, the deal ticket may differ from order ticket
            // Try to find the position by checking recent positions
            Sleep(100);
            for(int i = PositionsTotal() - 1; i >= 0; i--)
              {
               ulong t = PositionGetTicket(i);
               if(t > 0 && PositionGetInteger(POSITION_MAGIC) == InpMagic &&
                  PositionGetString(POSITION_SYMBOL) == m_symbol)
                 {
                  ticket = t;
                  break;
                 }
              }
           }

         int martLvl = m_risk.GetMartLevel(signal.direction);
         AddMeta(ticket, signal, 0, martLvl, 0, signal.lots);

         PrintFormat("APEX Order: %s %.2f lots @ %.2f | SL=%.2f TP=%.2f | Score=%.1f | %s | %s",
                     (signal.direction == SIGNAL_BUY ? "BUY" : "SELL"),
                     signal.lots, (signal.direction == SIGNAL_BUY ? ask : bid),
                     signal.sl, signal.tp2, signal.score,
                     EnumToString(signal.regime), EnumToString(signal.strategy));
        }
      return true;
     }
   else
     {
      PrintFormat("APEX Order: FAILED %s - Error %d: %s",
                  (signal.direction == SIGNAL_BUY ? "BUY" : "SELL"),
                  m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
      return false;
     }
  }

//+------------------------------------------------------------------+
//| Execute news straddle (BuyStop + SellStop)                        |
//+------------------------------------------------------------------+
bool COrderEngine::ExecuteNewsStraddle(double buyStopPrice, double sellStopPrice,
                                        double sl, double tp, double lots)
  {
   bool ok1 = m_trade.BuyStop(lots, buyStopPrice, m_symbol,
                               buyStopPrice - sl, buyStopPrice + tp,
                               ORDER_TIME_GTC, 0, InpComment + "_NEWS_BUY");
   bool ok2 = m_trade.SellStop(lots, sellStopPrice, m_symbol,
                                sellStopPrice + sl, sellStopPrice - tp,
                                ORDER_TIME_GTC, 0, InpComment + "_NEWS_SELL");

   if(ok1 && ok2)
      Print("APEX News: Straddle placed. BuyStop=", buyStopPrice, " SellStop=", sellStopPrice);

   return ok1 || ok2;
  }

//+------------------------------------------------------------------+
//| Cancel all pending orders                                         |
//+------------------------------------------------------------------+
bool COrderEngine::CancelPendingOrders()
  {
   bool ok = true;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetInteger(ORDER_MAGIC) == InpMagic &&
         OrderGetString(ORDER_SYMBOL) == m_symbol)
        {
         if(!m_trade.OrderDelete(ticket))
            ok = false;
        }
     }
   return ok;
  }

//+------------------------------------------------------------------+
//| Manage all open positions                                         |
//+------------------------------------------------------------------+
void COrderEngine::ManageOpenPositions()
  {
   if(!m_initialized) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;

      ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      ManageBreakEven(ticket, ptype);
      ManagePartialClose(ticket, ptype);
      ManageChandelierTrail(ticket, ptype);
     }

   ManageStalePositions();
  }

//+------------------------------------------------------------------+
//| Chandelier Trailing Stop                                          |
//| BUY:  SL = HH(5) - ATR × mult                                   |
//| SELL: SL = LL(5) + ATR × mult                                    |
//+------------------------------------------------------------------+
void COrderEngine::ManageChandelierTrail(ulong ticket, ENUM_POSITION_TYPE ptype)
  {
   int metaIdx = FindMeta(ticket);
   if(metaIdx < 0) return;

   // Only trail after breakeven
   if(!m_meta[metaIdx].partialDone) return; // Wait for at least partial close

   double atr = m_mtf.GetATR(PERIOD_M5);
   if(atr <= 0) return;

   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   double newSL = 0;

   if(ptype == POSITION_TYPE_BUY)
     {
      // Find highest high of last N bars
      double hh = -DBL_MAX;
      for(int b = 1; b <= InpTrailBars; b++)
        {
         double h = m_mtf.GetM5High(b);
         if(h > hh) hh = h;
        }
      newSL = hh - atr * InpTrailATR_Mult;

      // Ratchet only: new SL must be higher than current
      if(newSL > currentSL + point)
        {
         m_trade.PositionModify(ticket, NormalizeDouble(newSL, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)), currentTP);
        }
     }
   else // SELL
     {
      // Find lowest low of last N bars
      double ll = DBL_MAX;
      for(int b = 1; b <= InpTrailBars; b++)
        {
         double l = m_mtf.GetM5Low(b);
         if(l < ll) ll = l;
        }
      newSL = ll + atr * InpTrailATR_Mult;

      // Ratchet only: new SL must be lower than current
      if(currentSL == 0 || newSL < currentSL - point)
        {
         m_trade.PositionModify(ticket, NormalizeDouble(newSL, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)), currentTP);
        }
     }
  }

//+------------------------------------------------------------------+
//| Break-Even Management                                             |
//+------------------------------------------------------------------+
void COrderEngine::ManageBreakEven(ulong ticket, ENUM_POSITION_TYPE ptype)
  {
   int metaIdx = FindMeta(ticket);
   if(metaIdx < 0) return;

   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL  = PositionGetDouble(POSITION_SL);
   double currentTP  = PositionGetDouble(POSITION_TP);
   double atr = m_meta[metaIdx].entryATR;
   if(atr <= 0) atr = m_mtf.GetATR(PERIOD_M5);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

   double beTrigger = atr * InpBE_ATR_Mult;

   if(ptype == POSITION_TYPE_BUY)
     {
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double profit = bid - entryPrice;
      double beLevel = entryPrice + InpBE_PlusPoints * point;

      if(profit >= beTrigger && currentSL < beLevel)
        {
         m_trade.PositionModify(ticket, NormalizeDouble(beLevel, digits), currentTP);
        }
     }
   else
     {
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double profit = entryPrice - ask;
      double beLevel = entryPrice - InpBE_PlusPoints * point;

      if(profit >= beTrigger && (currentSL == 0 || currentSL > beLevel))
        {
         m_trade.PositionModify(ticket, NormalizeDouble(beLevel, digits), currentTP);
        }
     }
  }

//+------------------------------------------------------------------+
//| Partial Close at TP1                                              |
//+------------------------------------------------------------------+
void COrderEngine::ManagePartialClose(ulong ticket, ENUM_POSITION_TYPE ptype)
  {
   int metaIdx = FindMeta(ticket);
   if(metaIdx < 0 || m_meta[metaIdx].partialDone) return;

   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double volume = PositionGetDouble(POSITION_VOLUME);
   double atr = m_meta[metaIdx].entryATR;
   if(atr <= 0) atr = m_mtf.GetATR(PERIOD_M5);

   double tp1Distance = atr * InpTP1_ATR_Mult;
   double partialLots = NormalizeDouble(volume * InpPartialClosePercent / 100.0,
                                         (int)MathLog10(1.0 / SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP)));

   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   if(lotStep <= 0) lotStep = 0.01;
   partialLots = MathFloor(partialLots / lotStep) * lotStep;
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   if(partialLots < minLot) return; // Can't partial close below min lot

   double remainLots = volume - partialLots;
   if(remainLots < minLot) return; // Would close entire position

   if(ptype == POSITION_TYPE_BUY)
     {
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      if(bid - entryPrice >= tp1Distance)
        {
         if(m_trade.PositionClosePartial(ticket, partialLots))
           {
            m_meta[metaIdx].partialDone = true;
            PrintFormat("APEX: Partial close BUY #%d, %.2f lots at TP1", ticket, partialLots);
           }
        }
     }
   else
     {
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      if(entryPrice - ask >= tp1Distance)
        {
         if(m_trade.PositionClosePartial(ticket, partialLots))
           {
            m_meta[metaIdx].partialDone = true;
            PrintFormat("APEX: Partial close SELL #%d, %.2f lots at TP1", ticket, partialLots);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Close stale positions with minimal profit                         |
//+------------------------------------------------------------------+
void COrderEngine::ManageStalePositions()
  {
   datetime now = TimeCurrent();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;

      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      int hours = (int)((now - openTime) / 3600);

      if(hours >= InpStaleHours)
        {
         double profit = PositionGetDouble(POSITION_PROFIT);
         double atr = m_mtf.GetATR(PERIOD_M5);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);

         // Convert ATR threshold to monetary value
         double minProfit = atr * InpStaleMinProfitATR * volume * tickValue /
                           SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);

         if(profit < minProfit && profit > -minProfit * 3) // Don't close deep losers this way
           {
            m_trade.PositionClose(ticket);
            PrintFormat("APEX: Closed stale position #%d after %d hours. Profit: %.2f",
                        ticket, hours, profit);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Open a grid trade at specific level                               |
//+------------------------------------------------------------------+
bool COrderEngine::OpenGridTrade(ENUM_APEX_SIGNAL dir, double price, int level, double lots, double atr)
  {
   bool isBuy = (dir == SIGNAL_BUY);

   double sl, tp;
   string comment = StringFormat("%s_GRID_%d", InpComment, level);
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   bool result = false;

   if(isBuy)
     {
      sl = price - atr * InpGridSpacingATR * 2;
      tp = 0; // Grid uses aggregate TP management
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      result = m_trade.Buy(lots, m_symbol, ask, NormalizeDouble(sl, digits), 0, comment);
     }
   else
     {
      sl = price + atr * InpGridSpacingATR * 2;
      tp = 0;
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      result = m_trade.Sell(lots, m_symbol, bid, NormalizeDouble(sl, digits), 0, comment);
     }

   if(result)
     {
      if(isBuy)
        {
         m_gridBuy.active = true;
         m_gridBuy.filledLevels = level + 1;
         m_gridBuy.totalLots += lots;
         m_gridBuy.avgPrice = (m_gridBuy.avgPrice * (m_gridBuy.filledLevels - 1) + price) / m_gridBuy.filledLevels;
         if(level == 0) m_gridBuy.basePrice = price;
        }
      else
        {
         m_gridSell.active = true;
         m_gridSell.filledLevels = level + 1;
         m_gridSell.totalLots += lots;
         m_gridSell.avgPrice = (m_gridSell.avgPrice * (m_gridSell.filledLevels - 1) + price) / m_gridSell.filledLevels;
         if(level == 0) m_gridSell.basePrice = price;
        }
     }

   return result;
  }

//+------------------------------------------------------------------+
//| Close all grid positions in one direction                         |
//+------------------------------------------------------------------+
void COrderEngine::CloseGrid(ENUM_APEX_SIGNAL dir)
  {
   CloseByDirection(dir);
   if(dir == SIGNAL_BUY)
      ZeroMemory(m_gridBuy);
   else
      ZeroMemory(m_gridSell);
  }

//+------------------------------------------------------------------+
//| Get grid state with live netProfit computed                       |
//+------------------------------------------------------------------+
ApexGridState COrderEngine::GetGridState(ENUM_APEX_SIGNAL dir)
  {
   ApexGridState grid;
   if(dir == SIGNAL_BUY)
      grid = m_gridBuy;
   else
      grid = m_gridSell;

   // Compute live net floating P&L for grid positions
   if(grid.active)
     {
      grid.netProfit = 0;
      for(int i = 0; i < m_metaCount; i++)
        {
         if(m_meta[i].direction == dir && m_meta[i].gridLevel > 0 && m_meta[i].ticket > 0)
           {
            if(PositionSelectByTicket(m_meta[i].ticket))
              {
               grid.netProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
              }
           }
        }
      // Write back to member
      if(dir == SIGNAL_BUY)
         m_gridBuy.netProfit = grid.netProfit;
      else
         m_gridSell.netProfit = grid.netProfit;
     }

   return grid;
  }

//+------------------------------------------------------------------+
//| Check if pyramid opportunity exists                               |
//+------------------------------------------------------------------+
bool COrderEngine::FindPyramidOpportunity(ENUM_APEX_SIGNAL dir, double currentATR,
                                            double &entryPrice, int &nextLevel)
  {
   if(!InpPyramidEnabled) return false;

   // Find the latest position in this direction
   double latestEntry = 0;
   int maxPyramidLevel = 0;
   datetime latestTime = 0;

   for(int i = 0; i < m_metaCount; i++)
     {
      if(m_meta[i].direction == dir && m_meta[i].ticket > 0)
        {
         if(m_meta[i].entryTime > latestTime)
           {
            latestTime = m_meta[i].entryTime;
            latestEntry = m_meta[i].entryPrice;
           }
         if(m_meta[i].pyramidLevel > maxPyramidLevel)
            maxPyramidLevel = m_meta[i].pyramidLevel;
        }
     }

   if(latestEntry == 0 || maxPyramidLevel >= InpPyramidMaxAdds) return false;

   // Check if price has profited enough AND pulled back
   double currentPrice = (dir == SIGNAL_BUY) ?
                          SymbolInfoDouble(m_symbol, SYMBOL_ASK) :
                          SymbolInfoDouble(m_symbol, SYMBOL_BID);

   double profitDistance = (dir == SIGNAL_BUY) ?
                           (currentPrice - latestEntry) :
                           (latestEntry - currentPrice);

   // Must be in profit by min amount
   if(profitDistance < currentATR * InpPyramidMinProfitATR) return false;

   // Check for pullback to EMA
   double emaFast = m_mtf.GetData(PERIOD_M5).emaFast;
   double priceDist = MathAbs(currentPrice - emaFast);

   // Price should be near EMA (pulled back)
   if(priceDist < currentATR * InpPyramidPullbackATR)
     {
      entryPrice = currentPrice;
      nextLevel = maxPyramidLevel + 1;
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Metadata Management                                               |
//+------------------------------------------------------------------+
int COrderEngine::FindMeta(ulong ticket)
  {
   for(int i = 0; i < m_metaCount; i++)
      if(m_meta[i].ticket == ticket) return i;
   return -1;
  }

//+------------------------------------------------------------------+
void COrderEngine::AddMeta(ulong ticket, const ApexSignal &sig, int pyramidLvl, int martLvl, int gridLvl, double lots)
  {
   if(m_metaCount >= m_metaMaxSize)
     {
      // Compact: Remove stale entries
      int writeIdx = 0;
      for(int i = 0; i < m_metaCount; i++)
        {
         if(PositionSelectByTicket(m_meta[i].ticket))
           {
            if(writeIdx != i) m_meta[writeIdx] = m_meta[i];
            writeIdx++;
           }
        }
      m_metaCount = writeIdx;
      if(m_metaCount >= m_metaMaxSize) return; // Still full
     }

   m_meta[m_metaCount].ticket        = ticket;
   m_meta[m_metaCount].score         = sig.score;
   m_meta[m_metaCount].regime        = sig.regime;
   m_meta[m_metaCount].strategy      = sig.strategy;
   m_meta[m_metaCount].direction     = sig.direction;
   m_meta[m_metaCount].pyramidLevel  = pyramidLvl;
   m_meta[m_metaCount].martingaleLevel = martLvl;
   m_meta[m_metaCount].gridLevel     = gridLvl;
   m_meta[m_metaCount].partialDone   = false;
   m_meta[m_metaCount].entryATR      = m_mtf.GetATR(PERIOD_M5);
   m_meta[m_metaCount].entryPrice    = (sig.direction == SIGNAL_BUY) ?
                                        SymbolInfoDouble(m_symbol, SYMBOL_ASK) :
                                        SymbolInfoDouble(m_symbol, SYMBOL_BID);
   m_meta[m_metaCount].entryTime     = TimeCurrent();
   m_meta[m_metaCount].initialVolume = lots;
   m_metaCount++;
  }

//+------------------------------------------------------------------+
void COrderEngine::RemoveMeta(ulong ticket)
  {
   int idx = FindMeta(ticket);
   if(idx < 0) return;
   // Shift remaining entries
   for(int i = idx; i < m_metaCount - 1; i++)
      m_meta[i] = m_meta[i + 1];
   m_metaCount--;
  }

//+------------------------------------------------------------------+
void COrderEngine::OnPositionClosed(ulong ticket)
  {
   RemoveMeta(ticket);
  }

//+------------------------------------------------------------------+
//| Close all positions                                               |
//+------------------------------------------------------------------+
void COrderEngine::CloseAll()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      m_trade.PositionClose(ticket);
     }
   CancelPendingOrders();
   m_metaCount = 0;
   ZeroMemory(m_gridBuy);
   ZeroMemory(m_gridSell);
  }

//+------------------------------------------------------------------+
void COrderEngine::CloseByDirection(ENUM_APEX_SIGNAL dir)
  {
   ENUM_POSITION_TYPE ptype = (dir == SIGNAL_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == ptype)
         m_trade.PositionClose(ticket);
     }
  }

#endif // APEX_ORDERS_MQH
