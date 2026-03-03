//+------------------------------------------------------------------+
//|                                              DRAW_COLOR_LINE.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#property description "This indicator is a demo of DRAW_COLOR_LINE drawing style"
#property description "It draws a line with different colors using the Close price"
#property description "The line width, style and color are changed randomly after N ticks."

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot ColorLine
#property indicator_label1  "ColorLine"
#property indicator_type1   DRAW_COLOR_LINE
//--- 5 colors
#property indicator_color1  clrRed,clrBlue,clrGreen,clrOrange,clrDeepPink // (it's possible to specify up to 64 colors)
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      N=5;           // Number of ticks to change properties
input int      Length=20;     // Same color interval (in bars)
int            line_colors=5; // Number of colors - see #property indicator_color1
//--- plotting buffer
double         ColorLineBuffer[];
//--- color buffer
double         ColorLineColors[];

//--- colors array
color colors[]={clrRed,clrBlue,clrGreen,clrChocolate,clrMagenta,clrDodgerBlue,clrGoldenrod};
//--- line styles array
ENUM_LINE_STYLE styles[]={STYLE_SOLID,STYLE_DASH,STYLE_DOT,STYLE_DASHDOT,STYLE_DASHDOTDOT};
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ColorLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorLineColors,INDICATOR_COLOR_INDEX);
//--- set random seed
   MathSrand(GetTickCount());
//---
   return(INIT_SUCCEEDED);
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
   static int ticks=0;
//--- count the ticks to change style, color and width
   ticks++;
//--- if ticks>=N
   if(ticks>=N)
     {
      //--- change line properties
      ChangeLineAppearance();
      //--- change colors
      ChangeColors(colors,5);
      //--- set ticks counter to 0
      ticks=0;
     }

//--- calculation of indicator values
   for(int i=0;i<rates_total;i++)
     {
      //--- set value
      ColorLineBuffer[i]=close[i];
      //--- set color index (randomly)
      int color_index=i%(5*Length);
      color_index=color_index/Length;
      //--- the bar will have the color_index color
      ColorLineColors[i]=color_index;
     }

//--- return prev_calculated for the next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  Changes the colors                                              |
//+------------------------------------------------------------------+
void  ChangeColors(color  &cols[],int plot_colors)
  {
//--- number of colors
   int size=ArraySize(cols);
//--- 
   string comm=ChartGetString(0,CHART_COMMENT)+"\r\n\r\n";
//--- set new color index randomly
   for(int plot_color_ind=0;plot_color_ind<plot_colors;plot_color_ind++)
     {
      //--- get random number
      int number=MathRand();
      //--- get index as remainder of division by size
      int i=number%size;
      //--- set color as PLOT_LINE_COLOR property
      PlotIndexSetInteger(0,                    //  plotting style index
                          PLOT_LINE_COLOR,      //  property identifier
                          plot_color_ind,       //  color index
                          cols[i]);             //  new color
      //--- add colors to comment
      comm=comm+StringFormat("LineColorIndex[%d]=%s \r\n",plot_color_ind,ColorToString(cols[i],true));
      ChartSetString(0,CHART_COMMENT,comm);
     }
//---
  }
//+------------------------------------------------------------------+
//| Changes the color of a line                                      |
//+------------------------------------------------------------------+
void ChangeLineAppearance()
  {
//--- comment
   string comm="";
//--- change line width
   int number=MathRand();
//--- calc width
   int width=number%5; // width vary from 0 to 4
//--- set witdth as PLOT_LINE_WIDTH property
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,width);
//--- add line width
   comm=comm+" Width="+IntegerToString(width);

//--- change line style
   number=MathRand();
//--- styles
   int size=ArraySize(styles);
//--- style index
   int style_index=number%size;
//--- set color as PLOT_LINE_STYLE property
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,styles[style_index]);
//--- add to comment
   comm=EnumToString(styles[style_index])+", "+comm;   
//--- print comment
   Comment(comm);
  }
//+------------------------------------------------------------------+
