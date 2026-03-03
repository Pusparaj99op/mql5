//+------------------------------------------------------------------+
//|                                                       Trade Time |
//|                                           Copyright 2012,Karlson |
//+------------------------------------------------------------------+
#property description "Trade Time"
#property version "1.00"
#property copyright   "2012, Karlson."
#property link        "https://login.mql5.com/ru/users/Karlson"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

input int st=8;                   // Trade Starttime
input int en=20;                  // Trade Stoptime
input color cl =  clrSteelBlue;   // Color
input bool fill = false;          // Filling 

double hg[]={0},lw[]={0};
int dist;datetime ttt=0;
MqlDateTime time={0};
string start=NULL;
string end=NULL;
datetime dd[];
//+------------------------------------------------------------------+
//| MI initialization function                                       |
//+------------------------------------------------------------------+
void OnInit()
  {
   if(st>=en || st<0 || en>24) Print("Wrong parameters.");
   
   dist=(en-st)*3600; // calculate the distance of the rectangle
   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
   int limit;
   if(prev_calculated<1) {limit=0; } else {limit=prev_calculated-1;}

   for(int i=limit; i<rates_total; i++)
     {
      // calculations of previous days

      TimeToStruct(Time[i],time); // getting the bar time to determine the hour

      if(time.hour==st && time.min==0) // check the time against the trade start time
        {
         // determine the high and low of the day at the current moment of the trade start time
         
         if(CopyHigh(_Symbol,PERIOD_D1,Time[i],1,hg)<1) return(0);
         if(CopyLow(_Symbol,PERIOD_D1,Time[i],1,lw)<1) return (0);
         
         // calculate the rectangle end date
         
         ttt=Time[i]+dist;
         
         // draw previous rectangles
         
         ObjectCreate(0,"rec"+(string)Time[i],OBJ_RECTANGLE,0,Time[i],hg[0],ttt,lw[0]);
         ObjectSetInteger(0,"rec"+(string)Time[i],OBJPROP_COLOR,cl);
         ObjectSetInteger(0,"rec"+(string)Time[i],OBJPROP_FILL,fill);
        }

      // current day calculations with recalculations of the high and low.

      if(limit>rates_total-2)
        {

         // determine the high and low for the current trade day
         
         if(CopyLow(_Symbol,PERIOD_D1,Time[rates_total-1],1,lw)<1) return(0);
         if(CopyHigh(_Symbol,PERIOD_D1,Time[rates_total-1],1,hg)<1) return(0);
         
         //Print("DayLow=",lw[0],"   DayHigh=",hg[0]);
         
         // generate the rectangle start date-time of the current day

         string a=TimeToString(Time[rates_total-1]);
         string b=StringSubstr(a,0,11);
         string c=b+(string)st+":00";
         datetime t=StringToTime(c);
         
         // calculate the rectangle end date-time

         ttt=t+dist;
         
         // draw the current rectangle
         
         ObjectDelete(0,"rec"+(string)t);
         
         ObjectCreate(0,"rec"+(string)t,OBJ_RECTANGLE,0,t,hg[0],ttt,lw[0]);
         ObjectSetInteger(0,"rec"+(string)t,OBJPROP_COLOR,cl);
         ObjectSetInteger(0,"rec"+(string)t,OBJPROP_FILL,fill);
         
         ChartRedraw(0);
        }

     }
   ChartRedraw(0);

   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // delete the rectangles drawn 
   
   for(int i=ObjectsTotal(0,0,-1);i>0;i--)
     {
      string name=ObjectName(0,i-1,0,-1);
      if(StringFind(name,"rec",0)>-1) {ObjectDelete(0,name);}
     }

   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
