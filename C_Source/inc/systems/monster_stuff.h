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

#ifndef MSTUFF_H
#define MSTUFF_H

#include <ACS_ZDoom.h>

// Tokens
#define EMPIDENT s"S7_IsEmpress"

// Typedefs
typedef struct MonsterInfo_t MonsterInfo_t;

// Structs
struct MonsterInfo_t {
    MonsterInfo_t *next;        // Pointer to the next monster
    bool removed;               // This is true if the monster actor was removed

    // Physics and movement
    accum x, y, z;              // XYZ coordinates
    accum radius, height;       // Sizes (Radius and height)
    accum velX, velY, velZ;     // XYZ velocities
    accum angle, pitch;         // Rotations (Angle and pitch)
    accum floorZ, ceilZ;        // Sector Z coordinates

    // Health and stuff
    int health, maxHealth;      // Health and max health
    int tid;                    // The monster's TID

    // Flags
    bool friendly;              // The monster's friendliness
    bool boss;                  // Is the monster any kind of boss? (0: Not a boss, (normal monsters) 1: Miniboss, (Corpulents, etc.) 2: Boss, (Empress, Terminators, etc.) 3: Megaboss)
};

extern MonsterInfo_t *monsterList;

// Prototypes
void ClearMonsterList ();
bool AddMonsterToList  (MonsterInfo_t *monster);
void UpdateMonsterInfo (MonsterInfo_t *self);

#endif