//-------------------------------------------------------------------------------------------
//
// Projectile base
//
//-------------------------------------------------------------------------------------------
class S7_TraceResults_Encapsulated { TraceResults Results; }
class S7_Projectile_Trace : LineTracer {
    S7_Projectile sourceActor;
    Array<Actor> actorsToIgnore;
    Array<S7_TraceResults_Encapsulated> hits;
    TraceResults RealResults;
    int pushTime;

    play bool HitActor_Missile (S7_TraceResults_Encapsulated hit) {
        let mo = hit.Results.HitActor;

        int damage;

        if (mo.bNonShootable) // Check for a non-shootable mobj
            return false;
        if (mo.bGhost && sourceActor.bThruGhost) // Check for passing through a ghost
            return false;

        if (mo.bCorpse && sourceActor.bRipper && !mo.bShootable) // Check for rippers passing through corpses
            return false;

        double clipheight;

        if (mo.projectilepassheight > 0)
            clipheight = mo.projectilepassheight;
        else
            clipheight = mo.Height;

        // Check if it went over / under
        if (sourceActor.pos.Z > mo.pos.Z + clipheight) // Over mo
            return false;
        if ((sourceActor.pos.Z + sourceActor.height) < mo.pos.Z) // Under mo
            return false;

        // [RH] What is the point of this check, again? In Hexen, it is unconditional, but here we only do it if
        // the missile's damage is 0. MBF bouncer might have a non-0 damage value, but they must not deal damage
        // on impact either.
        if (sourceActor.bBounceOnActors && (sourceActor.IsZeroDamage () || !sourceActor.bMissile))
            return (sourceActor.target == mo || !mo.bSolid);

        switch (sourceActor.SpecialMissileHit (mo)) {
            case 0:     return true;
            case 1:     return false;
            default:    break;
        }

        // [RH] Extend DeHacked infighting to allow for monsters to never fight each other
        if (sourceActor.target) {
            if (mo == sourceActor.target) // Don't missile self
                return false;
        }
        if (!mo.bShootable) // Didn't do any damage
            return !mo.bSolid;
        if (mo.bSpectral && !sourceActor.bSpectral)
            return false;

        if (S7_ActorExtensions.CanRip (mo, sourceActor)) {
            if (!mo.bNoBlood && !mo.bReflective && sourceActor.bBloodlessImpact && !mo.bInvulnerable && !mo.bDormant)
                S7_ActorExtensions.RipperBlood (sourceActor, mo);

            mo.A_PlaySound ("misc/ripslop", CHAN_Body, 1, attenuation: ATTN_Idle);

            // Do poisoning (if using new style poison)
            if (sourceActor.PoisonDamage > 0 && sourceActor.PoisonDuration != int.min)
                mo.PoisonMobj (sourceActor, sourceActor.target, sourceActor.PoisonDamage, sourceActor.PoisonDuration, sourceActor.PoisonPeriod, sourceActor.PoisonDamageType);

            damage = sourceActor.GetMissileDamage (3, 2);

            int newdam = mo.DamageMobj (sourceActor, sourceActor.target, damage, sourceActor.DamageType);

            if (!sourceActor.bBloodlessImpact)
                mo.TraceBleed (newdam > 0 ? newdam : damage, sourceActor);

            if (mo.bPushable && !sourceActor.bCannotPush) {
                if (mo.lastPush != pushTime) { // Push thing
                    mo.vel += sourceActor.vel.XY * mo.pushFactor;
                    mo.lastPush = pushTime;
                }
            }
            return false;
        }

        // Do poisoning (if using new style poison)
        if (sourceActor.PoisonDamage > 0 && sourceActor.PoisonDuration != int.min)
            mo.PoisonMobj (sourceActor, sourceActor.target, sourceActor.PoisonDamage, sourceActor.PoisonDuration, sourceActor.PoisonPeriod, sourceActor.PoisonDamageType);

        // Do damage
        damage = sourceActor.GetMissileDamage (sourceActor.bStrifeDamage ? 3 : 7, 1);
        if ((damage > 0) || sourceActor.bForcePain || sourceActor.bCausePain) {
            int newdam = mo.DamageMobj (sourceActor, sourceActor.target, damage, sourceActor.DamageType);

            if (damage > 0) {
                if (sourceActor.bBloodsplatter && !mo.bNoBlood && !mo.bReflective && !mo.bInvulnerable && !mo.bDormant && !sourceActor.bBloodlessImpact &&
                    (random [CheckThing] () < 192))
                    mo.BloodSplatter (sourceActor.pos, sourceActor.AngleTo (mo));
                if (!sourceActor.bBloodlessImpact)
                    mo.TraceBleed (newdam > 0 ? newdam : damage, sourceActor);
            }
        }
        else
            mo.GiveBody (-damage);

        if (mo.bThruReflect && mo.bReflective && sourceActor.bMissile) {
            if (sourceActor.bSeekerMissile)
                sourceActor.tracer = sourceActor.target;

            sourceActor.target = mo;

            return false;
        }

        return true;       // don't traverse any more
    }

