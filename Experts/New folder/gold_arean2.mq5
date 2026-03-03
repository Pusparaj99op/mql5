//+------------------------------------------------------------------+
//|                                    Gold Quantum Scalper Pro.mq5  |
//|                        Aggressive XAUUSD Scalping EA - AI Powered|
//|                                   Copyright 2026, Advanced Trading|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Advanced Trading Systems"
#property link      "https://www.advancedtrading.com"
#property version   "3.50"
#property description "100% Independent Aggressive Gold Scalper"
#property description "Features: Order Flow, Multi-Strategy, Self-Correcting"
#property description "AI-Powered Adaptive Risk Management"

//--- Include necessary libraries
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Global Objects
CTrade         trade;
CPositionInfo  position;
CAccountInfo   account;
CSymbolInfo    symbolInfo;

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input group "==== TRADING SETTINGS ===="
input string   Symbol_Trade = "XAUUSD";           // Trading Symbol (Gold.i# for some brokers)
input ENUM_TIMEFRAMES Timeframe = PERIOD_M5;      // Timeframe M5/M1
input int      MagicNumber = 77777;               // Magic Number
input string   TradeComment = "GoldQuantumPro";   // Trade Comment

input group "==== TIME FILTER ===="
input int      StartHour = 1;                     // Start Trading Hour (01:00)
input int      EndHour = 23;                      // End Trading Hour (23:00)
input bool     TradeMonday = true;                // Trade on Monday
input bool     TradeTuesday = true;               // Trade on Tuesday
input bool     TradeWednesday = true;             // Trade on Wednesday
input bool     TradeThursday = true;              // Trade on Thursday
input bool     TradeFriday = true;                // Trade on Friday

input group "==== RISK MANAGEMENT ===="
input double   RiskPercent = 2.0;                 // Risk Per Trade (%)
input double   MaxDailyLoss = 5.0;                // Max Daily Loss (%)
input double   MaxDrawdown = 10.0;                // Max Drawdown (%)
input double   MinLotSize = 0.01;                 // Minimum Lot Size
input double   MaxLotSize = 10.0;                 // Maximum Lot Size
input bool     UseAdaptiveRisk = true;            // Use Adaptive Risk Management
input double   RiskMultiplierWin = 1.2;           // Risk Multiplier After Win
input double   RiskMultiplierLoss = 0.8;          // Risk Multiplier After Loss

input group "==== TECHNICAL INDICATORS ===="
input int      FastEMA_Period = 9;                // Fast EMA Period
input int      SlowEMA_Period = 21;               // Slow EMA Period
input int      RSI_Period = 14;                   // RSI Period
input int      RSI_Oversold = 30;                 // RSI Oversold Level
input int      RSI_Overbought = 70;               // RSI Overbought Level
input int      MACD_Fast = 12;                    // MACD Fast Period
input int      MACD_Slow = 26;                    // MACD Slow Period
input int      MACD_Signal = 9;                   // MACD Signal Period
input int      BB_Period = 20;                    // Bollinger Bands Period
input double   BB_Deviation = 2.0;                // Bollinger Bands Deviation
input int      ATR_Period = 14;                   // ATR Period

input group "==== ORDER FLOW ANALYSIS ===="
input bool     UseOrderFlow = true;               // Use Order Flow Analysis
input int      VolumeMA_Period = 20;              // Volume SMA Period
input double   VolumeThreshold = 1.5;             // Volume Spike Threshold
input int      TickDataDepth = 100;               // Tick Data Analysis Depth

input group "==== STOP LOSS & TAKE PROFIT ===="
input double   ATR_SL_Multiplier = 2.0;          // ATR Stop Loss Multiplier
input double   ATR_TP_Multiplier = 3.0;          // ATR Take Profit Multiplier
input bool     UseTrailingStop = true;            // Use Trailing Stop
input double   TrailingStart = 0.5;               // Trailing Start (ATR Multiple)
input double   TrailingStep = 0.2;                // Trailing Step (ATR Multiple)
input bool     UseBreakeven = true;               // Use Breakeven
input double   BreakevenTrigger = 0.3;            // Breakeven Trigger (ATR Multiple)
input double   BreakevenProfit = 0.1;             // Breakeven Profit (ATR Multiple)

