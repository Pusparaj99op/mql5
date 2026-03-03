//+------------------------------------------------------------------+
//|                                                      iSpread.mq5 |
//|                                                    A.V. Oreshkin |
//|                                                   vk.com/mtforex |
//+------------------------------------------------------------------+
#property copyright "A.V. Oreshkin"
#property link      "vk.com/mtforex"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers   15
#property indicator_plots     7
#property indicator_label1    "SNT";
#property indicator_label2    "L1 UP";
#property indicator_label3    "L2 UP";
#property indicator_label4    "L3 UP";
#property indicator_label5    "L1 DN";
#property indicator_label6    "L2 DN";
#property indicator_label7    "L3 DN";
#property indicator_color1    clrAqua
#property indicator_color2    clrRed
#property indicator_color3    clrYellow
#property indicator_color4    clrGreen
#property indicator_color5    clrRed
#property indicator_color6    clrYellow
#property indicator_color7    clrGreen
#property indicator_style1    STYLE_SOLID
#property indicator_style2    STYLE_SOLID
#property indicator_style3    STYLE_SOLID
#property indicator_style4    STYLE_SOLID
#property indicator_style5    STYLE_SOLID
#property indicator_style6    STYLE_SOLID
#property indicator_style7    STYLE_SOLID
#property indicator_type1     DRAW_LINE
#property indicator_type2     DRAW_LINE
#property indicator_type3     DRAW_LINE
#property indicator_type4     DRAW_LINE
#property indicator_type5     DRAW_LINE
#property indicator_type6     DRAW_LINE
#property indicator_type7     DRAW_LINE
#property indicator_width1    1
#property indicator_width2    1
#property indicator_width3    1
#property indicator_width4    1
#property indicator_width5    1
#property indicator_width6    1
#property indicator_width7    1
#property indicator_level1    0
#property indicator_level2    1
#property indicator_level3    -1
//+------------------------------------------------------------------+
//| enum MOVE                                                        |
//+------------------------------------------------------------------+
enum MOVE
  {
   Subtract=1,  //Difference
   Add=2,       //Sum   
   Multiply=3,  //Product
   Divizion=4   //Ratio
  };
//+------------------------------------------------------------------+
//| enum DET                                                         |
//+------------------------------------------------------------------+
enum DET
  {
   Returns=1,   //The first difference
   DeTrend=2    //Detrend using a simple MA
  };
//+------------------------------------------------------------------+
//| enum LVL                                                         |
//+------------------------------------------------------------------+
enum LVL
  {
   Norm=1,      //Normalization to 0..1 with an offset
   MaxMin=2,    //Levels of extrema
                //CKO=3      //Calculation of mean square deviation is not used. 1 - levels are narrowed and 2 - long calculation
  };
input datetime BeginTime      =  D'2013.01.01'; //Date to start
input string   Symbol1        =  "GBPUSD";      //Symbol 1
input string   Symbol2        =  "EURUSD";      //Symbol 2
input MOVE     Action         =  Divizion;      //Action
input bool     Invert1        =  false;         //Reverse of symbol 1
input bool     Invert2        =  false;         //Reverse of symbol 2
input double   Pow1           =  1;             //Power of symbol 1
input double   Pow2           =  1;             //Power of symbol 2
input double   Multi1         =  1;             //Multiplier of symbol 1
input double   Multi2         =  1;             //Multiplier of symbol 2
input bool     Ln             =  false;         //The logarithm
input uint     Average        =  3;             //Smoothing.Period
input DET      Algo           =  DeTrend;       //Selecting an algorithm
input uint     Window         =  288;           //Period for the algorithm
input bool     Screen_Levels  =  true;          //Show levels
input LVL      Method         =  Norm;          //Levels calculation method
input double   Levels         =  1;             //Ratio of levels

