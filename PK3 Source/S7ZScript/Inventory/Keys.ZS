/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Keycard credits:
** Coding: Chronos "phantombeta" Ouroboros
** Sprites: Blue Shadow
*/

class S7_KeycardReplacerBase : Key {
    default {
        Scale 0.3;
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
class S7_RedKeycard : S7_KeycardReplacerBase replaces RedCard {
    default {
        Inventory.PickupMessage "$REDKEY";
        Species 'RedCard';
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
class S7_BlueKeycard : S7_KeycardReplacerBase replaces BlueCard {
    default {
        Inventory.PickupMessage "$BLUEKEY";
        Species 'BlueCard';
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
class S7_YellowKeycard : S7_KeycardReplacerBase replaces YellowCard {
    default {
        Inventory.PickupMessage "$YELLOWKEY";
        Species 'YellowCard';
    }

    states {
    Spawn:
        S7KY A -1;
        stop;
    }
}