/** CVar manipulation **/
class S7_PlayerCVar {
    static int GetInt (PlayerInfo player, string cvarName) {
        if (!player)
            return 0;

        let tmpVar = CVar.GetCVar (cvarName, player);

        return tmpVar.GetInt ();
    }
    static double GetFloat (PlayerInfo player, string cvarName) {
        if (!player)
            return double.NaN;

        let tmpVar = CVar.GetCVar (cvarName, player);

        return tmpVar.GetFloat ();
    }
    static string GetString (PlayerInfo player, string cvarName) {
        if (!player)
            return "";

        let tmpVar = CVar.GetCVar (cvarName, player);

        return tmpVar.GetString ();
    }

    static void SetInt (PlayerInfo player, string cvarName, int val) {
        if (!player)
            return;

        let tmpVar = CVar.GetCVar (cvarName, player);

        tmpVar.SetInt (val);
    }
    static void SetFloat (PlayerInfo player, string cvarName, double val) {
        if (!player)
            return;

        let tmpVar = CVar.GetCVar (cvarName, player);

        tmpVar.SetFloat (val);
    }
    static void SetString (PlayerInfo player, string cvarName, string val) {
        if (!player)
            return;

        let tmpVar = CVar.GetCVar (cvarName, player);

        tmpVar.SetString (val);
    }

    static void ResetToDefault (PlayerInfo player, string cvarName) {
        if (!player)
            return;

        let tmpVar = CVar.GetCVar (cvarName, player);

        tmpVar.ResetToDefault ();
    }
}