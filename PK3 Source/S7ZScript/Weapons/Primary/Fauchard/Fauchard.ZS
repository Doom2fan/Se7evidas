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
// FS/002A Mod 4 "Fauchard" Automatic Rifle
//
//-------------------------------------------------------------------------------------------
class S7_FauchardMag : Ammo {
    default {
        Inventory.MaxAmount 23;
        Ammo.BackpackMaxAmount 23;

        +INVENTORY.IGNORESKILL
    }
}

class S7_Fauchard : S7_BaseWeapon {
    default {
        //$Category "Se7evidas/Weapons"
        //$Color 14
        //$Title ""Fauchard" Laser Rifle"
        //$NotAngled

        Tag "$FAUCHARD";
        Inventory.PickupMessage "$FAUCHARD";
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_FauchardMag';
        Weapon.AmmoType2 'S7_FBSysCells';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "LRFPA0";
        S7_BaseWeapon.ShortTag "$SHORTFAUCHARD";
        S7_BaseWeapon.AmmoBuyData "AFBC", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_Medium;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties false, 0.;
    }

    double GetDamageBonus () {
        if (!Owner)
            return 0.;

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys)
            return 0.;

        return pPawn.xpSys.GetStat (S7Stat_Tech, false) * 0.025;
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        LRFP A -1;
        stop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        LSRF A 1;
        wait;
    Anim.Handless:
        LSRF H 1;
        wait;
    Anim.Fire:
        LSRF A 1 bright;
        LSRF B 1;
        goto Anim.Idle;
    Anim.SelectHand:
        TNT1 A 1;
        HAN0 A 1 DoSelectOffset (( 98, 156), -5, true);
        HAN0 A 1 DoSelectOffset ((110, 137), -5);
        HAN0 A 1 DoSelectOffset ((120, 122), -5);
        HAN0 A 1 DoSelectOffset ((134, 106), -5);
        stop;
    Anim.DeselectHand:
        HAN0 A 1 DoSelectOffset ((134, 106), -5, true);
        HAN0 A 1 DoSelectOffset ((120, 122), -5);
        HAN0 A 1 DoSelectOffset ((110, 137), -5);
        HAN0 A 1 DoSelectOffset (( 98, 156), -5);
        stop;
    Anim.Reload:
        LSRF ACDEFGH   2;
        LSRF I         2 A_PlaySound ("Weapons/Fauchard/Out", CHAN_6);
        LSRF J        30;
        LSRF J        12 A_PlaySound ("Weapons/Fauchard/In", CHAN_7);
        LSRF KHGFEDCA  2;
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Handless");

            A_Overlay (-5, "Anim.SelectHand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);

            DoSelectOffset ((69, 49), forceNoInterpolate: true);
        }
        TNT1 A 1 DoSelectOffset (( 48,  33));
        TNT1 A 1 DoSelectOffset (( 36,  16));
        TNT1 A 1 DoSelectOffset ((- 4, - 4));
        TNT1 A 1 DoSelectOffset ((-24, -23));
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            DoSelectOffset ((10, 4), forceNoInterpolate: true);
            DoSelectOffset ((0, 0));
        }
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
        LSRF A 0 {
            if (health <= 0) {
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            S7_SetAnim ("Anim.Idle");
            return ResolveState (null);
        }
        TNT1 A 1;
        TNT1 A 1 {
            A_Overlay (-5, "Anim.DeselectHand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);

            S7_SetAnim ("Anim.Handless");
            DoSelectOffset ((-24, -23), forceNoInterpolate: true);
        }
        TNT1 A 1 DoSelectOffset ((-4, -4));
        TNT1 A 1 DoSelectOffset ((36, 16));
        TNT1 A 1 DoSelectOffset ((48, 33));
        TNT1 A 1 DoSelectOffset ((69, 49));
        goto TrueDeselect;

    Fire:
        TNT1 A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            S7_SetAnim ("Anim.Fire");

            A_PlaySound ("Weapons/Fauchard/Fire", CHAN_Weapon);
            A_AlertMonsters ();
            A_GunFlash ();

            S7_A_FireBullets ('S7_FauchardTracer', spread: (.14, .14), offs: (10, 4, 5), bonusDMGFactor: invoker.GetDamageBonus (), flags: S7_FB_UseAmmo);
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 2.5));

            S7_Recoil (-0.3);
            A_ZoomFactor (.9925, ZOOM_Instant);

            return ResolveState (null);
        }
        TNT1 A 1 {
            S7_Recoil (-0.3);
            A_ZoomFactor (.99625);
        }
        TNT1 A 3 {
            S7_Recoil (+0.24);
            A_ZoomFactor (1.);
        }
        TNT1 A 1 {
            A_Refire ();
            A_ClearRefire ();
        }
        goto Ready2;

    Flash:
        LSRF LM 1 bright;
        stop;

    DryFire:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/DryFireLaser", CHAN_7);
        }
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

            S7_SetAnim ("Anim.Reload");

            return ResolveState (null);
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

//-------------------------------------------------------------------------------------------
//
// Fauchard Tracer
//
//-------------------------------------------------------------------------------------------
class S7_FauchardTracer : S7_LaserTracer {
    default {
        DamageFunction ((30. + fRandom [weaponDamage] (-1., 1.)) * (1. + bonusDMGFactor));
        DamageType 'LaserTracer';
        Scale 0.015;
        MissileType 'S7_LaserTracerTrail';
        Decal 'S7_LaserDecal';

        -BLOODSPLATTER
    }

    states {
    Idle:
        LSFL A 1 bright;
        wait;

    Death:
    Crash:
        TNT1 A 3; //A_SpawnItemEx ('S7_LaserPuff')
        stop;
    XDeath:
        TNT1 A 3;
        stop;
    }
}

class S7_LaserTracerTrail : S7_TracerEffectsBase {
    default {
        Scale 0.015;
    }

    states {
    Spawn:
        LSFL A 1 bright;
    Loople:
        #### # 1 bright A_FadeOut (0.2);
        wait;
    }
}