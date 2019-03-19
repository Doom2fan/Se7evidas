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

// To make testing and stuff easier
class S7_CheatThingy : CustomInventory {
    default {
        Inventory.Icon "TNT1A0";
        Inventory.PickupMessage "";
        Inventory.MaxAmount 2;
        Inventory.Amount 1;
        Inventory.PickupSound "";
        Inventory.UseSound "";

        +INVENTORY.UNDROPPABLE +INVENTORY.AUTOACTIVATE +INVENTORY.ALWAYSPICKUP
    }

    states {
    Spawn:
        TNT1 A 0;
        stop;
    Use:
    Pickup: // Give things here
        TNT1 A 0 {
            GiveInventory ('S7_BackpackToken', 1);
            // Inventory
            GiveInventory ('S7_Berserk',  0x7FFFFFFF);
            GiveInventory ('S7_Medikit',  0x7FFFFFFF);
            GiveInventory ('S7_Stimpack', 0x7FFFFFFF);
            GiveInventory ('S7_Canteen',  0x7FFFFFFF);
            // Upgrades
            GiveInventory ('S7_UpgradeRadar', 1);
            GiveInventory ('S7_UpgradeRadarKeys', 1);
            GiveInventory ('S7_UpgradeRadarMinimap', 1);
            GiveInventory ('S7_UpgradeSlot1', 1);
            GiveInventory ('S7_UpgradeSlot2', 1);
            GiveInventory ('S7_UpgradeSlot3', 1);
            GiveInventory ('S7_UpgradeSlot4', 1);
            GiveInventory ('S7_UpgradeSlot5', 1);
            // Cash
            GiveInventory ('S7_Cash', 0x7FFFFFFF);
            // Misc
            for (int i = 0; i < S7_WeapData.ClipNames.Size (); i++)
                GiveInventory (S7_WeapData.ClipNames [i], 0x7FFFFFFF);
            for (int i = 0; i < S7_WeapData.AmmoNames.Size (); i++)
                GiveInventory (S7_WeapData.AmmoNames [i], 0x7FFFFFFF);
        }
        stop;
    }
}