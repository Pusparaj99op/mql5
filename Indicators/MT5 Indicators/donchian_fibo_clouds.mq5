//+------------------------------------------------------------------+
//|                                             Donchian_Fibo_Clouds |
//|                               Copyright © 2015, Guilherme Santos |
//|                                               fishguil@gmail.com |
//|                                                                  |
//|                            Modified Version of Donchian Channels |
//|                                        By Luis Guilherme Damiani |
//|                                      http://www.damianifx.com.br |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2015, Guilherme Santos"
#property link      "fishguil@gmail.com"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//+----------------------------------------------+
//| Объявление констант                          |
//+----------------------------------------------+
#define INDTOTAL 6            // константа для количества отображаемых индикаторов
#define BUFTOTAL 12           // константа для количества буфферов индикаторов BUFTOTAL*2
//+----------------------------------------------+
//---- количество индикаторных буферов
#property indicator_buffers BUFTOTAL
//---- использовано всего шесть графических построений
#property indicator_plots   INDTOTAL
//+----------------------------------------------+
//| Параметры отрисовки индикатора 1             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//--- в качестве цвета индикатора использован
#property indicator_color1  clrDodgerBlue
//--- отображение метки индикатора
#property indicator_label1  "Fibo 1.000"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 2             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type2   DRAW_FILLING
//--- в качестве цвета индикатора использован
#property indicator_color2  clrDeepSkyBlue
//--- отображение метки индикатора
#property indicator_label2  "Fibo 0.786"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 3             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type3   DRAW_FILLING
//--- в качестве цвета индикатора использован
#property indicator_color3  clrAqua
//--- отображение метки индикатора
#property indicator_label3  "Fibo 0.618"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 4             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type4   DRAW_FILLING
//--- в качестве цвета индикатора использован
#property indicator_color4  clrYellow
//--- отображение метки индикатора
#property indicator_label4  "Fibo 0.500"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 5             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type5   DRAW_FILLING
//--- в качестве цвета индикатора использован
#property indicator_color5  clrGold
//--- отображение метки индикатора
#property indicator_label5  "Fibo 0.382"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 6             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type6   DRAW_FILLING
//--- в качестве цвета индикатора использован
#property indicator_color6  clrRed
//--- отображение метки индикатора
#property indicator_label6  "Fibo 0.214"
//+-----------------------------------+
//| Enumeration declaration           |
//+-----------------------------------+
enum Applied_Extrem //type of extreme points
  {
   HIGH_LOW,
   HIGH_LOW_OPEN,
   HIGH_LOW_CLOSE,
   OPEN_HIGH_LOW,
   CLOSE_HIGH_LOW
  };
//+-----------------------------------+
//| Input parameters of the indicator |
//+-----------------------------------+
input uint FiboPeriod=72;                 // Period of averaging
input Applied_Extrem Extremes=HIGH_LOW;   // Type of extreme points
input int Margins=-2;
input double Level1=0.786;
input double Level2=0.618;
input double Level3=0.500;
input double Level4=0.382;
input double Level5=0.214;
input int Shift=0;                        // Horizontal shift of the indicator in bars
//+-----------------------------------+
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
//| Donchian Channel indicator initialization function               | 
//+------------------------------------------------------------------+  
void OnInit()
  {
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
      //---- осуществление сдвига начала отсчета отрисовки индикатора
      PlotIndexSetInteger(numb,PLOT_DRAW_BEGIN,FiboPeriod);
      //---- индексация элементов в буферах как в таймсериях
      ArraySetAsSeries(Ind[numb].m_UpBuffer,true);
      ArraySetAsSeries(Ind[numb].m_DnBuffer,true);
     }
//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"Donchian Fibo(Period = ",FiboPeriod,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| Donchian Channel iteration function                              | 
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
//---- checking the number of bars to be enough for the calculation
   if(rates_total<int(FiboPeriod)+1) return(0);
//---- declaration of variables with a floating point  
   double smin=0,smax=0,sdiff=0;
//---- объявления локальных переменных 
   int limit,bar;
//---- расчеты необходимого количества копируемых данных и стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-1-int(FiboPeriod); // стартовый номер для расчета всех баров
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
     }
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//---- основной цикл исправления и окрашивания свечей
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      switch(Extremes)
        {
         case HIGH_LOW:
            smax=high[ArrayMaximum(high,bar,FiboPeriod)];
            smin=low[ArrayMinimum(low,bar,FiboPeriod)];
            break;
            //---
         case HIGH_LOW_OPEN:
            smax=(open[ArrayMaximum(open,bar,FiboPeriod)]+high[ArrayMaximum(high,bar,FiboPeriod)])/2;
            smin=(open[ArrayMinimum(open,bar,FiboPeriod)]+low[ArrayMinimum(low,bar,FiboPeriod)])/2;
            break;
            //---
         case HIGH_LOW_CLOSE:
            smax=(close[ArrayMaximum(close,bar,FiboPeriod)]+high[ArrayMaximum(high,bar,FiboPeriod)])/2;
            smin=(close[ArrayMinimum(close,bar,FiboPeriod)]+low[ArrayMinimum(low,bar,FiboPeriod)])/2;
            break;
            //---
         case OPEN_HIGH_LOW:
            smax=open[ArrayMinimum(open,bar,FiboPeriod)];
            smin=open[ArrayMaximum(open,bar,FiboPeriod)];
            break;
            //---
         case CLOSE_HIGH_LOW:
            smax=close[ArrayMaximum(close,bar,FiboPeriod)];
            smin=close[ArrayMinimum(close,bar,FiboPeriod)];
            break;
        }
      sdiff=smax-smin;
      Ind[0].m_UpBuffer[bar]=smax;
      Ind[0].m_DnBuffer[bar]=Ind[1].m_UpBuffer[bar]=smin+sdiff*Level1;
      Ind[1].m_DnBuffer[bar]=Ind[2].m_UpBuffer[bar]=smin+sdiff*Level2;
      Ind[2].m_DnBuffer[bar]=Ind[3].m_UpBuffer[bar]=smin+sdiff*Level3;
      Ind[3].m_DnBuffer[bar]=Ind[4].m_UpBuffer[bar]=smin+sdiff*Level4;
      Ind[4].m_DnBuffer[bar]=Ind[5].m_UpBuffer[bar]=smin+sdiff*Level5;
      Ind[5].m_DnBuffer[bar]=smin;
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
