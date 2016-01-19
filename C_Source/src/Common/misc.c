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
#include "misc.h"

Script_C void S7_SpeedScript ENTER () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;
    
    int health;
    
    while (true) {
        health = GetActorProperty (0, APROP_Health);
        
        if (health <= 20)
            GiveInventory (s"S7_Dying", 9999999);
        else
            TakeInventory (s"S7_Dying", 9999999);
        
        Delay(1);
    }
}

Script_C void S7_WaterScript ENTER () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;
    
    while (true) {
        if (GetActorProperty(0, APROP_Waterlevel) > 2) // if underwater...
            GiveInventory (s"S7_IsUnderwater", 1); // give S7_IsUnderwater

        else if (GetActorProperty(0, APROP_Waterlevel) <= 2) // if not underwater
            TakeInventory (s"S7_IsUnderwater", 1); // take S7_IsUnderwater
            
        SetInventory (s"S7_AirTime", GetAirSupply (PLN));
        Delay (1);
    }
}

Script_C void S7_Keys ENTER () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;
    
    while (true) {
        if (KeyPressed (BT_RELOAD))
            UseInventory (s"S7_ReloadKey");
        
        Delay (1);
    }
}

#ifndef DISABLEBDCCOMPAT
Script_C void S7_BrutalDoomCompatibility OPEN () {
    // Not needed or desired in Titlemaps.
    if (GameType () == GAME_TITLE_MAP)
        return;
    
    bool ACTIVATE = 0;
    bool tid = UnusedTID (-37000, -47000);
    int delayer = 0;
    
    while (true) {
        if (Spawn (s"Brutal_Blood", 0.0k, 0.0k, 0.0k, tid) ||
            Spawn (s"BrutalPistol", 0.0k, 0.0k, 0.0k, tid)) {
            Thing_Remove (tid);
            ACTIVATE = 1;
        }
        
        if (ACTIVATE) {
            int randomizer = Random (0, 2);
            int randomizer2 = 0;
            int i = 0;
            int actionCount = 0;
            
            if (delayer == 0) {
                if (randomizer == 0) { // AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
                    delayer = 35 * Random (10, 20);
                    for (i = 0; i < Random (5, 30); i++) {
                        Spawn (s"GETTHATSHITOUTTAHERE", GetActorX (0) + RandomFixed (-200.0k, 200.0k), GetActorY (0) + RandomFixed (-200.0k, 200.0k), GetActorZ (0), tid);
                        Thing_Hate (tid, 0, 2);
                        Thing_ChangeTID (tid, 0);
                        NoiseAlert (0, 0);
                    }
                } else if (randomizer == 1) { // Fuck sector colours up
                    delayer = 35 * Random (10, 20);
                    for (i = 0; i < 32767; i++) {
                        Sector_SetColor (i, Random (0, 255), Random (0, 255), Random (0, 255), 0);
                        actionCount++;
                        if (actionCount >= 10000) {
                            Delay (1);
                            actionCount = 0;
                        }
                    }
                } else if (randomizer == 2) { // Fuck flat rotations up
                    delayer = 35 * Random (10, 20);
                    for (i = 0; i < 32767; i++) {
                        Sector_SetRotation (i, Random (0, 356), Random (0, 356));
                        actionCount++;
                        if (actionCount >= 10000) {
                            Delay (1);
                            actionCount = 0;
                        }
                    }
                }
                
                if (GetLevelInfo (LEVELINFO_KILLED_MONSTERS) >= GetLevelInfo (LEVELINFO_TOTAL_MONSTERS) ||
                    GetLevelInfo (LEVELINFO_FOUND_SECRETS)   >= GetLevelInfo (LEVELINFO_TOTAL_SECRETS)  ||
                    GetLevelInfo (LEVELINFO_FOUND_ITEMS)     >= GetLevelInfo (LEVELINFO_TOTAL_ITEMS)) {
                    for (i = 0; i < 10; i++) {
                        Spawn (s"GETTHATSHITOUTTAHERE", GetActorX (0) + RandomFixed (-200.0k, 200.0k), GetActorY (0) + RandomFixed (-200.0k, 200.0k), GetActorZ (0), tid);
                        Thing_Hate (tid, 0, 2);
                        Thing_ChangeTID(tid, 0);
                        NoiseAlert (0, 0);
                    }
                }
            }
            
            i = 0;
            randomizer = 0;
            randomizer2 = 0;
        }
        
        Delay (1);
        if (delayer > 0)
            delayer--;
        if (delayer < 0)
            delayer = 0;
    }
}
#endif