bool     Error_Init=true;
datetime BeginDate=0;
double   BF[], //The final array for the output
PR1[],PR2[],   //Arrays of initial data after mathematical processing
PRA1[],PRA2[], //Arrays PR1 and PR2 smoothed by a MA
CALC[],        //Output here either after a detrend or after the first difference
DTR[],         //An array after detrend
LG1[],LG2[],   //An array for first differences
max,min,       //Extreme for normalization
L1up[],L2up[],L3up[],L1dn[],L2dn[],L3dn[];//arrays for the levels
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Error_Init=true;
   LOAD_DATA();
   max=-10000;min=10000;
   IndicatorSetString(INDICATOR_SHORTNAME,NAME());
   SetIndexBuffer(0,BF,INDICATOR_DATA);
   SetIndexBuffer(1,L1up,INDICATOR_DATA);
   SetIndexBuffer(2,L2up,INDICATOR_DATA);
   SetIndexBuffer(3,L3up,INDICATOR_DATA);
   SetIndexBuffer(4,L1dn,INDICATOR_DATA);
   SetIndexBuffer(5,L2dn,INDICATOR_DATA);
   SetIndexBuffer(6,L3dn,INDICATOR_DATA);
   SetIndexBuffer(7,PR1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,PR2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,PRA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,PRA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,CALC,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,DTR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,LG1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,LG2,INDICATOR_CALCULATIONS);
//---
   ArraySetAsSeries(BF,false);
   ArraySetAsSeries(PR1,false);
   ArraySetAsSeries(PR2,false);
   ArraySetAsSeries(PRA1,false);
   ArraySetAsSeries(PRA2,false);
   ArraySetAsSeries(CALC,false);
   ArraySetAsSeries(DTR,false);
   ArraySetAsSeries(LG1,false);
   ArraySetAsSeries(LG2,false);
   ArraySetAsSeries(L1up,false);
   ArraySetAsSeries(L2up,false);
   ArraySetAsSeries(L3up,false);
   ArraySetAsSeries(L1dn,false);
   ArraySetAsSeries(L2dn,false);
   ArraySetAsSeries(L3dn,false);
//---
   ZeroMemory(L1up);
   ZeroMemory(L2up);
   ZeroMemory(L3up);
   ZeroMemory(L1dn);
   ZeroMemory(L2dn);
   ZeroMemory(L3dn);
//---
   return(INIT_SUCCEEDED);
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
   if(Error_Init) LOAD_DATA();
   if(Error_Init) return(INIT_FAILED); //Initialization error

   double pr1[1],pr2[1];
   int x1,x2;
   int limit=prev_calculated;
   if(limit>1) limit=limit-2;

//--- step 1 - data preparation
   for(int pos=1+limit;pos<rates_total;pos++)
     {//preparing initial data
      if(time[pos]<BeginDate)
        {
         EMTF(pos);
         continue;
        }
      //---
      x1=CopyClose(Symbol1,PERIOD_CURRENT,time[pos],1,pr1);
      x2=CopyClose(Symbol2,PERIOD_CURRENT,time[pos],1,pr2);
      if(x1<=0 || x2<=0)
        {
         EMTF(pos);
         Print("Data omission: "+string(time[pos]));
         continue;
        }
      if(pr1[0]==0 || pr2[0]==0)
        {
         EMTF(pos);
         Print("Zero data received: "+string(time[pos]));
         continue;
        }

      PR1[pos]=MODIFY(pr1[0],Invert1,Pow1,Multi1);
      PR2[pos]=MODIFY(pr2[0],Invert2,Pow2,Multi2);
     }//preparing initial data

//--- smoothing the received data
   if(Average>1) for(int pos=1+limit;pos<rates_total;pos++) MA(pos);
   else
     {
      ArrayCopy(PRA1,PR1,0,0,WHOLE_ARRAY);
      ArrayCopy(PRA2,PR2,0,0,WHOLE_ARRAY);
     }
//--- merge two arrays into one
   for(int pos=1+limit;pos<rates_total;pos++) CALC[pos]=ACTION(PRA1[pos],PRA2[pos]);

//--- Data preparation completed. Next - the converting and getting the synthetic
//--- step 2 - creating the synthetic symbol
//--- depending on what we select, either detrend using the MA or calculate the difference
   if(Algo==DeTrend && Window>1)
     {
      for(int pos=1+limit;pos<rates_total;pos++)
        {
         DT(pos);
         if(DTR[pos]==EMPTY_VALUE)BF[pos]=EMPTY_VALUE;
         else BF[pos]=DTR[pos];
        }
     }
   else
   if(Algo==Returns && Window>0)
     {
      for(int pos=1+limit;pos<rates_total;pos++)
        {
         LAG(pos);
         if(LG1[pos]==EMPTY_VALUE || LG2[pos]==EMPTY_VALUE) BF[pos]=EMPTY_VALUE;
         else BF[pos]=LG1[pos]/LG2[pos]-1;
        }
     }
   else  ArrayCopy(BF,CALC,0,0,WHOLE_ARRAY);

