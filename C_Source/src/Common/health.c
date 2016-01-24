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
#include "health.h"

#define MEDIKITHEALTH 40
#define STIMPACKHEALTH MEDIKITHEALTH / 2

Script_C void S7_MedikitScript () {
    Print ("Applying Medikit");
    Thing_Stop (0);
    SetPlayerProperty (0, 1, PROP_TOTALLYFROZEN);
    Delay (35 * 2);
    SetPlayerProperty (0, 0, PROP_TOTALLYFROZEN);
    
    if (MEDIKITHEALTH - (100 - GetActorProperty (0, APROP_Health)) >= STIMPACKHEALTH)
        if (CheckInventory (s"S7_Stimpack") < 8)
            GiveInventory (s"S7_Stimpack", 1);
        else
            Spawn (s"S7_Stimpack", GetActorX (0), GetActorY (0), GetActorZ (0));
    
    HealThing (MEDIKITHEALTH);
}

Script_C void S7_StimpackScript () {
    Print ("Applying Stimpack");
    Thing_Stop (0);
    SetPlayerProperty (0, 1, PROP_TOTALLYFROZEN);
    Delay (35 * 1);
    HealThing (STIMPACKHEALTH);
    SetPlayerProperty (0, 0, PROP_TOTALLYFROZEN);
}

void HeartbeatScript (PlayerData_t *player, int *heartbeatTics) {
    if (GetUserCVar (PLN, s"S7_HeartbeatsOn")) {
        if ((player->health <= 25 && player->health > 15 && *heartbeatTics >= 89) ||
            (player->health <= 15 && player->health > 10 && *heartbeatTics >= 71) ||
            (player->health <= 10 && player->health > 5  && *heartbeatTics >= 53) ||
            (player->health <= 5  && player->health > 2  && *heartbeatTics >= 35) ||
            (player->health <= 2  && player->health > 0  && *heartbeatTics >= 18)) {
            *heartbeatTics = 0;
            LocalAmbientSound (s"Player/Heartbeat", 127);
        } else if (player->health > 25)
            *heartbeatTics = 0;
        else
            (*heartbeatTics)++;
    }
}

Script_C int S7_GetMaxHealth () {
    return GetActorProperty (0, APROP_SpawnHealth);
}