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
#include "weapons/weap_data.h"
#include "weapons/slot_sys.h"

/*
weapBinds {
    vec2_i curWeap;                                     // Current weapon;
    int    weapBinds [WPBND_MAXSLOTS] [WPBND_MAXWEAPS]; // Weapon bindings array
};
*/

void CWeapSlots_BindSlot (PlayerData_t *player, int slot, int pos, int weap) {
    if (!player) {
        Log ("\CgFunction CWeapSlots_BindSlot: Fatal error: Invalid or NULL player struct");
        return FALSE;
    }
    
    if (slot < 0 || pos < 0 || weap < -1 || slot >= WPBND_MAXSLOTS || pos >= WPBND_MAXWEAPS || weap >= WeaponNames_Length) {
        for (int i = 0; i < WeaponNames_Length; i++) {
            Log ("%d: %S", i, WeaponNames [i]);
        }
        return;
    }

    player->weapBinds.weapBinds [slot] [pos] = weap;
}
void CWeapSlots_ToSlot (PlayerData_t *player, int slot, int pos) {
    if (!player) {
        Log ("\CgFunction CWeapSlots_ToSlot: Fatal error: Invalid or NULL player struct");
        return FALSE;
    }

    if (slot < 0 || pos < -1 || slot >= WPBND_MAXSLOTS || pos >= WPBND_MAXWEAPS)
        return;

    vec2_i newPos;
    WeapBinds_t *weapBinds = &(player->weapBinds);

    for (int i = WPBND_MAXWEAPS; i >= 0; i--) {
        if (i < 0)
            return;
    }

    if (slot == weapBinds->curWeap.x && pos == -1) {
        newPos.x = slot; newPos.y = weapBinds->curWeap.y + 1;
        if (newPos.x >= 0 && newPos.x < WPBND_MAXSLOTS &&
            newPos.y >= 0 && newPos.y < WPBND_MAXWEAPS &&
            weapBinds->weapBinds [newPos.x] [newPos.y] == -1) {
            newPos.y = 0;
        }
    } else if (newPos.x >= 0 && newPos.x < WPBND_MAXSLOTS &&
               newPos.y >= 0 && newPos.y < WPBND_MAXWEAPS &&
               weapBinds->weapBinds [newPos.x] [newPos.y] >= 0 && weapBinds->weapBinds [newPos.x] [newPos.y] < WeaponNames_Length) {
        newPos.x = slot; newPos.y = pos;
    }

    if ((newPos.x >= 0 && newPos.x < WPBND_MAXSLOTS) &&
        (newPos.y >= 0 && newPos.y < WPBND_MAXWEAPS) &&
        (weapBinds->weapBinds [newPos.x] [newPos.y] >= 0 && weapBinds->weapBinds [newPos.x] [newPos.y] < WeaponNames_Length) &&
        (weapBinds->curWeap.x != newPos.x && weapBinds->curWeap.y != newPos.y)) {
        if (weapBinds->weapBinds [newPos.x] [newPos.y] != weapBinds->weapBinds [weapBinds->curWeap.x] [weapBinds->curWeap.y])
            SetWeapon (WeaponNames [weapBinds->weapBinds [newPos.x] [newPos.y]]);

        weapBinds->curWeap = newPos;
    }
}

Script_C void S7_CWB_Slot NET (int slot, int pos) {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        Log ("\CgScript S7_CWB_Slot: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    CWeapSlots_Slot (player, slot, pos);
}

Script_C void S7_CWB_SetBind (int slot, int pos, int weap) {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        Log ("\CgScript S7_CWB_SetBind: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    CWeapSlots_BindSlot (player, slot, pos, weap);
}