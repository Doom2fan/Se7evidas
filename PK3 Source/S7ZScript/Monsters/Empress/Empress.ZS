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
        DamageFactor "PistolTracer", .7;
        DamageFactor "RevolverTracer", .8;
        DamageFactor "RifleTracer", .9;
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.5;
        DamageFactor "LaserTracer", 1.25;
        // Boss damage reduction
        DamageFactor "ExplosionSplashDMG", .25;
        DamageFactor "Shrapnel", .35;

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
            GiveXP (source, int (2250 * max (1, level / 2.)));
            GiveCash (source, int (2340 * max (1, level / 5.)));
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

    /** "Spawner" **/
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

            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23., 23.), fRandom [sfx] (-23., 23.), 15. + fRandom [sfx] (-0., 32.), 0, 0, 0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23., 23.), fRandom [sfx] (-23., 23.), 15. + fRandom [sfx] (-0., 32.), 0, 0, 0, 0, SXF_Clientside | SXF_NoCheckPosition);
            spawnLoopCount--;

            return ResolveState (null);
        }
        wait;
    PreSpawnIdle:
        TNT1 A 1 {
            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23., 23.), fRandom [sfx] (-23., 23.), 15. + fRandom [sfx] (-0., 32.), 0, 0, 0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23., 23.), fRandom [sfx] (-23., 23.), 15. + fRandom [sfx] (-0., 32.), 0, 0, 0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_S7LookEx (flags: LOF_NoSeeSound, fov: 360., seeStateLabel: "Spawn.Spawned");
        }
        loop;
    Spawn.Spawned:
        TNT1 A            0 {
            for (int i = 0; i < (5*2); i++)
                A_SpawnItemEx ('S7_EmpressPentagramCorner', 180., 0, 0, 0, 0, 0, (72/2.) * i, SXF_Clientside | SXF_NoCheckPosition);
        }
        TNT1 AAAAAAAAAAAA 1 A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23., 23.), fRandom [sfx] (-23., 23.), 15. + fRandom [sfx] (-0., 32.), 0, 0, 0, 0, SXF_Clientside | SXF_NoCheckPosition);
        TNT1 A            5;
        TNT1 A            0 {
            A_SetSize (default.Radius, default.Height, false);
            TeleportMove (pos, true);

            for (int i = 0; i < 48; i++) {
                A_SpawnItemEx ('S7_EmpressSparkle', fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 50. + fRandom [sfx] (0., 2.5),
                    fRandom [sfx] (-8., 8.), fRandom [sfx] (-8., 8.), fRandom [sfx] (-8., 8.), 0, SXF_Clientside | SXF_NoCheckPosition);
            }
        }
        goto Idle;
    }

    /** Idle, chasing enemy, initiating attack **/
    states {
    Idle:
        HRFR A   1 {
            TakeInventory ('S7_IsDead', 0x7FFFFFFF);
            ResetAttacks ();

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
            ResetAttacks ();
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

            return A_Jump (256, "Attack.Fireball", "Attack.MagicMissile", "Attack.DanmakuFireballs");
        }
        goto Attack.Fireball;
    }

    /** Shields **/
    states {
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
            A_SpawnItemEx ('S7_EmpressInvulnOrbiterCW',  64., 0, 50., 0, 0, 0, 0, SXF_NoCheckPosition | SXF_SetMaster);
        }
        HRFR F  9 A_SpawnItemEx ('S7_EmpressInvulnOrbiterCCW', 64., 0, 50., 0, 0, 0, 0, SXF_NoCheckPosition | SXF_SetMaster);
        HRFR F  9 A_SpawnItemEx ('S7_EmpressInvulnOrbiterCW',  64., 0, 50., 0, 0, 0, 0, SXF_NoCheckPosition | SXF_SetMaster);
        HRFR F  9 A_SpawnItemEx ('S7_EmpressInvulnOrbiterCCW', 64., 0, 50., 0, 0, 0, 0, SXF_NoCheckPosition | SXF_SetMaster);
        TNT1 A  0 { castingInvuln = false; }
        goto See;
    }

    action void ResetAttacks () {
        invoker.midAttack_Fireball = false;
        invoker.attackDanmakuFireballs_Time = false;
        invoker.attackMagicMissile_Shots = 0;

        invoker.castingInvuln = false;
    }

    /** Fireball attack **/
    bool midAttack_Fireball;

    states {
    Attack.Fireball:
        TNT1 A    0 { midAttack_Fireball = true; }
        HRFR AAA  1 A_FaceTarget (19, 9.5);
        HRFR HHHH 2 bright A_FaceTarget (19, 9.5);
        HRFR HHHH 2 bright A_FaceTarget (19, 9.5);

        HRFR H    1 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ('S7_EmpressMissile1', 105.);
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR H    1 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ('S7_EmpressMissile1', 105.);
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);

        HRFR H    1 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ('S7_EmpressMissile1', 105.);
        }
        HRFR HHHH 1 A_FaceTarget (90, 45);
        TNT1 A 0 A_PlaySound ("Misc/Common/Fireball2", attenuation: 0.5);
        HRFR HHHH 5;
        goto See;
    }

    /** Magic misile attack **/
    int attackMagicMissile_Shots;

    states {
    Attack.MagicMissile:
        HRFR AAA  1 A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        HRFR FFFF 2 bright A_FaceTarget (24, 12);
        TNT1 A    0 {
            attackMagicMissile_Shots = random [monsterSpc] (5, 12);
            A_FaceTarget (0, 0);
        }
    Attack.MagicMissile.Loople:
        HRFR E    1 bright A_SpawnProjectile ('S7_EmpressMissile2', 50.,  16, angle: fRandom [monsterSpread] (-.5, .5), pitch: fRandom [monsterSpread] (-1.25, 1.25));
        HRFR EEEE 1 bright A_FaceTarget (90, 45);
        HRFR E    1 bright A_SpawnProjectile ('S7_EmpressMissile2', 50., -16, angle: fRandom [monsterSpread] (-.5, .5), pitch: fRandom [monsterSpread] (-1.25, 1.25));
        HRFR EEEE 1 bright A_FaceTarget (90, 45);
        HRFR E    1 bright {
            if ((attackMagicMissile_Shots--) <= 0) {
                attackMagicMissile_Shots = 0;

                return ResolveState ("See");
            }

            return A_MonsterRefire (40, "See");
        }
        loop;
    }

    /** Danmaku fireballs attack **/
    const DanmakuFireballs_Time_CreateTetragram = 3;
    const DanmakuFireballs_Time_SpawnMissiles = 10;
    const DanmakuFireballs_Time_ChangeFrame = DanmakuFireballs_Time_LaunchMissiles - 2;
    const DanmakuFireballs_Time_Warn = 44;
    const DanmakuFireballs_Time_LaunchMissiles = 45;
    const DanmakuFireballs_Time_End = 65;

    const DanmakuFireballs_FireballCount = 6;
    const DanmakuFireballs_Tetragram_Steps = 16;
    const DanmakuFireballs_Tetragram_Dist = 96.;

    int attackDanmakuFireballs_Time;
    Array<S7_Empress_DanmakuFireball> attackDanmakuFireballs_Fireballs;
    action state DanmakuFireballs_DoAttack () {
        int time = invoker.attackDanmakuFireballs_Time;

        if (time >= DanmakuFireballs_Time_CreateTetragram) {
            int tetragramTime = time - DanmakuFireballs_Time_CreateTetragram;

            int fireSteps = clamp (
                int (DanmakuFireballs_Tetragram_Steps * (double (tetragramTime) / 17)),
                0, DanmakuFireballs_Tetragram_Steps
            );

            int initialStep = clamp ((time - (DanmakuFireballs_Time_LaunchMissiles - 5)) * 2, 0, DanmakuFireballs_Tetragram_Steps);

            for (int k = 0; k < 2; k++) {
                for (int i = 0; i < 4; i++) {
                    double angLeaf = 90 * i;
                    double angSpin = tetragramTime * 2. % 360;

                    for (int j = initialStep; j < fireSteps; j++) {
                        double angStep = (45. / DanmakuFireballs_Tetragram_Steps) * j;
                        double xOffs = (DanmakuFireballs_Tetragram_Dist / DanmakuFireballs_Tetragram_Steps) * (DanmakuFireballs_Tetragram_Steps - j);

                        if (k == 0)
                            angStep =  angStep;
                        else
                            angStep = -angStep;

                        Vector2 spawnPos = (
                            (xOffs * cos (angLeaf + angSpin + angStep + angle)),
                            (xOffs * sin (angLeaf + angSpin + angStep + angle))
                        );

                        bool success; Actor act;
                        [success, act] = A_SpawnItemEx ("S7_Empress_DanmakuFireballsFire",
                            spawnPos.X, spawnPos.Y, 95.,
                            0., 0., fRandom [sfx] (0., 5.),
                            flags: SXF_NoCheckPosition | SXF_Clientside | SXF_AbsoluteAngle | SXF_AbsolutePosition
                        );

                        if (success && act) {
                            Vector2 prevPos = (
                                (xOffs * cos (angLeaf + angSpin - 2 + angStep + angle)),
                                (xOffs * sin (angLeaf + angSpin - 2 + angStep + angle))
                            );

                            act.Prev = (pos.XY + prevPos, act.pos.Z);
                        }
                    }
                }
            }
        }

        if (time >= DanmakuFireballs_Time_ChangeFrame)
            frame++;

        if (time == 0)
            A_PlaySound ("Monsters/Empress/DanmakuFireballsStart", CHAN_Body, attenuation: 0.5);
        else if (time == DanmakuFireballs_Time_SpawnMissiles) {
            A_PlaySound ("Monsters/Empress/DanmakuFireballsLoop", CHAN_5, attenuation: 0.5);
            invoker.attackDanmakuFireballs_Fireballs.Clear ();

            for (int i = 0; i < DanmakuFireballs_FireballCount; i++) {
                let proj = S7_Empress_DanmakuFireball (A_SpawnProjectile ("S7_Empress_DanmakuFireball", flags: CMF_AimDirection));

                if (proj) {
                    invoker.attackDanmakuFireballs_Fireballs.Push (proj);

                    proj.tracer = target;
                    proj.phaseToTarg = (360. / DanmakuFireballs_FireballCount) * i;
                }
            }
        } else if (time == DanmakuFireballs_Time_Warn)
            A_PlaySound ("Monsters/Empress/DanmakuFireballsEnd", CHAN_6, attenuation: ATTN_NONE);
        else if (time == DanmakuFireballs_Time_LaunchMissiles) {
            for (int i = 0; i < invoker.attackDanmakuFireballs_Fireballs.Size (); i++) {
                let proj = invoker.attackDanmakuFireballs_Fireballs [i];

                if (proj)
                    proj.doLaunch = true;
            }

            invoker.attackDanmakuFireballs_Fireballs.Clear ();
        } else if (time == DanmakuFireballs_Time_End)
            return ResolveState ("See");

        invoker.attackDanmakuFireballs_Time++;

        return ResolveState (null);
    }

    states {
    Attack.DanmakuFireballs:
        HRFR AAAAAA 1 A_FaceTarget (60, 30);
        TNT1 A 0 { attackDanmakuFireballs_Time = 0; }
        HRFR I 1 DanmakuFireballs_DoAttack ();
        wait;
    }

    /** Pain and death **/
    states {
    Pain:
        HRFR G 8 {
            ResetAttacks ();

            A_Pain ();
        }
        goto See;
    Pain.Empress_BallExploded:
        HRFR G 13 {
            ResetAttacks ();

            A_Pain ();
        }
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
        HRFR FFFFFF  1 A_SpawnItemEx ('S7_EmpressDeathSmokeSpawner', 0, 0, 0, 0, 0, 0, 0, SXF_Clientside | SXF_NoCheckPosition);
        HRFR F       2;
        TNT1 A      35 {
            for (int i = 0; i < 48; i++) {
                A_SpawnItemEx ('S7_EmpressSparkle', fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 50. + fRandom [sfx] (0., 2.5),
                    fRandom [sfx] (-8., 8.), fRandom [sfx] (-8., 8.), fRandom [sfx] (-8., 8.), 0, SXF_Clientside | SXF_NoCheckPosition);
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
        TNT1 AAAAAAAA 0 A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23., 23.), fRandom [sfx] (-23., 23.), 15. + fRandom [sfx] (-0., 85.), 0, 0, 0, 0, SXF_Clientside | SXF_NoCheckPosition);
        stop;
    }
}

