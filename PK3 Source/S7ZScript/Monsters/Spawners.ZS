class S7_ReplacementSpawner : S7_MonsterSpawner {
    default {
        +ISMONSTER +COUNTKILL
    }

    override class<Actor> MS_GetMonsterSpawnList () {
        let mapData = S7_MapData.Get ();

        if (level.maptime <= 1) {
            let spawnPos = new ("S7_MapData_SpawnPos");

            spawnPos.actorClass = GetReplacee (GetClass ());
            spawnPos.pos = spawnPoint;

            mapData.monsterSpawnPos.Push (spawnPos);
        }

        if (!mapData.mapEventSet)
            S7_MapEventThinker.Init (null, mapData);

        if (mapData.mapEvent == MEVNT_PerfectHatred)
            return 'S7_MEvntNoMonster';

        return null;
    }

    bool spawnLater;
    void DoSpawnProcess () { // Gotta do this stupid hack...
        bIsMonster = false;
        ClearCounters ();

        Super.BeginPlay ();
    }

    override void BeginPlay () {
        let serverData = S7_ServerData.GetSpecial ();

        if (!serverData)
            spawnLater = true;
        else
            DoSpawnProcess ();
    }

    override void PostBeginPlay () {
        if (spawnLater)
            DoSpawnProcess ();

        Super.PostBeginPlay ();
    }
}

//-------------------------------------------------------------------------------------------
//
// Zombieman spawner
//
//-------------------------------------------------------------------------------------------
class S7_ZombiemanSpawner : S7_ReplacementSpawner replaces Zombieman {
    default {
        DropItem "S7_ScorpsTrooper", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Shotgun Guy spawner
//
//-------------------------------------------------------------------------------------------
class S7_ShotgunGuySpawner : S7_ReplacementSpawner replaces ShotgunGuy {
    default {
        DropItem "S7_ScorpsHunter", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Imp spawner
//
//-------------------------------------------------------------------------------------------
class S7_ImpSpawner : S7_ReplacementSpawner replaces DoomImp {
    default {
        DropItem "S7_Hellion", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Chaingun Guy spawner
//
//-------------------------------------------------------------------------------------------
class S7_ChaingunGuySpawner : S7_ReplacementSpawner replaces ChaingunGuy {
    default {
        DropItem "S7_ScorpsEnforcer", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Cacodemon spawner
//
//-------------------------------------------------------------------------------------------
class S7_CacodemonSpawner : S7_ReplacementSpawner replaces Cacodemon {
    default {
        DropItem "S7_Succubus", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Mancubus spawner
//
//-------------------------------------------------------------------------------------------
class S7_MancubusSpawner : S7_ReplacementSpawner replaces Fatso {
    default {
        DropItem "S7_FatFuck", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Hell Knight spawner
//
//-------------------------------------------------------------------------------------------
class S7_HellKnightSpawner : S7_ReplacementSpawner replaces HellKnight {
    default {
        DropItem "S7_BlackPanther", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Cyberdemon spawner
//
//-------------------------------------------------------------------------------------------
class S7_CyberdemonSpawner : S7_ReplacementSpawner replaces Cyberdemon {
    default {
        DropItem "S7_EmpressPreSpawn", 256, 1;
    }
}