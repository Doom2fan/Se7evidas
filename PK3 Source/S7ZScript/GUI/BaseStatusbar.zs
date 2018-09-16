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

    void DoBlurEffect (S7_BasePlayer pPawn, double TicFrac) {
        if (!pPawn)
            return;

        double mul = 0.0;

        S7_Invisibility_Power invisPwr = null;
        if (invisPwr = S7_Invisibility_Power (pPawn.FindInventory ("S7_Invisibility_Power")))
            mul = clamp ((invisPwr.EffectTics * 2.5) / (90 * 35), 0.35, 1.0);

        if (mul ~== 0.0)
            return;

        BeginHUD (0.075 * mul, true, 640, 360);
        TexMan.SetCameraToTexture (pPawn.cam4, "S7_CAMTEX3", CPlayer.fov);
        DrawImage ("S7_CAMTEX3", (0, 0), DI_ITEM_LEFT_TOP | DI_SCREEN_LEFT_TOP);
        BeginHUD (0.15 * mul, true, 640, 360);
        TexMan.SetCameraToTexture (pPawn.cam3, "S7_CAMTEX2", CPlayer.fov);
        DrawImage ("S7_CAMTEX2", (0, 0), DI_ITEM_LEFT_TOP | DI_SCREEN_LEFT_TOP);
        BeginHUD (0.3 * mul, true, 640, 360);
        TexMan.SetCameraToTexture (pPawn.cam2, "S7_CAMTEX1", CPlayer.fov);
        DrawImage ("S7_CAMTEX1", (0, 0), DI_ITEM_LEFT_TOP | DI_SCREEN_LEFT_TOP);
    }
}