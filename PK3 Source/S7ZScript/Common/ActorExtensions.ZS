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

class S7_CanHitPointData {
    Vector3 p2;

    double AngleTo;
    double PitchTo;

    int lineBlockFlags;
    bool ignoreAllActors;

    // Stuff to be ignored when tracing.
    Array<Actor> IgnoredActors;
}

class S7_CanHitPointLineTracer : LineTracer {
    S7_CanHitPointData data;

    override ETraceStatus TraceCallback () {
        switch (Results.HitType) {
            case TRACE_HitActor:
                if (data.ignoreAllActors)
                    return TRACE_Skip;
                if (Results.HitActor.bNoInteraction || Results.HitActor.bNoBlockmap || (!Results.HitActor.bSolid && !Results.HitActor.bShootable))
                    return TRACE_Skip;
                if (data.IgnoredActors.Find (Results.HitActor) != data.IgnoredActors.Size ())
                    return TRACE_Skip;
            break;

            case TRACE_HitFloor:
            case TRACE_HitCeiling:
                return TRACE_Stop;
            break;

            case TRACE_HitWall: {
                if (Results.Tier == TIER_Upper || Results.Tier == TIER_Lower) return TRACE_Stop;

                if ((Results.HitLine.flags & (Line.ML_BlockEverything | Line.ML_Blocking)) != 0)
                    return TRACE_Stop;
                if (!(Results.HitLine.flags & Line.ML_TwoSided))
                    return TRACE_Stop;
                if (Results.HitLine.flags & data.lineBlockFlags)
                    return TRACE_Stop;

                return TRACE_Skip;
            }
            break;
        }

        return TRACE_Stop;
    }
}

class S7_SectorList {
    Array<Sector> Sectors;
    Array<int> SectorsDoorCount;
}

class S7_ActorExtensions : Actor {
    const CHP_BlockFlags = Line.ML_BlockMonsters | Line.ML_Block_Players | Line.ML_Block_Floaters | Line.ML_BlockProjectile | Line.ML_BlockUse | Line.ML_BlockSight | Line.ML_BlockHitscan;
    static bool CanHitPoint (LevelLocals lvl, Vector3 p1, Vector3 p2, S7_CanHitPointData data) {
        if (!data)
            data = new ('S7_CanHitPointData');

        let diffVec = lvl.Vec3Diff (p1, p2);
        double dist = diffVec.Length ();

        [data.AngleTo, data.PitchTo] = S7_Math.GetAnglesTo (lvl, p1, p2);
        data.lineBlockFlags &= CHP_BlockFlags;

        let tracer = new ('S7_CanHitPointLineTracer');
        tracer.data = data;

        if (tracer.Trace (p1, Level.PointInSector (p1.XY), diffVec.Unit (), dist, TRACE_PortalRestrict)) {
            tracer.Destroy ();
            return false;
        }

        bool hitActor = (tracer.Results.HitType == TRACE_HitActor && tracer.Results.HitActor);
        if (hitActor && data.IgnoredActors.Find (tracer.Results.HitActor) == data.IgnoredActors.Size ()) {
            tracer.Destroy ();
            return false;
        }

        tracer.Destroy ();
        return true;
    }

    static State GetRaiseState (Actor act) {
        // Not a monster
        if (!act.bCorpse)
            return null;

        if (act.tics != -1 && // Not lying still yet
            !act.curState.bCanRaise) // Or not ready to be raised yet
            return null;

        if (act is 'PlayerPawn')
            return null;    // Do not resurrect players

        return act.FindState ('Raise');
    }

    static bool CheckIfActorInLOS (Actor self, Actor target, double fov = 90., int sightFlags = 0) {
        if (!self.CheckSight (target, sightFlags))
            return false;

        let diff = self.Vec3To (target);
        let dirVec = S7_Math.Vec3FromAngle (self.Angle, self.Pitch, 1).Unit ();

        if (diff dot dirVec > cos (fov / 2.))
            return false;

        return true;
    }

