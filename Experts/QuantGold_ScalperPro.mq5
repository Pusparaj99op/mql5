//+------------------------------------------------------------------+
//|                    QuantGold_ScalperPro.mq5                      |
//|          XAUUSD M5 Scalper v4.0 — Profitable Edition            |
//|   Dual-Strategy: Trend-Pullback + BB-Squeeze Breakout           |
//|   MTF Filter | Smart Risk | Self-Correcting | Kalman Smooth     |
//+------------------------------------------------------------------+
#property copyright "QuantGold ScalperPro v4.0"
#property version   "4.00"
#property description "XAUUSD M5 | Trend-Pullback + Breakout | MTF Filtered"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//===================================================================
//  INPUTS
//===================================================================

input group "=== STRATEGY SELECTION ==="
input bool   InpUseTrendPullback  = true;  // Strategy A: Trend Pullback (EMA bounce)
input bool   InpUseBreakout       = true;  // Strategy B: BB Squeeze Breakout
input bool   InpUseMeanRevert     = true;  // Strategy C: RSI Mean Reversion (range)

input group "=== EMA SETTINGS ==="
input int    InpEMA_Fast   = 9;            // M5 Fast EMA
input int    InpEMA_Mid    = 21;           // M5 Mid EMA
input int    InpEMA_Slow   = 50;           // M5 Slow EMA (pullback target)
input int    InpEMA_H1Fast = 21;           // H1 Fast EMA (trend filter)
input int    InpEMA_H1Slow = 89;           // H1 Slow EMA (trend filter)

input group "=== OSCILLATORS ==="
input int    InpRSI_Period = 9;            // RSI Period (fast for scalping)
input int    InpATR_Period = 14;           // ATR Period
input int    InpBB_Period  = 20;           // BB Period (squeeze detection)
input double InpBB_Dev     = 2.0;          // BB Deviation
input int    InpADX_Period = 14;           // ADX Period
input int    InpStoch_K    = 5;            // Stoch %K
input int    InpStoch_D    = 3;            // Stoch %D
input int    InpStoch_Slow = 3;            // Stoch Slowing
input int    InpCCI_Period = 14;           // CCI Period

input group "=== ENTRY FILTERS ==="
input double InpADX_Min           = 20.0;  // Min ADX for trend entries
input double InpADX_Max           = 60.0;  // Max ADX (avoid overextended moves)
input double InpBB_SqzPct         = 0.007; // BB Squeeze: width/mid ratio threshold
input double InpRSI_OS            = 35.0;  // RSI oversold level
input double InpRSI_OB            = 65.0;  // RSI overbought level
input int    InpMinBarsSinceLast  = 3;     // Min bars between new trades (same dir)
input bool   InpRequireCandle     = true;  // Require confirming candle pattern

input group "=== RISK MANAGEMENT ==="
input double InpRiskPct    = 1.0;          // Risk per trade (% of equity)
input double InpSL_ATR     = 1.8;          // Stop Loss   = ATR x multiplier
input double InpTP1_ATR    = 2.0;          // TP1 partial = ATR x multiplier
input double InpTP2_ATR    = 4.5;          // TP2 final   = ATR x multiplier
input double InpPartialPct = 60.0;         // % lots to close at TP1
input bool   InpBreakEven  = true;         // Break-even after TP1
input bool   InpTrailing   = true;         // Trailing stop after break-even
input double InpTrail_ATR  = 1.0;          // Trail distance = ATR x multiplier
input int    InpMaxTrades  = 2;            // Max simultaneous positions
input double InpMinLot     = 0.01;         // Min lot size
input double InpMaxLot     = 3.00;         // Max lot size

input group "=== PROTECTION ==="
input double InpMaxDailyLoss    = 3.0;     // Daily loss limit (% equity)
input double InpMaxDD           = 10.0;    // Max drawdown halt (% peak equity)
input int    InpConsecLossMax   = 3;       // Pause after N consecutive losses
input int    InpConsecLossPause = 5;       // Bars to pause after consec losses
input double InpMaxSpread       = 35.0;    // Max spread in points
input double InpMinATR          = 0.5;     // Min ATR (avoid dead sessions)
input double InpMaxATR          = 30.0;    // Max ATR (avoid extreme spikes)

