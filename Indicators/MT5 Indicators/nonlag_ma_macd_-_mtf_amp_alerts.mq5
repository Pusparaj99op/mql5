//------------------------------------------------------------------

   #property copyright "mladen"
   #property link      "www.forex-tsd.com"

//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   3
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  DeepSkyBlue,PaleVioletRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "NonLag ma MACD"
#property indicator_type2   DRAW_LINE
#property indicator_color2  DeepSkyBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_type3   DRAW_LINE
#property indicator_color3  DimGray
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

//
//
//
//
//

input ENUM_TIMEFRAMES    TimeFrame    = PERIOD_CURRENT; // Time frame
input int                FastLength   = 12;             // Fast MACD length
input int                SlowLength   = 26;             // Slow MACD length
input int                SignalLength =  9;             // Signal length
input ENUM_APPLIED_PRICE Price        = PRICE_CLOSE;    // Price to use
input bool               Interpolate  = true;           // Interpolate mtf data
input bool               alertsOn         = false;      // Alert on trend change
input bool               alertsOnCurrent  = true;       // Alert on current bar
input bool               alertsMessage    = true;       // Display messageas on alerts
input bool               alertsSound      = false;      // Play sound on alerts
input bool               alertsEmail      = false;      // Send email on alerts

//
//
//
//
//