    static bool CheckActorCollision (Actor a, Actor b, bool no_z = false) {
        double blockDist = b.radius + a.radius;

        let diff = a.Vec2To (b);

        if (abs (diff.X) >= blockDist || abs (diff.Y) >= blockDist)
            return false;

        if (!no_z && (a.pos.z >= (b.pos.Z + b.height) || (a.pos.Z + a.height) <= b.pos.Z))
            return false;

        return true;
    }

    /* Summary:
    **  Sets the actor's position. Basically like SetOrigin, but without the FFCF_OnlySpawnPos idiocy.
    **
    ** Arguments:
    **  mo: The actor to be moved.
    **  newPos: The position to set the actor to.
    */
    static void SetActorPosition (Actor act, Vector3 newPos) {
        LinkContext ctx;
        act.UnlinkFromWorld (ctx);
        act.SetXYZ (newPos);
        act.LinkToWorld (ctx);
        act.FindFloorCeiling ();
    }

    /* Summary:
    **  Checks if an actor is "fast".
    **
    ** Arguments:
    **  mo: The actor to be checked.
    **
    ** Returns:
    **  Returns a bool indicating whether the actor is "fast".
    */
    static bool IsFast (Actor act) {
        if (act.bAlwaysFast)
            return true;
        if (act.bNeverFast)
            return false;

        return G_SkillPropertyInt (SKILLP_FastMonsters);
    }

    /* Summary:
    **  Recurses through sectors like SoundAlert.
    **
    ** Arguments:
    **  sec: The sector to recurse.
    **  sectors: The array of sectors to push the sectors to.
    **  maxDoors: Maximum number of doors that can be ignored. Set to -1 to never check doors.
    */
    static void S7_RecurseSectors (Sector sec, S7_SectorList sectorList, int maxDoors = 0, int doorsCount = 0, bool doorSector = false) {
        if (sectorList.Sectors.Find (sec) != sectorList.Sectors.Size ())
            return;

        sectorList.Sectors.Push (sec);
        sectorList.SectorsDoorCount.Push (doorsCount);

        bool checkAbove = !sec.PortalBlocksSound (Sector.Ceiling);
        bool checkBelow = !sec.PortalBlocksSound (Sector.Floor);

        int lineCount = sec.Lines.Size ();
        for (int i = 0; i < lineCount; i++) {
            let check = sec.Lines [i];

            // Check sector portals
            if (checkAbove) {
                Sector upper = Level.PointInSector (check.v1.p + check.delta / 2 + sec.GetPortalDisplacement (Sector.Ceiling));
                S7_RecurseSectors (upper, sectorList, maxDoors, doorsCount);
            }
            if (checkBelow) {
                Sector lower = Level.PointInSector (check.v1.p + check.delta / 2 + sec.GetPortalDisplacement (Sector.Floor));
                S7_RecurseSectors (lower, sectorList, maxDoors, doorsCount);
            }

            /*
             * Can't support line portals currently :(
            */

            if (!check.Sidedef [Line.Back] || !(check.flags & Line.ML_TwoSided))
                continue;

            // Early out for intra-sector lines
            if (check.Sidedef [Line.Front].sector == check.Sidedef [Line.Back].sector)
                continue;

            Sector other;
            if (check.Sidedef [Line.Front].sector == sec)
                other = check.Sidedef [Line.Back].Sector;
            else
                other = check.Sidedef [Line.Front].Sector;

            // Check for closed door
            bool isDoorSector = false;
            int curDoorsCount = doorsCount;
            if (maxDoors > -1) {
                if ((sec.floorplane.ZatPoint (check.v1.p) >=
                    other.ceilingplane.ZatPoint (check.v1.p) &&
                    sec.floorplane.ZatPoint (check.v2.p) >=
                    other.ceilingplane.ZatPoint (check.v2.p))
                    || (other.floorplane.ZatPoint (check.v1.p) >=
                        sec.ceilingplane.ZatPoint (check.v1.p) &&
                        other.floorplane.ZatPoint (check.v2.p) >=
                        sec.ceilingplane.ZatPoint (check.v2.p))
                    || (other.floorplane.ZatPoint (check.v1.p) >=
                        other.ceilingplane.ZatPoint (check.v1.p) &&
                        other.floorplane.ZatPoint (check.v2.p) >=
                        other.ceilingplane.ZatPoint (check.v2.p))
                ) {
                    isDoorSector = !doorSector;
                    if (!doorSector && isDoorSector) {
                        if (++curDoorsCount > maxDoors)
                            continue;
                    }
                }
            }

            S7_RecurseSectors (other, sectorList, maxDoors, curDoorsCount, isDoorSector);
        }
    }

