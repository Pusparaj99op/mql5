//+------------------------------------------------------------------+
//|                           MyBOLsAlertV32.mq5 (Origin from BB.mq5)|
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                         SearchSurf-RmDj (The-How)|
//+------------------------------------------------------------------+
#property copyright   "2009, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Bollinger Bands"
#property description "------------------------- 2015 SearchSurf's Version 3.2 (RmDj)"
#include <MovingAverages.mqh>
//---
#property indicator_chart_window
#property indicator_buffers 6                          
#property indicator_plots   5                           
#property indicator_type1   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_type2   DRAW_LINE
#property indicator_color2  LightSeaGreen
#property indicator_type3   DRAW_LINE
#property indicator_color3  LightSeaGreen
#property indicator_type4   DRAW_ARROW                   
#property indicator_color4  Blue                         
#property indicator_type5   DRAW_ARROW                    
#property indicator_color5  Red                           
#property indicator_label1  "Bands middle"
#property indicator_label2  "Bands upper"
#property indicator_label3  "Bands lower"
//--- input parametrs
input int     InpBandsPeriod=20;       // Period
input int     InpBandsShift=0;         // Shift
input double  InpBandsDeviations=0.5;  // Deviation
input bool    Play_sound=true;         // Enable wav play.  
input bool    Emailing=false;          // Enable Email Alert.
input bool    OuterBandArrow=true;     // Enable Arrow Indicator 
input bool    BandLineOnly=false;      // Arrow on BandLine Only
//--- global variables
int           ExtBandsPeriod,ExtBandsShift;
double        ExtBandsDeviations;
int           ExtPlotBegin=0;
//---- indicator buffer
double        ExtMLBuffer[];
double        ExtTLBuffer[];
double        ExtBLBuffer[];
double        ExtUpBuffer[];
double        ExtLoBuffer[];
double        ExtStdDevBuffer[];
//--- Other Variable;
double        UpperBOL;
double        LowerBOL;
double        MidBOL;
string        InSeconds; // The string
string        sec[]; // result
ushort        usec; // code of seperator
long          seconds;
bool          play=1;
long          delay_sec;
double        mailcon=true;  //mail condition  (true = Allow / false = Don't queue);
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- check for input values
   if(InpBandsPeriod<2)
     {
      ExtBandsPeriod=20;
      printf("Incorrect value for input variable InpBandsPeriod=%d. Indicator will use value=%d for calculations.",InpBandsPeriod,ExtBandsPeriod);
     }
   else ExtBandsPeriod=InpBandsPeriod;
   if(InpBandsShift<0)
     {
      ExtBandsShift=0;
      printf("Incorrect value for input variable InpBandsShift=%d. Indicator will use value=%d for calculations.",InpBandsShift,ExtBandsShift);
     }
   else
      ExtBandsShift=InpBandsShift;
   if(InpBandsDeviations==0.0)
     {
      ExtBandsDeviations=2.0;
      printf("Incorrect value for input variable InpBandsDeviations=%f. Indicator will use value=%f for calculations.",InpBandsDeviations,ExtBandsDeviations);
     }
   else ExtBandsDeviations=InpBandsDeviations;
//--- define buffers
   SetIndexBuffer(0,ExtMLBuffer);
   SetIndexBuffer(1,ExtTLBuffer);
   SetIndexBuffer(2,ExtBLBuffer);
   SetIndexBuffer(3,ExtUpBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtLoBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,ExtStdDevBuffer,INDICATOR_CALCULATIONS);
//--- set index labels
   PlotIndexSetString(0,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Middle");
   PlotIndexSetString(1,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Upper");
   PlotIndexSetString(2,PLOT_LABEL,"Bands("+string(ExtBandsPeriod)+") Lower");
//--- indicator name
   IndicatorSetString(INDICATOR_SHORTNAME,"Bollinger Bands");
//--- indexes draw begin settings
   ExtPlotBegin=ExtBandsPeriod-1;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtBandsPeriod);
   PlotIndexSetInteger(3,PLOT_ARROW,217);
   PlotIndexSetInteger(4,PLOT_ARROW,218);
//--- indexes shift settings
   PlotIndexSetInteger(0,PLOT_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(1,PLOT_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(2,PLOT_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,ExtBandsShift);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,ExtBandsShift);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- number of digits of indicator value
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- OnInit done
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//--- variables
   int pos;
   int i;
   string Ptrimmed;
   double the_price;
//--- indexes draw begin settings, when we've recieved previous begin
   if(ExtPlotBegin!=ExtBandsPeriod+begin)
     {
      ExtPlotBegin=ExtBandsPeriod+begin;
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtPlotBegin);
      PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ExtPlotBegin);
     }
//--- check for bars count
   if(rates_total<ExtPlotBegin)
      return(0);
//--- starting calculation
   if(prev_calculated>1) pos=prev_calculated-1;
   else pos=0;
//--- This serves the calculated bars candle details.              
   MqlRates crates[];
   if(CopyRates(_Symbol,_Period,0,rates_total,crates)<0)
     {
      Alert("Unable to get total rates bars --- ",GetLastError());
      return(rates_total);
     }

