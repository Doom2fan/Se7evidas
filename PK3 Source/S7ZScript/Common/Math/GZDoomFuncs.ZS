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
    **  Checks which side of a line a point is on.
    **
    ** Arguments:
    **  x: The X coordinates of the point to check.
    **  y: The Y coordinates of the point to check.
    **  ld: The line to check.
    **
    ** Returns:
    **  Returns 0 if on the line or in front of it or 1 if behind the line.
    */
    clearscope static int PointOnLineSidePrecise (double x, double y, in Line ld) {
        return ((y - ld.v1.p.Y) * ld.delta.X + (ld.v1.p.X - x) * ld.delta.Y) > S7C_EqualEpsilon;
    }

    /* Summary:
    **  Checks which side of a line a point is on.
    **
    ** Arguments:
    **  p: The point to check.
    **  v1: The first vertex of the line.
    **  v2: The second vertex of the line.
    **
    ** Returns:
    **  Returns 0 if on the line or in front of it or 1 if behind the line.
    */
    clearscope static int PointOnLineSide (Vector2 p, Vector2 v1, vector2 v2) {
        return (p.Y - v1.Y) * (v2.X - v1.X) - (p.X - v1.X) * (v2.Y - v1.Y);
    }

    /* Summary:
    **  Projects a 2D point onto a map line.
    **
    ** Arguments:
    **  level: The LevelLocals struct for the level the line belongs to.
    **  l: The line to project the point onto.
    **  pos: The point to project.
    **
    ** Returns:
    **  Returns a bool indicating whether the point lies on the segment, and the closest point.
    */
    static bool, Vector2 ProjectPointToMapLine (LevelLocals level, in Line l, Vector2 point) {
        let ap = level.Vec2Diff (l.v1.p, point);

        let t = (ap dot l.delta) / (l.delta dot l.delta);
        let onLine = (t >= 0. && t <= 1.);

        return onLine, (l.v1.p + t * l.delta);
    }
}