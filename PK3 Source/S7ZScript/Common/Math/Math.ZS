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
class S7_Math {
    /** Constants **/
    const Pi  = 3.14159265358979323846264338328;
    const Tau = Pi * 2.;
    const PiOverTwo   = Pi / 2.;
    const PiOverFour  = Pi / 4.;
    const PiOverEight = Pi / 8.;

    const SqrtTwo = 1.41421356237309504880168872421;

    const VM_Epsilon = (1. / 65536.);

    /** General math **/
    static double Lerp (double x, double y, double a) {
        return x * (1-a) + y * a;
    }

    static int SignI (int s) {
        if (s > 0)
            return 1;
        if (s < 0)
            return -1;

        return 0;
    }

    static int SignF (double s) {
        if (s > 0)
            return 1;
        if (s < 0)
            return -1;

        return 0;
    }

    // Based on C/C++ example implementation by AMD, taken from Wikipedia.
    static double Smoothstep (double edge0, double edge1, double x) {
        // Scale, bias and saturate x to [0, 1] range
        x = clamp ((x - edge0) / (edge1 - edge0), 0., 1.);
        // Evaluate polynomial
        return x * x * (3. - 2. * x);
    }

    static double, double GenerateGaussianNoise (S7_FastRNG rng, double mean, double stddev) {
        double u, v, s;
        do {
            u = rng.GetFloat (-1., 1.);
            v = rng.GetFloat (-1., 1.);
            s = u * u + v * v;
        } while (s == 0. || s >= 1.);

        let fac = sqrt (-2. * log (s) / s);
        let z0 = u * fac;
        let z1 = v * fac;

        return (z0 * stddev + mean), (z1 * stddev + mean);
    }
}