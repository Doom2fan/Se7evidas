/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) ????      WildWeasel
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

// Credits:
// Coding: WildWeasel, Chronos "phantombeta" Ouroboros
// Sprites: Chronos "phantombeta" Ouroboros
// Weapons: S7_A_FireBullets (tracerName, spread: (horizontalSpread, .verticalSpread), offs: (10, verticalOffset, horizontalOffset), flags: S7_FB_UseAmmo);
// Monsters: A_SpawnProjectile (tracerName, verticalOffset, horizontalOffset, fRandom [monsterSpread] (-, horizontalSpread), 0, fRandom [monsterSpread] (-, verticalSpread))

//-------------------------------------------------------------------------------------------
//
// Base tracer
//
//-------------------------------------------------------------------------------------------
class S7_TracerEffectsBase : S7_FastProjTrailBase {
    default {
        Height 2;
        Radius 2;
        Scale 0.02120;
        RenderStyle "add";

        +FORCEXYBILLBOARD
    }
}

mixin class S7_BulletProjMixin {
    const S7_SBI_MinSparkZ = 2.5;
    const S7_SBI_MaxSparkZ = 6.;

    void S7_A_SpawnBulletImpact () {
        Vector3 norm, orth0, orth1;

        bool hitGeo = (BlockingType != S7_BLOCK_None && BlockingType != S7_BLOCK_Actor);
        if (hitGeo) {
            norm = GetGeoHitNormal ();

            if (norm == norm)
                [orth0, orth1] = S7_Math.GetOrthoVecs (norm);
            else
                Console.Printf ("NaN received from GetGeoHitNormal in S7_BulletProjMixin.S7_A_SpawnBulletImpact. This shouldn't happen.");
        } else
            norm = (0, 0, 0);

        Vector3 offs, actVel;
        for (int i = random [S7_HitsparksRNG] (3, 4); i > 0; i--) {
            if (!hitGeo) {
                offs = S7_Math.Vec3FromAngle (
                    fRandom [S7_HitsparksRNG] (0, 360),
                    fRandom [S7_HitsparksRNG] (-90, 90),
                    1
                );

                actVel = S7_Math.Vec3FromAngle (
                    fRandom [S7_HitsparksRNG] (0, 360),
                    fRandom [S7_HitsparksRNG] (-90, 90),
                    1
                );
            } else {
                offs = S7_Math.RandomHalfSphereVecFromNormal (norm, (fRandom [S7_HitsparksRNG] (-1, 1), fRandom [S7_HitsparksRNG] (-1, 1)), orth0, orth1);
                actVel = S7_Math.RandomHalfSphereVecFromNormal (norm, (fRandom [S7_HitsparksRNG] (-1, 1), fRandom [S7_HitsparksRNG] (-1, 1)), orth0, orth1);
            }
            actVel.XY *= 2.;
            actVel.Z = clamp (abs (actVel.Z) * fRandom [S7_HitsparksRNG] (S7_SBI_MinSparkZ, 6.), S7_SBI_MinSparkZ, S7_SBI_MaxSparkZ);

            offs = norm * 1.5 + offs * fRandom [S7_HitsparksRNG] (-.25, .25);

            let act = Spawn ('S7_BulletPuffSparks', level.Vec3Offset (pos, offs), ALLOW_REPLACE);
            act.vel = actVel;
        }

        for (int i = random [S7_HitsparksRNG] (3, 4); i > 0; i--) {
            if (!hitGeo) {
                offs = S7_Math.Vec3FromAngle (
                    fRandom [S7_HitsparksRNG] (0, 360),
                    fRandom [S7_HitsparksRNG] (-90, 90),
                    1
                );

                actVel = S7_Math.Vec3FromAngle (
                    fRandom [S7_HitsparksRNG] (0, 360),
                    fRandom [S7_HitsparksRNG] (-90, 90),
                    1
                );
            } else {
                offs = S7_Math.RandomHalfSphereVecFromNormal (norm, (fRandom [S7_HitsparksRNG] (-1, 1), fRandom [S7_HitsparksRNG] (-1, 1)), orth0, orth1);
                actVel = S7_Math.RandomHalfSphereVecFromNormal (norm, (fRandom [S7_HitsparksRNG] (-1, 1), fRandom [S7_HitsparksRNG] (-1, 1)), orth0, orth1);
            }

            offs = norm * 1.5 + offs * fRandom [S7_HitsparksRNG] (-2.5, 2.5);

            let act = S7_Smoke3 (Spawn ("S7_Smoke3", level.Vec3Offset (pos, offs), ALLOW_REPLACE));

            act.scale = (.021, .021);
            act.vel = actVel;
            act.fadeInTime = 0;
            act.stayTime = random [S7_HitsparksRNG] (6, 7);
            act.fadeOutTime = random [S7_HitsparksRNG] (4, 6);
            act.targetAlpha = fRandom [S7_HitsparksRNG] (.22, .25);
        }
    }
}

