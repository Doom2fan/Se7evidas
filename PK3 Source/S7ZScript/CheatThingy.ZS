// To make testing and stuff easier
class S7_CheatThingy : customInventory {
    default {
        inventory.icon "TNT1A0";
        inventory.pickupMessage "";
        inventory.maxAmount 2;
        inventory.amount 1;
        inventory.pickupSound "";
        inventory.useSound "";

        +inventory.undroppable
        +inventory.autoActivate
        +inventory.alwaysPickup
    }

    states {
    Spawn:
        TNT1 A 0;
        stop;
    Use:
    Pickup: // Give things here
        TNT1 A 0 {
            GiveInventory ("S7_BackpackToken", 1);
            // Inventory
            GiveInventory ("S7_Berserk",  0x7FFFFFFF);
            GiveInventory ("S7_Medikit",  0x7FFFFFFF);
            GiveInventory ("S7_Stimpack", 0x7FFFFFFF);
            GiveInventory ("S7_Canteen",  0x7FFFFFFF);
            // Upgrades
            GiveInventory ("S7_UpgradeRadar", 1);
            GiveInventory ("S7_UpgradeSlot1", 1);
            GiveInventory ("S7_UpgradeSlot2", 1);
            GiveInventory ("S7_UpgradeSlot3", 1);
            GiveInventory ("S7_UpgradeSlot4", 1);
            GiveInventory ("S7_UpgradeSlot5", 1);
            // Cash
            GiveInventory ("S7_Cash", 0x7FFFFFFF);
            // Misc
            for (int i = 0; i < S7_WeapData.S7_WeaponNames.Size (); i++)
                GiveInventory (S7_WeapData.S7_WeaponNames [i], 0x7FFFFFFF);
            for (int i = 0; i < S7_WeapData.S7_ClipNames.Size (); i++)
                GiveInventory (S7_WeapData.S7_ClipNames [i], 0x7FFFFFFF);
            for (int i = 0; i < S7_WeapData.S7_AmmoNames.Size (); i++)
                GiveInventory (S7_WeapData.S7_AmmoNames [i], 0x7FFFFFFF);
        }
        stop;
    }
}