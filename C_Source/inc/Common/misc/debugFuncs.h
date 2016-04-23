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

#ifndef DEBUGFUNCS_H
#define DEBUGFUNCS_H

#include <ACS_ZDoom.h>

#ifdef DEBUG
#define DebugMsg(...) Log_Str (s"%S\n\CgFunction %s, file %s, line %i.", StrParam_Str (__VA_ARGS__), __func__, __FILE__, __LINE__)
#else
#define DebugMsg(...) ( )
#endif

#endif