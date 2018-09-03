/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

//-------------------------------------------------------------------------------------------
//
// Chainsaw spawner
//
//-------------------------------------------------------------------------------------------
class S7_ChainsawSpawner : RandomSpawner replaces Chainsaw {
    default {
        DropItem "S7_Nothing"               , 256, 2;
        DropItem "S7_Loot_BloodChalice"     , 256, 3;
        DropItem "S7_Loot_SacrificialDagger", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Pistol spawner
//
//-------------------------------------------------------------------------------------------
class S7_PistolSpawner : RandomSpawner replaces Pistol {
    default {
        DropItem "S7_9mmCartridges"         , 256, 3;
        DropItem "S7_Loot_BloodChalice"     , 256, 2;
        DropItem "S7_Nothing"               , 256, 2;
        DropItem "S7_45ACPCartridges"       , 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Shotgun spawner
//
//-------------------------------------------------------------------------------------------
class S7_ShotgunSpawner : RandomSpawner replaces Shotgun {
    default {
        DropItem "S7_Loot_BloodChalice"     , 256, 7;
        DropItem "S7_Loot_SacrificialDagger", 256, 2;
        DropItem "S7_SSG"                   , 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Super shotgun spawner
//
//-------------------------------------------------------------------------------------------
class S7_SuperShotgunSpawner : RandomSpawner replaces SuperShotgun {
    default {
        DropItem "S7_Loot_BloodChalice"     , 256, 4;
        DropItem "S7_Loot_SacrificialDagger", 256, 3;
        DropItem "S7_SSG"                   , 256, 2;
        DropItem "S7_Loot_SkullSceptre"     , 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Chaingun spawner
//
//-------------------------------------------------------------------------------------------
class S7_ChaingunSpawner : RandomSpawner replaces Chaingun {
    default {
        DropItem "S7_Nothing"          , 256, 1;
        DropItem "S7_Loot_SkullSceptre", 256, 2;
        DropItem "S7_AK47"             , 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Rocket Launcher spawner
//
//-------------------------------------------------------------------------------------------
class S7_RocketLauncherSpawner : RandomSpawner replaces RocketLauncher {
    default {
        DropItem "S7_GrenadeBox"       , 256, 3;
        DropItem "S7_Loot_SkullSceptre", 256, 1;
    }
}