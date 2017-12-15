//-------------------------------------------------------------------------------------------
//
// FS/002A Mod 4 "Fauchard" Automatic Rifle
//
//-------------------------------------------------------------------------------------------
class S7_FauchardMag : ammo {
    default {
        inventory.maxAmount 23;
        ammo.backpackMaxAmount 23;

        +inventory.ignoreSkill
    }
}

class S7_Fauchard : S7_BaseWeapon {
    default {
        tag "$FAUCHARD";
        inventory.pickupMessage "$FAUCHARD";
        weapon.ammoType1 "S7_FauchardMag";
        weapon.ammoType2 "S7_FBSysCells";
        weapon.ammoUse 1;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "LRFPA0";
    }

    bool halfTic;

    states {
    Spawn:
        LRFP A -1;
        stop;

    Ready:
        LSRF VWXYZA 1;
    Ready2:
        LSRF A 1 {
            if (CheckInventory ("S7_Reloading", 1))
                return ResolveState ("Reload");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Deselect:
        LSRF AZYXWV 1;
        goto TrueDeselect;

    Fire:
        LSRF A 1 {
            if (!invoker.CheckAmmo (PrimaryFire, false, true))
                return ResolveState ("DryFire");

            A_PlaySound ("Weapons/Fauchard/Fire", (invoker.halfTic ? CHAN_5 : CHAN_Weapon));
            A_AlertMonsters ();
            A_GunFlash ();
            A_FireProjectile ("S7_ShotSmoke_2_Spawner", 0, 0, 2, 4);
            A_FireProjectile ("S7_FauchardTracer", fRandom [weaponSpread] (-0.14, 0.14), 1, 6, -3, 0, fRandom [weaponSpread] (-0.14, 0.14));
            A_SetPitch (pitch - 0.3, SPF_Interpolate);

            return ResolveState (null);
        }
        LSRF B 1 A_SetPitch (pitch - 0.3, SPF_Interpolate);
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
        LSRF A 3 A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
        TNT1 A 0 A_JumpIf (S7_PlayerCVar.GetInt (player, "S7_AutoReloading"), "Reload");
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
class S7_FauchardTracer : S7_BaseTracer {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 4.0) * 12);
        S7_BaseTracer.trueSpeed 300;
        damageType "LaserTracer";
        scale 0.015;
        missileType "S7_LaserTracerTrail";
        decal "S7_LaserDecal";

        -bloodSplatter
    }

    states {
    Idle:
        LSFL A 1 bright;
        wait;

    Death:
    Crash:
        TNT1 A 3; //A_SpawnItemEx ("S7_LaserPuff")
        stop;
    XDeath:
        TNT1 A 3;
        stop;
    }
}

class S7_LaserTracerTrail : S7_TracerEffectsBase {
    default {
        scale 0.015;
    }

    states {
    Spawn:
        LSFL A 1 bright;
    Loople:
        #### # 1 bright A_FadeOut (0.2);
        wait;
    }
}