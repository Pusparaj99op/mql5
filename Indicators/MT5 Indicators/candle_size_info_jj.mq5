//--- descrição
#property description "Script cria objeto gráfico de \"Texto\"."
//--- janela de exibição dos parâmetros de entrada durante inicialização do script
#property script_show_inputs


//--- entrada de parâmetros do script
input int               IHistoryBars=25;          // Check Historical Data
input string            InpFont="Tahoma";       // Font Type
input int               InpFontSize=7;          // Size of fonts
input color             UpColor=clrGold;         // Cor Up
input color             DwColor=clrRoyalBlue;         // Cor Dw
input color             HLColor=clrAqua;         // Cor Center
input bool              InpBack=false;           // Objeto de fundo
input bool              InpSelection=false;      // Destaque para mover
input bool              InpHidden=true;          // Ocultar na lista de objetos
input bool              WithDigit=true;          // Ocultar na lista de objetos
input long              InpZOrder=0;             // Prioridade para clique do mouse


int digits=0,extradig=0;

double            InpAngle=0.0;           // Ângulo de inclinação em graus
ENUM_ANCHOR_POINT InpAnchor=ANCHOR_CENTER; // Tipo de ancoragem
double   gBars=0;
double   gTotalRates=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   digits=MathPow(10,_Digits-extradig);
   if(WithDigit) extradig=1;

  }
//+------------------------------------------------------------------+
//| Mover ponto de ancoragem                                         |
//+------------------------------------------------------------------+
bool TextMove(const long   chart_ID=0,  // ID do gráfico
              const string name="Text", // nome do objeto
              datetime     time=0,      // coordenada do ponto de ancoragem do tempo
              double       price=0)     // coordenada do ponto de ancoragem do preço
  {
//--- se a posição do ponto não está definida, mover para a barra atual tendo o preço Bid
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- redefine o valor de erro
   ResetLastError();
//--- mover o ponto de ancoragem
   if(!ObjectMove(chart_ID,name,0,time,price))
     {
      Print(__FUNCTION__,
            ": falha ao mover o ponto de ancoragem! Código de erro = ",GetLastError());
      return(false);
     }
//--- sucesso na execução
   return(true);
  }
//+------------------------------------------------------------------+
//| Verificar valores de ponto de ancoragem e definir valores padrão |
//| para aqueles vazios                                              |
//+------------------------------------------------------------------+
void ChangeTextEmptyPoint(datetime &time,double &price)
  {
//--- se o tempo do ponto não está definido, será na barra atual
   if(!time)
      time=TimeCurrent();
//--- se o preço do ponto não está definido, ele terá valor Bid
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ClearMyObjects();
   Print("Deinit Value Chart, reason = "+IntegerToString(reason));
  }
//+------------------------------------------------------------------+
//| Value Chart                                                      | 
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

//--- definir a forma como muitas vezes os textos serão exibidos
   int scale=(int)ChartGetInteger(0,CHART_SCALE);
   int bars=(int)ChartGetInteger(0,CHART_VISIBLE_BARS)+3;
   double value;
   digits=MathPow(10,_Digits-extradig);

//--- definir o passo
   int step=1;
   switch(scale)
     {
      case 0:
         step=12;
         break;
      case 1:
         step=6;
         break;
      case 2:
         step=4;
         break;
      case 3:
         step=2;
         break;
     }
   gTotalRates=rates_total;
   gBars=bars;
   for(int i=rates_total-1;i>rates_total-bars;i-=step) 
     {
      if(Close[i]>Open[i])
        {
         // bullish candle
         value=(Close[i]-Open[i])*digits;
         //Print(Close[i]-Open[i], "->", Close[i]-Open[i]*digits);

         TextCreate(0,"Text_"+(string)i+(string)PERIOD_CURRENT,0,Time[i],(Close[i]+Open[i])/2,DoubleToString(value,extradig),InpFont,InpFontSize,
                    UpColor,InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder);

         value=(Open[i]-Low[i]) *digits;
         if(!TextCreate(0,"TextL_"+(string)i+(string)PERIOD_CURRENT,0,Time[i],Low[i],DoubleToString(value,extradig),InpFont,InpFontSize,
            HLColor,InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder)) {       return 0;     }

         value=(High[i]-Close[i]) *digits;
         if(!TextCreate(ChartID(),"TextH_"+(string)i+(string)PERIOD_CURRENT,0,Time[i],High[i],DoubleToString(value,extradig),InpFont,InpFontSize,
            HLColor,InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder)) {       return 0;     }

           } else {

         value=(Open[i]-Close[i]) *digits;
         if(!TextCreate(ChartID(),"Text_"+(string)i+(string)PERIOD_CURRENT,0,Time[i],(Close[i]+Open[i])/2,DoubleToString(value,extradig),InpFont,InpFontSize,
            DwColor,-InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder)) {      return 0;      }

         value=(Close[i]-Low[i]) *digits;
         if(!TextCreate(ChartID(),"TextL_"+(string)i+(string)PERIOD_CURRENT,0,Time[i],Low[i],DoubleToString(value,extradig),InpFont,InpFontSize,
            HLColor,InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder)) {       return 0;     }

         value=(High[i]-Open[i]) *digits;
         if(!TextCreate(ChartID(),"TextH_"+(string)i+(string)PERIOD_CURRENT,0,Time[i],High[i],DoubleToString(value,extradig),InpFont,InpFontSize,
            HLColor,InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder)) {       return 0;     }
        }

     }
   ChartRedraw();
   return 0;
  }
