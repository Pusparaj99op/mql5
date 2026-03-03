//+------------------------------------------------------------------+
//|                                      Colored moving averages.mq5 |
//+------------------------------------------------------------------+
#property copyright "Mladen"
#property link      "http://www.forex-tsd.com"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1

//
//
//
//
//

#property indicator_label1  "Moving average"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//
//
//
//
//

input int                inpLength  = 14;           // Moving average period (length)
input ENUM_APPLIED_PRICE Price      = PRICE_CLOSE;  // Applied price
input ENUM_MA_METHOD     Method     = MODE_EMA;     // Moving average method
input color              ColorFrom  = Lime;         // "Fast up" color
input color              ColorTo    = DeepPink;     // "Fast down" color
input int                MaxAngle   = 20;           // Angle threshhold for color steps

//
//
//
//
//

double maBuffer[];
double maColors[];
double atrBuffer[];

int maHandle;
int atrHandle;

//
//
//
//
//

#define angleBars   6
#define atrBars   100

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,maBuffer ,INDICATOR_DATA);         ArraySetAsSeries(maBuffer ,true);
   SetIndexBuffer(1,maColors ,INDICATOR_COLOR_INDEX);  ArraySetAsSeries(maColors ,true);
   SetIndexBuffer(2,atrBuffer,INDICATOR_DATA);         ArraySetAsSeries(atrBuffer,true);

   //
   //
   //
   //
   //
   
   int iLength = (inpLength>0) ? inpLength : 1;
   
      maHandle  = iMA(NULL,0,iLength,0,Method,Price);
      atrHandle = iATR(NULL,0,atrBars);
      PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,20);
      for (int i=0;i<20;i++) 
               PlotIndexSetInteger(0,PLOT_LINE_COLOR,i,gradientColor(i,20,ColorTo,ColorFrom));
   return(0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
               
      int limit = rates_total-prev_calculated;
          if (prev_calculated >  0) limit++;
          if (prev_calculated == 0) limit-=(angleBars+1);

      if (!checkCalculated(maHandle ,rates_total,"averages")) return(prev_calculated);
      if (!checkCalculated(atrHandle,rates_total,"ATR"))      return(prev_calculated);
      if (!doCopy(maHandle,maBuffer,0,limit     ,"averages")) return(prev_calculated);
      if (!doCopy(atrHandle,atrBuffer,0,limit   ,"ATR"))      return(prev_calculated);
      
   //
   //
   //
   //
   //

   for(int i=limit; i>=0; i--) maColors[i] = slopeColor(i);
   return(rates_total);
}




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

#define Pi 3.141592653589793238462643

//
//
//

int slopeColor(int i)
{
   double range  = atrBuffer[i];
   double angle  = 0.00;
   double change = maBuffer[i]-maBuffer[i+angleBars];

      if (range != 0) angle = MathArctan(change/(range*angleBars))*180.0/Pi;
      
      int theColor = (int)round((angle+MaxAngle)/(MaxAngle/10.0));
          theColor = (theColor>=0) ? ((theColor<20) ? theColor : 19) : 0;
   return(theColor);
}

//
//
//
//
//

color gradientColor(int step, int totalSteps, color from, color to)
{
   color newBlue  = getColor(step,totalSteps,(from & 0XFF0000)>>16,(to & 0XFF0000)>>16)<<16;
   color newGreen = getColor(step,totalSteps,(from & 0X00FF00)>> 8,(to & 0X00FF00)>> 8) <<8;
   color newRed   = getColor(step,totalSteps,(from & 0X0000FF)    ,(to & 0X0000FF)    )    ;
   return(newBlue+newGreen+newRed);
}

color getColor(int stepNo, int totalSteps, color from, color to)
{
   double step = (from-to)/(totalSteps-1.0);
   return((color)round(from-step*stepNo));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//

bool checkCalculated(int bufferHandle, int total, string checkDescription)
{
   int calculated=BarsCalculated(bufferHandle);
   if (calculated<total)
   {
      Print("Not all data of "+checkDescription+" calculated (",(string)(total-calculated)," un-calculated bars )");
      return(false);
   }
   return(true);
}

//
//
//
//
//

bool doCopy(const int bufferHandle, double& buffer[], const int buffNum, const int copyCount, string copyDescription)
{
   if(CopyBuffer(bufferHandle,buffNum,0,copyCount,buffer)<=0)
   {
      Print("Getting "+copyDescription+" failed! Error",GetLastError());
      return(false);
   }
   return(true);
}