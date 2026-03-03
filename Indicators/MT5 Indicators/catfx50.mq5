//+------------------------------------------------------------------+
//|                                                      CatFX50.mq5 |
//|                                                                  | 
//|                    http://www.forex-tsd.com/showthread.php?t=523 | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link      "http://www.forex-tsd.com/showthread.php?t=523"
#property description "CatFX50"
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- three buffers are used for calculation and drawing the indicator
#property indicator_buffers 3
//---- only three plots are used
#property indicator_plots   3
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//---- BlueViolet color is used as the color of the bullish line of the indicator
#property indicator_color1 clrBlueViolet
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "CatFX50 EMA"
//+----------------------------------------------+
//|  Bullish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- blue color is used for the indicator bullish line
#property indicator_color2  clrBlue
//---- indicator 2 line width is equal to 4
#property indicator_width2  4
//---- bearish indicator label display
#property indicator_label2 "CatFX50 Buy"
//+----------------------------------------------+
//|  Bearish indicator drawing parameters        |
//+----------------------------------------------+
//---- drawing the indicator 3 as a symbol
#property indicator_type3   DRAW_ARROW
//---- magenta color is used as the color of the bearish indicator line
#property indicator_color3  clrMagenta
//---- the indicator 3 line width is equal to 4
#property indicator_width3  4
//---- bullish indicator label display
#property indicator_label3  "CatFX50 Sell"
//+----------------------------------------------+
//|  declaration of enumerations                 |
//+----------------------------------------------+
enum HourCount //Час суток
  {
   D00=0,   //0
   D01,     //1
   D02,     //2
   D03,     //3
   D04,     //4
   D05,     //5
   D06,     //6
   D07,     //7
   D08,     //8
   D09,     //9
   D10,     //10
   D11,     //11
   D12,     //12
   D13,     //13
   D14,     //14
   D15,     //15
   D16,     //16
   D17,     //17
   D18,     //18
   D19,     //19
   D21,     //21
   D22,     //22
   D23      //23
  };
//+----------------------------------------------+
//|  declaring constants                         |
//+----------------------------------------------+
#define RESET  0 // The constant for getting the command for the indicator recalculation back to the terminal
//+----------------------------------------------+
//| Indicator input parameters                   |
//+----------------------------------------------+
input int confirm_StepMA_Bars=2;    //amount of bars for the signal confirmation
input HourCount TradeTimeFrom=D00;  //trading start
input HourCount TradeTimeTo=D23;    //trading end
input bool alert_ON=false;          //allow to put alert
input double Kfast=1.0000;
input double Kslow=1.0000;
input uint EMA_Period=50;
//+----------------------------------------------+

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double EMABuffer[];
double SellBuffer[];
double BuyBuffer[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//---- Declaration of integer variables for the indicator handles
int  EMA_Handle,ATR_Handle,StSt_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- initialization of global variables
   uint ATR_Period=5;
   uint StSt_Period=10;
   min_rates_total=int(MathMax(MathMax(ATR_Period,EMA_Period),StSt_Period)+confirm_StepMA_Bars+5);

//---- getting the iMA indicator handle
   EMA_Handle=iMA(NULL,0,EMA_Period,0,MODE_EMA,PRICE_MEDIAN);
   if(EMA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- getting the ATR indicator handle
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE) Print(" Failed to get handle of the ATR indicator");

//---- getting the StepSto_v1 indicator handle
   StSt_Handle=iCustom(NULL,0,"StepSto_v1",Kfast,Kslow,0);
   if(StSt_Handle==INVALID_HANDLE) Print(" Failed to get handle of StepSto_v1 indicator");

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,EMABuffer,INDICATOR_DATA);
//---- performing the shift of beginning of indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(EMABuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,119);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(BuyBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(2,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,119);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(SellBuffer,true);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and the label for sub-windows 
   string short_name="CatFX50";
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
//---- checking for the sufficiency of bars for the calculation
   if(BarsCalculated(StSt_Handle)<rates_total
      || BarsCalculated(EMA_Handle)<rates_total
      || BarsCalculated(ATR_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declaration of local variables 
   int limit,bar,to_copy;
   double ATR[],STSTM[],STSTS[];
   double stepma00,stepma01,stepma10,stepma11;

//--- calculations of the necessary amount of data to be copied and
//the limit starting index for loop of bars recalculation
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

   to_copy=limit+1;

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(STSTM,true);
   ArraySetAsSeries(STSTS,true);

//---- copy newly appeared data into the arrays
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
   if(CopyBuffer(EMA_Handle,0,0,to_copy,EMABuffer)<=0) return(RESET);
   if(CopyBuffer(StSt_Handle,MAIN_LINE,0,to_copy+confirm_StepMA_Bars+1,STSTM)<=0) return(RESET);
   if(CopyBuffer(StSt_Handle,SIGNAL_LINE,0,to_copy+confirm_StepMA_Bars+1,STSTS)<=0) return(RESET);

//---- main loop of the indicator calculation
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      SellBuffer[bar]=0;
      BuyBuffer[bar]=0;

      MqlDateTime tm;
      TimeToStruct(time[bar],tm);

      if(tm.hour>=TradeTimeFrom && tm.hour<=TradeTimeTo)
        {
         //Long check start
         if(open[bar+1]<EMABuffer[bar+1] && close[bar+1]>EMABuffer[bar+1] && open[bar]>EMABuffer[bar])//cross EMA50
           {
            for(int j=confirm_StepMA_Bars; j>=0; j--)
              {
               int barj=bar+j;
               stepma00=STSTM[barj];
               stepma01=STSTS[barj];
               stepma10=STSTM[barj+1];
               stepma11=STSTS[barj+1];

               if(stepma10<stepma11 && stepma00>stepma01)//StepMA cross
                 {
                  BuyBuffer[bar]=low[bar]-ATR[bar]/2;
                  if(!bar && alert_ON) Alert(TimeToString(time[bar],TIME_MINUTES)," CatFX50 ",Symbol()," BUY");
                 }
              }
           }
         //Long check end
         
         //Short check start
         if(open[bar+1]>EMABuffer[bar+1] && close[bar+1]<EMABuffer[bar+1] && open[bar]<EMABuffer[bar])//cross EMA50
           {
            for(int j=confirm_StepMA_Bars; j>=0; j--)
              {
               int barj=bar+j;
               stepma00=STSTM[barj];
               stepma01=STSTS[barj];
               stepma10=STSTM[barj+1];
               stepma11=STSTS[barj+1];

               if(stepma10>stepma11 && stepma00<stepma01)//StepMA cross
                 {
                  SellBuffer[bar]=high[bar]+ATR[bar]/2;
                  if(!bar && alert_ON) Alert(TimeToString(time[bar],TIME_MINUTES)," CatFX50 ",Symbol()," SELL");
                 }
              }
           }
         //Short check end
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
