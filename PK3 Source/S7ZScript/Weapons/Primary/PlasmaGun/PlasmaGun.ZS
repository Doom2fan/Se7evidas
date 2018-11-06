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
        Tag "$PLASMAGUN";
        Inventory.PickupMessage "$PLASMAGUN";

        Weapon.AmmoType1 'S7_PlasmaGunMag';
        Weapon.AmmoType2 'S7_Cells';
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;

        S7_BaseWeapon.Icon "PLSGU0";
        S7_BaseWeapon.ShortTag "$SHORTPLASMAGUN";
        S7_BaseWeapon.BindSlot WpSlot_Heavy;
        S7_BaseWeapon.UsesMag true;
    }

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = (semiAuto ? FMI_SemiAuto : FMI_FullAuto);
    }

    const CHARGE_MAX = 4;
    const CHARGE_COST = 9;
    const MAX_CHARGING_LEVEL = 53;

    int amountUsedToCharge;
    int prevCharge;
    int charge;
    int chargingLevel;
    bool semiAuto;
    bool altfireLock;

    int GetChargeCost () {
        if (!Owner)
            return CHARGE_COST;

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys)
            return CHARGE_COST;

        double ret = CHARGE_COST * (1.0 - (pPawn.xpSys.GetStat (S7Stat_Tech, false) * .01));
        return int (floor (clamp (ret, 4., CHARGE_COST)));
    }

    double GetDamageBonus () {
        if (!Owner)
            return 0.;

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys)
            return 0.;

        return pPawn.xpSys.GetStat (S7Stat_Tech, false) * 0.005;
    }

    states {
    Spawn:
        PLSG U -1;
        stop;

    Ready:
        PLSG VWXYZA 1;
    Ready2:
        PLSG A 1 {
            if (CheckInventory ('S7_Reloading', 1))
                return ResolveState ("Reload");
            if (CheckInventory ('S7_DoMelee', 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ('S7_ChangeFireMode', 1))
                return ResolveState ("ChangeMode");

            A_WeaponReady (((invoker.charge >= CHARGE_MAX) ? WRF_NoSecondary : 0));

            return ResolveState (null);
        }
        TNT1 A 0 { invoker.altfireLock = false; }
        loop;

    Deselect:
        PLSG AZYXWV 1;
        goto TrueDeselect;

    Fire:
        PLSG A 1 {
            if (invoker.charge >= 1)
                return ResolveState ("Fire.Charged");
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/PlasmaGun/Fire", CHAN_Weapon);

            A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 2, 3);
            let proj = S7_PlasmaGunRail (A_FireProjectile ('S7_PlasmaGunRail', fRandom [weaponSpread] (-0.275, 0.275), true, 6, -4, 0, fRandom [weaponSpread] (-0.275, 0.275)));

            if (proj)
                proj.damageBonus = invoker.GetDamageBonus ();

            A_WeaponOffset (4, 36);
            A_GunFlash ("Flash.Fire");

            return ResolveState (null);
        }
        PLSG D 1 A_WeaponOffset (3, 35);
        PLSG C 1 A_WeaponOffset (2, 34);
        PLSG B 1 A_WeaponOffset (1, 33);
        PLSG A 1 {
            if (invoker.semiAuto)
                return ResolveState ("Fire.Semi");

            A_WeaponOffset (0, 32);

            A_Refire ("Fire");

            return ResolveState (null);
        }
        goto Ready2;
    Fire.Semi:
        PLSG A 1 { player.WeaponState |= WF_WeaponReady; }
        goto Ready2;

    DryFire:
        PLSG A 3 {
            A_PlaySound ("Weapons/DryFirePlasma", CHAN_7);
            A_WeaponOffset (0, 32);
        }
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"), "Reload");
        goto Ready2;
    DryFire.Alt:
        PLSG A 3 A_PlaySound ("Weapons/DryFirePlasma", CHAN_7);
        goto Ready2;

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

            return ResolveState ("ReloadFinish");
        }
    ReloadFinish:
        PLSG A     2;
        PLSG ZYXWV 1;
        TNT1 A     6;
        TNT1 A    25 A_PlaySound ("Weapons/PlasmaGun/Out", CHAN_Weapon);
        TNT1 A    25 A_PlaySound ("Weapons/PlasmaGun/In", CHAN_Weapon);
        TNT1 A     8;
        PLSG VWXYZ 1;
        PLSG A     4 A_PlaySound ("Weapons/PlasmaGun/Beep", CHAN_Weapon);
        goto Ready2;

    Decharge:
        PLSG A 5 {
            GiveInventory ('S7_PlasmaGunMag', invoker.amountUsedToCharge);

            invoker.charge = 0;
            invoker.amountUsedToCharge = 0;

            A_SetBlend ("10 6B DA", 0.25, 4);
            TakeInventory ('S7_Reloading', 1);
        }
        goto Ready2;

    Fire.Charged:
        PLSG A     1 {
            if (invoker.charge > 1)
                A_SetBlend ("10 6B DA", 0.175 * invoker.charge, 8);

            double vR = double (invoker.charge) / CHARGE_MAX;
            A_PlaySound ("Weapons/PlasmaGun/Fire", CHAN_Weapon, 1. - (.5 * vR));
            A_PlaySound ("Weapons/PlasmaGun/AltFire", CHAN_5, 0.5 + (.5 * vR));

            let proj = S7_PlasmaGunRail (A_FireProjectile (String.Format ("S7_PlasmaGunRailCharge%d", invoker.charge), 0.0, 0, 6, -4, 0, 0.0));
            if (proj)
                proj.damageBonus = invoker.GetDamageBonus ();

            for (int i = 0; i < (invoker.charge + 1); i++)
                A_FireProjectile ('S7_ShotSmoke_2_Spawner', 0, false, 2, 3);

            A_WeaponOffset (8, 40);
            A_GunFlash ("Flash.Charged");

            invoker.prevCharge = invoker.charge;
            invoker.charge = 0;
            invoker.amountUsedToCharge = 0;
        }
        PLSG D     1 A_WeaponOffset (6, 38);
        PLSG F     1 A_WeaponOffset (4, 36);
        PLSG F     1 A_WeaponOffset (2, 34);
        PLSG F     6 {
            A_WeaponOffset (0, 32);

            int tics = 6 + int (max (0, invoker.prevCharge - 1) * 1.5);
            {
                let pPawn = S7_BasePlayer (self);

                if (pPawn && pPawn.xpSys)
                    tics = int (double (tics) * clamp (pPawn.xpSys.GetStat (S7Stat_Tech, false) * 0.06, .5, 1.));
            }

            invoker.prevCharge = 0;

            A_SetTics (tics);
        }
        PLSG EDCBA 1;
        goto Ready2;

    Flash.Fire:
        PLSF A 1 bright;
        stop;

    AltFire:
        PLSG A 1 {
            if (invoker.charge >= CHARGE_MAX)
                return ResolveState ("Ready2");
            else if (!CheckInventory ('S7_PlasmaGunMag', invoker.GetChargeCost ()))
                return ResolveState ("DryFire.Alt");

            return ResolveState (null);
        }
        PLSG A 1 A_Refire ("ChargeStart");
        TNT1 A 0 A_ClearRefire;
        goto Ready2;

    ChargeStart:
        TNT1 A 0 A_PlaySound ("Weapons/PlasmaGun/Charge", CHAN_Weapon);
    Charge:
        PLSG A 1 {
            if (invoker.chargingLevel >= MAX_CHARGING_LEVEL)
                return ResolveState ("ChargingFinished");

            A_WeaponOffset (0 + fRandom [weaponSpc] (-1, 1), 32 + fRandom [weaponSpc] (-1, 1));
            invoker.chargingLevel++;

            return ResolveState (null);
        }
        PLSG A 1 A_Refire ("Charge");
        PLSG A 1 A_ClearRefire;
        goto CancelCharging;

    CancelCharging:
        PLSG A 1 {
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
        PLSG A 5 {
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

    Flash.Charged:
        PLSF B 1 bright A_WeaponOffset (8, 40);
        stop;

    ChangeMode:
        PLSG A 1 {
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

            invoker.semiAuto = !invoker.semiAuto;

            A_PlaySound ("Weapons/ModeChange", CHAN_7);

            A_WeaponOffset (4, 36);
        }
        PLSG A 1 A_WeaponOffset (3, 35);
        PLSG A 1 A_WeaponOffset (2, 34);
        PLSG A 1 A_WeaponOffset (1, 33);
        PLSG A 1 A_WeaponOffset (0, 32);
        goto Ready2;
    }
}

/** Projectile **/
class S7_PlasmaGunRail : S7_BaseTracer {
    double damageBonus;

    default {
        S7_BaseTracer.TrueSpeed 270;
        Scale 0.015;
        DamageFunction ((fRandom [weaponDamage] (1.0, 2.0) * 22.75) * (1+damageBonus));
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