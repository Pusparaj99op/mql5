//+------------------------------------------------------------------+
//|                                             LinearRegression.mq5 |
//|                Copyright © 2006, tageiger, aka fxid10t@yahoo.com |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2006, tageiger, aka fxid10t@yahoo.com"
//---- link to the website of the author
#property link "http://www.metaquotes.net"
//---- indicator version
#property version   "1.00"
#property description "Linear Regression"
//---- drawing the indicator in the main window
#property indicator_chart_window
#property indicator_buffers  0
#property indicator_plots    0
//+------------------------------------------------+
//|  Declaration of constants                      |
//+------------------------------------------------+
#define RESET 0 // the constant for getting the command for the indicator recalculation back to the terminal
//+------------------------------------------------+
//| Enumeration for the level width                |
//+------------------------------------------------+ 
enum ENUM_WIDTH // type of constant
  {
   w_1 = 1,   // 1
   w_2,       // 2
   w_3,       // 3
   w_4,       // 4
   w_5        // 5
  };
//+------------------------------------------------+
//| Indicator input parameters                     |
//+------------------------------------------------+
input string lines_sirname="Linear_Regression_"; // Graphic objects group name
input ENUM_TIMEFRAMES period=PERIOD_CURRENT;     // Chart period
input int LR_length=34;                          // Indicator calculation period
input bool Deletelevel=true;                     // Level deletion

input color LR_c=Blue;                           // Middle line color
input ENUM_LINE_STYLE LR_style=STYLE_SOLID;      // Middle line style
input ENUM_WIDTH LR_width=w_3;                   // Middle line width

input double std_channel_1=0.618;                // Minimum regression
input color c_1=Gold;                            // Minimum line color
input ENUM_LINE_STYLE style_1=STYLE_DASH;        // Minimum line style
input ENUM_WIDTH width_1=w_1;                    // Minimum line width

input double std_channel_2=1.618;                // Nominal regression
input color c_2=Lime;                            // Nominal line color
input ENUM_LINE_STYLE style_2=STYLE_DOT;         // Nominal line style
input ENUM_WIDTH width_2=w_1;                    // Nominal line width

input double std_channel_3=2.618;                // Maximum regression
input color c_3=Magenta;                         // Maximum line color
input ENUM_LINE_STYLE style_3=STYLE_SOLID;       // Maximum line style
input ENUM_WIDTH width_3=w_3;                    // Maximum line width
//+----------------------------------------------+
int start_bar,end_bar,n,to_copy;
string LR_name,CH1P_name,CH1M_name,CH2P_name,CH2M_name,CH3P_name,CH3M_name;
//+------------------------------------------------------------------+
//|  Trend line creation                                             |
//+------------------------------------------------------------------+
void CreateTline(long     chart_id,      // chart ID
                 string   name,          // object name
                 int      nwin,          // window index
                 datetime time1,         // price level time 1
                 double   price1,        // price level 1
                 datetime time2,         // price level time 2
                 double   price2,        // price level 2
                 color    Color,         // line color
                 int      style,         // line style
                 int      width,         // line width
                 string   text)          // text
  {
//----
   ObjectCreate(chart_id,name,OBJ_TREND,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,true);
//----
  }
