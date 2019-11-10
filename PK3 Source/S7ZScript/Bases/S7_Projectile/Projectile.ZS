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
        Normal         = 0, /// The projectile uses the normal movement code.
        FastProjectile    , /// The projectile is a FastProjectile.
        InstantMovement   , /// The projectile is a FastProjectile, and performs all of its movement instantly.
        OldFastProj       , /// The projectile is a FastProjectile and uses GZDoom's code.
    };
    /// Determines how to detect collisions. Only used for EMovementMode.FastProjectile.
    enum EFPCollisionMode {
        ColMode_Center      = 1     , /// Check the center for collision
        ColMode_Corners     = 1 << 1, /// Check the corners for collision
        ColMode_EdgeCenters = 1 << 2, /// Check the center of the edges for collision.
    };
    /// Determines how to effects are placed. Only used for EMovementMode.FastProjectile.
    enum EEffectsStepMode {
        EFXStepMode_FastProj = 0, /// Emulates GZDoom's FastProjectile trails.
        EFXStepMode_Accurate    , /// Calculates effects placement accurately.
        EFXStepMode_MapUnit     , /// Places effects every /interval/ map units.
    };

    int moveMode;
    int fpCollisionMode;
    bool interpFastProj;
    int effectsStepsMode;
    double effectStepInterval;
    double effectStepMul;
    double bonusDMGFactor;

    bool hitSky;

    /// Which movement code to use.
    property MovementMode: moveMode;
    /// How to detect collisions. Only used by EMovementMode.FastProjectile.
    property FastProjCollision: fpCollisionMode;
    /// Changes how many times StepEffects is called. Only used by EMovementMode.FastProjectile.
    property EffectStepMul: effectStepMul;
    /// Changes how effects are placed. Only used by EMovementMode.FastProjectile.
    property EffectsStepsMode: effectsStepsMode;
    /// Changes the interval for effects placement. Uses the radius as the interval if negative. Defaults to -1. Only used by EMovementMode.FastProjectile.
    property EffectStepInterval: effectStepInterval;
    /// Whether to interpolate the projectile's movement. Only used by EMovementMode.FastProjectile.
    property InterpMove: interpFastProj;

    default {
        S7_Projectile.MovementMode Normal;
        S7_Projectile.FastProjCollision ColMode_EdgeCenters;
        S7_Projectile.InterpMove true;

        S7_Projectile.EffectStepMul 0.125;
        S7_Projectile.EffectsStepsMode EFXStepMode_Accurate;
        S7_Projectile.EffectStepInterval -1;

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

            case InstantMovement:
                InstantMovementTick ();
            break;

            case OldFastProj:
                Super.Tick ();
            break;
        }
    }

    virtual void PostMovement () { }

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
        if (!self || bDestroyed)
            return;

        ClearInterpolation ();

        if (!bNoTimeFreeze && isFrozen ())
            return;

        HandleMovement ();

        PostMovement ();

        // Return if the actor got removed
        if (!self || bDestroyed)
            return;
        // Freed itself
        if (!CheckNoDelay ())
            return;
        // Advance the state
        if (tics != -1) {
            if (tics > 0)
                tics--;

            while (!tics) {
                if (!self || bDestroyed || !CurState || !SetState (CurState.NextState)) // Actor was removed
                    return;
            }
        }
    }

    const S7_InstantMovement_Limit = 2 ** 14;
    virtual void InstantMovementTick () {
        if (!self || bDestroyed)
            return;

        ClearInterpolation ();

        if (!bNoTimeFreeze && isFrozen ())
            return;

        int moveCount = 0;
        while (!(vel ~== (0, 0, 0))) {
            HandleMovement ();

            if (!self || bDestroyed)
                return;

            PostMovement ();

            if (moveCount++ >= S7_InstantMovement_Limit) {
                Console.PrintF ("\cgSe7evidas error: Stopped instant-movement projectile \"%s\" from looping infinitely.", GetClassName ());
                Destroy ();
                return;
            }
        }

        // Return if the actor got removed
        if (!self || bDestroyed)
            return;
        // Freed itself
        if (!CheckNoDelay ())
            return;
        // Advance the state
        if (tics != -1) {
            if (tics > 0)
                tics--;

            while (!tics) {
                if (!self || bDestroyed || !CurState || !SetState (CurState.NextState)) // Actor was removed
                    return;
            }
        }
    }

    virtual void S7_ExplodeMissile (Line l, Actor targ, bool onSky) {
        hitSky = onSky;
        if (onSky && !bSkyExplode) {
            vel = (0, 0, 0);
            Destroy ();

            return;
        }

        ExplodeMissile (l, targ, onSky);
    }
}