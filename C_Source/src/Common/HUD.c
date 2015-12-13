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

string S7_HW_2ModeWpns [] [4] = {
    { s"S7_TEC9", s"S7_TEC9_Burst", s"BrstFire", s"FullAuto" },
    { s"S7_AMG",  s"S7_AMG_Burst",  s"BrstFire", s"FullAuto" }
};

void HW_SetFont (string font) {
    if (GetCVar (s"screenblocks") <= 11) // if the HUD shown...
        SetFont (font);
    else
        SetFont (s"TNT1A0");
}

Script_C void S7_HudWeapons ENTER CLIENTSIDE () { // HUD icons and stuff...
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;
    
    while (TRUE) {
        /* Firing modes */
        SetFont (s"TNT1A0");
        for (int x = 0; x < (sizeof (S7_HW_2ModeWpns) / sizeof (S7_HW_2ModeWpns [0])); x++) {
            if (CheckWeapon (S7_HW_2ModeWpns [x] [0])) {
                if (CheckInventory (S7_HW_2ModeWpns [x] [1]))
                    HW_SetFont (S7_HW_2ModeWpns [x] [2]);
                else
                    HW_SetFont (S7_HW_2ModeWpns [x] [3]);

                break;
            }
        }
        HudMessage (HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP | HUDMSG_LAYER_UNDERHUD, 10001, CR_UNTRANSLATED, 0.0k, 0.0k, 1, 0.0, 0.0, 0.0, "A");

        Delay (1);
    }
}