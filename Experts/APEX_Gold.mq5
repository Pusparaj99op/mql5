//+------------------------------------------------------------------+
//|                                                  APEX_Gold.mq5   |
//|        APEX Gold Destroyer - Maximum Aggression XAUUSD EA        |
//|        Full Kelly | Martingale | Pyramiding | Grid | DOM | HMM   |
//+------------------------------------------------------------------+
#property copyright   "APEX Gold Destroyer"
#property version     "1.00"
#property description "Brutally aggressive XAUUSD scalper/swing EA"
#property description "HMM regime detection + 20-component signal scoring"
#property description "Kelly sizing, martingale recovery, pyramiding, grid"
#property description "DOM order flow, news exploitation, Chandelier trailing"
#property strict

//+------------------------------------------------------------------+
//| Includes                                                          |
//+------------------------------------------------------------------+
#include <APEX/APEX_Config.mqh>
#include <APEX/APEX_MTF.mqh>
#include <APEX/APEX_Indicators.mqh>
#include <APEX/APEX_HMM.mqh>
#include <APEX/APEX_OrderFlow.mqh>
#include <APEX/APEX_Signals.mqh>
#include <APEX/APEX_Risk.mqh>
#include <APEX/APEX_Orders.mqh>
#include <APEX/APEX_News.mqh>
#include <APEX/APEX_Dashboard.mqh>

//+------------------------------------------------------------------+
//| Global Engines                                                    |
//+------------------------------------------------------------------+
CMTFEngine        g_mtf;
CIndicatorEngine  g_ind;
CHMMEngine        g_hmm;
COrderFlowEngine  g_flow;
CSignalEngine     g_signal;
CRiskEngine       g_risk;
COrderEngine      g_orders;
CNewsEngine       g_news;
CDashboardEngine  g_dash;

