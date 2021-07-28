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

    static vector2 ProjectPointToLineGZD (LevelLocals level, in Line l, Vector2 point) {
        let ap = level.Vec2Diff (l.v1.p, point);

        return l.v1.p + (ap dot l.delta) / (l.delta dot l.delta) * l.delta;
    }
}