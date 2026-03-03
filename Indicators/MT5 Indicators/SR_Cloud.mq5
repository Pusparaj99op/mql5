//+------------------------------------------------------------------+ 
//|                                                     SR_Cloud.mq5 | 
//|                                          Copyright © 2013, HgCl2 | 
//|                                                                  | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2013, HgCl2"
#property link ""
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 2
#property indicator_buffers 2 
//---- использовано одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//|  Параметры отрисовки индикатора   |
//+-----------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цвета индикатора использован Khaki
#property indicator_color1  clrKhaki
//---- отображение метки индикатора
#property indicator_label1  "SR_Cloud"
//+-----------------------------------+
//|  Объявление перечисления          |
//+-----------------------------------+
enum Applied_price_ //Тип константы
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
  };
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input double k_std=1.0;
input Applied_price_ Price=PRICE_OPEN_;
//+-----------------------------------+
double m[10000];
double o[10000];
//---- Объявление целых переменных начала отсчёта данных
int  min_rates_total;
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double ExtABuffer[];
double ExtBBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=2;

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,ExtABuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ExtABuffer,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,ExtBBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ExtBBuffer,true);

//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"SR_Cloud("+DoubleToString(k_std,4)+")");
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);

//---- Объявление переменных с плавающей точкой  
   static double LastHigh,LastLow;
   double g1=0.0,g2=0.0;
//---- Объявление целых переменных
   int limit,x=0;

//---- расчёт стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
      for(int bar=rates_total-1; bar>=0 && !IsStopped(); bar--)
        {
         ExtABuffer[bar]=0.0;
         ExtBBuffer[bar]=0.0;
        }
      LastHigh=0;
      LastLow=999999999;
     }
   else limit=rates_total-prev_calculated;  // стартовый номер для расчёта только новых баров

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
   if(Price==PRICE_OPEN_) ArraySetAsSeries(Open,true);
   else ArraySetAsSeries(Close,true);

//---- основной цикл расчёта индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      LastHigh=MathMax(LastHigh,High[bar+1]);
      LastLow=MathMin(LastLow,Low[bar+1]);
      
      MqlDateTime tm0,tm1;
      TimeToStruct(Time[bar],tm0);
      TimeToStruct(Time[bar+1],tm1);

      if(tm0.day!=tm1.day)
        {
         x++;
         if(Price==PRICE_OPEN_) o[x]=Open[bar];
         else o[x]=Close[bar];
         m[x]=LastHigh-o[x-1];

         if(LastHigh-o[x-1]>o[x-1]-LastLow) m[x]=o[x-1]-LastLow;

         LastLow=999999999;
         LastHigh=0;

         if(x>15)
           {
            double a1 = m[x];
            double a2 = m[x-1];
            double a3 = m[x-2];
            double a4 = m[x-3];
            double a5 = m[x-4];
            double a6 = m[x-5];
            double a7 = m[x-6];
            double a8 = m[x-7];
            double a9 = m[x-8];
            double a10 = m[x-9];
            double a11 = m[x-10];
            double a12 = m[x-11];
            double a13 = m[x-12];
            double a14 = m[x-13];
            //----
            double ax = 0.1111111 * (a1+a2+a3+a4+a5+a6+a7+a8+a9);
            double ay = 0.0714285 * (a1+a2+a3+a4+a5+a6+a7+a8+a9+a10+a11+a12+a13+a14);
            //----
            double stx=0.1111111 *(( a1-ax) *(a1-ax)+(a2-ax) *(a2-ax)+(a3-ax) *(a3-ax)+
                                   (a4-ax) *(a4-ax)+(a5-ax) *(a5-ax)+(a6-ax) *(a6-ax)+(a7-ax) *(a7-ax)
                                   +(a8-ax) *(a8-ax)+(a9-ax) *(a9-ax));
            //----
            double sty=0.0714285 *(( a1-ay) *(a1-ay)+(a2-ay) *(a2-ay)+(a3-ay) *(a3-ay)+
                                   (a4-ay) *(a4-ay)+(a5-ay) *(a5-ay)+(a6-ay) *(a6-ay)+(a7-ay) *(a7-ay)
                                   +(a8-ay) *(a8-ay)+(a9-ay) *(a9-ay)+(a10-ay) *(a10-ay)+(a11-ay) *(a11-ay)
                                   +(a12-ay) *(a12-ay)+(a13-ay) *(a13-ay)+(a14-ay) *(a14-ay));
            //----
            double st1 = ax + k_std * MathPow(stx,0.5);
            double st2 = ay + k_std * MathPow(sty,0.5);
            double std=st2;
            if(st1>st2) std=st1;
            g1 = o[x]+std;
            g2 = o[x]-std;
           }
        }

      if(x>15)
        {
         ExtABuffer[bar]=g1;
         ExtBBuffer[bar]=g2;
        }
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
