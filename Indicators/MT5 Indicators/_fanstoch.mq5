//+------------------------------------------------------------------+
//|                                                          !FanRSI |
//|               Copyright © 2006-2013, FINEXWARE Technologies GmbH |
//|                                                www.FINEXWARE.com |
//|                       programming & development - Alexey Sergeev |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006-2013, FINEXWARE Technologies GmbH"
#property link      "www.FINEXWARE.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers	100
#property indicator_plots 	100

enum enProgression { Arithmetical, Fibonacci, Leonardo, Geometrical}; // Types of calculation of the next period of the indicator
enum enLineGet { MainLine, SignalLine}; // The stochastic line that will be displayed

input color Color=clrLightSeaGreen; // Fan color
input enProgression Progress=Arithmetical; // Type of period calculation
input int nLine=10; // The number of lines of the fan
input int KPeriodStart=5; // Stating K period
input int DPeriodStart=3; // Starting D period
input int Slow=3;
input double Koef=2; // Progression coefficient
input enLineGet Line=MainLine; // Stochastic line

input ENUM_MA_METHOD Method=MODE_EMA; // Calculation price
input ENUM_STO_PRICE Price=STO_LOWHIGH; // Calculation price



//------------------------------------------------------------------	CRSI
class CStoch
{
	// Basic parameters
public:
	int m_h; // Basic handle
	double m_d[]; // Buffer
	int m_i; // Buffer index in the fan
	
	// Parameters o the handle
	string m_smb; // Symbol
	ENUM_TIMEFRAMES m_tf; // Period
	int m_Kperiod; // Period
	int m_Dperiod; // Period
	int m_slow; // 
	ENUM_MA_METHOD m_method; // Method
	ENUM_STO_PRICE m_price; // Calculation price
	
	// Basic functions
public:
	CStoch() { m_h=0; ArraySetAsSeries(m_d, true); }
	~CStoch() { if (m_h>0) IndicatorRelease(m_h); m_h=0; }
	void InitBuf(int i); // Initialize the indicator buffer
	//
public:
	bool Init(string smb, ENUM_TIMEFRAMES tf, int Kperiod, int Dperiod, int slow, ENUM_MA_METHOD method, ENUM_STO_PRICE price);
	bool GetData(int lim);
};
//------------------------------------------------------------------	InitBuf
void CStoch::InitBuf(int i) // Initialize the indicator buffer
{
	m_i=i; SetIndexBuffer(m_i, m_d, INDICATOR_DATA); PlotIndexSetInteger(m_i, PLOT_DRAW_TYPE, DRAW_LINE);
	PlotIndexSetInteger(m_i, PLOT_LINE_COLOR, Color); PlotIndexSetInteger(m_i, PLOT_LINE_STYLE, STYLE_SOLID); PlotIndexSetInteger(m_i, PLOT_LINE_WIDTH, 1);
}
//------------------------------------------------------------------	InitMA
bool CStoch::Init(string smb, ENUM_TIMEFRAMES tf, int Kperiod, int Dperiod, int slow, ENUM_MA_METHOD method, ENUM_STO_PRICE price)
{
	m_smb=smb; m_tf=tf; m_Kperiod=Kperiod; m_Dperiod=Dperiod; m_slow=slow; m_method=method; m_price=price;
	PlotIndexSetString(m_i, PLOT_LABEL, "Stoch("+string(m_Kperiod)+")");
	if (m_h>0) { IndicatorRelease(m_h); m_h=0; }
	m_h=iStochastic(m_smb, m_tf, m_Kperiod, m_Dperiod, m_slow, m_method, m_price);
	return(m_h>0); // βρε Ξκ
}
//------------------------------------------------------------------	GetMA
bool CStoch::GetData(int lim)
{
	int n=CopyBuffer(m_h, Line, 0, lim, d);
	if (n<lim) return(false);
	for (int i=0; i<lim; i++) m_d[i]=d[i];
	return(true);
}




CStoch fan[]; // An array of indicators
double d[]; // A temporary array for the indicator values

//------------------------------------------------------------------	OnInit
int OnInit()
{
	ArrayResize(fan, nLine); ArraySetAsSeries(d, true);
	for (int i=0; i<nLine; i++)
	{
		fan[i].InitBuf(i); // A buffer for the indicator has been initialized
		int p=NextPeriod(i);
		if (Line==MainLine) if (!fan[i].Init(Symbol(), Period(), KPeriodStart+p, DPeriodStart, Slow, Method, Price)) { Print("Initialization error of Stoch("+string(fan[i].m_Kperiod)+")"); break; } // An indicator has been created
		if (Line==SignalLine) if (!fan[i].Init(Symbol(), Period(), KPeriodStart, DPeriodStart+p, Slow, Method, Price)) { Print("Initialization error of Stoch("+string(fan[i].m_Kperiod)+")"); break; } // An indicator has been created
	}
	IndicatorSetString(INDICATOR_SHORTNAME, "Stoch_Fan("+string(nLine)+") "+EnumToString(Line)+"/"+EnumToString(Method)+"/"+EnumToString(Price));
	IndicatorSetInteger(INDICATOR_DIGITS, 2); IndicatorSetInteger(INDICATOR_LEVELS,2);
	IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 20); IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, 80);
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
