/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015  Chronos Ouroboros
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License along
**  with this program; if not, write to the Free Software Foundation, Inc.,
**  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include "includes.h"
#include "HUD.h"

Script_C void S7_HudWeapons ENTER CLIENTSIDE () { // HUD icons and stuff...
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