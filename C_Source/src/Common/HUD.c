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
#include "hud.h"

const string S7_HW_2ModeWpns [] [4] = {
    {
        s"S7_TEC9",
        s"S7_TEC9_Burst",
        s"BrstFire",
        s"FullAuto"
    },
    {
        s"S7_AMG",
        s"S7_AMG_Burst",
        s"BrstFire",
        s"FullAuto"
    },
    {
        s"S7_PlasmaGun",
        s"S7_PlasmaGun_Semi",
        s"SemiAuto",
        s"FullAuto"
    },
    {
        s"S7_ManxCarbine",
        s"S7_ManxCarbine_Semi",
        s"SemiAuto",
        s"FullAuto"
    }
};

void HW_SetFont (string font) {
    if (GetCVar (s"screenblocks") <= 11) // if the HUD is shown...
        SetFont (font); // Set the font to "font"
    else // If not
        SetFont (TNT1A0); // Set the font to TNT1A0
}

void HudWeapons () { // HUD icons and stuff...
    /* Firing modes */
    SetFont (TNT1A0); // Set the font to TNT1A0
    for (int x = 0; x < ArraySize (S7_HW_2ModeWpns); x++) { // Loop through everything in the weapons array
        if (CheckWeapon (S7_HW_2ModeWpns [x] [0])) { // If the player is using this weapon
            if (CheckInventory (S7_HW_2ModeWpns [x] [1])) // If the player has the specified item
                HW_SetFont (S7_HW_2ModeWpns [x] [2]); // Set the font to the first image
            else // If not
                HW_SetFont (S7_HW_2ModeWpns [x] [3]); // Set the font to the second image

            break; // Break from the loop
        }
    }
    HudMessage (HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP | HUDMSG_LAYER_UNDERHUD, 10001, CR_UNTRANSLATED, 0.0k, 0.0k, 1, 0.0, 0.0, 0.0, "A"); // Display the HUD message
}

Script_C void S7_ShowPop1 () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ShowPop1: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    if (player->scriptData.popupNum == 1) {
        if (player->scriptData.pPageNum < 2)
            player->scriptData.pPageNum++;
        else
            player->scriptData.popupNum = 0;
    } else {
        player->scriptData.pPageNum = 0;
        player->scriptData.popupNum = 1;
    }
}

#define SPopPrintText(id, x, y, color, ...) \
  ( \
   HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_OVERHUD, id, color, (x) + 0.1k, (y) + 0.1k, 0.1k, 0.0, 0.0, 0.0, __VA_ARGS__) \
  )
#define SP1BASEID 11000

#define SPopPrintList(header, array, id, x, y, numXOffset) \
  ( \
   SPopPrintListFunc (header, array, ArraySize (array), id, x, y, numXOffset) \
  )
void SPopPrintListFunc (string header, string listArray [] [2], int size, int *id, accum *x, accum *y, accum numXOffset) {
    SPopPrintText ((*id), (*x) - 6.0k, (*y), CR_WHITE, "%LS:", header);
    (*y) += 6.0k;
    (*id)++;
    for (int i = 0; i < size; i++, (*y) += 6.0k) {
        if (StrLen (listArray [i] [1]) <= 0) {
            if (StrLen (listArray [i] [0]) > 0) {
                SPopPrintText ((*id), (*x) - 3.0k, (*y), CR_WHITE, "%LS:", listArray [i] [0]);
                (*id) += 1;
            }
        } else {
            SPopPrintText ((*id),     (*x),              (*y), CR_WHITE, "%LS:",                 listArray [i] [0] );
            SPopPrintText ((*id) + 1, (*x) + numXOffset, (*y), CR_WHITE,   "%d", CheckInventory (listArray [i] [1]));

            (*id) += 2;
        }
    }
}

#define SPopPrintSwitchList(header, array, id, x, y) \
  ( \
   SPopPrintSwitchListFunc (header, array, ArraySize (array), id, x, y) \
  )
