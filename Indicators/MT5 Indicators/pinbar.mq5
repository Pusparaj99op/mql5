//+------------------------------------------------------------------+
//|                                                       PinBar.mq5 |
//|                      Copyright 2013, Andrei PunkBASSter Shpilev. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, PunkBASSter."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot OpenBuffer
#property indicator_label1  "OpenBuffer"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot StopBuffer
#property indicator_label2  "StopBuffer"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
//Minimal bar spread
input int      MinBarSize=200;//MinimalBarSpread(in pips)
//Offset for open price and stop loss
input int      PriceOffset=50;//Offset (in pips)
//BarRatio = Spread/Body
input double   BarRatio=2.2;//Minimal Spread/Body value
//TailRatio = BiggerTail/RestBarPart
input double   TailRatio=1.3;//Minimal BiggerTail/(Spread-BiggerTail) value
//Bear pinbar must have bear body, bull pinbar must have a bull body
input bool     UseBodyDirection=false;
//Bar is divided into 3 equal parts. Bear pinbar must close in the lower part, bull pin bar -- in the upper one
input bool     UseCloseThirds=true;
//Bear(bull) pinbar must be higher(lower) then several previous. Can be zero to disable extremum check 
input int      ExtremumOfBars=10;

//--- indicator buffers
double         OpenBuffer[];
double         StopBuffer[];
datetime       prevtime=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,OpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,StopBuffer,INDICATOR_DATA);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,115);
   PlotIndexSetInteger(1,PLOT_ARROW,115);
   
//---
   return(INIT_SUCCEEDED);
  }
  

enum ENUM_CLOSE_THIRDS
{
   UNKNOWN_PART,
   UPPER_PART,
   MIDDLE_PART,
   LOWER_PART,   
};

enum ENUM_BODY_DIRECTIONS
{
   BULL,
   BEAR,
   ZERO,
};

//+------------------------------------------------------------------+
//| Body direction check                                             |
//+------------------------------------------------------------------+
ENUM_BODY_DIRECTIONS BodyDirection(double open, double close)
{
   if(UseBodyDirection)
   {
      if(open<close)return(BULL);
      if(open>close)return(BEAR);
   }
   return(ZERO);
}


//+------------------------------------------------------------------+
//| Maximum check                                                    |
//+------------------------------------------------------------------+
bool CheckLocalMax(int idx,const double &high[],int extremumofbars)
{
   for(int i=idx-1; i>=idx-extremumofbars; i--)
      if(high[i]>high[idx])return(false);
      
   return(true);
}


//+------------------------------------------------------------------+
//| Minimum check                                                    |
//+------------------------------------------------------------------+
bool CheckLocalMin(int idx,const double &low[],int extremumofbars)
{
   for(int i=idx-1; i>=idx-extremumofbars; i--)
      if(low[i]<low[idx])return(false);
   
   return(true);
}


//+-------------------------------------------------+
//| Returns the number of a third of a bar where    |
//| its close price is located starting from the    |
//| high price.                                     |
//+-------------------------------------------------+
ENUM_CLOSE_THIRDS CloseThird(double high, double low, double close)
{
   if(UseCloseThirds)
   {
      double third = NormalizeDouble((high-low)/3,Digits());
      double b12 = high-third;
      double b23 = low +third;
      if(close>b12)               return(UPPER_PART);//upper part
      if(close<=b12 && close>=b23)return(MIDDLE_PART);//middle
      if(close<b23)               return(LOWER_PART);//lower part
   }
   return(UNKNOWN_PART);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int total,
                const int calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---
   for(int i=calculated>ExtremumOfBars?calculated-1:ExtremumOfBars; i<total-1; i++)
   {
      OpenBuffer[i]=0;
      StopBuffer[i]=0;
      double Spread=high[i]-low[i];
      if(Spread<MinBarSize*Point())continue;//not a pin bar, check next
         double Body=MathAbs(open[i]-close[i]);
         if(Body==0)Body=0.00001;//to avoid zero divide
         if(Spread/Body<BarRatio)continue;  //not a pin bar, check next
            double Offset=PriceOffset*Point();
            //check bear pin bar
            ENUM_CLOSE_THIRDS Third=CloseThird(high[i],low[i],close[i]);
            ENUM_BODY_DIRECTIONS Dir=BodyDirection(open[i],close[i]);
            
            double Tail = high[i] - MathMax(open[i],close[i]);
            double NotTail = Spread - Tail;
            if(NotTail==0)NotTail=0.00001;//to avoid zero divide
            double Ratio = Tail/NotTail;
            if(Ratio>=TailRatio)
            {
               if(Dir==BEAR || Dir==ZERO)
               if(Third==LOWER_PART || Third==UNKNOWN_PART)
               if(CheckLocalMax(i,high,ExtremumOfBars))
               {
                  OpenBuffer[i]=low[i]-Offset;
                  StopBuffer[i]=high[i]+Offset;
                  continue;
               }
            }
            
            Tail = MathMin(open[i],close[i]) - low[i];
            NotTail = Spread - Tail;
            if(NotTail==0)NotTail=0.00001;//to avoid zero divide
            Ratio = Tail/NotTail;
            if(Ratio>=TailRatio)
            {
               if(Dir==BULL || Dir==ZERO)
               if(Third==UPPER_PART || Third==UNKNOWN_PART)
               if(CheckLocalMin(i,low,ExtremumOfBars))
               {
                  OpenBuffer[i]=high[i]+Offset;
                  StopBuffer[i]=low[i]-Offset;
                  continue;
               }
            }
   }
//--- return value of prev_calculated for next call
   return(total);
}