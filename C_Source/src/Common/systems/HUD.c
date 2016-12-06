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
#include "systems/hud.h"

void HW_SetFont (string font) {
    if (GetCVar (s"screenblocks") <= 11) // if the HUD is shown...
        SetFont (font); // Set the font to "font"
    else // If not
        SetFont (TNT1A0); // Set the font to TNT1A0
}

void HudWeapons (PlayerData_t *player) { // HUD icons and stuff...
    if (!player)
        return;

    /* Firing modes */
    SetFont (TNT1A0); // Set the font to TNT1A0

    if (!player->scriptData.disableHUD) {
        for (int x = 0; x < S7_HW_2ModeWpns_Length; x++) { // Loop through everything in the weapons array
            if (CheckWeapon (S7_HW_2ModeWpns [x] [0])) { // If the player is using this weapon
                if (CheckInventory (S7_HW_2ModeWpns [x] [1])) // If the player has the specified item
                    HW_SetFont (S7_HW_2ModeWpns [x] [2]); // Set the font to the first image
                else // If not
                    HW_SetFont (S7_HW_2ModeWpns [x] [3]); // Set the font to the second image

                break; // Break from the loop
            }
        }
    }

    HudMessage (HUDMSG_PLAIN | HUDMSG_NOTWITHFULLMAP | HUDMSG_LAYER_UNDERHUD, 10001, CR_UNTRANSLATED, 0.0k, 0.0k, 1, 0.0k, 0.0k, 0.0k, "A"); // Display the HUD message
}

