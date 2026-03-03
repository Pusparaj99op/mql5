//+------------------------------------------------------------------+
//|                                                       iMAFan.mq5 |
//|                                                          Integer |
//|                                                 http://dmffx.com |
//+------------------------------------------------------------------+
#property copyright "Integer"
#property link      "http://dmffx.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 512
#property indicator_plots   512
//--- plot Label1
#property indicator_label1  "Label1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
/*
  A colorful fan of moving averages.  
   Parameters:
   MAMethod - 明 method;
   MAPrice - 明 applied price;
   PeriodFrom - 明 minimal period;
   PeriodStep - 明 period step;
   Count - number of 明 (max value is 512);
   Colors - number of colors (max value 6);
   Color_1, Color_2, Color_3, Color_4, Color_5, Color_6 - colors.
  
   
*/

input ENUM_MA_METHOD       MAMethod       =  1;
input ENUM_APPLIED_PRICE   MAPrice        =  PRICE_CLOSE;
input int                  PeriodFrom     =  10;
input int                  PeriodStep     =  3;
input int                  Count          =  33;
input int                  Colors         =  6;
input color                Color_1        =  Red;
input color                Color_2        =  Yellow;
input color                Color_3        =  Lime;
input color                Color_4        =  Aqua;
input color                Color_5        =  Blue;
input color                Color_6        =  Magenta;

struct BUF
  {
   double            Buf[];
  };

int Handle[];
BUF B[];
color C[];
int _Count;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   _Count=(int)MathMin(Count,512);

   ArrayResize(B,_Count);
   ArrayResize(Handle,_Count);
   ArrayResize(C,6);
   C[0]=Color_1;
   C[1]=Color_2;
   C[2]=Color_3;
   C[3]=Color_4;
   C[4]=Color_5;
   C[5]=Color_6;
   int _Colors=Colors;
   if(_Colors>6)_Colors=6;
   ArrayResize(C,_Colors);
   for(int i=0;i<_Colors/2;i++)
     {
      color tmp=C[i];
      C[i]=C[_Colors-1-i];
      C[_Colors-1-i]=tmp;
     }

//--- COLORS
   int CI[][3];
   ArrayResize(CI,_Count);
   for(int i=0;i<_Count;i++)
     {
      CI[i][0]=(_Colors-1)*(i)/(_Count);
     }
   int z=0;
   for(int i=0;i<_Count-1;i++)
     {
      if(CI[i][0]!=CI[i+1][0])
        {
         for(int j=z;j<=i;j++)
           {
            CI[j][1]=j-z;
            CI[j][2]=i-z+1;
           }
         z=i+1;
        }
     }
   for(int j=z;j<_Count;j++)
     {
      CI[j][1]=j-z;
      CI[j][2]=_Count-z;
     }
//--- /COLORS

   for(int i=0;i<512;i++)
     {
      PlotIndexSetInteger(i,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(i,PLOT_LINE_COLOR,CLR_NONE);
     }

   for(int i=0;i<_Count;i++)
     {
      SetIndexBuffer(i,B[i].Buf,INDICATOR_DATA);
      int map=PeriodFrom+(_Count-1-i)*PeriodStep;
      PlotIndexSetString(i,PLOT_LABEL,"MA("+IntegerToString(map)+")");
      PlotIndexSetInteger(i,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(i,PLOT_LINE_STYLE,STYLE_SOLID);
      PlotIndexSetInteger(i,PLOT_COLOR_INDEXES,1);
      PlotIndexSetInteger(i,PLOT_LINE_COLOR,GetColor(1.0*CI[i][1]/CI[i][2],C[CI[i][0]],C[CI[i][0]+1]));
      PlotIndexSetInteger(i,PLOT_LINE_WIDTH,1);
      PlotIndexSetDouble(i,PLOT_EMPTY_VALUE,0);
      PlotIndexSetInteger(i,PLOT_DRAW_BEGIN,map);
      Handle[i]=iMA(NULL,PERIOD_CURRENT,map,0,MAMethod,MAPrice);
     }

//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   for(int i=0;i<_Count;i++)
     {
      ArrayInitialize(B[i].Buf,EMPTY_VALUE);
     }
   for(int i=0;i<_Count;i++)
     {
      PlotIndexSetInteger(i,PLOT_LINE_COLOR,CLR_NONE);
      PlotIndexSetInteger(i,PLOT_DRAW_TYPE,DRAW_NONE);
      IndicatorRelease(Handle[i]);
     }
   ArrayFree(B);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime  &time[],
                const double  &open[],
                const double  &high[],
                const double  &low[],
                const double  &close[],
                const long  &tick_volume[],
                const long  &volume[],
                const int  &spread[]
                )
  {
   static bool error=true;
   int start;
   if(prev_calculated==0)
     {
      error=true;
     }
   if(error)
     {
      start=0;
      error=false;
     }
   else
     {
      start=prev_calculated-1;
     }

   for(int i=0;i<Count;i++)
     {
      if(CopyBuffer(Handle[i],0,0,rates_total-start,B[i].Buf)==-1)
        {
         error=true;
         Alert("er");
         return(0);
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| GetColor                                                         |
//+------------------------------------------------------------------+
color GetColor(double aK,int Col1,double Col2)
  {
   int R1,G1,B1,R2,G2,B2;
   fGetRGB(R1,G1,B1,int(Col1));
   fGetRGB(R2,G2,B2,int(Col2));
   return(fRGB(int(R1+aK*(R2-R1)),int(G1+aK*(G2-G1)),int(B1+aK*(B2-B1))));
  }
//+------------------------------------------------------------------+
//| fGetRGB                                                          |
//+------------------------------------------------------------------+
void fGetRGB(int  &aR,int  &aG,int  &aB,int aCol)
  {
   aB=aCol/65536;
   aCol-=aB*65536;
   aG=aCol/256;
   aCol-=aG*256;
   aR=aCol;
  }
//+------------------------------------------------------------------+
//| fRGB                                                             |
//+------------------------------------------------------------------+
color fRGB(int aR,int aG,int aB)
  {
   return(color(aR+256*aG+65536*aB));
  }
//+------------------------------------------------------------------+
