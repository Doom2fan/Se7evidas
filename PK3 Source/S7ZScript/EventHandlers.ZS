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
// Static event handler
//
//-------------------------------------------------------------------------------------------
class S7_StaticEventHandler : StaticEventHandler {
    override void WorldLoaded (WorldEvent e) {
        for (int i = 0; i < MAXPLAYERS; i++) {
            if (!playeringame [i])
                continue;

            Shader.SetEnabled (players [i], "S7_DemonEyes"  , false);
            Shader.SetEnabled (players [i], "S7_Invuln"     , false);
            Shader.SetEnabled (players [i], "S7_Nightvision", false);
            Shader.SetEnabled (players [i], "S7_StealthShader", !(gamestate == GS_TITLELEVEL));
        }
    }
}

//-------------------------------------------------------------------------------------------
//
// Server event handler
//
//-------------------------------------------------------------------------------------------
class S7_ServerEventHandler : EventHandler {
    override void WorldLoaded (WorldEvent e) {
        let serverData = S7_ServerData.Get ();
        let mapData = S7_MapData.Get ();

        S7_MapEventThinker.Init (serverData, mapData);

        if (mapData.mapEvent > 0)
            Console.PrintF ("%d", mapData.mapEvent);
    }

    override void WorldUnloaded (WorldEvent e) {
        let serverData = S7_ServerData.Get ();

        serverData.mapCount++;

        /*if (serverData.mapCount > 0 && random [S7_MapEvents] () < 32)
            serverData.queuedMapEvent = random [S7_MapEvents] (MEVNT_None + 1, MEVNT_LastToken - 1);
        else*/
            serverData.queuedMapEvent = MEVNT_None;
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
    static const String KeyBindsCCMDs [] = {
        "slot 1", "slot 2", "slot 3", "slot 4", "slot 5",
        "slot 6", "slot 7", "slot 8", "slot 9", "slot 0",
        "weapnext", "weapprev"
    };
    static const String KeyBindsNetEvents [] = {
        "slot:1", "slot:2", "slot:3", "slot:4", "slot:5",
        "slot:6", "slot:7", "slot:8", "slot:9", "slot:0",
        "next", "prev"
    };

    override bool InputProcess (InputEvent e) {
        if (e.Type != InputEvent.Type_KeyDown)
            return false;

        int bind1, bind2;
        for (int i = 0; i < 12; i++) {
            [bind1, bind2] = Bindings.GetKeysForCommand (KeyBindsCCMDs [i]);

            if (e.KeyScan == bind1 || e.KeyScan == bind2) {
                EventHandler.SendNetworkEvent (String.Format ("S7_WeapBindsSystem:%s", KeyBindsNetEvents [i]));
                return true;
            }
        }

        return false;
    }

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
            if (players [e.Player].PendingWeapon != WP_NOCHANGE)
                return;

            let serverData = S7_ServerData.Get ();
            if (!serverData || !serverData.S7Data || !serverData.S7Data.shopData)
                return;

            let weap = S7_BaseWeapon (players [e.Player].ReadyWeapon);
            if (weap) {
                int itemID = S7_Utils.MakeUIDStr (weap.ammoBuyShopItem);

                let shopData = serverData.S7Data.shopData;
                S7_SSItem item = NULL;

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
            } else if (pPawn && strings [1] ~== "FlashlightRelease"){
                let flashlight = S7_Flashlight (pPawn.FindInventory ("S7_Flashlight"));
                if (flashlight)
                    flashlight.ToggleReleased ();
            }
        } else if (strings [0] ~== "S7_WeapBindsSystem")
            WeapBindsSystem (e);
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

