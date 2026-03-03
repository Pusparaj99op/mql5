//+------------------------------------------------------------------+
//|                                                   MMLevls_VG.mq4 |
//|                        Copyright © 2006, Vladislav Goshkov (VG). |
//|                                                      4vg@mail.ru |
//|                                        Many thanks to Tim Kruzel |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2006, Vladislav Goshkov (VG)."
//---- link to the website of the author
#property link      "4vg@mail.ru"
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
//+-----------------------------------+
//|  enumeration declaration          |
//+-----------------------------------+
enum STYLE
  {
   STYLE_SOLID_,     // Solid line
   STYLE_DASH_,      // Dashed line
   STYLE_DOT_,       // Dotted line
   STYLE_DASHDOT_,   // Dot-dash line
   STYLE_DASHDOTDOT_ // Dot-dash line with double dots
  };
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int P=90;
input ENUM_TIMEFRAMES MMPeriod=PERIOD_D1;
input int StepBack=0;                    // Bar index for levels calculation
//----
input color  mml_clr_m_2_8 = Gray;       // [-2]/8 level color
input color  mml_clr_m_1_8 = Gray;       // [-1]/8 level color
input color  mml_clr_0_8   = Aqua;       // [0]/8 level color
input color  mml_clr_1_8   = Yellow;     // [1]/8 level color
input color  mml_clr_2_8   = Red;        // [2]/8 level color
input color  mml_clr_3_8   = Green;      // [3]/8 level color
input color  mml_clr_4_8   = Blue;       // [4]/8 level color
input color  mml_clr_5_8   = Green;      // [5]/8 level color
input color  mml_clr_6_8   = Red;        // [6]/8 level color
input color  mml_clr_7_8   = Yellow;     // [7]/8 level color
input color  mml_clr_8_8   = Aqua;       // [8]/8 level color
input color  mml_clr_p_1_8 = Gray;       // [+1]/8 level color
input color  mml_clr_p_2_8 = Gray;       // [+2]/8 level color
//----
input STYLE  mml_style_m_2_8 = STYLE_SOLID;             // [-2]/8 level line style
input STYLE  mml_style_m_1_8 = STYLE_DASHDOTDOT;        // [-1]/8 level line style
input STYLE  mml_style_0_8   = STYLE_DASHDOTDOT;        // [0]/8 level line style
input STYLE  mml_style_1_8   = STYLE_DASHDOTDOT;        // [1]/8 level line style
input STYLE  mml_style_2_8   = STYLE_DASHDOTDOT;        // [2]/8 level line style
input STYLE  mml_style_3_8   = STYLE_DASHDOTDOT;        // [3]/8 level line style
input STYLE  mml_style_4_8   = STYLE_DASHDOTDOT;        // [4]/8 level line style
input STYLE  mml_style_5_8   = STYLE_DASHDOTDOT;        // [5]/8 level line style
input STYLE  mml_style_6_8   = STYLE_DASHDOTDOT;        // [6]/8 level line style
input STYLE  mml_style_7_8   = STYLE_DASHDOTDOT;        // [7]/8 level line style
input STYLE  mml_style_8_8   = STYLE_DASHDOTDOT;        // [8]/8 level line style
input STYLE  mml_style_p_1_8 = STYLE_DASHDOTDOT;        // [+1]/8 level line style
input STYLE  mml_style_p_2_8 = STYLE_SOLID;             // [+2]/8 level line style
//----
input int    mml_wdth_m_2_8 = 1;        // [-2]/8 level width
input int    mml_wdth_m_1_8 = 1;        // [-1]/8 level width
input int    mml_wdth_0_8   = 1;        // [0]/8 level width
input int    mml_wdth_1_8   = 1;        // [1]/8 level width
input int    mml_wdth_2_8   = 1;        // [2]/8 level width
input int    mml_wdth_3_8   = 1;        // [3]/8 level width
input int    mml_wdth_4_8   = 1;        // [4]/8 level width
input int    mml_wdth_5_8   = 1;        // [5]/8 level width
input int    mml_wdth_6_8   = 1;        // [6]/8 level width
input int    mml_wdth_7_8   = 1;        // [7]/8 level width
input int    mml_wdth_8_8   = 1;        // [8]/8 level width
input int    mml_wdth_p_1_8 = 1;        // [+1]/8 level width
input int    mml_wdth_p_2_8 = 1;        // [+2]/8 level width
//----
input color  MarkColor=Red;    // Label color
input int    MarkNumber=217;   // Label index
input string Font= "Arial";    // Levels font
input int    FontSize = 11;    // Font size
//+-----------------------------------+
double dmml,dvtl,sum,v1,v2,mn,mx,x1,
x2,x3,x4,x5,x6,y1,y2,y3,y4,y5,y6,
octave,fractal,range,finalH,finalL,mml[13];

