//-------------------------------------------------------------------------------------------
//
// Projectile bases
//
//-------------------------------------------------------------------------------------------
class S7_FireballBase : S7_Projectile {
    default {
        S7_Projectile.MovementMode Normal;
        Radius 6;
        Height 16;
        Speed 15;
        FastSpeed 20;
        Damage 8;
        RenderStyle "add";
        Alpha 1.0;
        SeeSound "baron/attack";
        DeathSound "baron/shotx";
        Decal "BaronScorch";

        +RANDOMIZE
    }
}

//-------------------------------------------------------------------------------------------
//
// Misc bases
//
//-------------------------------------------------------------------------------------------
/** Monster spawner base
*** Usage: Works exactly like RandomSpawner, except you can override MS_GetMonsterSpawnList to change the spawner's behaviour.
*** Virtuals:
***     void PostSpawn (Actor spawned): Called when the actor is finished spawning. (From RandomSpawner)
***     DropItem MS_GetMonsterSpawnList (): called when getting the monster spawn list. (From S7_MonsterSpawner)
**/
// 99% of this is taken from the normal RandomSpawner code. I wouldn't need to do this if GetDropItems was a virtual function :V
class S7_MonsterSpawner : RandomSpawner {
    virtual class<Actor> MS_GetMonsterSpawnList () { return null; }

    // Literally the only reason we're even overriding this is because we can't override GetDropItems.
    override void BeginPlay () {
        if (bouncecount >= MAX_RANDOMSPAWNERS_RECURSION) { // Prevents infinite recursions
            Spawn ("Unknown", Pos, NO_REPLACE); // Show that there's a problem.
            Destroy ();
            return;
        }

        let actClass = MS_GetMonsterSpawnList ();
        if (actClass != null) {
            DoSpawnActor (actClass);
            return;
        }

        DropItem di;   // di will be our drop item list iterator
        DropItem drop; // while drop stays as the reference point.
        int n = 0;
        bool nomonsters = sv_nomonsters || level.nomonsters;

        drop = di = GetDropItems ();
        if (di != null) {
            while (di != null) {
                if (di.Name != 'None') {
                    if (!nomonsters || !IsMonster (di)) {
                        int amt = di.Amount;
                        if (amt < 0) amt = 1; // default value is -1, we need a positive value.
                        n += amt; // this is how we can weight the list.
                    }
                    di = di.Next;
                }
            }
            if (n == 0) { // Nothing left to spawn. They must have all been monsters, and monsters are disabled.
                Destroy ();
                return;
            }
            // Then we reset the iterator to the start position...
            di = drop;
            // Take a random number...
            n = random [randomspawn] (0, n - 1);
            // And iterate in the array up to the random number chosen.
            while (n > -1 && di != null) {
                if (di.Name != 'None' && (!nomonsters || !IsMonster (di))) {
                    int amt = di.Amount;
                    if (amt < 0) amt = 1;
                    n -= amt;
                    if ((di.Next != null) && (n > -1))
                        di = di.Next;
                    else
                        n = -1;
                }
                else
                    di = di.Next;
            }

            // So now we can spawn the dropped item.
            if (di == null) {
                Spawn ("Unknown", Pos, NO_REPLACE); // Show that there's a problem.
                Destroy ();
                return;
            } else if (random [randomspawn] () <= di.Probability) // prob 255 = always spawn, prob 0 = almost never spawn.
                DoSpawnActor (di.Name);
        }
    }

    void DoSpawnActor (class<Actor> cls) {
        // Handle replacement here so as to get the proper speed and flags for missiles
        if (cls != null) {
            Class<Actor> rep = GetReplacement (cls);
            if (rep != null)
                cls = rep;
        }

        if (cls != null) {
            Species = Name (cls);
            readonly<Actor> defmobj = GetDefaultByType (cls);
            Speed = defmobj.Speed;
            bMissile |= defmobj.bMissile;
            bSeekerMissile |= defmobj.bSeekerMissile;
            bSpectral |= defmobj.bSpectral;
        }
        else {
            A_Log (TEXTCOLOR_RED .. "Unknown item class ".. cls .." to drop from a random spawner (Custom Se7evidas monster spawner)\n");
            Species = 'None';
        }
    }
}

