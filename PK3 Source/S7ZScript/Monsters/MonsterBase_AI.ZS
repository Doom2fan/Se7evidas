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

    override void PostBeginPlay () {
        Super.PostBeginPlay ();
        SetOrigin ((pos.XY, floorZ), false);
    }
}

extend class S7_MonsterBase {
    int aiMode;
    Vector3 aiPathPos, aiPathHeading;
    Array<Actor> aiLastKnown;
    int aiCountdown;

    enum AI_Modes {
        AI_Normal,
        AI_Chasing,
        AI_Searching,
    };
    
    void ClearPath () {
        for (int i = aiLastKnown.Size () - 1; i >= 0; i--)
            aiLastKnown [i].Destroy ();

        aiLastKnown.Clear ();
    }
    
    void PushPath (Vector3 aiPathPos) {
        let newPoint = Spawn ('S7_LastKnownPositionMarker', aiPathPos);
        aiLastKnown.Push (newPoint);
    }
    
    void PopPath () {
        aiLastKnown [0].Destroy ();
        aiLastKnown.Delete (0);
    }
    
    void CreateSearchPath () {
        double pAngle = VectorAngle (aiPathHeading.X, aiPathHeading.Y);
        FLineTraceData data;

        ClearPath (); // Just in case
        PushPath (aiPathPos);

        aiLastKnown [0].LineTrace (pAngle, aiPathHeading.Length () * 105, 0, TRF_ThruActors, 25, 0, 0, data);
        PushPath (aiLastKnown [0].pos + Vec3Angle (data.distance - 8, pAngle, 0, true));

        for (int i = 0; i < 6; i++) {
            pAngle = fRandom [monsterAI] (0., 360.);
            aiLastKnown [1].LineTrace (pAngle, aiPathHeading.Length () * 105, 0, TRF_ThruActors, 25, 0, 0, data);
            PushPath (aiLastKnown [1].pos + Vec3Angle (data.distance - 8, pAngle, 0, true));
        }
    }

    void SearchBehavior () {
        // Reset AI mode, clear path (if needed) and skip AI checks if dead
        if (health <= 0) {
            aiMode = AI_Normal;

            if (aiLastKnown.Size () > 0)
                ClearPath ();

            return;
        }

        switch (aiMode) {
            // Standard AI mode, no changes to behavior
            case AI_Normal:
                if (!target)
                    return;

                if (aiLastKnown.Size () > 0 && target == aiLastKnown [0]) {
                    A_ClearTarget ();
                    ClearPath ();

                    return;
                }

                if (CheckIfTargetInLOS ()) {
                    // Add to aiCountdown while in LOS, up to 5 seconds as a sort of soft aggro-cooldown
                    // before monsters switch to more passive goal chase.
                    aiCountdown = clamp (aiCountdown + 1, 35, 175);
                    aiPathPos = target.pos;
                    aiPathHeading = target.vel;

                    break;
                }

                if (aiCountdown == 0) {
                    // Set 1-2 minutes for chase + search time.
                    aiCountdown = random [monsterAI] (60, 120) * 35;
                    A_ClearTarget ();
                    CreateSearchPath ();

                    target = aiLastKnown [0];
                    goal = aiLastKnown [0];
                    bChaseGoal = true;

                    aiMode = AI_Chasing;
                }
            break;

            // Player LOS, set goal to last known position.
            case AI_Chasing:
                // Simple check to see if the monster has aquired another target.
                if (target != aiLastKnown [0] && ! (target is "S7_LastKnownPositionMarker")) {
                    aiMode = AI_Normal;
                    goal = null;
                    bChaseGoal = false;
                }

                // Check if in search area or timer too low.
                if (Distance3D (aiLastKnown [0]) <= 64 || aiCountdown <= (30 * 35)) {
                    if (aiLastKnown.Size () > 1) {
                        PopPath ();

                        target = aiLastKnown [0];
                        goal = aiLastKnown [0];

                        aiCountdown += 70;
                    } else {
                        A_ClearTarget ();
                        ClearPath ();

                        goal = null;
                        bChaseGoal = false;

                        aiMode = AI_Searching;
                    }
                }
            break;

            // Reached last position or search timer dropped too low. Wander in area.
            case AI_Searching:
                if (aiCountdown % 5 == 0)
                    A_Wander ();

                // Another simple check to return to normal if monster gets a target.
                if (target)
                    aiMode = AI_Normal;

                // Finish the search and return to normal mode.
                if (aiCountdown <= 0) {
                    aiMode = AI_Normal;
                    A_ClearTarget ();

                    goal = null;
                }
            break;
        }

        aiCountdown = max (aiCountdown - 1, -1);
    }
}