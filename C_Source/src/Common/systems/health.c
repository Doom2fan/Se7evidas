/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015-???  Chronos Ouroboros
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
#include "systems/health.h"

#define MEDIKITHEALTH 40
#define STIMPACKHEALTH MEDIKITHEALTH / 2
#define STIMPACKITEM s"S7_Stimpack"

Script_C void S7_MedikitScript () {
    Print ("Applying Medikit");
    Thing_Stop (0);
    SetPlayerProperty (0, 1, PROP_TOTALLYFROZEN);
    Delay (35 * 2);
    SetPlayerProperty (0, 0, PROP_TOTALLYFROZEN);

    if (MEDIKITHEALTH - (100 - GetActorProperty (0, APROP_Health)) >= STIMPACKHEALTH)
        if (CheckInventory (STIMPACKITEM) < 8)
            GiveInventory (STIMPACKITEM, 1);
        else
            Spawn (STIMPACKITEM, GetActorX (0), GetActorY (0), GetActorZ (0));

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
    if (!player)
        return;

    if (GetUserCVar (PLN, s"S7_HeartbeatsOn")) { // If the player has heartbeats enabled...
        if ((player->health.health <= 25 && player->health.health > 15 && *heartbeatTics >= 89) || // If health is less than or equal to 25 but greater than 15 and heartbeatTics is greater than or equal to 89...
            (player->health.health <= 15 && player->health.health > 10 && *heartbeatTics >= 71) || // OR health is less than or equal to 15 but greater than 10 and heartbeatTics is greater than or equal to 71...
            (player->health.health <= 10 && player->health.health > 5  && *heartbeatTics >= 53) || // OR health is less than or equal to 10 but greater than 5  and heartbeatTics is greater than or equal to 53...
            (player->health.health <= 5  && player->health.health > 2  && *heartbeatTics >= 35) || // OR health is less than or equal to 5  but greater than 2  and heartbeatTics is greater than or equal to 35...
            (player->health.health <= 2  && player->health.health > 0  && *heartbeatTics >= 18)) { // OR health is less than or equal to 2  but greater than 0  and heartbeatTics is greater than or equal to 18...
            *heartbeatTics = 0; // Set heartbeatTics to 0
            LocalAmbientSound (s"Player/Heartbeat", 127); // Play the heartbeat sound
        } else if (player->health.health > 25) // If health is greater than 25...
            *heartbeatTics = 0; // Set heartbeatTics to 0
        else // if neither...
            (*heartbeatTics)++; // Add one to heartbeatTics
    }
}

Script_C int S7_GetMaxHealth () {
    return GetActorProperty (0, APROP_SpawnHealth);
}

Script_C void S7_CanteenScript () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ServersideEnter: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }
    int health     = GetActorProperty (0, APROP_Health);
    int milkAmount = CheckInventory (CANTEENITEM);

    if (health >= player->health.maxHealth || milkAmount < player->health.milkUseRate)
        return;

    while (TRUE) {
        if (health >= player->health.maxHealth || milkAmount < player->health.milkUseRate)
            break;

        SetActorProperty (0, APROP_Health, health + player->health.milkRegenRate);
        TakeInventory (CANTEENITEM, player->health.milkUseRate);
        health     = GetActorProperty (0, APROP_Health);
        milkAmount = CheckInventory (CANTEENITEM);
    }

    FadeRange (0, 40, 120, 0.5k, 0, 0, 0, 0.0k, 0.4k);
    PlaySound (0, s"Inventory/CanteenUse", CHAN_ITEM);
}