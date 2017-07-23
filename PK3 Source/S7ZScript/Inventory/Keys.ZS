/* Keycard credits:
** DECORATE: Chronos "phantombeta" Ouroboros
** Sprites: Blue Shadow
*/

class S7_KeycardReplacerBase : customInventory {
    default {
        scale 0.3;
        inventory.maxAmount 0;
    }

    states {
    GotIt:
        TNT1 A 0 A_RailWait;
        stop;
    Nope:
        TNT1 A 0 A_RailWait;
        fail;
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
    }

    states {
    Spawn:
        S7KR A -1;
        stop;

    Pickup:
        TNT1 A 0 A_JumpIfInventory ("redCard", 1, "Nope");
        TNT1 A 0 GiveInventory ("redCard", 1);
        TNT1 A 0 A_SpawnItemEx ("S7_RedKeycard", 0.0, 0.0, 25.0, 3.5, 0.0, 2.8, 0, SXF_NoCheckPosition);
        goto GotIt;
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
    }

    states {
    Spawn:
        S7KB A -1;
        stop;

    Pickup:
        TNT1 A 0 A_JumpIfInventory ("blueCard", 1, "Nope");
        TNT1 A 0 GiveInventory ("blueCard", 1);
        TNT1 A 0 A_SpawnItemEx ("S7_BlueKeycard", 0.0, 0.0, 25.0, 3.5, 0.0, 2.8, 0, SXF_NoCheckPosition);
        goto GotIt;
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
    }

    states {
    Spawn:
        S7KY A -1;
        stop;

    Pickup:
        TNT1 A 0 A_JumpIfInventory ("yellowCard", 1, "Nope");
        TNT1 A 0 GiveInventory ("yellowCard", 1);
        TNT1 A 0 A_SpawnItemEx ("S7_YellowKeycard", 0.0, 0.0, 25.0, 3.5, 0.0, 2.8, 0, SXF_NoCheckPosition);
        goto GotIt;
    }
}