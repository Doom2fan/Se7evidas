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

// Credits:
// Coding: WildWeasel, Chronos "phantombeta" Ouroboros
// Sprites: Chronos "phantombeta" Ouroboros
// Weapons: A_FireProjectile (tracerName, fRandom [weaponSpread] (-, horizontalSpread), 1, horizontalOffset, verticalOffset, 0, fRandom [weaponSpread] (-, verticalSpread))
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

class S7_BaseTracer : S7_Projectile {
    int trueSpeed;
    property TrueSpeed: trueSpeed;

    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_Center;
        S7_Projectile.InterpMove false;

        Alpha 1.0;
        RenderStyle "add";
        Radius 2;
        Height 2;
        Speed 25;
        S7_BaseTracer.TrueSpeed 150;
        DamageFunction (fRandom [weaponDamage] (1.0, 3.0) * 4);
        MissileHeight 8;

        +BLOODSPLATTER    +NOEXTREMEDEATH +NODAMAGETHRUST +PUFFGETSOWNER
        +FORCEXYBILLBOARD
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            A_ScaleVelocity (1.0 / 25);
            A_ScaleVelocity (abs (trueSpeed));
            return ResolveState ("Idle");
        }
    }
}
class S7_BulletTracer : S7_BaseTracer {
    default {
        Scale 0.02120;
        MissileType "S7_TracerTrail";
        Decal "BulletChip";
    }

    states {
    Idle:
        SPRK A 1 bright;
        wait;

    Death:
    Crash:
        SPRK A 2 bright {
            for (int i = 0; i < 4; i++) {
                A_SpawnItemEx ("S7_BulletPuffSparks", 0.0, 0.0, 0.0, fRandom [sfx] (-0.5, -2.0), fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (1.5, 4.0), 0, SXF_Clientside);
                if (i < 3)
                    A_SpawnItemEx ("S7_BulletPuffSmoke", 0.0, 0.0, 0.0, 0.0, fRandom [sfx] (-1.0, 1.0), fRandom [sfx] (-0.8, 0.8), 0, SXF_Clientside);
            }
        }
        SPRK A 2 bright A_SetScale (scale.X * 1.5, scale.Y * 1.5);
        stop;
    XDeath:
        TNT1 A 3 A_PlaySound ("Tracers/HitFlesh", CHAN_Body);
        stop;
    }
}

class S7_TracerTrail : S7_TracerEffectsBase {
    states {
    Spawn:
        //SPRK AAA 1 bright A_FadeOut (0.4);
        SPRK A 2 bright;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Bullet puff
//
//-------------------------------------------------------------------------------------------
class S7_BulletPuff : S7_TracerEffectsBase { // replaces bulletPuff {
    default {
        Scale 0.05;

        -CLIENTSIDEONLY
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_PlaySound ("Tracers/HitWall", CHAN_Body);
    NoSound:
        SPRK A 2 bright {
            for (int i = 0; i < 4; i++) {
                A_SpawnItemEx ("S7_BulletPuffSparks", 0.0, 0.0, 0.0, fRandom [sfx] (-0.5, -2.0), fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (1.5, 4.0), 0, SXF_Clientside);
                if (i < 3)
                    A_SpawnItemEx ("S7_BulletPuffSmoke", 0.0, 0.0, 0.0, 0.0, fRandom [sfx] (-1.0, 1.0), fRandom [sfx] (-0.8, 0.8), 0, SXF_Clientside);
            }
        }
        SPRK A 2 bright A_SetScale (scale.X * 1.5, scale.Y * 1.5);
        stop;
    }
}

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

        +DONTSPLASH
        -NOGRAVITY -NOINTERACTION
    }

    states {
    Spawn:
        SPRK A 1 bright;
    Loople:
        SPRK A 1 bright A_FadeOut (0.05);
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
        DamageFunction (fRandom [weaponDamage] (1.0, 3.0) * 9);
        S7_BaseTracer.TrueSpeed 260;
        DamageType "RifleTracer";
    }
}

class S7_AK47_Tracer : S7_BulletTracer {
    default {
        DamageFunction (fRandom [weaponDamage] (1.0, 3.0) * 8);
        S7_BaseTracer.TrueSpeed 220;
        DamageType "RifleTracer";
    }
}

class S7_SSGTracer : S7_BulletTracer { // 259 max DMG
    default {
        DamageFunction (fRandom [weaponDamage] (1.0, 1.5) * 5);
        S7_BaseTracer.TrueSpeed 250;
        DamageType "ShotgunTracer";
        MissileType "S7_SSGTracerTrail";
    }

    states {
    Death:
    Crash:
        TNT1 AAA 0 A_SpawnItemEx ("S7_BulletPuffSparks", 0.0, 0.0, 0.0, fRandom [sfx] (-0.5, -2.0), fRandom [sfx] (-2.0, 2.0), fRandom [sfx] (1.5, 4.0), 0, SXF_Clientside);
        TNT1 AA  0 A_SpawnItemEx ("S7_BulletPuffSmoke", 0.0, 0.0, 0.0, 0.0, fRandom [sfx] (-1.0, 1.0), fRandom [sfx] (-0.8, 0.8), 0, SXF_Clientside);
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
        DamageFunction (fRandom [weaponDamage] (1.0, 2.0) * 9);
        S7_BaseTracer.TrueSpeed 250;
        DamageType "ShotgunTracer";
        MissileType "S7_SSGTracerTrail";
    }
}
class S7_ManxCarbineTracer : S7_BulletTracer {
    default {
        DamageFunction (fRandom [weaponDamage] (1.0, 3.0) * 7);
        S7_BaseTracer.TrueSpeed 190;
        DamageType "PistolTracer";
    }
}
class S7_HitterSMGTracer : S7_BulletTracer {
    default {
        DamageFunction (fRandom [weaponDamage] (1.0, 3.0) * 6);
        S7_BaseTracer.TrueSpeed 170;
        DamageType "PistolTracer";
    }
}
class S7_ConquerorRifle_Tracer : S7_BulletTracer {
    default {
        DamageFunction (fRandom [weaponDamage] (1.0, 2.5) * 70);
        S7_BaseTracer.TrueSpeed 550; // So you need to compensate less when firing at long range
        DamageType "SniperRifleTracer";
    }
}

/*** Secondary ***/
class S7_RaptorTracer : S7_BulletTracer {
    default {
        DamageFunction (fRandom [weaponDamage] (2.0, 3.0) * 6);
        S7_BaseTracer.TrueSpeed 175;
        DamageType "PistolTracer";
    }
}
class S7_RevolverTracer : S7_BulletTracer {
    default {
        DamageFunction (fRandom [weaponDamage] (1.75, 2.5) * 40);
        S7_BaseTracer.TrueSpeed 210;
        DamageType "RevolverTracer";
    }
}
class S7_TEC9Tracer : S7_BulletTracer {
    default {
        DamageFunction (fRandom [weaponDamage] (1.5, 3.0) * 5);
        DamageType "PistolTracer";
    }
}