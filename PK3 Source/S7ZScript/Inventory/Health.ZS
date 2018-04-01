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
class S7_Medikit : S7_HealingItem replaces Medikit {
    default {
        Tag "Medikit";

        S7_HealingItem.healAmount 45;
        Inventory.MaxAmount 4;
        Inventory.InterHubAmount 4;
        Inventory.PickupMessage "$GOTMEDIKIT";
        Inventory.Icon "ARTIMEDI";

        +INVENTORY.INVBAR
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
class S7_Stimpack : S7_HealingItem replaces Stimpack {
    default {
        Tag "Stimpack";

        S7_HealingItem.HealAmount 20;
        Inventory.MaxAmount 8;
        Inventory.InterHubAmount 8;
        Inventory.PickupMessage "$GOTSTIM";
        Inventory.Icon "ARTISTIM";

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys || pPawn.health <= 0)
            return false;

        let regenMod = new ("S7_Stimpack_FasterRegen");

        if (!pPawn.xpSys.AddStatMod (regenMod))
            return false;

        if (!Super.Use (pickup)) {
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
        Tag "$CANTEEN";
        Inventory.MaxAmount 2000;
        inventory.interHubAmount 2000;
        Inventory.PickupMessage "$CANTEEN";
        Inventory.Icon "ARTICANT";

        +INVENTORY.INVBAR +INVENTORY.UNDROPPABLE +INVENTORY.KEEPDEPLETED +INVENTORY.UNTOSSABLE
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

/* Credits:
** Sprites: Raven Software, amv2k9, Chronos "phantombeta" Ouroboros
*/
class S7_CanteenRefill : Inventory replaces HealthBonus {
    default {
        Inventory.Amount 5;
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$GOTHTHBONUS";
        Scale 0.5;

        +COUNTITEM
    }

    override void PostBeginPlay () {
        Amount = random [S7_Inventory] (3, 8);
    }

    override bool TryPickup (in out Actor toucher) {
        let canteen = toucher.FindInventory ("S7_Canteen");

        if (!canteen) {
            toucher.GiveInventory ("S7_Canteen", 1);
            toucher.TakeInventory ("S7_Canteen", 0x7FFFFFFF);
            canteen = toucher.FindInventory ("S7_Canteen");
        }

        if (canteen.Amount < canteen.MaxAmount) {
            toucher.GiveInventory ("S7_Canteen", Amount);
            GoAwayAndDie();
            return true;
        }

        return false;
    }

    states {
    Spawn:
        BON1 A     8;
        BON1 BCDEF 1;
        BON1 G     4;
        BON1 FEDCB 1;
        loop;
    }
}