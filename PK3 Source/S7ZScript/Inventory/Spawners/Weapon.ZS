/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
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
// Chainsaw spawner
//
//-------------------------------------------------------------------------------------------
class S7_ChainsawSpawner : S7_ItemSpawner replaces Chainsaw {
    default {
        DropItem 'S7_Nothing'               , 256, 2;
        DropItem 'S7_Loot_BloodChalice'     , 256, 3;
        DropItem 'S7_Loot_SacrificialDagger', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Pistol spawner
//
//-------------------------------------------------------------------------------------------
class S7_PistolSpawner : S7_ItemSpawner replaces Pistol {
    default {
        DropItem 'S7_9mmCartridges'         , 256, 3;
        DropItem 'S7_Loot_BloodChalice'     , 256, 2;
        DropItem 'S7_Nothing'               , 256, 2;
        DropItem 'S7_45ACPCartridges'       , 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Shotgun spawner
//
//-------------------------------------------------------------------------------------------
class S7_ShotgunSpawner : S7_ItemSpawner replaces Shotgun {
    default {
        DropItem 'S7_Loot_BloodChalice'     , 256, 6;
        DropItem 'S7_Loot_SacrificialDagger', 256, 2;
        DropItem 'S7_SSG'                   , 256, 2;
    }
}

//-------------------------------------------------------------------------------------------
//
// Super shotgun spawner
//
//-------------------------------------------------------------------------------------------
class S7_SuperShotgunSpawner : S7_ItemSpawner replaces SuperShotgun {
    default {
        DropItem 'S7_Loot_BloodChalice'     , 256, 7;
        DropItem 'S7_Loot_SacrificialDagger', 256, 6;
        DropItem 'S7_SSG'                   , 256, 5;
        DropItem 'S7_Loot_SkullSceptre'     , 256, 2;
    }
}

//-------------------------------------------------------------------------------------------
//
// Chaingun spawner
//
//-------------------------------------------------------------------------------------------
class S7_ChaingunSpawner : S7_ItemSpawner replaces Chaingun {
    default {
        DropItem 'S7_Nothing'          , 256, 1;
        DropItem 'S7_Loot_SkullSceptre', 256, 2;
        DropItem 'S7_AK47'             , 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Rocket Launcher spawner
//
//-------------------------------------------------------------------------------------------
class S7_RocketLauncherSpawner : S7_ItemSpawner replaces RocketLauncher {
    default {
        DropItem 'S7_GrenadeBox'       , 256, 3;
        DropItem 'S7_Loot_SkullSceptre', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Plasma Rifle spawner
//
//-------------------------------------------------------------------------------------------
class S7_PlasmaRifleSpawner : S7_ItemSpawner replaces PlasmaRifle {
    default {
        DropItem 'S7_Loot_CreditsBriefcase5K', 256, 3;
        DropItem 'S7_Loot_GoldChest'         , 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// BFG 9000 spawner
//
//-------------------------------------------------------------------------------------------
class S7_BFG9000Spawner : S7_ItemSpawner replaces BFG9000 {
    default {
        DropItem 'S7_Loot_GoldChest'          , 256, 3;
        DropItem 'S7_Loot_CreditsBriefcase10K', 256, 1;
    }
}