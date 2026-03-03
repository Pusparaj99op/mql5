//+------------------------------------------------------------------+
//|                                             SessionIndicator.mq5 |
//|                              Market Session Boxes for MT5        |
//|  Asia / London / New York session rectangles.                    |
//|  UTC time sourced from broker server — device clock is ignored.  |
//+------------------------------------------------------------------+
#property copyright "MIT License"
#property version   "1.10"
#property description "Asia / London / New York session boxes with UTC dashboard."
#property description "Times are UTC from broker server — device clock has no effect."
#property indicator_chart_window
#property indicator_plots 0

#define OBJ_PREFIX  "SessInd_"
#define DB_PREFIX   "SessInd_DB_"    // dashboard objects

//=== Input Parameters =====================================================

input group              "=== Asia Session ==="
input bool   Asia_Show         = true;              // Show Asia session
input int    Asia_Start_Hour   = 0;                 // Asia start hour (UTC, 0–23)
input int    Asia_End_Hour     = 9;                 // Asia end hour   (UTC, 0–23)
input color  Asia_Color        = clrCornflowerBlue; // Asia colour

input group              "=== London Session ==="
input bool   London_Show       = true;              // Show London session
input int    London_Start_Hour = 8;                 // London start hour (UTC)
input int    London_End_Hour   = 17;                // London end hour   (UTC)
input color  London_Color      = clrMediumSeaGreen; // London colour

input group              "=== New York Session ==="
input bool   NY_Show           = true;              // Show New York session
input int    NY_Start_Hour     = 13;                // New York start hour (UTC)
input int    NY_End_Hour       = 22;                // New York end hour   (UTC)
input color  NY_Color          = clrSalmon;         // New York colour

input group              "=== Display ==="
input int    Days_To_Show      = 10;                // Trading days of history to draw
input int    Transparency      = 85;                // Box fill transparency: 0=opaque, 100=invisible
input bool   Show_Labels       = true;              // Show session labels with time range
input int    Label_Font_Size   = 9;                 // Label font size

input group              "=== Extra Visuals ==="
input bool             Show_Dashboard = true;              // UTC clock + active-session panel
input bool             Show_Open_Line = true;              // Dashed line at session open price
input bool             Show_Mid_Line  = false;             // Dotted line at session midpoint
input ENUM_BASE_CORNER Panel_Corner   = CORNER_RIGHT_UPPER; // Panel anchor corner

input group              "=== Economic Events ==="
input bool   Show_Events            = true;                    // Show upcoming high-impact USD event lines
input color  Event_Line_Color       = C'180,0,255';            // Event line colour (purple)
input int    Event_Days_Ahead       = 7;                       // How many days ahead to look for events
input bool   High_Impact_Only       = true;                    // Only show high-impact events
input bool   Use_External_Calendar  = false;                   // Fetch calendar from ForexFactory (requires WebRequest URL permission)
// ↑ To enable: MT5 → Tools → Options → Expert Advisors → Allow WebRequest
//   and add:  https://www.forexfactory.com

//=== Data Structures ======================================================

struct SessionDef
  {
   string            name;
   bool              show;
   int               startHour;
   int               endHour;
   color             clr;
  };

SessionDef g_sessions[3];

int g_eventRefreshTick = 0;   // counts OnTimer() ticks; event lines refresh every 60 s

// Dashboard label Y-offsets (pixels from corner, 18px per row)
#define DB_BG_X      10
#define DB_BG_Y      10
#define DB_BG_W      175
#define DB_BG_H      110
#define DB_TEXT_X    18
#define DB_ROW_H     18

//==========================================================================
//| Helpers                                                                  |
//==========================================================================

//--- Compute ARGB colour with alpha derived from Transparency input
uint ApplyAlpha(color clr)
  {
   uchar alpha = (uchar)MathRound(255.0 * (1.0 - Transparency / 100.0));
   return ColorToARGB(clr, alpha);
  }

//--- Is UTC hour 'h' inside [startHour, endHour)?
bool IsSessionOpen(int startHour, int endHour, int utcHour)
  {
   return (utcHour >= startHour && utcHour < endHour);
  }

