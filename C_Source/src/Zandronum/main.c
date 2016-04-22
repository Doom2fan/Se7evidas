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
#include "includes_zandro.h"
#include "stamina.h"
#include "sprint_system.h"

bool RunningInZDoom = FALSE;

Script_C void S7_Open OPEN () {
    ConsoleCommand (s"compat_clientssendfullbuttoninfo TRUE");
}

Script_C void S7_Enter ENTER () {
    if (!PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN];

    if (!player) {
        Log ("\CgScript S7_Enter: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    SetActorPropertyFixed (0, APROP_Speed, 1.0k);
    player->SprintDef.OldSpeed = 1.0k;
}

Script_C void S7_Respawn RESPAWN () {
    PlayerData_t *player = &PlayerData [PLN];

    if (!player) {
        Log ("\CgScript S7_Respawn: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    SetActorPropertyFixed (0, APROP_Speed, 1.0k);
    player->SprintDef.OldSpeed = 1.0k;
}

bool S7_PlayerNumEqualConsolePlayer (int playerNum) {
    if (playerNum == CPLN)
        return TRUE;

    return FALSE;
}

void PukeScriptFunction (int number, int arg0, int arg1, int arg2) {
    RequestScriptPuke (number, arg0, arg1, arg2);
}