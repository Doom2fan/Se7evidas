extend class S7_MonsterBase {
    const S7_MOVEDIR_EAST = 0;
    const S7_MOVEDIR_WEST = 32;
    const S7_MOVEDIR_NORTH = 16;
    const S7_MOVEDIR_SOUTH = 48;
    const S7_MOVEDIR_MAXDIR = 64;
    const S7_MOVEDIR_NODIR = 65;
    const S7_MOVEDIR_COUNT = 66;
    const S7_MOVEDIR_INTERVAL = 5.625;

    bool S7_TryWalk () {
        if (!S7_DoMove ())
            return false;

        movecount = random [TryWalk] (0, 255) & 15;
        return true;
    }

    void S7_DoNewChaseDir (double deltaX, double deltaY) {
        int d [2];
        int tDir;
        int oldDir, turnaround = S7_MOVEDIR_NODIR;
        bool attempts [S7_MOVEDIR_COUNT - 1]; // We don't need to attempt S7_MOVEDIR_NODIR.

        for (int i = 0; i < S7_MOVEDIR_COUNT - 1; i++)
            attempts [i] = false;
        oldDir = movedir;

        if (movedir != S7_MOVEDIR_NODIR)
            turnaround = int ((((movedir * S7_MOVEDIR_INTERVAL) + 180.) % 360.) / S7_MOVEDIR_INTERVAL);

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
            movedir = int ((ang >= 0 ? ang : 360 + ang) / S7_MOVEDIR_INTERVAL);

            if (movedir != turnaround) {
                attempts [movedir] = true;
                if (S7_TryWalk ())
                    return;
            }
        }

        // Try other directions
        if (!bAvoidingDropoff) {
            if (random [NewChaseDir] (0, 255) > 200 || abs (deltaY) > abs (deltaX)) {
                d [0] = (d [0] ^ d [1]);
                d [1] = (d [1] ^ d [0]);
                d [0] = (d [0] ^ d [1]);
            }

            if (d [0] == turnaround)
                d [0] = S7_MOVEDIR_NODIR;
            if (d [1] == turnaround)
                d [1] = S7_MOVEDIR_NODIR;
        }

        for (int i = 0; i < 2; i++) {
            if (d [1] != S7_MOVEDIR_NODIR && attempts [d [1]] == false) {
                movedir = d [1];
                attempts [d [1]] = true;
                // Either moved forward or attacked
                if (S7_TryWalk ())
                    return;
            }
        }

        if (!bAvoidingDropoff) {
            // There is no direct path to the enemy, so pick another direction.
            if (oldDir != S7_MOVEDIR_NODIR && attempts [oldDir] == false) {
                movedir = oldDir;
                attempts [oldDir] = true;
                if (S7_TryWalk ())
                    return;
            }
        }

        {
            bool reverse = random [NewChaseDir] (0, 255) & 1;
            int start = !reverse ?  S7_MOVEDIR_EAST       :  S7_MOVEDIR_MAXDIR    ;
            int end   = !reverse ?  S7_MOVEDIR_MAXDIR     : (S7_MOVEDIR_EAST  - 1);
            int incr = !reverse ? 1 : -1;

            for (tDir = start; !reverse ? (tDir <= end) : (tDir != end); tDir += incr) {
                if (tDir != turnaround && attempts [tdir] == false) {
                    movedir = tDir;
                    attempts [tDir] = true;
                    if (S7_TryWalk ())
                        return;
                }
            }
        }

        if (turnaround != S7_MOVEDIR_NODIR && attempts [turnaround] == false) {
            movedir = turnaround;
            if (S7_TryWalk ())
                return;
        }

        // Cannot move
        movedir = S7_MOVEDIR_NODIR;
    }

    void S7_NewChaseDir () {
        Vector2 delta;

        if ((bChaseGoal || goal == target) && goal) {
            delta = Vec2To (goal);
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

        if (target.health > 0 && !isFriend (target) && target != goal) {
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

    bool S7_DoMove () {
        if (bBlasted)
            return true;

        if (movedir >= S7_MOVEDIR_NODIR) {
            movedir = S7_MOVEDIR_NODIR; // make sure it's valid.
            return false;
        }

        if (!(bNoGravity || bCanJump) && (pos.Z > floorZ && !bOnMobj))
            return false;

        Vector3 oldPos = pos;
        int dropoff = 0;
        bool tryOK;

        // killough 10/98: Allow dogs to drop off of taller ledges sometimes.
        // dropoff == 1 means always allow it, dropoff==2 means only up to 128 high,
        // and only if the target is immediately on the other side of the line.
        if (bJumpDown && target && !target.IsFriend (self) && Distance2D (target) < 144 && random [Dropoff] (0, 255) < 235)
            dropoff = 2;

        Vector3 moveVec = (AngleToVector (movedir * S7_MOVEDIR_INTERVAL, Speed), 0);
        [angle, pitch] = S7_Math.GetAnglesTo (pos, pos + moveVec);

        double maxmove = radius - 1.;
        int stepCount = 1;

        if (maxmove > 0) {
            double xSpeed = abs (moveVec.X);
            double ySpeed = abs (moveVec.Y);

            if (xSpeed > ySpeed) {
                if (xSpeed > maxmove)
                    stepCount = 1 + int (xSpeed / maxmove);
            }
            else {
                if (ySpeed > maxmove)
                    stepCount = 1 + int (ySpeed / maxmove);
            }
        }

        FCheckPosition tm;
        tm.FromPMove = true;

        Vector2 startPos = pos.XY;
        Vector2 tryMoveVec = moveVec.XY;
        double oldAngle = angle;

        tryOK = true;
        for (int i = 1; i <= stepCount; i++) {
            let ptry = startPos + tryMoveVec * i / stepCount;

            // killough 3/15/98: don't jump over dropoffs
            tryOK = TryMove (ptry, dropoff, NULL, tm);
            if (!tryOK) break;

            // Handle portal transitions just like P_XYMovement.
            if (stepCount > 1 && pos.XY != ptry) {
                double angleDiff = DeltaAngle (oldAngle, angle);

                if (!(anglediff ~== 0)) {
                    tryMoveVec = RotateVector (tryMoveVec, angleDiff);
                    oldAngle = angle;
                }

                startPos = pos.XY - tryMoveVec * i / stepCount;
            }
        }

        if (NoMonsterInterpolation)
            ClearInterpolation ();

        // [RH] If a walking monster is no longer on the floor, move it down
        // to the floor if it is within MaxStepHeight, presuming that it is
        // actually walking down a step.
        if (tryOK && !(bNoGravity || bCanJump) && pos.Z > floorZ && !bOnMobj) {
            if (pos.Z <= floorZ + MaxStepHeight) {
                double savedZ = pos.Z;

                SetZ (floorZ);

                // Make sure that there isn't some other actor between us and
                // the floor we could get stuck in. The old code did not do this.
                if (!TestMobjZ ())
                    SetZ (savedZ);
                else {
                    let relPos = PosRelative (floorsector);

                    // The monster just hit the floor, so trigger any actions.
                    if (floorsector.SecActTarget && floorZ ~== floorsector.floorplane.ZAtPoint (relPos.XY))
                        floorsector.TriggerSectorActions (self, SectorAction.SECSPAC_HitFloor);
                    //P_CheckFor3DFloorHit (self, pos.Z, true);
                }
            } else if (pos.Z < floorZ)
                SetZ (floorZ);
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

                    Vector3 newPos = pos;
                    SetOrigin (oldPos, false);
                    SetOrigin (newPos, true);

                    return true;
                }

                SetZ (savedZ);
            }

            /*if (!spechit.Size ())
            {
                return false;
            }

            // open any specials
            movedir = DI_NODIR;

            // if the special is not a door that can be opened, return false
            //
            // killough 8/9/98: this is what caused monsters to get stuck in
            // doortracks, because it thought that the monster freed itself
            // by opening a door, even if it was moving towards the doortrack,
            // and not the door itself.
            //
            // killough 9/9/98: If a line blocking the monster is activated,
            // return true 90% of the time. If a line blocking the monster is
            // not activated, but some other line is, return false 90% of the
            // time. A bit of randomness is needed to ensure it's free from
            // lockups, but for most cases, it returns the correct result.
            //
            // Do NOT simply return false 1/4th of the time (causes monsters to
            // back out when they shouldn't, and creates secondary stickiness).

            spechit_t spec;
            int good = 0;
            
            if (!(flags6 & MF6_NOTRIGGER))
            {
                while (spechit.Pop (spec))
                {
                    // [RH] let monsters push lines, as well as use them
                    if (((flags4 & MF4_CANUSEWALLS) && P_ActivateLine (spec.line, actor, 0, SPAC_Use)) ||
                        ((flags2 & MF2_PUSHWALL) && P_ActivateLine (spec.line, actor, 0, SPAC_Push)))
                    {
                        good |= spec.line == BlockingLine ? 1 : 2;
                    }
                }
            }
            else spechit.Clear();
            return good && ((pr_opendoor() >= 203) ^ (good & 1));*/
        } else
            bInFloat = false;

        Vector3 newPos = pos;
        SetOrigin (oldPos, false);
        SetOrigin (newPos, true);

        return tryOK;
    }
}