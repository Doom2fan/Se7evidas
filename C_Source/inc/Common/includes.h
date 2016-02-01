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

#ifndef INCLUDES_H
#define INCLUDES_H

#include "util.h"
#include "util_math.h"
#include "commonFuncs.h"
#ifndef SERVER_C
#include "server.h"
#endif
#ifndef PLAYER_C
#include "player.h"
#endif


// Defines
#define PLN PlayerNumber()

// Script types
#define UNLOADING [[script ("Unloading") ]]
#define RETURN [[script ("Return") ]]
#define RESPAWN [[script ("Respawn") ]]

// Macros
#define SetInventory(name, amount) \
  ( \
   TakeInventory (name, 0x7FFFFFFF), \
   GiveInventory (name, amount) \
  )

#define ArraySize(array) sizeof(array) / sizeof(*array)

__addrdef extern  __gbl_arr GlobalVar;

#endif