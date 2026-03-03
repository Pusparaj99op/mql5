
#property description ""
#property description ""
//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   3
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrDeepSkyBlue,clrPaleVioletRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "NonLag ma MACD"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDeepSkyBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDimGray
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

//
//
//
//
//

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

input ENUM_TIMEFRAMES    TimeFrame        = PERIOD_CURRENT;   // Time frame
input int                FastLength       = 12;               // Fast non lag macd length
input int                SlowLength       = 26;               // Slow non lag macd length
input int                SignalLength     = 9;                // Signal non lag macd length
input enPrices           NlmPrice         = pr_close;         // Non lag macd Price
input bool               alertsOn         = false;            // Turn alerts on?
input bool               alertsOnCurrent  = true;             // Alert on current bar?
input bool               alertsMessage    = true;             // Display messageas on alerts?
input bool               alertsSound      = false;            // Play sound on alerts?
input bool               alertsEmail      = false;            // Send email on alerts?
input bool               alertsNotify     = false;            // Send push notification on alerts?
input bool               arrowsVisible    = false;            // Arrows visible?
input string             arrowsIdentifier = "nlmacdArrows1";  // Unique ID for arrows
input double             arrowsUpperGap   = 1.0;              // Upper arrow gap
input double             arrowsLowerGap   = 1.0;              // Lower arrow gap
input color              arrowsUpColor    = clrLimeGreen;     // Up arrow color
input color              arrowsDnColor    = clrOrange;        // Down arrow color
input int                arrowsUpCode     = 241;              // Up arrow code
input int                arrowsDnCode     = 242;              // Down arrow code
input int                arrowsSize       = 1;                // Arrows size
input bool               Interpolate      = true;             // Interpolate mtf data ?

//
//
//
//
//

double macd[];
double signal[];
double osma[];
double colorb[];
double count[];

int indHandle = INVALID_HANDLE; ENUM_TIMEFRAMES timeFrame;
#define _mtfCall iCustom(_Symbol,timeFrame,getIndicatorName(),PERIOD_CURRENT,FastLength,SlowLength,SignalLength,alertsOn,alertsOnCurrent,alertsMessage,alertsSound,alertsEmail,alertsNotify,false)

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,osma,  INDICATOR_DATA);  
   SetIndexBuffer(1,colorb,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(2,macd,  INDICATOR_DATA);
   SetIndexBuffer(3,signal,INDICATOR_DATA);
   SetIndexBuffer(4,count ,INDICATOR_CALCULATIONS); 
   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,2);
      timeFrame = fmax(_Period,TimeFrame);
         if (timeFrame != _Period) indHandle = _mtfCall;
   IndicatorSetString(INDICATOR_SHORTNAME,timeFrameToString(timeFrame)+" NonLag ma MACD ("+string(FastLength)+","+string(SlowLength)+","+string(SignalLength)+")");
return(0);
}