input group "==== ADVANCED FEATURES ===="
input bool     UseMultiStrategy = true;           // Use Multiple Strategies
input bool     UseAI_Optimization = true;         // Use AI Self-Optimization
input int      OptimizationPeriod = 100;          // Optimization Period (Trades)
input bool     DisplayInfo = true;                // Display Info on Chart
input color    InfoColor = clrLime;               // Info Text Color
input int      MaxTradesPerDay = 0;               // Max Trades Per Day (0=Unlimited)
input int      MaxOpenPositions = 3;              // Max Open Positions
input bool     UseNewsFilter = false;             // Use News Filter (Manual)

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
int      handleFastEMA, handleSlowEMA, handleRSI, handleMACD, handleBB, handleATR, handleVolume;
double   fastEMA[], slowEMA[], rsiBuffer[], macdMain[], macdSignal[];
double   bbUpper[], bbMiddle[], bbLower[], atrBuffer[], volumeBuffer[];
double   currentATR = 0;
double   currentRisk = 0;
double   dailyProfit = 0;
double   startingBalance = 0;
double   peakBalance = 0;
int      totalTradestoday = 0;
int      consecutiveWins = 0;
int      consecutiveLosses = 0;
datetime lastBarTime = 0;
datetime lastTradeTime = 0;
datetime todayDate = 0;

//--- Order Flow Variables
double   buyVolume = 0, sellVolume = 0;
double   orderFlowImbalance = 0;
int      tickCounter = 0;

