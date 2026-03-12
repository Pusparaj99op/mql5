//+------------------------------------------------------------------+
//|                                  XAU_MTF_Patterns_Indicator.mq5  |
//|                                - Multi-Timeframe Pattern Indicator|
//+------------------------------------------------------------------+
#property copyright "Kalvi Trading"
#property version   "6.00"
#property description "XAUUSD multi-timeframe chart pattern indicator v6"
#property description "RSI/MACD divergence, S/D zones, pivot points, BOS/CHoCH"
#property description "ATR filters, VWAP, BB squeeze, confluence panel, alerts"
#property strict
#property indicator_chart_window
#property indicator_plots 0

//--- Enums -------------------------------------------------------+
enum ENUM_PATTERN_FAMILY
{
   PATTERN_CANDLES   = 1,  // Candlestick only
   PATTERN_STRUCTURE = 2,  // Structural only
   PATTERN_BREAKOUTS = 4,  // Breakouts only
   PATTERN_ALL       = 7   // All Patterns
};

enum ENUM_TIME_SOURCE
{
   TIME_UTC    = 0,  // UTC (TimeGMT)
   TIME_SERVER = 1   // Broker server
};

//--- Inputs -------------------------------------------------------+
input group "=== General ==="
input string              InpSymbol             = "XAUUSD";         // Symbol
input bool                InpUseAllTimeframes   = true;              // Scan all TFs
input ENUM_PATTERN_FAMILY InpPatternFamily      = PATTERN_ALL;       // Which patterns
input int                 InpMaxObjectsPerTF    = 4;                 // Max objects drawn / TF
input int                 InpPatternHistoryBars = 8;                 // Look-back bars for patterns
input bool                InpPatternsCurrentTFOnly = true;           // Draw labels on chart TF only
input int                 InpMinDrawScore       = 65;                // Min score to draw pattern label

input group "=== SMA / MA Trend Filter ==="
input int                 InpSmaFast            = 50;                // Fast MA Period
input int                 InpSmaSlow            = 200;               // Slow MA Period
input ENUM_MA_METHOD      InpMaMethod           = MODE_SMA;          // MA Method
input bool                InpShowSmaArrows      = true;              // Draw MA crossover arrows
input bool                InpShowSmaLines       = true;              // Draw MA lines on chart
input color               InpSmaBullColor       = clrLime;           // MA Bullish color
input color               InpSmaBearColor       = clrTomato;         // MA Bearish color
input color               InpSmaNeutralColor    = clrSilver;         // MA Neutral color

input group "=== Fibonacci ==="
input bool                InpUseFibonacci       = false;             // Auto Fibonacci
input int                 InpFibLookbackBars    = 100;               // Fib lookback bars
input double              InpFibTolerancePts    = 800;               // Fib tolerance (points)
input bool                InpShowFibLabels      = true;              // Show Fib level labels
input color               InpFibColor           = clrGoldenrod;      // Fib color
input color               InpFibLabelColor      = clrWheat;          // Fib label color

input group "=== ATR & Pattern Filters ==="
input int                 InpAtrPeriod          = 14;                // ATR period
input double              InpMinBodyAtr         = 0.15;              // Min candle body (x ATR)
input double              InpAtrArrowOffset     = 0.4;               // Arrow distance (x ATR)

input group "=== Pattern Colors ==="
input color               InpBullPatternColor   = clrAqua;           // Bullish candle
input color               InpBearPatternColor   = clrOrangeRed;      // Bearish candle
input color               InpStructureColor     = clrMediumPurple;   // Structure
input color               InpBreakoutColor      = clrDeepSkyBlue;    // Breakout

input group "=== Session Boxes & Time ==="
input ENUM_TIME_SOURCE    InpTimeSource         = TIME_UTC;          // Time source
input bool                InpShowTimePanel      = true;              // Show time panel
input bool                InpShowSessionBoxes   = true;              // Draw session boxes
input bool                InpShowDashboard      = true;              // MTF dashboard panel
input string              InpAsianSession       = "00:00-08:00";     // Asian (GMT)
input string              InpLondonSession      = "08:00-16:00";     // London (GMT)
input string              InpNYSession          = "13:00-21:00";     // NY (GMT)
input color               InpAsianColor         = clrDarkSlateGray;  // Asian box
input color               InpLondonColor        = C'80,20,20';       // London box
input color               InpNYColor            = C'20,30,80';       // NY box

input group "=== Lot Calculator ==="
input bool                InpShowLotCalc        = true;              // Show lot calculator
input double              InpRiskPercent        = 1.0;               // Risk % per trade
input int                 InpStopLossPips       = 50;                // Default SL (pips)

input group "=== Trendlines ==="
input bool                InpShowTrendLines     = true;              // Auto draw trendlines
input color               InpTrendResistColor   = clrOrangeRed;      // Resistance trendline color
input color               InpTrendSupportColor  = clrLimeGreen;      // Support trendline color

input group "=== Session Overlap ==="
input bool                InpShowOverlapBox     = true;              // Draw London/NY overlap box
input color               InpOverlapColor       = C'90,90,0';        // Overlap box color

input group "=== RSI Divergence ==="
input bool                InpShowRsiDiv         = true;              // Detect RSI divergence
input int                 InpRsiPeriod          = 14;                // RSI period
input int                 InpRsiOverbought      = 70;                // RSI overbought level
input int                 InpRsiOversold        = 30;                // RSI oversold level

input group "=== MACD ==="
input bool                InpShowMacd           = true;              // Show MACD on dashboard
input int                 InpMacdFast           = 12;                // MACD fast period
input int                 InpMacdSlow           = 26;                // MACD slow period
input int                 InpMacdSignal         = 9;                 // MACD signal period

input group "=== Stochastic ==="
input bool                InpShowStoch          = true;              // Show Stochastic on dashboard
input int                 InpStochK             = 5;                 // Stochastic %K period
input int                 InpStochD             = 3;                 // Stochastic %D period
input int                 InpStochSlowing       = 3;                 // Stochastic slowing
input int                 InpStochOverbought    = 80;                // Stochastic overbought
input int                 InpStochOversold      = 20;                // Stochastic oversold

input group "=== Supply & Demand Zones ==="
input bool                InpShowSDZones        = true;              // Draw Supply / Demand zones
input double              InpSdImpulseAtr       = 1.5;               // Min impulse body (x ATR)
input int                 InpSdLookback         = 60;                // S/D lookback bars
input color               InpSupplyColor        = C'120,25,25';      // Supply zone color
input color               InpDemandColor        = C'20,70,20';       // Demand zone color

input group "=== Pivot Points ==="
input bool                InpShowPivots         = true;              // Draw daily pivot levels
input color               InpPivotColor         = clrGold;           // Pivot line color
input color               InpPivotResistColor   = clrOrangeRed;      // Resistance pivot color
input color               InpPivotSupportColor  = clrLimeGreen;      // Support pivot color

input group "=== VWAP ==="
input bool                InpShowVwap           = true;              // Show daily VWAP line
input color               InpVwapColor          = clrDodgerBlue;     // VWAP line color

input group "=== Bollinger Band Squeeze ==="
input bool                InpShowBBSqueeze      = true;              // Detect BB squeeze
input int                 InpBBPeriod           = 20;                // BB period
input double              InpBBDeviation        = 2.0;               // BB deviation
input double              InpBBSqueezeThreshold = 0.5;               // Squeeze threshold (x ATR%)

input group "=== Confluence Panel ==="
input bool                InpShowConfluence     = true;              // Show confluence score panel

input group "=== Alerts ==="
input bool                InpAlertPopup         = true;              // Popup alert
input bool                InpAlertSound         = false;             // Sound alert
input bool                InpAlertPush          = false;             // Push notification
input int                 InpAlertMinScore      = 80;                // Min score to trigger alert
input int                 InpAlertCooldownSec   = 300;               // Alert cooldown (seconds)

//--- Globals ------------------------------------------------------+
string g_prefix = "XAU_MTF_";
ENUM_TIMEFRAMES g_tfs[];
int    g_fastHandles[];
int    g_slowHandles[];
int    g_atrHandles[];       // ATR handles per TF
int    g_rsiHandles[];       // RSI handles per TF
int    g_macdHandles[];      // MACD handles per TF
int    g_stochHandles[];     // Stochastic handles per TF
int    g_bbHandles[];        // Bollinger Bands handles per TF
datetime g_lastChartBar  = 0;
datetime g_lastAlertTime = 0; // last alert timestamp
datetime g_lastTfBar[];     // per-TF last bar cache
string   g_lastTfPat[];     // per-TF last detected pattern (for dashboard)

//+------------------------------------------------------------------+
//| Utility: timeframe → short text                                  |
//+------------------------------------------------------------------+
string TfToText(const ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";   case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";   case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";   case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";  case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";  case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";  case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";   case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";   case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";   case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D1";   case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
   }
   return "TF";
}

//+------------------------------------------------------------------+
//| Build source-TF list (all or current only)                       |
//+------------------------------------------------------------------+
void BuildTimeframeList()
{
   if(!InpUseAllTimeframes)
   {
      ArrayResize(g_tfs, 1);
      g_tfs[0] = (ENUM_TIMEFRAMES)_Period;
      return;
   }
   ArrayResize(g_tfs, 9);
   g_tfs[0]=PERIOD_M1;  g_tfs[1]=PERIOD_M5;  g_tfs[2]=PERIOD_M15;
   g_tfs[3]=PERIOD_M30; g_tfs[4]=PERIOD_H1;  g_tfs[5]=PERIOD_H4;
   g_tfs[6]=PERIOD_D1;  g_tfs[7]=PERIOD_W1;  g_tfs[8]=PERIOD_MN1;
}

