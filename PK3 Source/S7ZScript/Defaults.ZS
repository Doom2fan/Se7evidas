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
        target = null;
    }
}

// By Chronos "phantombeta" Ouroboros
class S7_EffectsBase : Actor {
    void SetPosition (Vector3 newPos) {
        S7_ActorExtensions.SetActorPosition (self, newPos);
    }

    virtual void CheaperTick (bool noStates = false) {
        if (!(vel ~== (0, 0, 0))) {
            let newPos = level.Vec3Offset (pos, vel);
            bool xyPosEqual = (newPos.XY ~== pos.XY);

            if (xyPosEqual && !(vel.Z ~== 0)) {
                Prev.Z = pos.Z;
                SetZ (newPos.Z);
            } else if (!xyPosEqual)
                SetPosition (pos + vel);
        }

        if (noStates)
            return;

        // Return if the actor got removed.
        if (!self || bDestroyed)
            return;
        // Freed itself
        if (!CheckNoDelay ())
            return;
        // Advance the state
        if (tics != -1) {
            if (tics > 0)
                tics--;

            while (!tics) {
                if (!self || bDestroyed || !CurState || !SetState (CurState.NextState)) // Actor was removed
                    return;
            }
        }
    }
}

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