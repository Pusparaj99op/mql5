//+------------------------------------------------------------------+
//|                                             DayExtremumZones.mq5 |
//|                                                         Tapochun |
//|                         https://login.mql5.com/ru/users/tapochun |
//+------------------------------------------------------------------+
#property copyright "Tapochun"
#property link      "https://login.mql5.com/ru/users/tapochun"
#property version   "1.01"
#property indicator_chart_window
#property description "Индикатор отображает зоны максимумов и минимумов дня в процентах от дневного движения."
#property description "Использует индикатор DailySize https://www.mql5.com/ru/code/13323"
#property indicator_plots 2
#property indicator_buffers 4
//+------------------------------------------------------------------+
//| Глобальные переменные															|
//+------------------------------------------------------------------+
double bufW[];         // Значения максимумов дневного диапазона
double bufX[];         // Граница зоны максимумов/значения минимумов дневного диапазона

double bufY[];         // Значения минимумов дневного диапазона
double bufZ[];         // Граница зоны минимумов
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_DW_TYPE   // Перечисление - доступные типы отрисовки
  {
   FILLING,         // Заливка
   HISTOGRAM2,      // Гистограмма
   LINE,            // Линии
   ARROW,           // Стрелки
   NONE             // Не отрисовывается
  };

int globHandle;     // Хэндл индикатора дневных диапазонов (DailySize)
//+------------------------------------------------------------------+
//| Входные параметры																|
//+------------------------------------------------------------------+
input int inpUpZonePct = 15;                     // Размер зоны максимумов, % от дневного движения [0..50]
input int inpDnZonePct = 15;                     // Размер зоны минимумов, % от дневного движения [0..50]
input ENUM_DW_TYPE inpDrawType=ARROW;            // Тип отрисовки
input bool inpDrawInternalZone= true;            // Отображать внутреннюю зону (для типов "Линия"/"Стрелки"/"Не отрисовывается")
input bool inpShowData = false;                  // Отображать значения индикатора в окне данных
sinput string d1 = "";                           // Общие настройки отрисовки
input int inpUpWidth = 1;                        // Толщина отрисовки зоны максимумов
input int inpDnWidth = 1;                        // Толщина отрисовки зоны минимумов
input color inpUpColor= clrLightBlue;            // Цвет отрисовки зоны максимумов
input color inpDnColor = clrSpringGreen;         // Цвет отрисовки зоны минимумов
sinput string d2 = "";                           // Настройки отрисовки типа "Линия"/"Гистограмма"
input ENUM_LINE_STYLE inpUpStyle = STYLE_DOT;    // Стиль линии/зоны максимумов
input ENUM_LINE_STYLE inpDnStyle = STYLE_DOT;    // Стиль линии/зоны минимумов
sinput string d3 = "";                           // Настройки отрисовки типа "Стрелки"
input int inpUpArrowCode = 158;                  // Код стрелок зоны максимумов (для типа "Стрелки")
input int inpDnArrowCode = 158;                  // Код стрелок зоны минимумов (для типа "Стрелки")
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Проверка правильности входных параметров
   if(inpUpZonePct<0 || inpUpZonePct>50 || 
      inpDnZonePct<0 || inpDnZonePct>50)
     {
      Print(__FILE__,": ОШИБКА! Размер зон должен находиться в диапазоне от 0 до 50%. Проверьте входные параметры!");
      return( INIT_PARAMETERS_INCORRECT );
     }
//---
   if(_Period>PERIOD_H2)
     {
      Print(__FILE__,": ОШИБКА! Индикатор предназначен для работы на ТФ не выше H2!");
      return( INIT_PARAMETERS_INCORRECT );
     }
//---
   if(( inpDrawType==FILLING || inpDrawType==HISTOGRAM2) &&
      (inpUpZonePct==0 || inpDnZonePct==0))
     {
      Print(__FILE__,": ОШИБКА! Отрисовка стилем 'Заливка' или 'Гистограмма' доступна только при размерах зон > 0. Проверьте входные параметры!");
      return( INIT_PARAMETERS_INCORRECT );
     }
