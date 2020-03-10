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
    /// Some data about what the projectile is.
    enum EProjectileType {
        Proj_Kinetic     = 1 << 0,
        Proj_Magic       = 1 << 1,
        Proj_Flame       = 1 << 2,
        Proj_IgnoreArmor = 1 << 3,
    };
    /// Determines what blocked the projectile.
    enum EBlockTypes {
        S7_BLOCK_None,
        S7_BLOCK_Actor,
        S7_BLOCK_Line,
        S7_BLOCK_Floor,
        S7_BLOCK_Ceiling,
        S7_BLOCK_3DFloor_Floor,
        S7_BLOCK_3DFloor_Ceiling,
    };
    /// Determines what tier of a line blocked the projectile.
    enum EBlockLineTiers {
        S7_BLOCK_Tier_Bottom,
        S7_BLOCK_Tier_Middle,
        S7_BLOCK_Tier_Top,
        S7_BLOCK_Tier_FFloor,
    };

    int moveMode;
    int fpCollisionMode;
    bool interpFastProj;
    int effectsStepsMode;
    double effectStepInterval;
    double effectStepMul;
    double bonusDMGFactor;

    /// EProjectileType. Some data about what the projectile is.
    int projectileType;
    /// The projectile's mass in kilograms.
    double projectileMass;
    /// How pointy the projectile is. Increases penetration for kinetic projectiles.
    /// Range is [0-1], 0 is a flat-tipped projectile, ~0.5 is round tipped (e.g. handgun bullets),
    /// 1 is a pointy tip (e.g., rifle bullets).
    double projectilePoint;

    int BlockingType;
    int BlockingLineTier;
    S7_3DFloorPointer BlockingFFloor;

    private bool spawnedTrail;
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

    /// Some data about what the projectile is.
    property ProjType: projectileType;
    /// The projectile's mass in kilograms. Increases penetration for kinetic projectiles.
    property Mass: projectileMass;
    /// How pointy the projectile is. Increases penetration for kinetic projectiles. Range is [0-1].
    property Pointiness: projectilePoint;

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

    /* Summary:
    **  Calculates the projectile's raw kinetic energy.
    **
    ** Returns:
    **  The raw kinetic energy of the projectile in joules as a double.
    */
    virtual double GetKineticEnergy () {
        // 1/2 * <mass in kg> * <velocity in m>
        double velM = (vel.Length () / S7C_MapUnitsPerMeter * TICRATE);
        return .5 * projectileMass * (velM * velM);
    }

    /* Summary:
    **  Gets the normal vector for the level geometry the projectile hit.
    **  Only works when MovementMode is set to "FastProjectile" or "InstantMove".
    **
    ** Returns:
    **  Returns a Vector3 containing the normal of whatever the projectile hit.
    **  Returns a Vector3 containing NaNs if the projectile didn't hit any level geometry.
    */
    Vector3 GetGeoHitNormal () {
        switch (BlockingType) {
            case S7_BLOCK_Line:
                if (BlockingLine) {
                    double ang = VectorAngle (BlockingLine.delta.X, BlockingLine.delta.Y);
                    let norm = (AngleToVector (ang - 90, 1.), 0).Unit ();

                    if (S7_Math.PointOnLineSidePrecise (pos.X, pos.Y, BlockingLine) == 1)
                        norm = -norm;

                    return norm;
                }
            break;

            case S7_BLOCK_Floor:
                if (BlockingFloor)
                    return BlockingFloor.floorPlane.normal;
            break;

            case S7_BLOCK_Ceiling:
                if (BlockingCeiling)
                    return -BlockingCeiling.floorPlane.normal;
            break;

            case S7_BLOCK_3DFloor_Floor:
                if (BlockingFFloor)
                    return -BlockingFFloor.Get3DFloor ().top.normal; // 3D floor normals are inverted.
            break;

            case S7_BLOCK_3DFloor_Ceiling:
                if (BlockingFFloor)
                    return -BlockingFFloor.Get3DFloor ().bottom.normal; // 3D floor normals are inverted.
            break;
        }

        if (pos.Z <= FloorSector.floorPlane.ZatPoint (pos.XY))
            return FloorSector.floorPlane.normal;
        else if ((pos.Z + height) >= CeilingSector.ceilingPlane.ZatPoint (pos.XY))
            return CeilingSector.ceilingPlane.normal;

        return (double.NaN, double.NaN, double.NaN);
    }

    /* Summary:
    **  Called after movement is performed when the movement mode is set to "FastProjectile" or "InstantMove".
    */
    virtual void PostMovement () { }

    /* Summary:
    **  Called when the projectile hits something.
    **
    ** Arguments:
    **  l: The line the projectile hit, if any.
    **  targ: The actor the projectile hit, if any.
    **  onSky: Whether the projectile hit a sky.
    */
    virtual void S7_ExplodeMissile (Line l, Actor targ, bool onSky) {
        hitSky = onSky;
        if (onSky && !bSkyExplode) {
            vel = (0, 0, 0);
            Destroy ();

            return;
        }

        ExplodeMissile (l, targ, onSky);
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
    /* Summary:
    **  Called when the movement mode is set to "FastProjectile".
    */
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
    /* Summary:
    **  Called when the movement mode is set to "InstantMovement".
    */
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
}