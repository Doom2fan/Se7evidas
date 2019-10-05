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

// Version
const S7C_MajorVersion = 0;
const S7C_MinorVersion = 3;
const S7C_PointVersion = 0;

// Map events
enum S7_MapEventTypes {
    S7_MEVNT_None            = 0, // This is here just in case you need to check it for some reason.
    S7_MEVNT_GhostTown          ,
    S7_MEVNT_PowerOutage        ,
    S7_MEVNT_NuclearMeltdown    ,
    S7_MEVNT_PerfectHatred      ,
    S7_MEVNT_LastToken          , // This is here just so you don't have to keep track of the last event, it's not an actual event.
};

// Firing mode icons
enum S7_FiringModeIcon {
    S7_FMI_None      = 0,
    S7_FMI_SemiAuto  = 1,
    S7_FMI_BurstFire = 2,
    S7_FMI_FullAuto  = 3,
};

// Weapon binding slots
enum S7_WeaponSlots {
    S7_WpSlot_Medium = 1,
    S7_WpSlot_Light,
    S7_WpSlot_Heavy,
    S7_WpSlot_AreaDMG,
    S7_WpSlot_Special,
};

// Delayed spawns
enum S7_DelayedSpawns {
    S7_DelaySpawns_Off = 0,
    S7_DelaySpawns_MapStart = 1,
    S7_DelaySpawns_All = 2,
}

// Debugging constants
enum S7_DebuggingConstants {
    // Monster AI bitfield
    S7_Dbg_MAI_Searching = 1 << 0,
};

// Player data
const S7C_DodgeStamina = 30;
const S7C_SprintStamina = 5;
const S7C_BaseSprintFactor = 0.5;
const S7C_MJumpMinDiff = 15;
const S7C_WJumpDelay = 5;

// Misc
const S7C_MapUnitsPerMeter = 32;
const S7C_EqualEpsilon = (1 / 65536.);