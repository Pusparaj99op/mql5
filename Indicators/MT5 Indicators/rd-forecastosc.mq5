//+------------------------------------------------------------------+
//|                                               RD-ForecastOsc.mq5 |
//|                Copyright © 2005, Nick Bilak, beluck[AT]gmail.com |
//|                                    http://metatrader.50webs.com/ |
//+------------------------------------------------------------------+
//---- авторство индикатора
#property copyright "Copyright © 2005, Nick Bilak"
//---- ссылка на сайт автора
#property link      "http://metatrader.50webs.com/"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window 
//---- для расчёта и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//---- использовано одно графическое построение
#property indicator_plots   1
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//--- в качестве цветов индикатора использованы
#property indicator_color1  clrMediumSeaGreen,clrDeepPink
//---- отображение метки индикатора
#property indicator_label1  "RD-Forecast Oscilator"
//+----------------------------------------------+
//|  Объявление перечисления                     |
//+----------------------------------------------+
enum Applied_price_ //Тип константы
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
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint   length=15;
input uint   t3=3;
input double b=0.7;
input Applied_price_ IPC=PRICE_CLOSE_;//ценовая константа
//+----------------------------------------------+

//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[],SigBuffer[];
//---
int min_rates_total;
double b2,b3,c1,c2,c3,c4,w1,w2,n,Kx,Br;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- инициализация глобальных переменных
   b2=b*b;
   b3=b2*b;
   c1=-b3;
   c2=(3*(b2+b3));
   c3=-3*(2*b2+b+b3);
   c4=(1+3*b+b3+3*b2);
//----
   n=MathMax(n,t3);
   n=1+0.5*(n-1);
   w1=2/(n+1);
   w2=1-w1;
   Kx=6.0/(length*(length+1.0));
   Br=(length+1.0)/3.0;
   min_rates_total=int(length+1);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,SigBuffer,INDICATOR_DATA);

//---- осуществление сдвига начала отсчёта отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total+1);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- имя для окон данных и лэйба для субъокон 
   string short_name="RD-ForecastOsc";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
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
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);

//---- объявления локальных переменных 
   int first,bar,bar1;
   double WT,forecastosc,t3_fosc,sum,e1,e2,e3,e4,e5,e6,tmp,tmp2;
   static double e1_,e2_,e3_,e4_,e5_,e6_;

//---- расчёты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      first=min_rates_total+1; // стартовый номер для расчёта всех баров
      e1_=0.0;
      e2_=0.0;
      e3_=0.0;
      e4_=0.0;
      e5_=0.0;
      e6_=0.0;
     }
   else
     {
      first=prev_calculated-1; // стартовый номер для расчёта новых баров
     }
   bar1=rates_total-2;

//---- восстанавливаем значения переменных
   e1=e1_;
   e2=e2_;
   e3=e3_;
   e4=e4_;
   e5=e5_;
   e6=e6_;

//---- основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      sum=0.0;
      for(int i=int(length); i>0; i--)
        {
         tmp=Br;
         tmp2=i;
         tmp=tmp2-tmp;
         sum+=tmp*PriceSeries(IPC,bar-length+i,open,low,high,close);
        }
      WT=sum*Kx;
      //----
      forecastosc=(PriceSeries(IPC,bar,open,low,high,close)-WT)/WT*100;
      e1=w1*forecastosc + w2*e1;
      e2=w1*e1 + w2*e2;
      e3=w1*e2 + w2*e3;
      e4=w1*e3 + w2*e4;
      e5=w1*e4 + w2*e5;
      e6=w1*e5 + w2*e6;
      //----
      t3_fosc=c1*e6+c2*e5+c3*e4+c4*e3;
      IndBuffer[bar]=forecastosc;
      SigBuffer[bar]=t3_fosc;

      //---- запоминаем значения переменных перед прогонами на текущем баре
      if(bar==bar1)
        {
         e1_=e1;
         e2_=e2;
         e3_=e3;
         e4_=e4;
         e5_=e5;
         e6_=e6;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+   
//| Получение значения ценовой таймсерии                             |
//+------------------------------------------------------------------+ 
double PriceSeries(
                   uint applied_price,// Ценовая константа
                   uint   bar,// Индекс сдвига относительно текущего бара на указанное количество периодов назад или вперёд).
                   const double &Open[],
                   const double &Low[],
                   const double &High[],
                   const double &Close[])
//PriceSeries(applied_price, bar, open, low, high, close)
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
  {
//----
   switch(applied_price)
     {
      //---- Ценовые константы из перечисления ENUM_APPLIED_PRICE
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
      case 12:
        {
         double res=High[bar]+Low[bar]+Close[bar];

         if(Close[bar]<Open[bar]) res=(res+Low[bar])/2;
         if(Close[bar]>Open[bar]) res=(res+High[bar])/2;
         if(Close[bar]==Open[bar]) res=(res+Close[bar])/2;
         return(((res-Low[bar])+(res-High[bar]))/2);
        }
      //----
      default: return(Close[bar]);
     }
//----
//return(0);
  }
//+------------------------------------------------------------------+
