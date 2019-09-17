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
class S7_HealWeap : S7_BaseWeapon {
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

        S7_HealWeap.HealItem '';
        S7_HealWeap.HealItemAmount 1;

        S7_HealWeap.HealTime 1;
        S7_HealWeap.HealAmount 1;

        +INVENTORY.UNDROPPABLE
    }

    override void DoEffect () {
        Super.DoEffect ();

        if (healItem) {
            bInvBar = (!Owner.CheckInventory (healItem, 1) && usesLeft > 0);

            let healItemDef = GetDefaultByType (healItem);
            if (healItemDef)
                icon = GetDefaultByType (healItem).Icon;
        }
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

    virtual void StartHealing () { }

    virtual void DoingHealing () { }

    virtual bool DoHealing () {
        let pPawn = S7_BasePlayer (Owner);

        if (pPawn && pPawn.CanGiveHealing ()) {
            pPawn.GiveHealing (healAmount);
            return true;
        }

        return false;
    }

    virtual void CanceledHealing () { }

    int usesLeft;
    int healProgress;

    states {
    Ready:
        TNT1 A 0 { return ResolveState ("Ready2"); }
    Ready2:
        TNT1 A 1 {
            invoker.healProgress = -1;

            if (CheckInventory ('S7_DoMelee', 1))
                return ResolveState ("QuickMelee");
            TakeInventory ('S7_Reloading', 0x7FFFFFFF);
            TakeInventory ('S7_ChangeFireMode', 0x7FFFFFFF);

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
            if (invoker.IsPrepared ()) {
                invoker.StartHealing ();
                return ResolveState ("Heal");
            }

            return ResolveState (null);
        }
        TNT1 A 0 { A_Refire ("Prepare"); }
        TNT1 A 0 { return ResolveState ("Ready2"); }
        wait;
    Heal:
        TNT1 A 1 {
            let pPawn = S7_BasePlayer (self);

            if (pPawn) {
                invoker.DoingHealing ();
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
            invoker.CanceledHealing ();
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
/* Credits:
** Sprites: BloodyAcid
*/
class S7_Medikit : S7_HealWeapItem {
    default {
        Tag "$MEDIKIT";

        S7_HealWeapItem.HealWeap 'S7_MedikitApplicator';
        Inventory.MaxAmount 4;
        Inventory.InterHubAmount 4;
        Inventory.PickupMessage "$MEDIKIT";
        Inventory.Icon "MKITA0";

        +INVENTORY.INVBAR
    }

    states {
    Spawn:
        MKIT A -1;
        stop;
    }
}

class S7_MedikitApplicator : S7_HealWeap {
    default {
        S7_HealWeap.MaxUses 2;

        S7_HealWeap.HealItem 'S7_Medikit';
        S7_HealWeap.HealItemAmount 1;

        S7_HealWeap.HealTime floor (.75 * TICRATE); // .75 seconds
        S7_HealWeap.HealAmount 23;
    }

    void DoLockView () {
        lowerSpeed += S7_Math.DampedSpring (Owner.pitch, 65, lowerSpeed, .3, .85);
        Owner.A_SetPitch (Owner.pitch + lowerSpeed, SPF_Interpolate);
    }

    double lowerSpeed;
    override bool IsPrepared () {
        if (Owner.pitch >= 60)
            return true;
        else {
            DoLockView ();
            return false;
        }
    }

    override void StartHealing () {
        Owner.A_PlaySound ("S7Inventory/Medikit/Bandage", CHAN_7);
    }

    override void DoingHealing () {
        DoLockView ();
    }

    override bool DoHealing () {
        lowerSpeed = 0;

        let pPawn = S7_BasePlayer (Owner);

        if (pPawn && pPawn.CanGiveHealing ()) {
            pPawn.GiveHealing (healAmount);
            return true;
        }

        return false;
    }

    override void CanceledHealing () {
        Owner.A_StopSound (CHAN_7);
        lowerSpeed = 0;
    }
}

//-------------------------------------------------------------------------------------------
//
// Stimpack
//
//-------------------------------------------------------------------------------------------
/* Credits:
** Sprites: zrrion the insect, Chronos "phantombeta" Ouroboros
*/
class S7_Stimpack : S7_HealWeapItem {
    default {
        Tag "$STIMPACK";

        S7_HealWeapItem.HealWeap 'S7_StimpackApplicator';
        Inventory.MaxAmount 8;
        Inventory.InterHubAmount 8;
        Inventory.PickupMessage "$STIMPACK";
        Inventory.Icon "SPAKA0";

        +INVENTORY.INVBAR
    }

    states {
    Spawn:
        SPAK A -1;
        stop;
    }
}

class S7_StimpackApplicator : S7_HealWeap {
    default {
        S7_HealWeap.MaxUses 1;

        S7_HealWeap.HealItem 'S7_Stimpack';
        S7_HealWeap.HealItemAmount 1;

        S7_HealWeap.HealTime 5;
        S7_HealWeap.HealAmount 20;
    }

    override bool CanHeal () {
        return (usesLeft > 0);
    }

    double lowerSpeed;
    override bool IsPrepared () {
        if (Owner.pitch >= 48) {
            lowerSpeed = 0;
            return true;
        } else {
            lowerSpeed += S7_Math.DampedSpring (Owner.pitch, 50, lowerSpeed, .45, .9);
            Owner.A_SetPitch (Owner.pitch + lowerSpeed, SPF_Interpolate);
            return false;
        }
    }

    override bool DoHealing () {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || !pPawn.xpSys || !pPawn.CanGiveHealing (false))
            return false;

        let regenMod = S7_Stimpack_FasterRegen (pPawn.xpSys.GetStatModInstance ('S7_Stimpack_FasterRegen'));

        if (regenMod)
            regenMod.ticsLeft += max (TICRATE * 15, (TICRATE * 50) - regenMod.ticsLeft);
        else {
            regenMod = new ('S7_Stimpack_FasterRegen');

            if (!pPawn.xpSys.AddStatMod (regenMod)) {
                regenMod.Destroy ();
                return false;
            }
        }

        Owner.A_PlaySound ("S7Inventory/Stimpack/Apply", CHAN_7);
        pPawn.GiveHealing (healAmount);
        lowerSpeed = 0;

        return true;
    }
}

class S7_Stimpack_FasterRegen : S7_StatModifier {
    override bool Init (actor act, S7_XPSystem xpSys) {
        self.ticsLeft = TICRATE * 50;
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
        Inventory.Icon "graphics/Inventory/Canteen.png"; // Sprite by josh771

        +INVENTORY.INVBAR +INVENTORY.UNDROPPABLE +INVENTORY.KEEPDEPLETED +INVENTORY.UNTOSSABLE
    }

    override bool Use (bool pickup) {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn || pPawn.health <= 0 || pPawn.bKilled)
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
class S7_CanteenRefill : Inventory {
    default {
        Inventory.Amount 5;
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$GOTHTHBONUS";
        Scale 0.5;
    }

    override void PostBeginPlay () {
        Amount = random [S7_Inventory] (1, 6) * 15;
        scale.x = scale.y = (.35 + (double (Amount) / (6.*15.)) * .15);
    }

    override bool TryPickup (in out Actor toucher) {
        let canteen = toucher.FindInventory ('S7_Canteen');

        if (!canteen || canteen.Amount < canteen.MaxAmount) {
            toucher.GiveInventory ('S7_Canteen', Amount);
            GoAwayAndDie ();
            return true;
        }

        return false;
    }

    states {
    Spawn:
        BON1 A     8 bright;
        BON1 BCDEF 1 bright;
        BON1 G     4 bright;
        BON1 FEDCB 1 bright;
        loop;
    }
}