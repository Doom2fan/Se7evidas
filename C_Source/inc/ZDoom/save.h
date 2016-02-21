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

#ifndef SAVE_H
#define SAVE_H

#include <ACS_ZDoom.h>

// Defines
#define SAVESYS_SAVEVERSION 1

#define SD_INFO       s"S7_SaveData_Info"
#define SD_XPSYSTEM   s"S7_SaveData_XPSystem"
#define SD_SCRIPTDATA s"S7_SaveData_ScriptData"
#define SD_THUMPERDEF s"S7_SaveData_ThumperDef"
#define SD_INV        s"S7_SaveData_Inv"
#define SD_INV1       s"S7_SaveData_Inv1"
#define SD_INV2       s"S7_SaveData_Inv2"
#define SD_INV3       s"S7_SaveData_Inv3"
#define SD_INV4       s"S7_SaveData_Inv4"
#define SD_INV5       s"S7_SaveData_Inv5"
#define SD_INV6       s"S7_SaveData_Inv6"
#define SD_INV7       s"S7_SaveData_Inv7"
#define SD_INV8       s"S7_SaveData_Inv8"
#define SD_INV9       s"S7_SaveData_Inv9"
#define SD_INV10      s"S7_SaveData_Inv10"
#define SD_INV11      s"S7_SaveData_Inv11"
#define SD_INV12      s"S7_SaveData_Inv12"
#define SD_INV13      s"S7_SaveData_Inv13"
#define SD_INV14      s"S7_SaveData_Inv14"
#define SD_INV15      s"S7_SaveData_Inv15"
#define SD_INV16      s"S7_SaveData_Inv16"
#define SD_INV17      s"S7_SaveData_Inv17"
#define SD_INV18      s"S7_SaveData_Inv18"
#define SD_INV19      s"S7_SaveData_Inv19"
#define SD_INV20      s"S7_SaveData_Inv20"
#define SD_INV21      s"S7_SaveData_Inv21"
#define SD_INV22      s"S7_SaveData_Inv22"
#define SD_INV23      s"S7_SaveData_Inv23"
#define SD_INV24      s"S7_SaveData_Inv24"
#define SD_INV25      s"S7_SaveData_Inv25"

// Prototypes
bool        LoadSaveDataToPointer (int playerNum, SavedData_t *data);
SavedData_t LoadSaveData          (int playerNum);
void        SaveSaveData          (int playerNum, SavedData_t *data);

#endif