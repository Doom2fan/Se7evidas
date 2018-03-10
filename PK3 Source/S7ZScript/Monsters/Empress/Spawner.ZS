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

        DropItem "S7_Empress", 256;

        +LOOKALLAROUND
    }

    int loopCount;

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

            A_SpawnItemEx ("S7_EmpressSmoke", fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_SpawnItemEx ("S7_EmpressSmoke", fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            loopCount--;

            return ResolveState (null);
        }
        loop;
    PreSpawnIdle:
        TNT1 A 1 {
            A_SpawnItemEx ("S7_EmpressSmoke", fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
            A_SpawnItemEx ("S7_EmpressSmoke", fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
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
            for (int i = 0; i < 5; i++)
                A_SpawnItemEx ("S7_EmpressPentagramCorner", 180.0, 0.0, 0.0, 0.0, 0.0, 0.0, 72 * i, SXF_Clientside | SXF_NoCheckPosition);;
        }
        TNT1 AAAAAAAAAAAA 1 A_SpawnItemEx ("S7_EmpressSmoke", fRandom [sfx] (-23.0, 23.0), fRandom [sfx] (-23.0, 23.0), 15.0 + fRandom [sfx] (-0.0, 32.0), 0.0, 0.0, 0.0, 0, SXF_Clientside | SXF_NoCheckPosition);
        TNT1 A            5;
        TNT1 A            0 {
            Super.BeginPlay ();
            Super.PostBeginPlay ();

            for (int i = 0; i < 48; i++) {
                A_SpawnItemEx ("S7_EmpressSparkle", fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 50.0 + fRandom [sfx] (0.0, 2.5),
                    fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), fRandom [sfx] (-8.0, 8.0), 0, SXF_Clientside | SXF_NoCheckPosition);
            }
        }
    Idle:
        TNT1 A 1 {
            if (!tracer || tracer.health <= 0) {
                A_BossDeath ();
                Destroy ();
            }
        }
        loop;
    }
}