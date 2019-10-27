/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2019 Chronos "phantombeta" Ouroboros
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

/* Credits:
 * Sprites by DoomNukem and Chronos "phantombeta" Ouroboros.
*/
class S7_ManxScope : Inventory {
    default {
        //$Category "Se7evidas/Weapon modifications"
        //$Color 19
        //$Title "Manx Carbine Scope"
        //$NotAngled

        Inventory.MaxAmount 50;
        Inventory.Icon "WMODA0";

        Tag "$WEAPMOD_MANXSCOPE";

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        if (!Owner)
            return false;

        let manx = S7_ManxCarbine (Owner.FindInventory ('S7_ManxCarbine'));
        if (!manx || manx.hasScope)
            return false;

        manx.hasScope = true;
        return true;
    }

    states {
    Spawn:
        WMOD A -1;
        stop;
    }
}

/* Credits:
 * Sprites by Vostyok.
*/
class S7_ManxSuppressor : Inventory {
    default {
        //$Category "Se7evidas/Weapon modifications"
        //$Color 19
        //$Title "Manx Carbine Suppressor"
        //$NotAngled

        Inventory.MaxAmount 50;
        Inventory.Icon "WMODB0";

        Tag "$WEAPMOD_MANXSUPPRESSOR";

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        if (!Owner)
            return false;

        let manx = S7_ManxCarbine (Owner.FindInventory ('S7_ManxCarbine'));
        if (!manx || manx.hasSuppressor)
            return false;

        manx.hasSuppressor = true;
        return true;
    }

    states {
    Spawn:
        WMOD B -1;
        stop;
    }
}

/* Credits:
 * Sprites by Vostyok.
*/
class S7_TEC9Suppressor : Inventory {
    default {
        //$Category "Se7evidas/Weapon modifications"
        //$Color 19
        //$Title "Kronos SMG Supressor"
        //$NotAngled

        Inventory.MaxAmount 50;
        Inventory.Icon "WMODC0";

        Tag "$WEAPMOD_TEC9SUPPRESSOR";

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        if (!Owner)
            return false;

        let tec9 = S7_TEC9 (Owner.FindInventory ('S7_TEC9'));
        if (!tec9 || tec9.hasSuppressor)
            return false;

        tec9.hasSuppressor = true;
        return true;
    }

    states {
    Spawn:
        WMOD C -1;
        stop;
    }
}