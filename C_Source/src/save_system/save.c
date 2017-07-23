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
#include "misc/CSC.h"
#include "save_system/save_bankdata.h"
#include "save_system/save_inv.h"
#include "save_system/save.h"

int SaveDataSize = sizeof (SavedData_t);

int SaveSys_ReadInt (string s, int *offset, int length) {
    StrToIntValue ret = StrToIntHex (StrMid (s, *offset, length));
    *offset += length;
    return ret.value;
}

long int SaveSys_ReadLongInt (string s, int *offset, int length) {
    StrToIntValue ret = StrToIntHex (StrMid (s, *offset, length));
    *offset += length;
    return ret.value;
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
        DebugLog ("\CgFunction LoadSaveDataToPointer: Fatal error: Invalid or NULL player struct for player %d.", playerNum);
        return FALSE;
    }

    SavedData_t *tmpData = allocAndClear (sizeof (SavedData_t));
    int         *offset; *offset = 0;
    string cvarData;

    // Info
    cvarData = GetUserCVarString (playerNum, SD_INFO);
    if (StrLen (cvarData) < 1)
        return FALSE;

    int version = SaveSys_ReadInt (cvarData, offset, 4);
    if (version != SAVESYS_SAVEVERSION) {
        if (version < SAVESYS_SAVEVERSION)
            Log ("\CgSave system: Load failed: Save from an older version. (Save: %d, Mod: %d)", version, SAVESYS_SAVEVERSION);
        if (version > SAVESYS_SAVEVERSION)
            Log ("\CgSave system: Load failed: Save from a newer version. (Save: %d, Mod: %d)", version, SAVESYS_SAVEVERSION);
        return FALSE;
    }
    tmpData->gender = SaveSys_ReadInt (cvarData, offset, 1);
    int nameLen = SaveSys_ReadInt (cvarData, offset, 3);
    tmpData->name = SaveSys_ReadStr (cvarData, offset, nameLen);
    if (StrLen (tmpData->name) != nameLen) {
        SaveSys_UIError;
        return FALSE;
    }
    SaveSys_FailLoad (cvarData, *offset);

    *offset = 0;
    // RPG Systems
    cvarData = GetUserCVarString (playerNum, SD_RPGSYSTEM);
    tmpData->xpSystem.level = SaveSys_ReadInt (cvarData, offset, 4);
    tmpData->xpSystem.experience  = SaveSys_ReadInt (cvarData, offset, 8);
    tmpData->xpSystem.attrPoints  = SaveSys_ReadInt (cvarData, offset, 4);

    tmpData->xpSystem.strengthLVL = SaveSys_ReadInt (cvarData, offset, 4);
    tmpData->xpSystem.agilityLVL  = SaveSys_ReadInt (cvarData, offset, 4);
    tmpData->xpSystem.vitalityLVL = SaveSys_ReadInt (cvarData, offset, 4);
    tmpData->xpSystem.defenseLVL  = SaveSys_ReadInt (cvarData, offset, 4);
    tmpData->xpSystem.willLVL     = SaveSys_ReadInt (cvarData, offset, 4);
    tmpData->xpSystem.magicLVL    = SaveSys_ReadInt (cvarData, offset, 4);
    tmpData->xpSystem.techLVL     = SaveSys_ReadInt (cvarData, offset, 4);

    tmpData->cash = SaveSys_ReadInt (cvarData, offset, 8);
    SaveSys_FailLoad (cvarData, *offset);

    *offset = 0;
    // Script Data
    /*string scriptDataStr = GetUserCVarString (playerNum, SD_SCRIPTDATA);
    SaveSys_FailLoad (scriptDataStr, *offset);*/

    *offset = 0;
    // Custom weapon slots
    cvarData = GetUserCVarString (playerNum, SD_WEAPBINDS);
    for (int x = 0; x < WPBND_MAXSLOTS; x++) {
        for (int y = 0; y < WPBND_MAXWEAPS; y++) {
            int wp = SaveSys_ReadInt (cvarData, offset, 2);
            data->weapBinds.weapBinds [x] [y] = ((wp & 0x80) ? (wp | 0xFFFFFF00) : (wp));
        }
    }
    SaveSys_FailLoad (cvarData, *offset);

    *data = *tmpData;
    free (tmpData);

    player = NULL;

    return TRUE;
}

SavedData_t LoadSaveData (int playerNum) {
    SavedData_t data;

    if (!LoadSaveDataToPointer (playerNum, &data))
        data.isInvalid = TRUE;

    return data;
}

