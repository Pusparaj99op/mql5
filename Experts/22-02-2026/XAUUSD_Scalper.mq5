//+------------------------------------------------------------------+
//|                                              XAUUSD_Scalper.mq5  |
//|                        5-Position Scalper for XAUUSD (GOLD) MT5  |
//|                                           Version 2.0.0          |
//|                                     Personal Use Only            |
//+------------------------------------------------------------------+
#property copyright   "XAUUSD_1-3_scalper"
#property link        "https://github.com/Pusparaj99op/XAUUSD_1-3_scalper_MT5"
#property version     "2.00"
#property description "5-position XAUUSD scalper with 1:3 R:R, multi-indicator confluence, advanced math, MTF analysis, dynamic lots, and on-chart dashboard"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
//--- General
input string   InpEAComment          = "XAUUSD_1-3_scalper";   // EA Comment
input int      InpMagicNumber        = 202602220;              // Magic Number
input double   InpLotSize            = 0.01;                   // Lot Size (fixed, if dynamic off)
input int      InpMaxPositions       = 5;                      // Max Open Positions
input bool     InpReopenOnClose      = true;                   // Re-open on Position Close
input int      InpMaxSlippage        = 5;                      // Max Slippage (points)

//--- Dynamic Lot Sizing
input bool     InpUseDynamicLots     = true;                   // Use Dynamic Lot Sizing
input double   InpRiskPercent        = 1.0;                    // Risk % per Trade (of Balance)
input double   InpMinLotOverride     = 0.01;                   // Min Lot Override (0=broker min)
input double   InpMaxLotOverride     = 1.0;                    // Max Lot Override (0=broker max)

//--- SL/TP in USD
input double   InpSL_USD             = 1.0;                    // Stop Loss (USD per lot)
input double   InpTP_USD             = 3.0;                    // Take Profit (USD per lot)

//--- Dynamic SL/TP
input bool     InpDynamicSLTP        = false;                  // Use Dynamic ATR-based SL/TP
input double   InpSL_ATR_Mult        = 1.5;                    // SL ATR Multiplier (if dynamic)
input double   InpTP_ATR_Mult        = 3.0;                    // TP ATR Multiplier (if dynamic)
input bool     InpPartialTP          = false;                  // Enable Partial Take Profit
input double   InpPartialTPPercent   = 50.0;                   // % to Close at TP1
input double   InpTP1_ATR_Mult       = 1.5;                    // TP1 ATR Multiplier (partial close)

//--- EMA Trend
input int      InpEMA_Fast           = 20;                     // EMA Fast Period
input int      InpEMA_Mid            = 50;                     // EMA Mid Period
input int      InpEMA_Slow           = 200;                    // EMA Slow Period

//--- Stochastic
input int      InpStoch_K            = 5;                      // Stochastic %K Period
input int      InpStoch_D            = 3;                      // Stochastic %D Period
input int      InpStoch_Slowing      = 3;                      // Stochastic Slowing
input double   InpStoch_Overbought   = 80.0;                   // Stochastic Overbought
input double   InpStoch_Oversold     = 20.0;                   // Stochastic Oversold

//--- RSI
input int      InpRSI_Period         = 14;                     // RSI Period
input double   InpRSI_BuyLow        = 30.0;                   // RSI Buy Zone Low
input double   InpRSI_BuyHigh       = 60.0;                   // RSI Buy Zone High
input double   InpRSI_SellLow       = 40.0;                   // RSI Sell Zone Low
input double   InpRSI_SellHigh      = 70.0;                   // RSI Sell Zone High

//--- MACD
input int      InpMACD_Fast          = 12;                     // MACD Fast EMA
input int      InpMACD_Slow          = 26;                     // MACD Slow EMA
input int      InpMACD_Signal        = 9;                      // MACD Signal

//--- ATR Volatility Filter
input int      InpATR_Period         = 14;                     // ATR Period
input double   InpATR_Min            = 0.5;                    // Min ATR (USD)
input double   InpATR_Max            = 8.0;                    // Max ATR (USD)

//--- Volume Filter
input double   InpVolMultiplier      = 1.2;                    // Min Volume Multiplier

//--- Session Filter (GMT+5:30 / IST)
input bool     InpAvoidFridayClose   = true;                   // Avoid Friday Close
input string   InpFridayStopTime     = "23:30";                // Friday Stop New Trades After (IST)
input bool     InpAvoidMondayOpen    = true;                   // Avoid Monday Open
input string   InpMondayStartTime    = "01:03";                // Monday Start Trading After (IST)
input int      InpGMTOffset          = 5;                      // Broker GMT Offset (hours)
input int      InpGMTOffsetMin       = 30;                     // Broker GMT Offset (minutes)

//--- Session Windows (IST HH:MM)
input string   InpLondonStart        = "13:30";                // London Open Start (IST)
input string   InpLondonEnd          = "17:00";                // London Open End (IST)
input string   InpNYStart            = "18:30";                // NY Open Start (IST)
input string   InpNYEnd              = "22:30";                // NY Open End (IST)

//--- DOM
input bool     InpDOMEnabled         = true;                   // Enable DOM Analysis
input double   InpDOMImbalanceRatio  = 1.5;                    // DOM Imbalance Ratio Threshold

//--- Advanced Math
input bool     InpFibEnabled         = true;                   // Enable Fibonacci Levels
input bool     InpZScoreEnabled      = true;                   // Enable Z-Score Filter
input double   InpZScoreThreshold    = 1.5;                    // Z-Score Entry Threshold
input bool     InpATRRegimeEnabled   = true;                   // Enable ATR Regime Scaling
input bool     InpPriceActionEnabled = true;                   // Enable Price Action Patterns

//--- Bollinger Bands
input bool     InpBBEnabled          = true;                   // Enable Bollinger Bands
input int      InpBB_Period          = 20;                     // BB Period
input double   InpBB_Deviation       = 2.0;                    // BB Deviation
input double   InpBB_ProximityPct    = 0.05;                   // BB Proximity % (distance to band)

//--- VWAP
input bool     InpVWAPEnabled        = true;                   // Enable VWAP

//--- Linear Regression Channel
input bool     InpLinRegEnabled      = true;                   // Enable Linear Regression Channel
input int      InpLinReg_Period      = 50;                     // Linear Regression Lookback
input double   InpLinReg_DevMult     = 2.0;                    // Channel Deviation Multiplier

//--- Keltner Channel
input bool     InpKeltnerEnabled     = true;                   // Enable Keltner Channel
input int      InpKeltner_EMAPeriod  = 20;                     // Keltner EMA Period
input double   InpKeltner_ATRMult    = 1.5;                    // Keltner ATR Multiplier

//--- Multi-Timeframe Analysis
input bool     InpMTFEnabled         = true;                   // Enable MTF Analysis
input bool     InpMTFMandatory       = false;                  // Require MTF Alignment (vs. confluence)

//--- Trailing & Breakeven
input bool     InpUseTrailing        = true;                   // Use Trailing Stop
input double   InpBE_TriggerUSD      = 1.5;                    // Move to BE at +$X profit
input double   InpTrailDistATRMult   = 1.0;                    // Trailing Distance (ATR multiplier)

//--- Risk Management
input double   InpDailyLossCapUSD    = 10.0;                   // Daily Loss Cap (USD)
input double   InpMaxDrawdownPct     = 5.0;                    // Max Drawdown % Circuit Breaker

//--- Confluence
input int      InpMinConfluence      = 4;                      // Min Confluence Score to Enter (1-13)

//--- Dashboard
input bool     InpDashEnabled        = true;                   // Enable Chart Dashboard
input int      InpDashX              = 10;                     // Dashboard X Position
input int      InpDashY              = 25;                     // Dashboard Y Position

//--- CSV Logging
input bool     InpCSVEnabled         = true;                   // Enable CSV Logging

//--- Chart Arrows
input bool     InpArrowsEnabled      = true;                   // Enable Trade Arrows on Chart
input color    InpArrowBuyColor      = clrDodgerBlue;          // Buy Entry Arrow Color
input color    InpArrowSellColor     = clrOrangeRed;           // Sell Entry Arrow Color
input color    InpArrowWinColor      = clrLime;                // Winning Exit Arrow Color
input color    InpArrowLossColor     = clrRed;                 // Losing Exit Arrow Color

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;

//--- Indicator handles (M5)
int hEMA_Fast, hEMA_Mid, hEMA_Slow;
int hStoch, hRSI, hMACD, hATR;

//--- New indicator handles
int hBB;                          // Bollinger Bands
int hKeltner_EMA;                 // Keltner Channel EMA

//--- MTF handles
int hEMA_H1_Fast, hEMA_H1_Mid;   // H1 EMA 20/50
int hEMA_H4_Fast, hEMA_H4_Mid;   // H4 EMA 20/50