//+------------------------------------------------------------------+
//| Delete all objects whose name begins with prefix                 |
//+------------------------------------------------------------------+
void DeleteByPrefix(const string prefix)
{
   for(int i = ObjectsTotal(0) - 1; i >= 0; --i)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+
//| Parse "HH:MM-HH:MM" → minutes-from-midnight                     |
//+------------------------------------------------------------------+
bool ParseSession(const string session, int &startMin, int &endMin)
{
   string parts[];
   if(StringSplit(session, '-', parts) != 2) return false;
   string a[], b[];
   if(StringSplit(parts[0], ':', a) != 2) return false;
   if(StringSplit(parts[1], ':', b) != 2) return false;

   int sh=(int)StringToInteger(a[0]), sm=(int)StringToInteger(a[1]);
   int eh=(int)StringToInteger(b[0]), em=(int)StringToInteger(b[1]);
   if(sh<0||sh>23||eh<0||eh>23||sm<0||sm>59||em<0||em>59) return false;

   startMin = sh*60+sm;
   endMin   = eh*60+em;
   return true;
}

bool IsWithinSession(const datetime t, const string session)
{
   MqlDateTime md; TimeToStruct(t, md);
   int nowMin = md.hour*60 + md.min;
   int sMin=0, eMin=0;
   if(!ParseSession(session, sMin, eMin)) return false;
   return (sMin<=eMin) ? (nowMin>=sMin && nowMin<eMin) : (nowMin>=sMin || nowMin<eMin);
}

datetime ActiveTime()
{
   return (InpTimeSource==TIME_SERVER) ? TimeTradeServer() : TimeGMT();
}

string SessionName(const datetime now)
{
   if(IsWithinSession(now, InpAsianSession))  return "ASIAN";
   if(IsWithinSession(now, InpLondonSession)) return "LONDON";
   if(IsWithinSession(now, InpNYSession))     return "NEW YORK";
   return "OFF-SESSION";
}

color SessionColor(const datetime now)
{
   if(IsWithinSession(now, InpAsianSession))  return InpAsianColor;
   if(IsWithinSession(now, InpLondonSession)) return InpLondonColor;
   if(IsWithinSession(now, InpNYSession))     return InpNYColor;
   return clrDimGray;
}

//+------------------------------------------------------------------+
//| SMA/MA state for a given TF index                                |
//+------------------------------------------------------------------+
bool SMAState(const int idx, double &fastVal, double &slowVal, bool &bull, bool &bear)
{
   bull = false; bear = false; fastVal = 0; slowVal = 0;
   if(idx<0 || idx>=ArraySize(g_fastHandles)) return false;
   if(g_fastHandles[idx]==INVALID_HANDLE || g_slowHandles[idx]==INVALID_HANDLE) return false;
   double fb[1], sb[1];
   if(CopyBuffer(g_fastHandles[idx],0,0,1,fb)<1) return false;
   if(CopyBuffer(g_slowHandles[idx],0,0,1,sb)<1) return false;
   fastVal = fb[0]; slowVal = sb[0];
   bull = (fb[0]>sb[0]); bear = (fb[0]<sb[0]);
   return true;
}

//+------------------------------------------------------------------+
//| ATR value for a given TF index (returns 0 on failure)            |
//+------------------------------------------------------------------+
double GetAtr(const int idx)
{
   if(idx<0 || idx>=ArraySize(g_atrHandles)) return 0.0;
   if(g_atrHandles[idx]==INVALID_HANDLE) return 0.0;
   double buf[1];
   if(CopyBuffer(g_atrHandles[idx],0,0,1,buf)<1) return 0.0;
   return buf[0];
}

//+------------------------------------------------------------------+
//| RSI value for a given TF index (returns 50 on failure)           |
//+------------------------------------------------------------------+
double GetRsi(const int idx)
{
   if(idx<0 || idx>=ArraySize(g_rsiHandles)) return 50.0;
   if(g_rsiHandles[idx]==INVALID_HANDLE) return 50.0;
   double buf[1];
   if(CopyBuffer(g_rsiHandles[idx],0,0,1,buf)<1) return 50.0;
   return buf[0];
}

//+------------------------------------------------------------------+
//| MACD values for a given TF index                                 |//+------------------------------------------------------------------+
void GetMacd(const int idx, double &main, double &signal)
{
   main = 0; signal = 0;
   if(!InpShowMacd) return;
   if(idx<0 || idx>=ArraySize(g_macdHandles)) return;
   if(g_macdHandles[idx]==INVALID_HANDLE) return;
   double mb[1], sb[1];
   if(CopyBuffer(g_macdHandles[idx],0,0,1,mb)<1) return;
   if(CopyBuffer(g_macdHandles[idx],1,0,1,sb)<1) return;
   main = mb[0]; signal = sb[0];
}

//+------------------------------------------------------------------+
//| Stochastic %K for a given TF index (returns 50 on failure)       |
//+------------------------------------------------------------------+
double GetStoch(const int idx)
{
   if(!InpShowStoch) return 50.0;
   if(idx<0 || idx>=ArraySize(g_stochHandles)) return 50.0;
   if(g_stochHandles[idx]==INVALID_HANDLE) return 50.0;
   double buf[1];
   if(CopyBuffer(g_stochHandles[idx],0,0,1,buf)<1) return 50.0;
   return buf[0];
}

//+------------------------------------------------------------------+
//| Check whether a TF bar has advanced since last scan              |
//+------------------------------------------------------------------+
bool TfBarChanged(const int idx)
{
   if(idx<0 || idx>=ArraySize(g_lastTfBar)) return true;
   datetime t = iTime(InpSymbol, g_tfs[idx], 0);
   if(t != g_lastTfBar[idx])
   {
      g_lastTfBar[idx] = t;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| SECTION: Session Overlap Box (London + NY)                       |
//+------------------------------------------------------------------+
void DrawSessionOverlapBox()
{
   if(!InpShowOverlapBox) return;

   for(int day = 0; day < 2; day++)
   {
      datetime dayStart = StringToTime(TimeToString(ActiveTime() - day*86400, TIME_DATE));

      int lsMin=0, leMin=0, nsMin=0, neMin=0;
      if(!ParseSession(InpLondonSession, lsMin, leMin)) continue;
      if(!ParseSession(InpNYSession, nsMin, neMin))     continue;

      // Overlap = intersection of both sessions
      int ovStart = MathMax(lsMin, nsMin);
      int ovEnd   = MathMin(leMin, neMin);
      if(ovStart >= ovEnd) continue;

      datetime t1 = dayStart + ovStart * 60;
      datetime t2 = dayStart + ovEnd   * 60;
      if(t1 > ActiveTime() + 3600) continue;

      // Price range from M1 data
      int bS = iBarShift(InpSymbol, PERIOD_M1, t1, false);
      int bE = iBarShift(InpSymbol, PERIOD_M1, t2, false);
      if(bS < 0 || bE < 0) continue;
      if(bS < bE) { int tmp=bS; bS=bE; bE=tmp; }

      int hIdx = iHighest(InpSymbol, PERIOD_M1, MODE_HIGH, bS-bE+1, bE);
      int lIdx = iLowest (InpSymbol, PERIOD_M1, MODE_LOW,  bS-bE+1, bE);
      if(hIdx < 0 || lIdx < 0) continue;

      double hi = iHigh(InpSymbol, PERIOD_M1, hIdx);
      double lo = iLow (InpSymbol, PERIOD_M1, lIdx);
      if(hi <= lo) continue;

      string name = g_prefix + "SES_OVL_" + (string)day;
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, hi, t2, lo);
      else
      {
         ObjectMove(0, name, 0, t1, hi);
         ObjectMove(0, name, 1, t2, lo);
      }
      ObjectSetInteger(0, name, OBJPROP_COLOR,      InpOverlapColor);
      ObjectSetInteger(0, name, OBJPROP_FILL,       true);
      ObjectSetInteger(0, name, OBJPROP_BACK,       true);
      ObjectSetInteger(0, name, OBJPROP_STYLE,      STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

      // Label
      string lblName = g_prefix + "SESLBL_OVL_" + (string)day;
      if(ObjectFind(0, lblName) < 0)
         ObjectCreate(0, lblName, OBJ_TEXT, 0, t1, hi);
      else
         ObjectMove(0, lblName, 0, t1, hi);
      ObjectSetString (0, lblName, OBJPROP_TEXT,     " LDN/NY");
      ObjectSetInteger(0, lblName, OBJPROP_COLOR,    InpOverlapColor);
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, lblName, OBJPROP_ANCHOR,   ANCHOR_LEFT_LOWER);
   }
}

//+------------------------------------------------------------------+
//| SECTION: RSI Divergence Detection                                |
//+------------------------------------------------------------------+
int DetectRsiDivergence(const int idx, const ENUM_TIMEFRAMES tf,
                        string &patterns[], bool &directions[],
                        datetime &times[],  double &prices[],
                        const int maxResults)
{
   if(!InpShowRsiDiv) return 0;
   if(idx < 0 || idx >= ArraySize(g_rsiHandles)) return 0;
   if(g_rsiHandles[idx] == INVALID_HANDLE) return 0;

   int lb = MathMax(InpPatternHistoryBars, 20);
   double rsiArr[];
   MqlRates rr[];
   if(CopyBuffer(g_rsiHandles[idx], 0, 1, lb, rsiArr) < lb) return 0;
   if(CopyRates(InpSymbol, tf, 1, lb, rr) < lb) return 0;

   int mid   = lb / 2;
   int count = 0;

   // CopyRates with shift=1 returns rr[0]=oldest .. rr[lb-1]=newest
   // "older" half = 0..mid-1, "recent" half = mid..lb-1

   // --- Bullish divergence: price makes lower low (recent), RSI makes higher low ---
   int oLowBar = 0;   double oLow = DBL_MAX;
   int rLowBar = mid;  double rLow = DBL_MAX;
   for(int i = 0; i < mid;  i++) if(rr[i].low < oLow) { oLow = rr[i].low; oLowBar = i; }
   for(int i = mid; i < lb; i++) if(rr[i].low < rLow) { rLow = rr[i].low; rLowBar = i; }

   if(rLow < oLow && rsiArr[rLowBar] > rsiArr[oLowBar] + 3.0 &&
      rsiArr[rLowBar] < (double)(InpRsiOversold + 25))
   {
      ArrayResize(patterns,   count+1); ArrayResize(directions, count+1);
      ArrayResize(times,      count+1); ArrayResize(prices,     count+1);
      patterns[count]   = "RSI Bull Div";
      directions[count] = true;
      times[count]      = rr[rLowBar].time;
      prices[count]     = rLow;
      count++;
   }

   // --- Bearish divergence: price makes higher high (recent), RSI makes lower high ---
   if(count < maxResults)
   {
      int oHighBar = 0;   double oHigh = -DBL_MAX;
      int rHighBar = mid;  double rHigh = -DBL_MAX;
      for(int i = 0; i < mid;  i++) if(rr[i].high > oHigh) { oHigh = rr[i].high; oHighBar = i; }
      for(int i = mid; i < lb; i++) if(rr[i].high > rHigh) { rHigh = rr[i].high; rHighBar = i; }

      if(rHigh > oHigh && rsiArr[rHighBar] < rsiArr[oHighBar] - 3.0 &&
         rsiArr[rHighBar] > (double)(InpRsiOverbought - 25))
      {
         ArrayResize(patterns,   count+1); ArrayResize(directions, count+1);
         ArrayResize(times,      count+1); ArrayResize(prices,     count+1);
         patterns[count]   = "RSI Bear Div";
         directions[count] = false;
         times[count]      = rr[rHighBar].time;
         prices[count]     = rHigh;
         count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| SECTION: Session Boxes                                           |
//+------------------------------------------------------------------+
void DrawSessionBoxes()
{
   if(!InpShowSessionBoxes) return;

   // Only draw for today and yesterday (2 days) to avoid clutter
   for(int day=0; day<2; day++)
   {
      datetime dayStart = StringToTime(TimeToString(ActiveTime() - day*86400, TIME_DATE));
      DrawOneSessionBox(dayStart, InpAsianSession,  InpAsianColor,  "ASIAN_" + (string)day);
      DrawOneSessionBox(dayStart, InpLondonSession, InpLondonColor, "LONDON_"+ (string)day);
      DrawOneSessionBox(dayStart, InpNYSession,     InpNYColor,     "NY_"    + (string)day);
   }
   DrawSessionOverlapBox();
}

void DrawOneSessionBox(const datetime dayStart, const string session, const color clr, const string tag)
{
   int sMin=0, eMin=0;
   if(!ParseSession(session, sMin, eMin)) return;

   datetime t1 = dayStart + sMin*60;
   datetime t2 = dayStart + eMin*60;
   if(eMin <= sMin) t2 += 86400; // wraps midnight

   // Skip future boxes that haven't yet started
   if(t1 > ActiveTime() + 3600) return;

   // Find price range within the session
   int barStart = iBarShift(InpSymbol, PERIOD_M1, t1, false);
   int barEnd   = iBarShift(InpSymbol, PERIOD_M1, t2, false);
   if(barStart < 0 || barEnd < 0) return;
   if(barStart < barEnd) { int tmp=barStart; barStart=barEnd; barEnd=tmp; }

   int hIdx = iHighest(InpSymbol, PERIOD_M1, MODE_HIGH, barStart-barEnd+1, barEnd);
   int lIdx = iLowest (InpSymbol, PERIOD_M1, MODE_LOW,  barStart-barEnd+1, barEnd);
   if(hIdx<0 || lIdx<0) return;

   double hi = iHigh(InpSymbol, PERIOD_M1, hIdx);
   double lo = iLow (InpSymbol, PERIOD_M1, lIdx);
   if(hi <= lo) return;

   string name = g_prefix + "SES_" + tag;

   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, hi, t2, lo);
   else
   {
      ObjectMove(0, name, 0, t1, hi);
      ObjectMove(0, name, 1, t2, lo);
   }

   ObjectSetInteger(0, name, OBJPROP_COLOR,  clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,  STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,  1);
   ObjectSetInteger(0, name, OBJPROP_FILL,   true);
   ObjectSetInteger(0, name, OBJPROP_BACK,   true);

   // Session label at top-left corner
   string lblName = g_prefix + "SESLBL_" + tag;
   if(ObjectFind(0, lblName) < 0)
      ObjectCreate(0, lblName, OBJ_TEXT, 0, t1, hi);
   else
      ObjectMove(0, lblName, 0, t1, hi);

   // Extract session display name from tag
   string dispName = tag;
   int underscorePos = StringFind(tag, "_");
   if(underscorePos > 0)
      dispName = StringSubstr(tag, 0, underscorePos);

   ObjectSetString (0, lblName, OBJPROP_TEXT, " " + dispName);
   ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
}

//+------------------------------------------------------------------+
//| SECTION: Time + Session Info Panel (top-left)                    |
//+------------------------------------------------------------------+
void DrawTimePanel()
{
   if(!InpShowTimePanel) return;
   datetime utc = TimeGMT();
   datetime srv = TimeTradeServer();
   datetime active = ActiveTime();

   string bg  = g_prefix + "TIME_BG";
   string txt = g_prefix + "TIME_TXT";
   string sesLbl = g_prefix + "TIME_SES";

   // Background
   if(ObjectFind(0, bg) < 0)
   {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, 10);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE, 310);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE, 70);
      ObjectSetInteger(0, bg, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   }
   ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, SessionColor(active));

   // Time text
   if(ObjectFind(0, txt) < 0)
   {
      ObjectCreate(0, txt, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, txt, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, txt, OBJPROP_XDISTANCE, 18);
      ObjectSetInteger(0, txt, OBJPROP_YDISTANCE, 18);
      ObjectSetInteger(0, txt, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, txt, OBJPROP_FONTSIZE, 9);
   }
   string l1 = StringFormat("UTC %s  |  SRV %s",
                TimeToString(utc, TIME_MINUTES),
                TimeToString(srv, TIME_MINUTES));
   ObjectSetString(0, txt, OBJPROP_TEXT, l1);

   // Session name
   if(ObjectFind(0, sesLbl) < 0)
   {
      ObjectCreate(0, sesLbl, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, sesLbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, sesLbl, OBJPROP_XDISTANCE, 18);
      ObjectSetInteger(0, sesLbl, OBJPROP_YDISTANCE, 38);
      ObjectSetInteger(0, sesLbl, OBJPROP_FONTSIZE, 11);
   }
   string sesName = SessionName(active);
   ObjectSetString (0, sesLbl, OBJPROP_TEXT, sesName + " session");
   ObjectSetInteger(0, sesLbl, OBJPROP_COLOR, clrYellow);
}

//+------------------------------------------------------------------+
//| SECTION: MTF Dashboard (top-right)                               |
//+------------------------------------------------------------------+
void DrawDashboard()
{
   if(!InpShowDashboard) return;

   int rows = ArraySize(g_tfs);
   int rowH = 16;
   int panelW = 420;
   int panelH = 28 + rows * rowH;

   string bg = g_prefix + "DASH_BG";
   if(ObjectFind(0, bg) < 0)
   {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER,      CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE,   10);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE,   10);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE,       panelW);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR,     C'15,15,25');
      ObjectSetInteger(0, bg, OBJPROP_COLOR,       clrGold);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   }
   // Always keep panel height in sync with row count
   ObjectSetInteger(0, bg, OBJPROP_YSIZE, panelH);

   // Title
   string ttl = g_prefix + "DASH_TTL";
   if(ObjectFind(0, ttl) < 0)
   {
      ObjectCreate(0, ttl, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, ttl, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, ttl, OBJPROP_XDISTANCE, panelW - 8);
      ObjectSetInteger(0, ttl, OBJPROP_YDISTANCE, 14);
      ObjectSetInteger(0, ttl, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, ttl, OBJPROP_COLOR, clrGold);
   }
   ObjectSetString(0, ttl, OBJPROP_TEXT, "XAU MTF Dashboard v6");

   // Rows
   datetime now = ActiveTime();
   for(int i=0; i<rows; i++)
   {
      string rowName = g_prefix + "DASH_R" + (string)i;
      if(ObjectFind(0, rowName) < 0)
      {
         ObjectCreate(0, rowName, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, rowName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
         ObjectSetInteger(0, rowName, OBJPROP_XDISTANCE, panelW - 8);
         ObjectSetInteger(0, rowName, OBJPROP_YDISTANCE, 30 + i*rowH);
         ObjectSetInteger(0, rowName, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, rowName, OBJPROP_SELECTABLE, false);
      }

      double fv=0, sv=0;
      bool bull=false, bear=false;
      SMAState(i, fv, sv, bull, bear);

      string trend = bull ? "^BULL" : (bear ? "vBEAR" : "-FLAT");
      color  tClr  = bull ? InpSmaBullColor : (bear ? InpSmaBearColor : InpSmaNeutralColor);

      // Fib confluence
      double lastClose = iClose(InpSymbol, g_tfs[i], 0);
      bool fibZone = NearFib(g_tfs[i], lastClose);

      // ATR value
      double atr = GetAtr(i);
      string atrStr = (atr > 0) ? StringFormat(" ATR:%.0f", atr/_Point) : "";

      // RSI value with OB/OS tag
      double rsi = GetRsi(i);
      string rsiTag = (rsi >= InpRsiOverbought) ? " RSI:OB" :
                      (rsi <= InpRsiOversold)   ? " RSI:OS" :
                      StringFormat(" RSI:%.0f", rsi);

      // MACD direction tag
      double macdMain=0, macdSig=0;
      GetMacd(i, macdMain, macdSig);
      string macdTag = InpShowMacd ?
                        (macdMain > macdSig ? " M+" : " M-") : "";

      // Stochastic tag
      double stochK = GetStoch(i);
      string stochTag = InpShowStoch ?
                         ((stochK >= InpStochOverbought) ? " ST:OB" :
                          (stochK <= InpStochOversold)   ? " ST:OS" :
                          StringFormat(" ST:%.0f", stochK)) : "";

      // Row color: RSI extreme overrides trend color
      color rowClr = (rsi >= InpRsiOverbought) ? InpSmaBearColor :
                     (rsi <= InpRsiOversold)   ? InpSmaBullColor : tClr;

      // Last detected pattern (stored per TF in RenderPatterns)
      string patStr = "";
      if(i < ArraySize(g_lastTfPat) && g_lastTfPat[i] != "")
         patStr = " | " + g_lastTfPat[i];

       // BB squeeze tag
      string bbTag = GetBBSqueeze(i) ? " BB:SQ" : "";

      string row = StringFormat("%s %s%s%s%s%s%s%s%s",
                     TfToText(g_tfs[i]),
                     trend,
                     fibZone ? " FIB" : "",
                     atrStr,
                     rsiTag,
                     macdTag,
                     stochTag,
                     bbTag,
                     patStr);

      ObjectSetString (0, rowName, OBJPROP_TEXT, row);
      ObjectSetInteger(0, rowName, OBJPROP_COLOR, rowClr);
   }
}

