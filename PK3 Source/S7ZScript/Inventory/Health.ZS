class S7_HealingItem : Inventory {
    int healAmount;
    property HealAmount: healAmount;

    override bool Use (bool pickup) {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.healSys || !pPawn.xpSys)
            return false; // Return false if anything is invalid
        if (pPawn.health <= 0 || pPawn.health >= pPawn.GetMaxHealth ())
            return false; // Return false if the player is dead or at max health

        pPawn.healSys.regenPoints += healAmount * (1 + (pPawn.xpSys.GetStat (S7Stat_Vitality) / 5));

        return true;
    }
}

//-------------------------------------------------------------------------------------------
//
// Medikit
//
//-------------------------------------------------------------------------------------------
class S7_Medikit : S7_HealingItem replaces medikit {
    default {
        tag "Medikit";

        S7_HealingItem.healAmount 45;
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
    }
}

//-------------------------------------------------------------------------------------------
//
// Stimpack
//
//-------------------------------------------------------------------------------------------
class S7_Stimpack : S7_HealingItem replaces stimpack {
    default {
        tag "Stimpack";

        S7_HealingItem.healAmount 20;
        inventory.maxAmount 8;
        inventory.interHubAmount 8;
        inventory.pickupMessage "$GOTSTIM";
        inventory.icon "ARTISTIM";

        +inventory.invBar
    }

    override bool Use (bool pickup) {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys || pPawn.health <= 0)
            return false;

        let regenMod = new ("S7_Stimpack_FasterRegen");

        if (!pPawn.xpSys.AddStatMod (regenMod))
            return false;

        if (!super.Use (pickup)) {
            pPawn.xpSys.RemoveStatMod (regenMod);
            return false;
        }

        return true;
    }

    states {
    Spawn:
        STIM A -1;
        stop;
    }
}
class S7_Stimpack_FasterRegen : S7_StatModifier {
    override bool Init (actor act, S7_XPSystem xpSys) {
        self.ticsLeft = 35 * 30;
        self.stats = S7Stat_Special;
        self.specialStatName = "regenRate";
        self.factor = 0.75;

        return true;
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