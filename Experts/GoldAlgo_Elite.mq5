//+------------------------------------------------------------------+
//|                                              GoldAlgo_Elite.mq5  |
//|                   GoldAlgo Elite - Advanced XAUUSD M5 Scalper     |
//|                                                                   |
//|  Architecture: Modular OOP (6 modules)                            |
//|  Strategy: Multi-factor score-based ensemble                      |
//|  Instruments: XAUUSD / Gold.i# (XM broker)                       |
//|  Timeframe: M5                                                    |
//|  Features:                                                        |
//|    - 12-component signal scoring (EMA, Kalman, MACD, RSI, BB,    |
//|      Stoch, CCI, Z-Score, Order Flow, HMA, VWAP)                 |
//|    - ADX + Kalman + Bollinger regime detection                    |
//|    - Regime-dependent signal weighting                            |
//|    - Fractional Kelly position sizing + equity curve feedback     |
//|    - ATR-based dynamic SL/TP per trade                            |
//|    - Break-even, trailing stop, partial close                     |
//|    - Self-correcting: win-rate adaptation, regime blacklisting,   |
//|      consecutive-loss cooldown, score threshold adjustment        |
//|    - 10 safety gates (drawdown, daily loss, spread, ATR, etc.)   |
//|    - Custom OnTester() criterion for strategy optimization        |
//+------------------------------------------------------------------+
#property copyright   "GoldAlgo Elite"
#property link        ""
#property version     "1.00"
#property description "Advanced quantitative XAUUSD scalper with self-correction"
#property strict

//+------------------------------------------------------------------+
//| Module Includes                                                   |
//+------------------------------------------------------------------+
#include <GoldAlgo\GA_Config.mqh>
#include <GoldAlgo\GA_Indicators.mqh>
#include <GoldAlgo\GA_Signals.mqh>
#include <GoldAlgo\GA_Risk.mqh>
#include <GoldAlgo\GA_Orders.mqh>

//+------------------------------------------------------------------+
//| Module Instances                                                  |
//+------------------------------------------------------------------+
CIndicatorEngine  g_indicators;
CSignalGenerator  g_signals;
CRiskManager      g_risk;
COrderManager     g_orders;

