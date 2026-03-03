/*
 * For the indicator to work, place the
 * SmoothAlgorithms.mqh
 * in the directory: MetaTrader\\MQL5\Include
 */
//+------------------------------------------------------------------+
//|                                                   JFatlSpeed.mq5 |
//|                               Copyright © 2010, Nikolay Kositsin |
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "2010,   Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
#property version   "1.00"

//---- drawing the indicator in a separate window
#property indicator_separate_window 
//---- one buffer is used for calculation and drawing of the indicator
#property indicator_buffers 1
//---- only one plot is used
#property indicator_plots   1
//---- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//---- blue color is used as the color of the indicator line
#property indicator_color1  Blue
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1  2
//---- displaying the indicator label
#property indicator_label1  "JFATL"
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
enum Applied_price_ //Type of constant
  {
   PRICE_CLOSE_ = 1,     //PRICE_CLOSE
   PRICE_OPEN_,          //PRICE_OPEN
   PRICE_HIGH_,          //PRICE_HIGH
   PRICE_LOW_,           //PRICE_LOW
   PRICE_MEDIAN_,        //PRICE_MEDIAN
   PRICE_TYPICAL_,       //PRICE_TYPICAL
   PRICE_WEIGHTED_,      //PRICE_WEIGHTED
   PRICE_SIMPL_,         //PRICE_SIMPLE_
   PRICE_QUARTER_,       //PRICE_QUARTER_
   PRICE_TRENDFOLLOW0_, //PRICE_TRENDFOLLOW0_
   PRICE_TRENDFOLLOW1_  //PRICE_TRENDFOLLOW1_
  };
input int Length_=8; // JMA period of Fatl smoothing                   
input int Phase_=100; // JMA parameter of Fatl smoothing,
                      //that changes within the range -100 ... +100
//depends of the quality of the transitional prices;

input int MomPeriod=1;//Momentum indicator period for rate measuring

input int Smooth=2; // Depth of the JMA smoothing of the indicator                  
input int SmPhase=100; // Parameter of the JMA smoothing of the indicator
                       //that changes within the range -100 ... +100
//depends of the quality of the transitional prices;

input Applied_price_ IPC=PRICE_CLOSE_;//Price constant
/* , used for the indicator calculation (1-CLOSE, 2-OPEN, 3-HIGH, 4-LOW, 
  5-MEDIAN, 6-TYPICAL, 7-WEIGHTED, 8-SIMPL, 9-QUARTER, 10-TRENDFOLLOW, 11-0.5 * TRENDFOLLOW.) */

input int FATLShift=0; // Horizontal shift of the indicator in bars
//+-----------------------------------+

//---- declaration and initialization of a variable for storing the number of FATL calculated bars
int FATLPeriod=39;

//---- declaration of a dynamic array that further 
// will be used as an indicator buffer
double ExtLineBuffer[];

int start,fstart,jfstart,mstart,FATLSize;
double dPriceShift;
//+------------------------------------------------------------------+
// The iPriceSeries() function description                           |
// Description of CFATL, CJJMA and CMomentum classes                 |
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh>  
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- set ExtLineBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//---- shifting the indicator horizontally by FATLShift
   PlotIndexSetInteger(0,PLOT_SHIFT,FATLShift);
//---- initialization of variables
   fstart=FATLPeriod;
   jfstart=fstart+30;
   mstart=jfstart+MomPeriod;
   start=mstart+30;
//---- performing the shift of beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,start);
//---- initializations of a variable for the indicator short name
   string shortname;
   StringConcatenate(shortname,"JFATLSpeed(",Length_," ,",Phase_," ,",MomPeriod,")");
//---- create label to display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,shortname);
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- declaration of a CJJMA class variable from the JJMASeries_Cls.mqh file
   CJJMA JMA;
//---- setting up alerts for unacceptable values of external variables
   JMA.JJMALengthCheck("Length_", Length_);
   JMA.JJMAPhaseCheck("Phase_", Phase_);
   JMA.JJMALengthCheck("MomPeriod", MomPeriod);
   JMA.JJMALengthCheck("Smooth", Smooth);
   JMA.JJMAPhaseCheck("SmPhase", SmPhase);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
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
   if(rates_total<start)
      return(0);

//---- declarations of local variables 
   int first,bar;
   double price,jfatl,fatl,jmom,jfspeed;

//---- calculation of the 'first' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      first=0; // starting index for calculation of all bars
     }
   else first=prev_calculated-1; // starting index for calculation of new bars

//---- declaration of the CFATL, CJJMA and CMomentum classes variables from the JJMASeries_Cls.mqh file
   static CJJMA JMA1,JMA2;
   static CFATL FATL;
   static CMomentum MOM;

//---- main indicator calculation loop
   for(bar=first; bar<rates_total; bar++)
     {
      //---- getting the input price
      price=PriceSeries(IPC,bar,open,low,high,close);

      //---- uploading the input price into FATLSeries() and getting fatl
      fatl=FATL.FATLSeries(0,prev_calculated,rates_total,price,bar,false);

      //---- uploading fatl into JJMASeries() and getting jfatl
      jfatl=JMA1.JJMASeries(fstart,prev_calculated,rates_total,0,Phase_,Length_,fatl,bar,false);

      //---- uploading jfatl into MomentumSeries() and getting jmom
      jmom=MOM.MomentumSeries(jfstart,prev_calculated,rates_total,MomPeriod,jfatl,bar,false);

      //---- uploading jmom into JJMASeries() and getting jfspeed
      jfspeed=JMA2.JJMASeries(mstart,prev_calculated,rates_total,0,SmPhase,Smooth,jmom,bar,false);

      //---- changing dimension of the indicator up to integer values
      jfspeed/=_Point;

      //---- uploading jfspeed into the indicator buffer
      ExtLineBuffer[bar]=jfspeed;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
