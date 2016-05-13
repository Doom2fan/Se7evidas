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
#include "weapons/weap_data.h"
#include "weapons/weapon_stuff.h"

const string DummyWeapons [] = {
    s"S7_NullWeapon",
    SPRINTWEAPON,
    QUICKMELEEWEAPON,
    s"S7_BerserkWeap",
};

int GetWeaponName () {
    for (int x = 0; x < ArraySize (DummyWeapons); x++)
        if (CheckWeapon (DummyWeapons [x]))
            return -1;

    for (int y = 0; y < WeaponNames_Length; y++)
        if (CheckWeapon (WeaponNames [y]))
            return y;

    return -1;
}

void ChangeLastWeapon (bool mode, PlayerData_t *player) {
    if (!player) {
        Log ("\CgFunction ChangeLastWeapon: Fatal error: Invalid or NULL player struct");
        return;
    }

    int weaponNumber = 0;
    if (mode) {
        weaponNumber = player->scriptData.lastWeapon;
        if (weaponNumber < 0 || weaponNumber > WeaponNames_Length - 1)
            return;
        SetWeapon (WeaponNames [weaponNumber]);
    } else {
        weaponNumber = GetWeaponName ();
        if (weaponNumber < 0 || weaponNumber > WeaponNames_Length - 1)
            return;
        player->scriptData.lastWeapon = weaponNumber;
    }
}

void DisableWeapon (string meh, string blah, PlayerData_t *player) {
    if (!player) {
        Log ("\CgFunction DisableWeapon: Fatal error: Invalid or NULL player struct");
        return;
    }

    if (CheckWeapon (meh)) {
        TakeInventory (blah, 0x7FFFFFFF);
        ChangeLastWeapon (1, player);
        return;
    }
    GiveInventory (meh, 1);
    SetWeapon (meh);
    ChangeLastWeapon (0, player);
}

// Scripts
// SynthFire stuff
Script_C void S7_SynthFire (int mode) {
    while (TRUE) {
        if (!PlayerInGame (PLN))
            return;

        if (!CheckInventory (s"S7_SynthFireActive"))
            return;

        if (!mode) {
            if (KeyDown (BT_ATTACK))
                SetInventory (s"S7_SynthFireLeft", 1);

            if (KeyDown (BT_ALTATTACK))
                SetInventory (s"S7_SynthFireRight", 1);
        } else {
            if (KeyPressed (BT_ATTACK))
                SetInventory (s"S7_SynthFireLeft", 1);

            if (KeyPressed (BT_ALTATTACK))
                SetInventory (s"S7_SynthFireRight", 1);
        }

        Delay (1);

        if (!mode) {
            if (KeyUp (BT_ATTACK))
                SetInventory (s"S7_SynthFireLeft", 0);

            if (KeyUp (BT_ALTATTACK))
                SetInventory (s"S7_SynthFireRight", 0);
        }
    }
}

Script_C int S7_SynthFireAllowChange () {
    if (!CheckInventory (s"S7_SynthFireRightReloading") || CheckInventory (s"S7_SynthFireLeftReloading"))
        return 1;
    else
        return 0;
}

/*
Script_C void S7_RecoilPitch (accum offset) { // Called like this in code: TNT1 A 0 ACS_NamedExecuteAlways ("S7_RecoilPitch", 0, 0.5 * 65536)
    accum oldPitch = GetActorPitch (0);
    accum scaledOffset = ScaleValueAccum (offset, -90.0k, 90.0k, -0.25k, 0.25k);
    accum newPitch = ClampAccum (oldPitch - scaledOffset, -0.25k, 0.25k);

    SetActorPitch (0, newPitch);
}
*/

void AmmoCountersScript (PlayerData_t *player) {
    if (!player)
        return;

    if (CheckInventory (s"S7_ShotgunMagCounter") != (CheckInventory (s"S7_ShotgunMag") + CheckInventory (s"S7_ShotgunLoaded")))
        SetInventory (s"S7_ShotgunMagCounter", CheckInventory (s"S7_ShotgunMag") + CheckInventory (s"S7_ShotgunLoaded"));
}

/*#define PSICGFIREBOOL s"S7_PSICG_CanFire"
Script_C void S7_PSICG_FireTest () {
    accum puffX, puffY, puffZ;
    accum shooterX, shooterY, shooterZ;
    accum diff;

    puffX = GetActorX (0);
    puffY = GetActorY (0);
    puffZ = GetActorZ (0);

    SetActivator (0, AAPTR_TARGET);

    shooterX = GetActorX (0);
    shooterY = GetActorY (0);
    shooterZ = GetActorZ (0);

    diff = Distance2 (puffX, puffY, puffZ,
                      shooterX, shooterY, shooterZ);

    if (abs (diff) > 192)
        GiveInventory (PSICGFIREBOOL, 1);
    else
        TakeInventory (PSICGFIREBOOL, 0x7FFFFFFF);
}*/

Script_C int S7_MeleeDamage (int baseDamage, int mul) {
    accum baseMul  = 1.0k;
    accum mulBonus = 0.0k;

    if (CheckInventory (s"S7_BerserkToken")) {
        baseMul = 3.0k;
        mulBonus = RandomFixed (0.0k, 2.0k);
    }

    return RoundA ((baseDamage * baseMul + (0.5k * CheckInventory (XPS_STRENGTHTOKEN))) * (mul + mulBonus));
}

Script_C void S7_BerserkWeapToggle () {
    if (!PlayerInGame (PLN))
        return;
    
    DisableWeapon (s"S7_BerserkWeap", s"", &PlayerData [PLN]);
}

/*
weapBinds {
    vec2_i curWeap;                                     // Current weapon;
    int    weapBinds [WPBND_MAXSLOTS] [WPBND_MAXWEAPS]; // Weapon bindings array
};
*/

Script_C void S7_CWB_Slot NET (int slot, int pos) {
    if (slot < 0 || pos < -1 || slot >= WPBND_MAXSLOTS || pos >= WPBND_MAXWEAPS)
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_CWB_Slot: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }
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

Script_C void SetWeapBind (int slot, int pos, int weap) {
    if (slot < 0 || pos < 0 || weap < -1 || slot >= WPBND_MAXSLOTS || pos >= WPBND_MAXWEAPS || weap >= WeaponNames_Length) {
        for (int i = 0; i < WeaponNames_Length; i++) {
            Log ("%d: %S", i, WeaponNames [i]);
        }
        return;
    }

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript SetWeapBind: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    player->weapBinds.weapBinds [slot] [pos] = weap;
}