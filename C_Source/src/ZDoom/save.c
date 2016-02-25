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
#define SaveSys_UIError Log ("\CgSave system: Load failed: Couldn't read user info.\n\Cg\t(Debug info: file: %s; line: %d;)", __FILE__, __LINE__) \

#define SaveSys_FailLoad(s, length) \
if (StrLen (s) != length) { \
    Log ("\CgSave system: Load failed: Couldn't read save data.\n\Cg\t(Debug info: file: %s; line: %d;)", __FILE__, __LINE__); \
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
    SavedData_t tmpData;
    int *offset; *offset = 0;

    // Info
    string infoStr = GetUserCVarString (playerNum, SD_INFO);
    if (StrLen (infoStr) < 1) {
        SaveSys_UIError;
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
    tmpData.xpSystem.experience = SaveSys_ReadInt (rpgSysStr, offset, 7);
    tmpData.xpSystem.attrPoints = SaveSys_ReadInt (rpgSysStr, offset, 11);
    tmpData.xpSystem.strengthLVL = SaveSys_ReadInt (rpgSysStr, offset, 3);
    tmpData.xpSystem.staminaLVL = SaveSys_ReadInt (rpgSysStr, offset, 3);
    tmpData.cash = SaveSys_ReadInt (rpgSysStr, offset, 11);
    tmpData.ammoMax = SaveSys_ReadInt (rpgSysStr, offset, 4);
    SaveSys_FailLoad (rpgSysStr, *offset);

    *offset = 0;
    // Script Data
    string scriptDataStr = GetUserCVarString (playerNum, SD_SCRIPTDATA);
    tmpData.scriptData.lastWeapon = SaveSys_ReadInt (scriptDataStr, offset, 6);
    SaveSys_FailLoad (scriptDataStr, *offset);

    *offset = 0;
    // ThumperDef
    string thumperDefStr = GetUserCVarString (playerNum, SD_THUMPERDEF);
    for (int i = 0; i < 5; i++)
        tmpData.thumperDef.magShells [i] = SaveSys_ReadInt (thumperDefStr, offset, 4);
    tmpData.thumperDef.magIndex = SaveSys_ReadInt (thumperDefStr, offset, 4);
    tmpData.thumperDef.currentShell = SaveSys_ReadInt (thumperDefStr, offset, 4);
    SaveSys_FailLoad (thumperDefStr, *offset);

    // Inventory
    if (!SaveSys_LoadInventory (playerNum, data)) {
        Log ("\CgSave system: Load failed: Couldn't load inventory.");
        return FALSE;
    }

    *data = tmpData;

    return TRUE;
}

SavedData_t LoadSaveData (int playerNum) {
    SavedData_t data;

    if (!LoadSaveDataToPointer (playerNum, &data))
        data.isInvalid = TRUE;

    return data;
}

void SaveSaveData (int playerNum, SavedData_t *data) {
    // Info
    string infoStr = StrParam ("%+.4d%+.3d%S%+.3d", SAVESYS_SAVEVERSION, StrLen (data->name), data->name, data->gender);
    SetUserCVarString (playerNum, SD_INFO, infoStr);

    // RPG Systems
    string rpgSysStr = StrParam ("%+.5d%+.6d%+.10d%+.2d%+.2d%+.10d%+.3d", data->xpSystem.level, data->xpSystem.experience, data->xpSystem.attrPoints, data->xpSystem.strengthLVL, data->xpSystem.staminaLVL, data->cash, data->ammoMax);
    SetUserCVarString (playerNum, SD_RPGSYSTEM, rpgSysStr);

    // Script Data
    string scriptDataStr = StrParam ("%+.5d", data->scriptData.lastWeapon);
    SetUserCVarString (playerNum, SD_SCRIPTDATA, scriptDataStr);
    string thumperDefMagStr = s"";
    for (int i = 0; i < 5; i++)
        thumperDefMagStr = StrParam ("%S%+.3d", thumperDefMagStr, data->thumperDef.magShells [i]);
    string thumperDefStr = StrParam ("%S%+.3d%+.3d", thumperDefMagStr, data->thumperDef.magIndex, data->thumperDef.currentShell);
    SetUserCVarString (playerNum, SD_THUMPERDEF, thumperDefStr);

    // Inventory
    SaveSys_SaveInventory (playerNum, data);
}

Script_C void compressTest () {
    string sds = s"fdfdf0000000000000d0000,,,,,,,,,,,,d,,,,,,,,,dfdfd,,,,,,,,,,,,,,,,,,,,888d888888845619";
    string compressedSds = CSC_CompressString (sds);

    SetUserCVarString (PLN, s"S7_SaveData", compressedSds);
}

Script_C void decompressTest () {
    string derpStr =  s"\0x05\0x00\0x00\0x00\0x1F6\0x02\0x00\0x00\0x00\0x0C891981981981";

    string derpcompressed = s"";//CSC_DecompressFILE (derp);

    SetUserCVarString (PLN, s"S7_SaveData", derpcompressed);
}

Script_C void saveTest () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
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
}

Script_C void loadTest () {

}