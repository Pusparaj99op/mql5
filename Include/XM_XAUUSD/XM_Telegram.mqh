//+------------------------------------------------------------------+
//|                                                 XM_Telegram.mqh |
//|                        Telegram Bot Integration                  |
//|                              Copyright 2024-2026, XM_XAUUSD Bot  |
//+------------------------------------------------------------------+
#property copyright "XM_XAUUSD Bot"
#property link      "https://github.com/Pusparaj99op/XM_XAUUSD"
#property version   "1.00"
#property strict

#ifndef XM_TELEGRAM_MQH
#define XM_TELEGRAM_MQH

#include "XM_Config.mqh"

//+------------------------------------------------------------------+
//| CTelegramNotifier Class                                           |
//+------------------------------------------------------------------+
class CTelegramNotifier
{
private:
   string            m_botToken;
   string            m_chatID;
   string            m_baseURL;
   bool              m_enabled;
   datetime          m_lastMessageTime;
   int               m_messageCount;
   int               m_maxMessagesPerMinute;

   // Message queue for rate limiting
   string            m_messageQueue[];
   int               m_queueSize;

public:
   //--- Constructor/Destructor
                     CTelegramNotifier();
                    ~CTelegramNotifier();

   //--- Initialization
   bool              Initialize(string botToken, string chatID);
   void              SetEnabled(bool enabled) { m_enabled = enabled; }
   bool              IsEnabled() { return m_enabled; }

   //--- Message sending
   bool              SendMessage(string message);
   bool              SendTradeAlert(string type, string symbol, double lots, double price, double sl, double tp, string reason);
   bool              SendTradeClose(string symbol, double lots, double profit, double pips);
   bool              SendDailySummary(double balance, double equity, double dailyPnL, int trades, double winRate);
   bool              SendDrawdownAlert(double drawdownPercent, string type);
   bool              SendErrorAlert(string errorMessage);
   bool              SendSignalAlert(string direction, string reasons, double strength);

   //--- Formatting helpers
   string            FormatCurrency(double value);
   string            FormatPips(double pips);
   string            FormatPercent(double percent);
   string            EscapeMarkdown(string text);