void SPopPrintSwitchListFunc (string header, string listArray [] [2], int size, int *id, accum *x, accum *y) {
    SPopPrintText ((*id), (*x) - 6.0k, (*y), CR_WHITE, "%LS:", header);
    (*y) += 6.0k;
    (*id)++;
    for (int i = 0; i < size; i++, (*y) += 6.0k) {
        if (StrLen (listArray [i] [1]) <= 0) {
            if (StrLen (listArray [i] [0]) > 0) {
                SPopPrintText ((*id), (*x) - 3.0k, (*y), CR_WHITE, "%LS:", listArray [i] [0]);
                (*id) += 1;
            }
        } else {
            int color = CheckInventory (listArray [i] [1]) ? CR_WHITE : CR_DARKGREY;
            SPopPrintText ((*id), (*x), (*y), color, "%LS", listArray [i] [0]);
            (*id) += 1;
        }
    }
}

string AmmoList [] [2] = {
    {   s"POP_CARTRIDGES",          s""                         },
    {   s"9MM",                     s"S7_9mmCartridges"         },
    {   s"44M",                     s"S7_44MCartridges"         },
    {   s"762X39",                  s"S7_762x39Cartridges"      },
    {   s"20GA",                    s"S7_20gaShells"            },
    {   s"",                        s""                         },

    {   s"POP_BATTERIES",           s""                         },
    {   s"CELLS",                   s"S7_Cells"                 },
    {   s"",                        s""                         },

    {   s"POP_THGRENADES",          s""                         },
    {   s"POP_TH_ALL",              s"S7_Thumper_PUnified"      },
    {   s"POP_TH_EXP",              s"S7_Thumper_PExp"          },
    {   s"POP_TH_FRAG",             s"S7_Thumper_PFrag"         },
    {   s"POP_TH_THRM",             s"S7_Thumper_PTherm"        },
    {   s"POP_TH_FLRE",             s"S7_Thumper_PFlare"        },
    {   s"POP_TH_CLST",             s"S7_Thumper_PCluster"      },
    {   s"POP_TH_NAIL",             s"S7_Thumper_PNail"         },
    {   s"POP_TH_NGAS",             s"S7_Thumper_PNGas"         },
};
string WeaponsList [] [2] = {
    {   s"POP_PRI",                 s""                             },
    {   s"AMG",                     s"S7_AMG"                       },
    {   s"MANXCARBINE",             s"S7_ManxCarbine"               },
    {   s"SHOTGUN",                 s"S7_Shotgun"                   },
    {   s"",                        s""                             },
    
    {   s"POP_SEC",                 s""                             },
    {   s"RAPTOR",                  s"S7_Raptor"                    },
    {   s"TEC9",                    s"S7_TEC9"                      },
    {   s"REVOLVER",                s"S7_Revolver"                  },
    {   s"",                        s""                             },
    
    {   s"POP_SP",                  s""                             },
    {   s"THUMPER",                 s"S7_Thumper"                   },
    {   s"PLASMAGUN",               s"S7_PlasmaGun"                 },
    {   s"IONCANNON",               s"S7_PrettyShootyIonCannonGun"  },
};
string LootList [] [2] = {
    {   s"EMPTTHGR",                s"S7_Thumper_Used"              },
};
void ShowPop1 (PlayerData_t *player) {
    if (!player)
        return;

    SetHudSize (320, 200, FALSE);
    int id = SP1BASEID;
    if (player->scriptData.popupNum == 1) {
        SetFont (s"FSHUDFNT");
        if (player->scriptData.pPageNum == 0) {
            accum x = 10.0k; accum y = 12.0k;
            SPopPrintSwitchList (s"POP_WEAPON", WeaponsList, &id, &x, &y);
        } else if (player->scriptData.pPageNum == 1) {
            accum x = 10.0k; accum y = 12.0k;
            SPopPrintList (s"POP_AMMO", AmmoList, &id, &x, &y, 106.0k);
        } else if (player->scriptData.pPageNum == 2) {
            accum x = 10.0k; accum y = 12.0k;
            SPopPrintList (s"POP_LOOT", LootList, &id, &x, &y, 126.0k);
        }
    } else {
        ClearMessage (SP1BASEID);
        for (int i = 0; i < ArraySize (AmmoList) * 2; i++)
            ClearMessage (SP1BASEID + 1 + i);
    }
    SetHudSize (0, 0, FALSE);
}