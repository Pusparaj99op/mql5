//+------------------------------------------------------------------+
//|            XAUUSD Aggressive Scalper EA v2.0                      |
//|            Broker: XM360 | Instrument: XAUUSD (Gold.i#)           |
//|            Timeframe: M5 / M1 | Leverage: 1000:1                  |
//|            Developed in MQL5 — Full MT5 Feature Utilization        |
//+------------------------------------------------------------------+
#property copyright   "XAUUSD Scalper EA v2.0"
#property link        ""
#property version     "2.00"

//--- Include native MT5 libraries
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Indicators\Trend.mqh>
#include <Math\Stat\Math.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayInt.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+

//--- Symbol & Session
input string   InpSymbol             = "Gold.i#";       // Trading Symbol
input int      InpStartHour          = 1;               // Session Start Hour (01:00)
input int      InpEndHour            = 23;              // Session End Hour  (23:00)

//--- Timeframe
input ENUM_TIMEFRAMES InpTimeframe   = PERIOD_M5;       // Primary Timeframe

//--- Risk Management
input double   InpRiskPercent        = 1.5;             // Risk % per trade
input double   InpMaxDailyDrawdown   = 5.0;             // Max Daily Drawdown %
input double   InpMaxAccountRisk     = 10.0;            // Max Total Account Risk %
input int      InpMaxOpenTrades      = 10;              // Max concurrent trades
input bool     InpUseDynamicLot      = true;            // Dynamic lot sizing
input double   InpFixedLot           = 0.01;            // Fixed lot (if dynamic OFF)
input double   InpMaxLot             = 50.0;            // Maximum allowed lot size

//--- Stop Loss & Take Profit (in points)
input int      InpBaseSL             = 150;             // Base Stop Loss (points)
input int      InpBaseTP             = 250;             // Base Take Profit (points)
input bool     InpUseATRSLTP         = true;            // Use ATR-based SL/TP
input double   InpATRMultSL          = 1.5;             // ATR Multiplier for SL
input double   InpATRMultTP          = 2.5;             // ATR Multiplier for TP
input bool     InpUseTrailingStop    = true;            // Enable Trailing Stop
input int      InpTrailStart         = 100;             // Trail Start (points profit)
input int      InpTrailStep          = 30;              // Trail Step (points)
input bool     InpUseBreakEven       = true;            // Enable Break-Even
input int      InpBreakEvenAt        = 80;              // Break-Even trigger (points)

//--- Indicators
input int      InpEMAFast            = 8;               // Fast EMA Period
input int      InpEMAMid             = 21;              // Mid EMA Period
input int      InpEMASlow            = 55;              // Slow EMA Period
input int      InpRSIPeriod          = 14;              // RSI Period
input double   InpRSIOverbought      = 70.0;            // RSI Overbought
input double   InpRSIOversold        = 30.0;            // RSI Oversold
input int      InpATRPeriod          = 14;              // ATR Period
input int      InpBBPeriod           = 20;              // Bollinger Bands Period
input double   InpBBDeviation        = 2.0;             // BB Standard Deviation
input int      InpMACDFast           = 12;              // MACD Fast EMA
input int      InpMACDSlow           = 26;              // MACD Slow EMA
input int      InpMACDSignal         = 9;               // MACD Signal
input int      InpStochK             = 5;               // Stochastic %K
input int      InpStochD             = 3;               // Stochastic %D
input int      InpStochSlowing       = 3;               // Stochastic Slowing
input int      InpCCIPeriod          = 14;              // CCI Period
input int      InpWilliamsPeriod     = 14;              // Williams %R Period
input int      InpMomentumPeriod     = 10;              // Momentum Period

//--- Scalping Signal Filters
input int      InpSignalStrength     = 4;               // Minimum signal strength (1-7)
input bool     InpUseTrendFilter     = true;            // Use Trend Filter
input bool     InpUseVolatilityFilter= true;            // Use Volatility Filter
input double   InpMinATRPips         = 3.0;             // Min ATR in pips for trading
input double   InpMaxSpread          = 30.0;            // Max allowed spread (points)

//--- Quantitative & Self-Correcting
input bool     InpUseMartingale      = false;           // Use Martingale (CAUTION)
input double   InpMartingaleMult     = 1.5;             // Martingale Multiplier
input int      InpMartingaleMax      = 3;               // Max Martingale Steps
input bool     InpUseAntiMartingale  = true;            // Use Anti-Martingale (on win)
input double   InpAntiMartMult       = 1.2;             // Anti-Martingale Multiplier
input int      InpAntiMartMax        = 3;               // Max Anti-Martingale Steps
input bool     InpSelfCorrect        = true;            // Enable self-correction
input int      InpSelfCorrectBars    = 50;              // Bars for self-correction analysis
input double   InpWinRateThreshold   = 45.0;            // Min Win Rate % before adjustment

//--- Order Flow Analysis
input bool     InpUseOrderFlow       = true;            // Enable Order Flow Analysis
input int      InpOrderFlowBars      = 20;              // Bars for order flow calc
input double   InpOrderFlowThresh    = 0.6;             // Order flow imbalance threshold

//--- Display
input bool     InpShowDashboard      = true;            // Show Info Dashboard
input color    InpPanelBG            = C'20,20,40';     // Panel Background
input color    InpPanelText          = clrWhite;        // Panel Text Color
input color    InpProfitColor        = clrLime;         // Profit Color
input color    InpLossColor          = clrRed;          // Loss Color
input int      InpPanelX             = 10;              // Panel X position
input int      InpPanelY             = 30;              // Panel Y position

