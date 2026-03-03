//+------------------------------------------------------------------+
//|                                                  Pinbar Detector |
//|                                  Copyright © 2011, EarnForex.com |
//|                                        http://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, EarnForex"
#property link      "http://www.earnforex.com"
#property version   "1.01"

#property description "Pinbar Detector - detects Pinbars on charts."
#property description "Has two sets of predefined settings: common and strict."
#property description "Fully modifiable parameters of Pinbar pattern."
#property description "Usage instructions:"
#property description "http://www.earnforex.com/forex-strategy/pinbar-trading-system"
#property description "http://nysetrader.net/pin-bar/"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_ARROW
#property indicator_color1  clrLime, clrRed
#property indicator_width1  2

input bool   UseAlerts=true; // Permission to alerts
input bool   UseEmailAlerts=false; // Permission to email alerts
input double MaxNoseBodySize = 0.33; // maximum allowable ratio of Nose body to the bar length
input double NoseBodyPosition = 0.4; // extreme position of the Nose body inside the bar. Upper part for the bullish pattern, lower part to the bearish pattern
input bool   LeftEyeOppositeDirection=true; // Left eye should be bearish for the bullish Pin Bar and should be bullish for the bearish Pin Bar
input bool   NoseSameDirection=false; // the Nose should be in the same direction as the pattern itself
input bool   NoseBodyInsideLeftEyeBody=false; // the Nose body should be fit in the Left Eye body
input double LeftEyeMinBodySize=0.1; // minimum size of the Left Eye body relatively to the bar length
input double NoseProtruding=0.5; // minimum Nose protrusion relatively to the bar length
input double NoseBodyToLeftEyeBody=1; // maximum size of the Nose body relatively to the Left Eye body
input double NoseLengthToLeftEyeLength=0; // minimum Nose size relatively to the Left Eye
input double LeftEyeDepth=0.1; //  minimum depth of the Left Eye relatively to its length. Depth is the length of the bar part behind the Nose

//---- Indicator buffers
double UpDown[];
double Color[];

