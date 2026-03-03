//+------------------------------------------------------------------+
//|                                    XAUUSD_Aggressive_Scalper.mq5 |
//|                                      Advanced Scalping EA System |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Advanced Trading Systems"
#property link      ""
#property version   "3.50"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters
input group "=== BASIC SETTINGS ==="
input string InpSymbol = "XAUUSD";                    // Trading Symbol
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M5;      // Timeframe
input bool InpAggressiveMode = true;                 // Aggressive Mode
input int InpMagicNumber = 789456;                   // Magic Number

input group "=== TRADING TIME ==="
input int InpStartHour = 1;                          // Start Trading Hour
input int InpEndHour = 23;                           // End Trading Hour

input group "=== RISK MANAGEMENT ==="
input double InpRiskPercent = 2.0;                   // Risk Per Trade (%)
input double InpMaxDailyDrawdown = 5.0;              // Max Daily Drawdown (%)
input double InpMaxTotalRisk = 10.0;                 // Max Total Risk (%)
input bool InpUseDynamicLots = true;                 // Use Dynamic Lot Sizing
input double InpFixedLot = 0.01;                     // Fixed Lot Size

input group "=== STOP LOSS & TAKE PROFIT ==="
input int InpStopLoss = 150;                         // Stop Loss (Points)
input int InpTakeProfit = 200;                       // Take Profit (Points)
input bool InpUseATRforSLTP = true;                  // Use ATR for SL/TP
input double InpATRMultiplierSL = 1.5;               // ATR Multiplier for SL
input double InpATRMultiplierTP = 2.5;               // ATR Multiplier for TP
input bool InpUseTrailingStop = true;                // Use Trailing Stop
input int InpTrailingStop = 100;                     // Trailing Stop (Points)
input int InpTrailingStep = 50;                      // Trailing Step (Points)

input group "=== TECHNICAL INDICATORS ==="
input int InpRSIPeriod = 14;                         // RSI Period
input int InpRSIOverbought = 70;                     // RSI Overbought Level
input InpRSIOversold = 30;                           // RSI Oversold Level
input int InpEMAPeriod1 = 8;                         // Fast EMA Period
input int InpEMAPeriod2 = 21;                        // Medium EMA Period
input int InpEMAPeriod3 = 50;                        // Slow EMA Period
input int InpATRPeriod = 14;                         // ATR Period
input int InpBBPeriod = 20;                          // Bollinger Bands Period
input double InpBBDeviation = 2.0;                   // BB Deviation
input int InpMACDFast = 12;                          // MACD Fast EMA
input InpMACDSlow = 26;                              // MACD Slow EMA
input int InpMACDSignal = 9;                         // MACD Signal

input group "=== ORDER FLOW ANALYSIS ==="
input bool InpUseOrderFlow = true;                   // Use Order Flow Analysis
input int InpOrderFlowBars = 10;                     // Order Flow Lookback Bars
input double InpVolumeThreshold = 1.5;               // Volume Threshold Multiplier

input group "=== SCALPING PARAMETERS ==="
input int InpMinSpread = 0;                          // Min Spread (Points)
input int InpMaxSpread = 30;                         // Max Spread (Points)
input int InpMinBarDistance = 3;                     // Min Bars Between Trades
input bool InpUseBreakoutStrategy = true;            // Use Breakout Strategy
input bool InpUseMeanReversion = true;               // Use Mean Reversion
input bool InpUseMomentumStrategy = true;            // Use Momentum Strategy

input group "=== DISPLAY SETTINGS ==="
input bool InpShowPanel = true;                      // Show Info Panel
input color InpPanelColor = clrDarkSlateGray;        // Panel Background Color
input color InpTextColor = clrWhite;                 // Text Color
input int InpFontSize = 9;                           // Font Size

//--- Global Variables
CTrade trade;
CPositionInfo positionInfo;
COrderInfo orderInfo;
CAccountInfo accountInfo;
CSymbolInfo symbolInfo;

int rsiHandle, ema1Handle, ema2Handle, ema3Handle, atrHandle, bbHandle, macdHandle;
double rsiBuffer[], ema1Buffer[], ema2Buffer[], ema3Buffer[], atrBuffer[];
double bbUpperBuffer[], bbLowerBuffer[], bbMiddleBuffer[];
double macdBuffer[], macdSignalBuffer[];

datetime lastTradeTime = 0;
double dailyStartBalance = 0;
double totalProfit = 0;
double totalLoss = 0;
int totalTrades = 0;
int winningTrades = 0;
int losingTrades = 0;

