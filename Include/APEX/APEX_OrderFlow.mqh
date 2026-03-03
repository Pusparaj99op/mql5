//+------------------------------------------------------------------+
//|                                             APEX_OrderFlow.mqh   |
//|           APEX Gold Destroyer - Order Flow & DOM Engine           |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_ORDERFLOW_MQH
#define APEX_ORDERFLOW_MQH

#include "APEX_Config.mqh"

//+------------------------------------------------------------------+
//| DOM Level Data                                                    |
//+------------------------------------------------------------------+
struct DOMLevel
  {
   double            price;
   double            volume;
   ENUM_BOOK_TYPE    type;
  };

//+------------------------------------------------------------------+
//| Footprint Bucket                                                  |
//+------------------------------------------------------------------+
struct FootprintBucket
  {
   double            priceLevel;
   double            buyVolume;
   double            sellVolume;
   double            delta;           // buy - sell
  };

//+------------------------------------------------------------------+
//| Order Flow Engine                                                 |
//+------------------------------------------------------------------+
class COrderFlowEngine
  {
private:
   string            m_symbol;
   bool              m_initialized;
   bool              m_domActive;

   // DOM data
   double            m_bidVolume;
   double            m_askVolume;
   double            m_domImbalance;   // [-1, +1]
   DOMLevel          m_topBids[5];
   DOMLevel          m_topAsks[5];
   bool              m_bidWallDetected;
   bool              m_askWallDetected;
   double            m_bidWallPrice;
   double            m_askWallPrice;

   // Footprint data
   FootprintBucket   m_footprint[];
   int               m_footprintSize;
   double            m_footprintBias;  // Net directional pressure [-1, +1]

   // Candle-based OFI (fallback for backtesting)
   double            m_candleOFI;

   // Internal methods
   void              AnalyzeDOMWalls();
   void              BuildFootprint();

public:
                     COrderFlowEngine();
                    ~COrderFlowEngine();
   bool              Init(string symbol);
   void              Deinit();

   // Called from OnBookEvent
   void              ProcessBookEvent(const string &symbol);

   // Called from OnTick for tick-based analysis
   void              UpdateTickFlow();

   // Candle-based OFI update (for backtesting)
   void              UpdateCandleOFI(double ofi) { m_candleOFI = ofi; }

   // Accessors
   double            GetDOMImbalance()   { return m_domImbalance; }
   double            GetBidVolume()      { return m_bidVolume; }
   double            GetAskVolume()      { return m_askVolume; }
   bool              IsDOMActive()       { return m_domActive; }
   double            GetFootprintBias()  { return m_footprintBias; }
   double            GetCandleOFI()      { return m_candleOFI; }
   bool              HasBidWall()        { return m_bidWallDetected; }
   bool              HasAskWall()        { return m_askWallDetected; }
   double            GetBidWallPrice()   { return m_bidWallPrice; }
   double            GetAskWallPrice()   { return m_askWallPrice; }

   // Signal generation
   ENUM_APEX_SIGNAL  GetDOMSignal();
   double            GetDOMStrength();
   ENUM_APEX_SIGNAL  GetFootprintSignal();

   // Combined signal (DOM + footprint + candle OFI)
   double            GetCombinedFlowBias();
  };

//+------------------------------------------------------------------+
COrderFlowEngine::COrderFlowEngine()
  {
   m_initialized = false;
   m_domActive = false;
   m_bidVolume = 0;
   m_askVolume = 0;
   m_domImbalance = 0;
   m_bidWallDetected = false;
   m_askWallDetected = false;
   m_bidWallPrice = 0;
   m_askWallPrice = 0;
   m_footprintBias = 0;
   m_footprintSize = 0;
   m_candleOFI = 0;
  }

//+------------------------------------------------------------------+
COrderFlowEngine::~COrderFlowEngine()
  {
   Deinit();
  }

//+------------------------------------------------------------------+
bool COrderFlowEngine::Init(string symbol)
  {
   m_symbol = symbol;
   m_initialized = true;

   if(InpDOMEnabled)
     {
      m_domActive = MarketBookAdd(m_symbol);
      if(!m_domActive)
         Print("APEX OrderFlow: MarketBookAdd failed - DOM not available (backtest mode?)");
     }

   return true;
  }

