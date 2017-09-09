//-------------------------------------------------------------------------------------------
//
// Plasma Machine Gun Mk III
//
//-------------------------------------------------------------------------------------------
class S7_PlasmaGun_Semi          : S7_Boolean { }
class S7_PlasmaGun_Charge        : S7_Counter { default { inventory.maxAmount 4; } }
class S7_PlasmaGun_ChargingLevel : S7_Counter { default { inventory.maxAmount 53; } }
class S7_PlasmaGunMag            : ammo {
    default {
        inventory.maxAmount 36;
        ammo.backpackMaxAmount 36;

        +inventory.ignoreSkill
    }
}

class S7_PlasmaGun_AltfireLock : S7_Boolean { }

class S7_PlasmaGun : S7_BaseWeapon {
    default {
        tag "$PLASMAGUN";
        inventory.pickupMessage "$PLASMAGUN";
        weapon.ammoType1 "S7_PlasmaGunMag";
        weapon.ammoType2 "S7_Cells";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
    }

    override void DoEffect () {
        super.DoEffect ();

        fireModeIcon = (Owner.CheckInventory ("S7_PlasmaGun_Semi", 1)) ? FMI_SemiAuto : FMI_FullAuto;
    }

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

            GiveInventory ("S7_WeapReady", 1);
            A_WeaponReady ();