class S7_MEvntNoMonster : Actor {
    default {
        Health 0x00FFFFFF;
        Radius 1;
        Height 10000;
        Mass 0x7FFFFFFF;
        Speed 0;
        DamageFactor 0.0;
        DamageFactor "S7_ForceKillSpcDMG", 10.0;

        Monster;

        +INVULNERABLE +NOTELEPORT +DONTMORPH +NOTARGET
        +VULNERABLE
        -SHOOTABLE    -SOLID          -COUNTKILL   -CANPASS
        -CANPUSHWALLS -ACTIVATEMCROSS -CANUSEWALLS
    }

    states {
    Spawn:
        TNT1 A 0;
    Idle:
        TNT1 A 1;
        TNT1 A 0 A_CheckSight ("Idle");
        TNT1 A 1 A_Die ("S7_ForceKillSpcDMG");
        wait;

    Death:
        TNT1 A 0 A_NoBlocking;
        TNT1 A -1;
        stop;

    Raise:
        TNT1 A 0;
        goto Idle;
    }
}

/** FastProjectile trail base **/
class S7_FastProjTrailBase : S7_EffectsBase {
    default {
        +NOBLOCKMAP +NOGRAVITY     +NOTELEPORT     +THRUACTORS
        +CANNOTPUSH +NOINTERACTION +CLIENTSIDEONLY
        -SOLID
    }
}

/** Trace test puffs **/
class S7_TraceTestPuff : Actor {
    default {
        Radius 1;
        Height 1;

        +NOBLOCKMAP      +ALLOWTHRUFLAGS +NOINTERACTION +NOTIMEFREEZE
        +BLOODLESSIMPACT +PAINLESS
    }

    states {
    Spawn:
    Death:
        TNT1 A 1;
        stop;
    }
}

class S7_WallCheckPuff : S7_TraceTestPuff {
    default {
        +THRUACTORS
    }
}

//-------------------------------------------------------------------------------------------
//
// Projectile base
//
//-------------------------------------------------------------------------------------------
class S7_Projectile_Trace_RipHit {
    Vector3 hitPos;
    Actor mo;
}
class S7_Projectile_Trace : LineTracer {
    S7_Projectile sourceActor;
    Array<Actor> actorsToIgnore;
    Array<S7_Projectile_Trace_RipHit> actorsToRipThrough;
    
