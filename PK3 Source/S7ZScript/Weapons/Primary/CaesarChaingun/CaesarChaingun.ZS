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
// Avtomat Kalashnikova 47
//
//-------------------------------------------------------------------------------------------
class S7_CaesarChaingunMag : Ammo {
    default {
        Inventory.MaxAmount 100;
        Ammo.BackpackMaxAmount 100;

        +INVENTORY.IGNORESKILL
    }
}

class S7_CaesarChaingun : S7_BaseWeapon {
    default {
        Tag "$CAESARCHAINGUN";
        Inventory.PickupMessage "$CAESARCHAINGUN";

        Weapon.AmmoType1 'S7_CaesarChaingunMag';
        Weapon.AmmoType2 'S7_45WWCartridges';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "CESRZ0";
        S7_BaseWeapon.ShortTag "$SHORTCAESARCHAINGUN";
        S7_BaseWeapon.BindSlot WpSlot_Heavy;
        S7_BaseWeapon.UsesMag true;
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        fireMode = 1;
    }

    int fireMode;
    bool firedDud;

    states {
    Spawn:
        CESR Z -1;
        loop;

    Ready:
        CESR A 1 A_WeaponOffset (0 + (14.4 * 5), 32 + (14.4 * 5), WOF_Interpolate);
        CESR A 1 A_WeaponOffset (0 + (14.4 * 4), 32 + (14.4 * 4), WOF_Interpolate);
        CESR A 1 A_WeaponOffset (0 + (14.4 * 3), 32 + (14.4 * 3), WOF_Interpolate);
        CESR A 1 A_WeaponOffset (0 + (14.4 * 2), 32 + (14.4 * 2), WOF_Interpolate);
        CESR A 1 A_WeaponOffset (0 + (14.4 * 1), 32 + (14.4 * 1), WOF_Interpolate);
        CESR A 1 A_WeaponOffset (0, 32);
    Ready2:
        CESR A 1 S7_WeaponReady ("Reload", "ChangeMode");
        loop;

    ChangeMode:
        CESR A 5 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            if (++invoker.fireMode > 2)
                invoker.fireMode = 0;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);
        }
        goto Ready2;

    Deselect:
        CESR A 1 A_WeaponOffset (0, 32);
        CESR A 1 A_WeaponOffset (0 + (14.4 * 1), 32 + (14.4 * 1), WOF_Interpolate);
        CESR A 1 A_WeaponOffset (0 + (14.4 * 2), 32 + (14.4 * 2), WOF_Interpolate);
        CESR A 1 A_WeaponOffset (0 + (14.4 * 3), 32 + (14.4 * 3), WOF_Interpolate);
        CESR A 1 A_WeaponOffset (0 + (14.4 * 4), 32 + (14.4 * 4), WOF_Interpolate);
        CESR A 1 A_WeaponOffset (0 + (14.4 * 5), 32 + (14.4 * 5), WOF_Interpolate);
        goto TrueDeselect;

    Fire:
        CESR A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            invoker.firedDud = (random [weaponSpc] (0, 255) < 2);

            if (!invoker.firedDud) {
                A_AlertMonsters ();
                A_GunFlash ("Flash");

                A_FireProjectile ('S7_CaesarChaingun_Tracer', fRandom [weaponSpread] (-0.16, 0.16), true, 9, -2, 0, fRandom [weaponSpread] (-0.16, 0.16));
                A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 4.5, 2.85);

                A_PlaySound ("Weapons/CaesarChaingun/Fire", CHAN_Weapon);

                S7_Recoil (-0.9);
                A_WeaponOffset (6, 32 + 6);
            } else
                invoker.DepleteAmmo (false);

            A_FireProjectile ('S7_45WWCasingSpawnRifle', 0, false, 11.5, -9);

            return ResolveState (null);
        }
        CESR A 1 {
            if (!invoker.firedDud) {
                S7_Recoil (-0.9);
                A_WeaponOffset (3, 32 + 3);
            }
        }
        CESR A 2 {
            switch (invoker.fireMode) {
                default: A_SetTics (2); break;
                case  1: A_SetTics (1); break;
                case  2: A_SetTics (0); break;
            }
            if (!invoker.firedDud)
                S7_Recoil (-0.9);

            A_WeaponOffset (0, 32);
        }
    Fire.End:
        CESR A 1 A_Refire ("Fire");
        goto Ready2;

    DryFire:
        CESR A 3 A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
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
        CESR ABCD 1;
        CESR E    6;
        CESR FGH  1;
        CESR I    1 A_PlaySound ("Weapons/CaesarChaingun/Out", CHAN_5);
        CESR I    2 A_WeaponOffset (-2, 32 - 2);
        CESR J    2 A_WeaponOffset (-1, 32 - 1);
        CESR K    1 A_WeaponOffset ( 0, 32    );
        CESR LMN  1;
        CESR OPPQ 1;
        CESR R   20;
        CESR QPPO 1;
        CESR NMLK 1;
        CESR J    1 A_PlaySound ("Weapons/CaesarChaingun/In", CHAN_6);
        CESR I    2 A_WeaponOffset (2, 32 + 2);
        CESR I    2 A_WeaponOffset (1, 32 + 1);
        CESR H    1 A_WeaponOffset (0, 32    );
        CESR GF   1;
        CESR E    6;
        CESR DCBA 1;
        goto Ready2;

    // Muzzle flashes
    Flash:
        CSRF A 1 bright;
        stop;
    }
}