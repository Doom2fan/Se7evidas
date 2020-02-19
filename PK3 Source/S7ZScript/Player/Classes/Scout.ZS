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

//-------------------------------------------------------------------------------------------
//
// Scout playerclass
//
//-------------------------------------------------------------------------------------------
class S7_ScoutPlayer : S7_BasePlayer {
    default {
        S7_BasePlayer.ClassDescription "$S7_CLASSDESC_SCOUT";

        // Damage
        Health 75;
        Player.MaxHealth 75;
        Player.MugShotMaxHealth 75;
        GibHealth -37;

        // Movement
        Player.ForwardMove 1.2, 1.2;
        Player.SideMove 1.2, 1.2;
        Player.JumpZ 9.797;

        // Class stuff
        Player.DisplayName "$S7_SCOUTPLAYER";
    }

    override void GiveBasics_ClassSpecific () {
        GiveInventory ('S7_DaggerMelee', 1);
        GiveInventory ('S7_MultiJump_Max', 1); // Scouts can do double jumps from the start
        // Equipment
        GiveInventory ('S7_GrenadeCount', 4);
        GiveInventory ('S7_Stimpack', 3);
        GiveInventory ('S7_Medikit', 1);
        // Ammo
        GiveInventory ('S7_TEC9Clip', 32);
        GiveInventory ('S7_9mmCartridges', 130);

        GiveBasics_GiveStartingWeapon ('S7_GrenadeWeap');
        let tec9 = GiveBasics_GiveStartingWeapon ('S7_TEC9');

        weapBinds.LastWeapon = tec9;
        player.PendingWeapon = tec9;
    }

    /* Credits
     * Sprites: Rogue Entertainment, Chronos "phantombeta" Ouroboros
    */
    states {
    Spawn:
        PSCT AAAA 1;
        loop;

    See:
        TNT1 A      0 A_JumpIf (stepFrame == true, "See2");
        TNT1 A      0 { stepFrame = true; }
        PSCT AAAAAA 1;
        PSCT BBBBBB 1;
        goto Spawn;
    See2:
        TNT1 A      0 { stepFrame = false; }
        PSCT CCCCCC 1;
        PSCT DDDDDD 1;
        goto Spawn;

    Missile:
        PSCT E 12;
        goto Spawn;
    Melee:
        PSCT F 6 bright;
        goto Missile;

    Pain:
        PSCT G 4;
        PSCT G 4 A_Pain;
        goto Spawn;

    Death.Suicide:
    Death:
        PSCT H  3 A_PlayerScream;
        PSCT I  3;
        PSCT J  3 A_NoBlocking;
        PSCT K  3;
        PSCT L  3;
        PSCT M  3 A_StartSound ("Misc/Body", slot: CHAN_5);
        PSCT N  3;
        PSCT O -1;
        stop;

    XDeath:
        PSCT H 1;
        PSCT H 2 {
            A_XScream ();
            A_NoBlocking ();
        }
        goto XDeath.Finish;
    /*XDeath:
        PSCT O     5;
        PSCT P     5 A_XScream;
        PSCT Q     5 A_NoBlocking;
        PSCT RSTUV 5;
        PSCT W    -1;
        stop;*/

    Death.Plasma: // Temporarily
        goto Death;
    }
}