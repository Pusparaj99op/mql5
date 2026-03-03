//------------------------------------------------------------------------------------
//                                                       V_FastZZ_2DinapoliTargets.mq5
//                                                   The modified indicator FastZZ.mq5
//                                       Added DiNapoli Target Levels and Time Targets
//                                                         victorg, www.mql5.com, 2013
//------------------------------------------------------------------------------------
#property copyright   "Copyright 2012, Yurich"
#property link        "https://login.mql5.com/ru/users/Yurich"
#property version     "1.00"
#property description "FastZZ plus DiNapoli Target Levels."
#property description "The modified indicator FastZZ.mq5."
//------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Fast ZZ"
#property indicator_type1   DRAW_ZIGZAG
#property indicator_color1  clrTeal
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//------------
input int    Depth=500;               // Minimum points in a ray
input bool   VLine=true;              // Show the vertical lines
input bool   Sound=true;              // Play sound
input string SoundFile="expert.wav";  // Sound file
input color  cStar=clrHoneydew;       // Start Line color
input color  cStop=clrRed;            // Stop Line color
input color  cTar1=clrGreen;          // Target1 Line color
input color  cTar2=clrDarkOrange;     // Target2 Line color
input color  cTar3=clrDarkOrchid;     // Target3 Line color
input color  cTar4=clrDarkSlateBlue;  // Target4 Line color
input color  cTarT1=clrDarkSlateGray; // Time Target1 color
input color  cTarT2=clrDarkSlateGray; // Time Target2 color
input color  cTarT3=clrDarkSlateGray; // Time Target3 color
input color  cTarT4=clrDarkSlateGray; // Time Target4 color
input color  cTarT5=clrDarkSlateGray; // Time Target4 color
//------------
double   zzH[],zzL[],depth,A,B,C,Price[6];
int      last,direction,Refresh;
datetime AT,BT,CT,Time[5];
color    Color[11];
string   Name[11]={"Start Line","Stop Line","Target1 Line","Target2 Line",
                   "Target3 Line","Target4 Line","Time Target1","Time Target2",
                   "Time Target3","Time Target4","Time Target5"};
//------------------------------------------------------------------------------------
void OnInit()
  {
  int i;

  SetIndexBuffer(0,zzH,INDICATOR_DATA);
  SetIndexBuffer(1,zzL,INDICATOR_DATA);
  IndicatorSetInteger(INDICATOR_DIGITS,Digits());
  PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
  PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
  Color[0]=cStar; Color[1]=cStop; Color[2]=cTar1; Color[3]=cTar2;
  Color[4]=cTar3; Color[5]=cTar4; Color[6]=cTarT1; Color[7]=cTarT2;
  Color[8]=cTarT3; Color[9]=cTarT4; Color[10]=cTarT5;
  depth=Depth*_Point;
  direction=1; last=0; Refresh=1;
  for(i=0;i<6;i++)
    {
    if(ObjectFind(0,Name[i])!=0)
      {
      ObjectCreate(0,Name[i],OBJ_HLINE,0,0,0);
      ObjectSetInteger(0,Name[i],OBJPROP_COLOR,Color[i]);
      ObjectSetInteger(0,Name[i],OBJPROP_WIDTH,1);
      ObjectSetInteger(0,Name[i],OBJPROP_STYLE,STYLE_DOT);
//    ObjectSetString(0,Name[i],OBJPROP_TEXT,Name[i]);     // Object Description
      }
    }
  if(VLine==true)
    {
    for(i=6;i<11;i++)
      {
      if(ObjectFind(0,Name[i])!=0)
        {
        ObjectCreate(0,Name[i],OBJ_VLINE,0,0,0);
        ObjectSetInteger(0,Name[i],OBJPROP_COLOR,Color[i]);
        ObjectSetInteger(0,Name[i],OBJPROP_WIDTH,1);
        ObjectSetInteger(0,Name[i],OBJPROP_STYLE,STYLE_DOT);
//      ObjectSetString(0,Name[i],OBJPROP_TEXT,Name[i]);     // Object Description
        }
      }
    }
  }
//------------------------------------------------------------------------------------
void OnDeinit(const int reason)
  {
  int i;
   
  for(i=0;i<11;i++) ObjectDelete(0,Name[i]);
  ChartRedraw();
  return;
  }
