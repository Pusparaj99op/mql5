//+------------------------------------------------------------------+
//|            H4_Zone_Retest_M5_Fixed.mq5                           |
//|  Fixed version with ATR, EMA filter, improved trailing           |
//+------------------------------------------------------------------+
#property copyright "2025, phatnomenal"
#property version   "1.22"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\TerminalInfo.mqh>

CPositionInfo m_position;
CTrade        trade;

//-------------------- INPUTS --------------------
input double Lots               = 0.1;
input int    MaxWaitSeconds     = 24*60*60;
input bool   UseRiskPercent     = false;
input double RiskPercent        = 1.0;
input int    Slippage           = 10;
input bool   OnlyOnePosition    = true;
input string TradeComment       = "H4ZoneRetest";
input bool   UseNewsFilter      = true;
input int    NewsFilterMinutes  = 30;
input string NewsFilterCurrency = "USD";
input bool   UseTrailingStop    = true;
input int    TrailingMode       = 0;          // 0=fixed, 1=ATR
input double TrailingStart      = 200.0;
input double TrailingStep       = 100.0;
input int    ATR_Trail_Period   = 14;
input ENUM_TIMEFRAMES ATR_Trail_Timeframe = PERIOD_M15;
input double ATR_Trail_Mult     = 1.5;
input double BE_MovePoints      = 300.0;
input int    MagicNumber        = 202503;
input double MaxSpreadPoints    = 50.0;
input bool   NormalizePricesOut = true;
input bool   UseSessionFilter  = true;   // Bật/tắt lọc theo phiên
input int    SessionStartHour  = 7;      // Giờ bắt đầu (London)
input int    SessionEndHour    = 22;     // Giờ kết thúc (NY)
input double ShortLotMultiplier = 0.5; // multiplier cho short orders

// Zone settings
input int    ZoneMode           = 0;          // 0 = Daily HL prev, 1 = first N H4 bars
input int    ZoneFirstH4Count   = 4;

// Breakout confirmation
input double BreakoutBodyPct    = 50.0;
input double BreakoutMinPoints  = 200.0;

// EMA filter
input bool   UseEMAFilter       = true;
input int    EMA_Fast           = 50;
input int    EMA_Slow           = 200;
input ENUM_TIMEFRAMES EMA_Timeframe = PERIOD_H1;

// ATR for SL/TP
input bool   UseATRSizing       = true;
input int    ATR_Period         = 14;
input ENUM_TIMEFRAMES ATR_Timeframe = PERIOD_H1;
input double ATR_SL_Mult        = 1.5;
input double ATR_TP_Mult        = 3.0;

//-------------------- STATE --------------------
double zoneHigh = 0.0;
double zoneLow  = 0.0;
datetime zoneDayStart = 0;

bool   waitingRetest = false;
int    breakoutDir = 0;
double breakoutCandleHigh = 0.0;
double breakoutCandleLow  = 0.0;
datetime breakoutTime = 0;
datetime lastM5BarTime = 0;

//------------------------------------------------------------------
double NormPrice(double price){int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);return(NormalizePricesOut?NormalizeDouble(price,digits):price);} 

//------------------------------------------------------------------
// Zone update
//------------------------------------------------------------------
bool UpdateZoneIfNeeded(){
   datetime todayStart=(datetime)iTime(_Symbol,PERIOD_D1,1);
   if(todayStart==0) return(false);
   if(todayStart==zoneDayStart && zoneHigh>0 && zoneLow>0) return(true);

   if(ZoneMode==0){
      zoneHigh=iHigh(_Symbol,PERIOD_D1,1);
      zoneLow =iLow(_Symbol,PERIOD_D1,1);
   } else {
      datetime dayStart=iTime(_Symbol,PERIOD_D1,0);
      int h4Index=iBarShift(_Symbol,PERIOD_H4,dayStart,true);
      if(h4Index==-1) h4Index=0;
      zoneHigh=-DBL_MAX; zoneLow=DBL_MAX;
      for(int k=0;k<ZoneFirstH4Count;k++){
         double h=iHigh(_Symbol,PERIOD_H4,h4Index+k);
         double l=iLow(_Symbol,PERIOD_H4,h4Index+k);
         zoneHigh=MathMax(zoneHigh,h);
         zoneLow =MathMin(zoneLow,l);
      }
   }
   zoneDayStart=todayStart;
   waitingRetest=false; breakoutDir=0;
   return(true);
}
//------------------------------------------------------------------
// Check if current time is inside allowed trading session
//------------------------------------------------------------------

bool IsInTradingSession()
{
   if(!UseSessionFilter) 
      return true;

   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);  // tách thời gian server thành cấu trúc
   int hour = tm.hour;               // lấy giờ

   // nếu khung giờ nằm trong cùng 1 ngày
   if(SessionStartHour <= SessionEndHour)
   {
      if(hour >= SessionStartHour && hour <= SessionEndHour)
         return true;
   }
   else
   {
      // nếu khung giờ qua ngày (ví dụ 22h -> 5h sáng hôm sau)
      if(hour >= SessionStartHour || hour <= SessionEndHour)
         return true;
   }

   return false;
}




