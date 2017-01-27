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

#include "includes.h"
#include "common/vectors.h"

#define int_Vec2VecOps(prefix, type, op) \
vec2##prefix tmp = lhs; \
tmp.x op##= rhs.x; \
tmp.y op##= rhs.y; \
return tmp;
#define int_Vec2Ops(prefix, type, op) \
vec2##prefix tmp = lhs; \
tmp.x op##= rhs; \
tmp.y op##= rhs; \
return tmp;

#define int_Vec3VecOps(prefix, type, op) \
vec3##prefix tmp = lhs; \
tmp.x op##= rhs.x; \
tmp.y op##= rhs.y; \
tmp.z op##= rhs.z; \
return tmp;
#define int_Vec3Ops(prefix, type, op) \
vec3##prefix tmp = lhs; \
tmp.x op##= rhs; \
tmp.y op##= rhs; \
tmp.z op##= rhs; \
return tmp;

#define int_DefVecVecOps(prefix, vecPrefix, type, num) \
vec##num##vecPrefix Vec##num##prefix##_VecAdd (vec##num##vecPrefix lhs, vec##num##vecPrefix rhs) { int_Vec##num##VecOps (vecPrefix, type, +); } \
vec##num##vecPrefix Vec##num##prefix##_VecSub (vec##num##vecPrefix lhs, vec##num##vecPrefix rhs) { int_Vec##num##VecOps (vecPrefix, type, -); } \
vec##num##vecPrefix Vec##num##prefix##_VecMul (vec##num##vecPrefix lhs, vec##num##vecPrefix rhs) { int_Vec##num##VecOps (vecPrefix, type, *); } \
vec##num##vecPrefix Vec##num##prefix##_VecDiv (vec##num##vecPrefix lhs, vec##num##vecPrefix rhs) { int_Vec##num##VecOps (vecPrefix, type, /); }
#define int_DefVecOps(prefix, vecPrefix, type, num) \
vec##num##vecPrefix Vec##num##prefix##_Add (vec##num##vecPrefix lhs, type rhs) { int_Vec##num##Ops (vecPrefix, type, +); } \
vec##num##vecPrefix Vec##num##prefix##_Sub (vec##num##vecPrefix lhs, type rhs) { int_Vec##num##Ops (vecPrefix, type, -); } \
vec##num##vecPrefix Vec##num##prefix##_Mul (vec##num##vecPrefix lhs, type rhs) { int_Vec##num##Ops (vecPrefix, type, *); } \
vec##num##vecPrefix Vec##num##prefix##_Div (vec##num##vecPrefix lhs, type rhs) { int_Vec##num##Ops (vecPrefix, type, /); }

#define int_DefVecOpsAll(prefix, vecPrefix, type) \
int_DefVecVecOps (prefix,vecPrefix,type,2); \
int_DefVecOps    (prefix,vecPrefix,type,2); \
int_DefVecVecOps (prefix,vecPrefix,type,3); \
int_DefVecOps    (prefix,vecPrefix,type,3);

int_DefVecOpsAll (F,_f,float);
int_DefVecOpsAll (D,_d,double);
int_DefVecOpsAll (I,_i,int);
int_DefVecOpsAll (K,_k,accum);