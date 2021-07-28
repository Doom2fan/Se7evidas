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

extend class S7_Math {
    /** Trigonometry **/
    /* Summary:
    **  Gets the angle from a point to another.
    **
    ** Arguments:
    **  lvl: An instance of the LevelLocals struct.
    **  p1: The starting point.
    **  p2: The endpoint.
    **
    ** Returns:
    **  Returns the angle from p1 to p2.
    */
    static double GetAngleTo (LevelLocals lvl, Vector2 p1, Vector2 p2) {
        let diffVec = lvl.Vec2Diff (p1, p2);

        return VectorAngle (diffVec.X, diffVec.Y);
    }

    /* Summary:
    **  Gets the angle and pitch from a point to another.
    **
    ** Arguments:
    **  lvl: An instance of the LevelLocals struct.
    **  p1: The starting point.
    **  p2: The endpoint.
    **
    ** Returns:
    **  Returns the angle and pitch from p1 to p2.
    */
    static double, double GetAnglesTo (LevelLocals lvl, Vector3 p1, Vector3 p2) {
        let diffVec = lvl.Vec3Diff (p1, p2);

        double angle = VectorAngle (diffVec.X, diffVec.Y);
        double pitch = -VectorAngle (diffVec.XY.Length (), diffVec.Z);

        return angle, pitch;
    }

    /* Summary:
    **  Gets the angle and pitch of a 3D vector.
    **
    ** Arguments:
    **  vec: The vector.
    **
    ** Returns:
    **  Returns the angle and pitch of the vector.
    */
    static double, double GetVectorAngles (Vector3 vec) {
        double angle = VectorAngle (vec.X, vec.Y);
        double pitch = -VectorAngle (vec.XY.Length (), vec.Z);

        return angle, pitch;
    }

    /* Summary:
    **  Calculates a 3D vector with the specified yaw, pitch and length.
    **
    ** Arguments:
    **  yaw: The yaw of the vector.
    **  pitch: The pitch of the vector.
    **  length: The magnitude of the vector.
    **
    ** Returns:
    **  Returns a Vector3 of magnitude <length> with the specified yaw and pitch.
    */
    static Vector3 Vec3FromAngle (double yaw, double pitch, double length) {
        double pitchCos = cos (pitch);
        return (
            length * pitchCos * cos (yaw),
            length * pitchCos * sin (yaw),
            length * -sin (pitch)
        );
    }

    /* Summary:
    **  Gets the axis angles from yaw, pitch and roll.
    **
    ** Arguments:
    **  yaw
    **  pitch
    **  angle
    **
    ** Returns:
    **  Returns three vectors, one for each of X, Y and Z.
    */
    clearscope static Vector3, Vector3, Vector3 GetAxisAngles (double yaw, double pitch, double roll) {
        Vector3 forwards = (1, 0, 0),
                sideways = (0, 1, 0),
                vertical = (0, 0, 1);

        let qRot = S7_GM_Quaternion.CreateFromAngles (yaw, pitch, roll);

        forwards = qRot.RotateVector3 (forwards);
        sideways = qRot.RotateVector3 (sideways);
        vertical = qRot.RotateVector3 (vertical);

        return forwards, sideways, vertical;
    }

    /* Summary:
    **  Gets the axis angles from a quaternion.
    **
    ** Arguments:
    **  quat: The quaternion to use.
    **
    ** Returns:
    **  Returns three vectors, one for each of X, Y and Z.
    */
    clearscope static Vector3, Vector3, Vector3 GetAxesFromQuat (S7_GM_Quaternion quat) {
        Vector3 forwards = (1, 0, 0),
                sideways = (0, 1, 0),
                vertical = (0, 0, 1);

        forwards = quat.RotateVector3 (forwards);
        sideways = quat.RotateVector3 (sideways);
        vertical = quat.RotateVector3 (vertical);

        return forwards, sideways, vertical;
    }

    /* Summary:
    **  Reflects a vector around a normal.
    **
    ** Arguments:
    **  vec: The vector to reflect.
    **  normal: The normal to reflect the vector around.
    **
    ** Returns:
    **  Returns the reflected vector.
    */
    clearscope static Vector3 ReflectVector (Vector3 vec, Vector3 normal) {
        return (2 * (normal dot vec) * normal - vec).Unit ();
    }

    static vector2 ProjectPointToLine2D (Vector2 v1, Vector2 v2, Vector2 point) {
        let delta = v2 - v1;
        let ap = point - v1;

        return v1 + (ap dot delta) / (delta dot delta) * delta;
    }

    /* Summary:
    **  Calculates two orthogonal vectors from an arbitrary 3D vector.
    **
    ** Arguments:
    **  vec: The vector to calculate the orthogonal vectors from.
    **
    ** Returns:
    **  Returns two vectors orthogonal to the vector passed to the function.
    */
    clearscope static Vector3, Vector3 GetOrthoVecs (Vector3 vec) {
        if (vec ~== (0, 0, 0))
            return (0, 0, 0), (0, 0, 0);
        else if (vec.XY ~== (0, 0))
            return (1, 0, 0), (0, 1, 0);

        Vector3 orth0 = (-vec.y, vec.x, 0).Unit ();
        Vector3 orth1 = (vec cross orth0).Unit ();

        return orth0, orth1;
    }


    /* Summary:
    **  Calculates a random direction in a half-sphere around a normal vector.
    **
    ** Arguments:
    **  vec: The normal of the half-sphere.
    **  xy: Two random numbers in the range [0-1].
    **  orth0: A vector orthogonal to "vec". Must be different from orth1.
    **  orth1: A vector orthogonal to "vec". Must be different from orth0.
    **
    ** Returns:
    **  Returns a random 3D vector in a half-sphere around "vec".
    */
    clearscope static Vector3 RandomHalfSphereVecFromNormal (Vector3 vec, Vector2 xy, Vector3 orth0, Vector3 orth1) {
        if (vec ~== (0, 0, 0))
            return (0, 0, 0);

        if (xy dot xy > 1)
            xy = xy.Unit ();

        double z = sqrt (1 - xy.x * xy.x - xy.y * xy.y);
        Vector3 ret = (z * vec + xy.x * orth0 + xy.y * orth1);
        if (ret ~== (0, 0, 0))
            return (0, 0, 0);

        return ret.Unit ();
    }

    /** Polygons **/
    /* Summary:
    **  Calculates the smallest AABB that can hold a set of points.
    **
    ** Arguments:
    **  points: The set of vertices.
    **
    ** Returns:
    **  The XY origin of the rectangle and the rectangle's size.
    */
    static Vector2, Vector2 CalculateSmallestAABB (Array<double> points) {
        Vector2 origin = (int.Max, int.Max);
        Vector2 size = (int.Min, int.Min);

        for (int i = 0; i < points.Size (); i += 2) {
            Vector2 vertex = (points [i], points [i+1]);

            // Origin
            origin.X = min (origin.X, vertex.X);
            origin.Y = min (origin.Y, vertex.Y);
            // Size
            size.X = max (size.X, vertex.X);
            size.Y = max (size.Y, vertex.Y);
        }

        return origin, size;
    }

    /* Summary:
    **  Checks if a ray intersects a segment.
    **
    ** Arguments:
    **  point: The point from which the ray starts.
    **  a: The end-point of the segment with the smallest y coordinate. (A must be "below" B)
    **  b: The end-point of the segment with the greatest y coordinate (B must be "above" A)
    **
    ** Returns:
    **  Returns a bool indicating whether the ray is intersecting the segment.
    */
    static bool RayIntersectsSeg (Vector2 point, Vector2 a, Vector2 b) {
        if (point.Y == a.Y || point.Y == b.Y)
            point.Y += double.Epsilon;

        if (point.Y < a.Y || point.Y > b.Y)
            return false;
        else if (point.X >= max (a.X, b.X))
            return false;
        else {
            if (point.X < min (a.X, b.X))
                return true;
            else {
                double m_red, m_blue;

                if (a.X != b.X)
                    m_red = (b.Y - a.Y) / (b.X - a.X);
                else
                    m_red = double.infinity;

                if (a.X != point.X)
                    m_blue = (point.Y - a.Y) / (point.X - a.X);
                else
                    m_blue = double.infinity;

                if (m_blue >= m_red)
                    return true;
                else
                    return false;
            }
        }
    }

    /* Summary:
    **  Checks if a point is inside a polygon.
    **
    ** Arguments:
    **  point: The point to be checked.
    **  poly: The polygon.
    **
    ** Returns:
    **  Returns a bool indicating whether the point is inside the polygon.
    */
    static bool PointInPolygon (Vector2 point, S7_Polygon poly) {
        int count = 0;

        for (int i = 0; i < poly.lines.Size (); i++) {
            Vector2 a, b;

            if (poly.lines [i].v1.Y < poly.lines [i].v2.Y) {
                a = poly.lines [i].v1;
                b = poly.lines [i].v2;
            } else {
                a = poly.lines [i].v2;
                b = poly.lines [i].v1;
            }

            if (RayIntersectsSeg (point, a, b))
                count++;
        }

        return ((count & 1) == 1);
    }
}

class S7_Polygon {
    Array<S7_Line> lines;
}

class S7_Line {
    Vector2 v1, v2;
}