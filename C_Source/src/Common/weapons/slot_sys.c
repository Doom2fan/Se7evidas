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

//-------------------------------------------------------------------------------------------
//
// Functions
//
//-------------------------------------------------------------------------------------------
/*weapBinds {
    vec2_i curWeap;                                     // Current weapon;
    int    weapBinds [WPBND_MAXSLOTS] [WPBND_MAXWEAPS]; // Weapon bindings array
};*/
void CWeapSlots_BindSlot (PlayerData_t *player, int slot, int pos, int weap) {
    if (!player) {
        Log ("\CgFunction CWeapSlots_BindSlot: Fatal error: Invalid or NULL player struct");
        return;
    }

    player->weapBinds.weapBinds [slot] [pos] = weap;
    return;
}

#define CheckNPBounds (BoundsCheck (newPos.x, 0, WPBND_MAXSLOTS) && BoundsCheck (newPos.y, 0, WPBND_MAXWEAPS))
void CWeapSlots_Slot (PlayerData_t *player, int slot, int pos) { // pos = -1: Select first weapon of the slot or cycle it; pos >= 0: Select weapon in the specific position of the slot
    if (!player) {
        Log ("\CgFunction CWeapSlots_Slot: Fatal error: Invalid or NULL player struct");
        return;
    }

    if (slot < 0 || pos < -1 || slot >= WPBND_MAXSLOTS || pos >= WPBND_MAXWEAPS)
        return;

    vec2_i newPos;
    WeapBinds_t *weapBinds = &(player->weapBinds);

    if (slot == weapBinds->curWeap.x && pos == -1) {
        newPos.x = slot;
        newPos.y = weapBinds->curWeap.y + 1;
        while (!CheckNPBounds || !BoundsCheck (weapBinds->weapBinds [newPos.x] [newPos.y], 0, WeaponNames_Length) ||
               !CheckInventory (WeaponNames [weapBinds->weapBinds [newPos.x] [newPos.y]])) {
            if (newPos.y > WPBND_MAXWEAPS)
                newPos.y = 0;
            if (newPos.y == weapBinds->curWeap.y)
                break;
            newPos.y++;
        }
    } else if ((pos == -1 && slot != weapBinds->curWeap.x) && BoundsCheck (slot, 0, WPBND_MAXSLOTS) && pos < WPBND_MAXWEAPS) {
        newPos.x = slot;
        newPos.y = pos >= 0 ? pos : 0;
    } else {
        newPos.x = -1;
        newPos.y = -1;
    }
    
    if (CheckNPBounds && BoundsCheck (weapBinds->weapBinds [newPos.x] [newPos.y], 0, WeaponNames_Length) &&
        CheckInventory (WeaponNames [weapBinds->weapBinds [newPos.x] [newPos.y]])) {
        if (SetWeapon (WeaponNames [weapBinds->weapBinds [newPos.x] [newPos.y]]))
            weapBinds->curWeap = newPos;
    }
}

void CWeapSlots_WeapCycle (PlayerData_t *player, bool next) { // if next if false, behave as WeapPrev, if true, behave as WeapNext
    if (!player) {
        Log ("\CgFunction CWeapSlots_WeapNext: Fatal error: Invalid or NULL player struct");
        return;
    }

    WeapBinds_t *weapBinds = &(player->weapBinds);
    vec2_i newPos = weapBinds->curWeap;
    int mod      = next ? 1 : -1;
    int loopSlot = next ? 0 : WPBND_MAXSLOTS;
    int loopPos  = next ? 0 : WPBND_MAXWEAPS;

    while (TRUE) {
        newPos.y += mod;
        if (newPos.x == weapBinds->curWeap.x && newPos.y == weapBinds->curWeap.y)
            return;
        if ((next && newPos.y > WPBND_MAXWEAPS) || (!next && newPos.y < 0)) {
            if ((next && newPos.x > WPBND_MAXSLOTS) || (!next && newPos.x < 0))
                newPos.x = loopSlot;
            else
                newPos.x += mod;
            newPos.y = loopPos;
        }

        if (weapBinds->weapBinds [newPos.x] [newPos.y] >= 0 && weapBinds->weapBinds [newPos.x] [newPos.y] < WeaponNames_Length &&
            weapBinds->curWeap.x != newPos.x && weapBinds->curWeap.y != newPos.y) {
            if (weapBinds->weapBinds [newPos.x] [newPos.y] != weapBinds->weapBinds [weapBinds->curWeap.x] [weapBinds->curWeap.y])
                if (SetWeapon (WeaponNames [weapBinds->weapBinds [newPos.x] [newPos.y]]))
                    weapBinds->curWeap = newPos;
        }
    }
}

Script_C void FuckThisShit NET () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        Log ("\CgScript FuckThisShit: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    for (int x = 0; x < WPBND_MAXSLOTS; x++) {
        for (int y = 0; y < WPBND_MAXWEAPS; y++) {
            int weap = player->weapBinds.weapBinds [x] [y];
            Log ("Slot %d, pos %d: %d/%S", x, y, weap, WeaponNames [weap]);
        }
    }
}

//-------------------------------------------------------------------------------------------
//
// Scripts
//
//-------------------------------------------------------------------------------------------
void CustomWeapSlotsScript (PlayerData_t *player) {
    if (!player)
        return;

    
}

Script_C void S7_CWB_Slot NET (int slot, int pos) {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        Log ("\CgScript S7_CWB_Slot: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    CWeapSlots_Slot (player, slot, pos);
}

Script_C void S7_CWB_SetBind NET (int slot, int pos, int weap) {
    if (slot < 0 || pos < 0 || weap < -1 || slot >= WPBND_MAXSLOTS || pos >= WPBND_MAXWEAPS || weap >= WeaponNames_Length) {
        for (int i = 0; i < WeaponNames_Length; i++)
            Log ("%d: %S", i, WeaponNames [i]);
        
        return;
    }

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        Log ("\CgScript S7_CWB_SetBind: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    CWeapSlots_BindSlot (player, slot, pos, weap);
}

Script_C void S7_CWB_WeapCycle (bool next) {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        Log ("\CgScript S7_CWB_WeapCycle: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    CWeapSlots_WeapCycle (player, next);
}