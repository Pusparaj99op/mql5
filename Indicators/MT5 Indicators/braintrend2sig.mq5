//+------------------------------------------------------------------+
//|                                               BrainTrend2Sig.mq5 |
//|                               Copyright © 2005, BrainTrading Inc |
//|                                      http://www.braintrading.com |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2005, BrainTrading Inc."
//---- link to the website of the author
#property link      "http://www.braintrading.com/"
//---- Indicator Version Number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//----two buffers are used for calculation and drawing the indicator
#property indicator_buffers 2
//---- only two plots are used
#property indicator_plots   2
//+----------------------------------------------+
//|  Parameter of drawing the bearish indicator  |
//+----------------------------------------------+
//---- drawing the indicator 1 as a symbol
#property indicator_type1   DRAW_ARROW
//---- red color is used as the color of the bearish indicator line
#property indicator_color1  Red
//---- thickness of line of the indicator 1 is equal to 4
#property indicator_width1  4
//---- displaying of the bearish label of the indicator
#property indicator_label1  "Brain2Sell"
//+----------------------------------------------+
//|  Parameters of drawing the bullish indicator |
//+----------------------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type2   DRAW_ARROW
//---- blue color is used as the color of a bullish candlestick
#property indicator_color2  Blue
//---- thickness of line of the indicator 2 is equal to 4
#property indicator_width2  4
//---- displaying of the bullish label of the indicator
#property indicator_label2 "Brain2Buy"

//+----------------------------------------------+
//| Input parameters of the indicator            |
//+----------------------------------------------+
input int ATR_Period=7;
//+----------------------------------------------+

//---- declaration of dynamic arrays that further 
// will be used as indicator buffers
double SellBuffer[];
double BuyBuffer[];
//---
bool   river=true,river_;
int    glava,glava_,StartBars,OldTrend,ATR_Handle;
double s,dartp,cecf,Emaxtra,Emaxtra_,Values_[],Values[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- initialization of global variables 
   s=1.5;
   dartp=7.0;
   cecf=0.7;
   StartBars=ATR_Period+2;

//---- memory distribution for variables' arrays   
   if(ArrayResize(Values,ATR_Period)<ATR_Period)
      Print("Failed to distribute the memory for Values array");
   if(ArrayResize(Values_,ATR_Period)<ATR_Period)
      Print("Failed to distribute the memory for Values array_");

//---- turning a dynamic array into an indicator buffer
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBars);
//--- create label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Brain2Sell");
//---- indicator symbol
   PlotIndexSetInteger(0,PLOT_ARROW,108);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(SellBuffer,true);

//---- turning a dynamic array into an indicator buffer
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- shifting the start of drawing of the indicator 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartBars);
//--- create label to display in DataWindow
   PlotIndexSetString(1,PLOT_LABEL,"Brain2Buy");
//---- indicator symbol
   PlotIndexSetInteger(1,PLOT_ARROW,108);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(BuyBuffer,true);

//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- name for the data window and for the label of sub-windows 
   string short_name="BrainTrend2Sig";
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

//---- declaration of local variables    
   int bar,J,limit,Curr;
   double ATR,widcha,TR,Spread,range2;
   double Weight,Series1,High,Low;

//---- Calculate the limit starting number for loop of bars recalculation and start initialization of variables
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      limit=rates_total-StartBars; // starting number for calculation of all bars
      Emaxtra=close[limit+1];
      glava=0;
      double T_Series2=close[limit+2];
      double T_Series1=close[limit+1];
      if(T_Series2>T_Series1)
         river=true;
      else river=false;

      TR=spread[limit]+high[limit]-low[limit];

      if(MathAbs(spread[limit]+high[limit]-T_Series1)>TR)
         TR=MathAbs(spread[limit]+high[limit]-T_Series1);

      if(MathAbs(low[limit]-T_Series1)>TR)
         TR=MathAbs(low[limit]-T_Series1);

      ArrayInitialize(Values,TR);
     }
   else
     {
      limit=rates_total-prev_calculated; // starting number for calculation of new bars
     }

//---- indexing elements in arrays, as in timeseries  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(spread,true);
   ArraySetAsSeries(Values,true);
   ArraySetAsSeries(Values_,true);

//---- restore values of the variables
   glava=glava_;
   Emaxtra=Emaxtra_;
   river=river_;
   ArrayCopy(Values,Values_,0,WHOLE_ARRAY);
   
//---- main cycle of calculation of the indicator
   for(bar=limit; bar>=0; bar--)
     {
      //---- memorize values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         glava_=glava;
         Emaxtra_=Emaxtra;
         river_=river;
         ArrayCopy(Values_,Values,0,WHOLE_ARRAY);
        }

      SellBuffer[bar]=0.0;
      BuyBuffer[bar]=0.0;
    
      Spread=spread[bar]*_Point;

      High=high[bar];
      Low=low[bar];
      Series1=close[bar+1];
      TR=Spread+High-Low;

      if(MathAbs(Spread+High-Series1)>TR)
         TR=MathAbs(Spread+High-Series1);

      if(MathAbs(Low-Series1)>TR)
         TR=MathAbs(Low-Series1);

      Values[glava]=TR;

      ATR=0;
      Weight=ATR_Period;
      Curr=glava;

      for(J=0; J<=ATR_Period-1; J++)
        {
         ATR+=Values[Curr]*Weight;
         Weight-=1.0;
         Curr--;
         if(Curr==-1) Curr=ATR_Period-1;
        }

      ATR=2.0*ATR/(dartp *(dartp+1.0));
      glava++;
      
      range2=ATR*s/4;

      if(glava==ATR_Period) glava=0;

      widcha=cecf*ATR;

      if(river && Low<Emaxtra-widcha)
        {
         river=false;
         Emaxtra=Spread+High;
        }

      if(!river && Spread+High>Emaxtra+widcha)
        {
         river=true;
         Emaxtra=Low;
        }

      if(river && Low>Emaxtra)
        {
         Emaxtra=Low;
        }

      if(!river && Spread+High<Emaxtra)
        {
         Emaxtra=Spread+High;
        }

      if(river)
        {
         if(OldTrend<0) BuyBuffer[bar]=Low-range2;
         if(bar!=0)OldTrend=+1;
        }
      else
        {
         if(OldTrend>0) SellBuffer[bar]=High+range2;
         if(bar!=0)OldTrend=-1;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