//+------------------------------------------------------------------+
//| Global State                                                      |
//+------------------------------------------------------------------+
string            g_symbol;
datetime          g_lastBarTime      = 0;
datetime          g_lastTickTime     = 0;
bool              g_hedgeModeOK      = false;
bool              g_domSubscribed    = false;
ApexRegime        g_regime;           // Current regime state
double            g_realizedPnL      = 0;
int               g_tickCounter      = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Validate symbol
   g_symbol = Symbol();
   if(StringFind(g_symbol, "XAU") == -1 && StringFind(g_symbol, "GOLD") == -1
      && StringFind(g_symbol, "gold") == -1)
     {
      Print("[APEX] WARNING: Running on non-XAUUSD symbol: ", g_symbol,
            ". Designed for XAUUSD only.");
     }

   // Check hedge mode
   ENUM_ACCOUNT_MARGIN_MODE marginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   g_hedgeModeOK = (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   if(!g_hedgeModeOK)
     {
      Print("[APEX] WARNING: Account is NOT in hedge mode. Bi-directional trading limited.");
     }

   // Initialize all engines in dependency order
   if(!g_mtf.Init(g_symbol))
     {
      Print("[APEX] FATAL: MTF Engine init failed");
      return INIT_FAILED;
     }

   if(!g_ind.Init(g_symbol))
     {
      Print("[APEX] FATAL: Indicator Engine init failed");
      return INIT_FAILED;
     }

   if(!g_hmm.Init(g_symbol))
     {
      Print("[APEX] FATAL: HMM Engine init failed");
      return INIT_FAILED;
     }

   if(!g_flow.Init(g_symbol))
     {
      Print("[APEX] FATAL: OrderFlow Engine init failed");
      return INIT_FAILED;
     }

   if(!g_signal.Init(g_symbol, &g_mtf, &g_ind, &g_hmm, &g_flow))
     {
      Print("[APEX] FATAL: Signal Engine init failed");
      return INIT_FAILED;
     }

   if(!g_risk.Init(g_symbol))
     {
      Print("[APEX] FATAL: Risk Engine init failed");
      return INIT_FAILED;
     }

   if(!g_orders.Init(g_symbol, &g_risk, &g_mtf))
     {
      Print("[APEX] FATAL: Order Engine init failed");
      return INIT_FAILED;
     }

   if(!g_news.Init(g_symbol))
     {
      Print("[APEX] FATAL: News Engine init failed");
      return INIT_FAILED;
     }

   if(!g_dash.Init())
     {
      Print("[APEX] WARNING: Dashboard init failed (non-fatal)");
     }

   // Subscribe to DOM (OrderFlow engine also subscribes, but we track state here)
   if(InpDOMEnabled)
     {
      g_domSubscribed = MarketBookAdd(g_symbol);
      if(g_domSubscribed)
         Print("[APEX] DOM subscribed for ", g_symbol);
      else
         Print("[APEX] DOM subscription failed (normal in backtesting)");
     }

   // Initial HMM training
   g_hmm.ForceTrain();

   // Zero regime
   ZeroMemory(g_regime);
   g_regime.state = REGIME_TRANSITION;
   g_regime.hmmState = HMM_RANGE;

   Print("[APEX] ═══════════════════════════════════════════");
   Print("[APEX] APEX GOLD DESTROYER v", APEX_VERSION, " INITIALIZED");
   Print("[APEX] Symbol: ", g_symbol);
   Print("[APEX] Leverage: 1:", AccountInfoInteger(ACCOUNT_LEVERAGE));
   Print("[APEX] Hedge Mode: ", g_hedgeModeOK ? "YES" : "NO");
   Print("[APEX] Balance: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   Print("[APEX] DOM Active: ", g_domSubscribed ? "YES" : "NO");
   Print("[APEX] ═══════════════════════════════════════════");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Unsubscribe DOM
   if(g_domSubscribed)
      MarketBookRelease(g_symbol);

   // Shutdown all engines
   g_dash.Deinit();
   g_news.Deinit();
   g_orders.Deinit();
   g_risk.Deinit();
   g_signal.Deinit();
   g_flow.Deinit();
   g_hmm.Deinit();
   g_ind.Deinit();
   g_mtf.Deinit();

   Print("[APEX] Deinitialized. Reason: ", reason);
  }

//+------------------------------------------------------------------+
//| Expert tick function - Main Logic Hub                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   g_tickCounter++;

   // Per-Tick operations (trail, break-even, partial close, stale)
   g_orders.ManageOpenPositions();

   // Per-Tick order flow update
   g_flow.UpdateTickFlow();

   // Emergency stop check — v2: force-close all positions
   if(g_risk.IsEmergencyStop())
     {
      static bool emergencyClosed = false;
      if(!emergencyClosed)
        {
         Print("[APEX] EMERGENCY DRAWDOWN ", DoubleToString(InpMaxDrawdown, 0), "% - CLOSING ALL POSITIONS");
         g_orders.CloseAll();
         emergencyClosed = true;
        }
      if(g_tickCounter % 100 == 0)
         Print("[APEX] EMERGENCY DRAWDOWN LIMIT - All trading halted");
      return;
     }

   // New bar detection on M5
   datetime barTime = iTime(g_symbol, PERIOD_M5, 0);
   if(barTime == g_lastBarTime) return;   // Only process on new M5 bar
   g_lastBarTime = barTime;

   //--- NEW BAR PROCESSING START ---

   // Step 1: Update all data engines
   if(!g_mtf.Update())
     {
      Print("[APEX] MTF update failed - skipping bar");
      return;
     }

   // Step 2: Get M5 candle data for indicator engine
   double m5Open[], m5High[], m5Low[], m5Close[];
   long m5Vol[];
   int barCount = 60; // 5 hours of M5 data
   if(!g_mtf.GetM5Candles(m5Open, m5High, m5Low, m5Close, m5Vol, barCount))
     {
      Print("[APEX] Failed to get M5 candles");
      return;
     }

   // Step 3: Get BB data for indicators
   ApexTFData m5Data = g_mtf.GetData(PERIOD_M5);
   ApexTFData m5PrevData;
   ZeroMemory(m5PrevData);

   // Approximate prev BB from array
   double bbUpPrev = 0, bbMidPrev = 0, bbLowPrev = 0;
   if(barCount >= 2)
     {
      bbUpPrev  = m5Data.bbUpper;   // Simplified - use current as approx
      bbMidPrev = m5Data.bbMiddle;
      bbLowPrev = m5Data.bbLower;
     }

   // Step 4: Update custom indicators (Kalman, HMA, VWAP, ZScore, OFI, etc.)
   g_ind.Update(m5Open, m5High, m5Low, m5Close, m5Vol, barCount,
                m5Data.bbUpper, m5Data.bbMiddle, m5Data.bbLower,
                bbUpPrev, bbMidPrev, bbLowPrev);

   // Step 5: Feed candle OFI to order flow engine (for backtesting)
   g_flow.UpdateCandleOFI(g_ind.OFI());

   // Step 6: Update HMM regime detection
   g_hmm.Update();

   // Step 7: Update news engine
   g_news.Update();

   // Step 8: Fuse regime from HMM + indicator signals
   FuseRegime();

   // Step 9: Session filter
   if(!IsSessionActive())
     {
      UpdateDashboardOnly();
      return;
     }

   // Step 10: Generate signal from 20-component scoring engine
   ApexSignal sig = g_signal.GenerateSignal(g_regime);

   // Step 11: Execute trading logic
   ProcessSignal(sig);

   // Step 12: Check pyramid opportunities
   ProcessPyramiding(sig);

   // Step 13: Process grid recovery if active
   ProcessGrid(sig);

   // Step 14: Process news trading
   ProcessNews(sig);

   // Step 15: Update dashboard
   UpdateDashboard(sig);
  }

