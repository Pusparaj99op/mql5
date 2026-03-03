//+------------------------------------------------------------------+
//|                                EG-Money-Management-Indicator.mq4 |
//|                                         Copyright 2021. ErangaG  |
//|                         @author ErangaG. http://www.simply.trade |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Copyright 2021, ErangaG"
#property link      "http://www.simply.trade"
#property version   "21.11"
#property strict


enum EMyCapitalCalculation {
   FREEMARGIN = 2,
   BALANCE = 4,
   EQUITY = 8,
};

enum EMyRiskCalculation {
   ATR_POINTS = 3,
   FIXED_POINTS = 9,
};

class CMyToolkit {

 protected:

   virtual void  _Name() = NULL;   // A pure virtual function to make this class abstract

 public:

   static double NormalizeLots(string pSymbol, double pLots) {
      double uvolumeStep = SymbolInfoDouble(pSymbol, SYMBOL_VOLUME_STEP);
      double ulots = MathRound(pLots / uvolumeStep) * uvolumeStep; //-- normallize to a multiple of lotstep accepted by the broker
      return ulots;
   }

   static double ToPointDecimal(string pSymbol, uint pPointsCount) {
      int udigits = (int)SymbolInfoInteger(pSymbol, SYMBOL_DIGITS);
      double upointDecimal = SymbolInfoDouble(pSymbol, SYMBOL_POINT);
      return NormalizeDouble(upointDecimal * pPointsCount, udigits);
   }

   static int ToPointsCount(string pSymbol, double pDecimalValue) {
      double upointDecimal = SymbolInfoDouble(pSymbol, SYMBOL_POINT);
      return (int)((1 / upointDecimal) * pDecimalValue);
   }

   static int ToTicksCount(string pSymbol, uint pPointsCount) {
      // https://forum.mql4.com/43064#515262 for non-currency DE30:
      // SymbolInfoDouble(chart.symbol, SYMBOL_TRADE_TICK_SIZE) returns 0.5
      // SymbolInfoInteger(chart.symbol,SYMBOL_DIGITS) returns 1
      // SymbolInfoInteger(chart.symbol,SYMBOL_POINT) returns 0.1
      // Prices to open must be a multiple of ticksize
      double uticksize = SymbolInfoDouble(pSymbol, SYMBOL_TRADE_TICK_SIZE);
      int utickscount = (int)((pPointsCount / uticksize) * uticksize); //-- fix prices by ticksize
      return utickscount;
   }

   static double _CurrencyMultiplicator(string pCurrencyPairAppendix = "") {
      double _multiplicator = 1.0;
      string xCurrency = AccountInfoString(ACCOUNT_CURRENCY);
      StringToUpper(xCurrency);

      if(xCurrency == "USD")
         return (_multiplicator);
      if(xCurrency == "EUR")
         _multiplicator = 1.0 / SymbolInfoDouble("EURUSD" + pCurrencyPairAppendix, SYMBOL_BID);
      if(xCurrency == "GBP")
         _multiplicator = 1.0 / SymbolInfoDouble("GBPUSD" + pCurrencyPairAppendix, SYMBOL_BID);
      if(xCurrency == "AUD")
         _multiplicator = 1.0 / SymbolInfoDouble("AUDUSD" + pCurrencyPairAppendix, SYMBOL_BID);
      if(xCurrency == "NZD")
         _multiplicator = 1.0 / SymbolInfoDouble("NZDUSD" + pCurrencyPairAppendix, SYMBOL_BID);
      if(xCurrency == "CHF")
         _multiplicator = SymbolInfoDouble("USDCHF" + pCurrencyPairAppendix, SYMBOL_BID);
      if(xCurrency == "JPY")
         _multiplicator = SymbolInfoDouble("USDJPY" + pCurrencyPairAppendix, SYMBOL_BID);
      if(xCurrency == "CAD")
         _multiplicator = SymbolInfoDouble("USDCAD" + pCurrencyPairAppendix, SYMBOL_BID);
      if(_multiplicator == 0)
         _multiplicator = 1.0; // If account currency is neither of EUR, GBP, AUD, NZD, CHF, JPY or CAD we assumes that it is USD
      return (_multiplicator);
   }


