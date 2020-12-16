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

extend class S7_MonsterBase {
    double S7_Steer_Align (double maxAccel, double curAng, double targAng, double targRadius, double slowRadius) {
        double rotation = DeltaAngle (curAng, targAng);
        double rotationSize = abs (rotation);

        if (rotationSize < targRadius)
            return 0;

        rotation = maxAccel * (min (rotationSize, slowRadius) / slowRadius) * (rotation / rotationSize);

        double angularAccel = (rotation - angularVelocity);
        //angularAccel = clamp (angularAccel, -maxAccel, maxAccel);

        return angularAccel;
    }

    Vector2, double S7_DoSteering (double maxAccel, Actor targAct, double targRadius, double slowRadius) {
        double maxSpeedSquared = maxAccel;

        Vector2 linearAccel;
        double angularAccel;

        let targDiff = level.Vec3Diff (self.pos, level.Vec3Offset (targAct.pos, targAct.vel));
        double targetHorzDistSqr = targDiff.XY dot targDiff.XY;

        // If we're near the target, just face it.
        if (targetHorzDistSqr <= targRadius * targRadius) {
            Vector2 targDir = (0, 0);

            if (!(targDiff.XY ~== (0, 0)))
                targDir = targDiff.XY.Unit ();

            double targAng = !(targDir ~== (0, 0)) ? atan2 (targDir.Y, targDir.X) : angle;

            angularAccel = S7_Steer_Align (10, angle, targAng, 11.25, 45);

            return (0, 0), angularAccel;
        }

        double targetHorzDist = sqrt (targetHorzDistSqr);
        double targetSpeed = maxAccel * (min (targetHorzDist, slowRadius) / slowRadius);

        // Calculate linear acceleration.
        linearAccel = targDiff.XY.Unit () * targetSpeed;
        linearAccel = linearAccel - vel.XY;

        // Clamp linear acceleration.
        if (linearAccel dot linearAccel > maxSpeedSquared)
            linearAccel = linearAccel.Unit () * maxAccel;

        let nextVel = vel.XY + linearAccel;

        // Calculate target angle
        double targAng = !(nextVel ~== (0, 0)) ? atan2 (nextVel.Y, nextVel.X) : angle;

        angularAccel = S7_Steer_Align (10, angle, targAng, 11.25, 45);

        return linearAccel, angularAccel;
    }
}