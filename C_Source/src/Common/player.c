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

// Forward declarations
void PD_DoLoadSave (PlayerData_t *player, SavedData_t *saveData);
Script_C void RunIntro (PlayerData_t *player, SavedData_t *saveData);

// Arrays
PlayerData_t PlayerData [MAX_PLAYERS];

// Functions
void UpdatePlayerData (PlayerData_t *player) {
    if (!player) {
        Log ("\CgFunction UpdatePlayerData: Fatal error: Invalid or NULL player struct");
        return;
    }
    
    // Position and velocity
    player->physics.x = GetActorX (0); player->physics.y = GetActorY (0); player->physics.z = GetActorZ (0); // Get the XYZ coordinates
    player->physics.velX = GetActorVelX (0); player->physics.velY = GetActorVelY (0); player->physics.velZ = GetActorVelZ (0); // Get the XYZ velocities
    player->physics.angle = GetActorAngle (0); // Get the player's angle
    player->physics.velAngle = VectorAngle (player->physics.velX, player->physics.velZ); // Get the player's movement angle
    player->physics.floorZ = GetActorFloorZ (0); player->physics.ceilZ = GetActorCeilingZ (0); // Sector Z coordinates
    player->physics.relativeZ = player->physics.z - player->physics.floorZ; // Z coordinate relative to sector floor
    player->physics.jumpZ = GetActorPropertyFixed (0, APROP_JumpZ); // Jump height/velocity?

    // Health and stamina
    player->health.health = GetActorProperty (0, APROP_Health); // Get the health
    player->health.maxHealth = GetActorProperty (0, APROP_SpawnHealth); // Get the max health
    player->health.stamina = CheckInventory (STAMINATOKEN); // Get the stamina

    // Shop system stuff
    player->cash = CheckInventory (CASHTOKEN);

    // XP system stuff
    player->xpSystem.level = CheckInventory (XPS_LEVELTOKEN); // Get the current level
    player->xpSystem.experience = CheckInventory (XPS_EXPTOKEN); // Get the experience
    player->xpSystem.attrPoints = CheckInventory (XPS_ATTRPOINTSTOKEN); // Get the attribute points
    player->xpSystem.strengthLVL = CheckInventory (XPS_STRENGTHTOKEN); // Get the strength level
    player->xpSystem.staminaLVL = CheckInventory (XPS_STAMINATOKEN); // Get the stamina level

    // Misc
    player->misc.waterlevel = GetActorProperty (0, APROP_Waterlevel); // Get the waterlevel/how deep in water the player is

    // Script data
    player->parkourDef.mjumpMax = CheckInventory (MJUMP_MAXTOKEN);

    // Non struct data
    SetInventory (s"S7_AutoReloading", GetUserCVar (PLN, s"S7_AutoReloading"));
}

void UpdateAmmoMax (PlayerData_t *player) {
    player->ammoMax = BASEAMMOMAX;

    if (CheckInventory (s"S7_BackpackToken"))
        player->ammoMax += 2;

    for (int i = 0; i < ArraySize (PD_AmmoTypes); i++) {
        int maxAmount = PD_AmmoTypes [i].magSize * player->ammoMax;
        if (GetAmmoCapacity (PD_AmmoTypes [i].name) != maxAmount)
            SetAmmoCapacity (PD_AmmoTypes [i].name, maxAmount);
    }
}

void TakeCash (PlayerData_t *player, int amount) {
    if (!player) {
        Log ("\CgFunction TakeCash: Fatal error: Fatal error: Invalid or NULL player struct");
        return;
    }
    
    TakeInventory (CASHTOKEN, amount);
    player->cash = CheckInventory (CASHTOKEN);
}

void GiveCash (PlayerData_t *player, int amount) {
    if (!player) {
        Log ("\CgFunction GiveCash: Fatal error: Fatal error: Invalid or NULL player struct");
        return;
    }
    
    GiveInventory (CASHTOKEN, amount);
    player->cash = CheckInventory (CASHTOKEN);
}

void InitializePlayer (PlayerData_t *player) {
    if (!player) {
        Log ("\CgFunction InitializePlayer: Fatal error: Invalid or NULL player struct");
        return;
    }

    player->thumperDef.magIndex = -1;
    player->ammoMax = 6;

    SavedData_t saveData = {
        .isInvalid = TRUE,
    };
    
    if (!(ServerData.noSaveLoading) && GetUserCVar (PLN, s"S7_LoadSaveDataOnNewGame")) {
        saveData = LoadSaveData (PLN);
        if (!(saveData.isInvalid)) {
            PD_DoLoadSave (player, &saveData);
            UpdateAmmoMax (player);
            PrintBold ("Test");
        }
    }

    RunIntro (player, &saveData);
    player->initialized = TRUE;
}

void PD_DoLoadSave (PlayerData_t *player, SavedData_t *saveData) {
    if (!player) {
        Log ("\CgFunction PD_DoLoadSave: Fatal error: Invalid or NULL player struct");
        return;
    } else if (!saveData || saveData->isInvalid) {
        Log ("\CgFunction PD_DoLoadSave: Fatal error: Invalid or NULL save data struct");
        return;
    }

    // RPG Systems
    SetInventory (XPS_LEVELTOKEN,      saveData->xpSystem.level);
    SetInventory (XPS_EXPTOKEN,        saveData->xpSystem.experience);
    SetInventory (XPS_ATTRPOINTSTOKEN, saveData->xpSystem.attrPoints);
    SetInventory (XPS_STRENGTHTOKEN,   saveData->xpSystem.strengthLVL);
    SetInventory (XPS_STAMINATOKEN,    saveData->xpSystem.staminaLVL);
    SetInventory (CASHTOKEN,           saveData->cash);
    player->ammoMax = saveData->ammoMax;

    // Script Data
    player->scriptData = saveData->scriptData;
    player->thumperDef = saveData->thumperDef;
}

