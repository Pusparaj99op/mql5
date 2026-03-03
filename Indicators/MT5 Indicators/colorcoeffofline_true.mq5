//+------------------------------------------------------------------+
//|                                        ColorCoeffofLine_true.mq5 |
//|                                       Ramdass - Conversion only  |
//+------------------------------------------------------------------+
#property copyright "Ramdass - Conversion only"
#property link ""
//--- номер версии индикатора
#property version   "1.00"
//--- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//--- количество индикаторных буферов 2
#property indicator_buffers 2 
//--- использовано всего одно графические построение
#property indicator_plots   1
//+-----------------------------------+
//| Параметры отрисовки индикатора    |
//+-----------------------------------+
//--- отрисовка индикатора в виде пятицветной гистограммы
#property indicator_type1 DRAW_COLOR_HISTOGRAM
//--- в качестве окраски гистограммы использовано пять цветов
#property indicator_color1 clrGray,clrLime,clrBlue,clrRed,clrMagenta
//--- линия индикатора - сплошная
#property indicator_style1 STYLE_SOLID
//--- толщина линии индикатора равна 2
#property indicator_width1 2
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input int SMMAPeriod=5;  // Период усреднения
//+----------------------------------------------+
//--- объявление динамических массивов, которые будут в 
//--- в дальнейшем будут использованы в качестве индикаторных буферов
double ExtBuffer[],ColorExtBuffer[];
//--- объявление переменной для хранения хендла индикатора
int Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- превращение динамического массива ExtBuffer в индикаторный буфер
   SetIndexBuffer(0,ExtBuffer,INDICATOR_DATA);
//--- индексация элементов в буферах как в таймсериях
   ArraySetAsSeries(ExtBuffer,true);
//--- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorExtBuffer,INDICATOR_COLOR_INDEX);
//--- индексация элементов в буферах как в таймсериях
   ArraySetAsSeries(ColorExtBuffer,true);
//--- осуществление сдвига начала отсчета отрисовки индикатора MAPeriod
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,2*SMMAPeriod+4);
//--- получение хендла индикатора
   Handle=iMA(NULL,0,SMMAPeriod,3,MODE_SMMA,PRICE_MEDIAN);
   if(Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора SMMA");
      return(INIT_FAILED);
     }
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчета индикатора
                const double& low[],      // ценовой массив минимумов  цены для расчета индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- проверка количества баров на достаточность для расчета
   if(BarsCalculated(Handle)<rates_total || rates_total<2*SMMAPeriod-1)
      return(0);
//--- объявления локальных переменных 
   int to_copy,limit1,limit2,Count,bar,cnt,iii,ndot=SMMAPeriod;
   double Sum,SMMA[],TYVar,ZYVar,TIndicatorVar,ZIndicatorVar,M,N,AY,AIndicator;
//--- индексация элементов в массивах как в таймсериях
   ArraySetAsSeries(SMMA,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
//--- расчет стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      limit1=rates_total-SMMAPeriod-ndot-1; // стартовый номер для расчета всех баров
      limit2=limit1-1;
      to_copy=rates_total-SMMAPeriod;
     }
   else
     {
      limit1=rates_total-prev_calculated; // стартовый номер для расчета новых баров
      limit2=limit1; // стартовый номер для расчета новых баров
      to_copy=limit1+ndot+1;
     }
//--- копируем вновь появившиеся данные в массив SMMA[]
   if(CopyBuffer(Handle,0,0,to_copy,SMMA)<=0) return(0);
//--- основной цикл расчета индикатора
   for(bar=limit1; bar>=0; bar--)
     {
      TYVar = 0;
      ZYVar = 0;
      N = 0;
      M = 0;
      TIndicatorVar = 0;
      ZIndicatorVar = 0;
      //--- цикл суммирования значений
      for(cnt=ndot; cnt>=1; cnt--) // n=5 -  по пяти точкам
        {
         iii = bar + cnt - 1;
         Sum = (high[iii] + low[iii]) / 2;
         Count=SMMAPeriod+1-cnt;
         //ZYVar += Sum * Count; 
         ZYVar+=((high[bar+cnt-1]+low[bar+cnt-1])/2)*(6-cnt);
         TYVar+= Sum;
         N+=cnt*cnt; //равно 55
         M+=cnt; //равно 15
         ZIndicatorVar += SMMA[iii] * Count;
         TIndicatorVar += SMMA[iii];
        }
      //---
      AY=(TYVar+(N-2*ZYVar)*ndot/M)/M;
      AIndicator=(TIndicatorVar+(N-2*ZIndicatorVar)*ndot/M)/M;
      //---
      if(Symbol()=="EURUSD" || Symbol()=="GBPUSD" || Symbol()=="USDCAD" || Symbol()=="USDCHF"
         || Symbol()=="EURGBP" || Symbol()=="EURCHF" || Symbol()=="AUDUSD"
         || Symbol()=="GBPCHF")
        {ExtBuffer[bar]=(-1000)*MathLog(AY/AIndicator);}
      else {ExtBuffer[bar]=(1000)*MathLog(AY/AIndicator);}
     }
//--- основной цикл раскраски индикатора
   for(bar=limit2; bar>=0; bar--)
     {
      ColorExtBuffer[bar]=0;
      //---
      if(ExtBuffer[bar]>0)
        {
         if(ExtBuffer[bar]>ExtBuffer[bar+1]) ColorExtBuffer[bar]=1;
         if(ExtBuffer[bar]<ExtBuffer[bar+1]) ColorExtBuffer[bar]=2;
        }
      //---
      if(ExtBuffer[bar]<0)
        {
         if(ExtBuffer[bar]<ExtBuffer[bar+1]) ColorExtBuffer[bar]=3;
         if(ExtBuffer[bar]>ExtBuffer[bar+1]) ColorExtBuffer[bar]=4;
        }
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
