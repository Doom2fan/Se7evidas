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

#ifndef INCLUDES_H
#define INCLUDES_H

// Defines/Macros
#ifdef DEBUG
    #ifdef NDEBUG
        #undef NDEBUG
    #endif
#else
    #ifndef NDEBUG
        #define NDEBUG
    #endif
#endif

//#define GetUserCVar(num, cvar) CustGetUserCVar (num, cvar)
//#define GetUserCVarFixed(num, cvar) CustGetUserCVarFixed (num, cvar)
//#define GetUserCVarString(num, cvar) CustGetUserCVarString (num, cvar)
#define PLN PlayerNumber()
// The size is actually this minus the length of "<cvar name>="
#define MAXCVARSIZ 253

// ZDoom related defines
#define TICSINSEC  35.7142
#define TICSINSECA 35.7142k
#define BASE_GRAVITY 81.92k
#define BASE_GRAVITYF 81.92f

#define TICUNIT  0.028
#define TICUNITA 0.028k

#define Gender_Male  0
#define Gender_Fem   1
#define Gender_Other 2

#define M_PIk 3.141592653589793238462643383279502884k
#define M_PI_2k 1.570796326794896619231321691639751442k

// Script types
#define UNLOADING    [[script ("Unloading") ]]
#define RETURN       [[script ("Return") ]]
#define RESPAWN      [[script ("Respawn") ]]
#define IS_SCRIPT(n) [[address(n), call("SScriptI")]]
#define SS_SCRIPT    [[call("SScriptS")]]
#define ACS_SS_SCRIPT EXTACS SS_SCRIPT
#define Script_CS    ACS_SS_SCRIPT
#define Script_LS    SS_SCRIPT

// Actor names
#define DISABLEHUDTOKEN      s"S7_DisableHud"

// Includes
#include <float.h>
#include <assert.h>
#include "common/util.h"
#include "common/util_math.h"
#include "common/commonFuncs.h"
#include "misc/debugFuncs.h"
#ifndef SERVER_C
#include "common/server.h"
#endif
#ifndef PLAYER_C
#include "common/player.h"
#endif

// Typedefs
typedef char * cstr;

#endif