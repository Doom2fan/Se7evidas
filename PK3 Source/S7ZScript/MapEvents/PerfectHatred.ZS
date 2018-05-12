extend class S7_MapEventThinker {
    void PerfectHatred_Setup (S7_ServerData serverData, S7_MapData mapData) {
        let sky = TexMan.CheckForTexture ("ATWSKY", TexMan.Type_Any);
        level.ChangeSky (sky, sky); // Change the sky
        S_ChangeMusic ("", force: true); // Remove the music

        SetAllLight (16, true);
    }

    void PerfectHatred_Tick (S7_ServerData serverData, S7_MapData mapData) {
        let sky = TexMan.CheckForTexture ("ATWSKY", TexMan.Type_Any);
        level.ChangeSky (sky, sky); // Change the sky
        S_ChangeMusic ("", force: true); // Remove the music

        SetAllLight (16, ((level.time % 5) == 0));

        if (level.mapTime == 0) {
            Array<S7_MapData_SpawnPos> spawnSpots;
            spawnSpots.Copy (mapData.monsterSpawnPos);

            for (int i = 0; i < spawnSpots.Size (); i++) {
                Actor.Spawn ("S7_MEATW_Eyes", spawnSpots [i].pos);
            }
        }
    }
}

class S7_MEATW_Eyes : S7_EffectsBase {
    default {
        Scale 0.1;
        RenderStyle "Translucent";

        Tag "";

        +NOGRAVITY +CANNOTPUSH +INVULNERABLE +FORCEXYBILLBOARD
        +NODAMAGE  +NOTELEPORT
    }

    states {
    Spawn:
        MATW A 1 bright {
            let cam = players [consoleplayer].camera;

            double dist = Distance3D (cam);

            alpha = clamp ((1.0 / (1024-1000)) * (dist - 1000), 0.0, 1.0);

            return ResolveState (null);
        }
        loop;

    Death:
        stop;
    }
}