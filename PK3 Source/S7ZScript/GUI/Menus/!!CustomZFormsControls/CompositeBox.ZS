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

class S7_ZF_CompositeBox : S7_ZF_Element {
    S7_ZF_BoxTextures boxTex;

    void Config (S7_ZF_BoxTextures textures = null) {
        self.boxTex = textures;

        self.alpha = 1;
    }

    S7_ZF_CompositeBox Init (Vector2 pos, Vector2 size, S7_ZF_BoxTextures textures = null) {
        self.Config (textures);
        self.SetBox (pos, size);

        return self;
    }

    override void Drawer () {
        DrawBox ((0, 0), box.size, boxTex, true);
    }

    override void OnUIEvent (S7_ZF_UiEvent ev) {
        if (ev.type == UIEvent.Type_MouseMove) {
            DoHover ((ev.mouseX, ev.mouseY));
        }
    }
}