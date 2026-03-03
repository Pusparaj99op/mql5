//+------------------------------------------------------------------+
//|                                                    BAT_ATRv1.mq5 |
//|                                     Copyright © 2008, Team Aphid | 
//|                                                                  | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, Team Aphid"
#property link ""
#property description ""
//---- Indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//----four buffers are used for calculation of drawing of the indicator
#property indicator_buffers 4
//---- four plots are used
#property indicator_plots   4
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- blue color is used for the indicator
#property indicator_color1  clrBlue
//---- indicator 1 width is equal to 2
#property indicator_width1  2
//---- indicator bullish label display
#property indicator_label1  "Lower BAT_ATRv1"
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- Orange color is used as the color of the indicator
#property indicator_color2  clrOrange
//---- indicator 2 width is equal to 2
#property indicator_width2  2
//---- bearish indicator label display
#property indicator_label2 "Upper BAT_ATRv1"
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_ARROW
//---- blue color is used for the indicator
#property indicator_color3  clrBlue
//---- indicator 3 width is equal to 1
#property indicator_width3  1
//---- indicator bullish label display
#property indicator_label3  "BAT_ATRv1 Buy"
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing the indicator 4 as a symbol
#property indicator_type4   DRAW_ARROW
//---- Orange color is used as the color of the indicator
#property indicator_color4  clrOrange
//---- indicator 4 width is equal to 1
#property indicator_width4  1
//---- bearish indicator label display
#property indicator_label4 "BAT_ATRv1 Sell"
//+-----------------------------------+
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET 0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input uint    ATRPeriod=3;
input double Factor=3;
input bool   TypicalPrice=false;
//+----------------------------------------------+
//---- declaration of dynamic arrays that 
//---- will be used as indicator buffers
double BuyBuffer[],SellBuffer[];
double UpBuffer[],DnBuffer[];
//---- Declaration of integer variables for indicators handles
int ATR_Handle;
//---- declaration of the integer variables for the start of data calculation
int  min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables    
   min_rates_total=int(ATRPeriod+1);

//---- Getting the handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,ATRPeriod);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the ATR indicator");
      return(INIT_FAILED);
     }

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//---- Shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,158);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(UpBuffer,true);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,DnBuffer,INDICATOR_DATA);
//---- shifting the starting point of calculation of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,158);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(DnBuffer,true);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(2,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,174);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellBuffer,true);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(3,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 4
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,174);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyBuffer,true);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);

//---- Setting the indicator display accuracy format
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name;
   short_name="BAT_ATRv1 ("+string(ATRPeriod)+","+DoubleToString(Factor,2)+" )";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//---- initialization end
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(ATR_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declaration of local variables 
   int limit,bar,to_copy,Dir;
   double CurrUp,CurrDn,LvlUp,LvlDn,PriceLvl,Range[];
   static int Dir_;
   static double LvlUp_,LvlDn_;

//---- indexing elements in arrays as in timeseries
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);

//---- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total; // starting index for calculation of all bars     
     }
   else limit=rates_total-prev_calculated; // Starting index for the calculation of new bars

//---- calculation of the necessary amount of data to be copied
   to_copy=limit+1;

//---- copy newly appeared data in the Range[] arrays
   if(CopyBuffer(ATR_Handle,0,0,to_copy,Range)<=0) return(RESET);

//---- initialization at the start
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation
     {
      limit--;
      CurrUp=Close[limit+1]-Range[limit+1]*Factor;
      double PrevUp=Close[limit]-Range[limit]*Factor;
      CurrDn=Close[limit+1]-Range[limit+1]*Factor;
      double PrevDn=Close[limit]-Range[limit]*Factor;
      //----
      if(CurrUp>PrevUp) Dir_=+1;
      LvlUp_=CurrUp;
      if(CurrDn<PrevDn) Dir_=-1;
      LvlDn_=CurrDn;
     }

//---- Restore values of the variables
   LvlUp=LvlUp_;
   LvlDn=LvlDn_;
   Dir=Dir_;

//---- first indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      UpBuffer[bar]=0.0;
      DnBuffer[bar]=0.0;

      if(TypicalPrice) PriceLvl=(High[bar]+Low[bar]+Close[bar])/3;
      else PriceLvl=Close[bar];

      CurrUp=PriceLvl-Range[bar]*Factor;
      CurrDn=PriceLvl+Range[bar]*Factor;

      if(Dir==+1)
        {
         if(CurrUp>LvlUp)
           {
            UpBuffer[bar]=CurrUp;
            LvlUp=CurrUp;
           }
         else
           {
            UpBuffer[bar]=LvlUp;
           }

         if(Low[bar]<UpBuffer[bar])
           {
            Dir=-1;
            LvlDn=999999999;
           }
        }
      else
      if(Dir==-1)
        {
         if(CurrDn<LvlDn)
           {
            DnBuffer[bar]=CurrDn;
            LvlDn=CurrDn;
           }
         else
           {
            DnBuffer[bar]=LvlDn;
           }

         if(High[bar]>DnBuffer[bar])
           {
            Dir=+1;
            LvlUp=0;
           }
        }

      //---- Save the values of the variables
      if(bar==1)
        {
         LvlUp_=LvlUp;
         LvlDn_=LvlDn;
         Dir_=Dir;
        }
     }

//---- recalculation of the starting index for calculation of all bars
   if(prev_calculated>rates_total || prev_calculated<=0)// Checking for the first start of the indicator calculation     
      limit--;

//---- the second indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- reset the contents of the indicator buffers for calculation
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;

      if(UpBuffer[bar+1]>0.0&&DnBuffer[bar]>0.0) BuyBuffer [bar]=DnBuffer[bar];
      if(DnBuffer[bar+1]>0.0&&UpBuffer[bar]>0.0) SellBuffer[bar]=UpBuffer[bar];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
