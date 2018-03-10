//-------------------------------------------------------------------------------------------
//
// Empress (Female Heresiarch)
//
//-------------------------------------------------------------------------------------------
/** Constants **/
const S7_EmpressMass = 12000;

/** Inventory tokens **/
// Booleans
class S7_IsEmpress             : S7_Boolean { }
class S7_Empress_MidAttack1    : S7_Boolean { }
class S7_Empress_CastingInvuln : S7_Boolean { }

/** Main actor **/
class S7_Empress : S7_DemonBase {
    default {
        Health 4500;
        Radius 40;
        Height 100;
        Speed 18;
        Mass S7_EmpressMass;
        PainChance 15;
        PainChance "Empress_BallExploded", 256;
        PainChance "S7_SoulLance_Beam", 256;
        MinMissileChance 160;
        BloodColor "B2 11 DE";
        SeeSound "cyber/sight";
        PainSound "cyber/pain";
        DeathSound "cyber/death";
        ActiveSound "cyber/active";
        Species "S7Empress";
        Tag "$EMPRESSTAG";

        // Demon/Reanimated flesh damage reduction
        DamageFactor "PistolTracer", 0.7;
        DamageFactor "RevolverTracer", 0.8;
        DamageFactor "RifleTracer", 0.9;
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.5;
        DamageFactor "LaserTracer", 1.25;
        // Boss damage reduction
        DamageFactor "ExplosionSplashDMG", 0.25;
        DamageFactor "Shrapnel", 0.35;

        Monster;

        +FLOORCLIP +NOTARGET    +BOSS +BOSSDEATH
        +DONTMORPH +MISSILEMORE
    }

    const InvulnDelayTime = floor (35 * 7.5);
    const InvulnLimit = 2500;

    bool initialized;
    int ballsCount; // How much invulnerability thingies are left
    int invulnDelay; // How much time left until we can raise the shield
    bool canCastInvuln; // Whether shields can be cast

    bool canDieNow;
    Actor deathSource, deathInflictor;
    int deathDMGFlags;

    override void PostBeginPlay () {
        GiveInventory ("S7_IsEmpress", 1);
        TakeInventory ("S7_IsDead", 0x7FFFFFFF);
        initialized = true;
    }

    override void Die (Actor source, Actor inflictor, int dmgflags = 0) {
        if (canDieNow) {
            Die (source, inflictor, dmgflags);
            return;
        } else {
            deathSource = source;
            deathInflictor = inflictor;
            deathDMGFlags = dmgflags;
        }
    }

    override void Tick () {
        if (initialized) {
            if (health > InvulnLimit || ballsCount > 0) {
                canCastInvuln = false;

                if (ballsCount > 0)
                    invulnDelay = InvulnDelayTime;
            } else if (invulnDelay) {
                canCastInvuln = false;
                invulnDelay--;
            } else if (health <= InvulnLimit && ballsCount < 1 && invulnDelay < 1)
                canCastInvuln = true;
        }

        Super.Tick ();
    }

