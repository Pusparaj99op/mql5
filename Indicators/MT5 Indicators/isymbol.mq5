//+------------------------------------------------------------------+
//|                                                      iSymbol.mq5 |
//|                                               Copyright 2012, iC |
//|                                             http://icreator.biz/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, iC"
#property link      "http://icreator.biz/"
#property version   "0.10"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_type1   DRAW_BARS
#property indicator_color1  clrCrimson
//+-------------------------------------------------------- enums ---+
enum CYesNo { Yes=-1,No=1 };
//+------------------------------------------------------- inputs ---+
input string _InpInst="EURUSD"; // Symbol
input CYesNo _InpInvert=No;     // Invert
input CYesNo _InpScale=No;      // Scale fix
string _Inst;  
CYesNo _Invert=No;      
CYesNo _ScaleFix=No;
//+------------------------------------------------------ defines ---+
const int REDRAW=0;
const string TC=IntegerToString(GetTickCount());
const string OBJ_NAME="PriceDiffLabel"+TC;
const string OBJ_INVERT="ObjInvert"+TC;
const string OBJ_SCALE="ObjScale"+TC;
const string OBJ_INST="ObjSymbol"+TC;
const string OBJ_INST_TIP="ObjSymbolTip"+TC;
const string OBJ_FREEZE="ObjFreeze"+TC;
const string OBJ_BACK="ObjBackgroung"+TC;
const string OBJ_BACK2="ObjBack2"+TC;
const string WH=IntegerToString(ChartGetInteger(0,CHART_WINDOW_HANDLE));
const string COUNT="Count"+WH;
const string POSITION="Position"+WH;
//+--------------------------------------------- global variables ---+
double OBuf[],HBuf[],LBuf[],CBuf[];
CYesNo _freeze=No;
datetime _startTime=0;
datetime _endTime=0;
int _lastChoose=0;
int _first,_count;
string names[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0,OBuf,INDICATOR_DATA);
    SetIndexBuffer(1,HBuf,INDICATOR_DATA);
    SetIndexBuffer(2,LBuf,INDICATOR_DATA);
    SetIndexBuffer(3,CBuf,INDICATOR_DATA);
    IndicatorSetInteger(INDICATOR_DIGITS,_Digits);    
    PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
    if(!SymbolSelect(_InpInst,true))
    {
        Print("Wrong symbol.");
        return -1;
    } 
    _Inst=_InpInst;
    _Invert=_InpInvert;
    _ScaleFix=_InpScale;
    
    
    GlobalVariableSet(COUNT,GlobalVariableGet(COUNT)+1);
    GlobalVariableSet(POSITION,0);
    ObjCreate();    
    EventChartCustom(0,0,0,0,NULL);
    return 0;
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectDelete(0,OBJ_INVERT);
    ObjectDelete(0,OBJ_FREEZE);
    ObjectDelete(0,OBJ_SCALE);
    ObjectDelete(0,OBJ_INST);
    ObjectDelete(0,OBJ_INST_TIP);
    ObjectDelete(0,OBJ_BACK);
    ObjectDelete(0,OBJ_BACK2);
    if(GlobalVariableGet(COUNT)==1)
        GlobalVariableDel(COUNT);
    else
        GlobalVariableSet(COUNT,GlobalVariableGet(COUNT)-1);
    GlobalVariableDel(POSITION);
    EventChartCustom(0,0,0,0,NULL);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,         
                const int begin,               
                const double &in[])
{
    _Invert=CYesNo(ObjectGetInteger(0,OBJ_INVERT,OBJPROP_STATE)==0?1:-1);
    _ScaleFix=CYesNo(ObjectGetInteger(0,OBJ_SCALE,OBJPROP_STATE)==0?1:-1);
    _freeze=CYesNo(ObjectGetInteger(0,OBJ_FREEZE,OBJPROP_STATE)==0?1:-1);
    _Inst=ObjectGetString(0,OBJ_INST,OBJPROP_TEXT);

    ObjectSetInteger(0,OBJ_BACK,OBJPROP_BGCOLOR,PlotIndexGetInteger(0,PLOT_LINE_COLOR));
    if(_freeze==No)
    {
        int first=(int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR);        
        int count=(int)ChartGetInteger(0,CHART_VISIBLE_BARS);
        if(count-1>first)
            return 0;    
        _first=first;
        _count=count; 
    }  
    else if(_freeze==Yes)
    {           
        if(_lastChoose!=No)
            _first=_first+_first+1-_count;     
        _count=_first+1; 
    }      
    _lastChoose=_freeze;
    
    if(in[0]!=EMPTY_VALUE)
    {
        if(_ScaleFix==Yes)
            ChartSetInteger(0,CHART_SCALEFIX,0,true);
        else
            ChartSetInteger(0,CHART_SCALEFIX,0,false);
    }
    else if(in[2]!=EMPTY_VALUE)
    {
        if(_freeze==Yes)
        {  
            ObjectSetInteger(0,OBJ_FREEZE,OBJPROP_STATE,true);   
            ArrayInitialize(OBuf,0.0);
            ArrayInitialize(HBuf,0.0);
            ArrayInitialize(LBuf,0.0);
            ArrayInitialize(CBuf,0.0);
        }
        else
            ObjectSetInteger(0,OBJ_FREEZE,OBJPROP_STATE,false);
    }    
    else if(in[1]==EMPTY_VALUE &&
        in[3]==EMPTY_VALUE &&
        in[4]==EMPTY_VALUE)
        return rates_total;   

    double d=0;
    double tick_size=SymbolInfoDouble(_Inst,SYMBOL_POINT);
    double tick_size2=SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
    double min=DBL_MAX,max=0;
    double lOp=0;
    int cnt=-1;
    datetime prevTime=0;
    datetime time[];
    double high[],low[];
    double open[1];
    MqlRates rt[1];
    
    CopyOpen(_Symbol,0,_first,1,open);
    CopyTime(_Symbol,0,_first-_count+1,_count,time);
    CopyHigh(_Symbol,0,_first-_count+1,_count,high);
    CopyLow(_Symbol,0,_first-_count+1,_count,low);
    for(int i=rates_total-_first-1;i<rates_total-_first+_count-1;i++)
    {       
        CopyRates(_Inst,0,time[++cnt],1,rt); 
        if(rt[0].time==prevTime)
        {
            OBuf[i]=CBuf[i-1];
            HBuf[i]=CBuf[i-1];
            LBuf[i]=CBuf[i-1];
            CBuf[i]=CBuf[i-1];
            continue;
        }                                             
        if(cnt>0) d+=(rt[0].open-lOp)*_Invert/tick_size*tick_size2;
        lOp=rt[0].open;
        OBuf[i]=open[0];
        HBuf[i]=open[0];
        LBuf[i]=open[0];
        CBuf[i]=open[0];
        if(prevTime!=0)
        {
            OBuf[i]+=d;
            HBuf[i]+=d+(rt[0].high-rt[0].open)*_Invert/tick_size*tick_size2;
            LBuf[i]+=d+(rt[0].low-rt[0].open)*_Invert/tick_size*tick_size2;
            CBuf[i]+=d+(rt[0].close-rt[0].open)*_Invert/tick_size*tick_size2;
        }
        prevTime=rt[0].time;
        
        if(high[cnt]>max) max=high[cnt];
        if(HBuf[i]>max) max=HBuf[i];
        if(LBuf[i]>max) max=LBuf[i];
        if(low[cnt]<min) min=low[cnt];
        if(HBuf[i]<min) min=HBuf[i];
        if(LBuf[i]<min) min=LBuf[i];
    }  
    if(_ScaleFix==Yes)
    {   
        ChartSetDouble(0,CHART_FIXED_MAX,max);
        ChartSetDouble(0,CHART_FIXED_MIN,min);
    }
    return rates_total;
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    static datetime lastTime=0;
    static bool b=true;
    static int lastH=0;
    double arr[]={EMPTY_VALUE,EMPTY_VALUE,EMPTY_VALUE,EMPTY_VALUE,EMPTY_VALUE};
    
    switch(id)
    {
    case CHARTEVENT_CUSTOM:
        lastH=0;
        arr[4]=REDRAW;
        break;
    
    case CHARTEVENT_OBJECT_CLICK:
        b=false;        
        if(StringCompare(sparam,OBJ_SCALE)==0) 
            arr[0]=(double)ObjectGetInteger(0,OBJ_SCALE,OBJPROP_STATE);
        if(StringCompare(sparam,OBJ_INVERT)==0) 
            arr[1]=(double)ObjectGetInteger(0,OBJ_INVERT,OBJPROP_STATE);
        if(StringCompare(sparam,OBJ_FREEZE)==0) 
            arr[2]=(double)ObjectGetInteger(0,OBJ_FREEZE,OBJPROP_STATE);
        arr[4]=REDRAW;
        break;
    
    case CHARTEVENT_OBJECT_ENDEDIT:
        if(StringCompare(sparam,OBJ_INST)==0) 
        {  
            string s=ObjectGetString(0,OBJ_INST,OBJPROP_TEXT);
            if(SymbolSelect(s,true))
                arr[3]=true;
            else
                ObjectSetString(0,OBJ_INST,OBJPROP_TEXT,_Inst);
            arr[4]=REDRAW;                   
        }
        break;
        
    case CHARTEVENT_CLICK:
        if(!b)
        {
            b=true;
            return;
        }
        if(GetTickCount()-lastTime>250)
        {
            lastTime=GetTickCount();
            return;
        }
        else 
        {
            arr[2]=(double)ObjectGetInteger(0,OBJ_FREEZE,OBJPROP_STATE);
            for(int i=0;i<ObjectsTotal(0,0,OBJ_BUTTON);i++)
                if(ObjectGetString(0,ObjectName(0,i,0,OBJ_BUTTON),OBJPROP_TEXT)=="Freeze")
                    ObjectSetInteger(0,ObjectName(0,i,0,OBJ_BUTTON),OBJPROP_STATE,_freeze<0?false:true);
        }
        
    case CHARTEVENT_CHART_CHANGE:
        arr[4]=REDRAW;     
        break;
    }    
    if(arr[4]==REDRAW)
    {     
        if(lastH!=ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS))
            ObjRePos();
        lastH=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
        OnCalculate(Bars(_Symbol,0),0,0,arr);        
        ChartRedraw();  
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjCreate()
{       
    if(ObjectFind(0,OBJ_BACK)<0)
    {            
        ObjectCreate(0,OBJ_BACK,OBJ_RECTANGLE_LABEL,0,0,0);
        ObjectCreate(0,OBJ_BACK,OBJ_RECTANGLE_LABEL,0,0,0);
        ObjectSetInteger(0,OBJ_BACK,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(0,OBJ_BACK,OBJPROP_XDISTANCE,0);  
        ObjectSetInteger(0,OBJ_BACK,OBJPROP_XSIZE,357);
        ObjectSetInteger(0,OBJ_BACK,OBJPROP_YSIZE,26);        
        ObjectSetInteger(0,OBJ_BACK,OBJPROP_BACK,true);
    }      
    if(ObjectFind(0,OBJ_BACK2)<0)
    {    
        ObjectCreate(0,OBJ_BACK2,OBJ_RECTANGLE_LABEL,0,0,0);
        ObjectSetInteger(0,OBJ_BACK2,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(0,OBJ_BACK2,OBJPROP_XDISTANCE,229);  
        ObjectSetInteger(0,OBJ_BACK2,OBJPROP_XSIZE,125);
        ObjectSetInteger(0,OBJ_BACK2,OBJPROP_YSIZE,22);
        ObjectSetInteger(0,OBJ_BACK2,OBJPROP_BGCOLOR,clrWhite);
    } 
    if(ObjectFind(0,OBJ_SCALE)<0)
    {    
        ObjectCreate(0,OBJ_SCALE,OBJ_BUTTON,0,0,0);
        ObjectSetInteger(0,OBJ_SCALE,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(0,OBJ_SCALE,OBJPROP_XDISTANCE,2);        
        ObjectSetInteger(0,OBJ_SCALE,OBJPROP_FONTSIZE,9);
        ObjectSetString(0,OBJ_SCALE,OBJPROP_TEXT,"Scale fix");
        ObjectSetInteger(0,OBJ_SCALE,OBJPROP_XSIZE,75);
        ObjectSetInteger(0,OBJ_SCALE,OBJPROP_YSIZE,22);
        ObjectSetInteger(0,OBJ_SCALE,OBJPROP_STATE,_InpScale==Yes?true:false);
    }
    if(ObjectFind(0,OBJ_INVERT)<0)
    {        
        ObjectCreate(0,OBJ_INVERT,OBJ_BUTTON,0,0,0);
        ObjectSetInteger(0,OBJ_INVERT,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(0,OBJ_INVERT,OBJPROP_XDISTANCE,77);        
        ObjectSetInteger(0,OBJ_INVERT,OBJPROP_FONTSIZE,9);
        ObjectSetString(0,OBJ_INVERT,OBJPROP_TEXT,"Invert");
        ObjectSetInteger(0,OBJ_INVERT,OBJPROP_XSIZE,75);
        ObjectSetInteger(0,OBJ_INVERT,OBJPROP_YSIZE,22);
        ObjectSetInteger(0,OBJ_INVERT,OBJPROP_STATE,_InpInvert==Yes?true:false);
    }
    if(ObjectFind(0,OBJ_FREEZE)<0)
    {     
        ObjectCreate(0,OBJ_FREEZE,OBJ_BUTTON,0,0,0);
        ObjectSetInteger(0,OBJ_FREEZE,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(0,OBJ_FREEZE,OBJPROP_XDISTANCE,152);        
        ObjectSetInteger(0,OBJ_FREEZE,OBJPROP_FONTSIZE,9);
        ObjectSetString(0,OBJ_FREEZE,OBJPROP_TEXT,"Freeze");
        ObjectSetInteger(0,OBJ_FREEZE,OBJPROP_XSIZE,75);
        ObjectSetInteger(0,OBJ_FREEZE,OBJPROP_YSIZE,22);
    }
    if(ObjectFind(0,OBJ_INST)<0)
    {             
        ObjectCreate(0,OBJ_INST,OBJ_EDIT,0,0,0);
        ObjectSetInteger(0,OBJ_INST,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(0,OBJ_INST,OBJPROP_XDISTANCE,278);        
        ObjectSetInteger(0,OBJ_INST,OBJPROP_FONTSIZE,9);        
        ObjectSetInteger(0,OBJ_INST,OBJPROP_XSIZE,75);
        ObjectSetInteger(0,OBJ_INST,OBJPROP_YSIZE,18);
        ObjectSetInteger(0,OBJ_INST,OBJPROP_BGCOLOR,clrWhite);
        ObjectSetInteger(0,OBJ_INST,OBJPROP_BORDER_COLOR,clrWhite);
        ObjectSetInteger(0,OBJ_INST,OBJPROP_COLOR,clrBlack);      
        
        ObjectCreate(0,OBJ_INST_TIP,OBJ_LABEL,0,0,0);
        ObjectSetInteger(0,OBJ_INST_TIP,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(0,OBJ_INST_TIP,OBJPROP_XDISTANCE,235);        
        ObjectSetInteger(0,OBJ_INST_TIP,OBJPROP_FONTSIZE,9);
        ObjectSetString(0,OBJ_INST_TIP,OBJPROP_TEXT,"Symbol:");
        ObjectSetInteger(0,OBJ_INST_TIP,OBJPROP_COLOR,clrGray);    
        ObjectSetString(0,OBJ_INST,OBJPROP_TEXT,_InpInst);
    }  
}
void ObjRePos()
{       
    int yPos=(int)GlobalVariableGet(POSITION);
    int height=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS)-yPos*27;
    ObjectSetInteger(0,OBJ_SCALE,OBJPROP_YDISTANCE,height-25);
    ObjectSetInteger(0,OBJ_INVERT,OBJPROP_YDISTANCE,height-25);
    ObjectSetInteger(0,OBJ_FREEZE,OBJPROP_YDISTANCE,height-25);
    ObjectSetInteger(0,OBJ_INST_TIP,OBJPROP_YDISTANCE,height-22);
    ObjectSetInteger(0,OBJ_INST,OBJPROP_YDISTANCE,height-23);    
    ObjectSetInteger(0,OBJ_BACK,OBJPROP_YDISTANCE,height-27); 
    ObjectSetInteger(0,OBJ_BACK2,OBJPROP_YDISTANCE,height-25);
    if(yPos==GlobalVariableGet(COUNT)-1)
        GlobalVariableSet(POSITION,0);
    else    
        GlobalVariableSet(POSITION,++yPos);
}
//+------------------------------------------------------------------+