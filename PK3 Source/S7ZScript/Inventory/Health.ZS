//-------------------------------------------------------------------------------------------
//
// Medikit
//
//-------------------------------------------------------------------------------------------
class S7_Medikit : customInventory replaces medikit {
    default {
        tag "Medikit";
        inventory.maxAmount 4;
        inventory.interHubAmount 4;
        inventory.pickupMessage "$GOTMEDIKIT";
        inventory.icon "ARTIMEDI";

        +inventory.invBar
    }

    states {
    Spawn:
        MEDI A -1;
        stop;
    Use:
        TNT1 A 0 A_JumpIf (health >= callACS ("S7_GetMaxHealth"), "Failed");
        TNT1 A 0 ACS_NamedExecuteAlways ("S7_MedikitScript");
        stop;
    Failed:
        TNT1 A 0;
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Stimpack
//
//-------------------------------------------------------------------------------------------
class S7_Stimpack : customInventory replaces stimpack {
    default {
        tag "Stimpack";
        inventory.maxAmount 8;
        inventory.interHubAmount 8;
        inventory.pickupMessage "$GOTSTIM";
        inventory.icon "ARTISTIM";

        +inventory.invBar
    }

    states {
    Spawn:
        STIM A -1;
        stop;
    Use:
        TNT1 A 0 A_JumpIf (health >= callACS ("S7_GetMaxHealth"), "Failed");
        TNT1 A 0 ACS_NamedExecuteAlways ("S7_StimpackScript");
        stop;
    Failed:
        TNT1 A 0;
        fail;
    }
}

//-------------------------------------------------------------------------------------------
//
// Canteen
//
//-------------------------------------------------------------------------------------------
class S7_Canteen : Inventory {
    default {
        tag "$CANTEEN";
        inventory.maxAmount 2000;
        inventory.interHubAmount 2000;
        inventory.pickupMessage "$CANTEEN";
        inventory.icon "ARTICANT";

        +inventory.invBar +inventory.undroppable +inventory.keepDepleted +inventory.untossable
    }

    override bool Use (bool pickup) {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || pPawn.health <= 0)
            return false;

        if (pPawn.health >= pPawn.maxHealth || Amount < pPawn.playerData.milkUseRate)
            return false;

        while (pPawn.health < pPawn.maxHealth && Amount >= pPawn.playerData.milkUseRate) {
            pPawn.GiveBody (pPawn.playerData.milkRegenRate, 0);
            Amount -= pPawn.playerData.milkUseRate;
        }

        pPawn.A_SetBlend ("00 28 78", 0.5, 14);
        pPawn.A_PlaySound ("Inventory/CanteenUse", CHAN_ITEM);

        return false;
    }

    states {
    Spawn:
        CANT A -1;
        stop;
    }
}