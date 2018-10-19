/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

extend class S7_MonsterBase {
    /** Target interception **/
    enum S7_LeadTargetFlags {
        /// Aims at the target's base
        S7_LTF_TargetBase = 1,
        /// When set, the target's height is multiplied by the targHeightOff argument
        S7_LTF_TargHeightMul = 1 << 1,
    };

    virtual Vector3 LeadTarget (Actor targ, double projSpeed, Vector2 posOffsets, double targHeightOff = 0., int flags = 0) {
        if (!targ)
            return (double.NaN, double.NaN, double.NaN);

        double tmpAng = AngleTo (targ);
        Vector3 projPos = Vec3Offset (cos (tmpAng) * posOffsets.X, sin (tmpAng) * posOffsets.X, posOffsets.Y);
        Vector3 targPos;

        if (flags & S7_LTF_TargHeightMul)
            targPos = targ.Vec3Offset (0, 0, targ.height * targHeightOff);
        else if (flags & S7_LTF_TargetBase)
            targPos = targ.Vec3Offset (0, 0, targHeightOff);
        else
            targPos = targ.Vec3Offset (0, 0, (targ.height / 2.) + S7_LTF_TargHeightMul);

        [angle, pitch] = S7_Math.GetAnglesTo (projPos, targPos);

        if (targ.vel.X ~== 0 && targ.vel.Y ~== 0 && targ.vel.Z ~== 0) // Don't bother leading if the target isn't moving.
            return targPos;

        bool canIntercept;
        Vector3 interceptPos;
        [canIntercept, interceptPos] = S7_Math.CalculateInterceptShotPosition (projPos, targPos, targ.vel, projSpeed);

        // Couldn't intercept.
        if (!canIntercept)
            return targPos;

        [angle, pitch] = S7_Math.GetAnglesTo (projPos, interceptPos);

        return interceptPos;
    }

    /** Pitch correction for gravity-affected projectiles **/
    virtual double PitchCorrection (Vector3 targPos, double xyOffs, double zOffs, double projSpeed, double grav, bool retX1 = false) {
        double x1, x2;
        [x1, x2] = S7_Math.InterceptShotPitch (Vec3Offset (cos (angle) * xyOffs, sin (angle) * xyOffs, zOffs), targPos, projSpeed, grav);

        if ((retX1 && x1 != x1) || (!retX1 && x2 != x2)) // If these are NaN, well fuck. Probably means we can't hit.
            return double.NaN;

        if (retX1)
            return x1;
        else
            return x2;
    }
}