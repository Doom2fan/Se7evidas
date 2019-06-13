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
    **  Simulates a damped spring.
    **
    ** Arguments:
    **  p: Current position
    **  r: Rest position
    **  v: Current velocity
    **  k: Spring coefficient
    **  d: Damping coefficient
    **
    ** Returns:
    **  The new velocity.
    */
    static double DampedSpring (double p, double r, double v, double k, double d) {
        return -(d * v) - (k * (p - r));
    }
}