//--- ENUM_BASE_CORNER → matching ENUM_ANCHOR_POINT for text labels
ENUM_ANCHOR_POINT CornerAnchor(ENUM_BASE_CORNER c)
  {
   switch(c)
     {
      case CORNER_RIGHT_UPPER: return ANCHOR_RIGHT_UPPER;
      case CORNER_LEFT_LOWER:  return ANCHOR_LEFT_LOWER;
      case CORNER_RIGHT_LOWER: return ANCHOR_RIGHT_LOWER;
      default:                 return ANCHOR_LEFT_UPPER;
     }
  }

//==========================================================================
//| DeleteSessionObjects                                                     |
//==========================================================================
void DeleteSessionObjects()
  {
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, OBJ_PREFIX) == 0)
         ObjectDelete(0, name);
     }
  }

//==========================================================================
//| Dashboard — create background panel + static label objects              |
//==========================================================================
void DrawDashboard()
  {
//--- Background panel
   string bg = DB_PREFIX + "BG";
   if(ObjectFind(0, bg) < 0)
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bg, OBJPROP_CORNER,     Panel_Corner);
   ObjectSetInteger(0, bg, OBJPROP_XDISTANCE,  DB_BG_X);
   ObjectSetInteger(0, bg, OBJPROP_YDISTANCE,  DB_BG_Y);
   ObjectSetInteger(0, bg, OBJPROP_XSIZE,      DB_BG_W);
   ObjectSetInteger(0, bg, OBJPROP_YSIZE,      DB_BG_H);
   ObjectSetInteger(0, bg, OBJPROP_BGCOLOR,    C'18,22,28');
   ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0, bg, OBJPROP_COLOR,      C'55,65,80');
   ObjectSetInteger(0, bg, OBJPROP_BACK,       false);
   ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, bg, OBJPROP_HIDDEN,     true);

//--- Helper: create or reuse a text label
   string names[5];
   names[0] = DB_PREFIX + "Title";
   names[1] = DB_PREFIX + "UTC";
   names[2] = DB_PREFIX + "Asia";
   names[3] = DB_PREFIX + "London";
   names[4] = DB_PREFIX + "NY";

   color  colours[5] = {C'120,130,145', clrWhite, Asia_Color, London_Color, NY_Color};
   string fonts[5]   = {"Arial Bold", "Courier New", "Arial Bold", "Arial Bold", "Arial Bold"};
   int    sizes[5]   = {8, 9, 9, 9, 9};

   for(int i = 0; i < 5; i++)
     {
      if(ObjectFind(0, names[i]) < 0)
         ObjectCreate(0, names[i], OBJ_LABEL, 0, 0, 0);
      int xd = (Panel_Corner == CORNER_RIGHT_UPPER || Panel_Corner == CORNER_RIGHT_LOWER)
               ? DB_BG_X + DB_BG_W - DB_TEXT_X
               : DB_BG_X + DB_TEXT_X;
      int yd = DB_BG_Y + 8 + i * DB_ROW_H;
      if(Panel_Corner == CORNER_LEFT_LOWER || Panel_Corner == CORNER_RIGHT_LOWER)
         yd = DB_BG_Y + DB_BG_H - 8 - (4 - i) * DB_ROW_H;

      ObjectSetInteger(0, names[i], OBJPROP_CORNER,     Panel_Corner);
      ObjectSetInteger(0, names[i], OBJPROP_XDISTANCE,  xd);
      ObjectSetInteger(0, names[i], OBJPROP_YDISTANCE,  yd);
      ObjectSetInteger(0, names[i], OBJPROP_ANCHOR,     CornerAnchor(Panel_Corner));
      ObjectSetString (0, names[i], OBJPROP_FONT,       fonts[i]);
      ObjectSetInteger(0, names[i], OBJPROP_FONTSIZE,   sizes[i]);
      ObjectSetInteger(0, names[i], OBJPROP_COLOR,      colours[i]);
      ObjectSetInteger(0, names[i], OBJPROP_BACK,       false);
      ObjectSetInteger(0, names[i], OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, names[i], OBJPROP_HIDDEN,     true);
     }

   ObjectSetString(0, DB_PREFIX + "Title", OBJPROP_TEXT, "  SESSION MONITOR");
   UpdateDashboard();
  }

