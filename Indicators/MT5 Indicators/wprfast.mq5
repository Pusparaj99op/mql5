//+------------------------------------------------------------------+
//|                                                      WPRfast.mq5 | 
//|                                         Copyright © 2007, OlegVS | 
//|                                                                  | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2007, OlegVS"
#property link ""
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов
#property indicator_buffers 2 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//--- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//--- фиксированная высота подокна индикатора в пикселях 
#property indicator_height 20
//--- нижняя и верхняя границы шкалы отдельного окна индикатора
#property indicator_maximum +1.9
#property indicator_minimum +0.3
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в виде многоцветных значков
#property indicator_type1   DRAW_COLOR_ARROW
//---- в качестве цветов использованы
#property indicator_color1  clrDodgerBlue,clrMagenta
//---- толщина индикатора равна 4
#property indicator_width1  4
//---- отображение метки индикатора
#property indicator_label1  "WPRfast"
//+----------------------------------------------+
//| Параметры отображения горизонтальных уровней |
//+----------------------------------------------+
#property indicator_level1 1.0
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET 0    // Константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА                |
//+----------------------------------------------+
input uint iPeriod=9; // Период индикатора
input uint Max=49;    // Верхний уровень срабатывания 
input uint Min=9;     // Нижний уровень срабатывания 
input int Shift=0;    // Сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+

//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[];
double ColorIndBuffer[];
//--- объявление целочисленных переменных для хендлов индикаторов
int Ind_Handle;
//---- Объявление целых переменных начала отсчета данных
int min_rates_total;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//---- Инициализация переменных начала отсчета данных
   min_rates_total=int(iPeriod);

//--- получение хендла индикатора WPR
   Ind_Handle=iWPR(Symbol(),PERIOD_CURRENT,iPeriod);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора WPR");
      return(INIT_FAILED);
     }

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(IndBuffer,true);

//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ColorIndBuffer,true);

//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"WPRfast");

//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
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
   if(rates_total<min_rates_total || BarsCalculated(Ind_Handle)<rates_total) return(rates_total);

//---- объявления локальных переменных 
   int to_copy,limit,bar;
   double V1,V2,WPR[];

//---- расчет стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчета всех баров
     }
   else limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров

   to_copy=limit+1;

//---- индексация элементов в массивах, как в таймсериях  
   ArraySetAsSeries(WPR,true);

//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(Ind_Handle,0,0,to_copy,WPR)<=0) return(RESET);

//---- Основной цикл расчета индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      IndBuffer[bar]=0.0;
      ColorIndBuffer[bar]=0;
      V1=WPR[bar]*WPR[bar]/100;
      V2=MathCeil(V1);
      if(V2<Min)
        {
         IndBuffer[bar]=1.0;
         ColorIndBuffer[bar]=0;
        }
      if(V2>Max)
        {
         IndBuffer[bar]=1.0;
         ColorIndBuffer[bar]=1;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
