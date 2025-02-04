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

struct S7_SteeringContextMap {
    const Resolution = 32;
    const BucketSize = 360. / S7_SteeringContextMap.Resolution;

    double [Resolution] Interest;
    double [Resolution] Danger;

    double [Resolution] Merged;

    void Reset () {
        for (int i = 0; i < Resolution; i++)
            Interest [i] = Danger [i] = 0;
    }

    void AddInterestDirect (double bucket, double intensity) {
        Interest [bucket] = max (Interest [bucket], intensity);
    }

    void AddDangerDirect (double bucket, double intensity) {
        bucket = (bucket + Resolution) % Resolution;
        Danger [bucket] = max (Danger [bucket], intensity);
    }

    void AddInterest (double direction, double intensity, double spread) {
        // Normalize direction to 0-2π.
        direction = (direction + 360.) % 360.;

        // Convert direction to bucket index.
        let bucketSize = 360. / Resolution;
        let centerBucket = int (direction / BucketSize);

        // Calculate spread in terms of buckets.
        let spreadBuckets = max (spread / BucketSize, 1);
        let spreadBucketsReal = int (clamp (spreadBuckets, 1, Resolution / 2.));

        for (let i = -spreadBucketsReal; i <= spreadBucketsReal; i++) {
            let bucket = (centerBucket + i + Resolution) % Resolution;
            let falloff = 1. - (abs (i) / double (spreadBuckets));
            Interest [bucket] = max (Interest [bucket], intensity * falloff);
        }
    }

    void AddDanger (double direction, double intensity, double spread) {
        // Normalize direction to 0-2π.
        direction = (direction + 360.) % 360.;

        // Convert direction to bucket index.
        let centerBucket = int (direction / BucketSize);

        // Calculate spread in terms of buckets.
        let spreadBuckets = max (spread / BucketSize, 1);
        let spreadBucketsReal = int (clamp (spreadBuckets, 1, Resolution / 2.));

        for (let i = -spreadBucketsReal; i <= spreadBucketsReal; i++) {
            let bucket = (centerBucket + i + Resolution) % Resolution;
            let falloff = 1. - (abs (i) / double (spreadBuckets));
            Danger [bucket] = max (Danger [bucket], intensity * falloff);
        }
    }

    void MergeMaps () {
        let minDanger = double.Infinity;
        for (int i = 0; i < Resolution; i++)
            minDanger = min (minDanger, Danger [i]);

        for (int i = 0; i < Resolution; i++) {
            Merged [i] = (Danger [i] > minDanger + 1e-8) ? 0 : Interest [i];
            //Merged [i] = max (Interest [i] - (Danger [i] - minDanger), 0);
        }
    }
}

class S7_MonsterSteering abstract play {
    const MonsterUse_SPAC = SPAC_Cross | SPAC_Use | SPAC_MCross | SPAC_Impact | SPAC_Push | SPAC_MUse | SPAC_MPush;

    abstract Vector3, double GetSteering (S7_MonsterBase thisAgent);
}

class S7_MonsterSteering_ContextSteering : S7_MonsterSteering abstract {
    S7_SteeringContextMap steeringMap;

    abstract void PerformBehaviours (S7_MonsterBase thisAgent);

    virtual void PostProcessingPreMerge (S7_MonsterBase thisAgent) { }

    virtual void PostProcessingPostMerge (S7_MonsterBase thisAgent) { }

    abstract Vector3, double ActuateSteering (S7_MonsterBase thisAgent);