//--- Инициализируем индикаторные буферы
   SetIndexBuffer(0,bufW,INDICATOR_DATA);
   SetIndexBuffer(1,bufX,INDICATOR_DATA);
//---
   SetIndexBuffer(2,bufY,INDICATOR_DATA);
   SetIndexBuffer(3,bufZ,INDICATOR_DATA);
//--- Устанавливаем параметры отрисовки
   switch(inpDrawType)
     {
      case FILLING:
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_FILLING);
         PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_FILLING);
         //---
         PlotIndexSetString(0,PLOT_LABEL,"dez: up;dez: upZone");
         PlotIndexSetString(1,PLOT_LABEL,"dez: dn;dez: dnZone");
         //---
         PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,2);
         PlotIndexSetInteger(1,PLOT_COLOR_INDEXES,2);
         //---
         PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,inpUpColor);
         PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,inpUpColor);
         //---
         PlotIndexSetInteger(1,PLOT_LINE_COLOR,0,inpDnColor);
         PlotIndexSetInteger(1,PLOT_LINE_COLOR,1,inpDnColor);
         break;
      case HISTOGRAM2:
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_HISTOGRAM2);
         PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_HISTOGRAM2);
         //---
         PlotIndexSetString(0,PLOT_LABEL,"dez: up;dez: upZone");
         PlotIndexSetString(1,PLOT_LABEL,"dez: dn;dez: dnZone");
         //---
         PlotIndexSetInteger(0,PLOT_LINE_STYLE,inpUpStyle);
         PlotIndexSetInteger(1,PLOT_LINE_STYLE,inpDnStyle);
         break;
      case LINE:
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
         PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
         //---
         PlotIndexSetInteger(0,PLOT_LINE_STYLE,inpUpStyle);
         PlotIndexSetInteger(1,PLOT_LINE_STYLE,inpDnStyle);
         //---
         PlotIndexSetString(0,PLOT_LABEL,"dez: up");
         PlotIndexSetString(1,PLOT_LABEL,"dez: dn");
         //---
         PlotIndexSetInteger(0,PLOT_LINE_COLOR,inpUpColor);
         PlotIndexSetInteger(1,PLOT_LINE_COLOR,inpDnColor);
         break;
      case ARROW:
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_ARROW);
         PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_ARROW);
         //---
         PlotIndexSetInteger(0,PLOT_ARROW,inpUpArrowCode);
         PlotIndexSetInteger(1,PLOT_ARROW,inpDnArrowCode);
         //---
         PlotIndexSetString(0,PLOT_LABEL,"dez: up");
         PlotIndexSetString(1,PLOT_LABEL,"dez: dn");
         //---
         PlotIndexSetInteger(0,PLOT_LINE_COLOR,inpUpColor);
         PlotIndexSetInteger(1,PLOT_LINE_COLOR,inpDnColor);
         break;
      case NONE:
         PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
         PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
         //---
         PlotIndexSetString(0,PLOT_LABEL,"dez: up");
         PlotIndexSetString(1,PLOT_LABEL,"dez: dn");
         break;
      default:
         Print(__FUNCTION__,": ОШИБКА! Неизвестный тип отрисовки: "+EnumToString(inpDrawType));
         return( INIT_FAILED );
     }
//--- Устанавливаем толщину
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,inpUpWidth);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,inpDnWidth);
//--- Устанавливаем пустые значения буферов
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- Устанавливаем точность значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- Устанавливаем видимость значений в окне данных
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,inpShowData);
   PlotIndexSetInteger(1,PLOT_SHOW_DATA,inpShowData);
//--- Получаем хэндлы используемых индикаторов
   bool answer=InitializeIndicatorHandle(globHandle);
   if( !answer ) return( INIT_FAILED );
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
//--- Проверка наличия данных
   if( rates_total <= 0 ) return( 0 );
