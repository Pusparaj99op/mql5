//+------------------------------------------------------------------+
//|                                              Round price DOC.mq5 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"
#property version   "1.00"

//
//
//
//
//

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   7

#property indicator_type1   DRAW_LINE
#property indicator_color1  Gold
#property indicator_type2   DRAW_LINE
#property indicator_color2  DeepSkyBlue
#property indicator_type3   DRAW_LINE
#property indicator_color3  DeepSkyBlue
#property indicator_type4   DRAW_LINE
#property indicator_color4  DeepSkyBlue
#property indicator_type5   DRAW_LINE
#property indicator_color5  PaleVioletRed
#property indicator_type6   DRAW_LINE
#property indicator_color6  PaleVioletRed
#property indicator_type7   DRAW_LINE
#property indicator_color7  PaleVioletRed

//
//
//
//
//

input int                T3Period   = 89;          // T3 Calculation period
input double             T3Hot      = 0.7;         // T3 hot value
input bool               T3Original = false;       // T3 original Tillson calculation?
input ENUM_APPLIED_PRICE T3Price    = PRICE_CLOSE; // T3 price to use
input int                Delta1     =  89;         // Distance in points for first band
input int                Delta2     = 144;         // Distance in points for second band
input int                Delta3     = 233;         // Distance in points for third band

//
//
//
//
//
//

double t3[];
double t3Up1[];
double t3Up2[];
double t3Up3[];
double t3Dn1[];
double t3Dn2[];
double t3Dn3[];

double c1,c2,c3,c4,t3Alpha;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer( 0,t3   ,INDICATOR_DATA);
   SetIndexBuffer( 1,t3Up1,INDICATOR_DATA);
   SetIndexBuffer( 2,t3Up2,INDICATOR_DATA);
   SetIndexBuffer( 3,t3Up3,INDICATOR_DATA);
   SetIndexBuffer( 4,t3Dn1,INDICATOR_DATA);
   SetIndexBuffer( 5,t3Dn2,INDICATOR_DATA);
   SetIndexBuffer( 6,t3Dn3,INDICATOR_DATA);

   PlotIndexSetString(0,PLOT_LABEL,"T3");
   for (int i=1; i<4; i++)      
   {
      PlotIndexSetString(i  ,PLOT_LABEL,"T3 upper band "+(string)i);
      PlotIndexSetString(i+3,PLOT_LABEL,"T3 lower band "+(string)i);
   }      
      
   //
   //
   //
   //
   //
   
   double a  = MathMax(MathMin(T3Hot,1),0.0001);;
          c1 = -a*a*a;
          c2 =  3*(a*a+a*a*a);
          c3 = -3*(2*a*a+a+a*a*a);
          c4 = 1+3*a+a*a*a+3*a*a;
          double t3period  = T3Period; 
               if (!T3Original) t3period = 1.0 + (t3period-1.0)/2.0;
               t3Alpha = 2.0/(1.0 + t3period);
            
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
{

   //
   //
   //
   //
   //
      
      for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
      {
         double price;
         switch (T3Price)
         {
            case PRICE_CLOSE    : price = Close[i]; break;
            case PRICE_OPEN     : price = Open[i];  break;
            case PRICE_HIGH     : price = High[i];  break;
            case PRICE_LOW      : price = Low[i];   break;
            case PRICE_MEDIAN   : price = (High[i]+Low[i])/2.0; break;
            case PRICE_TYPICAL  : price = (High[i]+Low[i]+Close[i])/3.0; break;
            case PRICE_WEIGHTED : price = (High[i]+Low[i]+Close[i]+Close[i])/4.0; break;
            default : price = 0;
         }            
         
         t3[i]    = calcT3(price,i,rates_total);
         t3Up1[i] = t3[i]+Delta1*_Point;
         t3Up2[i] = t3[i]+Delta2*_Point;
         t3Up3[i] = t3[i]+Delta3*_Point;
         t3Dn1[i] = t3[i]-Delta1*_Point;
         t3Dn2[i] = t3[i]-Delta2*_Point;
         t3Dn3[i] = t3[i]-Delta3*_Point;
      }
   
   //
   //
   //
   //
   //
   
   return(rates_total);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double t3Values[][6];
double calcT3(double price, int r, int bars, int s=0)
{
   if (ArrayRange(t3Values,0)!=bars) ArrayResize(t3Values,bars);
      
   //
   //
   //
   //
   //
   //

   if (r < 2)
      {
         t3Values[r][s+0] = price;
         t3Values[r][s+1] = price;
         t3Values[r][s+2] = price;
         t3Values[r][s+3] = price;
         t3Values[r][s+4] = price;
         t3Values[r][s+5] = price;
      }
   else
      {
         t3Values[r][s+0] = t3Values[r-1][s+0]+t3Alpha*(price           -t3Values[r-1][s+0]);
         t3Values[r][s+1] = t3Values[r-1][s+1]+t3Alpha*(t3Values[r][s+0]-t3Values[r-1][s+1]);
         t3Values[r][s+2] = t3Values[r-1][s+2]+t3Alpha*(t3Values[r][s+1]-t3Values[r-1][s+2]);
         t3Values[r][s+3] = t3Values[r-1][s+3]+t3Alpha*(t3Values[r][s+2]-t3Values[r-1][s+3]);
         t3Values[r][s+4] = t3Values[r-1][s+4]+t3Alpha*(t3Values[r][s+3]-t3Values[r-1][s+4]);
         t3Values[r][s+5] = t3Values[r-1][s+5]+t3Alpha*(t3Values[r][s+4]-t3Values[r-1][s+5]);
      }
   return(c1*t3Values[r][s+5] + c2*t3Values[r][s+4] + c3*t3Values[r][s+3] + c4*t3Values[r][s+2]);
}