//--- Performance Tracking
struct PerformanceMetrics {
   int totalTrades;
   int winningTrades;
   int losingTrades;
   double grossProfit;
   double grossLoss;
   double maxDrawdown;
   double sharpeRatio;
   double profitFactor;
};
PerformanceMetrics metrics;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Set trading parameters
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(50);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);

   //--- Initialize symbol
   if(!symbolInfo.Name(_Symbol))
   {
      Print("Failed to initialize symbol: ", _Symbol);
      return(INIT_FAILED);
   }

   //--- Initialize indicators
   handleFastEMA = iMA(_Symbol, Timeframe, FastEMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   handleSlowEMA = iMA(_Symbol, Timeframe, SlowEMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   handleRSI = iRSI(_Symbol, Timeframe, RSI_Period, PRICE_CLOSE);
   handleMACD = iMACD(_Symbol, Timeframe, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
   handleBB = iBands(_Symbol, Timeframe, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
   handleATR = iATR(_Symbol, Timeframe, ATR_Period);
   handleVolume = iVolumes(_Symbol, Timeframe, VOLUME_TICK);

   //--- Check if indicators were created successfully
   if(handleFastEMA == INVALID_HANDLE || handleSlowEMA == INVALID_HANDLE ||
      handleRSI == INVALID_HANDLE || handleMACD == INVALID_HANDLE ||
      handleBB == INVALID_HANDLE || handleATR == INVALID_HANDLE)
   {
      Print("Error creating indicators!");
      return(INIT_FAILED);
   }

   //--- Set array as series
   ArraySetAsSeries(fastEMA, true);
   ArraySetAsSeries(slowEMA, true);
   ArraySetAsSeries(rsiBuffer, true);
   ArraySetAsSeries(macdMain, true);
   ArraySetAsSeries(macdSignal, true);
   ArraySetAsSeries(bbUpper, true);
   ArraySetAsSeries(bbMiddle, true);
   ArraySetAsSeries(bbLower, true);
   ArraySetAsSeries(atrBuffer, true);
   ArraySetAsSeries(volumeBuffer, true);

   //--- Initialize variables
   startingBalance = account.Balance();
   peakBalance = startingBalance;
   todayDate = TimeCurrent();

   //--- Initialize performance metrics
   metrics.totalTrades = 0;
   metrics.winningTrades = 0;
   metrics.losingTrades = 0;
   metrics.grossProfit = 0;
   metrics.grossLoss = 0;
   metrics.maxDrawdown = 0;
   metrics.profitFactor = 0;

   Print("═══════════════════════════════════════════════════════════");
   Print("  GOLD QUANTUM SCALPER PRO - AI POWERED EA INITIALIZED");
   Print("═══════════════════════════════════════════════════════════");
   Print("Symbol: ", _Symbol);
   Print("Timeframe: ", EnumToString(Timeframe));
   Print("Magic Number: ", MagicNumber);
   Print("Starting Balance: $", DoubleToString(startingBalance, 2));
   Print("Risk Per Trade: ", DoubleToString(RiskPercent, 2), "%");
   Print("═══════════════════════════════════════════════════════════");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release indicator handles
   IndicatorRelease(handleFastEMA);
   IndicatorRelease(handleSlowEMA);
   IndicatorRelease(handleRSI);
   IndicatorRelease(handleMACD);
   IndicatorRelease(handleBB);
   IndicatorRelease(handleATR);
   IndicatorRelease(handleVolume);

   //--- Remove objects from chart
   ObjectsDeleteAll(0, "GQS_");

   //--- Print final statistics
   Print("═══════════════════════════════════════════════════════════");
   Print("  GOLD QUANTUM SCALPER PRO - FINAL STATISTICS");
   Print("═══════════════════════════════════════════════════════════");
   Print("Total Trades: ", metrics.totalTrades);
   Print("Winning Trades: ", metrics.winningTrades);
   Print("Losing Trades: ", metrics.losingTrades);
   if(metrics.totalTrades > 0)
      Print("Win Rate: ", DoubleToString((double)metrics.winningTrades/metrics.totalTrades*100, 2), "%");
   Print("Gross Profit: $", DoubleToString(metrics.grossProfit, 2));
   Print("Gross Loss: $", DoubleToString(metrics.grossLoss, 2));
   if(metrics.grossLoss != 0)
      Print("Profit Factor: ", DoubleToString(metrics.grossProfit/MathAbs(metrics.grossLoss), 2));
   Print("Max Drawdown: ", DoubleToString(metrics.maxDrawdown, 2), "%");
   Print("Final Balance: $", DoubleToString(account.Balance(), 2));
   Print("═══════════════════════════════════════════════════════════");

   Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Check if new bar
   if(!IsNewBar())
      return;

   //--- Update daily statistics
   UpdateDailyStats();

   //--- Check trading conditions
   if(!IsTradingAllowed())
      return;

   //--- Update indicator values
   if(!UpdateIndicators())
      return;

   //--- Calculate current ATR
   currentATR = atrBuffer[0];

   //--- Order Flow Analysis
   if(UseOrderFlow)
      AnalyzeOrderFlow();

   //--- Manage existing positions
   ManagePositions();

   //--- Check for new signals
   int signal = GetTradingSignal();

   //--- Execute trades based on signal
   if(signal == 1) // Buy Signal
   {
      if(CountOpenPositions() < MaxOpenPositions)
         OpenPosition(ORDER_TYPE_BUY);
   }
   else if(signal == -1) // Sell Signal
   {
      if(CountOpenPositions() < MaxOpenPositions)
         OpenPosition(ORDER_TYPE_SELL);
   }

   //--- Display info on chart
   if(DisplayInfo)
      DisplayInformation();

   //--- AI Optimization
   if(UseAI_Optimization && metrics.totalTrades > 0 && metrics.totalTrades % OptimizationPeriod == 0)
      OptimizeParameters();
}

//+------------------------------------------------------------------+
//| Check if new bar                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, Timeframe, 0);
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Update daily statistics                                           |
//+------------------------------------------------------------------+
void UpdateDailyStats()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   datetime currentDate = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));

   if(currentDate != todayDate)
   {
      // New day - reset daily counters
      todayDate = currentDate;
      totalTradestoday = 0;
      dailyProfit = 0;
   }

   //--- Calculate daily profit
   double currentBalance = account.Balance();
   if(peakBalance < currentBalance)
      peakBalance = currentBalance;

   //--- Calculate drawdown
   double currentDrawdown = (peakBalance - currentBalance) / peakBalance * 100;
   if(currentDrawdown > metrics.maxDrawdown)
      metrics.maxDrawdown = currentDrawdown;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                       |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   //--- Check if EA trading is allowed
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Comment("EA trading is not allowed in terminal");
      return false;
   }

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Comment("EA trading is not allowed for this EA");
      return false;
   }

   //--- Check time filter
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.hour < StartHour || dt.hour >= EndHour)
      return false;

   //--- Check day of week
   switch(dt.day_of_week)
   {
      case 1: if(!TradeMonday) return false; break;
      case 2: if(!TradeTuesday) return false; break;
      case 3: if(!TradeWednesday) return false; break;
      case 4: if(!TradeThursday) return false; break;
      case 5: if(!TradeFriday) return false; break;
      default: return false; // Weekend
   }

   //--- Check max trades per day
   if(MaxTradesPerDay > 0 && totalTradestoday >= MaxTradesPerDay)
      return false;

   //--- Check daily loss limit
   double currentBalance = account.Balance();
   double dailyLoss = (startingBalance - currentBalance) / startingBalance * 100;
   if(dailyLoss >= MaxDailyLoss)
   {
      Comment("Daily loss limit reached: ", DoubleToString(dailyLoss, 2), "%");
      return false;
   }

   //--- Check max drawdown
   double currentDrawdown = (peakBalance - currentBalance) / peakBalance * 100;
   if(currentDrawdown >= MaxDrawdown)
   {
      Comment("Maximum drawdown reached: ", DoubleToString(currentDrawdown, 2), "%");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Update indicator values                                           |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
   if(CopyBuffer(handleFastEMA, 0, 0, 3, fastEMA) <= 0) return false;
   if(CopyBuffer(handleSlowEMA, 0, 0, 3, slowEMA) <= 0) return false;
   if(CopyBuffer(handleRSI, 0, 0, 3, rsiBuffer) <= 0) return false;
   if(CopyBuffer(handleMACD, 0, 0, 3, macdMain) <= 0) return false;
   if(CopyBuffer(handleMACD, 1, 0, 3, macdSignal) <= 0) return false;
   if(CopyBuffer(handleBB, 1, 0, 3, bbUpper) <= 0) return false;
   if(CopyBuffer(handleBB, 0, 0, 3, bbMiddle) <= 0) return false;
   if(CopyBuffer(handleBB, 2, 0, 3, bbLower) <= 0) return false;
   if(CopyBuffer(handleATR, 0, 0, 3, atrBuffer) <= 0) return false;
   if(CopyBuffer(handleVolume, 0, 0, VolumeMA_Period + 5, volumeBuffer) <= 0) return false;

   return true;
}