void OnDeinit(const int reason)
{
   string lookFor       = arrowsIdentifier+":";
   int    lookForLength = StringLen(lookFor);
   for (int i=ObjectsTotal(0)-1; i>=0; i--)
   {
      string objectName = ObjectName(0,i);
         if (StringSubstr(objectName,0,lookForLength) == lookFor) ObjectDelete(0,objectName);
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
   if (Bars(_Symbol,_Period)<rates_total) return(0);
      //
      //
      //
      //
      //
      
      if (timeFrame!=_Period)
      {
         double result[1]; datetime currTime[],nextTime[]; 
            if (indHandle == INVALID_HANDLE) indHandle = _mtfCall;
            if (indHandle == INVALID_HANDLE) return(0);
            if (CopyBuffer(indHandle,4,0,1,result)==-1) return(prev_calculated);
             
            //
            //
            //
            //
            //
              
            #define _processed EMPTY_VALUE-1
               int i,limit = rates_total-(int)fmin(result[0]*PeriodSeconds(timeFrame)/PeriodSeconds(_Period),rates_total); 
               for (limit=fmax(limit,0); limit>0 && !IsStopped(); limit--) if (count[limit]==_processed) break;
               for (i=fmin(limit,fmax(prev_calculated-1,0)); i<rates_total && !IsStopped(); i++    )
               {
                   if (CopyBuffer(indHandle,0,time[i],1,result)==-1) break; osma[i]   = result[0]; 
                   if (CopyBuffer(indHandle,1,time[i],1,result)==-1) break; colorb[i] = result[0]; 
                   if (CopyBuffer(indHandle,2,time[i],1,result)==-1) break; macd[i]   = result[0];
                   if (CopyBuffer(indHandle,3,time[i],1,result)==-1) break; signal[i] = result[0];
                                                                            count[i]  = _processed;
                   //
                   //
                   //
                   //
                   //
                   
                   manageArrow(high,low,close,time,colorb,i);    
                   #define _interpolate(buff,i,k,n) buff[i-k] = buff[i]+(buff[i-n]-buff[i])*k/n
                   if (!Interpolate) continue; CopyTime(_Symbol,TimeFrame,time[i  ],1,currTime); 
                      if (i<(rates_total-1)) { CopyTime(_Symbol,TimeFrame,time[i+1],1,nextTime); if (currTime[0]==nextTime[0]) continue; }
                      int n,k;
                         for(n=1; (i-n)> 0 && time[i-n] >= currTime[0]; n++) continue;	
                         for(k=1; (i-k)>=0 && k<n; k++)
                         {
                            _interpolate(osma,  i,k,n);
                            _interpolate(macd,  i,k,n);
                            _interpolate(signal,i,k,n);                        
                         }                              
                }
                if (i!=rates_total) return(0); return(rates_total);
      }
      
      //
      //
      //
      //
      //
      
      for (int i=(int)fmax(prev_calculated-1,0); i<rates_total; i++)
      {
         double price     = getPrice(NlmPrice,open,close,high,low,i,rates_total);
                macd[i]   = iNoLagMa(price,FastLength,i,rates_total,0)-iNoLagMa(price,SlowLength,i,rates_total,1);  
                signal[i] = iNoLagMa(macd[i],SignalLength,i,rates_total,2);
                osma[i]   = macd[i]-signal[i];
                colorb[i] = (i>0) ? (osma[i]>0) ? 0 : (osma[i]<0) ? 1 : colorb[i-1]  : 0;   
                manageArrow(high,low,close,time,colorb,i);      
      }      
      count[rates_total-1] = fmax(rates_total-prev_calculated+1,1);
      manageAlerts(time,colorb,rates_total);
return(rates_total);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

#define _length  0
#define _len     1
#define _weight  2

#define nlmInstances 3
double  nlm_values[3][nlmInstances];
double  nlm_prices[ ][nlmInstances];
double  nlm_alphas[ ][nlmInstances];

double iNoLagMa(double price, int length, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(nlm_prices,0)!=bars) ArrayResize(nlm_prices,bars);
                               nlm_prices[r][instanceNo]=price;
   if (length<3 || r<3) return(nlm_prices[r][instanceNo]);
   
   //
   //
   //
   //
   //
   
   if (nlm_values[_length][instanceNo] != length)
   {
      double Cycle = 4.0;
      double Coeff = 3.0*M_PI;
      int    Phase = length-1;
      
         nlm_values[_length][instanceNo] = length;
         nlm_values[_len   ][instanceNo] = length*4 + Phase;  
         nlm_values[_weight][instanceNo] = 0;

         if (ArrayRange(nlm_alphas,0) < nlm_values[_len][instanceNo]) ArrayResize(nlm_alphas,(int)nlm_values[_len][instanceNo]);
         for (int k=0; k<nlm_values[_len][instanceNo]; k++)
         {
            double t;
            if (k<=Phase-1) 
                 t = 1.0 * k/(Phase-1);
            else t = 1.0 + (k-Phase+1)*(2.0*Cycle-1.0)/(Cycle*length-1.0); 
            double beta = MathCos(M_PI*t);
            double g = 1.0/(Coeff*t+1); if (t <= 0.5 ) g = 1;
      
            nlm_alphas[k][instanceNo]        = g * beta;
            nlm_values[_weight][instanceNo] += nlm_alphas[k][instanceNo];
         }
   }
   
   //
   //
   //
   //
   //
   
   if (nlm_values[_weight][instanceNo]>0)
   {
      double sum = 0;
           for (int k=0; k < nlm_values[_len][instanceNo] && (r-k)>=0; k++) sum += nlm_alphas[k][instanceNo]*nlm_prices[r-k][instanceNo];
           return( sum / nlm_values[_weight][instanceNo]);
   }
   else return(0);           
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

#define priceInstances 1
double workHa[][priceInstances*4];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i,int _bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= _bars) ArrayResize(workHa,_bars); instanceNo*=4;
         
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

void manageArrow(const double& high[],const double& low[], const double& close[], const datetime& time[], double& state[], int i)
{
   if (arrowsVisible)
   {
      double atr = (i>0) ? fmax(high[i],close[i-1])-fmin(low[i],close[i-1]) : high[i]-low[i];
         for (int k=1; k<10 && (i-k)>0; k++) atr += fmax(high[i-k],close[i-k-1])-fmin(low[i-k],close[i-k-1]); atr/= 10;
         string lookFor = arrowsIdentifier+":"+(string)time[i]; ObjectDelete(0,lookFor);            
         if (i>0 && state[i] != state[i-1])
         {
            if (state[i] == 0) drawArrow(i,time[i],high[i],low[i],atr,arrowsUpColor,arrowsUpCode,false);
            if (state[i] == 1) drawArrow(i,time[i],high[i],low[i],atr,arrowsDnColor,arrowsDnCode, true);
         }
   }
}

//
//
//
//
//

void drawArrow(int i, datetime time, double high, double low, double gap, color theColor, int theCode, bool tup)
{
   string name = arrowsIdentifier+":"+(string)time;
   
      //
      //
      //
      //
      //

      ObjectCreate(0,name,OBJ_ARROW,0,time,0);
         ObjectSetInteger(0,name,OBJPROP_ARROWCODE,theCode);
         ObjectSetInteger(0,name,OBJPROP_WIDTH,arrowsSize);
         ObjectSetInteger(0,name,OBJPROP_COLOR,theColor);
         if (tup)
               ObjectSetDouble(0,name,OBJPROP_PRICE,high + arrowsUpperGap * gap);
         else  ObjectSetDouble(0,name,OBJPROP_PRICE,low  - arrowsLowerGap * gap);
}


//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void manageAlerts(const datetime& time[], double& ttrend[], int bars)
{
   if (!alertsOn) return;
      int whichBar = bars-1; if (!alertsOnCurrent) whichBar = bars-2; datetime time1 = time[whichBar];
      if (ttrend[whichBar] != ttrend[whichBar-1])
      {
         if (ttrend[whichBar] == 0) doAlert(time1,"up");
         if (ttrend[whichBar] == 1) doAlert(time1,"down");
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

      string message = timeFrameToString(_Period)+" "+_Symbol+" at "+TimeToString(TimeLocal(),TIME_SECONDS)+" nonlag macd "+doWhat;
         if (alertsMessage) Alert(message);
         if (alertsEmail)   SendMail(_Symbol+" nonlag macd",message);
         if (alertsNotify)  SendNotification(message);
         if (alertsSound)   PlaySound("alert2.wav");
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
         int i; for(i=ArraySize(_tfsPer)-1;i>=0;i--) if(period==_tfsPer[i]) break;
   return(_tfsStr[i]);   
}