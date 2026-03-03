//+------------------------------------------------------------------+
//|                                                      AMA_STL.mq5 |
//|                      Copyright © 2006, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 1
#property indicator_buffers 1 
//---- использовано одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//|  Параметры отрисовки индикатора   |
//+-----------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета линии индикатора использован SlateBlue цвет
#property indicator_color1 clrSlateBlue
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 1
#property indicator_width1  1
//---- отображение метки индикатора
#property indicator_label1  "AMA_STL"
//+-----------------------------------+
//|  объявление констант              |
//+-----------------------------------+
#define RESET 0 // Константа для возврата терминалу команды на пересчёт индикатора
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input uint FastMA=3;
input uint SlowMA=100;
input uint Range=160;
input uint filter=25;
input uint Level=100;
//+-----------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double ExtBuffer[];
//----
double k1,k2,dLevel;
//---- Объявление целых переменных начала отсчёта данных
int  min_rates_total;
//---- объявление глобальных переменных
int Count[];
double mAMA[];
//+------------------------------------------------------------------+
//|  Пересчет позиции самого нового элемента в массиве               |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[],// Возврат по ссылке номера текущего значения ценового ряда
                          int Size)
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max2=Size;
   Max1=Max2-1;

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=int(Range+1);
   k1=2.0/(SlowMA+1);
   k2=2.0/(FastMA+1)-k1;
   dLevel=Level*_Point;

//---- распределение памяти под массивы переменных  
   if(ArrayResize(Count,Range)<int(Range))
     {
      Print("Не удалось распределить память под массив Count[]");
      return(INIT_FAILED);
     }
   if(ArrayResize(mAMA,Range)<int(Range))
     {
      Print("Не удалось распределить память под массив mAMA[]");
      return(INIT_FAILED);
     }
   ArrayInitialize(Count,0);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,ExtBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ExtBuffer,true);

//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"AMA_STL");
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- завершение инициализации
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

//---- объявления локальных переменных 
   int limit,bar;
   double Noise,ER,SSC,AMA,sdAMA,dAMA,HH,LL,Res;
   static double AMA_;

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//---- расчёты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
      AMA_=close[limit+1];
      ArrayInitialize(mAMA,close[limit+1]);
     }
   else limit=rates_total-prev_calculated; // стартовый номер для расчёта новых баров
//----  
   AMA=AMA_;

//---- первый цикл расчёта индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Noise=0;
      for(int i=bar+int(Range)-1; i>=bar; i--) Noise+=MathAbs(close[i]-close[i+1]);
      if(Noise) ER=MathAbs(close[bar]-close[bar+Range])/Noise;
      else ER=0;
      SSC=(ER*k2+k1);
      AMA+=NormalizeDouble(SSC*SSC*(close[bar]-AMA),_Digits);
      mAMA[Count[0]]=AMA;
      //----
      if(filter<1) ExtBuffer[bar]=mAMA[Count[0]];
      else
        {
         sdAMA=0.0;
         for(int i=bar+int(SlowMA)-1; i>=bar; i--) sdAMA+=MathAbs(mAMA[Count[0]]-mAMA[Count[1]]);

         dAMA=mAMA[Count[0]]-mAMA[Count[1]];
         Res=NormalizeDouble(filter*sdAMA/(100*SlowMA),_Digits);
         //----
         if(dAMA>=0)
           {
            HH=high[ArrayMaximum(high,bar,Range)];;
            if(+dAMA<Res && high[bar]<=HH+dLevel) ExtBuffer[bar]=ExtBuffer[bar+1];
            else ExtBuffer[bar]=mAMA[Count[0]];
           }
         else
           {
            LL=low[ArrayMinimum(low,bar,Range)];
            if(-dAMA<Res && low[bar]>LL-dLevel) ExtBuffer[bar]=ExtBuffer[bar+1];
            else ExtBuffer[bar]=mAMA[Count[0]];
           }
        }
      
      if(bar)
        {
         Recount_ArrayZeroPos(Count,Range);
         AMA_=AMA;
        }
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
