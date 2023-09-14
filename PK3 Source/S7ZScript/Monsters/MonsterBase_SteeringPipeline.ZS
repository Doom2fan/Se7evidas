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

class S7_MonsterSteering_Targetter play abstract {
    abstract void GetGoal (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal);
}

class S7_MonsterSteering_Decomposer play abstract {
    abstract void Decompose (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal);
}

class S7_MonsterSteering_Constraint play abstract {
    abstract bool WillViolate (S7_MonsterBase monster, out S7_MonsterSteering_Path path);
    abstract void Suggest (S7_MonsterBase monster, out S7_MonsterSteering_Path path, out S7_MonsterSteering_Goal goal);
}

class S7_MonsterSteering_Actuator play abstract {
    abstract void GetPath (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal, out S7_MonsterSteering_Path path);
    abstract Vector3, double Output (S7_MonsterBase monster, out S7_MonsterSteering_Path path, out S7_MonsterSteering_Goal goal);
}

class S7_MonsterSteering_Deadlock play abstract {
    abstract Vector3, double Steer (S7_MonsterBase monster);
}

class S7_MonsterSteering_BasicTargetter : S7_MonsterSteering_Targetter {
    private double lookaheadFactor;

    S7_MonsterSteering_BasicTargetter WithLookahead (double newLookahead) {
        lookaheadFactor = newLookahead;
        return self;
    }

