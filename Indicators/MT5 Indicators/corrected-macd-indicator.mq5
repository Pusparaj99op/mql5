#property description ""
#property description ""
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2
#property indicator_label1  "MACD"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGray,clrLimeGreen,clrSandyBrown
#property indicator_label2  "corrected macd"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrGray,clrLimeGreen,clrSandyBrown
#property indicator_width2  2

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};
enum enColorOn
{
   cc_onSlope, // Change color on slope change
   cc_onZero,  // Change color zero cross
   cc_onOrig   // Change color original macd value cross
};

input ENUM_TIMEFRAMES TimeFrame        = PERIOD_CURRENT; // Time frame
input int             FastEMA          = 12;             // Fast EMA period
input int             SlowEMA          = 26;             // Slow EMA period
input int             CorrectionPeriod =  0;             // Correction period (<0 no correction =0 same as slow EMA)
input enPrices        Price            = pr_close;       // Price
input enColorOn       ColorOn          = cc_onOrig;      // Color change on :
input bool            AlertsOn         = false;          // Turn alerts on?
input bool            AlertsOnCurrent  = true;           // Alert on current bar?
input bool            AlertsMessage    = true;           // Display messageas on alerts?
input bool            AlertsSound      = false;          // Play sound on alerts?
input bool            AlertsEmail      = false;          // Send email on alerts?
input bool            AlertsNotify     = false;          // Send push notification on alerts?
input bool            ArrowsVisible    = false;          // Arrows visible?
input string          ArrowsIdentifier = "macArrows1";   // Unique ID for arrows
input double          ArrowsUpperGap   = 1.0;            // Upper arrow gap
input double          ArrowsLowerGap   = 1.0;            // Lower arrow gap
input color           ArrowsUpColor    = clrLimeGreen;   // Up arrow color
input color           ArrowsDnColor    = clrOrange;      // Down arrow color
input int             ArrowsUpCode     = 241;            // Up arrow code
input int             ArrowsDnCode     = 242;            // Down arrow code
input int             ArrowsSize       = 1;              // Arrows size
input bool            Interpolate      = true;           // Interpolate when in multi time frame mode?

