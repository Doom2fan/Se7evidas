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

extend class S7_MonsterBase {
    const S7_AlignedSeek_TargAngleRadius = 180. / 24.;
    const S7_AlignedSeek_TargAngleSlowRadius = 180. / 16.;
    const S7_Steer_MaxAngularAccel = 10.;

    double S7_Steer_Align (double maxAccel, double curAng, double targAng, double targRadius, double slowRadius) {
        double rotation = DeltaAngle (curAng, targAng);
        double rotationSize = abs (rotation);
        double rotationSign = S7_Math.SignF (rotation);

        double targetVelocity = rotation;
        if (rotationSize < targRadius)
            targetVelocity = 0;
        else if (rotationSize < slowRadius)
            targetVelocity = max (rotationSize / slowRadius, 0.01) * rotationSign;

        double angularAccel = (targetVelocity - angularVelocity);
        angularAccel = clamp (angularAccel, -maxAccel, maxAccel);

        return angularAccel;
    }

    Vector2 S7_Steer_Seek (double maxAccel, Vector2 targPos, double targRadius, double slowRadius) {
        double maxSpeedSquared = maxAccel;

        Vector2 linearAccel;

        let targDiff = level.Vec2Diff (pos.XY, targPos);
        double targetDistSqr = targDiff dot targDiff;
        Vector2 targDir = (0, 0);
        if (!(targDiff ~== (0, 0)))
            targDir = targDiff.Unit ();

        // If we're near the target, stop moving.
        if (targetDistSqr <= targRadius * targRadius)
            return (0, 0);

        double targetHorzDist = sqrt (targetDistSqr);
        double targetSpeed = maxAccel * (min (targetHorzDist, slowRadius) / slowRadius);

        // Calculate linear acceleration.
        linearAccel = targDir * targetSpeed;
        linearAccel = linearAccel - vel.XY;

        // Clamp linear acceleration.
        if (linearAccel dot linearAccel > maxSpeedSquared)
            linearAccel = linearAccel.Unit () * maxAccel;

        return linearAccel;
    }

    Vector2 S7_Steer_CalcPursuePos (double curSpeed, Vector2 targPos, Vector2 targVel, double maxPrediction) {
        double distance = level.Vec2Diff (pos.XY, targPos).Length ();

        double predictedTime;
        if (curSpeed <= distance / maxPrediction)
            predictedTime = maxPrediction;
        else
            predictedTime = distance / curSpeed;

        return level.Vec2Offset (targPos, targVel * predictedTime);
    }

    bool S7_Steer_WallAvoidance_Trace (double distance, double angleOffs, double offsY, double offsZ, out FLineTraceData data) {
        return LineTrace (angle + angleOffs, distance, 0., TRF_ThruActors | TRF_ThruHitscan | TRF_BlockSelf, offsZ, 0., offsY, data);
    }

    static const double FeelersAngles [] = {
        -22.5, 22.5,
        0, 0
    };
    static const double FeelersYOffs [] = {
        0, 0,
        -.8, .8
    };
    S7_TestThing a;
    bool, Vector2 S7_Steer_WallAvoidance (double maxAccel, double curSpeed, double predictionTime) {
        FLineTraceData data;
        Vector2 linearAccel = (0., 0.);
        bool avoidingWalls = false;

        if (!a)
            a = S7_TestThing (Spawn ("S7_TestThing"));

        a.sprite = GetSpriteIndex ("TNT1");
        a.bNotOnAutomap = true;
        for (int i = 0; i < FeelersAngles.Size (); i++) {
            let feelerAngle = FeelersAngles [i];
            let feelerYOffs = FeelersYOffs [i] * radius;

            if (S7_Steer_WallAvoidance_Trace (radius + curSpeed * predictionTime, feelerAngle, feelerYOffs, MaxStepHeight + .5, data)) {
                if (data.HitType == TRACE_HitWall) {
                    let line = data.HitLine;
                    let normal = AngleToVector (VectorAngle (line.delta.X, line.delta.Y) - 90., 1.).Unit ();

                    if (data.LineSide == Line.Back)
                        normal = -normal;

                    let avoidPos = data.HitLocation.XY + normal * radius * 2;
                    S7_ActorExtensions.SetActorPosition (a, (avoidPos, 0));
                    a.sprite = GetSpriteIndex ("AMRK");
                    a.bNotOnAutomap = false;

                    avoidingWalls = true;
                    linearAccel = S7_Steer_Seek (maxAccel, avoidPos, radius * 1, radius * 1.25);
                    break;
                }
            }
        }

        double linearAccelLenSqr = linearAccel dot linearAccel;
        if (linearAccelLenSqr > (maxAccel * maxAccel))
            linearAccel = linearAccel / sqrt (linearAccelLenSqr) * maxAccel;

        return avoidingWalls, linearAccel;
    }

    virtual void S7_DoSteering (double maxAccel, Actor targAct, double targRadius, double slowRadius) {
        Vector2 startVel = vel.XY;
        double startAngularVel = angularVelocity;
        double curSpeed = vel.XY.Length ();

        Vector2 linearAccel; double angularAccel;

        let targPos = S7_Steer_CalcPursuePos (curSpeed, targAct.pos.XY, targAct.vel.XY, 5);

        // Pursue the target.
        linearAccel = S7_Steer_Seek (maxAccel, targPos, targRadius, slowRadius);

        // Avoid walls.
        bool avoidingWalls; Vector2 wallAvoidLinearAccel;
        [avoidingWalls, wallAvoidLinearAccel] = S7_Steer_WallAvoidance (maxAccel, curSpeed, 5);
        if (avoidingWalls)
            vel += linearAccel + wallAvoidLinearAccel;
        else
            vel += linearAccel;

        // Face movement direction or target.
        double targAng;
        if (!(vel.XY ~== (0, 0)))
            targAng = atan2 (vel.Y, vel.X);
        else if (!(pos.XY ~== targAct.pos.XY))
            targAng = AngleTo (targAct);
        else
            targAng = Normalize180 (angle);

        angularAccel = S7_Steer_Align (S7_Steer_MaxAngularAccel, angle, targAng, S7_AlignedSeek_TargAngleRadius, S7_AlignedSeek_TargAngleSlowRadius);
        angularVelocity += angularAccel;

        linearAccel = vel.XY - startVel;
        if (linearAccel dot linearAccel > (maxAccel * maxAccel))
            linearAccel = linearAccel.Unit () * maxAccel;

        angularAccel = angularVelocity - startAngularVel;
        if (angularAccel > S7_Steer_MaxAngularAccel)
            angularAccel = S7_Math.SignF (angularAccel) * S7_Steer_MaxAngularAccel;

        vel.XY = startVel + linearAccel;
        angularVelocity = startAngularVel + angularAccel;
    }
}