//+------------------------------------------------------------------+
//| State Variables                                                   |
//+------------------------------------------------------------------+
datetime g_lastBarTime      = 0;       // New-bar gate
datetime g_startTime        = 0;       // EA start timestamp
int      g_totalTrades      = 0;       // Lifetime trade counter
double   g_startEquity      = 0;       // Starting equity for performance
datetime g_lastTradeBarTime = 0;       // For cooldown between entries
bool     g_haltTrading      = false;   // Emergency halt flag (DD breach)

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_startTime   = TimeCurrent();
   g_startEquity = AccountInfoDouble(ACCOUNT_EQUITY);

   //--- Resolve symbol with fallback chain
   if(!ResolveSymbol())
     {
      Alert("[GoldAlgo] FATAL: Cannot resolve gold symbol. Check InpSymbol parameter.");
      return INIT_FAILED;
     }

   //--- Validate timeframe
   if(Period() != InpTimeframe && !MQLInfoInteger(MQL_TESTER))
     {
      PrintFormat("[GoldAlgo] WARNING: Chart timeframe (%s) differs from input (%s). Using input timeframe.",
                  EnumToString(Period()), EnumToString(InpTimeframe));
     }

   //--- Print account info
   PrintFormat("[GoldAlgo] ================================================");
   PrintFormat("[GoldAlgo] GoldAlgo Elite v1.00 - Initializing...");
   PrintFormat("[GoldAlgo] Symbol: %s", g_workingSymbol);
   PrintFormat("[GoldAlgo] Timeframe: %s", EnumToString(InpTimeframe));
   PrintFormat("[GoldAlgo] Account: %s (#%d)", AccountInfoString(ACCOUNT_COMPANY), (int)AccountInfoInteger(ACCOUNT_LOGIN));
   PrintFormat("[GoldAlgo] Balance: %.2f %s", AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoString(ACCOUNT_CURRENCY));
   PrintFormat("[GoldAlgo] Leverage: 1:%d", (int)AccountInfoInteger(ACCOUNT_LEVERAGE));
   PrintFormat("[GoldAlgo] Margin Mode: %s",
               (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING
               ? "Hedging" : "Netting");
   PrintFormat("[GoldAlgo] Magic: %d", InpMagicNumber);
   PrintFormat("[GoldAlgo] Risk: %.1f%% per trade", InpRiskPercent);
   PrintFormat("[GoldAlgo] Session: %02d:00 - %02d:00", InpStartHour, InpEndHour);

   //--- Verify symbol properties
   double tickValue = SymbolInfoDouble(g_workingSymbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(g_workingSymbol, SYMBOL_TRADE_TICK_SIZE);
   double lotMin    = SymbolInfoDouble(g_workingSymbol, SYMBOL_VOLUME_MIN);
   double lotMax    = SymbolInfoDouble(g_workingSymbol, SYMBOL_VOLUME_MAX);
   double lotStep   = SymbolInfoDouble(g_workingSymbol, SYMBOL_VOLUME_STEP);
   int    digits    = (int)SymbolInfoInteger(g_workingSymbol, SYMBOL_DIGITS);
   int    stopsLvl  = (int)SymbolInfoInteger(g_workingSymbol, SYMBOL_TRADE_STOPS_LEVEL);

   PrintFormat("[GoldAlgo] Tick Value: %.5f | Tick Size: %.5f | Digits: %d", tickValue, tickSize, digits);
   PrintFormat("[GoldAlgo] Lots: Min=%.2f, Max=%.2f, Step=%.2f", lotMin, lotMax, lotStep);
   PrintFormat("[GoldAlgo] Stops Level: %d points", stopsLvl);

   if(tickValue <= 0 || tickSize <= 0)
     {
      Alert("[GoldAlgo] FATAL: Invalid tick data for ", g_workingSymbol);
      return INIT_FAILED;
     }

   //--- Initialize modules
   if(!g_indicators.Init(g_workingSymbol, InpTimeframe))
     {
      Alert("[GoldAlgo] FATAL: Failed to initialize indicators");
      return INIT_FAILED;
     }

   if(!g_signals.Init(&g_indicators, g_workingSymbol, InpTimeframe))
     {
      Alert("[GoldAlgo] FATAL: Failed to initialize signal generator");
      return INIT_FAILED;
     }

   if(!g_risk.Init(g_workingSymbol, InpMagicNumber, &g_indicators))
     {
      Alert("[GoldAlgo] FATAL: Failed to initialize risk manager");
      return INIT_FAILED;
     }

   if(!g_orders.Init(g_workingSymbol, InpMagicNumber, &g_indicators, &g_risk))
     {
      Alert("[GoldAlgo] FATAL: Failed to initialize order manager");
      return INIT_FAILED;
     }

   PrintFormat("[GoldAlgo] ================================================");
   PrintFormat("[GoldAlgo] All modules initialized successfully!");
   PrintFormat("[GoldAlgo] ================================================");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Release indicator handles
   g_indicators.Deinit();

   // Print performance summary
   double endEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double profit = endEquity - g_startEquity;
   double pctReturn = (g_startEquity > 0) ? (profit / g_startEquity * 100.0) : 0;

   PerformanceStats stats = g_risk.GetStats();

   PrintFormat("[GoldAlgo] ================================================");
   PrintFormat("[GoldAlgo] PERFORMANCE SUMMARY");
   PrintFormat("[GoldAlgo] Runtime: %s to %s",
               TimeToString(g_startTime), TimeToString(TimeCurrent()));
   PrintFormat("[GoldAlgo] Starting Equity: %.2f", g_startEquity);
   PrintFormat("[GoldAlgo] Ending Equity: %.2f", endEquity);
   PrintFormat("[GoldAlgo] Net Profit: %.2f (%.1f%%)", profit, pctReturn);
   PrintFormat("[GoldAlgo] Total Trades: %d", g_totalTrades);
   PrintFormat("[GoldAlgo] Win Rate: %.1f%%", stats.winRate);
   PrintFormat("[GoldAlgo] Profit Factor: %.2f", stats.profitFactor);
   PrintFormat("[GoldAlgo] Deinit reason: %d", reason);
   PrintFormat("[GoldAlgo] ================================================");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
  {
   //=== EVERY TICK: Position Management ===
   g_orders.ManagePositions();

   //=== EMERGENCY DRAWDOWN CHECK (every tick) ===
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double peakEq = g_risk.GetMetrics().peakEquity;
      if(peakEq > 0)
        {
         double dd = (peakEq - equity) / peakEq * 100.0;
         if(!g_haltTrading && dd >= InpMaxDrawdown)
           {
            g_orders.CloseAllPositions("EMERGENCY: Max drawdown exceeded");
            g_haltTrading = true;
            PrintFormat("[GoldAlgo] EMERGENCY HALT: DD=%.1f%% >= %.1f%%. All positions closed.", dd, InpMaxDrawdown);
           }
         else if(g_haltTrading && dd < InpMaxDrawdown * 0.5)
           {
            g_haltTrading = false;
            PrintFormat("[GoldAlgo] Trading resumed: DD=%.1f%% recovered below %.1f%%", dd, InpMaxDrawdown * 0.5);
           }
        }
   }
   if(g_haltTrading)
      return;

   //=== NEW BAR GATE ===
   datetime currentBarTime = iTime(g_workingSymbol, InpTimeframe, 0);
   if(currentBarTime == 0)
      return;  // Data not ready

   if(currentBarTime == g_lastBarTime)
      return;  // Same bar, skip signal evaluation

   g_lastBarTime = currentBarTime;

   //=== NEW BAR: Full evaluation ===

   //--- Step 1: Update all indicators
   if(!g_indicators.Update())
     {
      // Indicator data not ready (warmup period)
      return;
     }

   //--- Step 2: Check all safety gates
   RiskMetrics metrics;
   if(!g_risk.CheckSafetyGates(metrics))
     {
      // A gate was tripped — log occasionally (not every bar to reduce spam)
      static int gateLogCounter = 0;
      gateLogCounter++;
      if(gateLogCounter % 12 == 1) // Log every ~1 hour on M5
         PrintFormat("[GoldAlgo] Trading blocked: %s", metrics.haltReason);
      return;
     }

   //--- Step 2.5: Inter-trade cooldown check
   if(g_lastTradeBarTime != 0)
     {
      int barsSinceLast = iBarShift(g_workingSymbol, InpTimeframe, g_lastTradeBarTime, false);
      if(barsSinceLast >= 0 && barsSinceLast < InpCooldownBars)
         return;
     }

   //--- Step 3: Generate signal
   TradeSignal signal = g_signals.Evaluate();

   if(signal.direction == SIGNAL_NONE)
      return;  // No signal

   //--- Step 4: Check regime blacklist
   if(g_risk.IsRegimeBlacklisted(signal.regime))
     {
      PrintFormat("[GoldAlgo] Signal rejected: regime %s is blacklisted", EnumToString(signal.regime));
      return;
     }

   //--- Step 5: Apply adaptive score adjustment
   double scoreAdj = g_risk.GetScoreAdj();
   double effectiveScore = (signal.direction == SIGNAL_BUY) ? signal.buyScore : signal.sellScore;
   double requiredScore  = (signal.direction == SIGNAL_BUY) ? InpMinBuyScore : InpMinSellScore;
   requiredScore += scoreAdj;

   if(effectiveScore < requiredScore)
     {
      // Signal below adaptive threshold
      return;
     }

   //--- Step 6: Compute position size
   double lots = g_risk.ComputeLotSize(signal.slPoints);
   if(lots <= 0)
     {
      Print("[GoldAlgo] Lot size computation returned 0 — skipping trade");
      return;
     }

   //--- Step 6.5: Prevent duplicate-direction stacking
   if(g_orders.HasPositionInDirection(signal.direction))
     {
      return;
     }

   //--- Step 7: Execute trade
   if(g_orders.ExecuteTrade(signal, lots))
     {
      g_totalTrades++;
      g_lastTradeBarTime = currentBarTime;

      PrintFormat("[GoldAlgo] TRADE #%d | %s | Score=%.1f (req=%.1f) | Lots=%.2f | SL=%.0f TP=%.0f pts | Regime=%s (%.0f%%) | Risk=%.1f%% | LotMult=%.2f",
                  g_totalTrades,
                  signal.source,
                  effectiveScore,
                  requiredScore,
                  lots,
                  signal.slPoints,
                  signal.tpPoints,
                  EnumToString(signal.regime),
                  signal.regimeConfidence * 100,
                  metrics.adjustedRisk,
                  g_risk.GetLotMult());
     }
  }

//+------------------------------------------------------------------+
//| Trade transaction handler - for self-correction feedback          |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   // Only interested in deal additions (trade execution events)
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;

   ulong dealTicket = trans.deal;
   if(dealTicket == 0)
      return;

   // Only process deal closures (DEAL_ENTRY_OUT)
   if(!HistoryDealSelect(dealTicket))
      return;

   ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT)
      return;

   // Verify it's our deal
   long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
   string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);

   if(dealMagic != InpMagicNumber || dealSymbol != g_workingSymbol)
      return;

   // Get P&L (including swap and commission)
   double pnl = HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
              + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
              + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);

   // Get the position ticket to look up our entry metadata
   ulong positionID = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);

   // Detect partial close: compare deal volume with original position volume
   double dealVolume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
   double origVolume = g_orders.GetOriginalVolume(positionID);

   // Detect partial close: deal volume < original volume
   // Update tracking so the final close will be correctly identified
   if(origVolume > 0 && dealVolume < origVolume * 0.95)
     {
      double remainingVol = origVolume - dealVolume;
      g_orders.UpdateOriginalVolume(positionID, remainingVol);
      PrintFormat("[GoldAlgo] Partial close detected (vol=%.2f/%.2f), remaining=%.2f, skipping self-correction",
                  dealVolume, origVolume, remainingVol);
      return;
     }

   double entryScore = g_orders.GetEntryScore(positionID);
   ENUM_MARKET_REGIME regime = g_orders.GetEntryRegime(positionID);
   ENUM_SIGNAL_DIR dir = g_orders.GetEntryDirection(positionID);

   // Feed to risk manager for self-correction
   g_risk.OnTradeClosed(pnl, entryScore, regime, dir);
  }