/** Fireball attack **/
class S7_EmpressMissile1 : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.EffectStepMul .125 * 2;
        S7_Projectile.InterpMove false;

        Speed 45;
        DamageFunction (21 + random [monsterDMG] (-4, 4));

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
        Super.PostBeginPlay ();

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
            act.vel = (0., 0, fRandom [sfx] (.5, 3.));
        }

        return act;
    }

    states {
    Spawn:
        TNT1 A 1 bright {
            if (CheckInventory ('S7_IsDead', 1, AAPTR_Target) || !(target is 'S7_Empress') || !(S7_Empress (target)).midAttack_Fireball)
                return ResolveState ("DieOut");
            if (loopCount < 1)
                return ResolveState ("Flight");

            invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
            invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));

            if (self && target)
                Warp (target, 25., 0, 105., rotAngle, WARPF_AbsoluteAngle | WARPF_NoCheckPosition | WARPF_Interpolate);
            rotAngle += 24;
            loopCount--;

            return ResolveState (null);
        }
        loop;

    Flight:
        TNT1 A 1 bright {
            if (self && target)
                Warp (target, 25., 0, 105., 360, WARPF_AbsoluteAngle | WARPF_NoCheckPosition | WARPF_Interpolate);
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
        Alpha 1.;
        Scale .25;

        +NOINTERACTION +CLIENTSIDEONLY
    }

    states {
    Spawn:
        FIR1 ACEHJ 1 bright;
        stop;
    }
}