//--- Magic & Comment
input long     InpMagicNumber        = 20240101;        // EA Magic Number
input string   InpTradeComment       = "XAUUSD_Scalper";// Trade Comment

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+

CTrade         Trade;
CPositionInfo  PositionInfo;
COrderInfo     OrderInfo;
CSymbolInfo    SymbolInfo;
CAccountInfo   AccountInfo;

//--- Indicator handles
int hEMAFast, hEMAMid, hEMASlow;
int hRSI, hATR, hBB, hMACD, hStoch, hCCI, hWilliams, hMomentum;
int hEMAFastH, hEMASlowH;  // Higher TF EMAs

//--- Buffers
double bufEMAFast[], bufEMAMid[], bufEMASlow[];
double bufRSI[], bufATR[];
double bufBBUpper[], bufBBMid[], bufBBLower[];
double bufMACDMain[], bufMACDSignal[];
double bufStochMain[], bufStochSignal[];
double bufCCI[], bufWilliams[], bufMomentum[];
double bufEMAFastH[], bufEMASlowH[];

//--- Trade State
double   gDayStartBalance    = 0;
double   gDayPnL             = 0;
double   gSessionPnL         = 0;
double   gTotalWins          = 0;
double   gTotalLosses        = 0;
double   gTotalTrades        = 0;
double   gConsecutiveWins    = 0;
double   gConsecutiveLosses  = 0;
double   gCurrentLotMult     = 1.0;
double   gLastLot            = 0;
double   gPoint              = 0;
int      gDigits             = 0;
datetime gLastBarTime        = 0;
datetime gLastTradeTime      = 0;
bool     gTradingAllowed     = true;
int      gMartingaleStep     = 0;
int      gAntiMartStep       = 0;
double   gAdaptiveSLMult     = 1.0;
double   gAdaptiveTPMult     = 1.0;
double   gWinRate            = 50.0;

//--- Self-correction memory
double   gAvgWinPips         = 0;
double   gAvgLossPips        = 0;
double   gExpectedValue      = 0;
int      gAdjustmentCycles   = 0;

//--- Order Flow
double   gBuyVolume          = 0;
double   gSellVolume         = 0;
double   gOrderFlowImbalance = 0;

//--- Dashboard labels
string   PANEL_PREFIX        = "XAUUSD_Panel_";

//+------------------------------------------------------------------+
//| INITIALIZATION                                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Validate symbol
   if(!SymbolInfo.Name(InpSymbol))
   {
      Print("ERROR: Symbol '", InpSymbol, "' not found. Trying XAUUSD...");
      if(!SymbolInfo.Name("XAUUSD"))
      {
         Alert("Symbol not found! Check broker symbol name.");
         return INIT_FAILED;
      }
   }
   SymbolInfo.Refresh();

   //--- Set symbol properties
   gPoint  = SymbolInfo.Point();
   gDigits = (int)SymbolInfo.Digits();

   //--- Configure trade object
   Trade.SetExpertMagicNumber(InpMagicNumber);
   Trade.SetDeviationInPoints(20);
   Trade.SetTypeFilling(ORDER_FILLING_IOC);
   Trade.SetAsyncMode(false);
   Trade.LogLevel(LOG_LEVEL_ERRORS);

   //--- Initialize indicators
   if(!InitIndicators()) return INIT_FAILED;

   //--- Initialize day tracking
   gDayStartBalance = AccountInfo.Balance();
   gLastBarTime     = 0;
   gLastTradeTime   = 0;

   //--- Build dashboard
   if(InpShowDashboard) BuildDashboard();

   //--- Timer for real-time updates
   EventSetMillisecondTimer(500);

   Print("═══════════════════════════════════════════════");
   Print("  XAUUSD Aggressive Scalper EA v2.0 — STARTED");
   Print("  Symbol  : ", SymbolInfo.Name());
   Print("  Magic   : ", InpMagicNumber);
   Print("  Balance : ", DoubleToString(AccountInfo.Balance(), 2));
   Print("  Leverage: 1:", (int)(1.0 / AccountInfo.MarginStopOut()) );
   Print("═══════════════════════════════════════════════");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| DEINITIALIZATION                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   DeleteDashboard();
   IndicatorRelease(hEMAFast);
   IndicatorRelease(hEMAMid);
   IndicatorRelease(hEMASlow);
   IndicatorRelease(hRSI);
   IndicatorRelease(hATR);
   IndicatorRelease(hBB);
   IndicatorRelease(hMACD);
   IndicatorRelease(hStoch);
   IndicatorRelease(hCCI);
   IndicatorRelease(hWilliams);
   IndicatorRelease(hMomentum);
   IndicatorRelease(hEMAFastH);
   IndicatorRelease(hEMASlowH);

   Print("XAUUSD Scalper EA stopped. Reason: ", reason);
   Print("Session PnL: ", DoubleToString(gSessionPnL, 2));
   Print("Total Trades: ", (int)gTotalTrades, " | Wins: ", (int)gTotalWins, " | Losses: ", (int)gTotalLosses);
}

