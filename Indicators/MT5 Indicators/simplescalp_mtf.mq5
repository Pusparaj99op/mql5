//+------------------------------------------------------------------+
//|                                              SimpleScalp_MTF.mq5 |
//|                      Copyright © 2011, MetaQuotes Software Corp. |
//|                             http://www.mql4.com/ru/users/kontra  |
//------------------------------------------------------------------+
#property copyright "Copyright © 2011, MetaQuotes Software Corp."
#property link "http://www.mql4.com/ru/users/kontra"
#property description "Индикатор направленного тренда"
//--- номер версии индикатора
#property version   "1.00"
//--- отрисовка индикатора в главном окне
#property indicator_chart_window 
//--- для расчета и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//--- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//| Параметры отрисовки медвежьего индикатора    |
//+----------------------------------------------+
//--- отрисовка индикатора 1 в виде символа
#property indicator_type1   DRAW_ARROW
//--- в качестве цвета медвежьей линии индикатора использован Tomato цвет
#property indicator_color1  clrTomato
//--- толщина линии индикатора 1 равна 4
#property indicator_width1  4
//--- отображение бычьей метки индикатора
#property indicator_label1  "SimpleScalp_MTF Sell"
//+----------------------------------------------+
//| Параметры отрисовки бычьего индикатора       |
//+----------------------------------------------+
//--- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//--- в качестве цвета бычьей линии индикатора использован Lime цвет
#property indicator_color2  clrLime
//--- толщина линии индикатора 2 равна 4
#property indicator_width2  4
//--- отображение медвежьей метки индикатора
#property indicator_label2 "SimpleScalp_MTF Buy"
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчёт индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input ENUM_TIMEFRAMES TimeFrame1=PERIOD_H1;  // Период графика 1
input ENUM_TIMEFRAMES TimeFrame2=PERIOD_M30; // Период графика 2
input ENUM_TIMEFRAMES TimeFrame3=PERIOD_M15; // Период графика 3
//+----------------------------------------------+

//--- объявление динамических массивов, которые будут
//--- в дальнейшем использованы в качестве индикаторных буферов
double SellBuffer[];
double BuyBuffer[];
//--- объявление целочисленных переменных начала отсчета данных
int min_rates_total,ATR_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- инициализация глобальных переменных 
   int ATR_Period=15;
   min_rates_total=int(2);
//--- получение хендла индикатора ATR
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора ATR");
      return(INIT_FAILED);
     }
//--- проверка таймфреймов 
   if(TimeFrame1<=Period()) Alert("Период графика 1 должен быть больше периода текущего графика!");
   if(TimeFrame2<=Period()) Alert("Период графика 2 должен быть больше периода текущего графика!");
   if(TimeFrame3<=Period()) Alert("Период графика 3 должен быть больше периода текущего графика!");

//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,178);
//--- индексация элементов в буфере, как в таймсерии
   ArraySetAsSeries(SellBuffer,true);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,178);
//--- индексация элементов в буфере, как в таймсерии
   ArraySetAsSeries(BuyBuffer,true);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);

//--- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- имя для окон данных и метка для подокон 
   string short_name="SimpleScalp_MTF";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
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
   if(Bars(Symbol(),TimeFrame1)<min_rates_total
      || Bars(Symbol(),TimeFrame2)<min_rates_total
      || Bars(Symbol(),TimeFrame3)<min_rates_total
      || BarsCalculated(ATR_Handle)<rates_total
      || rates_total<min_rates_total)
      return(RESET);
//--- объявления локальных переменных 
   int limit,to_copy;
   double iClose1[],iClose2[],iClose3[];
   double iOpen1[],iOpen2[],iOpen3[],ATR[];
//--- расчёт стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
      limit=rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
   else limit=rates_total-prev_calculated;  // стартовый номер для расчёта только новых баров
   to_copy=limit+1;
//--- копируем вновь появившиеся данные в массивы и ATR[]
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
//--- индексация элементов в массивах, как в таймсериях  
   ArraySetAsSeries(iClose1,true);
   ArraySetAsSeries(iClose2,true);
   ArraySetAsSeries(iClose3,true);
   ArraySetAsSeries(iOpen1,true);
   ArraySetAsSeries(iOpen2,true);
   ArraySetAsSeries(iOpen3,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(ATR,true);
//--- основной цикл расчета индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;

      if(CopyClose(Symbol(),TimeFrame1,time[bar],min_rates_total,iClose1)<=0) return(RESET);
      if(CopyClose(Symbol(),TimeFrame2,time[bar],min_rates_total,iClose2)<=0) return(RESET);
      if(CopyClose(Symbol(),TimeFrame3,time[bar],min_rates_total,iClose3)<=0) return(RESET);
      if(CopyOpen(Symbol(),TimeFrame1,time[bar],min_rates_total,iOpen1)<=0) return(RESET);
      if(CopyOpen(Symbol(),TimeFrame2,time[bar],min_rates_total,iOpen2)<=0) return(RESET);
      if(CopyOpen(Symbol(),TimeFrame3,time[bar],min_rates_total,iOpen3)<=0) return(RESET);

      if(iClose1[1]-iOpen1[1]>0 && iClose2[1]-iOpen2[1]>0 && iClose3[1]-iOpen3[1]>0 && close[bar+1]-open[bar+1]>0) BuyBuffer[bar]=low[bar]-ATR[bar]*3/8;
      if(iClose1[1]-iOpen1[1]<0 && iClose2[1]-iOpen2[1]<0 && iClose3[1]-iOpen3[1]<0 && close[bar+1]-open[bar+1]<0) SellBuffer[bar]=high[bar]+ATR[bar]*3/8;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
