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
enum {
    CSC_OP_RAW      = 0x02, // (int amount)
    CSC_OP_DUP      = 0x05, // (int amount)
    CSC_OP_PTR      = 0x06, // (int pointer)
    CSC_OP_NUL      = 0xF0, // (void)
};

#define HARDOUTLIMIT 5000
string CSC_CompressString (string data) {
    int dataLen = StrLen (data);
    string output [HARDOUTLIMIT];
    int outIndex;
    string curOut;

    for (int i = 0; i < dataLen; i++) {
        string curChar = StrMid (data, i, 1);
        string nextChar;

        if (i + 1 < dataLen)
            nextChar = StrMid (data, i + 1, 1);
        else
            nextChar = NULL;

        if (StrCmp (curChar, s"\0x00") == 0) {
            output [outIndex] = StrParam ("%c%c%S", CSC_OP_RAW, StrLen (curOut), curOut);
            if (outIndex + 1 <= HARDOUTLIMIT) outIndex++; else return NULL;
            curOut = NULL;

            output [outIndex] = StrParam ("%c", CSC_OP_NUL);
            if (outIndex + 1 <= HARDOUTLIMIT) outIndex++; else return NULL;
        } else if (StrCmp (curChar, nextChar) == 0) {
            int dupCharAm = 1;
            string dupChar = curChar;

            while (true) {
                curChar = StrMid (data, i + dupCharAm, 1);

                if ((i + dupCharAm + 1) < dataLen) {
                    nextChar = StrMid (data, i + dupCharAm + 1, 1);
                } else {
                    nextChar = NULL;
                }

                if (StrCmp (curChar, nextChar) == 0) {
                    dupCharAm++;
                } else {
                    break;
                }

                if ((i + dupCharAm + 1) >= dataLen)
                    break;
            }

            if (dupCharAm >= 5 && dupCharAm <= 4294967295) {
                output [outIndex] = StrParam ("%c%.4c%S", CSC_OP_RAW, StrLen (curOut), curOut);
                if (outIndex + 1 <= HARDOUTLIMIT) outIndex++; else return NULL;
                curOut = NULL;

                output [outIndex] = StrParam ("%c%.4c%S", CSC_OP_DUP, dupCharAm, dupChar);
                if (outIndex + 1 <= HARDOUTLIMIT) outIndex++; else return NULL;

                i += dupCharAm;
            } else {
                curOut = StrParam ("%S%S", curOut, curChar);
            }
        } else {
            curOut = StrParam ("%S%S", curOut, curChar);
        }
    }

    string outStr;
    for (int j = 0; j < outIndex; j++) {
        if (j > HARDOUTLIMIT) return NULL;

        outStr = StrParam ("%S%S", outStr, output [j]);
    }

    return outStr;
}

string CSC_DecompressFILE (FILE *file) {
    string derp = s"";

    while (feof (file)) {

    }

    return derp;
}