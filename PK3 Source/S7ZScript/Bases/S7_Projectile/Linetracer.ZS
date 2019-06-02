class S7_Projectile_Trace : LineTracer {
    S7_Projectile sourceActor;
    Array<Line> activeLinesToIgnore;
    Array<Actor> actorsToIgnore;
    Array<Actor> actorsRipped;

    ETraceStatus HandleActor () {
        if (sourceActor.bThruActors)
            return TRACE_Skip;

        let mo = Results.HitActor;

        if (actorsToIgnore.Find (mo) != actorsToIgnore.Size ()) // Skip if the actor should be ignored
            return TRACE_Skip;
        if (actorsRipped.Find (mo) != actorsRipped.Size ()) // Skip if the actor was already ripped through
            return TRACE_Skip;

        if (mo == sourceActor || (sourceActor.bMissile && mo == sourceActor.target))
            return TRACE_Skip;

        if (!(mo.bSolid || mo.bSpecial || mo.bShootable || mo.bTouchy))
            return TRACE_Skip;

        if (mo.bThruActors)// || (sourceActor.bThruSpecies && mo.GetSpecies () == sourceActor.GetSpecies ()))
            return TRACE_Skip;

        return TRACE_Stop; // && sourceActor.CanCollideWith (Results.HitActor)
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
            Console.Printf ('sd');
            activeLinesToIgnore.Push (hl);
            return TRACE_Stop;
        }

        if (sourceActor.bMissile && (hl.flags & (Line.ML_BLOCKPROJECTILE | Line.ML_BLOCKEVERYTHING)))
            return TRACE_Stop;
        
        if (sourceActor.bMissile && Results.Tier == TIER_Middle && (hl.flags & Line.ML_BLOCKING) && (hl.flags & Line.ML_TWOSIDED))
            return TRACE_Skip;

        if ((hl.flags & Line.ML_BLOCKING) || (hl.flags & Line.ML_BLOCKEVERYTHING) || (sourceActor.bIsMonster && (hl.flags & Line.ML_BLOCKMONSTERS)))
            return TRACE_Stop;

        return TRACE_Skip;
    }
    
    override ETraceStatus TraceCallback () {
        /*if (!sourceActor)
            return TRACE_Skip;*/

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