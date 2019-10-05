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
        -NOBLOCKMAP -NOGRAVITY
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            Super.PostBeginPlay ();
            SetZ (floorZ);

            if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                sprite = GetSpriteIndex ('AMRK');
        }
        #### # 700 bright;
        stop;
    }
}

extend class S7_MonsterBase {
    int aiCountdown; // Countdown until the monster forgets its target.
    int aiNodeCountdown; // Countdown until the monster gives up on its current node and turns around.
    Vector3 aiLastTargetPos; // The last position on the monster's target.
    Actor aiNextNode; // The next node to move to.
    Actor aiLastKnown;

    void SearchBehavior_MakeNewNode (double lastAngle = double.NaN) {
        double lastDist, nextAngle;
        Vector3 nextNode = pos;
        FLineTraceData testNode;

        // If no last angle passed, base angle off last node or self
        if (!(lastAngle == lastAngle)) {
            if (aiLastKnown) {
                lastAngle = aiLastKnown.angle;
                aiLastKnown.Destroy ();
            } else
                lastAngle = angle;
        }

        // Check 5 random angle offsets for longest path
        for (int i = 0; i < 10; i++) {
            double testOffset = fRandom [monsterAI] (-45., 45.);

            LineTrace (lastAngle + testOffset, 256, 0, TRF_ThruActors | TRF_ThruHitscan, height / 2., data: testNode);

            if (testnode.Distance > lastDist) {
                nextNode = testNode.HitLocation;
                nextAngle = lastAngle + testOffset;
            }

            lastDist = testnode.Distance;
        }

        // Spawn and set the node
        aiLastKnown = Spawn ("S7_LastKnownPositionMarker", nextNode, ALLOW_REPLACE);
        aiLastKnown.angle = nextAngle;

        aiNextNode = aiLastKnown;

        aiNodeCountdown = random [monsterAI] (15 * TicRate, 20 * TicRate);

        if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
            Console.Printf ("%s %p picked a new pathnode", GetClassName (), self);
    }

    void SearchBehavior () {
        // Return conditions
        if (health <= 0 || bKilled)
            return;

        // Normal following behavior plus visibility checks
        if (target && !aiNextNode) {
            if (aiLastKnown)
                aiLastKnown.Destroy ();

            // Clear ambush flag if needed
            if (bAmbush && CheckIfTargetInLOS ()) {
                bAmbush = false;

                if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                    Console.Printf ("%s %p ambush flag cleared", GetClassName (), self);
            }

            // Store the position we last saw our target
            bool inLOS = CheckIfTargetInLOS ();
            if (inLOS)
                aiLastTargetPos = target.pos;

            // Forget player and set a search node if they can't be seen, are out of LoS or shadow
            if (!inLOS || !S7_CanSeeEnemy (target) || (target.bShadow && random [monsterAI] (0, 35) == 0)) {
                bool lastTargetPosValid = !(aiLastTargetPos != aiLastTargetPos);

                if (!bAmbush) {
                    aiCountdown = random [monsterAI] (30 * TicRate, int (2.5 * 60 * TicRate));

                    if (lastTargetPosValid) {
                        aiLastKnown = Spawn ("S7_LastKnownPositionMarker", aiLastTargetPos, ALLOW_REPLACE);
                        aiLastKnown.angle = angle;

                        aiNextNode = aiLastKnown;

                        aiNodeCountdown = random [monsterAI] (15 * TicRate, 40 * TicRate);
                    } else
                        SearchBehavior_MakeNewNode ();

                    if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                        Console.Printf ("%s %p lost target!", GetClassName (), self);
                } else if (lastTargetPosValid)
                    ForgetTarget (self);
            }
        } else if (aiNextNode && target) {
            if (CheckIfTargetInLOS () && S7_CanSeeEnemy (target)) {
                aiCountdown = -1;
                aiNodeCountdown = -1;

                if (aiNextNode)
                    aiNextNode.Destroy ();

                aiNextNode = null;
            }
        }

        if (!aiNextNode && aiNodeCountdown >= 0)
            aiNodeCountdown = -1;

        // Spawn new path nodes as reached
        if (aiCountdown > 0 && !aiNextNode)
            SearchBehavior_MakeNewNode ();

        // Give up the search when the countdown runs out
        if (aiCountdown == 0) {
            if (aiLastKnown)
                aiLastKnown.Destroy ();

            ForgetTarget (self);
            aiNodeCountdown = -1;

            if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                Console.Printf ("%s %p gave up the search", GetClassName (), self);
        }

        // Give up on the current node and turn around
        // if we're taking waaay too long to reach it.
        if (aiNodeCountdown == 0 && aiNextNode) {
            double newAngle = aiNextNode.angle - 180.;
            aiNextNode.Destroy ();
            SearchBehavior_MakeNewNode (newAngle);

            if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                Console.Printf ("%s %p couldn't reach a node", GetClassName (), self);
        }

        // Decrement timer
        aiCountdown = max (aiCountdown - 1, -1);
        aiNodeCountdown = max (aiNodeCountdown - 1, -1);

        if ((S7_Debug_MonsterAI & S7_Dbg_MAI_Searching) && (aiCountdown % 175 == 1))
            Console.Printf ("%s %p searching for %f seconds", GetClassName (), self, aiCountdown / TicRate);
    }

    void ForgetTarget (Actor which) {
        aiLastTargetPos = (double.NaN, double.NaN, double.NaN);

        // Built-in target-clearing functions
        which.A_ClearTarget ();
        which.A_ClearLastHeard ();

        // No idea if this does anything
        which.curSector.SoundTarget = null;

        // May as well go full-retard
        for (int i = 0; i < Level.Sectors.Size (); i++) {
            level.Sectors [i].SoundTarget = null;
        }
    }
}