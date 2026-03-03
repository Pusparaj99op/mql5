//+------------------------------------------------------------------+
//|                                                   WildersDMI.mq5 |
//|                           Copyright © 2007, TrendLaboratory Ltd. |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//|                                       E-mail: igorad2004@list.ru |
//+------------------------------------------------------------------+
//---- Copyright
#property copyright "Copyright © 2007, TrendLaboratory Ltd."
#property link      "http://finance.groups.yahoo.com/group/TrendLaboratory"
//---- Description of the indicator
#property description ""
//---- The indicator is drawn in a separate window
#property indicator_separate_window
//---- Four buffers are used for the indicator calculation and drawing
#property indicator_buffers 4
//---- Four graphical constructions are used
#property indicator_plots   4
//+----------------------------------------------+
//| Parameters for the ADX indicator             |
//+----------------------------------------------+
//---- Indicator 1 is drawn as a line
#property indicator_type1   DRAW_LINE
//---- Blue is used for the color of the indicator line
#property indicator_color1  clrBlue
//---- Indicator 1 line is solid
#property indicator_style1  STYLE_SOLID
//---- Line width of the indicator 1 is 2
#property indicator_width1  2
//---- The indicator label
#property indicator_label1  "ADX"
//+----------------------------------------------+
//| Parameters for drawing +DI                   |
//+----------------------------------------------+
//---- Indicator 2 is drawn as a line
#property indicator_type2   DRAW_LINE
//---- Green is used for the color of the indicator line
#property indicator_color2  clrGreen
//---- Dot-dash line for the indicator 2
#property indicator_style2  STYLE_DASHDOT
//---- Line width of the indicator 2 is 1
#property indicator_width2  1
//---- The indicator label
#property indicator_label2  "+DI"
//+----------------------------------------------+
//| Parameters for drawing -DI                   |
//+----------------------------------------------+
//---- Indicator 3 is drawn as a line
#property indicator_type3   DRAW_LINE
//---- Tomato is used for the color of the indicator line
#property indicator_color3  clrTomato
//---- Indicator 3 is a dotted line
#property indicator_style3  STYLE_DASHDOT
//---- Line width of the indicator 3 is 1
#property indicator_width3  1
//---- The indicator label
#property indicator_label3  "-DI"
//+----------------------------------------------+
//| Parameters for drawing ADXR                  |
//+----------------------------------------------+
//---- Indicator 4 is drawn as a line
#property indicator_type4   DRAW_LINE
//---- Orange is used for the color of the indicator line
#property indicator_color4  clrOrange
//---- Indicator 4 is a solid line
#property indicator_style4  STYLE_SOLID
//---- Line width of the indicator 4 is 2
#property indicator_width4  2
//---- The indicator label
#property indicator_label4  "ADXR"
//+----------------------------------------------+
//|  Declaring constants                         |
//+----------------------------------------------+
#define RESET 0 // A constant for returning an indicator recalculation command to the terminal

//+----------------------------------------------+
//|  INPUT PARAMETERS OF THE INDICATOR           |
//+----------------------------------------------+
input uint MA_Length=1;    // Period of additional smoothing 
input uint DMI_Length=14;  // Period of DMI
input uint ADX_Length=14;  // Period of ADX
input uint ADXR_Length=14; // Period of ADXR
input bool UseADX=true;    // Use ADX
input bool UseADXR=true;   // Use ADXR
input int  Shift=0;        // Horizontal shift of the indicator in bars
//+----------------------------------------------+
//---- Declaring dynamic arrays that will further be used as indicator buffers
double ADX[];
double PDI[];
double MDI[];
double ADXR[];
//---- Declaring integer variables for data calculation start
int min_rates_total;
double alfa1,alfa2;
//---- Declaring integer variables for the indicator handles
int CMA_Handle,LMA_Handle,HMA_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=int(MA_Length+1+ADXR_Length);
   alfa1=1.0/DMI_Length;
   alfa2=1.0/ADX_Length;

//---- Getting the handle of the iMA indicator
   CMA_Handle=iMA(NULL,0,MA_Length,0,MODE_EMA,PRICE_CLOSE);
   if(CMA_Handle==INVALID_HANDLE) Print(" Failed to get the handle of the iMA indicator");

//---- Getting the handle of the iMA indicator
   HMA_Handle=iMA(NULL,0,MA_Length,0,MODE_EMA,PRICE_HIGH);
   if(HMA_Handle==INVALID_HANDLE) Print(" Failed to get the handle of the iMA indicator");

