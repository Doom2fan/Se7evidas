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
int CWeapSlots_GetSlotMax (int slot) {
    if (ServerData.debugMode)
        return WPBND_MAXWEAPS;

    switch (slot) { // This is done by hand because, honestly, it'd be a waste of performance to make this generic when the maximum amount of slots is 5
        case 0:
            return 1 + (CheckInventory (s"S7_UpgradeSlot1") ? 1 : 0);
        break;
        case 1:
            return 1 + (CheckInventory (s"S7_UpgradeSlot2") ? 1 : 0);
        break;
        case 2:
            return 1 + (CheckInventory (s"S7_UpgradeSlot3") ? 2 : 0);
        break;
        case 3:
            return 1 + (CheckInventory (s"S7_UpgradeSlot4") ? 1 : 0);
        break;
        case 4:
            return 2 + (CheckInventory (s"S7_UpgradeSlot5") ? 1 : 0);
        break;
        default: // if the number is lower than 0 or greater than 4, return 0
            return 0;
        break;
    }
}

#define CheckNPBounds(pos) (BoundsCheck (pos.x, 0, WPBND_MAXSLOTS) && BoundsCheck (pos.y, 0, CWeapSlots_GetSlotMax (pos.x)))
string CWeapSlots_GetWeap (PlayerData_t *player, vec2_i pos) {
    if (!player) {
        DebugLog ("\CgFunction CWeapSlots_BindSlot: Fatal error: Invalid or NULL player struct");
        return NULL;
    }

    if (!CheckNPBounds (pos))
        return NULL;

    int weap = player->weapBinds.weapBinds [pos.x] [pos.y];
    if (BoundsCheck (weap, 0, WeaponNames_Length))
        return WeaponNames [weap];
    else
        return NULL;
}

void CWeapSlots_BindSlot (PlayerData_t *player, int slot, int pos, int weap) {
    if (!player) {
        DebugLog ("\CgFunction CWeapSlots_BindSlot: Fatal error: Invalid or NULL player struct");
        return;
    }

    player->weapBinds.weapBinds [slot] [pos] = weap;
    return;
}

void CWeapSlots_Slot (PlayerData_t *player, int slot, int pos) { // pos = -1: Select first weapon of the slot or cycle it; pos >= 0: Select weapon in the specific position of the slot
    if (!player) {
        DebugLog ("\CgFunction CWeapSlots_Slot: Fatal error: Invalid or NULL player struct");
        return;
    }

    if (slot < 0 || pos < -1 || slot >= WPBND_MAXSLOTS || pos >= CWeapSlots_GetSlotMax (slot))
        return;

    vec2_i newPos;
    WeapBinds_t *weapBinds = &(player->weapBinds);

    if (slot == weapBinds->curWeap.x && pos == -1) {
        newPos.x = slot;
        newPos.y = weapBinds->curWeap.y;
        int weapsChecked = 0;

        do {
            if (++newPos.y >= CWeapSlots_GetSlotMax (newPos.x)) {
                weapsChecked++;
                newPos.y = 0;
            }
            
            if (BoundsCheck (weapBinds->weapBinds [newPos.x] [newPos.y], 0, WeaponNames_Length) && CheckInventory (WeaponNames [player->weapBinds.weapBinds [newPos.x] [newPos.y]]))
                break;
        } while (newPos.y != weapBinds->curWeap.y && weapsChecked <= CWeapSlots_GetSlotMax (slot));
    } else if ((pos == -1 && slot != weapBinds->curWeap.x) && BoundsCheck (slot, 0, WPBND_MAXSLOTS) && pos < CWeapSlots_GetSlotMax (slot)) {
        newPos.x = slot;
        newPos.y = pos >= 0 ? pos : 0;
    } else {
        newPos.x = -1;
        newPos.y = -1;
    }
    
    if (CheckNPBounds (newPos) && BoundsCheck (weapBinds->weapBinds [newPos.x] [newPos.y], 0, WeaponNames_Length))
        weapBinds->switchWeap = newPos;
}

vec2_i CWeapSlots_GetNext (PlayerData_t *player) {
    if (!player) {
        DebugLog ("\CgFunction CWeapSlots_WeapNext: Fatal error: Invalid or NULL player struct");
        vec2_i pos = { -1, -1 };
        return pos;
    }

    WeapBinds_t *weapBinds = &(player->weapBinds);
    vec2_i newPos = weapBinds->curWeap;
    int slotsChecked = 0;

    if (!CheckNPBounds (newPos))
        newPos.x = newPos.y = 0;

    do {
        if (++newPos.y >= CWeapSlots_GetSlotMax (newPos.x)) {
            slotsChecked++;
            if (++newPos.x >= WPBND_MAXSLOTS)
                newPos.x = 0;
            newPos.y = 0;
        }

        if (BoundsCheck (weapBinds->weapBinds [newPos.x] [newPos.y], 0, WeaponNames_Length) && CheckInventory (WeaponNames [player->weapBinds.weapBinds [newPos.x] [newPos.y]]))
            return newPos;
    } while ((newPos.x != weapBinds->curWeap.x || newPos.y != weapBinds->curWeap.y) && slotsChecked <= WPBND_MAXSLOTS);

    return weapBinds->curWeap;
}

