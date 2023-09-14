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
    abstract bool WillViolate (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal);
    abstract void Suggest (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal);
}

class S7_MonsterSteering_Actuator play abstract {
    abstract Vector3, double Output (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal);
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
    private bool closestEndMode;
    private double closestEndMargin;

    private Vector3 newPosStored;

    S7_MonsterSteering_WallFollowingConstraint WithPlainMode () {
        closestEndMode = false;
        return self;
    }

    S7_MonsterSteering_WallFollowingConstraint WithClosestEndMode (double margin) {
        closestEndMode = true;
        closestEndMargin = margin;
        return self;
    }

    override bool WillViolate (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {
        if (!goal.HasPosition)
            return false;

        let startPoint = monster.Pos;
        let endPoint = goal.Position;

        if (startPoint ~== endPoint)
            return false;

        let level = monster.level;
        let wallTracer = monster.wallTracer;

        wallTracer.LineBlockFlags = S7_ActorExtensions.GetSelfBlockLineFlags (monster);
        wallTracer.CanDropoff = monster.S7_CanFly ();
        wallTracer.MaxDropOffHeight = monster.MaxDropOffHeight;

        let traceDiff = level.Vec3Diff (startPoint, endPoint);
        let traceLen = traceDiff.Length ();
        let traceDir = traceDiff / traceLen;

        let traceStartPos = level.Vec3Offset (startPoint, (0, 0, monster.MaxStepHeight + .5));

        if (!wallTracer.Trace (traceStartPos, monster.curSector, traceDir, traceLen, 0) || wallTracer.Results.HitType != TRACE_HitWall)
            return false;

        let hitLine = wallTracer.Results.HitLine;
        let wallDir = hitLine.delta.Unit ();
        let wallNormal = (wallDir.Y, -wallDir.X);

        if (level.PointOnLineSide (wallTracer.Results.HitPos.XY - traceDir.XY * .01, hitLine, true) == 1)
            wallNormal = -wallNormal;

        if (!closestEndMode) {
            let offsLen = monster.radius;
            let newPos = level.Vec2Offset (
                hitLine.v1.p,
                wallDir * (wallDir dot (endPoint.XY - hitLine.v1.p)) + wallNormal * offsLen
            );
            newPosStored = (newPos, endPoint.Z);
        } else {
            let offsNorm = wallNormal;
            let offsNormLen = monster.radius;
            let offsFwd = wallDir;
            let offsFwdLen = monster.radius * S7_Math.SqrtTwo * closestEndMargin;
            Vector2 closestPos;

            let p1Diff = level.Vec2Diff (endPoint.XY, hitLine.v1.p);
            let p2Diff = level.Vec2Diff (endPoint.XY, hitLine.v2.p);
            if ((p2Diff dot p2Diff) < (p1Diff dot p1Diff))
                closestPos = hitLine.v2.p;
            else {
                closestPos = hitLine.v1.p;
                offsFwd = -wallDir;
            }

            newPosStored = (level.Vec2Offset (closestPos, offsNorm * offsNormLen + offsFwd * offsFwdLen), endPoint.Z);
        }

        return true;
    }

    override void Suggest (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {
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

    override bool WillViolate (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {
        if (!goal.HasPosition)
            return false;

        let startPoint = monster.Pos;
        let endPoint = goal.Position;

        if (startPoint ~== endPoint)
            return false;

        let level = monster.level;
        let wallTracer = monster.wallTracer;

        wallTracer.LineBlockFlags = S7_ActorExtensions.GetSelfBlockLineFlags (monster);
        wallTracer.CanDropoff = monster.S7_CanFly ();
        wallTracer.MaxDropOffHeight = monster.MaxDropOffHeight;

        Vector2 feelerDirs [FeelersCount];
        double feelerLens [FeelersCount];
        double feelersDistToGoal [FeelersCount];

        let pathDiff = level.Vec3Diff (startPoint, endPoint);
        let pathLength = pathDiff.Length ();
        let pathDir = pathDiff / pathLength;

        let traceStartPos = level.Vec3Offset (startPoint, (0, 0, monster.MaxStepHeight + .5));

        bool traceSuccess;
        // Straight trace is calculated manually.
        feelerDirs [0] = pathDir.XY;
        [traceSuccess, feelerLens [0]] = TraceLine (monster, traceStartPos, pathDir, pathLength);
        feelersDistToGoal [0] = 1;
        // Early out if the segment direction isn't obstructed.
        if (!traceSuccess)
            return false;

        let chosenFeeler = -1;
        for (let i = 1; i < FeelersCount; i++) {
            let feelerDir = (Actor.RotateVector (pathDir.XY, FeelerAngles [i]), pathDir.Z);
            feelerDirs [i] = feelerDir.XY;

            [traceSuccess, feelerLens [i]] = TraceLine (monster, traceStartPos, feelerDir, pathLength);
            feelersDistToGoal [i] = feelerDir.XY dot pathDir.XY;
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

        newPosStored = level.Vec3Offset (startPoint, (feelerDirs [chosenFeeler] * feelerLens [chosenFeeler] * pathLength, 0));
        return true;
    }

    override void Suggest (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {
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

    override bool WillViolate (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {
        if (!goal.HasPosition)
            return false;

        let pathStartPos = monster.Pos;
        let pathEndPos = goal.Position;

        if (pathStartPos ~== pathEndPos)
            return false;

        Array<Actor> checkList;
        Array<int> batchStartIndex; // Stores which was the first index for that split.
        Array<int16> batchCounts;

        let marginFactor = self.marginFactor;
        let radius = monster.Radius;
        let outerRadius = monster.Radius * S7_Math.SqrtTwo;
        let height = monster.Height;
        let level = monster.Level;
        let splitSize = S7_Math.SqrtTwo * monster.Radius * marginFactor;

        let pathDiff = level.Vec3Diff (pathStartPos, pathEndPos);
        let pathLen = pathDiff.Length ();

        if (pathLen ~== 0)
            return false;

        let pathDir = pathDiff / pathLen;

        let startPoint = level.Vec3Offset (pathStartPos, pathDir * splitSize / 2.);
        let stepCount = pathLen / (splitSize / 2.);
        let stepCountInt = ceil (stepCount);
        let stepVec = pathDir * splitSize / 2.;

        if (pathLen < splitSize)
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
            let batchStart = batchStartIndex [batchI];
            let batchCount = batchCounts [batchI];

            for (let batchJ = 0; (batchJ < batchI) & (batchCount > 0); batchJ++) {
                let otherBatchStart = batchStartIndex [batchJ];
                let otherBatchEnd = otherBatchStart + batchCounts [batchJ];

                for (let i = batchStart + batchCount - 1; i >= batchStart; i--) {
                    let iObj = checkList [i];
                    for (let j = otherBatchStart; j < otherBatchEnd; j++) {
                        if (iObj == checkList [j]) {
                            if (i - batchStart < batchCount - 1)
                                checkList [i] = checkList [batchStart + batchCount - 1];

                            batchCount--;

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

                // Project the other actor onto the path.
                let startDiff = level.Vec3Diff (pathStartPos, other.Pos);
                let t = pathDir dot startDiff;

                if (t > closestDist)
                    continue;
                if (t < S7_Math.VM_Epsilon || t - pathLen > S7_Math.VM_Epsilon)
                    continue;

                let relativePos = pathStartPos + startDiff; // So we can omit a lot of portal checks.
                let projPos = pathStartPos + pathDir * t;

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
            let projPos = pathStartPos + pathDir * closestDist;
            let relativePos = projPos + closestActorOffset;
            let offsLen = closestActorOffset.XY.Length ();

            let newOffsDir = (0, 0);
            // Check if we pass through the center point of the obstacle.
            if (offsLen ~== 0)
                // Any vector at a right angle to the path will work.
                newOffsDir = (pathDir.Y, -pathDir.X);
            else
                newOffsDir = -closestActorOffset.XY / offsLen;

            let sumRadii = (outerRadius + closestActor.Radius * S7_Math.SqrtTwo) * marginFactor;
            newPosStored = level.Vec3Offset (closestActor.Pos, (newOffsDir * sumRadii, 0));

            return true;
        }

        return false;
    }

    override void Suggest (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {
        goal.WithPosition (newPosStored);
    }
}

class S7_MonsterSteering_BasicActuator : S7_MonsterSteering_Actuator {
    override Vector3, double Output (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {
        if (!goal.HasPosition && !goal.HasVelocity && !goal.HasAngle && !goal.HasAngularVel)
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

        let hasPositionVel = false;
        Vector3 posVel;
        if (goal.HasPosition) {
            let posDiff = !canFly
                ? (monster.level.Vec2Diff (monster.Pos.XY, goal.Position.XY), 0)
                : monster.level.Vec3Diff (monster.Pos, goal.Position);
            let posLen = posDiff.Length ();
            let posDir = posDiff / posLen;

            let slowRadius = monster.Radius + maxSpeed * 2;
            posVel = posDir * maxSpeed * clamp (posLen / slowRadius, 0, 1);

            hasVelocity = true;
            hasPositionVel = true;
        }

        if (goal.HasVelocity) {
            if (hasPositionVel) {
                let goalVelLen = goal.Velocity.Length ();
                let posVelLen = posVel.Length ();

                let goalVelDir = goal.Velocity / goalVelLen;
                let posVelDir = posVel / posVelLen;
                let velDot = abs (goalVelDir dot posVelDir);

                let newVelDir = S7_Math.Lerp3 (posVelDir + goalVelDir, goalVelDir, velDot).Unit ();
                let newVelLen = S7_Math.Lerp (posVelLen + goalVelLen, goalVelLen, velDot);

                targetVel = newVelDir * newVelLen;
            } else
                targetVel = goal.Velocity;

            hasVelocity = true;
        } else if (hasPositionVel) {
            targetVel = posVel;
            if (!hasAngle) {
                targetAngle = atan2 (targetVel.Y, targetVel.X);
                hasAngle = true;
            }

            hasVelocity = true;
        }

        let angularVel = goal.AngularVel;
        let hasAngularVel = goal.HasAngularVel;
        if (!hasAngularVel && hasAngle) {
            let angleDiff = Actor.Normalize180 (targetAngle - monster.Angle);
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
        if (hasAngularVel) {
            angularAccel = clamp (angularVel - monster.AngularVelocity, -maxTurnAccel, maxTurnAccel);
        }

        //Console.Printf ("LVel: %f, LAccel: %f", targetVel.Length (), linearAccel.Length ());
        //Console.Printf ("AVel: %f, AAccel: %f", angularVel, angularAccel);

        return linearAccel, angularAccel;
    }
}

class S7_MonsterSteering_BasicDeadlockActuator : S7_MonsterSteering_Deadlock {
    override Vector3, double Steer (S7_MonsterBase monster) {
        let maxSpeed = monster.Speed / Thinker.TicRate;
        let maxAccel = monster.MaxAccel / Thinker.TicRate;

        let targetVel = Actor.AngleToVector (monster.Angle, maxSpeed);
        let linearAccel = S7_Math.ClampVec2Length (targetVel - monster.Vel.XY, maxAccel);

        return (linearAccel, 0), 0;
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

    void ShowGoal (out S7_MonsterSteering_Goal goal) {
        let stepLen = S7C_MapUnitsPerMeter * .5;

        let startPos = monster.Pos;
        Vector3 stepDir;

        if (goal.HasPosition)
            stepDir = monster.level.Vec3Diff (startPos, goal.Position);
        else if (goal.HasVelocity)
            stepDir = goal.Velocity * 5;
        else
            return;

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
        let constraintsCount = constraints.Size ();
        for (int i = 0; i < ConstraintSteps; i++) {
            // Check for constraint violation.
            let cIdx = 0;
            for (; cIdx < constraintsCount; cIdx++) {
                let constraint = constraints [cIdx];

                if (constraint.WillViolate (monster, goal)) {
                    constraint.Suggest (monster, goal);
                    break;
                }
            }

            if (cIdx >= constraintsCount) {
                ShowGoal (goal);
                Vector3 linearAccel;
                double angularAccel;
                [linearAccel, angularAccel] = actuator.Output (monster, goal);
                return linearAccel, angularAccel;
            }
        }

        ShowGoal (goal);
        Vector3 linearAccel;
        double angularAccel;
        [linearAccel, angularAccel] = deadlockActuator.Steer (monster);
        return linearAccel, angularAccel;
    }
}