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

//-------------------------------------------------------------------------------------------
//
// Server event handler
//
//-------------------------------------------------------------------------------------------
class S7_ServerEventHandler : EventHandler {
    void ResetShaders () {
        for (int i = 0; i < MaxPlayers; i++) {
            if (!playeringame [i])
                continue;

            Shader.SetEnabled (players [i], "S7_Shadowsphere", false);
            Shader.SetEnabled (players [i], "S7_DemonEyes"   , false);
            Shader.SetEnabled (players [i], "S7_Invuln"      , false);
            Shader.SetEnabled (players [i], "S7_Nightvision" , false);
            //Shader.SetEnabled (players [i], "S7_StealthShader", !(gamestate == GS_TitleLevel));
        }
    }

    override void WorldLoaded (WorldEvent e) {
        let serverData = S7_ServerData.Get ();
        let mapData = S7_MapData.Get ();

        S7_MapEventThinker.Init (serverData, mapData);

        if (mapData.mapEvent > 0)
            Console.PrintF ("%d", mapData.mapEvent);

        ResetShaders ();
    }

    override void WorldUnloaded (WorldEvent e) {
        let serverData = S7_ServerData.Get ();

        serverData.mapCount++;

        /*if (serverData.mapCount > 0 && random [S7_MapEvents] () < 32)
            serverData.queuedMapEvent = random [S7_MapEvents] (S7_MEVNT_None + 1, S7_MEVNT_LastToken - 1);
        else*/
            serverData.queuedMapEvent = S7_MEVNT_None;

        ResetShaders ();
    }

    override void WorldTick () {
        let mapData = S7_MapData.Get ();
        if (mapData)
            mapData.Tick ();

        let serverData = S7_ServerData.Get ();
        if (serverData)
            serverData.Tick ();

        let meThinker = S7_MapEventThinker.Get ();
        if (meThinker)
            meThinker.TickMapEvents (serverData, mapData);
    }

    override void RenderOverlay (RenderEvent e) {
        Shader.SetUniform3f (players [consoleplayer], "S7_Nightvision", "offsets", (
            fRandom [S7_Nightvision_uOffsets] (0., 1.),
            fRandom [S7_Nightvision_uOffsets] (0., 1.),
            fRandom [S7_Nightvision_uOffsets] (0., 1.))
        );
        Shader.SetUniform1f (players [consoleplayer], "S7_Nightvision", "mean", -0.75);
        Shader.SetUniform1f (players [consoleplayer], "S7_Nightvision", "stddev", 0.5);
    }
}

//-------------------------------------------------------------------------------------------
//
// Player event handler
//
//-------------------------------------------------------------------------------------------
class S7_PlayerEventHandler : EventHandler {
    override void NetworkProcess (ConsoleEvent e) {
        if (e.Player < 0) // Don't execute this if the player isn't given/valid
            return;
        if (!playeringame [e.Player] || !players [e.Player].mo) // Don't execute if the player isn't ingame, the player is null or the player's PlayerPawn is null
            return;

        Array<String> strings; strings.Clear ();
        e.Name.Split (strings, ":");

        if (strings.Size () < 2)
            return;

        if (strings [0] ~== "S7_Keys" && strings [1] ~== "QuickBuyAmmo") {
            if (!playeringame [e.Player])
                return;
            if (!players [e.Player].ReadyWeapon || !(players [e.Player].ReadyWeapon is 'S7_BaseWeapon'))
                return;
            if (players [e.Player].PendingWeapon != WP_NoChange)
                return;

            let serverData = S7_ServerData.Get ();
            if (!serverData || !serverData.S7Data || !serverData.S7Data.shopData)
                return;

            let weap = S7_BaseWeapon (players [e.Player].ReadyWeapon);
            if (weap) {
                int itemID = S7_Utils.MakeUIDStr (weap.ammoBuyShopItem);

                let shopData = serverData.S7Data.shopData;
                S7_SSItem item = null;

                for (int i = 0; i < shopData.allItems.Size (); i++) {
                    if (shopData.allItems [i].id == itemID) {
                        item = shopData.allItems [i];
                        break;
                    }
                }
                if (!item)
                    return;

                item.BuyItem (S7_BasePlayer (players [e.Player].mo), weap.ammoBuyAmount, 0.0);
            }
        } else if (strings [0] ~== "S7_Keys") {
            if (!playeringame [e.Player])
                return;

            let pPawn = players [e.Player].mo;

            if (pPawn && strings [1] ~== "Melee")
                pPawn.SetInventory ('S7_DoMelee', 1);
            else if (pPawn && strings [1] ~== "FiringMode")
                pPawn.SetInventory ('S7_ChangeFireMode', 1);
            else if (pPawn && strings [1] ~== "FlashlightPress") {
                let flashlight = S7_Flashlight (pPawn.FindInventory ("S7_Flashlight"));
                if (flashlight)
                    flashlight.TogglePressed ();
            } else if (pPawn && strings [1] ~== "FlashlightRelease") {
                let flashlight = S7_Flashlight (pPawn.FindInventory ("S7_Flashlight"));
                if (flashlight)
                    flashlight.ToggleReleased ();
            }
        }
    }

    static const string serverCVars [] = {
        "S7_DodgeCooldown", "S7_MultiJumpZMul", "S7_ForceIntro", "S7_MaxLevel",
        "S7_InitialCashAmount", "S7_DebugMode", "S7_DebugOpts"
    };
    static const string userCVars [] = {
        "S7_MsgsOn", "S7_LogLVLUpMsgs", "S7_AutoReloading", "S7_HeartbeatsOn", "S7_NoIntro",
        "S7_NoIntroOnMP", "S7_EnemyHPBar_On", "S7_EnemyHPBar_HPDisp", "S7_EnemyHPBar_NametagOn",
        "S7_CasingsStayTime", "S7_CasingsFadeSpeed", "S7_GibsStayTime", "S7_GibsFadeSpeed"
        "S7_BloodSpotsStayTime", "S7_BloodSpotsFadeSpeed"
    };
    override void ConsoleProcess (ConsoleEvent e) {
        if (e.Name.IndexOf (":") < 0) {
            if (e.Name == "S7_ResetServerCVars") {
                for (int i = 0; i < serverCVars.Size (); i++) {
                    CVar cv = CVar.FindCVar (serverCVars [i]);

                    if (!cv)
                        continue;

                    cv.ResetToDefault ();
                }
            } else if (e.Name == "S7_ResetUserCVars") {
                for (int i = 0; i < userCVars.Size (); i++) {
                    CVar cv = CVar.FindCVar (userCVars [i]);

                    if (!cv)
                        continue;

                    cv.ResetToDefault ();
                }
            } else if (e.name ~== "S7_GetMapHash")
                Console.Printf ("\ck%s", level.GetChecksum ());
        } else {
            Array<String> strings; strings.Clear ();
            e.Name.Split (strings, ":");

            if (strings [0] == "S7_Keys") {
                let pPawn = players [consoleplayer].mo;

                if (pPawn && pPawn.health > 0 && strings [1] == "OpenPlayerMenu") {
                    Menu.SetMenu ('S7_PlayerMenu');
                    Menu.MenuSound ("S7Menu/Open");
                } else if (pPawn && pPawn.health > 0 && strings [1] == "OpenLuciusShop") {
                    Menu.SetMenu ('S7_LuciusShopMenu');
                    Menu.MenuSound ("S7Menu/Open");
                }
            }
        }
    }
}