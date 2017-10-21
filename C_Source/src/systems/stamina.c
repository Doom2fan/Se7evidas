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

#define SRGN_DoRegenCommon(x) \
( \
    GiveInventory (STAMINATOKEN, x), \
    player->scriptData.staminaTics = 0, \
    player->health.stamina = CheckInventory (STAMINATOKEN) \
)

void StaminaRegenerationPart1 (PlayerData_t *player) {
    if (!player)
        return;

    if (player->health.health > 0) {
        bool berserkActive = CheckInventory (BERSERKTOKEN);

        if (player->scriptData.staminaTics > 0 && player->health.stamina == GetMaxStamina (player) || player->scriptData.staminaTics > 0 && CheckWeapon (SPRINTWEAPON))
            player->scriptData.staminaTics = 0;

        if (!CheckWeapon (SPRINTWEAPON)) {
            if (!player->misc.dying && player->scriptData.staminaTics >= 1)
                SRGN_DoRegenCommon (berserkActive ? 4 : 1);
            else if (player->misc.dying && player->scriptData.staminaTics >= berserkActive ? 2 : 3)
                SRGN_DoRegenCommon (berserkActive ? 2 : 1);
        }
    } else {
        player->scriptData.staminaTics = 0;
    }
}

void StaminaRegenerationPart2 (PlayerData_t *player) {
    if (!player)
        return;

    if (player->health.health > 0 && !CheckWeapon (SPRINTWEAPON) && player->health.stamina != GetMaxStamina (player))
        player->scriptData.staminaTics++;
}