//-------------------------------------------------------------------------------------------
//
// Server event handler
//
//-------------------------------------------------------------------------------------------
class S7_ServerEventHandler : EventHandler {
    override void WorldLoaded (WorldEvent e) {
        let serverData = S7_ServerData.Get ();
        let mapData = S7_MapData.Get ();

        SetupMapEvents (serverData, mapData);

        if (mapData.mapEvent > 0)
            Console.PrintF ("%d", mapData.mapEvent);
    }

    void SetAllLight (int lightLevel, bool removeEffects) {
        if (removeEffects) {
            ThinkerIterator it = ThinkerIterator.Create ("Lighting");
            Lighting effect;

            while (effect = Lighting (it.Next ()))
                effect.Destroy ();
        }

        for (int i = 0; i < level.Sectors.Size(); i++) {
            Sector s = level.Sectors[i];
            s.SetLightLevel (lightLevel);
        }
    }

    void SetupMapEvents (S7_ServerData serverData, S7_MapData mapData) {
        if (mapData.mapEventSet) // Don't set map events up twice.
            return;

        //serverData.queuedMapEvent = S7_DebugOpts;//MEVNT_PowerOutage;
        mapData.mapEvent = serverData.queuedMapEvent;
        serverData.queuedMapEvent = MEVNT_None;

        do {
            mapData.mapEventSet = true;

            switch (mapData.mapEvent) {
                case MEVNT_None: break;

                case MEVNT_PowerOutage:
                    level.ChangeSky ("NEBSKY", "NEBSKY"); // Change the sky

                    SetAllLight (64, true);
                break;

                case MEVNT_PerfectHatred:
                    level.ChangeSky ("ATWSKY", "ATWSKY"); // Change the sky
                    S_ChangeMusic ("", force: true); // Remove the music

                    SetAllLight (2, true);
                break;

                case MEVNT_GhostTown: {
                    S_ChangeMusic ("", force: true); // Remove the music
                    let spot = Actor.Spawn ("MapSpot", (0.0, 0.0, 0.0)); // Spawn a mapspot
                    spot.A_PlaySound ("MapEvents/GhostTown/Wind", CHAN_Body | CHAN_ListenerZ | CHAN_NoPause, 1.0, true, ATTN_None); // Play a wind sound on it
                }
                break;

                default:
                    MapData.mapEvent = random [S7_MapEvents] (MEVNT_None + 1, MEVNT_LastToken - 1);
                    mapData.mapEventSet = false; // Set it back to false. This will make it loop.
                break;
            }
        } while (!mapData.mapEventSet);
    }

    override void WorldUnloaded (WorldEvent e) {
        let serverData = S7_ServerData.Get ();

        serverData.mapCount++;

        /*if (serverData.mapCount > 0 && random [S7_MapEvents] (0, 255) < 32)
            serverData.queuedMapEvent = random [S7_MapEvents] (MEVNT_None + 1, MEVNT_LastToken - 1);
        else*/
            serverData.queuedMapEvent = MEVNT_None;
    }

    override void WorldTick () {
        let mapData = S7_MapData.Get ();
        let serverData = S7_ServerData.Get ();

        mapData.Tick ();
        serverData.Tick ();

        TickMapEvents (mapData);
    }

