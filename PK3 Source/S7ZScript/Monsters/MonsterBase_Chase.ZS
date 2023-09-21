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
    enum AI_State {
        AIS_Chase,
        AIS_Wander,
        AIS_MissileAttack,
    }

    enum S7_ChaseFlags {
        S7CHF_DontMove,
        S7CHF_NightmareFast,
        S7CHF_NoDirectionTurn,
        S7CHF_NoPlayActive,
        S7CHF_NoRandomTurn,
        S7CHF_Resurrect,
        S7CHF_StopIfBlocked,
    }

    const S7_Class_Boss_Strafe_Range = 64 * 10;

    // The maximum range at which a monster will attack a stealthy player.
    double MaxStealthAttackRange;
    property MaxStealthAttackRange: MaxStealthAttackRange;
    double MaxStealthSightRange;
    property MaxStealthSightRange: MaxStealthSightRange;

    AI_State aiState;
    State aiChaseFuncState;

    default {
        S7_MonsterBase.MaxStealthSightRange 384.;
        S7_MonsterBase.MaxStealthAttackRange 256.;
    }

    private void InitializeChase () {
        aiState = AIS_Chase;
        aiChaseFuncState = null;

        if (!targetSystem)
            targetSystem = new ('S7_MonsterBase_TargettingSystem');
        targetSystem.Monster = self;
        targetSystem.Initialize ();
    }

    bool CheckReachedGoal (out S7_MonsterTargetInfo targetInfo) {
        if (!targetInfo.IsValid || (CurSector.Flags & Sector.SECF_NoAttack))
            return false;

        let diff = level.Vec2Diff (Pos.XY, targetInfo.Position.XY);
        return diff dot diff < (MeleeRange + Radius + targetInfo.Radius) ** 2;
    }

    //-------------------------------------------------------------------------------------------
    //
    // A_Wander
    //
    //-------------------------------------------------------------------------------------------
    void S7_DoWander (int flags = 0) {
        // [RH] Strife probably clears this flag somewhere, but I couldn't find where.
        // This seems as good a place as any.
        bInCombat = false;

        if (bInConversation)
            return;

        if (bStandStill)
            return;

        if (reactiontime > 0) {
            reactiontime--;
            return;
        }

        aiState = AIS_Wander;

        if (moveStandStillCount > 0)
            moveStandStillCount--;

        if (moveCount > 0)
            moveCount--;

        if (flags & S7CHF_DontMove)
            S7_SetStandStillCount ();

        if (S7_CanFly () || (Pos.Z <= floorZ || Pos.Z ~== floorZ || Vel.Z <= S7_Math.VM_Epsilon))
            S7_DoSteering ();
    }

    action void S7_Wander (int flags = 0) {
        invoker.S7_DoWander (flags);
    }

    //-------------------------------------------------------------------------------------------
    //
    // Missile checking
    //
    //-------------------------------------------------------------------------------------------

    virtual bool S7_Chase_CanMissileTarget () { return true; }
    virtual bool S7_Chase_CanMeleeTarget () { return true; }

    bool S7_CanAttackStealthEnemy (Actor other, double distSqr) {
        let stealthFactor = S7_GetTargetStealthFactor (other);
        let maxDist = max (MaxStealthAttackRange * (1. - stealthFactor), (radius * 2.) + other.radius);

        return !(stealthFactor >= .6 && distSqr > maxDist * maxDist);
    }

    bool S7_CheckMissileRange (bool noRandom) {
        if (CurSector.flags & Sector.SECF_NoAttack)
            return false;

        if (!S7_CheckIfInLOS (Target, sightFlags: SF_SeePastBlockEverything))
            return false;

        if (bJustHit) {
            // The target just hit the enemy, so fight back!
            bJustHit = false;

            // killough 7/18/98: no friendly fire at corpses
            // killough 11/98: prevent too much infighting among friends
            if (!bFriendly) return true;
            if (Target.Health <= 0) return false;
            if (!IsFriend (Target)) return true;

            return (Target.Player != null || !Target.bJustHit) && (noRandom || random [Defect] () > 128);
        }

        // Do not attack yet
        if (ReactionTime)
            return false;

        // killough 7/18/98: friendly monsters don't attack other friendly
        // monsters or players (except when attacked, and then only once)
        if (IsFriend (Target))
            return false;

        if (bFriendly && HitFriend ())
            return false;

        if (!S7_Chase_CanMissileTarget ())
            return false;

        let dist = Distance2DSquared (Target);
        if (!S7_CanAttackStealthEnemy (Target, dist))
            return false;

        dist = sqrt (dist);
        dist -= 64;

        // No melee attack, so fire more
        if (MeleeState == null)
            dist -= 128;

        return S7_SuggestMissileAttack (dist, noRandom);
    }

    bool S7_SuggestMissileAttack (double dist, bool noRandom) {
        // The Arch Vile's special behavior turned into a property
        if (MaxTargetRange > S7_Math.VM_Epsilon && dist > MaxTargetRange)
            return false;

        // From the Revenant: close enough for fist attack
        if (MeleeState != null && dist < MeleeThreshold)
            return false;

        if (bMissileMore)
            dist *= 0.5;
        if (bMissileEvenMore)
            dist *= 0.125;

        let mmc = int (MinMissileChance * G_SkillPropertyFloat (SKILLP_Aggressiveness));
        return noRandom || (random [CheckMissileRange] () >= min (int (dist), mmc));
    }

    //-------------------------------------------------------------------------------------------
    //
    // DoChase / A_DoChase
    //
    //-------------------------------------------------------------------------------------------
    // This might seem silly to make into a function, but it's used in several places. Better make it a function and
    // waste a few cycles than risk not updating a line when changed. And it wouldn't even matter if we had inlining.
    void S7_SetMoveCount () {
        int mask = (aiState == AIS_Wander) ? 7 : 15;
        moveCount = random [S7_Chase] (0, 255) & mask;
    }

    void S7_SetStandStillCount () {
        moveCount = 0;
        moveStandStillCount = random [S7_Chase] (0, 255) % 6;
    }

    void S7_DoChase (State meleestate, State missilestate, bool playActive, bool nightmareFast, int flags) {
        /*
        ** Quirks: Doesn't support the NightmareFast Gameinfo flag.
        */
        aiChaseFuncState = CurState;

        if (bInConversation || bInChase)
            return;

        if (flags & S7CHF_DontMove)
            S7_SetStandStillCount ();

        bInChase = true;
        if (aiState == AIS_Wander)
            aiState = AIS_Chase;

        // [RH] Andy Baker's stealth monsters
        if (bStealth)
            visdir = -1;

        if (reactiontime > 0)
            reactiontime--;

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
        /*if (strafecount)
            A_FaceTarget ();*/

        // [RH] If the target is dead or a friend (and not a goal), stop chasing it.
        if (target && target != goal && (target.health <= 0 || IsFriend (target)))
            target = null;

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
                    i = random [S7_NewChaseDir] (0, 255) & (MaxPlayers - 1);
                    while (!playeringame [i]) {
                        i = (i + 1) & (MaxPlayers - 1);
                    }
                }

                player = players [i];
            }

            if (player.attacker && player.attacker.health > 0 && player.attacker.bShootable && random [S7_NewChaseDir] (0, 255) < 80) {
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
            if (S7_LookForPlayers (true, null, fromChase: true) && target != goal) {
                bInChase = false;
                aiState = AIS_Chase;
                return;
            }

            if (!target && !targetSystem.NextNode.IsValid) {
                if (bFriendly) {
                    //A_Look(actor);
                    if (!target) {
                        if (moveStandStillCount < 1)
                            S7_DoWander ();
                        else
                            aiState = AIS_Chase;

                        bInChase = false;
                        return;
                    }
                } else {
                    SetIdle ();
                    bInChase = false;
                    aiState = AIS_Chase;
                    return;
                }
            }
        }

        // Do not attack twice in a row
        if (bJustAttacked) {
            bJustAttacked = false;

            if (!S7_ActorExtensions.IsFast (self) && moveCount < 1)
                S7_SetMoveCount ();

            bInChase = false;
            aiState = AIS_Chase;
            return;
        }

        if (aiState == AIS_Chase && S7_DoChase_Chase (playActive, flags))
            return;

        bool mayAttack = target != null;
        if (aiState != AIS_MissileAttack) {
            bool isFrightened = false;
            if (target) {
                isFrightened = (
                    (target.player && (target.player.cheats & CF_Frightening)) ||
                    target.bFrightening ||
                    bFrightened
                );
            }

            mayAttack = (!isFrightened || random [Anubis] (0, 255) < 43);
        }

        // [RH] Scared monsters attack less frequently
        if (mayAttack) {
            // Check for melee attack
            if (meleestate && CheckMeleeRange () && S7_Chase_CanMeleeTarget ()) {
                if (AttackSound)
                    A_StartSound (AttackSound, slot: CHAN_Weapon);

                SetState (meleestate);
                bInChase = false;
                aiState = AIS_Chase;

                return;
            }

            // Check for missile attack
            if (missilestate && S7_CheckMissileRange (aiState == AIS_MissileAttack)) {
                if (aiState != AIS_MissileAttack) {
                    if (moveCount < 1 || S7_ActorExtensions.IsFast (self))
                        aiState = AIS_MissileAttack;
                } else if (vel.XY ~== (0, 0)) {
                    SetState (missilestate);

                    bJustAttacked = true;
                    bInCombat = true;
                    bInChase = false;
                    aiState = AIS_Chase;

                    return;
                }
            } else if (aiState == AIS_MissileAttack)
                aiState = AIS_Chase;
        }

        S7_DoChaseEnd (playActive, flags);
    }

    bool S7_DoChase_Chase (bool playActive, int flags) {
        // [RH] Don't attack if just moving toward goal
        if (Goal && (Target == Goal || bChaseGoal)) {
            S7_MonsterTargetInfo goalInfo;
            goalInfo.FromActor (Goal);

            if (CheckReachedGoal (goalInfo)) {
                // Reached the goal
                let iterator = Level.CreateActorIterator (Goal.args [0], 'PatrolPoint');
                let specit = Level.CreateActorIterator (Goal.tid, 'PatrolSpecial');
                Actor spec;

                // Execute the specials of any PatrolSpecials with the same TID as the goal.
                for (Actor spec; spec = specit.Next ();) {
                    level.ExecuteSpecial (
                        spec.Special, self, null, false,
                        spec.Args [0], spec.Args [1], spec.Args [2], spec.Args [3], spec.Args [4]
                    );
                }

                let lastGoalAng = Goal.Angle;
                int delay;
                let newGoal = iterator.Next ();

                if (newGoal && Goal == Target) {
                    delay = newGoal.Args [1];
                    reactiontime = delay * TicRate + level.MapTime;
                } else {
                    delay = 0;
                    reactiontime = default.Reactiontime;
                    angle = lastGoalAng; // Look in direction of last goal
                }

                if (Target == Goal)
                    Target = null;
                bJustAttacked = true;

                if (newGoal && delay != 0) {
                    bInCombat = true;
                    SetIdle ();
                }

                bInChase = false;
                Goal = newGoal;

                return true;
            }

            if (Goal == Target) {
                S7_DoChaseEnd (playActive, flags);
                return true;
            }
        } else if (targetSystem.NextNode.IsValid && CheckReachedGoal (targetSystem.NextNode)) {
            if (targetSystem.Countdown > 0)
                targetSystem.SearchBehavior_MakeNewNode (targetSystem.NextNode.Angle);

            bJustAttacked = true;
            bInChase = false;

            return true;
        }

        return false;
    }

    void S7_DoChaseEnd (bool playActive, int flags) {
        // Possibly choose another target
        if ((multiplayer || TIDtoHate) && !threshold && !S7_CheckIfInLOS (target)) {
            bool lookForBetter = false;
            bool gotNew;

            if (bNoSightCheck) {
                bNoSightCheck = false;
                lookForBetter = true;
            }

            Actor oldTarget = target;
            gotNew = S7_LookForPlayers (true, null, fromChase: true);

            if (lookForBetter)
                bNoSightCheck = true;

            // Got a new target
            if (gotNew && target != oldTarget) {
                aiState = AIS_Chase;

                bInChase = false;
                return;
            }
        }

        if (aiState == AIS_Chase) {
            if (strafecount > 0)
                strafecount--;

            if (moveStandStillCount-- > 0)
                moveStandStillCount--;

            moveCount--;
            //Console.Printf ("%d", moveCount);
        }

        if (S7_CanFly () || (Pos.Z <= floorZ || Pos.Z ~== floorZ || Vel.Z <= S7_Math.VM_Epsilon))
            S7_DoSteering ();

        if (aiState == AIS_Chase) {
            // Make active sound
            if (playActive && random [Chase] (0, 255) < 3)
                PlayActiveSound ();
        }

        bInChase = false;
    }

    //-------------------------------------------------------------------------------------------
    //
    // A_Chase
    //
    //-------------------------------------------------------------------------------------------
    action void A_S7ChaseDef () {
        invoker.S7_DoChase (MeleeState, MissileState, true, false /*gameinfo.nightmarefast*/, 0);
    }

    action void A_S7Chase (StateLabel melee = null, StateLabel missile = null, int flags = 0) {
        // Add support for S7CHF_Resurrect
        /*if ((flags & S7CHF_Resurrect) && P_CheckForResurrection (self, false))
            return;*/

        invoker.S7_DoChase (ResolveState (melee), ResolveState (missile), !(flags & S7CHF_NoPlayActive),
            (flags & S7CHF_NightmareFast), flags
        );
    }
}