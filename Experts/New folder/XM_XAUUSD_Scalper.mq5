//+------------------------------------------------------------------+
//|                                          XM_XAUUSD_Scalper.mq5  |
//|                        Advanced Gold Scalper EA                  |
//|                              Copyright 2024-2026, XM_XAUUSD Bot  |
//+------------------------------------------------------------------+
#property copyright "2024-2026, XM_XAUUSD Bot"
#property link      "https://github.com/Pusparaj99op/XM_XAUUSD"
#property version   "1.00"
#property description "Advanced XAUUSD Scalper for XM Broker"
#property description "Multi-strategy ensemble with self-correction"
#property description "Features: Telegram, JSON export, News filter"
#property strict

//+------------------------------------------------------------------+
//| Includes                                                          |
//+------------------------------------------------------------------+
#include <XM_XAUUSD\XM_Config.mqh>
#include <XM_XAUUSD\XM_Indicators.mqh>
#include <XM_XAUUSD\XM_PriceAction.mqh>
#include <XM_XAUUSD\XM_OrderManager.mqh>
#include <XM_XAUUSD\XM_RiskGuard.mqh>
#include <XM_XAUUSD\XM_Telegram.mqh>
#include <XM_XAUUSD\XM_JsonExport.mqh>
#include <XM_XAUUSD\XM_NewsFilter.mqh>

//+------------------------------------------------------------------+
//| Global Objects                                                    |
//+------------------------------------------------------------------+
CIndicatorManager    g_indicators;
CPriceActionAnalyzer g_priceAction;
COrderManager        g_orderManager;
CRiskGuard           g_riskGuard;
CTelegramNotifier    g_telegram;
CJsonExporter        g_jsonExporter;
CNewsFilter          g_newsFilter;

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
datetime   g_lastBarTime = 0;
int        g_tickCount = 0;
bool       g_isInitialized = false;
MarketState g_marketState;
TradeSignal g_currentSignal;
datetime   g_dailySummaryTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("====================================");
   Print(EA_NAME, " v", EA_VERSION);
   Print("Initializing...");
   Print("====================================");

   // Validate symbol
   string actualSymbol = InpSymbol;
   if(!SymbolSelect(actualSymbol, true))
   {
      // Try alternate symbol names
      if(SymbolSelect("XAUUSD", true))
         actualSymbol = "XAUUSD";
      else if(SymbolSelect("Gold", true))
         actualSymbol = "Gold";
      else if(SymbolSelect("GOLD", true))
         actualSymbol = "GOLD";
      else
      {
         Print("Error: Symbol not found. Please check symbol name.");
         return INIT_PARAMETERS_INCORRECT;
      }
      Print("Using symbol: ", actualSymbol);
   }

   // Initialize Order Manager
   if(!g_orderManager.Initialize(actualSymbol, InpTimeframe, InpMagicNumber, InpEAComment))
   {
      Print("Error: Failed to initialize Order Manager");
      return INIT_FAILED;
   }

   // Initialize Indicator Manager
   if(!g_indicators.Initialize(actualSymbol, InpTimeframe))
   {
      Print("Error: Failed to initialize Indicators");
      return INIT_FAILED;
   }

   // Initialize Price Action Analyzer
   if(!g_priceAction.Initialize(actualSymbol, InpTimeframe))
   {
      Print("Error: Failed to initialize Price Action");
      return INIT_FAILED;
   }

   // Initialize Risk Guard
   if(!g_riskGuard.Initialize(actualSymbol, &g_orderManager))
   {
      Print("Error: Failed to initialize Risk Guard");
      return INIT_FAILED;
   }

   // Initialize Telegram (optional)
   if(InpUseTelegram && StringLen(InpTelegramBotToken) > 0 && StringLen(InpTelegramChatID) > 0)
   {
      g_telegram.Initialize(InpTelegramBotToken, InpTelegramChatID);
      g_telegram.SendMessage("🤖 " + EA_NAME + " started on " + actualSymbol);
   }

   // Initialize JSON Exporter (optional)
   if(InpEnableJsonExport)
   {
      g_jsonExporter.Initialize(actualSymbol, InpTimeframe, InpJsonFilename, InpJsonUpdateSeconds);
   }

   // Initialize News Filter (optional)
   if(InpUseNewsFilter)
   {
      g_newsFilter.Initialize(InpNewsAPIEndpoint, InpNewsMinutesBefore, InpNewsMinutesAfter);
   }

   // Create dashboard
   if(InpShowDashboard)
   {
      CreateDashboard();
   }

   g_isInitialized = true;
   g_lastBarTime = iTime(actualSymbol, InpTimeframe, 0);

   Print("====================================");
   Print("Initialization complete!");
   Print("Symbol: ", actualSymbol);
   Print("Timeframe: M5");
   Print("Magic Number: ", InpMagicNumber);
   Print("Risk per trade: ", InpRiskPercent, "%");
   Print("====================================");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Deinitializing ", EA_NAME);

   // Cleanup
   g_indicators.Deinitialize();
   g_jsonExporter.Deinitialize();

   // Remove all chart drawings
   ObjectsDeleteAll(0, "XM_Dashboard_");
   ObjectsDeleteAll(0, "XM_Panel_");
   g_priceAction.CleanupDrawings();
   g_orderManager.CleanupTradeDrawings();

   // Send shutdown notification
   if(InpUseTelegram)
   {
      g_telegram.SendMessage("🛑 " + EA_NAME + " stopped. Reason: " + IntegerToString(reason));
   }

   Print("Deinitialization complete");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!g_isInitialized) return;

   g_tickCount++;

   // Check for new bar
   datetime currentBarTime = iTime(InpSymbol, InpTimeframe, 0);
   bool isNewBar = (currentBarTime != g_lastBarTime);

   if(isNewBar)
   {
      g_lastBarTime = currentBarTime;
      OnNewBar();
   }

   // Always manage open positions
   ManageOpenPositions();

   // Update trade SL/TP lines on every tick
   if(InpDrawSLTPLines)
   {
      g_orderManager.UpdateTradeLines();
   }

   // Update JSON export periodically
   if(InpEnableJsonExport && g_jsonExporter.ShouldUpdate())
   {
      UpdateAndExportData();
   }

   // Update dashboard
   if(InpShowDashboard && g_tickCount % 10 == 0) // Every 10 ticks
   {
      UpdateDashboard();
   }

   // Process Telegram queue
   if(InpUseTelegram)
   {
      g_telegram.ProcessQueue();
   }

   // Daily summary check
   CheckDailySummary();
}

