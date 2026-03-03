//+------------------------------------------------------------------+
//|                                                      Gaps_cb.mq5 |
//|                                                         Tapochun |
//|                         https://login.mql5.com/ru/users/tapochun |
//+------------------------------------------------------------------+
#property copyright "Tapochun"
#property link      "https://login.mql5.com/ru/users/tapochun"
#property version   "1.00"
#property indicator_separate_window
#property indicator_minimum 0
//---
#property indicator_plots 1
#property indicator_buffers 2
//---
#property indicator_type1 DRAW_COLOR_HISTOGRAM
#property indicator_color1 clrLime, clrRed, clrGray
//+------------------------------------------------------------------+
//| Глобальные переменные															|
//+------------------------------------------------------------------+
double bufValue[];            // Буфер значений гэпов
double bufValueClr[];         // Буфер цвета гэпов
//+------------------------------------------------------------------+
//| Входные параметры																|
//+------------------------------------------------------------------+
input int inpBigGap=0;      // Размер большого гэпа (подсвечивается)
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Устанавливаем индексы массивов
   SetIndexBuffer(0,bufValue);
   SetIndexBuffer(1,bufValueClr,INDICATOR_COLOR_INDEX);
//--- Устанавливаем точность значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- Устанавливаем пустое значение для графической серии
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
   if(inpBigGap>0) // Если размер гэпа положительный
     {
      //--- Устанавливаем в подокно уровень минимального гэпа
      IndicatorSetInteger(INDICATOR_LEVELS,1);
      IndicatorSetDouble(INDICATOR_LEVELVALUE,0,inpBigGap);
      IndicatorSetString(INDICATOR_LEVELTEXT,0,"Big Gap");
     }
//--- Имя в подокне/окне данных
   IndicatorSetString(INDICATOR_SHORTNAME,"Gap");
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
//--- Если нет данных - выходим
   if( rates_total <= 0 ) return( 0 );

   if(prev_calculated!=0) // Если не первый расчет
     {
      if(rates_total>prev_calculated) // Если образовался новый бар
        {
         //--- Расчет гэпа на открытии текущего бара
         Calculation(rates_total-1,rates_total,inpBigGap,open,close);
        }
     }
   else                   // Если первый расчет
     {
      //--- Расчет гэпов на истории
      Calculation(1,rates_total,inpBigGap,open,close);
     }
//---
   return( rates_total );
  }
//+------------------------------------------------------------------+
//| Функция расчета																	|
//+------------------------------------------------------------------+
void Calculation(const int first,       // Первый бар для расчета
                 const int rates_total, // Количество просчитанных баров на текущем тике
                 const int bigGap,      // Размер большого гэпа
                 const double &open[],  // Массив цен открытия баров
                 const double &close[]  // Массив цен закрытия баров
                 )
  {
   int gap;                                 // Размер гэпа
   for( int i = 1; i < rates_total; i++ )   // Цикл по доступной истории
     {
      gap=int(MathRound(MathAbs(( open[i]-close[i-1])/_Point)));   // Размер гэпа, п
      bufValue[i]=gap;                  // Заносим значение в буфер
      if(gap>=bigGap)                   // Если размер гэпа не меньше большого
        {                               // Раскрашиваем столбик
         if( open[ i ] > close[ i-1 ] ) // Если гэп вверх
            bufValueClr[i]=1;           // Цвет - красный
         else                           // Если вниз
         bufValueClr[i]=0;              // Цвет - зеленый
        }
      else bufValueClr[i]=2;            // Если размер гэпа меньше минимального - цвет столбца гистограммы нейтральный
     }
  }
//+------------------------------------------------------------------+