   static double CalculateLotSize(string pSymbol, double pMoneyCapital, double pRiskDecimal, int pStoplossPoints, int pExtraPriceGapPoints, double pAllowedMaxLotSize, string pCurrencyPairAppendix = "") {
      // Calculate LotSize based on Equity, Risk in decimal and StopLoss in points
      double _moneyRisk, _lotsByRequiredMargin, _lotsByRisk, _lotSize;
      int _lotdigit = 2, _totalSLPoints, _totalTickCount;

      // Calculate Lot size according to Equity.
      double _marginForOneLot;
      if(OrderCalcMargin(ORDER_TYPE_BUY, pSymbol, 1, SymbolInfoDouble(pSymbol, SYMBOL_ASK), _marginForOneLot)) { // Calculate margin required for 1 lot
         _lotsByRequiredMargin = pMoneyCapital * 0.98 / _marginForOneLot;
         _lotsByRequiredMargin = MathMin(_lotsByRequiredMargin, MathMin(pAllowedMaxLotSize, SymbolInfoDouble(pSymbol, SYMBOL_VOLUME_MAX)));
         _lotsByRequiredMargin = NormalizeLots(pSymbol, _lotsByRequiredMargin);
      } else {
         _lotsByRequiredMargin = SymbolInfoDouble(pSymbol, SYMBOL_VOLUME_MAX);
      }

      double _lotStep = SymbolInfoDouble(pSymbol, SYMBOL_VOLUME_STEP); // Step in lot size changing
      double _oneTickValue = SymbolInfoDouble(pSymbol, SYMBOL_TRADE_TICK_VALUE); // Tick value of the asset

      if(_lotStep ==  1) _lotdigit = 0;
      if(_lotStep == 0.1) _lotdigit = 1;
      if(_lotStep == 0.01) _lotdigit = 2;

      _moneyRisk = pRiskDecimal * pMoneyCapital;
      _totalSLPoints = pStoplossPoints + pExtraPriceGapPoints;
      _totalTickCount = ToTicksCount(pSymbol, _totalSLPoints);

      // Calculate the Lot size according to Risk.
      _lotsByRisk = _moneyRisk / (_totalTickCount * _oneTickValue);
      _lotsByRisk = _lotsByRisk * _CurrencyMultiplicator(pCurrencyPairAppendix);
      _lotsByRisk = NormalizeLots(pSymbol, _lotsByRisk);

      _lotSize = MathMax(MathMin(_lotsByRisk, _lotsByRequiredMargin), SymbolInfoDouble(pSymbol, SYMBOL_VOLUME_MIN));
      _lotSize = NormalizeDouble(_lotSize, _lotdigit);
      return (_lotSize);
   }

