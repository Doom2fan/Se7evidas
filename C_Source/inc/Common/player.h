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

// Defines
#define SS_ITEMSMAX \
   ( \
    (ArraySize (player->shopDef.items)) \
   )

// Typedefs
typedef struct SS_Item_t SS_Item_t;
typedef struct SS_Page_t SS_Page_t;
typedef struct SS_Shop_t SS_Shop_t;

// Structs
typedef struct SS_Pos_t {
    int x, y;
} SS_Pos_t;

typedef struct ShopDef_t {
    bool open, disableOpen;
    SS_Shop_t *shop;
    SS_Page_t *page;
    SS_Item_t *items [100];
    int itemsLength;
    SS_Pos_t position;
    int moveDelay, moveSpeed;
    bool sellMode;
} ShopDef_t;

typedef struct SprintDef_t {
    accum OldSpeed; // The player's old speed
    bool Sprinting; // Is the player sprinting?
} SprintDef_t;

typedef struct ParkourDef_t {
    /* Dodging */
    int dodgeCooldown; // The cooldown before you can dodge again

    /* Multi-jumping */
    bool mjumpOnGround;
    int mjumpCount, mjumpMax;
} ParkourDef_t;

typedef struct ThumperDef_t {
    int magShells [4];
    int magIndex;
    int currentShell;
} ThumperDef_t;

typedef struct PlayerData_t {
    bool initialized;
    
    // Position, velocity, etc
    accum x, y, z;                      // XYZ coordinates
    accum velX, velY, velZ;             // XYZ velocities
    accum angle;                        // Angle
    accum velAngle;                     // Movement angle
    accum floorZ, ceilZ;                // Sector Z coordinates
    accum relativeZ;                    // Z coordinate relative to sector floor
    accum jumpZ;                        // Jump height/velocity?

    // Health and stamina
    int health;                         // Health
    int maxHealth;                      // Max health
    int stamina;                        // Stamina

    // XP system stuff
    int level;                          // Current level
    int experience;                     // Amount of experience
    int attrPoints;                     // Attribute points
    int strengthLVL;                    // Strength level
    int staminaLVL;                     // Stamina level

    // Shop system stuff
    int cash;                           // Cash
    
    // Misc
    int waterlevel;                     // How deep in water the player is
    bool dying;                         // Is the player dying?

    // Script data
    int lastWeapon;                     // The last weapon the player selected
    SprintDef_t SprintDef;              // Sprint system stuff
    bool staminaEmpty;                  // Did the player run out of stamina?
    int staminaTics;                    // Used for the stamina regeneration
    ParkourDef_t parkourDef;            // Dodging system stuff
    ThumperDef_t thumperDef;            // Thumper stuff
    ShopDef_t shopDef;                  // Shop system stuff
    int popupNum;                       // Current popup
    int pPageNum;                       // Current popup page
} PlayerData_t;

// Prototypes
void TakeCash (PlayerData_t *player, int amount);
void GiveCash (PlayerData_t *player, int amount);
void InitializePlayer (PlayerData_t *player);
void DisconnectPlayer (PlayerData_t *player);
void UpdatePlayerData (PlayerData_t *player);

// Externs
extern PlayerData_t PlayerData [MAX_PLAYERS];

#endif