//+------------------------------------------------------------------+
//| SECTION: SMA Trend Arrows on chart                               |
//+------------------------------------------------------------------+
void DrawSmaArrows()
{
   if(!InpShowSmaArrows) return;

   // Draw arrows for current chart TF only (to avoid clutter)
   ENUM_TIMEFRAMES chartTF = (ENUM_TIMEFRAMES)_Period;

   // Find index of chart TF in our list
   int idx = -1;
   for(int i=0; i<ArraySize(g_tfs); i++)
      if(g_tfs[i] == chartTF) { idx = i; break; }
   if(idx < 0) return;

   // Check last 5 bars for SMA cross
   for(int bar = 1; bar <= 5; bar++)
   {
      double fb[2], sb[2];
      if(CopyBuffer(g_fastHandles[idx], 0, bar, 2, fb) < 2) continue;
      if(CopyBuffer(g_slowHandles[idx], 0, bar, 2, sb) < 2) continue;

      bool crossUp   = (fb[0] <= sb[0] && fb[1] > sb[1]);
      bool crossDown = (fb[0] >= sb[0] && fb[1] < sb[1]);

      if(!crossUp && !crossDown) continue;

      datetime t = iTime(InpSymbol, chartTF, bar);
      string name = g_prefix + "SMA_ARR_" + (string)t;
      if(ObjectFind(0, name) >= 0) continue;

      double price = crossUp ? iLow(InpSymbol, chartTF, bar) : iHigh(InpSymbol, chartTF, bar);
      int code = crossUp ? 233 : 234;    // Wingdings: up / down arrow
      color clr = crossUp ? InpSmaBullColor : InpSmaBearColor;
      ENUM_OBJECT arrowType = crossUp ? OBJ_ARROW_UP : OBJ_ARROW_DOWN;

      ObjectCreate(0, name, arrowType, 0, t, price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, crossUp ? ANCHOR_TOP : ANCHOR_BOTTOM);
   }
}

