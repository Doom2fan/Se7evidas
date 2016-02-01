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
#include "weapon_stuff.h"
#include "stamina.h"
#include "sprint_system.h"

Script_C void S7_SprintSystem ENTER () {
    Start:
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP)
        return;
    
    int tics = 0;
    PlayerData_t *player = &PlayerData [PLN];

    while (TRUE) {
        if (CheckWeapon (s"S7_SprintWeapon") && !player->SprintDef.Sprinting) {
            SetActorPropertyFixed (0, APROP_Speed, player->SprintDef.OldSpeed);
            player->SprintDef.Sprinting = FALSE;
            tics = 0;
            DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting", player);
        }
        if (KeyDown (BT_USER1) &&
            !player->SprintDef.Sprinting &&
            CheckInventory (s"S7_Stamina") >= 5 && !CheckInventory (s"S7_Dying") &&
            !player->staminaEmpty) {
            player->SprintDef.Sprinting = TRUE;
            player->SprintDef.OldSpeed = GetActorPropertyFixed (0, APROP_Speed);
            DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting", player);
        }
        if (KeyUp (BT_USER1) && player->SprintDef.Sprinting && !player->staminaEmpty) {
            SetActorPropertyFixed (0, APROP_Speed, player->SprintDef.OldSpeed);
            player->SprintDef.Sprinting = FALSE;
            tics = 0;
            DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting", player);
        }
        if (CheckInventory (s"S7_Sprinting") && player->SprintDef.Sprinting) {
            if (CheckInventory (s"S7_Stamina") >= 5) {
                if (CheckInventory (s"S7_Sprinting") && tics >= 5 &&
                    ((abs (GetPlayerInput (-1, INPUT_FORWARDMOVE)) > 0) || (abs (GetPlayerInput (-1, INPUT_SIDEMOVE)) > 0))) {
                    tics = 0;
                    if (GetVelocity () > 0.0k) {
                        TakeInventory (s"S7_Stamina", 5);
                        player->stamina = CheckInventory (s"S7_Stamina");
                    }
                }
                if (CheckInventory (s"S7_Stamina") < 5 || CheckInventory (s"S7_Dying")) {
                    SetActorPropertyFixed (0, APROP_Speed, player->SprintDef.OldSpeed);
                    player->SprintDef.Sprinting = FALSE;
                    player->staminaEmpty = 1;
                    DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting", player);
                    goto Start;
                }
                if (CheckInventory (s"S7_Sprinting") && ((abs (GetPlayerInput (-1, INPUT_FORWARDMOVE)) > 6400) || (abs (GetPlayerInput (-1, INPUT_SIDEMOVE)) > 6400)))
                    SetActorPropertyFixed (0, APROP_Speed, 3.0k);
                else if (CheckInventory (s"S7_Sprinting") && !((abs (GetPlayerInput (-1, INPUT_FORWARDMOVE)) > 6400) || (abs (GetPlayerInput (-1, INPUT_SIDEMOVE)) > 6400)))
                    SetActorPropertyFixed (0, APROP_Speed, 6.0k);
                else if (!CheckInventory (s"S7_Sprinting"))
                    SetActorPropertyFixed (0, APROP_Speed, player->SprintDef.OldSpeed);
            }
        }
        
        Delay (1);
        
        if (player->SprintDef.Sprinting)
            tics++;
    }
}