//+------------------------------------------------------------------+
//| INITIALIZE INDICATORS                                             |
//+------------------------------------------------------------------+
bool InitIndicators()
{
   string sym = SymbolInfo.Name();

   hEMAFast  = iMA(sym, InpTimeframe, InpEMAFast,  0, MODE_EMA, PRICE_CLOSE);
   hEMAMid   = iMA(sym, InpTimeframe, InpEMAMid,   0, MODE_EMA, PRICE_CLOSE);
   hEMASlow  = iMA(sym, InpTimeframe, InpEMASlow,  0, MODE_EMA, PRICE_CLOSE);
   hRSI      = iRSI(sym, InpTimeframe, InpRSIPeriod, PRICE_CLOSE);
   hATR      = iATR(sym, InpTimeframe, InpATRPeriod);
   hBB       = iBands(sym, InpTimeframe, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   hMACD     = iMACD(sym, InpTimeframe, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   hStoch    = iStochastic(sym, InpTimeframe, InpStochK, InpStochD, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
   hCCI      = iCCI(sym, InpTimeframe, InpCCIPeriod, PRICE_TYPICAL);
   hWilliams = iWPR(sym, InpTimeframe, InpWilliamsPeriod);
   hMomentum = iMomentum(sym, InpTimeframe, InpMomentumPeriod, PRICE_CLOSE);

   //--- Higher timeframe trend confirmation (H1)
   hEMAFastH = iMA(sym, PERIOD_H1, 50,  0, MODE_EMA, PRICE_CLOSE);
   hEMASlowH = iMA(sym, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);

   if(hEMAFast  == INVALID_HANDLE || hEMAMid  == INVALID_HANDLE ||
      hEMASlow  == INVALID_HANDLE || hRSI     == INVALID_HANDLE ||
      hATR      == INVALID_HANDLE || hBB      == INVALID_HANDLE ||
      hMACD     == INVALID_HANDLE || hStoch   == INVALID_HANDLE ||
      hCCI      == INVALID_HANDLE || hWilliams== INVALID_HANDLE ||
      hMomentum == INVALID_HANDLE || hEMAFastH== INVALID_HANDLE ||
      hEMASlowH == INVALID_HANDLE)
   {
      Alert("Indicator initialization FAILED! Check symbol/timeframe.");
      return false;
   }

   ArraySetAsSeries(bufEMAFast,   true);
   ArraySetAsSeries(bufEMAMid,    true);
   ArraySetAsSeries(bufEMASlow,   true);
   ArraySetAsSeries(bufRSI,       true);
   ArraySetAsSeries(bufATR,       true);
   ArraySetAsSeries(bufBBUpper,   true);
   ArraySetAsSeries(bufBBMid,     true);
   ArraySetAsSeries(bufBBLower,   true);
   ArraySetAsSeries(bufMACDMain,  true);
   ArraySetAsSeries(bufMACDSignal,true);
   ArraySetAsSeries(bufStochMain, true);
   ArraySetAsSeries(bufStochSignal,true);
   ArraySetAsSeries(bufCCI,       true);
   ArraySetAsSeries(bufWilliams,  true);
   ArraySetAsSeries(bufMomentum,  true);
   ArraySetAsSeries(bufEMAFastH,  true);
   ArraySetAsSeries(bufEMASlowH,  true);

   return true;
}

//+------------------------------------------------------------------+
//| ONTICK — MAIN EXECUTION                                           |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Refresh symbol info
   SymbolInfo.RefreshRates();
   double ask = SymbolInfo.Ask();
   double bid = SymbolInfo.Bid();
   if(ask == 0 || bid == 0) return;

   //--- Check spread
   double spread = (ask - bid) / gPoint;
   if(spread > InpMaxSpread) return;

   //--- Session time check
   if(!IsInTradingSession()) return;

   //--- Daily drawdown check
   if(!CheckDailyDrawdown()) return;

   //--- Manage existing positions (trailing stop, break-even)
   ManageOpenPositions();

   //--- Bar-level logic (once per new bar)
   datetime currentBar = iTime(SymbolInfo.Name(), InpTimeframe, 0);
   if(currentBar == gLastBarTime) return;
   gLastBarTime = currentBar;

   //--- Load all indicator buffers
   if(!LoadIndicators()) return;

   //--- Update day PnL
   UpdateDayTracking();

   //--- Self-correction engine
   if(InpSelfCorrect) RunSelfCorrection();

   //--- Order flow analysis
   if(InpUseOrderFlow) AnalyzeOrderFlow();

   //--- Check max trades cap
   int openTrades = CountOpenTrades();
   if(openTrades >= InpMaxOpenTrades) return;

   //--- Generate composite signal
   int signal = GenerateSignal();
   if(MathAbs(signal) < InpSignalStrength) return;

   //--- Volatility filter
   if(InpUseVolatilityFilter)
   {
      double atrPips = bufATR[1] / (gPoint * 10);
      if(atrPips < InpMinATRPips) return;
   }

   //--- Calculate dynamic SL/TP
   double sl_points, tp_points;
   CalculateSLTP(sl_points, tp_points);

   //--- Calculate lot size
   double lotSize = CalculateLotSize(sl_points);
   if(lotSize <= 0) return;

   //--- Execute trade
   if(signal > 0)
      ExecuteTrade(ORDER_TYPE_BUY,  ask, bid, sl_points, tp_points, lotSize);
   else if(signal < 0)
      ExecuteTrade(ORDER_TYPE_SELL, ask, bid, sl_points, tp_points, lotSize);
}

//+------------------------------------------------------------------+
//| LOAD ALL INDICATOR VALUES                                         |
//+------------------------------------------------------------------+
bool LoadIndicators()
{
   int bars = 5;
   if(CopyBuffer(hEMAFast,   0, 0, bars, bufEMAFast)    < bars) return false;
   if(CopyBuffer(hEMAMid,    0, 0, bars, bufEMAMid)     < bars) return false;
   if(CopyBuffer(hEMASlow,   0, 0, bars, bufEMASlow)    < bars) return false;
   if(CopyBuffer(hRSI,       0, 0, bars, bufRSI)        < bars) return false;
   if(CopyBuffer(hATR,       0, 0, bars, bufATR)        < bars) return false;
   if(CopyBuffer(hBB,        0, 0, bars, bufBBUpper)    < bars) return false;
   if(CopyBuffer(hBB,        1, 0, bars, bufBBMid)      < bars) return false;
   if(CopyBuffer(hBB,        2, 0, bars, bufBBLower)    < bars) return false;
   if(CopyBuffer(hMACD,      0, 0, bars, bufMACDMain)   < bars) return false;
   if(CopyBuffer(hMACD,      1, 0, bars, bufMACDSignal) < bars) return false;
   if(CopyBuffer(hStoch,     0, 0, bars, bufStochMain)  < bars) return false;
   if(CopyBuffer(hStoch,     1, 0, bars, bufStochSignal)< bars) return false;
   if(CopyBuffer(hCCI,       0, 0, bars, bufCCI)        < bars) return false;
   if(CopyBuffer(hWilliams,  0, 0, bars, bufWilliams)   < bars) return false;
   if(CopyBuffer(hMomentum,  0, 0, bars, bufMomentum)   < bars) return false;
   if(CopyBuffer(hEMAFastH,  0, 0, bars, bufEMAFastH)   < bars) return false;
   if(CopyBuffer(hEMASlowH,  0, 0, bars, bufEMASlowH)   < bars) return false;
   return true;
}

//+------------------------------------------------------------------+
//| COMPOSITE SIGNAL ENGINE (Heavy Mathematics)                       |
//| Returns: positive = BUY strength, negative = SELL strength       |
//| Scale: -7 to +7                                                   |
//+------------------------------------------------------------------+
int GenerateSignal()
{
   int score = 0;
   double emaF1 = bufEMAFast[1],  emaF2 = bufEMAFast[2];
   double emaM1 = bufEMAMid[1],   emaM2 = bufEMAMid[2];
   double emaS1 = bufEMASlow[1],  emaS2 = bufEMASlow[2];
   double rsi1  = bufRSI[1],      rsi2  = bufRSI[2];
   double atr1  = bufATR[1];
   double bbU   = bufBBUpper[1],  bbL = bufBBLower[1], bbM = bufBBMid[1];
   double macdM1= bufMACDMain[1], macdS1 = bufMACDSignal[1];
   double macdM2= bufMACDMain[2], macdS2 = bufMACDSignal[2];
   double stochK = bufStochMain[1], stochD = bufStochSignal[1];
   double stochK2= bufStochMain[2], stochD2= bufStochSignal[2];
   double cci1  = bufCCI[1],      cci2 = bufCCI[2];
   double wpr1  = bufWilliams[1], wpr2 = bufWilliams[2];
   double mom1  = bufMomentum[1], mom2 = bufMomentum[2];
   double htfF  = bufEMAFastH[1], htfS = bufEMASlowH[1];
   double price = SymbolInfo.Bid();

   //--- [1] EMA ALIGNMENT (Trend direction — weight 2)
   bool bullishEMA = (emaF1 > emaM1 && emaM1 > emaS1 && emaF1 > emaF2);
   bool bearishEMA = (emaF1 < emaM1 && emaM1 < emaS1 && emaF1 < emaF2);
   if(bullishEMA) score += 2;
   if(bearishEMA) score -= 2;

   //--- [2] EMA CROSSOVER (Golden/Death cross on fast vs mid)
   bool bullCross = (emaF1 > emaM1 && emaF2 <= emaM2);
   bool bearCross = (emaF1 < emaM1 && emaF2 >= emaM2);
   if(bullCross) score += 1;
   if(bearCross) score -= 1;

   //--- [3] RSI MOMENTUM + DIVERGENCE PROXY
   bool rsiBull = (rsi1 > 50 && rsi1 > rsi2 && rsi1 < InpRSIOverbought);
   bool rsiBear = (rsi1 < 50 && rsi1 < rsi2 && rsi1 > InpRSIOversold);
   bool rsiOBBear = (rsi1 >= InpRSIOverbought);
   bool rsiOSBull = (rsi1 <= InpRSIOversold);
   if(rsiBull || rsiOSBull) score += 1;
   if(rsiBear || rsiOBBear) score -= 1;

   //--- [4] MACD CROSSOVER + HISTOGRAM DIRECTION
   bool macdBull = (macdM1 > macdS1 && macdM2 <= macdS2);
   bool macdBear = (macdM1 < macdS1 && macdM2 >= macdS2);
   bool macdHistBull = (macdM1 - macdS1) > (macdM2 - macdS2);
   bool macdHistBear = (macdM1 - macdS1) < (macdM2 - macdS2);
   if(macdBull || macdHistBull) score += 1;
   if(macdBear || macdHistBear) score -= 1;

   //--- [5] STOCHASTIC CROSSOVER + ZONE
   bool stochBull = (stochK > stochD && stochK2 <= stochD2 && stochK < 80);
   bool stochBear = (stochK < stochD && stochK2 >= stochD2 && stochK > 20);
   bool stochOSBull = (stochK < 20 && stochK > stochD);
   bool stochOBBear = (stochK > 80 && stochK < stochD);
   if(stochBull || stochOSBull) score += 1;
   if(stochBear || stochOBBear) score -= 1;

   //--- [6] BOLLINGER BANDS BREAKOUT / MEAN REVERSION
   double bbWidth = (bbU - bbL) / bbM;  // Normalized bandwidth
   bool bbBullBreak  = (price > bbU);
   bool bbBearBreak  = (price < bbL);
   bool bbBullRevert = (price < bbL && emaF1 > emaS1);
   bool bbBearRevert = (price > bbU && emaF1 < emaS1);
   if(bbBullBreak || bbBullRevert) score += 1;
   if(bbBearBreak || bbBearRevert) score -= 1;

   //--- [7] CCI SIGNAL (Commodity Channel Index)
   bool cciBull = (cci1 > 0 && cci2 < 0) || (cci1 > 100);
   bool cciBear = (cci1 < 0 && cci2 > 0) || (cci1 < -100);
   if(cciBull) score += 1;
   if(cciBear) score -= 1;

   //--- [8] WILLIAMS %R
   bool wprBull = (wpr1 > -20 && wpr2 <= -20) || (wpr1 > -50 && wpr2 < -50);
   bool wprBear = (wpr1 < -80 && wpr2 >= -80) || (wpr1 < -50 && wpr2 > -50);
   if(wprBull) score += 1;
   if(wprBear) score -= 1;

   //--- [9] MOMENTUM DIRECTION
   if(mom1 > 100 && mom1 > mom2) score += 1;
   if(mom1 < 100 && mom1 < mom2) score -= 1;

   //--- [10] HIGHER TIMEFRAME TREND FILTER (HTF H1)
   if(InpUseTrendFilter)
   {
      if(htfF > htfS && score < 0) score = 0;   // Cancel bearish on bullish HTF
      if(htfF < htfS && score > 0) score = 0;   // Cancel bullish on bearish HTF
   }

   //--- [11] ORDER FLOW IMBALANCE BOOST
   if(InpUseOrderFlow)
   {
      if(gOrderFlowImbalance > InpOrderFlowThresh  && score > 0) score += 1;
      if(gOrderFlowImbalance < -InpOrderFlowThresh && score < 0) score -= 1;
   }

   //--- [12] QUANTITATIVE EXPECTED VALUE ADJUSTMENT
   //    If EV is negative, require stronger signals
   if(gExpectedValue < 0 && MathAbs(score) < InpSignalStrength + 1)
      return 0;

   return score;
}

//+------------------------------------------------------------------+
//| CALCULATE DYNAMIC SL/TP                                          |
//+------------------------------------------------------------------+
void CalculateSLTP(double &sl_pts, double &tp_pts)
{
   if(InpUseATRSLTP && bufATR[1] > 0)
   {
      double atr = bufATR[1];
      sl_pts = (atr * InpATRMultSL * gAdaptiveSLMult) / gPoint;
      tp_pts = (atr * InpATRMultTP * gAdaptiveTPMult) / gPoint;

      //--- Quantitative RR floor — never let RR fall below 1.5:1
      if(tp_pts < sl_pts * 1.5)
         tp_pts = sl_pts * 1.5;

      //--- Apply Bollinger Band width adjustment
      double bbW = (bufBBUpper[1] - bufBBLower[1]);
      double bbAdj = MathMax(0.8, MathMin(1.5, bbW / atr));
      sl_pts *= bbAdj;
      tp_pts *= bbAdj;
   }
   else
   {
      sl_pts = InpBaseSL;
      tp_pts = InpBaseTP;
   }

   //--- Hard caps
   sl_pts = MathMax(50,  MathMin(sl_pts, 500));
   tp_pts = MathMax(100, MathMin(tp_pts, 1000));
}

//+------------------------------------------------------------------+
//| DYNAMIC LOT SIZE — Kelly Criterion + Risk %                      |
//+------------------------------------------------------------------+
double CalculateLotSize(double sl_points)
{
   double balance  = AccountInfo.Balance();
   double riskAmt  = balance * (InpRiskPercent / 100.0);

   //--- Kelly Criterion adjustment
   if(gTotalTrades > 10 && gWinRate > 0)
   {
      double winRate = gWinRate / 100.0;
      double avgRR   = (gAvgWinPips > 0 && gAvgLossPips > 0) ? gAvgWinPips / gAvgLossPips : 1.5;
      double kelly   = winRate - ((1.0 - winRate) / avgRR);
      kelly = MathMax(0.1, MathMin(kelly, 0.25)); // Fractional Kelly cap at 25%
      riskAmt = balance * kelly * (InpRiskPercent / 100.0) * 20; // Scale
   }

   //--- Martingale / Anti-Martingale multiplier
   riskAmt *= gCurrentLotMult;

   //--- Point value
   double tickVal  = SymbolInfo.TickValue();
   double tickSize = SymbolInfo.TickSize();
   if(tickVal == 0 || tickSize == 0) return 0;

   double slValue  = sl_points * gPoint * (tickVal / tickSize);
   if(slValue <= 0) return 0;

   double rawLot = riskAmt / slValue;

   //--- Normalize to broker step
   double lotStep = SymbolInfo.LotsStep();
   double minLot  = SymbolInfo.LotsMin();
   double maxLot  = MathMin(InpMaxLot, SymbolInfo.LotsMax());

   if(lotStep > 0)
      rawLot = MathFloor(rawLot / lotStep) * lotStep;

   rawLot = MathMax(minLot, MathMin(rawLot, maxLot));

   if(!InpUseDynamicLot) rawLot = InpFixedLot;

   return rawLot;
}

//+------------------------------------------------------------------+
//| EXECUTE TRADE                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE type, double ask, double bid,
                  double sl_pts, double tp_pts, double lot)
{
   double entryPrice, sl, tp;
   double slVal = sl_pts * gPoint;
   double tpVal = tp_pts * gPoint;

   if(type == ORDER_TYPE_BUY)
   {
      entryPrice = ask;
      sl = NormalizeDouble(entryPrice - slVal, gDigits);
      tp = NormalizeDouble(entryPrice + tpVal, gDigits);
   }
   else
   {
      entryPrice = bid;
      sl = NormalizeDouble(entryPrice + slVal, gDigits);
      tp = NormalizeDouble(entryPrice - tpVal, gDigits);
   }

   //--- Margin check
   double margin = 0;
   if(!OrderCalcMargin(type, SymbolInfo.Name(), lot, entryPrice, margin))
      return;
   if(margin > AccountInfo.FreeMargin() * 0.9)
   {
      Print("Insufficient margin for trade. Required: ", margin);
      return;
   }

   //--- Place order
   bool result = false;
   if(type == ORDER_TYPE_BUY)
      result = Trade.Buy(lot, SymbolInfo.Name(), entryPrice, sl, tp, InpTradeComment);
   else
      result = Trade.Sell(lot, SymbolInfo.Name(), entryPrice, sl, tp, InpTradeComment);

   if(result)
   {
      gLastTradeTime = TimeCurrent();
      gLastLot       = lot;
      Print("✅ Trade opened: ", EnumToString(type),
            " | Lot: ", lot,
            " | Entry: ", entryPrice,
            " | SL: ", sl,
            " | TP: ", tp,
            " | Balance: ", AccountInfo.Balance());
   }
   else
   {
      Print("❌ Trade failed. Error: ", Trade.ResultRetcode(), " - ", Trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| MANAGE OPEN POSITIONS — Trailing & Break-Even                    |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PositionInfo.SelectByIndex(i)) continue;
      if(PositionInfo.Magic() != InpMagicNumber) continue;
      if(PositionInfo.Symbol() != SymbolInfo.Name()) continue;

      double openPrice  = PositionInfo.PriceOpen();
      double currentSL  = PositionInfo.StopLoss();
      double currentTP  = PositionInfo.TakeProfit();
      double posType    = PositionInfo.PositionType();
      ulong  ticket     = PositionInfo.Ticket();
      double ask        = SymbolInfo.Ask();
      double bid        = SymbolInfo.Bid();
      double curPrice   = (posType == POSITION_TYPE_BUY) ? bid : ask;
      double profit_pts = 0;

      if(posType == POSITION_TYPE_BUY)
         profit_pts = (curPrice - openPrice) / gPoint;
      else
         profit_pts = (openPrice - curPrice) / gPoint;

      //--- Break-Even logic
      if(InpUseBreakEven && profit_pts >= InpBreakEvenAt)
      {
         double newSL = 0;
         if(posType == POSITION_TYPE_BUY)
            newSL = NormalizeDouble(openPrice + gPoint * 5, gDigits);
         else
            newSL = NormalizeDouble(openPrice - gPoint * 5, gDigits);

         bool needMove = (posType == POSITION_TYPE_BUY  && newSL > currentSL) ||
                         (posType == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL));
         if(needMove)
            Trade.PositionModify(ticket, newSL, currentTP);
      }

      //--- Trailing Stop logic
      if(InpUseTrailingStop && profit_pts >= InpTrailStart)
      {
         double trailDist = InpTrailStep * gPoint;
         double newSL = 0;
         if(posType == POSITION_TYPE_BUY)
         {
            newSL = NormalizeDouble(bid - trailDist, gDigits);
            if(newSL > currentSL)
               Trade.PositionModify(ticket, newSL, currentTP);
         }
         else
         {
            newSL = NormalizeDouble(ask + trailDist, gDigits);
            if(currentSL == 0 || newSL < currentSL)
               Trade.PositionModify(ticket, newSL, currentTP);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| ORDER FLOW ANALYSIS                                               |
//| Uses tick volume as a proxy for order flow imbalance             |
//+------------------------------------------------------------------+
void AnalyzeOrderFlow()
{
   long buyVol  = 0;
   long sellVol = 0;
   string sym   = SymbolInfo.Name();

   for(int i = 1; i <= InpOrderFlowBars; i++)
   {
      double o = iOpen(sym,  InpTimeframe, i);
      double c = iClose(sym, InpTimeframe, i);
      long   v = (long)iTickVolume(sym, InpTimeframe, i);
      if(c > o) buyVol  += v;
      else       sellVol += v;
   }

   long totalVol = buyVol + sellVol;
   if(totalVol > 0)
   {
      double ratio = (double)(buyVol - sellVol) / (double)totalVol;
      gOrderFlowImbalance = ratio; // -1.0 (full sell) to +1.0 (full buy)
   }
}

//+------------------------------------------------------------------+
//| SELF-CORRECTING ENGINE                                            |
//| Adapts SL/TP multipliers based on recent performance             |
//+------------------------------------------------------------------+
void RunSelfCorrection()
{
   if(gTotalTrades < 10) return;
   gWinRate = (gTotalTrades > 0) ? (gTotalWins / gTotalTrades) * 100.0 : 50.0;

   //--- Expected Value: EV = (WinRate * AvgWin) - (LossRate * AvgLoss)
   if(gAvgWinPips > 0 && gAvgLossPips > 0)
   {
      double wr = gWinRate / 100.0;
      gExpectedValue = (wr * gAvgWinPips) - ((1.0 - wr) * gAvgLossPips);
   }

   gAdjustmentCycles++;

   //--- Adjust SL multiplier if win rate too low
   if(gWinRate < InpWinRateThreshold)
   {
      gAdaptiveSLMult = MathMin(gAdaptiveSLMult * 1.05, 2.0); // Widen SL
      gAdaptiveTPMult = MathMax(gAdaptiveTPMult * 0.97, 0.7); // Tighten TP
      if(gAdjustmentCycles % 10 == 0)
         Print("⚙ Self-Correct: Win rate low (", DoubleToString(gWinRate,1), "%) — Adjusting SL wider, TP tighter");
   }
   else if(gWinRate > 65.0)
   {
      gAdaptiveSLMult = MathMax(gAdaptiveSLMult * 0.97, 0.5); // Tighten SL
      gAdaptiveTPMult = MathMin(gAdaptiveTPMult * 1.03, 2.0); // Widen TP
   }

   //--- Martingale / Anti-Martingale management
   if(InpUseMartingale && gConsecutiveLosses > 0)
   {
      int step = (int)MathMin(gConsecutiveLosses, InpMartingaleMax);
      gCurrentLotMult = MathPow(InpMartingaleMult, step);
      gMartingaleStep = step;
   }
   else if(InpUseAntiMartingale && gConsecutiveWins > 0)
   {
      int step = (int)MathMin(gConsecutiveWins, InpAntiMartMax);
      gCurrentLotMult = MathPow(InpAntiMartMult, step);
      gAntiMartStep   = step;
   }
   else
   {
      gCurrentLotMult = 1.0;
   }
}

//+------------------------------------------------------------------+
//| UPDATE DAY TRACKING + DEAL HISTORY                                |
//+------------------------------------------------------------------+
void UpdateDayTracking()
{
   //--- Check for new day
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   static int lastDay = -1;
   if(dt.day != lastDay)
   {
      gDayStartBalance = AccountInfo.Balance();
      lastDay = dt.day;
   }
   gDayPnL = AccountInfo.Balance() - gDayStartBalance;

   //--- Scan closed deals for stats
   HistorySelect(iTime(SymbolInfo.Name(), PERIOD_D1, 0), TimeCurrent());
   int deals = HistoryDealsTotal();
   gTotalTrades   = 0; gTotalWins = 0; gTotalLosses = 0;
   double sumWin  = 0, sumLoss = 0;
   double sumWinP = 0, sumLossP = 0;
   gConsecutiveWins   = 0;
   gConsecutiveLosses = 0;
   int streak         = 0;
   bool lastWin       = false;

   for(int i = 0; i < deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != SymbolInfo.Name()) continue;
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT) continue;

      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      double pips   = profit / (SymbolInfo.TickValue() * MathMax(HistoryDealGetDouble(ticket,DEAL_VOLUME),0.01));

      gTotalTrades++;
      if(profit > 0)
      {
         gTotalWins++;
         sumWinP += MathAbs(pips);
         sumWin  += profit;
         if(!lastWin) { streak = 0; lastWin = true; }
         streak++;
         gConsecutiveWins = MathMax(gConsecutiveWins, streak);
      }
      else
      {
         gTotalLosses++;
         sumLossP += MathAbs(pips);
         sumLoss  += MathAbs(profit);
         if(lastWin)  { streak = 0; lastWin = false; }
         streak++;
         gConsecutiveLosses = MathMax(gConsecutiveLosses, streak);
      }
   }

   if(gTotalWins   > 0) gAvgWinPips  = sumWinP  / gTotalWins;
   if(gTotalLosses > 0) gAvgLossPips = sumLossP / gTotalLosses;
   gWinRate = (gTotalTrades > 0) ? (gTotalWins / gTotalTrades) * 100.0 : 50.0;
   gSessionPnL = AccountInfo.Balance() - gDayStartBalance;
}

//+------------------------------------------------------------------+
//| CHECK DAILY DRAWDOWN LIMIT                                        |
//+------------------------------------------------------------------+
bool CheckDailyDrawdown()
{
   double balance = AccountInfo.Balance();
   if(gDayStartBalance <= 0) return true;
   double ddPct = ((gDayStartBalance - balance) / gDayStartBalance) * 100.0;
   if(ddPct >= InpMaxDailyDrawdown)
   {
      static datetime lastWarn = 0;
      if(TimeCurrent() - lastWarn > 3600)
      {
         Print("⛔ Daily drawdown limit reached: ", DoubleToString(ddPct, 2), "% — Trading halted today.");
         lastWarn = TimeCurrent();
      }
      return false;
   }
   //--- Overall account risk check
   double totalRisk = ((balance - AccountInfo.Equity()) / balance) * 100.0;
   if(totalRisk >= InpMaxAccountRisk) return false;
   return true;
}

//+------------------------------------------------------------------+
//| SESSION TIME FILTER                                               |
//+------------------------------------------------------------------+
bool IsInTradingSession()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_week == 0 || dt.day_of_week == 6) return false;
   if(dt.hour < InpStartHour || dt.hour >= InpEndHour)  return false;
   return true;
}

