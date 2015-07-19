#include "util.h"
#include "util_math.h"
#include "HUD.h"
#undef ACS_SHORT_NAMES

Script_C void S7_HudWeapons ENTER CLIENTSIDE (void) { // HUD icons and stuff...
    // Not needed or desired in TitleMaps.
    if (ACS_GameType () == GAME_TITLE_MAP)
        return;
    
    while (TRUE) {
        if (ACS_GetUserCVar (PLN, s"screenblocks") <= 11) { // if HUD shown...
            /* Firing modes */
            if (ACS_CheckWeapon (s"S7_TEC9")) { // if using the TEC-9...
                if (ACS_CheckInventory (s"S7_TEC9_Burst")) { // if in Burst mode...
                    SetFont (s"BrstFire"); // Display Burst icon
                } else { // if in full auto mode
                    SetFont (s"FullAuto"); // Display Full Auto icon
                }
            } else if (ACS_CheckWeapon (s"S7_AMG")) { // if using the AMG...
                if (ACS_CheckInventory (s"S7_AMG_Burst")) { // if in Burst mode...
                    SetFont (s"BrstFire"); // Display Burst icon
                } else { // if in full auto mode
                    SetFont (s"FullAuto"); // Display Full Auto icon
                }
            } else
                SetFont (s"TNT1A0");
        } else
            SetFont (s"TNT1A0");
        
        HudMessage (HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP | HUDMSG_LAYER_UNDERHUD, 10001, CR_UNTRANSLATED, 0.0k, 0.0k, 1, 0.0, 0.0, 0.0, "A");
        ACS_Delay (1);
    }
}