    override Vector3, double GetSteering (S7_MonsterBase thisAgent) {
        steeringMap.Reset ();

        // Process behaviours.
        PerformBehaviours (thisAgent);

        // Post-processing and merging.
        PostProcessingPreMerge (thisAgent);

        steeringMap.MergeMaps ();

        PostProcessingPostMerge (thisAgent);

        /*FSpawnParticleParams particleParams;
        particleParams.lifetime = 1;
        particleParams.style = STYLE_Add;
        particleParams.flags = SPF_FULLBRIGHT | SPF_REPLACE;
        particleParams.size = 4;
        particleParams.vel = (0, 0, 0);
        particleParams.accel = (0, 0, 0);

        particleParams.startalpha = 1.;

        for (int i = 0; i < S7_SteeringContextMap.Resolution; i++) {
            let iVec = Actor.AngleToVector (i * S7_SteeringContextMap.BucketSize, 1).Unit ();

            for (int j = 1; j < 2; j++) {
                double value;
                switch (j) {
                    default:
                    case 0: value = steeringMap.Interest [i]; particleParams.color1 = Color (  0, 255,   0); break;
                    case 1: value = steeringMap.Danger   [i]; particleParams.color1 = Color (255,   0,   0); break;
                    case 2: value = steeringMap.Merged   [i]; particleParams.color1 = Color (128,   0, 255); break;
                }

                value *= 50;
                if (value <= S7_Math.VM_Epsilon)
                    continue;

                let stepSize = 12.;
                let valueDiv = value / stepSize;
                for (let k = int (ceil (valueDiv)); k >= 0; k--) {
                    let dist = value - k * stepSize;
                    if (dist < S7_Math.VM_Epsilon)
                        continue;
                    particleParams.pos = thisAgent.Pos + (iVec * dist, thisAgent.Height / 2.);
                    level.SpawnParticle (particleParams);
                }
            }
        }*/

        // Perform steering.
        let [linearAccel, angularAccel] = ActuateSteering (thisAgent);
        return linearAccel, angularAccel;
    }

    double, double FindSteerDirectionSimple (S7_MonsterBase thisAgent) {
        // Find safest direction with highest interest.
        let maxInterest = 0.;
        let bestBucket = -1;

        for (let i = 0; i < S7_SteeringContextMap.Resolution; i++) {
            if (steeringMap.Merged [i] > maxInterest) {
                maxInterest = steeringMap.Merged [i];
                bestBucket = i;
            }
        }

        if (bestBucket < 0)
            return double.infinity, -1;

        // Calculate gradient for smoother direction.
        let prevBucket = steeringMap.Merged [(bestBucket - 1 + S7_SteeringContextMap.Resolution) % S7_SteeringContextMap.Resolution];
        let nextBucket = steeringMap.Merged [(bestBucket + 1) % S7_SteeringContextMap.Resolution];
        let gradientOffset = maxInterest > S7_Math.VM_Epsilon
                           ? (nextBucket - prevBucket) / (2. * maxInterest)
                           : 0.;

        return (bestBucket + gradientOffset) * S7_SteeringContextMap.BucketSize, steeringMap.Merged [bestBucket];
    }

    double, double FindSteerDirection (S7_MonsterBase thisAgent, uint gradientWindow = 8, double gradientFalloff = .7) {
        // Find safest direction with highest interest.
        let maxInterest = 0.;
        let bestBucket = -1;

        for (let i = 0; i < S7_SteeringContextMap.Resolution; i++) {
            if (steeringMap.Merged [i] > maxInterest) {
                maxInterest = steeringMap.Merged [i];
                bestBucket = i;
            }
        }

        if (bestBucket < 0)
            return double.infinity, -1;

        // Calculate weighted average direction considering nearby buckets.
        let weightedDirectionX = 0.;
        let weightedDirectionY = 0.;
        let totalWeight = 0.;

        for (let offset = 0; offset <= gradientWindow; offset++) {
            let bucketPos = (bestBucket + offset) % steeringMap.Resolution;
            let bucketNeg = (bestBucket - offset + steeringMap.Resolution) % steeringMap.Resolution;
            let bucketPosDirection = bucketPos * S7_SteeringContextMap.BucketSize;
            let bucketNegDirection = bucketNeg * S7_SteeringContextMap.BucketSize;

            // Calculate weight based on distance and interest.
            let distanceFactor = S7_Math.PowI (gradientFalloff, int (offset));
            let weightPos = steeringMap.Merged [bucketPos] * distanceFactor;
            let weightNeg = steeringMap.Merged [bucketNeg] * distanceFactor;

            // Add weighted vector components.
            weightedDirectionX += (cos (bucketPosDirection) * weightPos) + (cos (bucketNegDirection) * weightNeg);
            weightedDirectionY += (sin (bucketPosDirection) * weightPos) + (sin (bucketNegDirection) * weightNeg);
            totalWeight += weightPos + weightNeg;
        }

        if (totalWeight <= S7_Math.VM_Epsilon)
            return double.infinity, -1;

        // Calculate final direction and normalize the intensity.
        let finalDirection = atan2 (weightedDirectionY, weightedDirectionX);

        // Ensure direction is positive.
        if (finalDirection < 0)
            finalDirection += 360;

        return finalDirection, maxInterest;
    }