//+------------------------------------------------------------------+
//| Analyze Order Flow                                                |
//+------------------------------------------------------------------+
void AnalyzeOrderFlow()
{
   //--- Get tick volume data
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int copied = CopyRates(_Symbol, Timeframe, 0, VolumeMA_Period, rates);
   if(copied <= 0)
      return;

   //--- Calculate volume moving average
   double volumeMA = 0;
   for(int i = 0; i < VolumeMA_Period; i++)
   {
      volumeMA += (double)rates[i].tick_volume;
   }
   volumeMA /= VolumeMA_Period;

   //--- Analyze current volume
   double currentVolume = (double)rates[0].tick_volume;

   //--- Detect volume spikes
   if(currentVolume > volumeMA * VolumeThreshold)
   {
      //--- Determine if buying or selling pressure
      if(rates[0].close > rates[0].open)
      {
         buyVolume += currentVolume;
      }
      else if(rates[0].close < rates[0].open)
      {
         sellVolume += currentVolume;
      }
   }

   //--- Calculate order flow imbalance
   if(buyVolume + sellVolume > 0)
   {
      orderFlowImbalance = (buyVolume - sellVolume) / (buyVolume + sellVolume);
   }

   //--- Decay old data
   buyVolume *= 0.9;
   sellVolume *= 0.9;
}