    /* Summary:
    **  Checks if an actor is in the "void".
    **
    ** Arguments:
    **  mo: The actor to be checked.
    **
    ** Returns:
    **  Returns a bool indicating whether the actor is in the "void".
    */
    static bool IsInVoid (Actor mo) {
        let secPoly = new ('S7_Polygon');

        Sector sec = mo.CurSector;
        for (int i = 0; i < sec.lines.Size (); i++) {
            let line = new ('S7_Line');

            line.v1 = sec.lines [i].v1.p;
            line.v2 = sec.lines [i].v2.p;

            secPoly.lines.Push (line);
        }

        return !S7_Math.PointInPolygon (mo.pos.XY, secPoly);
    }

    /* Summary:
    **  Checks if an actor can be ripped by a projectile.
    **
    ** Arguments:
    **  victim: The actor to be checked.
    **  projectile: The projectile doing the ripping.
    **
    ** Returns:
    **  Returns a bool indicating whether the actor can be ripped through.
    */
    static clearscope bool CanRip (Actor victim, Actor projectile) {
        if (!projectile.bRipper || victim.bDontRip)
            return false;
        if (projectile.bNoBossRip && victim.bBoss)
            return false;
        if (victim.RipLevelMin > 0 && projectile.RipperLevel < victim.RipLevelMin)
            return false;
        if (victim.RipLevelMax > 0 && projectile.RipperLevel > victim.RipLevelMax)
            return false;

        return true;
    }

    // This only exists because P_RipperBlood wasn't exported to ZScript.
    static void RipperBlood (Actor mo, Actor bleeder) {
        Class<Actor> bloodcls = bleeder.GetBloodType (0);

        double xo = random2 [RipperBlood] () / 16.;
        double yo = random2 [RipperBlood] () / 16.;
        double zo = random2 [RipperBlood] () / 16.;
        Vector3 pos = mo.Vec3Offset (xo, yo, zo);

        if (bloodcls) {
            Actor th;
            th = Spawn (bloodcls, pos, NO_REPLACE); // GetBloodType already performed the replacement
            // [NG] Applying PUFFGETSOWNER to the blood will make it target the owner

            if (th.bPuffGetsOwner)
                th.target = bleeder;

            if (gameinfo.gametype == GAME_Heretic)
                th.bNoGravity = true;

            th.vel.X = mo.vel.X / 2;
            th.vel.Y = mo.vel.Y / 2;
            th.tics += random [RipperBlood] () & 3;

            // Colorize the blood!
            if (!th.bDontTranslate)
                th.Translation = bleeder.BloodTranslation;
        }
    }

    // Fucking GZDoom...
    static Actor DropItem (Actor source, Class<Actor> type, int dropAmount = -1, int chance = 256) {
        if (type != null && random [DropItem] () <= chance) {
            Actor mo;
            double spawnz = 0;

            if (true) {//!(i_compatflags & COMPATF_NoTossDrops)) {
                int style = sv_dropstyle;

                if (style == 0)
                    style = 1;//gameinfo.defaultdropstyle;

                if (style == 2)
                    spawnz = 24;
                else
                    spawnz = source.height / 2;
            }

            mo = Spawn (type, source.pos + (0, 0, spawnz), ALLOW_REPLACE);

            if (mo) {
                mo.bDropped = true;
                mo.bNoGravity = false;

                if (true)//!(i_compatflags & COMPATF_NoTossDrops))
                    TossItem (mo);

                if (mo is 'Inventory') {
                    let inv = Inventory (mo);

                    inv.ModifyDropAmount (dropAmount);
                    inv.bTossed = true;

                    if (inv.SpecialDropAction (source)) {
                        inv.Destroy ();
                        return null;
                    }

                    return inv;
                }

                return mo;
            }
        }

        return null;
    }