//---- Getting the handle of the iMA indicator
   LMA_Handle=iMA(NULL,0,MA_Length,0,MODE_EMA,PRICE_LOW);
   if(LMA_Handle==INVALID_HANDLE) Print(" Failed to get the handle of the iMA indicator");

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(0,ADX,INDICATOR_DATA);
//---- Shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- Shifting the beginning of indicator 1 drawing by min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ADX,true);

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(1,PDI,INDICATOR_DATA);
//---- Shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- Shifting the beginning of indicator 2 drawing by на min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(PDI,true);

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(2,MDI,INDICATOR_DATA);
//---- Shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- Shifting the beginning of indicator 3 drawing by на min_rates_total
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(MDI,true);

//---- Set dynamic array as an indicator buffer
   SetIndexBuffer(3,ADXR,INDICATOR_DATA);
//---- Shifting the indicator 2 horizontally by Shift
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- Shifting the beginning of indicator 4 drawing by на min_rates_total
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- Setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- Indexing elements in the buffer as in timeseries
   ArraySetAsSeries(ADXR,true);

//---- Initializations of variable for indicator short name
   string short_name="WildersDMI("+string(MA_Length)+","+string(DMI_Length)+","+string(ADX_Length)+","+string(ADXR_Length)+")";
//--- Creating a name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

//--- Determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- Checking if the number of bars is enough for the calculation
   if(BarsCalculated(CMA_Handle)<rates_total
      || BarsCalculated(HMA_Handle)<rates_total
      || BarsCalculated(LMA_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);

//---- declaration of local variables 
   int to_copy,limit,bar;
   double CMA[],HMA[],LMA[];
   double sPDI,sMDI,DX,STR;
   static double sPDI_,sMDI_,STR_;

//---- Calculations of the necessary number of copied data and limit starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of calculation of an indicator
     {
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
      sPDI_=0;
      sMDI_=0;
      STR_=0;
      
      for(bar=rates_total-1; bar>limit && !IsStopped(); bar--) ADX[bar]=0;
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for the calculation of new bars
     }

   to_copy=limit+2;

//---- copy newly appeared data into the arrays
   if(CopyBuffer(CMA_Handle,0,0,to_copy,CMA)<=0) return(RESET);
   if(CopyBuffer(HMA_Handle,0,0,to_copy,HMA)<=0) return(RESET);
   if(CopyBuffer(LMA_Handle,0,0,to_copy,LMA)<=0) return(RESET);

//---- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(CMA,true);
   ArraySetAsSeries(HMA,true);
   ArraySetAsSeries(LMA,true);

//---- main cycle of calculation of the indicator
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      double AvgHigh =HMA[bar];
      double AvgHigh1=HMA[bar+1];
      double AvgLow  =LMA[bar];
      double AvgLow1 =LMA[bar+1];
      double AvgClose1=CMA[bar+1];
      double hres=AvgHigh-AvgHigh1;
      double lres=AvgLow1-AvgLow;
      double Bulls=0.5*(MathAbs(hres)+hres);
      double Bears=0.5*(MathAbs(lres)+lres);
      
      if(Bulls>Bears) Bears=0;
      else if(Bulls<Bears) Bulls=0;
      else if(Bulls==Bears)
        {
         Bulls=0;
         Bears=0;
        }

      sPDI=sPDI_+alfa1*(Bulls-sPDI_);
      sMDI=sMDI_+alfa1*(Bears-sMDI_);

      double TR=MathMax(AvgHigh-AvgLow,AvgHigh-AvgClose1);
      STR=STR_+alfa1*(TR-STR_);

      if(STR>0)
        {
         PDI[bar]=100*sPDI/STR;
         MDI[bar]=100*sMDI/STR;
        }
      else
        {
         PDI[bar]=0;
         MDI[bar]=0;
        }

      if(UseADX)
        {
         double res=PDI[bar]+MDI[bar];
         if(res>0) DX=100*MathAbs(PDI[bar]-MDI[bar])/res;
         else DX=0;

         ADX[bar]=ADX[bar+1]+alfa2*(DX-ADX[bar+1]);
         if(UseADXR) ADXR[bar]=0.5*(ADX[bar]+ADX[bar+ADXR_Length]);
         else ADXR[bar]=0;
        }
      else ADX[bar]=0;

      if(bar)
        {
         sPDI_=sPDI;
         sMDI_=sMDI;
         STR_=STR;
        }

     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
