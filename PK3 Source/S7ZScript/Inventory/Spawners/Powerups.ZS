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
// Armor Bonus spawner
//
//-------------------------------------------------------------------------------------------
class S7_ArmorBonusSpawner : RandomSpawner replaces ArmorBonus {
    default {
        DropItem "S7_Nothing",         256, 2;
        DropItem "S7_ArmorBonus",      256, 4;
        DropItem "S7_LargeArmorBonus", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Invulnerability Sphere spawner
//
//-------------------------------------------------------------------------------------------
class S7_InvulnerabilitySpawner : RandomSpawner replaces InvulnerabilitySphere {
    default {
        DropItem "S7_InvulnerabilityType1", 256, 5;
        DropItem "S7_InvulnerabilityType2", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Soulsphere spawner
//
//-------------------------------------------------------------------------------------------
class S7_SoulsphereSpawner : RandomSpawner replaces Soulsphere {
    default {
        DropItem "S7_HeartSphere", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Megasphere spawner
//
//-------------------------------------------------------------------------------------------
class S7_MegasphereSpawner : RandomSpawner replaces Megasphere {
    default {
        DropItem "S7_SoulSphere", 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Infrared spawner
//
//-------------------------------------------------------------------------------------------
class S7_InfraredSpawner : RandomSpawner replaces Infrared {
    default {
        DropItem "S7_FlashlightBattery", 256, 1;
    }
}