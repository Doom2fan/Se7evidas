/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
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

class S7_Berserk : Ammo {
    default {
        Tag "$BERSERK";
        Inventory.Icon "BSRKA0";
        Inventory.PickupMessage "$BERSERK";
        Inventory.Amount 1;
        Inventory.MaxAmount 5;
        Inventory.InterHubAmount 5;

        +INVENTORY.INVBAR
        -INVENTORY.KEEPDEPLETED
    }

    override bool Use (bool pickup) {
        let bsrkWeap = Owner.FindInventory ("S7_BerserkWeap");

        if (bsrkWeap)
            bsrkWeap.Use (false);

        return false;
    }
}

class S7_BerserkToken : Powerup { default { powerup.duration -60; powerup.color "FF 20 20", 0.25; } }
class S7_BerserkPower : PowerWeaponLevel2 { default { powerup.duration -60; powerup.color "00 00 00", 0.0; } }

class S7_BerserkWeap : S7_NullWeapon {
    default {
        Tag "$BERSERKWEAP";
        Weapon.AmmoType1 "S7_Berserk";
        Weapon.AmmoUse1 1;

        +INVENTORY.UNDROPPABLE +INVENTORY.UNTOSSABLE
    }

    override bool Use (bool pickup) {
        return !pickup ? Weapon.Use (false) : false;
    }

    states {
    Spawn:
        TNT1 A 0 A_SpawnItemEx ("S7_Berserk", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition);
        stop;

    Ready:
        SYR0 A              1 A_JumpIfNoAmmo ("Ready2");
        SYR0 BCDEFGHIJKLMNO 1;
    Ready2:
        SYR1 A 0 A_JumpIfNoAmmo ("Ready2.NoAmmo");
        goto Ready2.DoThings;
    Ready2.NoAmmo:
        TNT1 A 0;
        goto Ready2.DoThings;
    Ready2.DoThings:
        #### # 1 {
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            A_WeaponReady ();

            return ResolveState (null);
        }
        goto Ready2;

    Deselect:
        TNT1 A 0 A_Lower;
        wait;

    Fire:
        SYR1 A          3 A_JumpIf (!invoker.CheckAmmo (PrimaryFire, false, true) || CheckInventory ("S7_BerserkToken", 1), "Ready2");
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
            TakeInventory ("S7_Berserk", 1);
            GiveInventory ("S7_BerserkPower", 1);
            GiveInventory ("S7_BerserkToken", 1);
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
        SYR2 O          1 A_FireProjectile ("S7_SpentSyringe", 0, 0, 0, 0);
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