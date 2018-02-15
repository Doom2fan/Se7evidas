extend class S7_DracoPlayer {
    const MaxDefMatEnergy = 500;
    int defenseMatrixEnergy;
    int dmEnergyRegenTime;
    int laserCooldown;

    void Tick_DefenseMatrix () {
        if (laserCooldown > 0)
            laserCooldown--;

        if (defenseMatrixEnergy > MaxDefMatEnergy)
            defenseMatrixEnergy = MaxDefMatEnergy;
        else if (defenseMatrixEnergy < MaxDefMatEnergy && !dmEnergyRegenTime) {
            defenseMatrixEnergy = min (defenseMatrixEnergy + 5, MaxDefMatEnergy);
            dmEnergyRegenTime = 17;
        } else if (dmEnergyRegenTime > 0)
            dmEnergyRegenTime--;

        if (defenseMatrixEnergy > 0) {
            ThinkerIterator actorFinder = ThinkerIterator.Create ("Actor", Thinker.STAT_DEFAULT);

            Actor mo;
            while (mo = Actor (actorFinder.Next ())) {
                if (mo is "S7_EffectsBase" || !mo.bMissile || mo.bKilled || !mo.target || mo.target == self || isFriend (mo.target))
                    continue;

                if (defenseMatrixEnergy >= 5 && abs (Distance3D (mo)) <= 160.0 && !(random [dracoADM] (0, 256) < 8)) {
                    let zap = Spawn ("S7_DracoADMZap", mo.pos, ALLOW_REPLACE);
                    zap.target = self;
                    mo.ExplodeMissile (NULL, zap, false);

                    defenseMatrixEnergy -= 5;
                    continue;
                }

                if (defenseMatrixEnergy >= 6 && !laserCooldown && !(random [dracoADM] (0, 256) < 16)) {
                    if (mo.bSeekerMissile && mo.tracer == self && abs (mo.Distance2D (mo.target)) >= (mo.target.radius * 1.5)) {
                        laserCooldown = 0;

                        if (defenseMatrixEnergy >= 3 && FireLaser (mo, -5)) {
                            laserCooldown += 5;
                            defenseMatrixEnergy -= 3;
                        }
                        if (defenseMatrixEnergy >= 3 && FireLaser (mo,  5)) {
                            laserCooldown += 5;
                            defenseMatrixEnergy -= 3;
                        }
                    }
                }
            }
        }
    }

    bool FireLaser (Actor mo, double xy_off) {
        if (!mo)
            return false;

        double angCos = cos (angle), angSin = sin (angle);
        let misPos = mo.pos + (0, 0, mo.height / 2);
        let laserStartPos = pos + (xy_off * angCos, xy_off * angSin, 50);

        Vector3 aimPos = S7_Math.CalculateInterceptShotPosition (laserStartPos, misPos, mo.vel, 350);

        if (!(aimPos.x == aimPos.x && aimPos.y == aimPos.y && aimPos.z == aimPos.z))
            return false;

        let marker = Spawn ("S7_DracoADMLaserMarker", aimPos);
        if (marker) {
            let oldTracer = tracer;

            marker.A_SetSize (mo.radius, mo.height, false);
            tracer = marker;

            if (!CheckLOF (CLOFF_FromBase, offsetheight: 50, offsetwidth: xy_off, ptr_target: AAPTR_Tracer)) {
                marker.SetOrigin (mo.pos, false);

                if (CheckLOF (CLOFF_FromBase, offsetheight: 50, offsetwidth: xy_off, ptr_target: AAPTR_Tracer))
                    aimPos = mo.pos;
                else {
                    tracer = oldTracer;
                    return false;
                }
            }

            tracer = oldTracer;
            marker.Destroy ();
        } else
            return false;

        let aimDiff = level.Vec3Diff (laserStartPos, aimPos);
        double fAngle = VectorAngle (aimDiff.x, aimDiff.y), fPitch = -VectorAngle (aimDiff.xy.Length (), aimDiff.z);

        let laser = A_SpawnProjectile ("S7_DracoADMLaser", 50, xy_off, fAngle, CMF_AimDirection | CMF_AbsoluteAngle | CMF_AbsolutePitch, fPitch);

        if (laser)
            laser.tracer = mo;

        return true;
    }
}

class S7_DracoADMZap : S7_DebrisGeneral {
    default {
        renderStyle "add";
        alpha 1.0;
        scale 0.5;

        +thruActors
    }

    states {
    Spawn:
        TNT1 A 0 A_Jump (256, "FrameA", "FrameB", "FrameC", "FrameD", "FrameE");
        wait;

    FrameA: ZAP1 A 0 { return ResolveState ("Anim"); }
    FrameB: ZAP1 B 0 { return ResolveState ("Anim"); }
    FrameC: ZAP1 C 0 { return ResolveState ("Anim"); }
    FrameD: ZAP1 D 0 { return ResolveState ("Anim"); }
    FrameE: ZAP1 E 0 { return ResolveState ("Anim"); }

    Anim:
        #### # 2 bright {
            int spawnCount = random [sfx] (4, 7);

            for (int i = 0; i < spawnCount; i++) {
                double spd = fRandom [sfx] (-5.0, 5.0);
                double ang = fRandom [sfx] (0, 360);

                A_SpawnItemEx ("S7_DracoADMZapSparks", fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (-2.0, 2.0),
                    spd * cos (ang), spd * sin (ang), fRandom [sfx] (1.5, 3.0), flags: SXF_NoCheckPosition | SXF_Clientside | SXF_SetTarget);
            }
        }
        stop;
    }
}

class S7_DracoADMZapSparks : S7_DebrisGeneral {
    default {
        renderStyle "add";
        alpha 1.0;
        gravity 0.25;

        +thruActors -noGravity
    }

    states {
    Spawn:
        TNT1 A 0 A_Jump (256, "Frame1", "Frame2", "Frame3");
        wait;

    Frame1: PLSE B 0 { return ResolveState ("Anim"); }
    Frame2: PLSE C 0 { return ResolveState ("Anim"); }
    Frame3: PLSE D 0 { return ResolveState ("Anim"); }

    Anim:
        #### # 2 bright A_SetScale (fRandom [sfx] (0.08, 0.25) * randomPick [sfx] (1, -1));
        #### # 1 bright A_FadeOut (0.05);
        wait;
    }
}

class S7_DracoADMLaser : S7_BaseTracer {
    default {
        S7_Projectile.MovementMode OldFastProj;
        damageFunction (fRandom [weaponDamage] (1.0, 4.0));
        speed 350;
        damageType "LaserTracer";
        scale 0.015;
        missileType "S7_LaserTracerTrail";
        decal "S7_LaserDecal";

        -bloodSplatter
    }

    override void Effect () {
        super.Effect ();

        if (tracer && S7_Math.CheckActorCollision (self, tracer)) {
            tracer.ExplodeMissile (NULL, self, false);
            ExplodeMissile (NULL, tracer);
        }
    }

    states {
    Spawn:
        TNT1 A 0;
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

class S7_DracoADMLaserMarker : S7_PositionMarker {
    default {
        radius 20;
        height 16;

        +shootable
        -noBlockmap -noInteraction -noClip
    }
}