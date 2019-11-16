version "3.3"

class S7_Draco_Massacre : S7_DracoWeapon {
    default {
        tag "$MASSACRERAILGUN";
        inventory.pickupMessage "$MASSACRERAILGUN";
        //weapon.ammoType1 "S7_PrettyShootyIonCannonGunMag";
        //weapon.ammoType2 "S7_Cells";
        weapon.ammoUse 0;
        weapon.ammoGive 0;
        S7_BaseWeapon.Icon "DMSCZ0";
        S7_BaseWeapon.ShortTag "$SHORTMASSACRERAILGUN";
    }

    double GetDamageBonus () {
        if (!Owner)
            return 0.;

        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys)
            return 0.;

        return pPawn.xpSys.GetStat (S7Stat_Tech, false) * 0.005;
    }

    action void DMSC_SpawnSmoke (int count) {
        for (int i = 0; i < count; i++)
            S7_A_SpawnSFX ('S7_HeatSmokeSpawner', offs: (0, random [S7_SmokeRNG] (4, 10), fRandom [S7_SmokeRNG] (9., 10.)));
            //A_FireProjectile ("S7_HeatSmokeSpawner", 0, 0, random [sfx] (4, 10), fRandom [sfx] (-8.0, -9.2));
    }

    const AnimLayer_ID = 2;

    action void S7_SetAnim (StateLabel animState) {
        S7_Internal_SetAnim (AnimLayer_ID, animState, 0, 0);
    }

    /** Pickup **/
    states {
    Spawn:
        DMSC Z -1;
        stop;
    }

    /** Animations **/
    states {
    Anim.Idle:
        DMSC A   12;
        DMSC BCDE 2;
        DMSC F    5;
        DMSC EDCB 2;
        loop;
    Anim.Fire:
        DMSC A 1 bright;
        DMSC A 1;
        wait;
    }

    /** Actions **/
    states {
    Ready:
    Ready2:
        TNT1 A 0 S7_SetAnim ("Anim.Idle");
    Ready2.SkipAnimSet:
        TNT1 A 1 S7_WeaponReady ("Reload", null, null);
        wait;

    Reload:
        DMSC A 5 TakeInventory ("S7_Reloading", 1);
        goto Ready2;

    Fire:
        DMSC A 1 {
            S7_SetAnim ("Anim.Fire");

            S7_A_FireBullets ('S7_Draco_MassacreProjectile', offs: (10, 4, 4.5), bonusDMGFactor: invoker.GetDamageBonus ());
            for (int i = 0; i < 4; i++)
                S7_A_SpawnSFX ('S7_ShotSmoke_2', offs: (15, 4 + fRandom [sfx] (-.5, .5), 4.5 + fRandom [sfx] (-.3, .3)));

            A_AlertMonsters ();
        }
        DMSC A 7 A_WeaponOffset (12, 32 + 9, WOF_Interpolate);
        DMSC A 1 {
            DMSC_SpawnSmoke (2);
            A_WeaponOffset (8, 32 + 6, WOF_Interpolate);
        }
        DMSC A 1 {
            DMSC_SpawnSmoke (2);
            A_WeaponOffset (4, 32 + 3, WOF_Interpolate);
        }
        DMSC A 1 {
            DMSC_SpawnSmoke (2);
            A_WeaponOffset (0, 32, WOF_Interpolate);
        }
        DMSC AAAAAAAA 2 DMSC_SpawnSmoke (5);
        goto Ready2;
    }
}

class S7_Draco_MassacreProjectile : S7_Projectile {
    int realDamage;

    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.interpMove false;
        S7_Projectile.EffectsStepsMode EFXStepMode_MapUnit;
        S7_Projectile.EffectStepInterval 10;

        radius 8;
        height 8;
        speed 20;
        renderStyle "add";
        scale 0.025;
        damageFunction (realDamage);
        damageType "DracoMassacre";
        missileType "S7_Draco_MassacreProjectileTrail";
        missileHeight 8;
        //decal "S7_IonCannon";

