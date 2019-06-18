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

        double p [3] = { sphereCoords.X, sphereCoords.Y, sphereCoords.Z };
        double bMin [3] = {
            boxCoords.X - boxSize.X,
            boxCoords.Y - boxSize.X,
            boxCoords.Z
        };
        double bMax [3] = {
            boxCoords.X + boxSize.X,
            boxCoords.Y + boxSize.X,
            boxCoords.Z + boxSize.Y
        };

        for (int i = 0; i < 3; i++) {
            // For each axis count any excess distance outside box extents
            float v = p [i];
            if (v < bMin [i]) sqDist += (bMin [i] - v) * (bMin [i] - v);
            if (v > bMax [i]) sqDist += (v - bMax [i]) * (v - bMax [i]);
        }

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

        if (abs (box2Coords.X - box1Coords.X) >= blockDist || abs (box2Coords.Y - box1Coords.Y) >= blockDist)
            return false;

        if (!no_z && (box1Coords.Z > (box2Coords.Z + box2Size.Y) || (box1Coords.Z + box1Size.Y) <= box2Coords.Z))
            return false;

        return true;
    }
}