    play bool HitActor (S7_TraceResults_Encapsulated hit) {
        Console.PrintF ("BBBB");
        if (sourceActor.bThruActors)
            return false;

        let mo = hit.Results.HitActor;

        if (actorsToIgnore.Size () > 0) {
            for (int i = 0; i < actorsToIgnore.Size (); i++) {
                if (mo == actorsToIgnore [i])
                    return false;
            }
        }

        if (mo != sourceActor && (sourceActor.bMissile && mo != sourceActor.Target)) {
            if (!(mo.bSolid || mo.bSpecial || mo.bShootable) || mo.bTouchy)
                return false;
            if (mo.bThruActors || (sourceActor.bThruSpecies && sourceActor.target && mo.GetSpecies () == sourceActor.target.GetSpecies ()))
                return false;

            if (mo.bSolid || (mo.bTouchy || mo.bBumpSpecial) && 
                ((sourceActor.bSolid || sourceActor.bMissile) || sourceActor.bBlasted || sourceActor.bBlockedBySolidActors || sourceActor.bMBFBouncer)
            ) {
                if (!sourceActor.CanCollideWith (mo, false) || !mo.CanCollideWith (sourceActor, true))
                    return false;
            }

            if (sourceActor.bMissile || (sourceActor.bMBFBouncer && !sourceActor.bSolid))
                return HitActor_Missile (hit);
        } else
            return false;

        return false;
    }
    
    override ETraceStatus TraceCallback () {
        /*if (!sourceActor)
            return TRACE_Skip;*/

        let hit = new ("S7_TraceResults_Encapsulated");
        hit.Results = Results;
        hits.Push (hit);
        Console.PrintF ("%d", hit.Results.HitType);

        switch (Results.HitType) {
            case TRACE_HitWall:
                if (Results.Tier == TIER_Upper || Results.Tier == TIER_Lower)
                    return TRACE_Stop;

                let hl = Results.HitLine;
                if (sourceActor.bMissile && (hl.flags & (Line.ML_BLOCKPROJECTILE | Line.ML_BLOCKEVERYTHING)))
                    return TRACE_Skip;
                
                if (sourceActor.bMissile && Results.Tier == TIER_Middle && (hl.flags & Line.ML_BLOCKING) && (hl.flags & Line.ML_TWOSIDED))
                    return TRACE_Skip;
                
                if ((hl.flags & Line.ML_BLOCKING) || (hl.flags & Line.ML_BLOCKEVERYTHING) || (sourceActor.bIsMonster && (hl.flags & Line.ML_BLOCKMONSTERS)))
                    return TRACE_Stop;
            break;

            case TRACE_HitFloor:
            case TRACE_HitCeiling:
                return TRACE_Stop;
        }

        return TRACE_Skip;
    }

    // Dem hacks.
    play bool PerformTrace (vector3 start, Sector sec, vector3 direction, double maxDist, ETraceFlags traceFlags) {
        hits.Clear ();
        // Perform the trace
        Trace (start, sec, direction, maxDist, traceFlags);

        bool hitSomething = false;

        S7_TraceResults_Encapsulated hit = null;
        for (int i = 0; i < hits.Size (); i++) {
            hit = hits [i];

            Console.PrintF ("%d", hit.Results.HitType);
            if (hit.Results.HitType == TRACE_HitActor) {
                if (HitActor (hit)) {
                    hitSomething = true;
                    break;
                } else
                    continue;
            } else if (hit.Results.HitType == TRACE_HitFloor || hit.Results.HitType == TRACE_HitCeiling) {
                hitSomething = true;
                break;
            } else if (hit.Results.HitType == TRACE_HitWall) {
                if (hit.Results.Tier == TIER_Upper || hit.Results.Tier == TIER_Lower) {
                    hitSomething = true;
                    break;
                }

                let hl = hit.Results.HitLine;
                if (sourceActor.bMissile && (hl.flags & (Line.ML_BLOCKPROJECTILE | Line.ML_BLOCKEVERYTHING))) {
                    hitSomething = true;
                    break;
                }
                
                if (sourceActor.bMissile && hit.Results.Tier == TIER_Middle && (hl.flags & Line.ML_BLOCKING) && (hl.flags & Line.ML_TWOSIDED))
                    continue;
                
                if ((hl.flags & Line.ML_BLOCKING) || (hl.flags & Line.ML_BLOCKEVERYTHING) || (sourceActor.bIsMonster && (hl.flags & Line.ML_BLOCKMONSTERS))) {
                    hitSomething = true;
                    break;
                }
            }
        }

        if (hit)
            RealResults = hit.Results;

        return hitSomething;
    }
}

