//+------------------------------------------------------------------+
//|                                      HL Cross Signal for WPR.mq5 |
//|                                  Copyright © 2008, Bigeev Rustem |
//|                                             http://www.parch.ru/ |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2008, Bigeev Rustem"
//---- link to the website of the author
#property link      "http://www.parch.ru/"
//---- indicator version number
#property version   "2.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- eight buffers are used for calculation and drawing the indicator
#property indicator_buffers 8
//---- 8 graphical plots are used
#property indicator_plots   8
//+----------------------------------------------+ 
//|  Declaration of constants                    |
//+----------------------------------------------+ 
#define RESET 0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- line color is used as the indicator color
#property indicator_color1  Red
//---- indicator 1 line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "Sell Stop"
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- lime color is used for the indicator
#property indicator_color2  Lime
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator label
#property indicator_label2 "Buy Stop"
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3 DRAW_ARROW
//---- magenta color is used for the indicator
#property indicator_color3 Magenta
//---- indicator 3 line width is equal to 2
#property indicator_width3  2
//---- displaying the indicator label
#property indicator_label3  "Sell TakeProfit"
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4 DRAW_ARROW
//---- Aqua color is used for the indicator 
#property indicator_color4 Aqua
//---- indicator 4 line width is equal to 2
#property indicator_width4  2
//---- displaying the indicator label
#property indicator_label4 "Buy TakeProfit"
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 5 as a symbol
#property indicator_type5 DRAW_ARROW
//---- magenta color is used for the indicator
#property indicator_color5 Magenta 
//---- indicator 5 line width is equal to 1
#property indicator_width5  1
//---- displaying the indicator label
#property indicator_label5  "Sell Signal"
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- drawing the indicator 6 as a symbol
#property indicator_type6 DRAW_ARROW
//---- Aqua color is used for the indicator
#property indicator_color6 Aqua
//---- indicator 6 line width is equal to 1
#property indicator_width6  1
//---- displaying the indicator label
#property indicator_label6 "Buy Signal"
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 7 as a symbol
#property indicator_type7 DRAW_ARROW
//---- red color is used for the indicator
#property indicator_color7 Red 
//---- indicator 7 line width is equal to 3
#property indicator_width7  3
//---- displaying the indicator label
#property indicator_label7  "Sell Input"
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- drawing the indicator 8 as a symbol
#property indicator_type8 DRAW_ARROW
//---- lime color is used for the indicator
#property indicator_color8 Lime
//---- толщина линии индикатора 8 равна 3
#property indicator_width8  3
//---- displaying the indicator label
#property indicator_label8 "Buy Input"
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input int Supr_Period=6;  // Period of the break through range; the greater is the value, the later and rarer are the signals
input int MA_Period=21;   // Period for the Heiken Ashi variable. Used as an additional filter
input int Risk=0;         // Maximal risk in pips, used for calculation of the level of entering on the basis of a closest MAX/MIN level
input int ATR_Period=120; // АТR period. Used for calculation of volatility.
input double Q=0.7;       // Parameter for placing Take Profit. - A rate of Stop Loss. If = 1, then Take Profit = Stop Loss
input int WPR_Period=12;  // WPR period. Used as an additional filter
input int HLine=-38;      // Upper signal line of stop levels for WPR
input int LLine=-62;      // Lower signal lime for stop levels of WPR
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double Sell[];
double Buy[];
double SellStop[];
double BuyStop[];
double SellTake[];
double BuyTake[];
double SellInput[];
double BuyInput[];

//----
double PointRisk,PointRisk10;
//---- declaration of integer variables for the start of data calculation
int min_rates_total;
//----declaration of variables for storing the indicators handles
int WPR_Handle,ATR_Handle,MA_Handle,MA1_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_total=int(MathMax(MA_Period,MathMax(WPR_Period,MathMax(ATR_Period,Supr_Period+1))));

//---- initialization of variables  
   PointRisk=Risk*_Point;
   PointRisk10=10*PointRisk;

//---- getting handle of the MA indicator
   MA_Handle=iMA(NULL,0,MA_Period,0,MODE_SMA,PRICE_MEDIAN);
   if(MA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the MA indicator");

//---- getting handle of the MA1 indicator
   MA1_Handle=iMA(NULL,0,1,0,MODE_SMA,PRICE_MEDIAN);
   if(MA1_Handle==INVALID_HANDLE) Print(" Failed to get handle of the MA1 indicator");

//---- getting handle of the WPR indicator
   WPR_Handle=iWPR(NULL,0,WPR_Period);
   if(WPR_Handle==INVALID_HANDLE) Print(" Failed to get handle of the WPR indicator");

//---- Get indicator's handle
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE) Print(" Failed to get handle of the ATR indicator");

//---- converting the SellStop[] dynamic array to an indicator buffer
   SetIndexBuffer(0,SellStop,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,119);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellStop,true);

//---- converting the BuyStop[] dynamic array to an indicator buffer
   SetIndexBuffer(1,BuyStop,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,119);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyStop,true);

//---- converting the SellTake[] dynamic array to an indicator buffer
   SetIndexBuffer(2,SellTake,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,158);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellTake,true);