class S7_BaseTracer : S7_Projectile {
    int trueSpeed;
    property TrueSpeed: trueSpeed;

    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_Center;
        S7_Projectile.InterpMove false;

        S7_BaseTracer.TrueSpeed -1;

        Alpha 1.0;
        RenderStyle "add";
        Radius 2;
        Height 2;
        Speed 150;
        DamageFunction int (8. + fRandom [weaponDamage] (-2., 2.));
        MissileHeight 8;

        +BLOODSPLATTER    +NOEXTREMEDEATH +NODAMAGETHRUST +PUFFGETSOWNER
        +FORCEXYBILLBOARD
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        if (trueSpeed > -1 && !(vel.Length () ~== 0))
            vel = vel.Unit () * trueSpeed;
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            return ResolveState ("Idle");
        }
    }
}
class S7_LaserTracer : S7_BaseTracer {
    default {
        S7_Projectile.MovementMode InstantMovement;
        S7_Projectile.EffectsStepsMode EFXStepMode_MapUnit;
        S7_Projectile.EffectStepInterval 10;

        Speed 8000;
    }
}

class S7_BulletTracer : S7_BaseTracer {
    default {
        S7_Projectile.EffectsStepsMode EFXStepMode_MapUnit;
        S7_Projectile.EffectStepInterval 10;

        DamageFunction int ((8. + fRandom [weaponDamage] (-2., 2.)) * (1. + bonusDMGFactor));

        Scale 0.02120;
        MissileType 'S7_TracerTrail';
        Decal 'BulletChip';
    }

    mixin S7_BulletProjMixin;

    states {
    Idle:
        SPRK A 1 bright;
        wait;

    Death:
    Crash:
        SPRK A 2 bright {
            S7_A_SpawnBulletImpact ();
        }
        SPRK A 2 bright A_SetScale (scale.X * 1.5, scale.Y * 1.5);
        stop;
    XDeath:
        TNT1 A 3 {
            if (random [misc] (0, 255) < 96)
                A_StartSound ("Tracers/HitFlesh", slot: CHAN_Body, volume: .5);
        }
        stop;
    }
}

class S7_TracerTrail : S7_TracerEffectsBase {
    default {
        alpha 0.5;
    }

