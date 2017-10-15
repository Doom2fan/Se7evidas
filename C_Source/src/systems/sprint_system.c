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
#include "weapons/weapon_stuff.h"
#include "systems/stamina.h"
#include "systems/sprint_system.h"

Script_C void S7_SprintSystem (PlayerData_t *player) {
    Start:
    // Not needed or desired in TitleMaps.
    if (ServerData.gameType == GAME_TITLE_MAP || !PlayerInGame (PLN))
        return;

    if (!player) {
        DebugLog ("\CgScript S7_SprintSystem: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    int tics,
        forwardMove,
        sideMove;

    while (TRUE) {
        if (!PlayerInGame (PLN))
            return;

        forwardMove = GetPlayerInput (-1, MODINPUT_FORWARDMOVE);
        sideMove    = GetPlayerInput (-1, MODINPUT_SIDEMOVE);

        if (CheckWeapon (SPRINTWEAPON) && !player->SprintDef.Sprinting) {
            SetActorPropertyFixed (0, APROP_Speed, player->SprintDef.OldSpeed);
            player->SprintDef.Sprinting = FALSE;
            tics = 0;
            DisableWeapon (SPRINTWEAPON, SPRINTINGTOKEN, player);
        }
        if (KeyDownMOD (BT_USER1) &&
            !player->SprintDef.Sprinting &&
            CheckInventory (STAMINATOKEN) >= 5 && !CheckInventory (DYINGTOKEN) &&
            !player->scriptData.staminaEmpty && !player->SprintDef.disable && !player->scriptData.beamGrab) {
            player->SprintDef.Sprinting = TRUE;
            player->SprintDef.OldSpeed = GetActorPropertyFixed (0, APROP_Speed);
            DisableWeapon (SPRINTWEAPON, SPRINTINGTOKEN, player);
        }
        if (KeyUpMOD (BT_USER1) && player->SprintDef.Sprinting) {
            SetActorPropertyFixed (0, APROP_Speed, player->SprintDef.OldSpeed);
            player->SprintDef.Sprinting = FALSE;
            tics = 0;
            DisableWeapon (SPRINTWEAPON, SPRINTINGTOKEN, player);
        }
        if (CheckInventory (SPRINTINGTOKEN) && player->SprintDef.Sprinting) {
            if (CheckInventory (STAMINATOKEN) >= 5) {
                if (CheckInventory (SPRINTINGTOKEN) && tics >= 5 && (forwardMove != 0 || sideMove != 0)) {
                    tics = 0;
                    if (GetVelocity () > 0.0k) {
                        TakeInventory (STAMINATOKEN, 5);
                        player->health.stamina = CheckInventory (STAMINATOKEN);
                    }
                }
                if (CheckInventory (STAMINATOKEN) < 5 || CheckInventory (DYINGTOKEN) || player->SprintDef.disable || player->scriptData.beamGrab) {
                    SetActorPropertyFixed (0, APROP_Speed, player->SprintDef.OldSpeed);
                    player->SprintDef.Sprinting = FALSE;
                    player->scriptData.staminaEmpty = 1;
                    DisableWeapon (SPRINTWEAPON, SPRINTINGTOKEN, player);
                    goto Start;
                }

                accum speedBonus = 1.0k + 0.1k; // * player->xpSystem.agilityLVL;
                if (CheckInventory (SPRINTINGTOKEN)) {
                    if (abs (forwardMove) > 6400 || abs (sideMove) > 6144)
                        SetActorPropertyFixed (0, APROP_Speed, 1.0k + speedBonus);
                    else if (abs (forwardMove) <= 6400 && abs (sideMove) <= 6144)
                        SetActorPropertyFixed (0, APROP_Speed, (1.0k + speedBonus) * 2.0k);
                } else if (!CheckInventory (SPRINTINGTOKEN))
                    SetActorPropertyFixed (0, APROP_Speed, player->SprintDef.OldSpeed);
            }
        }

        Delay (1);

        if (player->SprintDef.Sprinting)
            tics++;
    }
}