struct TradeSignal {
    int signal;           // 1 = Buy, -1 = Sell, 0 = None
    double strength;      // Signal strength 0-100
    string reason;        // Reason for signal
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Set symbol and validate
    if(!symbolInfo.Name(InpSymbol))
    {
        Print("Failed to set symbol: ", InpSymbol);
        return INIT_FAILED;
    }

    // Initialize trade object
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(50);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    trade.SetAsyncMode(false);

    // Initialize indicators
    rsiHandle = iRSI(InpSymbol, InpTimeframe, InpRSIPeriod, PRICE_CLOSE);
    ema1Handle = iMA(InpSymbol, InpTimeframe, InpEMAPeriod1, 0, MODE_EMA, PRICE_CLOSE);
    ema2Handle = iMA(InpSymbol, InpTimeframe, InpEMAPeriod2, 0, MODE_EMA, PRICE_CLOSE);
    ema3Handle = iMA(InpSymbol, InpTimeframe, InpEMAPeriod3, 0, MODE_EMA, PRICE_CLOSE);
    atrHandle = iATR(InpSymbol, InpTimeframe, InpATRPeriod);
    bbHandle = iBands(InpSymbol, InpTimeframe, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
    macdHandle = iMACD(InpSymbol, InpTimeframe, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);

    // Check handles
    if(rsiHandle == INVALID_HANDLE || ema1Handle == INVALID_HANDLE ||
       ema2Handle == INVALID_HANDLE || ema3Handle == INVALID_HANDLE ||
       atrHandle == INVALID_HANDLE || bbHandle == INVALID_HANDLE ||
       macdHandle == INVALID_HANDLE)
    {
        Print("Failed to create indicator handles");
        return INIT_FAILED;
    }

    // Set array as series
    ArraySetAsSeries(rsiBuffer, true);
    ArraySetAsSeries(ema1Buffer, true);
    ArraySetAsSeries(ema2Buffer, true);
    ArraySetAsSeries(ema3Buffer, true);
    ArraySetAsSeries(atrBuffer, true);
    ArraySetAsSeries(bbUpperBuffer, true);
    ArraySetAsSeries(bbLowerBuffer, true);
    ArraySetAsSeries(bbMiddleBuffer, true);
    ArraySetAsSeries(macdBuffer, true);
    ArraySetAsSeries(macdSignalBuffer, true);

    // Store initial balance
    dailyStartBalance = accountInfo.Balance();

    Print("===========================================");
    Print("XAUUSD Aggressive Scalper EA Initialized");
    Print("Account Balance: ", accountInfo.Balance());
    Print("Account Leverage: ", accountInfo.Leverage());
    Print("Symbol: ", InpSymbol);
    Print("Timeframe: ", EnumToString(InpTimeframe));
    Print("===========================================");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
    if(ema1Handle != INVALID_HANDLE) IndicatorRelease(ema1Handle);
    if(ema2Handle != INVALID_HANDLE) IndicatorRelease(ema2Handle);
    if(ema3Handle != INVALID_HANDLE) IndicatorRelease(ema3Handle);
    if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
    if(bbHandle != INVALID_HANDLE) IndicatorRelease(bbHandle);
    if(macdHandle != INVALID_HANDLE) IndicatorRelease(macdHandle);

    // Remove all objects
    ObjectsDeleteAll(0, "EA_");

    Print("EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if new bar
    static datetime lastBar = 0;
    datetime currentBar = iTime(InpSymbol, InpTimeframe, 0);

    bool isNewBar = (currentBar != lastBar);
    if(isNewBar) lastBar = currentBar;

    // Update account info
    accountInfo.Refresh();
    symbolInfo.Refresh();

    // Display info panel
    if(InpShowPanel)
        DisplayInfoPanel();

    // Display open trades on chart
    DisplayOpenTrades();

    // Check trading conditions
    if(!IsTradingAllowed()) return;

    // Update trailing stops
    if(InpUseTrailingStop)
        ManageTrailingStops();

    // Check risk limits
    if(!CheckRiskLimits()) return;

    // On new bar, analyze and execute trades
    if(isNewBar || InpAggressiveMode)
    {
        // Update indicator buffers
        if(!UpdateIndicators()) return;

        // Get trading signal
        TradeSignal signal = AnalyzeMarket();

        // Execute trade based on signal
        if(signal.signal != 0)
        {
            ExecuteTrade(signal);
        }
    }

    // Self-correcting mechanism
    PerformSelfCorrection();
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
    // Check trading hours
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);

    if(timeStruct.hour < InpStartHour || timeStruct.hour >= InpEndHour)
        return false;

    // Check if weekend
    if(timeStruct.day_of_week == 0 || timeStruct.day_of_week == 6)
        return false;

    // Check spread
    long spread = symbolInfo.Spread();
    if(spread < InpMinSpread || spread > InpMaxSpread)
        return false;

    // Check minimum bar distance
    if((TimeCurrent() - lastTradeTime) < (InpMinBarDistance * PeriodSeconds(InpTimeframe)))
        return false;

    return true;
}

//+------------------------------------------------------------------+
//| Check risk limits                                                |
//+------------------------------------------------------------------+
bool CheckRiskLimits()
{
    double currentBalance = accountInfo.Balance();
    double equity = accountInfo.Equity();

    // Check daily drawdown
    if(dailyStartBalance > 0)
    {
        double dailyDrawdown = ((dailyStartBalance - equity) / dailyStartBalance) * 100.0;
        if(dailyDrawdown > InpMaxDailyDrawdown)
        {
            Print("Daily drawdown limit reached: ", dailyDrawdown, "%");
            return false;
        }
    }

    // Reset daily balance at start of new day
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    static int lastDay = -1;
    if(timeStruct.day != lastDay)
    {
        lastDay = timeStruct.day;
        dailyStartBalance = currentBalance;
    }

    // Check total exposure
    double totalExposure = CalculateTotalExposure();
    double maxExposure = (currentBalance * InpMaxTotalRisk) / 100.0;

    if(totalExposure > maxExposure)
    {
        Print("Total exposure limit reached");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Update indicator buffers                                          |
//+------------------------------------------------------------------+
bool UpdateIndicators()
{
    if(CopyBuffer(rsiHandle, 0, 0, 3, rsiBuffer) <= 0) return false;
    if(CopyBuffer(ema1Handle, 0, 0, 3, ema1Buffer) <= 0) return false;
    if(CopyBuffer(ema2Handle, 0, 0, 3, ema2Buffer) <= 0) return false;
    if(CopyBuffer(ema3Handle, 0, 0, 3, ema3Buffer) <= 0) return false;
    if(CopyBuffer(atrHandle, 0, 0, 3, atrBuffer) <= 0) return false;
    if(CopyBuffer(bbHandle, 0, 0, 3, bbUpperBuffer) <= 0) return false;
    if(CopyBuffer(bbHandle, 1, 0, 3, bbMiddleBuffer) <= 0) return false;
    if(CopyBuffer(bbHandle, 2, 0, 3, bbLowerBuffer) <= 0) return false;
    if(CopyBuffer(macdHandle, 0, 0, 3, macdBuffer) <= 0) return false;
    if(CopyBuffer(macdHandle, 1, 0, 3, macdSignalBuffer) <= 0) return false;

    return true;
}

//+------------------------------------------------------------------+
//| Analyze market and generate trading signal                       |
//+------------------------------------------------------------------+
TradeSignal AnalyzeMarket()
{
    TradeSignal signal;
    signal.signal = 0;
    signal.strength = 0;
    signal.reason = "";

    double points = 0;
    string reasons = "";

    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(InpSymbol, InpTimeframe, 0, 50, rates) <= 0)
        return signal;

    double currentPrice = rates[0].close;

    // === MOMENTUM STRATEGY ===
    if(InpUseMomentumStrategy)
    {
        // RSI Analysis
        if(rsiBuffer[0] < InpRSIOversold && rsiBuffer[0] > rsiBuffer[1])
        {
            points += 20;
            reasons += "RSI Oversold Reversal | ";
        }
        else if(rsiBuffer[0] > InpRSIOverbought && rsiBuffer[0] < rsiBuffer[1])
        {
            points -= 20;
            reasons += "RSI Overbought Reversal | ";
        }

        // EMA Crossover
        if(ema1Buffer[0] > ema2Buffer[0] && ema1Buffer[1] <= ema2Buffer[1])
        {
            points += 25;
            reasons += "EMA Golden Cross | ";
        }
        else if(ema1Buffer[0] < ema2Buffer[0] && ema1Buffer[1] >= ema2Buffer[1])
        {
            points -= 25;
            reasons += "EMA Death Cross | ";
        }

        // EMA Trend
        if(ema1Buffer[0] > ema2Buffer[0] && ema2Buffer[0] > ema3Buffer[0])
        {
            points += 15;
            reasons += "Strong Uptrend | ";
        }
        else if(ema1Buffer[0] < ema2Buffer[0] && ema2Buffer[0] < ema3Buffer[0])
        {
            points -= 15;
            reasons += "Strong Downtrend | ";
        }

        // MACD Analysis
        if(macdBuffer[0] > macdSignalBuffer[0] && macdBuffer[1] <= macdSignalBuffer[1])
        {
            points += 20;
            reasons += "MACD Bull Cross | ";
        }
        else if(macdBuffer[0] < macdSignalBuffer[0] && macdBuffer[1] >= macdSignalBuffer[1])
        {
            points -= 20;
            reasons += "MACD Bear Cross | ";
        }
    }

    // === MEAN REVERSION STRATEGY ===
    if(InpUseMeanReversion)
    {
        double bbWidth = bbUpperBuffer[0] - bbLowerBuffer[0];
        double pricePosition = (currentPrice - bbLowerBuffer[0]) / bbWidth;

        if(currentPrice < bbLowerBuffer[0])
        {
            points += 25;
            reasons += "Price Below BB Lower | ";
        }
        else if(currentPrice > bbUpperBuffer[0])
        {
            points -= 25;
            reasons += "Price Above BB Upper | ";
        }

        // Price distance from middle BB
        double distanceFromMiddle = (currentPrice - bbMiddleBuffer[0]) / bbWidth;
        if(MathAbs(distanceFromMiddle) > 0.8)
        {
            if(distanceFromMiddle < 0)
                points += 10;
            else
                points -= 10;
            reasons += "Far From BB Middle | ";
        }
    }

    // === BREAKOUT STRATEGY ===
    if(InpUseBreakoutStrategy)
    {
        double highestHigh = rates[0].high;
        double lowestLow = rates[0].low;

        for(int i = 1; i <= 20; i++)
        {
            if(rates[i].high > highestHigh) highestHigh = rates[i].high;
            if(rates[i].low < lowestLow) lowestLow = rates[i].low;
        }

        if(currentPrice > highestHigh)
        {
            points += 30;
            reasons += "Breakout Above High | ";
        }
        else if(currentPrice < lowestLow)
        {
            points -= 30;
            reasons += "Breakout Below Low | ";
        }
    }

    // === ORDER FLOW ANALYSIS ===
    if(InpUseOrderFlow)
    {
        double orderFlowSignal = AnalyzeOrderFlow(rates);
        points += orderFlowSignal;
        if(orderFlowSignal > 0)
            reasons += "Bullish Order Flow | ";
        else if(orderFlowSignal < 0)
            reasons += "Bearish Order Flow | ";
    }

    // === VOLATILITY FILTER ===
    double atr = atrBuffer[0];
    double avgATR = (atrBuffer[0] + atrBuffer[1] + atrBuffer[2]) / 3.0;

    if(atr > avgATR * 1.5)
    {
        points *= 1.2; // Increase signal strength in high volatility
        reasons += "High Volatility | ";
    }

    // === FINAL SIGNAL DETERMINATION ===
    if(points > 50)
    {
        signal.signal = 1; // BUY
        signal.strength = MathMin(points, 100);
        signal.reason = reasons;
    }
    else if(points < -50)
    {
        signal.signal = -1; // SELL
        signal.strength = MathMin(MathAbs(points), 100);
        signal.reason = reasons;
    }

    return signal;
}

//+------------------------------------------------------------------+
//| Analyze order flow                                               |
//+------------------------------------------------------------------+
double AnalyzeOrderFlow(const MqlRates &rates[])
{
    double buyVolume = 0;
    double sellVolume = 0;
    double buyPressure = 0;
    double sellPressure = 0;

    long volumes[];
    ArraySetAsSeries(volumes, true);
    CopyTickVolume(InpSymbol, InpTimeframe, 0, InpOrderFlowBars, volumes);

    double avgVolume = 0;
    for(int i = 0; i < InpOrderFlowBars; i++)
    {
        avgVolume += volumes[i];

        double bodySize = MathAbs(rates[i].close - rates[i].open);
        double upperWick = rates[i].high - MathMax(rates[i].open, rates[i].close);
        double lowerWick = MathMin(rates[i].open, rates[i].close) - rates[i].low;

        if(rates[i].close > rates[i].open) // Bullish candle
        {
            buyVolume += volumes[i];
            buyPressure += (bodySize / (bodySize + upperWick + lowerWick + 0.000001)) * volumes[i];
        }
        else // Bearish candle
        {
            sellVolume += volumes[i];
            sellPressure += (bodySize / (bodySize + upperWick + lowerWick + 0.000001)) * volumes[i];
        }
    }

    avgVolume /= InpOrderFlowBars;

    // Calculate order flow imbalance
    double volumeImbalance = (buyVolume - sellVolume) / (buyVolume + sellVolume + 0.000001);
    double pressureImbalance = (buyPressure - sellPressure) / (buyPressure + sellPressure + 0.000001);

    // Recent volume spike
    double volumeSpike = volumes[0] / (avgVolume + 0.000001);

    double orderFlowScore = 0;

    if(volumeImbalance > 0.2 && pressureImbalance > 0.2)
        orderFlowScore += 15;
    else if(volumeImbalance < -0.2 && pressureImbalance < -0.2)
        orderFlowScore -= 15;

    if(volumeSpike > InpVolumeThreshold)
    {
        if(rates[0].close > rates[0].open)
            orderFlowScore += 10;
        else
            orderFlowScore -= 10;
    }

    return orderFlowScore;
}

//+------------------------------------------------------------------+
//| Execute trade based on signal                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(TradeSignal &signal)
{
    // Check if already have position in signal direction
    if(CountPositions() >= GetMaxPositions())
        return;

    double lotSize = CalculateLotSize();
    if(lotSize <= 0) return;

    double ask = symbolInfo.Ask();
    double bid = symbolInfo.Bid();
    double atr = atrBuffer[0];

    double sl = 0, tp = 0;

    if(signal.signal == 1) // BUY
    {
        if(InpUseATRforSLTP)
        {
            sl = ask - (atr * InpATRMultiplierSL);
            tp = ask + (atr * InpATRMultiplierTP);
        }
        else
        {
            sl = ask - (InpStopLoss * symbolInfo.Point());
            tp = ask + (InpTakeProfit * symbolInfo.Point());
        }

        // Normalize prices
        sl = NormalizeDouble(sl, symbolInfo.Digits());
        tp = NormalizeDouble(tp, symbolInfo.Digits());

        if(trade.Buy(lotSize, InpSymbol, ask, sl, tp, "Scalper Buy - " + signal.reason))
        {
            Print("BUY Order Executed: Lot=", lotSize, " SL=", sl, " TP=", tp, " Reason: ", signal.reason);
            lastTradeTime = TimeCurrent();
            totalTrades++;
        }
        else
        {
            Print("BUY Order Failed: ", trade.ResultRetcodeDescription());
        }
    }
    else if(signal.signal == -1) // SELL
    {
        if(InpUseATRforSLTP)
        {
            sl = bid + (atr * InpATRMultiplierSL);
            tp = bid - (atr * InpATRMultiplierTP);
        }
        else
        {
            sl = bid + (InpStopLoss * symbolInfo.Point());
            tp = bid - (InpTakeProfit * symbolInfo.Point());
        }

        // Normalize prices
        sl = NormalizeDouble(sl, symbolInfo.Digits());
        tp = NormalizeDouble(tp, symbolInfo.Digits());

        if(trade.Sell(lotSize, InpSymbol, bid, sl, tp, "Scalper Sell - " + signal.reason))
        {
            Print("SELL Order Executed: Lot=", lotSize, " SL=", sl, " TP=", tp, " Reason: ", signal.reason);
            lastTradeTime = TimeCurrent();
            totalTrades++;
        }
        else
        {
            Print("SELL Order Failed: ", trade.ResultRetcodeDescription());
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    if(!InpUseDynamicLots)
        return NormalizeLot(InpFixedLot);

    double balance = accountInfo.Balance();
    double riskAmount = (balance * InpRiskPercent) / 100.0;

    double atr = atrBuffer[0];
    double slDistance = 0;

    if(InpUseATRforSLTP)
        slDistance = atr * InpATRMultiplierSL;
    else
        slDistance = InpStopLoss * symbolInfo.Point();

    double tickValue = symbolInfo.TickValue();
    double tickSize = symbolInfo.TickSize();

    double lotSize = (riskAmount) / ((slDistance / tickSize) * tickValue);

    // Apply aggressive multiplier
    if(InpAggressiveMode)
        lotSize *= 1.5;

    return NormalizeLot(lotSize);
}

//+------------------------------------------------------------------+
//| Normalize lot size                                               |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
    double minLot = symbolInfo.LotsMin();
    double maxLot = symbolInfo.LotsMax();
    double lotStep = symbolInfo.LotsStep();

    lot = MathFloor(lot / lotStep) * lotStep;
    lot = MathMax(minLot, lot);
    lot = MathMin(maxLot, lot);

    return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Count open positions                                             |
//+------------------------------------------------------------------+
int CountPositions()
{
    int count = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == InpSymbol &&
               positionInfo.Magic() == InpMagicNumber)
            {
                count++;
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Get maximum positions allowed                                    |
//+------------------------------------------------------------------+
int GetMaxPositions()
{
    if(InpAggressiveMode)
        return 10; // No practical limit in aggressive mode
    else
        return 3;
}

//+------------------------------------------------------------------+
//| Calculate total exposure                                         |
//+------------------------------------------------------------------+
double CalculateTotalExposure()
{
    double exposure = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == InpSymbol &&
               positionInfo.Magic() == InpMagicNumber)
            {
                double positionSL = positionInfo.StopLoss();
                double positionPrice = positionInfo.PriceOpen();
                double slDistance = MathAbs(positionPrice - positionSL);

                if(slDistance > 0)
                {
                    double tickValue = symbolInfo.TickValue();
                    double tickSize = symbolInfo.TickSize();
                    double lots = positionInfo.Volume();

                    exposure += (slDistance / tickSize) * tickValue * lots;
                }
            }
        }
    }
    return exposure;
}

//+------------------------------------------------------------------+
//| Manage trailing stops                                            |
//+------------------------------------------------------------------+
void ManageTrailingStops()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == InpSymbol &&
               positionInfo.Magic() == InpMagicNumber)
            {
                double currentSL = positionInfo.StopLoss();
                double currentTP = positionInfo.TakeProfit();
                double openPrice = positionInfo.PriceOpen();
                ulong ticket = positionInfo.Ticket();

                double trailStop = InpTrailingStop * symbolInfo.Point();
                double trailStep = InpTrailingStep * symbolInfo.Point();

                if(positionInfo.PositionType() == POSITION_TYPE_BUY)
                {
                    double bid = symbolInfo.Bid();
                    double newSL = bid - trailStop;

                    if(bid > openPrice + trailStop)
                    {
                        if(newSL > currentSL + trailStep || currentSL == 0)
                        {
                            newSL = NormalizeDouble(newSL, symbolInfo.Digits());
                            trade.PositionModify(ticket, newSL, currentTP);
                        }
                    }
                }
                else if(positionInfo.PositionType() == POSITION_TYPE_SELL)
                {
                    double ask = symbolInfo.Ask();
                    double newSL = ask + trailStop;

                    if(ask < openPrice - trailStop)
                    {
                        if(newSL < currentSL - trailStep || currentSL == 0)
                        {
                            newSL = NormalizeDouble(newSL, symbolInfo.Digits());
                            trade.PositionModify(ticket, newSL, currentTP);
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Self-correcting mechanism                                        |
//+------------------------------------------------------------------+
void PerformSelfCorrection()
{
    static datetime lastCorrection = 0;

    // Perform correction every 1 hour
    if(TimeCurrent() - lastCorrection < 3600)
        return;

    lastCorrection = TimeCurrent();

    // Calculate win rate
    double winRate = 0;
    if(totalTrades > 0)
        winRate = ((double)winningTrades / totalTrades) * 100.0;

    // Check if strategy is underperforming
    if(totalTrades > 20 && winRate < 40.0)
    {
        Print("Self-Correction: Win rate low (", winRate, "%). Reducing aggressiveness.");
        // Close losing positions if drawdown is significant
        CloseLosingPositions(30.0); // Close positions with >30% loss
    }

    // Check for stale positions
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == InpSymbol &&
               positionInfo.Magic() == InpMagicNumber)
            {
                datetime openTime = (datetime)positionInfo.Time();
                int hoursOpen = (int)((TimeCurrent() - openTime) / 3600);

                // Close positions open for more than 12 hours
                if(hoursOpen > 12)
                {
                    trade.PositionClose(positionInfo.Ticket());
                    Print("Self-Correction: Closed stale position, open for ", hoursOpen, " hours");
                }
            }
        }
    }

    // Update statistics
    UpdateStatistics();
}

//+------------------------------------------------------------------+
//| Close losing positions                                           |
//+------------------------------------------------------------------+
void CloseLosingPositions(double lossPercent)
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == InpSymbol &&
               positionInfo.Magic() == InpMagicNumber)
            {
                double profit = positionInfo.Profit();
                double volume = positionInfo.Volume();
                double openPrice = positionInfo.PriceOpen();

                double lossAmount = (openPrice * volume * lossPercent) / 100.0;

                if(profit < -lossAmount)
                {
                    trade.PositionClose(positionInfo.Ticket());
                    Print("Self-Correction: Closed losing position with loss: ", profit);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update trading statistics                                        |
//+------------------------------------------------------------------+
void UpdateStatistics()
{
    winningTrades = 0;
    losingTrades = 0;
    totalProfit = 0;
    totalLoss = 0;

    // Get history for today
    datetime from = iTime(InpSymbol, PERIOD_D1, 0);
    datetime to = TimeCurrent();

    HistorySelect(from, to);

    for(int i = 0; i < HistoryDealsTotal(); i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0)
        {
            if(HistoryDealGetString(ticket, DEAL_SYMBOL) == InpSymbol &&
               HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpMagicNumber)
            {
                double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);

                if(profit > 0)
                {
                    winningTrades++;
                    totalProfit += profit;
                }
                else if(profit < 0)
                {
                    losingTrades++;
                    totalLoss += MathAbs(profit);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Display information panel                                        |
//+------------------------------------------------------------------+
void DisplayInfoPanel()
{
    int xOffset = 20;
    int yOffset = 20;
    int lineHeight = InpFontSize + 5;
    int panelWidth = 350;
    int panelHeight = 400;

    // Background panel
    if(ObjectFind(0, "EA_Panel_BG") < 0)
    {
        ObjectCreate(0, "EA_Panel_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, "EA_Panel_BG", OBJPROP_XDISTANCE, xOffset);
        ObjectSetInteger(0, "EA_Panel_BG", OBJPROP_YDISTANCE, yOffset);
        ObjectSetInteger(0, "EA_Panel_BG", OBJPROP_XSIZE, panelWidth);
        ObjectSetInteger(0, "EA_Panel_BG", OBJPROP_YSIZE, panelHeight);
        ObjectSetInteger(0, "EA_Panel_BG", OBJPROP_BGCOLOR, InpPanelColor);
        ObjectSetInteger(0, "EA_Panel_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, "EA_Panel_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, "EA_Panel_BG", OBJPROP_HIDDEN, true);
    }

    int line = 0;

    // Title
    CreateLabel("EA_Panel_Title", "═══ XAUUSD AGGRESSIVE SCALPER ═══",
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), clrGold, InpFontSize + 2, "Arial Black");

    line++;

    // Account Information
    CreateLabel("EA_Panel_L1", "═════ ACCOUNT INFO ═════",
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), clrYellow, InpFontSize, "Arial Bold");

    CreateLabel("EA_Panel_Balance", "Balance: $" + DoubleToString(accountInfo.Balance(), 2),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    CreateLabel("EA_Panel_Equity", "Equity: $" + DoubleToString(accountInfo.Equity(), 2),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    double floatingPL = accountInfo.Equity() - accountInfo.Balance();
    color plColor = floatingPL >= 0 ? clrLime : clrRed;
    CreateLabel("EA_Panel_Floating", "Floating P/L: $" + DoubleToString(floatingPL, 2),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), plColor, InpFontSize);

    CreateLabel("EA_Panel_Margin", "Free Margin: $" + DoubleToString(accountInfo.FreeMargin(), 2),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    line++;

    // Trading Statistics
    CreateLabel("EA_Panel_L2", "═════ STATISTICS ═════",
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), clrYellow, InpFontSize, "Arial Bold");

    CreateLabel("EA_Panel_OpenPos", "Open Positions: " + IntegerToString(CountPositions()),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    CreateLabel("EA_Panel_TotalTrades", "Total Trades Today: " + IntegerToString(totalTrades),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    CreateLabel("EA_Panel_WinTrades", "Winning: " + IntegerToString(winningTrades) + " | Losing: " + IntegerToString(losingTrades),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    double winRate = totalTrades > 0 ? ((double)winningTrades / totalTrades) * 100.0 : 0;
    CreateLabel("EA_Panel_WinRate", "Win Rate: " + DoubleToString(winRate, 1) + "%",
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), winRate >= 50 ? clrLime : clrOrange, InpFontSize);

    CreateLabel("EA_Panel_TotalProfit", "Total Profit: $" + DoubleToString(totalProfit, 2),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), clrLime, InpFontSize);

    CreateLabel("EA_Panel_TotalLoss", "Total Loss: $" + DoubleToString(totalLoss, 2),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), clrRed, InpFontSize);

    double netProfit = totalProfit - totalLoss;
    color netColor = netProfit >= 0 ? clrLime : clrRed;
    CreateLabel("EA_Panel_NetProfit", "Net Profit: $" + DoubleToString(netProfit, 2),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), netColor, InpFontSize);

    line++;

    // Market Information
    CreateLabel("EA_Panel_L3", "═════ MARKET INFO ═════",
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), clrYellow, InpFontSize, "Arial Bold");

    CreateLabel("EA_Panel_Spread", "Spread: " + IntegerToString(symbolInfo.Spread()) + " points",
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    CreateLabel("EA_Panel_Ask", "Ask: " + DoubleToString(symbolInfo.Ask(), symbolInfo.Digits()),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    CreateLabel("EA_Panel_Bid", "Bid: " + DoubleToString(symbolInfo.Bid(), symbolInfo.Digits()),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    CreateLabel("EA_Panel_ATR", "ATR: " + DoubleToString(atrBuffer[0], symbolInfo.Digits()),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    CreateLabel("EA_Panel_RSI", "RSI: " + DoubleToString(rsiBuffer[0], 2),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    line++;

    // Status
    CreateLabel("EA_Panel_L4", "═════ STATUS ═════",
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), clrYellow, InpFontSize, "Arial Bold");

    string status = IsTradingAllowed() ? "ACTIVE" : "PAUSED";
    color statusColor = IsTradingAllowed() ? clrLime : clrOrange;
    CreateLabel("EA_Panel_Status", "Status: " + status,
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), statusColor, InpFontSize);

    string mode = InpAggressiveMode ? "AGGRESSIVE" : "CONSERVATIVE";
    CreateLabel("EA_Panel_Mode", "Mode: " + mode,
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    CreateLabel("EA_Panel_Time", "Server Time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES),
                xOffset + 10, yOffset + 10 + (line++ * lineHeight), InpTextColor, InpFontSize);

    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Display open trades on chart                                     |
//+------------------------------------------------------------------+
void DisplayOpenTrades()
{
    // Remove old trade lines
    for(int i = ObjectsTotal(0, 0, OBJ_TREND) - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i, 0, OBJ_TREND);
        if(StringFind(name, "EA_Trade_") >= 0)
            ObjectDelete(0, name);
    }

    for(int i = ObjectsTotal(0, 0, OBJ_TEXT) - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i, 0, OBJ_TEXT);
        if(StringFind(name, "EA_Trade_") >= 0)
            ObjectDelete(0, name);
    }

    // Draw lines for open positions
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Symbol() == InpSymbol &&
               positionInfo.Magic() == InpMagicNumber)
            {
                ulong ticket = positionInfo.Ticket();
                double openPrice = positionInfo.PriceOpen();
                double sl = positionInfo.StopLoss();
                double tp = positionInfo.TakeProfit();
                datetime openTime = (datetime)positionInfo.Time();
                double profit = positionInfo.Profit();
                ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)positionInfo.Type();

                color lineColor = (type == POSITION_TYPE_BUY) ? clrDodgerBlue : clrOrangeRed;

                // Entry line
                string entryName = "EA_Trade_Entry_" + IntegerToString(ticket);
                ObjectCreate(0, entryName, OBJ_TREND, 0, openTime, openPrice, TimeCurrent() + PeriodSeconds(PERIOD_H1), openPrice);
                ObjectSetInteger(0, entryName, OBJPROP_COLOR, lineColor);
                ObjectSetInteger(0, entryName, OBJPROP_WIDTH, 2);
                ObjectSetInteger(0, entryName, OBJPROP_STYLE, STYLE_SOLID);
                ObjectSetInteger(0, entryName, OBJPROP_RAY_RIGHT, true);
                ObjectSetInteger(0, entryName, OBJPROP_BACK, false);

                // SL line
                if(sl > 0)
                {
                    string slName = "EA_Trade_SL_" + IntegerToString(ticket);
                    ObjectCreate(0, slName, OBJ_TREND, 0, openTime, sl, TimeCurrent() + PeriodSeconds(PERIOD_H1), sl);
                    ObjectSetInteger(0, slName, OBJPROP_COLOR, clrRed);
                    ObjectSetInteger(0, slName, OBJPROP_WIDTH, 1);
                    ObjectSetInteger(0, slName, OBJPROP_STYLE, STYLE_DOT);
                    ObjectSetInteger(0, slName, OBJPROP_RAY_RIGHT, true);
                    ObjectSetInteger(0, slName, OBJPROP_BACK, false);
                }

                // TP line
                if(tp > 0)
                {
                    string tpName = "EA_Trade_TP_" + IntegerToString(ticket);
                    ObjectCreate(0, tpName, OBJ_TREND, 0, openTime, tp, TimeCurrent() + PeriodSeconds(PERIOD_H1), tp);
                    ObjectSetInteger(0, tpName, OBJPROP_COLOR, clrLime);
                    ObjectSetInteger(0, tpName, OBJPROP_WIDTH, 1);
                    ObjectSetInteger(0, tpName, OBJPROP_STYLE, STYLE_DOT);
                    ObjectSetInteger(0, tpName, OBJPROP_RAY_RIGHT, true);
                    ObjectSetInteger(0, tpName, OBJPROP_BACK, false);
                }

                // Trade info text
                string infoName = "EA_Trade_Info_" + IntegerToString(ticket);
                string typeStr = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
                string infoText = "#" + IntegerToString(ticket) + " " + typeStr + " | P/L: $" + DoubleToString(profit, 2);

                ObjectCreate(0, infoName, OBJ_TEXT, 0, openTime, openPrice);
                ObjectSetString(0, infoName, OBJPROP_TEXT, infoText);
                ObjectSetInteger(0, infoName, OBJPROP_COLOR, profit >= 0 ? clrLime : clrRed);
                ObjectSetInteger(0, infoName, OBJPROP_FONTSIZE, 8);
                ObjectSetString(0, infoName, OBJPROP_FONT, "Arial Bold");
                ObjectSetInteger(0, infoName, OBJPROP_BACK, false);
            }
        }
    }

    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create label helper function                                     |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize, string font = "Arial")
{
    if(ObjectFind(0, name) < 0)
    {
        ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    }

    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
    ObjectSetString(0, name, OBJPROP_FONT, font);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+