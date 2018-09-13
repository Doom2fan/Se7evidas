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

//-------------------------------------------------------------------------------------------
//
// Monster bases
//
//-------------------------------------------------------------------------------------------
class S7_MonsterBase : Actor {
    default {
        Health 60;
        Radius 20;
        Height 56;
        Mass 100;
        Speed 8;

        /** Damage factors **/
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.5;
        DamageFactor "LaserTracer", 1.25;

        Monster;

        +FLOORCLIP +DONTHARMCLASS
    }

    int monsDeathType;
    Actor grabbedShooter;

    override void Die (Actor source, Actor inflictor, int dmgflags) {
        Super.Die (source, inflictor, dmgflags);

        if (source is "S7_PlayerSummon") {
            if (source.master && source.master.player && multiplayer)
                source.player.killcount++;
        }

        OnDeath (source, inflictor, dmgflags);
    }
    virtual void OnDeath (Actor source, Actor inflictor, int dmgflags) { }

    S7_XPSystem GetXPSystem () {
        return S7_XPSystem (FindInventory ("S7_XPSystem", true));
    }

    void GiveXP (Actor act, int amount) {
        if (!act || amount <= 0)
            return;

        S7_XPSystem xpSys = S7_XPSystem (act.FindInventory ("S7_XPSystem", true));

        if (!xpSys && act is "S7_PlayerSummon" && act.master)
            xpSys = S7_XPSystem (act.master.FindInventory ("S7_XPSystem", true));

        if (!xpSys)
            return;

        xpSys.GiveXP (amount);
    }

    void GiveCash (Actor act, int amount, class<Inventory> cashItem = 'S7_Cash') {
        if (!act || amount <= 0)
            return;

        if (act is "S7_PlayerSummon") {
            if (!act.master)
                return;

            act = act.master;
        }

        act.GiveInventory (cashItem, amount);
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

        if (targ && targ.bShootable && !targ.bInvisible) {
            if (IsFriend (targ)) { // Be a little more precise!
                // If we find a valid target here, the wandering logic should *not*
                // be activated! It would cause the seestate to be set twice.
                if (LookForPlayers (bLookAllAround, NULL) && !target.bInvisible) {
                    A_S7Look_SeeYou ();
                    return;
                }

                // Let the self wander around aimlessly looking for a fight
                if (SeeState && !targ.bInvisible)
                    SetState (SeeState);
                else
                    A_Wander ();
            } else if (!targ.bInvisible) {
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
        
        if (!LookForPlayers (bLookAllAround, NULL) || target.bInvisible)
            return;

        // Go into chase state
        A_S7Look_SeeYou ();
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

        if (targ && targ.bShootable && !targ.bInvisible) {
            if (IsFriend (targ)) { // Be a little more precise!
                if (!bStandStill) {
                    if (!(flags & LOF_NoSightCheck)) {
                        // If we find a valid target here, the wandering logic should *not*
                        // be activated! If would cause the seestate to be set twice.
                        if (LookForPlayers (true, params) && !target.bInvisible) {
                            A_S7LookEx_SeeYou (flags, customSeeState);
                            return;
                        }
                    }

                    // Let the self wander around aimlessly looking for a fight
                    if (!bInChase) {
                        if (customSeeState && !targ.bInvisible)
                            SetState (customSeeState);
                        else if (SeeState && !targ.bInvisible)
                            SetState (SeeState);
                        else
                            A_Wander ();
                    }
                }
            } else if (!targ.bInvisible) {
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
            if (!LookForPlayers (true, params) || target.bInvisible)
                return;
        } else
            return;
                    
        // Go into chase state
        A_S7LookEx_SeeYou (flags, customSeeState);
    }
}

class S7_DemonBase : S7_MonsterBase {
    default {
        // Demon flesh damage reduction
        DamageFactor "PistolTracer", 0.7;
        DamageFactor "RevolverTracer", 0.8;
        DamageFactor "ShotgunTracer", 0.86;
        DamageFactor "RifleTracer", 0.9;
    }
}

class S7_HellNobleBase : S7_DemonBase {
    default {
        Health 1000;
        Radius 24;
        Height 64;
        Mass 1000;
        PainChance 50;

        /** Damage factors **/
        // Demon flesh damage reduction
        DamageFactor "PistolTracer", 0.7;
        DamageFactor "RevolverTracer", 0.8;
        DamageFactor "RifleTracer", 0.9;
        // Hell Noble buckshot damage bonus
        DamageFactor "ShotgunTracer", 1.2;
    }
}

class S7_SuccubusBase : S7_DemonBase {
    default {
        Health 400;
        Radius 18;
        Height 50;
        Mass 200;
        PainChance 90;

        /** Damage factors **/
        // Demon flesh damage reduction
        // Succubi get lower reduction because they're mostly human
        DamageFactor "PistolTracer", 0.75;
        DamageFactor "RevolverTracer", 0.85;
        DamageFactor "ShotgunTracer", 0.91;
        DamageFactor "RifleTracer", 0.95;
    }
}

class S7_ScorpBase : S7_MonsterBase {
    default {
        Radius 16;
        Height 56;
        ActiveSound "Monsters/Nova/RadioChatter";

        /** Damage factors **/
        // Reanimated flesh damage reduction
        DamageFactor "PistolTracer", 0.75;
        DamageFactor "RevolverTracer", 0.85;
        DamageFactor "ShotgunTracer", 0.91;
        DamageFactor "RifleTracer", 0.95;
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.6;
        DamageFactor "LaserTracer", 1.35;
    }

    action void S7_DoScorpsChase () {
        bool canPlayActive = (
            CheckSight (target, SF_SeePastBlockEverything | SF_SeePastShootableLines) &&
            (random [monsterSpc] (0, 255) < 96)
        );

        A_Chase ("Melee", "Missile", flags: !canPlayActive ? CHF_NOPLAYACTIVE : 0);
    }

    // Default variables
    int fireMode, ammo;
    double turn, spreadX, spreadY;
}