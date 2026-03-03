//+------------------------------------------------------------------+
//|                                             CorrectedAverage.mq5 |
//|                            Copyright © 2006, Alexander Piechotta |
//|                                     http://onix-trade.net/forum/ |
//+------------------------------------------------------------------+
//---- авторство индикатора
#property copyright "Copyright © 2006, Alexander Piechotta"
//---- авторство индикатора
#property link      "http://onix-trade.net/forum/"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов
#property indicator_buffers 1 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//| Параметры отрисовки индикатора    |
//+-----------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета бычьей линии индикатора использован clrMediumSlateBlue цвет
#property indicator_color1 clrMediumSlateBlue
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение метки индикатора
#property indicator_label1  "CorrectedAverage"
//+-----------------------------------+
//| Объявление констант               |
//+-----------------------------------+
#define RESET 0 // константа для возврата терминалу команды на пересчет индикатора
//+-----------------------------------+
//| Входные параметры индикатора      |
//+-----------------------------------+
input ENUM_MA_METHOD MA_Method=MODE_SMA; // Метод усреднения
input uint Length=12; // Глубина сглаживания
input ENUM_APPLIED_PRICE Applied_price=PRICE_CLOSE; // Ценовая константа                
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
input int PriceShift=0; // Сдвиг индикатора по вертикали в пунктах
//+-----------------------------------+
//---- индикаторный буфер
double MABuffer[];
double dPriceShift;
//---- объявление глобальных переменных
int min_rates_total;
//---- объявление целочисленных переменных для хендлов индикаторов
int MA_Handle,STD_Handle;
//+------------------------------------------------------------------+    
//| MA indicator initialization function                             | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   switch(int(MA_Method))
     {
      case MODE_SMA: min_rates_total=int(Length); break;
      case MODE_EMA: min_rates_total=2; break;
      case MODE_SMMA: min_rates_total=int(Length)+1; break;
      case MODE_LWMA: min_rates_total=int(Length)+1; break;
     }
   min_rates_total++;
//---- получение хендла индикатора iStdDev
   STD_Handle=iStdDev(NULL,PERIOD_CURRENT,Length,0,MA_Method,Applied_price);
   if(STD_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iStdDev");
      return(1);
     }
//---- получение хендла индикатора iMA
   MA_Handle=iMA(NULL,PERIOD_CURRENT,Length,0,MA_Method,Applied_price);
   if(MA_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMA");
      return(1);
     }
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,MABuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(MABuffer,true);
//---- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- инициализация переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"CorrectedAverage( Length = ",Length,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
//---- завершение инициализации
   return(0);
  }
//+------------------------------------------------------------------+  
//| MA iteration function                                            | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const int begin,          // номер начала достоверного отсчета баров
                const double &price[]) // ценовой массив для расчета индикатора
  {
//---- проверка количества баров на достаточность для расчета
   if(BarsCalculated(STD_Handle)<rates_total
      || BarsCalculated(MA_Handle)<rates_total
      || rates_total<min_rates_total+begin) return(RESET);
//---- объявления локальных переменных 
   int limit,bar,to_copy;
   double v1,v2,k,MA[],STD[];
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(MA,true);
   ArraySetAsSeries(STD,true);
//---- расчеты необходимого количества копируемых данных и
//---- стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчета всех баров
      to_copy=limit+2;
      //---- осуществление сдвига начала отсчета отрисовки индикатора
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total+begin);
      for(bar=limit; bar>=0 && !IsStopped(); bar--) MABuffer[bar]=EMPTY_VALUE;
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
      to_copy=limit+1;
     }
//---- копируем вновь появившиеся данные в массивы STD[] и ATR[]
   if(CopyBuffer(MA_Handle,0,0,to_copy,MA)<=0) return(RESET);
   if(CopyBuffer(STD_Handle,0,0,to_copy,STD)<=0) return(RESET);
//----
   if(prev_calculated>rates_total || prev_calculated<=0) MABuffer[limit+1]=MA[limit+1];
//---- основной цикл расчета индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      v1=MathPow(STD[bar],2);
      v2=MathPow(MABuffer[bar+1]-MA[bar],2);
      //----
      if(v2<v1 || !v2) k=0.0;
      else k=1-v1/v2;
      //----
      MABuffer[bar]=MABuffer[bar+1]+k*(MA[bar]-MABuffer[bar+1]);
      MABuffer[bar]+=dPriceShift;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
