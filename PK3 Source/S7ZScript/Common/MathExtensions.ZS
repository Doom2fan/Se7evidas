/** Math extensions **/
class S7_Math : actor {
    /** Target interception **/
    /* Summary:
    **  Calculates the future position of a moving target so that a projectile launched immediately can hit it.
    **  Taken from the GameDev.net article "Shooting at stuff" (https://www.gamedev.net/articles/programming/math-and-physics/shooting-at-stuff-r3884/)
    **  Modified for use in 3D in GZDoom by Chronos "phantombeta" Ouroboros.
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
    static Vector3 CalculateInterceptShotPosition (Vector3 shooterPos, Vector3 targetPos, Vector3 targetVel, double projSpeed) {
        // This formulation uses the quadratic equation to solve the intercept position.
        Vector3 R = targetPos - shooterPos;
        double a = targetVel.x*targetVel.x + targetVel.y*targetVel.y + targetVel.z*targetVel.z - projSpeed*projSpeed;
        double b = 2 * (R.x*targetVel.x + R.y*targetVel.y + R.z*targetVel.z);
        double c = R.x*R.x + R.y*R.y + R.z*R.z;
        double tBullet = 0;

        if (R.Length () < double.Min_Normal) // If the target and the shooter have already collided, don't bother.
            return (double.NaN, double.NaN, double.NaN);

        // If the squared velocity of the target and the bullet are the same, the equation collapses to tBullet*b = -c.  If they are REALLY close to each other,
        // you could get some weirdness here. Do some "is it close" checking?
        if (abs (a) < 2 * double.Min_Normal) {
            if (abs (b) < 2 * double.Min_Normal) // If the b value is 0, we can't get a solution.
                return (double.NaN, double.NaN, double.NaN);

            tBullet = -c / b;
        } else {
            // Calculate the discriminant to figure out how many solutions there are.
            double discriminant = b*b - 4 * a * c;
            if (discriminant < 0) // All solutions are complex.
                return (double.NaN, double.NaN, double.NaN);

            if (discriminant > 0) { // Two solutions.  Pick the smaller one.
                // Calculate the quadratic.
                double quad = sqrt (discriminant);

                double  tBullet1 = (-b + quad) / (2 * a),
                        tBullet2 = (-b - quad) / (2 * a);

                if (tBullet1 < 0.0 && tBullet2 < 0.0)            // This would be really odd.
                    return (double.NaN, double.NaN, double.NaN); // Both times are negative.
                else if (tBullet2 < 0.0 && tBullet1 >= 0.0) // One negative, one positive.
                    tBullet = tBullet1;
                else if (tBullet1 < 0.0 && tBullet2 >= 0.0) // One negative, one positive.
                    tBullet = tBullet2;
                else if (tBullet1 < tBullet2) // First less than second
                    tBullet = tBullet1;
                else // Only choice left
                    tBullet = tBullet2;
            } else
                tBullet = -b / (2 * a);
        }

        // If the time is negative, we can't get there from here.
        if (tBullet < 0)
            return (double.NaN, double.NaN, double.NaN);

        // Calculate the intercept position.
        return (targetPos + tBullet * targetVel);
    }
    /** Ballistic trajectory correction **/
    /* Summary:
    **  Calculates the correct pitch a shooter needs to fire a gravity-affected projectile at to have it hit the target.
    **  Written by Chronos "phantombeta" Ouroboros. The equation were taken from Wikipedia.
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
    static double, double InterceptShotPitch (Vector3 shooterPos, Vector3 targetPos, double v, double grav) {
        double g = grav * 9.807,
            x = (targetPos.xy - shooterPos.xy).Length (),
            y = targetPos.z - shooterPos.z;

        double sq = (v*v*v*v) - g*(g*(x*x) + 2 * y * (v*v));

        if (sq >= 0 && sq != double.NaN) {
            sq = sqrt (sq);
            double x1 = atan2 ((v*v) + sq, g * x);
            double x2 = atan2 ((v*v) - sq, g * x);

            Console.Printf ("shooter (x: %f, y: %f, z: %f)\ntarget (x: %f, y: %f, z: %f)\nx1: %f\nx2: %f\ng: %f, x: %f, y: %f",
                shooterPos.x, shooterPos.y, shooterPos.z, targetPos.x, targetPos.y, targetPos.z, x1, x2, g, x, y);

            return x1, x2;
        } else
            return double.NaN, double.NaN;
    }


    /** 3D vector rotation **/
    /* Summary:
    **  Rotates a 3D vector along the specified axis.
    **  Coded by kodi from the ZDoom forums/Discord
    **
    ** Arguments:
    **  point: The vector to be rotated.
    **  ang: The angle to rotate the vector by.
    **  axis: Which axis to rotate in. (1: X/Roll, 2: Y/Pitch, 3:Z/Yaw)
    **
    ** Returns:
    **  The input vector rotated by the specified amount in the specified axis
    **/
    static vector3 RotateVec3 (vector3 point, double ang, int axis) {
        vector3 ret;
        vector3 row1;
        vector3 row2;
        vector3 row3;

        switch(axis) {
            case 1:
                row1 = (1.0,        0.0,        0.0);
                row2 = (0.0,        cos(ang),   -sin(ang));
                row3 = (1.0,        sin(ang),   cos(ang));
                break;

            case 2:
                row1 = (cos(ang),   0.0,        sin(ang)    );
                row2 = (0,          1.0,        0.0);
                row3 = (-sin(ang),  0.0,        cos(ang)    );
                break;

            case 3:
                row1 = (cos(ang),   -sin(ang),  0.0);
                row2 = (sin(ang),   cos(ang),   0.0);
                row3 = (0.0,        0.0,        1.0);
                break;
        }
        ret.x = (row1.x*point.x) + (row1.y*point.y) + (row1.z * point.z);
        ret.y = (row2.x*point.x) + (row2.y*point.y) + (row2.z * point.z);
        ret.z = (row3.x*point.x) + (row3.y*point.y) + (row3.z * point.z);
        return ret;
    }
}