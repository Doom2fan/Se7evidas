/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

/* Credits:
** Sprites: Eriance
*/
class S7_HeartSphere : Inventory { // I am not good at naming things
    double maxHealFactor;
    property MaxHealFactor: maxHealFactor;

    default {
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$HEARTSPHERE_PICKUP";
        S7_HeartSphere.MaxHealFactor 1.5;

        +INVENTORY.AUTOACTIVATE +INVENTORY.ALWAYSPICKUP +INVENTORY.FANCYPICKUPSOUND +COUNTITEM
    }

    override bool TryPickup (in out Actor toucher) {
        bool alwaysPickup = false;

        if (toucher && toucher.player) {
            CVar alwaysPickupCVar = CVar.GetCVar ("S7_AlwaysPickupHealthSpheres", toucher.player);
            alwaysPickup = alwaysPickupCVar.GetInt ();
        }

        if (!alwaysPickup) {
            let pPawn = PlayerPawn (toucher);
            if (pPawn && pPawn.health >= (pPawn.GetMaxHealth () * maxHealFactor)) {
                bAlwaysPickup = false;
                return false;
            }
        }

        bAlwaysPickup = true;
        return Super.TryPickup (toucher);
    }

    override bool Use (bool pickup) {
        let pPawn = PlayerPawn (Owner);
        if (!pPawn)
            return true;

        int maxHealth = pPawn.GetMaxHealth ();
        pPawn.GiveBody (maxHealth, int (maxHealth * maxHealFactor));
        
        return true;
    }

    states {
    Spawn:
        SPWR A   23 bright;
        SPWR BCD  4 bright;
        loop;
    }
}

/* Credits:
** Sprites: Eriance
*/
class S7_SoulSphere : S7_HeartSphere {
    default {
        Inventory.PickupMessage "$SOULSPHERE_PICKUP";
        S7_HeartSphere.MaxHealFactor 2.;
    }

    override bool Use (bool pickup) {
        Super.Use (pickup);

        Owner.GiveInventory ("S7_ArmorBonus", random [invSpc] (25, 35));
        let armor = S7_BasicArmor (Owner.FindInventory ("S7_BasicArmor"));
        if (armor && armor.armorData)
            armor.armorData.FixArmor (armor, 0x7FFFFFFF);
        
        return true;
    }

    states {
    Spawn:
        SPWR EFGH 4 bright;
        loop;
    }
}