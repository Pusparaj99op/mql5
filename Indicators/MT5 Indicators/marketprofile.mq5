//+------------------------------------------------------------------+
//|                                                MarketProfile.mq5 |
//|                            Copyright © 2006, Viatcheslav Suvorov |
//|                                                                  |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2006, Viatcheslav Suvorov"
//---- link to the web site of the author
#property link      ""
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window 
#property indicator_buffers 1
#property indicator_plots 1
//+----------------------------------------------+
//| Indicator drawing parameters                 |
//+----------------------------------------------+
input datetime StartDate=0;
input bool lastdayStart = true;
input int CountProfile=2;
input color AziaColor=SpringGreen;
input color EuropaColor=DeepSkyBlue;
input color AmericaColor=Violet;
input color MedianaColor=Gray;
//+----------------------------------------------+
int CurPeriod_;
datetime StartDate_;
//+------------------------------------------------------------------+
//|  Creating triangle                                               |
//+------------------------------------------------------------------+
void CreateRetangle(long     chart_id,  // chart ID
                    string   name,      // object name
                    int      nwin,      // window index
                    datetime time1,     // price level 1 time
                    double   price1,    // price level 1
                    datetime time2,     // price level 2 time
                    double   price2,    // price level 2
                    color    Color,     // line color
                    int      style,     // line style
                    int      width,     // line width
                    string   text)      // text
  {
//----
   ObjectCreate(chart_id,name,OBJ_RECTANGLE,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
//----
  }
//+------------------------------------------------------------------+
//|  Triangle reinstallation                                         |
//+------------------------------------------------------------------+
void SetRetangle(long     chart_id,  // chart ID
                 string   name,      // object name
                 int      nwin,      // window index
                 datetime time1,     // price level 1 time
                 double   price1,    // price level 1
                 datetime time2,     // price level 2 time
                 double   price2,    // price level 2
                 color    Color,     // line color
                 int      style,     // line style
                 int      width,     // line width
                 string   text)      // text
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateRetangle(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//----
   StartDate_=StartDate;
   CurPeriod_=PeriodSeconds(PERIOD_CURRENT)/60;
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectsDeleteAll(0,0,OBJ_RECTANGLE);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the calculation of indicator
                const double& low[],      // price array of minimums of price for the calculation of indicator
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//----
   int x=CurPeriod_;
   if(x<15 || x>60) return(0);

   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- declarations of local variables    
   bool signal;
   double onetick,Mediana=0.0,LastHigh,LastLow,CurPos;
   int i,j,MaxSize,MySize,MySizeEuropa,MySizeAzia,MySizeAmerica,BACK;
   datetime TimeDay,TimeYear;
   string sirname;

   if(lastdayStart) StartDate_=time[0];

   BACK=0;
   MqlDateTime tm;
   TimeToStruct(StartDate_,tm);
   TimeDay=tm.day_of_year;
   TimeYear=tm.year;
   TimeToStruct(time[BACK],tm);

   while(tm.day_of_year>TimeDay || (tm.year!=TimeYear && BACK<rates_total))
     {
      BACK++;
      if(BACK>=rates_total) return(rates_total);
      TimeToStruct(time[BACK],tm);
      TimeYear=tm.year;
     }

   onetick=1/(MathPow(10,_Digits));
   i=BACK;

   for(int cycles=CountProfile;cycles>0;cycles--)
     {
      signal=false;
      LastHigh=high[i];
      LastLow=low[i];

      while(!signal)
        {
         if(high[i+1]>LastHigh) LastHigh=high[i+1];
         if(low[i+1]<LastLow) LastLow=low[i+1];
         MaxSize=0;
         MySize=0;

         TimeToStruct(time[i],tm);
         TimeDay=tm.day;
         TimeToStruct(time[i+1],tm);

         if(TimeDay!=tm.day)
           {

            signal=true;
            CurPos=LastLow;
            while(CurPos<=LastHigh)
              {
               MySizeAzia=0;
               MySizeEuropa=0;
               MySizeAmerica=0;

               for(j=i;j>=BACK;j--)
                 {
                  if(high[j]>=CurPos && low[j]<=CurPos)
                    {
                     MySize++;
                     TimeToStruct(time[j],tm);
                     if(tm.hour>=13) MySizeAmerica++;
                     else
                        if(tm.hour>=8 && tm.hour<13) MySizeEuropa++;
                     else                         MySizeAzia++;
                    }
                 }

               if(MySizeAzia+MySizeEuropa+MySizeAmerica>MaxSize)
                 {
                  MaxSize=MySizeAzia+MySizeEuropa+MySizeAmerica;
                  Mediana=CurPos;
                 }

               sirname=TimeToString(time[i],TIME_DATE)+string(CurPos);

               if(MySizeAzia!=0)
                  CreateRetangle(0,"rec"+"Azia"+sirname,0,time[i],CurPos,time[i-MySizeAzia],CurPos+onetick,AziaColor,STYLE_SOLID,1,"rec"+"Azia"+sirname);

               if(MySizeEuropa!=0)
                  CreateRetangle(0,"rec"+"Europa"+sirname,0,time[i-MySizeAzia],CurPos,time[i-MySizeAzia-MySizeEuropa],CurPos+onetick,EuropaColor,STYLE_SOLID,1,"rec"+"Europa"+sirname);

               if(MySizeAmerica!=0)
                  CreateRetangle(0,"rec"+"America"+sirname,0,time[i-MySizeAzia-MySizeEuropa],CurPos,time[i-MySizeAzia-MySizeEuropa-MySizeAmerica],CurPos+onetick,AmericaColor,STYLE_SOLID,1,"rec"+"America"+sirname);

               CurPos=CurPos+onetick;
              }

            sirname=TimeToString(time[i],TIME_DATE);
            CreateRetangle(0,"mediana"+sirname,0,time[i],Mediana,time[i+10],Mediana+onetick,Gray,STYLE_SOLID,1,"mediana"+sirname);
            BACK=i+1;
           }
         i++;
         if(i>=rates_total) return(rates_total);
        }
     }
//----
   ChartRedraw(0);
//----   
   return(rates_total);
  }
//+------------------------------------------------------------------+
