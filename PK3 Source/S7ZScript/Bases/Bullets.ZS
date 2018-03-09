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
        height 2;
        radius 2;
        scale 0.02120;
        renderStyle "add";

        +forceXYBillboard
    }
}

class S7_BaseTracer : S7_Projectile {
    int trueSpeed;
    property trueSpeed: trueSpeed;

    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_Center;
        S7_Projectile.interpMove false;
        alpha 1.0;
        renderStyle "add";
        radius 2;
        height 2;
        speed 25;
        S7_BaseTracer.trueSpeed 150;
        damageFunction (fRandom [weaponDamage] (1.0, 3.0) * 4);
        missileHeight 8;

        +bloodSplatter +noExtremeDeath +noDamageThrust +puffGetsOwner
        +forceXYBillboard
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
        scale 0.02120;
        missileType "S7_TracerTrail";
        decal "BulletChip";
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
        scale 0.05;

        -clientsideOnly
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
        alpha 0.2;
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
        mass 1;
        gravity 1.0;

        +dontSplash
        -noGravity -noInteraction
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
        damageFunction (fRandom [weaponDamage] (1.0, 3.0) * 9);
        S7_BaseTracer.trueSpeed 260;
        damageType "RifleTracer";
    }
}

class S7_AK47_Tracer : S7_BulletTracer {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 3.0) * 8);
        S7_BaseTracer.trueSpeed 220;
        damageType "RifleTracer";
    }
}

class S7_SSGTracer : S7_BulletTracer { // 259 max DMG
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 3.0) * 2.3981);
        S7_BaseTracer.trueSpeed 250;
        damageType "ShotgunTracer";
        missileType "S7_SSGTracerTrail";
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
        damageFunction (fRandom [weaponDamage] (1.0, 3.0) * 6);
        S7_BaseTracer.trueSpeed 250;
        damageType "ShotgunTracer";
        missileType "S7_SSGTracerTrail";
    }
}
class S7_ManxCarbineTracer : S7_BulletTracer {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 3.0) * 7);
        S7_BaseTracer.trueSpeed 190;
        damageType "PistolTracer";
    }
}
class S7_HitterSMGTracer : S7_BulletTracer {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 3.0) * 6);
        S7_BaseTracer.trueSpeed 170;
        damageType "PistolTracer";
    }
}
class S7_ConquerorRifle_Tracer : S7_BulletTracer {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 2.5) * 70);
        S7_BaseTracer.trueSpeed 550; // So you need to compensate less when firing at long range
        damageType "SniperRifleTracer";
    }
}

/*** Secondary ***/
class S7_RaptorTracer : S7_BulletTracer {
    default {
        damageFunction (fRandom [weaponDamage] (1.5, 3.0) * 5);
        S7_BaseTracer.trueSpeed 160;
        damageType "PistolTracer";
    }
}
class S7_RevolverTracer : S7_BulletTracer {
    default {
        damageFunction (fRandom [weaponDamage] (1.75, 2.5) * 40);
        S7_BaseTracer.trueSpeed 210;
        damageType "RevolverTracer";
    }
}
class S7_TEC9Tracer : S7_BulletTracer {
    default {
        damageFunction (fRandom [weaponDamage] (1.5, 3.0) * 5);
        damageType "PistolTracer";
    }
}