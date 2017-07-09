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

#ifndef UDAMAGE_H
#define UDAMAGE_H

#include <ACS_ZDoom.h>

// Enums
typedef enum RDNB_Flags_t {
    RDNBF_FullDMGRadius = 1,
    RDNBF_IgnoreHeight  = 1 << 1,
    RDNBF_NoDMGThrust   = 1 << 2,
    RDNBF_DontHurtSrc   = 1 << 3,
    RDNBF_OldRDMGPure   = 1 << 4,
    RDNBF_OldRadiusDMG  = RDNBF_OldRDMGPure | RDNBF_IgnoreHeight | RDNBF_NoDMGThrust,
    RDNBF_ForceDMG      = 1 << 5,
} RDNB_Flags;

// Structs
typedef struct RadiusDMGNB_Data_t {
    vec3_k pos;
    int damage, radius;
    int inflictorTID;
    string damageType;
    RDNB_Flags flags;
} RadiusDMGNB_Data_t;

// Prototypes
//void RadiusDMGNoBlock (vec3_k pos, int damage, int radius, int inflictorTID, string damageType, RDNB_Flags flags);

#endif