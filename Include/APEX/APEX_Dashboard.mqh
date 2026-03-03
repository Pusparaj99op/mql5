//+------------------------------------------------------------------+
//|                                            APEX_Dashboard.mqh    |
//|          APEX Gold Destroyer - On-Chart HUD Dashboard             |
//+------------------------------------------------------------------+
#property copyright "APEX Gold Destroyer"
#property version   "1.00"
#property strict

#ifndef APEX_DASHBOARD_MQH
#define APEX_DASHBOARD_MQH

#include "APEX_Config.mqh"

//+------------------------------------------------------------------+
//| Dashboard Engine - Real-Time Combat HUD                           |
//+------------------------------------------------------------------+
class CDashboardEngine
  {
private:
   string            m_prefix;
   bool              m_initialized;
   int               m_x;
   int               m_y;
   int               m_lineHeight;
   color             m_bgColor;
   color             m_borderColor;
   color             m_textColor;
   color             m_headerColor;
   int               m_fontSize;
   string            m_fontName;
   int               m_panelWidth;
   int               m_panelHeight;
   int               m_lineCount;

   void              CreateBackground();
   void              CreateLabel(string name, int row, string text, color clr = clrWhite);
   void              UpdateLabel(string name, string text, color clr = clrWhite);
   void              DeleteObject(string name);
   color             RegimeColor(int regime);
   color             SignalColor(double score);
   color             PnLColor(double val);
   string            StateToString(int state);
   string            RegimeToString(int regime);
   string            StrategyToString(int strategy);

public:
                     CDashboardEngine();
                    ~CDashboardEngine();
   bool              Init();
   void              Deinit();

   // Main update method
   void              Update(int regime, int hmmState, double hmmConf, double hmmEntropy,
                            int htfBias, double signalScore, int strategy,
                            int posCount, double unrealPnL, double realizedPnL,
                            double winRate, int totalTrades,
                            double lotSize, int martingaleLevel,
                            double domBias, string nextNews, int newsMinutes,
                            int newsState,
                            double spread, double atr, double atrPercentile,
                            bool sessionActive, double equity, double balance);
  };

//+------------------------------------------------------------------+
CDashboardEngine::CDashboardEngine()
  {
   m_prefix     = "APEX_";
   m_initialized = false;
   m_x          = 10;
   m_y          = 30;
   m_lineHeight = 18;
   m_bgColor    = C'15,15,25';
   m_borderColor= C'60,60,100';
   m_textColor  = clrWhite;
   m_headerColor= C'0,200,255';
   m_fontSize   = 8;
   m_fontName   = "Consolas";
   m_panelWidth = 310;
   m_panelHeight= 520;
   m_lineCount  = 0;
  }

//+------------------------------------------------------------------+
CDashboardEngine::~CDashboardEngine() { Deinit(); }

//+------------------------------------------------------------------+
bool CDashboardEngine::Init()
  {
   if(!InpDashboard) return true;

   // Create background panel
   CreateBackground();

   // Create all static labels
   int row = 0;
   CreateLabel("title",    row++, "=== APEX GOLD DESTROYER ===", m_headerColor);
   CreateLabel("divider1", row++, "------------------------------", C'60,60,100');
   CreateLabel("regime",   row++, "Regime:    ---");
   CreateLabel("hmm",      row++, "HMM:       ---");
   CreateLabel("hmmconf",  row++, "HMM Conf:  ---");
   CreateLabel("entropy",  row++, "Entropy:   ---");
   CreateLabel("htfbias",  row++, "HTF Bias:  ---");
   CreateLabel("divider2", row++, "------------------------------", C'60,60,100');
   CreateLabel("signal",   row++, "Signal:    ---");
   CreateLabel("strategy", row++, "Strategy:  ---");
   CreateLabel("divider3", row++, "------------------------------", C'60,60,100');
   CreateLabel("pos",      row++, "Positions: ---");
   CreateLabel("upnl",     row++, "Unreal PnL:---");
   CreateLabel("rpnl",     row++, "Real PnL:  ---");
   CreateLabel("winrate",  row++, "Win Rate:  ---");
   CreateLabel("trades",   row++, "Trades:    ---");
   CreateLabel("divider4", row++, "------------------------------", C'60,60,100');
   CreateLabel("lots",     row++, "Lot Size:  ---");
   CreateLabel("martin",   row++, "Martingale:---");
   CreateLabel("dom",      row++, "DOM Bias:  ---");
   CreateLabel("divider5", row++, "------------------------------", C'60,60,100');
   CreateLabel("news",     row++, "Next News: ---");
   CreateLabel("newstime", row++, "News In:   ---");
   CreateLabel("newsstate",row++, "News Mode: ---");
   CreateLabel("divider6", row++, "------------------------------", C'60,60,100');
   CreateLabel("spread",   row++, "Spread:    ---");
   CreateLabel("atr",      row++, "ATR:       ---");
   CreateLabel("atrpct",   row++, "ATR %ile:  ---");
   CreateLabel("session",  row++, "Session:   ---");
   CreateLabel("equity",   row++, "Equity:    ---");
   CreateLabel("ddpct",    row++, "DD%:       ---");

   m_lineCount = row;
   m_panelHeight = (row + 1) * m_lineHeight + 15;

   // Resize background
   ObjectSetInteger(0, m_prefix + "bg", OBJPROP_YSIZE, m_panelHeight);

   m_initialized = true;
   ChartRedraw(0);
   return true;
  }

