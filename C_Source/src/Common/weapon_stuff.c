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

string WeaponName [] = {
    s"S7_PrettyShootyIonCannonGun",
    s"S7_PlasmaGun",
    s"S7_AMG",
    s"S7_Shotgun",
    s"S7_Raptor",
    s"S7_Revolver",
    s"S7_TEC9"
};

string DummyWeapons [] = {
    s"S7_NullWeapon",
    s"S7_SprintWeapon",
    s"S7_QuickMelee"
};

int GlobalVar LastWeapon [MAX_PLAYERS];

int GetWeaponName () {
    for (int x = 0; x < ArraySize (DummyWeapons); x++)
        if (CheckWeapon (DummyWeapons [x])) 
            return -1;
    
    for (int y = 0; y < ArraySize (WeaponName); y++)
        if (CheckWeapon (WeaponName [y]))
            return y;
    
    return -1;
}

void ChangeLastWeapon (bool mode) {
    int weaponNumber = 0;
    if (mode) {
        weaponNumber = LastWeapon [PLN];
        if (weaponNumber < 0 || weaponNumber > ArraySize (WeaponName) - 1)
            return;
        SetWeapon (WeaponName [weaponNumber]);
    } else {
        weaponNumber = GetWeaponName ();
        if (weaponNumber < 0 || weaponNumber > ArraySize (WeaponName) - 1)
            return;
        else
            LastWeapon [PLN] = weaponNumber;
    }
}

void DisableWeapon (string meh, string blah) {
    if (CheckWeapon (meh)) {
        TakeInventory (blah, 99999);
        ChangeLastWeapon (1);
        return;
    }
    GiveInventory (meh, 1);
    SetWeapon (meh);
    ChangeLastWeapon (0);
}

// Scripts
// SynthFire stuff
Script_C void S7_SynthFire () {
    while (TRUE) {
        if (!CheckInventory (s"S7_SynthFireActive"))
            return;
        
        if (KeyDown (BT_ATTACK) && !CheckInventory (s"S7_SynthFireLeft"))
            GiveInventory (s"S7_SynthFireLeft", 1);
        
        if (KeyDown (BT_ALTATTACK) && !CheckInventory (s"S7_SynthFireRight"))
            GiveInventory (s"S7_SynthFireRight", 1);
        
        Delay (1);
        
        if (KeyUp (BT_ATTACK) && CheckInventory (s"S7_SynthFireLeft"))
            TakeInventory (s"S7_SynthFireLeft", 1);
        
        if (KeyUp (BT_ALTATTACK) && CheckInventory (s"S7_SynthFireRight"))
            TakeInventory (s"S7_SynthFireRight", 1);
    }
}

Script_C int S7_SynthFireAllowChange () {
    if (!CheckInventory (s"S7_SynthFireRightReloading") || CheckInventory (s"S7_SynthFireLeftReloading"))
        return 1;
    else
        return 0;
}

Script_C void S7_QuickMelee () {
    DisableWeapon (s"S7_QuickMelee", s"None");
}

Script_C int S7_GetAutoReloading () {
    if (GetUserCVar (PLN, s"S7_AutoReloading") == false)
        return 0;
    else
        return 1;
}

Script_C void S7_RecoilPitch (accum offset) { // Called like this in code: TNT1 A 0 namedExecuteAlways ("S7_RecoilPitch", 0, 0.5 * 65535)
    accum oldPitch = GetActorPitch (0);
    accum scaledOffset = ScaleValueAccum (offset, -90.0k, 90.0k, -0.25k, 0.25k);
    accum newPitch = ClampAccum (oldPitch - scaledOffset, -0.25k, 0.25k);
    
    SetActorPitch (0, newPitch);
}