    static void TossItem (Actor item) {
        int style = sv_dropstyle;

        if (style == 0)
            style = 1;//gameinfo.defaultdropstyle;

        if (style == 2) {
            item.vel.X += random2 [DropItem] (7);
            item.vel.Y += random2 [DropItem] (7);
        } else {
            item.vel.X += random2 [DropItem] () / 256.;
            item.vel.Y += random2 [DropItem] () / 256.;
            item.vel.Z = 5. + random [DropItem] () / 64.;
        }
    }

    /** Delayed spawn checks **/
    static bool CheckDelayedSpawn (Actor act) {
        int maxSightRange = S7_DelayedSpawnsMaxSightRange;
        int maxSoundRange = S7_DelayedSpawnsMaxSoundRange;

        for (int i = 0; i < MaxPlayers; i++) {
            if (!playeringame [i])
                continue;
            if (!players [i].mo)
                continue;

            let pPawn = players [i].mo;
            if (pPawn.CheckSight (act, SF_IgnoreVisibility | SF_SeePastShootableLines | SF_SeePastBlockEverything) &&
                (!maxSightRange || pPawn.Distance3D (act) <= maxSightRange)
            ) {
                return true;
            }
        }

        if (act.LastHeard && (!maxSoundRange || act.LastHeard.Distance3D (act) <= maxSoundRange))
            return true;

        return false;
    }

    /* Summary:
    **  Converts player movement input to a far better format
    **
    ** Arguments:
    **  forwardMove: The player's forward movement input.
    **  sideMove: The player's sideways movement input.
    **
    ** Returns:
    **  Returns a Vector3 containing the converted input as XY and a bool indicating
    **  whether the player is running or not as Z.
    */
    static Vector3 ConvertPlayerMovementInput (int forwardMove, int sideMove) {
        bool xRunning = (abs (forwardMove) > 6400);
        bool yRunning = (abs (sideMove) > 6144);

        if (xRunning) {
            int sign = (uint (-forwardMove >>> 31) - uint (forwardMove >>> 31));
            forwardMove = (abs (forwardMove) - 6400) * sign;
        }
        if (yRunning) {
            int sign = (uint (-sideMove >>> 31) - uint (sideMove >>> 31));
            sideMove = (abs (sideMove) - 6144) * sign;
        }

        Vector3 ret;
        ret.X = (forwardMove / 6400.);
        ret.Y = (
            yRunning ?
            sideMove / 4096. :
            sideMove / 6144.
        );

        ret.Z = (xRunning || yRunning) ? 1. : 0.;

        return ret;
    }

    /* Summary:
    **   Gets the line blocking flags for this monster.
    */
    static int GetSelfBlockLineFlags (Actor act) {
        int flags = Line.ML_BlockEverything;

        bool isProjectile = act.bMissile || act.bMBFBouncer;
        bool notBlocked = act.bNoBlockMonst || (level.compatFlags & COMPATF_NoBlockFriends && act.bFriendly);

        if (isProjectile)
            flags |= Line.ML_BlockProjectile;
        if (!isProjectile || act.bBlockAsPlayer)
            flags |= Line.ML_Blocking;
        if (!notBlocked)
            flags |= Line.ML_BlockMonsters;
        if (act.player || act.bBlockAsPlayer)
            flags |= Line.ML_Blocking | Line.ML_Block_Players;
        if (act.bFloat)
            flags |= Line.ML_Block_Floaters;

        return flags;
    }

    /*static bool CheckSwitchRange (Line curLine, Actor mObj, int side, bool hasOptPos = false, Vector3 optPos = (0, 0, 0)) {
        // [...]
    }*/