    void SeekTarget (S7_MonsterBase thisAgent, Vector2 targetPos, double intensityMul, double range, double minSpread, double maxSpread) {
        let toTarget = level.Vec2Diff (thisAgent.Pos.XY, targetPos);
        let targetDist = toTarget.Length ();
        let targetDir = atan2 (toTarget.Y, toTarget.X);

        let distNorm = clamp (targetDist / range, 0., 1.);
        let intensity = distNorm * intensityMul;
        let spread = S7_Math.Lerp (minSpread, maxSpread, distNorm);

        steeringMap.AddInterest (targetDir, intensity, spread);
    }

    void SeekTargetWings (
        S7_MonsterBase thisAgent, Vector2 targetPos,
        double intensityMul, double range, double minSpread, double maxSpread,
        double sideIntensityMul, double sideSpread
    ) {
        let toTarget = level.Vec2Diff (thisAgent.Pos.XY, targetPos);
        let targetDist = toTarget.Length ();
        let targetDir = atan2 (toTarget.Y, toTarget.X);

        let distNorm = clamp (targetDist / range, 0., 1.);
        let intensity = distNorm * intensityMul;
        let spread = S7_Math.Lerp (minSpread, maxSpread, distNorm);

        steeringMap.AddInterest (targetDir, intensity, spread);

        let sideIntensity = intensity * sideIntensityMul;
        steeringMap.AddInterest (targetDir + 90, sideIntensity, sideSpread);
        steeringMap.AddInterest (targetDir - 90, sideIntensity, sideSpread);
    }

    void AvoidActors (S7_MonsterBase thisAgent, double avoidRange, double intensityMul, double minSpread, double maxSpread) {
        let avoidRangeSqr = avoidRange * avoidRange;
        for (let it = BlockThingsIterator.Create (thisAgent, (avoidRange + thisAgent.Radius) * 2); it.Next ();) {
            let obstacle = it.Thing;

            if (
                // Skip if the actor is null or us.
                !obstacle || obstacle == thisAgent ||
                // Skip 0-radius/height actors.
                obstacle.Radius <= S7_Math.VM_Epsilon || obstacle.Height <= S7_Math.VM_Epsilon ||
                // Skip non-solid objects.
                !obstacle.bSolid || obstacle.bNoClip || obstacle.bNoInteraction ||
                // Skip projectiles.
                obstacle.bMissile ||
                // Skip corpses.
                obstacle.bCorpse || obstacle.bKilled ||
                // Skip if we're completely above or below the other actor.
                thisAgent.Pos.Z > obstacle.Pos.Z + obstacle.Height || thisAgent.Pos.Z + thisAgent.Height < obstacle.Pos.Z
            )
                continue;

            let toObstacle = level.Vec2Diff (thisAgent.Pos.XY, obstacle.Pos.XY);
            let obstacleDir = atan2 (toObstacle.Y, toObstacle.X);
            let trueDist = max (toObstacle.Length () - (thisAgent.Radius + obstacle.Radius) * S7_Math.SquareRadiusVectorFactor (obstacleDir), 0);
            if (trueDist > avoidRange)
                continue;

            let distNorm = clamp (trueDist / avoidRange, 0., 1.);
            let intensity = max (0., 1. - (distNorm * distNorm));
            let spread = S7_Math.Lerp (maxSpread, minSpread, distNorm);

            steeringMap.AddDanger (obstacleDir, intensity, spread);
        }
    }

    void AvoidWallsRaycast (S7_MonsterBase thisAgent, double avoidRange, double avoidRadiusFactor, double intensityMul, double dropoffIntensityMul) {
        let wallTracer = thisAgent.wallTracer;
        wallTracer.LineBlockFlags = S7_ActorExtensions.GetSelfBlockLineFlags (thisAgent);
        wallTracer.CanDropoff = thisAgent.S7_CanFly ();
        wallTracer.MaxDropOffHeight = thisAgent.MaxDropOffHeight;

        let wallRayStartPos = level.Vec3Offset (thisAgent.Pos, (0, 0, thisAgent.MaxStepHeight + .5));
        let avoidRadius = thisAgent.Radius * avoidRadiusFactor;
        for (int i = 0; i < S7_SteeringContextMap.Resolution; i++) {
            let rayAng = i * S7_SteeringContextMap.BucketSize;
            let rayDir = (Actor.AngleToVector (rayAng, 1.), 0);
            let wallRayLen = avoidRadius * S7_Math.SquareRadiusVectorFactor (rayAng) + avoidRange;
            if (!wallTracer.Trace (wallRayStartPos, thisAgent.curSector, rayDir, wallRayLen, 0, ignoreAllActors: true) || wallTracer.Results.HitType != TRACE_HitWall)
                continue;

            let intensity = 1. / max (wallTracer.Results.Distance, 1e-10);
            if (wallTracer.WasDropoff)
                intensity *= dropoffIntensityMul;
            else if (S7_ActorExtensions.CheckCanActivateLine (wallTracer.Results.HitLine, thisAgent, wallTracer.Results.Side, MonsterUse_SPAC))
                continue;
            else
                intensity = intensityMul;

            steeringMap.AddDangerDirect (i, intensity);
            /*steeringMap.AddDangerDirect (i - 1, intensity * .5);
            steeringMap.AddDangerDirect (i + 1, intensity * .5);*/

            //intensity = wallTracer.Results.Distance/50;
            /*let spread = S7_Math.Lerp (S7_SteeringContextMap.BucketSize * 2., 0, clamp (wallTracer.Results.Distance / (thisAgent.Radius), 0., 1.));
            spread = S7_SteeringContextMap.BucketSize * 2.;
            steeringMap.AddDanger (rayAng, intensity, spread);*/
        }
    }

