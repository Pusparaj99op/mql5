//+-------------------------------------------------------------------------------------+
//|                                                             Minions.ServerClock.mq5 |
//| (CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License|
//|                                                          http://www.MinionsLabs.com |
//+-------------------------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Descriptors                                                      |
//+------------------------------------------------------------------+
#property copyright   "www.MinionsLabs.com"
#property link        "http://www.MinionsLabs.com"
#property version     "1.0"
#property description "Minions showing the Server Time in an unobtrusive way"
#property description " "
#property description "(CC) Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License"


//+------------------------------------------------------------------+
//| Indicator Settings                                               |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots   0


//+------------------------------------------------------------------+
// ENUMerations
//+------------------------------------------------------------------+
enum ML_WINPOSITION {
     ML_WINPOSITION_UPPER_LEFT=0,               //Upper Left of the chart
     ML_WINPOSITION_UPPER_CENTER=1,             //Upper Center of the chart
     ML_WINPOSITION_UPPER_RIGHT=2,              //Upper Right of the chart
     ML_WINPOSITION_LOWER_LEFT=3,               //Lower Left of the chart
     ML_WINPOSITION_LOWER_CENTER=4,             //Lower Center of the chart
     ML_WINPOSITION_LOWER_RIGHT=5               //Lower Right of the chart
};
enum ML_FONTTYPE {
     ML_FONTTYPE_ARIAL=0,                       //Arial
     ML_FONTTYPE_ARIALBLACK=1,                  //Arial Black
     ML_FONTTYPE_VERDANA=2,                     //Verdana
     ML_FONTTYPE_TAHOMA=3,                      //Tahoma
     ML_FONTTYPE_COURIERNEW=4,                  //Courier New
     ML_FONTTYPE_LUCIDACONSOLE=5                //Lucida Console

};


//+------------------------------------------------------------------+
// Inputs from User Interface                                        |
//+------------------------------------------------------------------+
input color           inpTextColor=C'80,80,0';                   // clock Text color
input ML_FONTTYPE     inpFontType=1;                                 // Font Type
input int             inpFontSize=24;                                // clock Font size
input ML_WINPOSITION  inpWindowPosition=ML_WINPOSITION_LOWER_LEFT;   // clock position
input int             inpXOffSet=0;                                  // Reposition Clock Offset on X axis (+/-)
input int             inpYOffSet=0;                                  // Reposition Clock Offset on Y axis (+/-)


//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
string clockName = "MLabs_ServerClock";        // Namespacing the clock...



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()   {

    // creates the Clock...
    ObjectCreate(     0, clockName, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger( 0, clockName, OBJPROP_COLOR, inpTextColor );
    ObjectSetInteger( 0, clockName, OBJPROP_FONTSIZE, inpFontSize );
    ObjectSetInteger( 0, clockName, OBJPROP_BACK,true);

    if (inpFontType==ML_FONTTYPE_ARIAL)         {  ObjectSetString(  0, clockName, OBJPROP_FONT, "Arial" );          }
    if (inpFontType==ML_FONTTYPE_ARIALBLACK)    {  ObjectSetString(  0, clockName, OBJPROP_FONT, "Arial Black" );    }
    if (inpFontType==ML_FONTTYPE_VERDANA)       {  ObjectSetString(  0, clockName, OBJPROP_FONT, "Verdana" );        }
    if (inpFontType==ML_FONTTYPE_TAHOMA)        {  ObjectSetString(  0, clockName, OBJPROP_FONT, "Tahoma" );         }
    if (inpFontType==ML_FONTTYPE_COURIERNEW)    {  ObjectSetString(  0, clockName, OBJPROP_FONT, "Courier New" );    }
    if (inpFontType==ML_FONTTYPE_LUCIDACONSOLE) {  ObjectSetString(  0, clockName, OBJPROP_FONT, "Lucida Console" ); }
    

    if (inpWindowPosition==ML_WINPOSITION_UPPER_LEFT) {
        ObjectSetInteger( 0, clockName, OBJPROP_CORNER, CORNER_LEFT_UPPER );
        ObjectSetInteger( 0, clockName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER );
        ObjectSetInteger( 0, clockName, OBJPROP_XDISTANCE, inpXOffSet );
        ObjectSetInteger( 0, clockName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_UPPER_RIGHT) {
        ObjectSetInteger( 0, clockName, OBJPROP_CORNER, CORNER_RIGHT_UPPER );
        ObjectSetInteger( 0, clockName, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER );
        ObjectSetInteger( 0, clockName, OBJPROP_XDISTANCE, inpXOffSet );
        ObjectSetInteger( 0, clockName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_UPPER_CENTER) {
        ObjectSetInteger( 0, clockName, OBJPROP_CORNER, CORNER_LEFT_UPPER );
        ObjectSetInteger( 0, clockName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER );
        ObjectSetInteger( 0, clockName, OBJPROP_XDISTANCE, inpXOffSet+ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0)/2 );
        ObjectSetInteger( 0, clockName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_LOWER_LEFT) {
        ObjectSetInteger( 0, clockName, OBJPROP_CORNER, CORNER_LEFT_LOWER );
        ObjectSetInteger( 0, clockName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER );
        ObjectSetInteger( 0, clockName, OBJPROP_XDISTANCE, inpXOffSet );
        ObjectSetInteger( 0, clockName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_LOWER_RIGHT) {
        ObjectSetInteger( 0, clockName, OBJPROP_CORNER, CORNER_RIGHT_LOWER );
        ObjectSetInteger( 0, clockName, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER );
        ObjectSetInteger( 0, clockName, OBJPROP_XDISTANCE, inpXOffSet );
        ObjectSetInteger( 0, clockName, OBJPROP_YDISTANCE, inpYOffSet);

    } else if (inpWindowPosition==ML_WINPOSITION_LOWER_CENTER) {
        ObjectSetInteger( 0, clockName, OBJPROP_CORNER, CORNER_LEFT_LOWER );
        ObjectSetInteger( 0, clockName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER );
        ObjectSetInteger( 0, clockName, OBJPROP_XDISTANCE, inpXOffSet+ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0)/2 );
        ObjectSetInteger( 0, clockName, OBJPROP_YDISTANCE, inpYOffSet);

    }

    ChartRedraw();
}


//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit( const int reason ) {
    ObjectDelete( 0, clockName );
}



//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate( const int        rates_total,       // price[] array size
                 const int        prev_calculated,   // number of handled bars at the previous call
                 const int        begin,             // index number in the price[] array meaningful data starts from
                 const double&    price[]            // array of values for calculation
                ) {

    // updates the time...  Just that...
    ObjectSetString( 0, clockName, OBJPROP_TEXT, TimeToString( TimeCurrent(), TIME_SECONDS) );

   return(rates_total);
  }
//+------------------------------------------------------------------+
