//+------------------------------------------------------------------+
//|                                                      JPTrend.mq5 |
//|                                               Xynium@laposte.net |
//+------------------------------------------------------------------+
#property copyright "2012, JPLathuile"
#property link "xynium@laposte.net"
#property version "1.00"
#property description "The indicator places support and resistant lines."
#property description "JP LATHUILE  Xynium@laposte.net"

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_label1  "JPTrend"

input int ipDimMaxPos=150;        // Max bars, used in analysis
input bool bAlertAuto=false;      // Auto alert
input double dAlertSeuil=0.0002;  // Trend deviation to alert
input color  clrSup= 0xFF0000;    // Color of support line
input color  clrRes= 0x0000FF;    // Color of resistance lines

double A,B;
int C[],D[];
bool bb;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
   ArrayResize(C,ipDimMaxPos,1);
   ArrayResize(D,ipDimMaxPos,1);
   IndicatorSetString(INDICATOR_SHORTNAME,"JPTrend");
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,0,OBJ_TREND);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   int icpt,limit,i;
   int icpu,iTc,iTcc;
   double paula,dy,fg;
   bool Claudia;
   string sName;
   int  iTP=1;

   if(rates_total<100) return(0);   //--- check for data

   if(prev_calculated==0) limit=0;
   else limit=prev_calculated;
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      if(i<20) continue;
      if(High[i]>A) C[0]=i;
      else { Lucie(); bb=true;  }
      A=High[i];
      if(Low[i]<B) D[0]=i;
      else {  Jane();bb=true; }
      B=Low[i];
     }

   if(bb)
     {
      ObjectsDeleteAll(0,0,OBJ_TREND);
      iTc=(3*ipDimMaxPos)/4;
      for(icpt=iTc;icpt>(iTP+1);icpt--)
        {
         for(icpu=icpt-1;icpu>iTP;icpu--)
           {
            fg=(double)(C[icpu]-C[icpt]);
            if(fg<=6) continue;
            paula=High[C[icpu]]-High[C[icpt]];
            Claudia=true;
            iTcc=(ipDimMaxPos+2*icpt)/3;
            for(i=iTcc;i>1;i--)
              {
               dy=paula*(C[i]-C[icpt])/fg+High[C[icpt]];
               if(dy<High[C[i]]){ Claudia=false; break;}
              }
            if(Claudia)
              {
               dy=paula*((double)(rates_total-1-C[icpt]))/fg+High[C[icpt]];
               if((dy>ChartGetDouble(0,CHART_PRICE_MAX,0)) || (dy<ChartGetDouble(0,CHART_PRICE_MIN,0))) Claudia=false;
               if((fabs(dy-High[rates_total-1])<dAlertSeuil) && (bAlertAuto)) Alert("Resistance reached");
              }
            if(Claudia)
              {
               sName="R"+IntegerToString(icpt,0,' ')+IntegerToString(icpu,0,' ');
               ObjectCreate(0,sName,OBJ_TREND,0,Time[C[icpt]],High[C[icpt]],Time[C[icpu]],High[C[icpu]]);
               ObjectSetInteger(0,sName,OBJPROP_RAY_RIGHT,true);
               ObjectSetInteger(0,sName,OBJPROP_COLOR,clrRes);
              }
           }
        }

      iTc=(3*ipDimMaxPos)/4;
      for(icpt=iTc;icpt>2;icpt--)
        {
         for(icpu=icpt-1;icpu>1;icpu--)
           {
            fg=(double)(D[icpu]-D[icpt]);
            if(fg<10) continue;
            paula=Low[D[icpu]]-Low[D[icpt]];
            Claudia=true;
            iTcc=(ipDimMaxPos+2*icpt)/3;  //down to depart
            for(i=iTcc;i>0;i--)
              {
               dy=(paula*((double)(D[i]-D[icpt])))/fg+Low[D[icpt]];
               if(dy>Low[D[i]]){ Claudia=false; break;}
              }
            if(Claudia)
              {
               dy=paula*((double)(rates_total-1-D[icpt]))/fg+Low[D[icpt]];
               if((dy>ChartGetDouble(0,CHART_PRICE_MAX,0)) || (dy<ChartGetDouble(0,CHART_PRICE_MIN,0))) Claudia=false;
               if((fabs(dy-Low[rates_total-1])<dAlertSeuil) && bAlertAuto) Alert("Support reached");
              }
            if(Claudia)
              {
               sName="S"+IntegerToString(icpt,0,' ')+IntegerToString(icpu,0,' ');
               ObjectCreate(0,sName,OBJ_TREND,0,Time[D[icpt]],Low[D[icpt]],Time[D[icpu]],Low[D[icpu]]);
               ObjectSetInteger(0,sName,OBJPROP_RAY_RIGHT,true);
               ObjectSetInteger(0,sName,OBJPROP_COLOR,clrSup);
              }
           }
        }

      bb=false;
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Lucie                                                            |
//+------------------------------------------------------------------+
void Lucie()
  {
   int it;

   for(it=ipDimMaxPos-1;it>0;it--)
     {
      C[it]=C[it-1];
     }
  }
//+------------------------------------------------------------------+
//| Jane                                                             |
//+------------------------------------------------------------------+
void Jane()
  {
   int it;

   for(it=ipDimMaxPos-1;it>0;it--)
     {
      D[it]=D[it-1];
     }
  }
//+------------------------------------------------------------------+
