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
// Empress (Female Heresiarch)
//
//-------------------------------------------------------------------------------------------
/** Constants **/
const S7_EmpressMass = 12000;

/** Inventory tokens **/
// Booleans
class S7_IsEmpress : S7_Boolean { }

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
        BloodType 'S7_EmpressBlood', 'S7_EmpressBloodSplatter';
        BloodColor "B2 11 DE";
        SeeSound "cyber/sight";
        PainSound "cyber/pain";
        DeathSound "cyber/death";
        ActiveSound "cyber/active";
        Species 'S7Empress';
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

    const InvulnDelayTime = 35 * 12;
    const InvulnLimit = 2500;
    const InvulnShieldAngle = 152.5;

    bool initialized;
    bool shieldUp; // The shield is active
    int ballsCount; // How much invulnerability thingies are left
    int invulnDelay; // How much time left until we can raise the shield
    bool canCastInvuln; // Whether shields can be cast

    bool midAttack1;
    int attack2Shots;
    bool castingInvuln;

    bool canDieNow;
    Actor deathSource, deathInflictor;
    int deathDMGFlags;

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        GiveInventory ('S7_IsEmpress', 1);
        TakeInventory ('S7_IsDead', 0x7FFFFFFF);

        initialized = true;
    }

    override int DamageMobj (Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
        bool hitShield = false;

        if (shieldUp) {
            let angTo = inflictor ? AngleTo (inflictor) : double.NaN;
            if (flags & DMG_USEANGLE && !inflictor)
                angTo = DeltaAngle (self.angle, angle);
            
            if (abs (angTo) <= InvulnShieldAngle)
                hitShield = true;
        }

        bool origInv = bInvulnerable, origPain = bNoPain, origBlood = bNoBlood;

        if (hitShield) { // Max hax
            bInvulnerable = true;
            bNoPain = !(random [monsterSpc] () < 48);
            bNoBlood = true;

            Spawn ('S7_EmpressShieldHitspark', inflictor.pos);
        } else if (shieldUp) {
            if (damage < TELEFRAG_DAMAGE)
                damage /= 2;
        }

        int ret = Super.DamageMobj (inflictor, source, damage, mod, flags, angle);

        bInvulnerable = origInv;
        bNoPain = origPain;
        bNoBlood = origBlood;

        return ret;
    }

    override void Die (Actor source, Actor inflictor, int dmgflags) {
        if (canDieNow) {
            Super.Die (source, inflictor, dmgflags);
            return;
        } else {
            deathSource = source;
            deathInflictor = inflictor;
            deathDMGFlags = dmgflags;
        }
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (2250 * max (1, level / 2)));
            GiveCash (source, int (2340 * max (1, level / 2)));
        }
    }

    override void Tick () {
        if (initialized) {
            if (health > InvulnLimit || shieldUp)
                canCastInvuln = false;
            else if (invulnDelay >= 0 && !shieldUp) {
                canCastInvuln = false;
                invulnDelay--;
            } else if (health <= InvulnLimit && !shieldUp && invulnDelay < 1)
                canCastInvuln = true;

            if (ballsCount < 1 && shieldUp)
                shieldUp = false;
            if (ballsCount < 0)
                ballsCount = 0;
        }

        Super.Tick ();
    }

    int spawnLoopCount;

    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_ChangeLinkFlags (blockmap: false);
            A_SetSize (0, 0, false);
            spawnLoopCount = random [monsterSpc] (4, 7);
        }
        TNT1 A 1 {
            if (spawnLoopCount < 1)
                return ResolveState ("PreSpawnIdle");

            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            spawnLoopCount--;

            return ResolveState (null);
        }
        wait;
    PreSpawnIdle:
        TNT1 A 1 {
            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_S7LookEx (flags: LOF_NoSeeSound, fov: 360., seeStateLabel: "Spawn.Spawned");
        }
        loop;
    Spawn.Spawned:
        TNT1 A            0 {
            for (int i = 0; i < (5*2); i++)
                A_SpawnItemEx ('S7_EmpressPentagramCorner', 180.0, 0.0, 0.0, 0.0, 0.0, 0.0, (72/2.) * i, SXF_Clientside | SXF_NoCheckPosition);
        }
        TNT1 AAAAAAAAAAAA 1 A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        TNT1 A            5;
        TNT1 A            0 {
            A_SetSize (default.Radius, default.Height, false);
            TeleportMove (pos, true);

            for (int i = 0; i < 48; i++) {
                A_SpawnItemEx ('S7_EmpressSparkle', fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 50.0 + fRandom [sfx] (0.0, 2.5),
                    fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), 0, SXF_Clientside | SXF_NoCheckPosition);
            }
        }

    Idle:
        HRFR A   1 {
            TakeInventory ('S7_IsDead', 0x7FFFFFFF);
            midAttack1 = false;

            if (health < 1)
                return ResolveState ("RunAway");

            A_S7Look ();

            return ResolveState (null);
        }
        HRFR AAAAAAAAA 1 A_JumpIf (health < 1, "RunAway");
        loop;

    See:
        TNT1 A    0 {
            TakeInventory ('S7_IsDead', 0x7FFFFFFF);
            midAttack1 = false;
            A_PlaySound ("Footsteps/Large", CHAN_5);
        }
        HRFR AABB 4 {
            if (health < 1)
                return ResolveState ("RunAway");

            A_S7ChaseDef ();
            return ResolveState (null);
        }
        TNT1 A    0 A_PlaySound ("Footsteps/Large", CHAN_6);
        HRFR CCDD 4 {
            if (health < 1)
                return ResolveState ("RunAway");

            A_S7ChaseDef ();

            return ResolveState (null);
        }
        loop;

    Missile:
        TNT1 A 0 {
            if (!shieldUp && canCastInvuln && random [monsterSpc] () < 64)
                return ResolveState ("ShieldsUp");

            return A_Jump (256, "Attack1", "Attack2");
        }
        goto Attack1;

    ShieldsUp:
        HRFR A  5 { bNoPain = true; }
        HRFR FF 5;
        HRFR F  9 {
            shieldUp = true;
            invulnDelay = InvulnDelayTime;
            //bNoBlood = true;
            //bInvulnerable = true;
            //GiveInventory ('S7_EmpressProtection', 1);
            castingInvuln = true;
            A_SpawnItemEx ('S7_EmpressInvulnOrbiterCW',  64.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_SetMaster);
        }
        HRFR F  9 A_SpawnItemEx ('S7_EmpressInvulnOrbiterCCW', 64.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_SetMaster);
        HRFR F  9 A_SpawnItemEx ('S7_EmpressInvulnOrbiterCW',  64.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_SetMaster);
        HRFR F  9 A_SpawnItemEx ('S7_EmpressInvulnOrbiterCCW', 64.0, 0.0, 50.0, 0.0, 0.0, 0.0, 0.0, SXF_NoCheckPosition | SXF_SetMaster);
        TNT1 A  0 { castingInvuln = false; }
        goto See;

    Attack1:
        TNT1 A    0 { midAttack1 = true; }
        HRFR AAA  1 A_FaceTarget (19, 9.5);
        HRFR HHHH 2 bright A_FaceTarget (19, 9.5);
        HRFR HHHH 2 bright A_FaceTarget (19, 9.5);

        HRFR H    1 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ('S7_EmpressMissile1', 105.0);
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR H    1 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ('S7_EmpressMissile1', 105.0);
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR H    1 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ('S7_EmpressMissile1', 105.0);
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR HHHH 5;
        goto See;
    Attack2:
        HRFR AAA  1 A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        TNT1 A    0 {
            attack2Shots = random [monsterSpc] (5, 12);
            A_FaceTarget (0, 0);
        }
    Attack2.Loople:
        HRFR E    1 bright A_SpawnProjectile ('S7_EmpressMissile2', 50.0,  16, angle: fRandom [monsterSpread] (-0.5, 0.5), pitch: fRandom [monsterSpread] (-1.25, 1.25));
        HRFR EEEE 1 bright A_FaceTarget (90, 45);
        HRFR E    1 bright A_SpawnProjectile ('S7_EmpressMissile2', 50.0, -16, angle: fRandom [monsterSpread] (-0.5, 0.5), pitch: fRandom [monsterSpread] (-1.25, 1.25));
        HRFR EEEE 1 bright A_FaceTarget (90, 45);
        HRFR E    1 bright {
            if ((attack2Shots--) <= 0) {
                attack2Shots = 0;

                return ResolveState ("See");
            }

            return A_MonsterRefire (40, "See");
        }
        loop;

    Pain:
        HRFR G 8 {
            midAttack1 = false;
            attack2Shots = 0;
            A_Pain ();
        }
        goto See;
    Pain.Empress_BallExploded:
        HRFR G 13 {
            midAttack1 = false;
            attack2Shots = 0;
            A_Pain ();
        }
        goto See;

    Pain.S7_SoulLance_Beam:
        HRFR G 3 {
            if ((target && target.CheckInventory ('S7_SoulLance_BeamGrabbed', 1)) || random [monsterSpc] () < 4)
                return ResolveState ("Pain");

            return CheckIfInTargetLOS (360.0, JLOSF_AllyNoJump) ? ResolveState ("SLance_BeamGrab") : ResolveState (null);
        }
        goto See;
    SLance_BeamGrab:
        HRFR E 1 {
            if (!target)
                return ResolveState ("SLance_BeamLost");

            ACS_NamedExecuteAlways ('S7_SLanceBeamGrab', 0); // Execute the ACS script. (this will get changed to ZScript later)

            bNoPain = true;
            A_SetMass (0x7FFFFFFF);
            target.GiveInventory ('S7_SoulLance_BeamGrabbed', 1);
            GiveInventory ('S7_SoulLance_BeamGrabbed', 1);

            return ResolveState (null);
        }
    SLance_BeamHold:
        HRFR E 1 {
            A_FaceTarget ();

            if (!CheckInventory ('S7_SoulLance_BeamGrabbed', 1) || !CheckIfInTargetLOS (360.0, JLOSF_AllyNoJump))
                return ResolveState ("SLance_BeamLost");

            return ResolveState (null);
        }
        loop;
    SLance_BeamLost:
        HRFR E 3 {
            A_SetMass (S7_EmpressMass);

            if (!shieldUp)
                bNoPain = false;

            if (target)
                target.TakeInventory ('S7_SoulLance_BeamGrabbed', 0x7FFFFFFF);

            TakeInventory ('S7_SoulLance_BeamGrabbed', 0x7FFFFFFF);
            A_FaceTarget ();
        }
        TNT1 A 0 A_JumpIf (health < 1, "RunAway");
        goto See;

    /** Death stuff **/
    RunAway:
        TNT1 A 0 {
            canDieNow = true;
            Die (deathSource, deathInflictor, deathDMGFlags);
        }
        goto Death;
    Death:
        TNT1 A 0 {
            GiveInventory ('S7_IsDead', 1);
            return (CheckInventory ('S7_SoulLance_BeamGrabbed', 1) ? ResolveState ("SLance_BeamLost") : ResolveState ("Death2"));
        }
    Death2:
        HRFR GGG    13 A_Pain;
        HRFR FFFFFF  1 A_SpawnItemEx ('S7_EmpressDeathSmokeSpawner', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        HRFR F       2;
        TNT1 A      35 {
            for (int i = 0; i < 48; i++) {
                A_SpawnItemEx ('S7_EmpressSparkle', fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 50.0 + fRandom [sfx] (0.0, 2.5),
                    fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), 0, SXF_Clientside | SXF_NoCheckPosition);
            }
            A_NoBlocking ();
            A_DamageChildren (0x7FFFFFFF, 'EmpressDeath');
            A_KillChildren ();
        }
        TNT1 A      -1;
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
        TNT1 AAAAAAAA 0 A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 85.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        stop;
    }
}