//--- Refresh UTC time and session LIVE/---- status (called every second)
void UpdateDashboard()
  {
   if(!Show_Dashboard) return;

   datetime utcNow = TimeGMT();
   MqlDateTime u;
   TimeToStruct(utcNow, u);

   ObjectSetString(0, DB_PREFIX + "UTC",
                   OBJPROP_TEXT,
                   StringFormat("  UTC  %02d:%02d:%02d", u.hour, u.min, u.sec));

   string sessNames[3] = {DB_PREFIX + "Asia", DB_PREFIX + "London", DB_PREFIX + "NY"};
   for(int s = 0; s < 3; s++)
     {
      if(!g_sessions[s].show)
        {
         ObjectSetString(0, sessNames[s], OBJPROP_TEXT,  "");
         continue;
        }
      bool live = IsSessionOpen(g_sessions[s].startHour, g_sessions[s].endHour, u.hour);
      string status = live ? "  LIVE" : "  ----";
      string row = StringFormat("  \x25CF %s %02d\x2013%02d  %s",
                                g_sessions[s].name,
                                g_sessions[s].startHour,
                                g_sessions[s].endHour,
                                status);
      ObjectSetString(0, sessNames[s], OBJPROP_TEXT, row);
      // Dim the label when session is closed
      ObjectSetInteger(0, sessNames[s], OBJPROP_COLOR,
                       live ? g_sessions[s].clr : C'70,80,95');
     }
   ChartRedraw(0);
  }

//==========================================================================
//| OnInit                                                                   |
//==========================================================================
int OnInit()
  {
   if(Days_To_Show < 1 || Days_To_Show > 365)
     { Print("SessionIndicator: Days_To_Show must be 1–365."); return INIT_PARAMETERS_INCORRECT; }

   int hourInputs[6] = {Asia_Start_Hour, Asia_End_Hour,
                        London_Start_Hour, London_End_Hour,
                        NY_Start_Hour, NY_End_Hour};
   for(int i = 0; i < 6; i++)
     {
      if(hourInputs[i] < 0 || hourInputs[i] > 23)
        { Print("SessionIndicator: Hour values must be 0–23."); return INIT_PARAMETERS_INCORRECT; }
     }

   g_sessions[0].name = "Asia";    g_sessions[0].show = Asia_Show;
   g_sessions[0].startHour = Asia_Start_Hour;    g_sessions[0].endHour = Asia_End_Hour;
   g_sessions[0].clr = Asia_Color;

   g_sessions[1].name = "London";  g_sessions[1].show = London_Show;
   g_sessions[1].startHour = London_Start_Hour;  g_sessions[1].endHour = London_End_Hour;
   g_sessions[1].clr = London_Color;

   g_sessions[2].name = "NY";      g_sessions[2].show = NY_Show;
   g_sessions[2].startHour = NY_Start_Hour;      g_sessions[2].endHour = NY_End_Hour;
   g_sessions[2].clr = NY_Color;

   // Ensure chart draws candles on top of background objects
   ChartSetInteger(0, CHART_FOREGROUND, true);

   DeleteSessionObjects();

   if(Show_Dashboard)
      DrawDashboard();

   DrawAllSessions();

   EventSetTimer(1); // 1-second tick for live UTC clock

   return INIT_SUCCEEDED;
  }

//==========================================================================
//| OnDeinit                                                                 |
//==========================================================================
void OnDeinit(const int reason)
  {
   EventKillTimer();
   DeleteSessionObjects();
  }

//==========================================================================
//| OnTimer — fires every second; refreshes UTC clock in dashboard          |
//==========================================================================
void OnTimer()
  {
   UpdateDashboard();
   g_eventRefreshTick++;
   if(g_eventRefreshTick >= 60)
     {
      g_eventRefreshTick = 0;
      DrawEventLines();
     }
  }