string ln_txt[13],buff_str="";

int bn_v1,bn_v2,OctLinesCnt=13,
mml_thk=8,mml_clr[13],mml_wdth[13],mml_style[13],
mml_shft=35,ntime,CurPeriod,nDigits,NewPeriod,CurPeriod_;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//----
   CurPeriod_=PeriodSeconds(PERIOD_CURRENT)/60;

   if(MMPeriod>0)
      NewPeriod=P*(int)MathCeil(PeriodSeconds(MMPeriod)/PeriodSeconds(PERIOD_CURRENT));
   else NewPeriod=P;

   ln_txt[0]  = "[-2/8]P"; // "Extremely overshoot [-2/8]";// [-2/8]
   ln_txt[1]  = "[-1/8]P"; // "Overshoot [-1/8]";// [-1/8]
   ln_txt[2]  = "[0/8]P";  // "Ultimate Support - extremely oversold [0/8]";// [0/8]
   ln_txt[3]  = "[1/8]P";  // "Weak, Stall and Reverse - [1/8]";// [1/8]
   ln_txt[4]  = "[2/8]P";  // "Pivot, Reverse - major [2/8]";// [2/8]
   ln_txt[5]  = "[3/8]P";  // "Bottom of Trading Range - [3/8], if 10-12 bars then 40% Time. BUY Premium Zone";//[3/8]
   ln_txt[6]  = "[4/8]P";  // "Major Support/Resistance Pivotal Point [4/8]- Best New BUY or SELL level";// [4/8]
   ln_txt[7]  = "[5/8]P";  // "Top of Trading Range - [5/8], if 10-12 bars then 40% Time. SELL Premium Zone";//[5/8]
   ln_txt[8]  = "[6/8]P";  // "Pivot, Reverse - major [6/8]";// [6/8]
   ln_txt[9]  = "[7/8]P";  // "Weak, Stall and Reverse - [7/8]";// [7/8]
   ln_txt[10] = "[8/8]P";  // "Ultimate Resistance - extremely overbought [8/8]";// [8/8]
   ln_txt[11] = "[+1/8]P"; // "Overshoot [+1/8]";// [+1/8]
   ln_txt[12] = "[+2/8]P"; // "Extremely overshoot [+2/8]";// [+2/8]

                           //mml_shft = 3;
   mml_thk=3;

