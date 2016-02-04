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
#include "HUD.h"
#include "misc.h"
#include "parkour.h"
#include "sprint_system.h"
#include "stamina.h"
#include "weapon_stuff.h"

Script_C void S7_ServersideOpen OPEN () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;
    
    SetAirControl (0.1k);

    while (TRUE) {
        UpdateServerData ();

        Delay (1);
    }
}

Script_C void S7_ServersideEnter ENTER () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    while (TRUE) { // Loop forever
        UpdatePlayerData (player); // Update the player's data 
        if (player->health > 0) {
            StaminaRegenerationPart1 (player);
            MultiJumpScript (player);
            DodgeScriptP1 (player);
        }
        SpeedScript (player);
        WaterScript (player);
        AmmoCountersScript (player);
        KeysScript ();

        Delay (1); // Wait for a tic

        if (player->health > 0) {
            StaminaRegenerationPart2 (player);
            DodgeScriptP2 (player);
        }
    }

}

Script_C void S7_ClientsideEnter ENTER CLIENTSIDE () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    int heartbeatTics = 0;

    while (TRUE) { // Loop forever
        HudWeapons ();
        HeartbeatScript (player, &heartbeatTics);

        Delay (1); // Wait for a tic
    }
}

void ResetStuff (PlayerData_t *player) {
    player->waterlevel = 0;
    player->dying = FALSE;
    player->staminaEmpty = FALSE;
    player->staminaTics = 0;
    player->parkourDef.dodgeCooldown = 0;
    player->parkourDef.mjumpCount = 0;
}

Script_C void S7_ServersideRespawn RESPAWN () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    ResetStuff (player);
}