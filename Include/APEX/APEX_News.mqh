//+------------------------------------------------------------------+
//|                                                 APEX_News.mqh    |
//|          APEX Gold Destroyer - News Exploitation Engine           |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_NEWS_MQH
#define APEX_NEWS_MQH

#include "APEX_Config.mqh"

//+------------------------------------------------------------------+
//| News Engine - Trade the News, Don't Just Filter It                |
//+------------------------------------------------------------------+
class CNewsEngine
  {
private:
   string            m_symbol;
   bool              m_initialized;

   // Cached events
   ApexNewsEvent     m_events[];
   int               m_eventCount;
   datetime          m_lastScan;

   // State
   ENUM_APEX_NEWS_STATE m_state;
   datetime          m_nextEventTime;
   string            m_nextEventName;
   int               m_nextEventImportance;
   double            m_preEventPrice;
   bool              m_straddlePlaced;

   // Internal methods
   void              ScanCalendar();


public:
                     CNewsEngine();
                    ~CNewsEngine();
   bool              Init(string symbol);
   void              Deinit();
   void              Update();

   // Accessors
   ENUM_APEX_NEWS_STATE GetState()    { return m_state; }
   datetime          GetNextEventTime(){ return m_nextEventTime; }
   string            GetNextEventName(){ return m_nextEventName; }
   int               GetNextEventImportance() { return m_nextEventImportance; }
   double            GetPreEventPrice(){ return m_preEventPrice; }
   bool              IsStraddlePlaced(){ return m_straddlePlaced; }
   void              SetStraddlePlaced(bool val) { m_straddlePlaced = val; }

   // Straddle levels
   bool              GetStraddleLevels(double atr, double &buyStopPrice, double &sellStopPrice,
                                       double &slDistance, double &tpDistance);

   // Minutes until next event
   int               MinutesToNextEvent();

   // Check if we should fade the spike
   bool              ShouldFadeSpike(double currentPrice, double atr);
   ENUM_APEX_SIGNAL  GetFadeDirection(double currentPrice);
  };

//+------------------------------------------------------------------+
CNewsEngine::CNewsEngine()
  {
   m_initialized = false;
   m_eventCount = 0;
   m_lastScan = 0;
   m_state = NEWS_NONE;
   m_nextEventTime = 0;
   m_nextEventName = "";
   m_nextEventImportance = 0;
   m_preEventPrice = 0;
   m_straddlePlaced = false;
  }

//+------------------------------------------------------------------+
CNewsEngine::~CNewsEngine() { Deinit(); }

//+------------------------------------------------------------------+
bool CNewsEngine::Init(string symbol)
  {
   m_symbol = symbol;
   ArrayResize(m_events, APEX_MAX_NEWS_EVENTS);
   m_initialized = InpNewsEnabled;
   return true;
  }

