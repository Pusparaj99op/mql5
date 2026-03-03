//+------------------------------------------------------------------+
//|                                                   ExCandles2.mq5 |
//|                           Copyright © 2006, Alex Sidd (Executer) |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2006, Alex Sidd (Executer)"
//---- link to the website of the author
#property link      "mailto:work_st@mail.ru"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
//---- number of indicator buffers
#property indicator_buffers 1 
//---- only one graphical plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int ExPeriod=24;
input bool TrendFilter=true;
input int how_bars=0;
input int UpSymbol=233;
input int DnSymbol=234;
input int VertShift=100;
//+----------------------------------------------+
//---- declaration of a dynamic array that further 
//---- will be used as an indicator buffer
double CCodeBuffer[];
double dVertShift;
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//|  Creation of a symbol label                                      |
//+------------------------------------------------------------------+
void CreateSymbol(long     chart_id,      // chart ID
                  string   name,          // object name
                  int      nwin,          // window index
                  datetime time,          // price level time
                  double   price,         // price level
                  color    Color,         // color
                  int      style,         // style
                  int      width,         // width
                  int      symbol,        // symbol
                  string   text)          // text
  {
//----
   ObjectCreate(chart_id,name,OBJ_ARROW,nwin,time,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart_id,name,OBJPROP_ARROWCODE,symbol);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//----
  }
//+------------------------------------------------------------------+
//|  Set symbol label                                                |
//+------------------------------------------------------------------+
void SetSymbol(long     chart_id,      // chart ID
               string   name,          // object name
               int      nwin,          // window index
               datetime time,          // price level time
               double   price,         // price level
               color    Color,         // color
               int      style,         // style
               int      width,         // width
               int      symbol,        // symbol
               string   text)          // text
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateSymbol(chart_id,name,nwin,time,price,Color,style,width,symbol,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time,price);
     }
//----
  }
//+------------------------------------------------------------------+
//| Trend                                                            |
//+------------------------------------------------------------------+  
int Trend(int rates_total,const double &Open[],const double &Close[],int i)
  {
//----
   double negative = 0;
   double positive = 0;
   if(i<rates_total-ExPeriod-1)
     {
      int k=i+ExPeriod;
      while(k>i)
        {
         if(Open[k]<Close[k])
            positive+=(Close[k]-Open[k]);
         if(Open[k]>Close[k])
            negative+=(Open[k]-Close[k]);
         k--;
        }
     }
   else return(0);
   if(positive - negative > 0) return(1);
   if(positive - negative < 0) return(-1);
   if(positive==negative) return(0);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Hanging Man                                                      |
//+------------------------------------------------------------------+
bool IsHangingMan(int rates_total,
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                int i1)
  {
//----
   double buf=Open[i1]-Close[i1];
   if(buf==0) buf=1;

   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)>0 && ((High[i1]-Open[i1])*100/
      buf<20) && ((Close[i1]-Low[i1])*100/buf>180)) || 
      (TrendFilter==false && ((High[i1]-Open[i1])*100/buf<20) && 
      ((Close[i1]-Low[i1])*100/buf>180)))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Hammer                                                           |
//+------------------------------------------------------------------+
bool IsHammer(int rates_total,
              const double &Open[],
              const double &High[],
              const double &Low[],
              const double &Close[],
              int i1)
  {
//----
   double buf=Close[i1]-Open[i1];
   if(buf==0) buf=1;

   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)<0 && ((High[i1]-Close[i1])*100/
      buf>180) && ((Open[i1]-Low[i1])*100/buf<20)) || 
      (TrendFilter==false && ((High[i1]-Close[i1])*100/buf>180) && 
      ((Open[i1]-Low[i1])*100/buf<20)))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Bearish Engulfing                                                |
//+------------------------------------------------------------------+
bool IsBearishEngulfing(int rates_total,
            const double &Open[],
            const double &Close[],
            int i1,
            int i2)
  {
//----
   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)>0 && (Open[i1]-Close[i1]>0) && 
      (Open[i1]>Close[i2]) && (Close[i1]<Open[i2]) && (Open[i2]-Close[i2]<0)) || 
      (TrendFilter==false>0 && (Open[i1]-Close[i1]>0) && (Open[i1]>Close[i2]) && 
      (Close[i1]<Open[i2]) && (Open[i2]-Close[i2]<0)))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Bullish Engulfing                                                |
