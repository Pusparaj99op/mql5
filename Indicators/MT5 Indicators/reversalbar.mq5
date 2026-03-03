//+------------------------------------------------------------------+
//|                                                  ReversalBar.mq5 |
//|                                                   vasbsm@mail.ru |
//+------------------------------------------------------------------+
#property copyright "zfs"
#property link      "vasbsm@mail.ru"

#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_width1  3
#property indicator_style1  STYLE_SOLID
#property indicator_label1  "ReversalBar"

color  ColorOf[3]={CLR_NONE,Red,Blue};
double ExtBuffer[];
double OpenBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
   SetIndexBuffer(0,OpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,CloseBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtBuffer,INDICATOR_COLOR_INDEX);
   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,3);
   for(int i=1;i<3;i++)
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,i,ColorOf[i]);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &Time[],const double &Open[],
                const double &High[],const double &Low[],const double &Close[],const long &TickVolume[],
                const long &Volume[],const int &Spread[])
  {
   int i;
   if(prev_calculated==0) i=0;
   else i=prev_calculated-1;
   while(i<rates_total)
     {
      OpenBuffer[i]=Open[i];
      HighBuffer[i]=High[i];
      LowBuffer[i]=Low[i];
      CloseBuffer[i]=Close[i];
      ExtBuffer[i]=0.0;
      if((i>2) && (High[i-1]>=High[i-2]) && 
         (Close[i-1]<(High[i-1]+Low[i-1])/2) && (Low[i]<Low[i-1]))ExtBuffer[i]=1.0;
      if((i>2) && (Low[i-1]<=Low[i-2]) && 
         (Close[i-1]>(High[i-1]+Low[i-1])/2) && (High[i]>High[i-1]))ExtBuffer[i]=2.0;
      i++;
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
