//+------------------------------------------------------------------+
//|                                   Waddah_Attar_Hidden_Levels.mq5 |
//|           Copyright © 2007, Waddah Attar waddahattar@hotmail.com |
//|                             Waddah Attar waddahattar@hotmail.com |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Copyright © 2007, Waddah Attar waddahattar@hotmail.com"
//---- link to the website of the author
#property link      "waddahattar@hotmail.com"
//---- indicator version number
#property version   "1.00"
//---- drawing the indicator in the main window
#property indicator_chart_window
//---- number of indicator buffers 5
#property indicator_buffers 5
//---- only 5 graphical plots are used
#property indicator_plots   5
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type1   DRAW_LINE
//---- Red color is used as the color of the indicator line
#property indicator_color1 clrRed
//---- the indicator line width
#property indicator_width1  2
//---- the indicator line is a continuous curve
#property indicator_style1  STYLE_SOLID
//---- displaying the indicator label
#property indicator_label1  "Waddah Attar Hidden Level 1"
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type2   DRAW_LINE
//---- Green color is used as the color of the indicator line
#property indicator_color2 clrGreen
//---- the indicator line width
#property indicator_width2  2
//---- the indicator line is a continuous curve
#property indicator_style2  STYLE_SOLID
//---- displaying the indicator label
#property indicator_label2  "Waddah Attar Hidden Level 2"
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type3   DRAW_LINE
//---- Blue color is used for the indicator line
#property indicator_color3 clrBlue
//---- the indicator line width
#property indicator_width3  1
//---- the indicator line is a continuous curve
#property indicator_style3  STYLE_DASHDOTDOT
//---- displaying the indicator label
#property indicator_label3  "Waddah Attar Hidden Level 3"
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type4   DRAW_LINE
//---- Blue color is used for the indicator line
#property indicator_color4 clrBlue
//---- the indicator line width
#property indicator_width4  1
//---- the indicator line is a continuous curve
#property indicator_style4  STYLE_DASHDOTDOT
//---- displaying the indicator label
#property indicator_label4  "Waddah Attar Hidden Level 4"
//+-----------------------------------+
//|  Parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing the indicator as a line
#property indicator_type5   DRAW_LINE
//---- Blue color is used for the indicator line
#property indicator_color5 clrBlue
//---- the indicator line width
#property indicator_width5  1
//---- the indicator line is a continuous curve
#property indicator_style5  STYLE_DASHDOTDOT
//---- displaying the indicator label
#property indicator_label5  "Waddah Attar Hidden Level 5"
//+-----------------------------------+
//|  declaration of constants         |
//+-----------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS       |
//+-----------------------------------+
input int Symbol_P1 = 119; // level 1 label
input int Symbol_P2 = 119; // level 2 label
input int Symbol_P3 = 119; // level 3 label
input int Symbol_P4 = 119; // level 4 label
input int Symbol_P5 = 119; // level 5 label

input int iShift=0; // horizontal shift of the indicator in bars
//+-----------------------------------+

//---- Declaration of integer variables of data starting point
int min_rates_total,Shift;
//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
double P1_Buffer[],P2_Buffer[],P3_Buffer[],P4_Buffer[],P5_Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- checking correctness of the chart periods
   if(Period()>PERIOD_H8)
     {
      Print("The Waddah_Attar_Hidden_Levels  indicator chart period cannot be more than the period H8");
      return;
     }
//---- Initialization of variables of data calculation starting point
   min_rates_total=1+2*PeriodSeconds(PERIOD_D1)/PeriodSeconds(PERIOD_CURRENT);
   Shift=iShift+1;

//---- setting dynamic arrays as indicator buffers
   SetIndexBuffer(0,P1_Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,P2_Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,P3_Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,P4_Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,P5_Buffer,INDICATOR_DATA);

//---- indicator symbols
   PlotIndexSetInteger(0,PLOT_ARROW,Symbol_P1);
   PlotIndexSetInteger(1,PLOT_ARROW,Symbol_P2);
   PlotIndexSetInteger(2,PLOT_ARROW,Symbol_P3);
   PlotIndexSetInteger(3,PLOT_ARROW,Symbol_P4);
   PlotIndexSetInteger(4,PLOT_ARROW,Symbol_P5);

