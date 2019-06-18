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
// Infantry playerclass
//
//-------------------------------------------------------------------------------------------
class S7_InfantryPlayer : S7_BasePlayer {
    default {
        S7_BasePlayer.ClassDescription "$S7_CLASSDESC_INFANTRY";

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
        // Equipment
        GiveInventory ('S7_GrenadeCount', 4);
        GiveInventory ('S7_Stimpack', 3);
        GiveInventory ('S7_Medikit', 2);
        // Ammo
        GiveInventory ('S7_RaptorClip', 24);
        GiveInventory ('S7_9mmCartridges', 108);

        GiveBasics_GiveStartingWeapon ('S7_GrenadeWeap');
        let raptor = GiveBasics_GiveStartingWeapon ('S7_Raptor');

        weapBinds.LastWeapon = raptor;
        player.PendingWeapon = raptor;
    }

    // Currently uses Scout sprites, as I haven't made any sprites for this class yet
    states {
    Spawn:
        PINF AAAA 1;
        loop;

    See:
        TNT1 A      0 A_JumpIf (stepFrame == true, "See2");
        TNT1 A      0 { stepFrame = true; }
        PINF AAAAAA 1;
        PINF BBBBBB 1;
        goto Spawn;
    See2:
        TNT1 A      0 { stepFrame = false; }
        PINF CCCCCC 1;
        PINF DDDDDD 1;
        goto Spawn;

    Missile:
        PINF E 12;
        goto Spawn;
    Melee:
        PINF F 6 bright;
        goto Missile;

    Pain:
        PINF G 4;
        PINF G 4 A_Pain;
        goto Spawn;

    Death.Suicide:
    Death:
        PINF H  4 A_PlayerScream;
        PINF I  4 A_PlaySound ("Misc/Body", CHAN_5);
        PINF J  5 A_NoBlocking;
        PINF K  5;
        PINF L  3;
        PINF M  3;
        PINF N -1;
        stop;

    XDeath:
        PINF H 1;
        PINF H 2 {
            A_XScream ();
            A_NoBlocking ();
        }
        goto XDeath.Finish;

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
        S7_BasePlayer.ClassDescription "$S7_CLASSDESC_RIFLEMAN";

        // Class stuff
        Player.DisplayName "$S7_RIFLEMANPLAYER";
    }

    override void GiveBasics_ClassSpecific () {
        // Equipment
        GiveInventory ('S7_GrenadeCount', 4);
        GiveInventory ('S7_Stimpack', 3);
        GiveInventory ('S7_Medikit', 2);
        GiveInventory ('S7_Flashlight', 1);
        // Ammo
        GiveInventory ('S7_RaptorClip', 24);
        GiveInventory ('S7_9mmCartridges', 84);
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
        S7_BasePlayer.ClassDescription "$S7_CLASSDESC_ENFORCER";

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