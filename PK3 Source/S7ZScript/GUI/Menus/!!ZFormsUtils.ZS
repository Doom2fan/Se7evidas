/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018-2020 Chronos "phantombeta" Ouroboros
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

class S7_ZFMenuUtils {
    static ui S7_ZF_BoxTextures GetConfirmMenuBG () {
        let boxTex = new ('S7_ZF_BoxTextures');

        boxTex.SetCorners (
            "graphics/Menu/ConfirmPopup/TopLeft.png",
            "graphics/Menu/ConfirmPopup/TopRight.png",
            "graphics/Menu/ConfirmPopup/BottomLeft.png",
            "graphics/Menu/ConfirmPopup/BottomRight.png"
        );
        boxTex.SetSides (
            "graphics/Menu/ConfirmPopup/Top.png",
            "graphics/Menu/ConfirmPopup/Bottom.png",
            "graphics/Menu/ConfirmPopup/Left.png",
            "graphics/Menu/ConfirmPopup/Right.png"
        );
        boxTex.SetMidTex ("graphics/Menu/ConfirmPopup/Middle.png");

        return boxTex;
    }
}
