//+------------------------------------------------------------------+
//|                                                        J_TPO.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
//---- indicator version
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//---- number of indicator buffers 2
#property indicator_buffers 2 
//---- only one plot is used
#property indicator_plots   1
//+----------------------------------------------+
//|  Indicator drawing parameters                |
//+----------------------------------------------+
//---- drawing indicator as a five-color histogram
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- five colors are used in the histogram
#property indicator_color1 Gray,Lime,Teal,Red,Brown
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//+----------------------------------------------+
//| Horizontal levels display parameters         |
//+----------------------------------------------+
#property indicator_level1 +0.5
#property indicator_level2  0.0
#property indicator_level3 -0.5
#property indicator_levelcolor Gray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//| Enumeration for the time series selection    |
//+----------------------------------------------+
enum Applied_price_      // Type of constant
  {
   PRICE_CLOSE_ = 1,     // Close
   PRICE_OPEN_,          // Open
   PRICE_HIGH_,          // High
   PRICE_LOW_,           // Low
   PRICE_MEDIAN_,        // Median Price (HL/2)
   PRICE_TYPICAL_,       // Typical Price (HLC/3)
   PRICE_WEIGHTED_,      // Weighted Close (HLCC/4)
   PRICE_SIMPLE,         // Simple Price (OC/2)
   PRICE_QUARTER_,       // Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  // TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   // TrendFollow_2 Price 
  };
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
input int Len_=14;                     // Smoothing period
input Applied_price_ IPC=PRICE_CLOSE_; // Price constant
//+----------------------------------------------+
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double ExtBuffer[],ColorExtBuffer[];
//----
int Len,LenM,LenP;
double Kf,Kl;
double arr0[],arr1[],arr2[],arr3[];
double Arr0[],Arr1[],Arr2[],Arr3[];
//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- initialization of variables
   Len=int(MathMax(Len_,3));
   LenM=Len-1;
   LenP=LenM+1;
   double k=LenP;
   Kf = 12 / (k * (k - 1) * (k + 1));
   Kl = (LenP + 1) * 0.5;

//---- initialization of variables of the start of data calculation 
   min_rates_total=2*Len+1;

//---- memory distribution for variables' arrays
   int size=Len+2;
   if(ArrayResize(arr0,size)<size) {Print("Failed to distribute the memory for arr0[] array"); return(-1);}
   if(ArrayResize(arr1,size)<size) {Print("Failed to distribute the memory for arr1[] array"); return(-1);}
   if(ArrayResize(arr2,size)<size) {Print("Failed to distribute the memory for arr2[] array"); return(-1);}
   if(ArrayResize(arr3,size)<size) {Print("Failed to distribute the memory for arr3[] array"); return(-1);}

   ArrayInitialize(arr0,0);
   ArrayInitialize(arr1,0);
   ArrayInitialize(arr2,0);
   ArrayInitialize(arr3,0);

//---- set ExtBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,ExtBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//---- set ColorExtBuffer[] dynamic array as an indicator buffer   
   SetIndexBuffer(1,ColorExtBuffer,INDICATOR_COLOR_INDEX);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total+1);

//---- indexing the elements in buffers as timeseries
   ArraySetAsSeries(ExtBuffer,true);
   ArraySetAsSeries(ColorExtBuffer,true);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double& high[],     // price array of maximums of price for the indicator calculation
                const double& low[],      // price array of minimums of price for the indicator calculation
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(rates_total<min_rates_total) return(0);

//---- declarations of local variables 
   int limit1,limit2;
   int run,count,fff,numbx,ppp,rrr,sss;
   double invelue1,invelue,tmp2,outvelue,tmp1,tmp,max,value,series;
   static int Count,run_;

//---- indexing elements in arrays as time series
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of the indicator calculation
     {
      limit1=rates_total-min_rates_total-1; // starting index for calculation of all bars
      limit2=limit1-1;
      ArrayInitialize(arr0,0);
      ArrayInitialize(arr1,0);
      ArrayInitialize(arr2,0);
      ArrayInitialize(arr3,0);
      Count=0;
      run_=0;
     }
   else
     {
      limit1=rates_total-prev_calculated; // starting index for calculation of all bars
      limit2=limit1;                      // starting index for calculation of new bars
     }

//---- restore values of the variables
   ArrayCopy(arr0,Arr0,0,0,WHOLE_ARRAY);
   ArrayCopy(arr1,Arr1,0,0,WHOLE_ARRAY);
   ArrayCopy(arr2,Arr2,0,0,WHOLE_ARRAY);
   ArrayCopy(arr3,Arr3,0,0,WHOLE_ARRAY);
   count=Count;
   run=run_;