input group "=== SESSION FILTER ==="
input bool   InpSessions    = true;        // Enable session filter
input int    InpLondonOpen  = 7;           // London open hour (server)
input int    InpSessionEnd  = 21;          // Hard close hour (server)
input bool   InpNoFriPM     = true;        // No new trades Friday 17:00+

input group "=== KALMAN FILTER ==="
input bool   InpKalman   = true;           // Enable Kalman price smoothing
input double InpKalman_Q = 0.005;          // Kalman process noise Q
input double InpKalman_R = 0.05;           // Kalman measurement noise R

input group "=== SELF-CORRECTION ==="
input int    InpSC_Lookback   = 15;        // Trades to analyse
input double InpSC_MinWR      = 42.0;      // Min win-rate before reducing size
input double InpSC_MinPF      = 1.15;      // Min profit factor before reducing size
input double InpSC_ReduceMult = 0.6;       // Size multiplier when underperforming

input group "=== DISPLAY ==="
input bool   InpPanel = true;              // Show dashboard

//===================================================================
//  GLOBAL STATE
//===================================================================

CTrade        g_trade;
CPositionInfo g_pos;
CAccountInfo  g_acc;
CSymbolInfo   g_sym;

// M5 handles
int hFastEMA, hMidEMA, hSlowEMA;
int hRSI, hATR, hBB, hADX, hStoch, hCCI;
// H1 handles
int hH1Fast, hH1Slow;

// Kalman
double kX=0, kP=1, kXPrev=0;
bool   kInit=false;

// Protection
double g_peakEq      = 0;
double g_dayStartBal = 0;
bool   g_halted      = false;
datetime g_lastDay   = 0;

// Trade cooldown
datetime g_lastBuyBar  = 0;
datetime g_lastSellBar = 0;
datetime g_pauseUntil  = 0;

// Stats
int    g_totalTrades = 0;
double g_totalPnL    = 0;
int    g_wins        = 0;
int    g_losses      = 0;
int    g_consecLoss  = 0;

// Self-correction
double g_sizeMult = 1.0;
double g_winRate  = 50.0;
double g_PF       = 1.5;

// TP1 tracking
struct TP1Rec {
   ulong  ticket;
   double tp1;
   int    dir;
   bool   partial;
   bool   be;
   double openPx;
};
TP1Rec g_tp1[50];
int    g_tp1n = 0;

// Bar time
datetime g_lastBar = 0;

//===================================================================
//  INIT / DEINIT
//===================================================================

