//+------------------------------------------------------------------+
//|                                                      Entropy.mq5 |
//|                                        Copyright © 2008,   Korey | 
//|                                                                  | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, Korey"
#property link ""
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- количество индикаторных буферов 1
#property indicator_buffers 1 
//---- использовано всего одно графические построение
#property indicator_plots   1
//+----------------------------------------------+
//| Параметры отрисовки индикатора               |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type1 DRAW_LINE
//---- в качестве окраски использован красно-коричневый цвет
#property indicator_color1 clrIndianRed
//---- линия индикатора - сплошная
#property indicator_style1 STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение метки сигнальной линии
#property indicator_label1  "Entropy"
//+----------------------------------------------+
//| Параметры отображения горизонтальных уровней |
//+----------------------------------------------+
#property indicator_level1 0.0
#property indicator_levelcolor clrBlue
#property indicator_levelstyle STYLE_SOLID
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input int Period_=15; // Период индикатора 
input int Shift=0;    // Сдвиг индикатора по горизонтали в барах 
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double ExtBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- превращение динамического массива ExtBuffer в индикаторный буфер
   SetIndexBuffer(0,ExtBuffer,INDICATOR_DATA);
//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"Entropy(",Period_,")");
//---- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- создание метки для отображения в Окне данных
   PlotIndexSetString(0,PLOT_LABEL,shortname);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,Period_);
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+4);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---- проверка количества баров на достаточность для расчета
   if(rates_total<Period_+begin) return(0);
//---- объявления локальных переменных 
   int first,bar,kkk;
//---- объявление переменных с плавающей точкой                 
   double sumx,sumx2,avgx,rmsx,Price0,Price1,fPrice,P,G;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      first=Period_+begin; // стартовый номер для расчета всех баров
     }
   else
     {
      first=prev_calculated-1; // стартовый номер для расчета новых баров
     }
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total; bar++)
     {
      sumx=0;
      sumx2=0;
      //---       
      for(int jjj=0; jjj<Period_; jjj++)
        {
         kkk=bar-jjj;
         Price0 = price[kkk];
         Price1 = price[kkk - 1];
         //---
         fPrice=MathLog(Price0/Price1);
         sumx+=fPrice;
         sumx2+=fPrice*fPrice;
        }
      //----       
      avgx = sumx / Period_;
      rmsx = MathSqrt(sumx2/Period_);
      //----      
      P = (1.0 + avgx/rmsx)/2.0;
      G = P * MathLog(1.0 + rmsx) + (1.0 - P) * MathLog(1.0 - rmsx);
      ExtBuffer[bar]=G;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