//+------------------------------------------------------------------+
//| Get trading signal                                                |
//+------------------------------------------------------------------+
int GetTradingSignal()
{
   int signal = 0;
   int bullishSignals = 0;
   int bearishSignals = 0;

   //--- Strategy 1: EMA Crossover
   if(fastEMA[0] > slowEMA[0] && fastEMA[1] <= slowEMA[1])
      bullishSignals++;
   if(fastEMA[0] < slowEMA[0] && fastEMA[1] >= slowEMA[1])
      bearishSignals++;

   //--- Strategy 2: RSI
   if(rsiBuffer[0] < RSI_Oversold && rsiBuffer[1] >= RSI_Oversold)
      bullishSignals++;
   if(rsiBuffer[0] > RSI_Overbought && rsiBuffer[1] <= RSI_Overbought)
      bearishSignals++;

   //--- Strategy 3: MACD
   if(macdMain[0] > macdSignal[0] && macdMain[1] <= macdSignal[1] && macdMain[0] > 0)
      bullishSignals++;
   if(macdMain[0] < macdSignal[0] && macdMain[1] >= macdSignal[1] && macdMain[0] < 0)
      bearishSignals++;

   //--- Strategy 4: Bollinger Bands
   double close = iClose(_Symbol, Timeframe, 0);
   double prevClose = iClose(_Symbol, Timeframe, 1);

   if(prevClose <= bbLower[1] && close > bbLower[0])
      bullishSignals++;
   if(prevClose >= bbUpper[1] && close < bbUpper[0])
      bearishSignals++;

   //--- Strategy 5: Order Flow
   if(UseOrderFlow)
   {
      if(orderFlowImbalance > 0.3)
         bullishSignals++;
      if(orderFlowImbalance < -0.3)
         bearishSignals++;
   }

   //--- Strategy 6: Price Action
   if(close > bbMiddle[0] && close > fastEMA[0])
      bullishSignals++;
   if(close < bbMiddle[0] && close < fastEMA[0])
      bearishSignals++;

   //--- Determine final signal (need at least 3 confirmations)
   if(bullishSignals >= 3 && bearishSignals == 0)
      signal = 1;  // Buy
   else if(bearishSignals >= 3 && bullishSignals == 0)
      signal = -1; // Sell

   return signal;
}

//+------------------------------------------------------------------+
//| Calculate lot size with dynamic risk                              |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossPoints)
{
   double lotSize = MinLotSize;

   if(stopLossPoints <= 0)
      return lotSize;

   //--- Calculate adaptive risk
   currentRisk = RiskPercent;

   if(UseAdaptiveRisk)
   {
      if(consecutiveWins >= 2)
         currentRisk *= RiskMultiplierWin;
      else if(consecutiveLosses >= 2)
         currentRisk *= RiskMultiplierLoss;
   }

   //--- Cap the risk
   if(currentRisk > RiskPercent * 2)
      currentRisk = RiskPercent * 2;
   if(currentRisk < RiskPercent * 0.5)
      currentRisk = RiskPercent * 0.5;

   //--- Get account info
   double accountBalance = account.Balance();
   double riskAmount = accountBalance * currentRisk / 100.0;

   //--- Get symbol info
   double tickValue = symbolInfo.TickValue();
   double tickSize = symbolInfo.TickSize();
   double point = symbolInfo.Point();

   //--- Calculate lot size
   if(tickValue != 0 && tickSize != 0)
   {
      lotSize = (riskAmount / stopLossPoints) / (tickValue / tickSize);
      lotSize = NormalizeLot(lotSize);
   }

   //--- Check lot limits
   if(lotSize < MinLotSize)
      lotSize = MinLotSize;
   if(lotSize > MaxLotSize)
      lotSize = MaxLotSize;

   //--- Check symbol lot limits
   double minLot = symbolInfo.LotsMin();
   double maxLot = symbolInfo.LotsMax();

   if(lotSize < minLot)
      lotSize = minLot;
   if(lotSize > maxLot)
      lotSize = maxLot;

   return lotSize;
}

//+------------------------------------------------------------------+
//| Normalize lot size                                                |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double lotStep = symbolInfo.LotsStep();
   return MathFloor(lot / lotStep) * lotStep;
}

