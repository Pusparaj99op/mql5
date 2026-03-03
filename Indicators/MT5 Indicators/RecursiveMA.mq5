//+------------------------------------------------------------------+
//|                                                  RecursiveMA.mq5 |
//|                                                         Galafron |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2009-2022, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property version     "1.1"
#property description "Recursive Moving Average Unlimited"
//+------------------------------------------------------------------+
//| properties                                                       |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_color1  HotPink
#property indicator_width2  1
#property indicator_label2  "Recursive MA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  Yellow
#property indicator_width2  1
#property indicator_label2  "Trigger"
#property indicator_applied_price PRICE_CLOSE
//+------------------------------------------------------------------+
//| input                                                            |
//+------------------------------------------------------------------+
enum  ENUM_MA_METHOD_EXT { MOD_EMA, MOD_SMMA };
input int                InpPeriodMA=2;                 // period
input int                InpIteration=20;               // number of iterations
input ENUM_MA_METHOD_EXT InpMethodMA=MOD_EMA;           // Moving average method
input bool               inpDisplaySignal;              // display arrow
//+------------------------------------------------------------------+
//| global                                                           |
//+------------------------------------------------------------------+
double                  XemaBuffer[], TriggerBuffer[];
double                  Ema[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
   ObjectsDeleteAll(0,MQLInfoString(MQL_PROGRAM_NAME),0);
//--- indicator buffers mapping
   SetIndexBuffer(0,XemaBuffer,INDICATOR_DATA);
//--- indicator buffers mapping
   SetIndexBuffer(1,TriggerBuffer,INDICATOR_DATA);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,0);
//--- name for indicator label
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,0);
//--- name for indicator label
   IndicatorSetString(INDICATOR_SHORTNAME,"Recursive MA");
//--- name for index label
   PlotIndexSetString(0,PLOT_LABEL,
   "Recursive EMA("+string(InpPeriodMA)+","+
   string(InpIteration)+","+
   EnumToString((ENUM_MA_METHOD_EXT)InpMethodMA)+","+
   string(inpDisplaySignal)+")");
//--- initialization done
   ArrayResize(Ema,InpIteration);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
  { 
   ObjectsDeleteAll(0,MQLInfoString(MQL_PROGRAM_NAME),0);
//--- The first way to get a deinitialization reason code 
   Print(__FUNCTION__," Deinitialization reason code = ",reason); 
//--- The second way to get a deinitialization reason code 
   Print(__FUNCTION__," _UninitReason = ",getUninitReasonText(_UninitReason)); 
//--- The third way to get a deinitialization reason code   
   Print(__FUNCTION__," UninitializeReason() = ",getUninitReasonText(UninitializeReason())); 
  } 
//+------------------------------------------------------------------+ 
//| Return a textual description of the deinitialization reason code | 
//+------------------------------------------------------------------+ 
string getUninitReasonText(int reasonCode) 
  { 
   string text=""; 
//--- 
   switch(reasonCode) 
     { 
      case REASON_ACCOUNT: 
         text="Account was changed";break; 
      case REASON_CHARTCHANGE: 
         text="Symbol or timeframe was changed";break; 
      case REASON_CHARTCLOSE: 
         text="Chart was closed";break; 
      case REASON_PARAMETERS: 
         text="Input-parameter was changed";break; 
      case REASON_RECOMPILE: 
         text="Program "+__FILE__+" was recompiled";break; 
      case REASON_REMOVE: 
         text="Program "+__FILE__+" was removed from chart";break; 
      case REASON_TEMPLATE: 
         text="New template was applied to chart";break; 
      default:text="Another reason"; 
     } 
//--- 
   return text; 
  }//+------------------------------------------------------------------+
//| main method                                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- check for data
   if(rates_total<3*InpPeriodMA-3)
      return(0);
//--- init array in case of restart
   int limit=0;
   if(prev_calculated==0)
     {
      ArrayInitialize(XemaBuffer,0);
      ArrayInitialize(TriggerBuffer,0);
      for(int i = 0 ; i < ArraySize(Ema) ; i++)
         Ema[i]=Open[0];
     }
   else
      limit=prev_calculated-1;
//--- filter in open prices
   if(rates_total==prev_calculated)
      return(rates_total);
//--- calculate MA
   for(int i = limit; i < rates_total; i++)
      if(i>0)
        {
         for(int j = 0 ; j < InpIteration ; j++)
           {
//--- init loop sum up array
            if(j == 0)
               if(InpMethodMA == MOD_EMA)
                  Ema [j] = Open [ i ]   * 2.0 / (InpPeriodMA + 1.0) + Ema [ j ] * (1 - 2.0 / (InpPeriodMA + 1.0)) ;
               else
                  Ema [j] =(Open [ i ]     + Ema [ j ] * (MathMin(i, InpPeriodMA) - 1.0)) / MathMin(i, InpPeriodMA) ;
//--- fill loop sum up array
            else
               if(InpMethodMA == MOD_EMA)
                  Ema [j] = Ema [ j - 1 ] * 2.0 / (InpPeriodMA + 1.0) + Ema [ j ] * (1 - 2.0 / (InpPeriodMA + 1.0)) ;
               else
                  Ema [j] =(Ema [ j - 1 ] + Ema [ j ] * (MathMin(i, InpPeriodMA) - 1.0)) / MathMin(i, InpPeriodMA) ;
//--- trigger sum up array
            if(j == 0)
               TriggerBuffer[i]  = (InpIteration - j) * Ema [j] / InpIteration / (InpIteration + 1.0) * 2.0;
            else
               TriggerBuffer[i] += (InpIteration - j) * Ema [j] / InpIteration / (InpIteration + 1.0) * 2.0;
          }
         XemaBuffer[i] = Ema [ InpIteration - 1 ] ;
//--- look for signal
         if(i>1&&inpDisplaySignal)
            if(TriggerBuffer[i-0] > XemaBuffer[i-0] && TriggerBuffer[i-1] < XemaBuffer[i-1])
               if(!ArrowCreate(0,MQLInfoString(MQL_PROGRAM_NAME)+"_ArrowBuy_"+(string)i,0,Time[i],Open[i]+SymbolInfoInteger(NULL,SYMBOL_SPREAD)*_Point,clrLime))
                  return(rates_total);
               else{}
            else
            if(TriggerBuffer[i-0] < XemaBuffer[i-0] && TriggerBuffer[i-1] > XemaBuffer[i-1])
               if(!ArrowCreate(0,MQLInfoString(MQL_PROGRAM_NAME)+"_ArrowSell_"+(string)i,0,Time[i],Open[i],clrRed))
                  return(rates_total);
        }
//---filter in open price
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| display arrpow                                                   |
//+------------------------------------------------------------------+
bool ArrowCreate(const long               chart_ID=0,        // chart's ID
                 const string          name="ArrowBuy",   // sign name
                 const int             sub_window=0,      // subwindow index
                 datetime              time=0,            // anchor point time
                 double                price=0,           // anchor point price
                 const color           clr=C'3,95,172',   // sign color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style (when highlighted)
                 const int             width=3,           // line size (when highlighted)
                 const bool            back=false,        // in the background
                 const bool            selection=false,   // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create the sign
   if(!ObjectCreate(chart_ID,name,(clr==clrLime? OBJ_ARROW_BUY:OBJ_ARROW_SELL),sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create \"Buy\" sign! Error code = ",GetLastError());
      return(false);
     }
//--- set a sign color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set a line style (when highlighted)
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set a line size (when highlighted)
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the sign by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
   }
