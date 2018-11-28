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
// Super Shotgun
//
//-------------------------------------------------------------------------------------------
class S7_SSGLeftLoadedToken  : S7_Boolean { } // These are for HUDs and stuff
class S7_SSGRightLoadedToken : S7_Boolean { }
class S7_SSGFauxClip : Ammo {
    default {
        Inventory.MaxAmount 2;
        Ammo.BackpackMaxAmount 2;

        +INVENTORY.IGNORESKILL
    }
}

class S7_SSG : S7_BaseWeapon {
    default {
        Tag "$SSG";
        Inventory.PickupMessage "$SSG";

        Weapon.AmmoType1 'S7_SSGFauxClip';
        Weapon.AmmoType2 'S7_12gaShells';
        Weapon.AmmoUse 0;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "SSGPA0";
        S7_BaseWeapon.ShortTag "$SHORTSSG";
        S7_BaseWeapon.BindSlot WpSlot_Medium;
        S7_BaseWeapon.UsesMag false;
        S7_BaseWeapon.CanReloadWhileSprinting true;
    }

    bool leftLoaded, rightLoaded, firingBoth;

    override void DoEffect () {
        Super.DoEffect ();

        Owner.SetInventory ('S7_SSGLeftLoadedToken',  (leftLoaded  ? 1 : 0));
        Owner.SetInventory ('S7_SSGRightLoadedToken', (rightLoaded ? 1 : 0));
        Owner.SetInventory ('S7_SSGFauxClip', Owner.CountInv ('S7_SSGLeftLoadedToken') + Owner.CountInv ('S7_SSGRightLoadedToken'));
    }

    override void DetachFromOwner () {
        Super.DetachFromOwner ();

        Owner.SetInventory ('S7_SSGLeftLoadedToken',  0);
        Owner.SetInventory ('S7_SSGRightLoadedToken', 0);
        Owner.SetInventory ('S7_SSGFauxClip', 0);
    }

    override bool SS_PreSell (int amount) {
        int count = 0;
        if ( leftLoaded) count++;
        if (rightLoaded) count++;

        for (int i = 0; i < count; i++) {
            if (Ammo2.Amount < Ammo2.MaxAmount)
                Owner.GiveInventory (Ammo2.GetClass (), 1);
            else
                DropAmmo (Ammo2.GetClass (), Owner, 1);
        }

        return true;
    }

