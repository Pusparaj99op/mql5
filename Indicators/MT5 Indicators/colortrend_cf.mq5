//+------------------------------------------------------------------+
//|                                                ColorTrend_CF.mq5 |
//|                                         CF = Continuation Factor |
//|               Converted by and Copyright: Ronald Verwer/ROVERCOM |
//|                                                         27/04/06 |
//+------------------------------------------------------------------+
//---- авторство индикатора
#property copyright "Converted by and Copyright: Ronald Verwer/ROVERCOM"
#property link ""
//---- номер версии индикатора
#property version   "1.01"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window 
//---- для расчета и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//---- использовано 1 графическое построение
#property indicator_plots   1
//+----------------------------------------------+
//| Параметры отрисовки заливки                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде заливки между двумя линиями
#property indicator_type1   DRAW_FILLING
//---- в качестве цветов заливки индикатора использованы MediumSeaGreen и DeepPink
#property indicator_color1  clrMediumSeaGreen, clrDeepPink
//---- отображение метки индикатора
#property indicator_label1 "Trend_CF"
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint Period_=30;
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double UpperBuffer[];
double LowerBuffer[];
//----
int Count[];
//---- объявление целочисленных переменных начала отсчета данных
int StartBar;
//---- объявление массивов переменных для кольцевых буферов
double x_p[],x_n[],y_p[],y_n[];
//+------------------------------------------------------------------+
//| Пересчет позиции самого нового элемента в кольцевом буфере       |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[]// возврат по ссылке номера текущего значения ценового ряда
                          )
  {
//----
   int numb;
   static int count=1;
   count--;
   if(count<0) count=int(Period_)-1;
//----
   for(int iii=0; iii<int(Period_); iii++)
     {
      numb=iii+count;
      if(numb>int(Period_)-1) numb-=int(Period_);
      CoArr[iii]=numb;
     }
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- инициализация констант
   StartBar=int(Period_);
//---- распределение памяти под массивы переменных   
   ArrayResize(x_p,Period_);
   ArrayResize(x_n,Period_);
   ArrayResize(y_p,Period_);
   ArrayResize(y_n,Period_);
   ArrayResize(Count,Period_);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,UpperBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartBar);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,LowerBuffer,INDICATOR_DATA);
//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"Trend_CF(",Period_,")");
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const int begin,          // номер начала достоверного отсчета баров
                const double &price[])    // ценовой массив для расчета индикатора
  {
//---- проверка количества баров на достаточность для расчета
   if(rates_total<StartBar+begin) return(0);
//---- объявления локальных переменных 
   int first,bar,bar0,bar1,barq;
   double chp,chn,cffp,cffn,dprice;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated==0) // проверка на первый старт расчета индикатора
      first=1+begin; // стартовый номер для расчета всех баров
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total; bar++)
     {
      dprice=price[bar]-price[bar-1];
      //----
      bar0=Count[0];
      bar1=Count[1];
      //----
      if(dprice>0)
        {
         x_p[bar0]=dprice;
         y_p[bar0]=x_p[bar0]+y_p[bar1];
         x_n[bar0]=0;
         y_n[bar0]=0;
        }
      else
        {
         x_n[bar0]=-dprice;
         y_n[bar0]=x_n[bar0]+y_n[bar1];
         x_p[bar0]=0;
         y_p[bar0]=0;
        }
      //----
      if(bar<StartBar+begin)
        {
         if(bar<rates_total-1) Recount_ArrayZeroPos(Count);
         continue;
        }
      //----
      chp=0;
      chn=0;
      cffp=0;
      cffn=0;
      //----
      for(int q=int(Period_)-1; q>=0; q--)
        {
         barq=Count[q];

         chp+=x_p[barq];
         chn+=x_n[barq];
         cffp+=y_p[barq];
         cffn+=y_n[barq];
        }
      //----
      UpperBuffer[bar]=(chp-cffn)/_Point;
      LowerBuffer[bar]=(chn-cffp)/_Point;
      //----
      if(bar<rates_total-1) Recount_ArrayZeroPos(Count);
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