//+------------------------------------------------------------------+
//|  Trend line reinstallation                                       |
//+------------------------------------------------------------------+
void SetTline(long     chart_id,      // chart ID
              string   name,          // object name
              int      nwin,          // window index
              datetime time1,         // price level time 1
              double   price1,        // price level 1
              datetime time2,         // price level time 2
              double   price2,        // price level 2
              color    Color,         // line color
              int      style,         // line style
              int      width,         // line width
              string   text)          // text
  {
//----
   if(ObjectFind(chart_id,name)==-1)
     {
      CreateTline(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,text);
     }
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- initialization of variables   
   string fullname=lines_sirname+string(period)+" "+string(LR_length);
   LR_name=fullname+" TL";
   CH1P_name=fullname+" +"+string(std_channel_1)+"d";
   CH1M_name=fullname+" -"+string(std_channel_1)+"d";
   CH2P_name=fullname+" +"+string(std_channel_2)+"d";
   CH2M_name=fullname+" -"+string(std_channel_2)+"d";
   CH3P_name=fullname+" +"+string(std_channel_3)+"d";
   CH3M_name=fullname+" -"+string(std_channel_3)+"d";
   start_bar=LR_length;
   end_bar=0;
   n=start_bar-end_bar+1;
   to_copy=2*n;
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//---- delete the level, if necessary
   if(Deletelevel)
     {
      ObjectDelete(0,LR_name);
      ObjectDelete(0,CH1P_name);
      ObjectDelete(0,CH1M_name);
      ObjectDelete(0,CH2P_name);
      ObjectDelete(0,CH2M_name);
      ObjectDelete(0,CH3P_name);
      ObjectDelete(0,CH3M_name);
     }
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
//---- declarations of local variables 
   double value,a,b,c,sumy,sumx,sumxy,sumx2,iClose[];
   datetime iTime[],start_time,end_time;

//--- copy newly appeared data in the arrays
   if(CopyClose(NULL,period,0,to_copy,iClose)<=0) return(RESET);
   if(CopyTime(NULL,period,0,to_copy,iTime)<=0) return(RESET);

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(iClose,true);
   ArraySetAsSeries(iTime,true);

   start_time=iTime[start_bar];
   end_time=iTime[end_bar];

   value=iClose[end_bar];
   sumy=value;
   sumx=0.0;
   sumxy=0.0;
   sumx2=0.0;

   for(int iii=1; iii<n; iii++)
     {
      value=iClose[end_bar+iii];
      sumy+=value;
      sumxy+=value*iii;
      sumx+=iii;
      sumx2+=iii*iii;
     }

   c=sumx2*n-sumx*sumx;
   if(!c) return(rates_total);

   b=(sumxy*n-sumx*sumy)/c;
   a=(sumy-sumx*b)/n;

   double LR_price_2=a;
   double LR_price_1=a+b*n;

//---- maximal deviation calculation (not used)
   double max_dev=0;
   double deviation=0;
   double dvalue=a;

   for(int iii=0; iii<n; iii++)
     {
      value=iClose[end_bar+iii];
      dvalue+=b;
      deviation=MathAbs(value-dvalue);
      if(max_dev<=deviation) max_dev=deviation;
     }

//---- Linear regression trendline    
   SetTline(0,LR_name,0,start_time,LR_price_1,end_time,LR_price_2,LR_c,LR_style,LR_width,LR_name);

//---- ...standard deviation...
   double x=0,x_sum=0,x_avg=0,x_sum_squared=0,std_dev=0,price1,price2;

   for(int iii=0; iii<start_bar; iii++)
     {
      x=MathAbs(iClose[iii]-ObjectGetValueByTime(0,LR_name,iTime[iii],0));
      x_sum+=x;

      if(iii>0)
        {
         x_avg=(x_avg+x)/iii;
         x_sum_squared+=(x-x_avg)*(x-x_avg);
         std_dev=MathSqrt(x_sum_squared/(start_bar-1));
        }
     }

//---- ...standard deviation channels...
   price1=LR_price_1+std_dev*std_channel_1;
   price2=LR_price_2+std_dev*std_channel_1;
   SetTline(0,CH1P_name,0,start_time,price1,end_time,price2,c_1,style_1,width_1,CH1P_name);

   price1=LR_price_1-std_dev*std_channel_1;
   price2=LR_price_2-std_dev*std_channel_1;
   SetTline(0,CH1M_name,0,start_time,price1,end_time,price2,c_1,style_1,width_1,CH1M_name);
//----   
   price1=LR_price_1+std_dev*std_channel_2;
   price2=LR_price_2+std_dev*std_channel_2;
   SetTline(0,CH2P_name,0,start_time,price1,end_time,price2,c_2,style_2,width_2,CH2P_name);

   price1=LR_price_1-std_dev*std_channel_2;
   price2=LR_price_2-std_dev*std_channel_2;
   SetTline(0,CH2M_name,0,start_time,price1,end_time,price2,c_2,style_2,width_2,CH2M_name);
//----  
   price1=LR_price_1+std_dev*std_channel_3;
   price2=LR_price_2+std_dev*std_channel_3;
   SetTline(0,CH3P_name,0,start_time,price1,end_time,price2,c_3,style_3,width_3,CH3P_name);

   price1=LR_price_1-std_dev*std_channel_3;
   price2=LR_price_2-std_dev*std_channel_3;
   SetTline(0,CH3M_name,0,start_time,price1,end_time,price2,c_3,style_3,width_3,CH3M_name);

//----   
   return(rates_total);
  }
//+------------------------------------------------------------------+
