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

/** Math extensions **/
extend class S7_Math {
    static Vector2 Vec2Mul (Vector2 lhs, Vector2 rhs) {
        return (lhs.X * rhs.X, lhs.Y * rhs.Y);
    }

    static Vector3 Vec3Mul (Vector3 lhs, Vector3 rhs) {
        return (lhs.X * rhs.X, lhs.Y * rhs.Y, lhs.Z * rhs.Z);
    }

    static Vector2 Vec2Div (Vector2 lhs, Vector2 rhs) {
        return (lhs.X / rhs.X, lhs.Y / rhs.Y);
    }

    static Vector3 Vec3Div (Vector3 lhs, Vector3 rhs) {
        return (lhs.X / rhs.X, lhs.Y / rhs.Y, lhs.Z / rhs.Z);
    }

    static Vector2 Vec2Mod (Vector2 lhs, Vector2 rhs) {
        return (lhs.X % rhs.X, lhs.Y % rhs.Y);
    }

    static Vector3 Vec3Mod (Vector3 lhs, Vector3 rhs) {
        return (lhs.X % rhs.X, lhs.Y % rhs.Y, lhs.Z % rhs.Z);
    }

    static Vector2 ClampVec2Length (Vector2 vec, double maxLen) {
        let vecSqr = vec dot vec;
        if (vecSqr <= (maxLen * maxLen))
            return vec;
        return vec / sqrt (vecSqr) * maxLen;
    }

    static Vector3 ClampVec3Length (Vector3 vec, double maxLen) {
        let vecSqr = vec dot vec;
        if (vecSqr <= (maxLen * maxLen))
            return vec;
        return vec / sqrt (vecSqr) * maxLen;
    }

    static Vector2 Lerp2 (Vector2 x, Vector2 y, double a) {
        return x * (1 - a) + y * a;
    }

    static Vector3 Lerp3 (Vector3 x, Vector3 y, double a) {
        return x * (1 - a) + y * a;
    }

    /* Summary:
    **  Performs a spherical linear interpolation on two vectors.
    **  NOTE: This operation is not commutative, swapping the start and end points will give a different result.
    **
    ** Arguments:
    **  start: The starting point of the interpolation.
    **  end: The end point of the interpolation.
    **  t: How much to interpolate towards the end point.
    **
    ** Returns:
    **  The new slerped angle between the start and end vectors.
    */
    static Vector2 Slerp2 (Vector2 start, Vector2 end, double t) {
        let dotVal = start dot end;

        // `acos(dot)` returns the angle between start and end, and multiplying that by percent returns the angle
        // between start and the final result.
        let theta = acos (dotVal) * t;
        let relativeVec = (end - start * dotVal).Unit ();

        // Orthonormal basis. The final result.
        return (start * cos (theta) + relativeVec * sin (theta));
    }

    /* Summary:
    **  Performs a spherical linear interpolation on two vectors.
    **  NOTE: This operation is not commutative, swapping the start and end points will give a different result.
    **
    ** Arguments:
    **  start: The starting point of the interpolation.
    **  end: The end point of the interpolation.
    **  t: How much to interpolate towards the end point.
    **
    ** Returns:
    **  The new slerped angle between the start and end vectors.
    */
    static Vector3 Slerp3 (Vector3 start, Vector3 end, double t) {
        let dotVal = start dot end;

        // `acos(dot)` returns the angle between start and end, and multiplying that by percent returns the angle
        // between start and the final result.
        let theta = acos (dotVal) * t;
        let relativeVec = (end - start * dotVal).Unit ();

        // Orthonormal basis. The final result.
        return (start * cos (theta) + relativeVec * sin (theta));
    }
}