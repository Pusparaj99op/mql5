//+------------------------------------------------------------------+
//|                                                    multi_usd_ind |
//|                                           Copyright 2014 Winston |
//+------------------------------------------------------------------+
#property copyright "Winston"
#property version "1.10"
#property description "Multi Currency Indicator with USD reference"
#property indicator_separate_window
#property indicator_level1 0.001; // 0.1% lines
#property indicator_level2 -0.001;
#property indicator_level3 0.01;  //  1% lines
#property indicator_level4 -0.01;
#property indicator_level5 0.1;   // 10% lines
#property indicator_level6 -0.1; 
#property indicator_label1 "USD"
#property indicator_buffers 7
#property indicator_plots   7
#property indicator_type1   DRAW_LINE
#property indicator_color1  Orange     // AUDUSD
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_type2   DRAW_LINE
#property indicator_color2  White      // EURUSD
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_type3   DRAW_SECTION
#property indicator_color3  Red        // GBPUSD
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_type4   DRAW_LINE
#property indicator_color4  Yellow     // NZDUSD
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_type5   DRAW_LINE
#property indicator_color5  Aqua       // USDCAD inverted
#property indicator_style5  STYLE_DOT
#property indicator_width5  1
#property indicator_type6   DRAW_SECTION
#property indicator_color6  SpringGreen // USDCHF inverted
#property indicator_style6  STYLE_DOT
#property indicator_width6  1
#property indicator_type7   DRAW_SECTION
#property indicator_color7  Violet     // USDJPY inverted
#property indicator_style7  STYLE_DOT
#property indicator_width7  1
//---
input double k=1.0; // Smoothing factor
input int p=60;     // Period
//---
int T,n=p;
double aug[],eug[],gug[],nug[],cug[],hug[],jug[]; // Display indicators
//---
MqlRates AU[],EU[],GU[],NU[],UC[],UH[],UJ[];
MqlDateTime tim;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
   ArraySetAsSeries(aug,true);
   ArraySetAsSeries(eug,true);
   ArraySetAsSeries(gug,true);
   ArraySetAsSeries(nug,true);
   ArraySetAsSeries(cug,true);
   ArraySetAsSeries(hug,true);
   ArraySetAsSeries(jug,true);
//---
   SetIndexBuffer(0,aug,INDICATOR_DATA);
   SetIndexBuffer(1,eug,INDICATOR_DATA);
   SetIndexBuffer(2,gug,INDICATOR_DATA);
   SetIndexBuffer(3,nug,INDICATOR_DATA);
   SetIndexBuffer(4,cug,INDICATOR_DATA);
   SetIndexBuffer(5,hug,INDICATOR_DATA);
   SetIndexBuffer(6,jug,INDICATOR_DATA);
//---
   ArraySetAsSeries(AU,true);
   ArraySetAsSeries(EU,true);
   ArraySetAsSeries(GU,true);
   ArraySetAsSeries(NU,true);
   ArraySetAsSeries(UC,true);
   ArraySetAsSeries(UH,true);
   ArraySetAsSeries(UJ,true);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,"AUD-org EUR-wht GBP-red NZD-yel CAD-blu CHF-green JPY-vio");
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   TimeCurrent(tim);
   if(T!=tim.min)
     {
      T=tim.min;
      n++;
     }
//---
   ArrayInitialize(aug,0);
   ArrayInitialize(eug,0);
   ArrayInitialize(gug,0);
   ArrayInitialize(nug,0);
   ArrayInitialize(cug,0);
   ArrayInitialize(hug,0);
   ArrayInitialize(jug,0);
//---
   CopyRates("AUDUSD",0,0,n+1,AU);
   CopyRates("EURUSD",0,0,n+1,EU);
   CopyRates("GBPUSD",0,0,n+1,GU);
   CopyRates("NZDUSD",0,0,n+1,NU);
   CopyRates("USDCAD",0,0,n+1,UC);
   CopyRates("USDCHF",0,0,n+1,UH);
   CopyRates("USDJPY",0,0,n+1,UJ);
//---
   double au=0,eu=0,gu=0,nu=0,uc=0,uh=0,uj=0;
//---
   for(int i=n;i>=0;i--)
     {
      if(AU[i].close*AU[n].close>0){au+=k*(1-AU[n].close/AU[i].close-au); aug[i]=au;}
      if(EU[i].close*EU[n].close>0){eu+=k*(1-EU[n].close/EU[i].close-eu); eug[i]=eu;}
      if(GU[i].close*GU[n].close>0){gu+=k*(1-GU[n].close/GU[i].close-gu); gug[i]=gu;}
      if(NU[i].close*NU[n].close>0){nu+=k*(1-NU[n].close/NU[i].close-nu); nug[i]=nu;}
      if(UC[i].close*UC[n].close>0){uc+=k*(1-UC[i].close/UC[n].close-uc); cug[i]=uc;}
      if(UH[i].close*UH[n].close>0){uh+=k*(1-UH[i].close/UH[n].close-uh); hug[i]=uh;}
      if(UJ[i].close*UJ[n].close>0){uj+=k*(1-UJ[i].close/UJ[n].close-uj); jug[i]=uj;}
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