//+------------------------------------------------------------------+
bool IsBullishEngulfing(int rates_total,
            const double &Open[],
            const double &Close[],
            int i1,
            int i2)
  {
//----
   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)<0 && (Open[i1]-Close[i1]<0) && 
      (Open[i2]-Close[i2]>0) && (Close[i1]>Open[i2]) && (Open[i1]<Close[i2])) || 
      (TrendFilter==false && (Open[i1]-Close[i1]<0) && (Open[i2]-Close[i2]>0) && 
      (Close[i1]>Open[i2]) && (Open[i1]<Close[i2])))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Dark Cloud Cover                                                 |
//+------------------------------------------------------------------+
bool DarkCloud_Cover(int rates_total,
                  const double &Open[],
                  const double &High[],
                  const double &Low[],
                  const double &Close[],
                  int i1,
                  int i2)
  {
//----
   double x=(High[i2]-Low[i2]);
   if(x==0) x=0.0001;

   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)>0 && 
      (Open[i1]-Close[i1]>0) && 
      (Open[i2]-Close[i2]<0) && 
      ((Close[i2]-Open[i2])/x>0.6) && 
      (Open[i1]>High[i2]) && 
      (Close[i1]<(Open[i2]+(Close[i2]-Open[i2])/2))) || 
      (TrendFilter==false && 
      (Open[i1]-Close[i1]>0) && 
      (Open[i2]-Close[i2]<0) && 
      ((Close[i2]-Open[i2])/x>0.6) && 
      (Open[i1]>High[i2]) && 
      (Close[i1]<(Open[i2]+(Close[i2]-Open[i2])/2))))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Piercing Line                                                    |
//+------------------------------------------------------------------+
bool PiercingLine(int rates_total,
             const double &Open[],
             const double &High[],
             const double &Low[],
             const double &Close[],
             int i1,
             int i2)
  {
//----
   double x=(High[i2]-Low[i2]);
   if(x==0) x=0.0001;

   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)<0 && 
      (Open[i1]-Close[i1]<0) && 
      (Open[i2]-Close[i2]>0) && 
      ((Open[i2]-Close[i2])/x>0.6) && 
      (Open[i1]<Low[i2]) && 
      (Close[i1]>(Close[i2]+(Open[i2]-Close[i2])/2))) || 
      (TrendFilter==false && 
      (Open[i1]-Close[i1]<0) && 
      (Open[i2]-Close[i2]>0) && 
      ((Open[i2]-Close[i2])/x>0.6) && 
      (Open[i1]<Low[i2]) && 
      (Close[i1]>(Close[i2]+(Open[i2]-Close[i2])/2))))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Morning Star                                                     |
//+------------------------------------------------------------------+
bool Morning_Star(int rates_total,
                  const double &Open[],
                  const double &Close[],
                  int i1,
                  int i2,
                  int i3)
  {
//----
   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)<0 && 
      (Open[i3]-Close[i3]>0) && 
      (Open[i1]-Close[i1]<0) && 
      (Close[i2]<Open[i3]) && 
      (Close[i2]<Open[i1]) && 
      (Close[i2]<Close[i1]) && 
      (Close[i2]<Close[i3]) && 
      (Open[i2]<Open[i1]) && 
      (Open[i2]<Open[i3]) && 
      (Open[i2]<Close[i3]) && 
      (Open[i2]<Close[i1])) || 
      (TrendFilter==false && 
      (Open[i3]-Close[i3]>0) && 
      (Open[i1]-Close[i1]<0) && 
      (Close[i2]<Open[i3]) && 
      (Close[i2]<Open[i1]) && 
      (Close[i2]<Close[i1]) && 
      (Close[i2]<Close[i3]) && 
      (Open[i2]<Open[i1]) && 
      (Open[i2]<Open[i3]) && 
      (Open[i2]<Close[i3]) && 
      (Open[i2]<Close[i1])))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Evening Star                                                     |
//+------------------------------------------------------------------+
bool Evening_Star(int rates_total,
                  const double &Open[],
                  const double &Close[],
                  int i1,
                  int i2,
                  int i3)
  {
//----
   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)>0 && 
      (Open[i3]-Close[i3]<0) && 
      (Open[i1]-Close[i1]>0) && 
      (Close[i2]>Open[i3]) && 
      (Close[i2]>Open[i1]) && 
      (Close[i2]>Close[i1]) && 
      (Close[i2]>Close[i3]) && 
      (Open[i2]>Open[i1]) && 
      (Open[i2]>Open[i3]) && 
      (Open[i2]>Close[i3]) && 
      (Open[i2]>Close[i1])) || 
      (TrendFilter==false && 
      (Open[i3]-Close[i3]<0) && 
      (Open[i1]-Close[i1]>0) && 
      (Close[i2]>Open[i3]) && 
      (Close[i2]>Open[i1]) && 
      (Close[i2]>Close[i1]) && 
      (Close[i2]>Close[i3]) && 
      (Open[i2]>Open[i1]) && 
      (Open[i2]>Open[i3]) && 
      (Open[i2]>Close[i3]) && 
      (Open[i2]>Close[i1])))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Evening Doji Star                                                |
