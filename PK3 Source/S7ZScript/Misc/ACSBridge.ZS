class S7_ACSBridge {
    static string GetVersion () {
        return String.Format ("%d.%d", S7C_MajorVersion, S7C_MinorVersion);
    }

    static int GetMapEvent () {
        let mapData = S7_MapData.GetSpecial ();

        if (!mapData)
            return 0;

        return mapData.mapEvent;
    }
}