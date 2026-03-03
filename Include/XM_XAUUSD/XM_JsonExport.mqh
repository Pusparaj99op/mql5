//+------------------------------------------------------------------+
//|                                               XM_JsonExport.mqh |
//|                        Real-time JSON Data Export                |
//|                              Copyright 2024-2026, XM_XAUUSD Bot  |
//+------------------------------------------------------------------+
#property copyright "XM_XAUUSD Bot"
#property link      "https://github.com/Pusparaj99op/XM_XAUUSD"
#property version   "1.00"
#property strict

#ifndef XM_JSONEXPORT_MQH
#define XM_JSONEXPORT_MQH

#include "XM_Config.mqh"

//+------------------------------------------------------------------+
//| CJsonExporter Class                                               |
//+------------------------------------------------------------------+
class CJsonExporter
{
private:
   string            m_filename;
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   int               m_updateInterval;
   datetime          m_lastUpdate;
   bool              m_enabled;
   int               m_fileHandle;

public:
   //--- Constructor/Destructor
                     CJsonExporter();
                    ~CJsonExporter();

   //--- Initialization
   bool              Initialize(string symbol, ENUM_TIMEFRAMES tf, string filename, int updateSeconds);
   void              Deinitialize();
   void              SetEnabled(bool enabled) { m_enabled = enabled; }

   //--- Export methods
   bool              ShouldUpdate();
   bool              ExportData(MarketState &state, RiskMetrics &risk, TradeSignal &signal);
   bool              ExportPriceData();
   bool              ExportPositions();
   bool              ExportAccountInfo();

   //--- JSON building helpers
   string            BuildMarketStateJson(MarketState &state);
   string            BuildRiskMetricsJson(RiskMetrics &risk);
   string            BuildSignalJson(TradeSignal &signal);
   string            BuildPositionsJson();
   string            BuildOHLCJson(int bars = 100);
   string            BuildIndicatorsJson(MarketState &state);