//+------------------------------------------------------------------+
//| DOM Book Event Handler                                            |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
   if(symbol != g_symbol) return;
   g_flow.ProcessBookEvent(symbol);
  }

//+------------------------------------------------------------------+
//| Trade Transaction Handler - Track Closed Trades                   |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   // Detect when a position is closed (deal type)
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
     {
      // Check if this deal closes a position
      if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
        {
         ulong dealTicket = trans.deal;
         if(dealTicket == 0) return;

         // Get deal info
         if(!HistoryDealSelect(dealTicket)) return;

         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
         long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);

         if(magic != InpMagic) return;  // Not our deal

         if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)
           {
            double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                          + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                          + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
            double lots   = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);

            // Determine direction from deal type (closing = reverse direction)
            ENUM_APEX_SIGNAL dir = SIGNAL_NONE;
            if(trans.deal_type == DEAL_TYPE_SELL) dir = SIGNAL_BUY;  // Closing buy
            if(trans.deal_type == DEAL_TYPE_BUY)  dir = SIGNAL_SELL; // Closing sell

            // Get position ID for meta lookup
            ulong posTicket = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);

            // Record in risk engine
            // Look up the actual strategy from position meta
            ENUM_APEX_STRATEGY actualStrategy = STRAT_TREND;
            for(int p = 0; p < g_orders.GetPositionCount(); p++)
              {
               ApexPositionMeta pm = g_orders.GetMeta(p);
               if(pm.ticket == posTicket)
                 { actualStrategy = pm.strategy; break; }
              }
            g_risk.RecordTrade(profit, lots, g_regime.state, actualStrategy, dir);

            // Track realized PnL
            g_realizedPnL += profit;

            // Remove from position meta tracking
            if(posTicket > 0)
               g_orders.OnPositionClosed(posTicket);

            if(profit >= 0)
               Print("[APEX] Trade CLOSED +$", DoubleToString(profit, 2), " (", lots, " lots)");
            else
               Print("[APEX] Trade CLOSED -$", DoubleToString(MathAbs(profit), 2), " (", lots, " lots)");
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Backtester custom optimization criterion                          |
//+------------------------------------------------------------------+
double OnTester()
  {
   double profit       = TesterStatistics(STAT_PROFIT);
   double pf           = TesterStatistics(STAT_PROFIT_FACTOR);
   double dd           = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   int    trades       = (int)TesterStatistics(STAT_TRADES);
   double expectedPP   = TesterStatistics(STAT_EXPECTED_PAYOFF);
   double sharpe       = TesterStatistics(STAT_SHARPE_RATIO);

   if(trades < 20) return -999;  // Not enough trades
   if(pf <= 0)     pf = 0.01;
   if(dd <= 0)     dd = 0.01;

   // Custom criterion: aggressive profit focus
   // (Profit × PF × √Trades) / (DD + 1)  + bonuses
   double criterion = (profit * pf * MathSqrt((double)trades)) / (dd + 1.0);

   // Bonus for high win rate
   double winRate = 0;
   double wins    = TesterStatistics(STAT_PROFIT_TRADES);
   double losses  = TesterStatistics(STAT_LOSS_TRADES);
   if(wins + losses > 0) winRate = wins / (wins + losses);
   if(winRate > 0.55) criterion *= 1.2;

   // Bonus for positive Sharpe
   if(sharpe > 0.5) criterion *= 1.1;

   // Bonus for reasonable expected payoff
   if(expectedPP > 0) criterion *= 1.1;

   // Penalty for extreme DD
   if(dd > 70) criterion *= 0.5;

   Print("[APEX] OnTester: Profit=$", DoubleToString(profit, 2),
         " PF=", DoubleToString(pf, 2),
         " DD=", DoubleToString(dd, 1), "%",
         " Trades=", trades,
         " Criterion=", DoubleToString(criterion, 2));

   return criterion;
  }