//--- main cycle   
   for(i=pos;i<rates_total && !IsStopped();i++)
     {
      //--- middle line
      ExtMLBuffer[i]=SimpleMA(i,ExtBandsPeriod,price);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,price,ExtMLBuffer,ExtBandsPeriod);
      //--- upper line
      ExtTLBuffer[i]=ExtMLBuffer[i]+ExtBandsDeviations*ExtStdDevBuffer[i];
      //--- lower line
      ExtBLBuffer[i]=ExtMLBuffer[i]-ExtBandsDeviations*ExtStdDevBuffer[i];
      //--- Will copy BOL band value of last bar:     
      MidBOL=ExtMLBuffer[i];
      LowerBOL = ExtBLBuffer[i];
      UpperBOL = ExtTLBuffer[i];
      ExtUpBuffer[i]=0;
      ExtLoBuffer[i]=0;
      //--- Places arrow indicator whenever price passed over outer bands******          
      if(OuterBandArrow)
        {
         if(BandLineOnly)
           {
            if(crates[i].low<UpperBOL && crates[i].high>UpperBOL) ExtUpBuffer[i]=UpperBOL;
            else ExtUpBuffer[i]=0;
            if(crates[i].high>LowerBOL && crates[i].low<LowerBOL) ExtLoBuffer[i]=LowerBOL;
            else ExtLoBuffer[i]=0;
           }
         else
           {
            if((crates[i].low<UpperBOL && crates[i].high>UpperBOL) || 
               (crates[i].low>UpperBOL && crates[i].high>UpperBOL)) ExtUpBuffer[i]=UpperBOL;
            else ExtUpBuffer[i]=0;
            if((crates[i].high>LowerBOL && crates[i].low<LowerBOL) || 
               (crates[i].high<LowerBOL && crates[i].low<LowerBOL)) ExtLoBuffer[i]=LowerBOL;
            else ExtLoBuffer[i]=0;
           }
        }
     }

//--- To get the latest close price:   (high,low,close,open,real volume,spread,tick volume,time)    
   MqlRates mrates[];  // for storing the price,volume,spread 
   ArraySetAsSeries(mrates,true);  // Records data in series format.
   if(CopyRates(_Symbol,_Period,0,3,mrates)<0) //CopyRates(Chart Current Symbol, Chart Current Period,start position, count, rates array)
     {
      Alert("Unable to get rates of 3 bars --- ",GetLastError());
      return(rates_total);
     }
//--- NOTE!!!  Make sure the name of the wav file in use here in PlaySound is present at the default folder of your MT5 sound folder...
//--- (Usually located at c:/Program files/yourMT5folder/Sounds...) --- Also, limit your wav playtime with max of 3 seconds only.
//--- If sound is switched OFF, omit string conversion proccessing...
   if(Play_sound)
     {
      InSeconds=TimeToString(TimeLocal(),TIME_SECONDS); //   00:00:XX
      usec=StringGetCharacter(":",0);
      StringSplit(InSeconds,usec,sec);
      seconds=StringToInteger(sec[2]);
     }
   else seconds=1;  // just to give varaible seconds a value, don't care anyway...  
//---
   the_price=mrates[0].close;
//--- Email sending will execute at one time only when current prize first overlaps bands, it will not allow to send another message 'till
//--- current prize hits the middle band mark.
   if(mrates[0].close==MidBOL) mailcon=true;   // flags email condition, allows email to get ready to send again (if price hits middleband).
                                               // No need for delay for sound to complete play, this timely routine will make sure wav playback without interfering with tick processing.
   if(seconds!=delay_sec)
     {
      if(seconds==5||seconds==10||seconds==15||seconds==20||
         seconds==25||seconds==30||seconds==35||seconds==40||
         seconds==45||seconds==50||seconds==55||seconds==0) play=true;
     }
//---
   delay_sec=seconds;
//---
   if((mrates[0].close>UpperBOL || mrates[0].close<LowerBOL))
     {
      if(mrates[0].close>UpperBOL)
        {
         if(Play_sound && play)
           {
            PlaySound("UpperBandAlert.wav");
            play=false;
           }
         if(mailcon && Emailing)
           {
            mailcon=false;
            //---
            usec=StringGetCharacter("_",0);
            StringSplit(EnumToString(_Period),usec,sec);
            Ptrimmed=sec[1];
            //---
            if(!SendMail(Ptrimmed+"UpB_"+_Symbol,Ptrimmed+_Symbol+" detected ABOVE Bollinger's Upper Band: "+DoubleToString(the_price,8)+"  This is an Alert Message."))
              {
               Alert("Mail queue failed.");
               return(rates_total);
              }
           }
        }
      //---
      else if(mrates[0].close<LowerBOL)
        {
         if(Play_sound && play)
           {
            PlaySound("LowerBandAlert.wav");
            play=false;
           }
         if(mailcon && Emailing)
           {
            mailcon=false;
            //---
            usec=StringGetCharacter("_",0);
            StringSplit(EnumToString(_Period),usec,sec);
            Ptrimmed=sec[1];
            //---
            if(!SendMail(Ptrimmed+"LwB_"+_Symbol,Ptrimmed+_Symbol+" detected BELOW Bollinger's Lower Band: "+DoubleToString(the_price,8)+"  This is an Alert Message."))
              {
               Alert("Mail queue failed.");
               return(rates_total);
              }
           }
        }
      else;
     }
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(int position,const double &price[],const double &MAprice[],int period)
  {
//--- variables
   double StdDev_dTmp=0.0;
//--- check for position
   if(position<period) return(StdDev_dTmp);
//--- calcualte StdDev
   for(int i=0;i<period;i++) StdDev_dTmp+=MathPow(price[position-i]-MAprice[position],2);
   StdDev_dTmp=MathSqrt(StdDev_dTmp/period);
//--- return calculated value
   return(StdDev_dTmp);
  }
//+------------------------------------------------------------------+
