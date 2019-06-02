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
        class<Actor> trail = MissileName;

        if (trail != null) {
            Vector3 finalPos = level.Vec3Offset (initialPos, stepDiff);

            Actor act = Spawn (trail, initialPos, ALLOW_REPLACE);

            double realFloorZ = GetZAt (finalPos.X, finalPos.Y, flags: GZF_AbsolutePos | GZF_AbsoluteAng);

            double hitz = finalPos.z - 8;
            if (hitz < realFloorZ)
                hitz = realFloorZ;
            // Do not clip this offset to the floor.
            hitz += missileHeight;

            LinkContext ctx;
            act.UnlinkFromWorld (ctx);
            act.SetXYZ ((finalPos.XY, hitz));
            act.LinkToWorld (ctx);
            act.FindFloorCeiling (FFCF_OnlySpawnPos);
            act.ClearInterpolation ();

            if (act != null) {
                if (bGetOwner && target != null)
                    act.target = target;
                else
                    act.target = self;
                
                act.angle = angle;
                act.pitch = pitch;
            }

            return act;
        }

        return NULL;
    }

    void SpawnEffects (Vector3 initialPos, double dist, Vector3 stepSize) {
        if (radius <= 0 || dist <= 0 || stepSize.XY.Length () <= 0 || stepSize.X != stepSize.X || stepSize.Y != stepSize.Y)
            return;

        double count = 8;
        while (abs (stepSize.X) > radius * count || abs (stepSize.Y) > radius * count) {
            if (count == double.infinity || count == -double.infinity) {
                if (S7_DebugMode)
                    Console.Printf ("S7_Projectile.SpawnEffects: count overflowed");

                return;
            }
            count += count;
        }

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