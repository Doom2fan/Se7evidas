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

class S7_MapEventThinker : Thinker {
    static void Init (S7_ServerData serverData, S7_MapData mapData) {
        let meThinker = Get ();

        if (!meThinker) {
            meThinker = new ('S7_MapEventThinker');
            meThinker.ChangeStatNum (STAT_Info);
        }

        if (!serverData)
            serverData = S7_ServerData.Get ();
        if (!mapData)
            mapData = S7_MapData.Get ();

        meThinker.SetupMapEvents (serverData, mapData);
    }

    static S7_MapEventThinker Get () {
        ThinkerIterator it = ThinkerIterator.Create ('S7_MapEventThinker', STAT_Info);
        return S7_MapEventThinker (it.Next ());
    }

    void SetupMapEvents (S7_ServerData serverData, S7_MapData mapData) {
        if (mapData.mapEventSet) // Don't set map events up twice.
            return;

        //serverData.queuedMapEvent = S7_MEVNT_PerfectHatred;//S7_DebugOpts;//S7_MEVNT_PowerOutage;
        mapData.mapEvent = serverData.queuedMapEvent;
        serverData.queuedMapEvent = S7_MEVNT_None;

        do {
            mapData.mapEventSet = true;

            switch (mapData.mapEvent) {
                case S7_MEVNT_None: break;

                case S7_MEVNT_PowerOutage: {
                    let sky = TexMan.CheckForTexture ("NEBSKY", TexMan.Type_Any);
                    level.ChangeSky (sky, sky); // Change the sky

                    SetAllLight (64, true);
                }
                break;

                case S7_MEVNT_PerfectHatred:
                    PerfectHatred_Setup (serverData, mapData);
                    break;

                case S7_MEVNT_GhostTown: {
                    S_ChangeMusic ("", force: true); // Remove the music
                    let spot = Actor.Spawn ('MapSpot', (0.0, 0.0, 0.0), NO_REPLACE); // Spawn a mapspot
                    spot.A_StartSound ("MapEvents/GhostTown/Wind", slot: CHAN_Body, flags: CHANF_ListenerZ | CHANF_NoPause | CHANF_Looping, attenuation: ATTN_None); // Play a wind sound on it
                }
                break;

                default: {
                    MapData.mapEvent = random [S7_MapEvents] (S7_MEVNT_None + 1, S7_MEVNT_LastToken - 1);
                    mapData.mapEventSet = false; // Set it back to false. This will make it loop.
                }
                break;
            }
        } while (!mapData.mapEventSet);
    }

    void TickMapEvents (S7_ServerData serverData, S7_MapData mapData) {
        switch (MapData.mapEvent) {
            case S7_MEVNT_PowerOutage: {
                let sky = TexMan.CheckForTexture ("NEBSKY", TexMan.Type_Any);
                level.ChangeSky (sky, sky); // Change the sky
                SetAllLight (64, ((level.time % 5) == 0));
            }
            break;

            case S7_MEVNT_PerfectHatred:
                PerfectHatred_Tick (serverData, mapData);
                break;

            case S7_MEVNT_GhostTown: {
                S_ChangeMusic ("", force: true); // Remove the music
            }
            break;
        }
    }

    /** Utility functions **/
    void SetAllLight (int lightLevel, bool removeEffects) {
        if (removeEffects) {
            ThinkerIterator it = ThinkerIterator.Create ('Lighting');
            Lighting effect;

            while (effect = Lighting (it.Next ()))
                effect.Destroy ();
        }

        for (int i = 0; i < level.Sectors.Size (); i++) {
            Sector s = level.Sectors [i];
            s.SetLightLevel (lightLevel);
        }
    }
}