#property description ""
#property description ""
//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   3

#property indicator_label1  "eco trend"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'221,247,221',clrMistyRose
#property indicator_label2  "eco"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrLimeGreen,clrPaleVioletRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_label3  "eco signal"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrPaleVioletRed
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

//
//
//
//
//

enum enStyle
{
   dis_tape,  // Display as tape
   dis_zero,  // Display as zero based zone
   dis_line   // Display as lines
};
enum enColors
{
   cl_onSlope,  // Color based on the slope of the oscillator
   cl_onZero    // Color based on zero cross
};
input double   Length1      = 32;         // Jurik first length
input double   Length2      =  5;         // Jurik second length
input double   Length3      =  5;         // Jurik signal line length
input double   Phase        = 0.0;        // Jurik phase
input enColors ColorOnSlope =  cl_onZero; // Color based on : 
input enStyle  DisplayStyle = dis_zero;   // Display style

//
//
//
//
//

double eco[];
double sig[];
double fill1[];
double fill2[];
double colorBuffer[];

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
   SetIndexBuffer(0,fill1,INDICATOR_DATA);
   SetIndexBuffer(1,fill2,INDICATOR_DATA);
   SetIndexBuffer(2,eco  ,INDICATOR_DATA);
   SetIndexBuffer(3,colorBuffer,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(4,sig,INDICATOR_DATA);

   //
   //
   //
   //
   //
         
   IndicatorSetString(INDICATOR_SHORTNAME,"Blau jurik eco("+DoubleToString(Length1,2)+","+DoubleToString(Length2,2)+","+DoubleToString(Length3,2)+","+")");
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
   
   int i=(int)MathMax(prev_calculated-1,0); for (;i<rates_total && !_StopFlag; i++)
      {
         double co = iSmooth(iSmooth(close[i]-open[i],Length1,Phase,i,rates_total,0),Length2,Phase,i,rates_total,1);
         double hl = iSmooth(iSmooth(high[i]-low[i],  Length1,Phase,i,rates_total,2),Length2,Phase,i,rates_total,3);
            if (hl!=0)
                  eco[i]  = 100.0*co/hl;
            else  eco[i]  = 0;
                  sig[i]  = iSmooth(eco[i],Length3,Phase,i,rates_total,4);
                  
            //
            //
            //
            //
            //
                              
            if (i>0)
            {
               colorBuffer[i]=colorBuffer[i-1];
               if (ColorOnSlope==cl_onSlope)
               {
                  if (eco[i]>eco[i-1]) colorBuffer[i]=0;
                  if (eco[i]<eco[i-1]) colorBuffer[i]=1;
               }
               else
               {
                  if (eco[i]>0) colorBuffer[i]=0;
                  if (eco[i]<0) colorBuffer[i]=1;
               }                  
            }
            
            //
            //
            //
            //
            //
            
            fill1[i] = EMPTY_VALUE;
            fill2[i] = EMPTY_VALUE;
            switch (DisplayStyle)
            {
               case dis_tape:
                     if (colorBuffer[i] == 0) { fill1[i] = fmax(eco[i],sig[i]); fill2[i] = fmin(eco[i],sig[i]); }
                     if (colorBuffer[i] == 1) { fill1[i] = fmin(eco[i],sig[i]); fill2[i] = fmax(eco[i],sig[i]); }
                     break;
               case dis_zero:
                     if (ColorOnSlope==cl_onSlope)
                     {
                        if (colorBuffer[i] == 0 && eco[i]>0) { fill1[i] = eco[i]; fill2[i] = 0; }
                        if (colorBuffer[i] == 0 && eco[i]<0) { fill2[i] = eco[i]; fill1[i] = 0; }
                        if (colorBuffer[i] == 1 && eco[i]>0) { fill2[i] = eco[i]; fill1[i] = 0; }
                        if (colorBuffer[i] == 1 && eco[i]<0) { fill1[i] = eco[i]; fill2[i] = 0; }
                     }
                     else
                     {
                        fill1[i] = fmax(eco[i],0);
                        fill2[i] = fmin(eco[i],0);
                     }                        
                     break;
               case dis_line: break;
            }
      }      
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

#define _smoothInstances     5
#define _smoothInstancesSize 10
double  _smthWork[][_smoothInstances*_smoothInstancesSize];

#define bsmax  5
#define bsmin  6
#define volty  7
#define vsum   8
#define avolty 9

//
//
//
//
//

double iSmooth(double price, double length, double phase, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(_smthWork,0)!=bars) ArrayResize(_smthWork,bars); instanceNo*=_smoothInstancesSize;
   if (price==EMPTY_VALUE) price=0;

   int k = 0; if (r==0) { for(; k<7; k++) _smthWork[0][instanceNo+k]=price; for(; k<10; k++) _smthWork[0][instanceNo+k]=0; return(price); }

      //
      //
      //
      //
      //
  
      double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = MathMax(len1-2.0,0.5);
      double del1   = price - _smthWork[r-1][instanceNo+bsmax];
      double del2   = price - _smthWork[r-1][instanceNo+bsmin];
      double div    = 1.0/(10.0+10.0*(MathMin(MathMax(length-10,0),100))/100);
      int    forBar = (int)MathMin(r,10);

         _smthWork[r][instanceNo+volty] = (MathAbs(del1) > MathAbs(del2)) ? MathAbs(del1): (MathAbs(del1) < MathAbs(del2)) ? MathAbs(del2) : 0;
         _smthWork[r][instanceNo+vsum]  = _smthWork[r-1][instanceNo+vsum] + (_smthWork[r][instanceNo+volty]-_smthWork[r-forBar][instanceNo+volty])*div;
        
         //
         //
         //
         //
         //
              
         _smthWork[r][instanceNo+avolty] = _smthWork[r-1][instanceNo+avolty]+(2.0/(MathMax(4.0*length,30)+1.0))*(_smthWork[r][instanceNo+vsum]-_smthWork[r-1][instanceNo+avolty]);
         double dVolty = (_smthWork[r][instanceNo+avolty] > 0) ? _smthWork[r][instanceNo+volty]/_smthWork[r][instanceNo+avolty] : 0;  
            if (dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
            if (dVolty < 1)                      dVolty = 1.0;

         //
         //
         //
         //
         //
        
         double pow2 = MathPow(dVolty, pow1);
         double len2 = MathSqrt(0.5*(length-1))*len1;
         double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

            if (del1 > 0) _smthWork[r][instanceNo+bsmax] = price; else _smthWork[r][instanceNo+bsmax] = price - Kv*del1;
            if (del2 < 0) _smthWork[r][instanceNo+bsmin] = price; else _smthWork[r][instanceNo+bsmin] = price - Kv*del2;

      //
      //
      //
      //
      //
      
      double R     = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

         _smthWork[r][instanceNo+0] = price + alpha*(_smthWork[r-1][instanceNo+0]-price);
         _smthWork[r][instanceNo+1] = (price - _smthWork[r][instanceNo+0])*(1-beta) + beta*_smthWork[r-1][instanceNo+1];
         _smthWork[r][instanceNo+2] = (_smthWork[r][instanceNo+0] + R*_smthWork[r][instanceNo+1]);
         _smthWork[r][instanceNo+3] = (_smthWork[r][instanceNo+2] - _smthWork[r-1][instanceNo+4])*MathPow((1-alpha),2) + MathPow(alpha,2)*_smthWork[r-1][instanceNo+3];
         _smthWork[r][instanceNo+4] = (_smthWork[r-1][instanceNo+4] + _smthWork[r][instanceNo+3]);

   //
   //
   //
   //
   //

   return(_smthWork[r][instanceNo+4]);
}