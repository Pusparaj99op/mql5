//+---------------------------------------------------------------------+ 
//|                                                           OsHMA.mq5 |
//|                                            Copyright © 2009, sealdo |
//|                                                    sealdo@yandex.ru |
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property  copyright "Copyright © 2009, sealdo"
#property  link      "sealdo@yandex.ru" 
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window 
//---- количество индикаторных буферов 2
#property indicator_buffers 2 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//|  Параметры отрисовки индикатора   |
//+-----------------------------------+
//---- отрисовка индикатора в виде четырёхцветной гистограммы
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//---- в качестве цветов четырёхцветной гистограммы использованы
#property indicator_color1 clrGray,clrBlue,clrDodgerBlue,clrDarkOrange,clrMagenta
//---- линия индикатора - сплошная
#property indicator_style1 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение метки индикатора
#property indicator_label1 "OsHMA"
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input int FastHMA=13; // Период быстрой HMA
input int SlowHMA=26; // Период медленной HMA
//+-----------------------------------+
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[],ColorIndBuffer[];
//---- Объявление целых переменных
int fHma2_Period,fSqrt_Period,sHma2_Period,sSqrt_Period;
//+------------------------------------------------------------------+    
//| OsHMA indicator initialization function                          | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Инициализация переменных
   fHma2_Period=int(MathFloor(FastHMA/2));
   sHma2_Period=int(MathFloor(SlowHMA/2));
   fSqrt_Period=int(MathFloor(MathSqrt(FastHMA)));
   sSqrt_Period=int(MathFloor(MathSqrt(SlowHMA)));

//---- Инициализация переменных начала отсчёта данных
   min_rates_total=MathMax(fHma2_Period+fSqrt_Period,sHma2_Period+sSqrt_Period);

//---- превращение динамического массива IndBuffer в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- создание метки для отображения в DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Ind");
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);

//---- имя для окон данных и лэйба для субъокон 
   string short_name="OsHMA";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name+"("+string(FastHMA)+","+string(SlowHMA)+")");
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+
// Описание класса CMoving_Average                                   | 
//+------------------------------------------------------------------+  
#include <SmoothAlgorithms.mqh>
//+------------------------------------------------------------------+  
//| OsHMA iteration function                                         | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,     // количество истории в барах на текущем тике
                const int prev_calculated, // количество истории в барах на предыдущем тике
                const int begin,           // номер начала достоверного отсчёта баров
                const double &price[]      // ценовой массив для расчёта индикатора
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total+begin) return(0);

//---- объявления локальных переменных 
   int first,bar;
   double lwma1,lwma2,fhma,shma,series;
   static uint fbegin,sbegin;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated==0) // проверка на первый старт расчёта индикатора
     {
      first=begin; // стартовый номер для расчёта всех баров
      int minbar=min_rates_total+begin;  
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,minbar);
      for(bar=0; bar<=minbar; bar++) IndBuffer[bar]=0;
      fbegin=FastHMA+1+begin;
      sbegin=SlowHMA+1+begin;
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- объявление переменной класса CMoving_Average из файла HMASeries_Cls.mqh
   static CMoving_Average MA1,MA2,MA3,MA4,MA5,MA6;

//---- основной цикл расчёта индикатора
   for(bar=first; bar<rates_total; bar++)
     {
      series=price[bar];

      lwma1=MA1.LWMASeries(begin,prev_calculated,rates_total,fHma2_Period,series,bar,false);
      lwma2=MA2.LWMASeries(begin,prev_calculated,rates_total,FastHMA,series,bar,false);
      fhma=MA3.LWMASeries(fbegin,prev_calculated,rates_total,fSqrt_Period,2*lwma1-lwma2,bar,false);
      //----
      lwma1=MA4.LWMASeries(begin,prev_calculated,rates_total,sHma2_Period,series,bar,false);
      lwma2=MA5.LWMASeries(begin,prev_calculated,rates_total,SlowHMA,series,bar,false);
      shma=MA6.LWMASeries(sbegin,prev_calculated,rates_total,sSqrt_Period,2*lwma1-lwma2,bar,false);
      //----
      IndBuffer[bar]=fhma-shma;
     }

   if(prev_calculated>rates_total || prev_calculated<=0) first++;
//---- Основной цикл раскраски индикатора Ind
   for(bar=first; bar<rates_total; bar++)
     {
      ColorIndBuffer[bar]=0;

      if(IndBuffer[bar]>0)
        {
         if(IndBuffer[bar]>IndBuffer[bar-1]) ColorIndBuffer[bar]=1;
         if(IndBuffer[bar]<IndBuffer[bar-1]) ColorIndBuffer[bar]=2;
        }

      if(IndBuffer[bar]<0)
        {
         if(IndBuffer[bar]<IndBuffer[bar-1]) ColorIndBuffer[bar]=3;
         if(IndBuffer[bar]>IndBuffer[bar-1]) ColorIndBuffer[bar]=4;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
