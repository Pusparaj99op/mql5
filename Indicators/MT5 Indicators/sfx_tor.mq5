//+------------------------------------------------------------------+
//|                                                      SFX_TOR.mq5 |
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
//--- для расчета и отрисовки индикатора использовано три буфера
#property indicator_buffers 3
//--- использовано три графических построения
#property indicator_plots   3
//+----------------------------------------------+
//| Параметры отрисовки бычьго индикатора        |
//+----------------------------------------------+
//--- отрисовка индикатора 1 в виде линии
#property indicator_type1   DRAW_LINE
//--- в качестве цвета бычей линии индикатора использован зеленый цвет
#property indicator_color1  clrLimeGreen
//--- линия индикатора 1 - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//--- толщина линии индикатора 1 равна 1
#property indicator_width1  1
//--- отображение бычей метки индикатора
#property indicator_label1  "ATR"
//+----------------------------------------------+
//| Параметры отрисовки медвежьего индикатора    |
//+----------------------------------------------+
//--- отрисовка индикатора 2 в виде линии
#property indicator_type2   DRAW_LINE
//--- в качестве цвета медвежьей линии индикатора использован розовый цвет
#property indicator_color2  clrMagenta
//--- линия индикатора 2 - непрерывная кривая
#property indicator_style2  STYLE_SOLID
//--- толщина линии индикатора 2 равна 1
#property indicator_width2  1
//--- отображение медвежьей метки индикатора
#property indicator_label2  "StdDev"
//+----------------------------------------------+
//| Параметры отрисовки StdDev MA индикатора     |
//+----------------------------------------------+
//--- отрисовка индикатора 3 в виде линии
#property indicator_type3   DRAW_LINE
//--- в качестве цвета MA линии индикатора использован синий цвет
#property indicator_color3  clrDodgerBlue
//--- линия индикатора 3 - непрерывная кривая
#property indicator_style3  STYLE_SOLID
//--- толщина линии индикатора 3 равна 1
#property indicator_width3  1
//--- отображение медвежьей метки индикатора
#property indicator_label3  "StdDev MA"
//+-----------------------------------------------+
//| объявление констант                           |
//+-----------------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint   ATR_period=12;
input uint   Std_period=12;
input  ENUM_MA_METHOD   Std_method=MODE_EMA;
input ENUM_APPLIED_PRICE   Std_price=PRICE_CLOSE;
input int   MAPeriod=3;
input  ENUM_MA_METHOD   MAType=MODE_SMMA;
//+----------------------------------------------+
//--- объявление динамических массивов, которые в дальнейшем
//--- будут использованы в качестве индикаторных буферов
double ATRBuffer[];
double StdBuffer[];
double MABuffer[];
//--- объявление целочисленных переменных для хендлов индикаторов
int ATR_Handle,Std_Handle,MA_Handle;
//--- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- получение хендла индикатора ATR
   ATR_Handle=iATR(NULL,PERIOD_CURRENT,ATR_period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора ATR");
      return(INIT_FAILED);
     }
//--- получение хендла индикатора iStdDev
   Std_Handle=iStdDev(NULL,0,Std_period,0,Std_method,Std_price);
   if(Std_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iStdDev");
      return(INIT_FAILED);
     }
//--- получение хендла индикатора iMA
   MA_Handle=iMA(NULL,0,MAPeriod,0,MAType,Std_Handle);
   if(MA_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMA");
      return(INIT_FAILED);
     }
//--- инициализация переменных начала отсчета данных
   min_rates_total=int(MathMax(ATR_period,Std_period+MAPeriod));
//--- превращение динамического массива ATRBuffer в индикаторный буфер
   SetIndexBuffer(0,ATRBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 1 на min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- индексация элементов в буферах как в таймсериях   
   ArraySetAsSeries(ATRBuffer,true);
//--- превращение динамического массива StdBuffer в индикаторный буфер
   SetIndexBuffer(1,StdBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 2 на min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- индексация элементов в буферах как в таймсериях   
   ArraySetAsSeries(StdBuffer,true);
//--- превращение динамического массива StdBuffer в индикаторный буфер
   SetIndexBuffer(2,MABuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 3 на min_rates_total
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- индексация элементов в буферах как в таймсериях   
   ArraySetAsSeries(MABuffer,true);
//--- инициализации переменной для короткого имени индикатора
   string shortname="SFX_TOR";
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
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
                const double& high[],     // ценовой массив максимумов цены для расчета индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчета индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- проверка количества баров на достаточность для расчета
   if(BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(Std_Handle)<rates_total
      || BarsCalculated(MA_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);
//--- объявления локальных переменных 
   int to_copy;
//--- расчет количества копируемых данных
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      to_copy=rates_total;
     }
   else to_copy=rates_total-prev_calculated+1; // стартовый номер для расчета новых баров
//--- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATRBuffer)<=0) return(RESET);
   if(CopyBuffer(Std_Handle,0,0,to_copy,StdBuffer)<=0) return(RESET);
   if(CopyBuffer(MA_Handle,0,0,to_copy,MABuffer)<=0) return(RESET);
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
