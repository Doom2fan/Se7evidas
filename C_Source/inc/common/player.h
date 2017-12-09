/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015-???  Chronos Ouroboros
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
#include "common/types.h"
#include "systems/bank_system.h"
#include "systems/monster_stuff.h"

// Typedefs
// Player data
typedef struct PD_Physics_t     PD_Physics_t;   // Physics
typedef struct PD_Health_t      PD_Health_t;    // Health
// Misc
typedef struct PD_Misc_t        PD_Misc_t;
// Script Data
typedef struct PD_ScriptData_t  PD_ScriptData_t;
typedef struct BankDef_t        BankDef_t;
typedef struct ParkourDef_t     ParkourDef_t;
typedef struct PlayerMenu_t     PlayerMenu_t;

// Structs
struct PD_Physics_t {
    accum x, y, z;                      // XYZ coordinates
    accum radius, height;               // Radius and height
    accum velX, velY, velZ;             // XYZ velocities
    accum angle, pitch;                 // Angle and pitch
    accum velAngle;                     // Movement angle
    accum floorZ, ceilZ;                // Sector Z coordinates
    accum relativeZ;                    // Z coordinate relative to sector floor
    accum jumpZ;                        // Jump height/velocity?
};

struct PD_Health_t {
    int health;                         // Health
    int maxHealth;                      // Max health
};

struct PD_Misc_t {
    int  waterlevel;                    // How deep in water the player is
    bool dying;                         // Is the player dying?
};

struct PD_ScriptData_t {
    bool  disableHUD;                   // Disable HUD
    int   lastWeapon;                   // The last weapon the player selected
    int   popupNum;                     // Current popup
    int   pPageNum;                     // Current popup page
    bool  beamGrab;                     // Soul lance beam grabbed
    accum prevEyesDist;                 // Previous EYES distance
    int   prevStaticImage;              // The previous image used for the static. This is so it doesn't use the same image twice in a row
};

struct ParkourDef_t {
    /* Multi-jumping */
    bool   mjumpOnGround;                 // Is the player on the ground?
    int    mjumpCount, mjumpMax;          // Count and max

    /* Wall-jumping */
    int    wjumpJustJumped;               // The player just walljumped

    /* Wall grabbing */
    bool   wGrabHolding;                  // The player's holding onto a wall
    int    wGrabHoldi;                    // The value of i that detected the wall currently being held in the wall checking loop
    accum  wGrabHoldAngle;                // The angle the player was at when he held onto the wall
    vec2_k wGrabOldCoords;                // The player's old coords
    accum  wGrabOldGravity;               // The player's old gravity
};

struct BankDef_t {
    unsigned long int cash;
    BS_Item_t itemStorage [500];
};

struct PlayerMenu_t {
    bool open, disable, pause;
    int moveDelay, moveSpeed;
    int id, curIdx;

    struct PM_Page_t *page;
};

typedef struct PlayerData_t {
    bool            initialized;        // Player is initialized

    // Position, velocity, etc
    PD_Physics_t    physics;            // Physics related stuff

    // Health and stamina
    PD_Health_t     health;             // Health related stuff

    // RPG system stuff
    int             cash;               // Cash
    int             ammoMax;            // Ammo max mul

    // Misc
    PD_Misc_t       misc;               // Misc stuff

    // Script data
    PD_ScriptData_t scriptData;         // Misc script data
    ParkourDef_t    parkourDef;         // Dodging system stuff
    BankDef_t       bankData;           // Bank system stuff
    PlayerMenu_t    playerMenu;         // Player menu info
} PlayerData_t;

// Prototypes
void InitializePlayer  (PlayerData_t *player);
void DisconnectPlayer  (PlayerData_t *player);
void UpdatePlayerData  (PlayerData_t *player);
void UpdatePlayerAlpha (PlayerData_t *player);

// Externs (The definitions for these is in playerDefs.c, not player.c)
extern PlayerData_t PlayerData [MAX_PLAYERS];
extern string PD_Gender [];
extern int PD_Gender_Length;

#endif