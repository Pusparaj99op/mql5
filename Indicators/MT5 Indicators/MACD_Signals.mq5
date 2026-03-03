//+------------------------------------------------------------------+
//|                                                    MyMACD_V2.mq5 |
//|                                               Copyright TheXpert |
//|                                           TheForEXpert@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) TheXpert, mailto:TheForEXpert@gmail.com"
#property link      "theforexpert@gmail.com"
#property version   "1.00"

#property indicator_separate_window

#property indicator_buffers 7
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  White, SkyBlue, FireBrick
#property indicator_width1  1

input string Copyright = "Copyright (c) TheXpert, mailto:TheForEXpert@gmail.com";

input string _1 = "Parameters for MACD";
input int MaFast = 5;
input int MaSlow = 73;
input int MaSignal = 13;

input string _2 = "Applied price";
input ENUM_APPLIED_PRICE Price = PRICE_WEIGHTED;

input string _3 = "Minimal distance from previous valuable extremum to be valuable";
input int Sequence = 17;

input bool Log = false;

#define NONE   0
#define UP     1
#define DN     -1

int Direction = NONE; 
double Last = 0;

datetime LastTime;

//---- buffers
double Values[];
double ValuesPainting[];
double PatternSignal[];
double Signal[];
double SignalDirection[];
double MACD[];
double SlowMA[];

string symbol;

int Length = 0;

int Prev = 0;
int PrevPrev = 0;
int PrevPrevPrev = 0;

double PrevValue = 0;
double PrevPrevValue = 0;
double PrevPrevPrevValue = 0;

double LastSignalValue = 0;
int LastSignal = 0;
bool IsLastSignal = false;

void PushBack(int Now, double NowValue)
{
   if (Prev == Now)
   {
      PrevValue = NowValue;
   }
   else
   {
      PrevPrevPrev = PrevPrev;
      PrevPrevPrevValue = PrevPrevValue;

      PrevPrev = Prev;
      PrevPrevValue = PrevValue;
   
      Prev = Now;
      PrevValue = NowValue;
   }
}

int MACDOrigin;
int SlowMAOrigin;

int OnInit()
{
   SetIndexBuffer(0, Values,           INDICATOR_DATA);
   SetIndexBuffer(1, ValuesPainting,   INDICATOR_COLOR_INDEX);
   
   SetIndexBuffer(2, PatternSignal,    INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, Signal,           INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, SignalDirection,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, SlowMA,           INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, MACD,             INDICATOR_CALCULATIONS);
   
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MaSlow);

   IndicatorSetString(INDICATOR_SHORTNAME, "MyMACD("+string(MaFast)+", "+string(MaSlow)+", "+string(MaSignal)+")");
   
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   MACDOrigin = iMACD(NULL, 0, MaFast, MaSlow, MaSignal, Price);
   SlowMAOrigin = iMA(NULL, 0, MaSlow, 0, MODE_EMA, PRICE_CLOSE);
   
   ArraySetAsSeries(Values, true);
   ArraySetAsSeries(ValuesPainting, true);
   ArraySetAsSeries(PatternSignal, true);
   ArraySetAsSeries(Signal, true);
   ArraySetAsSeries(SignalDirection, true);
   ArraySetAsSeries(SlowMA, true);
   ArraySetAsSeries(MACD, true);

   return(0);
}

int OnCalculate (
      const int bars,
      const int counted,
      const datetime& time[],     // Time
      const double& open[],       // Open
      const double& high[],       // High
      const double& low[],        // Low
      const double& close[],      // Close
      const long& tick_volume[],  // Tick Volume
      const long& volume[],       // Real Volume
      const int& spread[])        // Spread
{
   if (Log) Print("Started");
   
   int toCount = bars - (int)MathMax(counted - 1, 0);

   if (toCount <= 0) toCount = 1;

   if (Log) Print("MACDOrigin ", MACDOrigin, " SlowMAOrigin ", SlowMAOrigin, " bars ", bars, " counted ", counted, "toCount ", toCount);
   
   bool succeeded = 
      CopyBuffer(MACDOrigin, 1, 0, bars, MACD) != -1;
      
   if (!succeeded)
   {
      Print("Problems while getting MACD values, Last Error = ", GetLastError());
      return 0;
   }
   
   succeeded = 
      CopyBuffer(SlowMAOrigin, 0, 0, bars, SlowMA) != -1;
      
   if (!succeeded)
   {
      Print("Problems while getting MA values, Last Error = ", GetLastError());
      return 0;
   }
   
   for (int i = toCount - 1; i >= 0; i--)
   {
      if (SlowMA[i] != 0)
      {
         Values[i] = MACD[i]/SlowMA[i];
      }
      else if (Log) Print("Bad MA Value");
   }

   for (int i = toCount - 2; i >= 0; i--)
   {
      double now = Values[i];
      
      Signal[i + 1] = 0;
      
      if (i < bars - 2) 
      {
         SignalDirection[i + 1] = SignalDirection[i + 2];
      }
      
      PatternSignal[i + 1] = 0;

      if (Last == 0)
      {
         Last = now;
         continue;
      }

      if (Direction == NONE)
      {
         if (Last > now) Direction = DN;
         if (Last < now) Direction = UP;

         Last = now;
         Length = 1;
         
         continue;
      }
      
      if ((now - Last)*Direction > 0)
      {
         Last = now;
         Length++;
         
         Signal[i + 1] = 0;
         
         continue;
      }

      if ((now - Last)*Direction < 0)
      {
         Direction = -Direction;
         Signal[i + 1] = Direction*Values[i + 1];
         
         Last = now;
         
         if (Prev == 0)
         {
            PushBack(Direction, now);
            Length = 1;
            continue;
         }
         else
         {
            if (IsLastSignal)
            {
               if (Length > Sequence)
               {
                  PushBack(LastSignal, LastSignalValue);
                  PushBack(Direction, now);
                  IsLastSignal = false;
               }
               else
               {
                  LastSignal = Direction;
                  LastSignalValue = now;
                  Length = 1;
                  continue;
               }
            }
            else
            {
               if (Length > Sequence)
               {
                  PushBack(Direction, now);
               }
               else
               {
                  LastSignal = Direction;
                  LastSignalValue = now;
                  IsLastSignal = true;
                  Length = 1;
                  continue;
               }
            }

            Length = 1;
            
            // patterns
            if (     Prev == 1 
                  && PrevValue > PrevPrevPrevValue) PatternSignal[i + 1] = 1;
         
            if (     Prev == -1 
                  && PrevValue < PrevPrevPrevValue) PatternSignal[i + 1] = -1;
         
            if (     Prev == 1 
                  && PrevValue > -0.1*PrevPrevValue) PatternSignal[i + 1] = 1;
         
            if (     Prev == -1 
                  && PrevValue < -0.1*PrevPrevValue) PatternSignal[i + 1] = -1; 
                  
            if (PatternSignal[i + 1] != 0) 
            {
               if (PatternSignal[i + 1] > 0) 
               {
                  SignalDirection[i + 1] = 1;
               }
               
               if (PatternSignal[i + 1] < 0) 
               {
                  SignalDirection[i + 1] = -1;
               }
            }
         }
      }
   }
   
   for (int j = toCount - 1; j >= 0; j--)
   {
      if (SignalDirection[j] > 0)
      {
         ValuesPainting[j] = 1;
      }
      else if (SignalDirection[j] < 0)
      {
         ValuesPainting[j] = 2;
      }
   }
   
   return(bars);
}
