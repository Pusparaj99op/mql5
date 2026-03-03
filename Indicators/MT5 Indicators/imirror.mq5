#property copyright "2014, Timur Gatin"
#property link      "https://login.mql5.com/ru/users/gt788"
#property version   "2.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   1
//--- plot Label1
#property indicator_label1  "iMirror"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrLimeGreen,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input color Up=clrLimeGreen;      //The color of the bullish candlestick
input color Down=clrRed;          //The color of the bearish candlestick
input color Back=clrMidnightBlue; //background color
//--- indicator buffers
double         open[];
double         high[];
double         low[];
double         close[];
double         colors[];

long chart[6]; //an array for storing chart parameters

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,open,INDICATOR_DATA);
   SetIndexBuffer(1,high,INDICATOR_DATA);
   SetIndexBuffer(2,low,INDICATOR_DATA);
   SetIndexBuffer(3,close,INDICATOR_DATA);
   SetIndexBuffer(4,colors,INDICATOR_COLOR_INDEX);
//--- track the mouse
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1);
//--- save chart parameters in an array
//--- chart on top   
   chart[0]=ChartGetInteger(0,CHART_FOREGROUND); 
//--- color of bullish candlestick borders   
   chart[1]=ChartGetInteger(0,CHART_COLOR_CHART_UP); 
//--- color of bearish candlestick borders   
   chart[2]=ChartGetInteger(0,CHART_COLOR_CHART_DOWN); 
//--- chart type   
   chart[3]=ChartGetInteger(0,CHART_COLOR_CHART_LINE); 
//--- bullish candlestick fill color   
   chart[4]=ChartGetInteger(0,CHART_COLOR_CANDLE_BULL); 
//--- bearish candlestick fill color   
   chart[5]=ChartGetInteger(0,CHART_COLOR_CANDLE_BEAR); 
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- disable mouse tracking   
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,0); 
//--- restore the source parameters of the chart from an arrow
   ChartSetInteger(0,CHART_FOREGROUND,chart[0]);
   ChartSetInteger(0,CHART_COLOR_CHART_UP,chart[1]);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,chart[2]);
   ChartSetInteger(0,CHART_COLOR_CHART_LINE,chart[3]);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,chart[4]);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,chart[5]);
//--- forced chart redrawing   
   ChartRedraw(); 
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//--- handle ticks in OnChartEvent
   EventChartCustom(0,1387,0,0,NULL);
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//--- process only required events
   if(id!=CHARTEVENT_CHART_CHANGE && id!=CHARTEVENT_CUSTOM+1387 && 
      id!=CHARTEVENT_CLICK && id!=CHARTEVENT_MOUSE_MOVE) return;
//--- a static flag for a clock on the indicator
   static bool click_flag=false; 
//--- a static variable for storing timer events
   static uint sdelay=0;
//--- Do not handle the movement of the cursor, if the indicator is in the foreground or a pause of less than 50 ms
   if(id==CHARTEVENT_MOUSE_MOVE && (click_flag || GetTickCount()-sdelay<50)) return;
//--- an array for the prices   
   static double O[],H[],L[],C[];
//--- an array for the time
   static datetime T[];
//--- static variables for the left and the right bar
   static int sleft=0, sright=0;
//--- a variable for storing the max and min sum
   static double minimax=0;
//--- the number of the leftmost bar in the series
   int first=(int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR)+1; 
//--- bars on the chart
   int window=(int)ChartGetInteger(0,CHART_VISIBLE_BARS); 
//--- total bars om the symbol period
   int bars=Bars(_Symbol,_Period); 
//--- the index of the leftmost bar
   int left=bars-first; 
//--- the index of the rightmost bar
   int right=left+window; 
//--- check
   if(right>bars) return; 
