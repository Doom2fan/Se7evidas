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

//-------------------------------------------------------------------------------------------
//
// Ω-Σ "Deathbringer" Revolver
//
//-------------------------------------------------------------------------------------------
class S7_RevolverClip : Ammo {
    default {
        Inventory.MaxAmount 6;
        Ammo.BackpackMaxAmount 6;

        +INVENTORY.IGNORESKILL
    }
}

class S7_Revolver : S7_BaseWeapon {
    default {
        Tag "$REVOLVER";
        Inventory.PickupMessage "$REVOLVER";

        Weapon.AmmoType1 'S7_RevolverClip';
        Weapon.AmmoType2 'S7_44MCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "RVLPA0";
        S7_BaseWeapon.ShortTag "$SHORTREVOLVER";
        S7_BaseWeapon.BindSlot WpSlot_Light;
        S7_BaseWeapon.UsesMag true;
    }

    states {
    Spawn:
        RVLP A -1;
        loop;

    Ready:
        RVLV A 1 DoSelectOffset ((96, 96), forceNoInterpolate: true);
        RVLV A 1 DoSelectOffset ((72, 72));
        RVLV A 1 DoSelectOffset ((48, 48));
        RVLV A 1 DoSelectOffset ((24, 24));
        RVLV A 1 DoSelectOffset (( 8,  8));
        RVLV A 1 DoSelectOffset (( 0,  0));
    Ready2:
        RVLV A 1 S7_WeaponReady ("Reload", null);
        loop;

    Deselect:
        RVLV A 1 DoSelectOffset (( 0,  0));
        RVLV A 1 DoSelectOffset (( 8,  8));
        RVLV A 1 DoSelectOffset ((24, 24));
        RVLV A 1 DoSelectOffset ((48, 48));
        RVLV A 1 DoSelectOffset ((72, 72));
        RVLV A 1 DoSelectOffset ((96, 96));
        goto TrueDeselect;

    Fire:
        RVLV AABB 1;
        RVLV C  1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/Revolver/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 2, 5);
            A_FireProjectile ('S7_RevolverTracer', fRandom [weaponSpread] (-0.5, 0.5), true, 5, 2, 0, fRandom [weaponSpread] (-0.5, 0.5));

            S7_Recoil (-1.75);

            return ResolveState (null);
        }
        RVLV D  1 S7_Recoil (-1.75);
        RVLV EE 1;
        RVLV FG 1;
        RVLV A  1;
        goto Ready2;

    Flash:
        RVLF A 1 bright;
        stop;

    DryFire:
        RVLV C 3 A_PlaySound ("Weapons/Revolver/Dryfire", CHAN_7);
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);

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
        // Open
        RVLV AHIJ 1;
        RVLV KL   1;
        RVLV M    2 A_PlaySound ("Weapons/Revolver/Open", CHAN_5);
        RVLV NOP  1;
        RVLV QRR  1;
        RVLV S    3;
        // Eject
        RVLV T     1 {
            A_PlaySound ("Weapons/Revolver/Eject", CHAN_6);
            for (int i = 0; i < 3; i++) {
                A_FireProjectile ('S7_RevolverCasingSpawn', 0, false, 8 + i, -2);
                A_FireProjectile ('S7_RevolverCasingSpawn', 0, false, 8 + i, -3);
            }
        }
        RVLV U     5;
        RVLV VWXYZ 1;
        // Insert
        RVL2 ABCD 1;
        RVL2 E    3 A_PlaySound ("Weapons/Revolver/In", CHAN_7);
        RVL2 F    3;
        // Close
        RVL2 G   1;
        RVL2 H   1 A_PlaySound ("Weapons/Revolver/Close", CHAN_Weapon);
        RVL2 IJK 1;
        RVL2 LM  1;
        RVLV A   3;
        goto Ready2;
    }
}