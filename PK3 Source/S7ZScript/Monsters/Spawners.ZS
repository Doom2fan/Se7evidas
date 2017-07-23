class S7_ReplacementSpawner : S7_MonsterSpawner {
    override DropItem MS_GetMonsterSpawnList () {
        /*if (CallACS ("S7_GetMapEvent") == MEVNT_PerfectHatred)
            return S7_MEvntNoMonster*/
        return GetDropItems ();
    }
}
//-------------------------------------------------------------------------------------------
//
// Zombieman spawner
//
//-------------------------------------------------------------------------------------------
class S7_ZombiemanSpawner : S7_ReplacementSpawner replaces zombieman {
    default {
        DropItem "S7_ScorpsTrooper", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Imp spawner
//
//-------------------------------------------------------------------------------------------
class S7_ImpSpawner : S7_ReplacementSpawner replaces doomImp {
    default {
        DropItem "S7_Hellion", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Chaingun Guy spawner
//
//-------------------------------------------------------------------------------------------
class S7_ChaingunGuySpawner : S7_ReplacementSpawner replaces chaingunGuy {
    default {
        DropItem "S7_ScorpsEnforcer", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Cacodemon spawner
//
//-------------------------------------------------------------------------------------------
class S7_CacodemonSpawner : S7_ReplacementSpawner replaces cacodemon {
    default {
        DropItem "S7_Succubus", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Mancubus spawner
//
//-------------------------------------------------------------------------------------------
class S7_MancubusSpawner : S7_ReplacementSpawner replaces fatso {
    default {
        DropItem "S7_FatFuck", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Hell Knight spawner
//
//-------------------------------------------------------------------------------------------
class S7_HellKnightSpawner : S7_ReplacementSpawner replaces hellKnight {
    default {
        DropItem "S7_BlackPanther", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Cyberdemon spawner
//
//-------------------------------------------------------------------------------------------
class S7_CyberdemonSpawner : S7_ReplacementSpawner replaces cyberdemon {
    default {
        DropItem "S7_EmpressPreSpawn", 256, 1;
    }
}