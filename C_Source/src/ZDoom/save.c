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
#include "CSC.h"
#include "save_inv.h"
#include "save.h"

int SaveDataSize = sizeof (SavedData_t);

int SaveSys_ReadInt (string s, int *offset, int length) {
    int ret = StrToInt (StrMid (s, *offset, length));
    *offset += length;
    return ret;
}

string SaveSys_ReadStr (string s, int *offset, int length) {
    string ret = StrMid (s, *offset, length);
    *offset += length;
    return ret;
}

#ifdef DEBUG
#define SaveSys_UIError Log ("\CgSave system: Load failed: Couldn't read user info.\n\Cg    (Debug info: file: %s; line: %d;)", __FILE__, __LINE__) \

#define SaveSys_FailLoad(s, length) \
if (StrLen (s) != length) { \
    Log ("\CgSave system: Load failed: Couldn't read save data.\n\Cg    (Debug info: file: %s; line: %d;)", __FILE__, __LINE__); \
    return FALSE; \
}
#else
#define SaveSys_UIError Log ("\CgSave system: Load failed: Couldn't read user info.")

#define SaveSys_FailLoad(s, length) \
if (StrLen (s) != length) { \
    Log ("\CgSave system: Load failed: Couldn't read save data."); \
    return FALSE; \
}
#endif

bool LoadSaveDataToPointer (int playerNum, SavedData_t *data) {
    PlayerData_t *player = &PlayerData [playerNum]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgFunction LoadSaveDataToPointer: Fatal error: Invalid or NULL player struct for player %d.", playerNum);
        return FALSE;
    }

    SavedData_t  tmpData;
    int         *offset; *offset = 0;

    // Info
    string infoStr = GetUserCVarString (playerNum, SD_INFO);
    if (StrLen (infoStr) < 1) {
        return FALSE;
    }
    int version = SaveSys_ReadInt (infoStr, offset, 5);
    if (version != SAVESYS_SAVEVERSION) {
        if (version < SAVESYS_SAVEVERSION)
            Log ("\CgSave system: Load failed: Save from an older version. (Save: %d, Mod: %d)", version, SAVESYS_SAVEVERSION);
        if (version > SAVESYS_SAVEVERSION)
            Log ("\CgSave system: Load failed: Save from a newer version. (Save: %d, Mod: %d)", version, SAVESYS_SAVEVERSION);

        return FALSE;
    }
    int nameLen = SaveSys_ReadInt (infoStr, offset, 4);
    tmpData.name = SaveSys_ReadStr (infoStr, offset, nameLen);
    if (StrLen (tmpData.name) != nameLen) {
        SaveSys_UIError;
        return FALSE;
    }
    tmpData.gender = SaveSys_ReadInt (infoStr, offset, 4);

    *offset = 0;
    // RPG Systems
    string rpgSysStr = GetUserCVarString (playerNum, SD_RPGSYSTEM);
    tmpData.xpSystem.level = SaveSys_ReadInt (rpgSysStr, offset, 6);
    tmpData.xpSystem.experience  = SaveSys_ReadInt (rpgSysStr, offset, 7);
    tmpData.xpSystem.attrPoints  = SaveSys_ReadInt (rpgSysStr, offset, 11);
    tmpData.xpSystem.strengthLVL = SaveSys_ReadInt (rpgSysStr, offset, 3);
    tmpData.xpSystem.agilityLVL  = SaveSys_ReadInt (rpgSysStr, offset, 3);
    tmpData.xpSystem.vitalityLVL = SaveSys_ReadInt (rpgSysStr, offset, 3);
    tmpData.xpSystem.defenseLVL  = SaveSys_ReadInt (rpgSysStr, offset, 3);
    tmpData.xpSystem.magicLVL    = SaveSys_ReadInt (rpgSysStr, offset, 3);
    tmpData.cash = SaveSys_ReadInt (rpgSysStr, offset, 11);
    SaveSys_FailLoad (rpgSysStr, *offset);

    *offset = 0;
    // Script Data
    string scriptDataStr = GetUserCVarString (playerNum, SD_SCRIPTDATA);
    tmpData.scriptData.lastWeapon = SaveSys_ReadInt (scriptDataStr, offset, 6);
    SaveSys_FailLoad (scriptDataStr, *offset);

    *offset = 0;
    // ThumperDef
    string thumperDefStr = GetUserCVarString (playerNum, SD_THUMPERDEF);
    for (int i = 0; i < THUMPERMAGSIZE; i++)
        tmpData.thumperDef.magShells [i] = SaveSys_ReadInt (thumperDefStr, offset, 4);
    tmpData.thumperDef.magIndex = SaveSys_ReadInt (thumperDefStr, offset, 4);
    tmpData.thumperDef.currentShell = SaveSys_ReadInt (thumperDefStr, offset, 4);
    SaveSys_FailLoad (thumperDefStr, *offset);

    *data = tmpData;

    player = NULL;

    return TRUE;
}

SavedData_t LoadSaveData (int playerNum) {
    SavedData_t data;

    if (!LoadSaveDataToPointer (playerNum, &data)) {
        data.isInvalid = TRUE;
    }

    return data;
}

