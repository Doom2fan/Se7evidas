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
#include "save_inv.h"

#define INVCVARMAXLEN (MAXCVARSIZ) - 18
#define INVINFOSIZE (ArraySize (InvInfo))

SaveInv_InvInfo InvInfo [] = {
    // Ammo
    { .name = s"S7_9mmCartridges",              },
    { .name = s"S7_45ACPCartridges",            },
    { .name = s"S7_44MCartridges",              },
    { .name = s"S7_762x39Cartridges",           },
    { .name = s"S7_20gaShells",                 },
    { .name = s"S7_Cells",                      },
    { .name = s"S7_Thumper_PExp",               },
    { .name = s"S7_Thumper_PFrag",              },
    { .name = s"S7_Thumper_PTherm",             },
    { .name = s"S7_Thumper_PFlare",             },
    { .name = s"S7_Thumper_PCluster",           },
    { .name = s"S7_Thumper_PNail",              },
    { .name = s"S7_Thumper_PNGas",              },
    { .name = s"S7_BackpackToken",              },
    // Weapons and etc weapon info
    { .name = s"S7_AMG",                        }, // Mars Assault Rifle
    { .name = s"S7_AMGMag",                     },
    { .name = s"S7_HitterSMG",                  }, // Hitter SMG
    { .name = s"S7_HitterSMGClip",              },
    { .name = s"S7_HitterSMGUpperJammed",       },
    { .name = s"S7_HitterSMGLowerJammed",       },
    { .name = s"S7_ManxCarbine",                }, // Manx Carbine
    { .name = s"S7_ManxCarbineClip",            },
    { .name = s"S7_PlasmaGun",                  }, // Plasma MG
    { .name = s"S7_PlasmaGunMag",               },
    { .name = s"S7_PlasmaGun_Charge",           },
    { .name = s"S7_PrettyShootyIonCannonGun",   }, // Mjolnir Ion Cannon
    { .name = s"S7_Shotgun",                    }, // Lucifer Combat Shotgun
    { .name = s"S7_ShotgunMag",                 },
    { .name = s"S7_ShotgunLoaded",              },
    { .name = s"S7_Thumper",                    }, // Thumper 50mm GL
    { .name = s"S7_ThumperSelectedPool",        },
    { .name = s"S7_ThumperChambered",           },
    { .name = s"S7_Raptor",                     }, // Raptor
    { .name = s"S7_RaptorClip",                 },
    { .name = s"S7_Revolver",                   }, // Deathbringer
    { .name = s"S7_RevolverClip",               },
    { .name = s"S7_TEC9",                       }, // Kronos
    { .name = s"S7_TEC9Clip",                   },
    // Health
    { .name = s"S7_Medikit",                    },
    { .name = s"S7_Stimpack",                   },
    // Loot
    { .name = s"S7_Thumper_Used",               },
};

bool SaveSys_SaveInventory (int playerNum, SavedData_t *data) {
    string output = s"";
    for (int i = 0; i < INVINFOSIZE; i++) {
        output = StrParam ("%S%+.5d%+.10d", output, i, CheckInventory (InvInfo [i].name));
    }

    string outputArr [INVCVARCOUNT];

    // Add compression to this later
    int index = 1;
    outputArr [0] = StrMid (output, 0, INVCVARMAXLEN);
    output = StrMid (output, INVCVARMAXLEN, StrLen (output) + INVCVARMAXLEN);
    while (TRUE) {
        if (StrLen (output) < INVCVARMAXLEN)
            break;
        if (index >= INVCVARCOUNT)
            return FALSE;

        outputArr [index] = StrMid (output, 0, INVCVARMAXLEN);
        output = StrMid (output, INVCVARMAXLEN, StrLen (output) + INVCVARMAXLEN);
        index++;
    }
    if (StrLen (output) > 1) {
        if (index >= INVCVARCOUNT)
            return FALSE;

        outputArr [index] = StrMid (output, 0, INVCVARMAXLEN);
        output = StrMid (output, INVCVARMAXLEN, StrLen (output) + INVCVARMAXLEN);
        index++;
    }

    int i = 0;
    for (; i < INVCVARCOUNT; i++) {
        SetUserCVarString (playerNum, StrParam ("%S%d", SD_INV, i + 1), outputArr [i]);
    }
    for (; i < INVCVARCOUNT; i++) {
        SetUserCVarString (playerNum, StrParam ("%S%d", SD_INV, i + 1), s"");
    }

    return TRUE;
}

#define INV_ENTRY_LEN (6 + 11)
bool SaveSys_LoadInventory (int playerNum, SavedData_t *data) {
    string           input = s""; // Define input and initialize it to ""
    SaveInv_InvInfo *prev  = NULL;
    SaveInv_InvInfo *cur   = NULL;
    int             *offset; *offset = 0;

    for (int i = 0; i < INVCVARCOUNT; i++) // Loop through the inventory data CVars
        input = StrParam ("%S%S", input, GetUserCVarString (playerNum, StrParam ("%S%d", SD_INV, i + 1)));

    int length = StrLen (input);
    int count = length / INV_ENTRY_LEN;

    if (length % INV_ENTRY_LEN > 0)
        return FALSE;

    for (int i = 0; i < count; i++) {
        int type = SaveSys_ReadInt (input, offset, 6);
        int amount = SaveSys_ReadInt (input, offset, 11);

        if (type < 0 || type > INVINFOSIZE)
            return FALSE;

        SaveInv_InvInfo *inv = malloc (sizeof (SaveInv_InvInfo)); // Define inv pointer and point it to a new memory area
        inv->name = InvInfo [type].name;
        inv->amount = amount;
        inv->next = prev;
        prev = inv;
    }

    cur = prev;
    while (TRUE) {
        if (!cur)
            break;

        SetInventory (cur->name, cur->amount);
        // Update prev and cur
        prev = cur;
        cur = cur->next;
        // Free prev
        prev->next = NULL;
        free (prev);
    }

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