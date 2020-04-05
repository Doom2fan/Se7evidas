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

/* Credits:

** THGR  AB: ???, Chronos "phantombeta" Ouroboros
** THGR CDE: Id Software, Chronos "phantombeta" Ouroboros
** THGR   F: Raven Software, Chronos "phantombeta" Ouroboros
** THGR   G: Raven Software
*/

//-------------------------------------------------------------------------------------------
//
// Normal/Explosive
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenade : S7_Projectile {
    default {
        Radius 10;
        Height 10;
        Speed 112;
        DamageFunction (65. + fRandom [weaponDamage] (-1., 1.) * (1. + bonusDMGFactor));
        Scale 0.8;
        Gravity 0.25;
        Translation "112:127=216:223";

        Decal "Scorch";

        -NOGRAVITY
    }

    action void Gren_DoQuake () {
        A_QuakeEx (3, 3, 3, 17, 0, int (256 * scale.X), "", falloff: 1, rollIntensity: 2.);
    }

    bool projDetonated;
    double airburstRange;
    double rangeTravelled;

    override void S7_ExplodeMissile (Line l, Actor targ, bool onSky) {
        Super.S7_ExplodeMissile (l, targ, onSky);

        projDetonated = true;
    }

    virtual S7_Thumper_Used SpawnUsedShell () {
        let usedShell = S7_Thumper_Used (Spawn ('S7_Thumper_Used', pos, ALLOW_REPLACE));

        usedShell.SetOrigin (pos, true);
        usedShell.prev = prev;
        usedShell.vel = vel;

        usedShell.angle = angle;
        usedShell.pitch = pitch;

        usedShell.target = target;
        usedShell.master = master;
        usedShell.tracer = tracer;

        usedShell.Translation = self.Translation;

        return usedShell;
    }

    virtual void DoAirburst (Vector3 prevVel) {
        S7_ExplodeMissile (null, null, false);
        projDetonated = true;
    }

    override void Tick () {
        let oldPos = pos;
        let prevVel = vel;
        double airburstRangeLeft = (airburstRange - rangeTravelled);

        bool velResized = false;
        if (!projDetonated && airburstRange > 0 && airburstRangeLeft >= 0 && vel.Length () > airburstRangeLeft) {
            vel = vel.Unit () * airburstRangeLeft;

            velResized = true;
        }

        Super.Tick ();

        if (velResized && !projDetonated)
            vel = prevVel;

        rangeTravelled += level.Vec3Diff (oldPos, pos).Length ();

        if (!projDetonated && airburstRange > 0 && (airburstRange - rangeTravelled) < S7C_EqualEpsilon)
            DoAirburst (prevVel);
    }

    states {
    Spawn:
        THGR A 1;
        loop;
    Death:
        TNT1 A 0 {
            A_SetGravity (0.0);
            A_Stop ();

            return ResolveState ("Loople");
        }
        stop;
    Loople:
        TNT1 A 0 {
            A_SetScale (1.);
            S7_ExplosionSound.CreateExplosion2 (pos);

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (128. * (1. + invoker.bonusDMGFactor)), 192, fulldamagedistance: 64);
        }
        goto Explosion;

    Explosion:
        TNT1 A 20 {
            Gren_DoQuake ();
            let expl = Spawn ('S7_GenericExplosion', pos, ALLOW_REPLACE);
            if (expl) {
                expl.target = self;
                expl.scale = scale;
            }
        }
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Fragmentation
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeFrag : S7_ThumperGrenade {
    states {
    Loople:
        TNT1 A 0 {
            A_SetScale (.85);
            S7_ExplosionSound.CreateExplosion2 (pos);

            S7_ActorExtensions.A_S7SpawnShrapnel (
                self, random [weaponSpc] (100, 150),
                minVel: int (200. * (1. + invoker.bonusDMGFactor)),
                maxVel: int (450. * (1. + invoker.bonusDMGFactor)),
                minMass: 10, maxMass: 25,
                keScale: 125,
                zOff: 2.0, flags: SXF_TransferPointers
            );

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (128. * (1. + invoker.bonusDMGFactor)), 160, fulldamagedistance: 64);
        }
        goto Explosion;
    }
}

