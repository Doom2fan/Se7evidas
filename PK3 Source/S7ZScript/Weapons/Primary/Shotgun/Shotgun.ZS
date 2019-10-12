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
// AM-10 "Lucifer" Combat Shotgun
//
//-------------------------------------------------------------------------------------------
class S7_ShotgunMag : Ammo {
    default {
        Inventory.MaxAmount 10;
        Ammo.BackpackMaxAmount 10;

        +INVENTORY.IGNORESKILL
    }
}

class S7_Shotgun : S7_BaseWeapon {
    default {
        Tag "$SHOTGUN";
        Inventory.PickupMessage "$SHOTGUN";
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_ShotgunMag';
        Weapon.AmmoType2 'S7_20gaShells';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "DTUPA0";
        S7_BaseWeapon.ShortTag "$SHORTSHOTGUN";
        S7_BaseWeapon.AmmoBuyData "A20g", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_Medium;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 700, 0.4, 1.16;
    }

    int loaded;

    override bool SS_PreSell (int amount) {
        int amt = Ammo1.Amount + loaded;

        if ((Ammo2.Amount + amt) > Ammo2.MaxAmount && amt == (GetDefaultByType (Ammo2.GetClass ()).Amount))
            DropAmmo (Ammo2.GetClass (), Owner, 1);
        else {
            for (int i = amt; i > 0; i--) {
                if (Ammo2.Amount < Ammo2.MaxAmount)
                    Owner.GiveInventory (Ammo2.GetClass (), 1);
                else
                    DropAmmo (Ammo2.GetClass (), Owner, 1, angleOffs: fRandom [invSpc] (-5, 5));
            }
        }

        Owner.TakeInventory (Ammo1.GetClass (), 0x7FFFFFFF);

        return true;
    }

