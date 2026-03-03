//+------------------------------------------------------------------+
//|                                                 FiboCandles_.mq5 |
//|                                  Copyright © 2010, Ivan Kornilov |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, Ivan Kornilov"
#property link "excelf@gmail.com"
#property description "Fibo Candles 2"
//---- indicator version
#property version   "1.00"
//+------------------------------------------------+
//|  Indicator drawing parameters                  |
//+------------------------------------------------+
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- five buffers are used for calculation and drawing the indicator
#property indicator_buffers 5
//---- only one plot is used
#property indicator_plots   1
//---- color candlesticks are used as an indicator
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  Teal, Magenta
//---- displaying the indicator label
#property indicator_label1  "FiboCandles Open; FiboCandles High; FiboCandles Low; FiboCandles Close"
//+------------------------------------------------+
//|  Declaration of constants                      |
//+------------------------------------------------+
#define RESET  0 // the constant for getting the command for the indicator recalculation back to the terminal
//---- Fibo levels constants
#define LEVEL_1 0.236
#define LEVEL_2 0.382
#define LEVEL_3 0.500
#define LEVEL_4 0.618
#define LEVEL_5 0.762
//+------------------------------------------------+
//|  Enumeration for Fibo levels                   |
//+------------------------------------------------+
enum ENUM_FIBORATIO //Type of constant
  {
   LEVEL_1_ = 1,   //0.236
   LEVEL_2_,       //0.382
   LEVEL_3_,       //0.500
   LEVEL_4_,       //0.618
   LEVEL_5_        //0.762
  };
//+------------------------------------------------+ 
//| Enumeration for the level actuation indication |
//+------------------------------------------------+ 
enum ENUM_ALERT_MODE //Type of constant
  {
   OnlySound,   //only sound
   OnlyAlert    //only alert
  };
//+------------------------------------------------+
//| Indicator input parameters                     |
//+------------------------------------------------+
input int period=10;                        // Indicator period
input ENUM_FIBORATIO fiboLevel=LEVEL_1_;    // Fibo level value
//---- settings for submitted alerts
input uint SignalBar=0;                     // Signal bar index, 0 is a current bar
input ENUM_ALERT_MODE alert_mode=OnlySound; // Actuation indication version
input uint AlertCount=0;                    // Number of submitted alerts
//+------------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
double ExtColorBuffer[];
//---- declaration of the integer variables for the start of data calculation
int  min_rates_total;
//---- declaration of a variable for storing the Fibo level
double level;
//+------------------------------------------------------------------+
//|  Getting a timeframe as a line                                   |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {
//----
   return(StringSubstr(EnumToString(timeframe),7,-1));
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- initialization of global variables 
   min_rates_total=period;

   switch(fiboLevel)
     {
      case 1: level = LEVEL_1; break;
      case 2: level = LEVEL_2; break;
      case 3: level = LEVEL_3; break;
      case 4: level = LEVEL_4; break;
      case 5: level = LEVEL_5; break;
     }

//---- set dynamic arrays as indicator buffers
   SetIndexBuffer(0,ExtOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtCloseBuffer,INDICATOR_DATA);
//---- set ExtColorBuffer[] dynamic array as an indicator buffer   
   SetIndexBuffer(4,ExtColorBuffer,INDICATOR_COLOR_INDEX);
//---- shifting the start of drawing the indicator 1
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);

//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(ExtOpenBuffer,true);
   ArraySetAsSeries(ExtHighBuffer,true);
   ArraySetAsSeries(ExtLowBuffer,true);
   ArraySetAsSeries(ExtCloseBuffer,true);
   ArraySetAsSeries(ExtColorBuffer,true);

//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="Fibo Candles 2";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<min_rates_total) return(RESET);

//---- declarations of local variables 
   int limit,bar,trend;
   double maxHigh,minLow,range;
   static int trend_;
   static uint buycount=0,sellcount=0;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      trend_=0;
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
     }
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);

//---- set alerts counters to the initial position   
   if(rates_total!=prev_calculated && AlertCount)
     {
      buycount=AlertCount;
      sellcount=AlertCount;
     }

//---- restore values of the variables
   trend=trend_;

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0) trend_=trend;

      maxHigh=high[ArrayMaximum(high,bar,period)];
      minLow=low[ArrayMinimum(low,bar,period)];
      range=maxHigh-minLow;

      if(open[bar]>close[bar])
        {
         if(!(trend<0 && range*level<close[bar]-minLow)) trend=+1;
         else trend=-1;
        }
      else
        {
         if(!(trend>0 && range*level<maxHigh-close[bar])) trend=-1;
         else trend=+1;
        }

      if(trend==+1)
        {
         ExtOpenBuffer [bar]=MathMax(open[bar], close[bar]);
         ExtCloseBuffer[bar]=MathMin(open[bar], close[bar]);
        }

      if(trend==-1)
        {
         ExtOpenBuffer [bar]=MathMin(open[bar], close[bar]);
         ExtCloseBuffer[bar]=MathMax(open[bar], close[bar]);
        }

      ExtHighBuffer [bar]=high[bar];
      ExtLowBuffer  [bar]=low[bar];

      //--- candlesticks coloring
      if(ExtOpenBuffer[bar]>ExtCloseBuffer[bar]) ExtColorBuffer[bar]=1.0;
      else                                       ExtColorBuffer[bar]=0.0;
     }

   if(ExtColorBuffer[SignalBar+1]==0 && ExtColorBuffer[SignalBar]==1 && buycount)
     {
      if(alert_mode==OnlyAlert) Alert("FiboCandles: Signal for buying by ",Symbol(),GetStringTimeframe(_Period));
      if(alert_mode==OnlySound) PlaySound("alert.wav");
      buycount--;
     }

   if(ExtColorBuffer[SignalBar+1]==1 && ExtColorBuffer[SignalBar]==0 && sellcount)
     {
      if(alert_mode==OnlyAlert) Alert("FiboCandles: Signal for selling by ",Symbol(),GetStringTimeframe(_Period));
      if(alert_mode==OnlySound) PlaySound("alert.wav");
      sellcount--;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