//+------------------------------------------------------------------+
void CNewsEngine::Deinit()
  {
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Main update - called every new bar                                |
//+------------------------------------------------------------------+
void CNewsEngine::Update()
  {
   if(!m_initialized) { m_state = NEWS_NONE; return; }

   datetime now = TimeCurrent();

   // Rescan calendar every 5 minutes
   if(now - m_lastScan > 300)
      ScanCalendar();

   // Determine state based on next event
   if(m_nextEventTime == 0)
     {
      m_state = NEWS_NONE;
      return;
     }

   int minutesUntil = (int)((m_nextEventTime - now) / 60);

   if(minutesUntil > InpNewsPreMinutes)
     {
      m_state = NEWS_NONE;
      m_straddlePlaced = false;
     }
   else if(minutesUntil > 0 && minutesUntil <= InpNewsPreMinutes)
     {
      m_state = NEWS_PRE;
      if(m_preEventPrice == 0)
         m_preEventPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
     }
   else if(minutesUntil >= -InpNewsDuringMinutes && minutesUntil <= 0)
     {
      m_state = NEWS_DURING;
     }
   else if(minutesUntil < -InpNewsDuringMinutes && minutesUntil >= -InpNewsPostMinutes)
     {
      m_state = NEWS_POST_FADE;
     }
   else
     {
      // Event has passed - reset
      m_state = NEWS_NONE;
      m_preEventPrice = 0;
      m_straddlePlaced = false;
     }
  }

//+------------------------------------------------------------------+
//| Scan economic calendar for upcoming events                        |
//+------------------------------------------------------------------+
void CNewsEngine::ScanCalendar()
  {
   m_lastScan = TimeCurrent();
   m_eventCount = 0;
   m_nextEventTime = 0;

   datetime now = TimeCurrent();
   datetime from = now - 60;                    // 1 minute ago
   datetime to   = now + InpNewsPreMinutes * 60 + 3600; // Look ahead 1 hour + pre window

   MqlCalendarValue values[];
   int cnt = CalendarValueHistory(values, from, to, NULL, NULL);
   if(cnt <= 0) return;

   datetime closestTime = D'2099.01.01';
   int closestImportance = 0;
   string closestName = "";

   for(int i = 0; i < cnt; i++)
     {
      MqlCalendarEvent ev;
      if(!CalendarEventById(values[i].event_id, ev)) continue;

      // Filter by importance
      if(ev.importance < CALENDAR_IMPORTANCE_MODERATE) continue;

      // Filter by currency
      MqlCalendarCountry country;
      string currency = "";
      if(CalendarCountryById(ev.country_id, country))
         currency = country.currency;

      if(StringLen(InpNewsCurrency) > 0 && StringFind(currency, InpNewsCurrency) == -1)
         continue;

      // Store event
      if(m_eventCount < APEX_MAX_NEWS_EVENTS)
        {
         m_events[m_eventCount].eventTime  = values[i].time;
         m_events[m_eventCount].eventName  = ev.name;
         m_events[m_eventCount].currency   = currency;
         m_events[m_eventCount].importance = (int)ev.importance;
         m_events[m_eventCount].preEventPrice = 0;
         m_eventCount++;
        }

      // Track closest future event
      if(values[i].time >= now && values[i].time < closestTime)
        {
         closestTime = values[i].time;
         closestImportance = (int)ev.importance;
         closestName = ev.name;
        }
     }

   if(closestTime < D'2099.01.01')
     {
      m_nextEventTime = closestTime;
      m_nextEventImportance = closestImportance;
      m_nextEventName = closestName;
     }
  }

//+------------------------------------------------------------------+
int CNewsEngine::MinutesToNextEvent()
  {
   if(m_nextEventTime == 0) return 9999;
   return (int)((m_nextEventTime - TimeCurrent()) / 60);
  }

//+------------------------------------------------------------------+
//| Calculate straddle order levels                                   |
//+------------------------------------------------------------------+
bool CNewsEngine::GetStraddleLevels(double atr, double &buyStopPrice, double &sellStopPrice,
                                     double &slDistance, double &tpDistance)
  {
   if(m_state != NEWS_PRE || m_straddlePlaced) return false;
   if(atr <= 0) return false;

   double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);

   // Straddle distance scales with event importance
   double distMult = InpNewsStraddleATR;
   if(m_nextEventImportance >= (int)CALENDAR_IMPORTANCE_HIGH)
      distMult *= 1.0;  // High impact = normal distance
   else
      distMult *= 1.5;  // Medium impact = wider distance (less certain spike)

   buyStopPrice  = ask + atr * distMult;
   sellStopPrice = bid - atr * distMult;
   slDistance    = atr * InpNewsSL_ATR;
   tpDistance    = atr * InpNewsTP_ATR;

   return true;
  }

//+------------------------------------------------------------------+
//| Check if news spike should be faded                               |
//+------------------------------------------------------------------+
bool CNewsEngine::ShouldFadeSpike(double currentPrice, double atr)
  {
   if(m_state != NEWS_POST_FADE) return false;
   if(m_preEventPrice == 0) return false;

   double spikeSize = MathAbs(currentPrice - m_preEventPrice);
   return (spikeSize > atr * InpNewsFadeThreshATR);
  }

//+------------------------------------------------------------------+
ENUM_APEX_SIGNAL CNewsEngine::GetFadeDirection(double currentPrice)
  {
   if(m_preEventPrice == 0) return SIGNAL_NONE;
   // Fade = trade against the spike direction
   if(currentPrice > m_preEventPrice) return SIGNAL_SELL; // Price spiked up → fade sell
   if(currentPrice < m_preEventPrice) return SIGNAL_BUY;  // Price spiked down → fade buy
   return SIGNAL_NONE;
  }

#endif // APEX_NEWS_MQH
