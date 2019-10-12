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
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_SSGFauxClip';
        Weapon.AmmoType2 'S7_12gaShells';
        Weapon.AmmoUse 0;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "SSGPA0";
        S7_BaseWeapon.ShortTag "$SHORTSSG";
        S7_BaseWeapon.BindSlot S7_WpSlot_Medium;
        S7_BaseWeapon.UsesMag false;
        S7_BaseWeapon.CanReloadWhileSprinting true;
        S7_BaseWeapon.EnchantmentProperties true, 0.025;
        S7_BaseWeapon.EnchantmentPrice 700, 0.4, 1.16;
    }

    const AnimLayer_ID = 2;
    bool leftLoaded, rightLoaded, firingBoth_FiredLeft, firingBoth_FiredRight;

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
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 1, 4.5), amount: 2);
            S7_A_FireBullets ('S7_12gaTracer', spread: (.35, .35), offs: (10, 2, 12), amount: 9, bonusDMGFactor: invoker.Enchantments_GetDamageBonus ());
            invoker.leftLoaded = false;
        } else {
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 4.5), amount: 2);
            S7_A_FireBullets ('S7_12gaTracer', spread: (.35, .35), offs: (10, 6, 12), amount: 9, bonusDMGFactor: invoker.Enchantments_GetDamageBonus ());
            invoker.rightLoaded = false;
        }
    }

    action void S7_SpawnShell (bool right) {
        if (!right)
            S7_A_SpawnCasing ('S7_12gaShellCasing', (30, 4, 20), pitchOffs: -50, spread: (0, 1.5));
        else
            S7_A_SpawnCasing ('S7_12gaShellCasing', (30, 8, 20), pitchOffs: -50, spread: (0, 1.5));
    }

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        SSGP A -1;
        loop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        SSG0 A 1;
        wait;
    Anim.Fire:
        SSG5 A 1 bright;
        SSG5 B 1;
        goto Anim.Idle;

    Anim.ReloadOpen:
        SSG0 AAABC 1;
        SSG0 D     1 A_PlaySound ("Weapons/SSG/Open", CHAN_7);
        SSG0 E     1;
        wait;
    Anim.ReloadBoth:
        SSG0 F         1 {
            S7_SpawnShell (false);
            S7_SpawnShell (true);
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
        goto Anim.ReloadEnd;
    Anim.ReloadLeft:
        SSG3 A         1 S7_SpawnShell (false);
        SSG3 BCDEFHIJK 1;
        SSG0 Q         4 {
            A_PlaySound ("Weapons/SSG/In", CHAN_6);
            invoker.leftLoaded = true;
            TakeInventory (invoker.ammoType2, 1);
        }
        SSG3 LMN       1;
        SSG1 EFGHI     1;
        goto Anim.ReloadEnd;
    Anim.ReloadRight:
        SSG2 A      1 S7_SpawnShell (true);
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
        goto Anim.ReloadEnd;
    Anim.ReloadEnd:
        SSG0 E     1;
        SSG0 D     1 A_PlaySound ("Weapons/SSG/Close", CHAN_Weapon);
        SSG0 CBAAA 1;
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 S7_SetAnim ("Anim.Idle");
        TNT1 A 1 DoSelectOffset ((-71, 50), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((-61, 35));
        TNT1 A 1 DoSelectOffset ((-48, 21));
        TNT1 A 1 DoSelectOffset ((-34, 11));
        TNT1 A 1 DoSelectOffset ((-11,  4));
        TNT1 A 1 DoSelectOffset ((  0,  0));
    Ready2:
        TNT1 A 1 {
            bool attack = ((player.cmd.buttons & BT_Attack) && !(player.oldbuttons & BT_Attack));
            bool altAttack = ((player.cmd.buttons & BT_AltAttack) && !(player.oldbuttons & BT_AltAttack));
            if (attack && altAttack)
                return ResolveState ("Fire.Both");
            else if (attack)
                return ResolveState ("Fire.Left");
            else if (altAttack)
                return ResolveState ("Fire.Right");

            S7_SetAnim ("Anim.Idle");
            S7_WeaponReady ("Reload", null, "QuickMeleeDerp", wrFlags: WRF_NoFire);

            return ResolveState (null);
        }
        loop;
    QuickMeleeDerp:
        TNT1 A 0 S7_SetAnim ("Null");
        goto QuickMelee;

    Deselect:
        SSG0 A 0 {
            if (health <= 0) {
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            S7_SetAnim ("Anim.Idle");
            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset ((  0,  0));
        TNT1 A 1 DoSelectOffset ((-11,  4));
        TNT1 A 1 DoSelectOffset ((-34, 11));
        TNT1 A 1 DoSelectOffset ((-48, 21));
        TNT1 A 1 DoSelectOffset ((-61, 35));
        TNT1 A 1 DoSelectOffset ((-71, 50));
        goto TrueDeselect;
    }

    action state S7_FireSSGSingle (bool right, bool firingBoth = false) {
        if (!firingBoth) {
            int otherButton = (!right ? BT_AltAttack : BT_Attack);
            if (!(player.oldbuttons & otherButton) && (player.cmd.buttons & otherButton))
                return ResolveState ("Fire.Both");

            if (!right && !invoker.leftLoaded)
                return ResolveState ("DryFireLeft");
            else if (right && !invoker.rightLoaded)
                return ResolveState ("DryFireRight");
        }

        if (!firingBoth)
            S7_SetAnim ("Anim.Fire");

        A_AlertMonsters ();
        A_PlaySound ("Weapons/SSG/Fire", (!right ? CHAN_Weapon : CHAN_5));
        if (!firingBoth) {
            if (!right) A_GunFlash ("Flash.Left");
            else        A_GunFlash ("Flash.Right");
        }

        S7_FireSSG (right);
        A_ZoomFactor (.98, ZOOM_Instant);
        S7_Recoil (-2.175);

        return ResolveState (null);
    }

    action state S7_FireSSGBoth (bool right, bool firingBoth = false) {
        A_AlertMonsters ();
        A_PlaySound ("Weapons/SSG/Fire", (!right ? CHAN_Weapon : CHAN_5));

        S7_FireSSG (right);

        return ResolveState (null);
    }

    states {
    Fire.Left:
        TNT1 A 1 S7_FireSSGSingle (false);
        TNT1 A 1 {
            A_ZoomFactor (.99);
            S7_Recoil (-2.175);
        }
        TNT1 A 1 {
            A_ZoomFactor (1.);
            S7_Recoil (+1.0875);
        }
        goto Ready2;
    Fire.Right:
        TNT1 A 1 S7_FireSSGSingle (true);
        TNT1 A 1 {
            A_ZoomFactor (.99);
            S7_Recoil (-2.175);
        }
        TNT1 A 1 {
            A_ZoomFactor (1.);
            S7_Recoil (+1.0875);
        }
        goto Ready2;

    Fire.Both:
        TNT1 A 1 {
            if (!invoker.leftLoaded && !invoker.rightLoaded)
                return ResolveState ("DryFireBoth");

            if (invoker.leftLoaded && invoker.rightLoaded) {
                S7_SetAnim ("Anim.Fire");
                S7_FireSSGBoth (false);

                A_GunFlash ("Flash.Both");
                S7_Recoil (-1.0875);

                invoker.firingBoth_FiredLeft = true;
            } else if (!invoker.rightLoaded) {
                S7_SetAnim ("Anim.Fire");
                S7_FireSSGSingle (false, true);

                A_GunFlash ("Flash.Left");

                invoker.firingBoth_FiredLeft = true;
            } else {
                A_PlaySound ("Weapons/DryFireShotgun", CHAN_Weapon);
                invoker.firingBoth_FiredLeft = false;
            }

            if (invoker.firingBoth_FiredLeft)
                A_ZoomFactor (.98, ZOOM_Instant);

            return ResolveState (null);
        }
        TNT1 A 1 {
            if (invoker.firingBoth_FiredLeft && invoker.rightLoaded) {
                S7_SetAnim ("Anim.Fire");
                S7_FireSSGBoth (true);

                A_ZoomFactor (.975, ZOOM_Instant);
                S7_Recoil (-5.4375); // 2.175 * 2.5

                invoker.firingBoth_FiredRight = true;
            } else if (!invoker.firingBoth_FiredLeft) {
                S7_SetAnim ("Anim.Fire");
                A_GunFlash ("Flash.Right");

                S7_FireSSGSingle (true, true);
                A_ZoomFactor (.98, ZOOM_Instant);

                invoker.firingBoth_FiredRight = true;
            } else {
                A_ZoomFactor (.99);
                S7_Recoil (-2.175);
                A_PlaySound ("Weapons/DryFireShotgun", CHAN_5);

                invoker.firingBoth_FiredRight = false;
            }
        }
        TNT1 A 1 {
            if (invoker.firingBoth_FiredLeft && invoker.firingBoth_FiredRight) {
                A_ZoomFactor (.9875);
                S7_Recoil (-2.175);
            } else if (invoker.firingBoth_FiredLeft) {
                A_ZoomFactor (1.);
                S7_Recoil (+1.0875);
            } else if (invoker.firingBoth_FiredRight) {
                A_ZoomFactor (1.);
                S7_Recoil (-2.175);
            }
        }
        TNT1 A 1 {
            if (invoker.firingBoth_FiredLeft && invoker.firingBoth_FiredRight) {
                A_ZoomFactor (1.);
                S7_Recoil (+1.0875);
            } else if (invoker.firingBoth_FiredRight)
                S7_Recoil (+1.0875);
        }
        TNT1 A 1 {
            if (invoker.firingBoth_FiredLeft && invoker.firingBoth_FiredRight)
                S7_Recoil (+1.0875);
        }
        TNT1 A 2;
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

    DryFireLeft:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/DryFireShotgun", CHAN_6);
        }
        goto DryFireEnd;
    DryFireRight:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/DryFireShotgun", CHAN_7);
        }
        goto DryFireEnd;
    DryFireBoth:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/DryFireShotgun", CHAN_6);
        }
        TNT1 A 2 A_PlaySound ("Weapons/DryFireShotgun", CHAN_7);
        goto DryFireEnd;
    DryFireEnd:
        TNT1 A 0 A_JumpIf (!invoker.leftLoaded && !invoker.rightLoaded && S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);

            if ((invoker.leftLoaded && invoker.rightLoaded) ||
                (!invoker.leftLoaded && !invoker.rightLoaded && !CheckInventory (invoker.ammoType2, 2)) ||
                (!invoker.leftLoaded && !CheckInventory (invoker.ammoType2, 1)) ||
                (!invoker.rightLoaded && !CheckInventory (invoker.ammoType2, 1)))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        TNT1 A 5 S7_SetAnim ("Anim.ReloadOpen");
        TNT1 A 2 A_PlaySound ("Weapons/SSG/Open", CHAN_7);
        TNT1 A 0 {
            if (!invoker.leftLoaded && !invoker.rightLoaded)
                S7_SetAnim ("Anim.ReloadBoth");
            else if (!invoker.leftLoaded && invoker.rightLoaded)
                S7_SetAnim ("Anim.ReloadLeft");
            else if (invoker.leftLoaded && !invoker.rightLoaded)
                S7_SetAnim ("Anim.ReloadRight");
            else // Shouldn't EVER get here. If it still somehow did, uh... Just close the shotgun without reloading.
                S7_SetAnim ("Anim.ReloadEnd");
        }
        TNT1 A 1 {
            let psp = player.FindPSprite (AnimLayer_ID);
            if (psp && InStateSequence (psp.CurState, ResolveState ("Anim.Idle")))
                return ResolveState ("Ready2");

            return ResolveState (null);
        }
        wait;
    }
}