/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

extend class S7_MonsterBase {
    //-------------------------------------------------------------------------------------------
    //
    // DoChase / A_DoChase
    //
    //-------------------------------------------------------------------------------------------
    const S7_CLASS_BOSS_STRAFE_RANGE = 64*10;
    void S7_DoChase (bool fastChase, State meleestate, State missilestate, bool playActive, bool nightmareFast, bool dontMove, int flags) {
        /*
        ** Quirks: Doesn't support the NightmareFast Gameinfo flag.
        */
        if (bInConversation)
            return;

        if (bInChase)
            return;
        bInChase = true;

        // [RH] Andy Baker's stealth monsters
        if (bStealth)
            visdir = -1;

        if (reactiontime)
            reactiontime--;

        // [RH] Don't chase invisible targets
        if (target && target.bInvisible && target != goal)
            target = NULL;

        // Modify target threshold
        if (threshold) {
            if (!target || target.health <= 0)
                threshold = 0;
            else
                threshold--;
        }

        // Monsters move faster in nightmare mode
        if (nightmareFast && G_SkillPropertyInt (SKILLP_FastMonsters)) {
            if (tics > 3) {
                tics -= tics / 2;
                if (tics < 3)
                    tics = 3;
            }
        }

        // Turn towards movement direction if not there yet
        if (strafecount)
            A_FaceTarget ();
        else if (!(flags & CHF_NoDirectionTurn) && movedir < 8) {
            angle = floor (angle / 45) * 45.;

            double delta = deltaangle (angle, (movedir * 45));

            if (delta < 0)
                angle -= 45;
            else if (delta > 0)
                angle += 45;
        }

        // [RH] If the target is dead or a friend (and not a goal), stop chasing it.
        if (target && target != goal && (target.health <= 0 || IsFriend (target)))
            target = NULL;

        // [RH] Friendly monsters will consider chasing whoever hurts a player if they
        // don't already have a target.
        if (bFriendly && !target) {
            PlayerInfo player;

            if (FriendPlayer != 0)
                player = players [FriendPlayer - 1];
            else {
                int i;

                if (!multiplayer)
                    i = 0;
                else {
                    // for (i = pr_newchasedir() & (MAXPLAYERS-1); !playeringame[i]; i = (i+1) & (MAXPLAYERS-1))
                    i = random [NewChaseDir] (0, 255) & (MAXPLAYERS - 1);
                    while (!playeringame [i]) {
                        i = (i + 1) & (MAXPLAYERS - 1);
                    }
                }

                player = players [i];
            }

            if (player.attacker && player.attacker.health > 0 && player.attacker.bShootable && random [NewChaseDir] (0, 255) < 80) {
                if (!player.attacker.bFriendly || (deathmatch && FriendPlayer != 0 && player.attacker.FriendPlayer != 0 && FriendPlayer != player.attacker.FriendPlayer))
                    target = player.attacker;
            }
        }

        // Look for a new target
        if (!target || !target.bShootable) {
            if (target && target.bNonShootable) {
                // Target is only temporarily unshootable, so remember it.
                lastenemy = target;
                // Switch targets faster, since we're only changing because we can't
                // hurt our old one temporarily.
                threshold = 0;
            }

            // Got a new target
            if (S7_LookForPlayers (true, NULL) && target != goal) {
                bInChase = false;
                return;
            }

            if (!target) {
                if (bFriendly) {
                    //A_Look(actor);
                    if (!target) {
                        if (!dontMove)
                            A_Wander ();

                        bInChase = false;
                        return;
                    }
                } else {
                    SetIdle ();
                    bInChase = false;
                    return;
                }
            }
        }
        
        // do not attack twice in a row
        if (bJustAttacked) {
            bJustAttacked = false;

            if (!S7_ActorExtensions.IsFast (self) && !dontMove && !(flags & CHF_NoPostAttackTurn) && !(flags & CHF_StopIfBlocked))
                NewChaseDir ();

            // Because P_TryWalk would never be reached if the actor is stopped by a blocking object,
            // need to make sure the movecount is reset, otherwise they will just keep attacking
            // over and over again.
            if (flags & CHF_StopIfBlocked)
                movecount = random [TryWalk] (0, 255) & 15;

            bInChase = false;
            return;
        }
        
        // [RH] Don't attack if just moving toward goal
        if (target == goal || (bChaseGoal && goal)) {
            Actor savedTarget = target;
            target = goal;
            bool result = CheckMeleeRange ();
            target = savedTarget;

            if (result) {
                // Reached the goal
                ActorIterator iterator = ActorIterator.Create (goal.args [0], "PatrolPoint");
                ActorIterator specit = ActorIterator.Create (goal.tid, "PatrolSpecial");
                Actor spec;

                // Execute the specials of any PatrolSpecials with the same TID
                // as the goal.
                while (spec = specit.Next ()) {
                    level.ExecuteSpecial (
                        spec.special, self, NULL, false,
                        spec.args [0], spec.args [1], spec.args [2], spec.args [3], spec.args [4]
                    );
                }

                double lastGoalAng = goal.angle;
                int delay;
                Actor newGoal = iterator.Next ();

                if (newGoal && goal == target) {
                    delay = newGoal.args[1];
                    reactiontime = delay * TICRATE + level.maptime;
                } else {
                    delay = 0;
                    reactiontime = default.reactiontime;
                    angle = lastGoalAng; // Look in direction of last goal
                }

                if (target == goal)
                    target = NULL;
                bJustAttacked = true;

                if (newGoal && delay != 0) {
                    bInCombat = true;
                    SetIdle ();
                }

                bInChase = false;
                goal = newGoal;
                return;
            }
            if (goal == target) {
                S7_DoChaseEnd (fastChase, meleestate, missilestate, playActive, nightmareFast, dontMove, flags);
                return;
            }
        }

        // Strafe   (Hexen's class bosses)
        // This was the sole reason for the separate A_FastChase function but
        // it can be just as easily handled by a simple flag so the monsters
        // can take advantage of all the other enhancements of A_Chase.

        if (fastChase && !dontMove) {
            if (FastChaseStrafeCount > 0)
                FastChaseStrafeCount--;
            else {
                FastChaseStrafeCount = 0;
                vel.X = vel.Y = 0;

                double dist = Distance2D (target);
                if (dist < S7_CLASS_BOSS_STRAFE_RANGE) {
                    if (random [Chase] (0, 255) < 100) {
                        double ang = AngleTo (target);

                        ang += ((random [Chase] (0, 255) < 128) ? 90 : -90);

                        VelFromAngle (13., ang);
                        FastChaseStrafeCount = 3; // Strafe time
                    }
                }
            }

        }

        // [RH] Scared monsters attack less frequently
        if (((target.player == NULL ||
            !((target.player.cheats & CF_Frightening) || target.bFrightening)) &&
            !bFrightened) ||
            random [Anubis] (0, 255) < 43
        ) {
            // Check for melee attack
            if (meleestate && CheckMeleeRange ()) {
                if (AttackSound)
                    A_PlaySound (AttackSound, CHAN_Weapon, volume: 1., attenuation: ATTN_NORM);

                SetState (meleestate);
                bInChase = false;

                return;
            }
            
            // Check for missile attack
            if (missilestate) {
                if (!S7_ActorExtensions.IsFast (self) && movecount) {
                    S7_DoChaseEnd (fastChase, meleestate, missilestate, playActive, nightmareFast, dontMove, flags);
                    return;
                }
                
                if (!CheckMissileRange ()) {
                    S7_DoChaseEnd (fastChase, meleestate, missilestate, playActive, nightmareFast, dontMove, flags);
                    return;
                }
                
                SetState (missilestate);

                bJustAttacked = true;
                bInCombat = true;
                bInChase = false;

                return;
            }
        }

        S7_DoChaseEnd (fastChase, meleestate, missilestate, playActive, nightmareFast, dontMove, flags);
    }

    void S7_DoChaseEnd (bool fastChase, State meleestate, State missilestate, bool playActive, bool nightmareFast, bool dontMove, int flags) {
        // Possibly choose another target
        if ((multiplayer || TIDtoHate) && !threshold && !CheckSight (target)) {
            bool lookForBetter = false;
            bool gotNew;

            if (bNoSightCheck) {
                bNoSightCheck = false;
                lookForBetter = true;
            }

            Actor oldTarget = target;
            gotNew = S7_LookForPlayers (true, NULL);

            if (lookForBetter)
                bNoSightCheck = true;

            // Got a new target
            if (gotNew && target != oldTarget) {
                bInChase = false;
                return;
            }
        }

        //
        // Chase towards player
        //

        if (strafecount)
            strafecount--;
        
        // Class bosses don't do this when strafing
        if ((!fastChase || !FastChaseStrafeCount) && !dontMove) {
            // CANTLEAVEFLOORPIC handling was completely missing in the non-serpent functions.
            Vector2 old = pos.XY;
            //int oldgroup = PrevPortalGroup;
            TextureID oldFloor = floorpic;

            // chase towards player
            if ((--movecount < 0 && !(flags & CHF_NoRandomTurn)) || (!MonsterMove () && !(flags & CHF_StopIfBlocked)))
                NewChaseDir ();

            // If the move was illegal, reset it 
            // (copied from A_SerpentChase - it applies to everything with CANTLEAVEFLOORPIC!)
            if (bCantLeaveFloorPic && floorpic != oldFloor) {
                if (TryMove (old, false)) {
                    if (nomonsterinterpolation) {
                        Prev.X = old.X;
                        Prev.Y = old.Y;
                        //PrevPortalGroup = oldgroup;
                    }
                }

                if (!(flags & CHF_StopIfBlocked))
                    NewChaseDir ();
            }
        }
        else if (dontMove && movecount > 0)
            movecount--;
        
        // make active sound
        if (playActive && random [Chase] (0, 255) < 3)
            PlayActiveSound ();

        bInChase = false;
    }

    //-------------------------------------------------------------------------------------------
    //
    // A_Chase
    //
    //-------------------------------------------------------------------------------------------
    action void A_S7ChaseDef () {
        invoker.S7_DoChase (false, MeleeState, MissileState, true, false /*gameinfo.nightmarefast*/, false, 0);
    }

    action void A_S7Chase (StateLabel melee = null, StateLabel missile = null, int flags = 0) {
        // Add support for CHF_Resurrect
        /*if ((flags & CHF_Resurrect) && P_CheckForResurrection (self, false))
            return;*/

        invoker.S7_DoChase ((flags & CHF_FastChase), ResolveState (melee), ResolveState (missile), !(flags & CHF_NoPlayActive),
            (flags & CHF_NightmareFast), (flags & CHF_DontMove), flags
        );
    }
}