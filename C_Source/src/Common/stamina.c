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
#include "weapon_stuff.h"
#include "stamina.h"

#define MAXSTAMINA 150

int GlobalVar StaminaEmpty [MAX_PLAYERS];

Script_C void S7_StaminaRegeneration ENTER () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;
    
    int staminaTics = 0;
    int staminaAmount, health;
    
    while (TRUE) {
        staminaAmount = CheckInventory (s"S7_Stamina");
        health = GetActorProperty (0, APROP_Health);
        
        if (!CheckInventory (s"S7_Dying") && staminaTics >= 1 && !CheckWeapon (s"S7_SprintWeapon")) {
            staminaTics = 0;
            GiveInventory (s"S7_Stamina", 1);
        }
        if (CheckInventory (s"S7_Dying") && staminaTics >= 3 && !CheckWeapon (s"S7_SprintWeapon")) {
            staminaTics = 0;
            GiveInventory (s"S7_Stamina", 1);
        }
        if (staminaTics > 0 && staminaAmount == MAXSTAMINA || staminaTics > 0 && CheckWeapon (s"S7_SprintWeapon"))
            staminaTics = 0;            
        if (StaminaEmpty [PLN] == 1 && staminaAmount >= 50)
            StaminaEmpty [PLN] = 0;
        
        Delay(1);
        if (staminaAmount != MAXSTAMINA)
            if (!CheckWeapon (s"S7_SprintWeapon"))
                staminaTics++;
    }
}