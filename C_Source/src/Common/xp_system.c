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
#include "xp_system.h"

//-------------------------------------------------------------------------------------------
//
// XP System
//
//-------------------------------------------------------------------------------------------

void LevelUp (int level) {
    SetFont (s"DBIGFONT");
    
    if (GetUserCVar (PLN, s"S7_MsgsOn"))
        HudMessage ("You reached level ", d:level, s:"."; HUDMSG_FADEINOUT|GetUserCVar (PLN, "S7_LogLVLUpMsgs") * HUDMSG_LOG, 10000, CR_UNTRANSLATED, 0.5, 0.5, 3.0, 0.3, 0.3);
    
    PlaySound (0, s"Player/LevelUp", CHAN_UI);
    GiveInventory (s"S7_XP_System_Level", 1);
    GiveInventory (s"S7_XP_System_Experience", Random (4, 6));
}

Script_C void S7_XP_System ENTER {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;
    
    int currentLVL, currentXP, currentHP;
    int logMessages = GetUserCVar (PLN, s"S7_LogLVLUpMsgs");
    
    while (TRUE) {
        currentLVL = CheckInventory (s"S7_XP_System_Level");
        currentXP = CheckInventory (s"S7_XP_System_Experience");
        logMessages = GetUserCVar (PLN, s"S7_LogLVLUpMsgs");
        
        if (currentXP >= 1000 && currentLVL == 0) {
            levelUp (1);
            GiveInventory ("BerettaUpgrade", 1);
            SetFont ("SMALLFONT");
            if (GetUserCVar (PLN, s"S7_MsgsOn"))
                HudMessage (HUDMSG_FADEINOUT|logMessages * HUDMSG_LOG, 10001, CR_UNTRANSLATED, 0.0k, 0.0k, 1, 0.0, 0.0, 0.0, "Beretta upgraded.\nBurstfire(press %SK to change firing modes)", "+altfire");
                hudMessage (s:"Beretta upgraded.\nBurstfire(press ", k:"+altattack", s:" to change firing modes)";
                    HUDMSG_FADEINOUT|logMessages * HUDMSG_LOG, 9999, CR_UNTRANSLATED, 0.5, 0.6, 3.0, 0.3, 0.3);
        }
        
        Delay (1);
    }
}

//-------------------------------------------------------------------------------------------
//
// Stat System
//
//-------------------------------------------------------------------------------------------

// strength
/*int S7_StrengthStat (fixed baseDamage, fixed multiplier) {
    fixed strengthStat = CheckInventory (s"S7_Stats_System_Strength");
    fixed result = baseDamage * (1.0 + (multiplier * strengthStat));
    
    return result >> 16;
}*/