//+------------------------------------------------------------------+
//| SECTION: Fibonacci drawing with labeled levels                   |
//+------------------------------------------------------------------+
bool NearFib(const ENUM_TIMEFRAMES tf, const double price)
{
   if(!InpUseFibonacci) return false;
   int hIdx = iHighest(InpSymbol, tf, MODE_HIGH, InpFibLookbackBars, 1);
   int lIdx = iLowest (InpSymbol, tf, MODE_LOW,  InpFibLookbackBars, 1);
   if(hIdx<0 || lIdx<0) return false;
   double hi = iHigh(InpSymbol, tf, hIdx);
   double lo = iLow (InpSymbol, tf, lIdx);
   if(hi<=lo) return false;

   double fibPcts[] = {0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0, 1.272, 1.618, 2.618};
   double tol = InpFibTolerancePts * _Point;
   for(int i=0; i<ArraySize(fibPcts); i++)
   {
      double level = hi - (hi - lo) * fibPcts[i];
      if(MathAbs(price - level) <= tol)
         return true;
   }
   return false;
}

void DrawFibForTF(const ENUM_TIMEFRAMES tf)
{
   if(!InpUseFibonacci) return;

   int hIdx = iHighest(InpSymbol, tf, MODE_HIGH, InpFibLookbackBars, 1);
   int lIdx = iLowest (InpSymbol, tf, MODE_LOW,  InpFibLookbackBars, 1);
   if(hIdx<0 || lIdx<0) return;

   datetime tHi = iTime(InpSymbol, tf, hIdx);
   datetime tLo = iTime(InpSymbol, tf, lIdx);
   double   pHi = iHigh(InpSymbol, tf, hIdx);
   double   pLo = iLow (InpSymbol, tf, lIdx);
   if(tHi<=0 || tLo<=0 || pHi<=pLo) return;

   // Draw OBJ_FIBO reticle
   string name = g_prefix + "FIB_" + TfToText(tf);
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_FIBO, 0, tHi, pHi, tLo, pLo);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
   }
   else
   {
      ObjectMove(0, name, 0, tHi, pHi);
      ObjectMove(0, name, 1, tLo, pLo);
   }
   ObjectSetInteger(0, name, OBJPROP_COLOR, InpFibColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);

   // Draw price labels beside each level (only for chart TF or D1)
   if(!InpShowFibLabels) return;
   if(tf != (ENUM_TIMEFRAMES)_Period && tf != PERIOD_D1) return;

   double fibPcts[] = {0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0, 1.272, 1.618, 2.618};
   string fibNames[]= {"0%","23.6%","38.2%","50%","61.8%","78.6%","100%","127.2%","161.8%","261.8%"};
   datetime tLabel  = (tHi > tLo) ? tHi : tLo;

   for(int i=0; i<ArraySize(fibPcts); i++)
   {
      double level = pHi - (pHi - pLo) * fibPcts[i];
      string lbl = g_prefix + "FIBLBL_" + TfToText(tf) + "_" + (string)i;

      // Horizontal line for the level
      string hLine = g_prefix + "FIBLN_" + TfToText(tf) + "_" + (string)i;
      if(ObjectFind(0, hLine) < 0)
         ObjectCreate(0, hLine, OBJ_HLINE, 0, 0, level);
      else
         ObjectSetDouble(0, hLine, OBJPROP_PRICE, level);

      ObjectSetInteger(0, hLine, OBJPROP_COLOR, InpFibColor);
      ObjectSetInteger(0, hLine, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, hLine, OBJPROP_BACK, true);
      ObjectSetInteger(0, hLine, OBJPROP_WIDTH, 1);

      // Price label
      if(ObjectFind(0, lbl) < 0)
         ObjectCreate(0, lbl, OBJ_TEXT, 0, tLabel, level);
      else
         ObjectMove(0, lbl, 0, tLabel, level);

      string txt = StringFormat(" %s  %.2f", fibNames[i], level);
      ObjectSetString (0, lbl, OBJPROP_TEXT, txt);
      ObjectSetInteger(0, lbl, OBJPROP_COLOR, InpFibLabelColor);
      ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 7);
      ObjectSetInteger(0, lbl, OBJPROP_ANCHOR, ANCHOR_LEFT);
   }
}

//+------------------------------------------------------------------+
//| SECTION: Pattern Drawing helpers                                 |
//+------------------------------------------------------------------+
void DrawPatternLabel(const string name, const datetime t, const double price,
                      const string text, const color clr, const bool isBull,
                      const double atrVal = 0.0, const int score = 50)
{
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);

   // Score-driven font size: low=8, mid=10, high=12
   int fsize = (score >= 90) ? 12 : (score >= 70) ? 10 : 8;

   ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   ObjectSetString (0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fsize);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, isBull ? ANCHOR_UPPER : ANCHOR_LOWER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   // Arrow offset: ATR-based if available, else 300 points
   string arrName = name + "_arr";
   if(ObjectFind(0, arrName) >= 0) ObjectDelete(0, arrName);

   double offset = (atrVal > 0) ? atrVal * InpAtrArrowOffset : 300.0 * _Point;
   ENUM_OBJECT aType = isBull ? OBJ_ARROW_UP : OBJ_ARROW_DOWN;
   double aPrice = isBull ? price - offset : price + offset;

   ObjectCreate(0, arrName, aType, 0, t, aPrice);
   ObjectSetInteger(0, arrName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, arrName, OBJPROP_WIDTH, (score >= 80) ? 3 : 2);
   ObjectSetInteger(0, arrName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, arrName, OBJPROP_HIDDEN, true);
}

void DrawStructureZone(const string name, const datetime t1, const datetime t2,
                       const double priceHi, const double priceLo, const color clr)
{
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);

   ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, priceHi, t2, priceLo);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| SECTION: Candlestick Pattern Detection (expanded)                |
