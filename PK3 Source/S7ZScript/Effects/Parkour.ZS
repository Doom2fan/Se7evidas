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
// Multijump marker
//
//-------------------------------------------------------------------------------------------
class S7_MultiJump_Marker : S7_EffectsBase {
    default {
        Height 2;
        Radius 2;
        Alpha 1.0;
        RenderStyle "add";

        +NOTELEPORT +NOINTERACTION  +NOGRAVITY +FORCEXYBILLBOARD
        +CANNOTPUSH +CLIENTSIDEONLY
        -NOBLOCKMAP
    }

    states {
    Spawn:
        MJMP A 10 bright light ("MJMPMARKER");
        #### #  1 bright light ("MJMPMARKER") A_FadeOut (0.05);
        wait;
    }
}