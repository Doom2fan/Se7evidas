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

// Gotta figure out a way to make this work without NULLs/0x00... Ugh...
#ifdef NEVERHAPPENING

enum {
    CSC_OP_RAW      = 0x01, // (short amount)
    CSC_OP_DUP      = 0x04, // (short amount)
    CSC_OP_PTR      = 0x07, // (short pointer)
    CSC_OP_NUL      = 0xF0, // (void)
};

#define CSC_OPSTR_RAW s"\x01"
#define CSC_OPSTR_DUP s"\x04"
#define CSC_OPSTR_PTR s"\x07"
#define CSC_OPSTR_NUL s"\xF0"

#define CSC_BUFFERSIZE 1024

#define HARDOUTLIMIT 25000
string CSC_CompressString (string data) {
    string input = data;
    int inputLen = StrLen (input);
    string output [HARDOUTLIMIT];
    int outIndex;
    string curOut;

    if (inputLen < 0)
        inputLen = 0;

    for (int i = 0; i < inputLen; i++) {
        string curChar = StrMid (input, i, 1);
        string nextChar;

        if (i + 1 < inputLen)
            nextChar = StrMid (input, i + 1, 1);
        else
            nextChar = NULL;

        if (StrCmp (curChar, s"\x00") == 0) {
            output [outIndex] = StrParam ("%c%+.5d%S", CSC_OP_RAW, StrLen (curOut), curOut);
            if (outIndex + 1 <= HARDOUTLIMIT) outIndex++; else return NULL;
            curOut = NULL;

            output [outIndex] = StrParam ("%c", CSC_OP_NUL);
            if (outIndex + 1 <= HARDOUTLIMIT) outIndex++; else return NULL;
        } else if (StrCmp (curChar, nextChar) == 0) {
            int dupCharAm = 1;
            string dupChar = curChar;

            while (TRUE) {
                curChar = StrMid (input, i + dupCharAm, 1);

                if ((i + dupCharAm + 1) < inputLen) {
                    nextChar = StrMid (input, i + dupCharAm + 1, 1);
                } else {
                    nextChar = NULL;
                }

                if (StrCmp (curChar, nextChar) == 0) {
                    dupCharAm++;
                } else {
                    break;
                }

                if ((i + dupCharAm + 1) >= inputLen)
                    break;
            }

            if (dupCharAm >= 5 && dupCharAm <= 4294967295) {
                output [outIndex] = StrParam ("%c%+.5d%S", CSC_OP_RAW, StrLen (curOut), curOut);
                if (outIndex + 1 <= HARDOUTLIMIT) outIndex++; else return NULL;
                curOut = NULL;

                output [outIndex] = StrParam ("%c%+.5d%S", CSC_OP_DUP, dupCharAm, dupChar);
                if (outIndex + 1 <= HARDOUTLIMIT) outIndex++; else return NULL;

                i += dupCharAm;
            } else {
                curOut = StrParam ("%S%S", curOut, curChar);
            }
        } else {
            curOut = StrParam ("%S%S", curOut, curChar);
        }
    }

    for (int i = 0; i < outIndex; i++) {
        for (int j = 0; j < i; j++) {
            if (StrCmp (CSC_OPSTR_PTR, StrMid (output [0], 0, 1)) != 0) {
                if (StrCmp (output [i], output [j]) == 0) {
                    output [i] = StrParam ("%c%+.5d", CSC_OP_PTR, j);
                    break;
                }
            }
        }
    }

    string outStr;
    for (int i = 0; i < outIndex; i++) {
        if (i > HARDOUTLIMIT) return NULL;

        outStr = StrParam ("%S%S", outStr, output [i]);
    }

    return outStr;
}

#define CSC_DS_ConsumeInput(str, count) \
StrMid (str, 0, count); \
input = StrMid (str, 0 + count, inputLen - count); \
inputLen = StrLen (input)
#define CSC_DS_PtrIdent s"PTRRTPPTRRTPPTRRTPPTRRTPPTRRTPPTRRTPPTR"
string CSC_DecompressString (string data) {
    string input = data;
    int    inputLen = StrLen (input);
    string output [HARDOUTLIMIT];
    int    curIndex = 0;
    string opcode = s"";
    bool STOPNOW;
    if (inputLen < 0)
        inputLen = 0;

    while (TRUE) {
        if (STOPNOW || StrLen (input) < 1 || curIndex > HARDOUTLIMIT)
            break;

        opcode = CSC_DS_ConsumeInput (input, 1);
        if (StrCmp (opcode, CSC_OPSTR_RAW) == 0) {
            PrintBold ("RAW");
            string rawLenStr = CSC_DS_ConsumeInput (input, 6);
            int    rawLen = StrToInt (rawLenStr);
            if (rawLen < 1) return NULL;
            string rawText = CSC_DS_ConsumeInput (input, rawLen);
            output [curIndex] = rawText;

            curIndex++;
        } else if (StrCmp (opcode, CSC_OPSTR_DUP) == 0) {
            PrintBold ("DUP");
            string dupAmStr = CSC_DS_ConsumeInput (input, 6);
            int    dupAm = StrToInt (dupAmStr);
            if (dupAm < 1) return NULL;
            string dupChar = CSC_DS_ConsumeInput (input, 1);

            for (int i = 0; i < dupAm; i++)
                output [curIndex] = StrParam ("%S%S", output, dupChar);

            curIndex++;
        } else if (StrCmp (opcode, CSC_OPSTR_NUL) == 0) {
            PrintBold ("NUL");
            output [curIndex] = s"\x00";

            curIndex++;
        } else if (StrCmp (opcode, CSC_OPSTR_PTR) == 0) {
            PrintBold ("PTR");
            string ptrLoc = CSC_DS_ConsumeInput (input, 6);
            output [curIndex] = StrParam ("%S%S", CSC_DS_PtrIdent, ptrLoc);

            curIndex++;
        } else {
            PrintBold ("else");
            return NULL;
        }
    }

    string ret = s"";

    for (int i = 0; i < curIndex; i++) {
        if (StrCmp (output [i], CSC_DS_PtrIdent) == 38) {
            string ptrLocStr = StrRight (output [i], 39);
            int    ptrLoc = StrToInt (ptrLocStr);
            if (ptrLoc > HARDOUTLIMIT) return NULL;

            ret = StrParam ("%S%S", ret, output [ptrLoc]);
        } else {
            ret = StrParam ("%S%S", ret, output [i]);
        }
    }

    return ret;
}

#ifdef DEBUG

Script_C void compressTest () {
    string sds = s"fdfdf000000000000000000000d0000,,,,,,,,,,,,d,,,,,,,,,dfdfd,,,,,,,,,,,,,,,,,,,,888d888888845619111111111111111111fdfdf111111111111111111111fdfdf11111111111111111111111fdfdf1111111111111111fdfdf111111111";
    string compressedSds = CSC_CompressString (sds);

    SetUserCVarString (PLN, s"S7_TestData", compressedSds);
}

Script_C void decompressTest () {
    string derpStr = GetUserCVarString (PLN, s"S7_TestData");
    PrintBold ("derpStr: %S", derpStr);

    string derpcompressed = CSC_DecompressString (derpStr);

    SetUserCVarString (PLN, s"S7_TestData", derpcompressed);
}

#endif

#else

string CSC_CompressString (string data) {
    return data;
}

string CSC_DecompressString (string data) {
    return data;
}

#endif