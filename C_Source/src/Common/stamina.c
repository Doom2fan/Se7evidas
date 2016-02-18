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

void StaminaRegenerationPart1 (PlayerData_t *player) {
    if (!player)
        return;
    
    if (!(player->dying) && player->staminaTics >= 1 && !CheckWeapon (SPRINTWEAPON)) {
        player->staminaTics = 0;
        GiveInventory (STAMINATOKEN, 1);
        player->stamina = CheckInventory (STAMINATOKEN);
    } else if ((player->dying) && player->staminaTics >= 3 && !CheckWeapon (SPRINTWEAPON)) {
        player->staminaTics = 0;
        GiveInventory (STAMINATOKEN, 1);
        player->stamina = CheckInventory (STAMINATOKEN);
    }
    if (player->staminaTics > 0 && player->stamina == MAXSTAMINA || player->staminaTics > 0 && CheckWeapon (SPRINTWEAPON)) {
        player->staminaTics = 0;
    }
    if (player->staminaEmpty == TRUE && player->stamina >= 50) {
        player->staminaEmpty = FALSE;
    }
}

void StaminaRegenerationPart2 (PlayerData_t *player) {
    if (!player)
        return;
    
    if (player->stamina != MAXSTAMINA) {
        if (!CheckWeapon (SPRINTWEAPON)) {
            player->staminaTics++;
        }
    }
}