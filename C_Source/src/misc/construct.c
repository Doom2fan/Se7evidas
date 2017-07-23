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
#include "misc/construct.h"

/*struct SavedData_t SavedData_t_new () {
    SavedData_t ret;

    ret.isInvalid = FALSE;
    ret.name = NULL;
    ret.gender = ret.cash = 0;

    ret.scriptData = PD_ScriptData_t_new ();

    return ret;
}*/

struct PD_ScriptData_t PD_ScriptData_t_new () {
    PD_ScriptData_t ret;

    return ret;
}