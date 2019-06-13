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

class S7_Math {
    /** General math **/
    static double Lerp (double x, double y, double a) {
        return x * (1-a) + y * a;
    }

    // Based on C/C++ example implementation by AMD, taken from Wikipedia.
    static double Smoothstep (double edge0, double edge1, double x) {
        // Scale, bias and saturate x to [0, 1] range
        x = clamp ((x - edge0) / (edge1 - edge0), 0., 1.);
        // Evaluate polynomial
        return x * x * (3. - 2. * x);
    }
}