//--- step 3 - calculate the deviation levels
   if(Screen_Levels && Window!=0)//If we need to draw the levels, let's start to calculate them
     {//Screen_Levels
      for(int pos=1+limit;pos<rates_total;pos++)
        {
         if(BF[pos]==EMPTY_VALUE)
           {
            LCLEAR(pos);
            continue;
           }
         if(Method<=2)
           {
            //--- we have defined the current extremes
            if(BF[pos]>max) max=BF[pos];
            if(BF[pos]<min) min=BF[pos];

            if(Method==Norm)
               if(max-min!=0 && max!=-10000 && min!=10000)
                 {//Norm
                  BF[pos]=(BF[pos]-min)/(max-min)-0.5;
                  L1up[pos]=0.125*Levels;
                  L2up[pos]=2*L1up[pos];
                  L3up[pos]=3*L1up[pos];
                  L1dn[pos]=-L1up[pos];
                  L2dn[pos]=-L2up[pos];
                  L3dn[pos]=-L3up[pos];
                 }//Norm
            else  LCLEAR(pos);

            if(Method==MaxMin)
               if(max!=-10000 && min!=10000)
                 {//MaxMin               
                  L1up[pos]=MathMax(MathAbs(max),MathAbs(min))/4*Levels;
                  L2up[pos]=2*L1up[pos];
                  L3up[pos]=3*L1up[pos];
                  L1dn[pos]=-L1up[pos];
                  L2dn[pos]=-L2up[pos];
                  L3dn[pos]=-L3up[pos];
                 }//MaxMin 
            else  LCLEAR(pos);
           }
        }
     }//Screen_Levels
   else for(int pos=1+limit;pos<rates_total;pos++) LCLEAR(pos);

   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Changing the price                                               |
//+------------------------------------------------------------------+
double MODIFY(double in,bool inv,double pw,double ml)
  {
   if(inv) in=1/in;
   in=MathPow(in,pw)*ml;
   if(Ln) in=MathLog(in);
   return(in);
  }
//+------------------------------------------------------------------+
//| Mathematical action                                              |
//+------------------------------------------------------------------+
double ACTION(double in1,double in2)
  {
   if(in1==EMPTY_VALUE || in2==EMPTY_VALUE) return(EMPTY_VALUE);
   switch(Action)
     {
      case 1: return(in1-in2);
      case 2: return(in1+in2);
      case 3: return(in1*in2);
      case 4: return(in1/in2);
     }
   return(in1/in2);
  }
//+------------------------------------------------------------------+
//| Loading the required data                                        |
//+------------------------------------------------------------------+
bool LOAD_DATA()
  {
   string txt=TimeToString(TimeLocal(),TIME_SECONDS);
   if(!SymbolSelect(Symbol1,true))
     {
      txt=txt+"\nUnavailable "+Symbol1;
      Comment(txt);
      return(true);
     }
   if(!SymbolSelect(Symbol2,true))
     {
      txt=txt+"\nUnavailable "+Symbol2;
      Comment(txt);
      return(true);
     }
   int smb=int(Window)*2;
   if(Bars(Symbol1,PERIOD_CURRENT)<=smb)
     {
      txt=txt+"\nNot enough data of the first symbol";
      Comment(txt);
      return(true);
     }
   if(Bars(Symbol2,PERIOD_CURRENT)<=smb)
     {
      txt=txt+"\nNot enough data of the second symbol";
      Comment(txt);
      return(true);
     }
   datetime temp[1];
   if(CopyTime(Symbol1,PERIOD_CURRENT,Bars(Symbol1,PERIOD_CURRENT)-1,1,temp)<=0)
     {
      txt=txt+"\nGetting the date of the first symbol";
      Comment(txt);
      return(true);
     }
   BeginDate=MathMax(BeginTime,temp[0]);
   if(CopyTime(Symbol2,PERIOD_CURRENT,Bars(Symbol2,PERIOD_CURRENT)-1,1,temp)<=0)
     {
      txt=txt+"\nGetting the date of the second symbol";
      Comment(txt);
      return(true);
     }
   BeginDate=MathMax(BeginDate,temp[0]);
   Comment("");
   Error_Init=false;
   return(false);
  }
