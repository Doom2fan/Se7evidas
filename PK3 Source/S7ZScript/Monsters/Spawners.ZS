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
// Demon spawner
//
//-------------------------------------------------------------------------------------------
class S7_DemonSpawner : S7_ReplacementSpawner replaces Demon {
    default {
        DropItem "S7_DemonDog",  256, 3;
        DropItem "S7_Mechdemon", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Spectre spawner
//
//-------------------------------------------------------------------------------------------
class S7_SpectreSpawner : S7_ReplacementSpawner replaces Spectre {
    default {
        DropItem "S7_ShadowDemon", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Lost Soul spawner
//
//-------------------------------------------------------------------------------------------
class S7_LostSoulSpawner : S7_ReplacementSpawner replaces LostSoul {
    default {
        DropItem "S7_FleshSpawn", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Cacodemon spawner
//
//-------------------------------------------------------------------------------------------
class S7_CacodemonSpawner : S7_ReplacementSpawner replaces Cacodemon {
    default {
        DropItem "S7_Infernal", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Pain Elemental spawner
//
//-------------------------------------------------------------------------------------------
/*class S7_PainElementalSpawner : S7_ReplacementSpawner replaces PainElemental {
    default {
        DropItem "S7_Succubus", 256, 1;
    }
}*/

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
// Baron of Hell spawner
//
//-------------------------------------------------------------------------------------------
class S7_BaronOfHellSpawner : S7_ReplacementSpawner replaces BaronOfHell {
    default {
        DropItem "S7_InfernalGuardian", 256, 1;
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