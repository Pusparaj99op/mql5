//+------------------------------------------------------------------+ 
//|                                             AutoFibAutoTrend.mq5 | 
//|                                         Copyright © 2016, zzuegg | 
//|                                       when-money-makes-money.com | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2016, zzuegg"
#property link "when-money-makes-money.com" 
//---- номер версии индикатора
#property version   "1.00"
//+------------------------------------------------+ 
//|  Параметры отрисовки индикатора                |
//+------------------------------------------------+ 
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
#property indicator_buffers 0
#property indicator_plots   0
//+------------------------------------------------+ 
//|  Объявление констант                           |
//+------------------------------------------------+
#define RESET               0                   // Константа для возврата терминалу команды на пересчет индикатора
//+------------------------------------------------+ 
//|  Входные параметры индикатора                  |
//+------------------------------------------------+ 
//---- Входные параметры Зигзага
input ENUM_TIMEFRAMES Timeframe=PERIOD_H6;             // Таймфрейм Зигзага для расчета индикатора
input int ExtDepth=12;
input int ExtDeviation=5;
input int ExtBackstep=3;
//---- настройки визуального отображения индикатора
input string Sirname="AutoFibAutoTrend";  // Название для меток индикатора
input bool ShowFib=true;
input color FibColor=clrRed;
input uint   FibSize=1;
//----
input bool ShowFibFan=true;
input color FibFanColor=clrMediumSeaGreen;
input uint FibFanSize=1;
//----
input bool ShowTrend=true;
input color TrendColor=clrBlue;
input uint TrendSize=5;
//+-----------------------------------+
//---- объявление целочисленных переменных для хендлов индикаторов
int Ind_Handle;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
string fib1="";
string trend="";
string fibf1="";
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
//---- Инициализация переменных начала отсчета данных   
   min_rates_total=100;

//---- инициализация переменных
   fib1=Sirname+" fib1 "+GetStringTimeframe(Timeframe);
   trend=Sirname+" trend1 "+GetStringTimeframe(Timeframe);
   fibf1=Sirname+" fibf1 "+GetStringTimeframe(Timeframe);

//---- получение хендла индикатора ZigZag_NK_Color
   Ind_Handle=iCustom(Symbol(),Timeframe,"ZigZag_NK_Color",ExtDepth,ExtDeviation,ExtBackstep);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора ZigZag_NK_Color");
      return(INIT_FAILED);
     }