/** Magic missile attack **/
class S7_EmpressMissile2 : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_Center | ColMode_Corners;

        Radius 9;
        Height 20;
        Speed 40;

        DamageFunction (12 + random [monsterDMG] (-2, 2) * 8));
        MissileType 'S7_EmpressMissile2Trail';
        MissileHeight 8;

        RenderStyle "add";
        Scale .075;

        SeeSound "";
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
        TNT1 A 0 A_SetScale (1.);
        HRP1 ABCDE 2 bright;
        stop;
    }
}

class S7_EmpressMissile2Trail : S7_FastProjTrailBase {
    default {
        RenderStyle "add";
        Scale .075;

        +FORCEXYBILLBOARD
    }

    states {
    Spawn:
        HRSF AAA 1 bright A_FadeOut (.5);
        stop;
    }
}

/** Misc. attack effects **/
class S7_Empress_DanmakuFireballsFire : S7_FireBase {
    default {
        Alpha 1.;
        Scale .15;

        +NOINTERACTION +CLIENTSIDEONLY
    }

    states {
    Spawn:
        FIR1 ACE 1 bright;
        FIR1 H  1 bright A_Jump (128, "Null");
        stop;
    }
}

class S7_Empress_DanmakuFireball : S7_Projectile {
    default {
        Radius 20;
        Height 20;

        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.EffectStepMul .125 * 2;
        S7_Projectile.InterpMove false;

        Speed 25;
        DamageFunction ((35 / S7_Empress.DanmakuFireballs_FireballCount) + random [monsterDMG] (-2, 2));

        MissileType 'S7_EmpressMissile1Trail';
        MissileHeight 8;
        RenderStyle "add";

        DeathSound "Misc/Common/FireballHit";
        Obituary "$OB_EMPRESSFB";
        Species 'S7EmpressCrap';

        +FORCEXYBILLBOARD +THRUSPECIES
    }

