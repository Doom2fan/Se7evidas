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

//-------------------------------------------------------------------------------------------
//
// Armor bonus
//
//-------------------------------------------------------------------------------------------
/* Credits:
**  Sprites: id Software, Chronos "phantombeta" Ouroboros
**  Brightmaps: Chronos "phantombeta" Ouroboros
*/
class S7_ArmorBonus : Inventory {
    default {
        Inventory.Amount 4;
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$S7_ARMORBONUS";

        Tag "$S7_ARMORBONUS";
    }

    override void PostBeginPlay () {
        amount = random [invItems] (3, 5);
    }

    override bool TryPickup (in out Actor toucher) {
        let basicArmor = S7_BasicArmor (toucher.FindInventory ('S7_BasicArmor'));

        if (basicArmor && basicArmor.armorData && basicArmor.ArmorType != 'None') {
            basicArmor.armorData.armorBonuses += amount;
            basicArmor.armorData.GotBonus (basicArmor, amount);

            GoAwayAndDie();

            return true;
        }

        return false;
    }

    states {
    Spawn:
        BON2 A  9;
        BON2 BC 3 bright;
        BON2 D  9 bright;
        BON2 CB 3 bright;
        loop;
    }
}

/* Credits:
**  Sprites: id Software, Chronos "phantombeta" Ouroboros
**  Brightmaps: Chronos "phantombeta" Ouroboros
*/
class S7_LargeArmorBonus : S7_ArmorBonus {
    default {
        Inventory.Amount 7;
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$S7_LARGEARMORBONUS";

        Tag "$S7_LARGEARMORBONUS";
    }

    override void PostBeginPlay () {
        amount = random [invItems] (7, 8);
    }

    states {
    Spawn:
        BON3 A  9;
        BON3 BC 3 bright;
        BON3 D  9 bright;
        BON3 CB 3 bright;
        loop;
    }
}