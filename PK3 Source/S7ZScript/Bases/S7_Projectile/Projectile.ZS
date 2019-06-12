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

/// The base type for all S7 projectiles
class S7_Projectile : FastProjectile {
    enum EMovementMode {
        Normal = 0, /// The projectile uses the normal movement code.
        FastProjectile, /// The projectile is a FastProjectile.
        OldFastProj, /// The projectile is a FastProjectile and uses GZDoom's code.
    };
    /// Determines how to detect collisions. Only used for EMovementMode.FastProjectile.
    enum EFPCollisionMode {
        ColMode_Center      = 1, /// Check the center for collision
        ColMode_Corners     = 1 << 1, /// Check the corners for collision
        ColMode_EdgeCenters = 1 << 2, /// Check the center of the edges for collision.
    };

    int moveMode;
    int fpCollisionMode;
    bool interpFastProj;
    double effectStepMul;
    double bonusDMGFactor;

    bool hitSky;

    /// Which movement code to use.
    property MovementMode: moveMode;
    /// How to detect collisions. Only used by EMovementMode.FastProjectile.
    property FastProjCollision: fpCollisionMode;
    /// Changes how many times StepEffects is called. Only used by EMovementMode.FastProjectile.
    property EffectStepMul: effectStepMul;
    /// Whether to interpolate the projectile's movement. Only used by EMovementMode.FastProjectile.
    property InterpMove: interpFastProj;

    default {
        S7_Projectile.MovementMode Normal;
        S7_Projectile.FastProjCollision ColMode_EdgeCenters;
        S7_Projectile.InterpMove true;
        S7_Projectile.EffectStepMul 0.125;

        Projectile;
    }

    transient S7_Projectile_Trace tr;

    override void Tick () {
        switch (moveMode) {
            case Normal:
                Actor.Tick ();
            break;

            case FastProjectile:
                NewFastProjTick ();
            break;

            case OldFastProj:
                Super.Tick ();
            break;
        }
    }

    static const double FPColOffs [] = { // Y and Z, not X and Y.
        // Edge centers
         0, 1.0,
         1, 0.5,
         0, 0.0,
        -1, 0.5,
        // Corners
         1, 1,
         1, 0,
        -1, 0,
        -1, 1,
        // Center
        0, 0.5
    };
    virtual void NewFastProjTick () {
        if (!self)
            return;

        ClearInterpolation ();

        if (!bNoTimeFreeze && isFrozen ())
            return;

        HandleMovement ();

        // Nope the fuck out if self is null for some retarded reason
        if (!self)
            return;
        // Freed itself
        if (!CheckNoDelay ())
            return;
        // Advance the state
        if (tics != -1) {
            if (tics > 0)
                tics--;

            while (!tics) {
                if (!self || !CurState || !SetState (CurState.NextState)) // mobj was removed
                    return;
            }
        }
    }
}