   static void DisplayText(string objname, string objtext, int clr, int x, int y, int corner) {
      if(ObjectFind(ChartID(), objname) == -1) {
         ObjectCreate(ChartID(), objname, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(ChartID(), objname, OBJPROP_CORNER, corner);
         ObjectSetInteger(ChartID(), objname, OBJPROP_XDISTANCE, x);
         ObjectSetInteger(ChartID(), objname, OBJPROP_YDISTANCE, y);
         ObjectSetInteger(ChartID(), objname, OBJPROP_FONTSIZE, 13);
         ObjectSetString(ChartID(), objname, OBJPROP_FONT, "Arial");
      }
      ObjectSetString(ChartID(), objname, OBJPROP_TEXT, objtext);
      ObjectSetInteger(ChartID(), objname, OBJPROP_COLOR, clr);
   }

};


#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   3
#property indicator_type1   DRAW_NONE
#property indicator_color1  clrNONE
#property indicator_type2   DRAW_NONE
#property indicator_color2  clrNONE
#property indicator_type3   DRAW_NONE
#property indicator_color3  clrNONE

input group                   "Risk Mode"
input EMyCapitalCalculation   iRisk_AvailableCapital = BALANCE;  // Capital calculation mechanism
input double                  iRisk_FractionOfCapital = 0.01;    // Risk fraction of the capital ,ex: 0.01 = 1%
input EMyRiskCalculation      iRisk_RiskMode = ATR_POINTS;       // Stop-Loss points calculation mechanism

input group       "Stop-Loss Calculation"
input int         iCommon_ATRLength = 14;                         // ATR length for ATR based Stop-Loss
input double      iCommon_ATRMultiplier = 1.5;                    // ATR value multiplier
input int         iCommon_FixedStoplossPoints = 1000;             // Fixed size Stop-Loss point count

input group       "General Settings"
input string      iCommon_CurrencyPairAppendix = "";              // Currency Pair Appendix
input color       iCommon_ColorParameters = clrOrange;            // Colour for Parameters
input color       iCommon_ColorLotsize = clrDeepSkyBlue;          // Colour for calculaed Lots

ENUM_BASE_CORNER  mDisplay_Corner = CORNER_LEFT_LOWER;
int mMaxPeriod;
int mHandleATR;

double   mBuffer_lotsize[];
double   mBuffer_stoplossPoints[];
double   mBuffer_atrPoints[];
double   mBuffer_atr[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool myIndicatorCreate() {
   mHandleATR = iATR(NULL, PERIOD_CURRENT, iCommon_ATRLength);
   if (mHandleATR == INVALID_HANDLE) return (false);
   return (true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void myIndicatorRelease() {
   if (mHandleATR != INVALID_HANDLE) IndicatorRelease(mHandleATR);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   SetIndexBuffer(0, mBuffer_lotsize, INDICATOR_DATA);
   SetIndexBuffer(1, mBuffer_stoplossPoints, INDICATOR_DATA);
   SetIndexBuffer(2, mBuffer_atrPoints, INDICATOR_DATA);

   SetIndexBuffer(3, mBuffer_atr, INDICATOR_CALCULATIONS);

   PlotIndexSetString(0, PLOT_LABEL, "EG_Lots");
   PlotIndexSetString(1, PLOT_LABEL, "EG_Stoploss_Points");
   PlotIndexSetString(2, PLOT_LABEL, "EG_ATR_Points");

   mMaxPeriod = iCommon_ATRLength;
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, mMaxPeriod);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, mMaxPeriod);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, mMaxPeriod);

   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   IndicatorSetString(INDICATOR_SHORTNAME, MQLInfoString(MQL_PROGRAM_NAME));

   string str;
   if(myIndicatorCreate() == false) {
      StringConcatenate(str, "Failed to create indicator handle(s) , Error: ", GetLastError());
      MessageBox(str, "Error");
      return (INIT_FAILED);
   }
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int  reason) {
   ObjectDelete(ChartID(), "@MM-ATR");
   ObjectDelete(ChartID(), "@MM-LotText");
   ObjectDelete(ChartID(), "@MM-LotSize");
   myIndicatorRelease();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   if (IsStopped()) return(0);
   if (rates_total < mMaxPeriod) return(0);

   if (BarsCalculated(mHandleATR) < rates_total) return(0);

   int startBar = 0, copyLength = 0;
   if (prev_calculated > rates_total || prev_calculated <= 0) {
      copyLength = rates_total;
      startBar = mMaxPeriod;
   } else {
      copyLength = rates_total - prev_calculated;
      if (prev_calculated > 0) copyLength++;
      startBar = prev_calculated - 1;
   }

   if (CopyBuffer(mHandleATR, 0, 0, copyLength, mBuffer_atr) <= 0) return(0);

   double availableMoney, lotsize;
   int atrPoints, slPoints, extraPoints;
   string str;

   // Get available money
   switch (iRisk_AvailableCapital) {
   case FREEMARGIN:
      availableMoney = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      break;
   case BALANCE:
      availableMoney = AccountInfoDouble(ACCOUNT_BALANCE);
      break;
   case EQUITY:
      availableMoney = AccountInfoDouble(ACCOUNT_EQUITY);
      break;
   default:
      availableMoney = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      break;
   }

   for(int i = startBar; i < rates_total && !IsStopped(); i++) {

      atrPoints = (int)(mBuffer_atr[i] * MathPow(10, SymbolInfoInteger(NULL, SYMBOL_DIGITS)));
      slPoints = (int)MathCeil(iCommon_ATRMultiplier * atrPoints);

      // calculate raw lotsize
      if(iRisk_RiskMode == FIXED_POINTS) {
         slPoints = iCommon_FixedStoplossPoints;
      } else {
         slPoints = slPoints > 0 ? slPoints : iCommon_FixedStoplossPoints;
      }

      extraPoints = (int)SymbolInfoInteger(NULL, SYMBOL_SPREAD);
      lotsize = CMyToolkit::CalculateLotSize(NULL, availableMoney, iRisk_FractionOfCapital, slPoints, 0, SymbolInfoDouble(NULL, SYMBOL_VOLUME_MAX), iCommon_CurrencyPairAppendix);

      mBuffer_atrPoints[i] = StringToDouble(DoubleToString(atrPoints, 0));
      mBuffer_stoplossPoints[i] = StringToDouble(DoubleToString(slPoints, 0));
      mBuffer_lotsize[i] = StringToDouble(DoubleToString(lotsize, 2));;
   }

   if(iRisk_RiskMode == ATR_POINTS) {
      str = "";
      StringConcatenate(str, "ATR (", iCommon_ATRLength, ") : ", mBuffer_atrPoints[rates_total - 1], " points");
      CMyToolkit::DisplayText("@MM-ATR", str, iCommon_ColorParameters, 30, 110, mDisplay_Corner);
   }

   str = "";
   StringConcatenate(str, "Risk : ", DoubleToString((iRisk_FractionOfCapital * 100), 2), "% , Stop-Loss : ", mBuffer_stoplossPoints[rates_total - 1], " points");
   CMyToolkit::DisplayText("@MM-LotText", str, iCommon_ColorParameters, 30, 80, mDisplay_Corner);
   str = "";
   StringConcatenate(str, "Lots : ", mBuffer_lotsize[rates_total - 1]);
   CMyToolkit::DisplayText("@MM-LotSize", str, iCommon_ColorLotsize, 30, 50, mDisplay_Corner);

   return(rates_total);
}

//+------------------------------------------------------------------+
