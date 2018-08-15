/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

struct S7_Utils {
    static string GenName_Male_Eng () {
        int fore = random [nameGen] (0, S7_NamesList.NL_Male_Eng_Fore.Size () - 1);
        int sur  = random [nameGen] (0, S7_NamesList.NL_Male_Eng_Sur.Size ()  - 1);

        for (int i = 0; i < 50; i++) {
            if (S7_NamesList.NL_Male_Eng_Fore [fore] ~== S7_NamesList.NL_Male_Eng_Sur [sur])
                sur = random [nameGen] (0, S7_NamesList.NL_Male_Eng_Sur.Size () - 1);
            else
                break;
        }

        return String.Format ("%s %s", S7_NamesList.NL_Male_Eng_Fore [fore], S7_NamesList.NL_Male_Eng_Sur [sur]);
    }

    static int MakeUID (string a, string b, string c, string d) {
        if (a.Length () + b.Length () + c.Length () + d.Length () != 4)
            return 0;

        return (a.CharCodeAt (0) << 24 | b.CharCodeAt (0) << 16 | c.CharCodeAt (0) << 8 | d.CharCodeAt (0));
    }
}