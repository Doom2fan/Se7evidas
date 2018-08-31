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

//-------------------------------------------------------------------------------------------
//
// Misc
//
//-------------------------------------------------------------------------------------------
class S7_UpgradeEnemyHPBar : S7_Boolean { } // Enemy health
class S7_UpgradeRadar     : S7_Boolean { } // Enemy radar
class S7_UpgradeRadarKeys : S7_Boolean { } // Show keys on the radar
class S7_UpgradeRegen : S7_Boolean { }
class S7_UpgradeRegenPower : S7_Counter { default { Inventory.MaxAmount 2; } }
class S7_UpgradeSlot1 : S7_SlotMaxUpgrade { default { S7_SlotMaxUpgrade.Slot 1; } }
class S7_UpgradeSlot2 : S7_SlotMaxUpgrade { default { S7_SlotMaxUpgrade.Slot 2; } }
class S7_UpgradeSlot3 : S7_SlotMaxUpgrade { default { S7_SlotMaxUpgrade.Slot 3; } }
class S7_UpgradeSlot4 : S7_SlotMaxUpgrade { default { S7_SlotMaxUpgrade.Slot 4; } }
class S7_UpgradeSlot5 : S7_SlotMaxUpgrade { default { S7_SlotMaxUpgrade.Slot 5; } }