//+------------------------------------------------------------------+
//|                                         LarryWilliams_MinMax.mq5 |
//|                                      Copyright 2014, PunkBASSter |
//|                      https://login.mql5.com/en/users/punkbasster |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, PunkBASSter"
#property link      "https://login.mql5.com/en/users/punkbasster"
#property version   "1.1"


#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6
//--- plot Max1
#property indicator_label1  "Max1"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Min1
#property indicator_label2  "Min1"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot Max2
#property indicator_label3  "Max2"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot Min2
#property indicator_label4  "Min2"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot Max3
#property indicator_label5  "Max3"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrRed
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- plot Min3
#property indicator_label6  "Min3"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrRed
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1


class LastExtremums //class for storing and processing 2 last extremums for faster search of next level extremums
{
public:
   double   m_price[2];
   int      m_pos[2];

            LastExtremums()
               {
                  ArrayInitialize(m_price,0);
                  ArrayInitialize(m_pos,0);
               }
           ~LastExtremums(){};
   void     push(double price, int pos)
               {
                  m_price[0]=m_price[1];
                  m_price[1]=price;
                  m_pos[0]=m_pos[1];
                  m_pos[1]=pos;
               }
   int      checkMax(double last)
               {
                  if(m_price[0]<=m_price[1] && m_price[1]>=last)return(m_pos[1]);
                  else return 0;
               }
   int      checkMin(double last)
               {
                  if(m_price[0]>=m_price[1] && m_price[1]<=last)return(m_pos[1]);
                  else return 0;
               }
};

//--- input parameters
input bool     IgnoreInsideBars=true;

//--- indicator buffers
double         Max1Buffer[];
double         Min1Buffer[];
double         Max2Buffer[];
double         Min2Buffer[];
double         Max3Buffer[];
double         Min3Buffer[];
//--- temporary buffers
LastExtremums  MaxTemp1,MaxTemp2,MinTemp1,MinTemp2;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,Max1Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,Min1Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,Max2Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,Min2Buffer,INDICATOR_DATA);
   SetIndexBuffer(4,Max3Buffer,INDICATOR_DATA);
   SetIndexBuffer(5,Min3Buffer,INDICATOR_DATA);
   
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,3);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,3);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,3);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,3);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,3);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,3);

//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,159);
   PlotIndexSetInteger(1,PLOT_ARROW,159);
   PlotIndexSetInteger(2,PLOT_ARROW,159);
   PlotIndexSetInteger(3,PLOT_ARROW,159);
   PlotIndexSetInteger(4,PLOT_ARROW,159);
   PlotIndexSetInteger(5,PLOT_ARROW,159);
   
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-4);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,4);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-8);
   PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,8);
   
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);

//---
   return(INIT_SUCCEEDED);
  }
  

//+------------------------------------------------------------------+
//| Checking if the specified bar has a short-term maximum           |
//| Returns maximum value or 0                             |
//+------------------------------------------------------------------+
double CheckShortMax(const double &high[], const double &low[], int pos)
{
   if(!IgnoreInsideBars)   //consider inside bars as normal
   {
      if(high[pos]>=high[pos+1] && high[pos]>high[pos-1])return high[pos];
   }
   else                    //ignore inside bars while getting short-term extremums
   {
      if(high[pos-1]>=high[pos] && low[pos-1]<=low[pos])return 0;
   //looking left
      int i=pos-1;//nearest left bar
      while(i>2)
      {
         if(high[i-1]>=high[i] && low[i-1]<=low[i])i--;//moving to the previous bar if current is an inside one
         else break;
      }
   //looking right
      int limit=ArraySize(high)-2;
      int j=pos+1;//nearest right bar
      while(j<=limit)//loop for calculating indexes
      {
         if(high[j-1]>=high[j] && low[j-1]<=low[j])j++;//moving to the next bar if current is an inside one
         else break;
      }

   //checking maximum
      if(high[pos]>=high[i] && high[pos]>high[j])
         return high[pos];
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Checking if the specified bar has a short-term minimum           |
//| Returns minimum value or 0                             |
//+------------------------------------------------------------------+
double CheckShortMin(const double &high[], const double &low[], int pos)
{
   if(!IgnoreInsideBars)   //consider inside bars as normal
   {
      if(low[pos]<=low[pos+1] && low[pos]<low[pos-1])//minimum condition
         return low[pos];
   }
   else                    //ignore inside bars while getting short-term extremums
   {
      if(high[pos-1]>=high[pos] && low[pos-1]<=low[pos])return 0;
   //looking left
      int i=pos-1;//nearest left bar
      while(i>2)
      {
         if(high[i-1]>=high[i] && low[i-1]<=low[i])i--;//moving to the previous bar if current is an inside one
         else break;
      }
   //looking right
      int limit=ArraySize(high)-2;
      int j=pos+1;//nearest right bar
      while(j<=limit)
      {
         if(high[j-1]>=high[j] && low[j-1]<=low[j])j++;//moving to the next bar if current is an inside one
         else break;
      }
      
   //checking minimum
      if(low[pos]<=low[i] && low[pos]<low[j])
         return low[pos];
   }
   return 0;
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
//---
//---
   Max1Buffer[rates_total-1]=0;
   Min1Buffer[rates_total-1]=0;
   Max2Buffer[rates_total-1]=0;
   Min2Buffer[rates_total-1]=0;
   Max3Buffer[rates_total-1]=0;
   Min3Buffer[rates_total-1]=0;
   Max1Buffer[rates_total-2]=0;
   Min1Buffer[rates_total-2]=0;
   Max2Buffer[rates_total-2]=0;
   Min2Buffer[rates_total-2]=0;
   Max3Buffer[rates_total-2]=0;
   Min3Buffer[rates_total-2]=0;

   for(int i=prev_calculated>=3?prev_calculated-2:3 ; i<rates_total-2; i++)
   {
   //--- Short-term extremums
      double newmax=CheckShortMax(high,low,i);//finding short-term maximum (level 1)
      double newmin=CheckShortMin(high,low,i);//finding short-term minimun (level 1)
      Max1Buffer[i]=newmax;
      Min1Buffer[i]=newmin;
      Max2Buffer[i]=0;
      Min2Buffer[i]=0;
      Max3Buffer[i]=0;
      Min3Buffer[i]=0;

      int pos=0,lpos=0,poz=0,lpoz=0;
   //--- Intermediate, long-term maximums
      if(newmax!=EMPTY_VALUE && newmax>0)//if the new short-term maximum is found
      {
         pos=MaxTemp1.checkMax(newmax);//checking if 2 last maximums+newmax together form an intermediate maximum
         if(pos && pos!=i)
         {
            Max2Buffer[pos]=Max1Buffer[pos];
            lpos=MaxTemp2.checkMax(Max2Buffer[pos]);
            if(lpos)Max3Buffer[lpos]=Max2Buffer[lpos];
            MaxTemp2.push(Max2Buffer[pos],pos);
         }
         MaxTemp1.push(newmax,i);
      }
   
   //--- Intermediate, long-term minimums
      if(newmin!=EMPTY_VALUE && newmin>0)
      {
         poz=MinTemp1.checkMin(newmin);
         if(poz && poz!=i)
         {
            Min2Buffer[poz]=Min1Buffer[poz];
            lpoz=MinTemp2.checkMin(Min2Buffer[poz]);
            if(lpoz)Min3Buffer[lpoz]=Min2Buffer[lpoz];
            MinTemp2.push(Min2Buffer[poz],poz);
         }
         MinTemp1.push(newmin,i);
      }
   //--- force validation

  }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
