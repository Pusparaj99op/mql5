//+------------------------------------------------------------------+
//|                           Williams_Accumulation_Distribution.mq5 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
//--- авторство индикатора
#property copyright "Copyright © 2007, MetaQuotes Software Corp."
//--- ссылка на сайт автора
#property link      "http://www.metaquotes.net"
//--- номер версии индикатора
#property version   "1.00"
//--- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//--- количество индикаторных буферов
#property indicator_buffers 1
//--- использовано всего одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//| Параметры отрисовки индикатора    |
//+-----------------------------------+
//--- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_LINE
//--- в качестве цвета бычей линии индикатора использован LightSeaGreen цвет
#property indicator_color1 clrLightSeaGreen
//--- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//--- толщина линии индикатора равна 2
#property indicator_width1  2
//--- отображение метки индикатора
#property indicator_label1  "Williams_Accumulation_Distribution"
//+-----------------------------------+
//| Входные параметры индикатора      |
//+-----------------------------------+                  
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
//+-----------------------------------+
//--- объявление динамических массивов, которые в дальнейшем
//--- будут использованы в качестве индикаторных буферов
double IndBuffer[];
//--- объявление целых переменных начала отсчёта данных
int  min_rates_total;
//+------------------------------------------------------------------+    
//| Williams_Accumulation_Distribution indicator initialization      |
//+------------------------------------------------------------------+  
void OnInit()
  {
//--- инициализация переменных начала отсчёта данных
   min_rates_total=2;
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"Williams_Accumulation_Distribution");
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| Williams_Accumulation_Distribution iteration function            |
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчёта индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчёта индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);
//--- объявление локальных переменных
   int first,bar;
   double TRH,TRL,AD;
//---
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      first=min_rates_total; // стартовый номер для расчёта всех баров
      IndBuffer[first-1]=close[first-1];
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров
//--- основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      TRH=MathMax(high[bar],close[bar-1]);
      TRL=MathMin(low[bar],close[bar-1]);
      if(close[bar]>close[bar-1]+_Point) AD=close[bar]-TRL;
      else if(close[bar]<close[bar-1]-_Point) AD=close[bar]-TRH;
      else AD=0;      
      IndBuffer[bar]=IndBuffer[bar-1]+AD;
     }
//---+    
   return(rates_total);
  }
//+------------------------------------------------------------------+
