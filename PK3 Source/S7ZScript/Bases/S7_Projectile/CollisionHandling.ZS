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

extend class S7_Projectile {
    bool CheckSkyLine (Vector3 curPos, Line l) {
        if (!l)
            return false;

        if (l.backsector && l.backsector.GetTexture (sector.ceiling) == skyflatnum) {
            let posr = PosRelative (l.backsector);
            if (curPos.Z >= l.backsector.ceilingplane.ZatPoint (posr.XY)) {
                // Hack to prevent missiles exploding against the sky.
                // Does not handle sky floors.
                return true;
            }
        }

        // [RH] Don't explode on horizon lines.
        if (l.special == Line_Horizon)
            return true;

        return false;
    }

    bool CheckSkyHit (Vector3 curPos, FCheckPosition tm, bool checkTraceHit) {
        if (checkTraceHit && tr.Results.HitType == TRACE_HitWall && CheckSkyLine (curPos, tr.Results.HitLine))
            return true;

        if (tm) {
            if (tm.ceilingLine && CheckSkyLine (curPos, tm.ceilingLine))
                return true;

            if (curPos.Z < tm.floorZ && tm.floorpic == skyflatnum)
                return true;
            if ((curPos.Z + height) >= tm.ceilingZ && tm.ceilingpic == skyflatnum)
                return true;
        }

        if (BlockingLine && CheckSkyLine (curPos, BlockingLine))
            return true;

        TextureID hitPlaneTex;

        if (BlockingType == S7_BLOCK_Floor && BlockingFloor)
            hitPlaneTex = BlockingFloor.GetTexture (Sector.Floor);
        if (BlockingType == S7_BLOCK_Ceiling && BlockingCeiling)
            hitPlaneTex = BlockingCeiling.GetTexture (Sector.Ceiling);
        if (BlockingType == S7_BLOCK_3DFloor_Floor && BlockingFFloor)
            hitPlaneTex = BlockingFFloor.Get3DFloor ().GetTexture (Sector.Floor);
        if (BlockingType == S7_BLOCK_3DFloor_Ceiling && BlockingFFloor)
            hitPlaneTex = BlockingFFloor.Get3DFloor ().GetTexture (Sector.Ceiling);

        if (hitPlaneTex == skyflatnum)
            return true;

        return false;
    }

    protected double, double CheckBlockingPlanes (Vector3 checkPos) {
        Sector sec = level.PointInSector (checkPos.XY);

        double floorHeight, ceilHeight;
        Sector floorSec, ceilSec;
        F3DFloor floorFFloor, ceilFFloor;

        [floorHeight, floorSec, floorFFloor] = sec.NextLowestFloorAt (checkPos.X, checkPos.Y, checkPos.Z);
        [ ceilHeight,  ceilSec,  ceilFFloor] = sec.NextHighestCeilingAt (checkPos.X, checkPos.Y, checkPos.Z, checkPos.Z + height);

        if (floorFFloor && checkPos.Z <= floorHeight) {
            BlockingType = S7_BLOCK_3DFloor_Floor;

            BlockingFloor = floorFFloor.model;
            Blocking3DFloor = floorFFloor.model;
            BlockingFFloor = S7_3DFloorPointer.FromF3DFloor (floorFFloor);
        } else if (ceilFFloor && (checkPos.Z + height) >= ceilHeight) {
            BlockingType = S7_BLOCK_3DFloor_Ceiling;

            BlockingCeiling = ceilFFloor.model;
            Blocking3DFloor = ceilFFloor.model;
            BlockingFFloor = S7_3DFloorPointer.FromF3DFloor (ceilFFloor);
        } else if (checkPos.Z <= floorHeight) {
            BlockingType = S7_BLOCK_Floor;

            BlockingFloor = floorSec;
        } else if ((checkPos.Z + height) >= ceilHeight) {
            BlockingType = S7_BLOCK_Ceiling;

            BlockingCeiling = ceilSec;
        }

        return floorHeight, ceilHeight;
    }

    int HandleCollision (Vector3 oldPos, Vector3 oldVel, Vector3 startPos) {
        BlockingMobj = null;
        BlockingLine = null;
        Blocking3DFloor = null;
        BlockingFFloor = null;
        BlockingFloor = null;
        BlockingCeiling = null;
        BlockingType = S7_BLOCK_None;

        double hitDist = level.Vec3Diff (startPos, tr.Results.HitPos).Length ();
        if (hitDist > abs (oldVel.Length ()) + radius) {
            if (tr.Results.HitType == TRACE_HitActor && tr.Results.HitActor && tr.actorsToIgnore.Find (tr.Results.HitActor) == tr.actorsToIgnore.Size ())
                tr.actorsToIgnore.Push (tr.Results.HitActor);

            return 0;
        }

        let hitPos = level.Vec3Offset (oldPos, (oldVel.Unit () * hitDist));

        /*if (!bSkyExplode && CheckSkyHit (pos, null, true)) {
            if (!spawnedTrail) {
                SpawnEffects (oldPos, level.Vec3Diff (oldPos, pos).Length (), oldVel);
                spawnedTrail = true;
            }

            hitSky = true;
            S7_ExplodeMissile (null, null, true);

            return 1;
        }*/

        if (tr.Results.HitType == TRACE_HitFloor) {
            double floorHeight = tr.Results.HitSector.floorPlane.ZatPoint (hitPos.XY);

            if (tr.Results.FFloor)
                floorHeight = tr.Results.FFloor.top.ZatPoint (hitPos.XY);

            floorHeight = tr.Results.HitSector.NextLowestFloorAt (hitPos.X, hitPos.Y, floorHeight + 0.001);
            hitPos = (hitPos.XY, floorHeight);
        } else if (tr.Results.HitType == TRACE_HitCeiling) {
            double ceilHeight = tr.Results.HitSector.ceilingPlane.ZatPoint (hitPos.XY);

            if (tr.Results.FFloor)
                ceilHeight = tr.Results.FFloor.bottom.ZatPoint (hitPos.XY);

            ceilHeight = tr.Results.HitSector.NextHighestCeilingAt (hitPos.X, hitPos.Y, ceilHeight - 0.001, (ceilHeight - 0.001) + height);
            hitPos = (hitPos.XY, ceilHeight - (abs (height) - 1));
        } else {
            hitPos += -(oldVel.Unit () * abs (radius / 2.));
        }

        SetPosition (hitPos);
        if (!interpFastProj)
            ClearInterpolation ();

        FCheckPosition tm;
        tm.DoRipping = bRipper;

        SetZ (hitPos.Z);
        if (!TryMove (level.Vec2Offset (hitPos.XY, (double.epsilon * 3, double.epsilon * 3)), true, tm: tm)) {
            SetPosition (hitPos);
            if (!interpFastProj)
                ClearInterpolation ();

            if (BlockingMobj)
                BlockingType = S7_BLOCK_Actor;
            else if (BlockingLine) {
                BlockingType = S7_BLOCK_Line;

                if (tr.Results.HitType == TRACE_HitWall && tr.Results.Tier == TIER_FFloor && BlockingLine == tr.Results.HitLine) {
                    BlockingFFloor = S7_3DFloorPointer.FromF3DFloor (tr.Results.ffloor);
                    BlockingLineTier = S7_BLOCK_Tier_FFloor;
                } else if (!(BlockingLine.flags & Line.ML_TwoSided) || !BlockingLine.sidedef [Line.Back])
                    BlockingLineTier = S7_BLOCK_Tier_Middle;
                else {
                    Sector frontSec = BlockingLine.sidedef [Line.Front].sector;
                    Sector backSec = BlockingLine.sidedef [Line.Back].sector;

                    if (S7_Math.PointOnLineSidePrecise (pos.X, pos.Y, BlockingLine) == 1) {
                        let tmp = frontSec;
                        frontSec = backSec;
                        backSec = frontSec;
                    }

                    bool aboveBottom = (pos.Z >= backSec.floorPlane.ZatPoint (hitPos.XY));
                    bool belowTop = ((pos.Z + height) < backSec.ceilingPlane.ZatPoint (hitPos.XY));

                    if (aboveBottom && belowTop)
                        BlockingLineTier = S7_BLOCK_Tier_Middle;
                    else if (!aboveBottom)
                        BlockingLineTier = S7_BLOCK_Tier_Bottom;
                    else if (!belowTop)
                        BlockingLineTier = S7_BLOCK_Tier_Top;
                }
            } else
                CheckBlockingPlanes (pos);

            bool didHitSky = CheckSkyHit (pos, tm, true);

            if (!spawnedTrail && didHitSky) {
                SpawnEffects (oldPos, level.Vec3Diff (oldPos, pos).Length (), oldVel);
                spawnedTrail = true;
            }

            A_Stop ();
            S7_ExplodeMissile (BlockingLine, BlockingMobj, (!BlockingLine && !BlockingMobj) ? didHitSky : false);

            return 1;
        } else if (tr.Results.HitType == TRACE_HitActor && tr.Results.HitActor) {
            if (tr.actorsToIgnore.Find (tr.Results.HitActor) == tr.actorsToIgnore.Size ())
                tr.actorsToIgnore.Push (tr.Results.HitActor);

            if (bRipper && tr.actorsRipped.Find (tr.Results.HitActor) == tr.actorsRipped.Size ())
                tr.actorsRipped.Push (tr.Results.HitActor);
        } else if (tr.Results.HitType == TRACE_HitWall && tr.Results.HitLine) {
            let hl = tr.Results.HitLine;

            let oldSide = S7_Math.PointOnLineSidePrecise (oldPos.X, oldPos.Y, hl);
            let activationType = -1;

            if ((hl.activation & SPAC_MCross) && bActivateMCross)
                activationType = SPAC_MCross;
            else if ((hl.activation & SPAC_PCross) && bActivatePCross)
                activationType = SPAC_PCross;

            if (activationType != -1) {
                hl.Activate (self, oldSide, activationType);

                SetPosition (oldPos);
                ClearInterpolation ();
                return -1;
            }

            if (tr.Results.Tier == TIER_Middle && (hl.flags & Line.ML_3DMidTex) && !(hl.flags & Line.ML_3DMidTex_Impass)) {
                SetPosition (oldPos);
                ClearInterpolation ();
                return -1;
            }
        } else {
            double floorHeight, ceilHeight;
            [floorHeight, ceilHeight] = CheckBlockingPlanes (hitPos);

            bool hitPlane = (
                BlockingType == S7_BLOCK_Floor ||
                BlockingType == S7_BLOCK_Ceiling ||
                BlockingType == S7_BLOCK_3DFloor_Floor ||
                BlockingType == S7_BLOCK_3DFloor_Ceiling
            );

            if (hitPlane) {
                SetPosition (hitPos);
                if (!interpFastProj)
                    ClearInterpolation ();

                bool didHitSky = CheckSkyHit (pos, null, true);

                if (BlockingType == S7_BLOCK_Floor || BlockingType == S7_BLOCK_3DFloor_Floor) {
                    HitFloor ();
                    SetZ (floorHeight);
                } else
                    SetZ (ceilHeight - (abs (height) - 1));

                if (!spawnedTrail && didHitSky) {
                    SpawnEffects (oldPos, level.Vec3Diff (oldPos, pos).Length (), oldVel);
                    spawnedTrail = true;
                }

                if (bMissile) {
                    A_Stop ();
                    S7_ExplodeMissile (null, null, didHitSky);
                }

                return 1;
            }
        }

        SetPosition (oldPos);
        ClearInterpolation ();
        return 0;
    }
}