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

    /* Summary:
    **  Projects a 2D point onto a line segment.
    **
    ** Arguments:
    **  v1: The start vertex of the line segment.
    **  v2: The end vertex of the line segment.
    **  pos: The point to project onto the line segment.
    **
    ** Returns:
    **  Returns a bool indicating whether the point lies on the segment, and the closest point.
    */
    static bool, Vector2 ProjectPointToLine2D (Vector2 v1, Vector2 v2, Vector2 point) {
        let ap = level.Vec2Diff (v1, point);
        let delta = v2 - v1;

        let t = (ap dot delta) / (delta dot delta);
        let onLine = (t >= 0. && t <= 1.);

        return onLine, (v1 + t * delta);
    }

    /* Summary:
    **  Projects a 2D point onto a line segment.
    **
    ** Arguments:
    **  v1: The start vertex of the line segment.
    **  delta: The difference between the start and end vertices of the line segment. (v2 - v1)
    **  pos: The point to project onto the line segment.
    **
    ** Returns:
    **  Returns a bool indicating whether the point lies on the segment, and the closest point.
    */
    static bool, Vector2 ProjectPointToLine2D_Delta (Vector2 v1, Vector2 delta, Vector2 point) {
        let ap = level.Vec2Diff (v1, point);

        let t = (ap dot delta) / (delta dot delta);
        let onLine = (t >= 0. && t <= 1.);

        return onLine, (v1 + t * delta);
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
            point.Y += S7_Math.VM_Epsilon;

        if (point.Y < a.Y || point.Y > b.Y)
            return false;
        else if (point.X >= max (a.X, b.X))
            return false;
        else if (point.X < min (a.X, b.X))
            return true;

        let m_red = (a.X != b.X) ? ((b.Y - a.Y) / (b.X - a.X)) : double.infinity;
        let m_blue = (a.X != point.X) ? ((point.Y - a.Y) / (point.X - a.X)) : double.infinity;

        return m_blue >= m_red;
    }

    static bool RayIntersectsSegAuto (Vector2 point, Vector2 a, Vector2 b) {
        if (a.Y > b.Y)
            return RayIntersectsSeg (point, b, a);

        return RayIntersectsSeg (point, a, b);
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

    /* Summary:
    **  Checks if a ray intersects a segment.
    **
    ** Arguments:
    **  rayPos: The point from which the ray starts.
    **  rayDir: The direction of the ray.
    **  v1: The first end-point of the line segment.
    **  v2: The second end-point of the line segment.
    **  intersection: An output parameter which contains the point of intersection between the ray and the segment.
    **
    ** Returns:
    **  Returns a bool indicating whether the ray is intersecting the segment.
    */
    static bool, Vector2 RayLineSegIntersection (Vector2 rayPos, Vector2 rayDir, Vector2 v1, Vector2 v2) {
        let p1 = rayPos - v1;
        let p2 = v2 - v1;
        let p3 = (-rayDir.Y, rayDir.X);

        let dotVal = p2 dot p3;
        if (dotVal ~== 0)
            return false, (0, 0);

        let t1 = (p2.X * p1.Y - p2.Y * p1.X) / dotVal;
        let t2 = (p1 dot p3) / dotVal;

        if (t1 >= 0 && (t2 >= 0 && t2 <= 1))
            return true, rayPos + rayDir * t1;

        return false, (0, 0);
    }

    /* Summary:
    **  Determines whether a vertex is reflex or convex. The vertices must be sorted counter-clockwise.
    **
    ** Arguments:
    **  a: The previous vertex. (V-1)
    **  b: The vertex to check. (V)
    **  c: The next vertex. (V+1)
    **
    ** Returns:
    **  Returns true if the vertex is reflex, false if it's convex.
    */
    static bool IsVertexReflex (Vector2 a, Vector2 b, Vector2 c) {
        let v1 = b - a;
        let v2 = c - b;

        return (v1.X * v2.Y - v2.X * v1.Y) < 0;
    }
}

class S7_Polygon {
    Array<S7_Line> lines;
}

class S7_Line {
    Vector2 v1, v2;
}