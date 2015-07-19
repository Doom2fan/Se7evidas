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