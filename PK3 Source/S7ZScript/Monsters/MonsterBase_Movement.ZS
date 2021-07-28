/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 1993-1996 id Software
 *  Copyright (C) 1994-1996 Raven Software
 *  Copyright (C) 1998-1998 Chi Hoang, Lee Killough, Jim Flynn, Rand Phares, Ty Halderman
 *  Copyright (C) 1999-2016 Randy Heit
 *  Copyright (C) 2002-2016 Christoph Oelckers
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

class S7_TestThing : Actor {
    default {
        -NOBLOCKMAP -NOGRAVITY
    }

    states {
    Spawn:
        AMRK A 1 noDelay bright {
            SetZ (floorZ);
        }
        loop;
    }
}

class S7_TestThing2 : Actor {
    default {
        radius 0;
        height 0;

        renderStyle "Translucent";

        +NOBLOCKMAP +NOGRAVITY
    }

    override void Tick () {
        Super.Tick ();

        if (tics < 1 || CurState == null)
            return;

        double totalTics = CurState.tics;
        alpha = (tics / totalTics);
    }

    states {
    Spawn:
        AMRK A 35 noDelay bright;
        stop;
    }
}

class S7_MonsterBase_WallTracer : LineTracer {
    int LineBlockFlags;
    bool CanDropoff;
    double MaxDropOffHeight;

    bool WasDropoff;

    override ETraceStatus TraceCallback () {
        let hitPos = Results.HitPos;
        WasDropoff = false;

        if (Results.HitType != TRACE_HitWall)
            return TRACE_Skip;

        let curLine = Results.HitLine;

        // Stop if we hit the upper or lower of the line.
        if ((Results.Tier == TIER_Upper || Results.Tier == TIER_Lower))
            return TRACE_Stop;

        // Stop if this line matches any of the actor's blocking flags.
        if (curLine.flags & LineBlockFlags)
            return TRACE_Stop;

        // Stop if this is a dropoff.
        if (!CanDropoff && curLine.Sidedef [Line.Back] != null) {
            Sector hitSec = curLine.Sidedef [Results.Side].Sector;
            Sector oppositeSec = curLine.Sidedef [!Results.Side].Sector;

            // Not 3D floor aware because NextLowestFloorAt isn't clearscope for some fucking reason.
            // Original: .NextLowestFloorAt (hitPos.X, hitPos.Y, hitPos.Z + 1e+5)
            let hitZ = hitSec.floorPlane.ZatPoint (hitPos.XY);
            let oppZ = oppositeSec.floorPlane.ZatPoint (hitPos.XY);

            if ((hitZ - oppZ) > (MaxDropOffHeight + S7_Math.VM_Epsilon)) {
                WasDropoff = true;

                return TRACE_Stop;
            }
        }

        return TRACE_Skip;
    }
}