// Initial setting of octaves levels colors and lines width
   mml_clr[0]  = mml_clr_m_2_8;   mml_style[0] = mml_style_m_2_8; mml_wdth[0] = mml_wdth_m_2_8; // [-2]/8
   mml_clr[1]  = mml_clr_m_1_8;   mml_style[1] = mml_style_m_1_8; mml_wdth[1] = mml_wdth_m_1_8; // [-1]/8
   mml_clr[2]  = mml_clr_0_8;     mml_style[2] = mml_style_0_8;   mml_wdth[2] = mml_wdth_0_8;   //  [0]/8
   mml_clr[3]  = mml_clr_1_8;     mml_style[3] = mml_style_1_8;   mml_wdth[3] = mml_wdth_1_8;   //  [1]/8
   mml_clr[4]  = mml_clr_2_8;     mml_style[4] = mml_style_2_8;   mml_wdth[4] = mml_wdth_2_8;   //  [2]/8
   mml_clr[5]  = mml_clr_3_8;     mml_style[5] = mml_style_3_8;   mml_wdth[5] = mml_wdth_3_8;   //  [3]/8
   mml_clr[6]  = mml_clr_4_8;     mml_style[6] = mml_style_3_8;   mml_wdth[6] = mml_wdth_3_8;   //  [4]/8
   mml_clr[7]  = mml_clr_5_8;     mml_style[7] = mml_style_5_8;   mml_wdth[7] = mml_wdth_5_8;   //  [5]/8
   mml_clr[8]  = mml_clr_6_8;     mml_style[8] = mml_style_6_8;   mml_wdth[8] = mml_wdth_6_8;   //  [6]/8
   mml_clr[9]  = mml_clr_7_8;     mml_style[9] = mml_style_7_8;   mml_wdth[9] = mml_wdth_7_8;   //  [7]/8
   mml_clr[10] = mml_clr_8_8;     mml_style[10]= mml_style_8_8;   mml_wdth[10]= mml_wdth_8_8;   //  [8]/8
   mml_clr[11] = mml_clr_p_1_8;   mml_style[11]= mml_style_p_1_8; mml_wdth[11]= mml_wdth_p_1_8; // [+1]/8
   mml_clr[12] = mml_clr_p_2_8;   mml_style[12]= mml_style_p_2_8; mml_wdth[12]= mml_wdth_p_2_8; // [+2]/8
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   for(int i=0; i<OctLinesCnt; i++)
     {
      ObjectDelete(0,"mml"+IntegerToString(i));
      ObjectDelete(0,"mml_txt"+IntegerToString(i));
     }

   ObjectDelete(0,"LR_LatestCulcBar");
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<P) return(0);

