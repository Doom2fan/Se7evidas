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

#define PLAYER_C
#include "includes.h"
#undef PLAYER_C
#include "common/player.h"
#include "systems/monster_stuff.h"

// Forward declarations
Script_C void RunIntro (PlayerData_t *player);

// Functions
void UpdatePlayerData (PlayerData_t *player) {
    if (!player) {
        DebugLog ("\CgFunction UpdatePlayerData: Fatal error: Invalid or NULL player struct");
        return;
    }

    // Position and velocity
    player->physics.x = GetActorX (0); // Get the XYZ coordinates
    player->physics.y = GetActorY (0);
    player->physics.z = GetActorZ (0);
    player->physics.radius = GetActorPropertyFixed (0, APROP_Radius); // Get the player actor's size
    player->physics.height = GetActorPropertyFixed (0, APROP_Height);
    player->physics.velX = GetActorVelX (0); // Get the XYZ velocities
    player->physics.velY = GetActorVelY (0);
    player->physics.velZ = GetActorVelZ (0);
    player->physics.angle = GetActorAngle (0); // Get the angle and pitch
    player->physics.pitch = GetActorPitch (0);
    player->physics.velAngle = atan2A (player->physics.velX, player->physics.velZ); // Get the movement angle
    player->physics.floorZ = GetActorFloorZ (0);                                          // Sector Z coordinates
    player->physics.ceilZ  = GetActorCeilingZ (0);
    player->physics.relativeZ = player->physics.z - player->physics.floorZ; // Z coordinate relative to sector floor
    player->physics.jumpZ = GetActorPropertyFixed (0, APROP_JumpZ); // Jump height/velocity?

    // Health and stamina
    player->health.health = GetActorProperty (0, APROP_Health);         // Get the health
    player->health.maxHealth = GetActorProperty (0, APROP_SpawnHealth); // Get the max health

    // Shop system stuff
    player->cash = (CheckInventory (CASHTOKENGREATER) * CASHDIVPOINT) + CheckInventory (CASHTOKENLESSER);
    SetInventory (s"S7_CashCounter", player->cash);

    // Misc
    player->misc.waterlevel = GetActorProperty (0, APROP_Waterlevel); // Get the waterlevel/how deep in water the player is

    // Script data
    player->scriptData.disableHUD = CheckInventory (DISABLEHUDTOKEN);
    player->parkourDef.mjumpMax = CheckInventory (MJUMP_MAXTOKEN);
    player->scriptData.beamGrab = CheckInventory (SLANCE_BEAMGRABTOKEN);

    // Non struct data
    SetInventory (s"S7_AutoReloading", GetUserCVar (PLN, s"S7_AutoReloading"));
}

void UpdatePlayerAlpha (PlayerData_t *player) {
    if (!player)
        return;

    accum newAlpha = 1.0k;
    int   newRenderStyle = STYLE_Normal;
    accum oldAlpha = GetActorPropertyFixed (0, APROP_Alpha);
    int   oldRenderStyle = GetActorProperty (0, APROP_RenderStyle);

    if (CheckInventory (s"S7_PowerDodgeInvuln") > 0)
        newRenderStyle = STYLE_Shadow;

    if (newAlpha != oldAlpha)
        SetActorPropertyFixed (0, APROP_Alpha, newAlpha);
    if (newRenderStyle != oldRenderStyle)
        SetActorProperty      (0, APROP_RenderStyle, newRenderStyle);
}

void TakeCash (PlayerData_t *player, int amount) {
    if (!player) {
        DebugLog ("\CgFunction TakeCash: Fatal error: Fatal error: Invalid or NULL player struct");
        return;
    }

    int newAmount = player->cash - amount;
    SetInventory (CASHTOKENLESSER,  newAmount % CASHDIVPOINT);
    SetInventory (CASHTOKENGREATER, newAmount / CASHDIVPOINT);
    player->cash = (CheckInventory (CASHTOKENLESSER) * CASHDIVPOINT) + CheckInventory (CASHTOKENGREATER);
}