double  macd[],macdc[],corrm[],corrmc[],count[];
int     _mtfHandle = INVALID_HANDLE; ENUM_TIMEFRAMES timeFrame;
#define _mtfCall iCustom(_Symbol,timeFrame,getIndicatorName(),PERIOD_CURRENT,FastEMA,SlowEMA,CorrectionPeriod,Price,ColorOn,AlertsOn,AlertsOnCurrent,AlertsMessage,AlertsSound,AlertsEmail,AlertsNotify,false)

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void OnInit()
{
   SetIndexBuffer(0,macd  ,INDICATOR_DATA);
   SetIndexBuffer(1,macdc ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,corrm ,INDICATOR_DATA);
   SetIndexBuffer(3,corrmc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,count ,INDICATOR_CALCULATIONS);
         timeFrame = MathMax(_Period,TimeFrame);
      IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(timeFrame)+" \"Corrected\" MACD ("+string(FastEMA)+","+string(SlowEMA)+","+string(CorrectionPeriod)+")");
}
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,ArrowsIdentifier);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   if (Bars(_Symbol,_Period)<rates_total) return(-1);
   
   //
   //
   //
   //
   //
   
      if (timeFrame!=_Period)
      {
         double result[]; datetime currTime[],nextTime[]; 
            if (!timeFrameCheck(timeFrame,time))         return(0);
            if (_mtfHandle==INVALID_HANDLE) _mtfHandle = _mtfCall;
            if (_mtfHandle==INVALID_HANDLE)              return(0);
            if (CopyBuffer(_mtfHandle,4,0,1,result)==-1) return(0); 
      
                //
                //
                //
                //
                //
              
                #define _mtfRatio PeriodSeconds(timeFrame)/PeriodSeconds(_Period)
                int k,n,i = MathMin(MathMax(prev_calculated-1,0),MathMax(rates_total-(int)result[0]*_mtfRatio-1,0));
                for (; i<rates_total && !_StopFlag; i++ )
                {
                  #define _mtfCopy(_buff,_buffNo) if (CopyBuffer(_mtfHandle,_buffNo,time[i],1,result)==-1) break; _buff[i] = result[0]
                          _mtfCopy(macd  ,0);
                          _mtfCopy(macdc ,1);
                          _mtfCopy(corrm ,2);
                          _mtfCopy(corrmc,3);
                          if (ArrowsVisible && i>0)
                          {
                              string lookFor = ArrowsIdentifier+":"+(string)time[i]; ObjectDelete(0,lookFor);            
                              if (corrmc[i] != corrmc[i-1])
                              {
                                 double atr = MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);  for (int r=1; r<10 && (i-r)>0; r++) atr += MathMax(high[i-r],close[i-r-1])-MathMin(low[i-r],close[i-r-1]); atr/= 10;
                                    if (corrmc[i] == 1) drawArrow(i,time[i],high[i],low[i],atr,ArrowsUpColor,ArrowsUpCode,false);
                                    if (corrmc[i] == 2) drawArrow(i,time[i],high[i],low[i],atr,ArrowsDnColor,ArrowsDnCode, true);
                              }
                          }
                   
                          //
                          //
                          //
                          //
                          //
                   
                          #define _mtfInterpolate(_buff) _buff[i-k] = _buff[i]+(_buff[i-n]-_buff[i])*k/n
                          if (!Interpolate) continue;  CopyTime(_Symbol,timeFrame,time[i  ],1,currTime); 
                              if (i<(rates_total-1)) { CopyTime(_Symbol,timeFrame,time[i+1],1,nextTime); if (currTime[0]==nextTime[0]) continue; }
                              for(n=1; (i-n)> 0 && time[i-n] >= currTime[0]; n++) continue;	
                              for(k=1; (i-k)>=0 && k<n; k++)
                              {
                                  _mtfInterpolate(macd);
                                  _mtfInterpolate(corrm);
                              }                                 
                }
                return(i);
      }
   
   //
   //
   //
   //
   //
   
   int deviationsPeriod = (CorrectionPeriod>0) ? CorrectionPeriod : (CorrectionPeriod<0) ? 0 : (int)SlowEMA ;
   int colorOn          = (deviationsPeriod>0) ? ColorOn : (ColorOn!=cc_onOrig) ? ColorOn : cc_onSlope;
   int i=(int)MathMax(prev_calculated-1,0); for (; i<rates_total && !_StopFlag; i++)
   {
         double price = getPrice(Price,open,close,high,low,i,rates_total);
            macd[i]   = iEma(price,FastEMA,i,rates_total,0)-iEma(price,SlowEMA,i,rates_total,1);
               double v1 =         MathPow(iDeviation(macd[i],deviationsPeriod,false,i,rates_total),2);
               double v2 = (i>0) ? MathPow(corrm[i-1]-macd[i],2) : 0;
               double c  = (v2<v1 || v2==0) ? 0 : 1-v1/v2;
            corrm[i]  = (i>0) ? corrm[i-1]+c*(macd[i]-corrm[i-1]) : macd[i];
            macdc[i]  = (i>0) ? (macd[i]>macd[i-1]) ? 1 : (macd[i]<macd[i-1]) ? 2 : macdc[i-1]: 0;
            switch (colorOn)
            {
               case cc_onOrig : corrmc[i] = (corrm[i]<macd[i]) ? 1 : (corrm[i]>macd[i]) ? 2 : (i>0) ? corrmc[i-1]: 0; break;
               case cc_onZero : corrmc[i] = (corrm[i]>0)       ? 1 : (corrm[i]<0)       ? 2 : (i>0) ? corrmc[i-1]: 0; break;
               default :        corrmc[i] = (i>0) ? (corrm[i]>corrm[i-1]) ? 1 : (corrm[i]<corrm[i-1]) ? 2 : corrmc[i-1]: 0;
            }               
            
            //
            //
            //
            //
            //
            
            if (ArrowsVisible && i>0)
            {
               string lookFor = ArrowsIdentifier+":"+(string)time[i]; ObjectDelete(0,lookFor);            
               if (corrmc[i] != corrmc[i-1])
               {
                  double atr = MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);  for (int k=1; k<10 && (i-k)>0; k++) atr += MathMax(high[i-k],close[i-k-1])-MathMin(low[i-k],close[i-k-1]); atr/= 10;
                     if (corrmc[i] == 1) drawArrow(i,time[i],high[i],low[i],atr,ArrowsUpColor,ArrowsUpCode,false);
                     if (corrmc[i] == 2) drawArrow(i,time[i],high[i],low[i],atr,ArrowsDnColor,ArrowsDnCode, true);
               }
            }
   }         
   count[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
   manageAlerts(time,corrmc,colorOn,rates_total);
   return(i);
}

//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//
//
//
//

void drawArrow(int i, datetime time, double high, double low, double gap, color theColor, int theCode, bool tup)
{
   string name = ArrowsIdentifier+":"+(string)time;
   
      //
      //
      //
      //
      //

      ObjectCreate(0,name,OBJ_ARROW,0,time,0);
         ObjectSetInteger(0,name,OBJPROP_ARROWCODE,theCode);
         ObjectSetInteger(0,name,OBJPROP_WIDTH,ArrowsSize);
         ObjectSetInteger(0,name,OBJPROP_COLOR,theColor);
         if (tup)
               ObjectSetDouble(0,name,OBJPROP_PRICE,high + ArrowsUpperGap * gap);
         else  ObjectSetDouble(0,name,OBJPROP_PRICE,low  - ArrowsLowerGap * gap);
}


