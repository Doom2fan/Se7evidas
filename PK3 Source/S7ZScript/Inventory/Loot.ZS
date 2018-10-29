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

class S7_LootItem : Inventory {
    int blocksUsed;
    property BlocksUsed: blocksUsed;

    default {
        Inventory.MaxAmount 0x7FFFFFFF;

        +INVENTORY.IGNORESKILL
        -INVENTORY.INVBAR
    }

    override bool CanPickup (Actor toucher) {
        if (!toucher)
            return false;

        if (!Super.CanPickup (toucher))
            return false;

        int usedBlocksCount = 0;

        for (let inv = toucher.inv; inv; inv = inv.inv) {
            if (!(inv is 'S7_LootItem'))
                continue;

            let lootItem = S7_LootItem (inv);

            if (!lootItem) // Uh, shouldn't have gotten here, but ok, whatever...
                continue;

            usedBlocksCount += lootItem.blocksUsed * lootItem.Amount;
        }

        return (usedBlocksCount + (blocksUsed * amount)) <= 200;
    }
}

//-------------------------------------------------------------------------------------------
//
// Used 50mm grenade
//
//-------------------------------------------------------------------------------------------
class S7_Thumper_Used : S7_LootItem {
    default {
        S7_LootItem.BlocksUsed 2;

        Inventory.Amount 1;
        //Inventory.Icon "EMPT50MM";
        Inventory.PickupMessage "$EMPTTHGRPICK";
        Tag "$EMPTTHGR";
        Scale 0.8;
    }

    states {
    Spawn:
        THGR B -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Dropped loot weapons
//
//-------------------------------------------------------------------------------------------
// Sprite credits: Amuscaria/Eriance
class S7_Loot_ScorpsHunterSG : S7_LootItem {
    default {
        S7_LootItem.BlocksUsed 15;

        Inventory.Amount 1;
        Inventory.Icon "LOT1A0";
        Inventory.PickupMessage "$LOOT_SCORPSHUNTERSG_PICKUP";
        Tag "$LOOT_SCORPSHUNTERSG";
    }

    int shellsCount;
    bool isBroken;

    override void PostBeginPlay () {
        if (shellsCount == 0)
            shellsCount = random [invSpc] (2, 8);
        else if (shellsCount == -1)
            shellsCount = 0;

        if (isBroken)
            amount = 0;
    }

    override bool TryPickup (in out Actor toucher) {
        bool ret;

        if (isBroken)
            amount = 0;

        if (ret = Super.TryPickup (toucher))
            toucher.GiveInventory ('S7_12gaShells', shellsCount);

        return ret;
    }

    override String PickupMessage () {
        Array<string> str;
        str.Clear ();

        StringTable.Localize (Super.PickupMessage ()).Split (str, ":");

        if (str.Size () != 2) // Just in case.
            return "Some fuckwit fucked up the LANGUAGE lump entry for \"LOOT_SCORPSHUNTERSG_PICKUP\".";

        if (shellsCount == 0)
            return str [0];

        if (isBroken)
            return String.Format (StringTable.Localize ("$LOOT_SCORPSHUNTERSG_PICKUP_BROKEN"), shellsCount);

        return str [0] .. " " .. String.Format (str [1], shellsCount);
    }

    states {
    Spawn:
        LOT1 A -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Artifacts
//
//-------------------------------------------------------------------------------------------
// Sprite credits: Id Software
class S7_Loot_SkullSceptre : S7_LootItem {
    default {
        S7_LootItem.BlocksUsed 10;

        Inventory.Amount 1;
        //Inventory.Icon "LOT1B0";
        Inventory.PickupMessage "$LOOT_SKULLSCEPTRE";
        Tag "$LOOT_SKULLSCEPTRE";
        Scale 1;
    }

    states {
    Spawn:
        LOT1 B -1;
        stop;
    }
}

// Sprite credits: Id Software
class S7_Loot_SacrificialDagger : S7_LootItem {
    default {
        S7_LootItem.BlocksUsed 6;

        Inventory.Amount 1;
        //Inventory.Icon "LOT1C0";
        Inventory.PickupMessage "$LOOT_SACRIFICEDAGGER";
        Tag "$LOOT_SACRIFICEDAGGER";
        Scale 1;
    }

    states {
    Spawn:
        LOT1 C -1;
        stop;
    }
}

// Sprite credits: Id Software
class S7_Loot_BloodChalice : S7_LootItem {
    default {
        S7_LootItem.BlocksUsed 4;

        Inventory.Amount 1;
        //Inventory.Icon "LOT1D0";
        Inventory.PickupMessage "$LOOT_BLOODCHALICE";
        Tag "$LOOT_BLOODCHALICE";
        Scale 1;
    }

    states {
    Spawn:
        LOT1 D -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Treasure
//
//-------------------------------------------------------------------------------------------
// Sprite credits: Id Software
class S7_Loot_GoldChest : S7_LootItem {
    default {
        S7_LootItem.BlocksUsed 25;

        Inventory.Amount 1;
        //Inventory.Icon "LOT1E0";
        Inventory.PickupMessage "$LOOT_GOLDCHEST";
        Tag "$LOOT_GOLDCHEST";
        Scale 1;
    }

    states {
    Spawn:
        LOT1 E -1;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Treasure
//
//-------------------------------------------------------------------------------------------
// Sprite credits: amv2k9
class S7_Loot_CreditsBriefcase10K : Inventory {
    default {
        Inventory.Amount 10000;
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$LOOT_CREDITSCASE_10K";
        Scale 1;

        +INVENTORY.ALWAYSPICKUP +INVENTORY.AUTOACTIVATE
    }

    override bool TryPickup (in out Actor toucher) {
        if (!toucher || toucher.CountInv ('S7_Cash') > 0x7FFFFFFF - Amount) {
            bAlwaysPickup = false;
            return false;
        }

        if (!Super.TryPickup (toucher)) {
            Console.printf ("aaa");
            bAlwaysPickup = false;
            return false;
        }

        return true;
    }

    override bool Use (bool pickup) {
        if (!Owner)
            return false;

        Owner.GiveInventory ('S7_Cash', Amount);
        bAlwaysPickup = true;

        return true;
    }

    states {
    Spawn:
        LOT1 F -1;
        stop;
    }
}

class S7_Loot_CreditsBriefcase5K : S7_Loot_CreditsBriefcase10K {
    default {
        Inventory.Amount 5000;
        Inventory.PickupMessage "$LOOT_CREDITSCASE_5K";
        Scale 0.65;
    }
}