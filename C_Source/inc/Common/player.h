/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015  Chronos Ouroboros
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License along
**  with this program; if not, write to the Free Software Foundation, Inc.,
**  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#ifndef PLAYER_H
#define PLAYER_H

#include <ACS_ZDoom.h>

struct SprintDef_t {
    accum OldSpeed; // The player's old speed
    bool Sprinting; // Is the player sprinting?
};
typedef struct SprintDef_t SprintDef_t;

struct ParkourDef_t {
    /* Dodging */
    int dodgeCooldown; // The cooldown before you can dodge again

    /* Multi-jumping */
    bool mjumpOnGround;
    int mjumpCount;
    int mjumpMax;
};
typedef struct ParkourDef_t ParkourDef_t;

struct PlayerData_t {
    // Position, velocity, etc
    accum x; accum y; accum z;          // XYZ coordinates
    accum velX; accum velY; accum velZ; // XYZ velocities
    accum angle;                        // Angle
    accum velAngle;                     // Movement angle
    accum floorZ; accum ceilZ;
    accum relativeZ;
    accum jumpZ;

    // Health and stamina
    int health;    // Health
    int maxHealth; // Max health
    int stamina;   // Stamina

    // XP system stuff
    int level;       // Current level
    int experience;  // Amount of experience
    int attrPoints;  // Attribute points
    int strengthLVL; // Strength level
    int staminaLVL;  // Stamina level
    
    // Misc
    int waterlevel;  // How deep in water the player is
    bool dying;      // Is the player dying?

    // Script data
    int lastWeapon;        // The last weapon the player selected
    SprintDef_t SprintDef; // Sprint system stuff
    bool staminaEmpty;     // Did the player run out of stamina?
    int staminaTics;       // Used for the stamina regeneration
    ParkourDef_t parkourDef;   // Dodging system stuff
};
typedef struct PlayerData_t PlayerData_t;

extern PlayerData_t PlayerData [MAX_PLAYERS];

void UpdatePlayerData (PlayerData_t *player);

#endif