/// The base type for all S7 projectiles
class S7_Projectile : FastProjectile {
    enum EMovementMode {
        Normal = 0, /// The projectile uses the normal movement code.
        FastProjectile, /// The projectile is a FastProjectile.
        OldFastProj, /// The projectile is a FastProjectile and uses GZDoom's code.
    };
    /// Determines how to detect collisions. Only used for EMovementMode.FastProjectile.
    enum EFPCollisionMode {
        ColMode_Center      = 1, /// Check the center for collision
        ColMode_Corners     = 1 << 1, /// Check the corners for collision
        ColMode_EdgeCenters = 1 << 2, /// Check the center of the edges for collision.
    };

    int moveMode;
    int fpCollisionMode;
    bool interpFastProj;
    double effectStepMul;

    /// Which movement code to use.
    property MovementMode: moveMode;
    /// How to detect collisions. Only used by EMovementMode.FastProjectile.
    property FastProjCollision: fpCollisionMode;
    /// Changes how many times StepEffects is called. Only used by EMovementMode.FastProjectile.
    property EffectStepMul: effectStepMul;
    /// Whether to interpolate the projectile's movement. Only used by EMovementMode.FastProjectile.
    property InterpMove: interpFastProj;

    default {
        S7_Projectile.MovementMode Normal;
        S7_Projectile.FastProjCollision ColMode_EdgeCenters;
        S7_Projectile.InterpMove true;
        S7_Projectile.EffectStepMul 0.125;

        Projectile;
    }

    S7_Projectile_Trace tr;

    override void Tick () {
        switch (moveMode) {
            case Normal:
                Actor.Tick ();
            break;

            case FastProjectile:
                NewFastProjTick ();
            break;

            case OldFastProj:
                Super.Tick ();
            break;
        }
    }

    virtual Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        class<Actor> trail = MissileName;

        if (trail != null) {
            Vector3 finalPos = initialPos + stepDiff;

            Actor act = Spawn (trail, initialPos, ALLOW_REPLACE);
            act.SetOrigin (finalPos, false);

            double hitz = finalPos.z - 8;
            if (hitz < act.floorz)
                hitz = act.floorz;
            // Do not clip this offset to the floor.
            hitz += missileHeight;

            act.SetOrigin ((finalPos.xy, hitz), false);

            if (act != null) {
                if (bGetOwner && target != null)
                    act.target = target;
                else
                    act.target = self;
                
                act.angle = angle;
                act.pitch = pitch;
            }

            return act;
        }