//--- State tracking
datetime  g_lastBarTime     = 0;
double    g_dailyPnL        = 0;
int       g_dailyTradeCount = 0;
int       g_dailyWins       = 0;
int       g_dailyLosses     = 0;
datetime  g_lastDayReset    = 0;
bool      g_circuitBreaker  = false;
bool      g_domAvailable    = false;
int       g_lastPositionCount = 0;

//--- Dynamic lot sizing
double    g_calculatedLotSize = 0.01;

//--- MTF state
bool      g_mtfActive       = false;
int       g_mtfH1Trend      = 0;
int       g_mtfH4Trend      = 0;

//--- Fibonacci levels
double    g_fibLevels[]     = {0.236, 0.382, 0.5, 0.618, 0.786};

//--- ATR Regime history for percentile
double    g_atrHistory[];
int       g_atrHistorySize  = 100;

//--- VWAP state
double    g_vwapValue        = 0;
double    g_vwapSumPV        = 0;
double    g_vwapSumVol       = 0;
datetime  g_vwapResetTime    = 0;

//--- Linear Regression cache
double    g_linRegSlope      = 0;
double    g_linRegIntercept  = 0;
double    g_linRegUpper      = 0;
double    g_linRegLower      = 0;
double    g_linRegCenter     = 0;

//--- Partial TP tracking
ulong     g_partialTPDone[];
int       g_partialTPCount   = 0;

//--- Dashboard object names prefix
string    g_dashPrefix      = "XAUSD_DASH_";

//--- Arrow object names prefix
string    g_arrowPrefix     = "XAUSD_ARW_";

