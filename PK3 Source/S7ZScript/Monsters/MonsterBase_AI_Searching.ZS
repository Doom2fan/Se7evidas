/*
** zlib License
**
** (C) 2018      Sterling Parker (aka "Caligari87")
** (C) 2018-2019 Chronos Ouroboros (aka "phantombeta")
**
** This software is provided 'as-is', without any express or implied
** warranty.  In no event will the authors be held liable for any damages
** arising from the use of this software.
**
** Permission is granted to anyone to use this software for any purpose,
** including commercial applications, and to alter it and redistribute it
** freely, subject to the following restrictions:
**
** 1. The origin of this software must not be misrepresented; you must not
**    claim that you wrote the original software. If you use this software
**    in a product, an acknowledgment in the product documentation would be
**    appreciated but is not required.
** 2. Altered source versions must be plainly marked as such, and must not be
**    misrepresented as being the original software.
** 3. This notice may not be removed or altered from any source distribution.
*/

class S7_LastKnownPositionMarker : S7_PositionMarkerPersistent {
    default {
        +NOINTERACTION +NOBLOCKMAP +NOGRAVITY
    }

    states {
    Spawn:
        AMRK A 700 bright;
        stop;
    }
}

extend class S7_MonsterBase_TargettingSystem {
    int Countdown; // Countdown until the monster forgets its target.
    int NodeCountdown; // Countdown until the monster gives up on its current node and turns around.
    S7_MonsterTargetInfo LastTargetInfo; // The last info of the monster's target.
    S7_MonsterTargetInfo NextNode; // The next node to move to.

    void SearchBehavior_MakeNewNode (double lastAngle, bool nested = false) {
        let maxDist = 256.;
        let nextPos = Monster.Pos;
        FLineTraceData testNode;

        // Check random angle offsets for longest path
        double lastDist = -double.infinity;
        double nextAngle;
        for (let i = 0; i < 10; i++) {
            let testOffset = fRandom [monsterAI] (-45., 45.);

            let dist = maxDist;
            let curAngle = lastAngle + testOffset;
            let traceSuccess = Monster.LineTrace (
                curAngle,
                maxDist,
                0,
                TRF_ThruActors | TRF_ThruHitscan | TRF_BlockSelf,
                Monster.MaxStepHeight - .5,
                data: testNode
            );

            if (traceSuccess)
                dist = clamp (testNode.Distance - Monster.Radius, 0, maxDist);

            if (dist > lastDist) {
                nextPos = Monster.Level.Vec3Offset (Monster.Pos, (testNode.HitDir * dist));
                nextAngle = curAngle;

                lastDist = dist;
            }
        }

        if (lastDist ~== 0) {
            if (!nested)
                SearchBehavior_MakeNewNode (lastAngle - 180, true);
            else
                NextNode.Invalidate ();

            return;
        }

        // Spawn and set the node
        nextPos.Z = Monster.GetZAt (nextPos.X, nextPos.Y, flags: GZF_AbsolutePos);
        NextNode.FromPosVel (nextPos, (0, 0, 0), newAngle: nextAngle);
        NodeCountdown = random [monsterAI] (15 * TicRate, 20 * TicRate);

        if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
            Console.Printf ("%s %p picked a new pathnode", Monster.GetClassName (), Monster);
    }

    void SearchBehavior () {
        // Normal following behavior plus visibility checks.
        if (Monster.Target && !NextNode.IsValid) {
            // Clear ambush flag if needed.
            if (Monster.bAmbush && Monster.S7_CheckIfInLOS (Monster.Target)) {
                Monster.bAmbush = false;

                if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                    Console.Printf ("%s %p ambush flag cleared", Monster.GetClassName (), Monster);
            }

            let canSeeTarget = (
                Monster.S7_CanSeeEnemy (Monster.Target) && // Target is visible.
                (!Monster.Target.bShadow || random [monsterAI] (0, 35) == 0) && // Not shadow, OR could briefly see.
                Monster.CheckSight (Monster.Target) // Can actually see the enemy.
            );

            if (canSeeTarget)
                LastTargetInfo.FromActor (Monster.Target); // Store the position we last saw our target.
            else {
                // Forget the target and set a search node if they can't be seen, are out of LoS or shadow.
                let lastTargetPosValid = LastTargetInfo.IsValid;

                if (!Monster.bAmbush) {
                    Countdown = random [monsterAI] (30 * TicRate, int (2.5 * 60 * TicRate));

                    if (lastTargetPosValid) {
                        NextNode.Copy (LastTargetInfo);
                        NextNode.Angle = atan2 (NextNode.Position.Y, NextNode.Position.X);
                        NodeCountdown = random [monsterAI] (15 * TicRate, 40 * TicRate);
                    } else
                        SearchBehavior_MakeNewNode (Monster.Angle);

                    if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                        Console.Printf ("%s %p lost target!", Monster.GetClassName (), Monster);
                } else if (lastTargetPosValid)
                    ForgetTarget ();
            }
        } else if (Monster.Target && NextNode.IsValid) {
            if (Monster.S7_CheckIfInLOS (Monster.Target) && Monster.S7_CanSeeEnemy (Monster.Target)) {
                Countdown = -1;
                NodeCountdown = -1;
                NextNode.Invalidate ();
            }
        }

        if (!NextNode.IsValid && NodeCountdown >= 0)
            NodeCountdown = -1;

        // Spawn new path nodes as reached.
        if (Countdown > 0 && !NextNode.IsValid)
            SearchBehavior_MakeNewNode (Monster.Angle);

        // Give up the search when the countdown runs out.
        if (Countdown == 0) {
            ForgetTarget ();
            NodeCountdown = -1;

            if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                Console.Printf ("%s %p gave up the search", Monster.GetClassName (), Monster);
        }

        // Give up on the current node and turn around if we're taking waaay too long to reach it.
        if (NodeCountdown < 1 && NextNode.IsValid) {
            let newAngle = NextNode.Angle - 180.;
            SearchBehavior_MakeNewNode (newAngle);

            if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                Console.Printf ("%s %p couldn't reach a node", Monster.GetClassName (), Monster);
        }

        // Decrement timer.
        Countdown = max (Countdown - 1, -1);
        NodeCountdown = max (NodeCountdown - 1, -1);

        if ((S7_Debug_MonsterAI & S7_Dbg_MAI_Searching) && (Countdown % 175 == 1))
            Console.Printf ("%s %p searching for %f seconds", Monster.GetClassName (), Monster, Countdown / TicRate);
    }

    void ForgetTarget () {
        LastTargetInfo.Invalidate ();

        // Built-in target-clearing functions.
        Monster.A_ClearTarget ();
        Monster.A_ClearLastHeard ();

        // No idea if this does anything.
        Monster.CurSector.SoundTarget = null;

        // May as well do this.
        let level = Monster.Level;
        for (int i = 0; i < Level.Sectors.Size (); i++)
            level.Sectors [i].SoundTarget = null;
    }
}