//---- indexing elements in arrays as timeseries  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

   int i;

   if((ntime!=time[0]) || (CurPeriod!=CurPeriod_))
     {
      Print("MMLevls : NewPeriod = ",NewPeriod);

      if(NewPeriod>rates_total) NewPeriod=rates_total;

      bn_v1 = ArrayMinimum(low,StepBack,NewPeriod);
      bn_v2 = ArrayMaximum(high,StepBack,NewPeriod);

      v1 = low[bn_v1];
      v2 = high[bn_v2];

      if(v2<=250000 && v2>25000) fractal=100000;
      else
         if(v2<=25000 && v2>2500) fractal=10000;
      else
         if(v2<=2500 && v2>250) fractal=1000;
      else
         if(v2<=250 && v2>25) fractal=100;
      else
         if(v2<=25 && v2>12.5) fractal=12.5;
      else
         if(v2<=12.5 && v2>6.25) fractal=12.5;
      else
         if(v2<=6.25 && v2>3.125) fractal=6.25;
      else
         if(v2<=3.125 && v2>1.5625) fractal=3.125;
      else
         if(v2<=1.5625 && v2>0.390625) fractal=1.5625;
      else
         if(v2<=0.390625 && v2>0) fractal=0.1953125;

      range=v2-v1;
      sum=MathFloor(MathLog(fractal/range)/MathLog(2.0));
      octave=fractal*(MathPow(0.5,sum));
      mn=MathFloor(v1/octave)*octave;

      if(mn+octave>v2)
         mx=mn+octave;
      else mx=mn+(2*octave);

      if((v1>=(3*(mx-mn)/16.0+mn)) && (v2<=(9*(mx-mn)/16+mn)))
         x2=mn+(mx-mn)/2.0;
      else x2=0;

      if((v1>=(mn-(mx-mn)/8.0)) && (v2<=(5*(mx-mn)/8+mn)) && (x2==0))
         x1=mn+(mx-mn)/2.0;
      else x1=0;

      if((v1>=(mn+7*(mx-mn)/16.0)) && (v2<=(13*(mx-mn)/16+mn)))
         x4=mn+3*(mx-mn)/4.0;
      else x4=0;

      if((v1>=(mn+3*(mx-mn)/8.0)) && (v2<=(9*(mx-mn)/8+mn)) && (x4==0))
         x5=mx;
      else x5=0;

      if((v1>=(mn+(mx-mn)/8)) && (v2<=(7*(mx-mn)/8+mn)) && (x1==0) && (x2==0) && (x4==0) && (x5==0))
         x3=mn+3*(mx-mn)/4.0;
      else x3=0;

      if((x1+x2+x3+x4+x5)==0)
         x6=mx;
      else x6=0;

      finalH=x1+x2+x3+x4+x5+x6;

      if(x1>0)
         y1=mn;
      else y1=0;

      if(x2>0)
         y2=mn+(mx-mn)/4.0;
      else y2=0;

      if(x3>0)
         y3=mn+(mx-mn)/4.0;
      else y3=0;

      if(x4>0)
         y4=mn+(mx-mn)/2.0;
      else y4=0;

      if(x5>0)
         y5=mn+(mx-mn)/2.0;
      else y5=0;

      if((finalH>0) && ((y1+y2+y3+y4+y5)==0))
         y6=mn;
      else y6=0;

      finalL=y1+y2+y3+y4+y5+y6;

      for(i=0; i<OctLinesCnt; i++) mml[i]=0;

      dmml=(finalH-finalL)/8.0;
      Print("MMLevls : NewPeriod = ",NewPeriod," dmml = ",dmml," finalL = ",finalL);

      mml[0]=(finalL-dmml*2.0);

      for(i=1; i<OctLinesCnt; i++) mml[i]=mml[i-1]+dmml;

      for(i=0; i<OctLinesCnt; i++)
        {
         buff_str="mml"+IntegerToString(i);
         if(ObjectFind(0,buff_str)==-1)
           {
            ObjectCreate(0,buff_str,OBJ_HLINE,0,time[0],mml[i]);
            ObjectSetInteger(0,buff_str,OBJPROP_COLOR,mml_clr[i]);
            ObjectSetInteger(0,buff_str,OBJPROP_WIDTH,mml_wdth[i]);
            ObjectSetInteger(0,buff_str,OBJPROP_STYLE,mml_style[i]);
            ObjectSetInteger(0,buff_str,OBJPROP_BACK,true);
           }
         else
           {
            ObjectMove(0,buff_str,0,time[0],mml[i]);
           }

         buff_str="mml_txt"+IntegerToString(i);
         if(ObjectFind(0,buff_str)==-1)
           {
            ObjectCreate(0,buff_str,OBJ_TEXT,0,time[mml_shft],mml_shft);
            ObjectSetString(0,buff_str,OBJPROP_TEXT,ln_txt[i]);
            ObjectSetString(0,buff_str,OBJPROP_FONT,Font);
            ObjectSetInteger(0,buff_str,OBJPROP_FONTSIZE,FontSize);
            ObjectSetInteger(0,buff_str,OBJPROP_COLOR,mml_clr[i]);
            ObjectMove(0,buff_str,0,time[mml_shft],mml[i]);
           }
         else
           {
            ObjectMove(0,buff_str,0,time[mml_shft],mml[i]);
           }
        }

      ntime=(int)time[0];
      CurPeriod=CurPeriod_;

      string buff_str_="LR_LatestCulcBar";
      if(ObjectFind(0,buff_str_)==-1)
        {
         ObjectCreate(0,buff_str_,OBJ_ARROW,0,time[StepBack],low[StepBack]-2*_Point);
         ObjectSetInteger(0,buff_str_,OBJPROP_ARROWCODE,MarkNumber);
         ObjectSetInteger(0,buff_str_,OBJPROP_COLOR,MarkColor);
        }
      else
        {
         ObjectMove(0,buff_str_,0,time[StepBack],low[StepBack]-2*_Point);
        }
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