//+------------------------------------------------------------------+
//| New Bar Handler                                                   |
//+------------------------------------------------------------------+
void OnNewBar()
{
   // Update indicators
   if(!g_indicators.UpdateIndicators())
   {
      Print("Warning: Failed to update indicators");
      return;
   }

   // Update price action analysis
   g_priceAction.UpdateAnalysis();

   // Draw technical levels on chart
   if(InpDrawSRLevels)
      g_priceAction.DrawSupportResistanceLevels();
   if(InpDrawOrderBlocks)
      g_priceAction.DrawOrderBlocks();
   if(InpDrawSwingPoints)
      g_priceAction.DrawSwingPoints();

   // Update self-correction
   g_riskGuard.UpdateSelfCorrection();

   // Get market state
   g_indicators.FillMarketState(g_marketState);

   // Check if can trade
   if(!CanTrade())
   {
      if(InpDebugMode)
         Print("Trading conditions not met: ", g_riskGuard.GetPauseReason());
      return;
   }

   // Generate trading signal
   g_currentSignal = GenerateEnsembleSignal();

   // Execute signal if valid
   if(g_currentSignal.direction != SIGNAL_NONE && g_currentSignal.signalCount >= InpMinSignalsRequired)
   {
      ExecuteTrade(g_currentSignal);
   }
}

