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
    void HandleMovement () {
        let oldPos = pos;
        let oldVel = vel;
        
        if (vel ~== (0, 0, 0) && pos.Z ~== floorz)
            return;
            
        if (!tr) { tr = new ('S7_Projectile_Trace'); tr.sourceActor = self; }

        tr.actorsToIgnore.Clear ();
        tr.actorsRipped.Clear ();

        if (bMissile && vel.X == 0 && vel.Y == 0 && !IsZeroDamage ())
            vel.X = MinVel;

        let velUnit = vel.Unit ();
        double velAngle = VectorAngle (velUnit.x, velUnit.y);
        double s = sin (velAngle);
        double c = cos (velAngle);

        double maxDist = abs (vel.Length ());
        int colFlags = (fpCollisionMode & (ColMode_Center | ColMode_Corners | ColMode_EdgeCenters));
        int iMax = FPColOffs.Size () / 2;

        bool collisionHandled = false;
        for (int i = 0; i < iMax; i++) {
            int loopBreaker = 0;

            if (colFlags == 0 || bNoInteraction || bNoClip)
                break;

            if ((i >= 0 && i <= 3) && !(colFlags & ColMode_EdgeCenters))
                continue;
            else if ((i >= 4 && i <= 7) && !(colFlags & ColMode_Corners))
                continue;
            else if ((i == 8) && !(colFlags & ColMode_Center))
                continue;

            tr.activeLinesToIgnore.Clear ();
            tr.actorsToIgnore.Clear ();

            double xOffs = radius * FPColOffs [i * 2];
            double traceHeight = height * FPColOffs [i * 2 + 1];
            Vector3 traceOffs = (s * xOffs, c * xOffs, traceHeight);

            let curTracePos = pos;
            let traceEndpoint = level.Vec3Offset (pos, traceOffs + vel);

            int handleColRet = 0;
            do {
                Vector3 startPos = level.Vec3Offset (curTracePos, traceOffs);
                double traceMaxDist = level.Vec3Diff (startPos, traceEndpoint).Length ();

                if (tr.Trace (startPos, curSector, velUnit, traceMaxDist, 0)) {
                    if (!self)
                        return;

                    curTracePos = level.Vec3Offset (tr.Results.HitPos, velUnit * EQUAL_EPSILON);
                    handleColRet = HandleCollision (oldPos, oldVel, startPos);
                    if (handleColRet == 1) {
                        if (!self)
                            return;

                        tr.actorsToIgnore.Clear ();
                        collisionHandled = true;
                        break;
                    }
                } else {
                    handleColRet = 0;
                    tr.actorsToIgnore.Clear ();
                }

                loopBreaker++;
                if (loopBreaker >= 4096) { // Uh oh.
                    Console.PrintF ("\cgSe7evidas error: Broke an infinite loop in S7_Projectile.");
                    Destroy ();
                    return;
                }
            } while (tr.actorsToIgnore.Size () > 0 || handleColRet == -1);

            if (collisionHandled)
                break;
            else
                SetOrigin (oldPos, false);
        }

        if (!collisionHandled)
            SetOrigin (level.Vec3Offset (pos, vel), interpFastProj);

        SpawnEffects (oldPos, level.Vec3Diff (pos, oldPos).Length (), oldVel);

        if (!collisionHandled && bMissile) {
            bool floorHit = pos.Z <= floorZ;
            bool ceilingHit = (pos.Z + height) > ceilingZ;

            if ((floorHit || ceilingHit) && !bNoInteraction && !bNoClip) {
                SetZ (floorHit ? GetZAt () : ceilingZ - height);

                if (floorHit) {
                    HitFloor ();
                    BlockingFloor = CurSector;
                } else
                    BlockingCeiling = CurSector;

                A_Stop ();
                S7_ExplodeMissile (NULL, NULL, CheckSkyHit (null));
            }
        }

        vel.Z -= GetGravity ();

        UpdateWaterLevel ();
        CheckPortalTransition ();
    }
}