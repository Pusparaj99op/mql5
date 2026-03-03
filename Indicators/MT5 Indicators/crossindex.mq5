//+------------------------------------------------------------------+
//|                                                   CrossIndex.mq5 |
//|                           Copyright © 2010,     Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2010, Nikolay Kositsin"
//---- link to the website of the author
#property link "farria@mail.redcom.ru" 
//---- indicator version
#property version   "1.00"
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing indicator in a separate window
#property indicator_separate_window
//---- 6 buffers are used for calculation and drawing the indicator
#property indicator_buffers 6
//---- only two plots are used
#property indicator_plots   2
//---- color candlesticks are used as an indicator
#property indicator_type2   DRAW_COLOR_CANDLES
#property indicator_color2  LightSeaGreen, DeepPink
//---- displaying the indicator label
#property indicator_label2  "ExtOpenBuffer; ExtHighBuffer; ExtLowBuffer; ExtCloseBuffer"
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_      // Type of constant
  {
   PRICE_CLOSE_ = 1,     // Close
   PRICE_OPEN_,          // Open
   PRICE_HIGH_,          // High
   PRICE_LOW_,           // Low
   PRICE_MEDIAN_,        // Median Price (HL/2)
   PRICE_TYPICAL_,       // Typical Price (HLC/3)
   PRICE_WEIGHTED_,      // ExchIndWeighted Close (HLCC/4)
   PRICE_SIMPLE,         // Simple Price (OC/2)
   PRICE_QUARTER_,       // Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  // TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   // TrendFollow_2 Price 
  };
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input string CrossIndex="EURJPY";           // Currency pair
input color BidColor=Red;
input ENUM_LINE_STYLE BidStyle=STYLE_SOLID;
input Applied_price_ IPC=PRICE_CLOSE;       // Price constant in a zero buffer
input int IndicatorDigits=3;                // Indicator display accuracy format
input bool Direct=true;                     // Chart inversion
//+----------------------------------------------+
bool InitResult;
int prev_calculated_=0;
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double ExtBuffer[];
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
double ExtColorsBuffer[];
//+------------------------------------------------------------------+
//| Getting the minimum number of bars for time series               |
//+------------------------------------------------------------------+
int Rates_Total(string symbol,int Rates_total)
  {
//----
   static datetime LastTime[1];
   int bars=Bars(symbol,PERIOD_CURRENT);
//----
   int error=GetLastError();
   ResetLastError();
   if(error==4401) return(RESET);

   int rates_total_=MathMin(Rates_total,bars);

   datetime Time[1];
   if(CopyTime(symbol,0,bars-1,1,Time)<=0) return(RESET);
   if(Time[0]!=LastTime[0])
     {
      LastTime[0]=Time[0];
      return(RESET);
     }
//----
   return(rates_total_);
  }
//+----------------------------------------------------------------------------+
//|  Checking of the time series synchronization by the current bar time       |
//+----------------------------------------------------------------------------+
bool SynchroCheck(string symbol,datetime BarTime,int Bar)
  {
//----
   datetime TimeN[1];
//----
   if(!BarTime) return(RESET);

   if(CopyTime(symbol,0,Bar,1,TimeN)<=0) return(RESET);
   else if(TimeN[0]!=BarTime) return(RESET);
//----
   return(true);
  }
//+------------------------------------------------------------------+
//| PriceSeries() function                                           |
//+------------------------------------------------------------------+
double PriceSeries(uint applied_price,  // price constant
                   uint   bar,          // index of shift relative to the current bar for a specified number of periods back or forward).
                   const double &Open[],
                   const double &Low[],
                   const double &High[],
                   const double &Close[])
  {
//----+
   switch(applied_price)
     {
      //----+ Price constant from the enumeration ENUM_APPLIED_PRICE
      case  PRICE_CLOSE: return(Close[bar]);
      case  PRICE_OPEN: return(Open [bar]);
      case  PRICE_HIGH: return(High [bar]);
      case  PRICE_LOW: return(Low[bar]);
      case  PRICE_MEDIAN: return((High[bar]+Low[bar])/2.0);
      case  PRICE_TYPICAL: return((Close[bar]+High[bar]+Low[bar])/3.0);
      case  PRICE_WEIGHTED: return((2*Close[bar]+High[bar]+Low[bar])/4.0);

      //----+                            
      case  8: return((Open[bar] + Close[bar])/2.0);
      case  9: return((Open[bar] + Close[bar] + High[bar] + Low[bar])/4.0);
      //----                                
      case 10:
        {
         if(Close[bar]>Open[bar])return(High[bar]);
         else
           {
            if(Close[bar]<Open[bar])
               return(Low[bar]);
            else return(Close[bar]);
           }
        }
      //----         
      case 11:
        {
         if(Close[bar]>Open[bar])return((High[bar]+Close[bar])/2.0);
         else
           {
            if(Close[bar]<Open[bar])
               return((Low[bar]+Close[bar])/2.0);
            else return(Close[bar]);
           }
         break;
        }
      //----
      default: return(Close[bar]);
     }
//----+
//return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
   InitResult=true;
//--- initialization of global variables
   if(!SymbolInfoInteger(CrossIndex,SYMBOL_SELECT))
     {
      if(GetLastError()==ERR_MARKET_UNKNOWN_SYMBOL)
        {
         Print(__FUNCTION__,"(): ",CrossIndex," - There is no such a symbol!!!");
         InitResult=false;
        }
      else if(!SymbolSelect(CrossIndex,true))
        {
         Print(__FUNCTION__,"(): Failed to add a symbol for a currency ",CrossIndex," to the MarketWatch window!!!");
         InitResult=false;
        }
     }

//---- set dynamic arrays as indicator buffers
   SetIndexBuffer(1,ExtOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtCloseBuffer,INDICATOR_DATA);

//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0.0);

//---- set dynamic array as a color index buffer   
   SetIndexBuffer(5,ExtColorsBuffer,INDICATOR_COLOR_INDEX);
   
   SetIndexBuffer(0,ExtBuffer,INDICATOR_CALCULATIONS);

//---- indexing the elements in buffers as timeseries 
   ArraySetAsSeries(ExtBuffer,true);
   ArraySetAsSeries(ExtOpenBuffer,true);
   ArraySetAsSeries(ExtHighBuffer,true);
   ArraySetAsSeries(ExtLowBuffer,true);
   ArraySetAsSeries(ExtCloseBuffer,true);
   ArraySetAsSeries(ExtColorsBuffer,true);

//---- setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,IndicatorDigits);

//---- name for the data window and the label for sub-windows
   string short_name;
   StringConcatenate(short_name,"CrossIndex ",CrossIndex,",",StringSubstr(EnumToString(_Period),7,-1));
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

//---- Bid line drawing parameters   
   IndicatorSetInteger(INDICATOR_LEVELS,1);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,BidColor);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,BidStyle);

   EventSetTimer(1);
