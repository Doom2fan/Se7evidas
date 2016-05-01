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

#ifndef MSTUFF_H
#define MSTUFF_H

#include <ACS_ZDoom.h>

// Macros
#define EMPINVDELAY (35 * 7.5)
#define EMPINVLIMIT 2500
#define EMPMHEALTH 4500
// Tokens
#define EMPIDENT s"S7_IsEmpress"
#define EMPINVTOKEN s"S7_EmpressCanCastInvuln"
// User vars
#define EMPHPVAR s"user_trueHealth"

// Typedefs
typedef struct MonsterInfo_t MonsterInfo_t;

// Structs
struct MonsterInfo_t {
    MonsterInfo_t *next;        // Pointer to the next monster
    bool removed;               // This is true if the monster actor was removed

    // Physics and movement
    accum    x,    y,    z;     // XYZ coordinates
    accum velX, velY, velZ;     // XYZ velocities
    accum angle;                // Angle
    accum pitch;                // Pitch
    accum floorZ, ceilZ;        // Sector Z coordinates

    // Health and stuff
    int health, maxHealth;      // Health and max health
    int tid;                    // The monster's TID
};

extern MonsterInfo_t *monsterList;

// Prototypes
bool AddMonsterToList  (MonsterInfo_t *monster);
void UpdateMonsterInfo (MonsterInfo_t *self);

#endif