//------------------------------------------------------------------
bool IsNewsTime(){if(!UseNewsFilter) return(false); 
datetime now=TimeCurrent(); datetime from_time=now-NewsFilterMinutes*60; 
datetime to_time=now+NewsFilterMinutes*60; 
MqlCalendarValue values[]; 
int cnt=CalendarValueHistory(values,from_time,to_time,"",""); 
if(cnt<=0) return(false); for(int i=0;i<cnt;i++){MqlCalendarEvent ev; 
if(!CalendarEventById(values[i].event_id,ev)) continue; if(ev.importance<CALENDAR_IMPORTANCE_MODERATE) continue;
 MqlCalendarCountry country; string currency="";
  if(CalendarCountryById((long)ev.country_id,country)) currency=country.currency; if(StringLen(NewsFilterCurrency)>0 && StringFind(currency,NewsFilterCurrency)==-1) continue; return(true);} return(false);} 

//------------------------------------------------------------------
double CalculateLotByRisk(double entry,double sl_price){double balance=AccountInfoDouble(ACCOUNT_BALANCE); if(balance<=0) return(0.0); double riskMoney=balance*RiskPercent/100.0; double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE); if(tickValue<=0) tickValue=1.0; double distPoints=MathAbs(entry-sl_price)/_Point; if(distPoints<=0) return(0.0); double lot=riskMoney/(distPoints*tickValue); double minVol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN); double maxVol=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX); double volStep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP); if(volStep<=0.0) volStep=0.01; if(minVol>0.0) lot=MathMax(lot,minVol); if(maxVol>0.0) lot=MathMin(lot,maxVol); int steps=(int)MathFloor(lot/volStep); if(steps<1) steps=1; lot=steps*volStep; return(NormalizeDouble(lot,2));}

//------------------------------------------------------------------
bool HasOpenPosition(const string symbol){int total=(int)PositionsTotal(); for(int idx=0;idx<total;idx++){if(m_position.SelectByIndex(idx)){if(m_position.Symbol()==symbol){ulong pos_magic=(ulong)m_position.Magic(); if(MagicNumber==0||pos_magic==(ulong)MagicNumber) return(true);}}} return(false);} 

//------------------------------------------------------------------
bool CheckMarketConditions(){double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK); double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID); double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT); if(point<=0.0) point=_Point; double spreadPoints=(ask-bid)/point; if(MaxSpreadPoints>0.0 && spreadPoints>MaxSpreadPoints){return(false);} return(true);} 

//------------------------------------------------------------------
void ManageTrailingStops(){
   if(!UseTrailingStop) return;
   int total=(int)PositionsTotal();
   for(int idx=0; idx<total; idx++){
      if(!m_position.SelectByIndex(idx)) continue;
      if(m_position.Symbol()!=_Symbol) continue;
      long type=(long)m_position.Type();
      ulong ticket=(ulong)m_position.Ticket();
      double open_price=m_position.PriceOpen();
      double sl=m_position.StopLoss();
      double tp=m_position.TakeProfit();
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT); if(point<=0.0) point=_Point;

      if(type==POSITION_TYPE_BUY){
         double profit_points=(bid-open_price)/point;
         if(profit_points>TrailingStart){
            double new_sl=sl;
            if(TrailingMode==0) new_sl=bid-TrailingStep*point;
            else{
               int handleATR=iATR(_Symbol,ATR_Trail_Timeframe,ATR_Trail_Period);
               double buf[]; if(CopyBuffer(handleATR,0,0,1,buf)>0){new_sl=bid-ATR_Trail_Mult*buf[0];}
               IndicatorRelease(handleATR);
            }
            if(new_sl>sl+_Point) trade.PositionModify(ticket,NormPrice(new_sl),tp);
         }
         if(profit_points>=BE_MovePoints && sl<open_price){trade.PositionModify(ticket,NormPrice(open_price),tp);} 
      }
      if(type==POSITION_TYPE_SELL){
         double profit_points=(open_price-ask)/point;
         if(profit_points>TrailingStart){
            double new_sl=sl;
            if(TrailingMode==0) new_sl=ask+TrailingStep*point;
            else{
               int handleATR=iATR(_Symbol,ATR_Trail_Timeframe,ATR_Trail_Period);
               double buf[]; if(CopyBuffer(handleATR,0,0,1,buf)>0){new_sl=ask+ATR_Trail_Mult*buf[0];}
               IndicatorRelease(handleATR);
            }
            if(sl==0.0||new_sl<sl-_Point) trade.PositionModify(ticket,NormPrice(new_sl),tp);
         }
         if(profit_points>=BE_MovePoints && (sl==0.0||sl>open_price)){trade.PositionModify(ticket,NormPrice(open_price),tp);} 
      }
   }
}

//------------------------------------------------------------------
int OnInit(){trade.SetExpertMagicNumber((ulong)MagicNumber); trade.SetDeviationInPoints(Slippage); UpdateZoneIfNeeded(); return(INIT_SUCCEEDED);} 

