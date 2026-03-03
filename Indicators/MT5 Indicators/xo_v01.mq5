//+------------------------------------------------------------------+
//|                                                  	 			   XO |
//|               Copyright © 2006-2012, FINEXWARE Technologies GmbH |
//|                                                www.FINEXWARE.com |
//|      programming & development - Alexey Sergeev, Boris Gershanov |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006-2012, FINEXWARE Technologies GmbH"
#property link "www.FINEXWARE.com"
#property version "1.0"

#property indicator_separate_window

#property indicator_buffers 5
#property indicator_plots 1

#property indicator_color1 clrRed, clrLimeGreen

input int StepBox=50; // Price step
input double Treshold=2; // Threshold for the change of direction
input int MaxBar=1000; // Number of verifiable bars

double Up[], Hi[], Lo[], Dn[], Clr[];
double Box=StepBox*_Point;
//------------------------------------------------------------------	OnInit
int OnInit() 
{
	if (StepBox<=0 || Treshold<=0) { Alert("Error: StepBox<=0 || Treshold<=0"); return(-1); }
	int i=-1;
	i++; SetIndexBuffer(i, Up, INDICATOR_DATA);
	i++; SetIndexBuffer(i, Hi, INDICATOR_DATA);
	i++; SetIndexBuffer(i, Lo, INDICATOR_DATA);
	i++; SetIndexBuffer(i, Dn, INDICATOR_DATA);
	i++; SetIndexBuffer(i, Clr, INDICATOR_COLOR_INDEX);

	PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_COLOR_CANDLES);
	ArraySetAsSeries(Hi, true); ArraySetAsSeries(Lo, true); ArraySetAsSeries(Up, true); ArraySetAsSeries(Dn, true); ArraySetAsSeries(Clr, true);
	return(0);
} 
//------------------------------------------------------------------	OnCalculate
int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime& time[], const double& open[], const double& high[], const double& low[], const double& close[],
                const long& tick_volume[], const long& volume[], const int& spread[])
{
	ArrayInitialize(Hi, EMPTY_VALUE); ArrayInitialize(Lo, EMPTY_VALUE);
	ArrayInitialize(Up, EMPTY_VALUE); ArrayInitialize(Dn, EMPTY_VALUE);
	ArraySetAsSeries(high, true); ArraySetAsSeries(low, true); ArraySetAsSeries(time, true);

	int limit; if (MaxBar<=0) limit=rates_total-1; else limit=MaxBar;

	// 1 - calculation of the number of bars nBar XO
	int nBar=0, dir=0; double Lvl=0;
	for(int i=limit; i>=0; i--)
	{
		// If the bar higher than the prior step or if we change the direction and the bar above the Threshold*Step
		if ((high[i]>=Lvl+Box && dir==1) || (high[i]>=Lvl+Treshold*Box && dir==0))
		{
			Lvl+=Box*MathFloor((high[i]-Lvl)/Box); if (dir==0) nBar++; dir=1;
		}
		// If the bar below than the prior step or if we change the direction and the bar below the Threshold*Step
		else if ((low[i]<=Lvl-Box && dir==0) || (low[i]<=Lvl-Treshold*Box && dir==1))
		{
			Lvl-=Box*MathFloor((Lvl-low[i])/Box); if (dir==1) nBar++; dir=0;
		}
	}
	
	// 2 - drawing of bars XO / performs the same checks as for the calculation of the number of bars
	Lvl=0; dir=0; int b=nBar;
	for(int i=limit; i>=0; i--)
	{
		if ((high[i]>=Lvl+Box && dir==1) || (high[i]>=Lvl+Treshold*Box && dir==0)) 
		{
			if (dir==0) { b--; Dn[b]=Lvl+Box; }
			Lvl+=Box*MathFloor((high[i]-Lvl)/Box); Up[b]=Lvl; dir=1; Clr[b]=1;
		}
		else if ((low[i]<=Lvl-Box && dir==0) || (low[i]<=Lvl-Treshold*Box && dir==1)) 
		{
			if (dir==1) { b--; Dn[b]=Lvl-Box; }
			Lvl-=Box*MathFloor((Lvl-low[i])/Box); Up[b]=Lvl; dir=0; Clr[b]=0;
		}
		// check the extremes of shadows
		if (Hi[b]==EMPTY_VALUE || Hi[b]<Up[b]) Hi[b]=Up[b];
		if (Hi[b]==EMPTY_VALUE || Hi[b]<high[i]) Hi[b]=high[i];
		if (Lo[b]==EMPTY_VALUE || Lo[b]>Dn[b]) Lo[b]=Dn[b];
		if (Lo[b]==EMPTY_VALUE || Lo[b]>low[i]) Lo[b]=low[i];
	}
	
	// remove the initial bar
	Hi[nBar-1]=EMPTY_VALUE; Lo[nBar-1]=EMPTY_VALUE; Up[nBar-1]=EMPTY_VALUE; Dn[nBar-1]=EMPTY_VALUE;
	return(rates_total); 
}