   //--- Rate limiting
   bool              CanSendMessage();
   void              ProcessQueue();
   void              AddToQueue(string message);

private:
   bool              SendHTTPRequest(string message);
   string            URLEncode(string text);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CTelegramNotifier::CTelegramNotifier()
{
   m_botToken = "8444474068:AAFHrgxr40UchqyjQGKtsN6U0lilUiBgEBQ";
   m_chatID = "-1003558051069";
   m_baseURL = "https://api.telegram.org/bot";
   m_enabled = false;
   m_lastMessageTime = 0;
   m_messageCount = 0;
   m_maxMessagesPerMinute = 20;
   m_queueSize = 0;
   ArrayResize(m_messageQueue, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CTelegramNotifier::~CTelegramNotifier()
{
   ArrayFree(m_messageQueue);
}

//+------------------------------------------------------------------+
//| Initialize with credentials                                       |
//+------------------------------------------------------------------+
bool CTelegramNotifier::Initialize(string botToken, string chatID)
{
   if(StringLen(botToken) == 0 || StringLen(chatID) == 0)
   {
      Print("Telegram: Bot token or chat ID not provided. Notifications disabled.");
      m_enabled = false;
      return false;
   }

   m_botToken = botToken;
   m_chatID = chatID;
   m_enabled = true;

   Print("Telegram notifier initialized");

   // Send test message
   if(InpDebugMode)
   {
      SendMessage("🤖 XM XAUUSD Scalper Bot started!\n\n" +
                  "Symbol: " + InpSymbol + "\n" +
                  "Timeframe: M5\n" +
                  "Risk: " + DoubleToString(InpRiskPercent, 1) + "%");
   }

   return true;
}

//+------------------------------------------------------------------+
//| Send plain message                                                |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendMessage(string message)
{
   if(!m_enabled) return false;

   if(!CanSendMessage())
   {
      AddToQueue(message);
      return false;
   }

   return SendHTTPRequest(message);
}

//+------------------------------------------------------------------+
//| Send trade opened alert                                           |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendTradeAlert(string type, string symbol, double lots, double price, double sl, double tp, string reason)
{
   if(!m_enabled || !InpTelegramTradeAlerts) return false;

   string emoji = (type == "BUY") ? "🟢" : "🔴";
   string arrow = (type == "BUY") ? "⬆️" : "⬇️";

   string msg = emoji + " *NEW " + type + " ORDER*\n\n";
   msg += "Symbol: `" + symbol + "`\n";
   msg += "Direction: " + arrow + " " + type + "\n";
   msg += "Volume: `" + DoubleToString(lots, 2) + "` lots\n";
   msg += "Entry: `" + DoubleToString(price, 2) + "`\n";
   msg += "SL: `" + DoubleToString(sl, 2) + "`\n";
   msg += "TP: `" + DoubleToString(tp, 2) + "`\n";
   msg += "\n📊 Reason: " + reason;
   msg += "\n\n⏰ " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   return SendMessage(msg);
}

//+------------------------------------------------------------------+
//| Send trade closed alert                                           |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendTradeClose(string symbol, double lots, double profit, double pips)
{
   if(!m_enabled || !InpTelegramTradeAlerts) return false;

   string emoji = (profit >= 0) ? "✅" : "❌";
   string status = (profit >= 0) ? "PROFIT" : "LOSS";

   string msg = emoji + " *TRADE CLOSED - " + status + "*\n\n";
   msg += "Symbol: `" + symbol + "`\n";
   msg += "Volume: `" + DoubleToString(lots, 2) + "` lots\n";
   msg += "Result: `" + FormatCurrency(profit) + "`\n";
   msg += "Pips: `" + FormatPips(pips) + "`\n";
   msg += "\n⏰ " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   return SendMessage(msg);
}

//+------------------------------------------------------------------+
//| Send daily summary                                                |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendDailySummary(double balance, double equity, double dailyPnL, int trades, double winRate)
{
   if(!m_enabled || !InpTelegramDailySummary) return false;

   string pnlEmoji = (dailyPnL >= 0) ? "📈" : "📉";

   string msg = "📊 *DAILY SUMMARY*\n";
   msg += "━━━━━━━━━━━━━━━━━━\n\n";
   msg += "💰 Balance: `" + FormatCurrency(balance) + "`\n";
   msg += "💎 Equity: `" + FormatCurrency(equity) + "`\n";
   msg += pnlEmoji + " Daily P&L: `" + FormatCurrency(dailyPnL) + "`\n\n";
   msg += "📈 Trades: `" + IntegerToString(trades) + "`\n";
   msg += "🎯 Win Rate: `" + FormatPercent(winRate) + "`\n";
   msg += "\n━━━━━━━━━━━━━━━━━━\n";
   msg += "🤖 XM XAUUSD Scalper";

   return SendMessage(msg);
}

//+------------------------------------------------------------------+
//| Send drawdown alert                                               |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendDrawdownAlert(double drawdownPercent, string type)
{
   if(!m_enabled || !InpTelegramDrawdownAlert) return false;

   string msg = "⚠️ *DRAWDOWN ALERT*\n\n";
   msg += "Type: " + type + "\n";
   msg += "Drawdown: `" + FormatPercent(drawdownPercent) + "`\n";
   msg += "\n⏰ " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   if(drawdownPercent >= InpDailyDrawdownLimit * 0.8)
   {
      msg += "\n\n🚨 Approaching limit! Trading may pause.";
   }

   return SendMessage(msg);
}

//+------------------------------------------------------------------+
//| Send error alert                                                  |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendErrorAlert(string errorMessage)
{
   if(!m_enabled) return false;

   string msg = "🚨 *ERROR ALERT*\n\n";
   msg += "```\n" + errorMessage + "\n```\n";
   msg += "\n⏰ " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   return SendMessage(msg);
}

//+------------------------------------------------------------------+
//| Send signal alert                                                 |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendSignalAlert(string direction, string reasons, double strength)
{
   if(!m_enabled) return false;

   string emoji = (direction == "BUY") ? "🟢" : "🔴";

   string msg = emoji + " *SIGNAL DETECTED*\n\n";
   msg += "Direction: " + direction + "\n";
   msg += "Strength: " + DoubleToString(strength * 100, 0) + "%\n";
   msg += "Reasons:\n" + reasons + "\n";
   msg += "\n⏰ " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   return SendMessage(msg);
}

//+------------------------------------------------------------------+
//| Format currency value                                             |
//+------------------------------------------------------------------+
string CTelegramNotifier::FormatCurrency(double value)
{
   string sign = (value >= 0) ? "+" : "";
   return sign + "$" + DoubleToString(MathAbs(value), 2);
}

//+------------------------------------------------------------------+
//| Format pips value                                                 |
//+------------------------------------------------------------------+
string CTelegramNotifier::FormatPips(double pips)
{
   string sign = (pips >= 0) ? "+" : "";
   return sign + DoubleToString(pips, 1) + " pips";
}

//+------------------------------------------------------------------+
//| Format percentage                                                 |
//+------------------------------------------------------------------+
string CTelegramNotifier::FormatPercent(double percent)
{
   return DoubleToString(percent, 2) + "%";
}

//+------------------------------------------------------------------+
//| Escape markdown special characters                                |
//+------------------------------------------------------------------+
string CTelegramNotifier::EscapeMarkdown(string text)
{
   // Escape special markdown characters
   StringReplace(text, "_", "\\_");
   StringReplace(text, "[", "\\[");
   StringReplace(text, "]", "\\]");
   StringReplace(text, "(", "\\(");
   StringReplace(text, ")", "\\)");
   StringReplace(text, "~", "\\~");
   StringReplace(text, ">", "\\>");
   StringReplace(text, "#", "\\#");
   StringReplace(text, "+", "\\+");
   StringReplace(text, "-", "\\-");
   StringReplace(text, "=", "\\=");
   StringReplace(text, "|", "\\|");
   StringReplace(text, "{", "\\{");
   StringReplace(text, "}", "\\}");
   StringReplace(text, ".", "\\.");
   StringReplace(text, "!", "\\!");

   return text;
}

//+------------------------------------------------------------------+
//| Check if can send message (rate limiting)                         |
//+------------------------------------------------------------------+
bool CTelegramNotifier::CanSendMessage()
{
   datetime now = TimeCurrent();

   // Reset counter every minute
   if(now - m_lastMessageTime >= 60)
   {
      m_messageCount = 0;
      m_lastMessageTime = now;
   }

   return m_messageCount < m_maxMessagesPerMinute;
}

//+------------------------------------------------------------------+
//| Process message queue                                             |
//+------------------------------------------------------------------+
void CTelegramNotifier::ProcessQueue()
{
   if(m_queueSize == 0) return;
   if(!CanSendMessage()) return;

   // Send first message in queue
   if(SendHTTPRequest(m_messageQueue[0]))
   {
      // Remove from queue
      for(int i = 0; i < m_queueSize - 1; i++)
         m_messageQueue[i] = m_messageQueue[i + 1];

      m_queueSize--;
      ArrayResize(m_messageQueue, m_queueSize);
   }
}

//+------------------------------------------------------------------+
//| Add message to queue                                              |
//+------------------------------------------------------------------+
void CTelegramNotifier::AddToQueue(string message)
{
   if(m_queueSize >= 50) // Max queue size
   {
      // Remove oldest
      for(int i = 0; i < m_queueSize - 1; i++)
         m_messageQueue[i] = m_messageQueue[i + 1];
      m_queueSize--;
   }

   ArrayResize(m_messageQueue, m_queueSize + 1);
   m_messageQueue[m_queueSize] = message;
   m_queueSize++;
}

//+------------------------------------------------------------------+
//| Send HTTP request to Telegram API                                 |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendHTTPRequest(string message)
{
   if(!m_enabled) return false;

   string url = m_baseURL + m_botToken + "/sendMessage";

   // Prepare POST data
   string postData = "chat_id=" + m_chatID + "&text=" + URLEncode(message) + "&parse_mode=Markdown";

   char data[];
   char result[];
   string resultHeaders;

   StringToCharArray(postData, data, 0, StringLen(postData), CP_UTF8);
   ArrayResize(data, ArraySize(data) - 1); // Remove null terminator

   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";

   int timeout = 5000; // 5 seconds

   int res = WebRequest(
      "POST",
      url,
      headers,
      timeout,
      data,
      result,
      resultHeaders
   );

   if(res == -1)
   {
      int error = GetLastError();
      if(error == 4014) // URL not allowed
      {
         Print("Telegram error: URL not allowed in MT5. Add 'https://api.telegram.org' to Tools -> Options -> Expert Advisors -> Allow WebRequest");
      }
      else
      {
         Print("Telegram WebRequest error: ", error);
      }
      return false;
   }

   m_messageCount++;

   if(res == 200)
   {
      if(InpDebugMode)
         Print("Telegram message sent successfully");
      return true;
   }
   else
   {
      string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
      Print("Telegram API error. Code: ", res, " Response: ", response);
      return false;
   }
}

//+------------------------------------------------------------------+
//| URL encode string                                                 |
//+------------------------------------------------------------------+
string CTelegramNotifier::URLEncode(string text)
{
   string result = "";
   int len = StringLen(text);

   for(int i = 0; i < len; i++)
   {
      ushort ch = StringGetCharacter(text, i);

      if((ch >= 'a' && ch <= 'z') ||
         (ch >= 'A' && ch <= 'Z') ||
         (ch >= '0' && ch <= '9') ||
         ch == '-' || ch == '_' || ch == '.' || ch == '~')
      {
         result += ShortToString(ch);
      }
      else if(ch == ' ')
      {
         result += "+";
      }
      else
      {
         // Encode as %XX
         uchar bytes[];
         int byteLen = StringToCharArray(StringSubstr(text, i, 1), bytes, 0, -1, CP_UTF8);

         for(int j = 0; j < byteLen - 1; j++)
         {
            result += StringFormat("%%%02X", bytes[j]);
         }
      }
   }

   return result;
}

#endif // XM_TELEGRAM_MQH
//+------------------------------------------------------------------+