//---- converting the BuyTake[] dynamic array to an indicator buffer
   SetIndexBuffer(3,BuyTake,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,158);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyTake,true);

//---- converting the Sell[] dynamic array to an indicator buffer
   SetIndexBuffer(4,Sell,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 5
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(4,PLOT_ARROW,234);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Sell,true);

//---- converting the Buy[] dynamic array to an indicator buffer
   SetIndexBuffer(5,Buy,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 6
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(5,PLOT_ARROW,233);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(Buy,true);

//---- converting the SellInput[] dynamic array to an indicator buffer
   SetIndexBuffer(6,SellInput,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 7
   PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(6,PLOT_ARROW,177);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellInput,true);

//---- converting the BuyInput[] dynamic array to an indicator buffer
   SetIndexBuffer(7,BuyInput,INDICATOR_DATA);
//---- shifting the start of drawing the indicator 8
   PlotIndexSetInteger(7,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(7,PLOT_ARROW,177);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyInput,true);

//---- initializations of variable for a short name of the indicator
//---- creating name for displaying in a separate sub-window and in tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"HL Cross Signal for WPR");
//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of price maximums for the indicator calculation
                const double& low[],      // price array of price minimums for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(MA_Handle)<rates_total
      || BarsCalculated(MA1_Handle)<rates_total
      || BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(WPR_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declaration of local variables 
   int limit,bar,Flag;
   double WPR[1],ATR[1],MA[1],MA1[1];
   double Lhigh,Llow,Spread;
   static int Flag_;

//---- indexation of elements in arrays as in timeseries
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(spread,true);

//---- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1;  // tarting index for calculation of all bars
      Flag_=0;
     }
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

//---- restore values of the variables
   Flag=Flag_;

//---- main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- memorize values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
         Flag_=Flag;

      Sell[bar]=0.0;
      SellTake[bar]=0.0;
      SellStop[bar]=0.0;
      SellInput[bar]=0.0;

      Buy[bar]=0.0;
      BuyTake[bar]=0.0;
      BuyStop[bar]=0.0;
      BuyInput[bar]=0.0;

      Spread=spread[bar]*_Point;

      //--- copy newly appeared data in the arrays
      if(CopyBuffer(MA_Handle,0,bar,1,MA)<=0) return(RESET);
      if(CopyBuffer(MA1_Handle,0,bar,1,MA1)<=0) return(RESET);
      if(CopyBuffer(WPR_Handle,0,bar,1,WPR)<=0) return(RESET);
      if(CopyBuffer(ATR_Handle,0,bar,1,ATR)<=0) return(RESET);
      Lhigh=high[ArrayMaximum(high,bar+1,Supr_Period)];
      Llow=low[ArrayMinimum(low,bar+1,Supr_Period)];

      //---- buy signal condition
      if(Flag<=0)
         if((high[bar]>=Lhigh && close[bar]>MA1[0] && close[bar]>MA[0] && high[bar]>MA[0] && WPR[0]>=HLine)
            || (close[bar]>=SellStop[bar+1] && high[bar]>Lhigh))
           {
            Buy[bar]=MathMin(close[bar],(Llow+2*ATR[0]));
            if(Risk!=0 && Buy[bar]-Llow>PointRisk) Buy[bar]=Llow+PointRisk10;
            if(close[bar]<Llow+PointRisk10) Buy[bar]=close[bar];
            Flag=+1;
           }

      //---- sell signal condition
      if(Flag>=0)
         if((low[bar]<=Llow && close[bar]<MA1[0] && close[bar]<MA[0] && low[bar]<MA[0] && WPR[0]<=LLine)
            || (close[bar]<=BuyStop[bar+1] && low[bar]<Llow))
           {
            Sell[bar]=MathMax(close[bar],(Lhigh-2*ATR[0]));
            if(Risk!=0 && Lhigh-Sell[bar]>PointRisk) Sell[bar]=Lhigh-PointRisk10;
            if(close[bar]>Lhigh-PointRisk10) Sell[bar]=close[bar];
            Flag=-1;
           }

      if(Flag>0)
        {
         BuyStop[bar]=Llow-Spread*2;
         BuyTake[bar]=Lhigh+Spread*3;

         if(BuyStop[bar]<BuyStop[bar+1]&&!SellStop[bar+1]) BuyStop[bar]=BuyStop[bar+1];
         if(BuyTake[bar]<BuyTake[bar+1]&&!SellTake[bar+1]) BuyTake[bar]=BuyTake[bar+1];
        }

      if(Flag<0)
        {
         SellStop[bar]=Lhigh+Spread*3;
         SellTake[bar]=Llow-Spread*2;

         if(SellStop[bar]>SellStop[bar+1]&&!BuyStop[bar+1]) SellStop[bar]=SellStop[bar+1];
         if(SellTake[bar]>SellTake[bar+1]&&!BuyTake[bar+1]) SellTake[bar]=SellTake[bar+1];
        }

      if(Buy[bar]) BuyInput[bar]=Buy[bar]+(Buy[bar]-BuyStop[bar])*Q;
      if(Sell[bar]) SellInput[bar]=Sell[bar]-(SellStop[bar]-Sell[bar])*Q+Spread;

     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
