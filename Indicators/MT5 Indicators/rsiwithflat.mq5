//+------------------------------------------------------------------+
//|                                                  RSIWithFlat.mq5 |
//|                                 Copyright © 2014, Powered byStep | 
//|                                                                  | 
//+------------------------------------------------------------------+
#property description "Money Flow Index With Flat"
//---- авторство индикатора
#property copyright "Copyright © 2014, Powered byStep"
//---- авторство индикатора
#property link      ""
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- для расчёта и отрисовки индикатора использовано три буфера
#property indicator_buffers 3
//---- использовано два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//|  Параметры отрисовки индикатора 1            |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//--- в качестве цветов индикатора использованы
#property indicator_color1  clrSeaGreen,clrHotPink
//---- отображение бычей метки индикатора
#property indicator_label1  "RSI Oscillator"
//+----------------------------------------------+
//|  Параметры отрисовки индикатора 2            |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета медвежьей линии индикатора использован синий цвет
#property indicator_color2  clrBlue
//---- линия индикатора 2 - непрерывная кривая
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора 2 равна 5
#property indicator_width2  5
//---- отображение медвежьей метки индикатора
#property indicator_label2  "Flat"
//+----------------------------------------------+
//| Параметры отображения горизонтальных уровней |
//+----------------------------------------------+
#property indicator_level1 70.0
#property indicator_level2 50.0
#property indicator_level3 30.0
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET 0 // константа для возврата терминалу команды на пересчёт индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint                BBPeriod=20;                 // Период для расчета Боллинджера
input double              StdDeviation=2.0;            // Девиация Боллинджера
input ENUM_APPLIED_PRICE  applied_price=PRICE_CLOSE;   // Тип цены Боллинджера
input uint                RSIPeriod=14;                // Период RSI
input ENUM_APPLIED_PRICE  RSIPrice=PRICE_CLOSE;        // Цена RSI
input uint                MAPeriod=13;                 // Период усреднения сигнальной линии
input  ENUM_MA_METHOD     MAType=MODE_SMA;             // Тип усреднения сигнальной линии
input uint                flat=100;                    // величина флэта в пунктах
input int                 Shift=0;                     // сдвиг индикатора по горизонтали в барах 
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[];
double SignalBuffer[];
double IndBuffer1[];
//---- Объявление целых переменных для хендлов индикаторов
int BB_Handle,RSI_Handle,MA_Handle;
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=int(MathMax(BBPeriod,RSIPeriod));

//---- получение хендла индикатора iBands
   BB_Handle=iBands(Symbol(),PERIOD_CURRENT,BBPeriod,0,StdDeviation,applied_price);
   if(BB_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iBands");
      return(INIT_FAILED);
     }
//---- получение хендла индикатора iRSI
   RSI_Handle=iRSI(Symbol(),PERIOD_CURRENT,RSIPeriod,RSIPrice);
   if(RSI_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iRSI");
      return(INIT_FAILED);
     }
//---- получение хендла индикатора iMA
   MA_Handle=iMA(Symbol(),PERIOD_CURRENT,MAPeriod,0,MAType,RSI_Handle);
   if(MA_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iMA");
      return(INIT_FAILED);
     }

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(IndBuffer,true);
//---- осуществление сдвига индикатора 1 по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,SignalBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(SignalBuffer,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,IndBuffer1,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(IndBuffer1,true);
//---- осуществление сдвига индикатора 1 по горизонтали на Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   IndicatorSetString(INDICATOR_SHORTNAME,"RSIWithFlat");
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчёта индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчёта индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(BarsCalculated(BB_Handle)<rates_total
      || BarsCalculated(RSI_Handle)<rates_total
      || BarsCalculated(MA_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);

//---- объявления локальных переменных 
   int to_copy,limit,bar;
   double MainRSI[],SignRSI[],UpBB[],MainBB[];

//---- расчёты необходимого количества копируемых данных и стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
     }
   else limit=rates_total-prev_calculated; // стартовый номер для расчёта новых баров
   to_copy=limit+1;

//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(BB_Handle,UPPER_BAND,0,to_copy,UpBB)<=0) return(RESET);
   if(CopyBuffer(BB_Handle,BASE_LINE,0,to_copy,MainBB)<=0) return(RESET);
   if(CopyBuffer(RSI_Handle,MAIN_LINE,0,to_copy,MainRSI)<=0) return(RESET);
   if(CopyBuffer(MA_Handle,MAIN_LINE,0,to_copy,SignRSI)<=0) return(RESET);

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(UpBB,true);
   ArraySetAsSeries(MainBB,true);
   ArraySetAsSeries(MainRSI,true);
   ArraySetAsSeries(SignRSI,true);

//---- основной цикл расчёта индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      double res=(UpBB[bar]-MainBB[bar])/_Point;
      if(res<flat)
        {
         if(MainRSI[bar]>SignRSI[bar])
           {
            IndBuffer[bar]=50;
            SignalBuffer[bar]=50;
            IndBuffer1[bar]=50;
           }

         if(MainRSI[bar]<SignRSI[bar])
           {
            IndBuffer[bar]=50;
            SignalBuffer[bar]=50;
            IndBuffer1[bar]=50;
           }
        }
      else
        {
         IndBuffer1[bar]=EMPTY_VALUE;
         IndBuffer[bar]=MainRSI[bar];
         SignalBuffer[bar]=SignRSI[bar];
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
