class S7_MapData_SpawnPos {
    class<Actor> actorClass;
    Vector3 pos;
}
class S7_MapData : Thinker {
    // Spawn positions
    Array<S7_MapData_SpawnPos> monsterSpawnPos;

    // Map events
    int mapEvent;
    bool mapEventSet;

    S7_MapData Init () {
        ChangeStatNum (STAT_INFO);
        return self;
    }

    static S7_MapData Get () {
        ThinkerIterator it = ThinkerIterator.Create ("S7_MapData", STAT_INFO);
        let p = S7_MapData (it.Next ());

        if (!p)
            p = new ("S7_MapData").Init ();

        return p;
    }

    clearscope static S7_MapData GetSpecial () {
        ThinkerIterator it = ThinkerIterator.Create ("S7_MapData", STAT_STATIC);
        let p = S7_MapData (it.Next ());

        if (!p)
            return null;

        return p;
    }
}

class S7_ServerData : Thinker {
    S7_ShopData shopData;
    uint mapCount;
    // Map events
    int queuedMapEvent;
    // Level system
    int maxLevel;
    int avgLevel, highestLevel, lowestLevel;

    override void Tick () {
        avgLevel = 0;
        highestLevel = int.min;
        lowestLevel = int.max;

        int pCount;
        for (int i = 0; i < MAXPLAYERS; i++) {
            if (playeringame [i] && players [i].mo) {
                if (!(players [i].mo is "S7_BasePlayer"))
                    continue;

                let pPawn = S7_BasePlayer (players [i].mo);
                if (!pPawn) continue;
                let xpSys = pPawn.xpSys;
                if (!xpSys) continue;

                if (xpSys.level < lowestLevel)
                    lowestLevel = xpSys.level;
                if (xpSys.level > highestLevel)
                    highestLevel = xpSys.level;

                avgLevel += xpSys.level;
                pCount++;
            }
        }

        if (highestLevel == int.min)
            highestLevel = 0;
        if (lowestLevel == int.max)
            lowestLevel = 0;

        if (pCount > 0)
            avgLevel /= pCount;
    }

    S7_ServerData Init () {
        ChangeStatNum (STAT_STATIC);
        Tick ();
        return self;
    }

    static S7_ServerData Get () {
        ThinkerIterator it = ThinkerIterator.Create ("S7_ServerData", STAT_STATIC);
        let p = S7_ServerData (it.Next ());

        if (!p)
            p = new ("S7_ServerData").Init ();

        return p;
    }

    clearscope static S7_ServerData GetSpecial () {
        ThinkerIterator it = ThinkerIterator.Create ("S7_ServerData", STAT_STATIC);
        let p = S7_ServerData (it.Next ());

        if (!p)
            return null;

        return p;
    }
}