    double phaseToTarg, targAngle;
    bool doLaunch;
    double launchAngle, launchPitch;

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        bMissile = false;
        vel = (0, 0, 0);
    }

    override Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        Actor act = Super.StepEffects (initialPos, stepDiff, realVel);

        if (act) {
            act.SetOrigin (act.Vec3Offset (fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-3, 3)), false);
            act.vel = (0., 0, fRandom [sfx] (.5, 3.));
        }

        return act;
    }

    states {
    Spawn:
        TNT1 A 1 bright {
            let empress = S7_Empress (target);
            if (CheckInventory ('S7_IsDead', 1, AAPTR_Target) || !target)
                return ResolveState ("DieOut");
            if (empress.attackDanmakuFireballs_Time < S7_Empress.DanmakuFireballs_Time_SpawnMissiles)
                return ResolveState ("DieOut");
            if (doLaunch)
                return ResolveState ("Flight");

            if (GetAge () >= 1) {
                invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
                invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
            }

            if (self && tracer) {
                double spinSpeed = clamp (S7_Empress.DanmakuFireballs_Time_ChangeFrame - empress.attackDanmakuFireballs_Time, 0, 5);
                phaseToTarg += spinSpeed;

                Warp (tracer,
                    tracer.radius + 128., 0, tracer.height * .35,
                    angle: phaseToTarg,
                    flags: WARPF_NoCheckPosition | WARPF_Interpolate
                );

                Vector3 targPos = tracer.Vec3Offset (0., 0., tracer.height * .25);
                bool canIntercept;
                Vector3 interceptPos;

                [canIntercept, interceptPos] = S7_Math.CalculateInterceptShotPosition (level,
                    pos, tracer.pos,
                    tracer.vel, Speed
                );
                if (canIntercept)
                    targPos = interceptPos;
                
                [launchAngle, launchPitch] = S7_Math.GetAnglesTo (level, pos, targPos);
            }
            if (GetAge () < 1) {
                ClearInterpolation ();

                invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
                invoker.StepEffects (pos, (0, 0, 0), (0, 0, 0));
            }

            return ResolveState (null);
        }
        loop;

    Flight:
        TNT1 A 0 {
            bMissile = true; // Make it a projectile again

            Vel3DFromAngle (Speed, launchAngle, launchPitch);
        }
        TNT1 A 1 bright;
        wait;

    DieOut:
        TNT1 A 0 A_Die;
    Death:
        CP00 DEFGH 2 bright;
        stop;
    }   
}