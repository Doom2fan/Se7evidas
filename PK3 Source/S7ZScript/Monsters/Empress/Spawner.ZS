/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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

//-------------------------------------------------------------------------------------------
//
// Empress spawner
//
//-------------------------------------------------------------------------------------------
class S7_EmpressPreSpawn : S7_MonsterSpawner {
    default {
        Radius 1;
        Height 1;
        Mass 0x7FFFFFFF;

        DropItem 'S7_Empress', 256;

        +LOOKALLAROUND
        -NOSECTOR
    }

    int loopCount;
    Actor spawnedEmpress;

    override void BeginPlay () { Actor.BeginPlay (); }
    override void PostBeginPlay () { Actor.PostBeginPlay (); }
    override void Tick () { Actor.Tick (); }

    states {
    Spawn:
        TNT1 A 0 noDelay { loopCount = random [monsterSpc] (4, 7); }
    SpawnLoople:
        TNT1 A 1 {
            if (loopCount < 1)
                return ResolveState ("PreSpawnIdle");

            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            loopCount--;

            return ResolveState (null);
        }
        loop;
    PreSpawnIdle:
        TNT1 A 1 {
            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_Look ();
        }
        loop;

    See:
        TNT1 A 0 {
            if (CheckIfCloser (target, 384.0))
                return ResolveState ("GOGOGO");

            A_ClearTarget ();
            loopCount = 2;

            return ResolveState (null);
        }
        goto SpawnLoople;

    GOGOGO:
        TNT1 A            0 {
            for (int i = 0; i < (5*2); i++)
                A_SpawnItemEx ('S7_EmpressPentagramCorner', 180.0, 0.0, 0.0, 0.0, 0.0, 0.0, (72/2.) * i, SXF_Clientside | SXF_NoCheckPosition);
        }
        TNT1 AAAAAAAAAAAA 1 A_SpawnItemEx ('S7_EmpressSmoke', fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        TNT1 A            5;
        TNT1 A            0 {
            let prevTracer = tracer;

            Super.BeginPlay ();
            Super.PostBeginPlay ();

            if (tracer) {
                spawnedEmpress = tracer;
                tracer = prevTracer;

                spawnedEmpress.target = target;
                spawnedEmpress.master = master;
                spawnedEmpress.tracer = tracer;

                for (int i = 0; i < 48; i++) {
                    A_SpawnItemEx ('S7_EmpressSparkle', fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 50.0 + fRandom [sfx] (0.0, 2.5),
                        fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), 0, SXF_Clientside | SXF_NoCheckPosition);
                }
            }
        }
    Idle:
        TNT1 A 1 {
            if (!spawnedEmpress || (spawnedEmpress.health <= 0 && spawnedEmpress.tics == -1)) {
                A_BossDeath ();
                Destroy ();
            }
        }
        loop;
    }
}