    states {
    Spawn:
    Idle:
        HRFR A   1 {
            TakeInventory ("S7_IsDead", 0x7FFFFFFF);
            TakeInventory ("S7_Empress_MidAttack1", 0x7FFFFFFF);

            if (health < 1)
                return ResolveState ("RunAway");

            A_Look ();

            return ResolveState (null);
        }
        HRFR AAAAAAAAA 1 A_JumpIf (health < 1, "RunAway");
        loop;

    See:
        TNT1 A    0 {
            TakeInventory ("S7_IsDead", 0x7FFFFFFF);
            TakeInventory ("S7_Empress_MidAttack1", 0x7FFFFFFF);
            A_PlaySound ("Footsteps/Large", CHAN_5);
        }
        HRFR AABB 4 {
            if (health < 1)
                return ResolveState ("RunAway");

            A_Chase ();

            return ResolveState (null);
        }
        TNT1 A    0 A_PlaySound ("Footsteps/Large", CHAN_6);
        HRFR CCDD 4 {
            if (health < 1)
                return ResolveState ("RunAway");

            A_Chase ();

            return ResolveState (null);
        }
        loop;

    Missile:
        TNT1 A 0 {
            if (!ballsCount && canCastInvuln && random [monsterSpc] (0, 255) < 64)
                return ResolveState ("ShieldsUp");

            return A_Jump (256, "Attack1", "Attack2");
        }
        goto Attack1;

    ShieldsUp:
        HRFR A  5 { bNoPain = true; }
        HRFR FF 5;
        HRFR F  9 {
            bNoBlood = true;
            bInvulnerable = true;
            //GiveInventory ("S7_EmpressProtection", 1);
            GiveInventory ("S7_Empress_CastingInvuln", 1);
            A_SpawnItemEx ("S7_EmpressInvulnOrbiterCW",  64.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_SetMaster);
        }
        HRFR F  9 A_SpawnItemEx ("S7_EmpressInvulnOrbiterCCW", 64.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_SetMaster);
        HRFR F  9 A_SpawnItemEx ("S7_EmpressInvulnOrbiterCW",  64.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_SetMaster);
        HRFR F  9 A_SpawnItemEx ("S7_EmpressInvulnOrbiterCCW", 64.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_SetMaster);
        TNT1 A  0 TakeInventory ("S7_Empress_CastingInvuln", 0x7FFFFFFF);
        goto See;

    Attack1:
        TNT1 A     0 GiveInventory ("S7_Empress_MidAttack1", 1);
        HRFR AAHHH 1 A_FaceTarget (72, 36);

        HRFR H    1 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ("S7_EmpressMissile1", 105.0);
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR H    1 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ("S7_EmpressMissile1", 105.0);
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR H    1 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ("S7_EmpressMissile1", 105.0);
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR HHHH 5;
        goto See;
    /*Attack2:
        HRFR AAHHH 1 A_FaceTarget (72, 36);
    Attack2.Loople:
        TNT1 A 0 A_FaceTarget (90, 45);
        HRFR H 1 A_SpawnProjectile ("S7_EmpressMissile2", 105.0, 0, -135 + fRandom [monsterSpread] (0.0, 90.0), CMF_AimDirection);
        HRFR HH 1 A_FaceTarget (90, 45);
        TNT1 A 0 A_FaceTarget (90, 45);
        HRFR H 1 A_SpawnProjectile ("S7_EmpressMissile2", 105.0, 0,  135 - fRandom [monsterSpread] (0.0, 90.0), CMF_AimDirection);
        HRFR HH 1 A_FaceTarget (90, 45);
        HRFR H 1 A_MonsterRefire (40, "See");
        loop;*/

    Pain:
        HRFR G 8 {
            TakeInventory ("S7_Empress_MidAttack1", 0x7FFFFFFF);
            A_Pain ();
        }
        goto See;
    Pain.Empress_BallExploded:
        HRFR G 13 {
            TakeInventory ("S7_Empress_MidAttack1", 0x7FFFFFFF);
            A_Pain ();
        }
        goto See;

    Pain.S7_SoulLance_Beam:
        HRFR G 3 {
            if ((target && target.CheckInventory ("S7_SoulLance_BeamGrabbed", 1)) || random [monsterSpc] (0, 255) < 4)
                return ResolveState ("Pain");

            return CheckIfInTargetLOS (360.0, JLOSF_AllyNoJump) ? ResolveState ("SLance_BeamGrab") : ResolveState (null);
        }
        goto See;
    SLance_BeamGrab:
        HRFR E 1 {
            if (!target)
                return ResolveState ("SLance_BeamLost");

            ACS_NamedExecuteAlways ("S7_SLanceBeamGrab", 0); // Execute the ACS script. (this will get changed to ZScript later)

            bNoPain = true;
            A_SetMass (0x7FFFFFFF);
            target.GiveInventory ("S7_SoulLance_BeamGrabbed", 1);
            GiveInventory ("S7_SoulLance_BeamGrabbed", 1);

            return ResolveState (null);
        }
    SLance_BeamHold:
        HRFR E 1 {
            A_FaceTarget ();

            if (!CheckInventory ("S7_SoulLance_BeamGrabbed", 1) || !CheckIfInTargetLOS (360.0, JLOSF_AllyNoJump))
                return ResolveState ("SLance_BeamLost");

            return ResolveState (null);
        }
        loop;
    SLance_BeamLost:
        HRFR E 3 {
            A_SetMass (S7_EmpressMass);

            if (ballsCount < 1)
                bNoPain = false;

            if (target)
                target.TakeInventory ("S7_SoulLance_BeamGrabbed", 0x7FFFFFFF);

            TakeInventory ("S7_SoulLance_BeamGrabbed", 0x7FFFFFFF);
            A_FaceTarget ();
        }
        TNT1 A 0 A_JumpIf (health < 1, "RunAway");
        goto See;

    /** Death stuff **/
    RunAway:
        TNT1 A 0 {
            Die (deathSource, deathInflictor, deathDMGFlags);
        }
        goto Death;
    Death:
        TNT1 A 0 {
            GiveInventory ("S7_IsDead", 1);
            return (CheckInventory ("S7_SoulLance_BeamGrabbed", 1) ? ResolveState ("SLance_BeamLost") : ResolveState ("Death2"));
        }
    Death2:
        HRFR GGG    13 A_Pain;
        HRFR FFFFFF  1 A_SpawnItemEx ("S7_EmpressDeathSmokeSpawner", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        HRFR F       2;
        TNT1 A      -1 {
            for (int i = 0; i < 48; i++) {
                A_SpawnItemEx ("S7_EmpressSparkle", fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 50.0 + fRandom [sfx] (0.0, 2.5),
                    fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), 0, SXF_Clientside | SXF_NoCheckPosition);
            }
            A_NoBlocking ();
            A_DamageChildren (0x7FFFFFFF, "EmpressDeath");
            A_KillChildren ();
            Destroy ();
        }
        stop;
    }
}