    states {
    Spawn:
        SPRK AA 1 bright;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Bullet puff
//
//-------------------------------------------------------------------------------------------
class S7_BulletPuffSmoke : S7_BlackSmoke {
    default {
        Alpha 0.2;
    }

    states {
    Spawn:
        SMOK A 8;
        SMOK A 1 A_FadeOut (0.03);
        wait;
    }
}

class S7_BulletPuffSparks : S7_TracerEffectsBase {
    default {
        Mass 1;
        Gravity 1.0;

        +DONTSPLASH +NOCLIP
        -NOGRAVITY
    }

    states {
    Spawn:
        SPRK A 1 bright;
    Loople:
        SPRK A 1 bright {
            A_FadeOut (0.1);

            if (pos.Z < floorZ) {
                SetPosition ((pos.XY, floorZ));
                vel = (0, 0, 0);
            } else if (pos.Z > floorZ)
                vel -= (0, 0, GetGravity ());
        }
        loop;
    Death:
        TNT1 A 0;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Tracers
//
//-------------------------------------------------------------------------------------------
/*** Primary ***/
class S7_AMGTracer : S7_BulletTracer {
    default {
        DamageFunction int ((22. + fRandom [weaponDamage] (-1., 3.)) * (1. + bonusDMGFactor));
        Speed 260;
        DamageType 'RifleTracer';
    }
}

class S7_AK47_Tracer : S7_BulletTracer {
    default {
        DamageFunction int ((21. + fRandom [weaponDamage] (-1., 2.)) * (1. + bonusDMGFactor));
        Speed 220;
        DamageType 'RifleTracer';
    }
}

class S7_SSGTracer : S7_BulletTracer {
    default {
        DamageFunction int ((6. + fRandom [weaponDamage] (-2., 1.)) * (1. + bonusDMGFactor));
        Speed 250;
        DamageType 'ShotgunTracer';
        MissileType 'S7_SSGTracerTrail';
    }

    states {
    Death:
    Crash:
        TNT1 AAA 0 A_SpawnItemEx ('S7_BulletPuffSparks', 0.0, 0.0, 0.0, fRandom [S7_HitsparksRNG] (-0.5, -2.0), fRandom [S7_HitsparksRNG] (-2.0, 2.0), fRandom [S7_HitsparksRNG] (1.5, 4.0), 0, SXF_Clientside);
        TNT1 AA  0 A_SpawnItemEx ('S7_BulletPuffSmoke', 0.0, 0.0, 0.0, 0.0, fRandom [S7_HitsparksRNG] (-1.0, 1.0), fRandom [S7_HitsparksRNG] (-0.8, 0.8), 0, SXF_Clientside);
        SPRK A   2 bright;
        SPRK A   2 bright A_SetScale (scale.X * 1.5, scale.Y * 1.5);
        stop;
    }
}
class S7_SSGTracerTrail : S7_TracerTrail {
    states {
    Spawn:
        SPRK AA 1 bright A_FadeOut (0.45);
        stop;
    }
}

class S7_12gaTracer : S7_BulletTracer {
    default {
        DamageFunction int ((16. + fRandom [weaponDamage] (-2., 2.)) * (1. + bonusDMGFactor));
        Speed 250;
        DamageType 'ShotgunTracer';
        MissileType 'S7_SSGTracerTrail';
    }
}
class S7_ManxCarbineTracer : S7_BulletTracer {
    default {
        DamageFunction int ((17. + fRandom [weaponDamage] (-1., 1.)) * (1. + bonusDMGFactor));
        Speed 200;
        DamageType 'PistolTracer';
    }
}
class S7_HitterSMGTracer : S7_BulletTracer {
    default {
        DamageFunction int ((18. + fRandom [weaponDamage] (-2., 1.)) * (1. + bonusDMGFactor));
        Speed 170;
        DamageType 'PistolTracer';
    }
}
class S7_ConquerorRifle_Tracer : S7_BulletTracer {
    default {
        DamageFunction int ((120. + fRandom [weaponDamage] (-5., 5.)) * (1. + bonusDMGFactor));
        Speed 550; // So you need to compensate less when firing at long range
        DamageType 'SniperRifleTracer';
        S7_Projectile.EffectStepMul 0.036;
    }
}

class S7_CaesarChaingun_Tracer : S7_BulletTracer {
    default {
        DamageFunction int ((40. + fRandom [weaponDamage] (0, 5.)) * (1. + bonusDMGFactor));
        Speed 500;
        DamageType 'SniperRifleTracer';
        S7_Projectile.EffectStepMul 0.036;
    }
}

/*** Secondary ***/
class S7_RaptorTracer : S7_BulletTracer {
    default {
        DamageFunction int ((15.5 + fRandom [weaponDamage] (-1., 1.)) * (1. + bonusDMGFactor));
        Speed 175;
        DamageType 'PistolTracer';
    }
}
class S7_RevolverTracer : S7_BulletTracer {
    default {
        DamageFunction int ((60. + fRandom [weaponDamage] (-5., 5.)) * (1. + bonusDMGFactor));
        Speed 210;
        DamageType 'RevolverTracer';
    }
}
class S7_TEC9Tracer : S7_BulletTracer {
    default {
        DamageFunction int ((15.5 + fRandom [weaponDamage] (-1., 1.)) * (1. + bonusDMGFactor));
        Speed 175;
        DamageType 'PistolTracer';
    }
}