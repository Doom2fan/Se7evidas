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

#ifndef TYPES_H
#define TYPES_H

#include <ACS_ZDoom.h>

// Typedefs
typedef struct vec2_i vec2_i;
typedef struct vec3_i vec3_i;
typedef struct vec4_i vec4_i;
typedef struct vec5_i vec5_i;

typedef struct vec2_k vec2_k;
typedef struct vec3_k vec3_k;
typedef struct vec4_k vec4_k;
typedef struct vec5_k vec5_k;

// Structs
struct vec2_i { int x, y; };
struct vec3_i { int x, y, z; };
struct vec4_i { int x, y, z, w; };
struct vec5_i { int x, y, z, w, h; };

struct vec2_k { accum x, y; };
struct vec3_k { accum x, y, z; };
struct vec4_k { accum x, y, z, w; };
struct vec5_k { accum x, y, z, w, h; };

#endif