Script_C void S7_ShowPop1 () {
    if (!PlayerInGame (PLN))
        return;

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
    {   s"20GA",                    s"S7_20gaShells"            },
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

typedef struct EI_Struct {
    bool isValid;
    string name;
    int health;
    int maxHealth;
} EI_Struct;

Script_LS EI_Struct EI_GetInfo (int playerNum) {
    EI_Struct ret;
    ret.isValid = FALSE;

    if (SetActivator (ActivatorTID (), AAPTR_PLAYER_GETTARGET)) {
        int actorInfo = ClassifyActor (0);
        if (actorInfo & ACTOR_MONSTER && actorInfo & ACTOR_ALIVE && CheckFlag (0, s"shootable") && !(CheckFlag (0, s"noDamage") || CheckFlag (0, s"invulnerable"))) { // Monsters
            ret.name      = GetActorPropertyString (0, APROP_NameTag);

            if (CheckInventory (EMPIDENT)) {
                ret.health    = GetUserVariable (0, EMPHPVAR);
                ret.maxHealth = EMPMHEALTH;
                ret.isValid = TRUE;
            } else {
                ret.health    = GetActorProperty (0, APROP_Health);
                ret.maxHealth = GetActorProperty (0, APROP_SpawnHealth);
                ret.isValid   = TRUE;
            }
        } else if (actorInfo & ACTOR_ALIVE && (actorInfo & ACTOR_PLAYER || actorInfo & ACTOR_BOT || actorInfo & ACTOR_VOODOODOLL)) { // Players/bots
            ret.name      = StrParam ("%tS", playerNum);
            ret.health    = GetActorProperty (0, APROP_Health);
            ret.maxHealth = GetActorProperty (0, APROP_SpawnHealth);
            ret.isValid   = TRUE;

            if (actorInfo & ACTOR_BOT)
                ret.name  = StrParam ("%S (Bot)", ret.name);
            if (actorInfo & ACTOR_VOODOODOLL)
                ret.name  = StrParam ("%S (Voodoo doll)", ret.name);

            // Hacks to work around player health. Apparently players have a default max health of 0
            if (ret.maxHealth == 0) {
                if (ret.health > 100)
                    ret.maxHealth = ret.health;
                else
                    ret.maxHealth = 100;
            }
        }

        if (PLN == playerNum || CheckInventory (FAKEMONSTOKEN))
            ret.isValid = FALSE;
    }

    return ret;
}
#define EMBASEID 13000
void EnemyInfoScript (PlayerData_t *player, EIS_Data_t *data) {
    if (!player)
        return;

    EI_Struct info = EI_GetInfo (PLN);
    int screenblocks = GetCVar (s"screenblocks"); // GetUserCVar (PLN, s"S7_Screenblocks");
    int forceDirCvar = GetUserCVar (PLN, s"S7_EnemyHPBar_ForceDir");

    if (forceDirCvar) {
        if (forceDirCvar == 1)
            screenblocks = 11;
        else if (forceDirCvar >= 2)
            screenblocks = 10;
    }

    if (data->prevScreenblocks != screenblocks || data->prevOn != GetUserCVar (PLN, s"S7_EnemyHPBar_On") || data->prevDisableHUD != player->scriptData.disableHUD)
        data->forceClear = TRUE;

    if (data->forceClear) {
        for (int i = 0; i < 50; i++)
            ClearMessage (EMBASEID + i);

        data->forceClear = FALSE;
    }

    if (info.isValid && screenblocks <= 11 && GetUserCVar (PLN, s"S7_EnemyHPBar_On") && !player->scriptData.disableHUD) {
        SetHudSize (320, 200, FALSE);
        int    x, y,
                  y2;
        int    w, h;
        int    id = EMBASEID + 20;
        bool   vert = FALSE;
        string fg; //, bg;
        if (screenblocks == 11) {
            x =  59; y =  0;
            w = 202; h = 16;
            vert = FALSE;
            fg = s"ENHPBFG1";
            //bg = s"";
        } else if (screenblocks <= 10) {
            x =  5; y =  30;
            w = 16; h = 101;
            vert = TRUE;
            fg = s"ENHPBFG2";
            //bg = s"";
        }

        accum hpPercent = Percent (info.health > 0 ? info.health : 0, info.maxHealth) / 100.0k;
        if (vert) {
            accum thingy = (1.0k - hpPercent) * h;
            y2 = y + RoundA (thingy);
        } else
            w = (int) (hpPercent * w);

        SetHudClipRect (x, vert ? y2 : y, w, h);
        PrintSprite_Str (fg, id--, x * 1.0k + 0.1k, y * 1.0k + 0.1k, 0.1k);
        SetHudClipRect (0, 0, 0, 0);
        //PrintSprite (bg, id--, x * 1.0k, y * 1.0k, 0.1k);

        SetFont (s"SMALLFNT");
        if (GetUserCVar (PLN, s"S7_EnemyHPBar_HPDisp") > 0) {
            if (vert) {
                if (GetUserCVar (PLN, s"S7_EnemyHPBar_HPDisp") >= 2)
                    HudMessage_Str (HUDMSG_PLAIN, id--, CR_DARKGREY, 24.1k, 80.0k, 0.1k, 0.0k, 0.0k, 0.0k, s"%d %%", Percent (info.health, info.maxHealth));
                else if (GetUserCVar (PLN, s"S7_EnemyHPBar_HPDisp") == 1)
                    HudMessage_Str (HUDMSG_PLAIN, id--, CR_DARKGREY, 24.1k, 80.0k, 0.1k, 0.0k, 0.0k, 0.0k, s"%d/%d", info.health, info.maxHealth);
            } else {
                if (GetUserCVar (PLN, s"S7_EnemyHPBar_HPDisp") >= 2)
                    HudMessage_Str (HUDMSG_PLAIN, id--, CR_DARKGREY, 160.0k, 8.0k, 0.1k, 0.0k, 0.0k, 0.0k, s"%d %%", Percent (info.health, info.maxHealth));
                else if (GetUserCVar (PLN, s"S7_EnemyHPBar_HPDisp") == 1) {
                    HudMessage_Str (HUDMSG_PLAIN, id--, CR_DARKGREY, 164.1k, 8.0k, 0.1k, 0.0k, 0.0k, 0.0k, s"%d", info.maxHealth);
                    HudMessage_Str (HUDMSG_PLAIN, id--, CR_DARKGREY, 160.0k, 8.0k, 0.1k, 0.0k, 0.0k, 0.0k, s"/");
                    HudMessage_Str (HUDMSG_PLAIN, id--, CR_DARKGREY, 156.2k, 8.0k, 0.1k, 0.0k, 0.0k, 0.0k, s"%d", info.health);
                }
            }
        }

        if (GetUserCVar (PLN, s"S7_EnemyHPBar_NametagOn")  && info.name) {
            if (vert)
                HudMessage_Str (HUDMSG_PLAIN, id--, CR_DARKGREY,  24.1k,  90.1k, 0.1k, 0.0k, 0.0k, 0.0k, s"%S", info.name);
            else
                HudMessage_Str (HUDMSG_PLAIN, id--, CR_DARKGREY, 160.0k,  19.1k, 0.1k, 0.0k, 0.0k, 0.0k, s"%S", info.name);
        }
    }

    SetHudSize (0, 0, FALSE);

    data->prevScreenblocks = screenblocks;
    data->prevDisableHUD   = player->scriptData.disableHUD;
    data->prevOn           = GetUserCVar (PLN, s"S7_EnemyHPBar_On");
}

/*Script_LS int GetEyesDist (vec3_k playerPos) {
    if (!SetActivator (ActivatorTID (), AAPTR_GET_LINETARGET))
        return 32767.0k;
    return Distance2Vec (playerPos, GetActorPositionVec (0));
}*/

#define SOVERBASEID 14000
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
        SetFont (StrParam ("MAWTSTT%d", staticImage / 2 + 1));
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

#define RADAR_SCALE 10.0k
#define RADAR_MAXDIST 750
#define RADAR_XPOS GetUserCVar (0, s"S7_Radar_XPos")
#define RADAR_YPOS GetUserCVar (0, s"S7_Radar_YPos")
#define RADAR_BASEID 50000
void DrawRadar (PlayerData_t *player) {
    // Uncomment when you have something to use this for.
    /*MonsterInfo_t *monster = monsterList;
    accum x, y, dX, dY, dist;
    int colour, i = 1;
    bool draw;

    SetHudSize (GetUserCVar (0, s"S7_Radar_Width"), GetUserCVar (0, s"S7_Radar_Height"), FALSE);
    SetFont (s"SMALLFNT");
    HudMessage (HUDMSG_PLAIN, RADAR_BASEID, CR_BLUE, RADAR_XPOS + 0.1k, RADAR_YPOS + 0.1k, 0.0k, 0.0k, 0.0k, 0.0k, "@");

    while (TRUE) {
        if (!monster)
            break;

        dist = Distance2 (player->physics.x, player->physics.y, 0.0k, monster->x, monster->y, 0.0k);
        draw = dist <= RADAR_MAXDIST;

        // Coords
        x = player->physics.x - monster->x;
        y = player->physics.y - monster->y;
        dX = x * SinA (-player->physics.angle) + y * CosA (-player->physics.angle);
        dY = x * CosA (-player->physics.angle) - y * SinA (-player->physics.angle);
        dX /= RADAR_SCALE; dX += RADAR_XPOS; dX = (dX >> 16) << 16;
        dY /= RADAR_SCALE; dY += RADAR_YPOS; dY = (dY >> 16) << 16;

        if (dX < 0) dX -= 0.1; else dX += 0.1;
        if (dY < 0) dY -= 0.1; else dY += 0.1;

        if (monster->health <= 0)
            colour = CR_RED;
        else
            colour = CR_DARKGREY;

        if (!monster->removed && draw) {
            HudMessage (HUDMSG_PLAIN, RADAR_BASEID + i++, colour, dX, dY, 0.1k, 0.0k, 0.0k, 0.0k, "o");
        }

        monster = monster->next;
    }

    SetHudSize (0, 0, FALSE);*/
}