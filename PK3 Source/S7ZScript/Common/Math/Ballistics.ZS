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
    /** Target interception **/
    /* Summary:
    **  Calculates the future position of a moving target so that a projectile launched immediately can hit it.
    **  Taken from the GameDev.net article "Shooting at stuff" (https://www.gamedev.net/articles/programming/math-and-physics/shooting-at-stuff-r3884/)
    **  Modified for use in 3D in GZDoom by Chronos "phantombeta" Ouroboros.
    **  Dual-licensed under the GPL3 and Zlib licenses - this function can be used under the terms of either license.
    **
    ** Arguments:
    **  shooterPos: The shooter's position.
    **  targetPos: The target's position.
    **  targetVel: The target's velocities.
    **  projSpeed: The projectile's speed.
    **
    ** Returns:
    **  The position that the intercept will occur at. The function will return null if a solution cannot be found.
    **  Consider the case of a target moving away from the shooter faster than the speed of the projectile and you will see at least one case where this calculation may fail.
    */
    static bool, Vector3 CalculateInterceptShotPosition (LevelLocals lvl, Vector3 projPos, Vector3 targetPos, Vector3 targetVel, double projSpeed) {
    // This formulation uses the quadratic equation to solve
    // the intercept position.
        Vector3 R = lvl.Vec3Diff (projPos, targetPos);
        double a = (targetVel dot targetVel) - (projSpeed ** 2);
        double b = 2. * (R dot targetVel);
        double c = R dot R;
        double tBullet = 0.;

        // If the target and the shooter have already collided, don't bother.
        if (c < double.Min_Normal)
            return false, (double.NaN, double.NaN, double.NaN);

        // If the squared velocity of the target and the bullet are the same, the equation
        // collapses to tBullet*b = -c. If they are REALLY close to each other (float tol),
        // you could get some weirdness here. Do some "is it close" checking?
        if (abs (a) < double.Min_Normal) {
            // If the b value is 0, we can't get a solution.
            if (abs (b) < double.Min_Normal)
                return false, (double.NaN, double.NaN, double.NaN);

            tBullet = -c / b;
        } else {
            // Calculate the discriminant to figure out how many solutions there are.
            double discriminant = b*b - 4. * a * c;

            if (discriminant < 0.) // All solutions are complex.
                return false, (double.NaN, double.NaN, double.NaN);

            if (discriminant > 0.) {
                // Two solutions. Pick the smaller one.
                // Calculate the quadratic.
                double quad = sqrt (discriminant);
                double tBullet1 = (-b + quad) / (2. * a);
                double tBullet2 = (-b - quad) / (2. * a);

                if ((tBullet1 < 0.) && (tBullet2 < 0.)) // This would be really odd. Both times are negative.
                    return false, (double.NaN, double.NaN, double.NaN);
                else if (tBullet2 < 0. && tBullet1 >= 0.) // One negative, one positive.
                    tBullet = tBullet1;
                else if (tBullet1 < 0. && tBullet2 >= 0.) // One negative, one positive.
                    tBullet = tBullet2;
                else if (tBullet1 < tBullet2) // First less than second
                    tBullet = tBullet1;
                else // Only choice left
                    tBullet = tBullet2;
            } else
                tBullet = -b / (2. * a);
        }

        // If the time is negative, we can't get there from here.
        if (tBullet < 0.)
            return false, (double.NaN, double.NaN, double.NaN);

        // Calculate the intercept position.
        return true, lvl.Vec3Offset (targetPos, tBullet * targetVel);
    }

    /** Ballistic trajectory correction **/
    /* Summary:
    **  Calculates the correct pitch a shooter needs to fire a gravity-affected projectile at to have it hit the target.
    **  Written by Chronos "phantombeta" Ouroboros. The equations were taken from Wikipedia.
    **
    ** Arguments:
    **  shooterPos: The shooter's position.
    **  targetPos: The target's position.
    **  v: The projectile's speed.
    **  grav: The projectile's gravity multiplier.
    **
    ** Returns:
    **  The pitch that the projectile will need to be fired at. Actually returns two doubles.
    */
    static double, double InterceptShotPitch (LevelLocals lvl, Vector3 shooterPos, Vector3 targetPos, double v, double g) {
        Vector3 vecDiff = lvl.vec3Diff (shooterPos, targetPos);
        double x = vecDiff.XY.Length (),
               y = vecDiff.Z;

        double vSqr = v ** 2;
        double sq = (v ** 4) - g*(g*(x ** 2) + 2 * y * (vSqr));

        if (sq >= 0 && !(sq != sq)) {
            sq = sqrt (sq);
            double x1 = atan2 ((vSqr) + sq, g * x);
            double x2 = atan2 ((vSqr) - sq, g * x);

            return x1, x2;
        } else
            return double.NaN, double.NaN;
    }
}