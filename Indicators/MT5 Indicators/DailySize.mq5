//+------------------------------------------------------------------+
//|                                                    DailySize.mq5 |
//|                                                         Tapochun |
//|                         https://login.mql5.com/ru/users/tapochun |
//+------------------------------------------------------------------+
#property copyright "Tapochun"
#property link      "https://login.mql5.com/ru/users/tapochun"
#property version   "1.00"
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_plots 1
#property indicator_buffers 1
//---
#property indicator_type1 DRAW_HISTOGRAM
#property indicator_color1 clrRed
#property indicator_label1 "DailySize"
//+------------------------------------------------------------------+
//| Глобальные переменные															|
//+------------------------------------------------------------------+
double bufRange[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Выполняем проверку допустимого ТФ
   bool answer=CheckTimeframe();
   if( !answer ) return( INIT_PARAMETERS_INCORRECT );
//--- Присваиваем индекс индикаторному буферу
   SetIndexBuffer(0,bufRange);
//--- Устанавливаем точность значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- Устанавливаем начальные значения индикаторного буфера
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---
   return( INIT_SUCCEEDED );
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
//--- Если нет просчитанных данных - выходим
   if( rates_total <= 0 ) return( 0 );
//---
   static int dNum;             // Номер проверяемого дня
   static double dHigh = 0.0;   // Максимум проверяемого дня
   static double dLow = DBL_MAX;// Минимум проверяемого дня
//---
   if(prev_calculated!=0) // Если не первый расчет
     {
      //--- Рассчитываем индикатор на первой свече
      Calculation(rates_total-1,dNum,dHigh,dLow,rates_total,time,high,low);
     }
   else                   // Если первый расчет индикатора
     {
      //--- Инициализируем индикаторный буфер начальными значениями
      ArrayInitialize(bufRange,0.0);
      //--- Определяем номер бара первого полностью доступного дня
      int firstBar = GetFirstBar( time, rates_total, dNum );
      if( firstBar == 0 ) return( 0 );
      //--- Рассчитываем индикатор с бара firstBar
      Calculation(firstBar,dNum,dHigh,dLow,rates_total,time,high,low);
     }
//---
   return( rates_total );
  }
//+------------------------------------------------------------------+
//| Проверка допустимости размера ТФ											|
//+------------------------------------------------------------------+
bool CheckTimeframe()
  {
   if(_Period>PERIOD_D1) // Если текущий ТФ больше Д1
     {
      Print(__FUNCTION__,": Индикатор предназначен для запуска на ТФ до D1. Уменьшите ТФ!");
      return(false);     // Выходим с ошибкой
     }
   else return(true);    // Если допустимый ТФ - возвращаем истину
  }
//+------------------------------------------------------------------+
//| Получаем номер первого бара полностью доступного дня					|
//+------------------------------------------------------------------+
int GetFirstBar(const datetime &time[], // Массив времен открытия баров по текущему ТФ
                const int rates_total,  // Количество просчитанных баров
                int &dayNum)            // Номер проверяемого дня (out)
  {
   int prev = GetDayNumber(time[ 0 ] ); // Номер дня на предыдущем баре
   int curr;                            // Номер дня на текущем баре
   for(int i=1; i<rates_total; i++)     // Цикл по просчитанных барам
     {
      curr=GetDayNumber(time[i]);       // Определяем номер дня на текущем баре
      if(curr==prev) continue;          // Если номера совпадаюют - переходим к след. бару
      else                              // Если номера не совпадают
        {
         dayNum = curr;                 // Запоминаем номер первого проверяемого дня
         return(i );                    // Возвращаем номер бара первого полного дня
        }
     }
//---
   Print(__FUNCTION__,": Ожидаем больше данных..");
   return(0);                           // Возвращаем 0
  }
//+------------------------------------------------------------------+
//| Определяем номер дня по времени	бара										|
//+------------------------------------------------------------------+
int GetDayNumber(const datetime time) // Время бара
  {
   MqlDateTime tStr;                  // Структура времени
   TimeToStruct( time,tStr );         // Время в структуру
   return(tStr.day);                  // Возвращаем номер текущего дня
  }
//+------------------------------------------------------------------+
//| Функция расчета индикатора													|
//+------------------------------------------------------------------+
void Calculation(const int firstBar,     // Номер первого бара для расчета
                 int &dNum,              // Номер проверяемого дня (out)
                 double &dHigh,          // Максимум проверяемого дня (out)
                 double &dLow,           // Минимум проверяемого дня (out)
                 const int rates_total,  // Количество просчитанных баров
                 const datetime &time[], // Массив времен открытия просчитанных баров
                 const double &high[],   // Массив максимумов просчитанных баров
                 const double &low[]     // Массив минимумов просчитанных баров
                 )
  {
   int iNum;                                 // Номер дня на i баре
   for(int i = firstBar; i<rates_total; i++) // Цикл сформированным барам
     {
      iNum = GetDayNumber( time[ i ] );      // Получаем номер дня на i баре
      if( dNum != iNum )                     // Если считается новый день
        {
         //--- Сбрасываем параметры дня
         dNum = iNum;                        // Запоминаем новый номер проверяемого дня
         dHigh = high[ i ];                  // Запоминаем максимум i свечи
         dLow= low[ i ];                     // Запоминаем минимум i свечи
        }
      else                                   // Если считается текущий день
        {
         //--- Проверяем образование нового минимума/максимума дня
         if(high[i]>dHigh)                   // Если максимум на i свече больше сохраненного
            dHigh=high[i];                   // Запоминаем новое значение максимума текущего дня
         //---
         if(low[i]<dLow)                     // Если минимум на i свече меньше сохраненного
            dLow=low[i];                     // Запоминаем новое значение минимума текущего дня
        }
      //--- Рассчитываем значение индикатора - разность максимума и минимума текущего дня
      bufRange[i]=MathRound(( dHigh-dLow)/_Point);
     }
  }
//+------------------------------------------------------------------+
