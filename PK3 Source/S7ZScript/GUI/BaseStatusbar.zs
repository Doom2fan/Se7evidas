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

class S7_BaseStatusbar : BaseStatusBar {
    int GetStamina (bool max) {
        let dracoPlayer = S7_DracoPlayer (CPlayer.mo);

        if (max) {
            if (!dracoPlayer) return GetMaxAmount ('S7_Stamina');
            else return 500;
        } else {
            if (!dracoPlayer) return GetAmount ('S7_Stamina');
            else return dracoPlayer.defenseMatrixEnergy;
        }
    }

    /** Line drawing **/
    protected void DrawLine (Vector2 origin, Vector2 p1, Vector2 p2, Color lineColor, double thickness = -1, Vector2 scale = (1, 1), double alpha = 1., int flags = 0) {
        if (alpha <= 0)
            return;
        if (thickness ~== 0)
            return;

        Vector2 box = (abs (p2.X - p1.X) * scale.X, abs (p2.Y - p1.Y) * scale.Y);

        // Resolve auto-alignment before making any adjustments to the position values.
        if (!(flags & DI_Screen_Manual_Align)) {
            if (origin.X < 0) flags |= DI_Screen_Right;
            else flags |= DI_Screen_Left;
            if (origin.Y < 0) flags |= DI_Screen_Bottom;
            else flags |= DI_Screen_Top;
        }

        alpha *= self.Alpha;
        if (Alpha <= 0)
            return;

        origin += drawOffset;

        switch (flags & DI_Item_HMask) {
        case DI_Item_HCenter:   origin.X -= box.X / 2; p1.X += box.X / 2; p2.X += box.X / 2; break;
        case DI_Item_Right:     origin.X -= box.X    ; p1.X += box.X; p2.X += box.X; break;
        }

        switch (flags & DI_Item_VMask)
        {
        case DI_Item_VCenter: origin.Y -= box.Y / 2; p1.Y += box.Y / 2; p2.Y += box.Y / 2; break;
        case DI_Item_Bottom:  origin.Y -= box.Y    ; p1.Y += box.Y    ; p2.Y += box.Y; break;
        }

        if (!fullscreenOffsets) {
            [origin.X, origin.Y, box.X, box.Y] = StatusbarToRealCoords (origin.X, origin.Y, box.X, box.Y);
        } else {
            Vector2 org;

            switch (flags & DI_Screen_HMask)
            {
            default: org.X = 0; break;
            case DI_Screen_HCenter: org.X = Screen.GetWidth () / 2; break;
            case DI_Screen_Right:   org.X = Screen.GetWidth (); break;
            }

            switch (flags & DI_Screen_VMask)
            {
            default: org.Y = 0; break;
            case DI_Screen_VCenter: org.Y = screen.GetHeight () / 2; break;
            case DI_Screen_Bottom: org.Y = screen.GetHeight (); break;
            }

            Vector2 hudScale = GetHUDScale ();

            origin = (origin.X * hudScale.X, origin.Y * hudScale.Y);
            p1 = (p1.X * hudScale.X, p1.Y * hudScale.Y);
            p2 = (p2.X * hudScale.X, p2.Y * hudScale.Y);
            thickness *= hudScale.Y;
            box = (box.X * hudScale.X, box.Y * hudScale.Y);
            origin += org;
        }

        if (!(thickness ~== -1))
            Screen.DrawThickLine (int (origin.X + p1.X), int (origin.Y + p1.Y), int (origin.X + p2.X), int (origin.Y + p2.Y), thickness, lineColor, int (alpha * 255));
        else
            Screen.DrawLine (int (origin.X + p1.X), int (origin.Y + p1.Y), int (origin.X + p2.X), int (origin.Y + p2.Y), lineColor, int (alpha * 255));
    }

    /** Armor stuff **/
    int GetS7ArmorAmount () {
        let armor = CPlayer.mo.FindInventory ('S7_BasicArmor');
        return armor ? armor.Amount : 0;
    }

    int GetS7ArmorSaveAmount () {
        let armor = S7_BasicArmor (CPlayer.mo.FindInventory ('S7_BasicArmor'));
        return armor ? armor.ActualSaveAmount : 0;
    }

    /** Camtex stuff **/
    void DrawFullscreenCamTex (Actor cam, string tex, double alpha) {
        int w, h;

        let texID = TexMan.CheckForTexture (tex, TexMan.Type_Any);
        [w, h] = TexMan.GetSize (texID);
        double vWidth = h * Screen.GetAspectRatio ();

        TexMan.SetCameraToTexture (cam, tex, CPlayer.fov);
        Screen.DrawTexture (texID, false, (vWidth - w) / 2., 0., DTA_VirtualWidthF, vWidth, DTA_VirtualHeightF, double (h), DTA_KeepRatio, true, DTA_Alpha, alpha);
    }
}