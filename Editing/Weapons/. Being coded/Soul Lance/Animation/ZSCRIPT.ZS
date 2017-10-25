class S7_SLance_BeamHeld_Fire : S7_Boolean { }
class S7_SoulLance : S7_BaseWeapon {
    default {
        weapon.AmmoUse 0;
        weapon.AmmoGive 0;
        weapon.SlotNumber 0;

        -weapon.noAlert
    }

    states {
    Ready:
        SLNC ABCD     1;
        SLNC E        5;
        SLNC FGHIJKLM 1;
    Ready2:
        SLNC M 1 {
            if (CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
                return ResolveState ("Fire.Grabbed");
            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;
    Fire:
        SLNC NOPQRS 1;
        SLNC TU     2;
        TNT1 A      0 A_JumpIfInventory ("S7_SoulLance_BeamGrabbed", 1, "Hold.Grabbed");
    Hold:
        SLNC V       2 {
            A_FireProjectile ("S7_SoulLance_Mutilator", 0, 0, 0, 0);
            A_FireProjectile ("S7_SoulLance_Beam", 0.0, 0, 5, 0, 0, 0.0);
        }
        SLNC W       2;
        SLNC X       2 A_FireProjectile ("S7_SoulLance_Beam", 0.0, 0, 5, 0, 0, 0.0);
        SLNC Y       2;
        SLNC U       2 {
            if (CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
                return ResolveState ("Hold.Grabbed");

            A_Refire ();

            return ResolveState (null);
        }
        SLNC T       2;
        SLNC SRQPONM 1;
        goto Ready2;

    Fire.Grabbed:
        SLNC N     1 A_FireProjectile ("S7_SoulLance_Beam_GrabbedSpawner", 0.0, 0, 0, 0, 0, 0.0);
        SLNC OPQRS 1;
        SLNC TU    2;
    Hold.Grabbed:
        SLNC V       2 {
            A_FireProjectile ("S7_SoulLance_Mutilator", 0, 0, 0, 0);
            GiveInventory ("S7_SLance_BeamHeld_Fire", 1);
        }
        SLNC W       2;
        SLNC X       2 GiveInventory ("S7_SLance_BeamHeld_Fire", 1);
        SLNC Y       2;
        SLNC U       2 A_JumpIfInventory ("S7_SoulLance_BeamGrabbed", 1, "Hold.Grabbed");
        SLNC T       2;
        SLNC SRQPONM 1;
        goto Ready2;

    Select:
        TNT1 A 0 A_Raise;
        wait;
    Deselect:
        TNT1 A 0 {
            if (invoker.Owner.health < 1)
                return ResolveState ("TrueDeselect");
            if (CheckInventory ("S7_SoulLance_BeamGrabbed", 1))
                return ResolveState ("Deselect.BeamGrab");

            return ResolveState (null);
        }
    TrueDeselect:
        SLNC MMMMLKJIHGFEDCBA 1;

        TNT1 A 0 A_Lower;
        wait;
    Deselect.BeamGrab:
        TNT1 AAAAAAAAAAAAAAAA 0 A_WeaponReady (WRF_NoFire | WRF_NoSwitch | WRF_DisableSwitch | WRF_NoBob);
        goto Fire.Grabbed;
    }
}

class S7_SoulLance_Mutilator : actor {
    default {
        damageType "SoulLanceSelfDamage";
        obituary "$SLANCESELFKILL";

        +noInteraction +noGravity +invisible +cantSeek
        +noBlockmap +noTrigger +neverRespawn +dontSplash
        +noExtremeDeath +foilInvul +noDamageThrust
    }

    states {
    Death:
    Spawn:
        TNT1 A 1 {
            A_RearrangePointers (AAPTR_Default, AAPTR_TARGET, AAPTR_TARGET);
            A_DamageMaster (2, "SoulLanceSelfDamage");
        }
        stop;
    }
}

class S7_SoulLance_Beam_GrabbedSpawner : actor {
    default {
        radius 2;
        height 2;
        speed 0;
        renderStyle "none";

        projectile;
        +invulnerable +noDamage +noBlockmap +noTeleport
        +thruActors +noClip +noGravity +ghost
        +dontSplash +invisible +noInteraction
    }

    int user_off [3];

    states {
    Spawn:
        TNT1 A 1 noDelay {
            A_Warp (AAPTR_Target, user_off [0], user_off [1], user_off [2], 0, WARPF_NoCheckPosition | WARPF_Interpolate | WARPF_UseCallerAngle);

            if (!CheckLOF (CLOFF_JumpEnemy | CLOFF_JumpFriend | CLOFF_JumpObject | CLOFF_JumpNonHostile | CLOFF_SkipTarget, 0.0, 0.0, angle, -pitch))
                return ResolveState ("NoLOF");

            if (target && target.CheckInventory ("S7_SLance_BeamHeld_Fire", 1))
                return ResolveState ("ShootStuff");

            return ResolveState (null);
        }
        loop;

    ShootStuff:
        TNT1 A 0 {
            A_SpawnProjectile ("S7_SoulLance_Beam", 0.0, 5, angle, CMF_AimDirection | CMF_TrackOwner | CMF_AbsoluteAngle | CMF_AbsolutePitch, pitch);
            A_TakeFromTarget ("S7_SLance_BeamHeld_Fire", 0x7FFFFFFF);
        }
        goto Spawn;

    NoLOF:
        TNT1 A 1 A_TakeFromTarget ("S7_SoulLance_BeamGrabbed", 0x7FFFFFFF);
        stop;
    }
}

class S7_SoulLance_Beam : fastProjectile {
    default {
        radius 8;
        height 8;
        speed 25;
        health 200;
        renderStyle "add";
        scale 0.060;
        damageFunction (random (1, 2) * 5);
        damageType "S7_SoulLance_Beam";
        missileType "S7_SoulLance_Beam_Trail";
        missileHeight 8;
        decal "Scorch";
        alpha 1.0;

        projectile;
        +noDamageThrust +forceXYBillboard +ripper +forceRadiusDMG
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_ScaleVelocity (1.0 / (25 * 1.0));
            A_ScaleVelocity (health);
        }
    Idle:
        SLCF A 1 bright;
        loop;
    Death:
        //TNT1 A 0 A_Explode (random (1, 3) * 128, 32, 0);
        TNT1 A 0 {
            A_SpawnItemEx ("S7_SoulLance_Beam_Explosion", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_Clientside);
            for (int i = 0; i < 4; i++) {
                A_SpawnItemEx ("S7_SoulLance_Sparks",  0.0, 0.0, 0.0, frandom [sfx] (-2.5, 2.5), frandom [sfx] (-2.5, 2.5), frandom [sfx] (-0.5, 3.5), 0, SXF_Clientside);
                A_SpawnItemEx ("S7_SoulLance_Sparks2", 0.0, 0.0, 0.0, frandom [sfx] (-2.5, 2.5), frandom [sfx] (-2.5, 2.5), frandom [sfx] (-0.5, 3.5), 0, SXF_Clientside);
                A_SpawnItemEx ("S7_SoulLance_Sparks3", 0.0, 0.0, 0.0, frandom [sfx] (-2.5, 2.5), frandom [sfx] (-2.5, 2.5), frandom [sfx] (-0.5, 3.5), 0, SXF_Clientside);
                A_SpawnItemEx ("S7_SoulLance_Sparks4", 0.0, 0.0, 0.0, frandom [sfx] (-2.5, 2.5), frandom [sfx] (-2.5, 2.5), frandom [sfx] (-0.5, 3.5), 0, SXF_Clientside);
            }
        }
        stop;
    }
}

class S7_SoulLance_Beam_Explosion : S7_SoulLance_Beam {
    default {
        scale 1.0;
        translation "192:207=24:39", "224:224=16:16", "240:247=40:47";

        +forceXYBillboard
    }

    states {
    Spawn:
        PLSE ABCDE 2 bright;
        stop;
    }
}


class S7_SoulLance_Sparks : S7_TracerEffectsBase {
    default {
        gravity 0.38;
        scale 0.03;

        -noGravity -noInteraction
    }

    states {
    Spawn:
        SLCF A 1 bright;
        SLCF A 1 bright A_FadeOut (0.05);
        wait;
    }
}

class S7_SoulLance_Sparks2 : S7_SoulLance_Sparks {
    default {
        translation "192:207=24:39", "224:224=16:16", "240:247=40:47";
        scale 0.1;
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_Jump (256, "Spawn1", "Spawn2");
    Spawn1:
        PLSS A 1 bright;
        goto Fade;
    Spawn2:
        PLSS B 1 bright;
        goto Fade;
    Fade:
        ---- A 1 bright A_FadeOut (0.05);
        wait;
    }
}
class S7_SoulLance_Sparks3 : S7_SoulLance_Sparks2 {
    default {
        translation "192:207=168:183", "240:247=184:191";
    }
}
class S7_SoulLance_Sparks4 : S7_SoulLance_Sparks2 {
    default {
        translation "193:194=250:250", "195:196=251:251", "197:198=252:252", "199:199=253:253", "205:205=253:253", "202:202=253:253", "241:241=254:254";
    }

    states {
    Spawn2:
        goto Spawn1;
    }
}

class S7_SoulLance_Beam_Trail : S7_FastProjTrailBase {
    default {
        renderStyle "add";
        scale 0.060;
        alpha 1.0;
    }

    states {
    Spawn:
        SLCF A 1 bright;
        ---- A 1 bright A_FadeOut (0.065);
        wait;
    }
}