//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void manageAlerts(const datetime& _time[], double& _trend[], int colorOn, int bars)
{
   if (AlertsOn)
   {
      int whichBar = bars-1; if (!AlertsOnCurrent) whichBar = bars-2; datetime time1 = _time[whichBar];
      if (_trend[whichBar] != _trend[whichBar-1])
      {
         string add = "slope changed to";
         switch (colorOn)
         {
            case cc_onZero  : add = "zero level crossed"; break;
            case cc_onOrig  : add = "macd value crossed";
         }                  
         if (_trend[whichBar] == 1) doAlert(time1,add+" up");
         if (_trend[whichBar] == 2) doAlert(time1,add+" down");
      }         
   }
}   

//
//
//
//
//

void doAlert(datetime forTime, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   
   if (previousAlert != doWhat || previousTime != forTime) 
   {
      previousAlert  = doWhat;
      previousTime   = forTime;

      //
      //
      //
      //
      //

      string message = TimeToString(TimeLocal(),TIME_SECONDS)+" "+_Symbol+" corrected macd "+doWhat;
         if (AlertsMessage) Alert(message);
         if (AlertsEmail)   SendMail(_Symbol+" corrected macd",message);
         if (AlertsNotify)  SendNotification(message);
         if (AlertsSound)   PlaySound("alert2.wav");
   }
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
// 
//
//
//
//

double workDev[];
double iDeviation(double value, int length, bool isSample, int i, int bars)
{
   if (ArraySize(workDev)!=bars) ArrayResize(workDev,bars); workDev[i] = value;
                 
   //
   //
   //
   //
   //
   
      double oldMean   = value;
      double newMean   = value;
      double squares   = 0; int k;
      for (k=1; k<length && (i-k)>=0; k++)
      {
         newMean  = (workDev[i-k]-oldMean)/(k+1)+oldMean;
         squares += (workDev[i-k]-oldMean)*(workDev[i-k]-newMean);
         oldMean  = newMean;
      }
      return(MathSqrt(squares/MathMax(k-isSample,1)));
}

//
//
//
//
//

#define _emaInstances 2
double workEma[][_emaInstances];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= _bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo] = price;
   if (r>0 && period>1)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//
//

#define _pricesInstances 1
#define _pricesSize      4
double workHa[][_pricesInstances*_pricesSize];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i,int _bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= _bars) ArrayResize(workHa,_bars); instanceNo*=_pricesSize;
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][instanceNo+2] + workHa[i-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][instanceNo+0] = haLow;  workHa[i][instanceNo+1] = haHigh; } 
         else                 { workHa[i][instanceNo+0] = haHigh; workHa[i][instanceNo+1] = haLow;  } 
                                workHa[i][instanceNo+2] = haOpen;
                                workHa[i][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (tprice)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
      case pr_tbiased2:   
               if (close[i]>open[i]) return(high[i]);
               if (close[i]<open[i]) return(low[i]);
                                     return(close[i]);        
   }
   return(0);
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

string getIndicatorName()
{
   string path = MQL5InfoString(MQL5_PROGRAM_PATH);
   string data = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Indicators\\";
   string name = StringSubstr(path,StringLen(data));
      return(name);
}

//
//
//
//
//

int    _tfsPer[]={PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
string _tfsStr[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes","15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours","12 hours","daily","weekly","monthly"};
string timeFrameToString(int period)
{
   if (period==PERIOD_CURRENT) 
       period = _Period;   
         int i; for(i=0;i<ArraySize(_tfsPer);i++) if(period==_tfsPer[i]) break;
   return(_tfsStr[i]);   
}

//
//
//
//
//

bool timeFrameCheck(ENUM_TIMEFRAMES _timeFrame,const datetime& time[])
{
   static bool warned=false;
   if (time[0]<SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE))
   {
      datetime startTime,testTime[]; 
         if (SeriesInfoInteger(_Symbol,PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,startTime))
         if (startTime>0)                       { CopyTime(_Symbol,_timeFrame,time[0],1,testTime); SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE,startTime); }
         if (startTime<=0 || startTime>time[0]) { Comment(MQL5InfoString(MQL5_PROGRAM_NAME)+"\nMissing data for "+timeFrameToString(_timeFrame)+" time frame\nRe-trying on next tick"); warned=true; return(false); }
   }
   if (warned) { Comment(""); warned=false; }
   return(true);
}