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
#include "health.h"
#include "hud.h"
#include "misc.h"
#include "weapon_stuff.h"
#include "stamina.h"
#include "sprint_system.h"
#include "cvars.h"

Script_C void S7_Enter ENTER () {
    SetActorPropertyFixed (0, APROP_Speed, 1.0k);
    SprintDef [PLN].OldSpeed = 1.0k;
    //StaminaEmpty [PLN] = 0;
}

Script_C void S7_Respawn RESPAWN () {
    SetActorPropertyFixed (0, APROP_Speed, 1.0k);
    SprintDef [PLN].OldSpeed = 1.0k;
    //StaminaEmpty [PLN] = 0;
}

Script_C int S7_RunningInZDoom () {
    return 1;
}