//--- handle data if they have changed
   if(left!=sleft || right!=sright || right==bars)
     {
      //--- start of copying
      int start=first-window;
      //--- a local variable for the left bar
      int lleft=left;
      //--- if only the last bar has changed
      if(left==sleft && right==sright)
        {
         //--- one cell will be copied
         window=1;
         //--- the loop will be for one bar
         lleft=right-1;
        }
      //--- get price data
      if(CopyHigh(_Symbol,_Period,start,window,H)!=window)  return;
      if(CopyLow(_Symbol,_Period,start,window,L)!=window)   return;
      if(CopyClose(_Symbol,_Period,start,window,C)!=window) return;
      //--- remember extreme bars
      sright=right;
      sleft=left;
      //--- if more than one bar to handle
      if(window>1)
        {
         //--- get the open price
         if(CopyOpen(_Symbol,_Period,start,window,O)!=window) return; 
         //--- get the open time
         if(CopyTime(_Symbol,_Period,start,window,T)!=window) return; 
         //--- search for the window maximum
         double max=H[ArrayMaximum(H)]; 
         //--- search for the window minimum
         double min=L[ArrayMinimum(L)]; 
         //--- the sum of max and min
         minimax=max+min; 
        }
   
      //--- fill in indicator buffers
      for(int i=lleft;i<right;i++)
        {
         if(window>1)
           {
            open[i]=minimax-O[i-lleft];
           }
         high[i]=minimax-L[i-lleft];
         low[i]=minimax-H[i-lleft];
         close[i]=minimax-C[i-lleft];
         //--- defining the candlestick color
         //--- 0 cell for the bullish candlestick color
         if(open[i]<close[i]) colors[i]=0; 
         //--- 1 for bearish
         else colors[i]=1; 
        }
     }
//--- handling the mouse
   if(id==CHARTEVENT_MOUSE_MOVE || id==CHARTEVENT_CLICK)
     {
      //--- remember the timer value
      sdelay=GetTickCount();
      //--- the X coordinate of the cursor
      int x=(int)lparam; 
      //--- the Y coordinate of the cursor
      int y=(int)dparam; 
      //--- subwindiw number
      int sub=0; 
      //--- a variable for the price
      double p=0; 
      //--- a variable for the time
      datetime t=0; 
      //--- time determining error
      datetime dt=PeriodSeconds(); 
      //--- getting a price from coordinates
      ChartXYToTimePrice(0,x,y,sub,t,p); 
      //--- a flag of cursor on the indicator
      bool color_flag=false; 
      //--- checking if the cursor is on the indicator
      for(int i=left;i<right;i++)
        {
         if(t>T[i-left]-dt && t<T[i-left]+dt && p<high[i] && p>low[i])
           {
            color_flag=true;
            break;
           }
        }
      //--- a click on the indicator
      if(color_flag && id==CHARTEVENT_CLICK)
        {
         if(click_flag) click_flag=false;
         else click_flag=true;
        }
      //--- processing color of the indicator and chart
      static bool flag=true;
      if((color_flag || click_flag) && !flag)
        {
         flag=true;
         //--- changing indicator's cell 0 color
         PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,Up); 
         //--- changing indicator's cell 1 color
         PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,Down); 
         //--- changing chart colors
         ChartSetInteger(0,CHART_FOREGROUND,0);
         ChartSetInteger(0,CHART_COLOR_CHART_UP,Back);
         ChartSetInteger(0,CHART_COLOR_CHART_DOWN,Back);
         ChartSetInteger(0,CHART_COLOR_CHART_LINE,Back);
         ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,Back);
         ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,Back);
        }
      if(!color_flag && !click_flag && flag)
        {
         flag=false;
         PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,Back);
         PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,Back);
         ChartSetInteger(0,CHART_FOREGROUND,1);
         ChartSetInteger(0,CHART_COLOR_CHART_UP,Up);
         ChartSetInteger(0,CHART_COLOR_CHART_DOWN,Down);
         ChartSetInteger(0,CHART_COLOR_CHART_LINE,Up);
         ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,Up);
         ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,Down);
        }
     }
   ChartRedraw();
  }
//+------------------------------------------------------------------+
