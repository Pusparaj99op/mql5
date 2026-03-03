//+------------------------------------------------------------------+
//|                                                          !FanRSI |
//|               Copyright © 2006-2013, FINEXWARE Technologies GmbH |
//|                                                www.FINEXWARE.com |
//|                       programming & development - Alexey Sergeev |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006-2012, FINEXWARE Technologies GmbH"
#property link      "www.FINEXWARE.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers	100
#property indicator_plots 	100

enum enProgression { Arithmetical, Fibonacci, Leonardo, Geometrical}; // Types of calculation of the next period of the indicator

input color Color=clrDodgerBlue; // Fan color
input enProgression Progress=Arithmetical; // Type of period calculation
input int nLine=10; // The number of lines of the fan
input int PeriodStart=2; // Start period
input double Koef=2; // Coefficient of progression

input ENUM_APPLIED_PRICE Price=PRICE_CLOSE; // Calculation price



//------------------------------------------------------------------	CRSI
class CRSI
{
	// Basic parameters
public:
	int m_h; // Basic handle
	double m_d[]; // Buffer
	int m_i; // Buffer number in the fan
	
	// Parameters for the handle
	string m_smb; // Symbol
	ENUM_TIMEFRAMES m_tf; // Period
	int m_period; // Period
	ENUM_APPLIED_PRICE m_price; // Calculation price
	
	// Basic functions
public:
	CRSI() { m_h=0; ArraySetAsSeries(m_d, true); }
	~CRSI() { if (m_h>0) IndicatorRelease(m_h); m_h=0; }
	void InitBuf(int i); // Initialize the indicator buffer
	//
public:
	bool Init(string smb, ENUM_TIMEFRAMES tf, int period, ENUM_APPLIED_PRICE price);
	bool GetData(int lim);
};
//------------------------------------------------------------------	InitBuf
void CRSI::InitBuf(int i) // Initialize the indicator buffer
{
	m_i=i; SetIndexBuffer(m_i, m_d, INDICATOR_DATA); PlotIndexSetInteger(m_i, PLOT_DRAW_TYPE, DRAW_LINE);
	PlotIndexSetInteger(m_i, PLOT_LINE_COLOR, Color); PlotIndexSetInteger(m_i, PLOT_LINE_STYLE, STYLE_SOLID); PlotIndexSetInteger(m_i, PLOT_LINE_WIDTH, 1);
}
//------------------------------------------------------------------	InitMA
bool CRSI::Init(string smb, ENUM_TIMEFRAMES tf, int period, ENUM_APPLIED_PRICE price)
{
	m_smb=smb; m_tf=tf; m_period=period; m_price=price;
	PlotIndexSetString(m_i, PLOT_LABEL, "RSI("+string(m_period)+")");
	if (m_h>0) { IndicatorRelease(m_h); m_h=0; }
	m_h=iRSI(m_smb, m_tf, m_period, m_price);
	return(m_h>0); // βρε Ξκ
}
//------------------------------------------------------------------	GetMA
bool CRSI::GetData(int lim)
{
	int n=CopyBuffer(m_h, 0, 0, lim, d);
	if (n<lim) return(false);
	for (int i=0; i<lim; i++) m_d[i]=d[i];
	return(true);
}




CRSI fan[]; // An array of indicators
double d[]; // A temporary array for the indicator values

//------------------------------------------------------------------	OnInit
int OnInit()
{
	ArrayResize(fan, nLine); ArraySetAsSeries(d, true);
	for (int i=0; i<nLine; i++)
	{
		fan[i].InitBuf(i); // A buffer for the indicator has been initialized
		if (!fan[i].Init(Symbol(), Period(), PeriodStart+NextPeriod(i), Price)) { Print("Error of initialization of RSI("+string(fan[i].m_period)+")"); break; } // An indicator has been created
	}
	IndicatorSetString(INDICATOR_SHORTNAME, "RSI_Fan("+string(nLine)+") "+EnumToString(Price));
	IndicatorSetInteger(INDICATOR_DIGITS, 2); IndicatorSetInteger(INDICATOR_LEVELS,2);
	IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 30); IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, 70);
	IndicatorSetDouble(INDICATOR_MAXIMUM, 100); IndicatorSetDouble(INDICATOR_MINIMUM, 0);
	
	return(INIT_SUCCEEDED);
}
//------------------------------------------------------------------	OnCalculate
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[])
{
	int lim=rates_total-prev_calculated; if (lim>1) lim=rates_total; else lim++; // We have defined the number of bars to copy
	bool bOk=true; for (int i=0; i<nLine; i++) if (!fan[i].GetData(lim)) bOk=false; // Update all indicator buffers
	if (bOk) return(rates_total); else return(prev_calculated);
}
//------------------------------------------------------------------	NextPeriod
int NextPeriod(int s)
{
	double p=0;
	switch(Progress)
	{
	case Arithmetical: p=Koef*s; break;
	case Fibonacci: { double p0=0, p1=1; for (int i=2; i<s; i++) { p=p0+p1; p0=p1; p1=p; } } break;
	case Leonardo: { double p0=1, p1=1; for (int i=2; i<s; i++) { p=p0+p1+1; p0=p1; p1=p; } } break;
	case Geometrical: p=MathPow(Koef, s); break;
	}
	return(int(p));
}
