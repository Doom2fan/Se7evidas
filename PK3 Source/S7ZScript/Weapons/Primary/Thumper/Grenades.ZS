/* Credits:

** THGR  AB: ???, Chronos "phantombeta" Ouroboros
** THGR CDE: Id Software, Chronos "phantombeta" Ouroboros
** THGR   F: Raven Software, Chronos "phantombeta" Ouroboros
** THGR   G: Raven Software
*/

//-------------------------------------------------------------------------------------------
//
// Normal/Explosive
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenade : S7_Projectile {
    default {
        radius 10;
        height 10;
        speed 75;
        damageFunction (fRandom [weaponDamage] (1.0, 6.0) * 18);
        scale 0.8;
        gravity 0.25;
        translation "112:127=216:223";

        -noGravity
    }

    states {
    Spawn:
        THGR A 1;
        loop;
    Death:
        TNT1 A 0 {
            A_SetGravity (0.0);
            A_Stop ();

            return ResolveState ("Loople");
        }
        stop;
    Loople:
        TNT1 A 15 {
            A_SetScale (0.5);
            A_PlaySound ("Explosions/Explosion1");

            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (128, 128);

            A_SpawnItemEx ("S7_ThumperExplosion", 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_TransferScale);
        }
        stop;
    }
}
class S7_ThumperExplosion : actor {
    default {
        radius 10;
        height 10;

        +noGravity +forceXYBillboard +noInteraction +noBlockmap
    }

    states {
    Spawn:
        XPL1 ABCDE 3 bright;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Fragmentation
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeFrag : S7_ThumperGrenade {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 6.0) * 12);
    }

    states {
    Loople:
        TNT1 A  15 {
            A_SetScale (0.43);
            A_PlaySound ("Explosions/Explosion1");

            S7_ActorExtensions.A_S7SpawnShrapnel (self, 30);

            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (100, 100);

            A_SpawnItemEx ("S7_ThumperExplosion", 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_TransferScale);
        }
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Thermite/Incendiary
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeTherm : S7_ThumperGrenade {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 6.0) * 12);
        translation "112:127=184:191";
    }

    states {
    Loople:
        TNT1 A 15 {
            A_SetScale (0.43);
            A_PlaySound ("Explosions/Explosion1");

            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (80, 80);

            int count = 7 - random [weaponSpc] (0, 3);
            for (; count > 0; count--) {
                A_SpawnItemEx ("S7_ThumperGrenadeTherm_Fire", fRandom [weaponSpc] (-0.025, 0.025), fRandom [weaponSpc] (-0.025, 0.025), 0.25,
                    fRandom [weaponSpc] (2.8, 3.0), 0.0, fRandom [weaponSpc] (2.5, 4.0), fRandom [weaponSpc] (0.0, 359.0), SXF_TransferPointers | SXF_NoCheckPosition);
            }

            A_SpawnItemEx ("S7_ThumperExplosion", 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_TransferScale);
        }
        stop;
    }
}

class S7_ThumperGrenadeTherm_Fire : S7_Projectile {
    default {
        radius 1;
        height 1;
        mass 0x7FFFFFFF;
        args 72;
        renderStyle "add";
        damageFunction 0;
        damageType "ThermiteFire";

        +thruActors +noDamageThrust +bloodlessImpact +forceRadiusDMG
        +forceXYBillboard +dontSplash
        -noGravity
    }

    states {
    Spawn:
        THGR F 1;
        wait;
    Death:
        TNT1 A 0 {
            A_PlaySound ("Fire/Small", CHAN_7, 0.8, TRUE, 0.5);
            bForceXYBillboard = false;
            A_ChangeLinkFlags (false);
        }
    Loople:
        THGR C  2 bright {
            A_CountdownArg (0, "FadeOut");
            A_Explode (3, 64, XF_HurtSource, false, 48);
        }
        THGR DE 2 bright;
        loop;
    FadeOut:
        THGR C  2 bright {
            A_SetScale (scale.X - 0.035);
            A_Explode (3, 64, XF_HurtSource, false, 48);
        }
        THGR DE 2 bright A_FadeOut (0.08);
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Flare
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeFlare : S7_ThumperGrenade {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 6.0) * 5);
        damageType "TH_GrenadeImpact";
        translation "112:127=80:95";

