#property description ""
#property description ""
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3
//--- plot Short
#property indicator_label1  "Short"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Media
#property indicator_label2  "Media"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWhite
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot Longa
#property indicator_label3  "Longa"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- input parameters
input int      Short=3;
input int      Media=8;
input int      Longa=20;
//--- indicator buffers
double         ShortBuffer[];
double         MediaBuffer[];
double         LongaBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   IndicatorSetInteger(INDICATOR_DIGITS,4);
//--- indicator buffers mapping
   SetIndexBuffer(0,ShortBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MediaBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LongaBuffer,INDICATOR_DATA);
   
   string short_name;
   StringConcatenate(short_name,"d_index(",IntegerToString(Short),",",IntegerToString(Media),",",
                     IntegerToString(Longa)+")");

   IndicatorSetString(INDICATOR_SHORTNAME,short_name);   
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) 
{
if(rates_total<Longa-1+begin) 

	if(prev_calculated == 0) {
		ArrayInitialize(ShortBuffer, 0);
		ArrayInitialize(MediaBuffer, 0);
		ArrayInitialize(LongaBuffer, 0);
	}
	
	CalculateDidiIndex();
	
	return(rates_total);
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {
//---

}
//+------------------------------------------------------------------+
void CalculateDidiIndex() {
	int short_handle, average_handle, long_handle;
	int short_bars, average_bars, long_bars;

	short_handle   = iMA(Symbol(), PERIOD_CURRENT, Short, 0, MODE_SMA, PRICE_CLOSE);
	average_handle = iMA(Symbol(), PERIOD_CURRENT, Media, 0, MODE_SMA, PRICE_CLOSE);
	long_handle    = iMA(Symbol(), PERIOD_CURRENT, Longa, 0, MODE_SMA, PRICE_CLOSE);

	short_bars =   BarsCalculated(short_handle);
	average_bars = BarsCalculated(average_handle);
	long_bars =    BarsCalculated(long_handle);

	CopyBuffer(short_handle,   0, 0, short_bars,   ShortBuffer);
	CopyBuffer(average_handle, 0, 0, average_bars, MediaBuffer);
	CopyBuffer(long_handle,    0, 0, long_bars,    LongaBuffer);
	
	for(int i=0;i<short_bars;i++) {
		if(i>=Media) {
			ShortBuffer[i] /= MediaBuffer[i];
			if(i>=Longa) {
				LongaBuffer[i] /= MediaBuffer[i];
			}
			else {
				LongaBuffer[i] = 1;
			}
		}
		else {
			ShortBuffer[i] = 1;
		}
		MediaBuffer[i] = 1;
	}
}
