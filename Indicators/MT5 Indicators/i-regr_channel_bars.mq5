//+------------------------------------------------------------------+
//|                                               i-Regr Channel.mq5 |
//|                                         Copyright © 2009, kharko |
//|                                                                  |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2009, kharko"
//---- link to the website of the author
#property link      ""
//---- indicator version
#property version   "1.40"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- 3 buffers are used for calculation and drawing the indicator
#property indicator_buffers 3
//---- 3 plots are used
#property indicator_plots   3
//+----------------------------------------------+
//|  Lower channel line drawing parameters       |
//+----------------------------------------------+
//---- drawing the indicator as a label
#property indicator_type1   DRAW_LINE
//---- lime color is used as the color of the indicator line
#property indicator_color1  Lime
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width1  1
//---- displaying the indicator label
#property indicator_label1  "i-Regression Channel Up"
//+----------------------------------------------+
//|  Upper channel line drawing parameters       |
//+----------------------------------------------+
//---- drawing the indicator as a label
#property indicator_type2   DRAW_LINE
//---- magenta color is used for the indicator line
#property indicator_color2  Magenta
//---- the indicator line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width2  1
//---- displaying the indicator label
#property indicator_label2  "i-Regression Channel Down"
//+----------------------------------------------+
//|  Middle channel line drawing parameters      |
//+----------------------------------------------+
//---- drawing the indicator as a label
#property indicator_type3   DRAW_LINE
//---- use gray color for the indicator line
#property indicator_color3  Gray
//---- the indicator line is a continuous curve
#property indicator_style3  STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width3  1
//---- displaying the indicator label
#property indicator_label4  "i-Regression Channel Middle"
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_      // Type of constant
  {
   PRICE_CLOSE_ = 1,     // Close
   PRICE_OPEN_,          // Open
   PRICE_HIGH_,          // High
   PRICE_LOW_,           // Low
   PRICE_MEDIAN_,        // Median Price (HL/2)
   PRICE_TYPICAL_,       // Typical Price (HLC/3)
   PRICE_WEIGHTED_,      // Weighted Close (HLCC/4)
   PRICE_SIMPLE,         // Simple Price (OC/2)
   PRICE_QUARTER_,       // Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  // TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   // TrendFollow_2 Price 
  };
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int degree=1;                             // Regression degree (changes from 1 to 61)
input double kstd=1.0;                          // Channel width
input int CountBars=40;                         // Amount of bars for the channel calculation
input Applied_price_ Applied_price=PRICE_CLOSE; // Applied price 
input int shift=0;                              // Horizontal shift of the channel
//+-----------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double FxBuffer[],SqhBuffer[],SqlBuffer[];
//----
double ai[][65],b[],c[],x[],y[],sx[];
double qq,mm,tt,sq;
double sum;
int ip,p,n,f;
int ii,jj,kk,ll,nn;
int i0=0,limit,degree_;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables
   min_rates_total=CountBars;
   degree_=degree;
   if(degree<1) degree_=1;
   if(degree>61) degree_=61;

//---- memory distribution for variables' arrays 
   ArrayResize(ai,degree_+2);
   ArrayResize(b,degree_+2);
   ArrayResize(c,degree_+2);
   ArrayResize(x,degree_+2);
   ArrayResize(y,degree_+2);
   ArrayResize(sx,2*(degree_+3));

//---- set SqhBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,SqhBuffer,INDICATOR_DATA);
//---- set the position, from which the indicator drawing starts
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,0);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- horizontal shift of the indicator
   PlotIndexSetInteger(0,PLOT_SHIFT,shift);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(SqhBuffer,true);

//---- set ExteBuffer[]  dynamic array as indicator buffer
   SetIndexBuffer(1,SqlBuffer,INDICATOR_DATA);
//---- set the position, from which the indicator drawing starts
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,0);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//---- horizontal shift of the indicator
   PlotIndexSetInteger(1,PLOT_SHIFT,shift);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(SqlBuffer,true);

//---- set FxBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(2,FxBuffer,INDICATOR_DATA);
//---- set the position, from which the indicator drawing starts
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,0);
//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
//---- horizontal shift of the indicator
   PlotIndexSetInteger(2,PLOT_SHIFT,shift);
//---- indexing the elements in buffers as timeseries   
   ArraySetAsSeries(FxBuffer,true);

//---- initializations of a variable for the indicator short name
   string shortname="i-Regr Channel";
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,     // number of bars in history at the current tick
                const int prev_calculated, // number of bars calculated at previous call
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
   if(rates_total<min_rates_total) return(0);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(time,true);

   if(rates_total==prev_calculated) return(rates_total);
   else limit=CountBars-1;

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

   int mi;
   ip=limit;
   p=ip;
   sx[1]=p+1;
   nn=degree_+1;

   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      //---- set the position, from which the indicator drawing starts
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,rates_total-p-1);
      PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,rates_total-p-1);
      PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,rates_total-p-1);
     }

