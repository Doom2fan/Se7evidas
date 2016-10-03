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
#include "systems/HUD.h"
#include "systems/misc.h"
#include "systems/monster_stuff.h"
#include "systems/parkour.h"
#include "systems/sprint_system.h"
#include "systems/stamina.h"
#include "systems/xp_system.h"
#include "weapons/thumper.h"
#include "weapons/weapon_stuff.h"
#include "weapons/slot_sys.h"

void ShopSystem_Script (PlayerData_t *player);
void ResetStuff (PlayerData_t *player);

static int queuedMapEvent = MEVNT_None;

Script_C void S7_ServersideOpen OPEN () {
    #ifdef DEBUG
    if (RunningInZDoom)
        Log_Str (s"Se7evidas version %s\nSe7evidas ACSVM Library compiled at %s %s.", MOD_VERSION_CSTR, __DATE__, __TIME__);
    else
        Log_Str (s"Se7evidas version %S", MOD_VERSION_STRING);
    #endif

    SetAirControl (0.1k);
    //queuedMapEvent = MEVNT_PerfectHatred;
    MapData.mapEvent = queuedMapEvent;
    queuedMapEvent = 0;
    MapData.mapEventSet = true;
    if (MapData.mapEvent > 0)
        Log ("%d", MapData.mapEvent);
    SetupMapEvents ();

    while (TRUE) {
        UpdateServerData (); // Update server data
        UpdateMapData    (); // Update map data

        Delay (1);
    }
}

Script_C void S7_ServersideUnloading UNLOADING () {
    ServerData.mapCount++;

    if (ServerData.mapCount > 0 && Random (0, 255) < 32) {
        for (int i = 0; i < 50; i++)
            queuedMapEvent = Random (i > 25 ? MEVNT_None : MEVNT_None + 1, MEVNT_LastToken - 1);
    } else
        queuedMapEvent = MEVNT_None;

    ClearMonsterList ();

    for (int i = 0; i < MAX_PLAYERS; i++) {
        PlayerData_t *player = &PlayerData [i];
        if (player)
            ResetStuff (player);
    }
}

// General stuff
Script_C void S7_ServersideEnter ENTER () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP || !PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player)
        player = allocAndClear (sizeof (PlayerData_t));

    if (!player->initialized)
        InitializePlayer (player);
    else {
        FadeRange (0, 0, 0, 1.0k, 0, 0, 0, 0.0k, TicsToSecs (9));
        SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN);
        TakeInventory (DISABLEHUDTOKEN, 0x7FFFFFFF);
    }

    while (TRUE) { // Loop forever
        if (!PlayerInGame (PLN))
            return;

        UpdateXPSystem   (player); // Update everything related to the XP System
        UpdatePlayerData (player); // Update the player's data
        UpdateAmmoMax    (player); // Update the max ammo
        if (player->health.health > 0) {
            StaminaRegenerationPart1 (player); // Regenerate stamina (Part 1)
            WallJumpScript           (player);
            MultiJumpScript          (player);
            DodgeScriptP1            (player);
        }
        ShopSystem_Script  (player); // Run the shop system
        Thumper_Script     (player);
        SpeedScript        (player);
        WaterScript        (player);
        AmmoCountersScript (player);
        HellbladeScript    (player);
        CustomWeapSlots    (player);
        KeysScript ();

        UpdatePlayerAlpha  (player); // Update the alpha

        Delay (1); // Wait for a tic

        if (player->health.health > 0) {
            StaminaRegenerationPart2 (player); // Regenerate stamina (Part 2)
            DodgeScriptP2            (player);
        }
    }
}

// Clientside-ish (HUD, popups, heartbeats, etc.) stuff
Script_C void S7_ServersideEnter2 ENTER () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP || !PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ClientsideEnter: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    int        heartbeatTics = 0;
    SP_Data_t  sp_data;
    EIS_Data_t eis_data;

    while (TRUE) { // Loop forever
        if (!PlayerInGame (PLN))
            return;

        HeartbeatScript          (player, &heartbeatTics);
        Thumper_ScriptClientside (player);
        HudWeapons               (player);
        ShowPop                  (player, &sp_data);
        EnemyInfoScript          (player, &eis_data);
        ScreenOverlays           (player);
        DrawRadar                (player);

        Delay (1); // Wait for a tic
    }
}

Script_C void S7_MapStart ENTER () {
    if (!MapData.mapEventSet)
        while (!MapData.mapEventSet)
            Delay (1);

    SetHudSize (640, 480, FALSE);
    switch (MapData.mapEvent) {
        case MEVNT_GhostTown:
        break;

        case MEVNT_PowerOutage:
        break;

        case MEVNT_NuclearMeltdown:
        break;

        case MEVNT_PerfectHatred:
            SetFont (s"GARGWING");
            cstr s = CorruptText ((cstr) "Perfect Hatred");
            HudMessage (HUDMSG_FADEINOUT, 10000, CR_UNTRANSLATED, 250.1k, 320, 2.5, 0.8, 0.0, 0.0, s);
            Delay (2.5 * 35);
            for (int i = strlen (s) - 1; i >= 0; --i) {
                s [i] = 0;
                HudMessage (HUDMSG_PLAIN, 10000, CR_UNTRANSLATED, 250.1k, 320, 0.5, 0.0, 0.0, 0.0, "%s", s);
                Delay (3);
            }
        break;

        default:
        break;
    }
}

// Truly clientside stuff
Script_C void S7_ClientsideEnter ENTER CLIENTSIDE () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP || !PlayerInGame (PLN))
        return;

    if (S7_PlayerNumEqualConsolePlayer (PLN) == FALSE)
        return;

    while (TRUE) { // Loop forever
        if (!PlayerInGame (PLN))
            return;

        UpdateClientsideCVars ();

        Delay (1); // Wait for a tic
    }
}

void ResetStuff (PlayerData_t *player) {
    if (!player) {
        Log ("\CgFunction ResetStuff: Fatal error: Invalid or NULL player struct");
        return;
    }

    player->misc.waterlevel = 0;
    player->misc.dying = FALSE;
    player->scriptData.staminaEmpty = FALSE;
    player->scriptData.staminaTics = 0;
    player->scriptData.beamGrab = FALSE;
    player->parkourDef.dodgeCooldown = 0;
    player->parkourDef.dodgeInvulnTics = 0;
    player->parkourDef.mjumpCount = 0;
    SetInventory (DODGEINVULITEM,  0);
    SetInventory (DODGETRAILITEM,  0);
    SetInventory (DISABLEHUDTOKEN, 0);

    SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN);
}

Script_C void S7_ServersideRespawn RESPAWN () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP || !PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ServersideRespawn: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    ResetStuff (player);
}

Script_C void S7_ServersideDisconnect DISCONNECT (int num) {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;

    PlayerData_t *player = &PlayerData [num]; // Get the player's PlayerData_t struct

    Log ("%d", num);
    if (!player) {
        Log ("\CgScript S7_ServersideDisconnect: Fatal error: Invalid or NULL player struct for player %d.", num);
        return;
    }

    DisconnectPlayer (player);
}

Script_C int S7_RunningInZDoom () {
    return RunningInZDoom;
}