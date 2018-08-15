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