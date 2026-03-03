//+------------------------------------------------------------------+
//|                                                  DynamicRS_C.mq5 |
//|                                 Copyright © 2007, Nick A. Zhilin |
//|                                                  rebus58@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, Nick A. Zhilin"
#property link "rebus58@mail.ru"
//--- номер версии индикатора
#property version   "1.00"
//--- отрисовка индикатора в главном окне
#property indicator_chart_window 
//--- количество индикаторных буферов
#property indicator_buffers 2 
//--- использовано всего одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//|  Параметры отрисовки индикатора   |
//+-----------------------------------+
//--- отрисовка индикатора в виде многоцветной линии
#property indicator_type1   DRAW_COLOR_LINE
//--- в качестве цветов трехцветной линии использованы
#property indicator_color1  clrMagenta,clrYellow,clrBlueViolet
//--- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//--- толщина линии индикатора равна 2
#property indicator_width1  2
//--- отображение метки индикатора
#property indicator_label1  "DynamicRS_C"
//+-----------------------------------+
//| Входные параметры индикатора      |
//+-----------------------------------+
input uint Length=5;     // Глубина  первого сглаживания
input int Shift=0;       // Сдвиг индикатора по горизонтали в барах
input int PriceShift=0;  // Сдвиг индикатора по вертикали в пунктах
//+-----------------------------------+
//--- объявление динамических массивов, которые будут в 
//--- дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[];
double ColorIndBuffer[];
//--- объявление переменной значения вертикального сдвига мувинга
double dPriceShift;
//--- объявление целых переменных начала отсчета данных
int min_rates_total;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//--- инициализация переменных начала отсчета данных
   min_rates_total=int(Length+1);
//--- инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//--- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   string shortname;
//--- инициализации переменной для короткого имени индикатора
   StringConcatenate(shortname,"DynamicRS_C(",Length,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
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
//--- объявление целочисленных переменных и получение уже подсчитанных баров
   int first,bar;
//--- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      first=min_rates_total-1; // стартовый номер для расчета всех баров
      IndBuffer[first-1]=close[first-1];
      ColorIndBuffer[first-1]=1;
     }
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//--- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      ColorIndBuffer[bar]=1;
      if(high[bar]<high[bar-1] && high[bar]<high[bar-Length] && high[bar]<IndBuffer[bar-1])
        {
         IndBuffer[bar]=high[bar]+PriceShift;
         if(ColorIndBuffer[bar-1]==2) ColorIndBuffer[bar]=1; else ColorIndBuffer[bar]=0;
        }
      else if(low[bar]>low[bar-1] && low[bar]>low[bar-Length] && low[bar]>IndBuffer[bar-1])
        {
         IndBuffer[bar]=low[bar]+PriceShift;
         if(ColorIndBuffer[bar-1]==0) ColorIndBuffer[bar]=1; else ColorIndBuffer[bar]=2;
        }
      else
        {
         IndBuffer[bar]=IndBuffer[bar-1];
         ColorIndBuffer[bar]=ColorIndBuffer[bar-1];
         if(ColorIndBuffer[bar]==1)
           {
            if(ColorIndBuffer[bar-2]==0) ColorIndBuffer[bar]=2;
            if(ColorIndBuffer[bar-2]==2) ColorIndBuffer[bar]=0;
           }
        }
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
