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
        for (int i = 0; i < count; i++) {
            let act = S7_A_SpawnSFX ('S7_HeatSmoke', offs: (35, random [S7_SmokeRNG] (4, 10), fRandom [S7_SmokeRNG] (9., 10.)));
            act.vel = (vel / 2.) + act.vel;
        }
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
            bool hitGeo = (BlockingType != S7_BLOCK_None && BlockingType != S7_BLOCK_Actor);

            Vector3 norm, orth0, orth1;

            if (hitGeo) {
                norm = GetGeoHitNormal ();

                if (norm == norm)
                    [orth0, orth1] = S7_Math.GetOrthoVecs (norm);
                else
                    Console.Printf ("NaN received from GetGeoHitNormal in S7_Draco_MassacreProjectile's Death state. This shouldn't happen.");
            }

            for (int i = 0; i < 8; i++) {
                Vector3 offs;
                Vector3 actVel;

                if (!hitGeo) {
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
                    offs = S7_Math.RandomHalfSphereVecFromNormal (norm, (fRandom [sfx] (-1, 1), fRandom [sfx] (-1, 1)), orth0, orth1);
                    actVel = S7_Math.RandomHalfSphereVecFromNormal (norm, (fRandom [sfx] (-1 , 1), fRandom [sfx] (-1, 1)), orth0, orth1);
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