//+------------------------------------------------------------------+
//| REGIME FUSION: HMM (40%) + Indicators (60%)                      |
//+------------------------------------------------------------------+
void FuseRegime()
  {
   // HMM component
   ENUM_HMM_STATE hmmState = g_hmm.GetState();
   double hmmConf = g_hmm.GetConfidence();
   double hmmEntropy = g_hmm.GetEntropy();

   // Indicator component
   ApexTFData h1  = g_mtf.GetData(PERIOD_H1);
   ApexTFData m5  = g_mtf.GetData(PERIOD_M5);
   double adx     = m5.adxMain;
   double bbBW    = g_ind.BBBandwidth();
   double atrPctl = g_mtf.GetATRPercentile();
   double kalVel  = g_ind.KalmanVelocity();

   // === Indicator-based regime ===
   ENUM_APEX_REGIME indRegime = REGIME_RANGE;

   // Strong trend detection
   if(adx > 30 && MathAbs(kalVel) > 0.1)
     {
      if(m5.emaFast > m5.emaMid && m5.emaMid > m5.emaSlow && kalVel > 0)
         indRegime = REGIME_BULL;
      else if(m5.emaFast < m5.emaMid && m5.emaMid < m5.emaSlow && kalVel < 0)
         indRegime = REGIME_BEAR;
      else
         indRegime = REGIME_TRANSITION;
     }
   // Volatile detection
   else if(atrPctl > 0.85 || bbBW > 0.03)
     {
      indRegime = REGIME_VOLATILE;
     }
   // Range detection
   else if(adx < 20 && MathAbs(kalVel) < 0.05)
     {
      indRegime = REGIME_RANGE;
     }
   else
     {
      indRegime = REGIME_TRANSITION;
     }

   // === HMM-based regime suggestion ===
   ENUM_APEX_REGIME hmmRegime = g_hmm.GetRegimeSuggestion();

   // === Fusion ===
   double hmmWeight = InpHMM_WeightFusion;  // 0.4 by default
   double indWeight = 1.0 - hmmWeight;      // 0.6

   // Simple scoring: both agree = high confidence, disagree = transition
   ENUM_APEX_REGIME fusedRegime;

   if(hmmRegime == indRegime)
     {
      // Perfect agreement
      fusedRegime = indRegime;
      g_regime.confidence = MathMin(1.0, hmmConf * 0.5 + 0.5);
     }
   else if((hmmRegime == REGIME_BULL && indRegime == REGIME_BEAR) ||
           (hmmRegime == REGIME_BEAR && indRegime == REGIME_BULL))
     {
      // Direct contradiction - use indicator (more responsive)
      fusedRegime = REGIME_TRANSITION;
      g_regime.confidence = 0.3;
     }
   else
     {
      // Partial agreement - favor indicator-based but lower confidence
      if(hmmConf > 0.8 && hmmEntropy < 0.5)
         fusedRegime = hmmRegime;   // HMM very confident
      else
         fusedRegime = indRegime;   // Default to indicators
      g_regime.confidence = MathMin(0.8, hmmConf * hmmWeight + 0.5 * indWeight);
     }

   // High entropy override - if HMM is uncertain, don't trust it
   if(hmmEntropy > InpEntropyThreshold)
     {
      fusedRegime = indRegime;  // Fall back to pure indicator regime
      g_regime.confidence *= 0.7;
     }

   // Store regime
   g_regime.state         = fusedRegime;
   g_regime.hmmState      = hmmState;
   g_regime.entropy       = hmmEntropy;
   g_regime.adxValue      = adx;
   g_regime.bbBandwidth   = bbBW;
   g_regime.atrPercentile = atrPctl;
   g_regime.kalmanVelocity= kalVel;
  }