//+------------------------------------------------------------------+
//| Check if Can Trade                                                |
//+------------------------------------------------------------------+
bool CanTrade()
{
   // Check risk guard
   if(!g_riskGuard.CanOpenNewTrade())
      return false;

   // Check news filter
   if(InpUseNewsFilter && !g_newsFilter.IsTradingSafe())
   {
      if(InpDebugMode)
         Print("News filter: ", g_newsFilter.GetPauseReason());
      return false;
   }

   // Check spread
   if(!g_orderManager.IsSpreadOK())
   {
      if(InpDebugMode)
         Print("Spread too high");
      return false;
   }

   // Check if market is open
   if(!g_orderManager.IsMarketOpen())
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Generate Ensemble Signal                                          |
//+------------------------------------------------------------------+
TradeSignal GenerateEnsembleSignal()
{
   TradeSignal signal;
   signal.direction = SIGNAL_NONE;
   signal.strength = 0;
   signal.signalCount = 0;
   signal.reason = "";
   signal.signalTime = TimeCurrent();

   int buyVotes = 0;
   int sellVotes = 0;
   double buyWeight = 0;
   double sellWeight = 0;
   string reasons = "";

   // Signal 1: Indicator Confluence
   if(InpUseIndicatorSignal)
   {
      TradeSignal indicatorSignal = g_indicators.GetConfluenceSignal();
      if(indicatorSignal.direction == SIGNAL_BUY)
      {
         buyVotes++;
         buyWeight += InpIndicatorWeight * indicatorSignal.strength;
         reasons += "IND ";
      }
      else if(indicatorSignal.direction == SIGNAL_SELL)
      {
         sellVotes++;
         sellWeight += InpIndicatorWeight * indicatorSignal.strength;
         reasons += "IND ";
      }
   }

   // Signal 2: Price Action
   if(InpUsePriceAction)
   {
      ENUM_SIGNAL_TYPE paSignal = g_priceAction.GetPriceActionSignal();
      if(paSignal == SIGNAL_BUY)
      {
         buyVotes++;
         buyWeight += InpPriceActionWeight;
         reasons += "PA ";
      }
      else if(paSignal == SIGNAL_SELL)
      {
         sellVotes++;
         sellWeight += InpPriceActionWeight;
         reasons += "PA ";
      }

      // Order block signal
      ENUM_SIGNAL_TYPE obSignal = g_priceAction.GetOrderBlockSignal();
      if(obSignal == SIGNAL_BUY)
      {
         buyVotes++;
         buyWeight += InpPriceActionWeight * 0.8;
         reasons += "OB ";
      }
      else if(obSignal == SIGNAL_SELL)
      {
         sellVotes++;
         sellWeight += InpPriceActionWeight * 0.8;
         reasons += "OB ";
      }
   }

   // Signal 3: Volatility Breakout
   if(InpUseVolatilityBreak)
   {
      ENUM_SIGNAL_TYPE volSignal = GetVolatilityBreakoutSignal();
      if(volSignal == SIGNAL_BUY)
      {
         buyVotes++;
         buyWeight += InpVolatilityWeight;
         reasons += "VOL ";
      }
      else if(volSignal == SIGNAL_SELL)
      {
         sellVotes++;
         sellWeight += InpVolatilityWeight;
         reasons += "VOL ";
      }
   }

   // Signal 4: S/R Breakout
   ENUM_SIGNAL_TYPE srSignal = g_priceAction.GetSRBreakoutSignal();
   if(srSignal == SIGNAL_BUY)
   {
      buyVotes++;
      buyWeight += InpPriceActionWeight * 0.7;
      reasons += "SR_BO ";
   }
   else if(srSignal == SIGNAL_SELL)
   {
      sellVotes++;
      sellWeight += InpPriceActionWeight * 0.7;
      reasons += "SR_BO ";
   }

   // Determine final signal
   if(buyVotes >= InpMinSignalsRequired && buyVotes > sellVotes)
   {
      signal.direction = SIGNAL_BUY;
      signal.signalCount = buyVotes;
      signal.strength = MathMin(1.0, buyWeight / 3.0);
      signal.reason = reasons;
      signal.entryPrice = SymbolInfoDouble(InpSymbol, SYMBOL_ASK);
   }
   else if(sellVotes >= InpMinSignalsRequired && sellVotes > buyVotes)
   {
      signal.direction = SIGNAL_SELL;
      signal.signalCount = sellVotes;
      signal.strength = MathMin(1.0, sellWeight / 3.0);
      signal.reason = reasons;
      signal.entryPrice = SymbolInfoDouble(InpSymbol, SYMBOL_BID);
   }

   return signal;
}

//+------------------------------------------------------------------+
//| Get Volatility Breakout Signal                                    |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE GetVolatilityBreakoutSignal()
{
   double atr = g_indicators.GetATR(0);
   double atrPrev = g_indicators.GetATR(1);
   double bbWidth = g_indicators.GetBBWidth(0);
   double bbWidthPrev = g_indicators.GetBBWidth(1);

   double close = iClose(InpSymbol, InpTimeframe, 0);
   double closePrev = iClose(InpSymbol, InpTimeframe, 1);
   double open = iOpen(InpSymbol, InpTimeframe, 0);

   ENUM_VOLATILITY_STATE volState = g_indicators.GetVolatilityState();

   // Volatility expansion with directional breakout
   if((volState == VOL_HIGH || (InpVolBreakMedium && volState == VOL_NORMAL)) && bbWidth > bbWidthPrev * 1.2)
   {
      // Strong bullish candle with volatility expansion
      if(close > open && close - open > atr * 0.5)
      {
         // Price breaking upper band
         if(close > g_indicators.GetBBUpper(0))
            return SIGNAL_BUY;
      }
      // Strong bearish candle with volatility expansion
      else if(close < open && open - close > atr * 0.5)
      {
         // Price breaking lower band
         if(close < g_indicators.GetBBLower(0))
            return SIGNAL_SELL;
      }
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Execute Trade                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(TradeSignal &signal)
{
   // Calculate SL/TP
   double atr = g_indicators.GetATR(0);
   double sl, tp;

   if(signal.direction == SIGNAL_BUY)
   {
      signal.entryPrice = SymbolInfoDouble(InpSymbol, SYMBOL_ASK);

      // Get S/R levels for dynamic SL/TP
      double nearestSupport = g_priceAction.GetNearestSupport(signal.entryPrice);
      double nearestResistance = g_priceAction.GetNearestResistance(signal.entryPrice);

      sl = g_orderManager.CalculateDynamicSL(SIGNAL_BUY, signal.entryPrice, atr, nearestSupport);
      tp = g_orderManager.CalculateDynamicTP(SIGNAL_BUY, signal.entryPrice, atr, nearestResistance);
   }
   else // SELL
   {
      signal.entryPrice = SymbolInfoDouble(InpSymbol, SYMBOL_BID);

      double nearestSupport = g_priceAction.GetNearestSupport(signal.entryPrice);
      double nearestResistance = g_priceAction.GetNearestResistance(signal.entryPrice);

      sl = g_orderManager.CalculateDynamicSL(SIGNAL_SELL, signal.entryPrice, atr, nearestResistance);
      tp = g_orderManager.CalculateDynamicTP(SIGNAL_SELL, signal.entryPrice, atr, nearestSupport);
   }

   signal.stopLoss = sl;
   signal.takeProfit = tp;

   // Calculate lot size
   double slPips = MathAbs(signal.entryPrice - sl) / (SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10);
   double riskPercent = g_riskGuard.GetAdjustedRiskPercent();
   double lots = g_riskGuard.CalculatePositionSize(riskPercent, slPips);

   // Execute
   bool success = false;
   if(signal.direction == SIGNAL_BUY)
   {
      success = g_orderManager.OpenBuy(lots, sl, tp, signal.reason);
   }
   else
   {
      success = g_orderManager.OpenSell(lots, sl, tp, signal.reason);
   }

   if(success)
   {
      Print("Trade opened: ", (signal.direction == SIGNAL_BUY ? "BUY" : "SELL"));
      Print("Lots: ", lots, " SL: ", sl, " TP: ", tp);
      Print("Signals: ", signal.signalCount, " Reason: ", signal.reason);

      // Draw trade on chart
      g_orderManager.DrawTradeOnChart(signal.direction, signal.entryPrice, sl, tp, lots, signal.reason);

      // Send Telegram notification
      if(InpUseTelegram)
      {
         g_telegram.SendTradeAlert(
            (signal.direction == SIGNAL_BUY ? "BUY" : "SELL"),
            InpSymbol,
            lots,
            signal.entryPrice,
            sl,
            tp,
            signal.reason
         );
      }
   }
}

//+------------------------------------------------------------------+
//| Manage Open Positions                                             |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   // Trailing stop
   if(InpUseTrailingStop)
   {
      g_orderManager.ManageTrailingStop();
   }

   // Breakeven
   if(InpUseBreakeven)
   {
      g_orderManager.ManageBreakeven();
   }

   // Check for drawdown emergency
   if(g_riskGuard.ShouldReduceExposure())
   {
      // Could implement partial close here
      if(InpDebugMode)
         Print("Warning: Approaching drawdown limits");
   }

   // Check if daily limit reached - close all
   RiskMetrics metrics = g_riskGuard.GetMetrics();
   if(metrics.dailyDrawdown >= InpDailyDrawdownLimit)
   {
      Print("Daily drawdown limit reached. Closing all positions.");
      g_orderManager.CloseAllPositions();

      if(InpUseTelegram)
      {
         g_telegram.SendDrawdownAlert(metrics.dailyDrawdown, "DAILY LIMIT REACHED");
      }
   }
}

//+------------------------------------------------------------------+
//| Update and Export Data                                            |
//+------------------------------------------------------------------+
void UpdateAndExportData()
{
   g_riskGuard.UpdateMetrics();
   RiskMetrics metrics = g_riskGuard.GetMetrics();

   g_jsonExporter.ExportData(g_marketState, metrics, g_currentSignal);
}

//+------------------------------------------------------------------+
//| Check Daily Summary                                               |
//+------------------------------------------------------------------+
void CheckDailySummary()
{
   if(!InpUseTelegram || !InpTelegramDailySummary) return;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // Send summary at end of trading day (22:00)
   if(dt.hour == 22 && dt.min == 0)
   {
      datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
      if(g_dailySummaryTime != today)
      {
         g_dailySummaryTime = today;

         RiskMetrics metrics = g_riskGuard.GetMetrics();
         g_telegram.SendDailySummary(
            metrics.accountBalance,
            metrics.accountEquity,
            metrics.dailyPnL,
            metrics.totalTrades,
            metrics.winRate
         );
      }
   }
}

//+------------------------------------------------------------------+
//| Trade Transaction Handler                                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   // Handle trade close notifications
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
      {
         // Deal was added - could be open or close
         ulong dealTicket = trans.deal;

         if(HistoryDealSelect(dealTicket))
         {
            ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

            if(dealEntry == DEAL_ENTRY_OUT)
            {
               // Position closed
               double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
               double volume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
               string symbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
               double price = HistoryDealGetDouble(dealTicket, DEAL_PRICE);

               // Update history
               g_orderManager.UpdateTradeHistory();

               // Draw close marker on chart
               g_orderManager.DrawTradeClose(dealTicket, price, profit);

               // Update self-correction
               g_riskGuard.UpdateSelfCorrection();

               // Send notification
               if(InpUseTelegram)
               {
                  g_telegram.SendTradeClose(symbol, volume, profit, 0);
               }

               Print("Trade closed. Profit: ", profit);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Create Dashboard                                                  |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   int x = 10;
   int y = 20;

   // Background panel
   string panelName = "XM_Panel_BG";
   ObjectCreate(0, panelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, panelName, OBJPROP_XDISTANCE, 5);
   ObjectSetInteger(0, panelName, OBJPROP_YDISTANCE, 15);
   ObjectSetInteger(0, panelName, OBJPROP_XSIZE, 280);
   ObjectSetInteger(0, panelName, OBJPROP_YSIZE, 520);
   ObjectSetInteger(0, panelName, OBJPROP_BGCOLOR, C'15,15,25');
   ObjectSetInteger(0, panelName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, panelName, OBJPROP_BORDER_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, panelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, panelName, OBJPROP_BACK, false);
   ObjectSetInteger(0, panelName, OBJPROP_SELECTABLE, false);

   // Header separator
   string sepName = "XM_Panel_Sep1";
   ObjectCreate(0, sepName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, sepName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, sepName, OBJPROP_YDISTANCE, 50);
   ObjectSetInteger(0, sepName, OBJPROP_XSIZE, 270);
   ObjectSetInteger(0, sepName, OBJPROP_YSIZE, 2);
   ObjectSetInteger(0, sepName, OBJPROP_BGCOLOR, clrDodgerBlue);
   ObjectSetInteger(0, sepName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, sepName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, sepName, OBJPROP_SELECTABLE, false);

   // Title
   CreateLabel("XM_Dashboard_Title", x, y, EA_NAME, clrGold, 11); y += 35;

   // Account section
   CreateLabel("XM_Dashboard_Status", x, y, "Status: Initializing...", clrWhite, 10); y += 20;
   CreateLabel("XM_Dashboard_Balance", x, y, "Balance: $0.00", clrWhite, 10); y += 20;
   CreateLabel("XM_Dashboard_Equity", x, y, "Equity: $0.00", clrWhite, 10); y += 20;
   CreateLabel("XM_Dashboard_DailyPnL", x, y, "Daily P&L: $0.00", clrWhite, 10); y += 20;
   CreateLabel("XM_Dashboard_Drawdown", x, y, "Drawdown: 0.00%", clrWhite, 10); y += 22;

   // Separator 2
   string sepName2 = "XM_Panel_Sep2";
   ObjectCreate(0, sepName2, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, sepName2, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, sepName2, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, sepName2, OBJPROP_XSIZE, 270);
   ObjectSetInteger(0, sepName2, OBJPROP_YSIZE, 1);
   ObjectSetInteger(0, sepName2, OBJPROP_BGCOLOR, clrSlateGray);
   ObjectSetInteger(0, sepName2, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, sepName2, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, sepName2, OBJPROP_SELECTABLE, false);
   y += 5;

   // Trade Stats section
   CreateLabel("XM_Dashboard_Trades", x, y, "Trades: 0 | Win: 0%", clrWhite, 10); y += 20;
   CreateLabel("XM_Dashboard_Positions", x, y, "Open: 0 positions", clrWhite, 10); y += 20;
   CreateLabel("XM_Dashboard_LotMult", x, y, "Lot Mult: 1.00x", clrWhite, 10); y += 22;

   // Separator 3
   string sepName3 = "XM_Panel_Sep3";
   ObjectCreate(0, sepName3, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, sepName3, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, sepName3, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, sepName3, OBJPROP_XSIZE, 270);
   ObjectSetInteger(0, sepName3, OBJPROP_YSIZE, 1);
   ObjectSetInteger(0, sepName3, OBJPROP_BGCOLOR, clrSlateGray);
   ObjectSetInteger(0, sepName3, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, sepName3, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, sepName3, OBJPROP_SELECTABLE, false);
   y += 5;

   // Signal section
   CreateLabel("XM_Dashboard_Signal", x, y, "Signal: None", clrGray, 10); y += 20;
   CreateLabel("XM_Dashboard_SignalDetail", x, y, "Sources: ---", clrGray, 9); y += 20;
   CreateLabel("XM_Dashboard_RSI", x, y, "RSI: 50.00", clrWhite, 10); y += 20;
   CreateLabel("XM_Dashboard_ATR", x, y, "ATR: 0.00", clrWhite, 10); y += 20;
   CreateLabel("XM_Dashboard_Trend", x, y, "Trend: None", clrGray, 10); y += 20;
   CreateLabel("XM_Dashboard_Spread", x, y, "Spread: 0.0", clrWhite, 10); y += 22;

   // Separator 4
   string sepName4 = "XM_Panel_Sep4";
   ObjectCreate(0, sepName4, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, sepName4, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, sepName4, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, sepName4, OBJPROP_XSIZE, 270);
   ObjectSetInteger(0, sepName4, OBJPROP_YSIZE, 2);
   ObjectSetInteger(0, sepName4, OBJPROP_BGCOLOR, clrGold);
   ObjectSetInteger(0, sepName4, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, sepName4, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, sepName4, OBJPROP_SELECTABLE, false);
   y += 5;

   // Active Trade Info section
   CreateLabel("XM_Dashboard_TradeHeader", x, y, "ACTIVE TRADE", clrGold, 10); y += 20;
   CreateLabel("XM_Dashboard_TradeDir", x, y, "Direction: NO TRADE", clrGray, 10); y += 20;
   CreateLabel("XM_Dashboard_TradeEntry", x, y, "Entry: ---", clrWhite, 9); y += 18;
   CreateLabel("XM_Dashboard_TradeSL", x, y, "SL: ---", clrRed, 9); y += 18;
   CreateLabel("XM_Dashboard_TradeTP", x, y, "TP: ---", clrLime, 9); y += 18;
   CreateLabel("XM_Dashboard_TradeLots", x, y, "Lots: ---", clrWhite, 9); y += 18;
   CreateLabel("XM_Dashboard_TradePnL", x, y, "P&L: $0.00 (0.0 pips)", clrWhite, 10); y += 18;
   CreateLabel("XM_Dashboard_TradeRR", x, y, "R:R = ---", clrWhite, 9); y += 18;
   CreateLabel("XM_Dashboard_TradeDur", x, y, "Duration: ---", clrGray, 9); y += 5;

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Create Label Helper                                               |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize = 10)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| Update Dashboard                                                  |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!InpShowDashboard) return;

   RiskMetrics metrics = g_riskGuard.GetMetrics();

   // Status
   string status = metrics.tradingEnabled ? "ACTIVE" : "PAUSED";
   color statusColor = metrics.tradingEnabled ? clrLime : clrRed;
   ObjectSetString(0, "XM_Dashboard_Status", OBJPROP_TEXT, "Status: " + status);
   ObjectSetInteger(0, "XM_Dashboard_Status", OBJPROP_COLOR, statusColor);

   // Balance/Equity
   ObjectSetString(0, "XM_Dashboard_Balance", OBJPROP_TEXT,
                   StringFormat("Balance: $%.2f", metrics.accountBalance));
   ObjectSetString(0, "XM_Dashboard_Equity", OBJPROP_TEXT,
                   StringFormat("Equity: $%.2f", metrics.accountEquity));

   // Daily P&L
   color pnlColor = (metrics.dailyPnL >= 0) ? clrLime : clrRed;
   string pnlSign = (metrics.dailyPnL >= 0) ? "+" : "";
   ObjectSetString(0, "XM_Dashboard_DailyPnL", OBJPROP_TEXT,
                   StringFormat("Daily P&L: %s$%.2f", pnlSign, metrics.dailyPnL));
   ObjectSetInteger(0, "XM_Dashboard_DailyPnL", OBJPROP_COLOR, pnlColor);

   // Drawdown
   color ddColor = (metrics.dailyDrawdown < 3) ? clrWhite :
                   (metrics.dailyDrawdown < 5) ? clrYellow : clrRed;
   ObjectSetString(0, "XM_Dashboard_Drawdown", OBJPROP_TEXT,
                   StringFormat("Drawdown: %.2f%%", metrics.dailyDrawdown));
   ObjectSetInteger(0, "XM_Dashboard_Drawdown", OBJPROP_COLOR, ddColor);

   // Trades
   ObjectSetString(0, "XM_Dashboard_Trades", OBJPROP_TEXT,
                   StringFormat("Trades: %d | Win: %.1f%%", metrics.totalTrades, metrics.winRate));

   // Open positions
   int openPos = g_orderManager.CountOpenPositions();
   ObjectSetString(0, "XM_Dashboard_Positions", OBJPROP_TEXT,
                   StringFormat("Open: %d positions", openPos));

   // Lot multiplier
   ObjectSetString(0, "XM_Dashboard_LotMult", OBJPROP_TEXT,
                   StringFormat("Lot Mult: %.2fx", metrics.currentLotMultiplier));

   // Signal
   string signalText = "None";
   color signalColor = clrGray;
   if(g_currentSignal.direction == SIGNAL_BUY)
   {
      signalText = "BUY (" + IntegerToString(g_currentSignal.signalCount) + ")";
      signalColor = clrLime;
   }
   else if(g_currentSignal.direction == SIGNAL_SELL)
   {
      signalText = "SELL (" + IntegerToString(g_currentSignal.signalCount) + ")";
      signalColor = clrRed;
   }
   ObjectSetString(0, "XM_Dashboard_Signal", OBJPROP_TEXT, "Signal: " + signalText);
   ObjectSetInteger(0, "XM_Dashboard_Signal", OBJPROP_COLOR, signalColor);

   // Signal detail (sources)
   string sourcesText = "Sources: ";
   if(g_currentSignal.reason != "")
      sourcesText += g_currentSignal.reason;
   else
      sourcesText += "---";
   ObjectSetString(0, "XM_Dashboard_SignalDetail", OBJPROP_TEXT, sourcesText);
   ObjectSetInteger(0, "XM_Dashboard_SignalDetail", OBJPROP_COLOR,
      (g_currentSignal.direction != SIGNAL_NONE) ? clrWhite : clrGray);

   // Indicators
   ObjectSetString(0, "XM_Dashboard_RSI", OBJPROP_TEXT,
                   StringFormat("RSI: %.2f", g_marketState.rsi));
   ObjectSetString(0, "XM_Dashboard_ATR", OBJPROP_TEXT,
                   StringFormat("ATR: %.2f", g_marketState.atr));

   // Spread
   double spread = SymbolInfoDouble(InpSymbol, SYMBOL_ASK) - SymbolInfoDouble(InpSymbol, SYMBOL_BID);
   double spreadPips = spread / (SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10);
   color spreadColor = (spreadPips < 3.0) ? clrLime : (spreadPips < 5.0) ? clrYellow : clrRed;
   ObjectSetString(0, "XM_Dashboard_Spread", OBJPROP_TEXT,
                   StringFormat("Spread: %.1f pips", spreadPips));
   ObjectSetInteger(0, "XM_Dashboard_Spread", OBJPROP_COLOR, spreadColor);

   // Trend
   string trendText = "None";
   color trendColor = clrGray;
   if(g_marketState.trend == TREND_UP)
   {
      trendText = "UP ^";
      trendColor = clrLime;
   }
   else if(g_marketState.trend == TREND_DOWN)
   {
      trendText = "DOWN v";
      trendColor = clrRed;
   }
   ObjectSetString(0, "XM_Dashboard_Trend", OBJPROP_TEXT, "Trend: " + trendText);
   ObjectSetInteger(0, "XM_Dashboard_Trend", OBJPROP_COLOR, trendColor);

   // ===== ACTIVE TRADE INFO SECTION =====
   UpdateTradeInfoPanel();

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Update Active Trade Info Panel                                    |
//+------------------------------------------------------------------+
void UpdateTradeInfoPanel()
{
   CPositionInfo posInfo;
   bool hasPosition = false;

   // Find our most recent open position
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol() != InpSymbol) continue;
      if(posInfo.Magic() != InpMagicNumber) continue;
      hasPosition = true;
      break; // Take the first matching position
   }

   if(hasPosition)
   {
      // Direction
      bool isBuy = (posInfo.PositionType() == POSITION_TYPE_BUY);
      string dirText = isBuy ? ">> BUY <<" : ">> SELL <<";
      color dirColor = isBuy ? clrDodgerBlue : clrOrangeRed;
      ObjectSetString(0, "XM_Dashboard_TradeDir", OBJPROP_TEXT, dirText);
      ObjectSetInteger(0, "XM_Dashboard_TradeDir", OBJPROP_COLOR, dirColor);

      // Entry price
      double entry = posInfo.PriceOpen();
      ObjectSetString(0, "XM_Dashboard_TradeEntry", OBJPROP_TEXT,
         StringFormat("Entry: %.2f", entry));

      // SL
      double sl = posInfo.StopLoss();
      ObjectSetString(0, "XM_Dashboard_TradeSL", OBJPROP_TEXT,
         StringFormat("SL: %.2f (%.1f pips)", sl,
            MathAbs(entry - sl) / (SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10)));
      ObjectSetInteger(0, "XM_Dashboard_TradeSL", OBJPROP_COLOR, clrRed);

      // TP
      double tp = posInfo.TakeProfit();
      ObjectSetString(0, "XM_Dashboard_TradeTP", OBJPROP_TEXT,
         StringFormat("TP: %.2f (%.1f pips)", tp,
            MathAbs(tp - entry) / (SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10)));
      ObjectSetInteger(0, "XM_Dashboard_TradeTP", OBJPROP_COLOR, clrLime);

      // Lots
      ObjectSetString(0, "XM_Dashboard_TradeLots", OBJPROP_TEXT,
         StringFormat("Lots: %.2f", posInfo.Volume()));

      // P&L
      double pnl = posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
      double currentPrice = isBuy ? SymbolInfoDouble(InpSymbol, SYMBOL_BID) : SymbolInfoDouble(InpSymbol, SYMBOL_ASK);
      double pnlPips = isBuy ?
         (currentPrice - entry) / (SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10) :
         (entry - currentPrice) / (SymbolInfoDouble(InpSymbol, SYMBOL_POINT) * 10);
      color plColor = (pnl >= 0) ? clrLime : clrRed;
      ObjectSetString(0, "XM_Dashboard_TradePnL", OBJPROP_TEXT,
         StringFormat("P&L: %s$%.2f (%.1f pips)", (pnl >= 0 ? "+" : ""), pnl, pnlPips));
      ObjectSetInteger(0, "XM_Dashboard_TradePnL", OBJPROP_COLOR, plColor);

      // R:R
      double slDist = MathAbs(entry - sl);
      double tpDist = MathAbs(tp - entry);
      double rr = (slDist > 0) ? tpDist / slDist : 0;
      ObjectSetString(0, "XM_Dashboard_TradeRR", OBJPROP_TEXT,
         StringFormat("R:R = 1:%.1f", rr));

      // Duration
      datetime openTime = posInfo.Time();
      int durationSec = (int)(TimeCurrent() - openTime);
      int hours = durationSec / 3600;
      int mins = (durationSec % 3600) / 60;
      int secs = durationSec % 60;
      ObjectSetString(0, "XM_Dashboard_TradeDur", OBJPROP_TEXT,
         StringFormat("Duration: %d:%02d:%02d", hours, mins, secs));
      ObjectSetInteger(0, "XM_Dashboard_TradeDur", OBJPROP_COLOR, clrWhite);
   }
   else
   {
      // No active trade
      ObjectSetString(0, "XM_Dashboard_TradeDir", OBJPROP_TEXT, "NO ACTIVE TRADE");
      ObjectSetInteger(0, "XM_Dashboard_TradeDir", OBJPROP_COLOR, clrGray);
      ObjectSetString(0, "XM_Dashboard_TradeEntry", OBJPROP_TEXT, "Entry: ---");
      ObjectSetString(0, "XM_Dashboard_TradeSL", OBJPROP_TEXT, "SL: ---");
      ObjectSetInteger(0, "XM_Dashboard_TradeSL", OBJPROP_COLOR, clrGray);
      ObjectSetString(0, "XM_Dashboard_TradeTP", OBJPROP_TEXT, "TP: ---");
      ObjectSetInteger(0, "XM_Dashboard_TradeTP", OBJPROP_COLOR, clrGray);
      ObjectSetString(0, "XM_Dashboard_TradeLots", OBJPROP_TEXT, "Lots: ---");
      ObjectSetString(0, "XM_Dashboard_TradePnL", OBJPROP_TEXT, "P&L: ---");
      ObjectSetInteger(0, "XM_Dashboard_TradePnL", OBJPROP_COLOR, clrGray);
      ObjectSetString(0, "XM_Dashboard_TradeRR", OBJPROP_TEXT, "R:R = ---");
      ObjectSetString(0, "XM_Dashboard_TradeDur", OBJPROP_TEXT, "Duration: ---");
      ObjectSetInteger(0, "XM_Dashboard_TradeDur", OBJPROP_COLOR, clrGray);
   }
}

//+------------------------------------------------------------------+
//| Tester Event Handler (for optimization)                           |
//+------------------------------------------------------------------+
double OnTester()
{
   // Custom optimization criterion
   // Maximize: Profit Factor * Sqrt(Number of Trades) / Max Drawdown

   double profitFactor = TesterStatistics(STAT_PROFIT_FACTOR);
   double trades = TesterStatistics(STAT_TRADES);
   double maxDD = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   double profit = TesterStatistics(STAT_PROFIT);

   if(trades < 20 || maxDD > 30 || profitFactor < 1.0)
      return 0; // Filter out bad results

   // Custom formula balancing profitability with consistency
   double score = (profit * profitFactor * MathSqrt(trades)) / (maxDD + 1);

   return score;
}
//+------------------------------------------------------------------+
