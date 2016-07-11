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
#include "systems/xp_system.h"

#define XPSYSBASEXPGOAL (2500)
#define UpdateXPSysInfo() \
    player->xpSystem.level       = CheckInventory (XPS_LEVELTOKEN); \
    player->xpSystem.experience  = CheckInventory (XPS_EXPTOKEN); \
    player->xpSystem.attrPoints  = CheckInventory (XPS_ATTRPOINTSTOKEN); \
    player->xpSystem.strengthLVL = CheckInventory (XPS_STRENGTHTOKEN); \
    player->xpSystem.agilityLVL  = CheckInventory (XPS_AGILITYTOKEN); \
    player->xpSystem.vitalityLVL = CheckInventory (XPS_VITALITYTOKEN); \
    player->xpSystem.defenseLVL  = CheckInventory (XPS_DEFENSETOKEN); \
    player->xpSystem.magicLVL    = CheckInventory (XPS_MAGICTOKEN)

void LevelUp (int level, int attrPoints, bool log, string message) {
    SetFont (s"DBIGFONT");

    if (GetUserCVar (PLN, s"S7_MsgsOn")) {
        SetFont (s"DBIGFONT");
        HudMessage (HUDMSG_FADEINOUT | HUDMSG_LAYER_OVERHUD | HUDMSG_LOG * log, 11000, CR_UNTRANSLATED, 0.5k, 0.5k, 3.0k, 0.3, 0.3, 0.0, "Level up!");
        SetFont (s"SMALLFNT");
        if (!message)
            HudMessage_Str (HUDMSG_FADEINOUT | HUDMSG_LAYER_OVERHUD | HUDMSG_LOG * log, 11001, CR_UNTRANSLATED, 0.5k, 0.55k, 3.0k, 0.3, 0.3, 0.0, s"You have reached level %d.\nYou have gained %d attribute points.", level, attrPoints);
        else
            HudMessage_Str (HUDMSG_FADEINOUT | HUDMSG_LAYER_OVERHUD | HUDMSG_LOG * log, 11001, CR_UNTRANSLATED, 0.5k, 0.55k, 3.0k, 0.3, 0.3, 0.0, message);
    }

    PlaySound (0, s"Player/LevelUp", CHAN_UI);
}

void XPSys_UpdateLevel (PlayerData_t *player) {
    UpdateXPSysInfo ();

    bool logMessages = GetUserCVar (PLN, s"S7_LogLVLUpMsgs");
    int  reqXP = XPSYSBASEXPGOAL * (1.0k + 0.25k * player->xpSystem.level);
    int  nextLevel = player->xpSystem.level + 1;
    int  attrPoints = Random (2, 5);
    int  xp = player->xpSystem.experience;

    if (xp >= reqXP) {
        switch (nextLevel) {
            default:
                LevelUp (nextLevel, attrPoints, logMessages, NULL);
                SetInventory (XPS_LEVELTOKEN, nextLevel);
                GiveInventory (XPS_ATTRPOINTSTOKEN, attrPoints);
                TakeInventory (XPS_EXPTOKEN, reqXP);
                break;
        }
    }

    UpdateXPSysInfo ();
}

void XPSys_EnforceStats (PlayerData_t *player) {
    int baseHealth;
    int playerClass = GetPlayerInfo (PLN, PLAYERINFO_PLAYERCLASS);

    switch (playerClass) {
        case PlayerClass_Scout:
            baseHealth = 75;
            break;

        default:
            baseHealth = 100;
            break;
    }

    // Agility
    SetAmmoCapacity (STAMINATOKEN, GetMaxStamina (player));
    // Vitality
    SetActorProperty (0, APROP_SpawnHealth, (int) (baseHealth * (1.0k + 0.15k * player->xpSystem.vitalityLVL)));
    // Defense
    SetActorPropertyFixed (0, APROP_DamageFactor, 1.0k - 0.025k * player->xpSystem.defenseLVL);
    // Magic
    SetAmmoCapacity (MANATOKEN, GetMaxMana (player));
}

void UpdateXPSystem (PlayerData_t *player) {
    if (!player)
        return;

    XPSys_UpdateLevel  (player); // Level stuff
    XPSys_EnforceStats (player); // Stats stuff
}