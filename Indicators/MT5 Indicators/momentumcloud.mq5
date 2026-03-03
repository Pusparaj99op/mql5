//+------------------------------------------------------------------+
//|                                                MomentumCloud.mq5 |
//|                               Copyright © 2015, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2015, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window 
//---- количество индикаторных буферов 2
#property indicator_buffers 2 
//---- использовано одно графическое построение
#property indicator_plots   1
//+----------------------------------------------+
//| Параметры отрисовки индикатора               |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цветов индикатора использованы
#property indicator_color1  clrMediumAquamarine,clrHotPink
//---- отображение метки индикатора
#property indicator_label1  "MomentumCloud"
//+----------------------------------------------+
//| Объявление констант                          |
//+----------------------------------------------+
#define RESET 0 // константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint MomentumPeriod=14;           // Период Momentum индикатора
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double ExtABuffer[],ExtBBuffer[];
//---- объявление целочисленных переменных для хранения хендлов индикаторов
int IndA_Handle,IndB_Handle;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_total=int(MomentumPeriod);
//--- получение хендла индикатора iMomentum HIGH
   IndA_Handle=iMomentum(Symbol(),PERIOD_CURRENT,MomentumPeriod,PRICE_HIGH);
   if(IndA_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMomentum HIGH");
      return(INIT_FAILED);
     }
//--- получение хендла индикатора iMomentum LOW
   IndB_Handle=iMomentum(Symbol(),PERIOD_CURRENT,MomentumPeriod,PRICE_LOW);
   if(IndB_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMomentum LOW");
      return(INIT_FAILED);
     }
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,ExtABuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ExtABuffer,true);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,ExtBBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ExtBBuffer,true);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"MomentumCloud");
//--- определение точности отображения значений индикатора
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
//---- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total
      || BarsCalculated(IndA_Handle)<rates_total
      || BarsCalculated(IndB_Handle)<rates_total) return(RESET);
//---- объявления локальных переменных 
   int to_copy;
//---- расчеты необходимого количества копируемых данных
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      to_copy=rates_total; // стартовый номер для расчета всех баров
     }
   else to_copy=rates_total-prev_calculated+1; // стартовый номер для расчета новых баров
//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(IndA_Handle,0,0,to_copy,ExtABuffer)<=0) return(RESET);
   if(CopyBuffer(IndB_Handle,0,0,to_copy,ExtBBuffer)<=0) return(RESET);
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
