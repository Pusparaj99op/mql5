//+------------------------------------------------------------------+
//|                                               XM_NewsFilter.mqh |
//|                        Economic News Filter                      |
//|                              Copyright 2024-2026, XM_XAUUSD Bot  |
//+------------------------------------------------------------------+
#property copyright "XM_XAUUSD Bot"
#property link      "https://github.com/Pusparaj99op/XM_XAUUSD"
#property version   "1.00"
#property strict

#ifndef XM_NEWSFILTER_MQH
#define XM_NEWSFILTER_MQH

#include "XM_Config.mqh"

//+------------------------------------------------------------------+
//| News Event Structure                                              |
//+------------------------------------------------------------------+
struct NewsEvent
{
   datetime          time;
   string            currency;
   string            title;
   int               impact;          // 1=Low, 2=Medium, 3=High
   bool              isGoldRelated;
};

//+------------------------------------------------------------------+
//| CNewsFilter Class                                                 |
//+------------------------------------------------------------------+
class CNewsFilter
{
private:
   string            m_apiEndpoint;
   bool              m_enabled;
   bool              m_useAPI;
   bool              m_useCalendarFile;

   // News events storage
   NewsEvent         m_newsEvents[];
   int               m_eventCount;
   datetime          m_lastFetch;
   int               m_fetchIntervalHours;

   // Built-in important events (fallback)
   datetime          m_manualEvents[];
   int               m_manualEventCount;

   // Pause settings
   int               m_minutesBefore;
   int               m_minutesAfter;

   bool              m_isTradingPaused;
   string            m_pauseReason;
   datetime          m_pauseEndTime;

public:
   //--- Constructor/Destructor
                     CNewsFilter();
                    ~CNewsFilter();

   //--- Initialization
   bool              Initialize(string apiEndpoint = "", int minutesBefore = 15, int minutesAfter = 15);
   void              SetEnabled(bool enabled) { m_enabled = enabled; }
   bool              IsEnabled() { return m_enabled; }

   //--- Main check functions
   bool              IsTradingSafe();
   bool              IsNewsTime();
   bool              HasUpcomingNews(int withinMinutes);

   //--- News event management
   bool              FetchNewsFromAPI();
   bool              LoadNewsFromFile(string filename);
   void              AddManualEvent(datetime time, string title, int impact);
   void              ClearOldEvents();

   //--- Get info
   NewsEvent         GetNextEvent();
   int               GetMinutesToNextNews();
   string            GetPauseReason() { return m_pauseReason; }
   datetime          GetPauseEndTime() { return m_pauseEndTime; }
   int               GetEventCount() { return m_eventCount; }

   //--- Gold-specific news
   void              AddGoldRelatedEvents();
   bool              IsGoldImpactNews(NewsEvent &event);