    override ETraceStatus TraceCallback () {
        /*if (!sourceActor)
            return TRACE_Skip;*/

        switch (Results.HitType) {
            case TRACE_HitActor:
                if (sourceActor.bThruActors)
                    return TRACE_Skip;

                let mo = Results.HitActor;

                for (int i = 0; i < actorsToIgnore.Size (); i++) {
                    if (mo == actorsToIgnore [i])
                        return TRACE_Skip;
                }

                if (mo != sourceActor && (sourceActor.bMissile && mo != sourceActor.target)) {
                    if (!(mo.bSolid || mo.bSpecial || mo.bShootable || mo.bTouchy))
                        return TRACE_Skip;
                    if (mo.bThruActors)// || (sourceActor.bThruSpecies && mo.GetSpecies () == sourceActor.GetSpecies ()))
                        return TRACE_Skip;

                    if (sourceActor.bRipper && S7_ActorExtensions.CanRip (mo, sourceActor)) {
                        for (int i = 0; i < actorsToRipThrough.Size (); i++) {
                            if (actorsToRipThrough [i].mo == mo)
                                return TRACE_Skip;
                        }

                        let ripHit = new ("S7_Projectile_Trace_RipHit");
                        ripHit.hitPos = Results.HitPos;
                        ripHit.mo = mo;
                        actorsToRipThrough.Push (ripHit);

                        return TRACE_Skip;
                    } else
                        return TRACE_Stop; // && sourceActor.CanCollideWith (Results.HitActor)
                } else
                    return TRACE_Skip;
            break;

            case TRACE_HitFloor:
            case TRACE_HitCeiling:
                return TRACE_Stop;
            break;

            case TRACE_HitWall:
                if (Results.Tier == TIER_Upper || Results.Tier == TIER_Lower) return TRACE_Stop;

                let hl = Results.HitLine;
                if (sourceActor.bMissile && (hl.flags & (Line.ML_BLOCKPROJECTILE | Line.ML_BLOCKEVERYTHING)))
                    return TRACE_Stop;
                
                if (sourceActor.bMissile && Results.Tier == TIER_Middle && (hl.flags & Line.ML_BLOCKING) && (hl.flags & Line.ML_TWOSIDED))
                    return TRACE_Skip;
                
                if ((hl.flags & Line.ML_BLOCKING) || (hl.flags & Line.ML_BLOCKEVERYTHING) || (sourceActor.bIsMonster && (hl.flags & Line.ML_BLOCKMONSTERS)))
                    return TRACE_Stop;
            break;
        }
        return TRACE_Skip;
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

    transient S7_Projectile_Trace tr;

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

    virtual void DoRipping () {
        if (!bRipper || !tr)
            return;

        Array<S7_Projectile_Trace_RipHit> ripActors;
        ripActors.Clear ();
        ripActors.Copy (tr.actorsToRipThrough);
        tr.actorsToRipThrough.Clear ();

        Vector3 realPos = pos;

        for (int i = 0; i < ripActors.Size (); i++) {
            let ripHit = ripActors [i];

            if (!ripHit || !ripHit.mo)
                continue;
            if (ripHit.mo == target) // Don't rip our own shooter.
                continue;

            SetOrigin (ripHit.hitPos, false);
            TryMove (ripHit.hitPos.XY, true, false);

            if (ripHit)
                ripHit.Destroy ();

            SetOrigin (realPos, false);
        }

        SetOrigin (realPos, false);
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
        if (!self)
            return;

        ClearInterpolation ();
        let oldPos = pos;
        let oldVel = vel;

        if (!bNoTimeFreeze && (globalfreeze || level.Frozen))
            return;

        if (vel != (0, 0, 0) || (pos.Z != floorz)) {
            if (!tr) { tr = new ("S7_Projectile_Trace"); tr.sourceActor = self; }
            tr.actorsToIgnore.Clear ();
            tr.actorsToRipThrough.Clear ();

            if (bMissile && vel.X == 0 && vel.Y == 0 && !IsZeroDamage ())
                vel.X = MinVel;

            let velUnit = vel.Unit ();
            double velAngle = VectorAngle (velUnit.x, velUnit.y);
            double s = sin (velAngle);
            double c = cos (velAngle);

            double maxDist = abs (vel.Length ());
            int colFlags = (fpCollisionMode & (ColMode_Center | ColMode_Corners | ColMode_EdgeCenters));
            int iMax = FPColOffs.Size () / 2;

            int loopBreaker = 0;
            bool collisionHandled = false;
            for (int i = 0; i < iMax; i++) {
                if ((i >= 0 && i <= 3) && !(colFlags & ColMode_EdgeCenters))
                    continue;
                else if ((i >= 4 && i <= 7) && !(colFlags & ColMode_Corners))
                    continue;
                else if ((i == 8) && !(colFlags & ColMode_Center))
                    continue;

                tr.actorsToIgnore.Clear ();

                do {
                    double yOffs = radius * FPColOffs [i * 2];

                    if (tr.Trace (Vec3Offset (s * yOffs, c * yOffs, height * FPColOffs [i * 2 + 1]), curSector, velUnit, maxDist, 0)) {
                        if (HandleCollision (oldPos, oldVel)) {
                            if (!self)
                                return;

                            collisionHandled = true;
                            break;
                        }
                    } else
                        tr.actorsToIgnore.Clear ();

                    loopBreaker++;
                    if (loopBreaker >= 4096) { // Uh oh.
                        Console.PrintF ("\cgSe7evidas error: Broke an infinite loop in S7_Projectile.");
                        Destroy ();
                        return;
                    }
                } while (tr.actorsToIgnore.Size () > 0);

                if (collisionHandled)
                    break;
            }

            DoRipping ();

            if (!collisionHandled)
                SetOrigin (pos + vel, true);
            TryMove (pos.xy, true, false);

            SpawnEffects (oldPos, level.Vec3Diff (pos, oldPos).Length (), oldVel);

            if (!collisionHandled) {
                bool floorHit = pos.Z <= GetZAt ();
                bool ceilingHit = (pos.Z + height) > ceilingZ;

                bool hitSky = ((  floorHit &&   floorpic == skyflatnum) ||
                               (ceilingHit && ceilingpic == skyflatnum));

                if (hitSky && !bSkyExplode) {
                    Destroy ();
                    return;
                } else if (floorHit || ceilingHit) {
                    SetZ (floorHit ? GetZAt () : ceilingZ - height);

                    if (floorHit)
                        HitFloor ();

                    A_Stop ();
                    if (bMissile)
                        ExplodeMissile (NULL, NULL, hitsky);
                }
            }

            vel.z += GetGravity ();

            UpdateWaterLevel ();
            CheckPortalTransition ();
        }

        // Nope the fuck out if self is null for some retarded reason
        if (!self)
            return;
        // Freed itself
        if (!CheckNoDelay ())
            return;
        // Advance the state
        if (tics != -1) {
            if (tics > 0)
                tics--;

            while (!tics) {
                if (!self || !CurState || !SetState (CurState.NextState)) // mobj was removed
                    return;
            }
        }
    }

    bool HandleCollision (Vector3 oldPos, Vector3 oldVel) {
        if (abs (level.Vec3Diff (oldPos, tr.Results.hitPos).Length ()) > abs (oldVel.Length ()) + radius) {
            if (tr.Results.HitType == TRACE_HitActor && tr.Results.HitActor)
                tr.actorsToIgnore.Push (tr.Results.HitActor);

            return false;
        }

        double maxDist = abs (oldVel.Length ());
        double hitPosDist = abs (tr.Results.hitPos.Length ());
        let hitPos = tr.Results.HitPos;
        hitPos += -(oldVel.Unit () * abs (radius));

        SetOrigin (hitPos, interpFastProj);

        if (!bSkyExplode) {
            if (tr.Results.HitType == TRACE_HitWall && tr.Results.HitLine) {
                let l = tr.Results.HitLine;
                if (l.backsector && l.backsector.GetTexture (sector.ceiling) == skyflatnum) {
                    let posr = PosRelative (l.backsector);
                    if (pos.Z >= l.backsector.ceilingplane.ZatPoint (posr.XY)) {
                        // Hack to prevent missiles exploding against the sky.
                        // Does not handle sky floors.
                        SpawnEffects (oldPos, tr.Results.Distance, oldVel); 
                        DoRipping ();

                        Destroy ();

                        return true;
                    }
                }

                // [RH] Don't explode on horizon lines.
                if (l && l.special == Line_Horizon) {
                    SpawnEffects (oldPos, tr.Results.Distance, oldVel);
                    DoRipping ();

                    Destroy ();

                    return true;
                }
            } else if ((tr.Results.HitType == TRACE_HitFloor && floorpic == skyflatnum) ||
                (tr.Results.HitType == TRACE_HitCeiling && ceilingpic == skyflatnum)) {
                SpawnEffects (oldPos, tr.Results.Distance, oldVel);
                DoRipping ();

                Destroy ();

                return true;
            }
        }

        if (tr.Results.HitType == TRACE_HitFloor)
            hitPos = tr.Results.HitPos;
        else if (tr.Results.HitType == TRACE_HitCeiling) {
            hitPos = tr.Results.HitPos;
            hitPos -= (0, 0, height);
        }

        if (!TryMove (hitPos.xy + (double.epsilon * 3, double.epsilon * 3), true)) {
            SetOrigin (hitPos, interpFastProj);

            A_Stop ();
            ExplodeMissile (BlockingLine, BlockingMobj);

            return true;
        } else if (tr.Results.HitType == TRACE_HitActor && tr.Results.HitActor)
            tr.actorsToIgnore.Push (tr.Results.HitActor);
        else {
            let rHitPos = tr.Results.HitPos;
            if ((tr.Results.HitType == TRACE_HitFloor && rHitPos.z - GetZAt () <= 1) ||
                (tr.Results.HitType == TRACE_HitCeiling && ceilingZ - (rHitPos.z + height) <= 1)) {
                SetOrigin (hitPos, interpFastProj);

                if (tr.Results.HitType == TRACE_HitFloor) {
                    SetZ (GetZAt ());
                    HitFloor ();
                }

                if (bMissile) {
                    A_Stop ();
                    ExplodeMissile (NULL, NULL);
                }

                return true;
            }
        }

        SetOrigin (oldPos, false);
        return false;
    }
}