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

#include "sprint_system.h"

SprintDef GlobalVar SprintDef [MAX_PLAYERS];

Script_C void S7_SprintSystem ENTER (void) {
    Start:
    // Not needed or desired in TitleMaps.
    if (ACS_GameType () == GAME_TITLE_MAP)
        return;
    
    int tics = 0;
    while (TRUE) {
        if (ACS_CheckWeapon (s"S7_SprintWeapon") && !SprintDef [PLN].Sprinting) {
            ACS_SetActorPropertyFixed (0, APROP_Speed, SprintDef [PLN].OldSpeed);
            SprintDef [PLN].Sprinting = FALSE;
            tics = 0;
            DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting");
        }
        if (KeyDown (BT_USER1) &&
            !SprintDef [PLN].Sprinting &&
            ACS_CheckInventory (s"S7_Stamina") >= 5 && !ACS_CheckInventory (s"S7_Dying") &&
            !S7_SR_StaminaEmpty [PLN]) {
            SprintDef [PLN].Sprinting = TRUE;
            SprintDef [PLN].OldSpeed = ACS_GetActorProperty (0, APROP_Speed);
            DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting");
        }
        if (keyUp (BT_USER1) && SprintDef [PLN].Sprinting && !S7_SR_StaminaEmpty [PLN]) {
            ACS_SetActorPropertyFixed (0, APROP_Speed, SprintDef [PLN].OldSpeed);
            SprintDef [PLN].Sprinting = FALSE;
            tics = 0;
            DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting");
        }
        if (ACS_CheckInventory (s"S7_Sprinting") && SprintDef [PLN].Sprinting) {
            if (ACS_CheckInventory (s"S7_Stamina") >= 5) {
                if (ACS_CheckInventory (s"S7_Sprinting") && tics >= 5) {
                    tics = 0;
                    if (GetVelocity () > 0)
                        ACS_TakeInventory (s"S7_Stamina", 5);
                }
                if (ACS_CheckInventory (s"S7_Stamina") < 5 || ACS_CheckInventory (s"S7_Dying")) {
                    ACS_SetActorPropertyFixed (0, APROP_Speed, SprintDef [PLN].OldSpeed);
                    SprintDef [PLN].Sprinting = FALSE;
                    S7_SR_StaminaEmpty [PLN] = 1;
                    DisableWeapon (s"S7_SprintWeapon", s"S7_Sprinting");
                    goto Start;
                }
                if (ACS_CheckInventory (s"S7_Sprinting") && ((abs (ACS_GetPlayerInput (-1, INPUT_FORWARDMOVE)) > 6400) || (abs (ACS_GetPlayerInput (-1, INPUT_SIDEMOVE)) > 6400)))
                    ACS_SetActorPropertyFixed (0, APROP_Speed, 3.0k);
                else if (ACS_CheckInventory (s"S7_Sprinting") && !((abs (ACS_GetPlayerInput (-1, INPUT_FORWARDMOVE)) > 6400) || (abs (ACS_GetPlayerInput (-1, INPUT_SIDEMOVE)) > 6400)))
                    ACS_SetActorPropertyFixed (0, APROP_Speed, 6.0k);
                else if (!checkInventory (s"S7_Sprinting"))
                    ACS_SetActorPropertyFixed (0, APROP_Speed, SprintDef [PLN].OldSpeed);
            }
        }
        
        ACS_Delay (1);
        
        if (SprintDef [PLN].Sprinting)
            tics++;
    }
}