//+------------------------------------------------------------------+
void CDashboardEngine::Deinit()
  {
   if(!m_initialized) return;

   // Delete all objects with our prefix
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, m_prefix) == 0)
         ObjectDelete(0, name);
     }
   ChartRedraw(0);
   m_initialized = false;
  }

//+------------------------------------------------------------------+
void CDashboardEngine::CreateBackground()
  {
   string name = m_prefix + "bg";
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, m_panelWidth);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, m_panelHeight);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, m_bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, m_borderColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
void CDashboardEngine::CreateLabel(string name, int row, string text, color clr = clrWhite)
  {
   string objName = m_prefix + name;
   ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, m_x + 10);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, m_y + 8 + row * m_lineHeight);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetString(0, objName, OBJPROP_FONT, m_fontName);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, m_fontSize);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
void CDashboardEngine::UpdateLabel(string name, string text, color clr = clrWhite)
  {
   string objName = m_prefix + name;
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
  }

//+------------------------------------------------------------------+
color CDashboardEngine::RegimeColor(int regime)
  {
   switch(regime)
     {
      case REGIME_BULL:       return C'0,255,100';
      case REGIME_BEAR:       return C'255,80,80';
      case REGIME_RANGE:      return C'255,255,0';
      case REGIME_VOLATILE:   return C'255,0,255';
      case REGIME_TRANSITION: return C'180,180,180';
      default:                return clrWhite;
     }
  }

//+------------------------------------------------------------------+
color CDashboardEngine::SignalColor(double score)
  {
   if(score >= 8.0)   return C'0,255,100';
   if(score >= 6.0)   return C'0,200,255';
   if(score >= 4.0)   return C'255,255,0';
   if(score >= 0)     return C'180,180,180';
   if(score >= -4.0)  return C'255,255,0';
   if(score >= -6.0)  return C'255,150,0';
   return C'255,80,80';
  }

//+------------------------------------------------------------------+
color CDashboardEngine::PnLColor(double val)
  {
   if(val > 0) return C'0,255,100';
   if(val < 0) return C'255,80,80';
   return clrWhite;
  }

//+------------------------------------------------------------------+
string CDashboardEngine::RegimeToString(int regime)
  {
   switch(regime)
     {
      case REGIME_BULL:       return "BULL";
      case REGIME_BEAR:       return "BEAR";
      case REGIME_RANGE:      return "RANGE";
      case REGIME_VOLATILE:   return "VOLATILE";
      case REGIME_TRANSITION: return "TRANSITION";
      default:                return "UNKNOWN";
     }
  }

//+------------------------------------------------------------------+
string CDashboardEngine::StateToString(int state)
  {
   switch(state)
     {
      case 0:  return "BEAR";
      case 1:  return "RANGE";
      case 2:  return "BULL";
      default: return "???";
     }
  }

//+------------------------------------------------------------------+
string CDashboardEngine::StrategyToString(int strategy)
  {
   switch(strategy)
     {
      case STRAT_TREND:     return "TREND";
      case STRAT_PULLBACK:  return "PULLBACK";
      case STRAT_BREAKOUT:  return "BREAKOUT";
      case STRAT_MEANREV:   return "MEAN-REV";
      case STRAT_NEWS:      return "NEWS";
      case STRAT_DOM_SCALP: return "DOM-SCALP";
      case STRAT_GRID:      return "GRID";
      default:              return "NONE";
     }
  }

