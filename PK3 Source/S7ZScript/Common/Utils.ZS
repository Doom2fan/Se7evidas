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

        return (a.ByteAt (0) << 24 | b.ByteAt (0) << 16 | c.ByteAt (0) << 8 | d.ByteAt (0));
    }

    static int MakeUIDStr (string val) {
        if (val.Length () != 4)
            return 0;

        return (val.ByteAt (0) << 24 | val.ByteAt (1) << 16 | val.ByteAt (2) << 8 | val.ByteAt (3));
    }

    static string TrimZeroes (string inputStr) {
        int inputSize = inputStr.Length ();

        int lastLeadingZero = -1;
        int firstTrailingZero = inputSize + 1;

        bool foundFirstNonZero = false;
        bool foundLastNonZero = false;

        for (int i = 0; i < inputSize; i++) {
            if (!foundFirstNonZero && inputStr.Mid (i, 1) != "0") {
                lastLeadingZero = i;
                foundFirstNonZero = true;
            }

            int j = (inputSize - 1) - i;
            if (!foundLastNonZero && inputStr.Mid (j, 1) != "0") {
                firstTrailingZero = j + 1;
                foundLastNonZero = true;
            }
        }

        return inputStr.Left (firstTrailingZero).Mid (lastLeadingZero);
    }
}

class S7_BoundingBox {
    enum BoxSides {
        BOXTOP,
        BOXBOTTOM,
        BOXLEFT,
        BOXRIGHT
    };

    protected double m_Box [4];

    static S7_BoundingBox Create (Vector2 pos, double radius) {
        let ret = new ('S7_BoundingBox');

        ret.SetBox (pos, radius);

        return ret;
    }

    void SetBox (Vector2 pos, double radius) {
        m_Box [BOXTOP   ] = pos.Y + radius;
        m_Box [BOXLEFT  ] = pos.X - radius;
        m_Box [BOXRIGHT ] = pos.X + radius;
        m_Box [BOXBOTTOM] = pos.Y - radius;
    }

    void ClearBox () {
        m_Box [BOXTOP   ] = m_Box [BOXRIGHT] = -float.Max;
        m_Box [BOXBOTTOM] = m_Box [BOXLEFT ] = float.Max;
    }

    bool inRange (in Line ld) const {
        return (
            m_Box [BOXLEFT  ] < ld.bbox[BOXRIGHT ] &&
            m_Box [BOXRIGHT ] > ld.bbox[BOXLEFT  ] &&
            m_Box [BOXTOP   ] > ld.bbox[BOXBOTTOM] &&
            m_Box [BOXBOTTOM] < ld.bbox[BOXTOP   ]
        );
    }

    int BoxOnLineSide (in Line ld) const {
        int p1, p2;

        if (ld.delta.X ~== 0) {
            // ST_VERTICAL
            p1 = m_Box [BOXRIGHT] < ld.v1.p.X;
            p2 = m_Box [BOXLEFT ] < ld.v1.p.X;
            if (ld.delta.Y < 0) {
                p1 ^= 1;
                p2 ^= 1;
            }
        } else if (ld.delta.Y ~== 0) {
            // ST_HORIZONTAL:
            p1 = m_Box [BOXTOP   ] > ld.v1.p.X;
            p2 = m_Box [BOXBOTTOM] > ld.v1.p.Y;

            if (ld.delta.X < 0) {
                p1 ^= 1;
                p2 ^= 1;
            }
        } else if ((ld.delta.X * ld.delta.Y) >= 0) {
            // ST_POSITIVE:
            p1 = S7_Math.PointOnLineSidePrecise (m_Box [BOXLEFT ], m_Box [BOXTOP   ], ld);
            p2 = S7_Math.PointOnLineSidePrecise (m_Box [BOXRIGHT], m_Box [BOXBOTTOM], ld);
        } else {
            // ST_NEGATIVE:
            p1 = S7_Math.PointOnLineSidePrecise (m_Box [BOXRIGHT], m_Box [BOXTOP   ], ld);
            p2 = S7_Math.PointOnLineSidePrecise (m_Box [BOXLEFT ], m_Box [BOXBOTTOM], ld);
        }

        return (p1 == p2) ? p1 : -1;
    }
}