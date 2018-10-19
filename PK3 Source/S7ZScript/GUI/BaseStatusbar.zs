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

class S7_BaseS7HUD : BaseStatusBar {
    int GetStamina (bool max) {
        let dracoPlayer = S7_DracoPlayer (CPlayer.mo);

        if (max) {
            if (!dracoPlayer) return GetMaxAmount ("S7_Stamina");
            else return 500;
        } else {
            if (!dracoPlayer) return GetAmount ("S7_Stamina");
            else return dracoPlayer.defenseMatrixEnergy;
        }
    }

    /** Armor stuff **/
    int GetS7ArmorAmount () {
        let armor = CPlayer.mo.FindInventory ("S7_BasicArmor");
        return armor ? armor.Amount : 0;
    }

    int GetS7ArmorSaveAmount () {
        let armor = S7_BasicArmor (CPlayer.mo.FindInventory ("S7_BasicArmor"));
        return armor ? armor.ActualSaveAmount : 0;
    }

    void DrawFullscreenCamTex (Actor cam, string tex, double alpha) {
        int w, h;

        let texID = TexMan.CheckForTexture (tex, TexMan.Type_Any);
        [w, h] = TexMan.GetSize (texID);
        double vWidth = h * Screen.GetAspectRatio (); //(double (Screen.GetWidth ()) / double (Screen.GetHeight ()));

        TexMan.SetCameraToTexture (cam, tex, CPlayer.fov);
        Screen.DrawTexture (texID, false, (vWidth - w) / 2., 0., DTA_VirtualWidthF, vWidth, DTA_VirtualHeightF, double (h), DTA_KeepRatio, true, DTA_Alpha, alpha);
    }

    void DoBlurEffect (S7_BasePlayer pPawn, double TicFrac) {
        if (!pPawn)
            return;

        double mul = 0.0;

        S7_Invisibility_Power invisPwr = null;
        if (invisPwr = S7_Invisibility_Power (pPawn.FindInventory ("S7_Invisibility_Power")))
            mul = clamp ((invisPwr.EffectTics * 2.5) / (90 * 35), 0.35, 1.0);

        if (mul ~== 0.0)
            return;

        DrawFullscreenCamTex (pPawn.cam4, "S7_CAMTEX3", 0.075 * mul);
        DrawFullscreenCamTex (pPawn.cam3, "S7_CAMTEX2", 0.15  * mul);
        DrawFullscreenCamTex (pPawn.cam2, "S7_CAMTEX1", 0.3   * mul);
    }
}