        return NULL;
    }

    void SpawnEffects (Vector3 initialPos, double dist, Vector3 stepSize) {
        if (radius <= 0 || dist <= 0)
            return;

        int count = 8;
        while (abs (stepSize.X) > radius * count || abs (stepSize.Y) > radius * count)
            count += count;

        Vector3 frac = stepSize / count;

        int spawnCount = int (count * effectStepMul);
        for (int i = 0; i < count; i++) {
            double diff = abs ((frac * i).Length ());

            if (diff >= dist)
                break;

            if (--spawnCount <= 0) {
                spawnCount = int (count * effectStepMul);
                StepEffects (initialPos, frac * i, stepSize);
            }
        }
    }

    static const double FPColOffs [] = { // Y and Z, not X and Y.
        // Edge centers
         0, 1.0,
         1, 0.5,
         0, 0.0,
        -1, 0.5,
        // Corners
         1, 1,
         1, 0,
        -1, 0,
        -1, 1,
        // Center
        0, 0.5
    };
    virtual void NewFastProjTick () {
        ClearInterpolation ();
        let oldPos = pos;
        let oldVel = vel;

        if (!bNoTimeFreeze && (globalfreeze || level.Frozen))
            return;

        if (Vel != (0, 0, 0) || (pos.Z != floorz)) {
            if (!tr) { tr = new ("S7_Projectile_Trace"); tr.sourceActor = self; }
            tr.actorsToIgnore.Clear ();

            let velUnit = vel.Unit ();
            double velAngle = VectorAngle (velUnit.x, velUnit.y);
            double s = sin (velAngle);
            double c = cos (velAngle);

            bool collisionHandled;
            do {
                double maxDist = abs (vel.Length ()) + radius + height;
                int colFlags = (fpCollisionMode & (ColMode_Center | ColMode_Corners | ColMode_EdgeCenters));
                bool collided;

                int iMax = FPColOffs.Size () / 2;
                for (int i = 0; i < iMax; i++) {
                    if ((i >= 0 && i <= 3) && !(colFlags & ColMode_EdgeCenters))
                        continue;
                    else if ((i >= 4 && i <= 7) && !(colFlags & ColMode_Corners))
                        continue;
                    else if ((i == 8) && !(colFlags & ColMode_Center))
                        continue;
                    double yOffs = radius * FPColOffs [i * 2];

                    if (tr.PerformTrace (Vec3Offset (s * yOffs, c * yOffs, height * FPColOffs [i * 2 + 1]), curSector, velUnit, maxDist, 0)) {
                        if (collisionHandled = HandleCollision (oldPos, oldVel))
                            return;
                    }
                }

                if (!collided) {
                    tr.actorsToIgnore.Clear ();
                    collisionHandled = true;
                }
            } while (tr.actorsToIgnore.Size () > 0 && !collisionHandled);

            SetOrigin (pos + vel, true);
            SpawnEffects (oldPos, oldVel.Length (), oldVel);

            vel.z += GetGravity ();

            UpdateWaterLevel ();
            CheckPortalTransition ();
        }

        // freed itself
        if (!CheckNoDelay ())
            return;
        // Advance the state
        if (tics != -1) {
            if (tics > 0)
                tics--;

            while (!tics) {
                if (!SetState (CurState.NextState)) // mobj was removed
                    return;
            }
        }
    }

    bool HandleCollision (Vector3 oldPos, Vector3 oldVel) {
        if (abs (level.Vec3Diff (oldPos, tr.RealResults.hitPos).Length ()) > abs (oldVel.Length ()) + radius)
            return false;

        double maxDist = abs (oldVel.Length ());
        double hitPosDist = abs (tr.RealResults.hitPos.Length ());
        let hitPos = tr.RealResults.HitPos;
        hitPos += (-oldVel.Unit () * radius * 1.5);
        SetOrigin (hitPos, interpFastProj);

        if (!bSkyExplode) {
            if (tr.RealResults.HitType == TRACE_HitWall && tr.RealResults.HitLine) {
                let l = tr.RealResults.HitLine;
                if (l.backsector && l.backsector.GetTexture (sector.ceiling) == skyflatnum) {
                    let posr = PosRelative (l.backsector);
                    if (pos.Z >= l.backsector.ceilingplane.ZatPoint (posr.XY)) {
                        SpawnEffects (oldPos, tr.RealResults.Distance, oldVel); 
                        Destroy ();  // Hack to prevent missiles exploding against the sky.
                        return true; // Does not handle sky floors.
                    }
                }

                // [RH] Don't explode on horizon lines.
                if (l && l.special == Line_Horizon) {
                    SpawnEffects (oldPos, tr.RealResults.Distance, oldVel);
                    Destroy ();
                    return true;
                }
            } else if ((tr.RealResults.HitType == TRACE_HitFloor && floorpic == skyflatnum) ||
                (tr.RealResults.HitType == TRACE_HitCeiling && ceilingpic == skyflatnum)) {
                SpawnEffects (oldPos, tr.RealResults.Distance, oldVel);
                Destroy ();
                return true;
            }
        }

        if (tr.RealResults.HitType == TRACE_HitFloor)
            hitPos = tr.RealResults.HitPos;
        else if (tr.RealResults.HitType == TRACE_HitCeiling) {
            hitPos = tr.RealResults.HitPos;
            hitPos -= (0, 0, height);
        }

        SpawnEffects (oldPos, level.Vec3Diff (oldPos, pos).Length (), oldVel);
        if (!TryMove (tr.RealResults.HitPos.xy, true)) {
            SetOrigin (hitPos, interpFastProj);
            ExplodeMissile (BlockingLine, BlockingMobj);
            return true;
        } else if (tr.RealResults.HitType == TRACE_HitActor && tr.RealResults.HitActor)
            tr.actorsToIgnore.Push (tr.RealResults.HitActor);
        else {
            let rHitPos = tr.RealResults.HitPos;
            if ((tr.RealResults.HitType == TRACE_HitFloor && rHitPos.z - floorZ <= 1) ||
                (tr.RealResults.HitType == TRACE_HitCeiling && ceilingZ - (rHitPos.z + height) <= 1)) {
                if (tr.RealResults.HitType == TRACE_HitFloor)
                    HitFloor ();

                SetOrigin (hitPos, interpFastProj);
                ExplodeMissile (BlockingLine, BlockingMobj);
                return true;
            }
        }

        SetOrigin (oldPos, false);
        return false;
    }
}