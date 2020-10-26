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

/** Implements a fast RNG **/
class S7_FastRNG {
    private bool initialized;
    int seed;

    static S7_FastRNG CreateWithSeed (int seed) {
        let ret = new ('S7_FastRNG');

        ret.initialized = true;
        ret.seed = seed;

        return ret;
    }

    static S7_FastRNG Create () {
        int seed = level.totaltime ^ random [S7_FastRNGSeed] (1, int.max - 1);

        // Hash function from https://stackoverflow.com/a/12996028
        seed = ((seed >>> 16) ^ seed) * 0x45d9f3b;
        seed = ((seed >>> 16) ^ seed) * 0x45d9f3b;
        seed = (seed >>> 16) ^ seed;

        return CreateWithSeed (seed);
    }

    void Hash () {
        seed = (seed + 0x7ED55D16) + (seed <<  12);
        seed = (seed ^ 0xC761C23C) ^ (seed >>> 19);
        seed = (seed + 0x165667B1) + (seed <<   5);
        seed = (seed + 0xD3A2646C) ^ (seed <<   9);
        seed = (seed + 0xFD7046C5) + (seed <<   3);
        seed = (seed ^ 0xB55A4F09) ^ (seed >>> 16);
    }

    int GetInt (int min, int max) {
        if (!initialized)
            ThrowAbortException ("S7_FastRNG: RNG must be created with S7_FastRNG.Create!");

        Hash ();

        if (max < min) {
            int tmp = min;
            min = max;
            max = tmp;
        }

        return ((seed & 0x7FFFFFFF) % (max - min + 1)) + min;
    }

    double GetFloat (double min, double max) {
        if (!initialized)
            ThrowAbortException ("S7_FastRNG: RNG must be created with S7_FastRNG.Create!");

        Hash ();
        double frandom = double (seed & 0x7FFFFFFF) / double (int.max);

        if (max < min) {
            double tmp = min;
            min = max;
            max = tmp;
        }

        return frandom * (max - min) + min;
    }
}