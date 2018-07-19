//-------------------------------------------------------------------------------------------
//
// Chainsaw spawner
//
//-------------------------------------------------------------------------------------------
class S7_ChainsawSpawner : S7_ReplacementSpawner replaces Chainsaw {
    default {
        DropItem "S7_Nothing"               , 256, 2;
        DropItem "S7_Loot_BloodChalice"     , 256, 3;
        DropItem "S7_Loot_SacrificialDagger", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Shotgun spawner
//
//-------------------------------------------------------------------------------------------
class S7_ShotgunSpawner : S7_ReplacementSpawner replaces Shotgun {
    default {
        DropItem "S7_Loot_BloodChalice"     , 256, 3;
        DropItem "S7_Loot_SacrificialDagger", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Super shotgun spawner
//
//-------------------------------------------------------------------------------------------
class S7_SuperShotgunSpawner : S7_ReplacementSpawner replaces SuperShotgun {
    default {
        DropItem "S7_Loot_BloodChalice"     , 256, 2;
        DropItem "S7_Loot_SacrificialDagger", 256, 2;
        DropItem "S7_Loot_SkullSceptre"     , 256, 1;
    }
}