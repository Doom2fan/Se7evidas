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

class S7_DracoThing : Inventory {
    const morphFlags = MRF_FullHealth | MRF_WhenInvulnerable | MRF_LoseActualWeapon | MRF_UndoByDeath | MRF_UndoAlways | MRF_TransferTranslation;

    default {
        Inventory.MaxAmount 2;
        Inventory.Icon "BFUGA0";

        +INVENTORY.INVBAR
    }

    override bool Use (bool pickup) {
        let pPawn = S7_BasePlayer (Owner);

        if (!pPawn)
            return false;

        if (pPawn.weapBinds)
            pPawn.weapBinds.LastWeapon = null;

        if (!(pPawn is 'S7_DracoPlayer'))
            pPawn.MorphPlayer (pPawn.player, 'S7_DracoPlayer', 0x7FFFFFFF, morphFlags, null, null);
        else
            pPawn.UndoPlayerMorph (pPawn.player, MRF_UndoAlways, false);

        return false;
    }
}

//-------------------------------------------------------------------------------------------
//
// "Draco" Modular Battle Suit
//
//-------------------------------------------------------------------------------------------
class S7_DracoPlayer : S7_BasePlayer {
    default {
        // Damage
        Health 200;
        Player.MaxHealth 200;
        Player.MugShotMaxHealth 200;
        GibHealth -100;

        // Movement
        Player.ForwardMove .5, .5;
        Player.SideMove .25, .25;
        Player.JumpZ 9;

        // Class stuff
        Player.DisplayName "Draco";

        +S7_BASEPLAYER.S7_DISABLEMULTIJUMP
        +S7_BASEPLAYER.S7_DISABLEWALLJUMP
        +S7_BASEPLAYER.S7_DISABLEDODGING
        +S7_BASEPLAYER.S7_DISABLELEDGEGRAB
        +S7_BASEPLAYER.S7_DISABLESPRINTING
        +S7_BASEPLAYER.S7_DISABLETECHING
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();
        defenseMatrixEnergy = MaxDefMatEnergy;
    }

    override void Tick () {
        Super.Tick ();

        Tick_DefenseMatrix ();
    }

    override void CheckWeaponChange () { // We have to override this so Dracos can have multiple weapons
        let player = self.player;

        if (player.WeaponState & WF_DisableSwitch) // Weapon changing has been disabled, so throw away any pending weapon requests.
            player.PendingWeapon = WP_NoChange;

        // Put the weapon away if the player has a pending weapon or has died, and
        // we're at a place in the state sequence where dropping the weapon is okay.
        if ((player.PendingWeapon != WP_NoChange || player.health <= 0) && player.WeaponState & WF_WeaponSwitchOk)
            DropWeapon ();
    }

    override void GiveBasics_ClassSpecific () {
    }

    states {
    Spawn:
        BOSS AAAA 1;
        loop;
    See:
        TNT1 A      0 A_JumpIf (stepFrame == true, "See2");
        TNT1 A      0 { stepFrame = true; }
        BOSS AAAAAA 1;
        BOSS BBBBBB 1;
        goto Spawn;
    See2:
        TNT1 A      0 { stepFrame = false; }
        BOSS CCCCCC 1;
        BOSS DDDDDD 1;
        goto Spawn;
    Missile:
        BOSS EFG 4;
        goto Spawn;
    Melee:
        BOSS EFG 4;
        goto Spawn;
    Pain:
        BOSS H 4;
        BOSS H 4 A_Pain;
        goto Spawn;
    Death.Suicide:
    Death:
        BOSS I  3 A_PlayerScream;
        BOSS J  3;
        BOSS K  3 A_NoBlocking;
        BOSS L  3;
        BOSS M  3;
        BOSS N  3 A_StartSound ("Misc/Body", slot: CHAN_5);
        BOSS O -1;
        stop;
    XDeath:
        goto Death;
    Death.Plasma: // Temporarily
        goto Death;
    }
}