void GiveCash (PlayerData_t *player, int amount) {
    if (!player) {
        DebugLog ("\CgFunction GiveCash: Fatal error: Fatal error: Invalid or NULL player struct");
        return;
    }

    if (player->cash + amount > CASHMAXAMOUNT) {
        int toHeld = Min (CASHMAXAMOUNT - player->cash, amount);
        unsigned long int toStorage = amount - toHeld;
        GiveInventory (CASHTOKENLESSER,  toHeld % CASHDIVPOINT);
        GiveInventory (CASHTOKENGREATER, toHeld / CASHDIVPOINT);
        player->bankData.cash += toStorage;
    } else {
        GiveInventory (CASHTOKENLESSER,  amount % CASHDIVPOINT);
        GiveInventory (CASHTOKENGREATER, amount / CASHDIVPOINT);
    }

    player->cash = (CheckInventory (CASHTOKENLESSER) * CASHDIVPOINT) + CheckInventory (CASHTOKENGREATER);
}

void GiveCashNoBank (PlayerData_t *player, int amount) {
    if (!player) {
        DebugLog ("\CgFunction GiveCash: Fatal error: Fatal error: Invalid or NULL player struct");
        return;
    }

    GiveInventory (CASHTOKENLESSER,  amount % CASHDIVPOINT);
    GiveInventory (CASHTOKENGREATER, amount / CASHDIVPOINT);
    player->cash = (CheckInventory (CASHTOKENLESSER) * CASHDIVPOINT) + CheckInventory (CASHTOKENGREATER);
}

void SetCash (PlayerData_t *player, int amount) {
    if (!player) {
        DebugLog ("\CgFunction SetCash: Fatal error: Fatal error: Invalid or NULL player struct");
        return;
    }

    TakeInventory (CASHTOKENLESSER,  0x7FFFFFFF);
    TakeInventory (CASHTOKENGREATER, 0x7FFFFFFF);
    GiveInventory (CASHTOKENLESSER,  amount % CASHDIVPOINT);
    GiveInventory (CASHTOKENGREATER, amount / CASHDIVPOINT);
    player->cash = (CheckInventory (CASHTOKENLESSER) * CASHDIVPOINT) + CheckInventory (CASHTOKENGREATER);
}

void InitializePlayer (PlayerData_t *player) {
    if (!player) {
        DebugLog ("\CgFunction InitializePlayer: Fatal error: Invalid or NULL player struct");
        return;
    }

    player->ammoMax = BASEAMMOMAX;
    player->parkourDef.wGrabOldGravity = 1.0k;
    player->parkourDef.wGrabHolding = FALSE;
    SetInventory (DISABLEHUDTOKEN, 1);
    player->scriptData.disableHUD = TRUE;

    UpdatePlayerData (player);

    RunIntro (player);
    player->initialized = TRUE;
}

