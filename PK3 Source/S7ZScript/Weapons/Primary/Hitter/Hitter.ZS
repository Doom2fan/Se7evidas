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
// SR20 "Hitter" .45 ACP SMG
//
//-------------------------------------------------------------------------------------------
class S7_HitterSMGClip : Ammo {
    default {
        Inventory.MaxAmount 62;
        Ammo.BackpackMaxAmount 62;

        +INVENTORY.IGNORESKILL
    }
}

class S7_HitterSMG : S7_BaseWeapon {
    default {
        Tag "$HITTERSMG";
        Inventory.PickupMessage "HITTERSMG";
        Inventory.PickupSound "Weapons/Pickup/Small";

        Weapon.AmmoType1 'S7_HitterSMGClip';
        Weapon.AmmoType2 'S7_45ACPCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "SR20Z0";
        S7_BaseWeapon.ShortTag "$SHORTHITTERSMG";
        S7_BaseWeapon.AmmoBuyData "AACP", 1;
        S7_BaseWeapon.BindSlot WpSlot_Light;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.075;
        S7_BaseWeapon.EnchantmentPrice 650, 0.1, 1.16;
    }

    bool upperJammed, lowerJammed;

    action void S7_SpawnCasing () {
        S7_A_SpawnCasing ('S7_45ACPCasing', (30, 10, 10), pitchOffs: -45, spread: (10, 15));
    }

    states {
    Spawn:
        SR20 Z -1;
        loop;

    Ready:
        SR20 A 1 DoSelectOffset ((88, 88), forceNoInterpolate: true);
        SR20 A 1 DoSelectOffset ((72, 72));
        SR20 A 1 DoSelectOffset ((48, 48));
        SR20 A 1 DoSelectOffset ((24, 24));
        SR20 A 1 DoSelectOffset (( 8,  8));
        SR20 A 1 DoSelectOffset (( 0,  0));
    Ready2:
        SR20 A 1 S7_WeaponReady ("Reload", null);
        loop;

    Deselect:
        SR20 A 1 {
            if (health <= 0)
                return ResolveState ("Deselect.DEAD");

            DoSelectOffset (( 0,  0));
            return ResolveState (null);
        }
        SR20 A 1 DoSelectOffset (( 8,  8));
        SR20 A 1 DoSelectOffset ((24, 24));
        SR20 A 1 DoSelectOffset ((48, 48));
        SR20 A 1 DoSelectOffset ((72, 72));
        SR20 A 1 DoSelectOffset ((88, 88));
        goto TrueDeselect;

    Fire:
        SR20 A 1 A_JumpIf (!CheckInventory (invoker.ammoType1, 2), "DryFire");
    Hold:
        SR20 A  1 {
            if (!CheckInventory (invoker.ammoType1, 2))
                return ResolveState ("DryFire.Firing");

            if (invoker.upperJammed && invoker.lowerJammed)
                return ResolveState ("DoubleJammed");

            if (!invoker.upperJammed) {
                S7_SpawnCasing ();
                S7_A_FireBullets ('S7_HitterSMGTracer', spread: (.5, .5), offs: (10, 3.75, 3), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
            } else
                A_PlaySound ("Weapons/DryFireSMG", CHAN_6);

            if (!invoker.lowerJammed) {
                S7_SpawnCasing ();
                S7_A_FireBullets ('S7_HitterSMGTracer', spread: (.5, .5), offs: (10, 3.75, 6), bonusDMGFactor: invoker.Enchantments_GetDamageBonus (), flags: S7_FB_UseAmmo);
            } else
                A_PlaySound ("Weapons/DryFireSMG", CHAN_7);

            if (invoker.upperJammed)
                A_GunFlash ("Flash.UpperJammed");
            else if (invoker.lowerJammed)
                A_GunFlash ("Flash.LowerJammed");
            else
                A_GunFlash ("Flash");

            A_PlaySound ("Weapons/HitterSMG/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 1.5));
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 2.5));

            if (random [weaponSpc] () < 3) {
                int jamType = randomPick [weaponSpc] (0, 0, 1, 1, 2); // More likely to jam only one barrel

                if (jamType == 0 || jamType == 3)
                    invoker.upperJammed = true;
                if (jamType == 1 || jamType == 3)
                    invoker.lowerJammed = true;
            }

            S7_Recoil (-0.6);

            return ResolveState (null);
        }
        SR20 E  1 S7_Recoil (-0.6);
        SR20 D  1;
        SR20 C  1 A_Refire ("Hold");
        SR20 BA 1 A_ClearRefire;
        SR20 A  9;
        goto Ready2;

    DryFire:
        SR20 A 3 A_PlaySound ("Weapons/DryFireSMG", CHAN_7);
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;
    DryFire.Firing:
        SR20 A    1 {
            A_ClearRefire ();
            A_PlaySound ("Weapons/DryFireSMG", CHAN_7);
        }
        SR20 EDCB 1;
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    DoubleJammed:
        SR20 A     1 {
            A_ClearRefire ();
            A_PlaySound ("Weapons/DryFireSMG", CHAN_7);
        }
        SR20 CEDCB 1;
        SR20 A     1;
        goto Ready2;

    AltFire:
        SR20 A      1 A_ClearRefire;
        SR20 KLMNOP 1;
        SR20 Q      1 {
            if (invoker.upperJammed || CheckInventory (invoker.ammoType1, 1)) {
                S7_SpawnCasing ();
                if (!invoker.upperJammed)
                    TakeInventory (invoker.ammoType1, 1);
            }
            if (invoker.lowerJammed || CheckInventory (invoker.ammoType1, 1)) {
                S7_SpawnCasing ();
                if (!invoker.lowerJammed)
                    TakeInventory (invoker.ammoType1, 1);
            }

            invoker.upperJammed = false;
            invoker.lowerJammed = false;
            A_PlaySound ("Weapons/HitterSMG/Slide", CHAN_6);
        }
        SR20 RSTUVW 1;
        SR20 A 1 A_JumpIf (CheckInventory ('S7_Reloading', 1), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            A_ClearRefire ();

            if (invoker.upperJammed || invoker.lowerJammed)
                return ResolveState ("AltFire");

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
        // Reloading anim here
        SR20 AF  1;
        SR20 G   1 A_PlaySound ("Weapons/HitterSMG/Out", CHAN_6);
        SR20 H   1;
        SR20 I  18;
        SR20 I  28 A_PlaySound ("Weapons/HitterSMG/In", CHAN_7);
        SR20 JA  1;
        goto Ready2;

    Flash:
        SR2F A 1 bright;
        stop;
    Flash.UpperJammed:
        SR2F C 1 bright;
        stop;
    Flash.LowerJammed:
        SR2F B 1 bright;
        stop;
    }
}