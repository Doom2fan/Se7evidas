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
        Radius 10;
        Height 10;
        Speed 75;
        DamageFunction (fRandom [weaponDamage] (1.0, 6.0) * 18);
        Scale 0.8;
        Gravity 0.25;
        Translation "112:127=216:223";

        -NOGRAVITY
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
class S7_ThumperExplosion : Actor {
    default {
        Radius 10;
        Height 10;

        +NOGRAVITY +FORCEXYBILLBOARD +NOINTERACTION +NOBLOCKMAP
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
        DamageFunction (fRandom [weaponDamage] (1.0, 6.0) * 12);
    }

    states {
    Loople:
        TNT1 A  15 {
            A_SetScale (0.43);
            A_PlaySound ("Explosions/Explosion1");

            S7_ActorExtensions.A_S7SpawnShrapnel (
                self, fRandom [weaponSpc] (100, 150),
                minVel: 200, maxVel: 450,
                minMass: 10, maxMass: 25,
                keScale: 125,
                zOff: 2.0, flags: SXF_TransferPointers
            );

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
        DamageFunction (fRandom [weaponDamage] (1.0, 6.0) * 12);
        Translation "112:127=184:191";
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
                    fRandom [weaponSpc] (2.8, 3.0), 0.0, fRandom [weaponSpc] (2.5, 4.0), fRandom [weaponSpc] (0.0, 360.0), SXF_TransferPointers | SXF_NoCheckPosition);
            }

            A_SpawnItemEx ("S7_ThumperExplosion", 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_TransferScale);
        }
        stop;
    }
}

class S7_ThumperGrenadeTherm_Fire : S7_Projectile {
    default {
        Radius 1;
        Height 1;
        Mass 0x7FFFFFFF;
        Args 72;
        RenderStyle "add";
        DamageFunction 0;
        DamageType "ThermiteFire";

        +FORCEXYBILLBOARD +NODAMAGETHRUST +BLOODLESSIMPACT +FORCERADIUSDMG
        +THRUACTORS       +DONTSPLASH
        -NOGRAVITY
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
        DamageFunction (fRandom [weaponDamage] (1.0, 6.0) * 5);
        DamageType "TH_GrenadeImpact";
        Translation "112:127=80:95";

        -NOGRAVITY
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

    override void OnDestroy () {
        if (dynLight)
            dynLight.Destroy ();
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
        DamageFunction (fRandom [weaponDamage] (1.0, 3.0) * 18);
        Translation "112:127=200:207";
    }

    states {
    Loople:
        TNT1 A 15 {
            A_PlaySound ("Explosions/Explosion1");

            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (100, 100);

            double spawnZ = 0;
            double zMul = 1;
            double pitchMin = -22.5, pitchMax = 22.5;

            bool hitFloor = pos.z <= floorZ;
            bool hitCeil = pos.z + height >= ceilingZ;

            if (hitCeil && hitFloor) // Shouldn't really ever happen
                pitchMin = pitchMax = 0.;
            else if (hitCeil) {
                spawnZ = -2;
                pitchMin = 45;
                pitchMax = 45 + 22.5;
            } else if (hitFloor) {
                spawnZ = 2;
                pitchMin = -(5);
                pitchMax = -(5 + 22.5);
            }

            for (int i = random [weaponSpc] (24, 32); i > 0; i--) {
                A_SpawnProjectile ("S7_ThumperGrenadeCluster_Bomb", spawnZ, fRandom [weaponSpc] (-0.025, 0.025), fRandom [weaponSpc] (0, 359),
                    CMF_AimDirection | CMF_TrackOwner | CMF_AbsolutePitch,
                    fRandom [weaponSpc] (pitchMin, pitchMax)
                );
            }

            A_SetScale (0.43);
            A_SpawnItemEx ("S7_ThumperExplosion", 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_TransferScale);
        }
        stop;
    }
}

class S7_ThumperGrenadeCluster_Bomb : S7_Projectile {
    default {
        Radius 5;
        Height 5;
        Speed 30;
        DamageFunction (0);

        BounceCount 2;
        BounceSound "Bounce/MetalSmall";

        Scale 0.25;

        +BOUNCEONCEILINGS +BOUNCEONFLOORS +BOUNCEONWALLS +CANBOUNCEWATER
        +FORCEXYBILLBOARD
        -NOGRAVITY
    }

    states {
    Spawn:
        THGR G 1;
        loop;
    Bounce.Ceiling:
        TNT1 A 0 {
            bouncecount++;
        }
        goto Spawn;

    Death:
        XPL3 A         3 bright {
            bNoGravity = TRUE;

            A_PlaySound ("Explosions/Explosion2", CHAN_Body, 0.25);

            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (random [weaponSpc] (5, 6), 32, fulldamagedistance: 32);

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
        DamageFunction (fRandom [weaponDamage] (1.0, 6.0) * 13);
        Translation "112:127=[255,255,0]:[0,0,0]";
    }

    const AngleDiff = 20;

    states {
    Loople:
        TNT1 A 15 {
            A_PlaySound ("Explosions/Explosion1");
            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (95, 95);

            double spawnZ = 0;
            double zMul = 1;
            double pitchMin = -22.5, pitchMax = 22.5;

            bool hitFloor = pos.z <= floorZ;
            bool hitCeil = pos.z + height >= ceilingZ;

            if (hitCeil && hitFloor) // Shouldn't really ever happen
                pitchMin = pitchMax = 0.;
            else if (hitCeil) {
                spawnZ = -2;
                pitchMin = 45;
                pitchMax = 45 + 22.5;
            } else if (hitFloor) {
                spawnZ = 2;
                pitchMin = -(5);
                pitchMax = -(5 + 22.5);
            }

            for (int i = random [weaponSpc] (64, 96); i > 0; i--) {
                A_SpawnProjectile ("S7_ThumperGrenadeNail_Nail", spawnZ, fRandom [weaponSpc] (-0.025, 0.025), fRandom [weaponSpc] (0, 359),
                    CMF_AimDirection | CMF_TrackOwner | CMF_AbsolutePitch,
                    fRandom [weaponSpc] (pitchMin, pitchMax)
                );
            }

            A_SetScale (0.43);
            A_SpawnItemEx ("S7_ThumperExplosion", 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_TransferScale);
        }
        stop;
    }
}

class S7_ThumperGrenadeNail_Nail : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        Radius 2;
        Height 2;
        DamageFunction (fRandom [weaponDamage] (5.0, 10.0));
        Speed 1;
        /*MissileType "S7_HeatSmokeStatic";
        MissileHeight 8;*/

        +NOGRAVITY +BLOODSPLATTER +NOEXTREMEDEATH +NODAMAGETHRUST
        +RIPPER
    }

    states {
    Spawn:
        NAIL A 5 noDelay A_ScaleVelocity (400);
    Flight:
        TNT1 A 0 A_ChangeVelocity (0.0, 0.0, -0.5);
        NAIL AA 1 A_ScaleVelocity (0.99);
        NAIL A 1;
        loop;
    Death:
        NAIL A 250;
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
        DamageFunction (fRandom [weaponDamage] (1.0, 6.0) * 6);
        DamageType "TH_GrenadeImpact";
        Translation "112:127=104:111";
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
            A_Explode (random [weaponDamage] (25, 30), 192, XF_HurtSource, FALSE, 80);

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

            A_Explode (3, 128, XF_HurtSource, FALSE, 32);
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
        VSpeed 0;
        Scale 0.35;
        Alpha 1.0;
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