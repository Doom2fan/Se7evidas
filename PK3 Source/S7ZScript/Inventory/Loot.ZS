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
            if (!(inv is "S7_LootItem"))
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
class S7_Loot_ScorpsHunterSG : S7_LootItem {
    default {
        S7_LootItem.BlocksUsed 15;

        Inventory.Amount 1;
        Inventory.Icon "LOT1A0";
        Inventory.PickupMessage "$LOOT_SCORPSHUNTERSG_PICKUP";
        Tag "$LOOT_SCORPSHUNTERSG";
    }

    int shellsCount;

    override void PostBeginPlay () {
        if (shellsCount == 0)
            shellsCount = random [invSpc] (2, 8);
        else if (shellsCount == -1)
            shellsCount = 0;
    }

    override bool TryPickup (in out Actor toucher) {
        bool ret;

        if (ret = Super.TryPickup (toucher))
            toucher.GiveInventory ("S7_12gaShells", shellsCount);

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

        return str [0] .. " " .. String.Format (str [1], shellsCount);
    }

    states {
    Spawn:
        LOT1 A -1;
        stop;
    }
}