//---
   static int dNum;                         // Номер проверяемого дня
   static double dHigh = 0.0;               // Максимум дня
   static double dLow = DBL_MAX;            // Минимум дня
//---
   bool answer;                             // Ответ функции получения данных
   int firstBar = rates_total-2;            // Номер первого анализируемого бара
   int firstInd = 0;                        // Номер первого элемента в массиве значений индикатора
   double sizes[];                          // Массив - приемник размеров дневных диапазонов
//---
   if(prev_calculated!=0) // Если не первый запуск
     {
      if(rates_total>prev_calculated) // Если образовалась новая свеча
        {
         //--- Инициализируем индикаторные буферы начальными значениями
         const int n=rates_total-1;         // Обнуляемый индекс массива
         bufW[ n ] = EMPTY_VALUE;
         bufX[ n ] = EMPTY_VALUE;
         bufY[ n ] = EMPTY_VALUE;
         bufZ[ n ] = EMPTY_VALUE;
         //--- Получаем данные по индикатору размеров дневного диапазона
         answer=GetIndicatorData(globHandle,0,1,1,sizes,"DailySize");
         if( !answer ) return( prev_calculated );
        }
      else return(prev_calculated);         // Если не образовалась - выходим
     }
   else                                     // Если первый запуск
     {
      //--- Инициализируем индикаторные буферы начальными значениями
      ArrayInitialize(bufW,EMPTY_VALUE);
      ArrayInitialize(bufX,EMPTY_VALUE);
      ArrayInitialize(bufY,EMPTY_VALUE);
      ArrayInitialize(bufZ,EMPTY_VALUE);
      //--- Определяем номер бара первого полностью доступного дня
      firstBar=GetFirstBar(time,rates_total,dNum);
      if( firstBar == 0 ) return( prev_calculated );
      //--- Первый анализируемый элемент в массиве данных индикатора дневных диапазонов
      firstInd=firstBar;
      //--- Получаем данные по индикатору размеров дневного диапазона
      answer=GetIndicatorData(globHandle,0,0,rates_total,sizes,"DailySize");
      if( !answer ) return( prev_calculated );
     }
//---
   int iNum;                                    // Номер дня на i баре  
   for(int i=firstBar,j=firstInd; i<rates_total-1; i++,j++)
     {
      iNum=GetDayNumber(time[i]);         // Получаем номер дня на i баре
      if(dNum!=iNum) // Если считается новый день
        {
         //--- Сбрасываем параметры дня
         dNum = iNum;                           // Запоминаем новый номер проверяемого дня
         dHigh = high[ i ];                     // Запоминаем максимум i свечи
         dLow= low[ i ];                        // Запоминаем минимум i свечи
        }
      else                                     // Если считается текущий день
        {
         //--- Проверяем образование нового минимума/максимума дня
         if( high[ i ] > dHigh )                // Если максимум на i свече больше сохраненного
            dHigh = high[ i ];                  // Запоминаем новое значение максимума текущего дня

         if( low[ i ] < dLow )                   // Если минимум на i свече меньше сохраненного
            dLow = low[ i ];                     // Запоминаем новое значение минимума текущего дня
        }
      //---
      switch(inpDrawType) // В зависимости от типа отрисовки
        {
         case FILLING:                           // Тип - заливка
         case HISTOGRAM2:                        // Тип - гистограмма
            bufW[i]=dHigh;                                             // Значение максимума
            bufX[i]=bufW[i]-sizes[j]*inpUpZonePct/100*_Point;   // Значение зоны максимума
            //---
            bufY[ i ] = dLow;                                             // Значение минимума
            bufZ[ i ] = bufY[ i ] + sizes[ j ]*inpDnZonePct/100*_Point;   // Значение зоны минимума
            break;
         case LINE:                              // Тип - линия
         case ARROW:                           // Тип - стрелки
         case NONE:                              // Тип - без отображения
            if(inpDrawInternalZone) // Если установлена настройка отображения внутренней зоны
              {
               bufW[ i ]= dHigh-sizes[ j ]*inpUpZonePct/100*_Point;      // Значение зоны максимума
               bufX[ i ] = dLow+sizes[ j ]*inpDnZonePct/100*_Point;      // Значение зоны минимума
              }
            else                               // Если настройка не установлена
              {
               bufW[ i ]= dHigh;               // Значение максимума
               bufX[ i ] = dLow;               // Значение минимума
              }
            break;
         default:
            Print(__FUNCTION__,": ОШИБКА! Неизвестный тип отрисовки: "+EnumToString(inpDrawType));
            return( rates_total );
        }
     }
