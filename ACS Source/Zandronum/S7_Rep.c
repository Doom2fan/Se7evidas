#INCLUDE "zcommon.acs"
#LIBRARY "S7_Rep"

// Defines
#DEFINE MAXPLAYERS 64

// Includes
#INCLUDE "../commonFuncs.h"
#INCLUDE "S7_Rep/Shop System.h"

// Defines

// Highest script num ID: 800

#DEFINE S7_Enter_Zandronum 800
script S7_Enter_Zandronum (void) CLIENTSIDE {
    ConsoleCommand ("S7_Zandronum");
}