//+------------------------------------------------------------------+ 
//|                                                   Discipline.mq5 | 
//|                                Copyright © 2009, Michael Volochuk| 
//|                                               webtecnic@terra.es | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2009, Michael Volochuk"
#property link "webtecnic@terra.es" 
//---- indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers 2
#property indicator_buffers 2 
//---- only one plot is used
#property indicator_plots   1
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing indicator as a five-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- colors of the four-color histogram are as follows
#property indicator_color1 clrMagenta,clrBrown,clrGray,clrGreen,clrLime
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- Indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the indicator label
#property indicator_label1 "Discipline"
//+-----------------------------------+
//|  declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_ //Type of constant
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price
   PRICE_DEMARK_,        //Demark Price
   PRICE_NAVEL_          //Navel Price
  };
//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input uint IndPeriod=10; // indicator period
input Applied_price_ IPC=PRICE_CLOSE;//price constant
input uint IndBars=300; //number of calculated bars
//+-----------------------------------+
//---- Declaration of integer variables of data starting point
int min_rates_total,AtrPeriod;
double Threshold;
//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double IndBuffer[],ColorIndBuffer[];
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialization of variables of data calculation starting point
   AtrPeriod=10;
   min_rates_total=int(IndPeriod+3+1);
   min_rates_total=MathMax(AtrPeriod,min_rates_total);
   Threshold=1.2;

//---- set IndBuffer dynamic array as an indicator buffer
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- shifting the starting point of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting values of the indicator that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(IndBuffer,true);

//---- set dynamic array as as a color index buffer   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ColorIndBuffer,true);

//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,"Discipline");
//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- end of initialization
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+     
void OnDeinit(const int reason)
  {
//----
   int total=ObjectsTotal(0,0,-1)-1;
   string name,sirname;

   for(int numb=total; numb>=0 && !IsStopped(); numb--)
     {
      name=ObjectName(0,numb,0,-1);

      sirname=StringSubstr(name,0,StringLen("Exit"));
      if(sirname=="Exit") ObjectDelete(0,name);

      sirname=StringSubstr(name,0,StringLen("Buy"));
      if(sirname=="Buy") ObjectDelete(0,name);

      sirname=StringSubstr(name,0,StringLen("Sell"));
      if(sirname=="Sell") ObjectDelete(0,name);
     }
//----
   ChartRedraw(0);
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
//---- checking for the sufficiency of the number of bars for the calculation
   if(rates_total<min_rates_total) return(0);

//---- declaration of local variables 
   int limit,bar,clr;
   double Value0,Fish0,MaxH,MinL,price,Range,pos;
   static double Value1,Value2,Fish1,Fish2;
   string name;

//---- calculation of the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=int(MathMin(rates_total-min_rates_total,IndBars)); // starting number for calculation of all bars
      for(bar=rates_total-1; bar>limit && !IsStopped(); bar--) IndBuffer[bar]=EMPTY_VALUE;
      Value1=0.0;
      Value2=0.0;
      Fish1=0.0;
      Fish2=0.0;
     }
   else
     {
      limit=int(MathMin(rates_total-prev_calculated,IndBars)); // starting number for the calculation of new bars
     }

//---- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(time,true);

//---- Main calculation loop of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      MaxH=high[ArrayMaximum(high,bar,IndPeriod)];
      MinL=low[ArrayMinimum(low,bar,IndPeriod)];
      price=PriceSeries(IPC,bar,open,low,high,close);
      Range=MaxH-MinL;

      if(Range) Value0=0.33*2*((price-MinL)/Range-0.5)+0.67*Value1;
      else Value0=0.999;
      Value0=MathMin(MathMax(Value0,-0.999),+0.999);
      Fish0=0.5*MathLog((1.0+Value0)/(1.0-Value0))+0.5*Fish1;
      IndBuffer[bar]=Fish0;

      string sTime=TimeToString(time[bar],TIME_DATE|TIME_MINUTES);
      name="Exit"+sTime;
      if(bar==limit) ObjectDelete(0,name);

      if(Fish0<0 && Fish1>0) SetArrow(0,name,0,time[bar],close[bar],118,clrRed,4,ANCHOR_TOP);
      if(Fish0>0 && Fish1<0) SetArrow(0,name,0,time[bar],close[bar],118,clrBlue,4,ANCHOR_BOTTOM);

      name="Sell"+sTime;
      if(bar==limit) ObjectDelete(0,name);
      if(Fish0<-Threshold && Fish0>Fish1 && Fish1<=Fish2)
        {
         pos=high[bar]+GetRange(bar,low,high,AtrPeriod)/2;
         SetArrow(0,name,0,time[bar],pos,234,clrRed,4,ANCHOR_BOTTOM);
        }

      name="Buy"+sTime;
      if(bar==limit) ObjectDelete(0,name);
      if(Fish0>Threshold && Fish0<Fish1 && Fish1>=Fish2)
        {
         pos=low[bar]-GetRange(bar,low,high,AtrPeriod)/2;
         SetArrow(0,name,0,time[bar],pos,233,clrBlue,4,ANCHOR_TOP);
        }

      if(bar)
        {
         Value2=Value1;
         Value1=Value0;
         Fish2=Fish1;
         Fish1=Fish0;
        }
     }

   if(prev_calculated>rates_total || prev_calculated<=0) limit--;
