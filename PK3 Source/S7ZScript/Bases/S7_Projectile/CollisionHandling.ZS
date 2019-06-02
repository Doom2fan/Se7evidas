extend class S7_Projectile {
    int HandleCollision (Vector3 oldPos, Vector3 oldVel, Vector3 startPos) {
        double hitDist = level.Vec3Diff (startPos, tr.Results.hitPos).Length ();
        if (hitDist > abs (oldVel.Length ()) + radius) {
            if (tr.Results.HitType == TRACE_HitActor && tr.Results.HitActor && tr.actorsToIgnore.Find (tr.Results.HitActor) == tr.actorsToIgnore.Size ())
                tr.actorsToIgnore.Push (tr.Results.HitActor);

            return 0;
        }

        double maxDist = abs (oldVel.Length ());
        let hitPos = level.Vec3Offset (oldPos, (oldVel.Unit () * hitDist));
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

                        Destroy ();

                        return 1;
                    }
                }

                // [RH] Don't explode on horizon lines.
                if (l && l.special == Line_Horizon) {
                    SpawnEffects (oldPos, tr.Results.Distance, oldVel);

                    Destroy ();

                    return 1;
                }
            } else if ((tr.Results.HitType == TRACE_HitFloor && floorpic == skyflatnum) ||
                (tr.Results.HitType == TRACE_HitCeiling && ceilingpic == skyflatnum)) {
                SpawnEffects (oldPos, tr.Results.Distance, oldVel);

                Destroy ();

                return 1;
            }
        }

        if (tr.Results.HitType == TRACE_HitFloor)
            hitPos = tr.Results.HitPos;
        else if (tr.Results.HitType == TRACE_HitCeiling)
            hitPos = level.Vec3Offset (tr.Results.HitPos, (0, 0, -height));

        Vector3 rHitPos = tr.Results.HitPos;

        double realFloorZ = GetZAt (rHitPos.X, rHitPos.Y, flags: GZF_AbsolutePos | GZF_AbsoluteAng);
        double realCeilingZ = GetZAt (rHitPos.X, rHitPos.Y, flags: GZF_AbsolutePos | GZF_AbsoluteAng | GZF_Ceiling);

        bool floorHit = (rHitPos.Z <= realFloorZ || rHitPos.Z ~== realFloorZ);
        bool ceilingHit; {
            let hitPosTop = level.Vec3Offset (rHitPos, (0, 0, height));
            ceilingHit = hitPosTop.Z > realCeilingZ;
        }

        FCheckPosition tm;
        tm.DoRipping = bRipper;

        SetZ (hitPos.Z);
        if (!TryMove (level.Vec2Offset (hitPos.XY, (double.epsilon * 3, double.epsilon * 3)), true, tm: tm)) {
            SetOrigin (hitPos, interpFastProj);

            bool hitSky = ((  floorHit &&   floorpic == skyflatnum) ||
                           (ceilingHit && ceilingpic == skyflatnum));

            A_Stop ();
            ExplodeMissile (BlockingLine, BlockingMobj, (!BlockingLine && !BlockingMobj) ? hitSky : false);

            return 1;
        } else if (tr.Results.HitType == TRACE_HitActor && tr.Results.HitActor) {
            if (tr.actorsToIgnore.Find (tr.Results.HitActor) == tr.actorsToIgnore.Size ())
                tr.actorsToIgnore.Push (tr.Results.HitActor);

            if (bRipper && tr.actorsRipped.Find (tr.Results.HitActor) == tr.actorsRipped.Size ())
                tr.actorsRipped.Push (tr.Results.HitActor);
        } else if (tr.Results.HitType == TRACE_HitWall && tr.Results.HitLine) {
            let hl = tr.Results.HitLine;
            int oldSide = S7_Math.PointOnLineSidePrecise (oldPos.X, oldPos.Y, hl);

            int activationType = -1;

            if ((hl.activation & SPAC_MCross) && bActivateMCross)
                activationType = SPAC_MCross;
            else if ((hl.activation & SPAC_PCross) && bActivatePCross)
                activationType = SPAC_PCross;

            if (activationType != -1) {
                hl.Activate (self, oldSide, activationType);

                SetOrigin (oldPos, false);
                return -1;
            }
        } else {
            if ((tr.Results.HitType == TRACE_HitFloor && floorHit) ||
                (tr.Results.HitType == TRACE_HitCeiling && ceilingHit)) {
                SetOrigin (hitPos, interpFastProj);

                bool hitSky = ((  floorHit &&   floorpic == skyflatnum) ||
                               (ceilingHit && ceilingpic == skyflatnum));

                if (tr.Results.HitType == TRACE_HitFloor) {
                    SetZ (floorZ);
                    HitFloor ();
                }

                if (bMissile) {
                    A_Stop ();
                    ExplodeMissile (NULL, NULL, hitSky);
                }

                return 1;
            } else if (S7_DebugMode >= 1)
                Console.PrintF ("zzz %f ----- %f, %d", rHitPos.Z, GetZAt (rHitPos.X, rHitPos.Y, flags: GZF_AbsolutePos | GZF_AbsoluteAng), floorHit);
        }

        SetOrigin (oldPos, false);
        return 0;
    }
}