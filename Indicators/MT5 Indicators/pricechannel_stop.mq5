//+------------------------------------------------------------------+
//|                                            PriceChannel_Stop.mq4 | 
//|                           Copyright © 2005, TrendLaboratory Ltd. | 
//|                                       E-mail: igorad2004@list.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, TrendLaboratory Ltd." 
//---- link to the website of the author
#property link "E-mail: igorad2004@list.ru" 
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- six buffers are used for calculation and drawing the indicator
#property indicator_buffers 6
//---- totally 6 graphical plots are used
#property indicator_plots   6
//+----------------------------------------------+
//|  Parameters of drawing the bearish indicator |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- magenta color is used as the entry symbol
#property indicator_color1  Magenta
//---- thickness of line of the indicator 1 is equal to 1
#property indicator_width1  1
//---- displaying the indicator label 1
#property indicator_label1  "SellSignal"

//---- drawing the indicator 2 as a symbol
#property indicator_type2   DRAW_ARROW
//---- magenta color is used as a stop-losses symbol
#property indicator_color2  Magenta
//---- thickness of line of the indicator 2 is equal to 1
#property indicator_width2  1
//---- displaying the indicator label 2
#property indicator_label2 "SellStopSignal"

//---- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_LINE
//---- magenta color is used as a stop-losses line color
#property indicator_color3  Magenta
//---- thickness of line of the indicator 3 is equal to 1
#property indicator_width3  1
//---- displaying the indicator label 3
#property indicator_label3 "SellStopLine"
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4   DRAW_ARROW
//---- lime color is used as the entry symbol
#property indicator_color4  Lime
//---- thickness of line of the indicator 4 is equal to 1
#property indicator_width4  1
//---- displaying the indicator label 4
#property indicator_label4  "BuySignal"

//---- drawing the indicator 5 as a symbol
#property indicator_type5   DRAW_ARROW
//---- lime color is used as a stop-losses symbols
#property indicator_color5  Lime
//---- thickness of line of the indicator 5 is equal to 1
#property indicator_width5  1
//---- displaying the indicator label 5
#property indicator_label5 "BuyStopSignal"

//---- drawing the indicator 6 as a symbol
#property indicator_type6   DRAW_LINE
//---- lime color is used as a stop-losses line color
#property indicator_color6  Lime
//---- thickness of line of the indicator 6 is equal to 1
#property indicator_width6  1
//---- displaying the indicator label 6
#property indicator_label6 "BuyStopLine"

//+----------------------------------------------+
//| Input parameters of the indicator            |
//+----------------------------------------------+
input int ChannelPeriod=5;
input double Risk=0.10;
input bool Signal=true;
input bool Line=true;
//+----------------------------------------------+

//---- declaration of dynamic arrays that 
// will be used as indicator buffers
double DownTrendSignal[];
double DownTrendBuffer[];
double DownTrendLine[];
double UpTrendSignal[];
double UpTrendBuffer[];
double UpTrendLine[];
//----
int StartBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables 
   StartBars=ChannelPeriod+1;
//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,DownTrendSignal,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//---- create label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"SellSignal");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,108);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(DownTrendSignal,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,DownTrendBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//---- create label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"SellStopSignal");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(DownTrendBuffer,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(2,DownTrendLine,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,StartBars);
//---- create label to display in DataWindow
   PlotIndexSetString(2,PLOT_LABEL,"SellStopLine");
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(DownTrendLine,true);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(3,UpTrendSignal,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,StartBars);
//---- create label to display in DataWindow
   PlotIndexSetString(3,PLOT_LABEL,"BuySignal");
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,108);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(UpTrendSignal,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(4,UpTrendBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 5
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,StartBars);
//---- create label to display in DataWindow
   PlotIndexSetString(4,PLOT_LABEL,"BuyStopSignal");
//---- indicator symbol
   PlotIndexSetInteger(4,PLOT_ARROW,159);
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(UpTrendBuffer,true);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(5,UpTrendLine,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 6
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,StartBars);
//---- create label to display in DataWindow
   PlotIndexSetString(5,PLOT_LABEL,"BuyStopLine");
//---- indexing elements in the buffer as timeseries
   ArraySetAsSeries(UpTrendLine,true);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0.0);
   
//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="PriceChannel_Stop";
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
   if(rates_total<StartBars) return(0);

//---- declarations of local variables 
   int limit,bar,iii,trend;
   double bsmax[],bsmin[],High,Low,Price,dPrice;

//---- memory variables declarations  
   static int trend_;
   static double bsmax_,bsmin_;

//---- calculations of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      limit=rates_total-StartBars; // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }

//---- indexing elements in arrays as timeseries
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//---- change the sizes of temporary arrays 
   if(ArrayResize(bsmax,limit+2)!=limit+2) return(0);
   if(ArrayResize(bsmin,limit+2)!=limit+2) return(0);

//---- temporary arrays calculation preliminary cycle
   for(bar=limit; bar>=0; bar--)
     {
      High=high[bar];
      Low =low [bar];
      iii=bar-1+ChannelPeriod;
      while(iii>=bar)
        {
         Price=high[iii];
         if(High<Price)High=Price;
         Price=low[iii];
         if(Low>Price) Low=Price;
         iii--;
        }
      dPrice=(High-Low)*Risk;
      bsmax[bar]=High-dPrice;
      bsmin[bar]=Low +dPrice;
     }

//---- restore values of the variables
   bsmax[limit+1]=bsmax_;
   bsmin[limit+1]=bsmin_;
   trend=trend_;

//---- main indicator calculation loop
   for(bar=limit; bar>=0; bar--)
     {
//---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         bsmax_=bsmax[1];
         bsmin_=bsmin[1];
         trend_=trend;
        }
//----        
      UpTrendBuffer  [bar]=0.0;
      DownTrendBuffer[bar]=0.0;
      UpTrendSignal  [bar]=0.0;
      DownTrendSignal[bar]=0.0;
      UpTrendLine    [bar]=0.0;
      DownTrendLine  [bar]=0.0;
//----
      if(close[bar]>bsmax[bar+1]) trend= 1;
      if(close[bar]<bsmin[bar+1]) trend=-1;
//----
      if(trend>0 && bsmin[bar]<bsmin[bar+1]) bsmin[bar]=bsmin[bar+1];
      if(trend<0 && bsmax[bar]>bsmax[bar+1]) bsmax[bar]=bsmax[bar+1];
//----
      if(trend>0)
        {
         Price=bsmin[bar];
         if(Signal && DownTrendBuffer[bar+1]>0)
           {
            UpTrendSignal[bar]=Price;
            if(Line) UpTrendLine[bar]=Price;
           }
         else
           {
            UpTrendBuffer[bar]=Price;
            if(Line) UpTrendLine[bar]=Price;
           }
        }
//----
      if(trend<0)
        {
         Price=bsmax[bar];
         if(Signal && UpTrendBuffer[bar+1]>0)
           {
            DownTrendSignal[bar]=Price;
            if(Line) DownTrendLine[bar]=Price;
           }
         else
           {
            DownTrendBuffer[bar]=Price;
            if(Line) DownTrendLine[bar]=Price;
           }
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
