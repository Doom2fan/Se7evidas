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