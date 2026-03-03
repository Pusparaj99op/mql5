//+------------------------------------------------------------------+
//|                                                        Price.mq5 |
//|                               Copyright © 2016, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
//---- авторство индикатора
#property copyright "Copyright © 2016, Nikolay Kositsin"
//---- ссылка на сайт автора
#property link      "farria@mail.redcom.ru"
//---- номер версии индикатора
#property version   "1.00"
//----
#property description "Ценовая метка"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчета и отрисовки индикатора не используются буферы
#property indicator_buffers 0
//---- не используются графические построения
#property indicator_plots  0
//+----------------------------------------------+
//|Перечисление для вариантов определения тренда |
//+----------------------------------------------+
enum PriceMode
  {
   BID=0,  //биды
   ASK     //аски
  };
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input string  SirName="Price";               //Первая часть имени графических объектов
input PriceMode Price=BID;                   //Способ определения цены
input uint  Digits_=0;                       //Разряд округления
input color  Color_= clrMagenta;             //Цвет цены
input uint FontSize = 2;                     //Размер ценовых меток
input int  Shift = 10;                       //Сдвиг ценовых меток по горизонтали в барах
//+----------------------------------------------+
color clr;
int Normalize;
string ObjectNames;
double PointPow10;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- инициализация имен
   ObjectNames=SirName+" PriceLable";
//---- инициализация переменных         
   PointPow10=_Point*MathPow(10,Digits_);
   Normalize=int(_Digits-Digits_);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectDelete(0,ObjectNames);
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
                const double& high[],     // ценовой массив максимумов цены для расчета индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчета индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- индексация элементов в массивах как в таймсериях
   ArraySetAsSeries(close,false);
   ArraySetAsSeries(time,false);
   double price;
   if(Price==BID) price=close[rates_total-1];
   else 
    {
     ArraySetAsSeries(spread,false);
     price=close[rates_total-1]+_Point*spread[rates_total-1];
    }
   double res=NormalizeDouble(PointPow10*MathCeil(price/PointPow10),Normalize);
   datetime time0=time[rates_total-1]+PeriodSeconds()*Shift;
//----
   string info=ObjectNames+" "+DoubleToString(res,Normalize);
   SetRightPrice(0,ObjectNames,0,time0,res,Color_,FontSize,info);
//----
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  RightPrice creation                                             |
//+------------------------------------------------------------------+
void CreateRightPrice(long chart_id,// chart ID
                      string   name,              // object name
                      int      nwin,              // window index
                      datetime time,              // price level time
                      double   price,             // price level
                      color    Color,             // price color
                      int      fontsize,          // price size
                      string   text               // текст
                      )
  {
//----
   ObjectCreate(chart_id,name,OBJ_ARROW_RIGHT_PRICE,nwin,time,price);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,fontsize);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,false);
//----
  }
//+------------------------------------------------------------------+
//|  RightPrice reinstallation                                       |
//+------------------------------------------------------------------+
void SetRightPrice(long chart_id,// chart ID
                   string   name,              // object name
                   int      nwin,              // window index
                   datetime time,              // price level time
                   double   price,             // price level
                   color    Color,             // price color
                   int      fontsize,          // price size
                   string   text               // текст
                   )
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateRightPrice(chart_id,name,nwin,time,price,Color,fontsize,text);
   else
     {
      ObjectMove(chart_id,name,0,time,price);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
  }
//+------------------------------------------------------------------+
