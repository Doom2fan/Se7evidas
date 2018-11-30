/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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

/* Credits:
** Coding: Chronos "phantombeta" Ouroboros, Xaser
**
** Sprites:
**   HUD Sprites: Xaser, Chronos "phantombeta" Ouroboros
**   Animation: Xaser, Chronos "phantombeta" Ouroboros
**
** Sounds: Credits in the SNDINFO file (SNDINFO.MiscInventory)
*/

class S7_Berserk : Inventory {
    default {
        Tag "$BERSERK";
        Inventory.Icon "BSRKA0";
        Inventory.PickupMessage "$BERSERK";
        Inventory.Amount 1;
        Inventory.MaxAmount 5;
        Inventory.InterHubAmount 5;

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        let bsrkWeap = Owner.FindInventory ('S7_BerserkWeap');

        if (bsrkWeap)
            bsrkWeap.Use (false);
        else {
            bsrkWeap = owner.GiveInventoryType ('S7_BerserkWeap');

            if (bsrkWeap)
                bsrkWeap.Use (false);
        }

        return false;
    }

    states {
    Spawn:
        BSRK A -1;
        stop;
    }
}

class S7_BerserkToken : Powerup { default { Powerup.Duration -60; Powerup.Color "FF 20 20", 0.25; } }
class S7_BerserkPower : PowerWeaponLevel2 { default { Powerup.Duration -60; Powerup.Color "00 00 00", 0.0; } }

class S7_BerserkWeap : S7_BaseWeapon {
    default {
        Tag "$BERSERKWEAP";

        +INVENTORY.UNDROPPABLE +INVENTORY.UNTOSSABLE +WEAPON.CHEATNOTWEAPON
    }

    override bool Use (bool pickup) {
        return !pickup ? Weapon.Use (false) : false;
    }

    states {
    Spawn:
        TNT1 A 0 A_SpawnItemEx ('S7_Berserk', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition);
        stop;

    Ready:
        SYR1 A 1 {
            A_WeaponOffset (-12.8 * 5, 32 + (12.8 * 5));
            return CountInv ('S7_Berserk') <= 0 ? ResolveState ("Ready2.NoBerserk") : ResolveState (null);
        }
        SYR1 A 1 A_WeaponOffset (-12.8 * 4, 32 + (12.8 * 4));
        SYR1 A 1 A_WeaponOffset (-12.8 * 3, 32 + (12.8 * 3));
        SYR1 A 1 A_WeaponOffset (-12.8 * 2, 32 + (12.8 * 2));
        SYR1 A 1 A_WeaponOffset (-12.8 * 1, 32 + (12.8 * 1));
        TNT1 A 0 A_WeaponOffset (0, 32);
        goto Ready2;
    Ready2:
        SYR1 A 0 A_JumpIf (CountInv ('S7_Berserk') <= 0, "Ready2.NoBerserk");
        goto Ready2.DoThings;
    Ready2.NoBerserk:
        TNT1 A 0;
        goto Ready2.DoThings;
    Ready2.DoThings:
        #### # 1 {
            if (CheckInventory ('S7_DoMelee', 1))
                return ResolveState ("QuickMelee");
            TakeInventory ('S7_Reloading', 0x7FFFFFFF);
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            A_WeaponReady (!CheckInventory ('S7_Berserk', 1) ? WRF_NoPrimary : 0);

            return ResolveState (null);
        }
        goto Ready2;

    Deselect:
        SYR1 A 1 {
            if (CountInv ('S7_Berserk') <= 0)
                return ResolveState ("TrueDeselect");

            A_WeaponOffset (-12.8 * 1, 32 + (12.8 * 1));

            return ResolveState (null);
        }
        SYR1 A 1 A_WeaponOffset (-12.8 * 2, 32 + (12.8 * 2));
        SYR1 A 1 A_WeaponOffset (-12.8 * 3, 32 + (12.8 * 3));
        SYR1 A 1 A_WeaponOffset (-12.8 * 4, 32 + (12.8 * 4));
        SYR1 A 1 A_WeaponOffset (-12.8 * 5, 32 + (12.8 * 5));
        TNT1 A 0 A_WeaponOffset (0, 32);
        goto TrueDeselect;

    Fire:
        SYR1 A          3 A_JumpIf (!CheckInventory ('S7_Berserk', 1) || CheckInventory ('S7_BerserkToken', 1), "Ready2");
        SYR1 CDD        3;
        SYR1 EFGHI      1;
        SYR1 J          5;
        SYR1 KL         1;
        SYR1 M          8 A_PlaySound ("Syringe/In", CHAN_5);
        SYR1 N          2;
        SYR1 O          2 {
            A_PlaySound ("Berserk/Inject", CHAN_Weapon);
            A_PlaySound ("*pain", CHAN_Voice);
        }
        SYR1 P          2;
        SYR1 Q          2 {
            TakeInventory ('S7_Berserk', 1);
            GiveInventory ('S7_BerserkPower', 1);
            GiveInventory ('S7_BerserkToken', 1);
        }
        SYR1 QRSTUVWWWX 2;
        SYR1 Y          8;
        SYR1 Z          2;
        SYR2 A          2 A_PlaySound ("Syringe/Out", CHAN_5);
        SYR2 BCD        2;
        SYR2 E          8;
        SYR2 FG         2;
        SYR2 HIJKL      1;
        TNT1 A          0;
        SYR2 MN         1;
        SYR2 O          1 A_FireProjectile ('S7_SpentSyringe', 0, false, 0, 0);
        SYR2 PQR        1;
        TNT1 A          8;
        goto Ready;
    }
}

class S7_SpentSyringe : S7_CasingBase {
    default {
        Scale 0.1;
        SeeSound "Weapons/Shell";
    }

    states {
    Spawn:
        SYTR ABCDEFGHIJKLMNOP 1;
        loop;
    Death:
        #### # 1 A_Jump (256, "Delaying");
        wait;
    }
}