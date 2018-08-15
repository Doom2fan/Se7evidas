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
// Infiltrator playerclass
//
//-------------------------------------------------------------------------------------------
class S7_InfiltratorPlayer : S7_ScoutPlayer {
    default {
        // Movement
        Player.JumpZ 9.55; // Not quite as good at jumping as scouts

        // Class stuff
        Player.DisplayName "$S7_INFILTRATORPLAYER";

        // Misc
        Radius 15; // Can fit into smaller spaces
    }

    override void GiveBasics_ClassSpecific () {
        GiveInventory ("S7_DaggerMelee", 1);
        GiveInventory ("S7_MultiJump_Max", 1); // Scouts can do double jumps from the start
        // Equipment
        GiveInventory ("S7_Stimpack", 3);
        GiveInventory ("S7_Medikit", 1);
        // Ammo
        GiveInventory ("S7_TEC9Clip", 32);
        GiveInventory ("S7_ManxCarbineClip", 23);
        GiveInventory ("S7_9mmCartridges", 6 * 23);

        GiveBasics_GiveStartingWeapon ("S7_TEC9");
        let manx = GiveBasics_GiveStartingWeapon ("S7_ManxCarbine");
        // The TEC9 and the Manx should start out suppressed, but mods aren't in yet.

        weapBinds.LastWeapon = manx;
        player.PendingWeapon = manx;
    }
}