//----  
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
void OnTimer()
  {
   int rates_total=Bars(Symbol(),PERIOD_CURRENT);

//---- checking the currency symbol for its presence in the terminal's list
   if(!InitResult) {prev_calculated_=0; return;};

//---- declarations of local variables 
   int cross_rates_total,to_copy,limit,bar;
   cross_rates_total=Rates_Total(CrossIndex,rates_total);

   datetime time0=(datetime)SeriesInfoInteger(Symbol(),PERIOD_CURRENT,SERIES_LASTBAR_DATE);

//---- checking the number of bars to be enough for the calculation and verification of time series synchronization 
   if(!cross_rates_total || !SynchroCheck(CrossIndex,time0,0))
     {
      if(prev_calculated_>rates_total || prev_calculated_<=0) {prev_calculated_=0; return;};

      limit=rates_total-prev_calculated_;

      for(bar=limit-1; bar>=0; bar--)
        {
         ExtColorsBuffer[bar]=1.0;
         ExtBuffer[bar]=ExtBuffer[bar+1];

         ExtOpenBuffer [bar]=ExtCloseBuffer[bar+1];
         ExtCloseBuffer[bar]=ExtCloseBuffer[bar+1];
         ExtHighBuffer [bar]=ExtCloseBuffer[bar+1];
         ExtLowBuffer  [bar]=ExtCloseBuffer[bar+1];
        }

      return;
     }

//---- calculation of the 'limit' starting index for the bars recalculation loop
//---- and preliminary initialization of buffers with empty values
   if(prev_calculated_>rates_total || prev_calculated_<=0) // checking for the first start of the indicator calculation
     {
      limit=cross_rates_total-1;
      int draw_begin=rates_total-limit+1;

      //---- performing shift of the beginning of counting of drawing the indicator by draw_begin
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,draw_begin);
      PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,draw_begin);
      PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,draw_begin);
      PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,draw_begin);
      PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,draw_begin);
      PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,draw_begin);

      for(bar=limit; bar<rates_total; bar++)
        {
         ExtOpenBuffer[bar]=0.0;
         ExtCloseBuffer[bar]=0.0;
         ExtHighBuffer[bar]=0.0;
         ExtLowBuffer[bar]=0.0;
        }
     }
   else
     {
      limit=rates_total-prev_calculated_;
      if(limit>cross_rates_total-1) {prev_calculated_=0; return;};
     }

//---- calculation of the data amount to be copied   
   to_copy=limit+1;

//--- copy newly appeared data in the arrays
   if(CopyOpen (CrossIndex,PERIOD_CURRENT,0,to_copy,ExtOpenBuffer)<=0)  {prev_calculated_=0; return;};
   if(CopyHigh (CrossIndex,PERIOD_CURRENT,0,to_copy,ExtHighBuffer)<=0)  {prev_calculated_=0; return;};
   if(CopyLow  (CrossIndex,PERIOD_CURRENT,0,to_copy,ExtLowBuffer)<=0)   {prev_calculated_=0; return;};
   if(CopyClose(CrossIndex,PERIOD_CURRENT,0,to_copy,ExtCloseBuffer)<=0) {prev_calculated_=0; return;};

//---- painting the candlesticks
   for(bar=limit; bar>=0; bar--)
      if(ExtOpenBuffer[bar]<ExtCloseBuffer[bar]) ExtColorsBuffer[bar]=0.0;
   else                                          ExtColorsBuffer[bar]=1.0;

//---- download the calculated value of the price time series to the ExtBuffer[] zero buffer
   for(bar=limit; bar>=0; bar--)
      ExtBuffer[bar]=PriceSeries(IPC,bar,ExtOpenBuffer,ExtLowBuffer,ExtHighBuffer,ExtCloseBuffer);

//---- Bid line shift parameters     
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,ExtCloseBuffer[0]);
//----  
   if(prev_calculated_==0) ChartRedraw(0);
   prev_calculated_=rates_total;
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
//----
   return(rates_total);
//----
  }
//+------------------------------------------------------------------+