//+------------------------------------------------------------------+
void CDashboardEngine::Update(int regime, int hmmState, double hmmConf, double hmmEntropy,
                               int htfBias, double signalScore, int strategy,
                               int posCount, double unrealPnL, double realizedPnL,
                               double winRate, int totalTrades,
                               double lotSize, int martingaleLevel,
                               double domBias, string nextNews, int newsMinutes,
                               int newsState,
                               double spread, double atr, double atrPercentile,
                               bool sessionActive, double equity, double balance)
  {
   if(!m_initialized || !InpDashboard) return;

   // Regime
   UpdateLabel("regime", StringFormat("Regime:    %s", RegimeToString(regime)), RegimeColor(regime));

   // HMM
   UpdateLabel("hmm",    StringFormat("HMM:       %s", StateToString(hmmState)),
               hmmState == 2 ? C'0,255,100' : (hmmState == 0 ? C'255,80,80' : C'255,255,0'));
   UpdateLabel("hmmconf", StringFormat("HMM Conf:  %.1f%%", hmmConf * 100),
               hmmConf > 0.7 ? C'0,255,100' : (hmmConf > 0.5 ? C'255,255,0' : C'255,80,80'));
   UpdateLabel("entropy", StringFormat("Entropy:   %.2f", hmmEntropy),
               hmmEntropy < 0.6 ? C'0,255,100' : C'255,255,0');

   // HTF
   string htfStr = (htfBias > 0) ? "BULLISH" : (htfBias < 0 ? "BEARISH" : "NEUTRAL");
   color htfClr  = (htfBias > 0) ? C'0,255,100' : (htfBias < 0 ? C'255,80,80' : clrWhite);
   UpdateLabel("htfbias", StringFormat("HTF Bias:  %s", htfStr), htfClr);

   // Signal
   UpdateLabel("signal",   StringFormat("Signal:    %.1f", signalScore), SignalColor(signalScore));
   UpdateLabel("strategy", StringFormat("Strategy:  %s", StrategyToString(strategy)),
               strategy == STRAT_NEWS ? C'255,0,255' : C'0,200,255');

   // Positions
   UpdateLabel("pos",   StringFormat("Positions: %d", posCount),
               posCount > 3 ? C'255,150,0' : clrWhite);
   UpdateLabel("upnl",  StringFormat("Unreal PnL:$%.2f", unrealPnL), PnLColor(unrealPnL));
   UpdateLabel("rpnl",  StringFormat("Real PnL:  $%.2f", realizedPnL), PnLColor(realizedPnL));
   double winRatePct = winRate * 100.0;
   UpdateLabel("winrate", StringFormat("Win Rate:  %.1f%%", winRatePct),
               winRatePct > 55 ? C'0,255,100' : (winRatePct > 45 ? C'255,255,0' : C'255,80,80'));
   UpdateLabel("trades", StringFormat("Trades:    %d", totalTrades), clrWhite);

   // Sizing
   UpdateLabel("lots",   StringFormat("Lot Size:  %.2f", lotSize), clrWhite);
   UpdateLabel("martin", StringFormat("Martingale:Lv%d", martingaleLevel),
               martingaleLevel > 0 ? C'255,150,0' : clrWhite);
   UpdateLabel("dom",    StringFormat("DOM Bias:  %.2f", domBias),
               domBias > 0.3 ? C'0,255,100' : (domBias < -0.3 ? C'255,80,80' : clrWhite));

   // News
   UpdateLabel("news",    StringFormat("Next News: %s", nextNews == "" ? "---" : nextNews),
               newsMinutes <= 15 ? C'255,0,255' : clrWhite);
   UpdateLabel("newstime", StringFormat("News In:   %d min", newsMinutes),
               newsMinutes <= 5 ? C'255,0,0' : (newsMinutes <= 15 ? C'255,255,0' : clrWhite));

   string nsStr;
   color nsClr = clrWhite;
   switch(newsState)
     {
      case NEWS_NONE:      nsStr = "CLEAR";    nsClr = C'0,255,100'; break;
      case NEWS_PRE:       nsStr = "PRE-NEWS"; nsClr = C'255,255,0'; break;
      case NEWS_DURING:    nsStr = "LIVE!";    nsClr = C'255,0,0';   break;
      case NEWS_POST_FADE: nsStr = "FADE";     nsClr = C'255,0,255'; break;
      default:             nsStr = "---";      break;
     }
   UpdateLabel("newsstate", StringFormat("News Mode: %s", nsStr), nsClr);

   // Market info
   UpdateLabel("spread",  StringFormat("Spread:    %.1f pts", spread),
               spread > 50 ? C'255,80,80' : (spread > 30 ? C'255,255,0' : C'0,255,100'));
   UpdateLabel("atr",     StringFormat("ATR:       %.2f", atr), clrWhite);
   UpdateLabel("atrpct",  StringFormat("ATR %%ile:  %.0f%%", atrPercentile * 100),
               atrPercentile > 0.8 ? C'255,0,255' : clrWhite);
   UpdateLabel("session", StringFormat("Session:   %s", sessionActive ? "ACTIVE" : "CLOSED"),
               sessionActive ? C'0,255,100' : C'255,80,80');
   UpdateLabel("equity",  StringFormat("Equity:    $%.2f", equity),
               PnLColor(equity - balance));

   double ddPct = (balance > 0) ? ((balance - equity) / balance * 100.0) : 0;
   UpdateLabel("ddpct",   StringFormat("DD%%:       %.1f%%", ddPct),
               ddPct > 50 ? C'255,0,0' : (ddPct > 30 ? C'255,150,0' : (ddPct > 15 ? C'255,255,0' : C'0,255,100')));

   ChartRedraw(0);
  }

#endif // APEX_DASHBOARD_MQH