    void AvoidWallsSwept (S7_MonsterBase thisAgent, double avoidRange, double avoidRadiusFactor, double intensityMul, double dropoffIntensityMul) {
        let level = thisAgent.Level;
        let lineBlockFlags = S7_ActorExtensions.GetSelfBlockLineFlags (thisAgent);
        let canDropoff = thisAgent.S7_CanFly ();
        let maxDropOffHeight = thisAgent.MaxDropOffHeight;
        let maxStepHeight = thisAgent.MaxStepHeight;

        let agentPos = thisAgent.Pos.XY;
        let agentPosZ = thisAgent.Pos.Z;
        let agentRadius = thisAgent.Radius;
        let agentHeight = thisAgent.Height;
        let avoidRadius = thisAgent.Radius * avoidRadiusFactor;

        Array<int> linesToSweep; linesToSweep.Clear ();
        Array<int> linesToSweep_Dropoff; linesToSweep_Dropoff.Clear ();
        Array<int> linesToSweep_TwoSided; linesToSweep_TwoSided.Clear ();
        for (
            let lineIterator = BlockLinesIterator.CreateFromPos (
                (agentPos, agentPosZ), agentHeight,
                avoidRadius * S7_Math.SqrtTwo + avoidRange + agentRadius * 1.5
            );
            lineIterator.Next ();
        ) {
            let curLine = lineIterator.CurLine;
            let lineSide = S7_Math.PointOnLineSidePrecise (agentPos.X, agentPos.Y, curLine);

            // Check if this is an usable line.
            if (S7_ActorExtensions.CheckCanActivateLine (curLine, thisAgent, lineSide, MonsterUse_SPAC))
                continue;
            // Check if this line matches any of the agent's blocking flags.
            else if (curLine.flags & lineBlockFlags)
                linesToSweep.Push (curLine.Index ());
            // Check if this line is two-sided, and needs to be checked in the ray code, or check it here.
            else if (curLine.Sidedef [Line.Back] != null) {
                let hitSec = curLine.Sidedef [lineSide].Sector;
                let oppositeSec = curLine.Sidedef [!lineSide].Sector;

                // Needs to be checked in the ray code.
                if (
                    hitSec.Get3DFloorCount () > 0 ||
                    oppositeSec.Get3DFloorCount () > 0 ||
                    hitSec.FloorPlane.isSlope () ||
                    oppositeSec.FloorPlane.isSlope () ||
                    oppositeSec.CeilingPlane.isSlope ()
                ) {
                    linesToSweep_TwoSided.Push (curLine.Index ());
                    continue;
                }

                // We don't need to check the line if it isn't a sector boundary.
                if (hitSec == oppositeSec)
                    continue;

                let hitFloorZ = hitSec.FloorPlane.ZatPoint (hitSec.CenterSpot);
                let oppFloorZ = oppositeSec.FloorPlane.ZatPoint (oppositeSec.CenterSpot);
                let oppCeilZ = oppositeSec.CeilingPlane.ZatPoint (oppositeSec.CenterSpot);

                // Check if we'll hit the upper or lower of the line.
                if ((oppFloorZ > (hitFloorZ + maxStepHeight)) || ((oppCeilZ - hitFloorZ) <= agentHeight))
                    linesToSweep.Push (curLine.Index ());
                // Check if this is a dropoff.
                else if (!canDropoff && (hitFloorZ - oppFloorZ) >= maxDropOffHeight)
                    linesToSweep_Dropoff.Push (curLine.Index ());
            }
        }

        let wallRayLen = avoidRadius + avoidRange;
        for (int i = 0; i < S7_SteeringContextMap.Resolution; i++) {
            let rayAng = i * S7_SteeringContextMap.BucketSize;
            let rayDir = Actor.AngleToVector (rayAng, 1.);

            // Sweep lines.
            let isDropoff = false;
            let minTime = double.infinity;
            foreach (curLineIdx : linesToSweep) {
                let curLine = level.Lines [curLineIdx];
                let curTime = S7_Math.TestAABBLineSwept (
                    agentPos, agentRadius, rayDir,
                    curLine.v1.p, curLine.v2.p,
                    wallRayLen
                );

                if (curTime >= 0)
                    minTime = min (minTime, curTime);
            }

            foreach (curLineIdx : linesToSweep_Dropoff) {
                let curLine = level.Lines [curLineIdx];
                let curTime = S7_Math.TestAABBLineSwept (
                    agentPos, agentRadius, rayDir,
                    curLine.v1.p, curLine.v2.p,
                    wallRayLen
                );

                if (curTime >= 0 && (curTime < minTime || curTime ~== minTime)) {
                    minTime = curTime;
                    isDropoff = true;
                }
            }

            foreach (curLineIdx : linesToSweep_TwoSided) {
                let curLine = level.Lines [curLineIdx];
                let curIsDropoff = false;
                let checkLine = false;

                Vector2 hitPos;
                let rayHitTime = S7_Math.RayLineSegIntersectionTime (agentPos, rayDir, curLine.v1.p, curLine.v2.p);
                if (rayHitTime >= 0) {
                    hitPos = agentPos + rayDir * rayHitTime;
                    if (rayHitTime > minTime)
                        continue;
                } else {
                    let [rayHits, rayHitPos] = S7_Math.ProjectPointToLine2D_Delta (curLine.v1.p, curLine.delta, agentPos);
                    hitPos = rayHitPos;
                }

                let lineSide = S7_Math.PointOnLineSidePrecise (agentPos.X, agentPos.Y, curLine);
                let hitSec = curLine.Sidedef [lineSide].Sector;
                let oppositeSec = curLine.Sidedef [!lineSide].Sector;

                let hitFloorZ = hitSec.NextLowestFloorAt (hitPos.X, hitPos.Y, agentPosZ + maxStepHeight);
                let oppFloorZ = oppositeSec.NextLowestFloorAt (hitPos.X, hitPos.Y, hitFloorZ + maxStepHeight);
                let oppCeilZ = oppositeSec.NextHighestCeilingAt (hitPos.X, hitPos.Y, hitFloorZ, hitFloorZ + agentHeight);

                // Check if we'll hit the upper or lower of the line.
                if ((oppFloorZ > (hitFloorZ + maxStepHeight)) || ((oppCeilZ - hitFloorZ) <= agentHeight))
                    checkLine = true;
                // Check if this is a dropoff.
                else if (!canDropoff && (hitFloorZ - oppFloorZ) > (maxDropOffHeight + S7_Math.VM_Epsilon)) {
                    checkLine = true;
                    curIsDropoff = true;
                }

                // We don't need to check this line.
                if (!checkLine)
                    continue;

                let curTime = S7_Math.TestAABBLineSwept (
                    agentPos, agentRadius, rayDir,
                    curLine.v1.p, curLine.v2.p,
                    wallRayLen
                );

                if (curTime >= 0 && (curTime <= minTime || (curIsDropoff && curTime ~== minTime))) {
                    minTime = curTime;
                    isDropoff = curIsDropoff;
                }
            }

            if (minTime == double.infinity)
                continue;

            let intensity = (isDropoff ? dropoffIntensityMul : intensityMul) / max (minTime, 1e-10);

            steeringMap.AddDangerDirect (i, intensity);
        }
    }
}

