/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 1993-1996 id Software
 *  Copyright (C) 1994-1996 Raven Software
 *  Copyright (C) 1998-1998 Chi Hoang, Lee Killough, Jim Flynn, Rand Phares, Ty Halderman
 *  Copyright (C) 1999-2016 Randy Heit
 *  Copyright (C) 2002-2016 Christoph Oelckers
 *  Copyright (C) 2018      Chronos "phantombeta" Ouroboros
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
    const S7_MOVEDIR_EAST = 0;
    const S7_MOVEDIR_WEST = S7_MOVEDIR_MAXDIR / 2;
    const S7_MOVEDIR_NORTH = S7_MOVEDIR_MAXDIR / 4;
    const S7_MOVEDIR_SOUTH = int (floor (S7_MOVEDIR_MAXDIR * .75));
    const S7_MOVEDIR_MAXDIR = 32 - 1; // MUST BE A POWER OF TWO
    const S7_MOVEDIR_NODIR = S7_MOVEDIR_MAXDIR + 1;
    const S7_MOVEDIR_COUNT = S7_MOVEDIR_MAXDIR + 2;
    const S7_MOVEDIR_INTERVAL = 360. / (S7_MOVEDIR_MAXDIR + 1);

    int movementDir;

    bool, Vector2 S7_TryWalk (bool checkOnly = false) {
        bool success; Vector2 newPos;
        [success, newPos] = S7_DoMove (checkOnly);
        if (!success)
            return false, newPos;

        if (!checkOnly)
            movecount = (random [TryWalk] (0, 255) & 15);

        return true, newPos;
    }

    void S7_RandomChaseDir () {
        int oldDir, turnaround = S7_MOVEDIR_NODIR;

        oldDir = movementDir;

        if (movementDir != S7_MOVEDIR_NODIR)
            turnaround = (int ((((movementDir * S7_MOVEDIR_INTERVAL) + 180.) % 360.) / S7_MOVEDIR_INTERVAL) & S7_MOVEDIR_MAXDIR);

        if (bFriendly) {
            Actor player;
            int i = 0;

            if (FriendPlayer != 0)
                player = players [i = (FriendPlayer - 1)].mo;
            else {
                if (!multiplayer)
                    i = 0;
                else for (i = (random [NewChaseDir] (0, 255) & (MAXPLAYERS-1)); !playeringame [i]; i = ((i+1) & (MAXPLAYERS-1)))
                    ; // Do nothing

                player = players [i].mo;
            }

            if (player && playeringame [i]) {
                if (true || (random [NewChaseDir] (0, 255) & 1) || !CheckSight (player)) {
                    let delta = Vec2To (player);
                    int d [2];

                    if (delta.X > 10)
                        d [0] = S7_MOVEDIR_EAST;
                    else if (delta.X < -10)
                        d [0] = S7_MOVEDIR_WEST;
                    else
                        d [0] = S7_MOVEDIR_NODIR;

                    if (delta.Y < -10)
                        d [1] = S7_MOVEDIR_SOUTH;
                    else if (delta.Y > 10)
                        d [1] = S7_MOVEDIR_NORTH;
                    else
                        d [1] = S7_MOVEDIR_NODIR;

                    S7_DoNewChaseDir (d [0], d [1], player);
                    if (movementDir != S7_MOVEDIR_NODIR)
                        return;
                }
            }
        }
        // If the actor elects to continue in its current direction, let it do
        // so unless the way is blocked. Then it must turn.
        if (random [NewChaseDir] (0, 255) < 150) {
            if (S7_TryWalk ())
                return;
        }

        int turndir = (random [NewChaseDir] (0, 255) & 1) ? -1 : 1;

        if (oldDir == S7_MOVEDIR_NODIR)
            oldDir = random [NewChaseDir] (0, 255);

        int tDir;
        int oldDirMasked = (oldDir & S7_MOVEDIR_MAXDIR);
        for (tDir = ((oldDir + turndir) & S7_MOVEDIR_MAXDIR); tDir != oldDirMasked; tDir = ((tDir + turndir) & S7_MOVEDIR_MAXDIR)) {
            if (tDir != turnaround) {
                movementDir = (tDir & S7_MOVEDIR_MAXDIR);
                if (S7_TryWalk ())
                    return;
            }
        }

        if (turnaround != S7_MOVEDIR_NODIR) {
            movementDir = (turnaround & S7_MOVEDIR_MAXDIR);
            if (S7_TryWalk ()) {
                movecount = (random [NewChaseDir] (0, 255) & 15);
                return;
            }
        }

        movementDir = S7_MOVEDIR_NODIR;
    }

    void S7_DoNewChaseDir (double deltaX, double deltaY, Actor targ = null) {
        int d [2];
        int oldDir, turnaround = S7_MOVEDIR_NODIR;
        bool attempts [S7_MOVEDIR_COUNT - 1]; // We don't need to attempt S7_MOVEDIR_NODIR.

        for (int i = 0; i < S7_MOVEDIR_COUNT - 1; i++)
            attempts [i] = false;
        oldDir = movementDir;

        if (movementDir != S7_MOVEDIR_NODIR)
            turnaround = (int ((((movementDir * S7_MOVEDIR_INTERVAL) + 180.) % 360.) / S7_MOVEDIR_INTERVAL) & S7_MOVEDIR_MAXDIR);

        if (deltaX > 10)
            d [0] = S7_MOVEDIR_EAST;
        else if (deltaX < -10)
            d [0] = S7_MOVEDIR_WEST;
        else
            d [0] = S7_MOVEDIR_NODIR;

        if (deltaY < -10)
            d [1] = S7_MOVEDIR_SOUTH;
        else if (deltaY > 10)
            d [1] = S7_MOVEDIR_NORTH;
        else
            d [1] = S7_MOVEDIR_NODIR;

        // Try direct route
        if (d [0] != S7_MOVEDIR_NODIR && d [1] != S7_MOVEDIR_NODIR) {
            double ang = VectorAngle (deltaX, deltaY);
            movementDir = (int ((ang >= 0 ? ang : 360 + ang) / S7_MOVEDIR_INTERVAL) & S7_MOVEDIR_MAXDIR);

            if (movementDir != turnaround) {
                attempts [movementDir] = true;
                if (S7_TryWalk ())
                    return;
            }
        }

        // Try other directions
        if (!bAvoidingDropoff) {
            // There is no direct path to the enemy, so pick another direction.
            if (oldDir != S7_MOVEDIR_NODIR && attempts [oldDir] == false) {
                movementDir = (oldDir & S7_MOVEDIR_MAXDIR);
                attempts [oldDir] = true;
                if (S7_TryWalk ())
                    return;
            }
        }

        // Sweep to the left and to the right. We alternate from clockwise to
        // counter-clockwise to make the actor less likely to get stuck.
        // We also try to move in the direction that gets us the closest to
        // our target.
        Array<int> sweepClosestDirs; sweepClosestDirs.Clear ();
        Array<int> sweepIgnoredDirs; sweepIgnoredDirs.Clear (); // We keep this so we can try those in the next pass.
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
            for (int i = 1; i <= S7_MOVEDIR_MAXDIR * 2; i++) {
                int tDir = movementDir + (((-1) ^ ((i+1) & 1) * ((i+1) >> 1)));

                if (tDir > S7_MOVEDIR_MAXDIR)
                    tDir = tDir - S7_MOVEDIR_MAXDIR;
                if (tDir < -S7_MOVEDIR_MAXDIR)
                    tDir = tDir + S7_MOVEDIR_MAXDIR;
                if (tDir < 0)
                    tDir = S7_MOVEDIR_MAXDIR + tDir;

                if (tDir != turnaround && attempts [tDir] == false) {
                    bool success; Vector2 newPos;

                    movementDir = (tDir & S7_MOVEDIR_MAXDIR);
                    [success, newPos] = S7_TryWalk (true);

                    let diff = level.Vec2Diff (newPos, targPos);
                    double dist = diff dot diff;
                    if (success && dist <= sweepClosestDist) {
                        sweepClosestDirs.Push (tDir);
                        sweepClosestDist = dist;
                    } else if (success)
                        sweepIgnoredDirs.Push (tDir);
                }
            }
        }

        // Try the directions that'll get us closer to our target.
        if (sweepClosestDirs.Size () > 0) {
            for (int i = sweepClosestDirs.Size () - 1; i >= 0; i--) {
                // We don't need to do checks or mark as attempted here.
                movementDir = sweepClosestDirs [i];
                attempts [movementDir] = true;
                if (S7_TryWalk ())
                    return;
            }
        }

        // Try the other directions.
        if (sweepIgnoredDirs.Size () > 0) {
            for (int i = 0; i < sweepIgnoredDirs.Size (); i++) {
                // We don't need to do checks or mark as attempted here.
                movementDir = sweepIgnoredDirs [i];
                attempts [movementDir] = true;
                if (S7_TryWalk ())
                    return;
            }
        }

        // If all else fails, try to turn around.
        if (turnaround != S7_MOVEDIR_NODIR && attempts [turnaround] == false) {
            movementDir = (turnaround & S7_MOVEDIR_MAXDIR);
            if (S7_TryWalk ())
                return;
        }

        // Cannot move
        movementDir = S7_MOVEDIR_NODIR;
    }

    void S7_NewChaseDir () {
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

            double deltaX = 0;
            double deltaY = 0;
            while ((it.Next () && (line = it.CurLine))) {
                // Ignore one-sided linedefs
                if (line.backsector &&
                    box.inRange (line)
                    && box.BoxOnLineSide (line) == -1
                ) {
                    let relPos = PosRelative (line.frontsector);
                    double front = line.frontsector.floorplane.ZatPoint (relPos.XY);
                    double back  = line.backsector.floorplane.ZatPoint  (relPos.XY);
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
                    deltaX -= 32 * sin (ang);
                    deltaY += 32 * cos (ang);
                }
            }

            if (deltaX != 0 || deltaY != 0) {
                // [Graf Zahl] I have changed P_TryMove to only apply this logic when
                // being called from here. AVOIDINGDROPOFF activates the code that
                // allows monsters to move away from a dropoff. This is different from
                // MBF which requires unconditional use of the altered logic and therefore
                // forcing a massive change in the monster behavior to use this.

                bAvoidingDropoff = true;
                S7_DoNewChaseDir (deltaX, deltaY);
                bAvoidingDropoff = false;

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
                    isMeleeAttacker = (target.MissileState == NULL && dist < (target.MeleeRange + target.radius) * 2);
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

        S7_DoNewChaseDir (delta.X, delta.Y);

        // If strafing, set movecount to strafecount so that old Doom
        // logic still works the same, except in the strafing part

        if (strafecount)
            movecount = strafecount;
    }

    bool, Vector2 S7_DoMove (bool checkOnly = false) {
        if (bBlasted)
            return true, pos.XY;

        if (movementDir >= S7_MOVEDIR_NODIR) {
            movementDir = S7_MOVEDIR_NODIR; // make sure it's valid.
            return false, pos.XY;
        }

        if (!(bNoGravity || bCanJump) && (pos.Z > floorZ && !bOnMobj))
            return false, pos.XY;

        Vector2 possibleNewPos = (0, 0);
        Vector3 oldPos = pos;
        double oldAngle = angle, oldPitch = pitch;
        int dropoff = 0;
        bool tryOK;

        // killough 10/98: Allow dogs to drop off of taller ledges sometimes.
        // dropoff == 1 means always allow it, dropoff==2 means only up to 128 high,
        // and only if the target is immediately on the other side of the line.
        if (bJumpDown && target && !target.IsFriend (self) && Distance2D (target) < 144 && random [Dropoff] (0, 255) < 235)
            dropoff = 2;

        Vector3 moveVec = (AngleToVector (double (movementDir) * S7_MOVEDIR_INTERVAL, Speed), 0);
        [angle, pitch] = S7_Math.GetAnglesTo (level, pos, pos + moveVec);

        double maxmove = radius - 1.;
        double stepCount = 1;

        if (maxmove > 0) {
            double xSpeed = abs (moveVec.X);
            double ySpeed = abs (moveVec.Y);

            if (xSpeed > ySpeed) {
                if (xSpeed > maxmove)
                    stepCount = 1 + int (xSpeed / maxmove);
            } else {
                if (ySpeed > maxmove)
                    stepCount = 1 + int (ySpeed / maxmove);
            }
        }

        FCheckPosition tm;
        tm.FromPMove = true;

        Vector2 startPos = pos.XY;
        Vector2 tryMoveVec = moveVec.XY;
        double tryMoveOldAngle = angle;

        tryOK = true;
        for (int i = 1; i <= stepCount; i++) {
            let ptry = startPos + tryMoveVec * i / stepCount;

            // killough 3/15/98: don't jump over dropoffs
            if (!checkOnly)
                tryOK = TryMove (ptry, dropoff, NULL, tm);
            else
                tryOK = CheckMove (ptry, 0, tm: tm);
            if (!tryOK) break;

            possibleNewPos = pTry;

            // Handle portal transitions just like P_XYMovement.
            if (stepCount > 1 && pos.XY != ptry) {
                double angleDiff = DeltaAngle (tryMoveOldAngle, angle);

                if (!(anglediff ~== 0)) {
                    tryMoveVec = RotateVector (tryMoveVec, angleDiff);
                    tryMoveOldAngle = angle;
                }

                startPos = pos.XY - tryMoveVec * i / stepCount;
            }
        }

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
                // must adjust height
                double savedZ = pos.Z;

                if (pos.Z < tm.floorZ)
                    AddZ (FloatSpeed);
                else
                    AddZ (-FloatSpeed);

                // [RH] Check to make sure there's nothing in the way of the float
                if (TestMobjZ ()) {
                    bInFloat = true;

                    if (checkOnly) {
                        SetOrigin (oldPos, false);
                        angle = oldAngle;
                        pitch = oldPitch;
                    } else if (!NoMonsterInterpolation && pos.XY ~== possibleNewPos) {
                        Vector3 newPos = pos;
                        SetOrigin (oldPos, false);
                        SetOrigin (newPos, true);
                    }

                    return true, possibleNewPos;
                }

                SetZ (savedZ);
            }

            if (!checkOnly) {
                // Open any specials
                movementDir = S7_MOVEDIR_NODIR;

                int usesCount = CheckMonsterUseSpecials ();

                if (!NoMonsterInterpolation && pos.XY ~== possibleNewPos) {
                    Vector3 newPos = pos;
                    SetOrigin (oldPos, false);
                    SetOrigin (newPos, true);
                }
                
                return usesCount && ((random [OpenDoor] (0, 255) >= 203) ^ (usesCount & 1)), possibleNewPos;
            }
        } else
            bInFloat = false;

        if (checkOnly) {
            SetOrigin (oldPos, false);
            angle = oldAngle;
            pitch = oldPitch;
        } else if (!NoMonsterInterpolation && pos.XY ~== possibleNewPos) {
            Vector3 newPos = pos;
            SetOrigin (oldPos, false);
            SetOrigin (newPos, true);
        }

        return tryOK, possibleNewPos;
    }
}