#define BASEINTROID 12000
#define RIntPrintText(id, x, y, color, duration, ...) \
( \
 SetFont (s"SMALLFNT"), \
 HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_OVERHUD, id, color, (x) + 0.1k, (y) + 0.1k, duration, 0.0k, 0.0k, 0.0k, __VA_ARGS__) \
)
static const cstr RInt_CorruptNone [] = {
    (cstr) "None",
    (cstr) "Negligible",
};
static const cstr RInt_SpinnyThing [] = {
    (cstr) "|",
    (cstr) "/",
    (cstr) "-",
    (cstr) "\\",
};
Script_C void RunIntro (PlayerData_t *player) {
    if (!PlayerInGame (PLN) || PlayerIsBot (PLN))
        return;

    string  curName = StrParam ("%tS", PLN);
    int     curGender = GetPlayerInfo (PLN, PLAYERINFO_GENDER);
    int     corruptIndex = Random (0, ArraySize (RInt_CorruptNone) - 1);

    player->shopDef.disableOpen = TRUE;
    GiveInventory (DISABLEHUDTOKEN, 1);
    SetPlayerProperty (FALSE, ON, PROP_TOTALLYFROZEN);
    FadeRange (0, 0, 0, 1.0k, 0, 0, 0, 1.0k, TicsToSecs (9));
    Delay (17);

    if (GetUserCVar (PLN, s"S7_NoIntro") ||
        (GetUserCVar (PLN, s"S7_NoIntroOnMP") && GameType () != GAME_SINGLE_PLAYER)) {
        if (!GetCVar (s"S7_ForceIntro"))
            goto FinishIntro;
    }

    ActivatorSound (s"Comp/Access", 127);
    Delay (16);

    RIntPrintText (BASEINTROID,     -0.125k, -0.150k, CR_GREEN, 0.0k, "Nanomachines: |");
    Delay (2);
    RIntPrintText (BASEINTROID + 1, -0.125k, -0.175k, CR_GREEN, 0.0k, "Cybernetic enhancements: |");
    Delay (2);
    RIntPrintText (BASEINTROID + 2, -0.125k, -0.200k, CR_GREEN, 0.0k, "Corruption: |");
    Delay (2);
    RIntPrintText (BASEINTROID + 3, -0.125k, -0.225k, CR_GREEN, 0.0k, "ECM/ECCM: |");
    Delay (2);

    for (int i = 0, j = 0; i < (8 + 5); i++, j++) {
        if (j >= ArraySize (RInt_SpinnyThing)) j = 0;
        RIntPrintText (BASEINTROID,     -0.125k, -0.150k, CR_GREEN, 0.0k, "Nanomachines: %s",            i > (8 + 1) ? "Operational"                   : RInt_SpinnyThing [j]);
        RIntPrintText (BASEINTROID + 1, -0.125k, -0.175k, CR_GREEN, 0.0k, "Cybernetic enhancements: %s", i > (8 + 2) ? "Working"                       : RInt_SpinnyThing [j]);
        RIntPrintText (BASEINTROID + 2, -0.125k, -0.200k, CR_GREEN, 0.0k, "Corruption: %s",              i > (8 + 3) ? RInt_CorruptNone [corruptIndex] : RInt_SpinnyThing [j]);
        RIntPrintText (BASEINTROID + 3, -0.125k, -0.225k, CR_GREEN, 0.0k, "ECM/ECCM: %s", RInt_SpinnyThing [j]);
        Delay (3);
    }

    RIntPrintText (BASEINTROID + 3, -0.125k, -0.225k, CR_GREEN, 0.0k, "ECM/ECCM: Ok");
    ActivatorSound (s"Comp/Ok", 127);
    Delay (35 + 17);

    for (int i = 0; i < 35; i++)
        ClearMessage (BASEINTROID + i);

    ActivatorSound (s"Comp/Access", 127);
    RIntPrintText (BASEINTROID, -0.125k, -0.150k, CR_GREEN, 0.0k, "Name: %S", curName);
    RIntPrintText (BASEINTROID + 1, -0.125k, -0.175k, CR_GREEN, 0.0k, "Gender: %LS", PD_Gender [curGender]);
    Delay (7);
    ActivatorSound (s"Comp/Ok", 127);
    Delay (45);

FinishIntro:
    for (int i = 0; i < 35; i++)
        ClearMessage (BASEINTROID + i);
    TakeInventory (DISABLEHUDTOKEN, 0x7FFFFFFF);
    FadeRange (0, 0, 0, 1.0k, 0, 0, 0, 0.0k, TicsToSecs (9));
    player->shopDef.disableOpen = FALSE;
    SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN);
}

void DisconnectPlayer (PlayerData_t *player) {
    if (!player) {
        DebugLog ("\CgFunction DisconnectPlayer: Fatal error: Invalid or NULL player struct");
        return;
    }

    player->initialized = FALSE;
    int *pData = (int *) player;
    for (int i = 0; i < sizeof (PlayerData_t); i++)
        pData [i] = 0;
}