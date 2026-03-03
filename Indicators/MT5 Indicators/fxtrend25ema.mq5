//+------------------------------------------------------------------+
//|                                      FxTrend 25EMA Indicator.mq5 |
//|                                      Jose Luis Gongora Fernandez |
//|                                        http://www.forexploit.com |
//|                                               tw!:  @JossGongora |
//+------------------------------------------------------------------+
#property copyright "dec.-2013, Jose Luis Gongora Fernandez aka. jossfx"
#property link      "http://www.forexploit.com"
#property version   "1.0"

//---- indicator settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Lime,Red,Silver
#property indicator_width1  1
#property indicator_label1  "FxTrend 25EMA"
#define DATA_LIMIT 24

//--- handles for MAs
int    iMA_handle25EMA;

//--- indicator buffers
double iND_buff[];
double iMA_buff25EMA[];

//--- color buffer
double iND_color[];

//--- others
int last_side;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- indicator buffers mapping
   SetIndexBuffer(0,iND_buff,INDICATOR_DATA);
   SetIndexBuffer(1,iND_color,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,iMA_buff25EMA,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,24);
//--- name for DataWindow 
   IndicatorSetString(INDICATOR_SHORTNAME,"FxTrend 25EMA");
//--- get handles
   iMA_handle25EMA=iMA(NULL,0,25,0,MODE_EMA,PRICE_CLOSE);
//--- initialization   
   last_side=0;

//---- initialization done
  }
//+------------------------------------------------------------------+
//|  FxTrend 25EMA Indicator  - Forexploit team                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {

//--- check for rates total
   if(rates_total<=DATA_LIMIT) return(0);

//--- not all data may be calculated
   int calculated=BarsCalculated(iMA_handle25EMA);
   if(calculated<rates_total)
     {
      Print("Not all data of iMA_handle25EMA is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>=rates_total || prev_calculated<=0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
     }
//--- get 25EMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(iMA_handle25EMA,0,0,to_copy,iMA_buff25EMA)<=0)
     {
      Print("Getting 25EMA buffer is failed! Error",GetLastError());
      return(0);
     }

   int i,limit;
   if(prev_calculated<=DATA_LIMIT)
     {
      for(i=0;i<DATA_LIMIT;i++)
         iND_buff[i]=0.0;
      limit=DATA_LIMIT;
     }
   else limit=prev_calculated-1;

//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {

      if(Close[i]>iMA_buff25EMA[i])
         last_side=1;
      else if(Close[i]<iMA_buff25EMA[i])
         last_side=-1;

/** hunting the kiddie
                     i    
                     I_-_ 
                     I(")_____.
                    <\.v,----~
                    :/_(
                    ( ,)
                     uU    `-.---U`=
                     lL      (~~/>
                     
         **/

      iND_buff[i]=iMA_buff25EMA[i]-iMA_buff25EMA[i-2];

      if((Close[i]>=iMA_buff25EMA[i]) && (iMA_buff25EMA[i]-iMA_buff25EMA[i-2])>=0 && last_side==1)
        {
         iND_color[i]=0.0;
        }
      else if((Close[i]<=iMA_buff25EMA[i]) && (iMA_buff25EMA[i]-iMA_buff25EMA[i-2])<=0 && last_side==-1)
        {
         iND_color[i]=1.0;

        }
      else
        {
         iND_color[i]=2.0;
        }

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
