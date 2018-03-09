//-------------------------------------------------------------------------------------------
//
// Used 50mm grenade
//
//-------------------------------------------------------------------------------------------
class S7_Thumper_Used : S7_Counter {
    default {
        Inventory.Amount 1;
        //Inventory.Icon "EMPT50MM";
        Inventory.PickupMessage "$EMPTTHGRPICK";
        Tag "$EMPTTHGR";
        Scale 0.8;

        +INVENTORY.IGNORESKILL
    }

    states {
    Spawn:
        THGR B -1;
        stop;
    }
}