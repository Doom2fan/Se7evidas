//-------------------------------------------------------------------------------------------
//
// Used 50mm grenade
//
//-------------------------------------------------------------------------------------------
class S7_Thumper_Used : S7_Counter {
    default {
        inventory.amount 1;
        //inventory.icon "EMPT50MM";
        inventory.pickupMessage "$EMPTTHGRPICK";
        tag "$EMPTTHGR";
        scale 0.8;

        +inventory.ignoreSkill
    }

    states {
    Spawn:
        THGR B -1;
        stop;
    }
}