class S7_EmpressDeathSmokeSpawner : Actor {
    default {
        +NOINTERACTION  +NOGRAVITY +NOTELEPORT +NOBLOCKMAP
        +CLIENTSIDEONLY
    }

    states {
    Spawn:
        TNT1 AAAAAAAA 0 A_SpawnItemEx ("S7_EmpressSmoke", fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 85.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        stop;
    }
}

class S7_EmpressMissile2 : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        DamageFunction (fRandom [monsterDMG] (1.0, 3.0) * 4);
        Speed 45;
        MissileType "S7_EmpressMissile2Trail";
        MissileHeight 8;
        RenderStyle "add";
        DeathSound "imp/shotx";
        Obituary "$OB_EMPRESSFB";
        Species "S7EmpressCrap";
        Scale 0.75;

        +FORCEXYBILLBOARD +SEEKERMISSILE +THRUSPECIES
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_RearrangePointers (AAPTR_Target, AAPTR_Null, AAPTR_Null);
        BAL1 A 1 A_SeekerMissile (65, 65, SMF_Precise | SMF_Look);
        loop;

    Death:
        BAL1 CDE 3 bright;
        stop;
    }
}

class S7_EmpressMissile2Trail : S7_FastProjTrailBase {
    default {
        RenderStyle "add";
        Scale 0.75;

        +FORCEXYBILLBOARD
    }

    states {
    Spawn:
        BAL1 AAA 1 A_FadeOut (0.35);
        stop;
    }
}

class S7_EmpressMissile1 : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        DamageFunction (fRandom [monsterDMG] (2.0, 4.0) * 7);
        Speed 45;
        MissileType "S7_EmpressMissile1Trail";
        MissileHeight 8;
        RenderStyle "add";
        DeathSound "imp/shotx";
        Obituary "$OB_EMPRESSFB";
        Species "S7EmpressCrap";

        +FORCEXYBILLBOARD +SEEKERMISSILE +THRUSPECIES
    }

    double rotAngle;
    double loopCount;
    Vector3 savedVel;

    states {
    Spawn:
        TNT1 A 0 noDelay {
            bMissile = false; // remove the MISSILE flag so the Draco's defense system won't target it
            rotAngle = angle;
            loopCount = 15;
            savedVel = vel;
            A_ChangeVelocity (0.0, 0.0, 0.0, CVF_Replace);
        }
    Loople:
        BAL1 A 1 {
            if (CheckInventory ("S7_IsDead", 1, AAPTR_Target) || !CheckInventory ("S7_Empress_MidAttack1", 1, AAPTR_Target))
                return ResolveState ("DieOut");
            if (loopCount < 1)
                return ResolveState ("Flight");

            A_Warp (AAPTR_Target, 25.0, 0.0, 105.0, rotAngle, WARPF_AbsoluteAngle | WARPF_NoCheckPosition | WARPF_Interpolate);
            rotAngle += 24;
            loopCount--;

            return ResolveState (null);
        }
        loop;

    Flight:
        BAL1 A 1 A_Warp (AAPTR_Target, 25.0, 0.0, 105.0, 360, WARPF_AbsoluteAngle | WARPF_NoCheckPosition | WARPF_Interpolate);
        TNT1 A 0 {
            bMissile = true; // Make it a projectile again
            vel = savedVel; // Restore the projectile's velocity
            A_FaceTracer (0, 0); // Face the target
            A_SeekerMissile (1, 360, SMF_Precise | SMF_CurSpeed); // Make sure our direction gets adjusted
            A_SeekerMissile (1, 360, SMF_Precise | SMF_CurSpeed);
        }
        BAL1 A 2 A_SeekerMissile (6, 6, SMF_Precise | SMF_CurSpeed);
        wait;

    DieOut:
        TNT1 A 0 A_Die;
    Death:
        BAL1 CDE 3 bright;
        stop;
    }
}

class S7_EmpressMissile1Trail : S7_FastProjTrailBase {
    default {
        RenderStyle "add";

        +FORCEXYBILLBOARD
    }

    states {
    Spawn:
        BAL1 AAA 1 A_FadeOut (0.35);
        stop;
    }
}