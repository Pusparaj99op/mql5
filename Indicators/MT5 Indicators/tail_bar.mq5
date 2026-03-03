//+------------------------------------------------------------------+
//|                                                     Tail_Bar.mq5 | 
//|                                   Copyright © 2014, Inkov Evgeni | 
//|                                                    ew123@mail.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2014, Inkov Evgeni"
#property link "ew123@mail.ru"
//--- номер версии индикатора
#property version   "1.00"
//--- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//--- количество индикаторных буферов
#property indicator_buffers 2 
//--- использовано всего одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//| Параметры отрисовки индикатора    |
//+-----------------------------------+
//--- отрисовка индикатора в виде гистограммы
#property indicator_type1   DRAW_COLOR_HISTOGRAM
//--- в качестве цветов гистограммы использованы
#property indicator_color1  clrTeal,clrMagenta
//--- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//--- толщина линии индикатора равна 3
#property indicator_width1  3
//--- отображение метки индикатора
#property indicator_label1  "Tail_Bar"
//+-----------------------------------+
//| Входные параметры индикатора      |
//+-----------------------------------+
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
//+-----------------------------------+
//--- объявление динамических массивов, которые в дальнейшем
//--- будут использованы в качестве индикаторных буферов
double IndBuffer[],ColorIndBuffer[];
//--- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//--- инициализация переменных начала отсчета данных
   min_rates_total=2;
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"Tail_Bar");
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- завершение инициализации
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total) return(0);
//--- объявление переменных с плавающей точкой  
   double Val0;
   static double Val1;
//--- объявление целочисленных переменных и получение уже подсчитанных баров
   int first,bar;
//--- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      first=min_rates_total-1; // стартовый номер для расчета всех баров
      bar=first-1;
      Val1=((high[bar]-MathMax(close[bar],open[bar]))-(MathMin(close[bar],open[bar])-low[bar]))/_Point;
     }
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//--- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      Val0=((high[bar]-MathMax(close[bar],open[bar]))-(MathMin(close[bar],open[bar])-low[bar]))/_Point;
      IndBuffer[bar]=Val0;
      if(Val1<Val0) ColorIndBuffer[bar]=0;
      else ColorIndBuffer[bar]=1;      
      if(bar<rates_total-1) Val1=Val0;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
