/* Unused because it can't be ported:
 *   No `bool TexMan::UseWorldPanning (TextureID)`
 *   No `int, int TexMan::GetTexelSize (TextureID)`
 *   No `Vector2 TexMan::GetScale (TextureID)`
 */

/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2023 Chronos "phantombeta" Ouroboros
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

/*
 * Copyright 2004-2007 Randy Heit
 * Copyright 2006-2020 Christoph Oelckers
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

class S7_TextureUtils {
    static bool GetMidTextureCoords (Line l, int sideNum, out double texCoordsTop, out double texCoordsBottom) {
        if (!l.sidedef [0] || !l.sidedef [1])
            return false;

        let sidedef = l.sidedef [sideNum];
        let tex = sidedef.GetTexture (Side.Mid);
        if (!tex.IsValid ())
            return false;

        // We only need the vertical positioning info here.
        S7_TexCoordInfo tci;
        tci.GetFromTexture (tex, 1, sidedef.GetTextureYScale (Side.Mid), !!(Level.flags3 & LEVEL3_ForceWorldPanning));
        let yOffset = tci.RowOffset (sidedef.GetTextureYOffset (Side.Mid));
        let textureHeight = tci.RenderHeight;

        if (l.flags & Line.ML_DontPegBottom) {
            texCoordsBottom = yOffset + max (l.frontSector.GetPlaneTexZ (Sector.Floor), l.backSector.GetPlaneTexZ (Sector.Floor));
            texCoordsTop = texCoordsBottom + textureHeight;
        } else {
            texCoordsTop = yOffset + min (l.frontSector.GetPlaneTexZ (Sector.Ceiling), l.backSector.GetPlaneTexZ (Sector.Ceiling));
            texCoordsBottom = texCoordsTop - textureHeight;
        }
        return true;
    }
}

struct S7_TexCoordInfo {
    int RenderWidth;
    int RenderHeight;
    int Width;
    Vector2 Scale;
    Vector2 TempScale;
    bool WorldPanning;

    double FloatToTexU (double v) { return v / RenderWidth; }
    double FloatToTexV (double v) { return v / RenderHeight; }

    double RowOffset (double rowOffset) {
        let scale = abs (Scale.Y);
        return (scale == 1. || WorldPanning) ? rowOffset : (rowOffset / scale);
    }

    double TextureOffset (double textureOffset) {
        let scale = abs (Scale.X);
        return (scale == 1. || WorldPanning) ? textureOffset : (textureOffset / scale);
    }

    double TextureAdjustWidth () {
        if (!WorldPanning)
            return Width;

        let tScale = abs (TempScale.X);
        return tScale == 1. ? RenderWidth : (Width / tScale);
    }

    void GetFromTexture (TextureID tex, double x, double y, bool forceWorldPanning) {
        let scaledSize = TexMan.GetScaledSize (tex);

        if (x == 1.) {
            RenderWidth = int (scaledSize.X + .5);
            Scale.X = tex.GetScaleX ();
            TempScale.X = 1.;
        } else {
            let scaleX = x * tex.GetScaleX ();
            RenderWidth = int (ceil (tex.GetTexelWidth () / scaleX));
            Scale.X = scaleX;
            TempScale.X = x;
        }

        if (y == 1.) {
            RenderHeight = int (scaledSize.Y + .5);
            Scale.Y = tex.GetScaleY ();
            TempScale.Y = 1.;
        } else {
            let scaleY = y * tex.GetScaleY ();
            RenderHeight = int (ceil (tex.GetTexelHeight () / scaleY));
            Scale.Y = scaleY;
            TempScale.Y = y;
        }

        WorldPanning = forceWorldPanning || tex.UseWorldPanning ();
        Width = tex.GetTexelWidth ();
    }
}