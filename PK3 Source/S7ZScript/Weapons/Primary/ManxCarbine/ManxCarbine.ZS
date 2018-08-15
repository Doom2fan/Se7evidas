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

//-------------------------------------------------------------------------------------------
//
// C23 "Manx" Carbine
//
//-------------------------------------------------------------------------------------------
class S7_ManxCarbineClip : Ammo {
    default {
        Inventory.MaxAmount 23;
        Ammo.BackpackMaxAmount 23;

        +INVENTORY.IGNORESKILL
    }
}

class S7_ManxCarbine : S7_BaseWeapon {
    default {
        Tag "$MANXCARBINE";
        Inventory.PickupMessage "$MANXCARBINE";
        Weapon.AmmoType1 "S7_ManxCarbineClip";
        Weapon.AmmoType2 "S7_9mmCartridges";
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;
        S7_BaseWeapon.Icon "MANXZ0";
        S7_BaseWeapon.ShortTag "$SHORTMANXCARBINE";
        S7_BaseWeapon.BindSlot WpSlot_Medium;
    }

    bool semiAuto;

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = semiAuto ? FMI_SemiAuto : FMI_FullAuto;
    }

    states {
    Spawn:
        MANX Z -1;
        loop;

    Ready:
        MANX TUVWXA 1;
    Ready2:
        MANX A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Deselect:
        MANX AXWVUT 1;
        goto TrueDeselect;

    Fire:
        MANX A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/ManxCarbine/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 3.75, 1.75);
            A_FireProjectile ("S7_9mmCasingSpawn", 0, 0, 15, -9);
            A_FireProjectile ("S7_ManxCarbineTracer", fRandom [weaponSpread] (-0.25, 0.25), 1, 6, -3, 0, fRandom [weaponSpread] (-0.25, 0.25));
            S7_Recoil (-0.5);

            return ResolveState (null);
        }
        MANX B 1 S7_Recoil (-0.5);
        MANX C 1 A_JumpIf (invoker.semiAuto, "Fire.Semi");
        MANX A 1;
        MANX A 1 A_Refire;
        MANX A 3;
        goto Ready2;
    Fire.Semi:
        MANX C    1;
        MANX AAAA 1 { player.WeaponState |= WF_WeaponReady; }
        MANX A    2;
        goto Ready2;

    ChangeMode:
        MANX A 5 {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            if (invoker.semiAuto)
                invoker.semiAuto = false;
            else
                invoker.semiAuto = true;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);
        }
        goto Ready2;

    DryFire:
        MANX A 3 A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 1);

            if (CheckInventory (invoker.ammoType1, 0) || !CheckInventory (invoker.ammoType2, 1))
                return ResolveState ("Ready2");

            int ammoAmount = min (FindInventory (invoker.ammoType1).maxAmount - CountInv (invoker.ammoType1), CountInv (invoker.ammoType2));
            if (ammoAmount <= 0)
                return ResolveState ("Ready2");

            GiveInventory (invoker.ammoType1, ammoAmount);
            TakeInventory (invoker.ammoType2, ammoAmount);

            return ResolveState ("ReloadFinish");
        }
    ReloadFinish:
        MANX ADEFG 2;
        MANX H     6;
        MANX IJ    1;
        MANX KL    2;
        MANX M     2 A_PlaySound ("Weapons/ManxCarbine/In", CHAN_6);
        MANX NO    2;
        MANX PQEDA 2;
        goto Ready2;

    // Muzzle flashes
    Flash:
        MNXF A 1 bright;
        stop;
    }
}