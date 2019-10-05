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
    virtual Actor StepEffects (Vector3 initialPos, Vector3 stepDiff, Vector3 realVel) {
        Class<Actor> trail = MissileName;

        if (!trail)
            return null;

        Vector3 finalPos = level.Vec3Offset (initialPos, stepDiff);

        double realFloorZ = GetZAt (finalPos.X, finalPos.Y, flags: GZF_AbsolutePos | GZF_AbsoluteAng);

        finalPos.Z -= 8;
        if (finalPos.Z < realFloorZ)
            finalPos.Z = realFloorZ;
        // Do not clip this offset to the floor.
        finalPos.Z += missileHeight;

        Actor act = Spawn (trail, finalPos, ALLOW_REPLACE);

        if (!act)
            return null;

        if (bGetOwner && target != null)
            act.target = target;
        else
            act.target = self;

        act.angle = angle;
        act.pitch = pitch;

        return act;
    }

    void SpawnEffects (Vector3 initialPos, double dist, Vector3 stepSize) {
        double interval = radius;
        if (effectStepInterval >= 0)
            interval = effectStepInterval;

        if (effectStepMul < 0 ||
            interval <= 0 || dist <= 0
        ) {
            return;
        }

        Vector3 dirVec = stepSize.Unit ();

        if (effectsStepsMode == EFXStepMode_MapUnit) {
            Vector3 frac = dirVec * interval;
            int count = int ((dist / interval));
            Vector3 initialDist = (dirVec * dist) - (count * frac);

            for (int i = 0; i < count; i++) {
                Vector3 curDist = initialDist + (frac * i);
                double diff = abs (curDist.Length ());

                if (diff > dist)
                    break;

                StepEffects (initialPos, curDist, stepSize);
            }
        } else {
            if (stepSize.X != stepSize.X ||
                stepSize.Y != stepSize.Y ||
                stepSize.XY.Length () <= 0
            ) {
                return;
            }

            double count;
            if (effectsStepsMode == EFXStepMode_FastProj) {
                count = 8;
                while (abs (stepSize.X) > interval * count || abs (stepSize.Y) > interval * count) {
                    if (count == double.infinity || count == -double.infinity) {
                        if (S7_DebugMode)
                            Console.Printf ("S7_Projectile.SpawnEffects: count overflowed");

                        return;
                    }
                    count += count;
                }
            } else
                count = stepSize.Length () / interval;

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
    }
}