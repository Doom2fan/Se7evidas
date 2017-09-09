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

#ifndef WEAP_DATA_H
#define WEAP_DATA_H

#include <ACS_ZDoom.h>

typedef struct S7_HW_2ModeWpn {
    string weap;
    string token;
    string state1;
    string state2;
    string showToken;
    bool stMode;
} S7_HW_2ModeWpn;

extern const string WeaponNames [];
extern const int WeaponNames_Length;

extern const string ClipNames [];
extern const int ClipNames_Length;

extern const string AmmoNames [];
extern const int AmmoNames_Length;

#endif