//+------------------------------------------------------------------+
//| COUNT OPEN TRADES (This EA only)                                  |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionInfo.SelectByIndex(i))
         if(PositionInfo.Magic() == InpMagicNumber && PositionInfo.Symbol() == SymbolInfo.Name())
            count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| ON TRADE — Track results in real time                            |
//+------------------------------------------------------------------+
void OnTrade()
{
   UpdateDayTracking();
   if(InpShowDashboard) UpdateDashboard();
}

//+------------------------------------------------------------------+
//| ON TIMER — Dashboard refresh                                     |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(InpShowDashboard) UpdateDashboard();
}

//+------------------------------------------------------------------+
//| BUILD DASHBOARD                                                   |
//+------------------------------------------------------------------+
void BuildDashboard()
{
   int x = InpPanelX, y = InpPanelY;
   int w = 320, lineH = 18;
   int rows = 20;

   //--- Background
   string bg = PANEL_PREFIX + "BG";
   ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bg, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, bg, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, bg, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, bg, OBJPROP_YSIZE,       rows * lineH + 16);
   ObjectSetInteger(0, bg, OBJPROP_BGCOLOR,     InpPanelBG);
   ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bg, OBJPROP_COLOR,       clrGold);
   ObjectSetInteger(0, bg, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0, bg, OBJPROP_BACK,        false);

   string labels[] = {
      "XAUUSD Aggressive Scalper v2.0",
      "══════════════════════════════",
      "Symbol       :", "Balance      :", "Equity       :",
      "Free Margin  :", "Spread       :", "Session PnL  :",
      "Day PnL      :", "Open Trades  :", "Total Trades :",
      "Win Rate     :", "Avg Win      :", "Avg Loss     :",
      "Exp. Value   :", "Order Flow   :", "SL Mult      :",
      "TP Mult      :", "Lot Mult     :",
      "══════════════════════════════"
   };

   for(int i = 0; i < ArraySize(labels); i++)
   {
      string nm = PANEL_PREFIX + "LBL_" + IntegerToString(i);
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x + 6);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y + 8 + i * lineH);
      ObjectSetInteger(0, nm, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetString(0,  nm, OBJPROP_TEXT,      labels[i]);
      ObjectSetInteger(0, nm, OBJPROP_COLOR,     i == 0 ? clrGold : InpPanelText);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,  i == 0 ? 9 : 8);
      ObjectSetString(0,  nm, OBJPROP_FONT,      "Consolas");
   }

   //--- Value labels (right side)
   for(int i = 2; i < 19; i++)
   {
      string nm = PANEL_PREFIX + "VAL_" + IntegerToString(i);
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x + 160);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y + 8 + i * lineH);
      ObjectSetInteger(0, nm, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetString(0,  nm, OBJPROP_TEXT,      "...");
      ObjectSetInteger(0, nm, OBJPROP_COLOR,     InpPanelText);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,  8);
      ObjectSetString(0,  nm, OBJPROP_FONT,      "Consolas");
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| UPDATE DASHBOARD VALUES                                           |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   SymbolInfo.RefreshRates();
   double ask    = SymbolInfo.Ask();
   double bid    = SymbolInfo.Bid();
   double spread = (ask - bid) / gPoint;

   string vals[] = {
      SymbolInfo.Name(),
      DoubleToString(AccountInfo.Balance(), 2) + " " + AccountInfo.Currency(),
      DoubleToString(AccountInfo.Equity(),  2) + " " + AccountInfo.Currency(),
      DoubleToString(AccountInfo.FreeMargin(), 2),
      DoubleToString(spread, 1) + " pts",
      (gSessionPnL >= 0 ? "+" : "") + DoubleToString(gSessionPnL, 2),
      (gDayPnL >= 0 ? "+" : "") + DoubleToString(gDayPnL, 2),
      IntegerToString(CountOpenTrades()),
      IntegerToString((int)gTotalTrades),
      DoubleToString(gWinRate, 1) + "%",
      DoubleToString(gAvgWinPips,  1) + " pips",
      DoubleToString(gAvgLossPips, 1) + " pips",
      (gExpectedValue >= 0 ? "+" : "") + DoubleToString(gExpectedValue, 2),
      DoubleToString(gOrderFlowImbalance, 3),
      DoubleToString(gAdaptiveSLMult, 2) + "x",
      DoubleToString(gAdaptiveTPMult, 2) + "x",
      DoubleToString(gCurrentLotMult, 2) + "x"
   };

   for(int i = 0; i < ArraySize(vals); i++)
   {
      string nm = PANEL_PREFIX + "VAL_" + IntegerToString(i + 2);
      if(ObjectFind(0, nm) < 0) continue;
      ObjectSetString(0, nm, OBJPROP_TEXT, vals[i]);

      //--- Color coding for PnL
      if(i == 5 || i == 6)
      {
         double v = StringToDouble(vals[i]);
         ObjectSetInteger(0, nm, OBJPROP_COLOR, v >= 0 ? InpProfitColor : InpLossColor);
      }
      else if(i == 12) // EV
      {
         ObjectSetInteger(0, nm, OBJPROP_COLOR,
                          gExpectedValue >= 0 ? InpProfitColor : InpLossColor);
      }
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| DELETE DASHBOARD                                                  |
//+------------------------------------------------------------------+
void DeleteDashboard()
{
   ObjectsDeleteAll(0, PANEL_PREFIX);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| ON CHART EVENT — Interactive dashboard                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_KEYDOWN)
   {
      if(lparam == 'D') // Toggle dashboard
      {
         if(ObjectFind(0, PANEL_PREFIX + "BG") >= 0)
            DeleteDashboard();
         else
            BuildDashboard();
      }
   }
}
//+------------------------------------------------------------------+
//|  END OF EXPERT ADVISOR                                            |
//+------------------------------------------------------------------+