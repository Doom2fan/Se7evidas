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
// Telefog
//
//-------------------------------------------------------------------------------------------
class S7_TeleportFog : S7_EffectsBase {
    default {
        RenderStyle "add";

        +NOINTERACTION +NOTELEPORT +NOGRAVITY +NOBLOCKMAP
    }

    states {
    Spawn:
        TFOG A 36 bright;
    Fade:
        TFOG A 1 bright A_FadeOut (0.1);
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Telefog spawner
//
//-------------------------------------------------------------------------------------------
class S7_TeleportFogSpawner : TeleportFog replaces TeleportFog {
    states {
    Spawn:
        TNT1 A 0 noDelay A_SpawnItemEx ('S7_TeleportFog', 0.0, 0.0);
        stop;
    }
}