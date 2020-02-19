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
    const Team_None = 255;

    int S7_GetTeam () {
        if (player)
            return player.GetTeam ();

        int myTeam = DesignatedTeam;

        // Check for monsters that belong to a player on the team but aren't part of the team themselves.
        if (myTeam == Team_None && FriendPlayer != 0)
            myTeam = players [FriendPlayer - 1].GetTeam ();

        return myTeam;
    }

    double S7_GetTargetStealthFactor (Actor other) {
        let pPawn = S7_BasePlayer (other);

        if (pPawn)
            return pPawn.stealthFactor;

        return 0.;
    }

    bool S7_CanSeeEnemy (Actor other) {
        double dist = Distance2D (other);
        double stealthFactor = S7_GetTargetStealthFactor (other);
        double maxDist = max (maxStealthSightRange * (1. - stealthFactor), (radius * 2.) + other.radius);

        if (stealthFactor >= .6 && dist > maxDist)
            return false;

        if (bSeeInvisible)
            return true;

        if (other.bInvisible)
            return false;

        return true;
    }

    //-------------------------------------------------------------------------------------------
    //
    // LookForPlayers
    //
    //-------------------------------------------------------------------------------------------
    bool S7_LookForPlayers (int allAround, LookExParams params, bool fromChase = false) {
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
            if (FriendPlayer == 0 && (!teamplay || S7_GetTeam () == Team_None))
                return result;
            if (result || !deathmatch)
                return true;
        } // [SP] if false, and in deathmatch, intentional fall-through

        // Single player game and player is dead; look for monsters
        if (!(gameinfo.gametype & (GAME_DoomStrifeChex)) && !multiplayer && players [0].health <= 0 && !goal && gamestate != GS_TitleLevel)
            return LookForMonsters ();

        c = 0;
        if (TIDtoHate != 0)
            pnum = random [LookyLooky] (0, 255) & (MaxPlayers - 1);
        else
            pnum = LastLookPlayerNumber;

        while (true) {
            // [ED850] Each and every player should only ever be checked once.
            if (c++ < MaxPlayers) {
                pnum = (pnum + 1) & (MaxPlayers - 1);
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
                            lastenemy = null;
                            return true;
                        } else
                            lastenemy = null;
                    }
                }

                return target == goal && goal;
            }

            player = players [pnum];

            if (!player.mo.bShootable)
                continue;           // Not shootable (observer or dead)

            if (!(bFriendly ^ player.mo.bFriendly))
                continue;           // Same +MF_Friendly, ignore

            if (player.cheats & CF_NoTarget)
                continue;           // No target

            if (player.health <= 0)
                continue;           // Dead

            if (!IsVisible (player.mo, allAround, params))
                continue;           // Out of sight

            // [SP] Deathmatch fixes - if we have MF_Friendly we're definitely in deathmatch
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

                if (!S7_CanSeeEnemy (player.mo))
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
        bool targFromSound = false;

        if (bInConversation)
            return;

        // [RH] Set goal now if appropriate
        if (special == 229 && Args [0] == 0) { // 229 == Thing_SetGoal
            let iterator = Level.CreateActorIterator (Args [1], 'PatrolPoint');

            special = 0;
            goal = iterator.Next ();
            reactiontime = Args [2] * TicRate + level.maptime;

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
            targFromSound = true;

            // [RH] If the soundtarget is dead, don't chase it
            if (targ && targ.health <= 0) {
                targ = null;
                targFromSound = false;
            }

            if (targ && targ.player && ((targ.player.cheats & CF_NoTarget) || !targ.bFriendly))
                return;
        }

        // [RH] Andy Baker's stealth monsters
        if (bStealth)
            visdir = -1;

        if (targ && targ.bShootable) {
            if (IsFriend (targ)) { // Be a little more precise!
                // If we find a valid target here, the wandering logic should *not*
                // be activated! It would cause the seestate to be set twice.
                if (invoker.S7_LookForPlayers (bLookAllAround, null)) {
                    A_S7Look_SeeYou ();
                    return;
                }

                // Let the self wander around aimlessly looking for a fight
                if (SeeState)
                    SetState (SeeState);
                else
                    invoker.S7_DoWander ();
            } else if (targFromSound || invoker.S7_CanSeeEnemy (targ)) {
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

        if (!invoker.S7_LookForPlayers (bLookAllAround, null))
            return;

        // Go into chase state
        A_S7Look_SeeYou ();
    }

    action void A_S7Look_SeeYou () {
        // [RH] Don't start chasing after a goal if it isn't time yet.
        if (target == goal) {
            if (reactiontime > level.maptime)
                target = null;
        } else if (SeeSound)
            A_StartSound (SeeSound, slot: CHAN_Weapon, volume: 1., attenuation: bBoss ? ATTN_None : ATTN_Norm);

        if (target && SeeState)
            SetState (SeeState);
    }

    //-------------------------------------------------------------------------------------------
    //
    // A_LookEx
    //
    //-------------------------------------------------------------------------------------------
    action void A_S7LookEx (int flags = 0, double minSeeDist = 0, double maxSeeDist = 0, double maxHearDist = 0, double fov = 0, StateLabel seeStateLabel = null) {
        Actor targ = null;
        bool targFromSound = false;
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
            let iterator = Level.CreateActorIterator (Args [1], 'PatrolPoint');

            special = 0;
            goal = iterator.Next ();
            reactiontime = Args [2] * TicRate + level.maptime;

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
                targFromSound = true;

                if (targ) {
                    // [RH] If the soundtarget is dead, don't chase it
                    if (targ.health <= 0) {
                        targ = null;
                        targFromSound = false;
                    } else {
                        dist = Distance2D (targ);

                        // [KS] If the target is too far away, don't respond to the sound.
                        if (maxHearDist && dist > maxHearDist) {
                            targ = null;
                            LastHeard = null;
                            targFromSound = false;
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

        if (targ && targ.bShootable) {
            if (IsFriend (targ)) { // Be a little more precise!
                if (!bStandStill) {
                    if (!(flags & LOF_NoSightCheck)) {
                        // If we find a valid target here, the wandering logic should *not*
                        // be activated! If would cause the seestate to be set twice.
                        if (invoker.S7_LookForPlayers (true, params)) {
                            A_S7LookEx_SeeYou (flags, customSeeState);
                            return;
                        }
                    }

                    // Let the self wander around aimlessly looking for a fight
                    if (!bInChase) {
                        if (customSeeState)
                            SetState (customSeeState);
                        else if (SeeState)
                            SetState (SeeState);
                        else
                            invoker.S7_DoWander ();
                    }
                }
            } else if (targFromSound || invoker.S7_CanSeeEnemy (targ)) {
                target = targ; // We already have a target?

                // [KS] The target can become ourselves in rare circumstances (like
                // if we committed suicide), so if that's the case, just ignore it.
                if (target == self)
                    target = null;

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
            if (!invoker.S7_LookForPlayers (true, params))
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
                target = null;
        } else if (SeeSound && !(flags & LOF_NoSeeSound)) {
            if (flags & LOF_FullVolSeeSound) // Full volume
                A_StartSound (SeeSound, slot: CHAN_Weapon, volume: 1., attenuation: ATTN_None);
            else
                A_StartSound (SeeSound, slot: CHAN_Weapon, volume: 1., attenuation: ATTN_Norm);
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