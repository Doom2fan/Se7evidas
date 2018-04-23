/* Base item for healing items */
class S7_HealingItem : Inventory {
    int healAmount;
    property HealAmount: healAmount;

    override bool Use (bool pickup) {
        let pPawn = S7_BasePlayer (Owner);

        return pPawn.GiveHealing (healAmount);
    }
}

/* Base "weapon" for healing items */
class S7_HealWeap : S7_NullWeapon {
    meta int maxUses;
    property MaxUses: maxUses;

    meta class<Inventory> healItem;
    property HealItem: healItem;
    meta int healItemAmount;
    property HealItemAmount: healItemAmount;

    meta int healTime;
    property HealTime: healTime;
    meta int healAmount;
    property HealAmount: healAmount;

    default {
        S7_HealWeap.MaxUses 1; // Just to provide sane defaults

        S7_HealWeap.HealItem "";
        S7_HealWeap.HealItemAmount 1;

        S7_HealWeap.HealTime 1;
        S7_HealWeap.HealAmount 1;

        +INVENTORY.UNDROPPABLE
    }

    override bool Use (bool pickup) {
        return !pickup ? Weapon.Use (false) : false;
    }

    virtual bool CanHeal () {
        let pPawn = S7_BasePlayer (Owner);

        return (
            (pPawn && pPawn.CanGiveHealing ()) &&
            usesLeft > 0
        );
    }

    virtual bool IsPrepared () {
        return true;
    }

    virtual bool DoHealing () {
        let pPawn = S7_BasePlayer (Owner);

        if (pPawn && pPawn.CanGiveHealing ()) {
            pPawn.GiveHealing (healAmount);
            return true;
        }

        return false;
    }

    int usesLeft;
    int healProgress;

    states {
    Ready:
        TNT1 A 0 { return ResolveState ("Ready2"); }
    Ready2:
        TNT1 A 1 {
            invoker.healProgress = -1;

            if (CheckInventory ("S7_DoMelee", 1))
                return ResolveState ("QuickMelee");
            TakeInventory ("S7_Reloading", 0x7FFFFFFF);
            TakeInventory ("S7_ChangeFireMode", 0x7FFFFFFF);

            A_ClearRefire ();
            A_WeaponReady ();

            return ResolveState (null);
        }
        loop;

    Fire:
        TNT1 A 1 {
            let pPawn = S7_BasePlayer (self);

            if (invoker.usesLeft <= 0 && CheckInventory (invoker.healItem, invoker.healItemAmount)) {
                TakeInventory (invoker.healItem, invoker.healItemAmount);
                invoker.usesLeft = invoker.maxUses;
            }

            if (invoker.CanHeal ())
                invoker.healProgress = -1;
            else
                return ResolveState ("Ready2");            

            return ResolveState (null);
        }
        TNT1 A 0 { A_Refire ("Prepare"); }
        TNT1 A 0 { return ResolveState ("Ready2"); }
        wait;
    Prepare:
        TNT1 A 1 {
            if (invoker.IsPrepared ())
                return ResolveState ("Heal");

            return ResolveState (null);
        }
        TNT1 A 0 { A_Refire ("Prepare"); }
        TNT1 A 0 { return ResolveState ("Ready2"); }
        wait;
    Heal:
        TNT1 A 1 {
            let pPawn = S7_BasePlayer (self);

            if (pPawn) {
                if (invoker.healProgress >= invoker.healTime) {
                    if (invoker.DoHealing ()) {
                        invoker.usesLeft--;
                        invoker.healProgress = -1;
                    }

                    A_ClearRefire ();
                    return ResolveState ("Ready2");
                }

                invoker.healProgress++;
            }

            return ResolveState (null);
        }
        TNT1 A 0 { A_Refire ("Heal"); }
        TNT1 A 0 {
            invoker.healProgress = -1;
            return ResolveState ("Ready2");
        }
        wait;
    }
}

class S7_HealWeapItem : Inventory {
    class<Weapon> healWeap;
    property HealWeap: healWeap;

    override bool Use (bool pickup) {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn)
            return false;

        let applicator = pPawn.FindInventory (healWeap);
        if (!applicator) {
            pPawn.GiveInventory (healWeap, 1);
            applicator = pPawn.FindInventory (healWeap);
        }

        if (applicator)
            pPawn.player.PendingWeapon = Weapon (applicator);

        return false;
    }
}

//-------------------------------------------------------------------------------------------
//
// Medikit
//
//-------------------------------------------------------------------------------------------
class S7_Medikit : S7_HealWeapItem replaces Medikit {
    default {
        Tag "Medikit";

        S7_HealWeapItem.HealWeap "S7_MedikitApplicator";
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

class S7_MedikitApplicator : S7_HealWeap {
    default {
        S7_HealWeap.MaxUses 2;

        S7_HealWeap.HealItem "S7_Medikit";
        S7_HealWeap.HealItemAmount 1;

        S7_HealWeap.HealTime 2 * 35; // 2 seconds
        S7_HealWeap.HealAmount 23;
    }

    override bool IsPrepared () {
        if (Owner.pitch >= 80)
            return true;
        else {
            Owner.A_SetPitch (Owner.pitch + 8, SPF_Interpolate);
            return false;
        }
    }
}

//-------------------------------------------------------------------------------------------
//
// Stimpack
//
//-------------------------------------------------------------------------------------------
class S7_Stimpack : S7_HealWeapItem replaces Stimpack {
    default {
        Tag "Stimpack";

        S7_HealWeapItem.HealWeap "S7_StimpackApplicator";
        Inventory.MaxAmount 8;
        Inventory.InterHubAmount 8;
        Inventory.PickupMessage "$GOTSTIM";
        Inventory.Icon "ARTISTIM";

        +INVENTORY.INVBAR
    }

    states {
    Spawn:
        STIM A -1;
        stop;
    }
}

class S7_StimpackApplicator : S7_HealWeap {
    default {
        S7_HealWeap.MaxUses 1;

        S7_HealWeap.HealItem "S7_Stimpack";
        S7_HealWeap.HealItemAmount 1;

        S7_HealWeap.HealTime 17;
        S7_HealWeap.HealAmount 20;
    }

    override bool CanHeal () {
        return (usesLeft > 0);
    }

    override bool IsPrepared () {
        if (Owner.pitch >= 45)
            return true;
        else {
            Owner.A_SetPitch (Owner.pitch + 8, SPF_Interpolate);
            return false;
        }
    }

    override bool DoHealing () {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys || !pPawn.CanGiveHealing (false))
            return false;

        let regenMod = new ("S7_Stimpack_FasterRegen");

        if (!pPawn.xpSys.AddStatMod (regenMod)) {
            regenMod.Destroy ();
            return false;
        }

        pPawn.GiveHealing (healAmount);

        return true;
    }
}

class S7_Stimpack_FasterRegen : S7_StatModifier {
    override bool Init (actor act, S7_XPSystem xpSys) {
        self.ticsLeft = 35 * 45;
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