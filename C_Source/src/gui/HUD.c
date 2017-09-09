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
#include "systems/monster_stuff.h"
#include "weapons/weap_data.h"
#include "gui/HUD.h"

Script_C void S7_ShowPop1 () {
    if (!PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        DebugLog ("\CgScript S7_ShowPop1: Fatal error: Invalid or NULL player struct for player %d.", PLN);
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
   HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_OVERHUD, id, color, (x) + 0.1k, (y) + 0.1k, 0.1k, 0.0k, 0.0k, 0.0k, __VA_ARGS__) \
  )
#define SP1BASEID 11000

#define SPopPrintList(header, array, id, x, y, numXOffset) \
  ( \
   SPopPrintListFunc (header, array, ArraySize (array), id, x, y, numXOffset) \
  )
void SPopPrintListFunc (string header, string listArray [] [2], int size, int *id, accum *x, accum *y, accum numXOffset) {
    SPopPrintText ((*id)++, (*x) - 6.0k, (*y), CR_WHITE, "%LS:", header);
    (*y) += 6.0k;
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
    SPopPrintText ((*id)++, (*x) - 6.0k, (*y), CR_WHITE, "%LS:", header);
    (*y) += 6.0k;
    for (int i = 0; i < size; i++, (*y) += 6.0k) {
        if (StrLen (listArray [i] [1]) <= 0) {
            if (StrLen (listArray [i] [0]) > 0)
                SPopPrintText ((*id)++, (*x) - 3.0k, (*y), CR_WHITE, "%LS:", listArray [i] [0]);
        } else {
            int color = CheckInventory (listArray [i] [1]) ? CR_WHITE : CR_DARKGREY;
            SPopPrintText ((*id)++, (*x), (*y), color, "%LS", listArray [i] [0]);
        }
    }
}

static string AmmoList [] [2] = {
    {   s"POP_CARTRIDGES",          s""                         },
    {   s"9MM",                     s"S7_9mmCartridges"         },
    {   s"44M",                     s"S7_44MCartridges"         },
    {   s"762X39",                  s"S7_762x39Cartridges"      },
    {   s"45WW",                    s"S7_45WWCartridges"        },
    {   s"20GA",                    s"S7_20gaShells"            },
    {   s"12GA",                    s"S7_12gaShells"            },
    {   s"",                        s""                         },

    {   s"POP_BATTERIES",           s""                         },
    {   s"POP_CELLS",               s"S7_Cells"                 },
    {   s"POP_FBSYSCELLS",          s"S7_FBSysCells"            },
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
static string WeaponsList [] [2] = {
    {   s"POP_PRI",                 s""                             },
    {   s"AMG",                     s"S7_AMG"                       },
    {   s"FAUCHARD",                s"S7_Fauchard"                  },
    {   s"HITTERSMG",               s"S7_HitterSMG"                 },
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
static string LootList [] [2] = {
    {   s"EMPTTHGR",                s"S7_Thumper_Used"              },
};
void ShowPop (PlayerData_t *player, SP_Data_t *data) {
    if (!player)
        return;

    int dHUDPopupNum, dHUDPageNum;

    if (player->scriptData.disableHUD) {
        dHUDPopupNum = player->scriptData.popupNum;
        dHUDPageNum  = player->scriptData.pPageNum;
        player->scriptData.popupNum = player->scriptData.pPageNum = 0;
    }

    if ((player->scriptData.popupNum != data->prevPopupNum) ||
        (player->scriptData.pPageNum != data->prevPageNum)  ) {
        for (int i = 0; i < 100; i++)
            ClearMessage (SP1BASEID + 1 + i);
    }

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
    }

    if (player->scriptData.disableHUD) {
        player->scriptData.popupNum = dHUDPopupNum;
        player->scriptData.pPageNum = dHUDPageNum;
    }

    data->prevPopupNum = player->scriptData.popupNum;
    data->prevPageNum  = player->scriptData.pPageNum;

    SetHudSize (0, 0, FALSE);
}

/*Script_LS int GetEyesDist (vec3_k playerPos) {
    if (!SetActivator (ActivatorTID (), AAPTR_GET_LINETARGET))
        return 32767.0k;
    return Distance2Vec (playerPos, GetActorPositionVec (0));
}*/

#define SOVERBASEID 14000
const string SO_StaticImage [] = { s"MATWSTT1", s"MATWSTT2", s"MATWSTT3", s"MATWSTT4", };
void ScreenOverlays (PlayerData_t *player) {
    // Static
    if (MapData.mapEvent == MEVNT_PerfectHatred) {
        int   staticImage;
        accum staticAlpha = 0.025k;
        staticImage = player->scriptData.prevStaticImage;
        if (staticImage < 0 || staticImage >= 7)
            staticImage = 0;
        else
            staticImage++;

        SetHudSize (640, 480, FALSE);
        SetFont (SO_StaticImage [staticImage / 2]);
        HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_UNDERHUD | HUDMSG_ALPHA | HUDMSG_FADEOUT, SOVERBASEID + 1, CR_UNTRANSLATED, -106.1k, 0.1k, 0.5k, 0.5k, staticAlpha, 0.0k, "A");
        SetHudSize (0,   0,   FALSE);
        player->scriptData.prevStaticImage = staticImage;
    }

    // EYES overlay
    /*vec3_k playerPos;
    playerPos.x = player->physics.x; playerPos.y = player->physics.y; playerPos.z = player->physics.z;
    accum eyesDist = GetEyesDist (playerPos);
    accum alpha;

    SetFont (s"SMALLFNT");
    PrintBold ("%k", eyesDist);

    alpha = ClampAccum (CheckInventory (s"S7_MEATW_EyesCounter") + (eyesDist <= 512.0k ? eyesDist / 512.0k : 0.0k), 0.0k, 1.0k);

    SetHudSize (640, 480, FALSE);
    SetFont (s"MATWEYES");
    if (alpha > 0.0k)
        HudMessage (HUDMSG_PLAIN | HUDMSG_LAYER_UNDERHUD | HUDMSG_ALPHA | HUDMSG_FADEOUT, SOVERBASEID + 1, CR_UNTRANSLATED, -266.1k, 0.1k, 0.5k, 0.5k, alpha, 0.0k, "A");
    SetHudSize (0, 0, FALSE);

    player->scriptData.prevEyesDist = eyesDist;
    TakeInventory (s"S7_MEATW_EyesCounter", 0x7FFFFFFF);*/
}