//==========================================================================
//| OnCalculate                                                              |
//==========================================================================
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(prev_calculated == 0 || rates_total != prev_calculated)
      DrawAllSessions();
   return rates_total;
  }

//==========================================================================
//| DrawAllSessions                                                          |
//==========================================================================
void DrawAllSessions()
  {
   datetime utcNow  = TimeGMT();

   MqlDateTime st;
   TimeToStruct(utcNow, st);
   st.hour = 0; st.min = 0; st.sec = 0;
   datetime todayUTC = StructToTime(st);

   int daysDrawn = 0;
   int offset    = 0;

   while(daysDrawn < Days_To_Show)
     {
      if(offset > Days_To_Show * 3 + 10) break;

      datetime dayStart = todayUTC - (long)offset * 86400;
      MqlDateTime d;
      TimeToStruct(dayStart, d);
      if(d.day_of_week == 0 || d.day_of_week == 6)
        { offset++; continue; }

      for(int s = 0; s < 3; s++)
         if(g_sessions[s].show)
            DrawSession(g_sessions[s], dayStart, utcNow);

      daysDrawn++;
      offset++;
     }

   UpdateDashboard();
   DrawEventLines();
   ChartRedraw(0);
  }

//==========================================================================
//| DrawSession — rectangle, open line, midline, label                      |
//==========================================================================
void DrawSession(const SessionDef &sess, const datetime dayStart, const datetime utcNow)
  {
   datetime sessStart = dayStart + (long)sess.startHour * 3600;
   datetime sessEnd   = dayStart + (long)sess.endHour   * 3600;

   if(sessStart > utcNow) return;

   bool     isOpen  = (utcNow >= sessStart && utcNow < sessEnd);
   datetime drawEnd = isOpen ? utcNow : sessEnd;

//--- Object name stems
   MqlDateTime ds;
   TimeToStruct(dayStart, ds);
   string dateStr   = StringFormat("%04d%02d%02d", ds.year, ds.mon, ds.day);
   string stem      = OBJ_PREFIX + sess.name + "_" + dateStr;
   string rectName  = stem + "_R";
   string labelName = stem + "_L";
   string openName  = stem + "_O";
   string midName   = stem + "_M";

//--- Bar indices
   int barLeft  = iBarShift(_Symbol, PERIOD_CURRENT, sessStart, false);
   int barRight = iBarShift(_Symbol, PERIOD_CURRENT, drawEnd,   false);

   if(barLeft < 0 && barRight < 0) return;

   int totalBars = iBars(_Symbol, PERIOD_CURRENT);
   if(barLeft  < 0) barLeft  = totalBars - 1;
   if(barRight < 0) barRight = 0;
   if(barLeft  >= totalBars) barLeft  = totalBars - 1;
   if(barRight >= totalBars) barRight = totalBars - 1;
   if(barLeft < barRight) { int t = barLeft; barLeft = barRight; barRight = t; }

   int barCount = barLeft - barRight + 1;
   if(barCount <= 0) return;

//--- Price range
   int    highIdx  = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, barCount, barRight);
   int    lowIdx   = iLowest (_Symbol, PERIOD_CURRENT, MODE_LOW,  barCount, barRight);
   if(highIdx < 0 || lowIdx < 0) return;

   double priceHigh = iHigh(_Symbol, PERIOD_CURRENT, highIdx);
   double priceLow  = iLow (_Symbol, PERIOD_CURRENT, lowIdx);
   if(priceHigh <= 0.0 || priceLow <= 0.0 || priceHigh <= priceLow) return;

   double priceMid  = (priceHigh + priceLow) * 0.5;
   double priceOpen = iOpen(_Symbol, PERIOD_CURRENT, barLeft);  // open of first session bar

//--- Alpha-blended colour
   uint  fillClr  = ApplyAlpha(sess.clr);

