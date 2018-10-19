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
// Shadow
//
//-------------------------------------------------------------------------------------------
class S7_ShadowDemon : S7_Mechdemon {
    default {
        RenderStyle "Translucent";
        Alpha .25;

        Obituary "$OBSHADOW";
        Species "Mechdemon";
        Tag "$SHADOWTAG";
    }

    override void Tick () {
        bool attacking = InStateSequence (CurState, ResolveState ("Melee"));
        bool dead = (bKilled || health <= 0);

        if (attacking && alpha < 1.)
            alpha += 2./TICRATE;
        else if (dead && alpha < 1.)
            alpha += .15/TICRATE;
        else if (!attacking && !dead && health > 0 && alpha > .25) 
            alpha -= 1.5/TICRATE;

        alpha = clamp (alpha, .25, 1.);

        Super.Tick ();
    }
}