#define BASEINTROID 12000
#define RIntPrintText(id, x, y, color, duration, ...) \
( \
 SetFont (s"FSHUDFONT"), \
 HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_OVERHUD, id, color, (x) + 0.1k, (y) + 0.1k, duration, 0.0, 0.0, 0.0, __VA_ARGS__) \
)
Script_C void RunIntro (PlayerData_t *player, SavedData_t *saveData) {
    string  curName = StrParam ("%tS", PLN);
    int     curGender = GetPlayerInfo (PLN, PLAYERINFO_GENDER);
    string  savedName = s"";
    int     savedGender = 0;
    int     id = BASEINTROID;
    int     xMul = 0;

    if (saveData->isInvalid) {
        savedName = StrParam ("%tS", PLN);
        savedGender = GetPlayerInfo (PLN, PLAYERINFO_GENDER);
    } else {
        savedName = saveData->name;
        savedGender = saveData->gender;
    }

    player->shopDef.disableOpen = TRUE;
    SetPlayerProperty (FALSE, ON, PROP_TOTALLYFROZEN);
    FadeRange (0, 0, 0, 1.0k, 0, 0, 0, 1.0k, TicsToSecs (9));
    Delay (17);

    if (GetUserCVar (PLN, s"S7_NoIntro") ||
        (GetUserCVar (PLN, s"S7_NoIntroOnMP") && GameType () != GAME_SINGLE_PLAYER)) {
        if (!GetCVar (s"S7_ForceIntro"))
            goto FinishIntro;
    }

    SetHudSize (320, 200, 0);

    ActivatorSound (s"Comp/Access", 127);
    Delay (8);
    string nameMsg, genderMsg;
    if (StrCmp (savedName, curName) != 0) nameMsg = StrParam ("Name: %S, formerly %S.", savedName, curName);
    else                                  nameMsg = StrParam ("Name: %S.", savedName);

    if (savedGender != curGender) nameMsg = StrParam ("Name: %LS, formerly %LS.", PD_Gender [curGender], PD_Gender [savedGender]);
    else                          nameMsg = StrParam ("Name: %LS.", PD_Gender [curGender]);

    ActivatorSound (s"Comp/Ok", 127);
    RIntPrintText (id++, 0.0 + (10.0k * xMul++), 6.0k, CR_GREEN, 0.0k, "%S", nameMsg);
    Delay (3);
    ActivatorSound (s"Comp/Ok", 127);
    RIntPrintText (id++, 0.0 + (10.0k * xMul++), 6.0k, CR_GREEN, 0.0k, "%S", genderMsg);
    Delay (3);

    SetHudSize (0, 0, 0);
FinishIntro:
    FadeRange (0, 0, 0, 1.0k, 0, 0, 0, 0.0k, TicsToSecs (9));
    player->shopDef.disableOpen = FALSE;
    SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN);
}

void DisconnectPlayer (PlayerData_t *player) {
    if (!player) {
        Log ("\CgFunction DisconnectPlayer: Fatal error: Invalid or NULL player struct");
        return;
    }
    
    player->initialized = FALSE;
    // Position, velocity, etc
    player->physics.x = 0.0k; player->physics.y = 0.0k; player->physics.z = 0.0k;
    player->physics.velX = 0.0k; player->physics.velY = 0.0k; player->physics.velZ = 0.0k;
    player->physics.angle = 0.0k;
    player->physics.velAngle = 0.0k;
    player->physics.floorZ = 0.0k; player->physics.ceilZ = 0.0k;
    player->physics.relativeZ = 0.0k;
    player->physics.jumpZ = 0.0k;

    // Health and stamina
    player->health.health = 0;
    player->health.maxHealth = 0;
    player->health.stamina = 0;

    // XP system stuff
    player->xpSystem.level = 0;
    player->xpSystem.experience = 0;
    player->xpSystem.attrPoints = 0;
    player->xpSystem.strengthLVL = 0;
    player->xpSystem.staminaLVL = 0;
    
    // Misc
    player->misc.waterlevel = 0;
    player->misc.dying = FALSE;

    // Script data
    player->scriptData.lastWeapon = 0;
    // Sprint system stuff
    player->SprintDef.OldSpeed = 1.0k;
    player->SprintDef.Sprinting = FALSE;
    player->scriptData.staminaEmpty = FALSE;
    player->scriptData.staminaTics = 0;
    // Parkour system stuff
    player->parkourDef.dodgeCooldown = 0;
    player->parkourDef.mjumpOnGround = TRUE;
    player->parkourDef.mjumpCount = 0;
    player->parkourDef.mjumpMax = 1;
    // Thumper stuff
    for (int i = 0; i < ArraySize (player->thumperDef.magShells); i++)
        player->thumperDef.magShells [i] = 0;
    player->thumperDef.currentShell = 0;
    player->thumperDef.magIndex = -1;
    // Shop system stuff
    player->shopDef.open = FALSE;
    player->shopDef.disableOpen = FALSE;
    player->shopDef.page = NULL;
    for (int i = 0; i < ArraySize (player->shopDef.items); i++)
        player->shopDef.items [i] = NULL;
    player->shopDef.position.x = 0;
    player->shopDef.position.y = 0;
    player->shopDef.moveDelay = 0;
    player->shopDef.moveSpeed = 0;
    player->shopDef.sellMode = FALSE;
}