class S7_EmpressMissile2 : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_Center | ColMode_Corners;

        Radius 9;
        Height 20;
        Speed 40;

        DamageFunction int (floor (fRandom [monsterDMG] (1, 2) * 8));
        MissileType 'S7_EmpressMissile2Trail';
        MissileHeight 8;

        RenderStyle "add";
        Scale 0.075;

        DeathSound "Misc/Common/FireballHit";
        Obituary "$OB_EMPRESSFB";
        Species 'S7EmpressCrap';

        +FORCEXYBILLBOARD +SEEKERMISSILE +THRUSPECIES
    }

    states {
    Spawn:
        HRSF AAAAAAAA 1 noDelay bright A_SeekerMissile (4, 4);
        HRSF A 1 bright;
        wait;

    Death:
        TNT1 A 0 A_SetScale (1.0);
        HRP1 ABCDE 2 bright;
        stop;
    }
}

class S7_EmpressMissile2Trail : S7_FastProjTrailBase {
    default {
        RenderStyle "add";
        Scale 0.075;

        +FORCEXYBILLBOARD
    }

    states {
    Spawn:
        HRSF AAA 1 bright A_FadeOut (0.5);
        stop;
    }
}

class S7_EmpressMissile1 : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.EffectStepMul 0.125 * 2;
        S7_Projectile.InterpMove false;

        Speed 45;
        DamageFunction (fRandom [monsterDMG] (2.0, 4.0) * 7);

        MissileType 'S7_EmpressMissile1Trail';
        MissileHeight 8;
        RenderStyle "add";

        DeathSound "Misc/Common/FireballHit";
        Obituary "$OB_EMPRESSFB";
        Species 'S7EmpressCrap';

        +FORCEXYBILLBOARD +SEEKERMISSILE +THRUSPECIES
    }

    double rotAngle;
    double loopCount;
    Vector3 savedVel;

    override void PostBeginPlay () {
        bMissile = false; // remove the MISSILE flag so the Draco's defense system won't target it
        rotAngle = angle;
        loopCount = 15;
        savedVel = vel;
        vel = (0, 0, 0);
    }

    override Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        Actor act = Super.StepEffects (initialPos, stepDiff, realVel);

        if (act) {
            act.SetOrigin (act.Vec3Offset (fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-3, 3)), false);
            act.vel = (0.0, 0.0, fRandom [sfx] (0.5, 3.0));
        }

        return act;
    }

    states {
    Spawn:
        TNT1 A 1 bright {
            if (CheckInventory ('S7_IsDead', 1, AAPTR_Target) || !(target is 'S7_Empress') || !(S7_Empress (target)).midAttack1)
                return ResolveState ("DieOut");
            if (loopCount < 1)
                return ResolveState ("Flight");

            invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
            invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));

            if (self && target)
                Warp (target, 25.0, 0.0, 105.0, rotAngle, WARPF_AbsoluteAngle | WARPF_NoCheckPosition | WARPF_Interpolate);
            rotAngle += 24;
            loopCount--;

            return ResolveState (null);
        }
        loop;

    Flight:
        TNT1 A 1 bright {
            if (self && target)
                Warp (target, 25.0, 0.0, 105.0, 360, WARPF_AbsoluteAngle | WARPF_NoCheckPosition | WARPF_Interpolate);
        }
        TNT1 A 0 {
            bMissile = true; // Make it a projectile again
            vel = savedVel; // Restore the projectile's velocity
            A_FaceTracer (0, 0); // Face the target
            A_SeekerMissile (1, 360, SMF_Precise | SMF_CurSpeed); // Make sure our direction gets adjusted
            A_SeekerMissile (1, 360, SMF_Precise | SMF_CurSpeed);
        }
        TNT1 AAAAA 2 bright A_SeekerMissile (6, 6, SMF_Precise | SMF_CurSpeed);
        TNT1 A 2 bright;
        wait;

    DieOut:
        TNT1 A 0 A_Die;
    Death:
        CP00 DEFGH 2 bright;
        stop;
    }
}

class S7_EmpressMissile1Trail : S7_FireBase {
    default {
        Alpha 1.0;
        Scale 0.25;

        +NOINTERACTION +CLIENTSIDEONLY
    }

    states {
    Spawn:
        FIR1 ACEHJ 1 bright;
        stop;
    }
}