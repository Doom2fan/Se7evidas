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
#include "hud.h"

const string S7_HW_2ModeWpns [] [4] = {
    {
        s"S7_TEC9",
        s"S7_TEC9_Burst",
        s"BrstFire",
        s"FullAuto"
    },
    {
        s"S7_AMG",
        s"S7_AMG_Burst",
        s"BrstFire",
        s"FullAuto"
    },
    {
        s"S7_PlasmaGun",
        s"S7_PlasmaGun_Semi",
        s"SemiAuto",
        s"FullAuto"
    },
    {
        s"S7_ManxCarbine",
        s"S7_ManxCarbine_Semi",
        s"SemiAuto",
        s"FullAuto"
    }
};

void HW_SetFont (string font) {
    if (GetCVar (s"screenblocks") <= 11) // if the HUD is shown...
        SetFont (font); // Set the font to "font"
    else // If not
        SetFont (s"TNT1A0"); // Set the font to TNT1A0
}

void HudWeapons () { // HUD icons and stuff...
    /* Firing modes */
    SetFont (s"TNT1A0"); // Set the font to TNT1A0
    for (int x = 0; x < ArraySize (S7_HW_2ModeWpns); x++) { // Loop through everything in the weapons array
        if (CheckWeapon (S7_HW_2ModeWpns [x] [0])) { // If the player is using this weapon
            if (CheckInventory (S7_HW_2ModeWpns [x] [1])) // If the player has the specified item
                HW_SetFont (S7_HW_2ModeWpns [x] [2]); // Set the font to the first image
            else // If not
                HW_SetFont (S7_HW_2ModeWpns [x] [3]); // Set the font to the second image

            break; // Break from the loop
        }
    }
    HudMessage (HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP | HUDMSG_LAYER_UNDERHUD, 10001, CR_UNTRANSLATED, 0.0k, 0.0k, 1, 0.0, 0.0, 0.0, "A"); // Display the HUD message
}