bool SaveSaveData (int playerNum, SavedData_t *data) {
    // Info
    string infoStr = StrParam ("%+.4d%+.3d%S%+.3d", SAVESYS_SAVEVERSION, StrLen (data->name), data->name, data->gender);
    SetUserCVarString (playerNum, SD_INFO, infoStr);

    // RPG Systems
    string rpgSysStr = StrParam ("%+.5d%+.6d%+.10d%+.2d%+.2d%+.2d%+.2d%+.2d%+.10d",
        data->xpSystem.level,
        data->xpSystem.experience,
        data->xpSystem.attrPoints,
        data->xpSystem.strengthLVL,
        data->xpSystem.agilityLVL,
        data->xpSystem.vitalityLVL,
        data->xpSystem.defenseLVL,
        data->xpSystem.magicLVL,
        data->cash
    );
    SetUserCVarString (playerNum, SD_RPGSYSTEM, rpgSysStr);

    // Script Data
    string scriptDataStr = StrParam ("%+.5d", data->scriptData.lastWeapon);
    SetUserCVarString (playerNum, SD_SCRIPTDATA, scriptDataStr);
    string thumperDefMagStr = s"";
    for (int i = 0; i < THUMPERMAGSIZE; i++)
        thumperDefMagStr = StrParam ("%S%+.3d", thumperDefMagStr, data->thumperDef.magShells [i]);
    string thumperDefStr = StrParam ("%S%+.3d%+.3d", thumperDefMagStr, data->thumperDef.magIndex, data->thumperDef.currentShell);
    SetUserCVarString (playerNum, SD_THUMPERDEF, thumperDefStr);

    // Inventory
    if (!SaveSys_SaveInventory (playerNum, data, &importantInv) || !SaveSys_SaveInventory (playerNum, data, &normalInv)) {
        Log ("\CgSave system: Save failed: Couldn't save inventory.");
        return FALSE;
    }

    return TRUE;
}

Script_C void S7_ClearSaveData NET () {
    int playerNum = PLN;

    SetUserCVarString (playerNum, SD_INFO,       s"");
    SetUserCVarString (playerNum, SD_RPGSYSTEM,  s"");
    SetUserCVarString (playerNum, SD_SCRIPTDATA, s"");
    SetUserCVarString (playerNum, SD_THUMPERDEF, s"");
    for (int i = 0; i < importantInv.maxCVars; i++)
        SetUserCVarString (playerNum, StrParam ("%S%d", importantInv.cvarName, i + 1), s"");
    for (int i = 0; i < normalInv.maxCVars; i++)
        SetUserCVarString (playerNum, StrParam ("%S%d", normalInv.cvarName, i + 1), s"");
}

Script_C void S7_SaveSysSave NET () {
    int playerNum = PLN; // Get the player's number
    PlayerData_t *player = &PlayerData [playerNum]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_SaveSysSave: Fatal error: Invalid or NULL player struct for player %d.", playerNum);
        return;
    }

    SavedData_t saveData = SavedData_t_new ();

    saveData.name = StrParam ("%tS", playerNum);
    saveData.gender = GetPlayerInfo (playerNum, PLAYERINFO_GENDER);
    saveData.xpSystem = player->xpSystem;     // Level system stuff
    saveData.cash = player->cash;             // Cash

    // Script data
    saveData.scriptData = player->scriptData; // Misc script data
    saveData.thumperDef = player->thumperDef; // Thumper stuff

    SaveSaveData (playerNum, &saveData);

    player = NULL;
}

Script_C void S7_SaveSysLoad NET () {
    int playerNum = PLN; // Get the player's number
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_SaveSysLoad: Fatal error: Invalid or NULL player struct for player %d.", playerNum);
        return;
    }

    SavedData_t saveData = LoadSaveData (playerNum);

    if (!(saveData.isInvalid) && PD_PerformLoad (player, &saveData)) {
        if (!SaveSys_LoadInventory (playerNum, &saveData, &importantInv) || !SaveSys_LoadInventory (playerNum, &saveData, &normalInv)) {
            Log ("\CgSave system: Load failed: Couldn't load inventory.");
            return;
        }
    }

    player = NULL;
}

#ifdef DEBUG

Script_C void saveTest () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript saveTest: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    SavedData_t saveData;

    saveData.name = s"Cutie herm deer girl <3";
    saveData.gender = GetPlayerInfo (PLN, PLAYERINFO_GENDER);
    saveData.xpSystem = player->xpSystem;     // Level system stuff
    saveData.cash = player->cash;             // Cash

    // Script data
    saveData.scriptData = player->scriptData; // Misc script data
    saveData.thumperDef = player->thumperDef; // Thumper stuff

    SaveSaveData (PLN, &saveData);
    PrintBold ("%S", GetActorPropertyString (0, APROP_NameTag));

    player = NULL;
}

Script_C void loadTest () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript loadTest: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    SavedData_t saveData = LoadSaveData (PLN);

    if (PD_PerformLoad (player, &saveData)) {
        if (!SaveSys_LoadInventory (PLN, &saveData, &importantInv) || !SaveSys_LoadInventory (PLN, &saveData, &normalInv)) {
            Log ("\CgSave system: Load failed: Couldn't load inventory.");
            return;
        }
    }

    player = NULL;
}

#endif