// ── Rectangle ────────────────────────────────────────────────────────────
   if(ObjectFind(0, rectName) >= 0) ObjectDelete(0, rectName);
   ObjectCreate(0, rectName, OBJ_RECTANGLE, 0,
                sessStart, priceHigh, drawEnd, priceLow);
   ObjectSetInteger(0, rectName, OBJPROP_COLOR,      (long)fillClr);
   ObjectSetInteger(0, rectName, OBJPROP_FILL,       true);
   ObjectSetInteger(0, rectName, OBJPROP_BACK,       true);
   ObjectSetInteger(0, rectName, OBJPROP_WIDTH,      isOpen ? 2 : 1);         // live = thicker border
   ObjectSetInteger(0, rectName, OBJPROP_STYLE,      isOpen ? STYLE_SOLID : STYLE_DOT);
   ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, rectName, OBJPROP_HIDDEN,     true);

// ── Session open price line ───────────────────────────────────────────────
   if(Show_Open_Line && priceOpen > 0.0)
     {
      if(ObjectFind(0, openName) >= 0) ObjectDelete(0, openName);
      ObjectCreate(0, openName, OBJ_TREND, 0,
                   sessStart, priceOpen, drawEnd, priceOpen);
      ObjectSetInteger(0, openName, OBJPROP_COLOR,       (long)ApplyAlpha(sess.clr));
      ObjectSetInteger(0, openName, OBJPROP_WIDTH,       1);
      ObjectSetInteger(0, openName, OBJPROP_STYLE,       STYLE_DASH);
      ObjectSetInteger(0, openName, OBJPROP_RAY_LEFT,    false);
      ObjectSetInteger(0, openName, OBJPROP_RAY_RIGHT,   false);
      ObjectSetInteger(0, openName, OBJPROP_BACK,        true);
      ObjectSetInteger(0, openName, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(0, openName, OBJPROP_HIDDEN,      true);
     }

// ── Midpoint line ─────────────────────────────────────────────────────────
   if(Show_Mid_Line)
     {
      if(ObjectFind(0, midName) >= 0) ObjectDelete(0, midName);
      ObjectCreate(0, midName, OBJ_TREND, 0,
                   sessStart, priceMid, drawEnd, priceMid);
      ObjectSetInteger(0, midName, OBJPROP_COLOR,      (long)ApplyAlpha(sess.clr));
      ObjectSetInteger(0, midName, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, midName, OBJPROP_STYLE,      STYLE_DOT);
      ObjectSetInteger(0, midName, OBJPROP_RAY_LEFT,   false);
      ObjectSetInteger(0, midName, OBJPROP_RAY_RIGHT,  false);
      ObjectSetInteger(0, midName, OBJPROP_BACK,       true);
      ObjectSetInteger(0, midName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, midName, OBJPROP_HIDDEN,     true);
     }

// ── Label ─────────────────────────────────────────────────────────────────
   if(!Show_Labels) return;

   if(ObjectFind(0, labelName) >= 0) ObjectDelete(0, labelName);

   string labelText = StringFormat("%s  %02d\x2013%02d%s",
                                   sess.name,
                                   sess.startHour,
                                   sess.endHour,
                                   isOpen ? "  \x25CF" : "");  // ● dot when live

   ObjectCreate(0, labelName, OBJ_TEXT, 0, sessStart, priceHigh);
   ObjectSetString (0, labelName, OBJPROP_TEXT,       labelText);
   ObjectSetString (0, labelName, OBJPROP_FONT,       "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE,   Label_Font_Size);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR,      sess.clr);
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR,     ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, labelName, OBJPROP_BACK,       false);
   ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, labelName, OBJPROP_HIDDEN,     true);
  }