//-------------------------------------------------------------------------------------------
//
// Thermite/Incendiary
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeTherm : S7_ThumperGrenade {
    default {
        Translation "112:127=184:191";
    }

    states {
    Loople:
        TNT1 A 0 {
            S7_ExplosionSound.CreateExplosion2 (pos);

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (96. * (1. + invoker.bonusDMGFactor)), 144, fulldamagedistance: 48);

            bool hitFloor = (pos.Z <= floorZ);
            bool hitCeiling = (pos.Z + height >= ceilingZ);

            let fireDefs = GetDefaultByType ('S7_ThumperGrenadeTherm_Fire');

            double projAngle = angle + 180;

            if (BlockingLine)
                projAngle = VectorAngle (BlockingLine.delta.X, BlockingLine.delta.Y) - 90.;

            let rng = S7_FastRNG.Create ();

            Array<double> angles, pitches;
            angles.Clear (); pitches.Clear ();

            int count = 150 + random [weaponSpc] (0, 10);
            angles.Grow (count); pitches.Grow (count);

            while (angles.Size () <= count) {
                double z0, z1;

                [z0, z1] = S7_Math.GenerateGaussianNoise (rng, 0, 80);

                angles.Push (z0);
                angles.Push (z1);

                [z0, z1] = S7_Math.GenerateGaussianNoise (rng, 60, 25);

                pitches.Push (-z0);
                pitches.Push (-z1);
            }

            for (; count > 0; count--) {
                Vector3 firePos = (
                    fRandom [weaponSpc] (-.025, .025),
                    fRandom [weaponSpc] (-.025, .025),
                    pos.Z
                );
                Vector3 fireVel;

                fireVel = S7_Math.GetAxisAngles (
                    projAngle + angles [count],
                    fRandom [weaponSpc] (-89.9, 89.9),
                    0
                );

                fireVel *= fRandom [weaponSpc] (20., 30.);

                if (hitCeiling && !hitFloor) {
                    firePos.Z = ceilingZ - (fireDefs.height + 1.);
                    fireVel.Z = -abs (fireVel.Z);
                } else if (hitFloor && !hitCeiling) {
                    firePos.Z = floorZ + fireDefs.height + 1.;
                    fireVel.Z = abs (fireVel.Z);
                }

                bool success; Actor act;
                [success, act] = A_SpawnItemEx ('S7_ThumperGrenadeTherm_Fire',
                    firePos.X, firePos.Y, 0,
                    fireVel.X, fireVel.Y, fireVel.Z,
                    0, SXF_AbsoluteVelocity | SXF_TransferPointers | SXF_NoCheckPosition
                );

                let fire = S7_Projectile (act);
                if (success && fire) {
                    fire.bonusDMGFactor = (1. + invoker.bonusDMGFactor);
                    fire.SetOrigin ((fire.pos.XY, firePos.Z), false);
                }
            }

            for (int i = random [sfx] (15, 25); i > 0; i--) {
                let act = S7_Smoke3 (Spawn ("S7_Smoke3", pos + (fRandom [sfx] (-25, 25), fRandom [sfx] (-25, 25), 0), ALLOW_REPLACE));

                act.A_SetRenderstyle (act.alpha, STYLE_TranslucentStencil);
                act.SetShade ("FFFFFF");
                act.scale = (0.325, 0.325);
                act.vel = (
                    fRandom [sfx] (-.15, .15),
                    fRandom [sfx] (.1, .5) * fRandomPick [sfx] (-1, 1),
                    fRandom [sfx] (-.5, .5)
                );
                act.fadeInTime = random [sfx] (2, 5);
                act.stayTime = 10;
                act.fadeOutTime = random [sfx] (17, ceil (TicRate * 1.25));
                act.targetAlpha = .5;
            }

            A_SetScale (1.0);
        }
        goto Explosion;

    Explosion:
        TNT1 A 17 {
            Gren_DoQuake ();
            let expl = S7_GenericExplosion (Spawn ('S7_GenericExplosion', pos, ALLOW_REPLACE));
            if (expl) {
                expl.target = self;
                expl.noSmoke = true;
            }
        }
        stop;
    }
}

class S7_ThumperGrenadeTherm_Fire_Smoke : S7_FireThinker_Smoke {
    default {
        Alpha 0.9;

        RenderStyle "stencil";
        StencilColor "FF FF FF";
    }

