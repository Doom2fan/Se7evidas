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
        S7_BaseWeapon.BindSlot WpSlot_Medium;
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

    bool halfTic;

    states {
    Spawn:
        LRFP A -1;
        stop;

    Select.Hand:
        TNT1 A 1;
        HAN0 A 1 DoSelectOffset (( 98, 156), -5, true);
        HAN0 A 1 DoSelectOffset ((110, 137), -5);
        HAN0 A 1 DoSelectOffset ((120, 122), -5);
        HAN0 A 1 DoSelectOffset ((134, 106), -5);
        stop;
    Ready:
        LSRF H 1 {
            DoSelectOffset ((69, 49), forceNoInterpolate: true);
            A_Overlay (-5, "Select.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        LSRF H 1 DoSelectOffset (( 48,  33));
        LSRF H 1 DoSelectOffset (( 36,  16));
        LSRF H 1 DoSelectOffset ((-4 , -4 ));
        LSRF H 1 DoSelectOffset ((-24, -23));
        LSRF A 1 {
            DoSelectOffset ((10, 4), forceNoInterpolate: true);
            DoSelectOffset ((0, 0));
        }
    Ready2:
        LSRF A 1 S7_WeaponReady ("Reload", null);
        loop;

    Deselect.Hand:
        HAN0 A 1 DoSelectOffset ((134, 106), -5, true);
        HAN0 A 1 DoSelectOffset ((120, 122), -5);
        HAN0 A 1 DoSelectOffset ((110, 137), -5);
        HAN0 A 1 DoSelectOffset (( 98, 156), -5);
        stop;
    Deselect:
        LSRF A 1 A_JumpIf (health <= 0, "Deselect.DEAD");
        LSRF H 1 {
            DoSelectOffset ((-24, -23), forceNoInterpolate: true);
            A_Overlay (-5, "Deselect.Hand");
            A_OverlayFlags (-5, PSPF_AddWeapon, false);
        }
        LSRF H 1 DoSelectOffset ((-4 , -4 ));
        LSRF H 1 DoSelectOffset (( 36,  16));
        LSRF H 1 DoSelectOffset (( 48,  33));
        LSRF H 1 DoSelectOffset (( 69,  49));
        goto TrueDeselect;

    Fire:
        LSRF A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/Fauchard/Fire", (invoker.halfTic ? CHAN_5 : CHAN_Weapon));
            A_AlertMonsters ();
            A_GunFlash ();

            S7_A_FireBullets ('S7_FauchardTracer', spread: (.14, .14), offs: (10, 4, 5), bonusDMGFactor: invoker.GetDamageBonus (), flags: S7_FB_UseAmmo);
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 2.5));

            S7_Recoil (-0.3);

            return ResolveState (null);
        }
        LSRF B 1 S7_Recoil (-0.3);
        LSRF A 1;
        LSRF A 1 {
            if (invoker.halfTic) {
                invoker.halfTic = false;
                return ResolveState ("Fire.End");
            }

            invoker.halfTic = true;
            return ResolveState (null);
        }
    Fire.End:
        LSRF A 1 {
            A_Refire ();
            A_ClearRefire ();
        }
        goto Ready2;

    Flash:
        LSRF LM 1 bright;
        stop;

    DryFire:
        LSRF A 3 A_PlaySound ("Weapons/DryFireLaser", CHAN_7);
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
        LSRF ACDEFGH   2;
        LSRF I         2 A_PlaySound ("Weapons/Fauchard/Out", CHAN_6);
        LSRF J        30;
        LSRF J        12 A_PlaySound ("Weapons/Fauchard/In", CHAN_7);
        LSRF KHGFEDCA  2;
        goto Ready2;
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
        Speed 300;
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