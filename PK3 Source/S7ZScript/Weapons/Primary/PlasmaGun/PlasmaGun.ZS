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

class S7_PlasmaGun_AltfireLock : S7_Boolean { }

class S7_PlasmaGun : S7_BaseWeapon {
    default {
        Tag "$PLASMAGUN";
        Inventory.PickupMessage "$PLASMAGUN";
        Weapon.AmmoType1 "S7_PlasmaGunMag";
        Weapon.AmmoType2 "S7_Cells";
        Weapon.AmmoUse 1;
        Weapon.AmmoGive 0;
        S7_BaseWeapon.Icon "PLSGU0";
        S7_BaseWeapon.ShortTag "$SHORTPLASMAGUN";
        S7_BaseWeapon.BindSlot WpSlot_Heavy;
    }

    override void DoEffect () {
        Super.DoEffect ();

        fireModeIcon = (semiAuto ? FMI_SemiAuto : FMI_FullAuto);
    }

    const CHARGE_MAX = 4;
    const CHARGE_COST = 5;
    const MAX_CHARGING_LEVEL = 53;
    int charge;
    int chargingLevel;
    bool semiAuto;

    states {
    Spawn:
        PLSG U -1;
        stop;

    Ready:
        PLSG VWXYZA 1;
    Ready2:
        PLSG A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            if (CheckInventory ("S7_ChangeFireMode", 1))
                return ResolveState ("ChangeMode");

            A_WeaponReady (/*((invoker.charge >= CHARGE_MAX) ? WRF_NoSecondary : 0)*/);

            return ResolveState (null);
        }
        TNT1 A 0 TakeInventory ("S7_PlasmaGun_AltfireLock", 0x7FFFFFFF);
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

            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 3);
            A_FireProjectile ("S7_PlasmaGunRail", fRandom [weaponSpread] (-0.275, 0.275), 1, 6, -4, 0, fRandom [weaponSpread] (-0.275, 0.275));

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
        PLSG A 1 A_WeaponReady (WRF_NoBob | WRF_NoSecondary | WRF_DisableSwitch);
        goto Ready2;

    DryFire:
        PLSG A 3 {
            A_PlaySound ("Weapons/Misc/Dryfire", CHAN_7);
            A_WeaponOffset (0, 32);
        }
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"), "Reload");
        goto Ready2;
    DryFire.Alt:
        PLSG A 3 A_PlaySound ("Weapons/Misc/Dryfire", CHAN_7);
        goto Ready2;

    Reload:
        TNT1 A 0 {
            TakeInventory ("S7_Reloading", 1);

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
            GiveInventory ("S7_PlasmaGunMag", CHARGE_COST * invoker.charge);
            invoker.charge = 0;

            A_SetBlend ("10 6B DA", 0.25, 4);
            TakeInventory ("S7_Reloading", 1);
        }
        goto Ready2;

    Fire.Charged:
        PLSG A     1 {
            if (invoker.charge > 1)
                A_SetBlend ("10 6B DA", 0.175 * invoker.charge, 8);

            A_FireProjectile (String.Format ("S7_PlasmaGunRailCharge%d", invoker.charge), 0.0, 1, 6, -4, 0, 0.0);

            for (int i = 0; i < (invoker.charge + 1); i++)
                A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 3);

            A_WeaponOffset (8, 40);
            A_GunFlash ("Flash.Charged");

            invoker.charge = 0;
        }
        PLSG D     1 A_WeaponOffset (6, 38);
        PLSG F     1 A_WeaponOffset (4, 36);
        PLSG F     1 A_WeaponOffset (2, 34);
        PLSG F     6 A_WeaponOffset (0, 32);
        PLSG EDCBA 1;
        goto Ready2;

    Flash.Fire:
        PLSF A 1 bright;
        stop;

    AltFire:
        PLSG A 1 {
            if (invoker.charge >= CHARGE_MAX)
                return ResolveState ("Ready2");
            else if (!CheckInventory ("S7_PlasmaGunMag", CHARGE_COST))
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

            GiveInventory ("S7_PlasmaGun_AltfireLock", 1);
            A_ClearRefire ();

            invoker.chargingLevel--;
        }
        TNT1 A 0 A_JumpIf (invoker.chargingLevel > 0, "CancelCharging");
        goto Ready2;

    ChargingFinished:
        PLSG A 5 {
            A_StopSound (CHAN_Weapon);
            A_WeaponOffset (0, 32);

            if (!CheckInventory ("S7_PlasmaGunMag", CHARGE_COST))
                return ResolveState ("DryFire.Alt");

            A_PlaySound ("Weapons/PlasmaGun/ChargeFinish");
            A_SetBlend ("10 6B DA", 0.25, 5);

            GiveInventory ("S7_PlasmaGun_AltfireLock", 1);

            TakeInventory ("S7_PlasmaGunMag", CHARGE_COST, TIF_NoTakeInfinite);
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
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

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
    default {
        S7_BaseTracer.TrueSpeed 270;
        Scale 0.015;
        DamageFunction (fRandom [weaponDamage] (1.0, 3.5) * 13);
        MissileType "S7_PlasmaGunRailTrail";
        Decal "S7_PlasmaGunRail";

        +NODAMAGETHRUST
    }

    states {
    Idle:
        PLGF A 1 bright;
        wait;

    Death:
        HTS0 A       1 A_SetScale (scale.X * 10);
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