//+------------------------------------------------------------------+
//| Session filter - London/NY overlap emphasis                       |
//+------------------------------------------------------------------+
bool IsSessionActive()
  {
   if(!InpSessionFilter) return true;  // No filter = always active

   MqlDateTime dt;
   TimeCurrent(dt);
   int hour   = dt.hour;
   int minute = dt.min;
   int totalMin = hour * 60 + minute;

   bool londonActive = (hour >= InpLondonStart && hour < InpLondonEnd);
   bool nyActive     = (hour >= InpNYStart && hour < InpNYEnd);
   bool asiaActive   = InpAsiaEnabled && (hour >= InpAsiaStart && hour < InpAsiaEnd);

   bool inSession = londonActive || nyActive || asiaActive;

   // Skip first N minutes of each session
   if(inSession && InpSkipSessionOpen > 0)
     {
      int londonStartMin = InpLondonStart * 60;
      int nyStartMin     = InpNYStart * 60;
      int asiaStartMin   = InpAsiaStart * 60;

      if(londonActive && totalMin < londonStartMin + InpSkipSessionOpen) return false;
      if(nyActive && totalMin < nyStartMin + InpSkipSessionOpen) return false;
      if(asiaActive && totalMin < asiaStartMin + InpSkipSessionOpen) return false;
     }

   // Exception: always allow during news events
   if(g_news.GetState() == NEWS_DURING || g_news.GetState() == NEWS_PRE)
      return true;

   return inSession;
  }

//+------------------------------------------------------------------+
//| Process main signal - entry decisions                             |
//+------------------------------------------------------------------+
void ProcessSignal(const ApexSignal &sig)
  {
   if(sig.direction == SIGNAL_NONE) return;

   // Check direction threshold
   double absScore = MathAbs(sig.score);
   double threshold = (sig.direction == SIGNAL_BUY) ? InpMinBuyScore : InpMinSellScore;
   if(absScore < threshold) return;

   // v2: Spread filter — don't trade when spread is excessive
   double spread = SymbolInfoDouble(g_symbol, SYMBOL_ASK) - SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double atrNow = g_mtf.GetATR(PERIOD_M5);
   if(atrNow > 0 && spread > atrNow * 0.3)
     {
      return;  // Spread too wide (>30% of ATR)
     }

   // Check if we can trade (risk limits, blacklist, etc.)
   if(!g_risk.CanTrade(sig.direction, g_regime.state)) return;

   // Check max positions
   int posCount = g_risk.CountOpenPositions(InpMagic);
   if(posCount >= InpMaxPositions) return;

   // Check bi-directional
   if(!InpBiDirectional)
     {
      ENUM_APEX_SIGNAL opposite = (sig.direction == SIGNAL_BUY) ? SIGNAL_SELL : SIGNAL_BUY;
      if(g_risk.CountByDirection(opposite, InpMagic) > 0) return;
     }

   // Calculate lots with full risk pipeline
   // sig.sl is an absolute price - compute distance for lot sizing
   double currentPrice = (sig.direction == SIGNAL_BUY) ? SymbolInfoDouble(g_symbol, SYMBOL_ASK)
                                                        : SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double slDistance = MathAbs(currentPrice - sig.sl);
   if(slDistance <= 0) slDistance = g_mtf.GetATR(PERIOD_M5) * InpSL_ATR_Mult;

   ApexSignal execSig = sig;
   execSig.lots = g_risk.CalculateLots(sig, slDistance);

   if(execSig.lots <= 0) return;

   // v2: Aggregate lot exposure check before execution
   if(!g_risk.CanTradeWithLots(sig.direction, g_regime.state, execSig.lots)) return;

   // Execute!
   if(g_orders.ExecuteSignal(execSig))
     {
      Print("[APEX] === NEW ", (sig.direction == SIGNAL_BUY ? "BUY" : "SELL"), " ===",
            " Score=", DoubleToString(sig.score, 1),
            " Lots=", DoubleToString(execSig.lots, 2),
            " SL=", DoubleToString(sig.sl, (int)SymbolInfoInteger(g_symbol, SYMBOL_DIGITS)),
            " TP1=", DoubleToString(sig.tp1, (int)SymbolInfoInteger(g_symbol, SYMBOL_DIGITS)),
            " Regime=", EnumToString(g_regime.state),
            " Strategy=", EnumToString(sig.strategy));
     }
  }