//+------------------------------------------------------------------+
//| Assigning an empty value to all arrays at the current position   |
//+------------------------------------------------------------------+
void EMTF(int i)
  {
   BF[i]=EMPTY_VALUE;
   CALC[i]=EMPTY_VALUE;
   PR1[i]=EMPTY_VALUE;
   PR2[i]=EMPTY_VALUE;
   PRA1[i]=EMPTY_VALUE;
   PRA2[i]=EMPTY_VALUE;
   DTR[i]=EMPTY_VALUE;
   LG1[i]=EMPTY_VALUE;
   LG2[i]=EMPTY_VALUE;
   LCLEAR(i);
  }
//+------------------------------------------------------------------+
//| LCLEAR                                                           |
//+------------------------------------------------------------------+
void LCLEAR(int i)
  {
   L1up[i]=EMPTY_VALUE;
   L2up[i]=EMPTY_VALUE;
   L3up[i]=EMPTY_VALUE;
   L1dn[i]=EMPTY_VALUE;
   L2dn[i]=EMPTY_VALUE;
   L3dn[i]=EMPTY_VALUE;
  }
//+------------------------------------------------------------------+
//| Averaging initial data using a simple MA with the Average period |
//+------------------------------------------------------------------+
void MA(int pos)
  {
//--- if we get EMPTY_VALUE, return it
   if(pos<=(int)Average || PR1[pos]==EMPTY_VALUE || PR1[pos]==EMPTY_VALUE)
     {
      PRA1[pos]=EMPTY_VALUE;
      PRA2[pos]=EMPTY_VALUE;
      return;
     }
//--- average the first series. Simple arithmetic average
   int x1=1;
   double temp=PR1[pos];
   for(int j=1;j<(int)Average;j++)
      if(PR1[pos-j]!=EMPTY_VALUE)
        {
         temp+=PR1[pos-j];
         x1++;
        }
   temp=temp/(double)x1;
   PRA1[pos]=temp;

//--- average the second series. Simple arithmetic average
   x1=1;
   temp=PR2[pos];
   for(int j=1;j<(int)Average;j++)
      if(PR2[pos-j]!=EMPTY_VALUE)
        {
         temp+=PR2[pos-j];
         x1++;
        }
   temp=temp/(double)x1;
   PRA2[pos]=temp;
  }
//+------------------------------------------------------------------+
//| Detrending the series                                            |
//+------------------------------------------------------------------+
void DT(int pos)
  {
   if(pos<=int(Average+Window) || CALC[pos]==EMPTY_VALUE)
     {
      DTR[pos]=EMPTY_VALUE;
      return;
     }
//--- averaging the price series.
   int x1=1;
   double temp=CALC[pos];
   for(int j=1;j<(int)Window;j++)
      if(CALC[pos-j]!=EMPTY_VALUE)
        {
         temp+=CALC[pos-j];
         x1++;
        }
   temp=temp/(double)x1;
   DTR[pos]=CALC[pos]-temp;
  }
//+------------------------------------------------------------------+
//| Calculate first differences (I use ratio not difference)         |
//+------------------------------------------------------------------+
void LAG(int pos)
  {
   if(pos<=int(Average+Window) || PRA1[pos]==EMPTY_VALUE || PRA2[pos]==EMPTY_VALUE || 
      PRA1[pos-Window]==EMPTY_VALUE || PRA2[pos-Window]==EMPTY_VALUE)
     {
      LG1[pos]=EMPTY_VALUE;
      LG2[pos]=EMPTY_VALUE;
      return;
     }
   if(PRA1[pos-Window]!=0) LG1[pos]=PRA1[pos]/PRA1[pos-Window];
   else LG1[pos]=PRA1[pos];
   if(PRA2[pos-Window]!=0) LG2[pos]=PRA2[pos]/PRA2[pos-Window];
   else LG2[pos]=PRA2[pos];
  }
//+------------------------------------------------------------------+
//| Make up the indicator name                                       |
//+------------------------------------------------------------------+
string NAME()
  {
   string name="";
   if(Invert1) name="(inv)"+Symbol1;
   else name=Symbol1;
   switch(Action)
     {
      case 1: name=name+"-";break;
      case 2: name=name+"+";break;
      case 3: name=name+"*";break;
      case 4: name=name+"/";break;
     }
   if(Invert2) name=name+"(inv)"+Symbol2;
   else name=name+Symbol2;
   return(name);
  }
//+------------------------------------------------------------------+
