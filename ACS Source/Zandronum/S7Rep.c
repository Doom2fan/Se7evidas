#INCLUDE "zcommon.acs"
#LIBRARY "S7Rep"

// Defines
#LIBDEFINE MAXPLAYERS 64

// Includes
//#INCLUDE "../commonFuncs.h"
//#INCLUDE "S7Rep/Shop System.h"
#INCLUDE "S7Rep/Misc.h"

// Defines

script "S7_RunningInZDoom" (void) {
        SetResultValue (0);
        printBold (s:"S7_RunningInZDoom: 0Zandronum");
}