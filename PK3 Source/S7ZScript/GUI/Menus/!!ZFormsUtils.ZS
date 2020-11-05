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
    static ui S7_ZF_BoxTextures GetCommonMenuBG () {
        return S7_ZF_BoxTextures.CreateTexturePixels (
            "graphics/Menu/CommonBackground.png",
            // Middle's top-left corner
            (7, 7),
            // Middle's bottom-right corner
            (14, 14),
            // Whether to scale the sides
            false,
            // Whether to scale the middle
            false
        );
    }

    static ui S7_ZF_BoxTextures, S7_ZF_BoxTextures, S7_ZF_BoxTextures GetSmallButtonTexes () {
        let smallButtonIdle = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Generic/SmallButton.png", true);
        let smallButtonHover = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Generic/SmallButtonHover.png", true);
        let smallButtonClick = S7_ZF_BoxTextures.CreateSingleTexture ("graphics/Menu/Generic/SmallButtonPressed.png", true);

        return smallButtonIdle, smallButtonHover, smallButtonClick;
    }
}