    const S7_SPAC_Walking = 1 << 13; // This isn't defined in GZDoom, for some reason.
    static bool CheckCanActivateLine (Line curLine, Actor mObj, int side, int activationType, bool hasOptPos = false, Vector3 optPos = (0, 0, 0))
    {
        if (!curLine || !mObj)
            return false;

        let level = mObj.Level;
        let lineActivation = curLine.Activation;

        if ((curLine.Flags & Line.ML_FirstSideOnly && side == Line.Back) || curLine.Special == 0)
            return false;

        if ((activationType & (SPAC_Cross | SPAC_MCross)) && (lineActivation & S7_SPAC_Walking)) {
            // Not on floor.
            if ((mObj.Pos.Z > mObj.FloorZ) && !mObj.bOnMobj)
                return false;
        }

        if (lineActivation & SPAC_UseThrough)
            lineActivation |= SPAC_Use;
        else if (
            curLine.Special == Teleport &&
            (lineActivation & SPAC_Cross) &&
            (activationType & SPAC_PCross) &&
            mObj.bMissile
        ) {
            // Let missiles use regular player teleports
            lineActivation |= SPAC_PCross;
        }

        // BOOM's generalized line types that allow monster use can actually be activated by anything except projectiles.
        if (lineActivation & SPAC_AnyCross)
            lineActivation |= SPAC_Cross | SPAC_MCross;

        // NOT IMPLEMENTED
        /*if (activationType == SPAC_Use || activationType == SPAC_UseBack) {
            if (!CheckSwitchRange (curLine, mObj, side, hasOptPos, optPos))
                return false;
        }*/

        if (!mObj.player) {
            if (
                ((activationType & SPAC_Use ) && (lineActivation & SPAC_MUse ) && mObj.bCanUseWalls) ||
                ((activationType & SPAC_Push) && (lineActivation & SPAC_MPush) && mObj.bCanPushWalls)
            ) {
                return true;
            }
        }

        if ((lineActivation & activationType) == 0 && !((activationType & SPAC_MCross) && lineActivation == SPAC_Cross))
            return false;

        if ((activationType & SPAC_AnyCross) && (lineActivation & activationType))
            return true;

        if (
            !mObj.player &&
            !mObj.bMissile &&
            !(curLine.Flags & Line.ML_MonstersCanActivate) &&
            ((activationType & SPAC_MCross) == 0 || !(lineActivation & SPAC_MCross))
        ) {
            // [RH] Monsters' ability to activate this line depends on its type.
            // In Hexen, only MCROSS lines could be activated by monsters.
            // With lax activation checks, monsters can also activate certain lines
            // even without them being marked as monster activate-able.
            // This is the default for non-Hexen maps in Hexen format.
            // NOT IMPLEMENTED (we can't check for this :( )
            /*if (!(level.Flags2 & LEVEL2_LaxMonsterActivation))
                return false;*/

            // Never open secret doors.
            if ((activationType & (SPAC_Use | SPAC_Push)) && (curLine.Flags & Line.ML_Secret))
                return false;

            let noWay = true;
            if (activationType & (SPAC_Use | SPAC_Push)) {
                switch (curLine.Special) {
                    case Door_Raise:
                        return curLine.Args [0] == 0 && curLine.Args [1] < 64;

                    case Teleport:
                    case Teleport_NoFog:
                        return true;
                }

                return false;
            } else if (activationType & SPAC_MCross) {
                if ((lineActivation & SPAC_MCross))
                    return true;

                switch (curLine.Special) {
                    case Door_Raise:
                        return !(curLine.Args [1] >= 64);

                    case Teleport:
                    case Teleport_NoFog:
                    case Teleport_Line:
                    case Plat_DownWaitUpStayLip:
                    case Plat_DownWaitUpStay:
                        return true;
                }

                return false;
            } else
                return false;

            // This should be impossible to reach.
            return false;
        }

        if ((activationType & SPAC_MCross) &&
            !(lineActivation & SPAC_MCross) &&
            !(curLine.Flags & Line.ML_MonstersCanActivate))
            return false;

        return true;
    }
}