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
    override void GetGoal (S7_MonsterBase monster, out S7_MonsterSteering_Goal goal) {
        let goalAct = monster.S7_Chase_GetMovementGoal ();
        if (!goalAct)
            return;

        goal.WithPosition (goalAct.Pos);
    }
}

class S7_MonsterSteering_AvoidWallsConstraint : S7_MonsterSteering_Constraint {
    S7_MonsterSteering_Path newPathStored;

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

        if (wallTracer.Results.Side == Line.Back)
            wallNormal = -wallNormal;

        let p1Diff = level.Vec2Diff (endPoint.XY, hitLine.v1.p);
        let p2Diff = level.Vec2Diff (endPoint.XY, hitLine.v2.p);
        if ((p2Diff dot p2Diff) < (p1Diff dot p1Diff))
            return true, hitLine.v2.p, wallNormal, wallDir;

        return true, hitLine.v1.p, wallNormal, -wallDir;
    }

    override bool WillViolate (S7_MonsterBase monster, out S7_MonsterSteering_Path path) {
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

        for (int i = 0; i < newPath.Length () - 1; i++) {
            let startPoint = newPath.Index (i);
            let endPoint = newPath.Index (i + 1);

            if (startPoint ~== endPoint)
                continue;

            bool traceSuccess;
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
                newPath.Insert (i + 1, (otherEndPoint.XY, endPoint.Z));

            //wallTracer.CheckWallPassable (line);

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

    override void Suggest (S7_MonsterBase monster, out S7_MonsterSteering_Path path, out S7_MonsterSteering_Goal goal) {
        path.Move (newPathStored);
        newPathStored.Clear ();
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
        if (path.Length () < 2)
            return (0, 0, 0), 0;

        if (!S7_CanFly ()) {
            let pathDir = monster.level.Vec2Diff (path.Index (0).XY, path.Index (1).XY).Unit ();

            if (pathDir ~== (0, 0, 0))
                return (0, 0, 0), 0;

            let maxSpeed = monster.Speed;
            let curVel = monster.Vel;
            let targetVel = pathDir * maxSpeed;

            let linearAccel = targetVel - monster.Vel.XY;
            let linearAccelSqr = linearAccel dot linearAccel;
            if (linearAccelSqr > (maxSpeed * maxSpeed))
                linearAccel / sqrt (linearAccelSqr) * maxSpeed

            return linearAccel, atan2 (pathDir.Y, pathDir.X) - monster.Angle;
        } else {
            let pathDir = monster.level.Vec3Diff (path.Index (0), path.Index (1)).Unit ();

            if (pathDir ~== (0, 0, 0))
                return (0, 0, 0), 0;

            let maxSpeed = monster.Speed;
            let curVel = monster.Vel;
            let targetVel = pathDir * maxSpeed;

            let linearAccel = targetVel - monster.Vel;
            let linearAccelSqr = linearAccel dot linearAccel;
            if (linearAccelSqr > (maxSpeed * maxSpeed))
                linearAccel / sqrt (linearAccelSqr) * maxSpeed

            return linearAccel, atan2 (pathDir.Y, pathDir.X) - monster.Angle;
        }
    }
}

class S7_MonsterSteering_BasicDeadlockActuator : S7_MonsterSteering_Deadlock {
    override Vector3, double Steer (S7_MonsterBase monster) {
        let targetVel = (Actor.AngleToVector (monster.angle, monster.Speed), 0);

        let maxSpeed = monster.Speed;
        let linearAccel = targetVel - monster.Vel.XY;
        let linearAccelSqr = linearAccel dot linearAccel;
        if (linearAccelSqr > (maxSpeed * maxSpeed))
            return linearAccel / sqrt (linearAccelSqr) * maxSpeed, 0;

        return linearAccel, 0;
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
        actuator.GetPath (monster, goal, path);
        for (int i = 0; i < ConstraintSteps; i++) {
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
                //ShowPath (path);
                Vector3 linearAccel;
                double angularAccel;
                [linearAccel, angularAccel] = actuator.Output (monster, path, goal);
                return linearAccel, angularAccel;
            }
        }

        //ShowPath (path);
        Vector3 linearAccel;
        double angularAccel;
        [linearAccel, angularAccel] = deadlockActuator.Steer (monster);
        return linearAccel, angularAccel;
    }
}