//+------------------------------------------------------------------+
//| Pyramiding - Add to winning positions                             |
//+------------------------------------------------------------------+
void ProcessPyramiding(const ApexSignal &sig)
  {
   if(!InpPyramidEnabled) return;
   if(sig.direction == SIGNAL_NONE) return;

   // Only pyramid in same direction as current signal
   for(int dir = -1; dir <= 1; dir += 2)
     {
      ENUM_APEX_SIGNAL apexDir = (dir == 1) ? SIGNAL_BUY : SIGNAL_SELL;

      // Check if signal agrees
      if(sig.direction != apexDir) continue;

      // Can pyramid?
      if(!g_risk.CanPyramid(apexDir, InpMagic)) continue;

      double pyramidPrice;
      int nextLevel;
      double currentATR = g_mtf.GetATR(PERIOD_M5);

      if(g_orders.FindPyramidOpportunity(apexDir, currentATR, pyramidPrice, nextLevel))
        {
         // v2: Use CalculateBaseLots (no martingale/equity/confidence compounding)
         double baseLots = g_risk.CalculateBaseLots(sig, currentATR * InpSL_ATR_Mult);
         double pyramidLots = g_risk.GetPyramidLots(nextLevel, baseLots);

         // v2: Aggregate lot exposure check
         if(pyramidLots > 0 && g_risk.CanTradeWithLots(apexDir, g_regime.state, pyramidLots))
           {
            ApexSignal pyramidSig = sig;
            pyramidSig.lots = pyramidLots;
            pyramidSig.strategy = STRAT_TREND;

            if(g_orders.ExecuteSignal(pyramidSig))
              {
               Print("[APEX] PYRAMID ADD Lv", nextLevel, " ", (apexDir == SIGNAL_BUY ? "BUY" : "SELL"),
                     " Lots=", DoubleToString(pyramidLots, 2));
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Grid Recovery - Build grid on losers                              |
//+------------------------------------------------------------------+
void ProcessGrid(const ApexSignal &sig)
  {
   if(!InpGridEnabled) return;

   double currentATR = g_mtf.GetATR(PERIOD_M5);
   double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);

   // Check each direction for grid opportunities
   for(int dir = -1; dir <= 1; dir += 2)
     {
      ENUM_APEX_SIGNAL apexDir = (dir == 1) ? SIGNAL_BUY : SIGNAL_SELL;
      ApexGridState grid = g_orders.GetGridState(apexDir);

      if(!grid.active) continue;  // No active grid in this direction

      // Check if price has moved enough for next grid level
      if(grid.filledLevels >= InpGridMaxLevels) continue;

      double expectedPrice;
      if(apexDir == SIGNAL_BUY)
         expectedPrice = grid.basePrice - (grid.filledLevels + 1) * currentATR * InpGridSpacingATR;
      else
         expectedPrice = grid.basePrice + (grid.filledLevels + 1) * currentATR * InpGridSpacingATR;

      double currentPrice = (apexDir == SIGNAL_BUY) ? ask : bid;
      bool shouldAdd = false;

      if(apexDir == SIGNAL_BUY && currentPrice <= expectedPrice)
         shouldAdd = true;
      else if(apexDir == SIGNAL_SELL && currentPrice >= expectedPrice)
         shouldAdd = true;

      if(shouldAdd)
        {
         int nextLevel = grid.filledLevels + 1;
         // v2: Use CalculateBaseLots (no martingale compounding)
         double baseLots = g_risk.CalculateBaseLots(sig, currentATR * InpSL_ATR_Mult);
         double gridLots = g_risk.GetGridLots(nextLevel, baseLots);

         // v2: Aggregate lot exposure check
         if(gridLots > 0 && g_risk.CanTradeWithLots(apexDir, g_regime.state, gridLots))
           {
            g_orders.OpenGridTrade(apexDir, currentPrice, nextLevel, gridLots, currentATR);
            Print("[APEX] GRID Lv", nextLevel, " ", (apexDir == SIGNAL_BUY ? "BUY" : "SELL"),
                  " Price=", DoubleToString(currentPrice, (int)SymbolInfoInteger(g_symbol, SYMBOL_DIGITS)),
                  " Lots=", DoubleToString(gridLots, 2));
           }
        }

      // Close grid if in profit
      if(grid.netProfit > 0 && grid.filledLevels >= 2)
        {
         double gridProfitTarget = currentATR * InpGridSpacingATR * 0.5;
         if(grid.netProfit >= gridProfitTarget)
           {
            g_orders.CloseGrid(apexDir);
            Print("[APEX] GRID CLOSED at profit $", DoubleToString(grid.netProfit, 2));
           }
        }
     }

   // Activate new grid on a losing trade (triggered by martingale conditions)
   // This is handled automatically when martingale kicks in and grid is enabled
   if(!g_orders.IsGridActive(SIGNAL_BUY) && !g_orders.IsGridActive(SIGNAL_SELL))
     {
      // Check if we should start a grid based on current signal
      if(g_regime.state == REGIME_RANGE && sig.direction != SIGNAL_NONE)
        {
         double absScore = MathAbs(sig.score);
         if(absScore >= InpMinBuyScore * 0.7) // Lower threshold for grid entry
           {
            double gridPrice = (sig.direction == SIGNAL_BUY) ? ask : bid;
            // v2: Use CalculateBaseLots (no martingale compounding)
            double baseLots = g_risk.CalculateBaseLots(sig, currentATR * InpSL_ATR_Mult);
            double gridLots = g_risk.GetGridLots(1, baseLots);

            // v2: Aggregate lot exposure check
            if(gridLots > 0 && g_risk.CanTradeWithLots(sig.direction, g_regime.state, gridLots))
              {
               g_orders.OpenGridTrade(sig.direction, gridPrice, 1, gridLots, currentATR);
               Print("[APEX] NEW GRID started ", (sig.direction == SIGNAL_BUY ? "BUY" : "SELL"),
                     " in RANGE regime");
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| News Trading - Straddle, spike ride, fade                         |
//+------------------------------------------------------------------+
void ProcessNews(const ApexSignal &sig)
  {
   if(!InpNewsEnabled) return;

   ENUM_APEX_NEWS_STATE newsState = g_news.GetState();
   double currentATR = g_mtf.GetATR(PERIOD_M5);

   switch(newsState)
     {
      case NEWS_PRE:
        {
         // Place straddle orders before high-impact news
         if(!g_news.IsStraddlePlaced())
           {
            double buyStopPrice, sellStopPrice, slDist, tpDist;
            if(g_news.GetStraddleLevels(currentATR, buyStopPrice, sellStopPrice, slDist, tpDist))
              {
               // Use risk engine for lot sizing
               ApexSignal dummySig;
               ZeroMemory(dummySig);
               dummySig.direction = SIGNAL_BUY;
               dummySig.score = 8.0;  // High confidence for news
               dummySig.confidence = 0.8;
               dummySig.regime = g_regime.state;
               double newsLots = g_risk.CalculateLots(dummySig, slDist);

               if(newsLots > 0 && g_orders.ExecuteNewsStraddle(buyStopPrice, sellStopPrice,
                                                                 slDist, tpDist, newsLots))
                 {
                  g_news.SetStraddlePlaced(true);
                  Print("[APEX] NEWS STRADDLE placed - ", g_news.GetNextEventName(),
                        " in ", g_news.MinutesToNextEvent(), " minutes");
                 }
              }
           }
         break;
        }

      case NEWS_DURING:
        {
         // During news: let positions ride with tight trailing
         // The Chandelier trail in ManageOpenPositions handles this
         // Just log
         if(g_tickCounter % 50 == 0)
            Print("[APEX] NEWS LIVE: ", g_news.GetNextEventName());
         break;
        }

      case NEWS_POST_FADE:
        {
         // Check for fade opportunity
         double currentPrice = SymbolInfoDouble(g_symbol, SYMBOL_BID);
         if(g_news.ShouldFadeSpike(currentPrice, currentATR))
           {
            ENUM_APEX_SIGNAL fadeDir = g_news.GetFadeDirection(currentPrice);
            if(fadeDir != SIGNAL_NONE)
              {
               // Check we don't already have a fade position
               int fadeCount = g_risk.CountByDirection(fadeDir, InpMagic);
               if(fadeCount == 0 && g_risk.CanTrade(fadeDir, g_regime.state))
                 {
                  ApexSignal fadeSig;
                  ZeroMemory(fadeSig);
                  fadeSig.direction  = fadeDir;
                  fadeSig.score      = 7.0;
                  fadeSig.confidence = 0.7;
                  fadeSig.strategy   = STRAT_NEWS;
                  fadeSig.regime     = g_regime.state;
                  double fadeSlDist   = currentATR * InpSL_ATR_Mult * 1.5; // Wider SL for fade
                  double fadeBid     = SymbolInfoDouble(g_symbol, SYMBOL_BID);
                  double fadeAsk     = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
                  if(fadeDir == SIGNAL_BUY)
                    {
                     fadeSig.sl  = fadeAsk - fadeSlDist;
                     fadeSig.tp1 = fadeAsk + currentATR * InpTP1_ATR_Mult;
                     fadeSig.tp2 = fadeAsk + currentATR * InpTP2_ATR_Mult;
                    }
                  else
                    {
                     fadeSig.sl  = fadeBid + fadeSlDist;
                     fadeSig.tp1 = fadeBid - currentATR * InpTP1_ATR_Mult;
                     fadeSig.tp2 = fadeBid - currentATR * InpTP2_ATR_Mult;
                    }
                  fadeSig.lots       = g_risk.CalculateLots(fadeSig, fadeSlDist);

                  if(fadeSig.lots > 0 && g_orders.ExecuteSignal(fadeSig))
                    {
                     Print("[APEX] NEWS FADE ", (fadeDir == SIGNAL_BUY ? "BUY" : "SELL"),
                           " - Spike reversal trade");
                    }
                 }
              }
           }
         break;
        }

      case NEWS_NONE:
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//| Update Dashboard with all metrics                                 |
//+------------------------------------------------------------------+
void UpdateDashboard(const ApexSignal &sig)
  {
   if(!InpDashboard) return;

   ApexRiskMetrics rm = g_risk.GetMetrics();

   // Calculate unrealized PnL
   double unrealPnL = 0;
   int posTotal = PositionsTotal();
   for(int i = 0; i < posTotal; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      unrealPnL += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
     }

   double spread = SymbolInfoDouble(g_symbol, SYMBOL_ASK) - SymbolInfoDouble(g_symbol, SYMBOL_BID);
   spread /= SymbolInfoDouble(g_symbol, SYMBOL_POINT);

   g_dash.Update(
      (int)g_regime.state,
      (int)g_regime.hmmState,
      g_regime.confidence,
      g_regime.entropy,
      g_mtf.GetHTFBias(),
      sig.score,
      (int)sig.strategy,
      g_orders.GetPositionCount(),
      unrealPnL,
      g_realizedPnL,
      g_risk.GetWinRate(),
      g_risk.GetTotalTrades(),
      sig.lots,
      rm.martingaleLevel,
      g_flow.GetCombinedFlowBias(),
      g_news.GetNextEventName(),
      g_news.MinutesToNextEvent(),
      (int)g_news.GetState(),
      spread,
      g_mtf.GetATR(PERIOD_M5),
      g_mtf.GetATRPercentile(),
      IsSessionActive(),
      AccountInfoDouble(ACCOUNT_EQUITY),
      AccountInfoDouble(ACCOUNT_BALANCE)
   );
  }

//+------------------------------------------------------------------+
//| Update dashboard only (when session inactive)                     |
//+------------------------------------------------------------------+
void UpdateDashboardOnly()
  {
   if(!InpDashboard) return;

   ApexSignal emptySig;
   ZeroMemory(emptySig);
   UpdateDashboard(emptySig);
  }

//+------------------------------------------------------------------+
