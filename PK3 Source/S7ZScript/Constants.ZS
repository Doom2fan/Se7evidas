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
enum MapEventTypes {
    MEVNT_None            = 0, // This is here just in case you need to check it for some reason.
    MEVNT_GhostTown          ,
    MEVNT_PowerOutage        ,
    MEVNT_NuclearMeltdown    ,
    MEVNT_PerfectHatred      ,
    MEVNT_LastToken          , // This is here just so you don't have to keep track of the last event, it's not an actual event.
};

// Firing mode icons
enum FiringModeIcon {
    FMI_None      = 0,
    FMI_SemiAuto  = 1,
    FMI_BurstFire = 2,
    FMI_FullAuto  = 3,
};

// Weapon binding slots
enum S7_WeaponSlots {
    WpSlot_Medium = 1,
    WpSlot_Light,
    WpSlot_Heavy,
    WpSlot_AreaDMG,
    WpSlot_Special,
};

// Delayed spawns
enum S7_DelayedSpawns {
    DelaySpawns_Off = 0,
    DelaySpawns_MapStart = 1,
    DelaySpawns_All = 2,
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
const EQUAL_EPSILON = (1 / 65536.);
const TICRATE = Thinker.TICRATE;