//+------------------------------------------------------------------+
int DetectAllCandles(const ENUM_TIMEFRAMES tf, string &patterns[], bool &directions[],
                     datetime &times[], double &prices[],
                     const int maxResults, const double atrVal)
{
   MqlRates r[];
   int copied = CopyRates(InpSymbol, tf, 1, InpPatternHistoryBars, r);
   if(copied < 4) return 0;

   // Minimum body size to suppress noise (ATR fraction; skip if ATR unavailable)
   double minBody = (atrVal > 0 && InpMinBodyAtr > 0) ? atrVal * InpMinBodyAtr : 0.0;

   int count = 0;
   for(int i = 0; i < copied - 3 && count < maxResults; i++)
   {
      MqlRates c0 = r[i];     // most recent in window
      MqlRates c1 = r[i+1];   // previous
      MqlRates c2 = r[i+2];

      double body0 = MathAbs(c0.close - c0.open);
      double body1 = MathAbs(c1.close - c1.open);
      double range0 = c0.high - c0.low;
      if(range0 <= 0) continue;

      double upWick0  = c0.high - MathMax(c0.close, c0.open);
      double dnWick0  = MathMin(c0.close, c0.open) - c0.low;
      bool   green0   = (c0.close > c0.open);
      bool   red0     = (c0.close < c0.open);
      bool   green1   = (c1.close > c1.open);
      bool   red1     = (c1.close < c1.open);

      string pat  = "";
      bool   bull = false;

      // --- ATR body filter: skip tiny candles (noise) ---
      if(minBody > 0 && body0 < minBody && body1 < minBody)
         continue;

      // --- Bullish Engulfing ---
      if(red1 && green0 && body0 > body1 && c0.close > c1.open && c0.open < c1.close)
      { pat = "Bull Engulf"; bull = true; }

      // --- Bearish Engulfing ---
      else if(green1 && red0 && body0 > body1 && c0.open > c1.close && c0.close < c1.open)
      { pat = "Bear Engulf"; bull = false; }

      // --- Tweezer Bottom (bullish reversal) ---
      else if(red1 && green0 && MathAbs(c0.low - c1.low) <= range0 * 0.05 && body0 >= minBody)
      { pat = "Tweezer Bot"; bull = true; }

      // --- Tweezer Top (bearish reversal) ---
      else if(green1 && red0 && MathAbs(c0.high - c1.high) <= range0 * 0.05 && body0 >= minBody)
      { pat = "Tweezer Top"; bull = false; }

      // --- Bullish Pin Bar / Hammer ---
      else if(body0 >= minBody && dnWick0 >= body0 * 2.0 && upWick0 <= body0 * 0.5)
      { pat = "Hammer"; bull = true; }

      // --- Bearish Pin Bar / Shooting Star ---
      else if(body0 >= minBody && upWick0 >= body0 * 2.0 && dnWick0 <= body0 * 0.5)
      { pat = "Shooting Star"; bull = false; }

      // --- Doji (only if range is meaningful) ---
      else if(range0 >= minBody && body0 <= range0 * 0.08)
      { pat = "Doji"; bull = (c0.close >= (c0.high+c0.low)*0.5); }

      // --- 3-bar patterns ---
      else if(i+2 < copied)
      {
         double body2 = MathAbs(c2.close - c2.open);
         bool   red2  = (c2.close < c2.open);
         bool   green2= (c2.close > c2.open);

         // Morning Star: big red, small body, big green
         if(pat=="" && red2 && body2>=minBody && body1 <= body2*0.3 && green0 && body0>=body2*0.5)
         { pat = "Morning Star"; bull = true; }

         // Evening Star: big green, small body, big red
         else if(pat=="" && green2 && body2>=minBody && body1<=body2*0.3 && red0 && body0>=body2*0.5)
         { pat = "Evening Star"; bull = false; }

         // Three White Soldiers
         bool s3w = green0 && green1 && green2 &&
                    c0.close > c1.close && c1.close > c2.close &&
                    c0.open > c1.open   && c1.open > c2.open &&
                    body0>=minBody && body1>=minBody && body2>=minBody;
         if(pat=="" && s3w) { pat = "3 Soldiers"; bull = true; }

         // Three Black Crows
         bool s3c = red0 && red1 && red2 &&
                    c0.close < c1.close && c1.close < c2.close &&
                    c0.open < c1.open   && c1.open < c2.open &&
                    body0>=minBody && body1>=minBody && body2>=minBody;
         if(pat=="" && s3c) { pat = "3 Crows"; bull = false; }
      }

      // --- Inside Bar ---
      if(pat == "" && c0.high <= c1.high && c0.low >= c1.low)
      { pat = "Inside Bar"; bull = green0; }

      if(pat == "")
         continue;

      // Store result
      ArrayResize(patterns,   count+1);
      ArrayResize(directions, count+1);
      ArrayResize(times,      count+1);
      ArrayResize(prices,     count+1);
      patterns[count]   = pat;
      directions[count] = bull;
      times[count]      = c0.time;
      prices[count]     = bull ? c0.low : c0.high;
      count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| SECTION: Daily Pivot Points                                      |
//+------------------------------------------------------------------+
void DrawPivotPoints()
{
   if(!InpShowPivots) return;

   MqlRates daily[];
   if(CopyRates(InpSymbol, PERIOD_D1, 1, 1, daily) < 1) return;

   double pH = daily[0].high;
   double pL = daily[0].low;
   double pC = daily[0].close;
   double PP = (pH + pL + pC) / 3.0;
   double R1 = 2*PP - pL;
   double S1 = 2*PP - pH;
   double R2 = PP + (pH - pL);
   double S2 = PP - (pH - pL);
   double R3 = pH + 2*(PP - pL);
   double S3 = pL - 2*(pH - PP);

   string labels[] = {"PP",  "R1",  "R2",  "R3",  "S1",  "S2",  "S3"};
   double levels[] = { PP,    R1,    R2,    R3,    S1,    S2,    S3 };
   color  colors[] = { InpPivotColor,
                        InpPivotResistColor,  InpPivotResistColor,  InpPivotResistColor,
                        InpPivotSupportColor, InpPivotSupportColor, InpPivotSupportColor };

   datetime tLabel = iTime(InpSymbol, PERIOD_CURRENT, 0);
   for(int i=0; i<7; i++)
   {
      string name = g_prefix + "PIV_" + labels[i];
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, levels[i]);
      else
         ObjectSetDouble(0, name, OBJPROP_PRICE, levels[i]);

      ObjectSetInteger(0, name, OBJPROP_COLOR,      colors[i]);
      ObjectSetInteger(0, name, OBJPROP_STYLE,      (labels[i]=="PP") ? STYLE_SOLID : STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH,      (labels[i]=="PP") ? 2 : 1);
      ObjectSetInteger(0, name, OBJPROP_BACK,       true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

      string lbl = g_prefix + "PIVLBL_" + labels[i];
      if(ObjectFind(0, lbl) < 0)
         ObjectCreate(0, lbl, OBJ_TEXT, 0, tLabel, levels[i]);
      else
         ObjectMove(0, lbl, 0, tLabel, levels[i]);

      ObjectSetString (0, lbl, OBJPROP_TEXT,       StringFormat(" %s: %.2f", labels[i], levels[i]));
      ObjectSetInteger(0, lbl, OBJPROP_COLOR,      colors[i]);
      ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE,   7);
      ObjectSetInteger(0, lbl, OBJPROP_ANCHOR,     ANCHOR_LEFT);
      ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| SECTION: Supply & Demand Zone Detection                          |
//+------------------------------------------------------------------+
void DrawSupplyDemandZones()
{
   if(!InpShowSDZones) return;

   // Use chart TF for S/D zones
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)_Period;

   double atr = 0;
   for(int k=0; k<ArraySize(g_tfs); k++)
      if(g_tfs[k]==tf) { atr = GetAtr(k); break; }
   if(atr <= 0) return;

   MqlRates r[];
   int copied = CopyRates(InpSymbol, tf, 1, InpSdLookback, r);
   if(copied < 5) return;

   double minBody = atr * InpSdImpulseAtr;
   int sdCount = 0;

   // Delete stale S/D objects before redrawing
   DeleteByPrefix(g_prefix + "SD_");

   for(int i=1; i<copied-1 && sdCount<10; i++)
   {
      double body = MathAbs(r[i].close - r[i].open);
      if(body < minBody) continue;

      bool impulseBull = (r[i].close > r[i].open);

      // The base candle before the impulse should be small
      double prevBody = MathAbs(r[i+1].close - r[i+1].open);
      if(prevBody > atr * 0.5) continue;

      // Zone boundaries from the base candle and impulse open
      double zHi = MathMax(r[i+1].high, r[i].open);
      double zLo = MathMin(r[i+1].low,  r[i].open);
      if(zHi <= zLo) continue;

      string tag  = impulseBull ? "DEM" : "SUP";
      color  clr  = impulseBull ? InpDemandColor : InpSupplyColor;
      string name = g_prefix + "SD_" + tag + "_" + (string)sdCount;

      datetime t1 = r[i+1].time;
      datetime t2 = iTime(InpSymbol, tf, 0) + PeriodSeconds(tf) * 4;

      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, zHi, t2, zLo);
      ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
      ObjectSetInteger(0, name, OBJPROP_FILL,       true);
      ObjectSetInteger(0, name, OBJPROP_BACK,       true);
      ObjectSetInteger(0, name, OBJPROP_STYLE,      STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

      // Label
      string lbl = g_prefix + "SDLBL_" + tag + "_" + (string)sdCount;
      ObjectCreate(0, lbl, OBJ_TEXT, 0, t1, impulseBull ? zHi : zLo);
      ObjectSetString (0, lbl, OBJPROP_TEXT,       " " + (impulseBull ? "Demand" : "Supply"));
      ObjectSetInteger(0, lbl, OBJPROP_COLOR,      clr);
      ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE,   7);
      ObjectSetInteger(0, lbl, OBJPROP_ANCHOR,     impulseBull ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);

      sdCount++;
   }
}

//+------------------------------------------------------------------+
//| SECTION: Lot Calculator Panel (bottom-left)                      |
//+------------------------------------------------------------------+
void DrawLotCalcPanel()
{
   if(!InpShowLotCalc) return;

   string bg   = g_prefix + "CALC_BG";
   string txt1 = g_prefix + "CALC_TXT1";
   string txt2 = g_prefix + "CALC_TXT2";
   string hdr  = g_prefix + "CALC_HDR";

   if(ObjectFind(0, bg) < 0)
   {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, 10);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE, 260);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE, 68);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'15,15,25');
      ObjectSetInteger(0, bg, OBJPROP_COLOR, clrGold);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
   }
   if(ObjectFind(0, hdr) < 0)
   {
      ObjectCreate(0, hdr, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, hdr, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, hdr, OBJPROP_XDISTANCE, 18);
      ObjectSetInteger(0, hdr, OBJPROP_YDISTANCE, 62);
      ObjectSetInteger(0, hdr, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, hdr, OBJPROP_COLOR, clrGold);
      ObjectSetString (0, hdr, OBJPROP_TEXT, "Lot Calculator");
      ObjectSetInteger(0, hdr, OBJPROP_SELECTABLE, false);
   }
   // Line 1: Risk info
   if(ObjectFind(0, txt1) < 0)
   {
      ObjectCreate(0, txt1, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, txt1, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, txt1, OBJPROP_XDISTANCE, 18);
      ObjectSetInteger(0, txt1, OBJPROP_YDISTANCE, 44);
      ObjectSetInteger(0, txt1, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, txt1, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, txt1, OBJPROP_SELECTABLE, false);
   }
   // Line 2: Lot size
   if(ObjectFind(0, txt2) < 0)
   {
      ObjectCreate(0, txt2, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, txt2, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, txt2, OBJPROP_XDISTANCE, 18);
      ObjectSetInteger(0, txt2, OBJPROP_YDISTANCE, 26);
      ObjectSetInteger(0, txt2, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, txt2, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, txt2, OBJPROP_SELECTABLE, false);
   }

   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmt   = balance * (InpRiskPercent / 100.0);
   double tickVal   = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_VALUE);
   double pt        = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
   double tickSz    = SymbolInfoDouble(InpSymbol, SYMBOL_TRADE_TICK_SIZE);
   double lotSz     = 0.0;
   if(tickSz > 0)
   {
      double slPts     = InpStopLossPips * 10.0;
      double valPerLot = (slPts * pt / tickSz) * tickVal;
      if(valPerLot > 0) lotSz = NormalizeDouble(riskAmt / valPerLot, 2);
   }
   ObjectSetString(0, txt1, OBJPROP_TEXT, StringFormat("Risk: $%.2f  SL: %d pips", riskAmt, InpStopLossPips));
   ObjectSetString(0, txt2, OBJPROP_TEXT, StringFormat("Rec Lot: %.2f", lotSz));
}

//+------------------------------------------------------------------+
//| SECTION: Structural Pattern Detection (swing-based)              |
//+------------------------------------------------------------------+
struct SwingPoint
{
   int      barIndex;
   double   price;
   datetime time;
   bool     isHigh;
};

int FindSwings(const ENUM_TIMEFRAMES tf, SwingPoint &swings[], const int lookback, const int swingLen)
{
   MqlRates r[];
   int copied = CopyRates(InpSymbol, tf, 1, lookback, r);
   if(copied < swingLen * 3) return 0;

   int count = 0;
   for(int i = swingLen; i < copied - swingLen; i++)
   {
      bool isHigh = true;
      bool isLow  = true;
      for(int j = 1; j <= swingLen; j++)
      {
         if(r[i].high <= r[i-j].high || r[i].high <= r[i+j].high) isHigh = false;
         if(r[i].low  >= r[i-j].low  || r[i].low  >= r[i+j].low)  isLow  = false;
      }
      if(!isHigh && !isLow) continue;

      ArrayResize(swings, count+1);
      swings[count].barIndex = i;
      swings[count].price    = isHigh ? r[i].high : r[i].low;
      swings[count].time     = r[i].time;
      swings[count].isHigh   = isHigh;
      count++;
   }

   // Reverse so index 0 = most recent swing (consumers expect this order)
   for(int i = 0; i < count / 2; i++)
   {
      SwingPoint tmp = swings[i];
      swings[i] = swings[count - 1 - i];
      swings[count - 1 - i] = tmp;
   }
   return count;
}

//+------------------------------------------------------------------+
//| SECTION: Auto Trendlines from swing highs/lows                  |
//+------------------------------------------------------------------+
void DrawTrendLinesForTF(const ENUM_TIMEFRAMES tf)
{
   if(!InpShowTrendLines) return;

   SwingPoint sw[];
   int nSw = FindSwings(tf, sw, 150, 5);
   if(nSw < 2) return;

   // Collect last 2 swing highs and last 2 swing lows (most-recent first)
   SwingPoint highs[2]; int nh = 0;
   SwingPoint lows[2];  int nl = 0;
   for(int i = 0; i < nSw && (nh < 2 || nl < 2); i++)
   {
      if( sw[i].isHigh && nh < 2) highs[nh++] = sw[i];
      if(!sw[i].isHigh && nl < 2) lows[nl++]  = sw[i];
   }

   // Resistance trendline: connect last 2 swing highs
   if(nh == 2)
   {
      string name = g_prefix + "TLINE_H_" + TfToText(tf);
      bool dn  = (highs[0].price < highs[1].price);
      color clr = dn ? InpTrendResistColor : InpTrendSupportColor;
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_TREND, 0, highs[1].time, highs[1].price,
                                              highs[0].time, highs[0].price);
      else
      {
         ObjectMove(0, name, 0, highs[1].time, highs[1].price);
         ObjectMove(0, name, 1, highs[0].time, highs[0].price);
      }
      ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE,     STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_WIDTH,     1);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, name, OBJPROP_BACK,      true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,    true);
   }

   // Support trendline: connect last 2 swing lows
   if(nl == 2)
   {
      string name = g_prefix + "TLINE_L_" + TfToText(tf);
      bool up  = (lows[0].price > lows[1].price);
      color clr = up ? InpTrendSupportColor : InpTrendResistColor;
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_TREND, 0, lows[1].time, lows[1].price,
                                              lows[0].time, lows[0].price);
      else
      {
         ObjectMove(0, name, 0, lows[1].time, lows[1].price);
         ObjectMove(0, name, 1, lows[0].time, lows[0].price);
      }
      ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE,     STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_WIDTH,     1);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, name, OBJPROP_BACK,      true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN,    true);
   }
}

