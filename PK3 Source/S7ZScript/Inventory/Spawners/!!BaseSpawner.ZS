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

class S7_ItemSpawner : RandomSpawner {
    bool delayedSpawn;
    override void BeginPlay () {
        if (S7_DelayedItemSpawns != DelaySpawns_Off) {
            switch (S7_DelayedItemSpawns) {
            case DelaySpawns_MapStart:
                delayedSpawn = (GetLevelSpawnTime () <= 1);
                break;
            case DelaySpawns_All:
                delayedSpawn = true;
                break;
            }

            if (delayedSpawn)
                return;
        }

        Super.BeginPlay ();
    }

    override void PostBeginPlay () {
        if (delayedSpawn) {
            A_ChangeLinkFlags (sector: false);
            return;
        }

        Super.PostBeginPlay ();
    }

    override void Tick () {
        if (!delayedSpawn)
            Super.Tick ();
        else {
            if (S7_ActorExtensions.CheckDelayedSpawn (self)) {
                Super.BeginPlay ();
                Super.PostBeginPlay ();
                delayedSpawn = false;

                Super.Tick ();
            }
        }
    }
}