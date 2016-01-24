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

#define PLAYER_C
#include "includes.h"
#undef PLAYER_C
#include "player.h"

PlayerData_t PlayerData [MAX_PLAYERS];

void UpdatePlayerData (PlayerData_t *player) {
    // Position and velocity
    player->x = GetActorX (0); player->y = GetActorY (0); player->z = GetActorZ (0);
    player->velX = GetActorVelX (0); player->velY = GetActorVelY (0); player->velZ = GetActorVelZ (0);

    // Health and stamina
    player->health = GetActorProperty (0, APROP_Health);
    player->maxHealth = GetActorProperty (0, APROP_SpawnHealth);
    player->stamina = CheckInventory (s"S7_Stamina");

    // XP system stuff
    player->level = CheckInventory (s"S7_XP_System_Level");
    player->experience = CheckInventory (s"S7_XP_System_Experience");
    player->attrPoints = CheckInventory (s"S7_XP_System_AttributePoints");
    player->strengthLVL = CheckInventory (s"S7_Stats_System_Strength");
    player->staminaLVL = CheckInventory (s"S7_Stats_System_Stamina");

    // Misc
    player->waterlevel = GetActorProperty (0, APROP_Waterlevel);
}