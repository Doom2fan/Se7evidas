/* Keycard credits:
** Coding: Chronos "phantombeta" Ouroboros
** Sprites: Blue Shadow
*/

class S7_KeycardReplacerBase : key {
    default {
        scale 0.3;
    }

    override bool TryPickup (in out Actor toucher) {
        if (toucher.CheckInventory (GetClass (), 1))
            return false;

        bool ret;

        if (ret = Super.TryPickup (toucher))
            toucher.A_SpawnItemEx (GetClass (), 0.0, 0.0, 0.0 + 25.0, 3.5, 0.0, 2.8, 0, SXF_NoCheckPosition);

        return ret;
    }
}

//-------------------------------------------------------------------------------------------
//
// Red keycard
//
//-------------------------------------------------------------------------------------------
class S7_RedKeycard : S7_KeycardReplacerBase replaces redCard {
    default {
        inventory.pickupMessage "$REDKEY";
        species "redCard";
    }

    states {
    Spawn:
        S7KR A -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Blue keycard
//
//-------------------------------------------------------------------------------------------
class S7_BlueKeycard : S7_KeycardReplacerBase replaces blueCard {
    default {
        inventory.pickupMessage "$BLUEKEY";
        species "blueCard";
    }

    states {
    Spawn:
        S7KB A -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Yellow keycard
//
//-------------------------------------------------------------------------------------------
class S7_YellowKeycard : S7_KeycardReplacerBase replaces yellowCard {
    default {
        inventory.pickupMessage "$YELLOWKEY";
        species "yellowCard";
    }

    states {
    Spawn:
        S7KY A -1;
        stop;
    }
}