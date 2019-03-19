/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

//-------------------------------------------------------------------------------------------
//
// Null weapons
//
//-------------------------------------------------------------------------------------------

class S7_UnarmedWeap : S7_BaseWeapon {
    default {
        Tag "Unarmed";

        +INVENTORY.UNDROPPABLE +INVENTORY.UNTOSSABLE
    }

    states {
    Ready:
    Ready2:
        TNT1 A 1 S7_WeaponReady (null, null);
        loop;

    Deselect:
        goto TrueDeselect;

    Fire:
        goto QuickMelee;
    }
}

//-------------------------------------------------------------------------------------------
//
// Null weapons
//
//-------------------------------------------------------------------------------------------
class S7_NullWeapon : Weapon {
    default {
        Tag "Unarmed";
        Inventory.PickupSound "";
        Weapon.BobRangeX 0.3;
        Weapon.BobRangeY 0.5;
        Weapon.BobSpeed 2.0;
        Weapon.BobStyle "inverseSmooth";

        +WEAPON.CHEATNOTWEAPON +WEAPON.NOALERT +WEAPON.NOAUTOFIRE +WEAPON.AMMO_OPTIONAL
        +INVENTORY.UNDROPPABLE +NOINTERACTION
    }

    states {
    Spawn:
        stop;

    Select:
        TNT1 A 0 A_Raise;
        wait;
    Deselect:
        TNT1 A 0 A_Lower;
        wait;
    Ready:
        TNT1 A 1 A_WeaponReady (WRF_NoFire | WRF_NoBob);
        loop;
    Fire:
        TNT1 A 1;
        goto Ready;
    }
}

class S7_SprintWeapon : S7_NullWeapon {
    states {
    Ready:
        TNT1 A 1 {
            let pPawn = S7_BasePlayer (self);

            bool sprinting = false;
            if (pPawn) sprinting = pPawn.sprint_Sprinting;

            A_WeaponReady (WRF_NoFire | WRF_NoBob | (sprinting ? WRF_DisableSwitch : 0));
        }
        loop;
    }
}

class S7_LedgeGrabWeapon : S7_NullWeapon {
    states {
    Ready:
        TNT1 A 1 {
            let pData = S7_PlayerData (FindInventory ('S7_PlayerData'));

            bool grabbed = false;
            if (pData) grabbed = pData.lGrabGrabbed;

            A_WeaponReady (WRF_NoFire | WRF_NoBob | (grabbed ? WRF_DisableSwitch : 0));
        }
        loop;
    }
}