//------------------------------------------------------------------
void OnTick(){
 if(!IsInTradingSession())
      return;
UpdateZoneIfNeeded(); if(UseNewsFilter && IsNewsTime()) return; datetime currentM5Open=(datetime)iTime(_Symbol,PERIOD_M5,0); if(currentM5Open==0) return; if(currentM5Open==lastM5BarTime){ManageTrailingStops(); return;} lastM5BarTime=currentM5Open; double m5_open=iOpen(_Symbol,PERIOD_M5,1); double m5_close=iClose(_Symbol,PERIOD_M5,1); double m5_high=iHigh(_Symbol,PERIOD_M5,1); double m5_low=iLow(_Symbol,PERIOD_M5,1); datetime m5_close_time=(datetime)iTime(_Symbol,PERIOD_M5,1);

   double bodySize=MathAbs(m5_close-m5_open)/_Point;
   double rangeSize=(m5_high-m5_low)/_Point;
   bool bodyOk=(rangeSize>0 && bodySize>=BreakoutBodyPct/100.0*rangeSize);
   bool pointOk=(MathAbs(m5_close-m5_open)>=BreakoutMinPoints*_Point);

   if(m5_close>zoneHigh && m5_open<=zoneHigh && (bodyOk||pointOk)) {waitingRetest=true; breakoutDir=1; breakoutCandleHigh=m5_high; breakoutCandleLow=m5_low; breakoutTime=m5_close_time;} 
   else if(m5_close<zoneLow && m5_open>=zoneLow && (bodyOk||pointOk)) {waitingRetest=true; breakoutDir=-1; breakoutCandleHigh=m5_high; breakoutCandleLow=m5_low; breakoutTime=m5_close_time;}

   if(waitingRetest && TimeCurrent()-breakoutTime>MaxWaitSeconds){waitingRetest=false; breakoutDir=0;}

   if(waitingRetest && breakoutDir!=0){
      if(!CheckMarketConditions()) return;
      // EMA filter
      if(UseEMAFilter){
         int hFast=iMA(_Symbol,EMA_Timeframe,EMA_Fast,0,MODE_EMA,PRICE_CLOSE);
         int hSlow=iMA(_Symbol,EMA_Timeframe,EMA_Slow,0,MODE_EMA,PRICE_CLOSE);
         double emaFast=0.0, emaSlow=0.0;
         double bf[],bs[];
         if(hFast>0 && CopyBuffer(hFast,0,1,1,bf)>0) emaFast=bf[0];
         if(hSlow>0 && CopyBuffer(hSlow,0,1,1,bs)>0) emaSlow=bs[0];
         IndicatorRelease(hFast); IndicatorRelease(hSlow);
         double price=iClose(_Symbol,EMA_Timeframe,0);
         if(breakoutDir==1 && !(price>emaFast && price>emaSlow)){return;}
         if(breakoutDir==-1 && !(price<emaFast && price<emaSlow)){return;}
      }

      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      if(breakoutDir==1 && bid<=zoneHigh){
         if(OnlyOnePosition && HasOpenPosition(_Symbol)){waitingRetest=false; breakoutDir=0; return;}
         double entry=zoneHigh; double sl, tp; if(UseATRSizing){int h=iATR(_Symbol,ATR_Timeframe,ATR_Period); double buf[]; if(CopyBuffer(h,0,1,1,buf)>0){sl=entry-ATR_SL_Mult*buf[0]; tp=entry+ATR_TP_Mult*buf[0];} IndicatorRelease(h);} else {sl=breakoutCandleLow; tp=entry+1.5*(entry-sl);} entry=NormPrice(entry); sl=NormPrice(sl); tp=NormPrice(tp); double vol=UseRiskPercent?CalculateLotByRisk(entry,sl):Lots; if(vol>0) trade.Buy(vol,_Symbol,0.0,sl,tp,TradeComment); waitingRetest=false; breakoutDir=0;}
      /*else if(breakoutDir==-1 && ask>=zoneLow){
         if(OnlyOnePosition && HasOpenPosition(_Symbol)){waitingRetest=false; breakoutDir=0; return;}
         double entry=zoneLow; double sl, tp; if(UseATRSizing){int h=iATR(_Symbol,ATR_Timeframe,ATR_Period); double buf[]; if(CopyBuffer(h,0,1,1,buf)>0){sl=entry+ATR_SL_Mult*buf[0]; tp=entry-ATR_TP_Mult*buf[0];} IndicatorRelease(h);} else {sl=breakoutCandleHigh; tp=entry-1.5*(sl-entry);} entry=NormPrice(entry); sl=NormPrice(sl); tp=NormPrice(tp);double volBase = UseRiskPercent ? CalculateLotByRisk(entry,sl) : Lots;
         double vol = (breakoutDir == -1) ? volBase * ShortLotMultiplier : volBase; if(vol>0) trade.Sell(vol,_Symbol,0.0,sl,tp,TradeComment); waitingRetest=false; breakoutDir=0;}*/
   }
   ManageTrailingStops();
}