        -noGravity
    }

    bool initialized;
    int maxTime;
    int time;
    PointLight dynLight;

    override void PostBeginPlay () {
        time = maxTime = random [weaponSpc] (1025, 1050);

        if (!dynLight)
            dynLight = PointLight (Spawn ("PointLight")); // Spawn the dynamic light
        dynLight.target = self;
        dynLight.args [DynamicLight.Light_Red] = 114; // Color - Red
        dynLight.args [DynamicLight.Light_Green] = 186; // Color - Green
        dynLight.args [DynamicLight.Light_Blue] = 255; // Color - Blue
        dynLight.args [DynamicLight.Light_Intensity] = 85; // Size
        //dynLight.args [DynamicLight.Light_Secondary_Intensity] = 75; // Secondary size
        //dynLight.angle = 0.72;

        A_PlaySound ("Fire/Flare", CHAN_7, 0.15, TRUE);
        initialized = true;
    }

    states {
    Spawn:
        THGR A 1 {
            if (time <= 0)
                return ResolveState ("RanOut");

            if (dynLight) {
                double mult = 1.0;
                if (time < (maxTime * 0.25))
                    mult = Clamp (time / (maxTime * 0.025), 0.05, 1.0);
                dynLight.args [DynamicLight.Light_Intensity] = int (floor (85 * mult));
                //dynLight.args [DynamicLight.Light_Secondary_Intensity] = int (floor (75 * mult));
            } else
                return ResolveState ("RanOut");

            time--;

            return ResolveState (null);
        }
        loop;

    Death:
        TNT1 A 0 {
            if (!initialized)
                PostBeginPlay ();

            vel.x = vel.y = 0;
            A_SetGravity (1.0);
        }
    Loople:
        THGR A 1 {
            if (time <= 0)
                return ResolveState ("RanOut");

            if (dynLight) {
                double mult = 1.0;
                if (time < (maxTime * 0.25))
                    mult = Clamp (time / (maxTime * 0.025), 0.05, 1.0);
                dynLight.args [DynamicLight.Light_Intensity] = int (floor (85 * mult));
                //dynLight.args [DynamicLight.Light_Secondary_Intensity] = int (floor (75 * mult));
            } else
                return ResolveState ("RanOut");

            time--;

            return ResolveState (null);
        }
        loop;

    RanOut:
        THGR B 1 {
            if (dynLight)
                dynLight.A_Remove (AAPTR_Default, RMVF_EVERYTHING);

            A_StopSound (CHAN_7);
            A_SpawnItemEx ("S7_Thumper_Used", 0.0, 0.0, 0.0, vel.x, vel.y, vel.z, 0, SXF_NoCheckPosition | SXF_TransferTranslation | SXF_TransferPitch | SXF_TransferPointers | SXF_AbsoluteVelocity);
        }
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Clusterbomb
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeCluster : S7_ThumperGrenade {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 3.0) * 18);
        translation "112:127=200:207";
    }

    const AngleDiff = 60;

    states {
    Loople:
        TNT1 A 15 {
            A_PlaySound ("Explosions/Explosion1");

            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (70, 70);

            int i;
            double spawnZ = 0;
            double zMul = 1;

            if (pos.z + height >= ceilingZ) {
                spawnZ = -2;
                zMul = -1;
            } else if (pos.z <= floorZ)
                spawnZ = 2;

            while (i <= 360) {
                A_SpawnItemEx ("S7_ThumperGrenadeCluster_Bomb", 0.8, fRandom [weaponSpc] (-0.025, 0.025), spawnZ,
                    3.0, 0.0, fRandom [weaponSpc] (6.75, 7.0) * zMul, i, SXF_TransferPointers | SXF_NoCheckPosition);
                i += AngleDiff;
            }

            A_SetScale (0.43);
            A_SpawnItemEx ("S7_ThumperExplosion", 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_TransferScale);
        }
        stop;
    }
}

class S7_ThumperGrenadeCluster_Bomb : S7_Projectile {
    default {
        radius 1;
        height 1;
        damageFunction (8);
        bounceCount 2;
        BounceSound "Bounce/MetalSmall";

        +bounceOnCeilings +bounceOnFloors +bounceOnWalls +canBounceWater
        +forceXYBillboard
        -noGravity
    }

