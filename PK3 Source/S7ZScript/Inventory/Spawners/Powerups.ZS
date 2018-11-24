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

//-------------------------------------------------------------------------------------------
//
// Armor Bonus spawner
//
//-------------------------------------------------------------------------------------------
class S7_ArmorBonusSpawner : RandomSpawner replaces ArmorBonus {
    default {
        DropItem 'S7_CanteenRefill',   256, 2;
        DropItem 'S7_Nothing',         256, 2;
        DropItem 'S7_ArmorBonus',      256, 8;
        DropItem 'S7_LargeArmorBonus', 256, 2;
    }
}

//-------------------------------------------------------------------------------------------
//
// Invulnerability Sphere spawner
//
//-------------------------------------------------------------------------------------------
class S7_InvulnerabilitySpawner : RandomSpawner replaces InvulnerabilitySphere {
    default {
        DropItem 'S7_InvulnerabilityType1', 256, 5;
        DropItem 'S7_InvulnerabilityType2', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Soulsphere spawner
//
//-------------------------------------------------------------------------------------------
class S7_SoulsphereSpawner : RandomSpawner replaces Soulsphere {
    default {
        DropItem 'S7_HeartSphere', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Megasphere spawner
//
//-------------------------------------------------------------------------------------------
class S7_MegasphereSpawner : RandomSpawner replaces Megasphere {
    default {
        DropItem 'S7_SoulSphere', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Infrared spawner
//
//-------------------------------------------------------------------------------------------
class S7_InfraredSpawner : RandomSpawner replaces Infrared {
    default {
        DropItem 'S7_DemonEyes'        , 256, 3;
        DropItem 'S7_FlashlightBattery', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Berserk spawner
//
//-------------------------------------------------------------------------------------------
class S7_BerserkSpawner : RandomSpawner replaces Berserk {
    default {
        DropItem 'S7_Berserk', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Allmap spawner
//
//-------------------------------------------------------------------------------------------
class S7_AllmapSpawner : RandomSpawner replaces Allmap {
    default {
        DropItem 'S7_MapPowerup', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// RadSuit spawner
//
//-------------------------------------------------------------------------------------------
class S7_RadSuitSpawner : RandomSpawner replaces RadSuit {
    default {
        DropItem 'S7_Biosphere', 256, 1;
    }
}

//-------------------------------------------------------------------------------------------
//
// Blursphere spawner
//
//-------------------------------------------------------------------------------------------
class S7_BlursphereSpawner : RandomSpawner replaces Blursphere {
    default {
        DropItem 'S7_Invisibility', 256, 1;
    }
}