int OnInit() {
   g_sym.Name(_Symbol);
   g_sym.RefreshRates();

   g_trade.SetExpertMagicNumber(404040);
   g_trade.SetDeviationInPoints(50);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   g_trade.LogLevel(LOG_LEVEL_ERRORS);

   // M5 indicators
   hFastEMA = iMA(_Symbol, PERIOD_M5, InpEMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   hMidEMA  = iMA(_Symbol, PERIOD_M5, InpEMA_Mid,  0, MODE_EMA, PRICE_CLOSE);
   hSlowEMA = iMA(_Symbol, PERIOD_M5, InpEMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, PERIOD_M5, InpRSI_Period, PRICE_CLOSE);
   hATR     = iATR(_Symbol, PERIOD_M5, InpATR_Period);
   hBB      = iBands(_Symbol, PERIOD_M5, InpBB_Period, 0, InpBB_Dev, PRICE_CLOSE);
   hADX     = iADX(_Symbol, PERIOD_M5, InpADX_Period);
   hStoch   = iStochastic(_Symbol, PERIOD_M5, InpStoch_K, InpStoch_D, InpStoch_Slow, MODE_SMA, STO_LOWHIGH);
   hCCI     = iCCI(_Symbol, PERIOD_M5, InpCCI_Period, PRICE_TYPICAL);

   // H1 trend filter
   hH1Fast  = iMA(_Symbol, PERIOD_H1, InpEMA_H1Fast, 0, MODE_EMA, PRICE_CLOSE);
   hH1Slow  = iMA(_Symbol, PERIOD_H1, InpEMA_H1Slow, 0, MODE_EMA, PRICE_CLOSE);

   bool ok = (hFastEMA != INVALID_HANDLE && hMidEMA != INVALID_HANDLE &&
              hSlowEMA != INVALID_HANDLE && hRSI    != INVALID_HANDLE &&
              hATR     != INVALID_HANDLE && hBB     != INVALID_HANDLE &&
              hADX     != INVALID_HANDLE && hStoch  != INVALID_HANDLE &&
              hCCI     != INVALID_HANDLE && hH1Fast != INVALID_HANDLE &&
              hH1Slow  != INVALID_HANDLE);

   if (!ok) { Alert("Indicator handle creation FAILED."); return INIT_FAILED; }

   g_dayStartBal = g_acc.Balance();
   g_peakEq      = g_acc.Equity();
   g_lastDay     = TimeCurrent();

   if (InpPanel) BuildPanel();
   Print("QuantGold v4.0 initialised on ", _Symbol, " M5");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   IndicatorRelease(hFastEMA); IndicatorRelease(hMidEMA);
   IndicatorRelease(hSlowEMA); IndicatorRelease(hRSI);
   IndicatorRelease(hATR);     IndicatorRelease(hBB);
   IndicatorRelease(hADX);     IndicatorRelease(hStoch);
   IndicatorRelease(hCCI);     IndicatorRelease(hH1Fast);
   IndicatorRelease(hH1Slow);
   ObjectsDeleteAll(0,"QG_");
}

//===================================================================
//  MAIN TICK
//===================================================================

void OnTick() {
   g_sym.RefreshRates();
   datetime bar0 = iTime(_Symbol, PERIOD_M5, 0);

   // Every-tick trade management
   ManageTrades();
   if (InpPanel) RefreshPanel();

   // New bar only from here
   if (bar0 == g_lastBar) return;
   g_lastBar = bar0;

   // Daily reset + peak equity
   DailyReset();

   // Hard stops
   if (g_halted)              return;
   if (!DailyLossOK())        { g_halted = true; return; }
   if (!DrawdownOK())         { g_halted = true; return; }
   if (g_pauseUntil > bar0)  return;

   // Environment
   double atr    = GetBuf(hATR, 1);
   double spread = (double)g_sym.Spread();
   if (atr < InpMinATR || atr > InpMaxATR) return;
   if (spread > InpMaxSpread)              return;
   if (InpSessions && !SessionOK())        return;
   if (OpenCount() >= InpMaxTrades)        return;

   // ── Load indicators ──────────────────────────────────────────────

   double emaFast  = GetBuf(hFastEMA, 1);
   double emaMid   = GetBuf(hMidEMA,  1);
   double emaSlow  = GetBuf(hSlowEMA, 1);
   double emaMidP  = GetBuf(hMidEMA,  2);  // prior bar mid EMA
   double emaFastP = GetBuf(hFastEMA, 2);

   double h1Fast   = GetBuf(hH1Fast, 1);
   double h1Slow   = GetBuf(hH1Slow, 1);

   double rsi      = GetBuf(hRSI, 1);
   double rsiPrev  = GetBuf(hRSI, 2);

   double bbUp     = GetBuf(hBB, 1, 1);   // UPPER_BAND
   double bbMid    = GetBuf(hBB, 1, 0);   // BASE_LINE
   double bbLow    = GetBuf(hBB, 1, 2);   // LOWER_BAND
   double bbUpP    = GetBuf(hBB, 2, 1);
   double bbLowP   = GetBuf(hBB, 2, 2);
   double bbMidP   = GetBuf(hBB, 2, 0);

   double adx      = GetBuf(hADX, 1, 0);  // ADX main
   double diPlus   = GetBuf(hADX, 1, 1);  // +DI
   double diMinus  = GetBuf(hADX, 1, 2);  // -DI

   double stochK   = GetBuf(hStoch, 1, 0);
   double stochD   = GetBuf(hStoch, 1, 1);
   double stochKP  = GetBuf(hStoch, 2, 0);

   double cci      = GetBuf(hCCI, 1);
   double cciPrev  = GetBuf(hCCI, 2);

   double close1   = iClose(_Symbol, PERIOD_M5, 1);
   double open1    = iOpen (_Symbol, PERIOD_M5, 1);
   double high1    = iHigh (_Symbol, PERIOD_M5, 1);
   double low1     = iLow  (_Symbol, PERIOD_M5, 1);
   double close2   = iClose(_Symbol, PERIOD_M5, 2);
   double open2    = iOpen (_Symbol, PERIOD_M5, 2);

   // Kalman smoothed price
   double kPrice   = InpKalman ? KalmanUpdate(close1) : close1;

   // ── H1 Trend direction ───────────────────────────────────────────
   // +1 = bullish (fast above slow), -1 = bearish, 0 = neutral
   int h1Trend = 0;
   if (h1Fast > h1Slow * 1.0002) h1Trend =  1;
   if (h1Fast < h1Slow * 0.9998) h1Trend = -1;

   // ── Market regime ────────────────────────────────────────────────
   bool isTrending = (adx >= InpADX_Min && adx <= InpADX_Max);
   bool isRanging  = (adx < InpADX_Min);

   // ── BB squeeze ───────────────────────────────────────────────────
   double bbW     = (bbMid  > 0) ? (bbUp  - bbLow)  / bbMid  : 0;
   double bbWPrev = (bbMidP > 0) ? (bbUpP - bbLowP) / bbMidP : 0;
   bool   bbSqz   = (bbW < InpBB_SqzPct);
   bool   bbExp   = (!bbSqz && bbW > bbWPrev * 1.05); // width expanding now

   // ── Candle patterns ──────────────────────────────────────────────
   double body1  = MathAbs(close1 - open1);
   double range1 = high1 - low1;
   bool bullBar  = (close1 > open1 && body1 >= range1 * 0.5);
   bool bearBar  = (close1 < open1 && body1 >= range1 * 0.5);
   double body2  = MathAbs(close2 - open2);
   bool bullEng  = (close1 > open2 && open1 < close2 && body1 > body2 && close1 > open1);
   bool bearEng  = (close1 < open2 && open1 > close2 && body1 > body2 && close1 < open1);

   long  M5sec   = PeriodSeconds(PERIOD_M5);

   //=================================================================
   //  STRATEGY A — TREND PULLBACK
   //  Enter after a pullback to slow EMA in the direction of H1 trend
   //=================================================================
   if (InpUseTrendPullback && isTrending) {

      bool tpBuy = (h1Trend == 1)
                && (low1 <= emaSlow * 1.002 || close1 <= emaMid * 1.001)
                && (emaFast > emaFastP)          // fast EMA turned up this bar
                && (emaFast > emaSlow)            // bullish M5 structure
                && (diPlus > diMinus)
                && (rsi > 38.0 && rsi < 68.0)
                && (stochK >= stochKP || stochK < 35.0)
                && (!InpRequireCandle || bullBar || bullEng)
                && (bar0 - g_lastBuyBar > InpMinBarsSinceLast * M5sec);

      if (tpBuy) {
         double lot = CalcLots(atr);
         OpenBuy(lot, atr, "A_Pullback");
         g_lastBuyBar = bar0;
      }

      bool tpSell = (h1Trend == -1)
                 && (high1 >= emaSlow * 0.998 || close1 >= emaMid * 0.999)
                 && (emaFast < emaFastP)          // fast EMA turned down this bar
                 && (emaFast < emaSlow)            // bearish M5 structure
                 && (diMinus > diPlus)
                 && (rsi < 62.0 && rsi > 32.0)
                 && (stochK <= stochKP || stochK > 65.0)
                 && (!InpRequireCandle || bearBar || bearEng)
                 && (bar0 - g_lastSellBar > InpMinBarsSinceLast * M5sec);

      if (tpSell) {
         double lot = CalcLots(atr);
         OpenSell(lot, atr, "A_Pullback");
         g_lastSellBar = bar0;
      }
   }

   //=================================================================
   //  STRATEGY B — BB SQUEEZE BREAKOUT
   //  BB contracts → price explodes → ride the expansion
   //=================================================================
   if (InpUseBreakout && bbExp) {

      bool boBuy = (bbWPrev < InpBB_SqzPct * 1.6)  // was recently squeezed
                && (close1 > bbUp)                   // broke above upper band
                && (kPrice > bbUp)                   // Kalman confirms
                && (h1Trend >= 0)                    // H1 not bearish
                && (emaFast > emaSlow)               // M5 bullish structure
                && (rsi > 52.0)
                && (cci > 80.0)
                && (diPlus > diMinus)
                && (!InpRequireCandle || bullBar)
                && (bar0 - g_lastBuyBar > InpMinBarsSinceLast * M5sec);

      if (boBuy) {
         double lot = CalcLots(atr);
         OpenBuy(lot, atr, "B_Breakout");
         g_lastBuyBar = bar0;
      }

      bool boSell = (bbWPrev < InpBB_SqzPct * 1.6)
                 && (close1 < bbLow)                 // broke below lower band
                 && (kPrice < bbLow)
                 && (h1Trend <= 0)                   // H1 not bullish
                 && (emaFast < emaSlow)
                 && (rsi < 48.0)
                 && (cci < -80.0)
                 && (diMinus > diPlus)
                 && (!InpRequireCandle || bearBar)
                 && (bar0 - g_lastSellBar > InpMinBarsSinceLast * M5sec);

      if (boSell) {
         double lot = CalcLots(atr);
         OpenSell(lot, atr, "B_Breakout");
         g_lastSellBar = bar0;
      }
   }

   //=================================================================
   //  STRATEGY C — RSI MEAN REVERSION (ranging markets)
   //  Fade extremes when ADX is low and H1 has no clear trend
   //=================================================================
   if (InpUseMeanRevert && isRanging && h1Trend == 0) {

      bool mrBuy = (rsi < InpRSI_OS)
                && (rsi > rsiPrev)                        // RSI turning up
                && (stochK > stochD && stochKP <= stochD) // Stoch cross up
                && (stochK < 30.0)
                && (close1 <= bbLow * 1.001)
                && (cci < -100.0 && cci > cciPrev)        // CCI turning
                && (!InpRequireCandle || bullBar || bullEng)
                && (bar0 - g_lastBuyBar > InpMinBarsSinceLast * M5sec);

      if (mrBuy) {
         double lot = CalcLots(atr) * 0.8;
         OpenBuy(lot, atr, "C_MeanRev");
         g_lastBuyBar = bar0;
      }

      bool mrSell = (rsi > InpRSI_OB)
                 && (rsi < rsiPrev)                         // RSI turning down
                 && (stochK < stochD && stochKP >= stochD)  // Stoch cross down
                 && (stochK > 70.0)
                 && (close1 >= bbUp * 0.999)
                 && (cci > 100.0 && cci < cciPrev)          // CCI turning
                 && (!InpRequireCandle || bearBar || bearEng)
                 && (bar0 - g_lastSellBar > InpMinBarsSinceLast * M5sec);

      if (mrSell) {
         double lot = CalcLots(atr) * 0.8;
         OpenSell(lot, atr, "C_MeanRev");
         g_lastSellBar = bar0;
      }
   }

   // Self-correction runs every bar
   SelfCorrect();
}

//===================================================================
//  TRADE EXECUTION
//===================================================================

void OpenBuy(double lots, double atr, string tag) {
   if (lots < InpMinLot) return;
   g_sym.RefreshRates();
   double ask = g_sym.Ask();
   double pt  = g_sym.Point();
   double minS= g_sym.StopsLevel() * pt + pt;

   double sl  = NormalizeDouble(ask - atr * InpSL_ATR,  _Digits);
   double tp  = NormalizeDouble(ask + atr * InpTP2_ATR, _Digits);
   double tp1 = NormalizeDouble(ask + atr * InpTP1_ATR, _Digits);

   if ((ask - sl) < minS) sl = NormalizeDouble(ask - minS * 1.5, _Digits);
   if ((tp - ask) < minS) tp = NormalizeDouble(ask + minS * 3.0, _Digits);

   if (g_trade.Buy(lots, _Symbol, ask, sl, tp, tag)) {
      StoreTP1(g_trade.ResultOrder(), tp1, 1, ask);
      Print("[BUY] ",tag," lots=",lots," sl=",sl," tp=",tp);
   }
}

void OpenSell(double lots, double atr, string tag) {
   if (lots < InpMinLot) return;
   g_sym.RefreshRates();
   double bid = g_sym.Bid();
   double pt  = g_sym.Point();
   double minS= g_sym.StopsLevel() * pt + pt;

   double sl  = NormalizeDouble(bid + atr * InpSL_ATR,  _Digits);
   double tp  = NormalizeDouble(bid - atr * InpTP2_ATR, _Digits);
   double tp1 = NormalizeDouble(bid - atr * InpTP1_ATR, _Digits);

   if ((sl - bid) < minS) sl = NormalizeDouble(bid + minS * 1.5, _Digits);
   if ((bid - tp) < minS) tp = NormalizeDouble(bid - minS * 3.0, _Digits);

   if (g_trade.Sell(lots, _Symbol, bid, sl, tp, tag)) {
      StoreTP1(g_trade.ResultOrder(), tp1, -1, bid);
      Print("[SELL] ",tag," lots=",lots," sl=",sl," tp=",tp);
   }
}

//===================================================================
//  TRADE MANAGEMENT (every tick)
//===================================================================

void ManageTrades() {
   double atr = GetBuf(hATR, 1);
   if (atr <= 0) return;

   for (int i = PositionsTotal()-1; i >= 0; i--) {
      if (!g_pos.SelectByIndex(i)) continue;
      if (g_pos.Symbol() != _Symbol || g_pos.Magic() != 404040) continue;

      ulong  tk    = g_pos.Ticket();
      int    dir   = (g_pos.PositionType() == POSITION_TYPE_BUY) ? 1 : -1;
      double opPx  = g_pos.PriceOpen();
      double curSL = g_pos.StopLoss();
      double curTP = g_pos.TakeProfit();
      double lots  = g_pos.Volume();
      double curPx = (dir == 1) ? g_sym.Bid() : g_sym.Ask();
      double pt    = g_sym.Point();
      double minS  = g_sym.StopsLevel() * pt + pt;

      int ri = FindTP1(tk);
      if (ri < 0) continue;

      // ── Partial close at TP1 ─────────────────────────────────────
      if (!g_tp1[ri].partial) {
         bool hit = (dir == 1 && curPx >= g_tp1[ri].tp1) ||
                    (dir ==-1 && curPx <= g_tp1[ri].tp1);
         if (hit) {
            double cLots = NormalizeLot(lots * InpPartialPct / 100.0);
            if (cLots >= InpMinLot) g_trade.PositionClosePartial(tk, cLots);
            g_tp1[ri].partial = true;
         }
      }

      // ── Break-even ───────────────────────────────────────────────
      if (InpBreakEven && g_tp1[ri].partial && !g_tp1[ri].be) {
         double newSL = 0.0;
         bool   doIt  = false;
         if (dir == 1 && curSL < opPx) {
            newSL = NormalizeDouble(opPx + pt * 3, _Digits);
            doIt  = (curPx - newSL) >= minS;
         } else if (dir == -1 && curSL > opPx) {
            newSL = NormalizeDouble(opPx - pt * 3, _Digits);
            doIt  = (newSL - curPx) >= minS;
         }
         if (doIt) {
            if (g_trade.PositionModify(tk, newSL, curTP))
               g_tp1[ri].be = true;
         }
      }

      // ── Trailing stop (after break-even set) ─────────────────────
      if (InpTrailing && g_tp1[ri].be) {
         double trail  = atr * InpTrail_ATR;
         double newSL  = 0.0;
         bool   doTrl  = false;
         if (dir == 1) {
            newSL  = NormalizeDouble(curPx - trail, _Digits);
            doTrl  = (newSL > curSL + pt) && ((curPx - newSL) >= minS);
         } else {
            newSL  = NormalizeDouble(curPx + trail, _Digits);
            doTrl  = (newSL < curSL - pt) && ((newSL - curPx) >= minS);
         }
         if (doTrl) g_trade.PositionModify(tk, newSL, curTP);
      }
   }
}

//===================================================================
//  POSITION SIZING
//===================================================================

double CalcLots(double atr) {
   double equity  = g_acc.Equity();
   double risk    = equity * InpRiskPct / 100.0;
   double slDist  = atr * InpSL_ATR;
   double tickVal = g_sym.TickValue();
   double tickSz  = g_sym.TickSize();
   if (tickSz <= 0 || tickVal <= 0 || slDist <= 0) return InpMinLot;
   double lots    = risk / (slDist / tickSz * tickVal);
   lots           = lots * g_sizeMult;
   return NormalizeLot(lots);
}

double NormalizeLot(double lots) {
   double step = g_sym.LotsStep(); if (step <= 0) step = 0.01;
   lots = MathFloor(lots / step) * step;
   lots = MathMax(lots, InpMinLot);
   lots = MathMin(lots, InpMaxLot);
   return NormalizeDouble(lots, 2);
}

//===================================================================
//  KALMAN FILTER
//===================================================================

double KalmanUpdate(double z) {
   if (!kInit) { kX=z; kP=1.0; kXPrev=z; kInit=true; return z; }
   kXPrev    = kX;
   double pP = kP + InpKalman_Q;
   double K  = pP / (pP + InpKalman_R);
   kX        = kX + K * (z - kX);
   kP        = (1.0 - K) * pP;
   return kX;
}

//===================================================================
//  SESSION FILTER
//===================================================================

bool SessionOK() {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour; int dow = dt.day_of_week;
   if (dow == 0 || dow == 6)             return false; // Weekend
   if (InpNoFriPM && dow == 5 && h >= 17) return false; // Friday PM
   return (h >= InpLondonOpen && h < InpSessionEnd);
}

//===================================================================
//  PROTECTION
//===================================================================

void DailyReset() {
   MqlDateTime dnow, dlast;
   TimeToStruct(TimeCurrent(),  dnow);
   TimeToStruct(g_lastDay, dlast);
   if (dnow.day != dlast.day) {
      g_dayStartBal = g_acc.Balance();
      g_halted      = false;
      g_lastDay     = TimeCurrent();
   }
   double eq = g_acc.Equity();
   if (eq > g_peakEq) g_peakEq = eq;
}

bool DailyLossOK() {
   double loss = (g_dayStartBal - g_acc.Equity()) / g_dayStartBal * 100.0;
   if (loss >= InpMaxDailyLoss) {
      Print("Daily loss limit: ", DoubleToString(loss,2), "% — halting.");
      return false;
   }
   return true;
}

bool DrawdownOK() {
   if (g_peakEq <= 0) return true;
   double dd = (g_peakEq - g_acc.Equity()) / g_peakEq * 100.0;
   if (dd >= InpMaxDD) {
      Print("Max drawdown: ", DoubleToString(dd,2), "% — halting.");
      return false;
   }
   return true;
}

//===================================================================
//  SELF-CORRECTION ENGINE
//===================================================================

void SelfCorrect() {
   HistorySelect(TimeCurrent() - 60*24*3600, TimeCurrent());
   int total = HistoryDealsTotal();
   int count = 0, wins = 0, streak = 0;
   double gP = 0, gL = 0;
   bool   streakBroken = false;

   for (int i = total-1; i >= 0; i--) {
      ulong tk = HistoryDealGetTicket(i);
      if (HistoryDealGetInteger(tk, DEAL_MAGIC) != 404040)      continue;
      if (HistoryDealGetInteger(tk, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

      double pnl = HistoryDealGetDouble(tk, DEAL_PROFIT);

      // Consecutive loss streak (most recent first)
      if (!streakBroken) {
         if (pnl < 0) streak++;
         else         streakBroken = true;
      }

      if (count < InpSC_Lookback) {
         if (pnl > 0) { wins++; gP += pnl; }
         else           gL += MathAbs(pnl);
         count++;
      }
   }

   g_consecLoss = streak;
   if (g_consecLoss >= InpConsecLossMax) {
      g_pauseUntil = TimeCurrent() + InpConsecLossPause * PeriodSeconds(PERIOD_M5);
      Print("Consecutive losses=", g_consecLoss, " — pausing ", InpConsecLossPause, " bars.");
   }

   if (count == 0) return;
   g_winRate = (double)wins / count * 100.0;
   g_PF      = (gL > 0) ? gP / gL : (gP > 0 ? 9.9 : 0.1);

   if (g_winRate < InpSC_MinWR || g_PF < InpSC_MinPF)
      g_sizeMult = InpSC_ReduceMult;
   else if (g_winRate > 56.0 && g_PF > InpSC_MinPF * 1.4)
      g_sizeMult = 1.15;
   else
      g_sizeMult = 1.0;
}

//===================================================================
//  TP1 RECORD MANAGEMENT
//===================================================================

void StoreTP1(ulong tk, double tp1lvl, int d, double opPx) {
   if (g_tp1n >= ArraySize(g_tp1)-1) return;
   g_tp1[g_tp1n].ticket  = tk;
   g_tp1[g_tp1n].tp1     = tp1lvl;
   g_tp1[g_tp1n].dir     = d;
   g_tp1[g_tp1n].partial = false;
   g_tp1[g_tp1n].be      = false;
   g_tp1[g_tp1n].openPx  = opPx;
   g_tp1n++;
}

int FindTP1(ulong tk) {
   for (int i=0; i<g_tp1n; i++) if (g_tp1[i].ticket==tk) return i;
   return -1;
}

//===================================================================
//  TRADE CLOSED EVENT
//===================================================================

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &req,
                        const MqlTradeResult      &res) {
   if (trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   ulong dk = trans.deal;
   if (!HistoryDealSelect(dk)) return;
   if (HistoryDealGetInteger(dk, DEAL_MAGIC) != 404040)         return;
   if (HistoryDealGetInteger(dk, DEAL_ENTRY) != DEAL_ENTRY_OUT) return;
   double pnl = HistoryDealGetDouble(dk, DEAL_PROFIT);
   g_totalPnL += pnl;
   g_totalTrades++;
   if (pnl > 0) g_wins++; else g_losses++;
}

//===================================================================
//  HELPERS
//===================================================================

double GetBuf(int handle, int shift, int buf = 0) {
   double arr[]; ArraySetAsSeries(arr, true);
   if (CopyBuffer(handle, buf, shift, 1, arr) < 1) return 0.0;
   return arr[0];
}

int OpenCount() {
   int n = 0;
   for (int i = 0; i < PositionsTotal(); i++) {
      if (g_pos.SelectByIndex(i) &&
          g_pos.Symbol() == _Symbol &&
          g_pos.Magic()  == 404040) n++;
   }
   return n;
}

//===================================================================
//  DASHBOARD
//===================================================================

void BuildPanel() {
   CreateRect("QG_BG", 10, 20, 278, 275, C'10,12,30', C'30,130,230');
}

void RefreshPanel() {
   if (!InpPanel) return;
   double eq    = g_acc.Equity();
   double dayPL = eq - g_dayStartBal;
   double dd    = (g_peakEq > 0) ? (g_peakEq - eq) / g_peakEq * 100.0 : 0;
   string h1Dir = (GetBuf(hH1Fast,1) > GetBuf(hH1Slow,1)) ? "BULL ▲" : "BEAR ▼";
   color  h1Col = (GetBuf(hH1Fast,1) > GetBuf(hH1Slow,1)) ? clrLimeGreen : clrOrangeRed;

   string lines[10];
   color  cols[10];
   lines[0] = "  QuantGold ScalperPro v4.0";          cols[0] = C'0,210,255';
   lines[1] = "  "+_Symbol+" | M5 | 3-Strategy";       cols[1] = clrSilver;
   lines[2] = "  Equity  : $"+DoubleToString(eq,2);    cols[2] = clrWhite;
   lines[3] = "  Day P&L : $"+DoubleToString(dayPL,2)
             +"  DD:"+DoubleToString(dd,1)+"%";         cols[3] = (dayPL>=0)?clrLimeGreen:clrOrangeRed;
   lines[4] = "  Trades  : "+IntegerToString(g_totalTrades)
             +" W:"+IntegerToString(g_wins)
             +" L:"+IntegerToString(g_losses);           cols[4] = clrSilver;
   lines[5] = "  WinRate : "+DoubleToString(g_winRate,1)
             +"%  PF:"+DoubleToString(g_PF,2);           cols[5] = (g_winRate>=InpSC_MinWR)?clrLimeGreen:clrOrangeRed;
   lines[6] = "  SizeMul : "+DoubleToString(g_sizeMult,2)
             +"  Open:"+IntegerToString(OpenCount());     cols[6] = clrSilver;
   lines[7] = "  ConsLoss: "+IntegerToString(g_consecLoss);
                                                          cols[7] = (g_consecLoss>=2)?clrOrangeRed:clrSilver;
   lines[8] = "  H1 Trend: "+h1Dir;                     cols[8] = h1Col;
   lines[9] = g_halted ? "  !! TRADING HALTED !!" : "  Status  : ACTIVE";
                                                          cols[9] = g_halted?clrRed:clrLimeGreen;

   for (int i = 0; i < 10; i++)
      DrawLabel("QG_L"+IntegerToString(i), lines[i], cols[i], 13, 30+i*24);

   ChartRedraw(0);
}

void CreateRect(string nm, int x, int y, int w, int h, color bg, color brd) {
   ObjectCreate(0,nm,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,nm,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,nm,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,nm,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,nm,OBJPROP_BORDER_COLOR,brd);
   ObjectSetInteger(0,nm,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,nm,OBJPROP_CORNER,CORNER_LEFT_UPPER);
}

void DrawLabel(string nm, string txt, color clr, int fs, int y) {
   if (ObjectFind(0,nm) < 0) {
      ObjectCreate(0,nm,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,nm,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,fs);
      ObjectSetString(0,nm,OBJPROP_FONT,"Consolas");
   }
   ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,12);
   ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,nm,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);
}
//+------------------------------------------------------------------+