//+------------------------------------------------------------------+
//|  Trace Arrow Function                                            |
//+------------------------------------------------------------------+
void Trace(string name,int sens,double price,datetime time,color couleur)
  {
   ObjectCreate(0,name,OBJ_ARROW,0,time,price);
   if(sens==1)
      ObjectSetInteger(0,name,OBJPROP_ARROWCODE,233);
   if(sens==-1)
      ObjectSetInteger(0,name,OBJPROP_ARROWCODE,234);
   ObjectSetInteger(0,name,OBJPROP_COLOR,couleur);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,5);
  }
//+------------------------------------------------------------------+
//|   Delete Arrow Function                                          |
//+------------------------------------------------------------------+  
void ClearMyObjects() 
  {
   string name;
   int scale=(int)ChartGetInteger(0,CHART_SCALE);
   int bars=(int)ChartGetInteger(0,CHART_VISIBLE_BARS)+3;
   double value;
   digits=MathPow(10,_Digits-extradig);
   int step=1;
   switch(scale)
     {
      case 0:
         step=12;
         break;
      case 1:
         step=6;
         break;
      case 2:
         step=4;
         break;
      case 3:
         step=2;
         break;
     }
   for(int i=gTotalRates-1;i>gTotalRates-bars;i-=step) 
     {
      if(!TextDelete(ChartID(),"Text_"+(string)i+(string)PERIOD_CURRENT)){}
      if(!TextDelete(ChartID(),"TextH_"+(string)i+(string)PERIOD_CURRENT)){}
      if(!TextDelete(ChartID(),"TextL_"+(string)i+(string)PERIOD_CURRENT)){}
      //--- redesenhar o gráfico
     }
   ChartRedraw();

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Alterar o texto do objeto                                        |
//+------------------------------------------------------------------+
bool TextChange(const long   chart_ID=0,  // ID do Gráfico
                const string name="Text", // nome do objeto
                const string text="Text") // texto
  {
//--- redefine o valor de erro
   ResetLastError();
//--- alterar texto do objeto
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text))
     {
      Print(__FUNCTION__,
            ": falha ao alterar texto! Código de erro = ",GetLastError());
      return(false);
     }
//--- sucesso na execução
   return(true);
  }
//+------------------------------------------------------------------+
//| Excluir objeto Texto                                             |
//+------------------------------------------------------------------+
bool TextDelete(const long   chart_ID=0,  // Id do Gráfico
                const string name="Text") // nome do objeto
  {
//--- redefine o valor de erro
   ResetLastError();
//--- excluir o objeto
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": falha ao excluir o objeto \"Texto\"! Código de erro = ",GetLastError());
      return(false);
     }
//--- sucesso na execução
   return(true);
  }
//+------------------------------------------------------------------+
//| Criando objeto Texto                                             |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // ID do gráfico
                const string            name="Text",              // nome do objeto
                const int               sub_window=0,             // índice da sub-janela
                datetime                time=0,                   // ponto de ancoragem do tempo
                double                  price=0,                  // ponto de ancoragem do preço
                const string            text="Text",              // o próprio texto
                const string            font="Arial",             // fonte
                const int               font_size=10,             // tamanho da fonte
                const color             clr=clrRed,               // cor
                const double            angle=0.0,                // inclinação do texto
                const ENUM_ANCHOR_POINT anchor=ANCHOR_CENTER,// tipo de ancoragem
                const bool              back=false,               // no fundo
                const bool              selection=false,          // destaque para mover
                const bool              hidden=true,              // ocultar na lista de objetos
                const long              z_order=0)                // prioridade para clicar no mouse
  {

   if(ObjectFind(chart_ID,name)==-1) 
     {

      //--- definir as coordenadas de pontos de ancoragem, se eles não estão definidos
      //--- redefine o valor de erro
      ResetLastError();
      //--- criar objeto Texto
      if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price)) 
        {
         Print(__FUNCTION__,
               ": falha ao criar objeto \"Texto\"! Código de erro = ",GetLastError());
         return(false);
        }
      //--- definir o texto
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      //--- definir o texto fonte
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      //--- definir tamanho da fonte
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      //--- definir o ângulo de inclinação do texto
      ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
      //--- tipo de definição de ancoragem
      ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
      ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,ALIGN_CENTER);

      //--- definir cor
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      //--- exibir em primeiro plano (false) ou fundo (true)
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      //--- habilitar (true) ou desabilitar (false) o modo de mover o objeto com o mouse
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      //--- ocultar (true) ou exibir (false) o nome do objeto gráfico na lista de objeto 
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      //--- definir a prioridade para receber o evento com um clique do mouse no gráfico
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
      ObjectSetDouble(chart_ID,name,OBJPROP_PRICE,price);
      ObjectSetInteger(chart_ID,name,OBJPROP_TIME,time);

      //--- sucesso na execução
      return(true);
        } else {
      ChangeTextEmptyPoint(time,price);

      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
      ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
      ObjectSetDouble(chart_ID,name,OBJPROP_PRICE,price);
      ObjectSetInteger(chart_ID,name,OBJPROP_TIME,time);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      //--- definir tamanho da fonte
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,100);

/*ObjectSetString(chart_ID,name,OBJPROP_FONT,Font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,Size);*/
      return (true);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event ID
                  const long& lparam,   // Parameter of type long event
                  const double& dparam, // Parameter of type double event
                  const string& sparam  // Parameter of type string events
                  )
  {
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      ClearMyObjects();
     }

  }
//+------------------------------------------------------------------+
