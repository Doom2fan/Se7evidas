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
// Backpack spawner
//
//-------------------------------------------------------------------------------------------
class S7_BackpackSpawner : S7_ItemSpawner replaces Backpack {
    default {
        DropItem 'S7_Backpack', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Clip spawner
//
//-------------------------------------------------------------------------------------------
class S7_ClipSpawner : S7_ItemSpawner replaces Clip {
    default {
        DropItem 'S7_Nothing'      , 256, 4;
        DropItem 'S7_9mmCartridges', 256, 4;
    }
}

//-------------------------------------------------------------------------------------------
//
// ClipBox spawner
//
//-------------------------------------------------------------------------------------------
class S7_ClipBoxSpawner : S7_ItemSpawner replaces ClipBox {
    default {
        DropItem 'S7_Nothing'      , 256, 2;
        DropItem 'S7_9mmCartridges', 256, 4;
        DropItem 'S7_45ACPCartridges', 256, 1;
        DropItem 'S7_Loot_BloodChalice', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Shell spawner
//
//-------------------------------------------------------------------------------------------
class S7_ShellSpawner : S7_ItemSpawner replaces Shell {
    default {
        DropItem 'S7_Nothing'        , 256, 3;
        DropItem 'S7_12gaShellsSmall', 256, 2;
        DropItem 'S7_20gaShellsSmall', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// ShellBox spawner
//
//-------------------------------------------------------------------------------------------
class S7_ShellBoxSpawner : S7_ItemSpawner replaces ShellBox {
    default {
        DropItem 'S7_Nothing'   , 256, 2;
        DropItem 'S7_12gaShells', 256, 1;
        DropItem 'S7_20gaShells', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// RocketAmmo spawner
//
//-------------------------------------------------------------------------------------------
class S7_RocketAmmoSpawner : S7_ItemSpawner replaces RocketAmmo {
    default {
        DropItem 'S7_Nothing'     , 256, 2;
        DropItem 'S7_GrenadeCount', 256, 2;
    }
}

//-------------------------------------------------------------------------------------------
//
// RocketBox spawner
//
//-------------------------------------------------------------------------------------------
class S7_RocketBoxSpawner : S7_ItemSpawner replaces RocketBox {
    default {
        DropItem 'S7_Nothing'   , 256, 1;
        DropItem 'S7_GrenadeBox', 256, 3;
    }
}

//-------------------------------------------------------------------------------------------
//
// Cell spawner
//
//-------------------------------------------------------------------------------------------
class S7_CellSpawner : S7_ItemSpawner replaces Cell {
    default {
        DropItem 'S7_Nothing'   , 256, 3;
        DropItem 'S7_Cells'     , 256, 2;
        DropItem 'S7_FBSysCells', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Cell Pack spawner
//
//-------------------------------------------------------------------------------------------
class S7_CellPackSpawner : S7_ItemSpawner replaces CellPack {
    default {
        DropItem 'S7_Nothing'      , 256, 6;
        DropItem 'S7_Cells'        , 256, 3;
        DropItem 'S7_FBSysCellPack', 256, 2;
    }
}