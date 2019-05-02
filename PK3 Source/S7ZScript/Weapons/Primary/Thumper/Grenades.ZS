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
        DamageFunction (65. + fRandom [weaponDamage] (-1., 1.) * (1. + bonusDMGFactor));
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
        TNT1 A 0 {
            A_SetScale (1.);
            A_PlaySound ("Explosions/Explosion1", attenuation: 0.5);

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (128. * (1. + invoker.bonusDMGFactor)), 192, fulldamagedistance: 64);
        }
        goto Explosion;

    Explosion:
        TNT1 A 0 {
            A_SetRenderstyle (1.0, STYLE_Add);
            bForceXYBillboard = true;
            for (int i = random [sfx] (2, 4); i > 0; i--) {
                let act = S7_Smoke3 (Spawn ("S7_Smoke3", pos + (fRandom [sfx] (-15, 15), fRandom [sfx] (-15, 15), 0)));

                act.scale = (0.25 * scale.X, 0.25 * scale.Y);
                act.vel = (
                    fRandom [sfx] (-.15, .15),
                    fRandom [sfx] (.1, .5) * fRandomPick [sfx] (-1, 1),
                    fRandom [sfx] (-.5, .5)
                );
                act.fadeInTime = 0;
                act.stayTime = 15;
                act.fadeOutTime = 10;
                act.targetAlpha = .5;
            }

            let prevInterp = Prev;
            SetOrigin (pos, false);
            Prev = prevInterp;

            {
                let vert = Spawn ("S7_ThumperGrenade_Shockwave", pos);
                vert.scale.X = scale.X;
                vert.angle = angle;
                vert.pitch = 90;
            }

            for (int i = 0; i < 3; i++) {
                let act = Spawn ("S7_ThumperGrenade_Shockwave", pos);
                act.scale.X = scale.X;
                act.angle = fRandom [sfx] (-90, 90);
                act.pitch = 45 + fRandom [sfx] (0, 45);
            }
        }
        XPL1 A    3 bright;
        XPL1 BCDE 2 bright;
        stop;
    }
}

class S7_ThumperGrenade_Shockwave : S7_EffectsBase {
    default {
        Radius 10;
        Height 10;

        RenderStyle "AddStencil";
        StencilColor "CB5707";
        Alpha .5;

        +NOGRAVITY +FORCEXYBILLBOARD +NOINTERACTION +NOBLOCKMAP
    }

    double effectScale;

    states {
    Spawn:
        TNT1 A 0 noDelay {
            effectScale = scale.X;
            scale.X = 12 * effectScale;
            Console.Printf ("%f", scale.X);
        }

        SHCK AAAAA 1 bright { scale.X += 12 * effectScale; }
        SHCK A     1 bright {
            scale.X += 12 * effectScale;
            A_FadeOut (0.2);
        }
        wait;
    }
}

//-------------------------------------------------------------------------------------------
//
// Fragmentation
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeFrag : S7_ThumperGrenade {
    states {
    Loople:
        TNT1 A 0 {
            A_SetScale (.85);
            A_PlaySound ("Explosions/Explosion1", attenuation: 0.5);

            S7_ActorExtensions.A_S7SpawnShrapnel (
                self, random [weaponSpc] (100, 150),
                minVel: int (200. * (1. + invoker.bonusDMGFactor)),
                maxVel: int (450. * (1. + invoker.bonusDMGFactor)),
                minMass: 10, maxMass: 25,
                keScale: 125,
                zOff: 2.0, flags: SXF_TransferPointers
            );

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (128. * (1. + invoker.bonusDMGFactor)), 192, fulldamagedistance: 64);
        }
        goto Explosion;
    }
}

//-------------------------------------------------------------------------------------------
//
// Thermite/Incendiary
//
//-------------------------------------------------------------------------------------------
class S7_ThumperGrenadeTherm : S7_ThumperGrenade {
    default {
        Translation "112:127=184:191";
    }

