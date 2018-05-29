class S7_MapEventThinker : Thinker {
    static void Init (S7_ServerData serverData, S7_MapData mapData) {
        let meThinker = Get ();

        if (!meThinker) {
            meThinker = new ("S7_MapEventThinker");
            meThinker.ChangeStatNum (STAT_INFO);
        }

        if (!serverData)
            serverData = S7_ServerData.Get ();
        if (!mapData)
            mapData = S7_MapData.Get ();

        meThinker.SetupMapEvents (serverData, mapData);
    }

    static S7_MapEventThinker Get () {
        ThinkerIterator it = ThinkerIterator.Create ("S7_MapEventThinker", STAT_INFO);
        return S7_MapEventThinker (it.Next ());
    }

    void SetupMapEvents (S7_ServerData serverData, S7_MapData mapData) {
        if (mapData.mapEventSet) // Don't set map events up twice.
            return;

        //serverData.queuedMapEvent = MEVNT_PerfectHatred;//S7_DebugOpts;//MEVNT_PowerOutage;
        mapData.mapEvent = serverData.queuedMapEvent;
        serverData.queuedMapEvent = MEVNT_None;

        do {
            mapData.mapEventSet = true;

            switch (mapData.mapEvent) {
                case MEVNT_None: break;

                case MEVNT_PowerOutage: {
                    let sky = TexMan.CheckForTexture ("NEBSKY", TexMan.Type_Any);
                    level.ChangeSky (sky, sky); // Change the sky

                    SetAllLight (64, true);
                }
                break;

                case MEVNT_PerfectHatred:
                    PerfectHatred_Setup (serverData, mapData);
                    break;

                case MEVNT_GhostTown: {
                    S_ChangeMusic ("", force: true); // Remove the music
                    let spot = Actor.Spawn ("MapSpot", (0.0, 0.0, 0.0)); // Spawn a mapspot
                    spot.A_PlaySound ("MapEvents/GhostTown/Wind", CHAN_Body | CHAN_ListenerZ | CHAN_NoPause, 1.0, true, ATTN_None); // Play a wind sound on it
                }
                break;

                default: {
                    MapData.mapEvent = random [S7_MapEvents] (MEVNT_None + 1, MEVNT_LastToken - 1);
                    mapData.mapEventSet = false; // Set it back to false. This will make it loop.
                }
                break;
            }
        } while (!mapData.mapEventSet);
    }

    void TickMapEvents (S7_ServerData serverData, S7_MapData mapData) {
        switch (MapData.mapEvent) {
            case MEVNT_PowerOutage: {
                let sky = TexMan.CheckForTexture ("NEBSKY", TexMan.Type_Any);
                level.ChangeSky (sky, sky); // Change the sky
                SetAllLight (64, ((level.time % 5) == 0));
            }
            break;

            case MEVNT_PerfectHatred:
                PerfectHatred_Tick (serverData, mapData);
                break;

            case MEVNT_GhostTown: {
                S_ChangeMusic ("", force: true); // Remove the music
            }
            break;
        }
    }

    /** Utility functions **/
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
}