//==========================================================================
//| PlaceEventVLine — draw one purple dotted vertical + rotated label       |
//==========================================================================
void PlaceEventVLine(const string lineName,
                     const string labelName,
                     const datetime evTime,
                     const string   evName,
                     const double   labelPrice)
  {
   if(ObjectFind(0, lineName)  >= 0) ObjectDelete(0, lineName);
   if(ObjectFind(0, labelName) >= 0) ObjectDelete(0, labelName);

   ObjectCreate(0, lineName, OBJ_VLINE, 0, evTime, 0);
   ObjectSetInteger(0, lineName, OBJPROP_COLOR,      Event_Line_Color);
   ObjectSetInteger(0, lineName, OBJPROP_STYLE,      STYLE_DOT);
   ObjectSetInteger(0, lineName, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, lineName, OBJPROP_BACK,       true);
   ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, lineName, OBJPROP_HIDDEN,     true);
   ObjectSetString (0, lineName, OBJPROP_TOOLTIP,    evName);

   string shortName = evName;
   if(StringLen(shortName) > 20) shortName = StringSubstr(shortName, 0, 20);

   ObjectCreate(0, labelName, OBJ_TEXT, 0, evTime, labelPrice);
   ObjectSetString (0, labelName, OBJPROP_TEXT,      shortName);
   ObjectSetString (0, labelName, OBJPROP_FONT,      "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE,  7);
   ObjectSetDouble (0, labelName, OBJPROP_ANGLE,     90.0);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR,     Event_Line_Color);
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, labelName, OBJPROP_BACK,      false);
   ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, labelName, OBJPROP_HIDDEN,    true);
  }

//==========================================================================
//| RSS / WebRequest helpers                                                 |
//==========================================================================

//--- Extract the first occurrence of <tag>...</tag> starting at pos
string ExtractTagValue(const string &src, const string tag, int &pos)
  {
   string o = "<" + tag + ">";
   string c = "</" + tag + ">";
   int s = StringFind(src, o, pos);
   if(s < 0) { pos = StringLen(src); return ""; }
   s += StringLen(o);
   int e = StringFind(src, c, s);
   if(e < 0) { pos = StringLen(src); return ""; }
   pos = e + StringLen(c);
   return StringSubstr(src, s, e - s);
  }

//--- Parse RFC 2822 date "Tue, 10 Feb 2026 13:30:00 GMT" → datetime
//    Treated as broker-server time (consistent with existing session logic)
datetime ParseRFC2822(const string &dt)
  {
   string months[] = {"Jan","Feb","Mar","Apr","May","Jun",
                       "Jul","Aug","Sep","Oct","Nov","Dec"};
   int cp = StringFind(dt, ", ");
   if(cp < 0) return 0;
   string rest = StringSubstr(dt, cp + 2);
   string p[];
   if(StringSplit(rest, ' ', p) < 4) return 0;
   int day = (int)StringToInteger(p[0]);
   int mon = 0;
   for(int m = 0; m < 12; m++)
      if(p[1] == months[m]) { mon = m + 1; break; }
   int year = (int)StringToInteger(p[2]);
   if(day <= 0 || mon == 0 || year < 2020) return 0;
   string tp[];
   if(StringSplit(p[3], ':', tp) < 2) return 0;
   int h  = (int)StringToInteger(tp[0]);
   int mi = (int)StringToInteger(tp[1]);
   int sc = (ArraySize(tp) >= 3) ? (int)StringToInteger(tp[2]) : 0;
   // Build string in broker-time format; for UTC brokers this equals the GMT time directly
   return StringToTime(StringFormat("%04d.%02d.%02d %02d:%02d:%02d",
                                    year, mon, day, h, mi, sc));
  }

//--- Parse one RSS response and place event lines for items inside [from,to]
void ParseAndDrawFromRSS(const string &rss,
                          const datetime from,
                          const datetime to,
                          const double   labelPrice)
  {
   int pos = 0;
   while(true)
     {
      int itemStart = StringFind(rss, "<item>", pos);
      if(itemStart < 0) break;
      pos = itemStart + 6;
      int itemEnd = StringFind(rss, "</item>", pos);
      if(itemEnd < 0) break;
      string block = StringSubstr(rss, pos, itemEnd - pos);
      pos = itemEnd + 7;

      int p2 = 0;
      string title   = ExtractTagValue(block, "title",   p2);
      p2 = 0;
      string pubDate = ExtractTagValue(block, "pubDate", p2);
      p2 = 0;
      string impact  = ExtractTagValue(block, "impact",  p2);

      // Filter: must mention USD (ForexFactory RSS titles: "USD - CPI m/m")
      if(StringFind(title, "USD") < 0) continue;

      // Impact filter (ForexFactory uses "High", "Medium", "Low")
      if(High_Impact_Only && StringFind(impact, "High") < 0) continue;

      datetime evTime = ParseRFC2822(pubDate);
      if(evTime == 0 || evTime < from || evTime > to) continue;

      // Unique key from time + stripped title characters
      string key    = StringFormat("%d_%d", (int)evTime, StringLen(title));
      string lnName = OBJ_PREFIX + "EVT_W_" + key + "_V";
      string lbName = OBJ_PREFIX + "EVT_W_" + key + "_T";

      // Strip "USD - " prefix for label brevity
      string display = title;
      if(StringFind(display, "USD - ") == 0)
         display = StringSubstr(display, 6);

      PlaceEventVLine(lnName, lbName, evTime, display, labelPrice);
     }
  }

