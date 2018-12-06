/*
** zlib License
**
** (C) 2018 Sterling Parker (aka "Caligari87")
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
            SetOrigin ((pos.XY, floorZ), false);

            if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                sprite = GetSpriteIndex ('AMRK');
        }
        #### # 700 bright;
        stop;
    }
}

extend class S7_MonsterBase {
    int aiCountdown;
    Actor aiLastKnown;

    void SearchBehavior() {
        // Return conditions
        if (health <= 0 || bKilled)
            return;

        // Normal following behavior plus visibility checks
        if (target && target is "S7_BasePlayer") {
            if (aiLastKnown)
                aiLastKnown.Destroy ();

            // Clear ambush flag if needed
            if (CheckIfTargetInLOS () && bAmbush) {
                bAmbush = false;

                if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                    Console.Printf ("%s %p ambush flag cleared", GetClassName (), self);
            }

            // Forget player and set a search node if out of LoS, shadow, and not ambushing
            if (!CheckIfTargetInLOS () || (target.bShadow && random [monsterAI] (0, 35) == 0)) {
                if (!bAmbush) {
                    aiCountdown = random [monsterAI] (30 * 35, 60 * 35);

                    aiLastKnown = Spawn ("S7_LastKnownPositionMarker", target.pos, ALLOW_REPLACE);
                    aiLastKnown.angle = angle;

                    ForgetTarget (self);

                    goal = aiLastKnown;
                    target = aiLastKnown;

                    if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                        Console.Printf ("%s %p lost target!", GetClassName (), self);
                } else
                    ForgetTarget (self);
            }
        }

        // Spawn new path nodes as reached
        if (aiCountdown > 0 && !target) {
            double lastAngle, lastDist, nextAngle;
            Vector3 nextNode;
            FLineTraceData testNode;

            // Base angle off last node or self
            if (aiLastKnown) {
                lastAngle = aiLastKnown.angle;
                aiLastKnown.Destroy ();
            } else
                lastAngle = angle;

            // Check 5 random angle offsets for longest path
            for (int i = 0; i < 10; i++) {
                double testOffset = fRandom [monsterAI] (-90., 90.);

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

            goal = aiLastKnown;
            target = aiLastKnown;

            if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                Console.Printf ("%s %p picked a new pathnode", GetClassName (), self);
        }

        // Give up the search when the countdown runs out
        if (aiCountdown == 0) {
            if (aiLastKnown)
                aiLastKnown.Destroy ();

            if (S7_Debug_MonsterAI & S7_Dbg_MAI_Searching)
                Console.Printf ("%s %p gave up the search", GetClassName (), self);
        }

        // Decrement timer
        aiCountdown = max (aiCountdown - 1, -1);

        if ((S7_Debug_MonsterAI & S7_Dbg_MAI_Searching) && (aiCountdown % 175 == 1))
            Console.Printf ("%s %p searching for %f seconds", GetClassName (), self, aiCountdown / 35.);
    }

    void ForgetTarget (Actor which) {
        // Built-in target-clearing functions
        which.A_ClearTarget ();
        which.A_ClearSoundTarget ();
        which.A_ClearLastHeard ();

        // No idea if this does anything
        which.curSector.SoundTarget = null;

        // May as well go full-retard
        for (int i = 0; i < Level.Sectors.Size (); i++) {
            level.Sectors [i].SoundTarget = null;
        }

        // Reset to idle/spawn for HD monsters
        if (which.FindState ("Idle"))
            which.SetStateLabel ("Idle");
        else
            which.SetStateLabel ("Spawn");
    }
}