//---- sx
   for(mi=1;mi<=nn*2-2;mi++) // mathematical expression - for all mi from 1 up to nn*2-2 
     {
      sum=0;
      for(n=i0;n<=i0+p;n++)
        {
         sum+=MathPow(n,mi);
        }
      sx[mi+1]=sum;
     }

//---- syx
   for(mi=1;mi<=nn;mi++)
     {
      sum=0.00000;
      for(n=i0;n<=i0+p;n++)
        {

         if(mi==1) sum+=PriceSeries(Applied_price,n,open,low,high,close);
         else      sum+=PriceSeries(Applied_price,n,open,low,high,close)*MathPow(n,mi-1);
        }
      b[mi]=sum;
     }

///---- Matrix
   for(jj=1;jj<=nn;jj++)
      for(ii=1; ii<=nn; ii++)
        {
         kk=ii+jj-1;
         ai[ii][jj]=sx[kk];
        }

//---- Gauss
   for(kk=1; kk<=nn-1; kk++)
     {
      ll=0;
      mm=0;

      for(ii=kk; ii<=nn; ii++)
         if(MathAbs(ai[ii][kk])>mm)
           {
            mm=MathAbs(ai[ii][kk]);
            ll=ii;
           }

      if(ll==0) return(0);

      if(ll!=kk)
        {
         for(jj=1; jj<=nn; jj++)
           {
            tt=ai[kk][jj];
            ai[kk][jj]=ai[ll][jj];
            ai[ll][jj]=tt;
           }

         tt=b[kk];
         b[kk]=b[ll];
         b[ll]=tt;
        }

      for(ii=kk+1;ii<=nn;ii++)
        {
         qq=ai[ii][kk]/ai[kk][kk];

         for(jj=1;jj<=nn;jj++)
           {
            if(jj==kk) ai[ii][jj]=0;
            else       ai[ii][jj]=ai[ii][jj]-qq*ai[kk][jj];
           }

         b[ii]=b[ii]-qq*b[kk];
        }
     }

   x[nn]=b[nn]/ai[nn][nn];

   for(ii=nn-1;ii>=1;ii--)
     {
      tt=0;
      for(jj=1;jj<=nn-ii;jj++)
        {
         tt=tt+ai[ii][ii+jj]*x[ii+jj];
         x[ii]=(1/ai[ii][ii])*(b[ii]-tt);
        }
     }

//----
   for(n=i0;n<=i0+p;n++)
     {
      sum=0;
      for(kk=1;kk<=degree_;kk++) sum+=x[kk+1]*MathPow(n,kk);
      FxBuffer[n]=x[1]+sum;
     }

//----
   sq=0.0;
   for(n=i0;n<=i0+p;n++)
      sq+=MathPow(PriceSeries(Applied_price,n,open,low,high,close)-FxBuffer[n],2);

   sq=MathSqrt(sq/(p+1))*kstd;

   for(n=i0+p;n<=rates_total-1;n++)
     {
      FxBuffer[n]=0.0;
      SqhBuffer[n]=0.0;
      SqlBuffer[n]=0.0;
     }

   for(n=i0;n<=i0+p;n++)
     {
      if(FxBuffer[n])
        {
         SqhBuffer[n]=FxBuffer[n]+sq;
         SqlBuffer[n]=FxBuffer[n]-sq;
        }
      else
        {
         SqhBuffer[n]=0.0;
         SqlBuffer[n]=0.0;
        }
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+   
//| Getting values of a price series                                 |
//+------------------------------------------------------------------+ 
double PriceSeries(uint applied_price, // price constant
                   uint   bar,         // index of shift relative to the current bar for a specified number of periods back or forward
                   const double &Open[],
                   const double &Low[],
                   const double &High[],
                   const double &Close[])
  {
//----
   switch(applied_price)
     {
      //---- price constants from the ENUM_APPLIED_PRICE enumeration
      case  PRICE_CLOSE: return(Close[bar]);
      case  PRICE_OPEN: return(Open [bar]);
      case  PRICE_HIGH: return(High [bar]);
      case  PRICE_LOW: return(Low[bar]);
      case  PRICE_MEDIAN: return((High[bar]+Low[bar])/2.0);
      case  PRICE_TYPICAL: return((Close[bar]+High[bar]+Low[bar])/3.0);
      case  PRICE_WEIGHTED: return((2*Close[bar]+High[bar]+Low[bar])/4.0);

      //----                            
      case  8: return((Open[bar] + Close[bar])/2.0);
      case  9: return((Open[bar] + Close[bar] + High[bar] + Low[bar])/4.0);
      //----                                
      case 10:
        {
         if(Close[bar]>Open[bar])return(High[bar]);
         else
           {
            if(Close[bar]<Open[bar])
               return(Low[bar]);
            else return(Close[bar]);
           }
        }
      //----         
      case 11:
        {
         if(Close[bar]>Open[bar])return((High[bar]+Close[bar])/2.0);
         else
           {
            if(Close[bar]<Open[bar])
               return((Low[bar]+Close[bar])/2.0);
            else return(Close[bar]);
           }
         break;
        }
      //----
      default: return(Close[bar]);
     }
//----
  }
//+------------------------------------------------------------------+