    action void S7_FireSSG (bool right) {
        if (!right) {
            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 1, 1.5);
            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 1, 1.5);
            for (int i = 0; i < 9; i++)
                A_FireProjectile ('S7_12gaTracer', fRandom [weaponSpread] (-0.35, 0.35), true, 2, -8, 0, fRandom [weaponSpread] (-0.35, 0.35));
            invoker.leftLoaded = false;
        } else {
            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 2, 1.5);
            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 2, 1.5);
            for (int i = 0; i < 9; i++)
                A_FireProjectile ('S7_12gaTracer', fRandom [weaponSpread] (-0.35, 0.35), true, 5, -8, 0, fRandom [weaponSpread] (-0.35, 0.35));
            invoker.rightLoaded = false;
        }
    }

    states {
    Spawn:
        SSGP A -1;
        loop;

    Ready:
        SSG0 A 1 DoSelectOffset ((-71, 50));
        SSG0 A 1 DoSelectOffset ((-61, 35));
        SSG0 A 1 DoSelectOffset ((-48, 21));
        SSG0 A 1 DoSelectOffset ((-34, 11));
        SSG0 A 1 DoSelectOffset ((-11,  4));
        SSG0 A 1 DoSelectOffset ((  0,  0));
    Ready2:
        SSG0 A 1 {
            bool attack = ((player.cmd.buttons & BT_ATTACK) && !(player.oldbuttons & BT_ATTACK)), altAttack = ((player.cmd.buttons & BT_ALTATTACK) && !(player.oldbuttons & BT_ALTATTACK));
            if (attack && altAttack)
                return ResolveState ("Fire.Both");
            if (attack)
                return ResolveState ("Fire.Left");
            if (altAttack)
                return ResolveState ("Fire.Right");

            S7_WeaponReady ("Reload", null, wrFlags: WRF_NoFire);

            return ResolveState (null);
        }
        loop;

    Deselect:
        SSG0 A 1 DoSelectOffset ((  0,  0));
        SSG0 A 1 DoSelectOffset ((-11,  4));
        SSG0 A 1 DoSelectOffset ((-34, 11));
        SSG0 A 1 DoSelectOffset ((-48, 21));
        SSG0 A 1 DoSelectOffset ((-61, 35));
        SSG0 A 1 DoSelectOffset ((-71, 50));
        goto TrueDeselect;

    Fire.Left:
        SSG5 A 1 {
            if ((player.cmd.buttons & BT_ALTATTACK) && !(player.oldbuttons & BT_ALTATTACK))
                return ResolveState ("Fire.Both");

            if (!invoker.leftLoaded)
                return ResolveState ("DryFireLeft");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_Weapon);
            A_GunFlash ("Flash.Left");

            S7_FireSSG (false);

            S7_Recoil (-2.175);

            return ResolveState (null);
        }
        SSG5 B 1 S7_Recoil (-2.175);
        goto Ready2;
    Fire.Right:
        SSG5 A 1 {
            if ((player.cmd.buttons & BT_ATTACK) && !(player.oldbuttons & BT_ATTACK))
                return ResolveState ("Fire.Both");

            if (!invoker.rightLoaded)
                return ResolveState ("DryFireRight");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_5);
            A_GunFlash ("Flash.Right");

            S7_FireSSG (true);

            S7_Recoil (-2.175);

            return ResolveState (null);
        }
        SSG5 B 1 S7_Recoil (-2.175);
        goto Ready2;

    Fire.Both:
        SSG5 A 1 {
            if (!invoker.leftLoaded && !invoker.rightLoaded)
                return ResolveState ("DryFireBoth");
            else if (!invoker.leftLoaded)
                return ResolveState ("Fire.Both.DryLeft");
            else if (!invoker.rightLoaded)
                return ResolveState ("Fire.Both.DryRight");

            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_Weapon);
            A_GunFlash ("Flash.Both");

            S7_FireSSG (false);

            S7_Recoil (-1.0875);

            return ResolveState (null);
        }
        SSG5 A 1 {
            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_5);

            S7_FireSSG (true);

            S7_Recoil (-5.4375); // 2.175 * 2.5
        }
        SSG5 B 1 S7_Recoil (-2.175);
        SSG0 A 4;
        goto Ready2;
    Fire.Both.DryLeft:
        SSG5 A 1 A_PlaySound ("Weapons/DryFireShotgun", CHAN_Weapon);
        SSG5 A 1 {
            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_5);
            A_GunFlash ("Flash.Right");

            S7_FireSSG (true);

            S7_Recoil (-2.175);
        }
        SSG5 B 1 S7_Recoil (-2.175);
        SSG0 A 4;
        goto Ready2;
    Fire.Both.DryRight:
        SSG5 A 1 {
            A_AlertMonsters ();
            A_PlaySound ("Weapons/SSG/Fire", CHAN_Weapon);
            A_GunFlash ("Flash.Left");

            S7_FireSSG (false);

            S7_Recoil (-2.175);

            return ResolveState (null);
        }
        SSG5 B 1 {
            A_PlaySound ("Weapons/DryFireShotgun", CHAN_6);
            S7_Recoil (-2.175);
        }
        SSG0 A 5;
        goto Ready2;

    Flash.Left:
        SSG5 CD 1 bright;
        stop;
    Flash.Right:
        SSG5 EF 1 bright;
        stop;
    Flash.Both:
        SSG5 CGF 1 bright;
        stop;

    DryFireLeft:  SSG0 A 3 A_PlaySound ("Weapons/DryFireShotgun", CHAN_6); goto DryFireEnd;
    DryFireRight: SSG0 A 3 A_PlaySound ("Weapons/DryFireShotgun", CHAN_7); goto DryFireEnd;
    DryFireBoth:  SSG0 A 1 A_PlaySound ("Weapons/DryFireShotgun", CHAN_6);
                  SSG0 A 2 A_PlaySound ("Weapons/DryFireShotgun", CHAN_7); goto DryFireEnd;

    DryFireEnd:
        TNT1 A 0 A_JumpIf (!invoker.leftLoaded && !invoker.rightLoaded && S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    Reload:
        TNT1 A     0 {
            TakeInventory ('S7_Reloading', 1);

            if ((invoker.leftLoaded && invoker.rightLoaded) ||
                (!invoker.leftLoaded && !invoker.rightLoaded && !CheckInventory (invoker.ammoType2, 2)) ||
                (!invoker.leftLoaded && !CheckInventory (invoker.ammoType2, 1)) ||
                (!invoker.rightLoaded && !CheckInventory (invoker.ammoType2, 1)))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        SSG0 AAABC 1;
        SSG0 D     1 A_PlaySound ("Weapons/SSG/Open", CHAN_7);
        SSG0 E     1;
        TNT1 A     0 {
            if (!invoker.leftLoaded && !invoker.rightLoaded)
                return ResolveState ("LoadBoth");
            else if (!invoker.leftLoaded && invoker.rightLoaded)
                return ResolveState ("LoadLeft");
            else if (invoker.leftLoaded && !invoker.rightLoaded)
                return ResolveState ("LoadRight");

            return ResolveState ("ReloadEnd"); // Shouldn't EVER get here. If it still somehow did, uh... Just close the shotgun without reloading.
        }

    LoadBoth:
        SSG0 F         1 {
            A_FireProjectile ('S7_12gaShellCasingSpawn', 0, false, 4, -16);
            A_FireProjectile ('S7_12gaShellCasingSpawn', 0, false, 7, -18);
        }
        SSG0 GHIJKLMNO 1;
        SSG0 P         1 {
            A_PlaySound ("Weapons/SSG/In", CHAN_6);
            invoker.leftLoaded = true;
            TakeInventory (invoker.ammoType2, 1);
        }
        SSG0 Q         4;
        SSG0 RSTUVWXYZ 1;
        SSG1 A         1;
        SSG1 B         1 {
            A_PlaySound ("Weapons/SSG/In", CHAN_7);
            invoker.rightLoaded = true;
            TakeInventory (invoker.ammoType2, 1);
        }
        SSG1 C         4;
        SSG1 DEFGHI    1;
        goto ReloadEnd;

    LoadLeft:
        SSG3 A         1 A_FireProjectile ('S7_12gaShellCasingSpawn', 0, false, 4, -16);
        SSG3 BCDEFHIJK 1;
        SSG0 Q         4 {
            A_PlaySound ("Weapons/SSG/In", CHAN_6);
            invoker.leftLoaded = true;
            TakeInventory (invoker.ammoType2, 1);
        }
        SSG3 LM        1;
        SSG1 DEFGHI    1;
        goto ReloadEnd;

    LoadRight:
        SSG2 A      1 A_FireProjectile ('S7_12gaShellCasingSpawn', 0, false, 7, -18);
        SSG2 BCDE   1;
        SSG0 WXYZ   1;
        SSG1 A      1;
        SSG1 B      1 {
            A_PlaySound ("Weapons/SSG/In", CHAN_6);
            invoker.rightLoaded = true;
            TakeInventory (invoker.ammoType2, 1);
        }
        SSG1 C      4;
        SSG1 DEFGHI 1;
        goto ReloadEnd;

    ReloadEnd:
        SSG0 E     1;
        SSG0 D     1 A_PlaySound ("Weapons/SSG/Close", CHAN_Weapon);
        SSG0 CBAAA 1;
        goto Ready2;
    }
}