double macd[];
double signal[];
double osma[];
double colorBuffer[];
double countBuffer[];
ENUM_TIMEFRAMES timeFrame;
int             mtfHandle;
bool            calculating;

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
   SetIndexBuffer(0,osma,INDICATOR_DATA);  PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,2);
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(2,macd,INDICATOR_DATA);
   SetIndexBuffer(3,signal,INDICATOR_DATA);
   SetIndexBuffer(4,countBuffer,INDICATOR_CALCULATIONS); 

      //
      //
      //
      //
      //
         
      timeFrame   = MathMax(_Period,TimeFrame);
      calculating = (timeFrame==_Period);
      if (!calculating)
      {
         string name = getIndicatorName(); mtfHandle = iCustom(NULL,timeFrame,name,PERIOD_CURRENT,FastLength,SlowLength,SignalLength,Price);
      }
   IndicatorSetString(INDICATOR_SHORTNAME,getPeriodToString(timeFrame)+" NonLag ma MACD ("+string(FastLength)+","+string(SlowLength)+","+string(SignalLength)+")");
   return(0);
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
   //
   //
   //
   //
   //
   
   if (calculating)
   {
      for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
      {
         double price     = getPrice(Price,open,close,high,low,i);
                macd[i]   = iNoLagMa(price,FastLength,i,0)-iNoLagMa(price,SlowLength,i,1);
                signal[i] = iNoLagMa(macd[i],SignalLength,i,2);
                osma[i]   = macd[i]-signal[i];
         if (i>0)
         {
            colorBuffer[i] = colorBuffer[i-1];
               if (osma[i]>0) colorBuffer[i]=0;
               if (osma[i]<0) colorBuffer[i]=1;
         }
      }      
      countBuffer[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
      manageAlerts(time[rates_total-1],time[rates_total-2],colorBuffer,rates_total);
      return(rates_total);
   }
   
   //
   //
   //
   //
   //
   
      datetime times[]; 
      datetime startTime = time[0]-PeriodSeconds(timeFrame);
      datetime endTime   = time[rates_total-1];
         int bars = CopyTime(NULL,timeFrame,startTime,endTime,times);
        
         if (times[0]>time[0] || bars<1) return(prev_calculated);
               double tosma[]; CopyBuffer(mtfHandle,0,0,bars,tosma);
               double tcolo[]; CopyBuffer(mtfHandle,1,0,bars,tcolo);
               double tmacd[]; CopyBuffer(mtfHandle,2,0,bars,tmacd);
               double tsign[]; CopyBuffer(mtfHandle,3,0,bars,tsign);
               double count[]; CopyBuffer(mtfHandle,4,0,bars,count);
         int maxb = (int)MathMax(MathMin(count[bars-1]*PeriodSeconds(timeFrame)/PeriodSeconds(Period()),rates_total-1),1);

   //
   //
   //
   //
   //
      
   for(int i=(int)MathMax(prev_calculated-maxb,0); i<rates_total; i++)
   {
      int d = dateArrayBsearch(times,time[i],bars);
      if (d > -1 && d < bars)
      {
         osma[i]        = tosma[d];
         macd[i]        = tmacd[d];
         signal[i]      = tsign[d];
         colorBuffer[i] = tcolo[d];
      }
      if (!Interpolate) continue;
        
      //
      //
      //
      //
      //
         
      int j=MathMin(i+1,rates_total-1);
      if (d!=dateArrayBsearch(times,time[j],bars) || i==j)
      {
         int n,k;
            for(n = 1; (i-n)> 0 && time[i-n] >= times[d]; n++) continue;	
            for(k = 1; (i-k)>=0 && k<n; k++)
            {
               macd[i-k]   = macd[i]   + (macd[i-n]  - macd[i]  )*k/n;
               osma[i-k]   = osma[i]   + (osma[i-n]  - osma[i]  )*k/n;
               signal[i-k] = signal[i] + (signal[i-n]- signal[i])*k/n;
            }                  
      }
   }

   manageAlerts(times[bars-1],times[bars-2],tcolo,bars);
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

#define Pi       3.14159265358979323846264338327950288
#define _length  0
#define _len     1
#define _weight  2

#define numOfSeparateCalculations 3
double  nlm_values[3][numOfSeparateCalculations];
double  nlm_prices[ ][numOfSeparateCalculations];
double  nlm_alphas[ ][numOfSeparateCalculations];

double iNoLagMa(double price, int length, int r, int instanceNo=0)
{
   if (ArrayRange(nlm_prices,0) != Bars(Symbol(),0)) ArrayResize(nlm_prices,Bars(Symbol(),0));
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
      double Coeff = 3.0*Pi;
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
            double beta = MathCos(Pi*t);
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

void manageAlerts(datetime currTime, datetime prevTime, double& trend[], int bars)
{
   if (alertsOn)
   {
      datetime time     = currTime;
      int      whichBar = bars-1; if (!alertsOnCurrent) { whichBar = bars-2; time = prevTime; }
         
      //
      //
      //
      //
      //
         
      if (trend[whichBar] != trend[whichBar-1])
      {
         if (trend[whichBar] == 0) doAlert(time,"up");
         if (trend[whichBar] == 1) doAlert(time,"down");
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
   string message;
   
   if (previousAlert != doWhat || previousTime != forTime) 
   {
      previousAlert  = doWhat;
      previousTime   = forTime;

      //
      //
      //
      //
      //

      message = _Symbol+" "+getPeriodToString(timeFrame)+" at "+TimeToString(TimeLocal(),TIME_SECONDS)+" NonLag ma MACD trend changed to "+doWhat;
         if (alertsMessage) Alert(message);
         if (alertsEmail)   SendMail(_Symbol+" NonLag ma MACD",message);
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

double getPrice(ENUM_APPLIED_PRICE price,const double& open[], const double& close[], const double& high[], const double& low[],int i)
{
   switch (price)
   {
      case PRICE_CLOSE:     return(close[i]);
      case PRICE_OPEN:      return(open[i]);
      case PRICE_HIGH:      return(high[i]);
      case PRICE_LOW:       return(low[i]);
      case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
   }
   return(0);
}
  
//
//
//
//
//

string getIndicatorName()
{
   string progPath     = MQL5InfoString(MQL5_PROGRAM_PATH);
   string terminalPath = TerminalInfoString(TERMINAL_PATH);
   
   int startLength = StringLen(terminalPath)+17;
   int progLength  = StringLen(progPath);
         string indicatorName = StringSubstr(progPath,startLength);
                indicatorName = StringSubstr(indicatorName,0,StringLen(indicatorName)-4);
   return(indicatorName);
}

//
//
//
//
//
 
string getPeriodToString(int period)
{
   int i;
   static int    _per[]={1,2,3,4,5,6,10,12,15,20,30,0x4001,0x4002,0x4003,0x4004,0x4006,0x4008,0x400c,0x4018,0x8001,0xc001};
   static string _tfs[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes",
                         "15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours",
                         "12 hours","daily","weekly","monthly"};
   
   if (period==PERIOD_CURRENT) 
       period = Period();   
            for(i=0;i<20;i++) if(period==_per[i]) break;
   return(_tfs[i]);   
}


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

int dateArrayBsearch(datetime& times[], datetime toFind, int total)
{
   int mid   = 0;
   int first = 0;
   int last  = total-1;
   
   while (last >= first)
   {
      mid = (first + last) >> 1;
      if (toFind == times[mid] || (mid < (total-1) && (toFind > times[mid]) && (toFind < times[mid+1]))) break;
      if (toFind <  times[mid])
            last  = mid - 1;
      else  first = mid + 1;
   }
   return (mid);
}