extend class S7_MonsterBase {
    S7_MonsterBase_WallTracer wallTracer;

    enum EObstacleType {
        ObstacleType_None = 0,
        ObstacleType_BlockingLine = 1,
        ObstacleType_Dropoff = 2,
        ObstacleType_Actor = 3,
    }

    static const double WallFeelersAngles [] = {
        // Straight ahead.
        0,
        // Angled whiskers
        -22.5, 22.5
        // Parallel rays
        //0, 0
    };
    static const double WallFeelersYOffs [] = {
        // Straight ahead.
        0,
        // Angled whiskers
        0, 0
        // Parallel rays
        //-.8, .8
    };
    static const double WallFeelersLengths [] = {
        // Straight ahead.
        1,
        // Angled whiskers
        -2, -2
        // Parallel rays
        //0.5, 0.5
    };

    Vector2 S7_Steer_CalcPursuePos (double curSpeed, Vector2 targPos, Vector2 targVel, double maxPrediction) {
        double distance = level.Vec2Diff (pos.XY, targPos).Length ();

        double predictedTime;
        if (curSpeed <= distance / maxPrediction)
            predictedTime = maxPrediction;
        else
            predictedTime = distance / curSpeed;

        return level.Vec2Offset (targPos, targVel * predictedTime);
    }

    bool S7_Steer_WallAvoid_Trace (double distance, double traceAngle, double offsY, double offsZ) {
        let sinAng = sin (traceAngle);
        let cosAng = cos (traceAngle);

        let traceDir = (cosAng, sinAng, 0).Unit ();
        let offsets = (sinAng * offsY, cosAng * offsY, offsZ);

        let startPos = level.Vec3Offset (pos, offsets);
        return wallTracer.Trace (startPos, curSector, traceDir, distance, 0);
    }

    int, Vector2 S7_Steer_WallAvoid (double checkAngle, double maxAccel, double curSpeed, double predictionTime) {
        int blockType = ObstacleType_None;

        if (!wallTracer)
            wallTracer = new ('S7_MonsterBase_WallTracer');

        wallTracer.LineBlockFlags = S7_ActorExtensions.GetSelfBlockLineFlags (self);
        wallTracer.CanDropoff = bFloat;
        wallTracer.MaxDropOffHeight = MaxDropOffHeight;

        let realRadius = S7_Math.SqrtTwo * radius;
        let checkDir = AngleToVector (checkAngle, 1);

        let closestDist = double.infinity;
        Line closestHitLine = null;
        Vector2 closestHitCentralOffset;
        int closestHitSide;

        double traceDist = realRadius + max (max (curSpeed, maxAccel), realRadius / 2) * predictionTime;
        for (int i = 0; i < WallFeelersAngles.Size (); i++) {
            let feelerAngle = checkAngle + WallFeelersAngles [i];
            let feelerYOffs = WallFeelersYOffs [i] * radius;
            let feelerLength = WallFeelersLengths [i];
            feelerLength = (feelerLength < 0) ? (-feelerLength * realRadius) : (feelerLength * traceDist);

            if (S7_Steer_WallAvoid_Trace (feelerLength, feelerAngle, feelerYOffs, MaxStepHeight + .5)) {
                // Give priority to dropoffs.
                if (blockType == ObstacleType_Dropoff && !wallTracer.WasDropoff)
                    continue;

                if (wallTracer.Results.Distance >= closestDist) {
                    if (!wallTracer.WasDropoff || blockType == ObstacleType_Dropoff)
                        continue;
                }

                closestDist = wallTracer.Results.Distance;
                closestHitLine = wallTracer.Results.HitLine;
                closestHitSide = wallTracer.Results.Side;
                closestHitCentralOffset = S7_Math.ProjectPointToLine2D (
                    (0, 0), checkDir * traceDist, wallTracer.Results.HitVector.XY * max (closestDist - radius, 0)
                );
                blockType = ObstacleType_BlockingLine + wallTracer.WasDropoff;
            }
        }

        if (closestHitLine != null)
            return blockType, closestHitCentralOffset;

        return ObstacleType_None, (0, 0);
    }

    bool, Vector2 S7_Steer_AvoidActors (double checkAngle, double maxAccel, double curSpeed, double predictionTime) {
        let checkDir = AngleToVector (checkAngle, 1);
        let checkSpeed = max (maxAccel, curSpeed) * predictionTime;
        let checkVel = checkDir * checkSpeed;
        let realRadius = S7_Math.SqrtTwo * Radius;

        let it = BlockThingsIterator.Create (self, realRadius + checkSpeed + 128);

        let closestDist = double.infinity;

        while (it.Next ()) {
            let other = it.Thing;

            if (other == self)
                continue;

            Console.Printf ("%p a", other);

            // Ignore this actor if we won't collide in the Z axis
            /*if (other.Pos.Z >= (Pos.Z + Height) || Pos.Z >= (other.Pos.Z + other.Height))
                continue;*/

            // If the speed is less than the distance between the actors minus their radii, there's no way they can hit.
            let posDiff = level.Vec2Diff (pos.XY, other.Pos.XY);
            let sumRadii = realRadius + other.Radius * S7_Math.SqrtTwo;
            let directDistance = posDiff.Length ();
            if ((directDistance - sumRadii) >= checkSpeed)
                continue;
            Console.Printf ("%p b", other);

            // If we're already intersecting, ignore the actor. (That means this it has to be an uncollidable actor)
            /*if (directDistance - sumRadii < S7_Math.VM_Epsilon)
                continue;*/

            let D = checkDir dot posDiff;

            // If the dot product between checkDir and posDiff is <= 0, A isn't isn't moving towards B.
            if (D <= 0)
                continue;
            Console.Printf ("%p c", other);

            let F = (posDiff dot posDiff) - (D * D);

            // If the closest the actors will get is more than the sum of their radii, there's no way they'll collide.
            let sumRadiiSquared = sumRadii * sumRadii;
            if (F >= sumRadiiSquared)
                continue;
            Console.Printf ("%p d", other);

            // F and sumRadii form a right triangle.
            let T = sumRadiiSquared - F;

            if (T < 0)
                continue;
            Console.Printf ("%p e", other);

            let distance = D - Sqrt (T);

            // Make sure the distance A has to move to touch B is not greater than the magnitude of the movement.
            if (checkSpeed < distance)
                continue;
            Console.Printf ("%p f", other);

            // Ignore this actor if we can't collide with it.
            /*if (CheckPosition (other.Pos.XY + (1e-5, 1e-5), actorsOnly: true))
                continue;*/

            closestDist = min (closestDist, max (distance, 0));
        }

        if (closestDist < double.infinity) {
            Console.Printf ("asd %f", closestDist);
            return true, checkDir * closestDist;
        }

        return false, (0, 0);
    }

    int, Vector2 S7_Steer_AvoidObstacles (double checkAngle, double maxAccel, double curSpeed, double predictionTime) {
        int wallType; Vector2 wallOffset;
        bool actorHit; Vector2 actorOffset;

        [wallType, wallOffset] = S7_Steer_WallAvoid (checkAngle, maxAccel, curSpeed, predictionTime);
        [actorHit, actorOffset] = S7_Steer_AvoidActors (checkAngle, maxAccel, curSpeed, predictionTime);

        if (wallType == ObstacleType_None && !actorHit)
            return ObstacleType_None, (0, 0);

        int selectedObstacle;
        Vector2 selectedOffset;
        if (wallType == ObstacleType_None) {
            selectedObstacle = ObstacleType_Actor;
            selectedOffset = actorOffset;
        } else if (!actorHit) {
            selectedObstacle = wallType;
            selectedOffset = wallOffset;
        } else {
            let wallLenSqr = wallOffset dot wallOffset;
            let actorLenSqr = actorOffset dot actorOffset;

            // Return the shortest offset. (Exception: Dropoffs)
            if (wallLenSqr <= actorLenSqr || wallType == ObstacleType_Dropoff) {
                selectedObstacle = wallType;
                selectedOffset = wallOffset;
            } else {
                selectedObstacle = ObstacleType_Actor;
                selectedOffset = actorOffset;
            }
        }
        Spawn ('S7_TestThing2', (level.Vec2Offset (pos.XY, selectedOffset), pos.Z + MaxStepHeight + .5));

        return selectedObstacle, selectedOffset;
    }

    const S7_ChaseDir_Count = 12;
    const S7_ChaseDir_Interval = 360. / S7_ChaseDir_Count;
    const S7_ChaseDir_HalfInterval = S7_ChaseDir_Interval / 2.;
    const S7_ChaseDir_IntervalRandom = 360. / 32;
    const S7_ChaseDir_IntervalWander = 45. / 2;
    bool S7_NewChaseDir (double curDir, double maxAccel, Actor targAct, bool moveAway = false) {
        if (aiState == AIS_Wander)
            return S7_RandomChaseDir (curDir, maxAccel);

        bool runAway = false;
        if (!bNoFear && targAct == target) {
            runAway |= (
                (targAct.player && (targAct.player.cheats & CF_Frightening)) || bFrightened || targAct.bFrightening
            );
        }

        // Calculate the goal's position, pos diff and unit-length direction.
        let goalPos = targAct.pos.XY;
        Vector2 goalDiff;
        Vector2 goalDir;
        if (!runAway) {
            goalPos = S7_Steer_CalcPursuePos (vel.XY.Length (), targAct.pos.XY, targAct.vel.XY, 5);
            goalDiff = level.Vec2Diff (pos.XY, goalPos);

            // We can stay still if our goal is literally on top of us exactly.
            if (goalDiff ~== (0, 0))
                return false;

            goalDir = goalDiff.Unit ();
        } else {
            goalDiff = level.Vec2Diff (pos.XY, goalPos);

            if (!(goalDiff ~== (0, 0)))
                goalDir = -goalDiff.Unit ();
            else // Choose a random direction to move in if our target is right on top of us.
                goalDir = AngleToVector (fRandom [S7_NewChaseDir] (-180, 180), 1);
        }

        // Randomize the goal's direction a tiny bit.
        goalDir = RotateVector (goalDir, fRandom [S7_NewChaseDir] (-1, 1) * S7_ChaseDir_IntervalRandom);

        // Calculate the goal angle.
        let goalAngle = atan2 (goalDir.Y, goalDir.X);

        int dirBlocked;
        Vector2 dirOffset;
        let predTime = max (tics / 4., 1);
        let wallAvoidLenSqr = (maxAccel * predTime) ** 2;

        // Try the direct route.
        [dirBlocked, dirOffset] = S7_Steer_AvoidObstacles (goalAngle, maxAccel, 0, predTime);
        if (dirBlocked == ObstacleType_None) {
            angle = goalAngle;
            return true;
        } else if (dirBlocked != ObstacleType_Dropoff && (dirOffset dot dirOffset) > wallAvoidLenSqr) {
            angle = atan2 (dirOffset.Y, dirOffset.X);
            return true;
        }

        // Sweep to find the closest direction.
        double closestDir;
        let closestDistSqr = double.infinity;

        int sweepSwap = randomPick [NewChaseDir] (-1, 1);
        // Honestly shouldn't really do much, but why not?
        let sweepFwd = goalAngle;
        if (random [S7_NewChaseDir] (0, 1))
            sweepFwd = curDir + fRandom [S7_NewChaseDir] (-1, 1) * S7_ChaseDir_IntervalRandom;

        for (int i = 1; i <= S7_ChaseDir_Count; i++) {
            int tDir = ((i >> 1) * sweepSwap);
            sweepSwap = -sweepSwap;

            let thisDir = Normalize180 (sweepFwd + tDir * S7_ChaseDir_Interval);

            [dirBlocked, dirOffset] = S7_Steer_AvoidObstacles (thisDir, maxAccel, 0, predTime);
            if (dirBlocked == ObstacleType_None)
                dirOffset = AngleToVector (thisDir, 1);
            else if (dirBlocked == ObstacleType_Dropoff || (dirOffset dot dirOffset) <= wallAvoidLenSqr)
                continue;

            let dirEndPos = level.Vec2Offset (pos.XY, dirOffset);
            let endToGoalDiff = level.Vec2Diff (dirEndPos, goalPos);
            let thisDistSqr = endToGoalDiff dot endToGoalDiff;
            if (thisDistSqr < closestDistSqr) {
                closestDir = atan2 (dirOffset.Y, dirOffset.X);
                closestDistSqr = thisDistSqr;
            }
        }

        if (closestDistSqr != double.infinity) {
            angle = closestDir;
            return true;
        }

        Console.Printf ("Can't move!");
        return false;
    }

    bool S7_RandomChaseDir (double curDir, double maxAccel) {
        let predTime = max (tics / 4., 1);
        let wallAvoidLenSqr = (maxAccel * predTime) ** 2;

        let WanderAngle = angle + fRandom [S7_NewChaseDir] (-1, 1) * S7_ChaseDir_IntervalWander;
        let wanderDist = max (radius, Speed) + 4;
        let wanderPos = pos.XY + AngleToVector (wanderAngle, wanderDist);

        // Try the direct route.
        if (S7_Steer_WallAvoid (wanderAngle, maxAccel, 0, predTime) == ObstacleType_None) {
            angle = wanderAngle;
            return true;
        }

        // Sweep to find an usable direction.
        double closestDir;
        let closestDistSqr = double.infinity;

        int sweepSwap = randomPick [NewChaseDir] (-1, 1);
        let sweepFwd = wanderAngle + fRandom [S7_NewChaseDir] (-1, 1) * S7_ChaseDir_IntervalRandom;
        for (int i = 1; i <= S7_ChaseDir_Count; i++) {
            int tDir = ((i >> 1) * sweepSwap);
            sweepSwap = -sweepSwap;

            let thisDir = Normalize180 (sweepFwd + tDir * S7_ChaseDir_Interval);

            if (S7_Steer_AvoidObstacles (thisDir, maxAccel, 0, predTime) != ObstacleType_None)
                continue;

            let dirEndPos = pos.XY + AngleToVector (thisDir, maxAccel);
            let endToGoalDiff = dirEndPos - wanderPos;

            let thisDistSqr = endToGoalDiff dot endToGoalDiff;
            if (thisDistSqr < closestDistSqr) {
                closestDir = thisDir;
                closestDistSqr = thisDistSqr;
            }
        }

        if (closestDistSqr != double.infinity) {
            angle = closestDir;
            return true;
        }

        return false;
    }

    Vector2 GetClampedLinearAccel (Vector2 linearAccel, double maxAccel) {
        double linearAccelSqr = linearAccel dot linearAccel;
        if (linearAccelSqr > (maxAccel * maxAccel))
            return linearAccel / sqrt (linearAccelSqr) * maxAccel;

        return linearAccel;
    }

    void S7_DoSteering (double maxAccel, Actor targAct, bool dontMove) {
        bool canFloat = bFloat;
        if (!canFloat && (pos.Z > floorZ || vel.Z > S7_Math.VM_Epsilon))
            return;

        bool chooseNewDir = moveCount < 1;

        let predictionTime = max (CurState.Tics / 4., 1);

        let walkDir = (vel.XY ~== (0, 0)) ? angle : atan2 (vel.Y, vel.X);
        let wallAvoidSpeed = max (radius * 1.25, vel.XY.Length ());
        if (S7_Steer_WallAvoid (walkDir, maxAccel, wallAvoidSpeed, predictionTime) != ObstacleType_None)
            chooseNewDir = true;

        bool canWalk = true;
        bool mustStop = false;

        if ((!targAct && aiState != AIS_Wander) || dontMove || aiState == AIS_MissileAttack) {
            canWalk = false;
            mustStop = true;
        } else if (chooseNewDir) {
            canWalk &= S7_NewChaseDir (walkDir, maxAccel, targAct);
            mustStop = !canWalk;
        }

        Vector2 targetVel;
        if (mustStop)
            targetVel = (0, 0);
        else if (canWalk) {
            targetVel = AngleToVector (angle, maxAccel);

            if (moveCount < 1)
                S7_SetMoveCount ();
        } else
            return;

        let linearAccel = targetVel - vel.XY;

        double linearAccelSqr = linearAccel dot linearAccel;
        if (linearAccelSqr > (maxAccel * maxAccel))
            linearAccel = linearAccel / sqrt (linearAccelSqr) * maxAccel;

        vel.XY += GetClampedLinearAccel (targetVel - vel.XY, maxAccel);
    }

    void S7_DoTickSteering (double maxAccel) {
        /*
         * This function is executed in Tick, intended for making monsters attempt to avoid slipping down dropoffs.
         */

        if (aiChaseFuncState == null)
            return;

        if (aiState != AIS_MissileAttack || health < 1 || bKilled || aiChaseFuncState != CurState) {
            aiChaseFuncState = null;
            return;
        }

        let velLen = vel.XY.Length ();
        if (velLen <= S7_Math.VM_Epsilon)
            return;

        bool mustStop = false;

        let predictionTime = 1.;

        let walkDir = atan2 (vel.Y, vel.X);
        let wallAvoidSpeed = max (radius * 1.25, velLen);
        if (S7_Steer_WallAvoid (walkDir, maxAccel, wallAvoidSpeed, predictionTime) == ObstacleType_Dropoff)
            mustStop = true;

        if (!mustStop)
            return;

        Console.Printf ("asd");
        vel.XY += GetClampedLinearAccel (-vel.XY, maxAccel);
    }
}