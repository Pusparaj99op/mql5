//+------------------------------------------------------------------+
//|                                                  iFXAnalyser.mq5 |
//|                           Copyright © 2006, Renato P. dos Santos |
//|                   inspired on 4xtraderCY's and SchaunRSA's ideas |
//|   http://www.strategybuilderfx.com/forums/showthread.php?t=16086 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Renato P. dos Santos"
#property link "http://www.strategybuilderfx.com/forums/showthread.php?t=16086"
//---- номер версии индикатора
#property version   "1.00"
//---- описание индикатора
#property description ""
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window  
//---- для расчета и отрисовки индикатора использовано три буфера
#property indicator_buffers 3
//---- использовано три графических построения
#property indicator_plots   3
//+----------------------------------------------+
//| Параметры отрисовки верхней линии 1          |
//+----------------------------------------------+
//---- отрисовка индикатора 1 в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета линии индикатора использован синий цвет
#property indicator_color1  clrBlue
//---- линия индикатора 1 - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора 1 равна 1
#property indicator_width1  1
//---- отображение метки индикатора
#property indicator_label1  "Div"
//+----------------------------------------------+
//| Параметры отрисовки линии 2                  |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета линии индикатора использован красный цвет
#property indicator_color2  clrRed
//---- линия индикатора 2 - непрерывная кривая
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора 2 равна 1
#property indicator_width2  1
//---- отображение метки индикатора
#property indicator_label2  "Slope"
//+----------------------------------------------+
//| Параметры отрисовки линии 3                  |
//+----------------------------------------------+
//---- отрисовка индикатора 3 в виде линии
#property indicator_type3   DRAW_LINE
//---- в качестве цвета линии индикатора использован зеленый цвет
#property indicator_color3  clrGreen
//---- линия индикатора 3 - непрерывная кривая
#property indicator_style3  STYLE_SOLID
//---- толщина линии индикатора 3 равна 1
#property indicator_width3  1
//---- отображение метки индикатора
#property indicator_label3  "Acel"
//+----------------------------------------------+
//| Объявление констант                          |
//+----------------------------------------------+
#define RESET 0 // константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint                FastMAPeriod=4;
input  ENUM_MA_METHOD     FastMAType=MODE_SMA;
input ENUM_APPLIED_PRICE  FastMAPrice=PRICE_CLOSE;
input uint                SlowMAPeriod=6;
input  ENUM_MA_METHOD     SlowMAType=MODE_SMA;
input ENUM_APPLIED_PRICE  SlowMAPrice=PRICE_CLOSE;
input int    Shift=0; // Сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double Ind1Buffer[];
double Ind2Buffer[];
double Ind3Buffer[];
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//---- объявление целочисленных переменных для хендлов индикаторов
int FsMA_Handle,SlMA_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_total=int(MathMax(FastMAPeriod,SlowMAPeriod)+3);
//---- получение хендла индикатора Fast iMA
   FsMA_Handle=iMA(_Symbol,PERIOD_CURRENT,FastMAPeriod,0,FastMAType,FastMAPrice);
   if(FsMA_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора Fast iMA");
      return(INIT_FAILED);
     }
//---- получение хендла индикатора Slow iMA
   SlMA_Handle=iMA(_Symbol,PERIOD_CURRENT,SlowMAPeriod,0,SlowMAType,SlowMAPrice);
   if(SlMA_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора Slow iMA");
      return(INIT_FAILED);
     }
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,Ind1Buffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 1 на min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(Ind1Buffer,true);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,Ind2Buffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 2 по горизонтали на Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 2 на min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(Ind2Buffer,true);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,Ind3Buffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 3 по горизонтали на Shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 3 на min_rates_total
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(Ind3Buffer,true);
//---- инициализация переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"i-iFXAnalyser(",FastMAPeriod,",",SlowMAPeriod,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчета индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчета индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(BarsCalculated(FsMA_Handle)<rates_total
      || BarsCalculated(SlMA_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);
//---- объявление локальных переменных 
   int to_copy,limit,bar;
   double FsMA[],SlMA[];
//---- расчеты необходимого количества копируемых данных и
//---- стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-1-min_rates_total; // стартовый номер для расчета всех баров
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
     }
   to_copy=limit+3;
//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(FsMA_Handle,0,0,to_copy,FsMA)<=0) return(RESET);
   if(CopyBuffer(SlMA_Handle,0,0,to_copy,SlMA)<=0) return(RESET);
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(FsMA,true);
   ArraySetAsSeries(SlMA,true);
//---- основной цикл расчета индикатора
   for(bar=0; bar<limit && !IsStopped(); bar++)
     {
      Ind1Buffer[bar]=FsMA[bar]-SlMA[bar];
      double diff=FsMA[bar+1]-SlMA[bar+1];
      Ind2Buffer[bar]=Ind1Buffer[bar]-diff;
      Ind3Buffer[bar]=Ind2Buffer[bar]-diff-(FsMA[bar+2]-SlMA[bar+2]);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
