//+---------------------------------------------------------------------+
//|                                                  Rainbow_Clouds.mq5 | 
//|                                  Copyright © 2015, Nikolay Kositsin | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2015, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//+----------------------------------------------+
//| Объявление констант                          |
//+----------------------------------------------+
#define INDTOTAL 5            // константа для количества отображаемых индикаторов
#define STEPTOTAL INDTOTAL*12 // константа для количества градаций шага
//+----------------------------------------------+
//---- количество индикаторных буферов
#property indicator_buffers 10//INDTOTAL*2 
//---- использовано всего пять графических построений
#property indicator_plots   INDTOTAL
//+----------------------------------------------+
//| Параметры отрисовки индикатора 1             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//--- в качестве цветов индикатора использованы
#property indicator_color1  clrGold,clrGold
//--- отображение метки индикатора
#property indicator_label1  "Rainbow_Cloud 1"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 2             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type2   DRAW_FILLING
//--- в качестве цветов индикатора использованы
#property indicator_color2  clrDodgerBlue,clrDodgerBlue
//--- отображение метки индикатора
#property indicator_label2  "Rainbow_Cloud 2"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 3             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type3   DRAW_FILLING
//--- в качестве цветов индикатора использованы
#property indicator_color3  clrLimeGreen,clrLimeGreen
//--- отображение метки индикатора
#property indicator_label3  "Rainbow_Cloud 3"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 4             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type4   DRAW_FILLING
//--- в качестве цветов индикатора использованы
#property indicator_color4  clrRed,clrRed
//--- отображение метки индикатора
#property indicator_label4  "Rainbow_Cloud 4"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 5             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type5   DRAW_FILLING
//--- в качестве цветов индикатора использованы
#property indicator_color5  clrDarkOrchid,clrDarkOrchid
//--- отображение метки индикатора
#property indicator_label5  "Rainbow_Cloud 5"
//+----------------------------------------------+
//| Описание класса CXMA                         |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA1[INDTOTAL+1];
//+----------------------------------------------+
//| Объявление перечислений                      |
//+----------------------------------------------+
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
//+----------------------------------------------+
//| Объявление перечислений                      |
//+----------------------------------------------+
/*enum Smooth_Method - перечисление объявлено в файле SmoothAlgorithms.mqh
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA,   //AMA
  }; */
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input Smooth_Method XMA_Method=MODE_EMA; // Метод усреднения
input uint StartLength=2; // Первая глубина усреднения
input uint StartStep=2;   // Стартовый шаг изменения усреднения 
input uint EndStep=6;     // Финишный шаг изменения усреднения                                         
input int XPhase=15;      // Параметр усреднения
                          // для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса
// для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC=PRICE_QUARTER_; // Ценовая константа
input int Shift=0;      // Сдвиг индикатора по горизонтали в барах
input int PriceShift=0; // Сдвиг индикатора по вертикали в пунктах
//+----------------------------------------------+
//---- объявление переменной значения вертикального сдвига скользящей средней
double dPriceShift;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
int length[INDTOTAL+1];
//+------------------------------------------------------------------+
//| Класс индикаторных буферов                                       |
//+------------------------------------------------------------------+  
class CIndBuffers
  {
public:
   double            m_UpBuffer[];
   double            m_DnBuffer[];
  };
//--- объявление динамических массивов, которые в дальнейшем
//--- будут использованы в качестве индикаторных буферов
CIndBuffers Ind[INDTOTAL];
//+------------------------------------------------------------------+   
//| Rainbow_Clouds indicator initialization function                 | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- инициализация переменных начала отсчета данных
   int period[STEPTOTAL+1];
   double ratio=(EndStep-StartStep)/(STEPTOTAL-1);
   period[0]=int(StartLength);
   for(int count=1; count<=STEPTOTAL; count++) period[count]=period[count-1]+int(StartStep+count*ratio);
   min_rates_total=int(GetStartBars(XMA_Method,int(period[STEPTOTAL]),XPhase));
   for(int numb=0; numb<=INDTOTAL; numb++) length[numb]=period[numb*12];
//---- инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
//---
   for(int numb=0; numb<INDTOTAL; numb++)
     {
      int count=numb*2;
      //---- превращение динамических массивов в индикаторные буферы
      SetIndexBuffer(count,Ind[numb].m_UpBuffer,INDICATOR_DATA);
      SetIndexBuffer(count+1,Ind[numb].m_DnBuffer,INDICATOR_DATA);
      //---- осуществление сдвига индикаторов по горизонтали
      PlotIndexSetInteger(numb,PLOT_SHIFT,Shift);
      //---- установка значений индикатора, которые не будут видимы на графике
      PlotIndexSetDouble(numb,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      //---- отображение меток индикаторов
      PlotIndexSetString(numb,PLOT_LABEL,"Rainbow_Cloud "+string(numb+1));
     }
//---- инициализация переменной для короткого имени индикатора
   string shortname;
   string Smooth1=XMA1[0].GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"Rainbow(",StartLength,", ",Smooth1,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+ 
//| Rainbow_Clouds iteration function                                | 
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
   if(rates_total<min_rates_total) return(0);
//---- объявление переменных с плавающей точкой  
   double price;
//---- объявление целых переменных и получение уже посчитанных баров
   int first,bar;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
      first=0; // стартовый номер для расчета всех баров
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price=PriceSeries(IPC,bar,open,low,high,close);
      Ind[0].m_UpBuffer[bar]=XMA1[0].XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,length[0],price,bar,false)+dPriceShift;
      Ind[0].m_DnBuffer[bar]=XMA1[1].XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,length[1],price,bar,false)+dPriceShift;
      Ind[1].m_UpBuffer[bar]=Ind[0].m_DnBuffer[bar];
      Ind[1].m_DnBuffer[bar]=XMA1[2].XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,length[2],price,bar,false)+dPriceShift;
      Ind[2].m_UpBuffer[bar]=Ind[1].m_DnBuffer[bar];
      Ind[2].m_DnBuffer[bar]=XMA1[3].XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,length[3],price,bar,false)+dPriceShift;
      Ind[3].m_UpBuffer[bar]=Ind[2].m_DnBuffer[bar];
      Ind[3].m_DnBuffer[bar]=XMA1[4].XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,length[4],price,bar,false)+dPriceShift;
      Ind[4].m_UpBuffer[bar]=Ind[3].m_DnBuffer[bar];
      Ind[4].m_DnBuffer[bar]=XMA1[5].XMASeries(0,prev_calculated,rates_total,XMA_Method,XPhase,length[5],price,bar,false)+dPriceShift;
     }
//----         
   return(rates_total);
  }
//+------------------------------------------------------------------+
