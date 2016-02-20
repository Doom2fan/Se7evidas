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
#include "save.h"

void GetSaveDataToPointer (int playerNum, SavedData_t *data) {
    
}

SavedData_t GetSaveData (int playerNum) {
    SavedData_t data;

    GetSaveDataToPointer (playerNum, &data);

    return data;
}

void SetSaveData (int playerNum, SavedData_t *data) {

}

Script_C void compressTest () {
    string sds = s"fdfdf0000000000000d0000,,,,,,,,,,,,d,,,,,,,,,dfdfd,,,,,,,,,,,,,,,,,,,,888d888888845619";
    string compressedSds = CSC_CompressString (sds);

    SetUserCVarString (PLN, s"S7_SaveData", compressedSds);
}

Script_C void decompressText () {
    string derpStr = s"\0x05\0x00\0x00\0x00\0x1F6\0x02\0x00\0x00\0x00\0x0C891981981981";
    FILE *derp = fopen (NULL, 0, derpStr, "derpStr", "rw");

    string derpcompressed = CSC_DecompressFILE (derp)/

    SetUserCVarString (PLN, s"S7_SaveData", derpcompressed);
}