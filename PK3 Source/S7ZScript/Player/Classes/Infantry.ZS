/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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
// Infantry playerclass
//
//-------------------------------------------------------------------------------------------
class S7_InfantryPlayer : S7_BasePlayer {
    default {
        // Damage
        Health 100;
        Player.MaxHealth 100;
        Player.MugShotMaxHealth 100;
        GibHealth -50;

        // Movement
        Player.ForwardMove 1.0, 1.0;
        Player.SideMove 1.0, 1.0;
        Player.JumpZ 8;

        // Class stuff
        Player.DisplayName "$S7_INFANTRYPLAYER";
    }

    override void GiveBasics_ClassSpecific () {
        GiveInventory ('S7_KickMelee', 1);
        // Equipment
        GiveInventory ('S7_GrenadeCount', 4);
        GiveInventory ('S7_Stimpack', 3);
        GiveInventory ('S7_Medikit', 2);
        // Ammo
        GiveInventory ('S7_RaptorClip', 16);
        GiveInventory ('S7_9mmCartridges', 70);

        GiveBasics_GiveStartingWeapon ('S7_GrenadeWeap');
        let raptor = GiveBasics_GiveStartingWeapon ('S7_Raptor');

        weapBinds.LastWeapon = raptor;
        player.PendingWeapon = raptor;
    }

    // Currently uses Scout sprites, as I haven't made any sprites for this class yet
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
        PSCT M  3 A_PlaySound ("Misc/Body", CHAN_5);
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

//-------------------------------------------------------------------------------------------
//
// Rifleman playerclass
//
//-------------------------------------------------------------------------------------------
class S7_RiflemanPlayer : S7_InfantryPlayer {
    default {
        // Class stuff
        Player.DisplayName "$S7_RIFLEMANPLAYER";
    }

    override void GiveBasics_ClassSpecific () {
        GiveInventory ('S7_KickMelee', 1);
        // Equipment
        GiveInventory ('S7_GrenadeCount', 4);
        GiveInventory ('S7_Stimpack', 3);
        GiveInventory ('S7_Medikit', 2);
        GiveInventory ('S7_Flashlight', 1);
        // Ammo
        GiveInventory ('S7_RaptorClip', 16);
        GiveInventory ('S7_9mmCartridges', 50);
        GiveInventory ('S7_AMGMag', 35);
        GiveInventory ('S7_762x39Cartridges', 160);

        GiveBasics_GiveStartingWeapon ('S7_GrenadeWeap');
        GiveBasics_GiveStartingWeapon ('S7_Raptor');
        let rifle = GiveBasics_GiveStartingWeapon ('S7_AMG');

        weapBinds.LastWeapon = rifle;
        player.PendingWeapon = rifle;
    }
}

//-------------------------------------------------------------------------------------------
//
// Enforcer playerclass
//
//-------------------------------------------------------------------------------------------
class S7_EnforcerPlayer : S7_InfantryPlayer {
    default {
        // Class stuff
        Player.DisplayName "$S7_ENFORCERPLAYER";
    }

    override void GiveBasics_ClassSpecific () {
        GiveInventory ('S7_MacheteMelee', 1);
        // Equipment
        GiveInventory ('S7_GrenadeCount', 4);
        GiveInventory ('S7_Stimpack', 3);
        GiveInventory ('S7_Medikit', 2);
        GiveInventory ('S7_Flashlight', 1);
        // Ammo
        GiveInventory ('S7_RevolverClip', 6);
        GiveInventory ('S7_44MCartridges', 24);
        GiveInventory ('S7_ShotgunMag', 10);
        GiveInventory ('S7_20gaShells', 20);

        GiveBasics_GiveStartingWeapon ('S7_GrenadeWeap');
        GiveBasics_GiveStartingWeapon ('S7_Revolver');
        let shotgun = GiveBasics_GiveStartingWeapon ('S7_Shotgun');

        weapBinds.LastWeapon = shotgun;
        player.PendingWeapon = shotgun;
    }
}