        +forceXYBillboard +forceRadiusDMG +bloodlessImpact
    }

    /*override Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        let act = super.StepEffects (initialPos, stepDiff, realVel);
        act.alpha = (abs (stepDiff.Length ()) / abs (realVel.Length ()));
        return act;
    }*/

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        vel = vel.Unit () * 650;
        realDamage = 50 + (random [weaponDamage] (0.0, 5.0) * 20);
    }

    static Vector3 GetGeoHitNormal (Actor act) {
        if (act.BlockingLine) {
            double ang = VectorAngle (act.BlockingLine.delta.X, act.BlockingLine.delta.Y);
            let norm = (AngleToVector (ang - 90, 1.), 0).Unit ();

            if (S7_Math.PointOnLineSidePrecise (act.pos.X, act.pos.Y, act.BlockingLine) == 1)
                norm = -norm;

            return norm;
        } else if (act.BlockingFloor)
            return act.BlockingFloor.floorPlane.normal;
        else if (act.BlockingCeiling)
            return act.BlockingCeiling.ceilingPlane.normal;

        if (act.pos.Z <= act.FloorSector.floorPlane.ZatPoint (act.pos.XY))
            return act.FloorSector.floorPlane.normal;
        else if ((act.pos.Z + act.height) >= act.CeilingSector.ceilingPlane.ZatPoint (act.pos.XY))
            return act.CeilingSector.ceilingPlane.normal;

        return (double.NaN, double.NaN, double.NaN);
    }

    clearscope static Vector3, Vector3 GetOrthoVecs (Vector3 vec) {
        if (vec == (0, 0, 0))
            return (0, 0, 0);
        else if (vec.XY == (0, 0))
            return (1, 1, 0).Unit ();

        Vector3 orth0 = (-vec.y, vec.x, 0).Unit ();
        Vector3 orth1 = (vec cross orth0).Unit ();
        Console.Printf ("vec: %f, %f, %f", vec.X, vec.Y, vec.Z);
        Console.Printf ("orth0: %f, %f, %f", orth0.X, orth0.Y, orth0.Z);
        Console.Printf ("orth1: %f, %f, %f", orth1.X, orth1.Y, orth1.Z);

        return orth0, orth1;
    }

    static Vector3 RandomOrthoHalfSphereVec (Vector3 vec, Vector3 orth0, Vector3 orth1) {
        if (vec ~== (0, 0, 0))
            return (0, 0, 0);

        Vector2 xy = (fRandom [sfx] (-1, 1), fRandom [sfx] (-1, 1));

        if (xy dot xy > 1)
            xy = xy.Unit ();

        double z = sqrt (1 - xy.x * xy.x - xy.y * xy.y);
        Vector3 ret = (z * vec + xy.x * orth0 + xy.y * orth1);
        if (ret ~== (0, 0, 0))
            return (0, 0, 0);

        return ret.Unit ();
    }
    states {
    Spawn:
        PLGF A 1 bright;
        PLGF A 1 bright {
            let swVel = vel.Unit () * 3.5;
            Actor sw; bool useless;
            [useless, sw] = A_SpawnItemEx ("S7_Draco_MassacreProjectileShockwave", flags: SXF_NoCheckPosition | SXF_Clientside);
            sw.vel = -swVel;
        }
        wait;

    Death:
        TNT1 A 3 {
            let norm = GetGeoHitNormal (self);
            Vector3 orth0, orth1;
            if (norm == norm)
                [orth0, orth1] = GetOrthoVecs (norm);
            else
                Console.Printf ("fuck");

            /*double minAngle, maxAngle;
            double minPitch, maxPitch;

            if (BlockingMobj) {
                minAngle = 0; maxAngle = 359.9999;
                minPitch = -90; maxPitch = 90;
            } else {
                double _discard;

                let norm = GetGeoHitConstraints (pos, CurSector, BlockingLine, BlockingFloor, BlockingCeiling);

                double normAngle, normPitch;
                [normAngle, normPitch] = S7_Math.GetVectorAngles (norm);
                let quat = S7_GM_Quaternion.CreateFromAngles (normAngle, normPitch, 0);

                let pitchQuat = S7_GM_Quaternion.CreateFromAngles ( 0, 90, 0);

                [minAngle, _discard, _discard] = quat.MultiplyQuat (S7_GM_Quaternion.CreateFromAngles (-90,   0, 0)).ToAngles ();
                [maxAngle, _discard, _discard] = quat.MultiplyQuat (S7_GM_Quaternion.CreateFromAngles ( 90,   0, 0)).ToAngles ();
                [_discard, minPitch, _discard] = quat.MultiplyQuat (S7_GM_Quaternion.CreateFromAngles (  0,  90, 0)).ToAngles ();
                [_discard, maxPitch, _discard] = quat.MultiplyQuat (S7_GM_Quaternion.CreateFromAngles (  0, -90, 0)).ToAngles ();
                Console.Printf ("angles: %f, %f", minAngle, maxAngle);
                Console.Printf ("pitches: %f, %f", minPitch, maxPitch);

                quat.Destroy ();
                pitchQuat.Destroy ();
            }*/

            for (int i = 0; i < 8; i++) {
                Vector3 offs;
                Vector3 actVel;

                if (BlockingMobj || norm != norm) {
                    offs = S7_Math.Vec3FromAngle (
                        fRandom [sfx] (0, 360),
                        fRandom [sfx] (-90, 90),
                        1
                    );

                    actVel = S7_Math.Vec3FromAngle (
                        fRandom [sfx] (0, 360),
                        fRandom [sfx] (-90, 90),
                        1
                    );
                } else {
                    offs = RandomOrthoHalfSphereVec (norm, orth0, orth1);
                    actVel = RandomOrthoHalfSphereVec (norm, orth0, orth1);
                }

                offs *= fRandom [sfx] (0, 15);
                actVel *= fRandom [sfx] (0.25, 2.5);

                let actPos = level.Vec3Offset (pos, offs);

                let act = Spawn ('S7_Draco_MassacreExpSmoke', actPos);
                act.vel = actVel;
            }

            A_Explode (350, 256, fulldamagedistance: 96);
        }
        stop;
    }
}

class S7_Draco_MassacreProjectileTrail : S7_TracerEffectsBase {
    default {
        renderStyle "add";
        scale 0.025;
    }

    states {
    Spawn:
        PLGF A 2 bright;
        PLGF A 1 A_FadeOut (1. / (35. * .25));
        wait;
    }
}

class S7_Draco_MassacreProjectileShockwave : S7_FastProjTrailBase {
    default {
        renderStyle "add";
        scale 0.25;
        alpha 1.0;

        +noInteraction
    }

    states {
    Spawn:
        SSHK ABCDEFGHIJKL 1 A_FadeOut (0.08182);
        stop;
    }
}

class S7_Draco_MassacreExpSmoke : S7_HeatSmoke {
    default {
        renderStyle "add";
        scale 1.0;
        alpha 1.0;

        +rollSprite
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_SetRoll (fRandom [sfx] (0, 360));
            return A_Jump (256, "FrameA", "FrameB", "FrameC", "FrameD");
        }
        wait;

    FrameA: DMSE A 0; goto Loople;
    FrameB: DMSE B 0; goto Loople;
    FrameC: DMSE C 0; goto Loople;
    FrameD: DMSE D 0; goto Loople;

    Loople:
        "####" "#" 1 bright {
            A_FadeOut (0.05);
            A_SetScale (scale.X + 0.02);
        }
        loop;
    }
}