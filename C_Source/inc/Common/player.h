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
#include "types.h"

// Macros
#define SS_ITEMSMAX \
( \
 (ArraySize (player->shopDef.items)) \
)

// Typedefs
typedef struct PD_AmmoType_t    PD_AmmoType_t;
// Player data
typedef struct PD_Physics_t     PD_Physics_t;   // Physics
typedef struct PD_Health_t      PD_Health_t;    // Health
// RPG Systems
typedef struct PD_XPSystem_t    PD_XPSystem_t;  // XP System
// Misc
typedef struct PD_Misc_t        PD_Misc_t;
// Script Data
// Shop system
typedef struct PD_ScriptData_t  PD_ScriptData_t;
typedef struct SS_Item_t        SS_Item_t;
typedef struct SS_Page_t        SS_Page_t;
typedef struct SS_Shop_t        SS_Shop_t;
typedef struct ShopDef_t        ShopDef_t;
typedef struct SprintDef_t      SprintDef_t;
typedef struct ParkourDef_t     ParkourDef_t;
typedef struct ThumperDef_t     ThumperDef_t;
typedef struct WeapBinds_t      WeapBinds_t;
// Save system
typedef struct SavedData_t      SavedData_t;

// Blerghled Prototypes
bool        LoadSaveDataToPointer (int playerNum, SavedData_t *data);
SavedData_t LoadSaveData          (int playerNum);
bool        SaveSaveData          (int playerNum, SavedData_t *data);

// Structs
struct PD_AmmoType_t {
    string name;
    int    magSize;
};

struct PD_Physics_t {
    accum x, y, z;                      // XYZ coordinates
    accum velX, velY, velZ;             // XYZ velocities
    accum angle;                        // Angle
    accum velAngle;                     // Movement angle
    accum floorZ, ceilZ;                // Sector Z coordinates
    accum relativeZ;                    // Z coordinate relative to sector floor
    accum jumpZ;                        // Jump height/velocity?
};

struct PD_Health_t {
    int health;                         // Health
    int maxHealth;                      // Max health
    int stamina;                        // Stamina
    int milkRegenRate;                  // Canteen regen rate
    int milkUseRate;                    // Canteen use rate
};

struct PD_XPSystem_t {
    int level;                          // Current level
    int experience;                     // Amount of experience
    int attrPoints;                     // Attribute points
    int strengthLVL;                    // Strength level
    int staminaLVL;                     // Stamina level
};

typedef struct PD_Misc_t {
    int  waterlevel;                    // How deep in water the player is
    bool dying;                         // Is the player dying?
};

struct PD_ScriptData_t {
    bool  disableHUD;                   // Disable HUD
    int   lastWeapon;                   // The last weapon the player selected
    bool  staminaEmpty;                 // Did the player run out of stamina?
    int   staminaTics;                  // Used for the stamina regeneration
    int   popupNum;                     // Current popup
    int   pPageNum;                     // Current popup page
    bool  beamGrab;                     // Soul lance beam grabbed
};

struct SprintDef_t {
    accum OldSpeed;                     // The player's old speed
    bool  Sprinting;                    // Is the player sprinting?
    bool  disable;                      // Disable sprinting
};

struct ParkourDef_t {
    /* Dodging */
    int  dodgeCooldown;                 // The cooldown before you can dodge again
    int  dodgeInvulnTics;               // The time you stay invulnerable

    /* Multi-jumping */
    bool mjumpOnGround;                 // Is the player on the ground?
    int  mjumpCount, mjumpMax;          // Count and max
};

#define THUMPERMAGSIZE 4
struct ThumperDef_t {
    int magShells [THUMPERMAGSIZE];     // Loaded shells in mag
    int magIndex;                       // Current shell in mag
    int currentShell;                   // Loaded shell in chamber
};

struct ShopDef_t {
    bool       open, disableOpen;
    SS_Shop_t *shop;
    SS_Page_t *page;
    SS_Item_t *items [100];
    int        itemsLength;
    vec2_i     position;
    int        moveDelay, moveSpeed;
    bool       sellMode;
};

struct WeapBinds_t {
    vec2_i curWeap;                     // Current weapon;
    int    weapBinds [5] [5];           // Weapon bindings array
};

typedef struct PlayerData_t {
    bool            initialized;        // Player is initialized
    
    // Position, velocity, etc
    PD_Physics_t    physics;            // Physics related stuff

    // Health and stamina
    PD_Health_t     health;             // Health related stuff

    // RPG system stuff
    PD_XPSystem_t   xpSystem;           // Level system stuff
    int             cash;               // Cash
    int             ammoMax;            // Ammo max mul
    
    // Misc
    PD_Misc_t       misc;               // Misc stuff

    // Script data
    PD_ScriptData_t scriptData;         // Misc script data
    SprintDef_t     SprintDef;          // Sprint system stuff
    ParkourDef_t    parkourDef;         // Dodging system stuff
    ThumperDef_t    thumperDef;         // Thumper stuff
    ShopDef_t       shopDef;            // Shop system stuff
    WeapBinds_t     weapBinds;          // Weapon bindings
} PlayerData_t;

struct SavedData_t {
    bool            isInvalid;          // Is the save data invalid?
    string          name;               // Player name
    int             gender;             // Player gender

    // RPG Systems
    PD_XPSystem_t   xpSystem;           // Level system stuff
    int             cash;               // Cash

    // Script data
    PD_ScriptData_t scriptData;         // Misc script data
    ThumperDef_t    thumperDef;         // Thumper stuff
    WeapBinds_t     weapBinds;          // Weapon bindings
};

// Stuff
static const string PD_Gender [] = {
    s"GEN_MALE",
    s"GEN_FEM",
    s"GEN_OTHER",
    s"GEN_HERM",
};

static const PD_AmmoType_t PD_AmmoTypes [] = {
    {
        .name = s"S7_9mmCartridges",
        .magSize = 15,
    },
    {
        .name = s"S7_45ACPCartridges",
        .magSize = 62,
    },
    {
        .name = s"S7_44MCartridges",
        .magSize = 6,
    },
    {
        .name = s"S7_762x39Cartridges",
        .magSize = 35,
    },
    {
        .name = s"S7_20gaShells",
        .magSize = 10,
    },
    {
        .name = s"S7_Cells",
        .magSize = 36,
    },
    {
        .name = s"S7_FBSysCells",
        .magSize = 23,
    },
    {
        .name = s"S7_Thumper_PExp",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PFrag",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PTherm",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PFlare",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PCluster",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PNail",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PNGas",
        .magSize = 5,
    },
};

string ReqClientsideCVars [] [2] = {
    { s"screenblocks", s"S7_Screenblocks", },
};

// Prototypes
void TakeCash (PlayerData_t *player, int amount);
void GiveCash (PlayerData_t *player, int amount);
void InitializePlayer  (PlayerData_t *player);
void DisconnectPlayer  (PlayerData_t *player);
void UpdatePlayerData  (PlayerData_t *player);
void UpdateAmmoMax     (PlayerData_t *player);
void UpdatePlayerAlpha (PlayerData_t *player);
void UpdateClientsideCVars ();
bool PD_DoLoadSave  (PlayerData_t *player, SavedData_t *saveData);
bool PD_PerformLoad (PlayerData_t *player, SavedData_t *saveData);

// Externs
extern PlayerData_t PlayerData [MAX_PLAYERS];

#endif