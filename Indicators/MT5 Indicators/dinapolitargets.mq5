//+------------------------------------------------------------------+
//|                                              DinapoliTargets.mq5 |
//+------------------------------------------------------------------+
#property copyright "mishanya"
#property link      "mishanya_fx@yahoo.com"
#property version   "1.01"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_label1  "DinapoliTargets"
#property indicator_type1   DRAW_SECTION
#property indicator_color1  Blue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input int      barn=300;
input int      Length=6;
//---- buffers
double ExtMapBuffer[];
//----
string Name[5]={"Start Line","Stop line","Target1 Line","Target2 Line","Target3 Line"};
color Color[5]={Honeydew,Red,Green,Yellow,DarkOrchid};
double Price[5];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMapBuffer,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetString(0,PLOT_LABEL,"DinapoliTargets("+(string)Length+")");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   for(int i=0;i<5;i++) ObjectDelete(0,Name[i]);
   return;
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &open[],
                const double &High[],
                const double &Low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(rates_total<barn) return(0);
   if(prev_calculated==0) ArrayInitialize(ExtMapBuffer,0.0);
   datetime Time0;
   int shift,Swing,Swing_n,uzl,i,zu,zd;
   double PointA,PointB,PointC;
   double LL,HH,BH,BL,Spread;
   double Uzel[10000];

//--- loop from first bar to current bar (with shift=0) 
   Swing_n=0;Swing=0;uzl=0;
   i=rates_total-barn-1;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,i);
   BH=High[i];BL=Low[i];zu=i;zd=i;
//----
   for(shift=i;shift<rates_total;shift++)
     {
      LL=10000000;HH=-100000000;
      for(i=shift-Length;i<shift;i++)
        {
         if(Low[i]< LL) {LL=Low[i];}
         if(High[i]>HH) {HH=High[i];}
        }
      if(Low[shift]<LL && High[shift]>HH)
        {
         Swing=2;
         if(Swing_n==1) {zu=shift-1;}
         if(Swing_n==-1) {zd=shift-1;}
        }
      else
        {
         if(Low[shift]<LL) {Swing=-1;}
         if(High[shift]>HH) {Swing=1;}
        }
      if(Swing!=Swing_n && Swing_n!=0)
        {
         if(Swing==2)
           {
            Swing=-Swing_n;BH=High[shift];BL=Low[shift];
           }
         uzl++;
         if(Swing==1)
           {
            Uzel[uzl]=BL;
            ExtMapBuffer[zd]=BL;
           }
         if(Swing==-1)
           {
            Uzel[uzl]=BH;
            ExtMapBuffer[zu]=BH;
           }
         BH=High[shift];
         BL=Low[shift];
        }
      if(Swing==1)
        {
         if(High[shift]>=BH) {BH=High[shift];zu=shift;}
        }
      if(Swing==-1)
        {
         if(Low[shift]<=BL) {BL=Low[shift]; zd=shift;}
        }
      Swing_n=Swing;
     }
//----
   PointA=Uzel[uzl-2];
   PointB=Uzel[uzl-1];
   PointC=Uzel[uzl];
   Comment(PointA," ",PointB," ",PointC);
//----
   Price[2]=NormalizeDouble((PointB-PointA)*0.618+PointC,_Digits);//Target1
   Price[3]=PointB-PointA+PointC;//Target2
   Price[4]=NormalizeDouble((PointB-PointA)*1.618+PointC,_Digits);//Target3
                                                                  //Fantnsy=NormalizeDouble((PointB-PointA)*2.618+PointC,_Digits);
   Spread=SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)*_Point;
   if(PointB<PointC)
     {
      Price[0]=NormalizeDouble((PointB-PointA)*0.318+PointC,_Digits)-Spread;//Start
      Price[1]=PointC+2*Spread;//Stop
     }
   if(PointB>PointC)
     {
      Price[0]=NormalizeDouble((PointB-PointA)*0.318+PointC,_Digits)+Spread;//Start
      Price[1]=PointC-2*Spread;//Stop
     }
//+----
   Time0=Time[rates_total-1];
   for(i=0;i<5;i++)
     {
      if(ObjectFind(0,Name[i])!=0)
        {
         ObjectCreate(0,Name[i],OBJ_HLINE,0,Time0,Price[i]);
         ObjectSetInteger(0,Name[i],OBJPROP_COLOR,Color[i]);
         ObjectSetInteger(0,Name[i],OBJPROP_WIDTH,1);
         ObjectSetInteger(0,Name[i],OBJPROP_STYLE,STYLE_DOT);
        }
      else ObjectMove(0,Name[i],0,Time0,Price[i]);
     }
   ChartRedraw();
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
