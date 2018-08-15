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

class S7_Boolean : Inventory {
    default {
        Inventory.MaxAmount 1;
        inventory.interHubAmount 1;

        +INVENTORY.UNDROPPABLE
        -INVENTORY.INVBAR
    }
}

class S7_Counter : Inventory {
    default {
        Inventory.MaxAmount 0x7FFFFFFF;
        inventory.interHubAmount 0x7FFFFFFF;

        +INVENTORY.UNDROPPABLE
        -INVENTORY.INVBAR
    }
}

// By Jekyll Grim Payne "Aka" zer0
class S7_DebrisGeneral : S7_EffectsBase {
    default {
        Radius 1;
        Height 1;
        Mass 1;
        Damage 0;

        +MISSILE    +NOBLOCKMAP       +NOGRAVITY +DROPOFF
        +NOTELEPORT +FORCEXYBILLBOARD +GHOST
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();
        target = NULL;
    }
}

// By Chronos "phantombeta" Ouroboros
class S7_EffectsBase : Actor { }

class S7_PositionMarker : Actor { // For when an actor needs to mark a position.
    default {
        Radius 0;
        Height 0;
        Mass 0;

        +NOBLOCKMAP +NOGRAVITY  +NOINTERACTION +NOCLIP
        +NOTELEPORT +CANNOTPUSH +THRUACTORS
        -SOLID -SHOOTABLE
    }

    states {
    Spawn:
        TNT1 A 1;
        stop;
    }
}
class S7_PositionMarkerPersistent : S7_PositionMarker {
    states {
    Spawn:
        TNT1 A 1;
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Action runner item base
//
//-------------------------------------------------------------------------------------------
class S7_ActionRunnerBase : CustomInventory {
    default {
        Inventory.MaxAmount 1;

        +INVENTORY.AUTOACTIVATE +INVENTORY.QUIET +INVENTORY.ALWAYSPICKUP
    }

    states {
    Spawn:
        TNT1 A 0;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Custom key base
//
//-------------------------------------------------------------------------------------------
class S7_CustomKey : CustomInventory {
    default {
        inventory.amount 1;
        Inventory.MaxAmount 1;

        +INVENTORY.UNDROPPABLE
        -INVENTORY.INVBAR
    }
}

//-------------------------------------------------------------------------------------------
//
// Distance testing puff
//
//-------------------------------------------------------------------------------------------
class S7_DistanceTestPuff : Actor {
    default {
        Damage 0;
        DamageType "TesterProjectile";
        Alpha 0.0;
        Scale 0.0;
        Decal "None";

        +BLOODLESSIMPACT +PAINLESS +NOPAIN +PUFFGETSOWNER
        +NOTIMEFREEZE
    }

    states {
    Spawn:
    Death:
    Crash:
    Crush:
        TNT1 A 1 A_Jump (256, "RunStuff");
        wait;
    RunStuff:
        TNT1 A 2;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Distance testing projectile
//
//-------------------------------------------------------------------------------------------
class S7_DistanceTestProjectile : FastProjectile {
    default {
        Speed 25;
        Damage 0;
        DamageType "TesterProjectile";
        Alpha 0.0;
        Scale 0.0;
        Decal "None";

        Projectile;

        +BLOODLESSIMPACT +PAINLESS +NOPAIN +NOTIMEFREEZE
    }

    states {
    Spawn:
        TNT1 A 2;
        stop;
    }
}