    action void S7_FireShotgun (bool right) {
        if (!right) {
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 1, 3.5), amount: 2);
            S7_A_FireBullets ('S7_SSGTracer', spread: (.25, .25), offs: (10, 2, 6), amount: 18, bonusDMGFactor: invoker.Enchantments_GetDamageBonus ());
        } else {
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 4, 3.5), amount: 2);
            S7_A_FireBullets ('S7_SSGTracer', spread: (.25, .25), offs: (10, 6, 8), amount: 18, bonusDMGFactor: invoker.Enchantments_GetDamageBonus ());
        }
    }

    action void S7_SpawnCasing (bool right) {
        if (!right)
            S7_A_SpawnCasing ('S7_ShellCasing', (30, 4.0, 12), pitchOffs: 90, spread: (0, 0), horzMul: -.5);
        else
            S7_A_SpawnCasing ('S7_ShellCasing', (30, 4.5, 12), pitchOffs: 90, spread: (0, 0), horzMul:  .5);
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        DTUP A -1;
        stop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        SSGR A 1;
        wait;
    Anim.Fire:
        SSGF E 1 bright;
        SSGF E 2;
        SSGF F 1;
        goto Anim.Idle;
    Anim.AltFire:
        SSGF ED 1 bright;
        SSGF DD 1;
        SSGF EF 1;
        SSGR A  1;
        goto Anim.Idle;
    Anim.Pump: // 10 tics
        SSGR A 1 A_WeaponOffset ( 4, 32 +  4);
        SSGR A 1 A_WeaponOffset ( 8, 32 +  8);
        SSGR A 4 A_WeaponOffset (12, 32 + 12);
        SSGR A 1 A_WeaponOffset ( 9, 32 +  9);
        SSGR A 1 A_WeaponOffset ( 6, 32 +  6);
        SSGR A 1 A_WeaponOffset ( 3, 32 +  3);
        SSGR A 1 A_WeaponOffset ( 0, 32     );
        goto Anim.Idle;
    Anim.InsertShells: // 28 tics
        DSGR AB 1;
        DSGR C  4;
        DSGR BA 1;
        DSGR A  1 A_PlaySound ("Weapons/Shotgun/ShellIn", CHAN_6);
        DSGR B  1;
        DSGR C  4;
        DSGR B  1;
        DSGR A 13;
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 S7_SetAnim ("Anim.Idle");
        TNT1 A 1 DoSelectOffset ((64, 64), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((32, 32));
        TNT1 A 1 DoSelectOffset ((16, 16));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset (( 0,  0));
    Ready2:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            S7_WeaponReady ("Reload", null, "QuickMeleeDerp");
        }
        loop;
    QuickMeleeDerp:
        TNT1 A 0 S7_SetAnim ("Null");
        goto QuickMelee;

    Deselect:
        SSGR A 0 {
            if (health <= 0) {
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            S7_SetAnim ("Anim.Idle");

            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 1 DoSelectOffset (( 8,  8));
        TNT1 A 1 DoSelectOffset ((16, 16));
        TNT1 A 1 DoSelectOffset ((32, 32));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((64, 64));
        goto TrueDeselect;

    Fire:
        TNT1 A 1 {
            bool firingRight = false;
            int ammoCount = CountInv (invoker.ammoType1);

            if (ammoCount >= 10 && invoker.loaded != 2) // If the mag ammo is completely full, (i.e. two in chamber and 8 in mag) then this makes no sense.
                invoker.loaded = 2;                     // Probably cheating or a bug. Just silently fix it and fire anyway.
            else if (ammoCount <= 0)
                return ResolveState ("DryFire");
            else if (invoker.loaded == 1 || (invoker.loaded > 0 && ammoCount == 1)) {
                firingRight = true;
            } else if (invoker.loaded <= 0)
                return ResolveState ("Pump");

            S7_SetAnim ("Anim.Fire");

            A_PlaySound ("Weapons/Shotgun/Fire", CHAN_5);
            A_AlertMonsters ();
            if (!firingRight)
                A_GunFlash ("FlashLeft");
            else
                A_GunFlash ("FlashRight");

            invoker.loaded--;
            invoker.DepleteAmmo (false, true, 1);
            S7_FireShotgun (firingRight);

            A_ZoomFactor (.98, ZOOM_Instant);
            S7_Recoil (-1.45);

            return ResolveState (null);
        }
        TNT1 A  2 {
            A_ZoomFactor (.99);
            S7_Recoil (-1.45);
        }
        TNT1 A 1 {
            A_ZoomFactor (1.);
            S7_Recoil (+.725);
        }
        TNT1 A 1 S7_Recoil (+.725);
        goto Ready2;

    AltFire:
        TNT1 A 0 {
            int ammoCount = CountInv (invoker.ammoType1);

            if (ammoCount >= 10 && invoker.loaded != 2) // If the mag ammo is completely full, (i.e. two in chamber and 8 in mag) then this makes no sense.
                invoker.loaded = 2;                     // Probably cheating or a bug. Just silently fix it and fire anyway.
            else if (ammoCount == 0)
                return ResolveState ("DryFire");
            else if (invoker.loaded == 0)
                return ResolveState ("Pump");
            else if (invoker.loaded == 1 || ammoCount == 1)
                return ResolveState ("Fire");

            S7_SetAnim ("Anim.AltFire");

            return ResolveState (null);
        }
        TNT1 A 1 bright {
            A_PlaySound ("Weapons/Shotgun/Fire", CHAN_5);

            A_AlertMonsters ();
            A_GunFlash ("AltFlash");

            invoker.loaded = 1;
            invoker.DepleteAmmo (false, true, 1);
            S7_FireShotgun (false);

            A_ZoomFactor (.98, ZOOM_Instant);
            S7_Recoil (-.725);
        }
        TNT1 A 1 bright {
            A_PlaySound ("Weapons/Shotgun/Fire", CHAN_6);

            A_AlertMonsters ();

            invoker.loaded = 0;
            invoker.DepleteAmmo (false, true, 1);
            S7_FireShotgun (true);

            A_ZoomFactor (.975, ZOOM_Instant);
            S7_Recoil (-2.175);
        }
        TNT1 A 1 {
            A_ZoomFactor (.9875);
            S7_Recoil (-1.45);
        }
        TNT1 A 1 {
            A_ZoomFactor (1.);
            S7_Recoil (-1.45);
        }
        TNT1 A 1;
        TNT1 A 1 S7_Recoil (+1.45);
        TNT1 A 1 S7_Recoil (+1.45);
        goto Ready2;

    FlashLeft:
        SSGF A 2 bright;
        stop;
    FlashRight:
        SSGF B 2 bright;
        stop;
    AltFlash:
        SSGF AC 1 bright;
        stop;

    Pump:
        TNT1 A 1 {
            int ammoCount = CountInv (invoker.ammoType1);

            if (ammoCount >= 10) {  // If the mag ammo is completely full, (i.e. two in chamber and 8 in mag) then this makes no sense.
                invoker.loaded = 2; // Probably cheating or a bug. Just silently fix it and fire anyway.
                return ResolveState ("Fire");
            } else if (ammoCount == 1 && invoker.loaded >= 1)
                return ResolveState ("Ready2");
            else if (ammoCount <= 0)
                return ResolveState ("DryFire");

            invoker.loaded = 2;

            return ResolveState (null);
        }
        TNT1 A 10 {
            S7_SetAnim ("Anim.Pump");
            A_PlaySound ("Weapons/Shotgun/Pump", CHAN_7);

            S7_SpawnCasing (false);
            S7_SpawnCasing (true);
        }
        goto Ready2;

    DryFire:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/DryFireShotgun", CHAN_7);
        }
        TNT1 A 0 {
            if (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload ()) {
                GiveInventory ('S7_Reloading', 1);
                return ResolveState ("Reload");
            }

            return ResolveState (null);
        }
        goto Ready2;

    Reload:
        TNT1 A 5 {
            if (!CheckInventory ('S7_Reloading', 1) || CheckInventory (invoker.ammoType1, 0) || CountInv (invoker.ammoType2) < 2)
                return ResolveState ("ReloadEnd");

            S7_SetAnim ("Anim.Idle");

            return ResolveState (null);
        }
        TNT1 A 0 A_JumpIf (invoker.loaded != 2, "InsertShells.Pump");
        goto InsertShells;

    InsertShells:
        TNT1 A 28 {
            if (!CheckInventory ('S7_Reloading', 1) || CheckInventory (invoker.ammoType1, 0) || CountInv (invoker.ammoType2) < 2)
                return ResolveState ("ReloadEnd");

            GiveInventory ('S7_ShotgunMag', 2);
            TakeInventory ('S7_20gaShells', 2);

            S7_SetAnim ("Anim.InsertShells");
            A_PlaySound ("Weapons/Shotgun/ShellIn", CHAN_5);

            return ResolveState (null);
        }
        TNT1 A 0 A_JumpIf (invoker.loaded != 2, "InsertShells.Pump");
        goto InsertShells;

    InsertShells.Pump:
        TNT1 A 1;
        TNT1 A 10 {
            if (invoker.loaded >= 2) {
                invoker.loaded = 2;
                return ResolveState ("InsertShells");
            } else if (invoker.loaded == 1) {
                TakeInventory (invoker.ammoType1, 1); // Remove the extra shell
                GiveInventory (invoker.ammoType2, 1);
                S7_SpawnCasing (false);
                if (CheckInventory (invoker.ammoType1, 2))
                    invoker.loaded = 2; // Load 2 shells into the chamber
                else
                    invoker.loaded = 0;
            } else if (invoker.loaded <= 0 && CheckInventory (invoker.ammoType1, 2)) {
                S7_SpawnCasing (false);
                S7_SpawnCasing (true);
                invoker.loaded = 2;
            } else
                return ResolveState ("InsertShells");

            A_PlaySound ("Weapons/Shotgun/Pump", CHAN_7);
            S7_SetAnim ("Anim.Pump");

            return ResolveState (null);
        }
        goto InsertShells;

    ReloadEnd:
        TNT1 A 0 TakeInventory ('S7_Reloading', 1);
        goto Ready2;
    }
}