    states {
    Loople:
        TNT1 A 0 {
            A_PlaySound ("Explosions/Explosion1", attenuation: 0.5);

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (96. * (1. + invoker.bonusDMGFactor)), 144, fulldamagedistance: 48);

            bool hitCeiling = (pos.Z + height >= ceilingZ);

            int count = 20 + random [weaponSpc] (0, 5);
            for (; count > 0; count--) {
                Vector3 firePos = (
                    fRandom [weaponSpc] (-.025, .025),
                    fRandom [weaponSpc] (-.025, .025),
                    .25
                );
                Vector3 fireVel = (
                    fRandom [weaponSpc] (1.75, 6.),
                    0.,
                    fRandom [weaponSpc] (2.5 , 5.)
                );

                if (hitCeiling) {
                    firePos.Z = -firePos.Z;
                    fireVel.X = fRandom [weaponSpc] (0., 6.);
                    fireVel.Z = -fireVel.Z;
                }

                bool success; Actor act;
                [success, act] = A_SpawnItemEx ('S7_ThumperGrenadeTherm_Fire',
                    firePos.X, firePos.Y, firePos.Z,
                    fireVel.X, fireVel.Y, fireVel.Z,
                    fRandom [weaponSpc] (0., 360.), SXF_TransferPointers | SXF_NoCheckPosition
                );

                let fire = S7_Projectile (act);
                if (success && fire)
                    fire.bonusDMGFactor = (1. + invoker.bonusDMGFactor);

                A_SetScale (0.6);
            }
        }
        goto Explosion;
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
        DamageType 'ThermiteFire';

        +FORCEXYBILLBOARD +NODAMAGETHRUST +BLOODLESSIMPACT +FORCERADIUSDMG
        +THRUACTORS       +DONTSPLASH
        -NOGRAVITY
    }

    states {
    Spawn:
        THGR F 1 bright;
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
            A_Explode (int (1. * (1. + invoker.bonusDMGFactor)), 45, XF_HurtSource, fulldamagedistance: 45);
        }
        THGR DE 2 bright;
        loop;
    FadeOut:
        THGR C  2 bright {
            A_SetScale (scale.X - 0.035);
            A_Explode (int (1. * (1. + invoker.bonusDMGFactor)), int (45 * scale.X), XF_HurtSource, fulldamagedistance: int (45 * scale.X));
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
        DamageType 'TH_GrenadeImpact';
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
            dynLight = PointLight (Spawn ('PointLight')); // Spawn the dynamic light
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
            A_SpawnItemEx ('S7_Thumper_Used', 0.0, 0.0, 0.0, vel.x, vel.y, vel.z, 0, SXF_NoCheckPosition | SXF_TransferTranslation | SXF_TransferPitch | SXF_TransferPointers | SXF_AbsoluteVelocity);
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
        Translation "112:127=200:207";
    }

    states {
    Loople:
        TNT1 A 0 {
            A_PlaySound ("Explosions/Explosion1", attenuation: 0.5);

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (64. * (1. + invoker.bonusDMGFactor)), 96, fulldamagedistance: 32);

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
                let bomb = S7_Projectile (
                    A_SpawnProjectile ('S7_ThumperGrenadeCluster_Bomb', spawnZ, fRandom [weaponSpc] (-0.025, 0.025), fRandom [weaponSpc] (0, 359),
                        CMF_AimDirection | CMF_TrackOwner | CMF_AbsolutePitch,
                        fRandom [weaponSpc] (pitchMin, pitchMax)
                    )
                );

                if (bomb)
                    bomb.bonusDMGFactor = (1. + invoker.bonusDMGFactor);
            }

            A_SetScale (0.6);
        }
        goto Explosion;
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

            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (fRandom [weaponSpc] (5., 6.) * (1. + invoker.bonusDMGFactor)), 32, fulldamagedistance: 32);

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
        Translation "112:127=[255,255,0]:[0,0,0]";
    }

    const AngleDiff = 20;

    states {
    Loople:
        TNT1 A 0 {
            A_PlaySound ("Explosions/Explosion1", attenuation: 0.5);
            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (int (64. * (1. + invoker.bonusDMGFactor)), 96, fulldamagedistance: 32);

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
                let nail = S7_Projectile (
                    A_SpawnProjectile ('S7_ThumperGrenadeNail_Nail', spawnZ, fRandom [weaponSpc] (-0.025, 0.025), fRandom [weaponSpc] (0, 359),
                        CMF_AimDirection | CMF_TrackOwner | CMF_AbsolutePitch,
                        fRandom [weaponSpc] (pitchMin, pitchMax)
                    )
                );

                if (nail)
                    nail.bonusDMGFactor = (1. + invoker.bonusDMGFactor);
            }

            A_SetScale (0.8);
        }
        goto Explosion;
    }
}