   //--- Utility
   string            DoubleToJsonString(double value, int digits = 5);
   string            BoolToJsonString(bool value);
   string            EscapeJsonString(string text);
   string            GetFilePath() { return m_filename; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CJsonExporter::CJsonExporter()
{
   m_filename = "xauusd_live.json";
   m_symbol = "";
   m_timeframe = PERIOD_M5;
   m_updateInterval = 5;
   m_lastUpdate = 0;
   m_enabled = false;
   m_fileHandle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CJsonExporter::~CJsonExporter()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CJsonExporter::Initialize(string symbol, ENUM_TIMEFRAMES tf, string filename, int updateSeconds)
{
   m_symbol = symbol;
   m_timeframe = tf;
   m_filename = filename;
   m_updateInterval = updateSeconds;
   m_enabled = true;
   m_lastUpdate = 0;

   Print("JSON Exporter initialized. File: ", m_filename);
   Print("Update interval: ", m_updateInterval, " seconds");
   Print("File will be saved to: MQL5/Files/", m_filename);

   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize                                                      |
//+------------------------------------------------------------------+
void CJsonExporter::Deinitialize()
{
   if(m_fileHandle != INVALID_HANDLE)
   {
      FileClose(m_fileHandle);
      m_fileHandle = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Check if should update                                            |
//+------------------------------------------------------------------+
bool CJsonExporter::ShouldUpdate()
{
   if(!m_enabled) return false;

   datetime now = TimeCurrent();
   if(now - m_lastUpdate >= m_updateInterval)
   {
      m_lastUpdate = now;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Export all data to JSON file                                      |
//+------------------------------------------------------------------+
bool CJsonExporter::ExportData(MarketState &state, RiskMetrics &risk, TradeSignal &signal)
{
   if(!m_enabled) return false;

   // Build complete JSON
   string json = "{\n";

   // Timestamp
   json += "  \"timestamp\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\",\n";
   json += "  \"timestamp_unix\": " + IntegerToString((long)TimeCurrent()) + ",\n";
   json += "  \"symbol\": \"" + m_symbol + "\",\n";
   json += "  \"timeframe\": \"M5\",\n";

   // Market state
   json += "  \"market\": " + BuildMarketStateJson(state) + ",\n";

   // Indicators
   json += "  \"indicators\": " + BuildIndicatorsJson(state) + ",\n";

   // Current signal
   json += "  \"signal\": " + BuildSignalJson(signal) + ",\n";

   // Risk metrics
   json += "  \"risk\": " + BuildRiskMetricsJson(risk) + ",\n";

   // Open positions
   json += "  \"positions\": " + BuildPositionsJson() + ",\n";

   // Recent OHLC data
   json += "  \"ohlc\": " + BuildOHLCJson(50) + "\n";

   json += "}\n";

   // Write to file
   int handle = FileOpen(m_filename, FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      Print("Failed to open JSON file for writing: ", GetLastError());
      return false;
   }

   FileWriteString(handle, json);
   FileClose(handle);

   if(InpDebugMode)
      Print("JSON data exported to ", m_filename);

   return true;
}

//+------------------------------------------------------------------+
//| Export price data only                                            |
//+------------------------------------------------------------------+
bool CJsonExporter::ExportPriceData()
{
   string json = "{\n";
   json += "  \"timestamp\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\",\n";
   json += "  \"symbol\": \"" + m_symbol + "\",\n";
   json += "  \"bid\": " + DoubleToJsonString(SymbolInfoDouble(m_symbol, SYMBOL_BID), 2) + ",\n";
   json += "  \"ask\": " + DoubleToJsonString(SymbolInfoDouble(m_symbol, SYMBOL_ASK), 2) + ",\n";
   json += "  \"spread\": " + DoubleToJsonString(SymbolInfoDouble(m_symbol, SYMBOL_ASK) - SymbolInfoDouble(m_symbol, SYMBOL_BID), 2) + ",\n";
   json += "  \"ohlc\": " + BuildOHLCJson(10) + "\n";
   json += "}\n";

   int handle = FileOpen("xauusd_price.json", FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE) return false;

   FileWriteString(handle, json);
   FileClose(handle);

   return true;
}

//+------------------------------------------------------------------+
//| Export positions only                                             |
//+------------------------------------------------------------------+
bool CJsonExporter::ExportPositions()
{
   string json = "{\n";
   json += "  \"timestamp\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\",\n";
   json += "  \"positions\": " + BuildPositionsJson() + "\n";
   json += "}\n";

   int handle = FileOpen("xauusd_positions.json", FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE) return false;

   FileWriteString(handle, json);
   FileClose(handle);

   return true;
}

//+------------------------------------------------------------------+
//| Export account info only                                          |
//+------------------------------------------------------------------+
bool CJsonExporter::ExportAccountInfo()
{
   string json = "{\n";
   json += "  \"timestamp\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\",\n";
   json += "  \"balance\": " + DoubleToJsonString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",\n";
   json += "  \"equity\": " + DoubleToJsonString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ",\n";
   json += "  \"margin\": " + DoubleToJsonString(AccountInfoDouble(ACCOUNT_MARGIN), 2) + ",\n";
   json += "  \"free_margin\": " + DoubleToJsonString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2) + ",\n";
   json += "  \"margin_level\": " + DoubleToJsonString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2) + ",\n";
   json += "  \"profit\": " + DoubleToJsonString(AccountInfoDouble(ACCOUNT_PROFIT), 2) + "\n";
   json += "}\n";

   int handle = FileOpen("xauusd_account.json", FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE) return false;

   FileWriteString(handle, json);
   FileClose(handle);

   return true;
}

//+------------------------------------------------------------------+
//| Build Market State JSON                                           |
//+------------------------------------------------------------------+
string CJsonExporter::BuildMarketStateJson(MarketState &state)
{
   string json = "{\n";
   json += "    \"bid\": " + DoubleToJsonString(state.bid, 2) + ",\n";
   json += "    \"ask\": " + DoubleToJsonString(state.ask, 2) + ",\n";
   json += "    \"spread\": " + DoubleToJsonString(state.spread, 2) + ",\n";
   json += "    \"atr\": " + DoubleToJsonString(state.atr, 2) + ",\n";
   json += "    \"trend\": \"" + EnumToString(state.trend) + "\",\n";
   json += "    \"volatility\": \"" + EnumToString(state.volatility) + "\",\n";
   json += "    \"session\": \"" + EnumToString(state.session) + "\"\n";
   json += "  }";

   return json;
}

//+------------------------------------------------------------------+
//| Build Indicators JSON                                             |
//+------------------------------------------------------------------+
string CJsonExporter::BuildIndicatorsJson(MarketState &state)
{
   string json = "{\n";
   json += "    \"rsi\": " + DoubleToJsonString(state.rsi, 2) + ",\n";
   json += "    \"bb_upper\": " + DoubleToJsonString(state.bbUpper, 2) + ",\n";
   json += "    \"bb_middle\": " + DoubleToJsonString(state.bbMiddle, 2) + ",\n";
   json += "    \"bb_lower\": " + DoubleToJsonString(state.bbLower, 2) + ",\n";
   json += "    \"macd_main\": " + DoubleToJsonString(state.macdMain, 5) + ",\n";
   json += "    \"macd_signal\": " + DoubleToJsonString(state.macdSignal, 5) + ",\n";
   json += "    \"macd_histogram\": " + DoubleToJsonString(state.macdHistogram, 5) + ",\n";
   json += "    \"ma_fast\": " + DoubleToJsonString(state.maFast, 2) + ",\n";
   json += "    \"ma_slow\": " + DoubleToJsonString(state.maSlow, 2) + ",\n";
   json += "    \"ma_trend\": " + DoubleToJsonString(state.maTrend, 2) + ",\n";
   json += "    \"stoch_k\": " + DoubleToJsonString(state.stochK, 2) + ",\n";
   json += "    \"stoch_d\": " + DoubleToJsonString(state.stochD, 2) + "\n";
   json += "  }";

   return json;
}

//+------------------------------------------------------------------+
//| Build Signal JSON                                                 |
//+------------------------------------------------------------------+
string CJsonExporter::BuildSignalJson(TradeSignal &signal)
{
   string direction = "NONE";
   if(signal.direction == SIGNAL_BUY) direction = "BUY";
   else if(signal.direction == SIGNAL_SELL) direction = "SELL";

   string json = "{\n";
   json += "    \"direction\": \"" + direction + "\",\n";
   json += "    \"strength\": " + DoubleToJsonString(signal.strength, 2) + ",\n";
   json += "    \"signal_count\": " + IntegerToString(signal.signalCount) + ",\n";
   json += "    \"entry_price\": " + DoubleToJsonString(signal.entryPrice, 2) + ",\n";
   json += "    \"stop_loss\": " + DoubleToJsonString(signal.stopLoss, 2) + ",\n";
   json += "    \"take_profit\": " + DoubleToJsonString(signal.takeProfit, 2) + ",\n";
   json += "    \"reason\": \"" + EscapeJsonString(signal.reason) + "\",\n";
   json += "    \"time\": \"" + TimeToString(signal.signalTime, TIME_DATE|TIME_SECONDS) + "\"\n";
   json += "  }";

   return json;
}

//+------------------------------------------------------------------+
//| Build Risk Metrics JSON                                           |
//+------------------------------------------------------------------+
string CJsonExporter::BuildRiskMetricsJson(RiskMetrics &risk)
{
   string json = "{\n";
   json += "    \"balance\": " + DoubleToJsonString(risk.accountBalance, 2) + ",\n";
   json += "    \"equity\": " + DoubleToJsonString(risk.accountEquity, 2) + ",\n";
   json += "    \"margin\": " + DoubleToJsonString(risk.accountMargin, 2) + ",\n";
   json += "    \"free_margin\": " + DoubleToJsonString(risk.freeMargin, 2) + ",\n";
   json += "    \"daily_pnl\": " + DoubleToJsonString(risk.dailyPnL, 2) + ",\n";
   json += "    \"weekly_pnl\": " + DoubleToJsonString(risk.weeklyPnL, 2) + ",\n";
   json += "    \"daily_drawdown\": " + DoubleToJsonString(risk.dailyDrawdown, 2) + ",\n";
   json += "    \"weekly_drawdown\": " + DoubleToJsonString(risk.weeklyDrawdown, 2) + ",\n";
   json += "    \"max_drawdown\": " + DoubleToJsonString(risk.maxDrawdown, 2) + ",\n";
   json += "    \"total_trades\": " + IntegerToString(risk.totalTrades) + ",\n";
   json += "    \"winning_trades\": " + IntegerToString(risk.winningTrades) + ",\n";
   json += "    \"losing_trades\": " + IntegerToString(risk.losingTrades) + ",\n";
   json += "    \"win_rate\": " + DoubleToJsonString(risk.winRate, 2) + ",\n";
   json += "    \"consecutive_wins\": " + IntegerToString(risk.consecutiveWins) + ",\n";
   json += "    \"consecutive_losses\": " + IntegerToString(risk.consecutiveLosses) + ",\n";
   json += "    \"lot_multiplier\": " + DoubleToJsonString(risk.currentLotMultiplier, 2) + ",\n";
   json += "    \"trading_enabled\": " + BoolToJsonString(risk.tradingEnabled) + ",\n";
   json += "    \"pause_reason\": \"" + EscapeJsonString(risk.pauseReason) + "\"\n";
   json += "  }";

   return json;
}

//+------------------------------------------------------------------+
//| Build Positions JSON                                              |
//+------------------------------------------------------------------+
string CJsonExporter::BuildPositionsJson()
{
   string json = "[\n";
   bool first = true;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      if(!first) json += ",\n";
      first = false;

      string type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";

      json += "    {\n";
      json += "      \"ticket\": " + IntegerToString(ticket) + ",\n";
      json += "      \"type\": \"" + type + "\",\n";
      json += "      \"volume\": " + DoubleToJsonString(PositionGetDouble(POSITION_VOLUME), 2) + ",\n";
      json += "      \"open_price\": " + DoubleToJsonString(PositionGetDouble(POSITION_PRICE_OPEN), 2) + ",\n";
      json += "      \"current_price\": " + DoubleToJsonString(PositionGetDouble(POSITION_PRICE_CURRENT), 2) + ",\n";
      json += "      \"sl\": " + DoubleToJsonString(PositionGetDouble(POSITION_SL), 2) + ",\n";
      json += "      \"tp\": " + DoubleToJsonString(PositionGetDouble(POSITION_TP), 2) + ",\n";
      json += "      \"profit\": " + DoubleToJsonString(PositionGetDouble(POSITION_PROFIT), 2) + ",\n";
      json += "      \"swap\": " + DoubleToJsonString(PositionGetDouble(POSITION_SWAP), 2) + ",\n";
      json += "      \"open_time\": \"" + TimeToString((datetime)PositionGetInteger(POSITION_TIME), TIME_DATE|TIME_SECONDS) + "\"\n";
      json += "    }";
   }

   json += "\n  ]";

   return json;
}

//+------------------------------------------------------------------+
//| Build OHLC JSON                                                   |
//+------------------------------------------------------------------+
string CJsonExporter::BuildOHLCJson(int bars = 100)
{
   string json = "[\n";

   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int copied = CopyRates(m_symbol, m_timeframe, 0, bars, rates);
   if(copied <= 0)
   {
      json += "  ]";
      return json;
   }

   for(int i = copied - 1; i >= 0; i--)
   {
      json += "    {\n";
      json += "      \"time\": \"" + TimeToString(rates[i].time, TIME_DATE|TIME_SECONDS) + "\",\n";
      json += "      \"time_unix\": " + IntegerToString((long)rates[i].time) + ",\n";
      json += "      \"open\": " + DoubleToJsonString(rates[i].open, 2) + ",\n";
      json += "      \"high\": " + DoubleToJsonString(rates[i].high, 2) + ",\n";
      json += "      \"low\": " + DoubleToJsonString(rates[i].low, 2) + ",\n";
      json += "      \"close\": " + DoubleToJsonString(rates[i].close, 2) + ",\n";
      json += "      \"volume\": " + IntegerToString(rates[i].tick_volume) + "\n";
      json += "    }";

      if(i > 0) json += ",";
      json += "\n";
   }

   json += "  ]";

   return json;
}

//+------------------------------------------------------------------+
//| Convert double to JSON string                                     |
//+------------------------------------------------------------------+
string CJsonExporter::DoubleToJsonString(double value, int digits = 5)
{
   if(!MathIsValidNumber(value))
      return "null";

   return DoubleToString(value, digits);
}

//+------------------------------------------------------------------+
//| Convert bool to JSON string                                       |
//+------------------------------------------------------------------+
string CJsonExporter::BoolToJsonString(bool value)
{
   return value ? "true" : "false";
}

//+------------------------------------------------------------------+
//| Escape JSON string                                                |
//+------------------------------------------------------------------+
string CJsonExporter::EscapeJsonString(string text)
{
   StringReplace(text, "\\", "\\\\");
   StringReplace(text, "\"", "\\\"");
   StringReplace(text, "\n", "\\n");
   StringReplace(text, "\r", "\\r");
   StringReplace(text, "\t", "\\t");

   return text;
}

#endif // XM_JSONEXPORT_MQH
//+------------------------------------------------------------------+