//---- Main indicator coloring loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      clr=2;

      if(IndBuffer[bar]>0)
        {
         if(IndBuffer[bar]>IndBuffer[bar+1]) clr=4;
         if(IndBuffer[bar]<IndBuffer[bar+1]) clr=3;
        }

      if(IndBuffer[bar]<0)
        {
         if(IndBuffer[bar]<IndBuffer[bar+1]) clr=0;
         if(IndBuffer[bar]>IndBuffer[bar+1]) clr=1;
        }

      ColorIndBuffer[bar]=clr;
     }
//----     
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| GetRange function                                                |
//+------------------------------------------------------------------+     
double GetRange(int index,const double &Low[],const double &High[],uint Len)
  {
//----
   double AvgRange=0.0;
   for(int count=index; count<int(index+Len); count++) AvgRange+=MathAbs(High[count]-Low[count]);
//----
   return(AvgRange/Len);
  }
//+------------------------------------------------------------------+   
//| Getting values of a price time series                            |
//+------------------------------------------------------------------+ 
double PriceSeries
(
 uint applied_price,// Price constant
 uint   bar,// Shift index relative to the current bar by a specified number of periods backward or forward).
 const double &Open[],
 const double &Low[],
 const double &High[],
 const double &Close[]
 )
//PriceSeries(applied_price, bar, open, low, high, close)
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
  {
//----
   switch(applied_price)
     {
      //---- Price constants from the ENUM_APPLIED_PRICE enumeration
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
      case 12:
        {
         double res=High[bar]+Low[bar]+Close[bar];

         if(Close[bar]<Open[bar]) res=(res+Low[bar])/2;
         if(Close[bar]>Open[bar]) res=(res+High[bar])/2;
         if(Close[bar]==Open[bar]) res=(res+Close[bar])/2;
         return(((res-Low[bar])+(res-High[bar]))/2);
        }
      //----
      default: return(Close[bar]);
     }
//----
//return(0);
  }
//+------------------------------------------------------------------+
//|  creating a text label                                           |
//+------------------------------------------------------------------+
void CreateArrow(long chart_id,// chart ID
                 string   name,              // object name
                 int      nwin,              // window index
                 datetime time,              // price level time
                 double   price,             // price level
                 uint     arrow,             // Labels
                 color    Color,             // Text color
                 int      Size,              // Text size
                 ENUM_ARROW_ANCHOR point     // The chart corner to Which an text is attached
                 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_ARROW,nwin,time,price);
   ObjectSetInteger(chart_id,name,OBJPROP_ARROWCODE,arrow);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,Size);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,point);

//----
  }
//+------------------------------------------------------------------+
//|  changing a text label                                           |
//+------------------------------------------------------------------+
void SetArrow(long chart_id,// chart ID
              string   name,              // object name
              int      nwin,              // window index
              datetime time,              // price level time
              double   price,             // price level
              uint     arrow,             // Labels
              color    Color,             // Text color
              int      Size,              // Text size
              ENUM_ARROW_ANCHOR point     // The chart corner to Which an text is attached
              )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateArrow(chart_id,name,nwin,time,price,arrow,Color,Size,point);
   else
     {
      ObjectMove(chart_id,name,0,time,price);
     }
//----
  }
//+------------------------------------------------------------------+
