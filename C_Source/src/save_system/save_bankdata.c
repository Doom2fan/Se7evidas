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
#include "save_system/save.h"
#include "save_system/save_bankdata.h"

bool SaveSys_SaveBank (int playerNum, SavedData_t *data) {
    string output = s"";
    output = StrParam ("%S%.16x%.8x", output, data->bankData.cash, ArraySize (data->bankData.itemStorage));
    for (int i = 0; i < ArraySize (data->bankData.itemStorage); i++)
        output = StrParam ("%S%.2x%.2x%.4x", output, data->bankData.itemStorage [i].type, data->bankData.itemStorage [i].id, data->bankData.itemStorage [i].amount);

    // Add compression to this someday maybe
    int index = 1;
    SetUserCVarString (playerNum, StrParam ("%S%d", SD_BANKDATA, index++), StrMid (output, 0, BANKCVARMAXLEN));
    output = StrMid (output, BANKCVARMAXLEN, StrLen (output) + BANKCVARMAXLEN);
    while (TRUE) {
        if (StrLen (output) < BANKCVARMAXLEN)
            break;
        if (index >= BANKMAXCVARS)
            return FALSE;

        SetUserCVarString (playerNum, StrParam ("%S%d", SD_BANKDATA, index++), StrMid (output, 0, BANKCVARMAXLEN));
        output = StrMid (output, BANKCVARMAXLEN, StrLen (output) + BANKCVARMAXLEN);
    }
    if (StrLen (output) > 1) {
        if (index >= BANKMAXCVARS)
            return FALSE;

        SetUserCVarString (playerNum, StrParam ("%S%d", SD_BANKDATA, index++), StrMid (output, 0, BANKCVARMAXLEN));
        output = StrMid (output, BANKCVARMAXLEN, StrLen (output) + BANKCVARMAXLEN);
    }
    for (; index < BANKMAXCVARS; index++)
        SetUserCVarString (playerNum, StrParam ("%S%d", SD_BANKDATA, index), s"");

    return TRUE;
}

bool SaveSys_LoadBank (int playerNum, SavedData_t *data) {
    string input = s""; // Define input and initialize it to ""
    int   *offset; *offset = 0;

    for (int i = 0; i < BANKMAXCVARS; i++) // Loop through the bank data CVars
        input = StrParam ("%S%S", input, GetUserCVarString (playerNum, StrParam ("%S%d", SD_BANKDATA, i + 1)));

    int length = StrLen (input);
    data->bankData.cash = SaveSys_ReadLongInt (input, offset, 16);
    int count = SaveSys_ReadInt (input, offset, 4);
    for (int i = 0; i < count; i++) {
        int type = SaveSys_ReadInt (input, offset, 2);
        data->bankData.itemStorage [i].type = ((type & 0x80) ? (type | 0xFFFFFF00) : type);
        data->bankData.itemStorage [i].id = SaveSys_ReadInt (input, offset, 2);
        data->bankData.itemStorage [i].amount = SaveSys_ReadInt (input, offset, 4);
    }

    if (length < *offset)
        return FALSE;

    return TRUE;
}

/* Use this later for the bank system loading routine:
    #define BANK_ENTRY_LEN (6 + 11)
    #define BANKINFOSIZE (ArraySize (bankInfo))
    ...
    string input = s""; // Define input and initialize it to ""

    for (int i = 0; i < BANKCVARCOUNT; i++) // Loop through the inventory data CVars
        input = StrParam ("%S%S", input, GetUserCVarString (playerNum, StrParam ("%S%d", SD_BANK, i + 1)));

    if (StrLen (input) % BANK_ENTRY_LEN > 0)
        return FALSE;
*/