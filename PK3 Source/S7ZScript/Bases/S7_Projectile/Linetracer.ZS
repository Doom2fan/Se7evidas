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

class S7_Projectile_Trace : LineTracer {
    S7_Projectile sourceActor;
    transient Array<F3DFloor> ffloorsToIgnore;
    transient Array<Line> activeLinesToIgnore;
    transient Array<Actor> actorsToIgnore;
    transient Array<Actor> actorsRipped;

    ETraceStatus HandleActor () {
        if (sourceActor.bThruActors)
            return TRACE_Skip;

        let mo = Results.HitActor;

        if (actorsToIgnore.Find (mo) != actorsToIgnore.Size ()) // Skip if the actor should be ignored
            return TRACE_Skip;
        if (actorsRipped.Find (mo) != actorsRipped.Size ()) // Skip if the actor was already ripped through
            return TRACE_Skip;

        if (mo == sourceActor || (sourceActor.bMissile && !sourceActor.bHitOwner && mo == sourceActor.target))
            return TRACE_Skip;

        if (!(mo.bSolid || mo.bSpecial || mo.bShootable || mo.bTouchy))
            return TRACE_Skip;

        if (mo.bThruActors)
            return TRACE_Skip;

        return TRACE_Stop;
    }

    ETraceStatus HandleWall () {
        if (Results.Tier == TIER_Upper || Results.Tier == TIER_Lower)
            return TRACE_Stop;

        let hl = Results.HitLine;

        if (activeLinesToIgnore.Find (hl) == activeLinesToIgnore.Size () &&
            (
                ((hl.activation & SPAC_MCross) && sourceActor.bActivateMCross) ||
                ((hl.activation & SPAC_PCross) && sourceActor.bActivatePCross)
            )
        ) {
            activeLinesToIgnore.Push (hl);
            return TRACE_Stop;
        }

        if (Results.ffloor && ffloorsToIgnore.Find (Results.ffloor) == ffloorsToIgnore.Size ()) {
            ffloorsToIgnore.Push (Results.ffloor);
            return TRACE_Stop;
        }

        if (Results.Tier == TIER_Middle && !hl.backsector)
            return TRACE_Stop;

        if (sourceActor.bMissile && (hl.flags & (Line.ML_BlockProjectile | Line.ML_BlockEverything)))
            return TRACE_Stop;

        if (sourceActor.bMissile && Results.Tier == TIER_Middle && (hl.flags & Line.ML_Blocking) && (hl.flags & Line.ML_TwoSided))
            return TRACE_Skip;

        if ((hl.flags & Line.ML_3DMidTex) && !(hl.flags & Line.ML_3DMidTex_Impass))
            return TRACE_Stop;

        if ((hl.flags & (Line.ML_Blocking | Line.ML_BlockEverything)) || (sourceActor.bIsMonster && (hl.flags & Line.ML_BlockMonsters)))
            return TRACE_Stop;

        return TRACE_Skip;
    }

    override ETraceStatus TraceCallback () {
        ETraceStatus status = TRACE_Skip;
        switch (Results.HitType) {
            case TRACE_HitActor:
                status = HandleActor ();
            break;

            case TRACE_HitFloor:
            case TRACE_HitCeiling:
                status = TRACE_Stop;
            break;

            case TRACE_HitWall:
                status = HandleWall ();
            break;
        }

        return status;
    }
}