//+------------------------------------------------------------------+
bool IsEveningDojiStar(int rates_total,
                        const double &Open[],
                        const double &Close[],
                        int i1,
                        int i2,
                        int i3)
  {
//----
   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)>0 && 
      (Open[i2]==Close[i2]) && 
      (Open[i3]-Close[i3]<0) && 
      (Open[i1]-Close[i1]>0) && 
      (Close[i2]>Open[i3]) && 
      (Close[i2]>Open[i1]) && 
      (Close[i2]>Close[i1]) && 
      (Close[i2]>Close[i3]) && 
      (Open[i2]>Open[i1]) && 
      (Open[i2]>Open[i3]) && 
      (Open[i2]>Close[i3]) && 
      (Open[i2]>Close[i1])) || 
      (TrendFilter==false && 
      (Open[i2]==Close[i2]) && 
      (Open[i3]-Close[i3]<0) && 
      (Open[i1]-Close[i1]>0) && 
      (Close[i2]>Open[i3]) && 
      (Close[i2]>Open[i1]) && 
      (Close[i2]>Close[i1]) && 
      (Close[i2]>Close[i3]) && 
      (Open[i2]>Open[i1]) && 
      (Open[i2]>Open[i3]) && 
      (Open[i2]>Close[i3]) && 
      (Open[i2]>Close[i1])))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Morning Doji Star                                                |
//+------------------------------------------------------------------+
bool IsMorningDojiStar(int rates_total,
                        const double &Open[],
                        const double &Close[],
                        int i1,
                        int i2,
                        int i3)
  {
//----
   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)<0 && 
      (Open[i2]==Close[i2]) && 
      (Open[i3]-Close[i3]>0) && 
      (Open[i1]-Close[i1]<0) && 
      (Close[i2]<Open[i3]) && 
      (Close[i2]<Open[i1]) && 
      (Close[i2]<Close[i1]) && 
      (Close[i2]<Close[i3]) && 
      (Open[i2]<Open[i1]) && 
      (Open[i2]<Open[i3]) && 
      (Open[i2]<Close[i3]) && 
      (Open[i2]<Close[i1])) || 
      (TrendFilter==false && 
      (Open[i2]==Close[i2]) && 
      (Open[i3]-Close[i3]>0) && 
      (Open[i1]-Close[i1]<0) && 
      (Close[i2]<Open[i3]) && 
      (Close[i2]<Open[i1]) && 
      (Close[i2]<Close[i1]) && 
      (Close[i2]<Close[i3]) && 
      (Open[i2]<Open[i1]) && 
      (Open[i2]<Open[i3]) && 
      (Open[i2]<Close[i3]) && 
      (Open[i2]<Close[i1])))
      return(true);
   else  return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Shooting Star                                                    |
//+------------------------------------------------------------------+
bool IsShootingStar(int rates_total,
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                int i1)
  {
//----
   double buf=Open[i1]-Close[i1];
   if(buf==0) buf=1;

   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)>0 && ((High[i1]-Open[i1])*100/
      buf>180) && ((Close[i1]-Low[i1])*100/buf<20)) || 
      (TrendFilter==false && ((High[i1]-Open[i1])*100/buf>180) && 
      ((Close[i1]-Low[i1])*100/buf<20)))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Inverted Hammer                                                  |
//+------------------------------------------------------------------+
bool IsInvertedHammer(int rates_total,
                    const double &Open[],
                    const double &High[],
                    const double &Low[],
                    const double &Close[],
                    int i1)
  {
//----
   double buf=Close[i1]-Open[i1];
   if(buf==0) buf=1;

   if((TrendFilter==true && Trend(rates_total,Open,Close,i1)<0 && ((High[i1]-Close[i1])*100/
      buf<20) && ((Open[i1]-Low[i1])*100/buf>180)) || 
      (TrendFilter==false && ((High[i1]-Close[i1])*100/buf<20) && 
      ((Open[i1]-Low[i1])*100/buf>180)))
      return(true);
   else return(false);
//----
   return(false);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectsDeleteAll(0,0,OBJ_ARROW);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=ExPeriod;

//---- Initialization of variables   
   dVertShift=VertShift*_Point;

//---- set CCodeBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,CCodeBuffer,INDICATOR_CALCULATIONS);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(CCodeBuffer,true);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//----
   if(rates_total<min_rates_total) return(0);

   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//---- declarations of local variables
   string name;
   double negative=0,positive=0;
   int i,limit;

//---- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      if(how_bars<=0 || how_bars>rates_total)
         limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
      else limit=how_bars;
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }

