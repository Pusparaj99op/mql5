//+------------------------------------------------------------------+
//|                                                 RSI_Bands_v1.mq4 |
//|                                  Copyright 2020, Fabio Cavalloni |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Fabio Cavalloni"
#property link      "https://www.mql5.com/en/users/kava93"
#property version   "1.00"
#property indicator_buffers 6
#property indicator_plots 6
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100

input int         iRSIPeriod              = 14;    // RSI periods
input int         iBandsPeriod            = 34;    // BB periods
input double      iBandsDeviation         = 2.5;   // BB deviation

double ExtRSI[], ExtUp[], ExtDn[], ExtMd[], ExtBuyArrow[], ExtSellArrow[];
double RSI[], BBUp[], BBMd[], BBDn[];
int    RSI_Handle,
       BB_Handle;

int OnInit() {
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI("+string(iRSIPeriod)+") Bands("+string(iBandsPeriod)+","+DoubleToString(iBandsDeviation,2)+")");
   
   SetIndexBuffer(0,ExtRSI);
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,clrDodgerBlue);
   SetIndexLabel(0,"RSI");
   SetIndexBuffer(1,ExtUp);
   SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,clrBlack);
   SetIndexLabel(1,"Upper band");
   SetIndexBuffer(2,ExtDn);
   SetIndexStyle(2,DRAW_LINE,STYLE_DOT,1,clrBlack);
   SetIndexLabel(2,"Lower band");
   SetIndexBuffer(3,ExtMd);
   SetIndexStyle(3,DRAW_LINE,STYLE_DOT,1,clrBlack);
   SetIndexLabel(3,"Middle band");
   SetIndexBuffer(4,ExtBuyArrow);
   SetIndexStyle(4,DRAW_ARROW,0,1,clrGreen);
   PlotIndexSetInteger(4,PLOT_ARROW,225);
   SetIndexLabel(4,"Buy arrow");
   SetIndexBuffer(5,ExtSellArrow);
   SetIndexStyle(5,DRAW_ARROW,0,1,clrRed);
   PlotIndexSetInteger(5,PLOT_ARROW,226);
   SetIndexLabel(5,"Sell arrow");
   
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,iRSIPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,iRSIPeriod+iBandsPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,iRSIPeriod+iBandsPeriod);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,iRSIPeriod+iBandsPeriod);
   
   ArraySetAsSeries(RSI,true);
   ArraySetAsSeries(BBUp,true);
   ArraySetAsSeries(BBDn,true);
   ArraySetAsSeries(BBMd,true);
   
   ArraySetAsSeries(ExtRSI,true);
   ArraySetAsSeries(ExtUp,true);
   ArraySetAsSeries(ExtDn,true);
   ArraySetAsSeries(ExtMd,true);
   ArraySetAsSeries(ExtBuyArrow,true);
   ArraySetAsSeries(ExtSellArrow,true);
   
   RSI_Handle = iRSI(NULL,0,iRSIPeriod,PRICE_CLOSE);
   BB_Handle  = iBands(NULL,0,iBandsPeriod,0,iBandsDeviation,RSI_Handle);
   
   return(INIT_SUCCEEDED);
}
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   if( !SymbolIsSynchronized(_Symbol) || rates_total<0 || !IndicatorsOk(rates_total) ) return(0);
   
   int limit = MathMin(rates_total-prev_calculated+1,rates_total-1);
   if( !FillArrayFromBuffer(RSI,0,RSI_Handle,limit,0) ) return(rates_total);
   if( !FillArrayFromBuffer(BBMd,0,BB_Handle,limit,0) ) return(rates_total);
   if( !FillArrayFromBuffer(BBUp,0,BB_Handle,limit,1) ) return(rates_total);
   if( !FillArrayFromBuffer(BBDn,0,BB_Handle,limit,2) ) return(rates_total);
   for( int i=0; i<limit; i++ ) {
      ExtRSI[i] = RSI[i];
   }
   for( int i=0; i<limit; i++ ) {
      ExtUp[i]          = BBUp[i];
      ExtMd[i]          = BBMd[i];
      ExtDn[i]          = BBDn[i];
      ExtBuyArrow[i]    = EMPTY_VALUE;
      ExtSellArrow[i]   = EMPTY_VALUE;
   }
   for( int i=1; i<limit; i++ ) {
      bool BuyArrow  = ExtRSI[i]>ExtDn[i] && ExtRSI[i+1]<=ExtDn[i+1];
      bool SellArrow = ExtRSI[i]<ExtUp[i] && ExtRSI[i+1]>=ExtUp[i+1];
      
      if( BuyArrow )  ExtBuyArrow[i]  = ExtDn[i];
      if( SellArrow ) ExtSellArrow[i] = ExtUp[i];
   } 
   return(rates_total);
}

bool IndicatorsOk(int rates) {
   if( BarsCalculated(RSI_Handle)<rates ) return(false);
   if( BarsCalculated(BB_Handle)<rates ) return(false);
   return(true);
}

bool FillArrayFromBuffer(double &values[],   // indicator buffer of indicator values
                         int shift,          // shift
                         int ind_handle,     // handle of the indicator
                         int amount,         // number of copied values
                         int buffer          // buffer number
                        ) {
   ResetLastError();
   if(CopyBuffer(ind_handle,buffer,-shift,amount,values)<0)
     {
      PrintFormat("Failed to copy data from the indicator handle, error code %d",GetLastError());
      return(false);
     }
   return(true);
}

void SetIndexStyle(int index,
                       int type,
                       int style=1,
                       int width=1,
                       color clr=clrNONE) {
   if(width>-1)
      PlotIndexSetInteger(index,PLOT_LINE_WIDTH,width);
   if(clr!=CLR_NONE)
      PlotIndexSetInteger(index,PLOT_LINE_COLOR,clr);
   switch(type)
     {
      case 0:
         PlotIndexSetInteger(index,PLOT_DRAW_TYPE,DRAW_LINE); break;
      case 1:
         PlotIndexSetInteger(index,PLOT_DRAW_TYPE,DRAW_SECTION); break;
      case 2:
         PlotIndexSetInteger(index,PLOT_DRAW_TYPE,DRAW_HISTOGRAM); break;
      case 3:
         PlotIndexSetInteger(index,PLOT_DRAW_TYPE,DRAW_ARROW); break;
      case 4:
         PlotIndexSetInteger(index,PLOT_DRAW_TYPE,DRAW_ZIGZAG); break;
      case 12:
         PlotIndexSetInteger(index,PLOT_DRAW_TYPE,DRAW_NONE); break;

      default:
         PlotIndexSetInteger(index,PLOT_DRAW_TYPE,DRAW_LINE);
     }
   switch(style)
     {
      case STYLE_SOLID:
         PlotIndexSetInteger(index,PLOT_LINE_STYLE,STYLE_SOLID); break;
      case STYLE_DASH:
         PlotIndexSetInteger(index,PLOT_LINE_STYLE,STYLE_DASH); break;
      case STYLE_DOT:
         PlotIndexSetInteger(index,PLOT_LINE_STYLE,STYLE_DOT); break;
      case STYLE_DASHDOT:
         PlotIndexSetInteger(index,PLOT_LINE_STYLE,STYLE_DASHDOT); break;
      case STYLE_DASHDOTDOT:
         PlotIndexSetInteger(index,PLOT_LINE_STYLE,STYLE_DASHDOTDOT); break;

      default: return;
     }
} 
    
void SetIndexLabel(int index, string label) {
   PlotIndexSetString(index,PLOT_LABEL,label);
}