vec2_i CWeapSlots_GetPrev (PlayerData_t *player) {
    if (!player) {
        DebugLog ("\CgFunction CWeapSlots_WeapNext: Fatal error: Invalid or NULL player struct");
        vec2_i pos = { -1, -1 };
        return pos;
    }

    WeapBinds_t *weapBinds = &(player->weapBinds);
    vec2_i newPos = weapBinds->curWeap;
    int slotsChecked = 0;

    if (!CheckNPBounds (newPos))
        newPos.x = newPos.y = 0;

    do {
        if (--newPos.y < 0) {
            slotsChecked++;
            if (--newPos.x < 0)
                newPos.x = WPBND_MAXSLOTS - 1;
            newPos.y = CWeapSlots_GetSlotMax (newPos.x) - 1;
        }

        if (BoundsCheck (weapBinds->weapBinds [newPos.x] [newPos.y], 0, WeaponNames_Length) && CheckInventory (WeaponNames [player->weapBinds.weapBinds [newPos.x] [newPos.y]]))
            return newPos;
    } while ((newPos.x != weapBinds->curWeap.x || newPos.y != weapBinds->curWeap.y) && slotsChecked <= WPBND_MAXSLOTS);

    return weapBinds->curWeap;
}

//-------------------------------------------------------------------------------------------
//
// Scripts
//
//-------------------------------------------------------------------------------------------
void CustomWeapSlotsScript (PlayerData_t *player) {
    if (!player)
        return;

    if (player->scriptData.weaponReady) {
        string cWeap = WeaponNames [player->weapBinds.weapBinds [player->weapBinds.curWeap.x] [player->weapBinds.curWeap.y]];
        string sWeap = WeaponNames [player->weapBinds.weapBinds [player->weapBinds.curWeap.x] [player->weapBinds.curWeap.y]];

        if (player->weapBinds.switchWeap.x > -1 && player->weapBinds.switchWeap.y > -1) {
            player->weapBinds.curWeap = player->weapBinds.switchWeap;
            player->weapBinds.switchWeap.x = player->weapBinds.switchWeap.y = -1;
            SetWeapon (sWeap);
        } else if (!CheckWeapon (cWeap))
            SetWeapon (cWeap);
    }
}

Script_C void S7_CWB_Slot NET (int slot, int pos) {
    if (!PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        DebugLog ("\CgScript S7_CWB_Slot: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    if (player->SprintDef.Sprinting || player->scriptData.beamGrab)
        return;

    CWeapSlots_Slot (player, slot, pos);
}

Script_C void S7_CWB_WeapCycle (bool next) {
    if (!PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        DebugLog ("\CgScript S7_CWB_WeapCycle: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    if (player->SprintDef.Sprinting || player->scriptData.beamGrab)
        return;

    vec2_i newPos = next ? CWeapSlots_GetNext (player) : CWeapSlots_GetPrev (player);
    if (!CheckNPBounds (newPos) || (newPos.x == player->weapBinds.curWeap.x && newPos.y == player->weapBinds.curWeap.y))
        return;
    player->weapBinds.switchWeap = newPos;
}

#ifdef DEBUG
Script_C void S7_CWB_SetBind NET (int slot, int pos, int weap) {
    if (!PlayerInGame (PLN))
        return;

    if (slot < 0 || pos < 0 || weap < -1 || slot >= WPBND_MAXSLOTS || pos >= CWeapSlots_GetSlotMax (slot) || weap >= WeaponNames_Length) {
        for (int i = 0; i < WeaponNames_Length; i++)
            Log ("%d: %S", i, WeaponNames [i]);
        
        return;
    }

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        DebugLog ("\CgScript S7_CWB_SetBind: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    CWeapSlots_BindSlot (player, slot, pos, weap);
}

Script_C void FuckThisShit NET (bool derp) {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    if (!player) {
        DebugLog ("\CgScript FuckThisShit: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    if (derp) {
        for (int i = 0; i < WeaponNames_Length; i++)
            player->weapBinds.weapBinds [i / WPBND_MAXSLOTS] [i % WPBND_MAXWEAPS] = i;
    } else {
        for (int x = 0; x < WPBND_MAXSLOTS; x++) {
            for (int y = 0; y < WPBND_MAXWEAPS; y++) {
                int weap = player->weapBinds.weapBinds [x] [y];
                Log ("Slot %d, pos %d: %d/%S", x, y, weap, WeaponNames [weap]);
            }
        }
    }
}
#endif