   //--- Utility
   void              PrintUpcomingEvents(int count = 5);
   string            ImpactToString(int impact);

private:
   bool              ParseNewsJSON(string jsonData);
   bool              ParseNewsCSV(string csvData);
   void              SortEventsByTime();
   bool              IsImportantCurrency(string currency);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CNewsFilter::CNewsFilter()
{
   m_apiEndpoint = "";
   m_enabled = false;
   m_useAPI = false;
   m_useCalendarFile = false;
   m_eventCount = 0;
   m_lastFetch = 0;
   m_fetchIntervalHours = 4;
   m_manualEventCount = 0;
   m_minutesBefore = 15;
   m_minutesAfter = 15;
   m_isTradingPaused = false;
   m_pauseReason = "";
   m_pauseEndTime = 0;

   ArrayResize(m_newsEvents, 0);
   ArrayResize(m_manualEvents, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CNewsFilter::~CNewsFilter()
{
   ArrayFree(m_newsEvents);
   ArrayFree(m_manualEvents);
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CNewsFilter::Initialize(string apiEndpoint = "", int minutesBefore = 15, int minutesAfter = 15)
{
   m_minutesBefore = minutesBefore;
   m_minutesAfter = minutesAfter;
   m_enabled = true;

   if(StringLen(apiEndpoint) > 0)
   {
      m_apiEndpoint = apiEndpoint;
      m_useAPI = true;
      Print("News Filter: API mode enabled. Endpoint: ", m_apiEndpoint);
   }
   else
   {
      m_useAPI = false;
      Print("News Filter: Using built-in calendar. No API configured.");
   }

   // Add known recurring events
   AddGoldRelatedEvents();

   Print("News Filter initialized. Pause: ", m_minutesBefore, " min before, ", m_minutesAfter, " min after");

   return true;
}

//+------------------------------------------------------------------+
//| Check if Trading is Safe (no news)                                |
//+------------------------------------------------------------------+
bool CNewsFilter::IsTradingSafe()
{
   if(!m_enabled) return true;

   // Check if currently in pause period
   if(m_isTradingPaused && TimeCurrent() < m_pauseEndTime)
   {
      return false;
   }

   // Check for upcoming news
   if(IsNewsTime())
   {
      return false;
   }

   m_isTradingPaused = false;
   m_pauseReason = "";
   return true;
}

//+------------------------------------------------------------------+
//| Check if Currently in News Time Window                            |
//+------------------------------------------------------------------+
bool CNewsFilter::IsNewsTime()
{
   if(!m_enabled) return false;

   datetime now = TimeCurrent();
   datetime windowStart = now - m_minutesAfter * 60;
   datetime windowEnd = now + m_minutesBefore * 60;

   // Check all events
   for(int i = 0; i < m_eventCount; i++)
   {
      // Only check high impact if configured
      if(InpFilterHighImpact && m_newsEvents[i].impact < 3)
         continue;

      if(InpFilterMediumImpact && m_newsEvents[i].impact < 2)
         continue;

      // Check if event is in the window
      if(m_newsEvents[i].time >= windowStart && m_newsEvents[i].time <= windowEnd)
      {
         m_isTradingPaused = true;
         m_pauseReason = StringFormat("News: %s (%s)",
                                       m_newsEvents[i].title,
                                       TimeToString(m_newsEvents[i].time, TIME_MINUTES));
         m_pauseEndTime = m_newsEvents[i].time + m_minutesAfter * 60;
         return true;
      }
   }

   // Check manual events
   for(int i = 0; i < m_manualEventCount; i++)
   {
      if(m_manualEvents[i] >= windowStart && m_manualEvents[i] <= windowEnd)
      {
         m_isTradingPaused = true;
         m_pauseReason = "Scheduled news event";
         m_pauseEndTime = m_manualEvents[i] + m_minutesAfter * 60;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if Has Upcoming News                                        |
//+------------------------------------------------------------------+
bool CNewsFilter::HasUpcomingNews(int withinMinutes)
{
   datetime now = TimeCurrent();
   datetime windowEnd = now + withinMinutes * 60;

   for(int i = 0; i < m_eventCount; i++)
   {
      if(m_newsEvents[i].time >= now && m_newsEvents[i].time <= windowEnd)
      {
         if(InpFilterHighImpact && m_newsEvents[i].impact >= 3)
            return true;
         if(InpFilterMediumImpact && m_newsEvents[i].impact >= 2)
            return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Fetch News from API                                               |
//+------------------------------------------------------------------+
bool CNewsFilter::FetchNewsFromAPI()
{
   if(!m_useAPI || StringLen(m_apiEndpoint) == 0)
      return false;

   // Check if should fetch (rate limiting)
   if(TimeCurrent() - m_lastFetch < m_fetchIntervalHours * 3600)
      return true; // Use cached data

   char data[];
   char result[];
   string resultHeaders;

   int timeout = 10000; // 10 seconds

   int res = WebRequest(
      "GET",
      m_apiEndpoint,
      "",
      timeout,
      data,
      result,
      resultHeaders
   );

   if(res == -1)
   {
      int error = GetLastError();
      if(error == 4014)
      {
         Print("News API: URL not allowed. Add your API URL to MT5 allowed WebRequest URLs");
      }
      else
      {
         Print("News API: WebRequest error: ", error);
      }
      return false;
   }

   if(res == 200)
   {
      string jsonData = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
      m_lastFetch = TimeCurrent();
      return ParseNewsJSON(jsonData);
   }

   Print("News API: HTTP error ", res);
   return false;
}

//+------------------------------------------------------------------+
//| Load News from CSV File                                           |
//+------------------------------------------------------------------+
bool CNewsFilter::LoadNewsFromFile(string filename)
{
   // File format: datetime,currency,title,impact
   // Example: 2026.02.13 14:30,USD,CPI m/m,3

   int handle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      Print("News: Could not open calendar file: ", filename);
      return false;
   }

   string content = "";
   while(!FileIsEnding(handle))
   {
      content += FileReadString(handle) + "\n";
   }
   FileClose(handle);

   return ParseNewsCSV(content);
}

//+------------------------------------------------------------------+
//| Add Manual Event                                                  |
//+------------------------------------------------------------------+
void CNewsFilter::AddManualEvent(datetime time, string title, int impact)
{
   // Add to manual events
   ArrayResize(m_manualEvents, m_manualEventCount + 1);
   m_manualEvents[m_manualEventCount] = time;
   m_manualEventCount++;

   // Also add to news events
   ArrayResize(m_newsEvents, m_eventCount + 1);
   m_newsEvents[m_eventCount].time = time;
   m_newsEvents[m_eventCount].currency = "USD";
   m_newsEvents[m_eventCount].title = title;
   m_newsEvents[m_eventCount].impact = impact;
   m_newsEvents[m_eventCount].isGoldRelated = true;
   m_eventCount++;
}

//+------------------------------------------------------------------+
//| Clear Old Events                                                  |
//+------------------------------------------------------------------+
void CNewsFilter::ClearOldEvents()
{
   datetime now = TimeCurrent();
   int validCount = 0;

   for(int i = 0; i < m_eventCount; i++)
   {
      // Keep events from last hour and future
      if(m_newsEvents[i].time >= now - 3600)
      {
         if(validCount != i)
         {
            m_newsEvents[validCount] = m_newsEvents[i];
         }
         validCount++;
      }
   }

   m_eventCount = validCount;
   ArrayResize(m_newsEvents, m_eventCount);
}

//+------------------------------------------------------------------+
//| Get Next Event                                                    |
//+------------------------------------------------------------------+
NewsEvent CNewsFilter::GetNextEvent()
{
   NewsEvent empty;
   empty.time = 0;
   empty.currency = "";
   empty.title = "";
   empty.impact = 0;
   empty.isGoldRelated = false;

   datetime now = TimeCurrent();

   for(int i = 0; i < m_eventCount; i++)
   {
      if(m_newsEvents[i].time > now)
      {
         return m_newsEvents[i];
      }
   }

   return empty;
}

//+------------------------------------------------------------------+
//| Get Minutes to Next News                                          |
//+------------------------------------------------------------------+
int CNewsFilter::GetMinutesToNextNews()
{
   NewsEvent next = GetNextEvent();
   if(next.time == 0)
      return 9999;

   datetime now = TimeCurrent();
   return (int)((next.time - now) / 60);
}

//+------------------------------------------------------------------+
//| Add Gold Related Events                                           |
//+------------------------------------------------------------------+
void CNewsFilter::AddGoldRelatedEvents()
{
   // Add recurring important events for Gold/USD
   // These are approximate times - in production, use API or updated calendar

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   // Get this week's dates
   datetime today = StringToTime(TimeToString(now, TIME_DATE));

   // NFP - First Friday of month at 13:30 GMT (typical)
   // FOMC - Check fed calendar
   // CPI - Usually mid-month

   // Add some sample events for testing (you should replace with real calendar)
   // These would typically come from your API or a calendar file

   /*
   // Example: Add NFP if it's the first Friday
   if(dt.day_of_week == 5 && dt.day <= 7)
   {
      datetime nfpTime = today + 13 * 3600 + 30 * 60; // 13:30
      AddManualEvent(nfpTime, "Non-Farm Payrolls", 3);
   }
   */

   Print("Gold-related events configured");
}

//+------------------------------------------------------------------+
//| Check if Gold Impact News                                         |
//+------------------------------------------------------------------+
bool CNewsFilter::IsGoldImpactNews(NewsEvent &event)
{
   // High impact USD news affects Gold
   if(event.currency == "USD" && event.impact >= 3)
      return true;

   // Interest rate decisions
   if(StringFind(event.title, "Interest Rate") >= 0)
      return true;

   // Inflation data
   if(StringFind(event.title, "CPI") >= 0 || StringFind(event.title, "Inflation") >= 0)
      return true;

   // Employment data
   if(StringFind(event.title, "NFP") >= 0 || StringFind(event.title, "Employment") >= 0)
      return true;

   // Fed related
   if(StringFind(event.title, "Fed") >= 0 || StringFind(event.title, "FOMC") >= 0)
      return true;

   return event.isGoldRelated;
}

//+------------------------------------------------------------------+
//| Print Upcoming Events                                             |
//+------------------------------------------------------------------+
void CNewsFilter::PrintUpcomingEvents(int count = 5)
{
   Print("=== Upcoming News Events ===");

   int printed = 0;
   datetime now = TimeCurrent();

   for(int i = 0; i < m_eventCount && printed < count; i++)
   {
      if(m_newsEvents[i].time > now)
      {
         Print(TimeToString(m_newsEvents[i].time, TIME_DATE|TIME_MINUTES),
               " | ", m_newsEvents[i].currency,
               " | ", ImpactToString(m_newsEvents[i].impact),
               " | ", m_newsEvents[i].title);
         printed++;
      }
   }

   if(printed == 0)
      Print("No upcoming events in calendar");

   Print("============================");
}

//+------------------------------------------------------------------+
//| Impact to String                                                  |
//+------------------------------------------------------------------+
string CNewsFilter::ImpactToString(int impact)
{
   switch(impact)
   {
      case 1: return "Low";
      case 2: return "Medium";
      case 3: return "HIGH";
      default: return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Parse News JSON                                                   |
//+------------------------------------------------------------------+
bool CNewsFilter::ParseNewsJSON(string jsonData)
{
   // Simple JSON parsing for news events
   // Expected format: [{"time":"2026-02-13T14:30:00Z","currency":"USD","title":"CPI","impact":3}, ...]

   // This is a simplified parser - in production use a proper JSON library

   int count = 0;
   int pos = 0;

   ArrayResize(m_newsEvents, 0);
   m_eventCount = 0;

   while(true)
   {
      int start = StringFind(jsonData, "{", pos);
      if(start < 0) break;

      int end = StringFind(jsonData, "}", start);
      if(end < 0) break;

      string eventStr = StringSubstr(jsonData, start, end - start + 1);

      // Extract fields (simplified)
      // In production, use proper JSON parsing

      NewsEvent event;
      event.time = TimeCurrent(); // Default
      event.currency = "USD";
      event.title = "Unknown Event";
      event.impact = 2;
      event.isGoldRelated = true;

      // Try to find time
      int timePos = StringFind(eventStr, "\"time\":");
      if(timePos >= 0)
      {
         // Parse time...
         // This would need proper implementation based on your API's time format
      }

      ArrayResize(m_newsEvents, m_eventCount + 1);
      m_newsEvents[m_eventCount] = event;
      m_eventCount++;

      pos = end + 1;
      count++;

      if(count > 100) break; // Safety limit
   }

   Print("Parsed ", m_eventCount, " news events from API");
   SortEventsByTime();

   return m_eventCount > 0;
}

//+------------------------------------------------------------------+
//| Parse News CSV                                                    |
//+------------------------------------------------------------------+
bool CNewsFilter::ParseNewsCSV(string csvData)
{
   // Format: datetime,currency,title,impact

   string lines[];
   int lineCount = StringSplit(csvData, '\n', lines);

   ArrayResize(m_newsEvents, 0);
   m_eventCount = 0;

   for(int i = 0; i < lineCount; i++)
   {
      string line = lines[i];
      StringTrimLeft(line);
      StringTrimRight(line);

      if(StringLen(line) == 0) continue;
      if(StringGetCharacter(line, 0) == '#') continue; // Skip comments

      string fields[];
      int fieldCount = StringSplit(line, ',', fields);

      if(fieldCount >= 4)
      {
         NewsEvent event;
         event.time = StringToTime(fields[0]);
         event.currency = fields[1];
         event.title = fields[2];
         event.impact = (int)StringToInteger(fields[3]);
         event.isGoldRelated = IsImportantCurrency(event.currency);

         ArrayResize(m_newsEvents, m_eventCount + 1);
         m_newsEvents[m_eventCount] = event;
         m_eventCount++;
      }
   }

   Print("Loaded ", m_eventCount, " news events from CSV");
   SortEventsByTime();

   return m_eventCount > 0;
}

//+------------------------------------------------------------------+
//| Sort Events by Time                                               |
//+------------------------------------------------------------------+
void CNewsFilter::SortEventsByTime()
{
   // Simple bubble sort
   for(int i = 0; i < m_eventCount - 1; i++)
   {
      for(int j = 0; j < m_eventCount - i - 1; j++)
      {
         if(m_newsEvents[j].time > m_newsEvents[j + 1].time)
         {
            NewsEvent temp = m_newsEvents[j];
            m_newsEvents[j] = m_newsEvents[j + 1];
            m_newsEvents[j + 1] = temp;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if Important Currency for Gold                              |
//+------------------------------------------------------------------+
bool CNewsFilter::IsImportantCurrency(string currency)
{
   // USD is most important for Gold
   if(currency == "USD") return true;

   // These can also affect Gold
   if(currency == "EUR") return true;
   if(currency == "CNY") return true;
   if(currency == "CHF") return true;

   return false;
}

#endif // XM_NEWSFILTER_MQH
//+------------------------------------------------------------------+