class S7_MonsterSteering_Simple : S7_MonsterSteering_ContextSteering {
    override void PerformBehaviours (S7_MonsterBase thisAgent) {
        if (thisAgent.MoveStandStillCount > 0)
            return;

        // Insert dangers.
        //AvoidWallsRaycast (thisAgent, S7C_MapUnitsPerMeter * 2, 2, 1.8, 1.8);
        AvoidWallsSwept (thisAgent, S7C_MapUnitsPerMeter * .25, 2, 1.8, 1.8);

        //AvoidActors (thisAgent, S7C_MapUnitsPerMeter * 1.5, 1., 11.25, 135);
        AvoidActors (thisAgent, S7C_MapUnitsPerMeter * 2, 1.2, 30., 70.);

        // Insert interests.
        if (thisAgent.target) {
            let seekRange = thisAgent.Radius + thisAgent.target.Radius + S7C_MapUnitsPerMeter * 2.5;
            SeekTargetWings (thisAgent, thisAgent.target.Pos.XY, 1, seekRange, 45, 90, .4, 22.5);
        }
    }

    static const float BlurOffsets [] = {
        -2, -1, 0, 1, 2
    };

    static const float BlurWeights [] = {
        0.0013496809513018281,
        0.15730538687737936,
        0.6826898643426378,
        0.15730538687737936,
        0.0013496809513018281
    };