//---- Global variables
int LastBars=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- indicator buffers mapping  
   SetIndexBuffer(0,UpDown,INDICATOR_DATA);
   SetIndexBuffer(1,Color,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(UpDown,true);
   ArraySetAsSeries(Color,true);
//---- drawing settings
   PlotIndexSetInteger(0,PLOT_ARROW,74);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetString(0,PLOT_LABEL,"Pinbar");
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tickvolume[],
                const long &volume[],
                const int &spread[])
  {
//----
   int NeedBarsCounted;
   double NoseLength,NoseBody,LeftEyeBody,LeftEyeLength;
//----
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(Close,true);
//----
   if(LastBars==rates_total) return(rates_total);
   NeedBarsCounted=rates_total-LastBars;
   LastBars=rates_total;
   if(NeedBarsCounted==rates_total) NeedBarsCounted--;
//----
   UpDown[0]=EMPTY_VALUE;
//----
   for(int bar=NeedBarsCounted; bar>=1; bar--)
     {
      //---- Prevents bogus indicator arrows from appearing (looks like PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE); is not enough.)
      UpDown[bar]=EMPTY_VALUE;

      //---- Won't have Left Eye for the left-most bar
      if(bar==rates_total-1) continue;

      // Left Eye and Nose bars's paramaters
      NoseLength=High[bar]-Low[bar];
      if(!NoseLength) NoseLength = _Point;
      LeftEyeLength = High[bar + 1] - Low[bar + 1];
      if(!LeftEyeLength) LeftEyeLength=_Point;
      NoseBody=MathAbs(Open[bar]-Close[bar]);
      if(!NoseBody) NoseBody = _Point;
      LeftEyeBody = MathAbs(Open[bar + 1] - Close[bar + 1]);
      if(!LeftEyeBody) LeftEyeBody=_Point;

      //---- Bearish Pinbar
      if(High[bar]-High[bar+1]>=NoseLength*NoseProtruding) // Nose protrusion
        {
         if(NoseBody/NoseLength<=MaxNoseBodySize) // Nose body to candle length ratio
           {
            if(1 -(High[bar]-MathMax(Open[bar],Close[bar]))/NoseLength<NoseBodyPosition) // Nose body position in bottom part of the bar
              {
               if(!LeftEyeOppositeDirection || Close[bar+1]>Open[bar+1]) // Left Eye bullish if required
                 {
                  if(!NoseSameDirection || Close[bar]<Open[bar]) // Nose bearish if required
                    {
                     if(LeftEyeBody/LeftEyeLength>=LeftEyeMinBodySize) // Left eye body to candle length ratio
                       {
                        if(MathMax(Open[bar],Close[bar]<=High[bar+1]) && MathMin(Open[bar],Close[bar])>=Low[bar+1]) // Nose body inside Left Eye bar
                          {
                           if(NoseBody/LeftEyeBody<=NoseBodyToLeftEyeBody) // Nose body to Left Eye body ratio
                             {
                              if(NoseLength/LeftEyeLength>=NoseLengthToLeftEyeLength) // Nose length to Left Eye length ratio
                                {
                                 if(Low[bar]-Low[bar+1]>=LeftEyeLength*LeftEyeDepth) // Left Eye low is low enough
                                   {
                                    if(!NoseBodyInsideLeftEyeBody || MathMax(Open[bar],Close[bar])<=MathMax(Open[bar+1],Close[bar+1]) && MathMin(Open[bar],Close[bar])>=MathMin(Open[bar+1],Close[bar+1])) // Nose body inside Left Eye body if required
                                      {
                                       UpDown[bar]= High[bar]+5 * _Point+NoseLength/5;
                                       Color[bar] = 1;
                                       if(bar==1) SendAlert("Bearish"); // Send alerts only for the latest fully formed bar
                                      }
                                   }
                                }
                             }
                          }
                       }
                    }
                 }
              }
           }
        }

      //---- Bullish Pinbar
      if(Low[bar+1]-Low[bar]>=NoseLength*NoseProtruding) // Nose protrusion
        {
         if(NoseBody/NoseLength<=MaxNoseBodySize) // Nose body to candle length ratio
           {
            if(1 -(MathMin(Open[bar],Close[bar])-Low[bar])/NoseLength<NoseBodyPosition) // Nose body position in top part of the bar
              {
               if(!LeftEyeOppositeDirection || Close[bar+1]<Open[bar+1]) // Left Eye bearish if required
                 {
                  if(!NoseSameDirection || Close[bar]>Open[bar]) // Nose bullish if required
                    {
                     if(LeftEyeBody/LeftEyeLength>=LeftEyeMinBodySize) // Left eye body to candle length ratio
                       {
                        if(MathMax(Open[bar],Close[bar]<=High[bar+1]) && (MathMin(Open[bar],Close[bar])>=Low[bar+1])) // Nose body inside Left Eye bar
                          {
                           if(NoseBody/LeftEyeBody<=NoseBodyToLeftEyeBody) // Nose body to Left Eye body ratio
                             {
                              if(NoseLength/LeftEyeLength>=NoseLengthToLeftEyeLength) // Nose length to Left Eye length ratio
                                {
                                 if(High[bar+1]-High[bar]>=LeftEyeLength*LeftEyeDepth) // Left Eye high is high enough
                                   {
                                    if(!NoseBodyInsideLeftEyeBody || MathMax(Open[bar],Close[bar])<=MathMax(Open[bar+1],Close[bar+1]) && MathMin(Open[bar],Close[bar])>=MathMin(Open[bar+1],Close[bar+1])) // Nose body inside Left Eye body if required
                                      {
                                       UpDown[bar]= Low[bar]-5 * _Point-NoseLength/5;
                                       Color[bar] = 0;
                                       if(bar==1) SendAlert("Bullish"); // Send alerts only for the latest fully formed bar
                                      }
                                   }
                                }
                             }
                          }
                       }
                    }
                 }
              }
           }
        }
     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  Getting string timeframe                                        |
//+------------------------------------------------------------------+
string TimeframeToString(ENUM_TIMEFRAMES timeframe) {return(StringSubstr(EnumToString(timeframe),7,-1));}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendAlert(string dir)
  {
//----
   string per=TimeframeToString(_Period);
   if(UseAlerts)
     {
      Alert(dir+" Pinbar on ",_Symbol," @ ",per);
      PlaySound("alert.wav");
     }
   if(UseEmailAlerts)
      SendMail(_Symbol+" @ "+per+" - "+dir+" Pinbar",dir+" Pinbar on "+_Symbol+" @ "+per+" as of "+TimeToString(TimeCurrent()));
//----
  }
//+------------------------------------------------------------------+