//---
   return( rates_total );
  }
//+------------------------------------------------------------------+
//| Получаем данные индикаторного буфера										|
//+------------------------------------------------------------------+
bool GetIndicatorData(const int handle,           // Хэндл индикатора
                      const int bufferNum,        // Номер буфера для копирования
                      const int startPos,         // Стартовая позиция для копирования
                      const int count,            // Сколько элементов копируем
                      double &array[],            // Массив приемник (out)
                      string strIndName = ""      // Имя индикатора (для сообщения об ошибке)
                      )
  {
   int num=CopyBuffer(handle,bufferNum,startPos,count,array);      // Копируем данные
   if(num==-1) // Если произошла ошибка копирования
     {
      Print(__FUNCTION__,": ОШИБКА #",GetLastError(),". Данные индикатора "+strIndName+" не получены. Скопировано элементов: ",num);
      return(false);                                                      // Возвращаем ложь
     }
   return(true);                                                         // Если данные скопированы - возвращаем истину
  }
//+------------------------------------------------------------------+
//| Получаем номер первого бара полностью доступного дня					|
//+------------------------------------------------------------------+
int GetFirstBar(const datetime &time[],     // Массив времен открытия баров по текущему ТФ
                const int rates_total,      // Количество просчитанных баров
                int &dayNum                 // Номер проверяемого дня (out)
                )
  {
   int prev = GetDayNumber( time[ 0 ] );    // Номер дня на предыдущем баре
   int curr;                                // Номер дня на текущем баре
   for(int i=1; i<rates_total; i++) // Цикл по просчитанных барам
     {
      curr = GetDayNumber( time[ i ] );     // Определяем номер дня на текущем баре
      if( curr == prev) continue;           // Если номера совпадаюют - переходим к след. бару
      else                                  // Если номера не совпадают
        {
         dayNum = curr;                     // Запоминаем номер первого проверяемого дня
         return( i );                       // Возвращаем номер бара первого полного дня
        }
     }
//---
   Print(__FUNCTION__,": Ожидаем больше данных..");
   return(0);                             // Возвращаем 0
  }
//+------------------------------------------------------------------+
//| Определяем номер дня по времени	бара										|
//+------------------------------------------------------------------+
int GetDayNumber(const datetime time) // Время бара
  {
   MqlDateTime tStr;                        // Структура времени
   TimeToStruct( time, tStr );              // Время в структуру
   return( tStr.day );                      // Возвращаем номер текущего дня
  }
//+------------------------------------------------------------------+
//| Инициализируем хэндл индикатора дневных диапазонов					|
//+------------------------------------------------------------------+
bool InitializeIndicatorHandle(int &handle) // Хэндл индикатора (out)
  {
   handle=iCustom(_Symbol,_Period,"DailySize");   // Попытка получения хэндла..
   if(handle==INVALID_HANDLE) // Если хэндл не получен
     {
      Print(__FUNCTION__,": ОШИБКА #",_LastError,". Хэндл индикатора DailySize не получен!");
      return(false);                                    // Выходим с ошибкой
     }
   else return(true);                                 // Если хэндл получен - возвращаем истину
  }
//+------------------------------------------------------------------+
