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
#include "misc/RNG_LCE.h"

/** Finish this later **/

void _LCE_Init (LCE_t *r, unsigned int mul, unsigned int inc, unsigned int mod) {
    r->mul = mul;
    r->inc = inc;
    r->mod = mod;

    r->min = (inc == 0 ? 1 : 0);
    r->max = mod - 1;

    r->_x = mod ? (mul + inc) % mod : (mul + inc);

    _LCE_Seed (r, 1);
}

void _LCE_Seed (LCE_t *r, unsigned int x0) {
    assert (r->inc == 0);

    r->_x = r->mod ? (x0 % r->mod) : x0;
    _LCE_PopFront (r);
}

void _LCE_PopFront (LCE_t *r) {
    if (r->mod) {
        if (r->mod == UINT_MAX) {
            unsigned long
                x = ((unsigned long) r->mul * r->_x + r->inc),
                v = x >> 32,
                w = x & UINT_MAX;
            unsigned int y = (unsigned int) (v + w);
            r->_x = (y < v || y == UINT_MAX) ? (y + 1) : y;
        } else if (r->mod == INT_MAX) {
            unsigned long
                x = (unsigned long) r->mul * r->_x + r->inc,
                v = x >> 31,
                w = x & INT_MAX;
            unsigned int y = (unsigned int) (v + w);
            r->_x = (y >= INT_MAX) ? (y - INT_MAX) : y;
        } else {
            r->_x = (unsigned int) (((unsigned long) r->mul * r->_x + r->inc) % r->mod);
        }
    } else {
        r->_x = r->mul * r->_x + r->inc;
    }
}

#define _LCE_UniformBase(type) \
    type min, max; \
    if (a <= b) { \
        min = a; max = b; \
    } else { \
        min = b; max = a; \
    } \
\
    type result = min + (max - min) * (type) (r->_x - r->min) / (r->max - r->min); \
    _LCE_PopFront (r); \
\
    return result

accum _LCE_Uniform (LCE_t *r, accum a, accum b) {
    _LCE_UniformBase (accum);
}

float _LCE_UniformF (LCE_t *r, float a, float b) {
    _LCE_UniformBase (float);
}

double _LCE_UniformD (LCE_t *r, double a, double b) {
    _LCE_UniformBase (double);
}