int DetectAllStructure(const ENUM_TIMEFRAMES tf, string &patterns[], bool &directions[],
                       datetime &times[], double &prices[],
                       datetime &zoneT1[], datetime &zoneT2[],
                       double &zoneHi[], double &zoneLo[], const int maxResults)
{
   SwingPoint sw[];
   int nSw = FindSwings(tf, sw, 200, 5);
   if(nSw < 3) return 0;

   double tol = 600 * _Point;
   int count = 0;

   // Walk through triplets of same-type swings
   for(int i = 0; i < nSw - 2 && count < maxResults; i++)
   {
      SwingPoint A = sw[i];
      // Find next two of same polarity
      SwingPoint B, C;
      bool foundB = false, foundC = false;
      for(int j = i+1; j < nSw; j++)
      {
         if(!foundB && sw[j].isHigh != A.isHigh) { B = sw[j]; foundB = true; continue; }
         if(foundB && !foundC && sw[j].isHigh == A.isHigh) { C = sw[j]; foundC = true; break; }
      }
      if(!foundB || !foundC) continue;

      string pat = "";
      bool bull = false;

      if(A.isHigh && C.isHigh)
      {
         // Double Top
         if(MathAbs(A.price - C.price) <= tol && B.price < A.price - tol)
         { pat = "Double Top"; bull = false; }
         // Head & Shoulders (B is higher)
         // Find the "head" which should be a high between A and C
         SwingPoint head;
         bool foundHead = false;
         for(int k = i+1; k < nSw; k++)
         {
            if(sw[k].isHigh && sw[k].time > A.time && sw[k].time < C.time && sw[k].price > A.price + tol)
            { head = sw[k]; foundHead = true; break; }
         }
         if(foundHead && pat == "")
         { pat = "Head&Shoulders"; bull = false;
           A.price = head.price; A.time = head.time; }
      }
      else if(!A.isHigh && !C.isHigh)
      {
         // Double Bottom
         if(MathAbs(A.price - C.price) <= tol && B.price > A.price + tol)
         { pat = "Double Bottom"; bull = true; }
         // Inv H&S
         SwingPoint head;
         bool foundHead = false;
         for(int k = i+1; k < nSw; k++)
         {
            if(!sw[k].isHigh && sw[k].time > A.time && sw[k].time < C.time && sw[k].price < A.price - tol)
            { head = sw[k]; foundHead = true; break; }
         }
         if(foundHead && pat == "")
         { pat = "Inv H&S"; bull = true;
           A.price = head.price; A.time = head.time; }
      }

      if(pat == "") continue;

      ArrayResize(patterns,   count+1);
      ArrayResize(directions, count+1);
      ArrayResize(times,      count+1);
      ArrayResize(prices,     count+1);
      ArrayResize(zoneT1,     count+1);
      ArrayResize(zoneT2,     count+1);
      ArrayResize(zoneHi,     count+1);
      ArrayResize(zoneLo,     count+1);

      patterns[count]   = pat;
      directions[count] = bull;
      times[count]      = A.time;
      prices[count]     = A.price;

      // Zone for visual rectangle
      datetime earlyT = (A.time < C.time) ? A.time : C.time;
      datetime lateT  = (A.time > C.time) ? A.time : C.time;
      double hiP = MathMax(A.price, MathMax(B.price, C.price));
      double loP = MathMin(A.price, MathMin(B.price, C.price));
      zoneT1[count] = earlyT;
      zoneT2[count] = lateT;
      zoneHi[count] = hiP;
      zoneLo[count] = loP;
      count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| SECTION: Market Structure — BOS / CHoCH Detection               |
//+------------------------------------------------------------------+
void DetectMarketStructure(const int idx)
{
   ENUM_TIMEFRAMES tf = g_tfs[idx];
   SwingPoint sw[];
   int nSw = FindSwings(tf, sw, 100, 3);
   if(nSw < 3) return;

   double highs[3]; datetime highTimes[3]; int nh=0;
   double lows[3];  datetime lowTimes[3];  int nl=0;

   for(int i=0; i<nSw && (nh<3||nl<3); i++)
   {
      if( sw[i].isHigh && nh<3) { highs[nh]=sw[i].price; highTimes[nh]=sw[i].time; nh++; }
      if(!sw[i].isHigh && nl<3) { lows[nl]=sw[i].price;  lowTimes[nl]=sw[i].time;  nl++; }
   }

   if(nh<2 || nl<2) return;

   double lastClose = iClose(InpSymbol, tf, 0);
   bool bosBull = (nh>=1 && lastClose > highs[0]);  // close above last swing high → BOS UP
   bool bosBear = (nl>=1 && lastClose < lows[0]);   // close below last swing low  → BOS DN
   bool chochBull = (nh>=2 && highs[0] > highs[1]); // Higher High → bullish structure shift
   bool chochBear = (nl>=2 && lows[0]  < lows[1]);  // Lower Low   → bearish structure shift

   string pfx = g_prefix + "MS_" + TfToText(tf);

   if(bosBull)
   {
      string name = pfx + "_BOS_BUL";
      if(ObjectFind(0, name) < 0)
      {
         datetime t = iTime(InpSymbol, tf, 0);
         ObjectCreate(0, name, OBJ_TEXT, 0, t, highs[0]);
         ObjectSetString (0, name, OBJPROP_TEXT,     " BOS ↑ " + TfToText(tf));
         ObjectSetInteger(0, name, OBJPROP_COLOR,    InpSmaBullColor);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, name, OBJPROP_ANCHOR,   ANCHOR_LEFT_LOWER);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      }
   }
   if(bosBear)
   {
      string name = pfx + "_BOS_BEA";
      if(ObjectFind(0, name) < 0)
      {
         datetime t = iTime(InpSymbol, tf, 0);
         ObjectCreate(0, name, OBJ_TEXT, 0, t, lows[0]);
         ObjectSetString (0, name, OBJPROP_TEXT,     " BOS ↓ " + TfToText(tf));
         ObjectSetInteger(0, name, OBJPROP_COLOR,    InpSmaBearColor);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, name, OBJPROP_ANCHOR,   ANCHOR_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      }
   }

   // CHoCH dashed horizontal at the broken level
   if(chochBull && nh>=2)
   {
      string name = pfx + "_CHOCH_BUL";
      if(ObjectFind(0, name)<0)
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, highs[1]);
      else
         ObjectSetDouble(0, name, OBJPROP_PRICE, highs[1]);
      ObjectSetInteger(0, name, OBJPROP_COLOR,      InpSmaBullColor);
      ObjectSetInteger(0, name, OBJPROP_STYLE,      STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, name, OBJPROP_BACK,       true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
   if(chochBear && nl>=2)
   {
      string name = pfx + "_CHOCH_BEA";
      if(ObjectFind(0, name)<0)
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, lows[1]);
      else
         ObjectSetDouble(0, name, OBJPROP_PRICE, lows[1]);
      ObjectSetInteger(0, name, OBJPROP_COLOR,      InpSmaBearColor);
      ObjectSetInteger(0, name, OBJPROP_STYLE,      STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, name, OBJPROP_BACK,       true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| SECTION: Breakout / Triangle Detection                           |
//+------------------------------------------------------------------+
int DetectAllBreakouts(const ENUM_TIMEFRAMES tf, string &patterns[], bool &directions[],
                       datetime &times[], double &prices[], const int maxResults)
{
   MqlRates r[];
   int copied = CopyRates(InpSymbol, tf, 1, 80, r);
   if(copied < 42) return 0;

   // Build channel from bars 10..40
   double upper = -DBL_MAX, lower = DBL_MAX;
   for(int i=10; i<40; i++)
   {
      upper = MathMax(upper, r[i].high);
      lower = MathMin(lower, r[i].low);
   }
   if(upper <= lower) return 0;

   int count = 0;

   // Check last 10 bars for breakout
   for(int i=0; i<10 && count < maxResults; i++)
   {
      bool upBreak = (r[i].close > upper && r[i].open <= upper);
      bool dnBreak = (r[i].close < lower && r[i].open >= lower);
      if(!upBreak && !dnBreak) continue;

      ArrayResize(patterns,   count+1);
      ArrayResize(directions, count+1);
      ArrayResize(times,      count+1);
      ArrayResize(prices,     count+1);

      patterns[count]   = upBreak ? "Channel Break Up" : "Channel Break Dn";
      directions[count] = upBreak;
      times[count]      = r[i].time;
      prices[count]     = r[i].close;
      count++;
   }

   // Compression / triangle
   if(count < maxResults)
   {
      // Measure recent range vs older range
      double rangeRecent = 0;
      for(int i=0; i<10; i++) rangeRecent = MathMax(rangeRecent, r[i].high - r[i].low);
      double rangeOld = 0;
      for(int i=30; i<40; i++) rangeOld = MathMax(rangeOld, r[i].high - r[i].low);

      if(rangeOld > 0 && rangeRecent < rangeOld * 0.5)
      {
         ArrayResize(patterns,   count+1);
         ArrayResize(directions, count+1);
         ArrayResize(times,      count+1);
         ArrayResize(prices,     count+1);
         patterns[count]   = "Triangle";
         directions[count] = (r[0].close >= (upper+lower)*0.5);
         times[count]      = r[0].time;
         prices[count]     = r[0].close;
         count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Send pattern alert (subject to score threshold + cooldown)       |
//+------------------------------------------------------------------+
void TrySendAlert(const string patText, const int score,
                  const string tf, const bool isBull)
{
   if(score < InpAlertMinScore) return;

   datetime now = TimeCurrent();
   if(now - g_lastAlertTime < InpAlertCooldownSec) return;
   g_lastAlertTime = now;

   string msg = StringFormat("XAU [%s] %s %s  Score:%d  @%.2f",
                             tf,
                             patText,
                             isBull ? "BULL" : "BEAR",
                             score,
                             iClose(InpSymbol, PERIOD_CURRENT, 0));
   if(InpAlertPopup)  Alert(msg);
   if(InpAlertSound)  PlaySound("alert.wav");
   if(InpAlertPush)   SendNotification(msg);
}

//+------------------------------------------------------------------+
//| Confidence Scoring                                               |
//+------------------------------------------------------------------+
int PatternScore(const bool smaBull, const bool smaBear,
                 const bool patBull, const bool fibConf,
                 const datetime now, const int idx = -1)
{
   int s = 50;
   if(patBull && smaBull)        s += 20;
   if(!patBull && smaBear)       s += 20;
   if(fibConf)                   s += 15;
   if(IsWithinSession(now, InpLondonSession) || IsWithinSession(now, InpNYSession))
      s += 10;

   // MACD confluence bonus (+10)
   if(idx >= 0)
   {
      double mm=0, ms=0;
      GetMacd(idx, mm, ms);
      if(patBull  && mm > ms) s += 10;
      if(!patBull && mm < ms) s += 10;
   }

   // Stochastic extreme bonus (+5)
   if(idx >= 0)
   {
      double sk = GetStoch(idx);
      if(patBull  && sk <= InpStochOversold)   s += 5;
      if(!patBull && sk >= InpStochOverbought) s += 5;
   }

   return MathMin(s, 100);
}

//+------------------------------------------------------------------+
//| SECTION: Master Render (patterns + fib + arrows)                 |
//+------------------------------------------------------------------+
void RenderPatterns()
{
   datetime now    = ActiveTime();
   ENUM_TIMEFRAMES chartTF = (ENUM_TIMEFRAMES)_Period;

   for(int i = 0; i < ArraySize(g_tfs); i++)
   {
      ENUM_TIMEFRAMES tf = g_tfs[i];
      bool drawLabels = (!InpPatternsCurrentTFOnly || tf == chartTF);

      double fv=0, sv=0;
      bool smaBull=false, smaBear=false;
      SMAState(i, fv, sv, smaBull, smaBear);

      DrawFibForTF(tf);
      DrawTrendLinesForTF(tf);
      DetectMarketStructure(i);

      int objCount = 0;

      double atr = GetAtr(i);

      // --- Candlestick patterns ---
      if((InpPatternFamily & PATTERN_CANDLES) == PATTERN_CANDLES)
      {
         string pats[];  bool dirs[];  datetime ts[];  double ps[];
         int n = DetectAllCandles(tf, pats, dirs, ts, ps, InpMaxObjectsPerTF, atr);
         for(int j = 0; j < n && objCount < InpMaxObjectsPerTF; j++)
         {
            bool fibZ  = NearFib(tf, ps[j]);
            int  score = PatternScore(smaBull, smaBear, dirs[j], fibZ, now, i);
            if(j == 0 && i < ArraySize(g_lastTfPat)) g_lastTfPat[i] = pats[j];
            if(j == 0) TrySendAlert(pats[j], score, TfToText(tf), dirs[j]);
            if(!drawLabels || score < InpMinDrawScore) continue;
            color c    = dirs[j] ? InpBullPatternColor : InpBearPatternColor;
            string name = g_prefix + "PAT_C_" + TfToText(tf) + "_" + (string)ts[j];
            string txt  = StringFormat("%s %s[%d]", TfToText(tf), pats[j], score);
            DrawPatternLabel(name, ts[j], ps[j], txt, c, dirs[j], atr, score);
            objCount++;
         }
      }

      // --- Structure patterns ---
      if((InpPatternFamily & PATTERN_STRUCTURE) == PATTERN_STRUCTURE)
      {
         string pats[];  bool dirs[];  datetime ts[];  double ps[];
         datetime zt1[]; datetime zt2[]; double zhi[]; double zlo[];
         int n = DetectAllStructure(tf, pats, dirs, ts, ps, zt1, zt2, zhi, zlo, InpMaxObjectsPerTF);
         for(int j = 0; j < n && objCount < InpMaxObjectsPerTF; j++)
         {
            bool fibZ  = NearFib(tf, ps[j]);
            int  score = PatternScore(smaBull, smaBear, dirs[j], fibZ, now, i);
            if(j == 0 && i < ArraySize(g_lastTfPat) && g_lastTfPat[i] == "") g_lastTfPat[i] = pats[j];
            if(!drawLabels || score < InpMinDrawScore) continue;
            string name = g_prefix + "PAT_S_" + TfToText(tf) + "_" + (string)ts[j];
            string txt  = StringFormat("%s %s[%d]", TfToText(tf), pats[j], score);
            DrawPatternLabel(name, ts[j], ps[j], txt, InpStructureColor, dirs[j], atr, score);
            string zName = g_prefix + "PAT_SZ_" + TfToText(tf) + "_" + (string)ts[j];
            DrawStructureZone(zName, zt1[j], zt2[j], zhi[j], zlo[j], InpStructureColor);
            objCount++;
         }
      }

      // --- Breakout patterns ---
      if((InpPatternFamily & PATTERN_BREAKOUTS) == PATTERN_BREAKOUTS)
      {
         string pats[];  bool dirs[];  datetime ts[];  double ps[];
         int n = DetectAllBreakouts(tf, pats, dirs, ts, ps, InpMaxObjectsPerTF);
         for(int j = 0; j < n && objCount < InpMaxObjectsPerTF; j++)
         {
            bool fibZ  = NearFib(tf, ps[j]);
            int  score = PatternScore(smaBull, smaBear, dirs[j], fibZ, now, i);
            if(j == 0 && i < ArraySize(g_lastTfPat) && g_lastTfPat[i] == "") g_lastTfPat[i] = pats[j];
            if(!drawLabels || score < InpMinDrawScore) continue;
            string name = g_prefix + "PAT_B_" + TfToText(tf) + "_" + (string)ts[j];
            string txt  = StringFormat("%s %s[%d]", TfToText(tf), pats[j], score);
            DrawPatternLabel(name, ts[j], ps[j], txt, InpBreakoutColor, dirs[j], atr, score);
            objCount++;
         }
      }

      // --- RSI Divergence ---
      {
         string pats[];  bool dirs[];  datetime ts[];  double ps[];
         int n = DetectRsiDivergence(i, tf, pats, dirs, ts, ps, InpMaxObjectsPerTF);
         for(int j = 0; j < n && objCount < InpMaxObjectsPerTF; j++)
         {
            bool fibZ  = NearFib(tf, ps[j]);
            int  score = MathMin(PatternScore(smaBull, smaBear, dirs[j], fibZ, now, i) + 5, 100);
            if(j == 0 && i < ArraySize(g_lastTfPat) && g_lastTfPat[i] == "") g_lastTfPat[i] = pats[j];
            if(j == 0) TrySendAlert(pats[j], score, TfToText(tf), dirs[j]);
            if(!drawLabels || score < InpMinDrawScore) continue;
            color divC  = dirs[j] ? InpBullPatternColor : InpBearPatternColor;
            string name = g_prefix + "PAT_R_" + TfToText(tf) + "_" + (string)ts[j];
            string txt  = StringFormat("%s %s[%d]", TfToText(tf), pats[j], score);
            DrawPatternLabel(name, ts[j], ps[j], txt, divC, dirs[j], atr, score);
            objCount++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Indicator initialization                                         |
//+------------------------------------------------------------------+
//| SECTION: VWAP                                                    |
//+------------------------------------------------------------------+
void DrawVwap()
{
   if(!InpShowVwap) return;

   // Calculate daily VWAP from M1 data since session midnight
   datetime dayStart = StringToTime(TimeToString(ActiveTime(), TIME_DATE));
   int barStart = iBarShift(InpSymbol, PERIOD_M1, dayStart, false);
   if(barStart < 0) return;

   MqlRates r[];
   int copied = CopyRates(InpSymbol, PERIOD_M1, 0, barStart + 1, r);
   if(copied < 2) return;

   double cumTPV = 0.0, cumVol = 0.0;
   for(int i = copied - 1; i >= 0; i--)
   {
      double tp  = (r[i].high + r[i].low + r[i].close) / 3.0;
      double vol = (double)r[i].tick_volume;
      cumTPV += tp * vol;
      cumVol += vol;
   }
   if(cumVol <= 0.0) return;
   double vwapPrice = cumTPV / cumVol;

   string name = g_prefix + "VWAP";
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, vwapPrice);
   else
      ObjectSetDouble(0, name, OBJPROP_PRICE, vwapPrice);

   ObjectSetInteger(0, name, OBJPROP_COLOR,      InpVwapColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      STYLE_DASH);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      2);
   ObjectSetInteger(0, name, OBJPROP_BACK,       true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

   // Label
   string lbl = g_prefix + "VWAP_LBL";
   datetime tLabel = iTime(InpSymbol, PERIOD_CURRENT, 0);
   if(ObjectFind(0, lbl) < 0)
      ObjectCreate(0, lbl, OBJ_TEXT, 0, tLabel, vwapPrice);
   else
      ObjectMove(0, lbl, 0, tLabel, vwapPrice);
   ObjectSetString (0, lbl, OBJPROP_TEXT,       StringFormat(" VWAP %.2f", vwapPrice));
   ObjectSetInteger(0, lbl, OBJPROP_COLOR,      InpVwapColor);
   ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE,   8);
   ObjectSetInteger(0, lbl, OBJPROP_ANCHOR,     ANCHOR_LEFT);
   ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| SECTION: Bollinger Band Squeeze Detection                         |
//+------------------------------------------------------------------+
bool GetBBSqueeze(const int idx)
{
   if(!InpShowBBSqueeze) return false;
   if(idx < 0 || idx >= ArraySize(g_bbHandles)) return false;
   if(g_bbHandles[idx] == INVALID_HANDLE) return false;

   double upper[1], lower[1];
   if(CopyBuffer(g_bbHandles[idx], 1, 0, 1, upper) < 1) return false;
   if(CopyBuffer(g_bbHandles[idx], 2, 0, 1, lower) < 1) return false;

   double atr = GetAtr(idx);
   if(atr <= 0.0) return false;

   double bandwidth = upper[0] - lower[0];
   return (bandwidth < atr * InpBBSqueezeThreshold * 4.0);
}

//+------------------------------------------------------------------+
//| SECTION: Confluence Score Panel (bottom-right)                   |
//+------------------------------------------------------------------+
void DrawConfluencePanel()
{
   if(!InpShowConfluence) return;

   // Find index of current chart TF
   int idx = -1;
   ENUM_TIMEFRAMES chartTF = (ENUM_TIMEFRAMES)_Period;
   for(int i = 0; i < ArraySize(g_tfs); i++)
      if(g_tfs[i] == chartTF) { idx = i; break; }

   int score = 0;
   string details = "";

   if(idx >= 0)
   {
      double fv=0, sv=0; bool bull=false, bear=false;
      SMAState(idx, fv, sv, bull, bear);
      if(bull)  { score += 20; details += "MA+ "; }
      if(bear)  { score += 20; details += "MA- "; }

      double rsi = GetRsi(idx);
      if(rsi <= InpRsiOversold)   { score += 15; details += "RSI-OS "; }
      if(rsi >= InpRsiOverbought) { score += 15; details += "RSI-OB "; }

      double mm=0, ms=0; GetMacd(idx, mm, ms);
      if(mm != ms) { score += 15; details += "MACD "; }

      double sk = GetStoch(idx);
      if(sk <= InpStochOversold || sk >= InpStochOverbought) { score += 10; details += "STOCH "; }

      double close = iClose(InpSymbol, chartTF, 0);
      if(NearFib(chartTF, close)) { score += 15; details += "FIB "; }

      datetime now = ActiveTime();
      if(IsWithinSession(now, InpLondonSession) || IsWithinSession(now, InpNYSession))
      { score += 10; details += "SESSION "; }

      if(GetBBSqueeze(idx)) { score = MathMin(score + 15, 100); details += "BB-SQ "; }
      score = MathMin(score, 100);
   }

   color barClr = (score >= 70) ? clrLimeGreen : (score >= 40) ? clrGold : clrTomato;

   string bg  = g_prefix + "CONF_BG";
   string hdr = g_prefix + "CONF_HDR";
   string sc  = g_prefix + "CONF_SC";
   string dt  = g_prefix + "CONF_DT";

   if(ObjectFind(0, bg) < 0)
   {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER,      CORNER_RIGHT_LOWER);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE,   10);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE,   10);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE,       230);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE,       72);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR,     C'15,15,25');
      ObjectSetInteger(0, bg, OBJPROP_COLOR,       clrGold);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE,  false);
   }
   if(ObjectFind(0, hdr) < 0)
   {
      ObjectCreate(0, hdr, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, hdr, OBJPROP_CORNER,     CORNER_RIGHT_LOWER);
      ObjectSetInteger(0, hdr, OBJPROP_XDISTANCE,  222);
      ObjectSetInteger(0, hdr, OBJPROP_YDISTANCE,  66);
      ObjectSetInteger(0, hdr, OBJPROP_FONTSIZE,   8);
      ObjectSetInteger(0, hdr, OBJPROP_COLOR,      clrGold);
      ObjectSetString (0, hdr, OBJPROP_TEXT,       "Confluence");
      ObjectSetInteger(0, hdr, OBJPROP_SELECTABLE, false);
   }
   if(ObjectFind(0, sc) < 0)
   {
      ObjectCreate(0, sc, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, sc, OBJPROP_CORNER,     CORNER_RIGHT_LOWER);
      ObjectSetInteger(0, sc, OBJPROP_XDISTANCE,  222);
      ObjectSetInteger(0, sc, OBJPROP_YDISTANCE,  46);
      ObjectSetInteger(0, sc, OBJPROP_FONTSIZE,   14);
      ObjectSetInteger(0, sc, OBJPROP_SELECTABLE, false);
   }
   if(ObjectFind(0, dt) < 0)
   {
      ObjectCreate(0, dt, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, dt, OBJPROP_CORNER,     CORNER_RIGHT_LOWER);
      ObjectSetInteger(0, dt, OBJPROP_XDISTANCE,  222);
      ObjectSetInteger(0, dt, OBJPROP_YDISTANCE,  24);
      ObjectSetInteger(0, dt, OBJPROP_FONTSIZE,   7);
      ObjectSetInteger(0, dt, OBJPROP_COLOR,      clrSilver);
      ObjectSetInteger(0, dt, OBJPROP_SELECTABLE, false);
   }

   ObjectSetString (0, sc, OBJPROP_TEXT,  StringFormat("%d%%", score));
   ObjectSetInteger(0, sc, OBJPROP_COLOR, barClr);
   if(StringLen(details) > 0)
      ObjectSetString(0, dt, OBJPROP_TEXT, details);
   else
      ObjectSetString(0, dt, OBJPROP_TEXT, "No signals");
}

//+------------------------------------------------------------------+
//| Indicator initialization                                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // --- Input validation ---
   if(InpSmaFast <= 0 || InpSmaSlow <= 0)
   {
      Print("ERROR: MA periods must be > 0. SmaFast=", InpSmaFast, " SmaSlow=", InpSmaSlow);
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpSmaFast >= InpSmaSlow)
   {
      Print("WARNING: SmaFast (", InpSmaFast, ") >= SmaSlow (", InpSmaSlow, "). MA crossover signals may be unreliable.");
   }
   if(InpAtrPeriod <= 0)
   {
      Print("ERROR: ATR period must be > 0.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpRsiPeriod <= 0)
   {
      Print("ERROR: RSI period must be > 0.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpRsiOversold >= InpRsiOverbought)
   {
      Print("WARNING: RSI oversold (", InpRsiOversold, ") >= overbought (", InpRsiOverbought, "). RSI zones may be reversed.");
   }
   if(InpAlertMinScore < 0 || InpAlertMinScore > 100)
   {
      Print("WARNING: InpAlertMinScore should be 0-100. Got ", InpAlertMinScore);
   }

   if(_Symbol != InpSymbol)
      Print("Indicator designed for ", InpSymbol, " but attached on ", _Symbol);

   BuildTimeframeList();

   int n = ArraySize(g_tfs);
   ArrayResize(g_fastHandles,  n);
   ArrayResize(g_slowHandles,  n);
   ArrayResize(g_atrHandles,   n);
   ArrayResize(g_rsiHandles,   n);
   ArrayResize(g_macdHandles,  n);
   ArrayResize(g_stochHandles, n);
   ArrayResize(g_bbHandles,    n);
   ArrayResize(g_lastTfBar,    n);
   ArrayResize(g_lastTfPat,    n);
   ArrayInitialize(g_lastTfBar, 0);

   for(int i = 0; i < n; i++)
   {
      string tfTxt = TfToText(g_tfs[i]);

      g_fastHandles[i] = iMA(InpSymbol, g_tfs[i], InpSmaFast, 0, InpMaMethod, PRICE_CLOSE);
      if(g_fastHandles[i] == INVALID_HANDLE)
         PrintFormat("WARNING: iMA fast failed for TF %s", tfTxt);

      g_slowHandles[i] = iMA(InpSymbol, g_tfs[i], InpSmaSlow, 0, InpMaMethod, PRICE_CLOSE);
      if(g_slowHandles[i] == INVALID_HANDLE)
         PrintFormat("WARNING: iMA slow failed for TF %s", tfTxt);

      g_atrHandles[i] = iATR(InpSymbol, g_tfs[i], InpAtrPeriod);
      if(g_atrHandles[i] == INVALID_HANDLE)
         PrintFormat("WARNING: iATR failed for TF %s", tfTxt);

      g_rsiHandles[i] = iRSI(InpSymbol, g_tfs[i], InpRsiPeriod, PRICE_CLOSE);
      if(g_rsiHandles[i] == INVALID_HANDLE)
         PrintFormat("WARNING: iRSI failed for TF %s", tfTxt);

      g_macdHandles[i] = iMACD(InpSymbol, g_tfs[i], InpMacdFast, InpMacdSlow, InpMacdSignal, PRICE_CLOSE);
      if(g_macdHandles[i] == INVALID_HANDLE)
         PrintFormat("WARNING: iMACD failed for TF %s", tfTxt);

      g_stochHandles[i] = iStochastic(InpSymbol, g_tfs[i], InpStochK, InpStochD, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
      if(g_stochHandles[i] == INVALID_HANDLE)
         PrintFormat("WARNING: iStochastic failed for TF %s", tfTxt);

      g_bbHandles[i] = iBands(InpSymbol, g_tfs[i], InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
      if(g_bbHandles[i] == INVALID_HANDLE)
         PrintFormat("WARNING: iBands failed for TF %s", tfTxt);

      g_lastTfPat[i] = "";
   }

   // Optionally draw MA lines on chart for current TF
   if(InpShowSmaLines)
   {
      for(int i = 0; i < n; i++)
      {
         if(g_tfs[i] == (ENUM_TIMEFRAMES)_Period)
         {
            if(g_fastHandles[i] != INVALID_HANDLE) ChartIndicatorAdd(0, 0, g_fastHandles[i]);
            if(g_slowHandles[i] != INVALID_HANDLE) ChartIndicatorAdd(0, 0, g_slowHandles[i]);
            break;
         }
      }
   }

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Indicator deinitialization                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeleteByPrefix(g_prefix);   // wipe all our objects

   for(int i = 0; i < ArraySize(g_fastHandles); i++)
   {
      if(g_fastHandles[i]  != INVALID_HANDLE) IndicatorRelease(g_fastHandles[i]);
      if(g_slowHandles[i]  != INVALID_HANDLE) IndicatorRelease(g_slowHandles[i]);
      if(i < ArraySize(g_atrHandles)   && g_atrHandles[i]   != INVALID_HANDLE) IndicatorRelease(g_atrHandles[i]);
      if(i < ArraySize(g_rsiHandles)   && g_rsiHandles[i]   != INVALID_HANDLE) IndicatorRelease(g_rsiHandles[i]);
      if(i < ArraySize(g_macdHandles)  && g_macdHandles[i]  != INVALID_HANDLE) IndicatorRelease(g_macdHandles[i]);
      if(i < ArraySize(g_stochHandles) && g_stochHandles[i] != INVALID_HANDLE) IndicatorRelease(g_stochHandles[i]);
      if(i < ArraySize(g_bbHandles)    && g_bbHandles[i]    != INVALID_HANDLE) IndicatorRelease(g_bbHandles[i]);
   }
}

//+------------------------------------------------------------------+
//| Indicator calculation                                            |
//+------------------------------------------------------------------+
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
   if(rates_total < 10) return rates_total;

   // time[] default order: oldest at [0]. Use last element for newest bar.
   datetime currentBar = time[rates_total - 1];
   bool newBar = (currentBar != g_lastChartBar);

   if(newBar)
   {
      g_lastChartBar = currentBar;

      // Reset per-TF pattern labels
      for(int i = 0; i < ArraySize(g_lastTfPat); i++) g_lastTfPat[i] = "";

      // Delete stale drawn objects by prefix categories, then redraw
      DeleteByPrefix(g_prefix + "PAT_");
      DeleteByPrefix(g_prefix + "SMA_ARR_");
      DeleteByPrefix(g_prefix + "TLINE_");
      DeleteByPrefix(g_prefix + "MS_");
      DeleteByPrefix(g_prefix + "PIV_");
      DeleteByPrefix(g_prefix + "PIVLBL_");
      DeleteByPrefix(g_prefix + "VWAP");

      RenderPatterns();
      DrawSmaArrows();
      DrawSessionBoxes();
      DrawPivotPoints();
      DrawSupplyDemandZones();
      DrawVwap();

      ChartRedraw(0);
   }

   // Always update live panels (tick-level refresh)
   DrawTimePanel();
   DrawDashboard();
   DrawLotCalcPanel();
   DrawConfluencePanel();

   return rates_total;
}