//---- main indicator calculation loop
   for(int bar=limit1; bar>=0 && !IsStopped(); bar--)
     {
      //---- store values of the variables before running at the current bar
      if(rates_total!=prev_calculated && bar==0)
        {
         ArrayCopy(Arr0,arr0,0,0,WHOLE_ARRAY);
         ArrayCopy(Arr1,arr1,0,0,WHOLE_ARRAY);
         ArrayCopy(Arr2,arr2,0,0,WHOLE_ARRAY);
         ArrayCopy(Arr3,arr3,0,0,WHOLE_ARRAY);
         Count=count;
         run_=run;
        }

      //---- calling the PriceSeries function to get the 'Series' input price
      series=PriceSeries(IPC,bar,open,low,high,close);
      tmp2=0;
      tmp1=0;

      if(!count)
        {
         count=1;
         run=0;
         invelue=series;
         arr0[count]=invelue;
        }
      else
        {
         if(count<=LenP) count++;
         else count=LenP+1;

         invelue1=invelue;
         invelue=series;

         if(count>LenP)
           {
            for(fff=2; fff<=LenP; fff++) arr0[fff-1]=arr0[fff];
            arr0[LenP]=invelue;
           }
         else arr0[count]=invelue;

         if(LenM>= count && invelue1 != invelue) run = 1;
         if(LenM == count &&! run) count = 0;
        }

      if(count>=LenP)
        {
         for(rrr=1; rrr<=LenP; rrr++)
           {
            arr1[rrr] = arr0[rrr];
            arr2[rrr] = rrr;
            arr3[rrr] = rrr;
           }

         for(ppp=1; ppp<LenP; ppp++)
           {
            max=arr1[ppp];
            numbx=ppp;
            fff=ppp+1;

            for(fff=ppp+1; fff<=LenP; fff++)
               if(arr1[fff]<max)
                 {
                  max=arr1[fff];
                  numbx=fff;
                 }

            tmp=arr1[ppp];
            arr1[ppp]=arr1[numbx];
            arr1[numbx]=tmp;
            tmp=arr2[ppp];
            arr2[ppp]=arr2[numbx];
            arr2[numbx]=tmp;
           }

         ppp=1;
         while(LenP>ppp)
           {
            fff=ppp+1;
            tmp2 = 1;
            tmp1 = arr3[ppp];
            while(tmp2!=0)
              {
               if(arr1[ppp]!=arr1[fff])
                 {
                  if(fff-ppp>1)
                    {
                     tmp1/=fff-ppp;
                     sss=ppp;
                     for(sss=ppp; sss<fff; sss++) arr3[sss]=tmp1;
                    }

                  tmp2=0;
                 }
               else
                 {
                  tmp1+=arr3[fff];
                  fff=fff+1;
                 }
              }

            ppp=fff;
           }

         tmp1=0;
         for(ppp=1; ppp<=LenP; ppp++) tmp1+=(arr3[ppp]-Kl) *(arr2[ppp]-Kl);
         outvelue=Kf*tmp1;
        }
      else outvelue=0;

      value=outvelue;
      if(value==0) value=0.00001;

      ExtBuffer[bar]=value;
     }

//---- main cycle of the indicator coloring
   for(int bar=limit2; bar>=0; bar--)
     {
      ColorExtBuffer[bar]=0;

      if(ExtBuffer[bar]>0)
        {
         if(ExtBuffer[bar]>ExtBuffer[bar+1]) ColorExtBuffer[bar]=1;
         if(ExtBuffer[bar]<ExtBuffer[bar+1]) ColorExtBuffer[bar]=2;
        }

      if(ExtBuffer[bar]<0)
        {
         if(ExtBuffer[bar]<ExtBuffer[bar+1]) ColorExtBuffer[bar]=3;
         if(ExtBuffer[bar]>ExtBuffer[bar+1]) ColorExtBuffer[bar]=4;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+   
//| Getting values of a price timeseries                             |
//+------------------------------------------------------------------+ 
double PriceSeries(uint applied_price, // price constant
                   uint   bar,         // index of shift relative to the current bar for a specified number of periods back or forward
                   const double &Open[],
                   const double &Low[],
                   const double &High[],
                   const double &Close[])
  {
//----
   switch(applied_price)
     {
      //---- price constants from the ENUM_APPLIED_PRICE enumeration
      case  PRICE_CLOSE: return(Close[bar]);
      case  PRICE_OPEN: return(Open [bar]);
      case  PRICE_HIGH: return(High [bar]);
      case  PRICE_LOW: return(Low[bar]);
      case  PRICE_MEDIAN: return((High[bar]+Low[bar])/2.0);
      case  PRICE_TYPICAL: return((Close[bar]+High[bar]+Low[bar])/3.0);
      case  PRICE_WEIGHTED: return((2*Close[bar]+High[bar]+Low[bar])/4.0);

      //----                            
      case  8: return((Open[bar] + Close[bar])/2.0);
      case  9: return((Open[bar] + Close[bar] + High[bar] + Low[bar])/4.0);
      //----                                
      case 10:
        {
         if(Close[bar]>Open[bar])return(High[bar]);
         else
           {
            if(Close[bar]<Open[bar])
               return(Low[bar]);
            else return(Close[bar]);
           }
        }
      //----         
      case 11:
        {
         if(Close[bar]>Open[bar])return((High[bar]+Close[bar])/2.0);
         else
           {
            if(Close[bar]<Open[bar])
               return((Low[bar]+Close[bar])/2.0);
            else return(Close[bar]);
           }
         break;
        }
      //----
      default: return(Close[bar]);
     }
//----
//return(0);
  }
//+------------------------------------------------------------------+