    override void PostBeginPlay () {
        chosenFrame = smokeRNG.GetInt (0, 24);

        double offsMax = fireSize / 3.;
        SetOrigin (Vec3Offset (
            smokeRNG.GetFloat (-offsMax, offsMax),
            smokeRNG.GetFloat (-offsMax, offsMax),
            smokeRNG.GetFloat (-offsMax, offsMax)
        ), false);

        if (pos.Z <= (floorZ + 1))
            SetZ (floorZ + 1);

        if ((pos.Z + height) < ceilingZ)
            vel.Z = smokeRNG.GetFloat (1.2, 4.);

        A_SetScale (smokeRNG.GetFloat (0.05, 0.065));
        scaleSpeed = 0.005;
        if (scale.X < 0)
            scaleSpeed = -scaleSpeed;

        alpha += smokeRNG.GetFloat (-0.1, 0.1);
        alphaSpeed = 0.05;

        roll = smokeRNG.GetFloat (0, 360);
        bSpriteFlip = smokeRNG.GetInt (0, 1);

        fadeTime = smokeRNG.GetInt (4, 10);
    }

    override void Tick () {
        if (isFrozen ())
            return;

        frame = chosenFrame;

        if (!(vel ~== (0, 0, 0))) {
            let newPos = level.Vec3Offset (pos, vel);
            bool xyPosEqual = (newPos.XY ~== pos.XY);

            if (xyPosEqual && !(vel.Z ~== 0)) {
                Prev.Z = pos.Z;
                SetZ (newPos.Z);
            } else if (!xyPosEqual)
                SetOrigin (pos + vel, true);
        }

        if (fadeTime > 0)
            fadeTime--;
        else if ((alpha -= alphaSpeed) < alphaSpeed) {
            Destroy ();
            return;
        }

        scale.X = scale.Y = scale.X + scaleSpeed;
    }
}

class S7_ThumperGrenadeTherm_Fire_Trail : S7_ThumperGrenadeTherm_Fire_Smoke {
    const FadeSpeed = 0.2;
    const ScaleSpeed = 0.002;

    override void PostBeginPlay () {
        chosenFrame = random [sfx] (0, 24);

        A_SetScale (0.0225);

        roll = fRandom [sfx] (0, 360);
        bSpriteFlip = random [sfx] (0, 1);
    }

    override void Tick () {
        if (isFrozen ())
            return;

        frame = chosenFrame;

        if (
            (alpha -= FadeSpeed) <= 0. ||
            (scale.Y = (scale.X -= ScaleSpeed)) < (ScaleSpeed * 2)
        ) {
            Destroy ();
            return;
        }
    }
}

class S7_ThumperGrenadeTherm_Fire_Fire : S7_FireThinker_Flame {
    override void PostBeginPlay () {
        double offsMax = fireSize / 3.;
        SetOrigin (Vec3Offset (
            flameRNG.GetFloat (-offsMax, offsMax),
            flameRNG.GetFloat (-offsMax, offsMax),
            flameRNG.GetFloat (-offsMax, offsMax)
        ), false);

        A_StartSound ("Fire/DoomCrackle", attenuation: 2);

        Destroy ();
    }

    states {
    Spawn:
        TNT1 A 1;
        stop;
    }
}