//---- имя для окон данных и лэйба для субъокон 
   string shortname;
   StringConcatenate(shortname,"ZigZag (ExtDepth=",ExtDepth,"ExtDeviation = ",ExtDeviation,"ExtBackstep = ",ExtBackstep,")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectDelete(0,fib1);
   ObjectDelete(0,trend);
   ObjectDelete(0,fibf1);
//----
   ChartRedraw(0);
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
   if(BarsCalculated(Ind_Handle)<min_rates_total) return(RESET);
   if(BarsCalculated(Ind_Handle)<Bars(Symbol(),Timeframe)) return(prev_calculated);
//---- объявление локальных переменных
   double UpSign[],DnSign[];
   static datetime TIME[];

//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(Ind_Handle,0,0,rates_total,DnSign)<=0) return(RESET);
   if(CopyBuffer(Ind_Handle,1,0,rates_total,UpSign)<=0) return(RESET);
   if(CopyTime(Symbol(),Timeframe,0,rates_total,TIME)<=0) return(RESET);

//---- индексация элементов в массивах, как в таймсериях  
   ArraySetAsSeries(DnSign,true);
   ArraySetAsSeries(UpSign,true);
   ArraySetAsSeries(TIME,true);

   static datetime curr=NULL;
   if(curr!=TIME[0])
     {
      curr=TIME[0];
      double swing_value[4]={0,0,0,0};
      datetime swing_date[4]={0,0,0,0};
      int found=NULL;
      double tmp=NULL;
      int bar=NULL;
      while(found<4 && bar<rates_total)
        {
         if(UpSign[bar])
           {
            swing_value[found]=UpSign[bar];
            swing_date[found]=TIME[bar];
            found++;
           }
         if(DnSign[bar])
           {
            swing_value[found]=DnSign[bar];
            swing_date[found]=TIME[bar];
            found++;
           }
         bar++;
        }

      if(ShowTrend) SetChannel(0,trend,0,swing_date[3],swing_value[3],swing_date[1],swing_value[1],swing_date[2],swing_value[2],TrendColor,0,TrendSize,true,trend);
      if(ShowFib) SetFibo(0,fib1,0,swing_date[2],swing_value[2],swing_date[1],swing_value[1],FibColor,0,FibSize,true,fib1);
      if(ShowFibFan) SetFiboFan(0,fibf1,0,swing_date[2],swing_value[2],swing_date[1],swing_value[1],FibFanColor,0,FibFanSize,true,fibf1);
     }
//----
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  Создание Фибо                                                   |
//+------------------------------------------------------------------+
void CreateFibo(long     chart_id,      // идентификатор графика
                string   name,          // имя объекта
                int      nwin,          // индекс окна
                datetime time1,         // время 1 ценового уровня
                double   price1,        // 1 ценовой уровень
                datetime time2,         // время 2 ценового уровня
                double   price2,        // 2 ценовой уровень
                color    Color,         // цвет линии
                int      style,         // стиль линии
                int      width,         // толщина линии
                int      ray,           // направление луча: -1 - влево, +1 - вправо, остальные значения - нет луча
                string   text)          // текст
  {
//----
   ObjectCreate(chart_id,name,OBJ_FIBO,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);

   if(ray>0)ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);
   if(ray<0)ObjectSetInteger(chart_id,name,OBJPROP_RAY_LEFT,true);

   if(ray==0)
     {
      ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(chart_id,name,OBJPROP_RAY_LEFT,false);
     }

   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);

   for(int numb=0; numb<10; numb++)
     {
      ObjectSetInteger(chart_id,name,OBJPROP_LEVELCOLOR,numb,Color);
      ObjectSetInteger(chart_id,name,OBJPROP_LEVELSTYLE,numb,style);
      ObjectSetInteger(chart_id,name,OBJPROP_LEVELWIDTH,numb,width);
     }
//----
  }
//+------------------------------------------------------------------+
//|  Переустановка Фибо                                              |
//+------------------------------------------------------------------+
void SetFibo(long     chart_id,      // идентификатор графика
             string   name,          // имя объекта
             int      nwin,          // индекс окна
             datetime time1,         // время 1 ценового уровня
             double   price1,        // 1 ценовой уровень
             datetime time2,         // время 2 ценового уровня
             double   price2,        // 2 ценовой уровень
             color    Color,         // цвет линии
             int      style,         // стиль линии
             int      width,         // толщина линии
             int      ray,           // направление луча: -1 - влево, 0 - нет луча, +1 - вправо
             string   text)          // текст
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateFibo(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,ray,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
     }
//----
  }
//+------------------------------------------------------------------+
//|  Создание Фибо                                                   |
//+------------------------------------------------------------------+
void CreateFiboFan(long     chart_id,      // идентификатор графика
                   string   name,          // имя объекта
                   int      nwin,          // индекс окна
                   datetime time1,         // время 1 ценового уровня
                   double   price1,        // 1 ценовой уровень
                   datetime time2,         // время 2 ценового уровня
                   double   price2,        // 2 ценовой уровень
                   color    Color,         // цвет линии
                   int      style,         // стиль линии
                   int      width,         // толщина линии
                   int      ray,           // направление луча: -1 - влево, +1 - вправо, остальные значения - нет луча
                   string   text)          // текст
  {
//----
   ObjectCreate(chart_id,name,OBJ_FIBOFAN,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);

   if(ray>0)ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);
   if(ray<0)ObjectSetInteger(chart_id,name,OBJPROP_RAY_LEFT,true);

   if(ray==0)
     {
      ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(chart_id,name,OBJPROP_RAY_LEFT,false);
     }

   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);

   for(int numb=0; numb<10; numb++)
     {
      ObjectSetInteger(chart_id,name,OBJPROP_LEVELCOLOR,numb,Color);
      ObjectSetInteger(chart_id,name,OBJPROP_LEVELSTYLE,numb,style);
      ObjectSetInteger(chart_id,name,OBJPROP_LEVELWIDTH,numb,width);
     }
