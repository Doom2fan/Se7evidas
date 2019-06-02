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
    double bonusDMGFactor;

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

        if (!bNoTimeFreeze && isFrozen ())
            return;

        if (vel != (0, 0, 0) || (pos.Z != floorz)) {
            if (!tr) { tr = new ('S7_Projectile_Trace'); tr.sourceActor = self; }
            tr.actorsToIgnore.Clear ();
            tr.actorsRipped.Clear ();

            if (bMissile && vel.X == 0 && vel.Y == 0 && !IsZeroDamage ())
                vel.X = MinVel;

            let velUnit = vel.Unit ();
            double velAngle = VectorAngle (velUnit.x, velUnit.y);
            double s = sin (velAngle);
            double c = cos (velAngle);

            double maxDist = abs (vel.Length ());
            int colFlags = (fpCollisionMode & (ColMode_Center | ColMode_Corners | ColMode_EdgeCenters));
            int iMax = FPColOffs.Size () / 2;

            bool collisionHandled = false;
            for (int i = 0; i < iMax; i++) {
                int loopBreaker = 0;

                if (colFlags == 0 || bNoInteraction || bNoClip)
                    break;

                if ((i >= 0 && i <= 3) && !(colFlags & ColMode_EdgeCenters))
                    continue;
                else if ((i >= 4 && i <= 7) && !(colFlags & ColMode_Corners))
                    continue;
                else if ((i == 8) && !(colFlags & ColMode_Center))
                    continue;

                tr.activeLinesToIgnore.Clear ();
                tr.actorsToIgnore.Clear ();

                int handleColRet = 0;
                do {
                    double xOffs = radius * FPColOffs [i * 2];
                    Vector3 startPos = Vec3Offset (s * xOffs, c * xOffs, height * FPColOffs [i * 2 + 1]);

                    if (tr.Trace (startPos, curSector, velUnit, maxDist, 0)) {
                        if (!self)
                            return;

                        handleColRet = HandleCollision (oldPos, oldVel, startPos);
                        if (handleColRet == 1) {
                            if (!self)
                                return;

                            tr.actorsToIgnore.Clear ();
                            collisionHandled = true;
                            break;
                        }
                    } else {
                        handleColRet = 0;
                        tr.actorsToIgnore.Clear ();
                    }

                    loopBreaker++;
                    if (loopBreaker >= 4096) { // Uh oh.
                        Console.PrintF ("\cgSe7evidas error: Broke an infinite loop in S7_Projectile.");
                        Destroy ();
                        return;
                    }
                } while (tr.actorsToIgnore.Size () > 0 || handleColRet == -1);

                if (collisionHandled)
                    break;
                else
                    SetOrigin (oldPos, false);
            }

            if (!collisionHandled)
                SetOrigin (pos + vel, interpFastProj);

            SpawnEffects (oldPos, level.Vec3Diff (pos, oldPos).Length (), oldVel);

            if (!collisionHandled && bMissile) {
                bool floorHit = pos.Z <= floorZ;
                bool ceilingHit = (pos.Z + height) > ceilingZ;

                bool hitSky = ((  floorHit &&   floorpic == skyflatnum) ||
                               (ceilingHit && ceilingpic == skyflatnum));

                if (hitSky && !bSkyExplode) {
                    Destroy ();
                    return;
                } else if ((floorHit || ceilingHit) && !bNoInteraction && !bNoClip) {
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
}