    states {
    Spawn:
        THGR G 1;
        loop;
    Death:
        XPL3 A         3 bright {
            bNoGravity = TRUE;

            A_PlaySound ("Explosions/Explosion2", CHAN_Body, 0.25);

            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (20, 20);

            A_SetScale (0.2);
        }
        XPL3 BCDEFGHIJ 3 bright;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Nailbomb
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeNail : S7_ThumperGrenade {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 6.0) * 13);
        translation "112:127=200:207";
    }

    const AngleDiff = 20;

    states {
    Loople:
        TNT1 A 15 {
            A_PlaySound ("Explosions/Explosion1");
            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (65, 65);

            double projPitch = 0;

            if (pos.z + height >= ceilingZ)
                projPitch =  22.5;
            else if (pos.z <= floorZ)
                projPitch = -22.5;

            for (int i = 0; i <= 360; i += AngleDiff)
                A_SpawnProjectile ("S7_ThumperGrenadeNail_Nail", 2.2, 0, i, CMF_AimDirection | CMF_TrackOwner, projPitch);

            A_SetScale (0.43);
            A_SpawnItemEx ("S7_ThumperExplosion", 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_TransferScale);
        }
        stop;
    }
}

class S7_ThumperGrenadeNail_Nail : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        radius 2;
        height 2;
        damageFunction (fRandom [weaponDamage] (3.0, 5.0));
        speed 1;
        missileType "S7_HeatSmokeStatic";
        missileHeight 8;

        +noGravity +bloodSplatter +noExtremeDeath +noDamageThrust
        +ripper
    }

    states {
    Spawn:
        NAIL A 5 noDelay A_ScaleVelocity (45);
    Flight:
        TNT1 A 0 A_ChangeVelocity (0.0, 0.0, -0.5);
        NAIL AA 1 A_ScaleVelocity (0.99);
        NAIL A 1;
        loop;
    Death:
        NAIL A 500;
        NAIL A 1 A_FadeOut (0.03);
        wait;
    XDeath:
        TNT1 A 3 A_PlaySound ("Bullet/HitFlesh", CHAN_Body, 0.5);
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Nerve gas
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeNGas : S7_ThumperGrenade {
    default {
        damageFunction (fRandom [weaponDamage] (1.0, 6.0) * 6);
        damageType "TH_GrenadeImpact";
        translation "112:127=104:111";
    }

    int time;

    states {
    Loople:
        THGR B 1 {
            A_PlaySound ("Steam/Burst");

            A_SetGravity (1.0);
            bDontSplash = true;
            bNoDamageThrust = true;
            bBloodlessImpact = true;
            bForceRadiusDMG = true;

            A_SetDamageType ("NerveGas");
            A_Explode (random [weaponDamage] (25, 30), 96, XF_HurtSource, FALSE, 80);

            for (int i = 0; i < 360; i += 25) {
                A_SpawnItemEx ("S7_ThumperGrenadeNGas_GasCloud_Trail", 0.0, 0.0, 1.0,  6.0, 0.0, 0.5, i, SXF_NoCheckPosition);
                A_SpawnItemEx ("S7_ThumperGrenadeNGas_GasCloud_Trail", 0.0, 0.0, 1.0,  3.0, 0.0, 0.5, i + 12.5, SXF_NoCheckPosition);
            }

            time = (2 * 35) - random [weaponSpc] (-10, 10);
        }
    ActualLoople:
        THGR B 1 {
            if (time <= 0)
                return ResolveState ("Die");

            A_Explode (3, 64, XF_HurtSource, FALSE, 32);
            A_SpawnItemEx ("S7_ThumperGrenadeNGas_GasCloud_Trail", 0.0, 0.0, 0.25, 0.0, 0.0, 3.5, 0, SXF_NoCheckPosition);
            time--;

            return ResolveState (null);
        }
        loop;
    Die:
        THGR B 1 A_SpawnItemEx ("S7_Thumper_Used", 0.0, 0.0, 0.0, vel.x, vel.y, vel.z, 0, SXF_NoCheckPosition | SXF_TransferTranslation | SXF_TransferPitch | SXF_TransferPointers | SXF_AbsoluteVelocity);
        stop;
    }
}

/** Nerve gas cloud trail **/
class S7_ThumperGrenadeNGas_GasCloud_Trail : S7_ShotSmoke {
    default {
        vSpeed 0;
        scale 0.35;
        alpha 1.0;
    }

    states {
    Spawn:
        SMK2 AABBCCDD 1 {
            if (scale.X <= 0)
                return ResolveState ("Die");

            A_SetScale (scale.X - 0.03);
            A_FadeOut (0.03);

            return ResolveState (null);
        }
        loop;
    Die:
        TNT1 A 0;
        stop;
    }
}