    override void PostProcessingPreMerge (S7_MonsterBase thisAgent) {
        return;
        for (let i = 0; i < S7_SteeringContextMap.Resolution; i++) {
            let accum = 0.;
            for (let j = 0; j < BlurOffsets.Size (); j++)
                accum += steeringMap.Danger [(i + BlurOffsets [j] + S7_SteeringContextMap.Resolution) % S7_SteeringContextMap.Resolution] * BlurWeights [j];

            steeringMap.Danger [i] = accum;
        }
    }

    override void PostProcessingPostMerge (S7_MonsterBase thisAgent) {
        let velAng = (atan2 (thisAgent.Vel.Y, thisAgent.Vel.X) + 360.) % 360.;
        let velLenSquared = thisAgent.Vel.XY.LengthSquared ();
        if (velLenSquared > S7_Math.VM_Epsilon ** 2) {
            let velLen = sqrt (velLenSquared);
            let maxSpeed = thisAgent.Speed / Thinker.TicRate;

            let velFac = velLen / maxSpeed;
            let exponent = (1. / 3. * (velFac * velFac * velFac));
            for (int i = 0; i < S7_SteeringContextMap.Resolution; i++) {
                let dotProd = cos (velAng - (i * S7_SteeringContextMap.BucketSize));
                let scaleFac = exp (exponent * log (dotProd * .5 + .5));
                steeringMap.Merged [i] = steeringMap.Merged [i] * scaleFac;
            }
        }
    }

    override Vector3, double ActuateSteering (S7_MonsterBase thisAgent) {
        let maxSpeed = thisAgent.Speed / Thinker.TicRate;
        let maxAccel = thisAgent.MaxAccel / Thinker.TicRate;
        let maxTurnSpeed = thisAgent.MaxTurnSpeed / Thinker.TicRate;
        let maxTurnAccel = thisAgent.MaxTurnAccel / Thinker.TicRate;
        let canFly = thisAgent.S7_CanFly ();

        let agentAngle = thisAgent.Angle;

        let desiredVel = (0, 0, 0);
        let desiredAngle = agentAngle;
        if (thisAgent.MoveStandStillCount <= 0) {
            let [direction, interest] = FindSteerDirection (thisAgent);

            if (interest >= S7_Math.VM_Epsilon) {
                desiredVel.XY = Actor.AngleToVector (direction, maxSpeed * clamp (interest, 0., 1.));
                desiredAngle = direction;
            }
        } else
            desiredAngle = thisAgent.MoveStandStillAngle;

        // Handle linear acceleration.
        let velApplyFactor = max (cos (Actor.DeltaAngle (agentAngle, desiredAngle)), 0);
        let appliedVel = desiredVel * velApplyFactor;

        Vector3 linearAccel;
        if (!canFly)
            linearAccel = (S7_Math.ClampVec2Length (appliedVel.XY - thisAgent.Vel.XY, maxAccel), 0);
        else
            linearAccel = S7_Math.ClampVec3Length (appliedVel - thisAgent.Vel, maxAccel);

        // Handle angular acceleration.
        let angleDiff = Actor.Normalize180 (desiredAngle - thisAgent.Angle);
        let slowRadius = maxTurnSpeed * 4;

        let desiredAngularVel = maxTurnSpeed * clamp (abs (angleDiff) / slowRadius, 0, 1);
        if (angleDiff < 0)
            desiredAngularVel = -desiredAngularVel;

        let angularAccel = clamp (desiredAngularVel - thisAgent.AngularVelocity, -maxTurnAccel, maxTurnAccel);

        return linearAccel, angularAccel;
    }
}