//+------------------------------------------------------------------+
//| Strategy Tester optimization criterion                            |
//+------------------------------------------------------------------+
double OnTester()
  {
   // Fetch tester statistics
   double netProfit     = TesterStatistics(STAT_PROFIT);
   double grossProfit   = TesterStatistics(STAT_GROSS_PROFIT);
   double grossLoss     = TesterStatistics(STAT_GROSS_LOSS);
   double maxDrawdown   = TesterStatistics(STAT_EQUITY_DD_RELATIVE);
   int    totalTrades   = (int)TesterStatistics(STAT_TRADES);
   double profitFactor  = TesterStatistics(STAT_PROFIT_FACTOR);
   double sharpeRatio   = TesterStatistics(STAT_SHARPE_RATIO);
   double recoveryFactor= TesterStatistics(STAT_RECOVERY_FACTOR);
   double expectedPayoff= TesterStatistics(STAT_EXPECTED_PAYOFF);

   //--- Reject poor runs
   if(totalTrades < 30)
      return -1.0;  // Not enough trades to evaluate

   if(maxDrawdown > 25.0)
      return -2.0;  // Excessive drawdown

   if(profitFactor < 1.0)
      return -3.0;  // Unprofitable

   if(netProfit <= 0)
      return -4.0;

   //--- Composite score: profit * PF * sqrt(trades) / (DD + 1)
   // This balances profitability, consistency, trade frequency, and risk
   double score = (netProfit * profitFactor * MathSqrt((double)totalTrades)) / (maxDrawdown + 1.0);

   // Sharpe bonus
   if(sharpeRatio > 0)
      score *= (1.0 + sharpeRatio * 0.1);

   // Recovery factor bonus
   if(recoveryFactor > 1.0)
      score *= (1.0 + MathLog(recoveryFactor) * 0.1);

   PrintFormat("[GoldAlgo] OnTester: Profit=%.2f, PF=%.2f, DD=%.1f%%, Trades=%d, Sharpe=%.2f, Score=%.2f",
               netProfit, profitFactor, maxDrawdown, totalTrades, sharpeRatio, score);

   return score;
  }

//+------------------------------------------------------------------+
//| Chart event handler (optional visual feedback)                    |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   // Could be used for on-chart dashboard in future
  }
//+------------------------------------------------------------------+
