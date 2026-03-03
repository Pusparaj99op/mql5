//+------------------------------------------------------------------+ 
//|                                                      MA_2HTF.mq5 | 
//|                                         Copyright © 2006, lukas1 | 
//|                                                                  | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2006, lukas1"
#property link ""
//--- номер версии индикатора
#property version   "1.60"
#property description "Цветное облако из средних с разных таймфреймов с одинаковыми параметрами на одном графике."
//--- отрисовка индикатора в главном окне
#property indicator_chart_window
//--- количество индикаторных буферов 2
#property indicator_buffers 2 
//--- использовано всего одно графическое построение
#property indicator_plots   1
//+-------------------------------------+
//|  объявление констант                |
//+-------------------------------------+
#define RESET 0              // Константа для возврата терминалу команды на пересчет индикатора
#define INDICATOR_NAME "MA"  // Константа для имени индикатора
#define SIZE 2               // Константа для количества вызовов функции CountIndicator коде
//+-------------------------------------+
//|  Параметры отрисовки индикатора     |
//+-------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//--- в качестве цветов индикатора использованы
#property indicator_color1  clrPaleGreen,clrHotPink
//--- отображение метки индикатора
#property indicator_label1  "MA_2HTF"
//+-------------------------------------+
//| Входные параметры индикатора        |
//+-------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame1=PERIOD_M30; // Период графика индикатора 1 (младший таймфрейм)
input uint                 MAPeriod1=13;
input  ENUM_MA_METHOD      MAType1=MODE_EMA;
input ENUM_APPLIED_PRICE   MAPrice1=PRICE_CLOSE;
//---
input ENUM_TIMEFRAMES TimeFrame2=PERIOD_H4;  // Период графика индикатора 2 (старший таймфрейм)
input uint                 MAPeriod2=13;
input  ENUM_MA_METHOD      MAType2=MODE_EMA;
input ENUM_APPLIED_PRICE   MAPrice2=PRICE_CLOSE;
//---
input int                  Shift=0;          // Сдвиг индикатора по горизонтали в барах
//+-------------------------------------+ 
//--- объявление динамических массивов, которые в дальнейшем
//--- будут использованы в качестве индикаторных буферов
double Ind1Buffer[];
double Ind2Buffer[];
//--- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//--- объявление целочисленных переменных для хендлов индикаторов
int Ind1_Handle,Ind2_Handle;
//+------------------------------------------------------------------+
//| Получение таймфрейма в виде строки                               |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- проверка периодов графиков на корректность
   if(!TimeFramesCheck(INDICATOR_NAME,TimeFrame1,TimeFrame2)) return(INIT_FAILED);
//--- инициализация переменных 
   min_rates_total=2;
//--- получение хендла индикатора MA 1
   Ind1_Handle=iMA(Symbol(),TimeFrame1,MAPeriod1,0,MAType1,MAPrice1);
   if(Ind1_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора MA 1");
      return(INIT_FAILED);
     }
//--- получение хендла индикатора MA 2
   Ind2_Handle=iMA(Symbol(),TimeFrame2,MAPeriod2,0,MAType2,MAPrice2);
   if(Ind2_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора MA 2");
      return(INIT_FAILED);
     }
//--- инициализация индикаторных буферов
   IndInit(0,Ind1Buffer);
   IndInit(1,Ind2Buffer);
   PlotInit(0,0.0,min_rates_total,Shift);
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame1),", ",GetStringTimeframe(TimeFrame2),")");
//---
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
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
   if(rates_total<min_rates_total) return(RESET);
   if(BarsCalculated(Ind1_Handle)<Bars(Symbol(),TimeFrame1)) return(prev_calculated);
   if(BarsCalculated(Ind2_Handle)<Bars(Symbol(),TimeFrame2)) return(prev_calculated);
//--- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(time,true);
//---
   if(!CountIndicator(0,NULL,TimeFrame1,Ind1_Handle,0,Ind1Buffer,time,rates_total,prev_calculated,min_rates_total)) return(RESET);
   if(!CountIndicator(1,NULL,TimeFrame2,Ind2_Handle,0,Ind2Buffer,time,rates_total,prev_calculated,min_rates_total)) return(RESET);
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Инициализация индикаторного буфера                               |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[])
  {
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(Number,Buffer,INDICATOR_DATA);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(Buffer,true);
  }
//+------------------------------------------------------------------+
//| Инициализация индикаторного буфера                               |
//+------------------------------------------------------------------+    
void PlotInit(int Number,double Empty_Value,int Draw_Begin,int nShift)
  {
//--- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//--- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//--- осуществление сдвига индикатора 2 по горизонтали на Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
  }
//+------------------------------------------------------------------+
//| CountLine                                                        |
//+------------------------------------------------------------------+
bool CountIndicator(uint     Numb,            // Номер функции CountLine по списку в коде индикатора (стартовый номер - 0)
                    string   Symb,            // Символ графика
                    ENUM_TIMEFRAMES TFrame,   // Период графика
                    int      IndHandle,       // Хендл обрабатываемого индикатора
                    uint     BuffNumb,        // Номер буфера обрабатываемого индикатора
                    double&  IndBuf[],        // Приемный буфер индикатора
                    const datetime& iTime[],  // Таймсерия времени
                    const int Rates_Total,    // количество истории в барах на текущем тике
                    const int Prev_Calculated,// количество истории в барах на предыдущем тике
                    const int Min_Rates_Total)// минимальное количество истории в барах для расчета
  {
//---
   static int LastCountBar[SIZE];
   datetime IndTime[1];
   int limit;
//--- расчеты необходимого количества копируемых данных
//--- и стартового номера limit для цикла пересчета баров
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=Rates_Total-Min_Rates_Total-1; // стартовый номер для расчета всех баров
      LastCountBar[Numb]=limit;
     }
   else limit=LastCountBar[Numb]+Rates_Total-Prev_Calculated; // стартовый номер для расчета новых баров 

//--- основной цикл расчета индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- обнулим содержимое индикаторных буферов до расчета
      IndBuf[bar]=0.0;
      //--- копируем вновь появившиеся данные в массив IndTime
      if(CopyTime(Symbol(),TFrame,iTime[bar],1,IndTime)<=0) return(RESET);

      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double Arr[1];
         //--- копируем вновь появившиеся данные в массив Arr
         if(CopyBuffer(IndHandle,BuffNumb,iTime[bar],1,Arr)<=0) return(RESET);
         IndBuf[bar]=Arr[0];
        }
      else IndBuf[bar]=IndBuf[bar+1];
     }
//---     
   return(true);
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(string IndName,
                     ENUM_TIMEFRAMES TFrame1, //Период графика индикатора 1 (младший таймфрейм)
                     ENUM_TIMEFRAMES TFrame2) //Период графика индикатора 3 (старший таймфрейм)
  {
//--- проверка периодов графиков на корректность
   if(TFrame1<Period() && TFrame1!=PERIOD_CURRENT)
     {
      Print("Период графика 1 для индикатора "+IndName+" не может быть меньше периода текущего графика!");
      Print("Следует изменить входные параметры индикатора!");
      return(RESET);
     }

   if(TFrame2<=TFrame1)
     {
      Print("Период графика 2 для индикатора "+IndName+" должен быть больше периода графика 1!");
      Print("Следует изменить входные параметры индикатора!");
      return(RESET);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