//--- Fetch one ForexFactory RSS page and parse it
void FetchAndParseFF(const string url,
                     const datetime from,
                     const datetime to,
                     const double   labelPrice)
  {
   char   req[], res[];
   string respHeaders;
   // A browser-like User-Agent is needed; ForexFactory rejects bare requests
   string headers = "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/120.0.0.0 Safari/537.36\r\n"
                    "Accept: application/rss+xml, text/xml\r\n";

   int code = WebRequest("GET", url, headers, 8000, req, res, respHeaders);
   if(code != 200)
     {
      Print("SessionIndicator [WebCalendar]: HTTP ", code, " for ", url);
      return;
     }
   string rss = CharArrayToString(res, 0, WHOLE_ARRAY, CP_UTF8);
   ParseAndDrawFromRSS(rss, from, to, labelPrice);
  }

//==========================================================================
//| DrawEventLines — purple dotted verticals for upcoming USD/Gold events   |
//==========================================================================
void DrawEventLines()
  {
// ── cleanup ──────────────────────────────────────────────────────────────
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string nm = ObjectName(0, i, 0, -1);
      if(StringFind(nm, OBJ_PREFIX + "EVT_") == 0)
         ObjectDelete(0, nm);
     }

   if(!Show_Events) { ChartRedraw(0); return; }

// ── time window ──────────────────────────────────────────────────────────
   datetime utcNow = TimeGMT();
   MqlDateTime st;
   TimeToStruct(utcNow, st);
   st.hour = 0; st.min = 0; st.sec = 0;
   datetime utcFrom = StructToTime(st);
   datetime utcTo   = utcNow + (long)Event_Days_Ahead * 86400;

// ── label anchor price (3% below chart top) ───────────────────────────────
   double chartHigh  = ChartGetDouble(0, CHART_PRICE_MAX);
   double chartLow   = ChartGetDouble(0, CHART_PRICE_MIN);
   double labelPrice = chartHigh - (chartHigh - chartLow) * 0.03;

// ── source branch ────────────────────────────────────────────────────────
   if(Use_External_Calendar)
     {
      // Two RSS pages cover up to ~14 days ahead
      FetchAndParseFF("https://www.forexfactory.com/calendar.php?week=this&type=rss",
                      utcFrom, utcTo, labelPrice);
      if(Event_Days_Ahead > 4)
         FetchAndParseFF("https://www.forexfactory.com/calendar.php?week=next&type=rss",
                         utcFrom, utcTo, labelPrice);
      ChartRedraw(0);
      return;
     }

// ── MT5 built-in calendar (default) ──────────────────────────────────────
   MqlCalendarValue values[];
   if(!CalendarValueHistory(values, utcFrom, utcTo, "US"))
     { ChartRedraw(0); return; }

   int evCount = ArraySize(values);
   for(int i = 0; i < evCount; i++)
     {
      MqlCalendarEvent ev;
      if(!CalendarEventById(values[i].event_id, ev)) continue;
      if(High_Impact_Only && ev.importance != CALENDAR_IMPORTANCE_HIGH) continue;

      string evStem   = OBJ_PREFIX + "EVT_" + (string)values[i].id;
      PlaceEventVLine(evStem + "_V", evStem + "_T",
                      values[i].time, ev.name, labelPrice);
     }

   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
