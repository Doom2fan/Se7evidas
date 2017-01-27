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

#ifndef VECTORS_H
#define VECTORS_H

#include <ACS_ZDoom.h>

// AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
#define int_DefVecTypes(prefix, type) \
typedef struct vec2##prefix { type x, y; } vec2##prefix; \
typedef struct vec3##prefix { type x, y, z; } vec3##prefix; \
typedef struct vec4##prefix { type x, y, z, w; } vec4##prefix; \
typedef struct vec5##prefix { type x, y, z, w, h; } vec5##prefix;

#define int_DefVecOpsPrototypesNum(prefix, vecPrefix, type, num) \
vec##num##vecPrefix Vec##num##prefix##_VecAdd (vec##num##vecPrefix lhs, vec##num##vecPrefix rhs); \
vec##num##vecPrefix Vec##num##prefix##_VecSub (vec##num##vecPrefix lhs, vec##num##vecPrefix rhs); \
vec##num##vecPrefix Vec##num##prefix##_VecMul (vec##num##vecPrefix lhs, vec##num##vecPrefix rhs); \
vec##num##vecPrefix Vec##num##prefix##_VecDiv (vec##num##vecPrefix lhs, vec##num##vecPrefix rhs); \
vec##num##vecPrefix Vec##num##prefix##_Add (vec##num##vecPrefix lhs, type rhs); \
vec##num##vecPrefix Vec##num##prefix##_Sub (vec##num##vecPrefix lhs, type rhs); \
vec##num##vecPrefix Vec##num##prefix##_Mul (vec##num##vecPrefix lhs, type rhs); \
vec##num##vecPrefix Vec##num##prefix##_Div (vec##num##vecPrefix lhs, type rhs);

#define int_DefVecOpsPrototypes(prefix, vecPrefix, type) \
int_DefVecOpsPrototypesNum (prefix,vecPrefix,type,2); \
int_DefVecOpsPrototypesNum (prefix,vecPrefix,type,3);

#define Vec2Length(vec, sqrt) (sqrt ((vec.x * vec.x) + (vec.y * vec.y)))
#define Vec2LengthSquared(vec) ((vec.x * vec.x) + (vec.y * vec.y))

#define Vec3Length(vec, sqrt) (sqrt ((vec.x * vec.x) + (vec.y * vec.y) + (vec.z * vec.z)))
#define Vec3LengthSquared(vec) ((vec.x * vec.x) + (vec.y * vec.y) + (vec.z * vec.z))

// Macros
// Float
#define Vec2F_Length(vec) Vec2Length (vec, sqrtf)
#define Vec2F_LengthSquared(vec) Vec2LengthSquared (vec)

#define Vec3F_Length(vec) Vec3Length (vec, sqrtf)
#define Vec3F_LengthSquared(vec) Vec3LengthSquared (vec)
// Double
#define Vec2D_Length(vec) Vec2Length (vec, sqrt)
#define Vec2D_LengthSquared(vec) Vec2LengthSquared (vec)

#define Vec3D_Length(vec) Vec3Length (vec, sqrt)
#define Vec3D_LengthSquared(vec) Vec3LengthSquared (vec)
// Int
#define Vec2I_Length(vec) Vec2Length (vec, ACS_Sqrt)
#define Vec2I_LengthSquared(vec) Vec2LengthSquared (vec)

#define Vec3I_Length(vec) Vec3Length (vec, ACS_Sqrt)
#define Vec3I_LengthSquared(vec) Vec3LengthSquared (vec)
// Accum. Vec*K_Length macros provided mostly for convenience and consistency.
#define Vec2K_Length(vec) (VectorLength (vec.x, vec.y))
#define Vec2K_LengthSquared(vec) Vec2LengthSquared (vec)

#define Vec3K_Length(vec) (VectorLength (vec.z, VectorLength (vec.x, vec.y)))
#define Vec3K_LengthSquared(vec) Vec3LengthSquared (vec)

// Defs
int_DefVecTypes (_f,float);  // vecX_f (float)
int_DefVecTypes (_d,double); // vecX_d (double)
int_DefVecTypes (_i,int);    // vecX_i (int)
int_DefVecTypes (_k,accum);  // vecX_k (accum)
// Prototypes
int_DefVecOpsPrototypes (F,_f,float); // The second argument can't have a space, because otherwise it'll break the macro.
int_DefVecOpsPrototypes (D,_d,double);
int_DefVecOpsPrototypes (I,_i,int);
int_DefVecOpsPrototypes (K,_k,accum);

#undef int_DefVecTypes
#undef int_DefVecOpsPrototypesNum
#undef int_DefVecOpsPrototypes

#endif