    void TickMapEvents (S7_MapData mapData) {
        switch (MapData.mapEvent) {
            case MEVNT_PowerOutage:
                level.ChangeSky ("NEBSKY", "NEBSKY"); // Change the sky
                SetAllLight (64, ((level.time % 5) == 0));
            break;

            case MEVNT_PerfectHatred:
                level.ChangeSky ("ATWSKY", "ATWSKY"); // Change the sky
                S_ChangeMusic ("", force: true); // Remove the music

                SetAllLight (2, ((level.time % 5) == 0));
            break;

            case MEVNT_GhostTown:
                S_ChangeMusic ("", force: true); // Remove the music
            break;
        }
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

        Array<String> strings;
        e.Name.Split (strings, ":");

        if (strings.Size () < 2) // Return if the array has less than two strings
            return;

        if (strings [0] == "S7_Keys") {
            let pPawn = players [e.Player].mo;

            if (pPawn && strings [1] == "Melee")
                pPawn.SetInventory ("S7_DoMelee", 1);
            else if (pPawn && strings [1] == "FiringMode")
                pPawn.SetInventory ("S7_ChangeFireMode", 1);
        } else if (strings [0] == "S7_WeapBindsSystem")
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
            Array<String> strings;
            e.Name.Split (strings, ":");

            if (strings [0] == "S7_Keys") {
                let pPawn = players [consoleplayer].mo;

                if (pPawn && pPawn.health > 0 && strings [1] == "OpenPlayerMenu")
                    Menu.SetMenu ("S7_PlayerMenu");
                else if (pPawn && pPawn.health > 0 && strings [1] == "OpenLuciusShop")
                    Menu.SetMenu ("S7_LuciusShopMenu");
            }
        }
    }

    void WeapBindsSystem (ConsoleEvent e) {
        PlayerInfo player = players [e.Player];

        if (!player) // Return if the player is null
            return;

        let weapBinds = S7_WeapBindsSystem (player.mo.FindInventory ("S7_WeapBindsSystem"));

        if (!weapBinds) // Return if weapBinds is null
            return;

        bool isDraco = (player.mo is "S7_DracoPlayer");

        Array<String> commandStrings;
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

            CVar dispTags = CVar.GetCVar ("displaynametags", player);
            CVar tagColor = CVar.GetCVar ("nametagcolor", player);
            if (dispTags && weapon && (dispTags.GetInt () & 2))
                S7_HudMessage.ShowFade (e.Player, weapon.GetTag (), S7_Utils.MakeUID ("W", "E", "P", "N"), (0.5, 0.90), 35 * 2, 0, ceil (35 * 0.35), alignment: S7_HudMessage.AlignCenter,
                    color: tagColor ? tagColor.GetInt () : Font.CR_GOLD, fnt: "SmallFont");
        } else if (commandStrings [1] == "prev") {
            S7_BaseWeapon weapon = weapBinds.CycleWeapons (true, false, isDraco);

            if (player.ReadyWeapon != weapon && weapon != null) {
                player.PendingWeapon = weapon;
                weapBinds.LastWeapon = weapon;
            }

            CVar dispTags = CVar.GetCVar ("displaynametags", player);
            CVar tagColor = CVar.GetCVar ("nametagcolor", player);
            if (dispTags && weapon && (dispTags.GetInt () & 2))
                S7_HudMessage.ShowFade (e.Player, weapon.GetTag (), S7_Utils.MakeUID ("W", "E", "P", "N"), (0.5, 0.90), 35 * 2, 0, ceil (35 * 0.35), alignment: S7_HudMessage.AlignCenter,
                    color: tagColor ? tagColor.GetInt () : Font.CR_GOLD, fnt: "SmallFont");
        } else if (commandStrings [1] == "test") {
            for (int i = 1; i <= 5; i++)
                weapBinds.SlotMaximum [i] = 3;

            // Medium
            WeapBindsSystem_Derp (player, 1, "S7_AK47");
            WeapBindsSystem_Derp (player, 1, "S7_Fauchard");
            WeapBindsSystem_Derp (player, 1, "S7_SSG");
            // Light
            weapBinds.Binds [2].Clear ();
            WeapBindsSystem_Derp (player, 2, "S7_Revolver");
            WeapBindsSystem_Derp (player, 2, "S7_HitterSMG");
            WeapBindsSystem_Derp (player, 2, "S7_LaserPewPew");
            // Heavy
            WeapBindsSystem_Derp (player, 3, "S7_ConquerorRifle");
            WeapBindsSystem_Derp (player, 3, "S7_Thumper");
            // Area-damage
            WeapBindsSystem_Derp (player, 4, "S7_PrettyShootyIonCannonGun");
            // Special
            WeapBindsSystem_Derp (player, 5, "S7_GrenadeWeap");
            WeapBindsSystem_Derp (player, 5, "S7_SoulLance");
        }
    }
    void WeapBindsSystem_Derp (PlayerInfo player, int slot, string weapon) {
        if (!player) return;
        let weapBinds = S7_WeapBindsSystem (player.mo.FindInventory ("S7_WeapBindsSystem"));
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