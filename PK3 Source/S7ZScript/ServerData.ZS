class S7_MapData : Thinker {
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
}

class S7_ServerData : Thinker {
    S7_ShopData shopData;
    uint mapCount;
    // Map events
    int queuedMapEvent;
    // Level system
    int maxLevel;
    int avgLevel, highestLevel, lowestLevel;

    S7_ServerData Init () {
        ChangeStatNum (STAT_STATIC);
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