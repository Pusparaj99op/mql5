//+------------------------------------------------------------------+
//|                                                      Gaus_MA.mq5 |
//|                            Copyright © 2009, Gregory A. Kakhiani |
//|                                              gkakhiani@gmail.com | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009, Gregory A. Kakhiani"
#property link      "gkakhiani@gmail.com"
#property version   "1.00"
//----
#property description "Усреднение (Сглаживание кривой цен) цен при помощи модифицированного алгоритма"
#property description "линейно-взвешенного скользящего среднего, где коэффициенты сглаживания расcчитываются"
#property description "при помощи радиально-базисной функци (функция Гаусса)"
//---- отрисовка индикатора в основном окне
#property indicator_chart_window
//---- для расчета и отрисовки индикатора использован один буфер
#property indicator_buffers 2
//---- использовано всего одно графическое построение
#property indicator_plots   1
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_COLOR_LINE
//---- в качестве цветов трехцветной линии использованы
#property indicator_color1  clrGray,clrTeal,clrCrimson
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1  2
//---- отображение метки индикатора
#property indicator_label1  "GaussAverage"
//+-----------------------------------+
//| Объявление перечисления           |
//+-----------------------------------+
enum Applied_price_ //тип константы
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price 
   PRICE_DEMARK_         //Demark Price
  };
//+-----------------------------------+
//| Входные параметры индикатора      |
//+-----------------------------------+
input uint      period=10;      // Период усреднения 
input double    N_=2;           // Степень экспоненты
input double    A=-0.001;       // Коэффициент степени е
input bool      Vol=false;      // Умножить на объем
input ENUM_APPLIED_VOLUME VolumeType=VOLUME_TICK;  // Объем
input Applied_price_ Applied_Price=PRICE_CLOSE_;   // Ценовая константа
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
input int PriceShift=0; // Сдвиг индикатора по вертикали в пунктах
//+-----------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double ExtLineBuffer[];
double ColorExtLineBuffer[];
//----
double N,dPriceShift;
double Coefs[]; //массив для хранения коэффициентов
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total,AvPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- превращение динамического массива ExtLineBuffer в индикаторный буфер
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- инициализация переменных
   AvPeriod=int(period);
//AvPeriod=MathMin(period,49);
   min_rates_total=AvPeriod+1;
   ArrayResize(Coefs,AvPeriod);
   N=N_;
   if(MathAbs(N)>5) N=5;
//---- заполнение массива коэффициентов
   for(int iii=0; iii<AvPeriod; iii++) Coefs[iii]=MathExp(A*MathPow(iii,N));
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"GaussAverage");
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorExtLineBuffer,INDICATOR_COLOR_INDEX);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//---- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total)
      return(0);
//---- объявления локальных переменных 
   int first,bar;
   double sum=0; //временные переменные для сумм
   double W=0;   //участвующих в числителе и знаменателе
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      first=min_rates_total; // стартовый номер для расчета всех баров
     }
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total; bar++)
     {
      sum=0;
      W=0;
      //----
      for(int kkk=0; kkk<AvPeriod; kkk++)
         if(Vol)
           {
            if(VolumeType==VOLUME_TICK)
              {
               sum+=PriceSeries(Applied_Price,bar-kkk,open,low,high,close)*tick_volume[bar]*Coefs[kkk];
               W+=Coefs[kkk]*tick_volume[bar];
              }
            else
              {
               sum+=PriceSeries(Applied_Price,bar-kkk,open,low,high,close)*volume[bar]*Coefs[kkk];
               W+=Coefs[kkk]*volume[bar];
              }
           }
      else
        {
         sum+=PriceSeries(Applied_Price,bar-kkk,open,low,high,close)*Coefs[kkk];
         W+=Coefs[kkk];
        }
      //---- инициализация ячейки индикаторного буфера полученным значением
      ExtLineBuffer[bar]=sum/W+dPriceShift;
     }
//---- пересчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
      first++;
//---- основной цикл раскраски сигнальной линии
   for(bar=first; bar<rates_total; bar++)
     {
      ColorExtLineBuffer[bar]=0;
      if(ExtLineBuffer[bar-1]<ExtLineBuffer[bar]) ColorExtLineBuffer[bar]=1;
      if(ExtLineBuffer[bar-1]>ExtLineBuffer[bar]) ColorExtLineBuffer[bar]=2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+  
//| PriceSeries() function                                           |
//+------------------------------------------------------------------+
double PriceSeries(uint applied_price,// ценовая константа
                   uint   bar,        // индекс сдвига относительно текущего бара на указанное количество периодов назад или вперед
                   const double &Open[],
                   const double &Low[],
                   const double &High[],
                   const double &Close[])
  {
//----
   switch(applied_price)
     {
      //---- ценовые константы из перечисления ENUM_APPLIED_PRICE
      case  PRICE_CLOSE: return(Close[bar]);
      case  PRICE_OPEN: return(Open [bar]);
      case  PRICE_HIGH: return(High [bar]);
      case  PRICE_LOW: return(Low[bar]);
      case  PRICE_MEDIAN: return((High[bar]+Low[bar])/2.0);
      case  PRICE_TYPICAL: return((Close[bar]+High[bar]+Low[bar])/3.0);
      case  PRICE_WEIGHTED: return((2*Close[bar]+High[bar]+Low[bar])/4.0);
      //----
      case  8: return((Open[bar] + Close[bar])/2.0);
      case  9: return((Open[bar] + Close[bar] + High[bar] + Low[bar])/4.0);
      //----
      case 10:
        {
         if(Close[bar]>Open[bar])return(High[bar]);
         else
           {
            if(Close[bar]<Open[bar])
               return(Low[bar]);
            else return(Close[bar]);
           }
        }
      //----
      case 11:
        {
         if(Close[bar]>Open[bar])return((High[bar]+Close[bar])/2.0);
         else
           {
            if(Close[bar]<Open[bar])
               return((Low[bar]+Close[bar])/2.0);
            else return(Close[bar]);
           }
         break;
        }
      //----
      default: return(Close[bar]);
     }
//----
//return(0);
  }
//+------------------------------------------------------------------+
