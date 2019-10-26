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
// Plasma Machine Gun Mk III
//
//-------------------------------------------------------------------------------------------
class S7_PlasmaGunMag : Ammo {
    default {
        Inventory.MaxAmount 36;
        Ammo.BackpackMaxAmount 36;

        +INVENTORY.IGNORESKILL
    }
}

class S7_PlasmaGun : S7_BaseWeapon {
    default {
        //$Category "Se7evidas/Weapons"
        //$Color 14
        //$Title "Prototype Plasma Machinegun"
        //$NotAngled

        Tag "$PLASMAGUN";
        Inventory.PickupMessage "$PLASMAGUN";
        Inventory.PickupSound "Weapons/Pickup/Medium";

        Weapon.AmmoType1 'S7_PlasmaGunMag';
        Weapon.AmmoType2 'S7_Cells';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "PLSGU0";
        S7_BaseWeapon.ShortTag "$SHORTPLASMAGUN";
        S7_BaseWeapon.AmmoBuyData "ACEL", 1;
        S7_BaseWeapon.BindSlot S7_WpSlot_Heavy;
        S7_BaseWeapon.UsesMag true;
        S7_BaseWeapon.EnchantmentProperties false, 0.;
    }

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = (semiAuto ? S7_FMI_SemiAuto : S7_FMI_FullAuto);
    }

    const Charge_Max = 4;
    const Charge_Cost = 9;
    const Max_Charging_Level = 53;

    int amountUsedToCharge;
    int prevCharge;
    int charge;
    int chargingLevel;
    bool semiAuto;
    bool altfireLock;

    override double S7_WeightSpeedModifier (double strengthStat, double berserkCount) {
        return clamp (.85 + clamp (.175 * log (strengthStat / 3.875), 0., 1.) + (.0565 * berserkCount), 0., 1.);
    }

    int GetChargeCost () {
        if (!Owner)
            return Charge_Cost;

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys)
            return Charge_Cost;

        double ret = Charge_Cost * (1.0 - (pPawn.xpSys.GetStat (S7Stat_Tech, false) * .01));
        return int (floor (clamp (ret, 4., Charge_Cost)));
    }

    double GetDamageBonus () {
        if (!Owner)
            return 0.;

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys)
            return 0.;

        return pPawn.xpSys.GetStat (S7Stat_Tech, false) * 0.005;
    }

    action double GetRecoilZoomFactor (int chargeLevel, int stepCount, int whichStep) {
        double baseFactor;

        baseFactor = (1. - .99125);
        baseFactor = baseFactor * 1.5 * max (.5 + .5 * chargeLevel, 1.);
        baseFactor = 1. - baseFactor;

        return S7_Math.Lerp (baseFactor, 1., 1. / stepCount * whichStep);
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        PLSG U -1;
        stop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        PLSG A 1;
        wait;
    Anim.Fire:
        PLSG A 1 bright;
        PLSG DCB 1;
        goto Anim.Idle;
    Anim.FireCharged:
        PLSG A 1 bright;
        PLSG D 1;
        PLSG F 1;
        wait;
    Anim.FireChargedEnd:
        PLSG EDCBA 1;
        goto Anim.Idle;
    Anim.Reload:
        PLSG A  2 DoSelectOffset (( 0,  0), forceNoInterpolate: true);
        PLSG A  1 DoSelectOffset ((24, 24));
        PLSG A  1 DoSelectOffset ((38, 37));
        PLSG A  1 DoSelectOffset ((48, 48));
        PLSG A  1 DoSelectOffset ((60, 58));
        PLSG A  1 DoSelectOffset ((72, 72));
        TNT1 A  6;
        TNT1 A 25 A_PlaySound ("Weapons/PlasmaGun/Out", CHAN_Weapon);
        TNT1 A 25 A_PlaySound ("Weapons/PlasmaGun/In", CHAN_Weapon);
        TNT1 A  8;
        PLSG A  1 DoSelectOffset ((72, 72), forceNoInterpolate: true);
        PLSG A  1 DoSelectOffset ((60, 58));
        PLSG A  1 DoSelectOffset ((48, 48));
        PLSG A  1 DoSelectOffset ((38, 37));
        PLSG A  1 DoSelectOffset ((24, 24));
        PLSG A  4 {
            DoSelectOffset (( 0,  0));
            A_PlaySound ("Weapons/PlasmaGun/Beep", CHAN_Weapon);
        }
        goto Anim.Idle;
    }

    /** Actions **/
    states {
    Ready:
        TNT1 A 0 S7_SetAnim ("Anim.Idle");
        TNT1 A 1 DoSelectOffset ((72, 72), forceNoInterpolate: true);
        TNT1 A 1 DoSelectOffset ((60, 58));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((38, 37));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset (( 0,  0));
    Ready2:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");
            S7_WeaponReady ("Reload", "ChangeMode", "QuickMeleeDerp", wrFlags: ((invoker.charge >= Charge_Max) ? WRF_NoSecondary : 0));
        }
        TNT1 A 0 { invoker.altfireLock = false; }
        loop;
    QuickMeleeDerp:
        TNT1 A 0 S7_SetAnim ("Null");
        goto QuickMelee;

    Deselect:
        PLSG A 0 {
            if (health <= 0) {
                S7_SetAnim ("Null");
                return ResolveState ("Deselect.DEAD");
            }

            S7_SetAnim ("Anim.Idle");
            return ResolveState (null);
        }
        TNT1 A 1 DoSelectOffset (( 0,  0));
        TNT1 A 1 DoSelectOffset ((24, 24));
        TNT1 A 1 DoSelectOffset ((38, 37));
        TNT1 A 1 DoSelectOffset ((48, 48));
        TNT1 A 1 DoSelectOffset ((60, 58));
        TNT1 A 1 DoSelectOffset ((72, 72));
        goto TrueDeselect;

    // Firing
    Fire:
        TNT1 A 1 {
            if (invoker.charge >= 1)
                return ResolveState ("Fire.Charged");
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            S7_SetAnim ("Anim.Fire");

            A_PlaySound ("Weapons/PlasmaGun/Fire", CHAN_Weapon);

            S7_A_FireBullets ('S7_PlasmaGunRail', spread: (.275, .275), offs: (10, 5, 8), bonusDMGFactor: invoker.GetDamageBonus (), flags: S7_FB_UseAmmo);
            S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 3));
            A_GunFlash ();

            A_ZoomFactor (.99125, ZOOM_Instant);
            S7_Recoil (-.8);
            A_WeaponOffset (4, 36);

            return ResolveState (null);
        }
        TNT1 A 1 {
            A_ZoomFactor (.995625);
            S7_Recoil (-.675);
            A_WeaponOffset (3, 35);
        }
        TNT1 A 1 {
            A_ZoomFactor (1.);
            S7_Recoil (+.6);
            A_WeaponOffset (2, 34);
        }
        TNT1 A 1 A_WeaponOffset (1, 33);
        TNT1 A 1 {
            A_WeaponOffset (0, 32);

            if (invoker.semiAuto)
                player.WeaponState |= WF_WeaponReady;
            else
                A_Refire ("Fire");
        }
        goto Ready2;

    Fire.Charged:
        TNT1 A 1 {
            S7_SetAnim ("Anim.FireCharged");

            if (invoker.charge > 1)
                A_SetBlend ("10 6B DA", 0.175 * invoker.charge, 8);

            double vR = double (invoker.charge) / Charge_Max;
            A_PlaySound ("Weapons/PlasmaGun/Fire", CHAN_Weapon, 1. - (.5 * vR));
            A_PlaySound ("Weapons/PlasmaGun/AltFire", CHAN_5, 0.5 + (.5 * vR));

            A_GunFlash ("Flash.Charged");
            S7_A_FireBullets (String.Format ("S7_PlasmaGunRailCharge%d", invoker.charge), offs: (10, 5, 8), bonusDMGFactor: invoker.GetDamageBonus ());
            for (int i = 0; i < (invoker.charge + 1); i++)
                S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 2, 3));

            A_ZoomFactor (GetRecoilZoomFactor (invoker.charge, 2, 0), ZOOM_Instant);
            S7_Recoil (-.8 * (1.5 * max (.5 + .5 * invoker.charge, 1.)));
            A_WeaponOffset (8, 40);

            invoker.prevCharge = invoker.charge;
            invoker.charge = 0;
            invoker.amountUsedToCharge = 0;
        }
        TNT1 A 1 {
            A_ZoomFactor (GetRecoilZoomFactor (invoker.charge, 2, 1));
            S7_Recoil (-.675 * (1.5 * max (.5 + .5 * invoker.charge, 1.)));
            A_WeaponOffset (6, 38);
        }
        TNT1 A 1 {
            A_ZoomFactor (GetRecoilZoomFactor (invoker.charge, 2, 2));
            S7_Recoil (+.6 * (1.5 * max (.5 + .5 * invoker.charge, 1.)));
            A_WeaponOffset (4, 36);
        }
        TNT1 A 1 A_WeaponOffset (2, 34);
        TNT1 A 6 {
            A_WeaponOffset (0, 32);

            int tics = int (6 * (1 + max (0., invoker.prevCharge - 1.) * 0.5));
            {
                let pPawn = S7_BasePlayer (self);

                if (pPawn && pPawn.xpSys)
                    tics = int (double (tics) * clamp (1. - pPawn.xpSys.GetStat (S7Stat_Tech, false) * 0.06, .5, 1.));
            }

            invoker.prevCharge = 0;

            A_SetTics (tics);
        }
        TNT1 A 5 S7_SetAnim ("Anim.FireChargedEnd");
        goto Ready2;

    // Charging
    AltFire:
        TNT1 A 1 {
            if (invoker.charge >= Charge_Max)
                return ResolveState ("Ready2");
            else if (!CheckInventory ('S7_PlasmaGunMag', invoker.GetChargeCost ()))
                return ResolveState ("DryFire.Alt");

            S7_SetAnim ("Anim.Idle");

            return ResolveState (null);
        }
        TNT1 A 1 A_Refire ("ChargeStart");
        TNT1 A 0 A_ClearRefire;
        goto Ready2;

    ChargeStart:
        TNT1 A 0 A_PlaySound ("Weapons/PlasmaGun/Charge", CHAN_Weapon);
    Charge:
        TNT1 A 1 {
            if (invoker.chargingLevel >= Max_Charging_Level)
                return ResolveState ("ChargingFinished");

            S7_SetAnim ("Anim.Idle");

            A_WeaponOffset (0 + fRandom [weaponSpc] (-1, 1), 32 + fRandom [weaponSpc] (-1, 1));
            invoker.chargingLevel++;

            return ResolveState (null);
        }
        TNT1 A 1 A_Refire ("Charge");
        TNT1 A 1 A_ClearRefire;
        goto CancelCharging;

    CancelCharging:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");

            A_StopSound (CHAN_Weapon);
            A_WeaponOffset (0, 32);

            invoker.altfireLock = true;
            A_ClearRefire ();

            if (invoker.chargingLevel <= 0) {
                invoker.chargingLevel = 0; // Just to make sure.
                return ResolveState ("Ready2");
            }

            invoker.chargingLevel -= random [weaponSpc] (2, 3);

            return ResolveState (null);
        }
        loop;

    ChargingFinished:
        TNT1 A 5 {
            S7_SetAnim ("Anim.Idle");

            A_StopSound (CHAN_Weapon);
            A_WeaponOffset (0, 32);

            if (!CheckInventory ('S7_PlasmaGunMag', invoker.GetChargeCost ()))
                return ResolveState ("DryFire.Alt");

            A_PlaySound ("Weapons/PlasmaGun/ChargeFinish");
            A_SetBlend ("10 6B DA", 0.25, 5);

            invoker.altfireLock = true;

            int chargeCost = invoker.GetChargeCost ();

            TakeInventory ('S7_PlasmaGunMag', chargeCost, TIF_NoTakeInfinite);
            invoker.amountUsedToCharge += chargeCost;
            invoker.charge++;
            invoker.chargingLevel = 0;

            A_ClearRefire ();

            return ResolveState (null);
        }
        goto Ready2;

    // Changing firing mode
    ChangeMode:
        TNT1 A 1 {
            S7_SetAnim ("Anim.Idle");

            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            invoker.semiAuto = !invoker.semiAuto;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            A_WeaponOffset (4, 36);
        }
        TNT1 A 1 A_WeaponOffset (3, 35);
        TNT1 A 1 A_WeaponOffset (2, 34);
        TNT1 A 1 A_WeaponOffset (1, 33);
        TNT1 A 1 A_WeaponOffset (0, 32);
        goto Ready2;

    // Flashes
    Flash:
        PLSF A 1 bright;
        stop;
    Flash.Charged:
        PLSF B 1 bright;
        stop;

    // Dryfires
    DryFire:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/DryFirePlasma", CHAN_7);

            A_WeaponOffset (0, 32);
            A_ClearRefire ();
        }
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading") && invoker.CanReload (), "Reload");
        goto Ready2;
    DryFire.Alt:
        TNT1 A 3 {
            S7_SetAnim ("Anim.Idle");
            A_PlaySound ("Weapons/DryFirePlasma", CHAN_7);

            A_ClearRefire ();
        }
        goto Ready2;

    // Reloading
    Reload:
        TNT1 A 0 {
            TakeInventory ('S7_Reloading', 1);

            if (invoker.charge > 0)
                return ResolveState ("Decharge");

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

    Decharge:
        TNT1 A 5 {
            S7_SetAnim ("Anim.Idle");

            GiveInventory ('S7_PlasmaGunMag', invoker.amountUsedToCharge);

            invoker.charge = 0;
            invoker.amountUsedToCharge = 0;

            A_SetBlend ("10 6B DA", 0.25, 4);
            TakeInventory ('S7_Reloading', 1);
        }
        goto Ready2;
    }
}

/** Projectile **/
class S7_PlasmaGunRail : S7_BaseTracer {
    double damageBonus;

    default {
        DamageFunction ((34.125 + fRandom [weaponDamage] (-1., 1.)) * (1. + bonusDMGFactor));
        Speed 270;
        Scale 0.015;
        MissileType 'S7_PlasmaGunRailTrail';
        Decal 'S7_PlasmaGunRail';

        +NODAMAGETHRUST
    }

    states {
    Idle:
        PLGF A 1 bright;
        wait;

    Death:
        HTS0 A       1 A_SetScale (default.scale.X * 10);
        HTS0 BCDEFGH 1;
        stop;
    }
}

/** Trails **/
class S7_PlasmaGunRailTrail : S7_TracerEffectsBase {
    default {
        Scale 0.015;
    }

    states {
    Spawn:
        PLGF A 1 bright;
        #### # 1 bright A_FadeOut (0.13);
        wait;
    }
}