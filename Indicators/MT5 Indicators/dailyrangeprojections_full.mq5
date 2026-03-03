//+------------------------------------------------------------------+
//|                                 Daily Range Projections Full.mq5 |
//|                           Copyright © 2010,     Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2010, Nikolay Kositsin"
//---- link to the website of the author
#property link "farria@mail.redcom.ru"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- three buffers are used for calculation and drawing the indicator
#property indicator_buffers 3
//---- 3 plots are used
#property indicator_plots   3
//+----------------------------------------------+
//|  Indicator 1 drawing parameters              |
//+----------------------------------------------+
//---- drawing the indicator as a label
#property indicator_type1   DRAW_ARROW
//---- lime color is used as the color of the indicator 1 line
#property indicator_color1  Lime
//---- indicator 1 line width is equal to 3
#property indicator_width1  3
//---- displaying the indicator label
#property indicator_label1  "Tomorrow's anticipated high price"
//+----------------------------------------------+
//|  Indicator 2 drawing parameters              |
//+----------------------------------------------+
//---- drawing the indicator as a label
#property indicator_type2   DRAW_ARROW
//---- dark orchid color is used for the indicator 2 line
#property indicator_color2  DarkOrchid
//---- indicator 2 line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator label
#property indicator_label2  "Tomorrow's anticipated average price"
//+----------------------------------------------+
//|  R30 level drawing parameters                |
//+----------------------------------------------+
//---- drawing the indicator as a label
#property indicator_type3   DRAW_ARROW
//---- red color is used for the indicator line
#property indicator_color3 Red
//---- the indicator line width is equal to 3
#property indicator_width3  3
//---- displaying the indicator label
#property indicator_label3  "Tomorrow's anticipated low price"
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int  Symbol_MAX = 119;        // High price label for tomorrow
input int  Symbol_MID = 167;        // Average price label for tomorrow
input int  Symbol_MIN = 119;        // Low price label for tomorrow
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double ExtMaxBuffer[];
double ExtMinBuffer[];
double ExtMidBuffer[];
//+------------------------------------------------------------------+
//|  Creating horizontal price level                                 |
//+------------------------------------------------------------------+
void CreateHline(long   chart_id,  // chart ID
                 string name,      // object name
                 int    nwin,      // window index
                 double price,     // price level
                 color  Color,     // line color
                 int    style,     // line style
                 int    width,     // line width
                 string text)      // text
  {
//----
   ObjectCreate(chart_id,name,OBJ_HLINE,0,0,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//----
  }
//+------------------------------------------------------------------+
//|  Reinstallation of the horizontal price level                    |
//+------------------------------------------------------------------+
void SetHline(long   chart_id,  // chart ID
              string name,      // object name
              int    nwin,      // window index
              double price,     // price level
              color  Color,     // line color
              int    style,     // line style
              int    width,     // line width
              string text)      // text
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateHline(chart_id,name,nwin,price,Color,style,width,text);
   else
     {
      // ObjectSetDouble(chart_id,name,OBJPROP_MIDRICE,price);
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,0,price);
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- set ExtMaxBuffer[], ExtMidBuffer[] and ExtMinBuffer[] dynamic arrays into indicator buffers
   SetIndexBuffer(0,ExtMaxBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtMidBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtMinBuffer,INDICATOR_DATA);

//---- indicator symbols
   PlotIndexSetInteger(0,PLOT_ARROW,Symbol_MAX);
   PlotIndexSetInteger(1,PLOT_ARROW,Symbol_MID);
   PlotIndexSetInteger(2,PLOT_ARROW,Symbol_MIN);

//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(ExtMaxBuffer,true);
   ArraySetAsSeries(ExtMidBuffer,true);
   ArraySetAsSeries(ExtMinBuffer,true);

//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- creating labels for displaying in DataWindow and the name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"Daily Range Projections");
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----

//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- 
   if(_Period>=PERIOD_D1 || rates_total<1) return(RESET);

//---- declarations of local variables 
   int limit,bar;

//---- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-1;                 // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(time,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- declarations of local variables 
      double X=0.0;
      MqlRates rates[2]; // static array and reverse indexing of the elements (the current bar is the first one!)      

      //---- copy newly appeared data in the rates array
      if(CopyRates(Symbol(),PERIOD_D1,time[bar],2,rates)<=0) return(RESET);

      if(rates[1].close< rates[1].open) X=(rates[0].high+rates[0].low+rates[0].close+rates[0].low  )/2.0;
      if(rates[1].close> rates[1].open) X=(rates[0].high+rates[0].low+rates[0].close+rates[0].high )/2.0;
      if(rates[1].close==rates[1].open) X=(rates[0].high+rates[0].low+rates[0].close+rates[0].close)/2.0;

      ExtMaxBuffer[bar] = NormalizeDouble(X-rates[0].low, _Digits);
      ExtMinBuffer[bar] = NormalizeDouble(X-rates[0].high,_Digits);
      ExtMidBuffer[bar] = NormalizeDouble((ExtMaxBuffer[bar]+ExtMinBuffer[bar])/2.0,_Digits);
     }
//----   
   return(rates_total);
  }
//+------------------------------------------------------------------+