//+------------------------------------------------------------------+
//| INITIALIZATION                                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Validate symbol
   string sym = _Symbol;
   symInfo.Name(sym);

   //--- Setup trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpMaxSlippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   //--- Create M5 indicator handles
   hEMA_Fast = iMA(sym, PERIOD_M5, InpEMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   hEMA_Mid  = iMA(sym, PERIOD_M5, InpEMA_Mid,  0, MODE_EMA, PRICE_CLOSE);
   hEMA_Slow = iMA(sym, PERIOD_M5, InpEMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   hStoch    = iStochastic(sym, PERIOD_M5, InpStoch_K, InpStoch_D, InpStoch_Slowing, MODE_SMA, STO_LOWHIGH);
   hRSI      = iRSI(sym, PERIOD_M5, InpRSI_Period, PRICE_CLOSE);
   hMACD     = iMACD(sym, PERIOD_M5, InpMACD_Fast, InpMACD_Slow, InpMACD_Signal, PRICE_CLOSE);
   hATR      = iATR(sym, PERIOD_M5, InpATR_Period);

   if(hEMA_Fast == INVALID_HANDLE || hEMA_Mid == INVALID_HANDLE || hEMA_Slow == INVALID_HANDLE ||
      hStoch == INVALID_HANDLE || hRSI == INVALID_HANDLE || hMACD == INVALID_HANDLE || hATR == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create indicator handles!");
      return INIT_FAILED;
   }

   //--- Bollinger Bands handle
   hBB = INVALID_HANDLE;
   if(InpBBEnabled)
   {
      hBB = iBands(sym, PERIOD_M5, InpBB_Period, 0, InpBB_Deviation, PRICE_CLOSE);
      if(hBB == INVALID_HANDLE)
         Print("WARNING: Failed to create Bollinger Bands handle");
   }

   //--- Keltner Channel EMA handle
   hKeltner_EMA = INVALID_HANDLE;
   if(InpKeltnerEnabled)
   {
      hKeltner_EMA = iMA(sym, PERIOD_M5, InpKeltner_EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(hKeltner_EMA == INVALID_HANDLE)
         Print("WARNING: Failed to create Keltner EMA handle");
   }

   //--- MTF indicator handles
   hEMA_H1_Fast = INVALID_HANDLE;
   hEMA_H1_Mid  = INVALID_HANDLE;
   hEMA_H4_Fast = INVALID_HANDLE;
   hEMA_H4_Mid  = INVALID_HANDLE;
   g_mtfActive  = false;

   if(InpMTFEnabled)
   {
      hEMA_H1_Fast = iMA(sym, PERIOD_H1, InpEMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
      hEMA_H1_Mid  = iMA(sym, PERIOD_H1, InpEMA_Mid,  0, MODE_EMA, PRICE_CLOSE);
      hEMA_H4_Fast = iMA(sym, PERIOD_H4, InpEMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
      hEMA_H4_Mid  = iMA(sym, PERIOD_H4, InpEMA_Mid,  0, MODE_EMA, PRICE_CLOSE);

      if(hEMA_H1_Fast != INVALID_HANDLE && hEMA_H1_Mid != INVALID_HANDLE &&
         hEMA_H4_Fast != INVALID_HANDLE && hEMA_H4_Mid != INVALID_HANDLE)
      {
         g_mtfActive = true;
      }
      else
      {
         Print("WARNING: Failed to create MTF indicator handles. MTF disabled.");
      }
   }

   //--- DOM subscription
   if(InpDOMEnabled)
   {
      g_domAvailable = MarketBookAdd(sym);
      if(!g_domAvailable)
         Print("WARNING: DOM data not available for ", sym, ". DOM filter disabled.");
   }

   //--- Initialize ATR history array
   ArrayResize(g_atrHistory, g_atrHistorySize);
   ArrayInitialize(g_atrHistory, 0);

   //--- Initialize partial TP tracking
   ArrayResize(g_partialTPDone, 0);
   g_partialTPCount = 0;

   //--- Reset daily counters
   ResetDailyCounters();

   //--- Initialize dashboard
   if(InpDashEnabled)
      CreateDashboard();

   Print("XAUUSD Scalper v2.0.0 initialized on ", sym, " | Magic: ", InpMagicNumber);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| DEINITIALIZATION                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release M5 indicator handles
   if(hEMA_Fast != INVALID_HANDLE)  IndicatorRelease(hEMA_Fast);
   if(hEMA_Mid  != INVALID_HANDLE)  IndicatorRelease(hEMA_Mid);
   if(hEMA_Slow != INVALID_HANDLE)  IndicatorRelease(hEMA_Slow);
   if(hStoch    != INVALID_HANDLE)  IndicatorRelease(hStoch);
   if(hRSI      != INVALID_HANDLE)  IndicatorRelease(hRSI);
   if(hMACD     != INVALID_HANDLE)  IndicatorRelease(hMACD);
   if(hATR      != INVALID_HANDLE)  IndicatorRelease(hATR);

   //--- Release new indicator handles
   if(hBB != INVALID_HANDLE)           IndicatorRelease(hBB);
   if(hKeltner_EMA != INVALID_HANDLE)  IndicatorRelease(hKeltner_EMA);

   //--- Release MTF handles
   if(hEMA_H1_Fast != INVALID_HANDLE) IndicatorRelease(hEMA_H1_Fast);
   if(hEMA_H1_Mid  != INVALID_HANDLE) IndicatorRelease(hEMA_H1_Mid);
   if(hEMA_H4_Fast != INVALID_HANDLE) IndicatorRelease(hEMA_H4_Fast);
   if(hEMA_H4_Mid  != INVALID_HANDLE) IndicatorRelease(hEMA_H4_Mid);

   //--- Unsubscribe DOM
   if(InpDOMEnabled && g_domAvailable)
      MarketBookRelease(_Symbol);

   //--- Remove dashboard objects
   DeleteDashboard();

   //--- Remove arrow objects
   if(InpArrowsEnabled)
   {
      int total = ObjectsTotal(0, 0, -1);
      for(int i = total - 1; i >= 0; i--)
      {
         string name = ObjectName(0, i);
         if(StringFind(name, g_arrowPrefix) >= 0)
            ObjectDelete(0, name);
      }
   }

   Print("XAUUSD Scalper deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| MAIN TICK HANDLER                                                 |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check for new day — reset daily counters
   MqlDateTime dtNow;
   TimeCurrent(dtNow);
   datetime todayStart = StringToTime(IntegerToString(dtNow.year) + "." +
                         IntegerToString(dtNow.mon) + "." +
                         IntegerToString(dtNow.day));
   if(todayStart != g_lastDayReset)
   {
      ResetDailyCounters();
      g_lastDayReset = todayStart;
   }

   //--- Update daily P&L from closed positions
   UpdateDailyPnL();

   //--- Circuit breaker check
   if(g_circuitBreaker)
   {
      ManageOpenPositions();
      if(InpDashEnabled) UpdateDashboard();
      return;
   }

   //--- Check drawdown circuit breaker
   if(CheckDrawdownBreaker())
   {
      g_circuitBreaker = true;
      Print("CIRCUIT BREAKER: Max drawdown exceeded. Trading halted for today.");
      if(InpDashEnabled) UpdateDashboard();
      return;
   }

   //--- Daily loss cap
   if(g_dailyPnL <= -InpDailyLossCapUSD)
   {
      g_circuitBreaker = true;
      Print("DAILY LOSS CAP: $", DoubleToString(InpDailyLossCapUSD, 2), " reached. Trading halted.");
      if(InpDashEnabled) UpdateDashboard();
      return;
   }

   //--- Manage open positions (trailing, breakeven, partial TP)
   ManageOpenPositions();

   //--- Check for re-open logic
   int openCount = CountMyPositions();
   if(InpReopenOnClose && openCount < g_lastPositionCount && openCount < InpMaxPositions)
   {
      // A position was closed — we may want to re-open if conditions still valid
      // This is handled by the normal entry logic below
   }
   g_lastPositionCount = openCount;

   //--- Only evaluate new entries on new M5 bar
   datetime barTime = iTime(_Symbol, PERIOD_M5, 0);
   if(barTime == g_lastBarTime)
   {
      if(InpDashEnabled) UpdateDashboard();
      return;
   }
   g_lastBarTime = barTime;

   //--- Update ATR history for regime classification
   UpdateATRHistory();

   //--- Update VWAP
   if(InpVWAPEnabled)
      UpdateVWAP();

   //--- Update Linear Regression
   if(InpLinRegEnabled)
      CalculateLinearRegression();

   //--- Session filter
   if(!IsSessionAllowed())
   {
      if(InpDashEnabled) UpdateDashboard();
      return;
   }

   //--- Max positions check
   if(openCount >= InpMaxPositions)
   {
      if(InpDashEnabled) UpdateDashboard();
      return;
   }

   //--- Read indicator values
   double emaFast[], emaMid[], emaSlow[];
   double stochK[], stochD[];
   double rsiVal[];
   double macdMain[], macdSignal[];
   double atrVal[];

   if(CopyBuffer(hEMA_Fast, 0, 0, 3, emaFast) < 3) return;
   if(CopyBuffer(hEMA_Mid,  0, 0, 3, emaMid)  < 3) return;
   if(CopyBuffer(hEMA_Slow, 0, 0, 3, emaSlow) < 3) return;
   if(CopyBuffer(hStoch,    0, 0, 3, stochK)   < 3) return;
   if(CopyBuffer(hStoch,    1, 0, 3, stochD)   < 3) return;
   if(CopyBuffer(hRSI,      0, 0, 3, rsiVal)   < 3) return;
   if(CopyBuffer(hMACD,     0, 0, 3, macdMain) < 3) return;
   if(CopyBuffer(hMACD,     1, 0, 3, macdSignal)< 3) return;
   if(CopyBuffer(hATR,      0, 0, 3, atrVal)   < 3) return;

   //--- Use bar [1] (completed bar) for signals
   double ema20  = emaFast[1];
   double ema50  = emaMid[1];
   double ema200 = emaSlow[1];
   double sk     = stochK[1];
   double sk_prev= stochK[2];
   double sd     = stochD[1];
   double sd_prev= stochD[2];
   double rsi    = rsiVal[1];
   double macd_h = macdMain[1] - macdSignal[1]; // histogram
   double atr    = atrVal[1];

   //--- ATR volatility filter
   if(atr < InpATR_Min || atr > InpATR_Max)
   {
      if(InpDashEnabled) UpdateDashboard();
      return;
   }

   //--- Determine trend direction via EMA cascade
   int trendDir = GetTrendDirection(ema20, ema50, ema200);
   if(trendDir == 0)
   {
      if(InpDashEnabled) UpdateDashboard();
      return; // No clear trend
   }

   //--- MTF mandatory filter
   if(g_mtfActive && InpMTFMandatory)
   {
      if(!CheckMTFAlignment(trendDir))
      {
         if(InpDashEnabled) UpdateDashboard();
         return;
      }
   }

   //--- Calculate confluence score
   int confluenceScore = 0;
   string signalDetails = "";

   //--- 1. Stochastic signal
   if(trendDir > 0) // BUY trend
   {
      // Buy on oversold cross-up
      if(sk_prev < InpStoch_Oversold && sk > sd && sk_prev <= sd_prev)
      {
         confluenceScore++;
         signalDetails += "Stoch+ ";
      }
   }
   else // SELL trend
   {
      // Sell on overbought cross-down
      if(sk_prev > InpStoch_Overbought && sk < sd && sk_prev >= sd_prev)
      {
         confluenceScore++;
         signalDetails += "Stoch+ ";
      }
   }

   //--- 2. RSI filter
   if(trendDir > 0 && rsi >= InpRSI_BuyLow && rsi <= InpRSI_BuyHigh)
   {
      confluenceScore++;
      signalDetails += "RSI+ ";
   }
   else if(trendDir < 0 && rsi >= InpRSI_SellLow && rsi <= InpRSI_SellHigh)
   {
      confluenceScore++;
      signalDetails += "RSI+ ";
   }

   //--- 3. MACD histogram alignment
   if((trendDir > 0 && macd_h > 0) || (trendDir < 0 && macd_h < 0))
   {
      confluenceScore++;
      signalDetails += "MACD+ ";
   }

   //--- 4. Volume filter
   if(CheckVolumeFilter())
   {
      confluenceScore++;
      signalDetails += "VOL+ ";
   }

   //--- 5. Advanced Math signals
   double close1 = iClose(_Symbol, PERIOD_M5, 1);

   // Fibonacci proximity
   if(InpFibEnabled && CheckFibProximity(trendDir))
   {
      confluenceScore++;
      signalDetails += "FIB+ ";
   }

   // Z-Score
   if(InpZScoreEnabled && CheckZScore(close1, ema50, trendDir))
   {
      confluenceScore++;
      signalDetails += "ZSCORE+ ";
   }

   // Price Action Patterns
   if(InpPriceActionEnabled && CheckPriceAction(trendDir))
   {
      confluenceScore++;
      signalDetails += "PA+ ";
   }

   //--- 6. Bollinger Bands proximity
   if(InpBBEnabled && hBB != INVALID_HANDLE && CheckBollingerBands(trendDir))
   {
      confluenceScore++;
      signalDetails += "BB+ ";
   }

   //--- 7. VWAP alignment
   if(InpVWAPEnabled && CheckVWAP(trendDir))
   {
      confluenceScore++;
      signalDetails += "VWAP+ ";
   }

   //--- 8. Linear Regression Channel
   if(InpLinRegEnabled && CheckLinearRegression(trendDir))
   {
      confluenceScore++;
      signalDetails += "LINREG+ ";
   }

   //--- 9. Keltner Channel breakout
   if(InpKeltnerEnabled && hKeltner_EMA != INVALID_HANDLE && CheckKeltnerChannel(trendDir))
   {
      confluenceScore++;
      signalDetails += "KC+ ";
   }

   //--- 10. MTF Alignment (as confluence point, not mandatory)
   if(g_mtfActive && !InpMTFMandatory)
   {
      if(CheckMTFAlignment(trendDir))
      {
         confluenceScore++;
         signalDetails += "MTF+ ";
      }
   }

   //--- ATR Regime weight scaling
   if(InpATRRegimeEnabled)
   {
      int regime = GetATRRegime(atr);
      if(regime == 2) // Medium — ideal
         confluenceScore++;
   }

   //--- Check minimum confluence
   if(confluenceScore < InpMinConfluence)
   {
      if(InpDashEnabled) UpdateDashboard();
      return;
   }

   //--- DOM filter
   if(InpDOMEnabled && g_domAvailable)
   {
      if(!CheckDOMImbalance(trendDir))
      {
         if(InpDashEnabled) UpdateDashboard();
         return;
      }
      signalDetails += "DOM+ ";
   }

   //--- Spread check
   double spread = symInfo.Spread() * _Point;
   if(spread > atr * 0.3) // Spread too wide relative to ATR
   {
      if(InpDashEnabled) UpdateDashboard();
      return;
   }

   //--- All filters passed — OPEN TRADE
   OpenTrade(trendDir, confluenceScore, signalDetails);

   //--- Update dashboard
   if(InpDashEnabled) UpdateDashboard();
}

//+------------------------------------------------------------------+
//| TREND DIRECTION — EMA CASCADE                                     |
//+------------------------------------------------------------------+
int GetTrendDirection(double ema20, double ema50, double ema200)
{
   // Strong bullish: EMA20 > EMA50 > EMA200
   if(ema20 > ema50 && ema50 > ema200)
      return 1; // BUY

   // Strong bearish: EMA20 < EMA50 < EMA200
   if(ema20 < ema50 && ema50 < ema200)
      return -1; // SELL

   return 0; // No clear trend
}

//+------------------------------------------------------------------+
//| MTF TREND DETECTION                                               |
//+------------------------------------------------------------------+
int GetMTFTrend(int hFast, int hMid)
{
   double fast[], mid[];
   if(CopyBuffer(hFast, 0, 1, 1, fast) < 1) return 0;
   if(CopyBuffer(hMid,  0, 1, 1, mid)  < 1) return 0;

   if(fast[0] > mid[0]) return  1;  // Bullish
   if(fast[0] < mid[0]) return -1;  // Bearish
   return 0;                         // Flat
}

bool CheckMTFAlignment(int m5TrendDir)
{
   g_mtfH1Trend = GetMTFTrend(hEMA_H1_Fast, hEMA_H1_Mid);
   g_mtfH4Trend = GetMTFTrend(hEMA_H4_Fast, hEMA_H4_Mid);

   // All three timeframes must agree
   return (m5TrendDir == g_mtfH1Trend && m5TrendDir == g_mtfH4Trend);
}

//+------------------------------------------------------------------+
//| SESSION FILTER                                                    |
//+------------------------------------------------------------------+
bool IsSessionAllowed()
{
   MqlDateTime dt;
   TimeCurrent(dt);

   // Convert broker time to IST (GMT+5:30)
   datetime brokerTime = TimeCurrent();
   int brokerOffsetSec = InpGMTOffset * 3600 + InpGMTOffsetMin * 60;
   int istOffsetSec    = 5 * 3600 + 30 * 60;
   datetime istTime    = brokerTime + (istOffsetSec - brokerOffsetSec);

   MqlDateTime istDt;
   TimeToStruct(istTime, istDt);

   int istMinutes = istDt.hour * 60 + istDt.min;

   //--- No trading on weekends
   if(istDt.day_of_week == 0 || istDt.day_of_week == 6)
      return false;

   //--- Friday close avoidance
   if(InpAvoidFridayClose && istDt.day_of_week == 5)
   {
      int fridayStop = ParseTimeToMinutes(InpFridayStopTime);
      if(istMinutes >= fridayStop)
         return false;
   }

   //--- Monday open avoidance
   if(InpAvoidMondayOpen && istDt.day_of_week == 1)
   {
      int mondayStart = ParseTimeToMinutes(InpMondayStartTime);
      if(istMinutes < mondayStart)
         return false;
   }

   //--- Check if within preferred session windows (London or NY)
   int londonStart = ParseTimeToMinutes(InpLondonStart);
   int londonEnd   = ParseTimeToMinutes(InpLondonEnd);
   int nyStart     = ParseTimeToMinutes(InpNYStart);
   int nyEnd       = ParseTimeToMinutes(InpNYEnd);

   bool inLondon = (istMinutes >= londonStart && istMinutes <= londonEnd);
   bool inNY     = (istMinutes >= nyStart && istMinutes <= nyEnd);

   // Allow trading during any part of the day, but boost confidence during sessions
   // For now, we allow all trading hours (01:03 to 23:57 IST)
   if(istMinutes < 63 || istMinutes > 1437) // Before 01:03 or after 23:57
      return false;

   return true;
}

//--- Parse "HH:MM" string to total minutes
int ParseTimeToMinutes(string timeStr)
{
   int colonPos = StringFind(timeStr, ":");
   if(colonPos < 0) return 0;
   int hrs = (int)StringToInteger(StringSubstr(timeStr, 0, colonPos));
   int mins = (int)StringToInteger(StringSubstr(timeStr, colonPos + 1));
   return hrs * 60 + mins;
}

//+------------------------------------------------------------------+
//| VOLUME FILTER                                                     |
//+------------------------------------------------------------------+
bool CheckVolumeFilter()
{
   //--- Get tick volumes for last 20 bars
   long volumes[];
   if(CopyTickVolume(_Symbol, PERIOD_M5, 0, 21, volumes) < 21)
      return true; // Can't check, allow

   //--- Average of bars 1-20 (skip current bar 0)
   double avgVol = 0;
   for(int i = 1; i < 21; i++)
      avgVol += (double)volumes[i];
   avgVol /= 20.0;

   //--- Current bar volume > multiplier * average
   return ((double)volumes[0] >= InpVolMultiplier * avgVol);
}

//+------------------------------------------------------------------+
//| DOM IMBALANCE CHECK                                               |
//+------------------------------------------------------------------+
bool CheckDOMImbalance(int trendDir)
{
   MqlBookInfo book[];
   if(!MarketBookGet(_Symbol, book))
      return true; // Can't read, allow

   int total = ArraySize(book);
   if(total < 2)
      return true;

   double bidVolume = 0, askVolume = 0;
   for(int i = 0; i < total; i++)
   {
      if(book[i].type == BOOK_TYPE_BUY || book[i].type == BOOK_TYPE_BUY_MARKET)
         bidVolume += book[i].volume_real;
      else if(book[i].type == BOOK_TYPE_SELL || book[i].type == BOOK_TYPE_SELL_MARKET)
         askVolume += book[i].volume_real;
   }

   if(bidVolume <= 0 || askVolume <= 0)
      return true;

   //--- For BUY: bid volume should dominate (buyers are strong)
   if(trendDir > 0)
      return (bidVolume / askVolume >= InpDOMImbalanceRatio);

   //--- For SELL: ask volume should dominate (sellers are strong)
   if(trendDir < 0)
      return (askVolume / bidVolume >= InpDOMImbalanceRatio);

   return false;
}

//+------------------------------------------------------------------+
//| FIBONACCI PROXIMITY CHECK                                         |
//+------------------------------------------------------------------+
bool CheckFibProximity(int trendDir)
{
   //--- Find recent swing high/low over last 50 bars
   double highs[], lows[];
   if(CopyHigh(_Symbol, PERIOD_M5, 1, 50, highs) < 50) return false;
   if(CopyLow(_Symbol, PERIOD_M5, 1, 50, lows) < 50) return false;

   double swingHigh = highs[ArrayMaximum(highs)];
   double swingLow  = lows[ArrayMinimum(lows)];
   double range     = swingHigh - swingLow;

   if(range < _Point * 10)
      return false;

   double close1 = iClose(_Symbol, PERIOD_M5, 1);
   double tolerance = range * 0.02; // 2% of range

   for(int i = 0; i < ArraySize(g_fibLevels); i++)
   {
      double fibPrice;
      if(trendDir > 0) // Uptrend — look for retracement support
         fibPrice = swingHigh - range * g_fibLevels[i];
      else             // Downtrend — look for retracement resistance
         fibPrice = swingLow + range * g_fibLevels[i];

      if(MathAbs(close1 - fibPrice) <= tolerance)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Z-SCORE CHECK                                                     |
//+------------------------------------------------------------------+
bool CheckZScore(double price, double ema50, int trendDir)
{
   //--- Rolling Z-score of price deviation from EMA50
   double closes[];
   if(CopyClose(_Symbol, PERIOD_M5, 1, 50, closes) < 50) return false;

   double emaValues[];
   if(CopyBuffer(hEMA_Mid, 0, 1, 50, emaValues) < 50) return false;

   //--- Calculate deviations
   double deviations[];
   ArrayResize(deviations, 50);
   double sumDev = 0, sumDevSq = 0;

   for(int i = 0; i < 50; i++)
   {
      deviations[i] = closes[i] - emaValues[i];
      sumDev += deviations[i];
      sumDevSq += deviations[i] * deviations[i];
   }

   double meanDev = sumDev / 50.0;
   double stdDev  = MathSqrt(sumDevSq / 50.0 - meanDev * meanDev);

   if(stdDev < _Point)
      return false;

   double currentDev = price - ema50;
   double zScore = (currentDev - meanDev) / stdDev;

   //--- For BUY: price should be significantly below mean (pullback)
   if(trendDir > 0 && zScore < -InpZScoreThreshold)
      return true;

   //--- For SELL: price should be significantly above mean (pullback)
   if(trendDir < 0 && zScore > InpZScoreThreshold)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| ATR REGIME CLASSIFICATION                                         |
//+------------------------------------------------------------------+
void UpdateATRHistory()
{
   double atrBuf[];
   if(CopyBuffer(hATR, 0, 1, 1, atrBuf) < 1) return;

   //--- Shift array and add new value
   for(int i = g_atrHistorySize - 1; i > 0; i--)
      g_atrHistory[i] = g_atrHistory[i - 1];
   g_atrHistory[0] = atrBuf[0];
}

int GetATRRegime(double currentATR)
{
   //--- Count how many historical ATRs are below current
   int below = 0;
   int valid = 0;
   for(int i = 0; i < g_atrHistorySize; i++)
   {
      if(g_atrHistory[i] > 0)
      {
         valid++;
         if(g_atrHistory[i] < currentATR)
            below++;
      }
   }

   if(valid < 20) return 2; // Not enough data, assume medium

   double percentile = (double)below / (double)valid * 100.0;

   if(percentile < 33.0) return 1;  // Low volatility
   if(percentile < 66.0) return 2;  // Medium (ideal)
   return 3;                         // High volatility
}

//+------------------------------------------------------------------+
//| PRICE ACTION PATTERN DETECTION                                    |
//+------------------------------------------------------------------+
bool CheckPriceAction(int trendDir)
{
   double open1  = iOpen(_Symbol, PERIOD_M5, 1);
   double close1 = iClose(_Symbol, PERIOD_M5, 1);
   double high1  = iHigh(_Symbol, PERIOD_M5, 1);
   double low1   = iLow(_Symbol, PERIOD_M5, 1);

   double open2  = iOpen(_Symbol, PERIOD_M5, 2);
   double close2 = iClose(_Symbol, PERIOD_M5, 2);
   double high2  = iHigh(_Symbol, PERIOD_M5, 2);
   double low2   = iLow(_Symbol, PERIOD_M5, 2);

   double body1 = MathAbs(close1 - open1);
   double body2 = MathAbs(close2 - open2);
   double range1 = high1 - low1;
   double range2 = high2 - low2;

   if(range1 < _Point || range2 < _Point)
      return false;

   //--- Pin Bar detection
   if(trendDir > 0) // Bullish pin bar
   {
      double lowerWick = MathMin(open1, close1) - low1;
      double upperWick = high1 - MathMax(open1, close1);
      if(lowerWick > body1 * 2.0 && lowerWick > upperWick * 2.0)
         return true;
   }
   else // Bearish pin bar
   {
      double upperWick = high1 - MathMax(open1, close1);
      double lowerWick = MathMin(open1, close1) - low1;
      if(upperWick > body1 * 2.0 && upperWick > lowerWick * 2.0)
         return true;
   }

   //--- Engulfing pattern
   if(trendDir > 0) // Bullish engulfing
   {
      if(close2 < open2 && close1 > open1 && // prev bearish, current bullish
         close1 > open2 && open1 < close2)     // current body engulfs prev
         return true;
   }
   else // Bearish engulfing
   {
      if(close2 > open2 && close1 < open1 && // prev bullish, current bearish
         close1 < open2 && open1 > close2)     // current body engulfs prev
         return true;
   }

   //--- Inside Bar breakout
   if(high1 < high2 && low1 > low2) // Bar 1 is inside bar 2
   {
      double close0 = iClose(_Symbol, PERIOD_M5, 0); // Current forming bar
      if(trendDir > 0 && close0 > high1)  return true; // Breakout up
      if(trendDir < 0 && close0 < low1)   return true; // Breakout down
   }

   return false;
}

//+------------------------------------------------------------------+
//| BOLLINGER BANDS CHECK                                             |
//+------------------------------------------------------------------+
bool CheckBollingerBands(int trendDir)
{
   double upper[], lower[], middle[];
   if(CopyBuffer(hBB, 1, 1, 1, upper) < 1) return false;   // Upper band = buffer 1
   if(CopyBuffer(hBB, 2, 1, 1, lower) < 1) return false;   // Lower band = buffer 2
   if(CopyBuffer(hBB, 0, 1, 1, middle) < 1) return false;  // Middle = buffer 0

   double close1 = iClose(_Symbol, PERIOD_M5, 1);
   double bandWidth = upper[0] - lower[0];
   if(bandWidth <= 0) return false;

   double proximity = bandWidth * InpBB_ProximityPct;

   // BUY: price near lower band in uptrend (pullback to support)
   if(trendDir > 0 && close1 <= lower[0] + proximity)
      return true;

   // SELL: price near upper band in downtrend (pullback to resistance)
   if(trendDir < 0 && close1 >= upper[0] - proximity)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| VWAP CALCULATION & CHECK                                          |
//+------------------------------------------------------------------+
void UpdateVWAP()
{
   //--- Check if we need to reset (new day)
   MqlDateTime dtNow;
   TimeCurrent(dtNow);
   datetime todayStart = StringToTime(IntegerToString(dtNow.year) + "." +
                         IntegerToString(dtNow.mon) + "." +
                         IntegerToString(dtNow.day));

   if(todayStart != g_vwapResetTime)
   {
      g_vwapSumPV  = 0;
      g_vwapSumVol = 0;
      g_vwapResetTime = todayStart;

      // Recalculate from today's bars
      int barsToday = iBarShift(_Symbol, PERIOD_M5, todayStart, false);
      if(barsToday <= 0) barsToday = 1;
      if(barsToday > 500) barsToday = 500; // safety cap

      for(int i = barsToday; i >= 1; i--)
      {
         double typicalPrice = (iHigh(_Symbol, PERIOD_M5, i) +
                                iLow(_Symbol, PERIOD_M5, i) +
                                iClose(_Symbol, PERIOD_M5, i)) / 3.0;
         long vol[];
         if(CopyTickVolume(_Symbol, PERIOD_M5, i, 1, vol) >= 1 && vol[0] > 0)
         {
            g_vwapSumPV  += typicalPrice * (double)vol[0];
            g_vwapSumVol += (double)vol[0];
         }
      }
   }
   else
   {
      // Add latest completed bar (bar 1)
      double typicalPrice = (iHigh(_Symbol, PERIOD_M5, 1) +
                             iLow(_Symbol, PERIOD_M5, 1) +
                             iClose(_Symbol, PERIOD_M5, 1)) / 3.0;
      long vol[];
      if(CopyTickVolume(_Symbol, PERIOD_M5, 1, 1, vol) >= 1 && vol[0] > 0)
      {
         g_vwapSumPV  += typicalPrice * (double)vol[0];
         g_vwapSumVol += (double)vol[0];
      }
   }

   if(g_vwapSumVol > 0)
      g_vwapValue = g_vwapSumPV / g_vwapSumVol;
}

bool CheckVWAP(int trendDir)
{
   if(g_vwapValue <= 0) return false;

   double close1 = iClose(_Symbol, PERIOD_M5, 1);

   // BUY: price above VWAP in uptrend
   if(trendDir > 0 && close1 > g_vwapValue)
      return true;

   // SELL: price below VWAP in downtrend
   if(trendDir < 0 && close1 < g_vwapValue)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| LINEAR REGRESSION CHANNEL                                         |
//+------------------------------------------------------------------+
void CalculateLinearRegression()
{
   int period = InpLinReg_Period;
   double closes[];
   if(CopyClose(_Symbol, PERIOD_M5, 1, period, closes) < period) return;

   // Least squares: y = mx + b
   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   for(int i = 0; i < period; i++)
   {
      double x = (double)i;
      sumX  += x;
      sumY  += closes[i];
      sumXY += x * closes[i];
      sumX2 += x * x;
   }

   double n = (double)period;
   double denom = n * sumX2 - sumX * sumX;
   if(MathAbs(denom) < 1e-10) return;

   g_linRegSlope     = (n * sumXY - sumX * sumY) / denom;
   g_linRegIntercept = (sumY - g_linRegSlope * sumX) / n;

   // Center value at most recent bar (x = period-1)
   g_linRegCenter = g_linRegSlope * (double)(period - 1) + g_linRegIntercept;

   // Standard deviation of residuals
   double sumResidSq = 0;
   for(int i = 0; i < period; i++)
   {
      double predicted = g_linRegSlope * (double)i + g_linRegIntercept;
      double resid = closes[i] - predicted;
      sumResidSq += resid * resid;
   }
   double stdDev = MathSqrt(sumResidSq / n);

   g_linRegUpper = g_linRegCenter + stdDev * InpLinReg_DevMult;
   g_linRegLower = g_linRegCenter - stdDev * InpLinReg_DevMult;
}

bool CheckLinearRegression(int trendDir)
{
   if(g_linRegCenter <= 0) return false;

   double close1 = iClose(_Symbol, PERIOD_M5, 1);
   double channelWidth = g_linRegUpper - g_linRegLower;
   if(channelWidth <= 0) return false;

   double proximity = channelWidth * 0.1; // Within 10% of channel boundary

   // Trend strength: slope must align with direction
   if(trendDir > 0 && g_linRegSlope <= 0) return false;
   if(trendDir < 0 && g_linRegSlope >= 0) return false;

   // BUY: price near lower channel in uptrend
   if(trendDir > 0 && close1 <= g_linRegLower + proximity)
      return true;

   // SELL: price near upper channel in downtrend
   if(trendDir < 0 && close1 >= g_linRegUpper - proximity)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| KELTNER CHANNEL CHECK                                             |
//+------------------------------------------------------------------+
bool CheckKeltnerChannel(int trendDir)
{
   double keltnerEMA[];
   double atrBuf[];

   if(CopyBuffer(hKeltner_EMA, 0, 1, 1, keltnerEMA) < 1) return false;
   if(CopyBuffer(hATR, 0, 1, 1, atrBuf) < 1) return false;

   double upperKC = keltnerEMA[0] + InpKeltner_ATRMult * atrBuf[0];
   double lowerKC = keltnerEMA[0] - InpKeltner_ATRMult * atrBuf[0];

   double close1 = iClose(_Symbol, PERIOD_M5, 1);

   // Breakout confirmation: price breaking above upper = strong buy momentum
   if(trendDir > 0 && close1 > upperKC)
      return true;

   // Breakout confirmation: price breaking below lower = strong sell momentum
   if(trendDir < 0 && close1 < lowerKC)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| DYNAMIC LOT SIZING                                                |
//+------------------------------------------------------------------+
double CalculateDynamicLotSize(double slDistanceUSD)
{
   if(!InpUseDynamicLots || slDistanceUSD <= 0)
      return VerifyLotSize(InpLotSize);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * (InpRiskPercent / 100.0);

   // lotSize = riskAmount / SL_per_lot
   double lotSize = riskAmount / slDistanceUSD;

   return VerifyLotSize(lotSize);
}

double VerifyLotSize(double lots)
{
   double minVol  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   // Apply user overrides
   if(InpMinLotOverride > 0) minVol = MathMax(minVol, InpMinLotOverride);
   if(InpMaxLotOverride > 0) maxVol = MathMin(maxVol, InpMaxLotOverride);

   // Clamp
   if(lots < minVol) lots = minVol;
   if(lots > maxVol) lots = maxVol;

   // Round down to step
   if(stepVol > 0)
      lots = MathFloor(lots / stepVol) * stepVol;

   // Normalize
   if(stepVol >= 0.1)
      lots = NormalizeDouble(lots, 1);
   else
      lots = NormalizeDouble(lots, 2);

   return lots;
}

//+------------------------------------------------------------------+
//| OPEN TRADE                                                        |
//+------------------------------------------------------------------+
void OpenTrade(int direction, int confluenceScore, string signalDetails)
{
   symInfo.RefreshRates();

   double price, sl, tp;
   ENUM_ORDER_TYPE orderType;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   if(tickValue <= 0 || tickSize <= 0)
   {
      Print("ERROR: Invalid tick value/size. Cannot calculate SL/TP.");
      return;
   }

   double slDistancePrice, tpDistancePrice;
   double slDistanceUSD;

   if(InpDynamicSLTP)
   {
      //--- ATR-based SL/TP
      double atrBuf[];
      if(CopyBuffer(hATR, 0, 1, 1, atrBuf) < 1)
      {
         Print("ERROR: Cannot read ATR for dynamic SL/TP");
         return;
      }
      slDistancePrice = atrBuf[0] * InpSL_ATR_Mult;
      tpDistancePrice = atrBuf[0] * InpTP_ATR_Mult;

      // Calculate USD equivalent for lot sizing
      slDistanceUSD = (slDistancePrice / tickSize) * tickValue;
   }
   else
   {
      //--- Fixed USD SL/TP (original behavior)
      slDistanceUSD = InpSL_USD;
      slDistancePrice = (InpSL_USD / (tickValue / tickSize));
      tpDistancePrice = (InpTP_USD / (tickValue / tickSize));
   }

   //--- Calculate lot size (dynamic or fixed)
   double lotSize = CalculateDynamicLotSize(slDistanceUSD);
   g_calculatedLotSize = lotSize;

   if(direction > 0) // BUY
   {
      price = symInfo.Ask();
      sl    = NormalizeDouble(price - slDistancePrice, digits);
      tp    = NormalizeDouble(price + tpDistancePrice, digits);
      orderType = ORDER_TYPE_BUY;
   }
   else // SELL
   {
      price = symInfo.Bid();
      sl    = NormalizeDouble(price + slDistancePrice, digits);
      tp    = NormalizeDouble(price - tpDistancePrice, digits);
      orderType = ORDER_TYPE_SELL;
   }

   //--- Send order
   string comment = InpEAComment + "|C" + IntegerToString(confluenceScore);
   if(trade.PositionOpen(_Symbol, orderType, lotSize, price, sl, tp, comment))
   {
      g_dailyTradeCount++;

      //--- Draw entry arrow on chart
      DrawEntryArrow(trade.ResultOrder(), direction, price, TimeCurrent());

      Print("TRADE OPENED: ", (direction > 0 ? "BUY" : "SELL"),
            " @ ", DoubleToString(price, digits),
            " Lots:", DoubleToString(lotSize, 2),
            " SL:", DoubleToString(sl, digits),
            " TP:", DoubleToString(tp, digits),
            " Confluence:", confluenceScore,
            " [", signalDetails, "]");

      //--- CSV Log
      if(InpCSVEnabled)
         LogTradeToCSV("OPEN", direction, price, sl, tp, confluenceScore, signalDetails);
   }
   else
   {
      Print("TRADE FAILED: Error ", trade.ResultRetcode(), " - ", trade.ResultComment());
   }
}

//+------------------------------------------------------------------+
//| MANAGE OPEN POSITIONS — TRAILING, BREAKEVEN, PARTIAL TP           |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   //--- Get current ATR for trailing
   double atrBuf[];
   double currentATR = 0;
   if(CopyBuffer(hATR, 0, 1, 1, atrBuf) >= 1)
      currentATR = atrBuf[0];

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != InpMagicNumber) continue;
      if(posInfo.Symbol() != _Symbol) continue;

      double openPrice  = posInfo.PriceOpen();
      double currentSL  = posInfo.StopLoss();
      double currentTP  = posInfo.TakeProfit();
      double profit     = posInfo.Profit();
      ulong  ticket     = posInfo.Ticket();
      ENUM_POSITION_TYPE posType = posInfo.PositionType();

      //--- Partial Take Profit
      if(InpPartialTP && InpDynamicSLTP && currentATR > 0)
      {
         bool alreadyPartial = false;
         for(int p = 0; p < g_partialTPCount; p++)
         {
            if(g_partialTPDone[p] == ticket)
            {
               alreadyPartial = true;
               break;
            }
         }

         if(!alreadyPartial)
         {
            double tp1Distance = currentATR * InpTP1_ATR_Mult;
            symInfo.RefreshRates();
            double currentPrice = (posType == POSITION_TYPE_BUY) ? symInfo.Bid() : symInfo.Ask();
            double profitDistance;

            if(posType == POSITION_TYPE_BUY)
               profitDistance = currentPrice - openPrice;
            else
               profitDistance = openPrice - currentPrice;

            if(profitDistance >= tp1Distance)
            {
               double volume = posInfo.Volume();
               double closeVol = NormalizeDouble(volume * (InpPartialTPPercent / 100.0), 2);
               closeVol = VerifyLotSize(closeVol);

               double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
               double remainVol = volume - closeVol;

               if(closeVol >= minVol && remainVol >= minVol)
               {
                  if(trade.PositionClosePartial(ticket, closeVol))
                  {
                     Print("PARTIAL TP: Closed ", DoubleToString(closeVol, 2),
                           " lots of ticket #", ticket);

                     g_partialTPCount++;
                     ArrayResize(g_partialTPDone, g_partialTPCount);
                     g_partialTPDone[g_partialTPCount - 1] = ticket;

                     // Move SL to breakeven on remainder
                     double beBuffer = tickSize * 2;
                     double beSL;
                     if(posType == POSITION_TYPE_BUY)
                        beSL = NormalizeDouble(openPrice + beBuffer, digits);
                     else
                        beSL = NormalizeDouble(openPrice - beBuffer, digits);

                     trade.PositionModify(ticket, beSL, currentTP);
                  }
               }
            }
         }
      }

      if(!InpUseTrailing) continue;

      //--- Breakeven logic
      if(profit >= InpBE_TriggerUSD && tickValue > 0)
      {
         double beSL;
         double beBuffer = tickSize * 2; // Small buffer above/below BE

         if(posType == POSITION_TYPE_BUY)
         {
            beSL = NormalizeDouble(openPrice + beBuffer, digits);
            if(currentSL < beSL)
            {
               if(trade.PositionModify(ticket, beSL, currentTP))
                  Print("BE applied to ticket #", ticket);
            }
         }
         else
         {
            beSL = NormalizeDouble(openPrice - beBuffer, digits);
            if(currentSL > beSL || currentSL == 0)
            {
               if(trade.PositionModify(ticket, beSL, currentTP))
                  Print("BE applied to ticket #", ticket);
            }
         }
      }

      //--- Trailing stop logic (ATR-based)
      if(currentATR > 0 && profit > InpBE_TriggerUSD * 1.5)
      {
         double trailDist = currentATR * InpTrailDistATRMult;
         symInfo.RefreshRates();

         if(posType == POSITION_TYPE_BUY)
         {
            double newSL = NormalizeDouble(symInfo.Bid() - trailDist, digits);
            if(newSL > currentSL && newSL > openPrice)
            {
               if(trade.PositionModify(ticket, newSL, currentTP))
                  Print("TRAIL: ticket #", ticket, " SL -> ", DoubleToString(newSL, digits));
            }
         }
         else
         {
            double newSL = NormalizeDouble(symInfo.Ask() + trailDist, digits);
            if((newSL < currentSL || currentSL == 0) && newSL < openPrice)
            {
               if(trade.PositionModify(ticket, newSL, currentTP))
                  Print("TRAIL: ticket #", ticket, " SL -> ", DoubleToString(newSL, digits));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| COUNT MY POSITIONS                                                |
//+------------------------------------------------------------------+
int CountMyPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() == InpMagicNumber && posInfo.Symbol() == _Symbol)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| DAILY P&L TRACKING                                                |
//+------------------------------------------------------------------+
void ResetDailyCounters()
{
   g_dailyPnL        = 0;
   g_dailyTradeCount = 0;
   g_dailyWins       = 0;
   g_dailyLosses     = 0;
   g_circuitBreaker  = false;
}

void UpdateDailyPnL()
{
   //--- Calculate P&L from history for today
   MqlDateTime dtNow;
   TimeCurrent(dtNow);
   datetime todayStart = StringToTime(IntegerToString(dtNow.year) + "." +
                         IntegerToString(dtNow.mon) + "." +
                         IntegerToString(dtNow.day));

   g_dailyPnL   = 0;
   g_dailyWins  = 0;
   g_dailyLosses= 0;

   //--- Closed deals today
   if(HistorySelect(todayStart, TimeCurrent()))
   {
      int totalDeals = HistoryDealsTotal();
      for(int i = 0; i < totalDeals; i++)
      {
         ulong dealTicket = HistoryDealGetTicket(i);
         if(dealTicket == 0) continue;
         if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != InpMagicNumber) continue;
         if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol) continue;

         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
         if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)
         {
            double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT) +
                                HistoryDealGetDouble(dealTicket, DEAL_SWAP) +
                                HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
            g_dailyPnL += dealProfit;

            if(dealProfit > 0)  g_dailyWins++;
            if(dealProfit < 0)  g_dailyLosses++;
         }
      }
   }

   //--- Add floating P&L
   double floatingPnL = GetFloatingPnL();
   // Note: daily P&L for circuit breaker is realized only
}

double GetFloatingPnL()
{
   double floating = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != InpMagicNumber || posInfo.Symbol() != _Symbol) continue;
      floating += posInfo.Profit() + posInfo.Swap();
   }
   return floating;
}

//+------------------------------------------------------------------+
//| DRAWDOWN CIRCUIT BREAKER                                          |
//+------------------------------------------------------------------+
bool CheckDrawdownBreaker()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);

   if(balance <= 0) return false;

   double drawdownPct = (balance - equity) / balance * 100.0;
   return (drawdownPct >= InpMaxDrawdownPct);
}

//+------------------------------------------------------------------+
//| CSV TRADE LOGGING                                                 |
//+------------------------------------------------------------------+
void LogTradeToCSV(string action, int direction, double price, double sl, double tp,
                   int confluence, string details)
{
   string filename = "XAUUSD_Scalper_Log.csv";
   int handle = FileOpen(filename, FILE_WRITE | FILE_READ | FILE_CSV | FILE_COMMON, ',');

   if(handle == INVALID_HANDLE)
   {
      Print("WARNING: Cannot open CSV log file");
      return;
   }

   //--- Move to end of file
   FileSeek(handle, 0, SEEK_END);

   //--- Write header if file is empty
   if(FileTell(handle) == 0)
   {
      FileWrite(handle, "DateTime", "Action", "Direction", "Price", "SL", "TP",
                "Confluence", "Details", "DailyPnL", "Balance", "LotSize");
   }

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   string dirStr = (direction > 0 ? "BUY" : "SELL");
   string dtStr  = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);

   FileWrite(handle, dtStr, action, dirStr,
             DoubleToString(price, digits),
             DoubleToString(sl, digits),
             DoubleToString(tp, digits),
             IntegerToString(confluence),
             details,
             DoubleToString(g_dailyPnL, 2),
             DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
             DoubleToString(g_calculatedLotSize, 2));

   FileClose(handle);
}

//+------------------------------------------------------------------+
//| CHART TRADE ARROWS                                                |
//+------------------------------------------------------------------+
void DrawEntryArrow(ulong ticket, int direction, double price, datetime time)
{
   if(!InpArrowsEnabled) return;

   string name = g_arrowPrefix + "ENTRY_" + IntegerToString(ticket);
   ENUM_OBJECT arrowType = (direction > 0) ? OBJ_ARROW_BUY : OBJ_ARROW_SELL;
   color arrowColor = (direction > 0) ? InpArrowBuyColor : InpArrowSellColor;

   ObjectCreate(0, name, arrowType, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, arrowColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);

   string dirStr = (direction > 0) ? "BUY" : "SELL";
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   ObjectSetString(0, name, OBJPROP_TOOLTIP,
      dirStr + " @ " + DoubleToString(price, digits) + " | #" + IntegerToString(ticket));

   ChartRedraw();
}

void DrawExitArrow(ulong ticket, double price, datetime time, double profit)
{
   if(!InpArrowsEnabled) return;

   string name = g_arrowPrefix + "EXIT_" + IntegerToString(ticket);
   color arrowColor = (profit >= 0) ? InpArrowWinColor : InpArrowLossColor;

   // Use checkmark for win, X for loss (Wingdings codes)
   int arrowCode = (profit >= 0) ? 252 : 251;

   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR, arrowColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);

   string resultStr = (profit >= 0) ? "WIN" : "LOSS";
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   ObjectSetString(0, name, OBJPROP_TOOLTIP,
      resultStr + " $" + DoubleToString(profit, 2) + " @ " + DoubleToString(price, digits));

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| ON TRADE — LOG CLOSE EVENTS & DRAW EXIT ARROWS                    |
//+------------------------------------------------------------------+
void OnTrade()
{
   //--- Check if a position was just closed
   static int lastPosCount = 0;
   int currentPosCount = CountMyPositions();

   if(currentPosCount < lastPosCount)
   {
      // A position was closed — log the last closed deal
      if(HistorySelect(TimeCurrent() - 60, TimeCurrent()))
      {
         int totalDeals = HistoryDealsTotal();
         for(int i = totalDeals - 1; i >= 0; i--)
         {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(dealTicket == 0) continue;
            if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != InpMagicNumber) continue;
            if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol) continue;

            ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
            if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)
            {
               double closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
               double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
               int dir = (HistoryDealGetInteger(dealTicket, DEAL_TYPE) == DEAL_TYPE_SELL) ? 1 : -1;
               // DEAL_TYPE_SELL closes a BUY, so original was BUY (dir=1)

               //--- Draw exit arrow
               DrawExitArrow(dealTicket, closePrice, TimeCurrent(), dealProfit);

               //--- CSV Log
               if(InpCSVEnabled)
               {
                  string result = (dealProfit >= 0) ? "WIN" : "LOSS";
                  LogTradeToCSV("CLOSE_" + result, dir, closePrice, 0, 0, 0,
                                "Profit: " + DoubleToString(dealProfit, 2));
               }

               //--- Remove from partial TP tracking
               for(int p = 0; p < g_partialTPCount; p++)
               {
                  if(g_partialTPDone[p] == dealTicket)
                  {
                     for(int q = p; q < g_partialTPCount - 1; q++)
                        g_partialTPDone[q] = g_partialTPDone[q + 1];
                     g_partialTPCount--;
                     ArrayResize(g_partialTPDone, g_partialTPCount);
                     break;
                  }
               }

               break;
            }
         }
      }
   }
   lastPosCount = currentPosCount;
}

//+------------------------------------------------------------------+
//| CHART DASHBOARD                                                   |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   DeleteDashboard(); // Clean slate
}