class S7_ThumperGrenadeTherm_Fire : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_Center;
        S7_Projectile.EffectStepMul -1;

        Radius 9;
        Height 8;
        Mass 0x7FFFFFFF;
        Gravity 4;
        RenderStyle "add";
        DamageFunction 0;
        DamageType 'ThermiteFire';

        MissileType 'S7_ThumperGrenadeTherm_Fire_Trail';

        +FORCEXYBILLBOARD +NODAMAGETHRUST +BLOODLESSIMPACT +HITTRACER
        +HITOWNER
        -NOGRAVITY
    }

    S7_FireThinker_BaseInfo info;
    int stepMulCounter;

    bool hitSomething;

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        info = new ('S7_FireThinker_BaseInfo');

        info.duration = int (TicRate * fRandom [weaponSpc] (12.5, 20.));
        info.fireSize = 24. * fRandom [weaponSpc] (0.85, 1.25);

        info.damage = 1;
        info.damageMul = 1. + bonusDMGFactor;
        info.damageDelay = 5;
        info.damageType = DamageType;

        info.smokeDelay = 4;
        info.smokeMinDensity = 0;
        info.smokeMaxDensity = 3;
        info.smokeActor = 'S7_ThumperGrenadeTherm_Fire_Smoke';

        info.flameMinDelay = TicRate * 8;
        info.flameMaxDelay = TicRate * 12;
        info.flameMinDensity = 1;
        info.flameMaxDensity = 1;
        info.flameActor = 'S7_ThumperGrenadeTherm_Fire_Fire';

        trailType = null;
        stepMulCounter = randomPick [S7_SmokeRNG] (4, 4, 4, 4, -1);
    }

    Class<Actor> trailType;
    override Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        if (!trailType)
            return null;

        Vector3 finalPos = level.Vec3Offset (initialPos, stepDiff);

        double realFloorZ = GetZAt (finalPos.X, finalPos.Y, flags: GZF_AbsolutePos | GZF_AbsoluteAng);

        if (finalPos.Z < realFloorZ)
            finalPos.Z = realFloorZ;

        Actor act = Spawn (trailType, finalPos, ALLOW_REPLACE);

        if (act)
            act.ClearInterpolation ();

        return act;
    }

    override void Tick () {
        Super.Tick ();

        if (--info.duration < 1) {
            Destroy ();
            return;
        }

        if (!self || bDestroyed || !info || hitSky)
            return;

        if (stepMulCounter > 0) {
            stepMulCounter--;
            switch (stepMulCounter) {
                case 2:
                    effectStepMul = (1. / 4.);
                    trailType = MissileName;
                    break;
                case 1:
                    effectStepMul = (1. / 5.);
                    trailType = MissileName;
                    break;
                case 0:
                    effectStepMul = (1. / 6.);
                    trailType = MissileName;
                    break;
            }
        }

        S7_StickToObject ();
    }

    const SmallMovementSpeed = 1. / 256.;
    void S7_StickToObject () {
        if (!tracer)
            tracer = BlockingMobj;

        if (S7_FireThinker.StickFromActor (self, target, tracer, info))
            Destroy ();
        else if (hitSomething) {
            tracer = BlockingMobj = null;
            bMissile = true;

            if (vel ~== (0, 0, 0)) {
                vel = (
                    fRandomPick [weaponSpc] (-SmallMovementSpeed, SmallMovementSpeed),
                    fRandomPick [weaponSpc] (-SmallMovementSpeed, SmallMovementSpeed),
                    -SmallMovementSpeed
                );
            }
        }
    }

    states {
    Spawn:
        THGR F 6 bright;
        wait;
    Death:
        TNT1 A 0 {
            A_ChangeLinkFlags (blockmap: false);

            bSpriteFlip = !!random [weaponSpc] (0, 1);
        }
        goto Loople;
    Loople:
        THGR F 1 bright;
        TNT1 A 0 { hitSomething = true; }
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Flare
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeFlare : S7_ThumperGrenade {
    meta color LightColor;
    property LightColor: LightColor;
    meta int LightIntensity;
    property LightIntensity: LightIntensity;

    default {
        S7_ThumperGrenadeFlare.LightColor "#72BAFF";
        S7_ThumperGrenadeFlare.LightIntensity 85.;
        DamageType 'TH_GrenadeImpact';
        Translation "112:127=80:95";

        Decal "";

        -NOGRAVITY
    }

    bool initialized;
    int maxTime;
    int time;
    PointLightAttenuated dynLight;

    override void PostBeginPlay () {
        time = maxTime = random [weaponSpc] (1025, 1050);

        if (!dynLight)
            dynLight = PointLightAttenuated (Spawn ('PointLightAttenuated', pos, NO_REPLACE)); // Spawn the dynamic light

        dynLight.target = self;
        dynLight.args [DynamicLight.Light_Red] = LightColor.r; // Color - Red
        dynLight.args [DynamicLight.Light_Green] = LightColor.g; // Color - Green
        dynLight.args [DynamicLight.Light_Blue] = LightColor.b; // Color - Blue
        dynLight.args [DynamicLight.Light_Intensity] = LightIntensity; // Size

        airburstRange = 0;

        A_StartSound ("Fire/Flare", slot: CHAN_7, flags: CHANF_Looping, volume: .15);
        initialized = true;
    }

    override void Tick () {
        Super.Tick ();

        if (dynLight) {
            dynLight.SetOrigin (pos, true);
            dynLight.target = self;

            double mult = Clamp (time / (maxTime * .65), 0., 1.);

            dynLight.args [DynamicLight.Light_Red] = int (LightColor.r * mult); // Color - Red
            dynLight.args [DynamicLight.Light_Green] = int (LightColor.g * mult); // Color - Green
            dynLight.args [DynamicLight.Light_Blue] = int (LightColor.b * mult); // Color - Blue
            dynLight.args [DynamicLight.Light_Intensity] = int (floor (S7_Math.Lerp (LightIntensity, LightIntensity * .8, 1. - mult)));
        }

        if (time > 0)
            time--;
    }

    override void OnDestroy () {
        if (dynLight)
            dynLight.Destroy ();
    }

    states {
    Spawn:
        THGR A 1 noDelay {
            if ((time <= 0 || !dynLight) && vel.Length () ~== 0.)
                return ResolveState ("RanOut");

            return ResolveState (null);
        }
        loop;

    Death:
        TNT1 A 0 {
            if (!initialized)
                PostBeginPlay ();

            A_SetGravity (1.0);
            bNoGravity = false;
            A_ChangeLinkFlags (blockmap: false);
        }
    Loople:
        THGR A 1 {
            if ((time <= 0 || !dynLight) && vel.Length () ~== 0.)
                return ResolveState ("RanOut");

            return ResolveState (null);
        }
        loop;

    RanOut:
        THGR B 1 {
            if (dynLight)
                dynLight.A_Remove (AAPTR_Default, RMVF_Everything);

            A_StopSound (CHAN_7);

            SpawnUsedShell ();
        }
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Clusterbomb
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeCluster : S7_ThumperGrenade {
    default {
        Translation "112:127=200:207";
    }

    states {
    Loople:
        TNT1 A 0 {
            S7_ExplosionSound.CreateExplosion2 (pos);

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (64. * (1. + invoker.bonusDMGFactor)), 96, fulldamagedistance: 32);

            double spawnZ = 0;
            double zMul = 1;
            double pitchMin = -22.5, pitchMax = 22.5;

            bool hitFloor = pos.z <= floorZ;
            bool hitCeil = pos.z + height >= ceilingZ;

            if (hitCeil && hitFloor) // Shouldn't really ever happen
                pitchMin = pitchMax = 0.;
            else if (hitCeil) {
                spawnZ = -2;
                pitchMin = 45;
                pitchMax = 45 + 22.5;
            } else if (hitFloor) {
                spawnZ = 2;
                pitchMin = -(5);
                pitchMax = -(5 + 22.5);
            }

            for (int i = random [weaponSpc] (24, 32); i > 0; i--) {
                let bomb = S7_Projectile (
                    A_SpawnProjectile ('S7_ThumperGrenadeCluster_Bomb', spawnZ, fRandom [weaponSpc] (-0.025, 0.025), fRandom [weaponSpc] (0, 359),
                        CMF_AimDirection | CMF_TrackOwner | CMF_AbsolutePitch,
                        fRandom [weaponSpc] (pitchMin, pitchMax)
                    )
                );

                if (bomb)
                    bomb.bonusDMGFactor = (1. + invoker.bonusDMGFactor);
            }

            A_SetScale (0.6);
        }
        goto Explosion;
    }
}

class S7_ThumperGrenadeCluster_Bomb : S7_Projectile {
    default {
        Radius 5;
        Height 5;
        Speed 30;
        DamageFunction (0);

        BounceCount 2;
        BounceSound "Bounce/MetalSmall";

        Scale 0.25;

        +BOUNCEONCEILINGS +BOUNCEONFLOORS +BOUNCEONWALLS +CANBOUNCEWATER
        +FORCEXYBILLBOARD
        -NOGRAVITY
    }

    states {
    Spawn:
        THGR G 1;
        loop;
    Bounce.Ceiling:
        TNT1 A 0 {
            bouncecount++;
        }
        goto Spawn;

    Death:
        XPL3 A         3 bright {
            bNoGravity = true;

            S7_ExplosionSound.CreateExplosion1 (pos);

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (fRandom [weaponSpc] (5., 6.) * (1. + invoker.bonusDMGFactor)), 32, fulldamagedistance: 32);

            A_SetScale (0.2);
        }
        XPL3 BCDEFGHIJ 3 bright;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Nailbomb
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeNail : S7_ThumperGrenade {
    default {
        Translation "112:127=[255,255,0]:[0,0,0]";
    }

    const AngleDiff = 20;

    states {
    Loople:
        TNT1 A 0 {
            S7_ExplosionSound.CreateExplosion2 (pos);

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (64. * (1. + invoker.bonusDMGFactor)), 96, fulldamagedistance: 32);

            double spawnZ = 0;
            double zMul = 1;
            double pitchMin = -22.5, pitchMax = 22.5;

            bool hitFloor = pos.z <= floorZ;
            bool hitCeil = pos.z + height >= ceilingZ;

            if (hitCeil && hitFloor) // Shouldn't really ever happen
                pitchMin = pitchMax = 0.;
            else if (hitCeil) {
                spawnZ = -2;
                pitchMin = 45;
                pitchMax = 45 + 22.5;
            } else if (hitFloor) {
                spawnZ = 2;
                pitchMin = -(5);
                pitchMax = -(5 + 22.5);
            }

            for (int i = random [weaponSpc] (64, 96); i > 0; i--) {
                let nail = S7_Projectile (
                    A_SpawnProjectile ('S7_ThumperGrenadeNail_Nail', spawnZ, fRandom [weaponSpc] (-0.025, 0.025), fRandom [weaponSpc] (0, 359),
                        CMF_AimDirection | CMF_TrackOwner | CMF_AbsolutePitch,
                        fRandom [weaponSpc] (pitchMin, pitchMax)
                    )
                );

                if (nail)
                    nail.bonusDMGFactor = (1. + invoker.bonusDMGFactor);
            }

            A_SetScale (0.8);
        }
        goto Explosion;
    }
}

class S7_ThumperGrenadeNail_Nail : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        Radius 2;
        Height 2;
        DamageFunction (fRandom [weaponDamage] (5., 10.) * (1. + bonusDMGFactor));
        Speed 1;

        +NOGRAVITY +BLOODSPLATTER +NOEXTREMEDEATH +NODAMAGETHRUST
        +RIPPER
    }

    states {
    Spawn:
        NAIL A 5 noDelay A_ScaleVelocity (400);
    Flight:
        TNT1 A 0 A_ChangeVelocity (0.0, 0.0, -0.5);
        NAIL AA 1 A_ScaleVelocity (0.99);
        NAIL A 1;
        loop;
    Death:
        NAIL A 250;
        NAIL A 1 A_FadeOut (0.03);
        wait;
    XDeath:
        TNT1 A 3 A_StartSound ("Bullet/HitFlesh", slot: CHAN_Body, volume: .5);
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Nerve gas
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeNGas : S7_ThumperGrenade {
    default {
        DamageType 'TH_GrenadeImpact';
        Translation "112:127=104:111";

        Decal "";
    }

    action void S7_DoDamage (int dmgMin, int dmgMax, double maxDist, double fullDmgDist, bool zeroMinDmg) {
        let sectorList = new ("S7_SectorList");
        sectorList.Sectors.Clear ();

        S7_ActorExtensions.S7_RecurseSectors (CurSector, sectorList, 0);

        bool randDMG = (dmgMin != dmgMax);

        Array<Actor> actorsDamaged; actorsDamaged.Clear ();
        int secCount = sectorList.Sectors.Size (), actorsDamagedCount = 0;
        for (int i = 0; i < secCount; i++) {
            Sector sec = sectorList.Sectors [i];

            for (Actor mo = sec.thinglist; mo; mo = mo.snext) {
                // Shouldn't happen.
                if (!mo)
                    continue;

                // Don't hurt non-monsters.
                if (!mo.bIsMonster && (!mo.player || mo.player.mo != mo))
                    continue;

                // Don't damage the same actor twice.
                if (actorsDamaged.Find (mo) != actorsDamagedCount)
                    continue;

                // Vulnerable actors can be damaged by radius attacks even if not shootable
                // Used to emulate MBF's vulnerability of non-missile bouncers to explosions.
                if (!(mo.bShootable || mo.bVulnerable))
                    continue;

                double dist = mo.Distance3D (self);
                if (dist > maxDist)
                    continue;

                double dmgFract = (1. - clamp (dist - fullDmgDist, 0., dist) * (1. / (maxDist - fullDmgDist)));
                int moDMG = int (max (
                    (randDMG ? fRandom [weaponDamage] (dmgMin, dmgMax) : dmgMin) * dmgFract,
                    !zeroMinDmg ? !!(random [weaponDamage] (0, 5)) : 0) * (1. + invoker.bonusDMGFactor)
                );
                if (moDMG <= 0)
                    continue;

                mo.DamageMobj (self, target, moDMG, damageType, DMG_Explosion);
                actorsDamaged.Push (mo);
                actorsDamagedCount++;
            }
        }
    }

    bool emittingGas;
    int time;

    action void S7_InitialGasBurst () {
        name origDMGType = damageType;

        bDontSplash = true;
        bNoDamageThrust = true;
        bBloodlessImpact = true;
        bForceRadiusDMG = true;
        A_SetDamageType ('NerveGas');

        S7_DoDamage (25, 30, 192., 80., false);

        for (int i = 0; i < 360; i += 25) {
            A_SpawnItemEx ('S7_ThumperGrenadeNGas_GasCloud_Trail', 0.0, 0.0, 1.0,  6.0, 0.0, 0.5, i, SXF_NoCheckPosition);
            A_SpawnItemEx ('S7_ThumperGrenadeNGas_GasCloud_Trail', 0.0, 0.0, 1.0,  3.0, 0.0, 0.5, i + 12.5, SXF_NoCheckPosition);
        }

        invoker.time = (2 * TicRate) - random [weaponSpc] (-10, 10);

        A_SetDamageType (origDMGType);
        bDontSplash = false;
        bNoDamageThrust = false;
        bBloodlessImpact = false;
        bForceRadiusDMG = false;
    }

    action void S7_EmitGas () {
        if (invoker.time < 1)
            return;

        name origDMGType = damageType;

        bDontSplash = true;
        bNoDamageThrust = true;
        bBloodlessImpact = true;
        bForceRadiusDMG = true;
        A_SetDamageType ('NerveGas');

        S7_DoDamage (3, 3, 1024., 512., false);
        A_SpawnItemEx ('S7_ThumperGrenadeNGas_GasCloud_Trail', 0.0, 0.0, 0.25, 0.0, 0.0, 3.5, 0, SXF_NoCheckPosition);
        invoker.time--;

        A_SetDamageType (origDMGType);
        bDontSplash = false;
        bNoDamageThrust = false;
        bBloodlessImpact = false;
        bForceRadiusDMG = false;
    }

    override void DoAirburst (Vector3 prevVel) {
        A_StartSound ("Steam/Burst", CHAN_Body);
        S7_InitialGasBurst ();
        emittingGas = true;
        projDetonated = true;

        vel = prevVel + (prevVel.XY.Unit () * 25, -GetGravity ());
    }

    states {
    Spawn:
        THGR A 1 noDelay {
            if (emittingGas)
                S7_EmitGas ();
        }
        loop;
    Death:
        TNT1 A 0 {
            A_Stop ();

            A_SetGravity (1.0);
            bNoGravity = false;

            A_ChangeLinkFlags (blockmap: false);

            return ResolveState ("Loople");
        }
        stop;
    Loople:
        THGR B 1 {
            A_SetGravity (1.0);

            if (!emittingGas)
                S7_InitialGasBurst ();
        }
    ActualLoople:
        THGR B 1 {
            if (time < 1)
                return ResolveState ("Die");

            S7_EmitGas ();

            return ResolveState (null);
        }
        loop;
    Die:
        THGR B 1 { SpawnUsedShell (); }
        stop;
    }
}

/** Nerve gas cloud trail **/
class S7_ThumperGrenadeNGas_GasCloud_Trail : S7_ShotSmoke {
    default {
        VSpeed 0;
        Scale 0.35;
        Alpha 1.0;
    }

    states {
    Spawn:
        SMK2 AABBCCDD 1 {
            if (scale.X <= 0)
                return ResolveState ("Die");

            A_SetScale (scale.X - 0.03);
            A_FadeOut (0.03);

            return ResolveState (null);
        }
        loop;
    Die:
        TNT1 A 0;
        stop;
    }
}