//+------------------------------------------------------------------+
void COrderFlowEngine::Deinit()
  {
   if(m_domActive)
     {
      MarketBookRelease(m_symbol);
      m_domActive = false;
     }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Process DOM update from OnBookEvent                               |
//+------------------------------------------------------------------+
void COrderFlowEngine::ProcessBookEvent(const string &symbol)
  {
   if(symbol != m_symbol || !m_initialized) return;

   MqlBookInfo book[];
   if(!MarketBookGet(m_symbol, book) || ArraySize(book) == 0) return;

   m_domActive = true;
   m_bidVolume = 0;
   m_askVolume = 0;

   int bidCount = 0, askCount = 0;
   double totalBidVol = 0, totalAskVol = 0;
   int bookSize = ArraySize(book);

   // Reset top levels
   for(int i = 0; i < 5; i++)
     {
      ZeroMemory(m_topBids[i]);
      ZeroMemory(m_topAsks[i]);
     }

   for(int i = 0; i < bookSize; i++)
     {
      double vol = (double)book[i].volume;
      if(book[i].type == BOOK_TYPE_SELL)
        {
         m_askVolume += vol;
         if(askCount < 5)
           {
            m_topAsks[askCount].price  = book[i].price;
            m_topAsks[askCount].volume = vol;
            m_topAsks[askCount].type   = book[i].type;
            askCount++;
           }
        }
      else if(book[i].type == BOOK_TYPE_BUY)
        {
         m_bidVolume += vol;
         if(bidCount < 5)
           {
            m_topBids[bidCount].price  = book[i].price;
            m_topBids[bidCount].volume = vol;
            m_topBids[bidCount].type   = book[i].type;
            bidCount++;
           }
        }
     }

   // Calculate DOM imbalance
   double total = m_bidVolume + m_askVolume;
   m_domImbalance = (total > 0) ? (m_bidVolume - m_askVolume) / total : 0;

   // Analyze for walls
   AnalyzeDOMWalls();
  }

//+------------------------------------------------------------------+
//| Detect large resting orders (walls)                               |
//+------------------------------------------------------------------+
void COrderFlowEngine::AnalyzeDOMWalls()
  {
   m_bidWallDetected = false;
   m_askWallDetected = false;

   // Calculate average volume per level
   double avgBidVol = 0, avgAskVol = 0;
   int bidLevels = 0, askLevels = 0;

   for(int i = 0; i < 5; i++)
     {
      if(m_topBids[i].volume > 0) { avgBidVol += m_topBids[i].volume; bidLevels++; }
      if(m_topAsks[i].volume > 0) { avgAskVol += m_topAsks[i].volume; askLevels++; }
     }
   if(bidLevels > 0) avgBidVol /= bidLevels;
   if(askLevels > 0) avgAskVol /= askLevels;

   double wallThreshold = InpDOMWallMultiplier;

   // Check for bid walls (large buy resting orders = support)
   for(int i = 0; i < 5; i++)
     {
      if(m_topBids[i].volume > avgBidVol * wallThreshold && avgBidVol > 0)
        {
         m_bidWallDetected = true;
         m_bidWallPrice = m_topBids[i].price;
         break;
        }
     }

   // Check for ask walls (large sell resting orders = resistance)
   for(int i = 0; i < 5; i++)
     {
      if(m_topAsks[i].volume > avgAskVol * wallThreshold && avgAskVol > 0)
        {
         m_askWallDetected = true;
         m_askWallPrice = m_topAsks[i].price;
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//| Build tick footprint analysis                                     |
//+------------------------------------------------------------------+
void COrderFlowEngine::BuildFootprint()
  {
   MqlTick ticks[];
   int copied = CopyTicks(m_symbol, ticks, COPY_TICKS_ALL, 0, InpTickFootprintCount);
   if(copied < 50)
     {
      m_footprintBias = 0;
      return;
     }

   // Determine price range for bucketing
   double minPrice = DBL_MAX, maxPrice = -DBL_MAX;
   for(int i = 0; i < copied; i++)
     {
      double price = (ticks[i].bid + ticks[i].ask) / 2.0;
      if(price < minPrice) minPrice = price;
      if(price > maxPrice) maxPrice = price;
     }

   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double bucketSize = point * 50; // 50 points per bucket
   if(bucketSize <= 0) bucketSize = 0.5;

   int numBuckets = (int)MathCeil((maxPrice - minPrice) / bucketSize) + 1;
   numBuckets = MathMin(numBuckets, 100); // Cap at 100 buckets

   ArrayResize(m_footprint, numBuckets);
   m_footprintSize = numBuckets;

   for(int i = 0; i < numBuckets; i++)
     {
      m_footprint[i].priceLevel = minPrice + i * bucketSize;
      m_footprint[i].buyVolume = 0;
      m_footprint[i].sellVolume = 0;
      m_footprint[i].delta = 0;
     }

   // Classify each tick into buckets
   double totalBuy = 0, totalSell = 0;
   for(int i = 1; i < copied; i++)
     {
      double price = (ticks[i].bid + ticks[i].ask) / 2.0;
      int bucket = (int)((price - minPrice) / bucketSize);
      if(bucket < 0) bucket = 0;
      if(bucket >= numBuckets) bucket = numBuckets - 1;

      bool isBuyTick = false;
      if(ticks[i].last >= ticks[i].ask)
         isBuyTick = true;
      else if(ticks[i].last <= ticks[i].bid)
         isBuyTick = false;
      else
         isBuyTick = (ticks[i].last > ticks[i-1].last);

      if(isBuyTick)
        {
         m_footprint[bucket].buyVolume += 1.0;
         totalBuy += 1.0;
        }
      else
        {
         m_footprint[bucket].sellVolume += 1.0;
         totalSell += 1.0;
        }
     }

   // Compute deltas and overall bias
   for(int i = 0; i < numBuckets; i++)
      m_footprint[i].delta = m_footprint[i].buyVolume - m_footprint[i].sellVolume;

   double total = totalBuy + totalSell;
   m_footprintBias = (total > 0) ? (totalBuy - totalSell) / total : 0;
  }

//+------------------------------------------------------------------+
//| Called from OnTick for periodic tick analysis                      |
//+------------------------------------------------------------------+
void COrderFlowEngine::UpdateTickFlow()
  {
   BuildFootprint();
  }

//+------------------------------------------------------------------+
//| DOM Signal Direction                                              |
//+------------------------------------------------------------------+
ENUM_APEX_SIGNAL COrderFlowEngine::GetDOMSignal()
  {
   if(!m_domActive) return SIGNAL_NONE;
   if(m_domImbalance >= InpDOMThresholdStrong) return SIGNAL_BUY;
   if(m_domImbalance <= -InpDOMThresholdStrong) return SIGNAL_SELL;
   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
double COrderFlowEngine::GetDOMStrength()
  {
   return MathAbs(m_domImbalance);
  }

//+------------------------------------------------------------------+
ENUM_APEX_SIGNAL COrderFlowEngine::GetFootprintSignal()
  {
   if(m_footprintBias > 0.3) return SIGNAL_BUY;
   if(m_footprintBias < -0.3) return SIGNAL_SELL;
   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| Combined flow bias: DOM + footprint + candle OFI                  |
//+------------------------------------------------------------------+
double COrderFlowEngine::GetCombinedFlowBias()
  {
   double bias = 0;
   int sources = 0;

   // DOM (highest weight if available)
   if(m_domActive && MathAbs(m_domImbalance) > 0.05)
     {
      bias += m_domImbalance * 2.0;
      sources += 2;
     }

   // Footprint
   if(MathAbs(m_footprintBias) > 0.05)
     {
      bias += m_footprintBias * 1.5;
      sources += 1;
     }

   // Candle OFI (always available)
   if(MathAbs(m_candleOFI) > 0.05)
     {
      bias += m_candleOFI * 1.0;
      sources += 1;
     }

   return (sources > 0) ? bias / sources : 0;
  }

#endif // APEX_ORDERFLOW_MQH
