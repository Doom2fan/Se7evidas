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
    const S7_MoveDir_East = 0;
    const S7_MoveDir_West = S7_MoveDir_MaxDir / 2;
    const S7_MoveDir_North = S7_MoveDir_MaxDir / 4;
    const S7_MoveDir_South = int (floor (S7_MoveDir_MaxDir * .75));
    // MUST BE A POWER OF TWO
    // IF YOU CHANGE THIS TO ANYTHING HIGHER THAN 32,
    // REVERT COMMIT 66f70402 ("Optimized S7_DoNewChaseDir's attempts array into an int.")
    const S7_MoveDir_MaxDir = 32 - 1;
    const S7_MoveDir_NoDir = S7_MoveDir_MaxDir + 1;
    const S7_MoveDir_Count = S7_MoveDir_MaxDir + 2;
    const S7_MoveDir_Interval = 360. / (S7_MoveDir_MaxDir + 1);

    int movementDir;

    void CustomSetOrigin (Vector3 newPos) {
        LinkContext ctx;
        UnlinkFromWorld (ctx);
        SetXYZ (newPos);
        LinkToWorld (ctx);
        FindFloorCeiling ();
    }

    bool, Vector2 S7_TryWalk (out DoMoveData dmData) {
        bool success; Vector2 newPos;
        [success, newPos] = S7_DoMoveInternal (dmData, false);

        if (success)
            movecount = (random [TryWalk] () & 15);

        return success, newPos;
    }

    void S7_RandomChaseDir () {
        DoMoveData dmData;
        DoMove_GetData (dmData);

        int oldDir, turnaround = S7_MoveDir_NoDir;

        oldDir = movementDir;

        if (movementDir != S7_MoveDir_NoDir)
            turnaround = (int ((((movementDir * S7_MoveDir_Interval) + 180.) % 360.) / S7_MoveDir_Interval) & S7_MoveDir_MaxDir);

        if (bFriendly) {
            Actor player;
            int i = 0;

            if (FriendPlayer != 0)
                player = players [i = (FriendPlayer - 1)].mo;
            else {
                if (!multiplayer)
                    i = 0;
                else for (i = (random [NewChaseDir] (0, 255) & (MaxPlayers-1)); !playeringame [i]; i = ((i+1) & (MaxPlayers-1)))
                    ; // Do nothing

                player = players [i].mo;
            }

            if (player && playeringame [i]) {
                if (true || (random [NewChaseDir] (0, 255) & 1) || !CheckSight (player)) {
                    let delta = Vec2To (player);

                    S7_DoNewChaseDir (delta, dmData, player);
                    if (movementDir != S7_MoveDir_NoDir)
                        return;
                }
            }
        }
        // If the actor elects to continue in its current direction, let it do
        // so unless the way is blocked. Then it must turn.
        if (random [NewChaseDir] (0, 255) < 150) {
            if (S7_TryWalk (dmData))
                return;
        }

        int turndir = (random [NewChaseDir] (0, 255) & 1) ? -1 : 1;

        if (oldDir == S7_MoveDir_NoDir)
            oldDir = random [NewChaseDir] (0, 255);

        int tDir;
        int oldDirMasked = (oldDir & S7_MoveDir_MaxDir);
        for (tDir = ((oldDir + turndir) & S7_MoveDir_MaxDir); tDir != oldDirMasked; tDir = ((tDir + turndir) & S7_MoveDir_MaxDir)) {
            if (tDir != turnaround) {
                movementDir = (tDir & S7_MoveDir_MaxDir);
                if (S7_TryWalk (dmData))
                    return;
            }
        }

        if (turnaround != S7_MoveDir_NoDir) {
            movementDir = (turnaround & S7_MoveDir_MaxDir);
            if (S7_TryWalk (dmData)) {
                movecount = (random [NewChaseDir] (0, 255) & 15);
                return;
            }
        }

        movementDir = S7_MoveDir_NoDir;
    }

    int doNewChaseDir_WhatToIgnore;
    void S7_DoNewChaseDir (Vector2 delta, out DoMoveData dmData, Actor targ = null) {
        int d [2];
        int oldDir, walkDir = S7_MoveDir_NoDir;
        uint attempts = 0; // We don't need to attempt S7_MoveDir_NoDir.
        oldDir = movementDir;

        // Try direct route
        if (abs (delta.X) >= 10 && abs (delta.Y) >= 10) {
            double ang = VectorAngle (delta.X, delta.Y);
            movementDir = walkDir = (int ((ang >= 0 ? ang : 360 + ang) / S7_MoveDir_Interval) & S7_MoveDir_MaxDir);

            attempts |= (1 << movementDir);
            if (S7_TryWalk (dmData)) {
                doNewChaseDir_WhatToIgnore = 0;
                return;
            }
        }

        if (doNewChaseDir_WhatToIgnore == 0 || doNewChaseDir_WhatToIgnore == 3) {
            int forwardsDir = walkDir;

            if (forwardsDir == S7_MoveDir_NoDir)
                forwardsDir = oldDir;

            if (forwardsDir != S7_MoveDir_NoDir) {
                int moveDir = forwardsDir - 8;

                if (moveDir < 0)
                    moveDir = 32 + moveDir;

                int tmp = ((0xFFFF << moveDir) | (0xFFFF >>> (32-moveDir)));

                if (doNewChaseDir_WhatToIgnore == 0)
                    attempts |= ~tmp;
                else
                    attempts |= tmp;
            } else
                doNewChaseDir_WhatToIgnore = ((doNewChaseDir_WhatToIgnore+1) & 3);
        }

        if (doNewChaseDir_WhatToIgnore <= 1)
            attempts = 0xAAAAAAAA; // Only even bits
        else if (doNewChaseDir_WhatToIgnore == 2)
            attempts = 0x55555555; // Only odd bits

        // Sweep to the left and to the right. We alternate from clockwise to
        // counter-clockwise to make the actor less likely to get stuck.
        // We also try to move in the direction that gets us the closest to
        // our target.
        int sweepClosestDirs [S7_MoveDir_MaxDir + 1];
        int sweepIgnoredDirs [S7_MoveDir_MaxDir + 1]; // We keep this so we can try those in the next pass.
        int closestDirsCount = 0, ignoredDirsCount = 0;
        double sweepClosestDist = double.infinity;
        bool hasTarget = false;
        Vector2 targPos;

        if (targ) {
            targPos = targ.pos.XY;
            hasTarget = true;
        } if ((bChaseGoal || goal == target) && goal) {
            targPos = goal.pos.XY;
            hasTarget = true;
        } else if (aiNextNode) {
            targPos = aiNextNode.pos.XY;
            hasTarget = true;
        } else if (target) {
            targPos = target.pos.XY;
            hasTarget = true;
        }

        if (hasTarget) {
            int sweepSwap = ((random [NewChaseDir] (0, 255) & 1) ? -1 : 1);
            int forwardsDir = walkDir;

            if (forwardsDir == S7_MoveDir_NoDir) {
                if (oldDir != S7_MoveDir_NoDir)
                    forwardsDir = oldDir;
                else
                    forwardsDir = 0;
            }

            //bool asd = false;
            for (int i = 1; i <= S7_MoveDir_MaxDir; i++) {
                int tDir = forwardsDir + ((i >> 1) * sweepSwap);
                tDir = tDir & S7_MoveDir_MaxDir;
                sweepSwap = -sweepSwap;

                if ((attempts & (1 << tDir)))
                    continue;

                movementDir = tDir;
                attempts |= (1 << movementDir);
                if (S7_TryWalk (dmData)) {
                    doNewChaseDir_WhatToIgnore = 0;
                    return;
                }

                /*if (asd) {
                    sweepIgnoredDirs [ignoredDirsCount++] = tDir;
                    continue;
                }

                bool success; Vector2 newPos;

                movementDir = (tDir & S7_MoveDir_MaxDir);
                [success, newPos] = S7_DoMoveInternal (dmData, true);

                double dist = double.infinity;
                if (success) {
                    let diff = level.Vec2Diff (newPos, targPos);
                    dist = diff dot diff;
                }

                if (success && dist <= sweepClosestDist) {
                    sweepClosestDirs [closestDirsCount++] = tDir;
                    sweepClosestDist = dist;
                    asd = true;
                } else
                    sweepIgnoredDirs [ignoredDirsCount++] = tDir;*/
            }
        }

        /*// Try the directions that'll get us closer to our target.
        if (closestDirsCount > 0) {
            for (int i = closestDirsCount - 1; i >= 0; i--) {
                // We don't need to check if it was already attempted here.
                movementDir = sweepClosestDirs [i];
                attempts |= (1 << movementDir);
                if (S7_TryWalk (dmData)) {
                    doNewChaseDir_WhatToIgnore = 0;
                    return;
                }
            }
        }

        // Try the other directions.
        if (ignoredDirsCount > 0) {
            for (int i = 0; i < ignoredDirsCount; i++) {
                // We don't need to check if it was already attempted here.
                movementDir = sweepIgnoredDirs [i];
                attempts |= (1 << movementDir);
                if (S7_TryWalk (dmData)) {
                    doNewChaseDir_WhatToIgnore = 0;
                    return;
                }
            }
        }*/

        // Cannot move
        movementDir = S7_MoveDir_NoDir;
        doNewChaseDir_WhatToIgnore = ((doNewChaseDir_WhatToIgnore+1) & 3);
    }

    void S7_NewChaseDir () {
        DoMoveData dmData;
        DoMove_GetData (dmData);

        if (bBlasted)
            return;

        if (!(bNoGravity || bCanJump) && (pos.Z > floorZ && !bOnMobj))
            return;

        Vector2 delta;

        if ((bChaseGoal || goal == target) && goal) {
            delta = Vec2To (goal);
        } else if (aiNextNode) {
            delta = Vec2To (aiNextNode);
        } else if (target) {
            delta = Vec2To (target);

            if (!bNoFear) {
                if ((target.player && (target.player.cheats & CF_Frightening)) ||
                    bFrightened || target.bFrightening
                ) {
                    delta = -delta;
                }
            }
        } else {
            Console.Printf ("S7_NewChaseDir: called with no target");
            return;
        }

        if (floorZ - dropoffZ > MaxDropOffHeight && pos.Z <= floorZ &&
            !bDropOff && !bOnMobj && !bFloat
        ) {
            let box = S7_BoundingBox.Create (pos.XY, radius);
            let it = BlockLinesIterator.Create (self);
            Line line;

            Vector2 dropoffDelta = (0, 0);
            while ((it.Next () && (line = it.CurLine))) {
                // Ignore one-sided linedefs
                if (line.backsector &&
                    box.inRange (line)
                    && box.BoxOnLineSide (line) == -1
                ) {
                    let relPos = PosRelative (line.frontsector);
                    double front = line.frontsector.floorplane.ZatPoint (relPos.XY);
                    double back  =  line.backsector.floorplane.ZatPoint (relPos.XY);
                    double ang;

                    // The monster must contact one of the two floors,
                    // and the other must be a tall dropoff

                    if (back == pos.Z && front < pos.Z - MaxDropOffHeight)
                        ang = VectorAngle (line.delta.X, line.delta.Y); // Front side dropoff
                    else if (front == pos.Z && back < pos.Z - MaxDropOffHeight)
                        ang = VectorAngle (line.delta.X, line.delta.Y) + 180.; // Back side dropoff
                    else
                        continue;

                    ang = (ang >= 0 ? ang : 360. + ang);

                    // Move away from dropoff at a standard speed.
                    // Multiple contacted linedefs are cumulative (e.g. hanging over corner)
                    dropoffDelta.X -= Speed * sin (ang);
                    dropoffDelta.Y += Speed * cos (ang);
                }
            }

            if (!(dropoffDelta ~== (0, 0))) {
                S7_DoNewChaseDir (dropoffDelta, dmData);

                // If moving away from dropoff, set movecount to 1 so that
                // small steps are taken away to get monster away from dropoff
                movecount = 1;

                return;
            }
        }

        if (target && target.health > 0 && !isFriend (target) && target != goal && !aiNextNode) {
            // Live enemy target
            if (bAvoidMelee) {
                bool isMeleeAttacker = false;
                double dist = Distance2D (target);

                if (!target.player)
                    isMeleeAttacker = (target.MissileState == null && dist < (target.MeleeRange + target.radius) * 2);
                else if (target.player.ReadyWeapon) {
                    // Melee range of player weapon is a parameter of the action function and cannot be checked here.
                    isMeleeAttacker = (target.player.ReadyWeapon.bMeleeWeapon && dist < 192);
                }

                if (isMeleeAttacker) {
                    strafecount = random [EnemyStrafe] (0, 255) & 15;
                    delta = -delta;
                }
            }
        }

        S7_DoNewChaseDir (delta, dmData);

        // If strafing, set movecount to strafecount so that old Doom
        // logic still works the same, except in the strafing part

        if (strafecount)
            movecount = strafecount;
    }

    bool, Vector2 S7_DoMove (bool checkOnly = false) {
        if (bBlasted)
            return true, pos.XY;

        if (!(bNoGravity || bCanJump) && (pos.Z > floorZ && !bOnMobj))
            return false, pos.XY;

        DoMoveData dmData;
        DoMove_GetData (dmData);

        return S7_DoMoveInternal (dmData, checkOnly);
    }

    struct DoMoveData {
        int dropoff;
        double maxmove;

        double initialFloorZ;
    }

    void DoMove_GetData (out DoMoveData data) {
        data.dropoff = 0;
        data.maxmove = max (radius, 1);
        data.initialFloorZ = GetZAt (pos.X, pos.Y, flags: GZF_AbsolutePos | GZF_AbsoluteAng);

        // killough 10/98: Allow dogs to drop off of taller ledges sometimes.
        // dropoff == 1 means always allow it, dropoff==2 means only up to 128 high,
        // and only if the target is immediately on the other side of the line.
        if (bJumpDown && target && !target.IsFriend (self) && Distance2DSquared (target) < 144*144 && random [Dropoff] (0, 255) < 235)
            data.dropoff = 2;
    }

    bool, Vector2 S7_DoMoveInternal (out DoMoveData data, bool checkOnly = false) {
        if (movementDir >= S7_MoveDir_NoDir) {
            movementDir = S7_MoveDir_NoDir; // Make sure it's valid.
            return false, pos.XY;
        }

        Vector2 possibleNewPos = (0, 0);
        Vector3 oldPos = pos;
        double oldAngle = angle, oldPitch = pitch;
        bool tryOK;

        angle = double (movementDir) * S7_MoveDir_Interval;
        pitch = 0;
        Vector3 moveVec = (AngleToVector (angle, Speed), 0);

        int stepCount = int (ceil (Speed / data.maxmove));
        double stepCountInv = 1. / stepCount;

        FCheckPosition tm;
        tm.FromPMove = true;

        Vector2 startPos = pos.XY;
        Vector2 tryMoveVec = moveVec.XY;
        double tryMoveOldAngle = angle;

        tryOK = true;
        let prevPrev = Prev;
        let prevPos = pos;
        bool savedDropOff = bDropOff;
        double oldFloorZ = data.initialFloorZ;
        bDropOff = false;
        for (int i = 1; i <= stepCount; i++) {
            let ptry = startPos + tryMoveVec * i * stepCountInv;

            // killough 3/15/98: Don't jump over dropoffs
            if (!checkOnly) {
                prevPos = pos;
                Prev = prevPrev;
                tryOK = TryMove (ptry, true, null, tm);
            } else {
                prevPos = (startPos + tryMoveVec * (i - 1) * stepCountInv, pos.Z);
                tryOK = CheckMove (ptry, 0, tm: tm);
            }

            double newFloorZ = GetZAt (ptry.X, ptry.Y, flags: GZF_AbsolutePos | GZF_AbsoluteAng);

            if (!savedDropOff && abs (newFloorZ - oldFloorZ) > MaxStepHeight) {
                tryOK = false;
                if (!checkOnly) {
                    CustomSetOrigin (prevPos);

                    if (!NoMonsterInterpolation)
                        Prev = prevPrev;
                    else
                        Prev = prevPos;
                }
            }

            if (!tryOK) break;

            oldFloorZ = newFloorZ;
            possibleNewPos = pTry;

            // Handle portal transitions just like P_XYMovement.
            if ((stepCount > 1) & (pos.XY != ptry)) {
                double angleDiff = DeltaAngle (tryMoveOldAngle, angle);

                if (!(anglediff ~== 0)) {
                    tryMoveVec = RotateVector (tryMoveVec, angleDiff);
                    tryMoveOldAngle = angle;
                }

                startPos = pos.XY - tryMoveVec * i * stepCountInv;
            }
        }

        bDropoff = savedDropOff;

        ClearInterpolation ();

        // [RH] If a walking monster is no longer on the floor, move it down
        // to the floor if it is within MaxStepHeight, presuming that it is
        // actually walking down a step.
        if (tryOK && !(bNoGravity || bCanJump) && (pos.Z > floorZ) && !bOnMobj) {
            if (pos.Z <= floorZ + MaxStepHeight) {
                double savedZ = pos.Z;

                SetZ (floorZ);

                // Make sure that there isn't some other actor between us and
                // the floor we could get stuck in. The old code did not do this.
                if (!TestMobjZ ())
                    SetZ (savedZ);
                else if (!checkOnly) {
                    let relPos = PosRelative (floorsector);

                    // The monster just hit the floor, so trigger any actions.
                    if (floorsector.SecActTarget && floorZ ~== floorsector.floorplane.ZAtPoint (relPos.XY))
                        floorsector.TriggerSectorActions (self, SectorAction.SECSPAC_HitFloor);
                    CheckFor3DFloorHit (pos.Z, true);
                }
            }
        }

        if (!tryOK) {
            if ((bCanJump || bFloat) && tm.floatok) {
                // Must adjust height
                double savedZ = pos.Z;

                if (pos.Z < tm.floorZ)
                    AddZ (FloatSpeed);
                else
                    AddZ (-FloatSpeed);

                // [RH] Check to make sure there's nothing in the way of the float
                if (TestMobjZ ()) {
                    bInFloat = true;

                    if (checkOnly) {
                        CustomSetOrigin (oldPos);
                        ClearInterpolation ();
                        angle = oldAngle;
                        pitch = oldPitch;
                    } else if (!NoMonsterInterpolation && pos.XY ~== possibleNewPos)
                        Prev = oldPos;

                    return true, possibleNewPos;
                }

                SetZ (savedZ);
            }

            if (!checkOnly) {
                // Open any specials
                movementDir = S7_MoveDir_NoDir;

                int usesCount = CheckMonsterUseSpecials ();

                if (!NoMonsterInterpolation && pos.XY ~== possibleNewPos)
                    Prev = oldPos;

                return usesCount && ((random [OpenDoor] (0, 255) >= 203) ^ (usesCount & 1)), possibleNewPos;
            }
        } else
            bInFloat = false;

        if (checkOnly) {
            CustomSetOrigin (oldPos);
            ClearInterpolation ();
            angle = oldAngle;
            pitch = oldPitch;
        } else if (!NoMonsterInterpolation && pos.XY ~== possibleNewPos)
            Prev = oldPos;

        return tryOK, possibleNewPos;
    }
}