            return ResolveState (null);
        }
        TNT1 A 0 TakeInventory ("S7_PlasmaGun_AltfireLock", 0x7FFFFFFF);
        loop;
    Ready2Derp:
        PLSG A 2;
        goto Ready2;

    Deselect:
        PLSG AZYXWV 1;
        goto TrueDeselect;

    Fire:
        PLSG A 1 offset (4, 36) {
            if (CheckInventory ("S7_PlasmaGun_Charge", 1))
                return ResolveState ("Fire.Charged");
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/PlasmaGun/Fire", CHAN_Weapon);
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 3);
            A_FireProjectile ("S7_PlasmaGunRail", fRandom [weaponSpread] (-0.275, 0.275), 1, 6, -4, 0, fRandom [weaponSpread] (-0.275, 0.275));
            A_GunFlash ("Flash.Fire");

            return ResolveState (null);
        }
        PLSG D 1 offset (3, 35);
        PLSG C 1 offset (2, 34);
        PLSG B 1 offset (1, 33);
        PLSG A 1 {
            if (CheckInventory ("S7_PlasmaGun_Semi", 1))
                return ResolveState ("Fire.Semi");

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
            A_WeaponReady (WRF_NoFire | WRF_DisableSwitch);
        }
        TNT1 A 0 A_JumpIfInventory ("S7_AutoReloading", 1, "Reload");
        goto Ready2;
    DryFire.Alt:
        PLSG A 3 A_PlaySound ("Weapons/Misc/Dryfire", CHAN_7);
        goto Ready2;
    Reload:
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_Charge", 1, "Decharge");
        PLSG A 1 TakeInventory ("S7_Reloading", 1);
        goto Ready2;

    Decharge:
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_Charge", 1, 1);
        goto Decharge.End;
        TNT1 A 0 TakeInventory ("S7_PlasmaGun_Charge", 1);
        TNT1 A 0 GiveInventory ("S7_PlasmaGunMag", 5);
        loop;
    Decharge.End:
        PLSG A 5 A_SetBlend ("10 6B DA", 0.25, 4);
        TNT1 A 0 A_JumpIfInventory ("S7_Reloading", 1, 1);
        goto Reload;
        TNT1 A 0 TakeInventory ("S7_Reloading", 1);
        goto Ready2;

    Fire.Charged:
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_Charge", 4, "Fire.ChargeLevel4");
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_Charge", 3, "Fire.ChargeLevel3");
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_Charge", 2, "Fire.ChargeLevel2");
    Fire.ChargeLevel1:
        TNT1 A 0 A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 3);
        TNT1 A 0 A_FireProjectile ("S7_PlasmaGunRailCharge1", 0.0, 1, 6, -4, 0, 0.0);
        goto Fire.Charged.Finish;
    Fire.ChargeLevel2:
        TNT1 A  0 A_SetBlend ("10 6B DA", 0.2333, 8);
        TNT1 AA 0 A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 3);
        TNT1 A  0 A_FireProjectile ("S7_PlasmaGunRailCharge2", 0.0, 1, 6, -4, 0, 0.0);
        goto Fire.Charged.Finish;
    Fire.ChargeLevel3:
        TNT1 A   0 A_SetBlend ("10 6B DA", 0.4666, 8);
        TNT1 AAA 0 A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 3);
        TNT1 A   0 A_FireProjectile ("S7_PlasmaGunRailCharge3", 0.0, 1, 6, -4, 0, 0.0);
        goto Fire.Charged.Finish;
    Fire.ChargeLevel4:
        TNT1 A    0 A_SetBlend ("10 6B DA", 0.7, 8);
        TNT1 AAAA 0 A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 3);
        TNT1 A    0 A_FireProjectile ("S7_PlasmaGunRailCharge4", 0.0, 1, 6, -4, 0, 0.0);
        goto Fire.Charged.Finish;
    Fire.Charged.Finish:
        TNT1 A     0 A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 3);
        TNT1 A     0 TakeInventory ("S7_PlasmaGun_Charge", 0x7FFFFFFF);
        PLSG A     1 offset (8, 40) A_GunFlash ("Flash.Charged");
        PLSG D     1 offset (6, 38);
        PLSG F     1 offset (4, 36);
        PLSG F     1 offset (2, 34);
        PLSG F     6;
        PLSG EDCBA 1;
        goto Ready2;

    Flash.Fire:
        PLSF A 1 bright;
        stop;

    AltFire:
        PLSG A 1 A_JumpIfInventory ("S7_PlasmaGun_AltfireLock", 1, "Ready2");
        PLSG A 2 A_JumpIfInventory ("S7_PlasmaGun_Charge", 4, "Ready2Derp");
        PLSG A 1 A_JumpIfInventory ("S7_PlasmaGunMag", 5, 1);
        goto DryFire.Alt;
        PLSG A 1 A_Refire ("ChargeStart");
        TNT1 A 0 A_ClearRefire;
        goto Ready2Derp;

    ChargeStart:
        TNT1 A 0 A_PlaySound ("Weapons/PlasmaGun/Charge", CHAN_Weapon);
    Charge:
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_ChargingLevel", 0, "ChargingFinished");
        PLSG A 1 GiveInventory ("S7_PlasmaGun_ChargingLevel", 1);
        PLSG A 1 A_Refire ("Charge2");
        PLSG A 1 A_ClearRefire;
        goto CancelCharging;
    Charge2:
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_ChargingLevel", 0, "ChargingFinished");
        PLSG G 1 GiveInventory ("S7_PlasmaGun_ChargingLevel", 1);
        PLSG A 1 A_Refire ("Charge3");
        PLSG A 1 A_ClearRefire;
        goto CancelCharging;
    Charge3:
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_ChargingLevel", 0, "ChargingFinished");
        PLSG I 1 GiveInventory ("S7_PlasmaGun_ChargingLevel", 1);
        PLSG A 1 A_Refire ("Charge4");
        PLSG A 1 A_ClearRefire;
        goto CancelCharging;
    Charge4:
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_ChargingLevel", 0, "ChargingFinished");
        PLSG J 1 GiveInventory ("S7_PlasmaGun_ChargingLevel", 1);
        PLSG A 1 A_Refire ("Charge5");
        PLSG A 1 A_ClearRefire;
        goto CancelCharging;
    Charge5:
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_ChargingLevel", 0, "ChargingFinished");
        PLSG H 1 GiveInventory ("S7_PlasmaGun_ChargingLevel", 1);
        PLSG A 1 A_Refire ("Charge");
        PLSG A 1 A_ClearRefire;
        goto CancelCharging;

    CancelCharging:
        TNT1 A 0 A_StopSound (CHAN_Weapon);
        TNT1 A 0 GiveInventory ("S7_PlasmaGun_AltfireLock", 1);
        PLSG A 1 A_ClearRefire;
        TNT1 A 0 TakeInventory ("S7_PlasmaGun_ChargingLevel", 1);
        TNT1 A 0 A_JumpIfInventory ("S7_PlasmaGun_ChargingLevel", 1, "CancelCharging");
        goto Ready2Derp;
    ChargingFinished:
        TNT1 A     0 A_StopSound (CHAN_Weapon);
        TNT1 A     0 A_JumpIfInventory ("S7_PlasmaGunMag", 5, 1);
        goto DryFire.Alt;
        TNT1 A     0 GiveInventory ("S7_PlasmaGun_AltfireLock", 1);
        TNT1 A     0 A_SetBlend ("10 6B DA", 0.25, 5);
        TNT1 A     0 TakeInventory ("S7_PlasmaGunMag", 5, TIF_NoTakeInfinite);
        TNT1 A     0 TakeInventory ("S7_PlasmaGun_ChargingLevel", 0x7FFFFFFF);
        TNT1 A     0 GiveInventory ("S7_PlasmaGun_Charge", 1);
        TNT1 A     0 A_PlaySound ("Weapons/PlasmaGun/ChargeFinish");
        PLSG AAAAA 1 A_ClearRefire;
        goto Ready2Derp;

    Flash.Charged:
        PLSF B 1 bright offset (8, 40);
        stop;

    ChangeMode:
        PLSG A 1 offset (4, 36) {
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            if (CheckInventory ("S7_PlasmaGun_Semi", 1))
                TakeInventory ("S7_PlasmaGun_Semi", 0x7FFFFFFF);
            else
                GiveInventory ("S7_PlasmaGun_Semi", 1);

            A_PlaySound ("Weapons/ModeChange", CHAN_7);
        }
        PLSG A 1 offset (3, 35);
        PLSG A 1 offset (2, 34);
        PLSG A 1 offset (1, 33);
        PLSG A 1 A_WeaponReady (WRF_NoBob | WRF_NoFire | WRF_DisableSwitch);
        goto Ready2;
    }
}

/** Projectile **/
class S7_PlasmaGunRail : S7_BaseTracer {
    default {
        S7_BaseTracer.trueSpeed 270;
        scale 0.015;
        damageFunction (fRandom [weaponDamage] (1.0, 3.5) * 13);
        missileType "S7_PlasmaGunRailTrail";
        decal "S7_PlasmaGunRail";

        +noDamageThrust
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
        scale 0.015;
    }

    states {
    Spawn:
        PLGF A 1 bright;
        #### # 1 bright A_FadeOut (0.13);
        wait;
    }
}