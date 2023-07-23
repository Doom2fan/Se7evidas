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

class S7_3DFloorPointer play {
    Sector ownerSector;
    int ffloorIndex;

    F3DFloor Get3DFloor () {
        return ownerSector.Get3DFloor (ffloorIndex);
    }

    static S7_3DFloorPointer FromF3DFloor (F3DFloor ffloor) {
        let owner = ffloor.target;

        int ffloorCount = owner.Get3DFloorCount ();
        for (int i = 0; i < ffloorCount; i++) {
            let cur3DFloor = owner.Get3DFloor (i);
            if (cur3DFloor == ffloor) {
                let ptr = new ('S7_3DFloorPointer');

                ptr.ownerSector = owner;
                ptr.ffloorIndex = i;

                return ptr;
            }
        }

        ThrowAbortException ("Error in S7_3DFloorPointer.FromF3DFloor: Could not find 3D floor???");
        return null;
    }
}

struct S7_Utils {
    /* Summary:
    **  Generates a random male english name.
    **
    ** Returns:
    **  Returns a string with the generated name and surname.
    */
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

    /* Summary:
    **  Creates a 32-bit UID from 4 characters.
    **
    ** Arguments:
    **  a: The first character.
    **  b: The second character.
    **  c: The third character.
    **  d: The fourth character.
    **
    ** Returns:
    **  Returns an UID composed from the input characters.
    */
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

    /* Summary:
    **  Trims zeroes from a string.
    **
    ** Arguments:
    **  inputStr: The input string.
    **
    ** Returns:
    **  Returns the input string with leading and trailing zeroes removed.
    */
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

    /* Summary:
    **  Sorts a dynamic array of ints using the quicksort algorithm.
    **
    ** Arguments:
    **  arr: The array to sort.
    **  l: The lower bound of the sub-array.
    **  r: The upper bound of the sub-array.
    **
    ** Returns:
    **  Returns void.
    */
    static void QuicksortInt (out Array<int> arr, int l, int r) {
        // Base case: No need to sort arrays of length <= 1
        if (l >= r)
            return;

        // Choose pivot to be the last element in the subarray
        int pivot = arr [r];

        // Index indicating the "split" between elements smaller than pivot and
        // elements greater than pivot
        int cnt = l;

        // Traverse through array from l to r
        for (int i = l; i <= r; i++) {
            // If an element less than or equal to the pivot is found...
            if (arr [i] <= pivot) {
                // Then swap arr [cnt] and arr [i] so that the smaller element arr [i]
                // is to the left of all elements greater than pivots
                int tmp = arr [cnt];
                arr [cnt] = arr [i];
                arr [i] = tmp;

                // Make sure to increment cnt so we can keep track of what to swap
                // arr [i] with
                cnt++;
            }
        }

        // NOTE: cnt is currently at one plus the pivot's index
        // (Hence, the cnt-2 when recursively sorting the left side of pivot)
        QuicksortInt (arr, l  , cnt - 2); // Recursively sort the left side of pivot
        QuicksortInt (arr, cnt,       r); // Recursively sort the right side of pivot
    }
}

class S7_BoundingBox {
    enum BoxSides {
        BoxTop,
        BoxBottom,
        BoxLeft,
        BoxRight
    };

    protected double m_Box [4];

    static S7_BoundingBox Create (Vector2 pos, double radius) {
        let ret = new ('S7_BoundingBox');

        ret.SetBox (pos, radius);

        return ret;
    }

    void SetBox (Vector2 pos, double radius) {
        m_Box [BoxTop   ] = pos.Y + radius;
        m_Box [BoxLeft  ] = pos.X - radius;
        m_Box [BoxRight ] = pos.X + radius;
        m_Box [BoxBottom] = pos.Y - radius;
    }

    void ClearBox () {
        m_Box [BoxTop   ] = m_Box [BoxRight] = -float.Max;
        m_Box [BoxBottom] = m_Box [BoxLeft ] = float.Max;
    }

    bool inRange (in Line ld) const {
        return (
            m_Box [BoxLeft  ] < ld.bbox [BoxRight ] &&
            m_Box [BoxRight ] > ld.bbox [BoxLeft  ] &&
            m_Box [BoxTop   ] > ld.bbox [BoxBottom] &&
            m_Box [BoxBottom] < ld.bbox [BoxTop   ]
        );
    }

    int BoxOnLineSide (in Line ld) const {
        int p1, p2;

        if (ld.delta.X ~== 0) {
            // ST_Vertical
            p1 = m_Box [BoxRight] < ld.v1.p.X;
            p2 = m_Box [BoxLeft ] < ld.v1.p.X;
            if (ld.delta.Y < 0) {
                p1 ^= 1;
                p2 ^= 1;
            }
        } else if (ld.delta.Y ~== 0) {
            // ST_Horizontal:
            p1 = m_Box [BoxTop   ] > ld.v1.p.X;
            p2 = m_Box [BoxBottom] > ld.v1.p.Y;

            if (ld.delta.X < 0) {
                p1 ^= 1;
                p2 ^= 1;
            }
        } else if ((ld.delta.X * ld.delta.Y) >= 0) {
            // ST_Positive:
            p1 = S7_Math.PointOnLineSidePrecise (m_Box [BoxLeft ], m_Box [BoxTop   ], ld);
            p2 = S7_Math.PointOnLineSidePrecise (m_Box [BoxRight], m_Box [BoxBottom], ld);
        } else {
            // ST_Negative:
            p1 = S7_Math.PointOnLineSidePrecise (m_Box [BoxRight], m_Box [BoxTop   ], ld);
            p2 = S7_Math.PointOnLineSidePrecise (m_Box [BoxLeft ], m_Box [BoxBottom], ld);
        }

        return (p1 == p2) ? p1 : -1;
    }
}

struct SArrayVector2 {
    private Array<double> pointsX;
    private Array<double> pointsY;

    Vector2 Index (int i) {
        return (pointsX [i], pointsY [i]);
    }

    int Size () {
        return pointsX.Size ();
    }

    void Push (Vector2 p) {
        pointsX.Push (p.X);
        pointsY.Push (p.Y);
    }

    void Insert (uint index, Vector2 p) {
        pointsX.Insert (index, p.X);
        pointsY.Insert (index, p.Y);
    }

    void Delete (uint index, int n = 1) {
        pointsX.Delete (index, n);
        pointsY.Delete (index, n);
    }

    void Clear () {
        pointsX.Clear ();
        pointsY.Clear ();
    }

    void ShrinkToFit () {
        pointsX.ShrinkToFit ();
        pointsY.ShrinkToFit ();
    }

    void Copy (SArrayVector2 other) {
        pointsX.Copy (other.pointsX);
        pointsY.Copy (other.pointsY);
    }

    void Move (SArrayVector2 other) {
        pointsX.Move (other.pointsX);
        pointsY.Move (other.pointsY);
    }
}