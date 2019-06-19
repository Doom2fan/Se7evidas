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
    /* Summary:
    **  Checks if a sphere intersects an AABB.
    **
    ** Arguments:
    **  sphereCoords: The coordinates of the sphere.
    **  sphereRadius: The radius of the sphere.
    **  boxCoords: The coordinates of the AABB.
    **  boxSize: The radius and height of the AABB.
    **
    ** Returns:
    **  Returns true if the sphere intersects the AABB, false otherwise.
    */
    static bool TestSphereAABB (Vector3 sphereCoords, double sphereRadius, Vector3 boxCoords, Vector2 boxSize) {
        // Compute squared distance between sphere center and AABB
        // the sqrt (dist) is fine to use as well, but this is faster.
        float sqDist = 0.0f;

        let diffCoords = level.Vec3Diff (sphereCoords, boxCoords);

        Vector3 bMin = (
            diffCoords.X - boxSize.X,
            diffCoords.Y - boxSize.X,
            diffCoords.Z
        );
        Vector3 bMax = (
            diffCoords.X + boxSize.X,
            diffCoords.Y + boxSize.X,
            diffCoords.Z + boxSize.Y
        );

        // For each axis count any excess distance outside box extents
        // X
        if (bMin.X > 0) sqDist += (bMin.X) * (bMin.X);
        if (bMax.X < 0) sqDist += (bMax.X) * (bMax.X);
        // Y
        if (bMin.Y > 0) sqDist += (bMin.Y) * (bMin.Y);
        if (bMax.Y < 0) sqDist += (bMax.Y) * (bMax.Y);
        // Z
        if (bMin.Z > 0) sqDist += (bMin.Z) * (bMin.Z);
        if (bMax.Z < 0) sqDist += (bMax.Z) * (bMax.Z);

        // Sphere and AABB intersect if the (squared) distance between them is
        // less than the (squared) sphere radius.
        return sqDist <= sphereRadius * sphereRadius;
    }

    /* Summary:
    **  Checks if an AABB intersects another.
    **
    ** Arguments:
    **  box1Coords: The coordinates of the first AABB.
    **  box1Size: The radius and height of the first AABB.
    **  box2Coords: The coordinates of the second AABB.
    **  box2Size: The radius and height of the second AABB.
    **  no_z: A boolean indicating whether to test the Z axis.
    **
    ** Returns:
    **  Returns true if the sphere intersects the AABB, false otherwise.
    */
    static bool TestAABB (Vector3 box1Coords, Vector2 box1Size, Vector3 box2Coords, Vector2 box2Size, bool no_z = false) {
        double blockDist = box2Size.X + box1Size.X;

        let diff = level.Vec2Diff (box1Coords.XY, box2Coords.XY);

        if (abs (diff.X) >= blockDist || abs (diff.Y) >= blockDist)
            return false;

        if (!no_z && (box1Coords.Z >= (box2Coords.Z + box2Size.Y) || (box1Coords.Z + box1Size.Y) <= box2Coords.Z))
            return false;

        return true;
    }
}