class S7_ThumperGrenadeNail_Nail : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        Radius 2;
        Height 2;
        DamageFunction (fRandom [weaponDamage] (5., 10.) * (1. + bonusDMGFactor));
        Speed 1;
        /*MissileType 'S7_HeatSmokeStatic';
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
        DamageType 'TH_GrenadeImpact';
        Translation "112:127=104:111";
    }

    action void S7_DoDamage (int dmgMin, int dmgMax, double maxDist, double fullDmgDist, bool zeroMinDmg) {
        let sectorList = new ("S7_SectorList");
        sectorList.Sectors.Clear ();

        S7_ActorExtensions.S7_RecurseSectors (CurSector, sectorList, 0);

        bool randDMG = (dmgMin != dmgMax);

        Array<Actor> actorsDamaged; actorsDamaged.Clear ();
        int secCount = sectorList.Sectors.Size (), actorsDamagedCount = 0;
        for (int i = 0; i < secCount; i++) {
            Sector sec = sectorList.Sectors [i];

            for (Actor mo = sec.thinglist; mo; mo = mo.snext) {
                // Shouldn't happen.
                if (!mo)
                    continue;

                // Don't hurt non-monsters.
                if (!mo.bIsMonster && (!mo.player || mo.player.mo != mo))
                    continue;

                // Don't damage the same actor twice.
                if (actorsDamaged.Find (mo) != actorsDamagedCount)
                    continue;

                // Vulnerable actors can be damaged by radius attacks even if not shootable
                // Used to emulate MBF's vulnerability of non-missile bouncers to explosions.
                if (!(mo.bShootable || mo.bVulnerable))
                    continue;

                double dist = mo.Distance3D (self);
                if (dist > maxDist)
                    continue;

                double dmgFract = (1. - clamp (dist - fullDmgDist, 0., dist) * (1. / (maxDist - fullDmgDist)));
                int moDMG = int (max (
                    (randDMG ? fRandom [weaponDamage] (dmgMin, dmgMax) : dmgMin) * dmgFract,
                    !zeroMinDmg ? !!(random [weaponDamage] (0, 5)) : 0) * (1. + invoker.bonusDMGFactor)
                );
                if (moDMG <= 0)
                    continue;

                mo.DamageMobj (self, target, moDMG, damageType, DMG_Explosion);
                actorsDamaged.Push (mo);
                actorsDamagedCount++;
            }
        }
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

            A_SetDamageType ('NerveGas');
            S7_DoDamage (25, 30, 192., 80., false);


            for (int i = 0; i < 360; i += 25) {
                A_SpawnItemEx ('S7_ThumperGrenadeNGas_GasCloud_Trail', 0.0, 0.0, 1.0,  6.0, 0.0, 0.5, i, SXF_NoCheckPosition);
                A_SpawnItemEx ('S7_ThumperGrenadeNGas_GasCloud_Trail', 0.0, 0.0, 1.0,  3.0, 0.0, 0.5, i + 12.5, SXF_NoCheckPosition);
            }

            time = (2 * 35) - random [weaponSpc] (-10, 10);
        }
    ActualLoople:
        THGR B 1 {
            if (time <= 0)
                return ResolveState ("Die");

            S7_DoDamage (3, 3, 1024., 512., false);
            A_SpawnItemEx ('S7_ThumperGrenadeNGas_GasCloud_Trail', 0.0, 0.0, 0.25, 0.0, 0.0, 3.5, 0, SXF_NoCheckPosition);
            time--;

            return ResolveState (null);
        }
        loop;
    Die:
        THGR B 1 A_SpawnItemEx ('S7_Thumper_Used', 0.0, 0.0, 0.0, vel.x, vel.y, vel.z, 0, SXF_NoCheckPosition | SXF_TransferTranslation | SXF_TransferPitch | SXF_TransferPointers | SXF_AbsoluteVelocity);
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