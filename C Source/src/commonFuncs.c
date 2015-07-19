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

#include "util.h"
#include "util_math.h"
#include "commonFuncs.h"
#undef ACS_SHORT_NAMES

int KeyUp (int key) {
    int buttons = ACS_GetPlayerInput (-1, INPUT_BUTTONS);

    if (~buttons & key)
        return 1;
    
    return 0;
}

int KeyDown (int key) {
    int buttons = ACS_GetPlayerInput (-1, INPUT_BUTTONS);

    if (buttons & key)
        return 1;
    
    return 0;
}

int KeyPressed (int key) {
    int buttons     = ACS_GetPlayerInput (-1, INPUT_BUTTONS);
    int oldbuttons  = ACS_GetPlayerInput (-1, INPUT_OLDBUTTONS);
    int newbuttons  = (buttons ^ oldbuttons) & buttons;

    if (newbuttons & key)
        return 1;
    
    return 0;
}

int UnusedTID (int start, int end) {
    int ret = start - 1;
    int tidNum;
    if (start > end) {
        start ^= end;
        end ^= start;
        start ^= end;
    } // good ol' XOR swap
    while (ret++ != end) {
        if (ACS_ThingCount (0, ret) == 0)
            return ret;
    }
    
    return -1;
}