//---- main indicator calculation loop
   for(i=limit; i>=0 && !IsStopped(); i--)
     {
      if(IsShootingStar(rates_total,open,high,low,close,i+1))
        {
         name="Shooting star "+string(i);
         SetSymbol(0,name,0,time[i+1],high[i+1]+dVertShift,Red,STYLE_SOLID,3,DnSymbol,name);
         CCodeBuffer[i]=1;
        }
      if(IsInvertedHammer(rates_total,open,high,low,close,i+1))
        {
         name="Inverted hammer "+string(i);
         SetSymbol(0,name,0,time[i+1],low[i+1]-dVertShift,Blue,STYLE_SOLID,3,UpSymbol,name);
         CCodeBuffer[i]=2;
        }
      if(IsHangingMan(rates_total,open,high,low,close,i+1))
        {
         name="Hangman "+string(i);
         SetSymbol(0,name,0,time[i+1],high[i+1]+dVertShift,Red,STYLE_SOLID,3,DnSymbol,name);
         CCodeBuffer[i]=3;
        }
      if(IsHammer(rates_total,open,high,low,close,i+1))
        {
         name="Hammer "+string(i);
         SetSymbol(0,name,0,time[i+1],low[i+1]-dVertShift,Blue,STYLE_SOLID,3,UpSymbol,name);
         CCodeBuffer[i]=4;
        }
      if(IsBearishEngulfing(rates_total,open,close,i+1,i+2))
        {
         name="Bearish engulfing "+string(i);
         SetSymbol(0,name,0,time[i+1],high[i+1]+dVertShift,Maroon,STYLE_SOLID,3,DnSymbol,name);
         CCodeBuffer[i]=5;
        }
      if(IsBullishEngulfing(rates_total,open,close,i+1,i+2))
        {
         name="Bullish engulfing "+string(i);
         SetSymbol(0,name,0,time[i+1],low[i+1]-dVertShift,RoyalBlue,STYLE_SOLID,3,UpSymbol,name);
         CCodeBuffer[i]=6;
        }
      if(DarkCloud_Cover(rates_total,open,high,low,close,i+1,i+2))
        {
         name="Dark cloud cover "+string(i);
         SetSymbol(0,name,0,time[i],high[i]+dVertShift,OrangeRed,STYLE_SOLID,3,DnSymbol,name);
         CCodeBuffer[i]=7;
        }
      if(PiercingLine(rates_total,open,high,low,close,i+1,i+2))
        {
         name="Piercing line pattern "+string(i);
         SetSymbol(0,name,0,time[i],low[i]-dVertShift,SlateBlue,STYLE_SOLID,3,UpSymbol,name);
         CCodeBuffer[i]=8;
        }
      if(Evening_Star(rates_total,open,close,i+1,i+2,i+3))
        {
         name="Evening star "+string(i);
         SetSymbol(0,name,0,time[i+2],high[i+2]+dVertShift,Red,STYLE_SOLID,3,DnSymbol,name);
         CCodeBuffer[i]=9;
        }
      if(Morning_Star(rates_total,open,close,i+1,i+2,i+3))
        {
         name="Morning star "+string(i);
         SetSymbol(0,name,0,time[i+2],low[i+2]-dVertShift,DodgerBlue,STYLE_SOLID,3,UpSymbol,name);
         CCodeBuffer[i]=10;
        }
      if(IsEveningDojiStar(rates_total,open,close,i+1,i+2,i+3))
        {
         name="Evening doji star "+string(i);
         SetSymbol(0,name,0,time[i+2],high[i+2]+dVertShift,DeepPink,STYLE_SOLID,3,DnSymbol,name);
         CCodeBuffer[i]=11;
        }
      if(IsMorningDojiStar(rates_total,open,close,i+1,i+2,i+3))
        {
         name="Morning doji star "+string(i);
         SetSymbol(0,name,0,time[i+2],low[i+2]-dVertShift,Blue,STYLE_SOLID,3,UpSymbol,name);
         CCodeBuffer[i]=12;
        }
     }
//----
   ChartRedraw(0);
//----   
   return(rates_total);
  }
//+------------------------------------------------------------------+