                if (pPawn && pPawn.health > 0 && strings [1] == "OpenPlayerMenu")
                    Menu.SetMenu ('S7_PlayerMenu');
                else if (pPawn && pPawn.health > 0 && strings [1] == "OpenLuciusShop")
                    Menu.SetMenu ('S7_LuciusShopMenu');
            }
        }
    }

    void WeapBindsSystem (ConsoleEvent e) {
        PlayerInfo player = players [e.Player];

        if (!player) // Return if the player is null
            return;

        let weapBinds = S7_WeapBindsSystem (player.mo.FindInventory ('S7_WeapBindsSystem'));

        if (!weapBinds) // Return if weapBinds is null
            return;

        bool isDraco = (player.mo is 'S7_DracoPlayer');

        Array<String> commandStrings; commandStrings.Clear ();
        e.Name.Split (commandStrings, ":");
        if (commandStrings.Size () < 2) // Return if the array contains less than two strings
            return;

        if (commandStrings [1] == "slot") {
            if (commandStrings.Size () < 3) // Return if the array contains less than 3 strings
                return;

            int slot = commandStrings [2].ToInt ();
            if (slot < 0 || slot > 9)
                return;

            S7_BaseWeapon weapon = weapBinds.PickWeapon (slot, false, isDraco);

            if (player.ReadyWeapon != weapon && weapon != null) {
                player.PendingWeapon = weapon;
                weapBinds.LastWeapon = weapon;
            }
        } else if (commandStrings [1] == "next") {
            S7_BaseWeapon weapon = weapBinds.CycleWeapons (false, false, isDraco);

            if (player.ReadyWeapon != weapon && weapon != null) {
                player.PendingWeapon = weapon;
                weapBinds.LastWeapon = weapon;
            }

            CVar dispTags = CVar.GetCVar ("displaynametags", players [consoleplayer]);
            CVar tagColor = CVar.GetCVar ("nametagcolor", players [consoleplayer]);
            if (dispTags && weapon && (dispTags.GetInt () & 2))
                S7_HudMessageFade.Show (e.Player, weapon.GetTag (), S7_Utils.MakeUID ("W", "E", "P", "N"), (0.5, 0.90), 35 * 2, 0, ceil (35 * 0.35), alignment: S7_HudMessage.AlignCenter,
                    color: tagColor ? tagColor.GetInt () : Font.CR_GOLD, fnt: 'SmallFont');
        } else if (commandStrings [1] == "prev") {
            S7_BaseWeapon weapon = weapBinds.CycleWeapons (true, false, isDraco);

            if (player.ReadyWeapon != weapon && weapon != null) {
                player.PendingWeapon = weapon;
                weapBinds.LastWeapon = weapon;
            }

            CVar dispTags = CVar.GetCVar ("displaynametags", players [consoleplayer]);
            CVar tagColor = CVar.GetCVar ("nametagcolor", players [consoleplayer]);
            if (dispTags && weapon && (dispTags.GetInt () & 2))
                S7_HudMessageFade.Show (e.Player, weapon.GetTag (), S7_Utils.MakeUID ("W", "E", "P", "N"), (0.5, 0.90), 35 * 2, 0, ceil (35 * 0.35), alignment: S7_HudMessage.AlignCenter,
                    color: tagColor ? tagColor.GetInt () : Font.CR_GOLD, fnt: 'SmallFont');
        } else if (commandStrings [1] == "test") {
            for (int i = 1; i <= 5; i++)
                weapBinds.SlotMaximum [i] = 3;

            // Medium
            WeapBindsSystem_Derp (player, 1, 'S7_AK47');
            WeapBindsSystem_Derp (player, 1, 'S7_Fauchard');
            WeapBindsSystem_Derp (player, 1, 'S7_SSG');
            // Light
            weapBinds.Binds [2].Clear ();
            WeapBindsSystem_Derp (player, 2, 'S7_Revolver');
            WeapBindsSystem_Derp (player, 2, 'S7_HitterSMG');
            WeapBindsSystem_Derp (player, 2, 'S7_LaserPewPew');
            // Heavy
            WeapBindsSystem_Derp (player, 3, 'S7_ConquerorRifle');
            WeapBindsSystem_Derp (player, 3, 'S7_Thumper');
            // Area-damage
            WeapBindsSystem_Derp (player, 4, 'S7_PrettyShootyIonCannonGun');
            // Special
            WeapBindsSystem_Derp (player, 5, 'S7_GrenadeWeap');
            WeapBindsSystem_Derp (player, 5, 'S7_SoulLance');
        }
    }
    void WeapBindsSystem_Derp (PlayerInfo player, int slot, string weapon) {
        if (!player) return;
        let weapBinds = S7_WeapBindsSystem (player.mo.FindInventory ('S7_WeapBindsSystem'));
        if (!weapBinds) return;
        let weapInv = S7_BaseWeapon (player.mo.FindInventory (weapon));

        if (!weapInv || weapInv.Amount <= 0) {
            if (!player.mo.GiveInventory (weapon, 1))
                return;

            weapInv = S7_BaseWeapon (player.mo.FindInventory (weapon));
        }

        if (weapBinds.Binds [slot].Find (weapInv) == weapBinds.Binds [slot].Size ())
            weapBinds.Binds [slot].Push (weapInv);
    }
}