//----
  }
//+------------------------------------------------------------------+
//|  Переустановка Фибо                                              |
//+------------------------------------------------------------------+
void SetFiboFan(long     chart_id,      // идентификатор графика
                string   name,          // имя объекта
                int      nwin,          // индекс окна
                datetime time1,         // время 1 ценового уровня
                double   price1,        // 1 ценовой уровень
                datetime time2,         // время 2 ценового уровня
                double   price2,        // 2 ценовой уровень
                color    Color,         // цвет линии
                int      style,         // стиль линии
                int      width,         // толщина линии
                int      ray,           // направление луча: -1 - влево, 0 - нет луча, +1 - вправо
                string   text)          // текст
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateFiboFan(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,ray,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
     }
//----
  }
//+------------------------------------------------------------------+
//|  Создание канала                                                 |
//+------------------------------------------------------------------+
void CreateChannel(long     chart_id,      // идентификатор графика
                   string   name,          // имя объекта
                   int      nwin,          // индекс окна
                   datetime time1,         // время 1 ценового уровня
                   double   price1,        // 1 ценовой уровень
                   datetime time2,         // время 2 ценового уровня
                   double   price2,        // 2 ценовой уровень
                   datetime time3,         // время 3 ценового уровня
                   double   price3,        // 3 ценовой уровень
                   color    Color,         // цвет линии
                   int      style,         // стиль линии
                   int      width,         // толщина линии
                   int      ray,           // направление луча: -1 - влево, +1 - вправо, остальные значения - нет луча
                   string   text)          // текст
  {
//----
   ObjectCreate(chart_id,name,OBJ_CHANNEL,nwin,time1,price1,time2,price2,time3,price3);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);

   if(ray>0)ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);
   if(ray<0)ObjectSetInteger(chart_id,name,OBJPROP_RAY_LEFT,true);

   if(ray==0)
     {
      ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(chart_id,name,OBJPROP_RAY_LEFT,false);
     }

   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);

   for(int numb=0; numb<10; numb++)
     {
      ObjectSetInteger(chart_id,name,OBJPROP_LEVELCOLOR,numb,Color);
      ObjectSetInteger(chart_id,name,OBJPROP_LEVELSTYLE,numb,style);
      ObjectSetInteger(chart_id,name,OBJPROP_LEVELWIDTH,numb,width);
     }
//----
  }
//+------------------------------------------------------------------+
//|  Переустановка канала                                            |
//+------------------------------------------------------------------+
void SetChannel(long     chart_id,      // идентификатор графика
                string   name,          // имя объекта
                int      nwin,          // индекс окна
                datetime time1,         // время 1 ценового уровня
                double   price1,        // 1 ценовой уровень
                datetime time2,         // время 2 ценового уровня
                double   price2,        // 2 ценовой уровень
                datetime time3,         // время 3 ценового уровня
                double   price3,        // 3 ценовой уровень
                color    Color,         // цвет линии
                int      style,         // стиль линии
                int      width,         // толщина линии
                int      ray,           // направление луча: -1 - влево, 0 - нет луча, +1 - вправо
                string   text)          // текст
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateChannel(chart_id,name,nwin,time1,price1,time2,price2,time3,price3,Color,style,width,ray,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
      ObjectMove(chart_id,name,2,time3,price3);
     }
//----
  }
//+------------------------------------------------------------------+