bool SaveSaveData (int playerNum, SavedData_t *data) {
    // Info
    string infoStr = StrParam ("%.4x%.1x%.3x%S", SAVESYS_SAVEVERSION, data->gender, StrLen (data->name), data->name);
    SetUserCVarString (playerNum, SD_INFO, infoStr);

    // RPG Systems
    string statPoints = StrParam ("%.4x%.4x%.4x%.4x%.4x%.4x%.4x",
        data->xpSystem.strengthLVL & 0xFFFF,
        data->xpSystem.agilityLVL  & 0xFFFF,
        data->xpSystem.vitalityLVL & 0xFFFF,
        data->xpSystem.defenseLVL  & 0xFFFF,
        data->xpSystem.willLVL     & 0xFFFF,
        data->xpSystem.magicLVL    & 0xFFFF,
        data->xpSystem.techLVL     & 0xFFFF);
    string rpgSysStr = StrParam ("%.4x%.8x%.4x%s%.8x",
        data->xpSystem.level,
        data->xpSystem.experience,
        data->xpSystem.attrPoints,
        statPoints,
        data->cash
    );

    SetUserCVarString (playerNum, SD_RPGSYSTEM, rpgSysStr);

    // Script Data
    /*string scriptDataStr = ;
    SetUserCVarString (playerNum, SD_SCRIPTDATA, scriptDataStr);*/

    // Custom weapon slots
    string weapBindsStr = s"";
    for (int x = 0; x < WPBND_MAXSLOTS; x++) {
        for (int y = 0; y < WPBND_MAXWEAPS; y++) {
            int bind = data->weapBinds.weapBinds [x] [y];
            weapBindsStr = StrParam ("%S%.2x", weapBindsStr, ((bind & 0x0000007F) | ((bind >> 24) & 0x00000080)) & 0x000000FF);
        }
    }
    SetUserCVarString (playerNum, SD_WEAPBINDS, weapBindsStr);

    // Bank System
    if (!SaveSys_SaveBank (playerNum, data)) {
        Log ("\CgSave system: Save failed: Couldn't save storage/bank data.");
        return FALSE;
    }

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
    for (int i = 0; i < importantInv.maxCVars; i++)
        SetUserCVarString (playerNum, StrParam ("%S%d", importantInv.cvarName, i + 1), s"");
    for (int i = 0; i < normalInv.maxCVars; i++)
        SetUserCVarString (playerNum, StrParam ("%S%d", normalInv.cvarName, i + 1), s"");
}

Script_C void S7_SaveSysSave NET () {
    int playerNum = PLN; // Get the player's number
    PlayerData_t *player = &PlayerData [playerNum]; // Get the player's PlayerData_t struct

    if (!player) {
        DebugLog ("\CgScript S7_SaveSysSave: Fatal error: Invalid or NULL player struct for player %d.", playerNum);
        return;
    }

    SavedData_t saveData;

    saveData.name = StrParam ("%tS", playerNum);
    saveData.gender = GetPlayerInfo (playerNum, PLAYERINFO_GENDER);
    saveData.xpSystem = player->xpSystem;     // Level system stuff
    saveData.bankData = player->bankData;     // Bank system stuff
    saveData.cash = player->cash;             // Cash

    // Script data
    saveData.scriptData = player->scriptData; // Misc script data
    saveData.weapBinds  = player->weapBinds;  // Custom weapon slots stuff

    SaveSaveData (playerNum, &saveData);

    player = NULL;
}

Script_C void S7_SaveSysLoad NET () {
    int playerNum = PLN; // Get the player's number
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        DebugLog ("\CgScript S7_SaveSysLoad: Fatal error: Invalid or NULL player struct for player %d.", playerNum);
        return;
    }

    SavedData_t saveData = LoadSaveData (playerNum);

    if (!(saveData.isInvalid) && PD_PerformLoad (player, &saveData)) {
        if (!SaveSys_LoadBank (playerNum, &saveData)) {
            Log ("\CgSave system: Load failed: Couldn't load storage/bank data.");
            return;
        }
        if (!SaveSys_LoadInventory (playerNum, &saveData, &importantInv) || !SaveSys_LoadInventory (playerNum, &saveData, &normalInv)) {
            Log ("\CgSave system: Load failed: Couldn't load inventory.");
            return;
        }
    }

    player = NULL;
}

#ifdef DEBUG

Script_C void saveTest () {
    if (!CheckCheats () || !PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        DebugLog ("\CgScript saveTest: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    SavedData_t saveData;

    saveData.name = s"DUUUUUUUURRRRR";
    saveData.gender = GetPlayerInfo (PLN, PLAYERINFO_GENDER);
    saveData.xpSystem = player->xpSystem;     // Level system stuff
    saveData.cash = player->cash;             // Cash

    // Script data
    saveData.scriptData = player->scriptData; // Misc script data

    SaveSaveData (PLN, &saveData);
    PrintBold ("%S", GetActorPropertyString (0, APROP_NameTag));

    player = NULL;
}

Script_C void loadTest () {
    if (!CheckCheats () || !PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        DebugLog ("\CgScript loadTest: Fatal error: Invalid or NULL player struct for player %d.", PLN);
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