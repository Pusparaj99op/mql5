//+------------------------------------------------------------------+ 
//|                                                     CCMx_HTF.mq5 | 
//|                               Copyright © 2014, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2014, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//---- номер версии индикатора
#property version   "1.00"
#property description "CCMx с возможностью изменения таймфрейма во входных параметрах"
//--- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- количество индикаторных буферов
#property indicator_buffers 2 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//+-------------------------------------+
//|  объявление констант                |
//+-------------------------------------+
#define RESET 0                          // Константа для возврата терминалу команды на пересчёт индикатора
#define INDICATOR_NAME "CCMx"            // Константа для имени индикатора
#define SIZE 1                           // Константа для количества вызовов функции CountIndicator
//+-------------------------------------+
//|  Параметры отрисовки индикатора 1   |
//+-------------------------------------+
//---- в качестве индикатора использована линия
#property indicator_type1   DRAW_LINE
//--- в качестве цвета бычей линии индикатора использован Chocolate цвет
#property indicator_color1  clrChocolate
//--- линия индикатора 1 - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 4
#property indicator_width1  4
//---- отображение метки индикатора
#property indicator_label1  INDICATOR_NAME

//+-------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА       |
//+-------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4; //Период графика индикатора
//+-------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА       |
//+-------------------------------------+
input uint   F=12;
input double k=1.682;
input double L_adx=18;
input ENUM_APPLIED_PRICE PriceMACD=PRICE_CLOSE;
input int Shift=0;               // сдвиг индикатора по горизонтали в барах 
input double Level1=+423.6;      // Уровень 1
input double Level2=+261.8;      // Уровень 2
input double Level3=+161.8;      // Уровень 3
input double Level4=+61.8;       // Уровень 4
input double Level5=0.0;         // Уровень 5
input double Level6=-61.8;       // Уровень 6
input double Level7=-161.8;      // Уровень 7
input double Level8=-261.8;      // Уровень 8
input double Level9=-423.6;      // Уровень 9                   
//+-------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[];
double ColorIndBuffer[];
//---- Объявление стрингов
string Symbol_,Word;
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//---- Объявление целых переменных для хендлов индикаторов
int Ind_Handle;
//+------------------------------------------------------------------+
//|  Получение таймфрейма в виде строки                              |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- проверка периодов графиков на корректность
   if(!TimeFramesCheck(INDICATOR_NAME,TimeFrame)) return(INIT_FAILED);

//---- Инициализация переменных 
   min_rates_total=2;
   Symbol_=Symbol();
   Word=INDICATOR_NAME+" индикатор: "+Symbol_+StringSubstr(EnumToString(_Period),7,-1);

//---- получение хендла индикатора CCMx
   Ind_Handle=iCustom(Symbol(),TimeFrame,INDICATOR_NAME,F,k,L_adx,PriceMACD,0,0,0,0,0,0,0,0,0,0);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора CCMx");
      return(INIT_FAILED);
     }

//---- Инициализация индикаторного буферов
   IndInit(0,IndBuffer,0.0,min_rates_total,Shift);

//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"(",GetStringTimeframe(TimeFrame),")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//--- количество  горизонтальных уровней индикатора 9   
   IndicatorSetInteger(INDICATOR_LEVELS,9);
//--- значения горизонтальных уровней индикатора   
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,Level1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,Level2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,Level3);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,3,Level4);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,4,Level5);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,5,Level6);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,6,Level7);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,7,Level8);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,8,Level9);
//--- в качестве цветов линий горизонтальных уровней использованы серый и розовый цвета  
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrBlue);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrMagenta);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,clrBlue);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,3,clrMagenta);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,4,clrGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,5,clrMagenta);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,6,clrBlue);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,7,clrMagenta);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,8,clrBlue);
//--- в линии горизонтального уровня использован короткий штрих-пунктир  
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,3,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,4,STYLE_DASH);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,5,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,6,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,7,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,8,STYLE_DASHDOTDOT);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(RESET);

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(time,true);

//----
   if(!CountIndicator(0,NULL,TimeFrame,Ind_Handle,0,IndBuffer,time,rates_total,prev_calculated,min_rates_total)) return(RESET);
//----     
   return(rates_total);
  }
//----
//+------------------------------------------------------------------+
//| Инициализация индикаторного буфера                               |
//+------------------------------------------------------------------+    
void IndInit(int Number,double &Buffer[],double Empty_Value,int Draw_Begin,int nShift)
  {
//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(Number,Buffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//---- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//---- индексация элементов в буферах как в таймсериях
   ArraySetAsSeries(Buffer,true);
//----
  }
//+------------------------------------------------------------------+
//| CountLine                                                        |
//+------------------------------------------------------------------+
bool CountIndicator(
                    uint     Numb,            // Номер функции CountLine по списку в коде индикатора (стартовый номер - 0)
                    string   Symb,            // Символ графика
                    ENUM_TIMEFRAMES TFrame,   // Период графика
                    int      IndHandle,       // Хендл обрабатываемого индикатора
                    uint     BuffNumb,        // Номер буфера обрабатываемого индикатора
                    double&  IndBuf[],        // Приёмный буфер индикатора
                    const datetime& iTime[],  // Таймсерия времени
                    const int Rates_Total,    // количество истории в барах на текущем тике
                    const int Prev_Calculated,// количество истории в барах на предыдущем тике
                    const int Min_Rates_Total // минимальное количество истории в барах для расчёта
                    )
//---- 
  {
//----
   static int LastCountBar[SIZE];
   datetime IndTime[1];
   int limit;

//---- расчёты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчёта баров
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=Rates_Total-Min_Rates_Total-1; // стартовый номер для расчёта всех баров
      LastCountBar[Numb]=limit;
     }
   else limit=LastCountBar[Numb]+Rates_Total-Prev_Calculated; // стартовый номер для расчёта новых баров 

//---- основной цикл расчёта индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- обнулим содержимое индикаторных буферов до расчёта
      IndBuf[bar]=0.0;

      //---- копируем вновь появившиеся данные в массив IndTime
      if(CopyTime(Symbol_,TFrame,iTime[bar],1,IndTime)<=0) return(RESET);

      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double Arr[1];

         //---- копируем вновь появившиеся данные в массивы
         if(CopyBuffer(IndHandle,BuffNumb,iTime[bar],1,Arr)<=0) return(RESET);

         IndBuf[bar]=Arr[0];
        }
      else IndBuf[bar]=IndBuf[bar+1];
     }
//----     
   return(true);
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(
                     string IndName,
                     ENUM_TIMEFRAMES TFrame //Период графика индикатора
                     )
//TimeFramesCheck(INDICATOR_NAME,TimeFrame)
  {
//---- проверка периодов графиков на корректность
   if(TFrame<Period() && TFrame!=PERIOD_CURRENT)
     {
      Print("Период графика для индикатора "+IndName+" не может быть меньше периода текущего графика!");
      Print("Следует изменить входные параметры индикатора!");
      return(RESET);
     }
//----
   return(true);
  }
//+------------------------------------------------------------------+