    override void GetGoal (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {
        if (monster.MoveStandStillCount > 0) {
            goal.WithVelocity ((0, 0, 0));
            return;
        }

        monster.aiNextNode = null;
        let goalAct = monster.S7_Chase_GetMovementGoal ();

        switch (monster.AIState) {
            case S7_MonsterBase.AIS_Wander:
                if (!goalAct) {
                    HandleWander (monster, goal);
                    break;
                }
            case S7_MonsterBase.AIS_Chase:
                HandleChase (monster, goalAct, goal);
                break;
            case S7_MonsterBase.AIS_MissileAttack:
                goal.WithVelocity ((0, 0, 0));
                break;
        }
    }

    void HandleChase (S7_MonsterBase monster, Actor goalAct, out S7_MonsterSteering_Goal goal) {
        let mustStop = (!goalAct && monster.AIState != S7_MonsterBase.AIS_Wander) || monster.MoveStandStillCount > 0;

        if (mustStop)
            goal.WithVelocity ((0, 0, 0));
        else {
            let goalVel = monster.S7_CanFly () ? goalAct.Vel : (goalAct.Vel.XY, 0);
            goal.WithPosition (monster.Level.Vec3Offset (goalAct.Pos, goalVel * lookaheadFactor * Thinker.TicRate));
        }

        if (monster.bInChase && monster.MoveCount < 0)
            monster.S7_SetMoveCount ();
    }

    void HandleWander (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {

    }
}

class S7_MonsterSteering_WallFollowingConstraint : S7_MonsterSteering_Constraint {
    private S7_MonsterSteering_Path newPathStored;
    private Vector3 newPosStored;

    static bool, Vector2, Vector3, Vector3 TraceLine (S7_MonsterBase monster, Vector3 startPoint, Vector3 endPoint) {
        let wallTracer = monster.wallTracer;
        let level = monster.level;

        let traceDiff = level.Vec3Diff (startPoint, endPoint);
        let traceLen = traceDiff.Length ();
        let traceDir = traceDiff / traceLen;

        let traceStartPos = level.Vec3Offset (startPoint, (0, 0, monster.MaxStepHeight + .5));

        if (!wallTracer.Trace (traceStartPos, monster.curSector, traceDir, traceLen, 0) || wallTracer.Results.HitType != TRACE_HitWall)
            return false, (0, 0), (0, 0, 0), (0, 0, 0);

        let hitLine = wallTracer.Results.HitLine;
        let wallDir = (hitLine.delta, 0).Unit ();
        let wallNormal = (wallDir.Y, -wallDir.X, 0);

        if (S7_Math.PointOnLineSidePrecise (wallTracer.Results.HitPos.X, wallTracer.Results.HitPos.Y, hitLine) < 0)
            wallNormal = -wallNormal;

        let p1Diff = level.Vec2Diff (endPoint.XY, hitLine.v1.p);
        let p2Diff = level.Vec2Diff (endPoint.XY, hitLine.v2.p);
        if ((p2Diff dot p2Diff) < (p1Diff dot p1Diff))
            return true, hitLine.v2.p, wallNormal, wallDir;

        return true, hitLine.v1.p, wallNormal, -wallDir;
    }

    static Line, Vector3, Vector3 TraceLine2 (S7_MonsterBase monster, Vector3 startPoint, Vector3 endPoint) {
        let wallTracer = monster.wallTracer;
        let level = monster.level;

        let traceDiff = level.Vec3Diff (startPoint, endPoint);
        let traceLen = traceDiff.Length ();
        let traceDir = traceDiff / traceLen;

        let traceStartPos = level.Vec3Offset (startPoint, (0, 0, monster.MaxStepHeight + .5));

        if (!wallTracer.Trace (traceStartPos, monster.curSector, traceDir, traceLen, 0) || wallTracer.Results.HitType != TRACE_HitWall)
            return null, (0, 0, 0), (0, 0, 0);

        let hitLine = wallTracer.Results.HitLine;
        let wallDir = (hitLine.delta, 0).Unit ();
        let wallNormal = (wallDir.Y, -wallDir.X, 0);

        let testPoint = wallTracer.Results.HitPos - traceDir * .01;
        if (S7_Math.PointOnLineSidePrecise (testPoint.X, testPoint.Y, hitLine) == 1)
            wallNormal = -wallNormal;

        return hitLine, wallNormal, wallDir;
    }

    override bool WillViolate (S7_MonsterBase monster, out S7_MonsterSteering_Path path) {
        return WillViolate2 (monster, path);
        //if (path.Length () != 2) return false;
        if (path.Length () < 2)
            return false;

        let level = monster.level;
        let wallTracer = monster.wallTracer;
        let changedAny = false;

        wallTracer.LineBlockFlags = S7_ActorExtensions.GetSelfBlockLineFlags (monster);
        wallTracer.CanDropoff = monster.S7_CanFly ();
        wallTracer.MaxDropOffHeight = monster.MaxDropOffHeight;

        S7_MonsterSteering_Path newPath;
        newPath.Clear ();
        newPath.Copy (path);

        let pathLen = newPath.Length ();
        for (int i = 0; i < pathLen - 1; i++) {
            let startPoint = newPath.Index (i);
            let endPoint = newPath.Index (i + 1);

            if (startPoint ~== endPoint)
                continue;

            /*bool traceSuccess;
            Vector2 closestPos;
            Vector3 wallNormal;
            Vector3 wallDir;
            [traceSuccess, closestPos, wallNormal, wallDir] = TraceLine (monster, startPoint, endPoint);
            if (!traceSuccess)
                continue;

            changedAny = true;

            let offsLen = monster.radius;
            let offsNorm = wallNormal;
            let offsFwd = wallDir;
            let otherEndPoint = (closestPos, endPoint.Z) + offsNorm * offsLen;

            if (level.Vec3Diff (startPoint, otherEndPoint).Length () <= monster.radius && i > 0) {
                let prevStartPoint = newPath.Index (i - 1);
                if (!(prevStartPoint ~== startPoint)) {
                    let newOffs = -level.Vec3Offset (prevStartPoint, startPoint).Unit () * monster.radius * 5;
                    newPath.Insert (i + 1, level.Vec3Offset (startPoint, newOffs));

                    i--;
                } else
                    newPath.Insert (i + 1, (otherEndPoint.XY, endPoint.Z));
            } else
                newPath.Insert (i + 1, (otherEndPoint.XY, endPoint.Z));*/

            let [hitLine, wallNormal, wallDir] = TraceLine2 (monster, startPoint, endPoint);
            if (hitLine == null)
                continue;

            changedAny = true;

            let offsLen = monster.radius;
            let projectedPos = hitLine.v1.p + wallDir.XY * (wallDir.XY dot (endPoint.XY - hitLine.v1.p));
            let otherEndPoint = projectedPos + wallNormal.XY * offsLen;

            /*if (level.Vec2Diff (startPoint.XY, otherEndPoint).Length () <= monster.radius && i > 0) {
                let prevStartPoint = newPath.Index (i - 1);
                if (!(prevStartPoint ~== startPoint)) {
                    let newOffs = -level.Vec3Offset (prevStartPoint, startPoint).Unit () * monster.radius * 5;
                    newPath.Insert (i + 1, level.Vec3Offset (startPoint, newOffs));

                    i--;
                } else
                    newPath.Insert (i + 1, (otherEndPoint, endPoint.Z));
            } else*/
                newPath.Insert (i + 1, (otherEndPoint, endPoint.Z));
                if (i + 1 + 1 < newPath.Length ())
                    newPath.Delete (i + 1 + 1, newPath.Length () - (i + 1 + 1));

            pathLen = newPath.Length ();
            //wallTracer.CheckWallPassable (line);
            //break;
            if (newPath.Length () > 150) {
                //Console.Printf("oops");
                break;
            }
        }

        if (changedAny) {
            newPathStored.Move (newPath);
            return true;
        }

        return false;
    }

    bool WillViolate2 (S7_MonsterBase monster, out S7_MonsterSteering_Path path) {
        //if (path.Length () != 2) return false;
        if (path.Length () < 2)
            return false;

        let level = monster.level;
        let wallTracer = monster.wallTracer;
        let changedAny = false;

        wallTracer.LineBlockFlags = S7_ActorExtensions.GetSelfBlockLineFlags (monster);
        wallTracer.CanDropoff = monster.S7_CanFly ();
        wallTracer.MaxDropOffHeight = monster.MaxDropOffHeight;

        let pathLen = path.Length ();
        for (int i = 0; i < pathLen - 1; i++) {
            let startPoint = path.Index (i);
            let endPoint = path.Index (i + 1);

            if (startPoint ~== endPoint)
                continue;

            /*bool traceSuccess;
            Vector2 closestPos;
            Vector3 wallNormal;
            Vector3 wallDir;
            [traceSuccess, closestPos, wallNormal, wallDir] = TraceLine (monster, startPoint, endPoint);
            if (!traceSuccess)
                continue;

            let offsLen = monster.radius;
            let offsNorm = wallNormal;
            let offsFwd = wallDir;
            let otherEndPoint = (closestPos, endPoint.Z) + offsNorm * offsLen;

            if (level.Vec3Diff (startPoint, otherEndPoint).Length () <= monster.radius && i > 0) {
                let prevStartPoint = path.Index (i - 1);
                if (!(prevStartPoint ~== startPoint))
                    newPosStored = -level.Vec3Offset (prevStartPoint, startPoint).Unit () * monster.radius * 5;
                else
                    newPosStored = (otherEndPoint.XY, endPoint.Z);
            } else
                newPosStored = (otherEndPoint.XY, endPoint.Z)*/

            let [hitLine, wallNormal, wallDir] = TraceLine2 (monster, startPoint, endPoint);
            if (hitLine == null)
                continue;

            let offsLen = monster.radius;
            let projectedPos = hitLine.v1.p + wallDir.XY * (wallDir.XY dot (endPoint.XY - hitLine.v1.p));
            let otherEndPoint = projectedPos + wallNormal.XY * offsLen;

            /*if (level.Vec2Diff (startPoint.XY, otherEndPoint).Length () <= monster.radius && i > 0) {
                let prevStartPoint = path.Index (i - 1);
                if (!(prevStartPoint ~== startPoint)) {
                    let newOffs = -level.Vec3Offset (prevStartPoint, startPoint).Unit () * monster.radius * 5;
                    newPosStored = level.Vec3Offset (startPoint, newOffs);
                } else
                    newPosStored = (otherEndPoint, endPoint.Z);
            } else*/
                newPosStored = (otherEndPoint, endPoint.Z);

            changedAny = true;
            break;
        }

        return changedAny;
    }

    override void Suggest (S7_MonsterBase monster, out S7_MonsterSteering_Path path, out S7_MonsterSteering_Goal goal) {
        goal.WithPosition (newPosStored);
    }
}

class S7_MonsterSteering_WallAvoidanceConstraint : S7_MonsterSteering_Constraint {
    const FeelersCount = 9;
    static const double FeelerAngles [] = {
        0, // The first feeler must always be 0.
        -19.6875, 19.6875,
        -39.375, 39.375,
        -59.0625, 59.0625,
        -78.75, 78.75
    };

    private Vector3 newPosStored;

    static bool, double TraceLine (S7_MonsterBase monster, Vector3 startPos, Vector3 traceDir, double traceLen) {
        let wallTracer = monster.wallTracer;
        if (!wallTracer.Trace (startPos, monster.curSector, traceDir, traceLen, 0) || wallTracer.Results.HitType != TRACE_HitWall)
            return false, 1;

        return true, wallTracer.Results.Fraction;
    }

    override bool WillViolate (S7_MonsterBase monster, out S7_MonsterSteering_Path path) {
        if (path.Length () < 2)
            return false;

        let level = monster.level;
        let wallTracer = monster.wallTracer;

        wallTracer.LineBlockFlags = S7_ActorExtensions.GetSelfBlockLineFlags (monster);
        wallTracer.CanDropoff = monster.S7_CanFly ();
        wallTracer.MaxDropOffHeight = monster.MaxDropOffHeight;

        Vector2 feelerDirs [FeelersCount];
        double feelerLens [FeelersCount];
        double feelersDistToGoal [FeelersCount];

        let pathLen = path.Length ();
        for (let pathIdx = 0; pathIdx < pathLen - 1; pathIdx++) {
            let segmentStartPos = path.Index (pathIdx);
            let segmentEndPos = path.Index (pathIdx + 1);
            let segmentDiff = level.Vec3Diff (segmentStartPos, segmentEndPos);

            if (segmentDiff dot segmentDiff ~== 0)
                continue;

            let segmentLength = segmentDiff.Length ();
            let segmentDir = segmentDiff / segmentLength;

            let traceStartPos = level.Vec3Offset (segmentStartPos, (0, 0, monster.MaxStepHeight + .5));

            bool traceSuccess;
            // Straight trace is calculated manually.
            feelerDirs [0] = segmentDir.XY;
            [traceSuccess, feelerLens [0]] = TraceLine (monster, traceStartPos, segmentDir, segmentLength);
            feelersDistToGoal [0] = 1;
            // Early out if the segment direction isn't obstructed.
            if (!traceSuccess)
                continue;

            let chosenFeeler = -1;
            for (let i = 1; i < FeelersCount; i++) {
                let feelerDir = (Actor.RotateVector (segmentDir.XY, FeelerAngles [i]), segmentDir.Z);
                feelerDirs [i] = feelerDir.XY;

                [traceSuccess, feelerLens [i]] = TraceLine (monster, traceStartPos, feelerDir, segmentLength);
                feelersDistToGoal [i] = feelerDir.XY dot segmentDir.XY;
            }

            let highestScore = -double.infinity;
            for (let i = 0; i < FeelersCount; i++) {
                let feelerScore = feelersDistToGoal [i] * feelerLens [i];

                if (feelerScore < highestScore)
                    continue;

                highestScore = feelerScore;
                chosenFeeler = i;
            }

            // This doesn't sound possible but better safe than sorry.
            if (chosenFeeler < 0)
                return false;

            newPosStored = level.Vec3Offset (segmentStartPos, (feelerDirs [chosenFeeler] * feelerLens [chosenFeeler] * segmentLength, 0));
            return true;
        }

        return false;
    }

    override void Suggest (S7_MonsterBase monster, out S7_MonsterSteering_Path path, out S7_MonsterSteering_Goal goal) {
        goal.WithPosition (newPosStored);
    }
}

class S7_MonsterSteering_AvoidObstaclesConstraint : S7_MonsterSteering_Constraint {
    private double marginFactor;

    private Vector3 newPosStored;

    S7_MonsterSteering_AvoidObstaclesConstraint WithMargin (double newMargin) {
        marginFactor = newMargin;
        return self;
    }

    override bool WillViolate (S7_MonsterBase monster, out S7_MonsterSteering_Path path) {
        Array<Actor> checkList;
        Array<int> batchStartIndex; // Stores which was the first index for that split.
        Array<int16> batchCounts;

        let marginFactor = self.marginFactor;
        let radius = monster.Radius;
        let outerRadius = monster.Radius * S7_Math.SqrtTwo;
        let height = monster.Height;
        let level = monster.Level;
        let splitSize = S7_Math.SqrtTwo * monster.Radius * marginFactor;

        let pathLen = path.Length ();
        for (let pathIdx = 0; pathIdx < pathLen - 1; pathIdx++) {
            checkList.Clear ();
            batchStartIndex.Clear ();
            batchCounts.Clear ();

            let segStartPos = path.Index (pathIdx);
            let segEndPos = path.Index (pathIdx + 1);

            let segDiff = level.Vec3Diff (segStartPos, segEndPos);
            let segLen = segDiff.Length ();

            if (segLen ~== 0)
                continue;

            let segDir = segDiff / segLen;

            let startPoint = level.Vec3Offset (segStartPos, segDir * splitSize / 2.);
            let stepCount = segLen / (splitSize / 2.);
            let stepCountInt = ceil (stepCount);
            let stepVec = segDir * splitSize / 2.;

            if (segLen < splitSize)
                stepCount = 1;

            batchStartIndex.Reserve (stepCountInt);
            batchCounts.Reserve (stepCountInt);
            for (let batchI = 0; batchI < stepCountInt; batchI++) {
                batchStartIndex [batchI] = checkList.Size ();

                let centerPoint = level.Vec3Offset (startPoint, stepVec * min (batchI, stepCount));
                let it = BlockThingsIterator.CreateFromPos (
                    centerPoint.X, centerPoint.Y, centerPoint.Z,
                    monster.Height, splitSize,
                    false
                );

                for (let other = it.Thing; it.Next (); other = it.Thing) {
                    if (
                        !other ||
                        other == monster || // Skip self.
                        !other.bSolid || other.bNoClip || other.bNoInteraction || // Skip things non-solid objects.
                        other.bMissile || // Skip projectiles.
                        other.Radius <= S7_Math.VM_Epsilon || other.Height <= S7_Math.VM_Epsilon ||
                        other.bCorpse || other.bKilled || // Skip corpses and other dead actors.
                        other.bIsMonster || other is 'S7_MonsterBase' || // Skip other monsters. (that's for avoidance)
                        (other.player && other == other.player.mo) // Skip players (but not voodoo dolls)
                    )
                        continue;

                    checkList.Push (other);
                }

                batchCounts [batchI] = checkList.Size () - batchStartIndex [batchI];
            }

            for (let batchI = 0; batchI < stepCountInt; batchI++) {
                break;
                let batchStart = batchStartIndex [batchI];
                let batchCount = batchCounts [batchI];

                for (let batchJ = 0; (batchJ < batchI) & (batchCount > 0); batchJ++) {
                    let otherBatchStart = batchStartIndex [batchJ];
                    let otherBatchEnd = otherBatchStart + batchCounts [batchJ];

                    for (let i = batchStart; i < batchStart + batchCount; i++) {
                        let iObj = checkList [i];
                        for (let j = otherBatchStart; j = otherBatchEnd; j++) {
                            if (iObj == checkList [j]) {
                                if (i - batchStart < batchCount - 1)
                                    checkList [i] = checkList [batchStart + batchCount - 1];

                                batchCount--;
                                i--;

                                break;
                            }
                        }
                    }
                }

                batchCounts [batchI] = batchCount;
            }

            let closestDist = double.infinity;
            Actor closestActor = null;
            let closestActorOffset = (0, 0, 0);
            for (let batchI = 0; batchI < stepCountInt; batchI++) {
                let batchStart = batchStartIndex [batchI];
                let batchEnd = batchStart + batchCounts [batchI];

                for (let actI = batchStart; actI < batchEnd; actI++) {
                    let other = checkList [actI];

                    // Project the other actor onto the path segment.
                    let startDiff = level.Vec3Diff (segStartPos, other.Pos);
                    let t = segDir dot startDiff;

                    if (t > closestDist)
                        continue;
                    if (t < S7_Math.VM_Epsilon || t - segLen > S7_Math.VM_Epsilon)
                        continue;

                    let relativePos = segStartPos + startDiff; // So we can omit a lot of portal checks.
                    let projPos = segStartPos + segDir * t;

                    // Calculate the difference between the closest position and the sum of the ("real") radii.
                    let posDiff = relativePos - projPos;
                    let sumRadii = outerRadius + other.Radius * S7_Math.SqrtTwo;

                    // Skip if we're definitely not colliding on the XY plane.
                    if ((posDiff.XY dot posDiff.XY) > sumRadii * sumRadii)
                        continue;

                    // Skip if we can't be colliding on the Z axis.
                    if (projPos.Z + height < relativePos.Z || relativePos.Z + other.height < relativePos.Z)
                        continue;

                    // If we had a possible hit, check if we can collide with that actor.
                    if (monster.CheckPosition (other.Pos.XY, actorsOnly: true))
                        continue;

                    closestDist = t;
                    closestActor = other;
                    closestActorOffset = posDiff;
                }
            }

            if (closestActor) {
                let projPos = segStartPos + segDir * closestDist;
                let relativePos = projPos + closestActorOffset;
                let offsLen = closestActorOffset.XY.Length ();

                let newOffsDir = (0, 0);
                // Check if we pass through the center point of the obstacle.
                if (offsLen ~== 0) {
                    // Any vector at a right angle to the path segment will work.
                    newOffsDir = (segDir.Y, -segDir.X);
                    Console.Printf ("a");
                } else {
                    newOffsDir = -closestActorOffset.XY / offsLen;
                    Console.Printf ("b");
                }

                let sumRadii = (outerRadius + closestActor.Radius * S7_Math.SqrtTwo) * marginFactor;
                newPosStored = level.Vec3Offset (closestActor.Pos, (newOffsDir * sumRadii, 0));

                return true;
            }
        }

        return false;
    }

    override void Suggest (S7_MonsterBase monster, out S7_MonsterSteering_Path path, out S7_MonsterSteering_Goal goal) {
        goal.WithPosition (newPosStored);
    }
}

class S7_MonsterSteering_BasicActuator : S7_MonsterSteering_Actuator {
    override void GetPath (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal, out S7_MonsterSteering_Path path) {
        path.Clear ();

        if (!goal.HasPosition)
            return;

        path.Push (monster.Pos);
        path.Push (goal.Position);
    }

    override Vector3, double Output (S7_MonsterBase monster, out S7_MonsterSteering_Path path, out S7_MonsterSteering_Goal goal) {
        if (path.Length () < 2 && !goal.hasVelocity && !goal.HasAngle && !goal.HasAngularVel)
            return (0, 0, 0), 0;

        let maxSpeed = monster.Speed / Thinker.TicRate;
        let maxAccel = monster.MaxAccel / Thinker.TicRate;
        let maxTurnSpeed = monster.MaxTurnSpeed / Thinker.TicRate;
        let maxTurnAccel = monster.MaxTurnAccel / Thinker.TicRate;
        let canFly = monster.S7_CanFly ();

        // Targets
        let hasVelocity = false;
        Vector3 targetVel = (0, 0, 0);
        let hasAngle = goal.HasAngle;
        let targetAngle = goal.Angle;

        let hasPathVel = false;
        Vector3 pathVel;
        if (path.Length () > 1) {
            let pathDiff = !canFly
                ? (monster.level.Vec2Diff (path.IndexXY (0), path.IndexXY (1)), 0)
                : monster.level.Vec3Diff (path.Index (0), path.Index (1));
            let pathLen = pathDiff.Length ();
            let pathDir = pathDiff / pathLen;

            let slowRadius = monster.Radius + maxSpeed * 2;
            pathVel = pathDir * maxSpeed * clamp (pathLen / slowRadius, 0, 1);

            hasVelocity = true;
            hasPathVel = true;
        }

        if (goal.HasVelocity) {
            if (hasPathVel) {
                let goalVelLen = goal.Velocity.Length ();
                let pathVelLen = pathVel.Length ();

                let goalVelDir = goal.Velocity / goalVelLen;
                let pathVelDir = pathVel / pathVelLen;
                let velDot = abs (goalVelDir dot pathVelDir);

                let newVelDir = S7_Math.Lerp3 (pathVelDir + goalVelDir, goalVelDir, velDot).Unit ();
                let newVelLen = S7_Math.Lerp (pathVelLen + goalVelLen, goalVelLen, velDot);

                targetVel = newVelDir * newVelLen;
            } else
                targetVel = goal.Velocity;

            hasVelocity = true;
        } else if (hasPathVel) {
            targetVel = pathVel;
            if (!hasAngle) {
                targetAngle = atan2 (targetVel.Y, targetVel.X);
                hasAngle = true;
            }

            hasVelocity = true;
        }

        let angularVel = goal.AngularVel;
        let hasAngularVel = goal.HasAngularVel;
        if (!hasAngularVel && hasAngle) {
            let angleDiff = Actor.Normalize180 (targetAngle - Actor.Normalize180 (monster.Angle));
            let slowRadius = maxTurnSpeed * 4;
            angularVel = maxTurnSpeed * clamp (abs (angleDiff) / slowRadius, 0, 1);

            if (angleDiff < 0)
                angularVel = -angularVel;
            hasAngularVel = true;
        }

        let linearAccel = (0, 0, 0);
        let angularAccel = 0.;
        if (hasVelocity) {
            targetVel = S7_Math.ClampVec3Length (targetVel, maxSpeed);
            if (!canFly)
                linearAccel = (S7_Math.ClampVec2Length (targetVel.XY - monster.Vel.XY, maxAccel), 0);
            else
                linearAccel = S7_Math.ClampVec3Length (targetVel - monster.Vel, maxAccel);
        }
        if (hasAngularVel)
            angularAccel = clamp (angularVel - monster.AngularVelocity, -maxTurnAccel, maxTurnAccel);

        //Console.Printf ("LVel: %f, LAccel: %f", targetVel.Length (), linearAccel.Length ());
        //Console.Printf ("AVel: %f, AAccel: %f", angularVel, angularAccel);

        return linearAccel, angularAccel;
    }
}

class S7_MonsterSteering_BasicDeadlockActuator : S7_MonsterSteering_Deadlock {
    override Vector3, double Steer (S7_MonsterBase monster) {
        let maxSpeed = monster.Speed / Thinker.TicRate;
        let maxAccel = monster.MaxAccel / Thinker.TicRate;
        let maxTurnSpeed = monster.MaxTurnSpeed / Thinker.TicRate;
        let maxTurnAccel = monster.MaxTurnAccel / Thinker.TicRate;

        let curAngle = Actor.Normalize180 (monster.Angle);
        let targetAngle = Actor.Normalize180 (curAngle + random [asd] (-22, 22));
        let targetVel = Actor.AngleToVector (targetAngle, maxSpeed);

        let angleDiff = Actor.Normalize180 (targetAngle - curAngle);
        let slowRadius = maxTurnSpeed * 4;
        let angularVel = maxTurnSpeed * clamp (abs (angleDiff) / slowRadius, 0, 1);

        let linearAccel = S7_Math.ClampVec2Length (targetVel - monster.Vel.XY, maxAccel);
        let angularAccel = clamp (angularVel - monster.AngularVelocity, -maxTurnAccel, maxTurnAccel);

        return (linearAccel, 0), angularAccel;
    }
}

struct S7_MonsterSteering_Goal {
    bool HasPosition;
    Vector3 Position;

    bool HasVelocity;
    Vector3 Velocity;

    bool HasAngle;
    double Angle;

    bool HasAngularVel;
    double AngularVel;

    void Initialize () {
        HasPosition = false;
        Position = (0, 0, 0);

        HasVelocity = false;
        Velocity = (0, 0, 0);

        HasAngle = false;
        Angle = 0;

        HasAngularVel = false;
        AngularVel = 0;
    }

    void Copy (out S7_MonsterSteering_Goal other) {
        HasPosition = other.HasPosition;
        Position = other.Position;

        HasVelocity = other.HasVelocity;
        Velocity = other.Velocity;

        HasAngle = other.HasAngle;
        Angle = other.Angle;

        HasAngularVel = other.HasAngularVel;
        AngularVel = other.AngularVel;
    }

    void WithPosition (Vector3 pos) {
        HasPosition = true;
        Position = pos;
    }

    void WithVelocity (Vector3 vel) {
        HasVelocity = true;
        Velocity = vel;
    }

    void WithAngle (double ang) {
        HasAngle = true;
        Angle = ang;
    }

    void WithAngularVel (double angVel) {
        HasAngularVel = true;
        AngularVel = angVel;
    }
}

struct S7_MonsterSteering_Path {
    private Array<double> pointsX;
    private Array<double> pointsY;
    private Array<double> pointsZ;

    Vector3 Index (int i) {
        return (pointsX [i], pointsY [i], pointsZ [i]);
    }

    Vector2 IndexXY (int i) {
        return (pointsX [i], pointsY [i]);
    }

    int Length () {
        return pointsX.Size ();
    }

    void Push (Vector3 p) {
        pointsX.Push (p.X);
        pointsY.Push (p.Y);
        pointsZ.Push (p.Z);
    }

    void Insert (uint index, Vector3 p) {
        pointsX.Insert (index, p.X);
        pointsY.Insert (index, p.Y);
        pointsZ.Insert (index, p.Z);
    }

    void Delete (uint index, int n = 1) {
        pointsX.Delete (index, n);
        pointsY.Delete (index, n);
        pointsZ.Delete (index, n);
    }

    void Clear () {
        pointsX.Clear ();
        pointsY.Clear ();
        pointsZ.Clear ();
    }

    void ShrinkToFit () {
        pointsX.ShrinkToFit ();
        pointsY.ShrinkToFit ();
        pointsZ.ShrinkToFit ();
    }

    void Copy (S7_MonsterSteering_Path other) {
        pointsX.Copy (other.pointsX);
        pointsY.Copy (other.pointsY);
        pointsZ.Copy (other.pointsZ);
    }

    void Move (S7_MonsterSteering_Path other) {
        pointsX.Move (other.pointsX);
        pointsY.Move (other.pointsY);
        pointsZ.Move (other.pointsZ);
    }
}

class S7_MonsterSteering_Pipeline play {
    const ConstraintSteps = 5;

    private S7_MonsterBase monster;

    private Array<S7_MonsterSteering_Targetter> targetters;
    private Array<S7_MonsterSteering_Decomposer> decomposers;
    private Array<S7_MonsterSteering_Constraint> constraints;
    private S7_MonsterSteering_Actuator actuator;
    private S7_MonsterSteering_Deadlock deadlockActuator;

    static S7_MonsterSteering_Pipeline Create (S7_MonsterBase monster) {
        let ret = new ('S7_MonsterSteering_Pipeline');
        ret.monster = monster;
        return ret;
    }

    S7_MonsterSteering_Pipeline AddTargetter (S7_MonsterSteering_Targetter targetter) {
        targetters.Push (targetter);
        return self;
    }

    S7_MonsterSteering_Pipeline AddDecomposer (S7_MonsterSteering_Decomposer decomposer) {
        decomposers.Push (decomposer);
        return self;
    }

    S7_MonsterSteering_Pipeline AddConstraint (S7_MonsterSteering_Constraint constraint) {
        constraints.Push (constraint);
        return self;
    }

    S7_MonsterSteering_Pipeline WithActuator (S7_MonsterSteering_Actuator newActuator) {
        actuator = newActuator;
        return self;
    }

    S7_MonsterSteering_Pipeline WithDeadlockActuator (S7_MonsterSteering_Deadlock deadlock) {
        deadlockActuator = deadlock;
        return self;
    }

    void ShowPath (out S7_MonsterSteering_Path path) {
        return;
        let stepLen = S7C_MapUnitsPerMeter * .5;
        for (int i = 0; i < path.Length () - 1; i++) {
            let startPos = path.Index (i);
            let endPos = path.Index (i + 1);

            if (startPos ~== endPos)
                continue;

            let stepDir = monster.level.Vec3Diff (startPos, endPos);
            let stepCount = stepDir.Length () / stepLen;
            stepDir = stepDir.Unit ();

            for (int i = int (ceil (stepCount)); i >= 0; i--) {
                let stepPos = monster.level.Vec3Offset (startPos, stepDir * min (i, stepCount) * stepLen);
                let asd = Actor.Spawn ('S7_Asd', stepPos);
                asd.SetState (asd.FindState ('Spawn2'));
                asd.tics = 5;
                asd.scale *= 0.2;
                asd.A_SetRenderstyle (asd.alpha, STYLE_TranslucentStencil);
                asd.SetShade ("00FF00");
            }
        }
    }

    Vector3, double GetSteering () {
        S7_MonsterSteering_Goal goal;

        // Get the top-level goal.
        let targettersCount = targetters.Size ();
        for (int i = 0; i < targettersCount; i++)
            targetters [i].GetGoal (monster, goal);

        // Decompose the top-level goal.
        let decomposersCount = decomposers.Size ();
        for (int i = 0; i < decomposersCount; i++)
            decomposers [i].Decompose (monster, goal);

        // Actuate and constrain.
        S7_MonsterSteering_Path path;
        let constraintsCount = constraints.Size ();
        for (int i = 0; i < ConstraintSteps; i++) {
            actuator.GetPath (monster, goal, path);
            // Check for constraint violation.
            let cIdx = 0;
            for (; cIdx < constraintsCount; cIdx++) {
                let constraint = constraints [cIdx];

                if (constraint.WillViolate (monster, path)) {
                    constraint.Suggest (monster, path, goal);
                    break;
                }
            }

            if (cIdx >= constraintsCount) {
                ShowPath (path);
                Vector3 linearAccel;
                double angularAccel;
                [linearAccel, angularAccel] = actuator.Output (monster, path, goal);
                return linearAccel, angularAccel;
            }
        }

        ShowPath (path);
        Console.Printf ("deadlocked");
        Vector3 linearAccel;
        double angularAccel;
        [linearAccel, angularAccel] = deadlockActuator.Steer (monster);
        return linearAccel, angularAccel;
    }
}