//-------------------------------------------------------------------------------------------
//
// Grenade
//
//-------------------------------------------------------------------------------------------
class S7_GrenadeCount : ammo {
    default {
        inventory.maxAmount 15;
        ammo.backpackMaxAmount 15;

        +inventory.ignoreSkill
    }
}

class S7_GrenadeForce : S7_Counter { default { inventory.maxAmount 30; } }
class S7_GrenadeWeap : S7_BaseWeapon {
    default {
        tag "$GRENADEWEAP";
        weapon.ammoType "S7_GrenadeCount";
        weapon.ammoUse 0;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "TGRNZ0";
        S7_BaseWeapon.ShortTag "$GRENADEWEAP";
        S7_BaseWeapon.BindSlot WpSlot_Special;
    }

    states {
    Ready:
    Ready2:
        TNT1 A 1 {
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Deselect:
        goto TrueDeselect;

    Fire:
        TNT1 A      0 A_JumpIfInventory ("S7_GrenadeCount", 1, 1);
        goto Ready2;
        TGRN WXY    1;
        TGRN ABCDEF 1;
        TGRN G      1 A_PlaySound ("Weapons/GrenadePinPull", CHAN_Weapon);
        TGRN HIJKLM 1;
        TNT1 A      1;
    Hold:
        TNT1 A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("CancelThrow");

            GiveInventory ("S7_GrenadeForce", 1);
            return ResolveState (null);
        }
        TNT1 A 1 A_Refire ("Hold");
        TNT1 A 8 {
            TakeInventory ("S7_GrenadeCount", 1, TIF_NoTakeInfinite);
            A_SpawnItemEx ("S7_ThrownHandGrenade", 0, 0, height - 12,
                                Cos (pitch) * Cos (angle) * 4 + vel.X, Cos (pitch) * Sin (angle) * 4 + vel.Y, -Sin (pitch) * 4 + vel.Z, 0, SXF_AbsoluteMomentum | SXF_NoCheckPosition | SXF_TransferPitch);
        }
        TNT1 A 0 A_ClearRefire;
        goto Ready2;

    CancelThrow:
        TNT1 A      1 {
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_GrenadeForce", 0x7FFFFFFF);
            A_ClearRefire ();
        }
        TGRN MLKJIH 1;
        TGRN G      1 A_PlaySound ("Weapons/GrenadePinPull", CHAN_Weapon);
        TGRN FEDCBA 1;
        TGRN YXW    1;
        goto Ready2;
    }
}

//-------------------------------------------------------------------------------------------
//
// Thrown grenade
//
//-------------------------------------------------------------------------------------------
class S7_ThrownHandGrenade : actor {
    default {
        radius 5;
        height 5;
        speed 5;
        mass 30;
        damageFunction (0);
        bounceType "Doom";
        pushFactor 3;
        wallBounceFactor 0.1;
        bounceFactor 0.1;
        scale 0.3;

        projectile;
        +canBounceWater +noExplodeFloor +activateMCross +forceXYBillboard
        +skyExplode +noBlood +useBounceState
        -noTeleport -noGravity -floorClip
    }

    float fuse;
    int frame;

    states {
    Spawn:
        TNT1 A 0 noDelay {
            fuse = 35 * 3.5;
            int grenadeForce = target.CountInv ("S7_GrenadeForce");
            A_ChangeVelocity (Cos (pitch) * grenadeForce, 0, -Sin (pitch) * grenadeForce, CVF_Relative);
            A_TakeFromTarget ("S7_GrenadeForce", 0x7FFFFFFF);
        }
        goto Flight;
    Flight:
        TNT1 A 0 {
            switch (frame) {
                case 7: return ResolveState ("FlightH"); break;
                case 6: return ResolveState ("FlightG"); break;
                case 5: return ResolveState ("FlightF"); break;
                case 4: return ResolveState ("FlightE"); break;
                case 3: return ResolveState ("FlightD"); break;
                case 2: return ResolveState ("FlightC"); break;
                case 1: return ResolveState ("FlightB"); break;
            }
            return ResolveState ("FlightA");
        }

    FlightA: TGRP A 0; goto Flight2;
    FlightB: TGRP B 0; goto Flight2;
    FlightC: TGRP C 0; goto Flight2;
    FlightD: TGRP D 0; goto Flight2;
    FlightE: TGRP E 0; goto Flight2;
    FlightF: TGRP F 0; goto Flight2;
    FlightG: TGRP G 0; goto Flight2;
    FlightH: TGRP H 0 { frame = 0; } goto Flight2;

    Flight2:
        #### # 2 {
            if (fuse <= 0)
                return ResolveState ("Death_BurnFuse");

            fuse -= 2;

            return ResolveState (null);
        }
        #### # 0 {
            frame++;
            if ((Abs (vel.x) + Abs (vel.y)) < 1)
                return ResolveState ("Death_BurnFuse");

            return ResolveState (null);
        }
        goto Flight;

    Bounce:
    Death:
        #### # 0 {
            A_ChangeLinkFlags (false);
            bmissile = false;
            bpushable = true;
            bsolid = true;

            if (pos.z - floorZ > 1)
                return ResolveState ("Flight2");

            A_ChangeVelocity (vel.x * 5, vel.y * 5, vel.z, CVF_Replace);

            return ResolveState (null);
        }
        goto Flight2;

    Death_BurnFuse:
        #### # 1 {
            if (fuse <= 0)
                return ResolveState ("KABOOM");

            fuse--;

            return ResolveState (null);
        }
        loop;
    KABOOM:
        TNT1 A 0 {
            A_Stop ();
            bsolid = false;
            bpushable = false;
            A_ChangeLinkFlags (true);
            bmissile = true;
            scale.x = 1.0; scale.y = 1.0;
            S7_ActorExtensions.A_S7SpawnShrapnel (self, 100, 0.0, 0.0, 2.0, SXF_TransferPointers);
            A_PlaySound ("Explosions/Explosion1");
        }
        goto KABOOM.Anim;
    KABOOM.Anim:
        XPL1 A    3 bright {
            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (fRandom [weaponDamage] (192.0, 256.0), fRandom [weaponSpread] (192.0, 256.0));
        }
        XPL1 BCDE 3 bright;
        stop;
    }
}