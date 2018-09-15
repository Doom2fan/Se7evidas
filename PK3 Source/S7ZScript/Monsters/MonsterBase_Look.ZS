extend class S7_MonsterBase {
    const TEAM_NONE = 255;

    int S7_GetTeam () {
        if (player)
            return player.GetTeam ();

        int myTeam = DesignatedTeam;

        // Check for monsters that belong to a player on the team but aren't part of the team themselves.
        if (myTeam == TEAM_NONE && FriendPlayer != 0)
            myTeam = players [FriendPlayer - 1].GetTeam ();

        return myTeam;
    }

    bool S7_IsInvisible (Actor other) {
        if (bSeeInvisible)
            return true;

        return (other.bInvisible);
    }

    //-------------------------------------------------------------------------------------------
    //
    // LookForPlayers
    //
    //-------------------------------------------------------------------------------------------
    bool S7_LookForPlayers (int allAround, LookExParams params) {
        int        c;
        int        pnum;
        PlayerInfo player;
        bool chasegoal = params ? (!(params.flags & LOF_DontChaseGoal)) : true;

        if (TIDtoHate != 0) {
            if (LookForTID (allAround, params))
                return true;
            if (bHuntPlayers)
                return false;
        } else if (bFriendly) {
            bool result = LookForEnemies (allAround, params);

            // [SP] If you don't see any enemies in deathmatch, look for players (but only when friend to a specific player.)
            if (FriendPlayer == 0 && (!teamplay || S7_GetTeam () == TEAM_NONE))
                return result;
            if (result || !deathmatch)
                return true;
        } // [SP] if false, and in deathmatch, intentional fall-through

        // Single player game and player is dead; look for monsters
        if (!(gameinfo.gametype & (GAME_DoomStrifeChex)) && !multiplayer && players [0].health <= 0 && !goal && gamestate != GS_TITLELEVEL)
            return LookForMonsters ();

        c = 0;
        if (TIDtoHate != 0)
            pnum = random [LookyLooky] (0, 255) & (MAXPLAYERS - 1);
        else
            pnum = LastLookPlayerNumber;
            
        while (true) {
            // [ED850] Each and every player should only ever be checked once.
            if (c++ < MAXPLAYERS) {
                pnum = (pnum + 1) & (MAXPLAYERS - 1);
                if (!playeringame [pnum])
                    continue;

                if (TIDtoHate == 0)
                    LastLookPlayerNumber = pnum;
            } else {
                // Done looking
                if (!target) {
                    // [RH] Use goal as target
                    // [KS] ...unless we're ignoring goals and we don't already have one
                    if (goal && chasegoal) {
                        target = goal;
                        return true;
                    }

                    // Use last known enemy if no players sighted -- killough 2/15/98:
                    if (lastenemy && lastenemy.health > 0) {
                        if (!IsFriend (lastenemy)) {
                            target = lastenemy;
                            lastenemy = NULL;
                            return true;
                        } else
                            lastenemy = NULL;
                    }
                }

                return target == goal && goal;
            }

            player = players [pnum];

            if (!player.mo.bShootable)
                continue;           // not shootable (observer or dead)

            if (!(bFriendly ^ player.mo.bFriendly))
                continue;           // same +MF_FRIENDLY, ignore

            if (player.cheats & CF_NoTarget)
                continue;           // no target

            if (player.health <= 0)
                continue;           // dead

            if (!IsVisible (player.mo, allAround, params))
                continue;           // out of sight

            // [SP] Deathmatch fixes - if we have MF_FRIENDLY we're definitely in deathmatch
            // we're going to ignore our master, but go after his enemies.
            if (bFriendly) {
                if (IsFriend (player.mo))
                    continue;
            }

            // [RC] Well, let's let special monsters with this flag active be able to see
            // the player then, eh?
            if (!bSeeInvisible) {
                if (player.mo.bShadow || player.mo.bGhost) {
                    if (player.mo.Distance2D (self) > 128. && (player.mo.vel.X*player.mo.vel.X + player.mo.vel.Y*player.mo.vel.Y) < 5.*5.)
                        continue; // Player is sneaking - can't detect
                    if (random [LookForPlayers] (0, 255) < 225)
                        continue; // Player isn't sneaking, but still didn't detect
                }

                if (S7_IsInvisible (player.mo))
                    continue;
            }
            
            // [RH] Need to be sure the reactiontime is 0 if the monster is
            // leaving its goal to go after a player.
            if (goal && target == goal)
                reactiontime = 0;

            target = player.mo;

            return true;
        }

        return false;
    }

    //-------------------------------------------------------------------------------------------
    //
    // A_Look
    //
    //-------------------------------------------------------------------------------------------
    action void A_S7Look () {
        Actor targ;

        if (bInConversation)
            return;

        // [RH] Set goal now if appropriate
        if (special == 229 && Args [0] == 0) { // 229 == Thing_SetGoal
            let iterator = ActorIterator.Create (Args [1], "PatrolPoint");

            special = 0;
            goal = iterator.Next ();
            reactiontime = Args [2] * TICRATE + level.maptime;

            if (Args [3] == 0)
                bChaseGoal = false;
            else
                bChaseGoal = true;
        }

        threshold = 0; // Any shot will wake up

        if (TIDtoHate != 0)
            targ = target;
        else {
            targ = bNoSector ? CurSector.SoundTarget : LastHeard;

            // [RH] If the soundtarget is dead, don't chase it
            if (targ && targ.health <= 0)
                targ = NULL;

            if (targ && targ.player && ((targ.player.cheats & CF_NoTarget) || !targ.bFriendly))
                return;
        }

        // [RH] Andy Baker's stealth monsters
        if (bStealth)
            visdir = -1;

        if (targ && targ.bShootable && !invoker.S7_IsInvisible (targ)) {
            if (IsFriend (targ)) { // Be a little more precise!
                // If we find a valid target here, the wandering logic should *not*
                // be activated! It would cause the seestate to be set twice.
                if (invoker.S7_LookForPlayers (bLookAllAround, NULL) && !invoker.S7_IsInvisible (target)) {
                    A_S7Look_SeeYou ();
                    return;
                }

                // Let the self wander around aimlessly looking for a fight
                if (SeeState && !invoker.S7_IsInvisible (targ))
                    SetState (SeeState);
                else
                    A_Wander ();
            } else if (!invoker.S7_IsInvisible (targ)) {
                target = targ;

                if (bAmbush) {
                    if (CheckSight (target, SF_SeePastBlockEverything)) {
                        A_S7Look_SeeYou ();
                        return;
                    }
                } else {
                    A_S7Look_SeeYou ();
                    return;
                }
            }
        }
        
        if (!invoker.S7_LookForPlayers (bLookAllAround, NULL) || invoker.S7_IsInvisible (target))
            return;

        // Go into chase state
        A_S7Look_SeeYou ();
    }

    action void A_S7Look_SeeYou () {
        // [RH] Don't start chasing after a goal if it isn't time yet.
        if (target == goal) {
            if (reactiontime > level.maptime)
                target = NULL;
        } else if (SeeSound)
            A_PlaySound (SeeSound, CHAN_Weapon, volume: 1., attenuation: bBoss ? ATTN_NONE : ATTN_NORM);

        if (target && SeeState)
            SetState (SeeState);
    }

    //-------------------------------------------------------------------------------------------
    //
    // A_LookEx
    //
    //-------------------------------------------------------------------------------------------
    action void A_S7LookEx (int flags = 0, double minSeeDist = 0, double maxSeeDist = 0, double maxHearDist = 0, double fov = 0, StateLabel seeStateLabel = null) {
        Actor targ = NULL;
        double dist;
        State customSeeState = FindState (seeStateLabel);

        if (fov == 0)
            fov = 180.;

        LookExParams params;
        params.fov = fov;
        params.minDist = minSeeDist;
        params.maxDist = maxSeeDist;
        params.maxHearDist = maxHearDist;
        params.flags = flags;
        params.seeState = customSeeState;

        if (bInConversation)
            return;

        // [RH] Set goal now if appropriate
        if (special == 229 && Args [0] == 0) { // 229 == Thing_SetGoal
            let iterator = ActorIterator.Create (Args [1], "PatrolPoint");

            special = 0;
            goal = iterator.Next ();
            reactiontime = Args [2] * TICRATE + level.maptime;

            if (Args [3] == 0)
                bChaseGoal = false;
            else
                bChaseGoal = true;
        }

        threshold = 0; // Any shot will wake up

        if (TIDtoHate != 0)
            targ = target;
        else {
            if (!(flags & LOF_NoSoundCheck)) {
                targ = bNoSector ? CurSector.SoundTarget : LastHeard;

                if (targ) {
                    // [RH] If the soundtarget is dead, don't chase it
                    if (targ.health <= 0)
                        targ = NULL;
                    else {
                        dist = Distance2D (targ);

                        // [KS] If the target is too far away, don't respond to the sound.
                        if (maxHearDist && dist > maxHearDist) {
                            targ = NULL;
                            LastHeard = NULL;
                        }
                    }
                }
            }
            
            if (targ && targ.player && (targ.player.cheats & CF_NoTarget))
                return;
        }

        // [RH] Andy Baker's stealth monsters
        if (bStealth)
            visdir = -1;

        if (targ && targ.bShootable && !invoker.S7_IsInvisible (targ)) {
            if (IsFriend (targ)) { // Be a little more precise!
                if (!bStandStill) {
                    if (!(flags & LOF_NoSightCheck)) {
                        // If we find a valid target here, the wandering logic should *not*
                        // be activated! If would cause the seestate to be set twice.
                        if (invoker.S7_LookForPlayers (true, params) && !invoker.S7_IsInvisible (target)) {
                            A_S7LookEx_SeeYou (flags, customSeeState);
                            return;
                        }
                    }

                    // Let the self wander around aimlessly looking for a fight
                    if (!bInChase) {
                        if (customSeeState && !invoker.S7_IsInvisible (targ))
                            SetState (customSeeState);
                        else if (SeeState && !invoker.S7_IsInvisible (targ))
                            SetState (SeeState);
                        else
                            A_Wander ();
                    }
                }
            } else if (!invoker.S7_IsInvisible (targ)) {
                target = targ; // We already have a target?
                
                // [KS] The target can become ourselves in rare circumstances (like
                // if we committed suicide), so if that's the case, just ignore it.
                if (target == self)
                    target = NULL;

                if (target) {
                    if (bAmbush) {
                        dist = Distance2D (target);

                        if (CheckSight (target, SF_SeePastBlockEverything) &&
                            (!minSeeDist || dist > minSeeDist) &&
                            (!maxSeeDist || dist < maxSeeDist)
                        ) {
                            A_S7LookEx_SeeYou (flags, customSeeState);
                            return;
                        }
                    } else {
                        A_S7LookEx_SeeYou (flags, customSeeState);
                        return;
                    }
                }
            }
        }

        if (!(flags & LOF_NoSightCheck)) {
            if (!invoker.S7_LookForPlayers (true, params) || invoker.S7_IsInvisible (target))
                return;
        } else
            return;
                    
        // Go into chase state
        A_S7LookEx_SeeYou (flags, customSeeState);
    }

    action void A_S7LookEx_SeeYou (int flags, State customSeeState) {
        // [RH] Don't start chasing after a goal if it isn't time yet.
        if (target == goal) {
            if (reactiontime > level.maptime)
                target = NULL;
        } else if (SeeSound && !(flags & LOF_NoSeeSound)) {
            if (flags & LOF_FullVolSeeSound) // Full volume
                A_PlaySound (SeeSound, CHAN_Weapon, volume: 1., attenuation: ATTN_NONE);
            else
                A_PlaySound (SeeSound, CHAN_Weapon, volume: 1., attenuation: ATTN_NORM);
        }

        if (target && !bInChase) {
            if (!(flags & LOF_NoJump)) {
                if (customSeeState)
                    SetState (customSeeState);
                else
                    SetState (SeeState);
            }
        }
    }
}