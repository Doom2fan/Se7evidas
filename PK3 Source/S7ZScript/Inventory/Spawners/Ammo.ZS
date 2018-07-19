//-------------------------------------------------------------------------------------------
//
// Clip spawner
//
//-------------------------------------------------------------------------------------------
class S7_ClipSpawner : S7_ReplacementSpawner replaces Clip {
    default {
        DropItem "S7_Nothing"      , 256, 3;
        DropItem "S7_9mmCartridges", 256, 4;
        DropItem "S7_45ACPCartridges", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// ClipBox spawner
//
//-------------------------------------------------------------------------------------------
class S7_ClipBoxSpawner : S7_ReplacementSpawner replaces ClipBox {
    default {
        DropItem "S7_9mmCartridges", 256, 5;
        DropItem "S7_45ACPCartridges", 256, 2;
        DropItem "S7_Loot_BloodChalice", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Shell spawner
//
//-------------------------------------------------------------------------------------------
class S7_ShellSpawner : S7_ReplacementSpawner replaces Shell {
    default {
        DropItem "S7_Nothing"        , 256, 3;
        DropItem "S7_12gaShellsSmall", 256, 2;
        DropItem "S7_20gaShellsSmall", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// ShellBox spawner
//
//-------------------------------------------------------------------------------------------
class S7_ShellBoxSpawner : S7_ReplacementSpawner replaces ShellBox {
    default {
        DropItem "S7_Nothing"   , 256, 2;
        DropItem "S7_12gaShells", 256, 2;
        DropItem "S7_20gaShells", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// RocketAmmo spawner
//
//-------------------------------------------------------------------------------------------
class S7_RocketAmmoSpawner : S7_ReplacementSpawner replaces RocketAmmo {
    default {
        DropItem "S7_Nothing"     , 256, 2;
        DropItem "S7_GrenadeCount", 256, 2;
    }
}

//-------------------------------------------------------------------------------------------
//
// RocketBox spawner
//
//-------------------------------------------------------------------------------------------
class S7_RocketBoxSpawner : S7_ReplacementSpawner replaces RocketBox {
    default {
        DropItem "S7_Nothing"     , 256, 1;
        DropItem "S7_GrenadeCount", 256, 3;
    }
}