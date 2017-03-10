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
        Log ("\CgFunction LoadSaveDataToPointer: Fatal error: Invalid or NULL player struct for player %d.", playerNum);
        return FALSE;
    }

    SavedData_t  tmpData;
    int         *offset; *offset = 0;

    // Info
    string infoStr = GetUserCVarString (playerNum, SD_INFO);
    if (StrLen (infoStr) < 1)
        return FALSE;

    int version = SaveSys_ReadInt (infoStr, offset, 4);
    if (version != SAVESYS_SAVEVERSION) {
        if (version < SAVESYS_SAVEVERSION)
            Log ("\CgSave system: Load failed: Save from an older version. (Save: %d, Mod: %d)", version, SAVESYS_SAVEVERSION);
        if (version > SAVESYS_SAVEVERSION)
            Log ("\CgSave system: Load failed: Save from a newer version. (Save: %d, Mod: %d)", version, SAVESYS_SAVEVERSION);
        return FALSE;
    }
    tmpData.gender = SaveSys_ReadInt (infoStr, offset, 1);
    int nameLen = SaveSys_ReadInt (infoStr, offset, 3);
    tmpData.name = SaveSys_ReadStr (infoStr, offset, nameLen);
    if (StrLen (tmpData.name) != nameLen) {
        SaveSys_UIError;
        return FALSE;
    }
    SaveSys_FailLoad (infoStr, *offset);

    *offset = 0;
    // RPG Systems
    string rpgSysStr = GetUserCVarString (playerNum, SD_RPGSYSTEM);
    tmpData.xpSystem.level = SaveSys_ReadInt (rpgSysStr, offset, 2);
    tmpData.xpSystem.experience  = SaveSys_ReadInt (rpgSysStr, offset, 8);
    tmpData.xpSystem.attrPoints  = SaveSys_ReadInt (rpgSysStr, offset, 4);

    long int statPoints = (SaveSys_ReadLongInt (rpgSysStr, offset, 8)) | (SaveSys_ReadLongInt (rpgSysStr, offset, 8) << 32);
    tmpData.xpSystem.strengthLVL = (int) ((statPoints)       & 0x0000001F); // Now we're doing it like this
    tmpData.xpSystem.agilityLVL  = (int) ((statPoints >>  5) & 0x0000001F);
    tmpData.xpSystem.vitalityLVL = (int) ((statPoints >> 10) & 0x0000001F);
    tmpData.xpSystem.defenseLVL  = (int) ((statPoints >> 15) & 0x0000001F);
    tmpData.xpSystem.willLVL     = (int) ((statPoints >> 20) & 0x0000001F);
    tmpData.xpSystem.magicLVL    = (int) ((statPoints >> 25) & 0x0000001F);
    tmpData.xpSystem.techLVL     = (int) ((statPoints >> 30) & 0x0000001F);

    tmpData.cash = SaveSys_ReadInt (rpgSysStr, offset, 8);
    SaveSys_FailLoad (rpgSysStr, *offset);

    *offset = 0;
    // Script Data
    /*string scriptDataStr = GetUserCVarString (playerNum, SD_SCRIPTDATA);
    SaveSys_FailLoad (scriptDataStr, *offset);*/

    *offset = 0;
    // ThumperDef
    string thumperDefStr = GetUserCVarString (playerNum, SD_THUMPERDEF);
    for (int i = 0; i < THUMPERMAGSIZE; i++)
        tmpData.thumperDef.magShells [i] = SaveSys_ReadInt (thumperDefStr, offset, 8);
    tmpData.thumperDef.magIndex = SaveSys_ReadInt (thumperDefStr, offset, 8);
    tmpData.thumperDef.currentShell = SaveSys_ReadInt (thumperDefStr, offset, 8);
    SaveSys_FailLoad (thumperDefStr, *offset);

    *offset = 0;
    // Custom weapon slots
    string weapBindsStr = GetUserCVarString (playerNum, SD_WEAPBINDS);
    for (int x = 0; x < WPBND_MAXSLOTS; x++) {
        for (int y = 0; y < WPBND_MAXWEAPS; y++) {
            int wp = SaveSys_ReadInt (weapBindsStr, offset, 2);
            data->weapBinds.weapBinds [x] [y] = ((wp & 0x80) ? (wp | 0xFFFFFF00) : (wp));
        }
    }
    SaveSys_FailLoad (weapBindsStr, *offset);

    *data = tmpData;

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
    long int statPoints =
         (data->xpSystem.strengthLVL & 0x1F)        |
        ((data->xpSystem.agilityLVL  & 0x1F) <<  5) |
        ((data->xpSystem.vitalityLVL & 0x1F) << 10) |
        ((data->xpSystem.defenseLVL  & 0x1F) << 15) |
        ((data->xpSystem.willLVL     & 0x1F) << 20) |
        ((data->xpSystem.magicLVL    & 0x1F) << 25) |
        (((long int) data->xpSystem.techLVL & 0x1F) << 30);
    string rpgSysStr = StrParam ("%.2x%.8x%.4x%.8x%.8x%.8x",
        data->xpSystem.level,
        data->xpSystem.experience,
        data->xpSystem.attrPoints,
        (int)  (statPoints & 0x00000000FFFFFFFF),
        (int) ((statPoints & 0xFFFFFFFF00000000) >> 32),
        data->cash
    );

    SetUserCVarString (playerNum, SD_RPGSYSTEM, rpgSysStr);

    // Script Data
    /*string scriptDataStr = ;
    SetUserCVarString (playerNum, SD_SCRIPTDATA, scriptDataStr);*/
    // Thumper data
    string thumperDefMagStr = s"";
    for (int i = 0; i < THUMPERMAGSIZE; i++)
        thumperDefMagStr = StrParam ("%S%.8x", thumperDefMagStr, data->thumperDef.magShells [i]);
    string thumperDefStr = StrParam ("%S%.8x%.8x", thumperDefMagStr, data->thumperDef.magIndex, data->thumperDef.currentShell);
    SetUserCVarString (playerNum, SD_THUMPERDEF, thumperDefStr);

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

    SavedData_t saveData;

    saveData.name = StrParam ("%tS", playerNum);
    saveData.gender = GetPlayerInfo (playerNum, PLAYERINFO_GENDER);
    saveData.xpSystem = player->xpSystem;     // Level system stuff
    saveData.bankData = player->bankData;     // Bank system stuff
    saveData.cash = player->cash;             // Cash

    // Script data
    saveData.scriptData = player->scriptData; // Misc script data
    saveData.thumperDef = player->thumperDef; // Thumper stuff
    saveData.weapBinds  = player->weapBinds;  // Custom weapon slots stuff

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
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript saveTest: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    SavedData_t saveData;

    saveData.name = s"DUUUUUUUURRRRR";
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