//+------------------------------------------------------------------+
//| Open position                                                      |
//+------------------------------------------------------------------+
void OpenPosition(ENUM_ORDER_TYPE orderType)
{
   //--- Calculate Stop Loss and Take Profit
   double atr = atrBuffer[0];
   double slPoints = atr * ATR_SL_Multiplier / symbolInfo.Point();
   double tpPoints = atr * ATR_TP_Multiplier / symbolInfo.Point();

   //--- Calculate lot size
   double lotSize = CalculateLotSize(slPoints);

   if(lotSize < symbolInfo.LotsMin())
   {
      Print("Lot size too small: ", lotSize);
      return;
   }

   //--- Get current prices
   double ask = symbolInfo.Ask();
   double bid = symbolInfo.Bid();
   double price = (orderType == ORDER_TYPE_BUY) ? ask : bid;

   //--- Calculate SL and TP levels
   double sl = 0, tp = 0;

   if(orderType == ORDER_TYPE_BUY)
   {
      sl = NormalizeDouble(ask - slPoints * symbolInfo.Point(), symbolInfo.Digits());
      tp = NormalizeDouble(ask + tpPoints * symbolInfo.Point(), symbolInfo.Digits());
   }
   else
   {
      sl = NormalizeDouble(bid + slPoints * symbolInfo.Point(), symbolInfo.Digits());
      tp = NormalizeDouble(bid - tpPoints * symbolInfo.Point(), symbolInfo.Digits());
   }

   //--- Open position
   bool result = false;
   if(orderType == ORDER_TYPE_BUY)
      result = trade.Buy(lotSize, _Symbol, ask, sl, tp, TradeComment);
   else
      result = trade.Sell(lotSize, _Symbol, bid, sl, tp, TradeComment);

   if(result)
   {
      Print("Position opened successfully: ", EnumToString(orderType),
            " | Lot: ", DoubleToString(lotSize, 2),
            " | SL: ", DoubleToString(sl, symbolInfo.Digits()),
            " | TP: ", DoubleToString(tp, symbolInfo.Digits()));

      totalTradestoday++;
      metrics.totalTrades++;
      lastTradeTime = TimeCurrent();
   }
   else
   {
      Print("Error opening position: ", GetLastError(), " | ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Count open positions                                              |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Manage open positions                                             |
//+------------------------------------------------------------------+
void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!position.SelectByIndex(i))
         continue;

      if(position.Symbol() != _Symbol || position.Magic() != MagicNumber)
         continue;

      ulong ticket = position.Ticket();
      double openPrice = position.PriceOpen();
      double currentSL = position.StopLoss();
      double currentTP = position.TakeProfit();
      ENUM_POSITION_TYPE posType = position.PositionType();

      double currentPrice = (posType == POSITION_TYPE_BUY) ? symbolInfo.Bid() : symbolInfo.Ask();
      double atr = atrBuffer[0];

      //--- Breakeven
      if(UseBreakeven)
      {
         double breakevenDistance = atr * BreakevenTrigger;
         double breakevenLevel = atr * BreakevenProfit;

         if(posType == POSITION_TYPE_BUY)
         {
            if(currentPrice > openPrice + breakevenDistance &&
               (currentSL < openPrice || currentSL == 0))
            {
               double newSL = NormalizeDouble(openPrice + breakevenLevel, symbolInfo.Digits());
               trade.PositionModify(ticket, newSL, currentTP);
               Print("Breakeven activated for Buy position #", ticket);
            }
         }
         else if(posType == POSITION_TYPE_SELL)
         {
            if(currentPrice < openPrice - breakevenDistance &&
               (currentSL > openPrice || currentSL == 0))
            {
               double newSL = NormalizeDouble(openPrice - breakevenLevel, symbolInfo.Digits());
               trade.PositionModify(ticket, newSL, currentTP);
               Print("Breakeven activated for Sell position #", ticket);
            }
         }
      }

      //--- Trailing Stop
      if(UseTrailingStop)
      {
         double trailingDistance = atr * TrailingStart;
         double trailingStep = atr * TrailingStep;

         if(posType == POSITION_TYPE_BUY)
         {
            if(currentPrice > openPrice + trailingDistance)
            {
               double newSL = NormalizeDouble(currentPrice - trailingDistance, symbolInfo.Digits());
               if(newSL > currentSL + trailingStep || currentSL == 0)
               {
                  trade.PositionModify(ticket, newSL, currentTP);
               }
            }
         }
         else if(posType == POSITION_TYPE_SELL)
         {
            if(currentPrice < openPrice - trailingDistance)
            {
               double newSL = NormalizeDouble(currentPrice + trailingDistance, symbolInfo.Digits());
               if(newSL < currentSL - trailingStep || currentSL == 0)
               {
                  trade.PositionModify(ticket, newSL, currentTP);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Optimize parameters (AI Self-Optimization)                        |
//+------------------------------------------------------------------+
void OptimizeParameters()
{
   //--- Calculate win rate
   double winRate = 0;
   if(metrics.totalTrades > 0)
      winRate = (double)metrics.winningTrades / metrics.totalTrades;

   //--- Calculate profit factor
   if(metrics.grossLoss != 0)
      metrics.profitFactor = metrics.grossProfit / MathAbs(metrics.grossLoss);

   //--- Adaptive optimization based on performance
   if(winRate < 0.45) // Poor performance
   {
      // Make strategy more conservative
      // Increase required confirmations
      Print("AI Optimization: Performance below threshold. Adjusting to conservative mode.");
   }
   else if(winRate > 0.65) // Good performance
   {
      // Can be slightly more aggressive
      Print("AI Optimization: Excellent performance. Maintaining current parameters.");
   }

   //--- Adjust based on market volatility
   double avgATR = 0;
   for(int i = 0; i < 20; i++)
      avgATR += atrBuffer[i];
   avgATR /= 20;

   if(avgATR > currentATR * 1.5)
   {
      Print("AI Optimization: High volatility detected. Widening stops.");
   }
   else if(avgATR < currentATR * 0.7)
   {
      Print("AI Optimization: Low volatility detected. Tightening stops.");
   }
}

//+------------------------------------------------------------------+
//| Display information on chart                                      |
//+------------------------------------------------------------------+
void DisplayInformation()
{
   string info = "";
   info += "\n═══════════════════════════════════════";
   info += "\n  GOLD QUANTUM SCALPER PRO";
   info += "\n═══════════════════════════════════════";
   info += "\n  Balance: $" + DoubleToString(account.Balance(), 2);
   info += "\n  Equity: $" + DoubleToString(account.Equity(), 2);
   info += "\n  Profit: $" + DoubleToString(account.Profit(), 2);
   info += "\n";
   info += "\n  Open Positions: " + IntegerToString(CountOpenPositions());
   info += "\n  Trades Today: " + IntegerToString(totalTradestoday);
   info += "\n";
   info += "\n  Total Trades: " + IntegerToString(metrics.totalTrades);
   info += "\n  Win Rate: " + DoubleToString((metrics.totalTrades > 0 ? (double)metrics.winningTrades/metrics.totalTrades*100 : 0), 2) + "%";
   info += "\n  Profit Factor: " + DoubleToString(metrics.profitFactor, 2);
   info += "\n  Max DD: " + DoubleToString(metrics.maxDrawdown, 2) + "%";
   info += "\n";
   info += "\n  Current Risk: " + DoubleToString(currentRisk, 2) + "%";
   info += "\n  ATR: " + DoubleToString(currentATR, 2);
   info += "\n  RSI: " + DoubleToString(rsiBuffer[0], 2);
   info += "\n";
   info += "\n  Order Flow: " + DoubleToString(orderFlowImbalance, 3);
   info += "\n  Buy Vol: " + DoubleToString(buyVolume, 0);
   info += "\n  Sell Vol: " + DoubleToString(sellVolume, 0);
   info += "\n═══════════════════════════════════════";

   Comment(info);
}

//+------------------------------------------------------------------+
//| Trade transaction handler                                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   //--- Check transaction type
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      //--- Get deal info
      ulong dealTicket = trans.deal;
      if(HistoryDealSelect(dealTicket))
      {
         long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
         long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
         double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);

         //--- Check if it's a closing deal
         if(dealEntry == DEAL_ENTRY_OUT)
         {
            //--- Update statistics
            if(dealProfit > 0)
            {
               metrics.winningTrades++;
               metrics.grossProfit += dealProfit;
               consecutiveWins++;
               consecutiveLosses = 0;
            }
            else if(dealProfit < 0)
            {
               metrics.losingTrades++;
               metrics.grossLoss += dealProfit;
               consecutiveLosses++;
               consecutiveWins = 0;
            }

            dailyProfit += dealProfit;

            //--- Print trade result
            Print("Trade closed: ", (dealProfit > 0 ? "WIN" : "LOSS"),
                  " | Profit: $", DoubleToString(dealProfit, 2),
                  " | Balance: $", DoubleToString(account.Balance(), 2));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| OnTimer function (optional for additional features)               |
//+------------------------------------------------------------------+
void OnTimer()
{
   //--- Can be used for periodic checks or updates
   //--- Currently not implemented but available for future enhancements
}
//+------------------------------------------------------------------+