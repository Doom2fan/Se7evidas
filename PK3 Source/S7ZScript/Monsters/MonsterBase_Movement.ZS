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

class S7_MonsterBase_WallTracer : LineTracer {
    int LineBlockFlags;
    bool CanDropoff;
    double MaxDropOffHeight;

    bool WasDropoff;

    bool CheckWallPassable (Line curLine) {
        return curLine.flags & LineBlockFlags;
    }

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
class S7_Asd : Actor {
    default {
        +NOGRAVITY +NOINTERACTION
    }

    states {
    Spawn:
        BAL1 A 3;
        BAL1 A 2 A_FadeOut (0.1);
        wait;
    Spawn2:
        BAL1 A -1;
        stop;
    }
}

extend class S7_MonsterBase {
    S7_MonsterBase_WallTracer wallTracer;
    int moveStandStillCount;

    S7_MonsterSteering_Pipeline steerPipeline;

    private void InitializeMovement () {
        if (!wallTracer)
            wallTracer = new ('S7_MonsterBase_WallTracer');

        if (!steerPipeline) {
            steerPipeline = S7_MonsterSteering_Pipeline.Create (self)
                .AddTargetter (new ('S7_MonsterSteering_BasicTargetter').WithLookahead (.15))
                //.AddConstraint (new ('S7_MonsterSteering_WallFollowingConstraint'))//.WithClosestEndMode (2))
                .AddConstraint (new ('S7_MonsterSteering_WallAvoidanceConstraint'))
                .AddConstraint (new ('S7_MonsterSteering_AvoidObstaclesConstraint').WithMargin (1.5))
                .WithActuator (new ('S7_MonsterSteering_BasicActuator'))
                .WithDeadlockActuator (new ('S7_MonsterSteering_BasicDeadlockActuator'));
        }

        moveStandStillCount = 0;
    }

    bool S7_CanFly () {
        return bFloat;
    }

    void S7_DoSteering () {
        let [linearAccel, angularAccel] = steerPipeline.GetSteering ();

        Vel += linearAccel;
        AngularVelocity += angularAccel;
    }

    void S7_DoTickSteering_CheckUse () {
        let velLen = Vel.XY.Length ();
        if (velLen <= S7_Math.VM_Epsilon)
            return;

        if (CheckPosition (Level.Vec2Offset (Pos.XY, Vel.XY / velLen * Radius), false))
            return;

        let usesCount = CheckMonsterUseSpecials ();
        if (usesCount < 1)
            return;

        if ((random [OpenDoor] (0, 255) >= 203) ^ (usesCount & 1))
            return;

        S7_SetStandStillCount ();
    }

    void S7_DoTickSteering () {
        if (aiChaseFuncState == null || IsFrozen ())
            return;

        if (Health < 1 || bKilled || aiChaseFuncState != CurState) {
            aiChaseFuncState = null;
            return;
        }

        let canMove = S7_CanFly () || (Pos.Z <= FloorZ || Pos.Z ~== FloorZ || Vel.Z <= S7_Math.VM_Epsilon);
        if (!canMove)
            return;

        S7_DoSteering ();

        if (moveStandStillCount < 1)
            S7_DoTickSteering_CheckUse ();
    }
}