//---- restriction to draw empty values for the indicator
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- indexing the elements in buffers as in timeseries   
   ArraySetAsSeries(P1_Buffer,true);
   ArraySetAsSeries(P2_Buffer,true);
   ArraySetAsSeries(P3_Buffer,true);
   ArraySetAsSeries(P4_Buffer,true);
   ArraySetAsSeries(P5_Buffer,true);

//---- shifting the indicator 1 horizontally
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);

//---- data window name and subwindow label 
   IndicatorSetString(INDICATOR_SHORTNAME,"Waddah_Attar_Hidden_Levels");
//---- Setting the format of accuracy of displaying the indicator
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // amount of history in bars at the current tick
                const int prev_calculated,// amount of history in bars at the previous tick
                const datetime &Time[],
                const double &Open[],
                const double& High[],     // price array of maximums of price for the calculation of indicator
                const double& Low[],      // price array of minimums of price for the calculation of indicator
                const double &Close[],
                const long &Tick_volume[],
                const long &Volume[],
                const int &Spread[]
                )
  {
//---- 
   if(rates_total<min_rates_total || Period()>PERIOD_H8) return(RESET);
   
//---- indexing elements in arrays as in timeseries  
   ArraySetAsSeries(Time,true);
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Close,true);

   int limit,bar;
   datetime iTime[1];
   double iOpen[2],iClose[2],iHigh[2],iLow[2],c1,c2;
   
   static uint LastCountBar;
   static double;

//---- the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // starting number for calculation of all bars
      LastCountBar=rates_total;
     }
   else limit=int(LastCountBar)+rates_total-prev_calculated; // starting number for the calculation of new bars 

   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- copy new data to the iTime array
      if(CopyTime(Symbol(),PERIOD_D1,Time[bar],1,iTime)<=0) return(RESET);

      if(Time[bar]>=iTime[0] && Time[bar+1]<iTime[0])
        {
         LastCountBar=bar;

         //---- copy newly appeared data into the arrays
         if(CopyOpen(Symbol(),PERIOD_D1,Time[bar],2,iOpen)<=0) return(RESET);
         if(CopyLow(Symbol(),PERIOD_D1,Time[bar],2,iLow)<=0) return(RESET);
         if(CopyHigh(Symbol(),PERIOD_D1,Time[bar],2,iHigh)<=0) return(RESET);
         if(CopyClose(Symbol(),PERIOD_D1,Time[bar],2,iClose)<=0) return(RESET);

         if(iClose[0]>=iOpen[0])
           {
            c1 = (iHigh[0]-iClose[0])/2+iClose[0];
            c2 = (iOpen[0]-iLow[0])/2+iLow[0];
           }
         else
           {
            c1 = (iHigh[0]-iOpen[0])/2+iOpen[0];
            c2 = (iClose[0]-iLow[0])/2+iLow[0];
           }
           
         P1_Buffer[bar+1]=c1;
         P2_Buffer[bar+1]=c2;
         P3_Buffer[bar+1]=(c1+c2)/2;
         P4_Buffer[bar+1]=c1+(c1-c2)*0.618;
         P5_Buffer[bar+1]=c2-(c1-c2)*0.618;
         
         P1_Buffer[bar+2]=EMPTY_VALUE;
         P2_Buffer[bar+2]=EMPTY_VALUE;
         P3_Buffer[bar+2]=EMPTY_VALUE;
         P4_Buffer[bar+2]=EMPTY_VALUE;
         P5_Buffer[bar+2]=EMPTY_VALUE;
         
         P1_Buffer[bar]=c1;
         P2_Buffer[bar]=c2;
         P3_Buffer[bar]=(c1+c2)/2;
         P4_Buffer[bar]=c1+(c1-c2)*0.618;
         P5_Buffer[bar]=c2-(c1-c2)*0.618;
        }
      else
        {
         P1_Buffer[bar+1]=P1_Buffer[bar+2];
         P2_Buffer[bar+1]=P2_Buffer[bar+2];
         P3_Buffer[bar+1]=P3_Buffer[bar+2];
         P4_Buffer[bar+1]=P4_Buffer[bar+2];
         P5_Buffer[bar+1]=P5_Buffer[bar+2];
         
         P1_Buffer[bar]=EMPTY_VALUE;
         P2_Buffer[bar]=EMPTY_VALUE;
         P3_Buffer[bar]=EMPTY_VALUE;
         P4_Buffer[bar]=EMPTY_VALUE;
         P5_Buffer[bar]=EMPTY_VALUE;
        }
     }
//----   
   return(rates_total);
  }
//+------------------------------------------------------------------+
