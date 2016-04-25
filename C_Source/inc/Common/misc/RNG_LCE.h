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

#ifndef RNG_LCE_H
#define RNG_LCE_H

#include <ACS_ZDoom.h>

// Macros

// Structs
typedef struct _LCE_t {
    unsigned int mul; // a
    unsigned int inc; // c
    unsigned int mod; // m

    unsigned int min;
    unsigned int max;

    unsigned int _x;
} LCE_t;

// Prototypes
void _LCE_Init (LCE_t *r, unsigned int mul, unsigned int inc, unsigned int mod);
void _LCE_Seed (LCE_t *r, unsigned int x0);
void _LCE_PopFront (LCE_t *r);
void _LCE_Front (LCE_t *r);
accum _LCE_Uniform (LCE_t *r, accum a, accum b);
float _LCE_UniformF (LCE_t *r, float a, float b);
double _LCE_UniformD (LCE_t *r, double a, double b);

#endif