//------------------------------------------------------------------------------------
int OnCalculate(const int total,
                const int calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick[],
                const long &real[],
                const int &spread[])
  {
  int i;
  bool set;
  double a;
   
  if(calculated==0) last=0;
  for(i=calculated>0?calculated-1:0;i<total-1;i++)
    {
    set=false; zzL[i]=0; zzH[i]=0;
    if(direction>0)
      {
      if(high[i]>zzH[last])
        {
        zzH[last]=0; zzH[i]=high[i];
        if(low[i]<high[last]-depth)
          {
          if(open[i]<close[i])
            {
            zzH[last]=high[last];
            A=C; B=high[last]; C=low[i];
            AT=CT; BT=time[last]; CT=time[i];
            Refresh=1;
            }
          else
            {
            direction=-1;
            A=B; B=C; C=high[i];
            AT=BT; BT=CT; CT=time[i];
            Refresh=1;
            }
          zzL[i]=low[i];
          }
        last=i; set=true;
        }
      if(low[i]<zzH[last]-depth&&(!set||open[i]>close[i]))
        {
        zzL[i]=low[i];
        if(high[i]>zzL[i]+depth&&open[i]<close[i])
          {
          zzH[i]=high[i];
          A=C; B=high[last]; C=low[i];
          AT=CT; BT=time[last]; CT=time[i];
          Refresh=1;
          }
        else
          {
          if(direction>0)
            {
            A=B; B=C; C=high[last];
            AT=BT; BT=CT; CT=time[last];
            Refresh=1;
            }
          direction=-1;
          }
        last=i;
        }
      }
    else
      {
      if(low[i]<zzL[last])
        {
        zzL[last]=0; zzL[i]=low[i];
        if(high[i]>low[last]+depth)
          {
          if(open[i]>close[i])
            {
            zzL[last]=low[last];
            A=C; B=low[last]; C=high[i];
            AT=CT; BT=time[last]; CT=time[i];
            Refresh=1;
            }
          else
            {
            direction=1;
            A=B; B=C; C=low[i];
            AT=BT; BT=CT; CT=time[i];
            Refresh=1;
            }
          zzH[i]=high[i];
          }
        last=i; set=true;
        }
      if(high[i]>zzL[last]+depth&&(!set||open[i]<close[i]))
        {
        zzH[i]=high[i];
        if(low[i]<zzH[i]-depth&&open[i]>close[i])
          {
          zzL[i]=low[i];
          A=C; B=low[last]; C=high[i];
          AT=CT; BT=time[last]; CT=time[i];
          Refresh=1;
          }
        else
          {
          if(direction<0)
            {
            A=B; B=C; C=low[last];
            AT=BT; BT=CT; CT=time[last];
            Refresh=1;
            }
          direction=1;
          }
        last=i;
        }
      }
    zzH[total-1]=0; zzL[total-1]=0;
    }
//------------
  if(Refresh==1)
    {
    Refresh=0; a=B-A;
    Price[0]=NormalizeDouble(a*0.318+C,_Digits);           // Start;
    Price[1]=C;                                            // Stop
    Price[2]=NormalizeDouble(a*0.618+C,_Digits);           // Target1
    Price[3]=a+C;                                          // Target2;
    Price[4]=NormalizeDouble(a*1.618+C,_Digits);           // Target3;
    Price[5]=NormalizeDouble(a*2.618+C,_Digits);           // Target4;
    for(i=0;i<6;i++) ObjectMove(0,Name[i],0,time[total-1],Price[i]);
    if(VLine==true)
      {
      a=(double)(BT-AT);
      Time[0]=(datetime)MathRound(a*0.318)+CT;             // Time Target1
      Time[1]=(datetime)MathRound(a*0.618)+CT;             // Time Target2
      Time[2]=(datetime)MathRound(a)+CT;                   // Time Target3
      Time[3]=(datetime)MathRound(a*1.618)+CT;             // Time Target4
      Time[4]=(datetime)MathRound(a*2.618)+CT;             // Time Target5
      for(i=6;i<11;i++) ObjectMove(0,Name[i],0,Time[i-6],open[total-1]);
      }
    ChartRedraw();
    // If the direction is changed, then play the sound.
    if(Sound==true)PlaySound(SoundFile);
    }
  return(total);
  }
//------------------------------------------------------------------------------------