void DeleteDashboard()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, g_dashPrefix) >= 0)
         ObjectDelete(0, name);
   }
}

void UpdateDashboard()
{
   int x = InpDashX;
   int y = InpDashY;
   int lineHeight = 18;
   int row = 0;
   color clrProfit  = clrLimeGreen;
   color clrLoss    = clrRed;
   color clrNeutral = clrWhite;
   color clrHeader  = clrGold;

   //--- Background panel
   string bgName = g_dashPrefix + "BG";
   if(ObjectFind(0, bgName) < 0)
   {
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, 380);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, 520);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, C'30,30,30');
      ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrDimGray);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
   }
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x - 5);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y - 5);

   //--- Header
   DashLabel("HDR", "XAUUSD Scalper v2.0.0", x, y + row * lineHeight, clrHeader, 10);
   row++;
   DashLabel("LINE", "────────────────────────────────", x, y + row * lineHeight, clrDimGray, 8);
   row++;

   //--- Trend direction
   int trendDir = 0;
   double emaFast[], emaMid[], emaSlow[];
   if(CopyBuffer(hEMA_Fast, 0, 1, 1, emaFast) >= 1 &&
      CopyBuffer(hEMA_Mid,  0, 1, 1, emaMid) >= 1 &&
      CopyBuffer(hEMA_Slow, 0, 1, 1, emaSlow) >= 1)
   {
      trendDir = GetTrendDirection(emaFast[0], emaMid[0], emaSlow[0]);
   }

   string trendStr = (trendDir > 0) ? "BUY" : (trendDir < 0 ? "SELL" : "FLAT");
   color trendClr = (trendDir > 0) ? clrProfit : (trendDir < 0 ? clrLoss : clrNeutral);
   DashLabel("TREND", "M5 Trend: " + trendStr, x, y + row * lineHeight, trendClr, 9);
   row++;

   //--- MTF Trend Status
   if(g_mtfActive)
   {
      string h1Str = (g_mtfH1Trend > 0) ? "BUY" : (g_mtfH1Trend < 0 ? "SELL" : "FLAT");
      string h4Str = (g_mtfH4Trend > 0) ? "BUY" : (g_mtfH4Trend < 0 ? "SELL" : "FLAT");
      color h1Clr = (g_mtfH1Trend > 0) ? clrProfit : (g_mtfH1Trend < 0 ? clrLoss : clrNeutral);
      color h4Clr = (g_mtfH4Trend > 0) ? clrProfit : (g_mtfH4Trend < 0 ? clrLoss : clrNeutral);

      DashLabel("MTFH1", "H1 Trend: " + h1Str, x, y + row * lineHeight, h1Clr, 9);
      row++;
      DashLabel("MTFH4", "H4 Trend: " + h4Str, x, y + row * lineHeight, h4Clr, 9);
      row++;
   }

   //--- Open positions
   int openCount = CountMyPositions();
   DashLabel("OPOS", "Open Positions: " + IntegerToString(openCount) + " / " + IntegerToString(InpMaxPositions),
             x, y + row * lineHeight, clrNeutral, 9);
   row++;

   //--- Calculated Lot Size
   DashLabel("LOTS", "Lot Size: " + DoubleToString(g_calculatedLotSize, 2) +
             (InpUseDynamicLots ? " (Dynamic)" : " (Fixed)"),
             x, y + row * lineHeight, clrNeutral, 9);
   row++;

   //--- Floating P&L
   double floatPnL = GetFloatingPnL();
   color pnlClr = (floatPnL >= 0) ? clrProfit : clrLoss;
   DashLabel("FPNL", "Floating P&L: $" + DoubleToString(floatPnL, 2),
             x, y + row * lineHeight, pnlClr, 9);
   row++;

   //--- Daily P&L
   color dClr = (g_dailyPnL >= 0) ? clrProfit : clrLoss;
   DashLabel("DPNL", "Daily P&L: $" + DoubleToString(g_dailyPnL, 2),
             x, y + row * lineHeight, dClr, 9);
   row++;

   //--- Daily stats
   int totalTrades = g_dailyWins + g_dailyLosses;
   double winRate = (totalTrades > 0) ? (double)g_dailyWins / totalTrades * 100.0 : 0;
   DashLabel("WR", "Win Rate: " + DoubleToString(winRate, 1) + "% (" +
             IntegerToString(g_dailyWins) + "W / " + IntegerToString(g_dailyLosses) + "L)",
             x, y + row * lineHeight, clrNeutral, 9);
   row++;

   //--- ATR
   double atrDashVal[];
   double atr = 0;
   if(CopyBuffer(hATR, 0, 1, 1, atrDashVal) >= 1)
      atr = atrDashVal[0];
   DashLabel("ATR", "ATR(14): $" + DoubleToString(atr, 2),
             x, y + row * lineHeight, clrNeutral, 9);
   row++;

   //--- ATR Regime
   string regimeStr = "N/A";
   if(atr > 0)
   {
      int regime = GetATRRegime(atr);
      regimeStr = (regime == 1) ? "LOW" : (regime == 2 ? "MEDIUM" : "HIGH");
   }
   DashLabel("REGIME", "Volatility: " + regimeStr,
             x, y + row * lineHeight, clrNeutral, 9);
   row++;

   //--- Dynamic SL/TP values
   if(InpDynamicSLTP && atr > 0)
   {
      double dynSL = atr * InpSL_ATR_Mult;
      double dynTP = atr * InpTP_ATR_Mult;
      DashLabel("DYNSL", "Dyn SL: $" + DoubleToString(dynSL, 2) +
                " | TP: $" + DoubleToString(dynTP, 2),
                x, y + row * lineHeight, clrNeutral, 9);
      row++;
   }

   //--- VWAP Level
   if(InpVWAPEnabled && g_vwapValue > 0)
   {
      int vwapDigits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      DashLabel("VWAP", "VWAP: " + DoubleToString(g_vwapValue, vwapDigits),
                x, y + row * lineHeight, clrNeutral, 9);
      row++;
   }

   //--- Bollinger Band Width
   if(InpBBEnabled && hBB != INVALID_HANDLE)
   {
      double bbUpper[], bbLower[];
      double bbWidth = 0;
      if(CopyBuffer(hBB, 1, 1, 1, bbUpper) >= 1 && CopyBuffer(hBB, 2, 1, 1, bbLower) >= 1)
         bbWidth = bbUpper[0] - bbLower[0];
      DashLabel("BBW", "BB Width: $" + DoubleToString(bbWidth, 2),
                x, y + row * lineHeight, clrNeutral, 9);
      row++;
   }

   //--- Spread
   symInfo.RefreshRates();
   double spread = symInfo.Spread() * _Point;
   DashLabel("SPREAD", "Spread: $" + DoubleToString(spread, 2) + " (" +
             IntegerToString((int)symInfo.Spread()) + " pts)",
             x, y + row * lineHeight, clrNeutral, 9);
   row++;

   //--- Circuit Breaker status
   if(g_circuitBreaker)
   {
      DashLabel("CB", "!! CIRCUIT BREAKER ACTIVE", x, y + row * lineHeight, clrRed, 9);
      row++;
   }

   DashLabel("LINE2", "────────────────────────────────", x, y + row * lineHeight, clrDimGray, 8);
   row++;

   //--- Per-position details
   int posRow = 0;
   for(int i = 0; i < PositionsTotal() && posRow < InpMaxPositions; i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != InpMagicNumber || posInfo.Symbol() != _Symbol) continue;

      string dirStr = (posInfo.PositionType() == POSITION_TYPE_BUY) ? "BUY " : "SELL";
      int posDigits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double pProfit = posInfo.Profit() + posInfo.Swap();
      color posClr = (pProfit >= 0) ? clrProfit : clrLoss;

      string posText = "#" + IntegerToString((int)posInfo.Ticket() % 10000) + " " + dirStr +
                       " @" + DoubleToString(posInfo.PriceOpen(), posDigits) +
                       " " + DoubleToString(posInfo.Volume(), 2) + "L" +
                       " P:" + DoubleToString(pProfit, 2);

      DashLabel("P" + IntegerToString(posRow), posText,
                x, y + row * lineHeight, posClr, 8);
      row++;
      posRow++;
   }

   //--- Resize background to fit
   int panelHeight = (row + 1) * lineHeight + 10;
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE, panelHeight);

   ChartRedraw();
}

//--- Helper: Create/Update a dashboard label
void DashLabel(string id, string text, int xPos, int yPos, color clr, int fontSize)
{
   string name = g_dashPrefix + id;
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xPos);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, yPos);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
}

//+------------------------------------------------------------------+
//| ON BOOK EVENT — DOM DATA                                          |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
{
   // DOM data refreshed — handled in OnTick via CheckDOMImbalance
}

//+------------------------------------------------------------------+
//| END OF EXPERT ADVISOR                                             |
//+------------------------------------------------------------------+
