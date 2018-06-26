//-------------------------------------------------------------------------------------------
//
// Corpulent
//
//-------------------------------------------------------------------------------------------
class S7_FatFuck : S7_DemonBase {
    default {
        Health 900;
        Radius 48;
        Height 64;
        Speed 5;
        PainChance 80;
        Mass 1500;
        BloodColor "DA E1 00";
        Species "S7FatFuck";
        Tag "$FATFUCKTAG";

        SeeSound "fatso/sight";
        PainSound "fatso/pain";
        DeathSound "fatso/death";
        ActiveSound "fatso/active";

        // Demon/Reanimated flesh damage reduction
        DamageFactor "PistolTracer", 0.7;
        DamageFactor "RevolverTracer", 0.8;
        DamageFactor "RifleTracer", 0.9;
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.5;
        DamageFactor "LaserTracer", 1.25;
        // (Mini-)Boss damage reduction
        DamageFactor "ExplosionSplashDMG", 0.75;
        DamageFactor "Shrapnel", 0.80;

        Monster;

        +MISSILEMORE +FLOORCLIP +DONTMORPH +BOSSDEATH
    }

    int attackRepeatCount;

    states {
    Spawn:
        FAT1 A 15 A_Look;
        loop;

    See:
        TNT1 A      0 A_PlaySound ("Footsteps/Huge", CHAN_5);
        FAT1 AABBCC 5 A_Chase;
        TNT1 A      0 A_PlaySound ("Footsteps/Huge", CHAN_6);
        FAT1 DDEEFF 5 A_Chase;
        loop;

    Missile:
        TNT1 A 0 {
            attackRepeatCount = 0;

            if (target && Distance2D (target) <= (radius + 256) && abs (pos.z - target.pos.z) < 24)
                return ResolveState ("FlamethrowerAttack");
            
            return ResolveState ("FireballAttack");
        }
        goto FireballAttack;
    
    FlamethrowerAttack:
        FAT1 G 6 {
            A_FaceTarget (0, 0);

            if (attackRepeatCount >= 3)
                return ResolveState ("See");
            else if (attackRepeatCount >= 0)
                A_SetTics (2);
            
            return ResolveState (null);
        }
        FAT1 HHHHHH 2 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ("S7_FatFuckFlame", 25.0, -25, -2.5 + fRandom [monsterSpread] (-1.5, 1.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ("S7_FatFuckFlame", 25.0,  25,  2.5 + fRandom [monsterSpread] (-1.5, 1.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 I 5 { attackRepeatCount++; }
        goto FlamethrowerAttack;

    FireballAttack:
        TNT1 A 0 A_PlaySound ("fatso/raiseguns", CHAN_Voice);
        FAT1 GGGGGGGGGG 1 A_FaceTarget (36, 18);

        FAT1 H     10 bright {
            A_FaceTarget (0, 0);
            A_PlaySound ("fatso/attack", CHAN_Weapon);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0, -25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0,  25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 IIIGGG 2 A_FaceTarget (60, 30);

        FAT1 H     10 bright {
            A_FaceTarget (0, 0);
            A_PlaySound ("fatso/attack", CHAN_Weapon);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0, -25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0,  25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 IIIGGG 2 A_FaceTarget (60, 30);

        FAT1 H 10 bright {
            A_FaceTarget (0, 0);
            A_PlaySound ("fatso/attack", CHAN_Weapon);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0, -25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0,  25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 IG 6;
        goto See;

    /*Melee:
        goto See;*/

    Pain:
        FAT1 J 5;
        FAT1 J 5 A_Pain;
        goto See;

    Death:
        FAT1 J     14 A_Pain;
        FAT1 K      4 A_Scream;
        FAT1 L      4;
        FAT1 M      4 A_NoBlocking;
        FAT1 NOPQRS 4;
        FAT1 T     -1;
        stop;

    Raise:
        FAT1 T 4;
        FAT1 SRQPONMLK 4;
        goto Spawn;
    }
}

class S7_FatFuckFlame_Fire : S7_FireBase {
    default {
        RenderStyle "add";
        Alpha 1.0;
        Scale 0.25;
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        scale.x = scale.y = fRandom [sfx] (0.2, 0.3);
    }

    states {
    Spawn:
        FIR1 ABCDEFHIJKL 1 A_SetTics (random [sfx] (1, 2));
        stop;
    }
}

class S7_FatFuckFlame_Trail : S7_EffectsBase {
    default {
        +NOGRAVITY
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            for (int i = random [sfx] (1, 3); i > 0; i--) {
                A_SpawnItemEx ("S7_FatFuckFlame_Fire",
                yOfs: fRandom [sfx] (-6, 6), zOfs: fRandom [sfx] (-6, 6),
                xVel: fRandom [sfx] (-.25, .25), yVel: fRandom [sfx] (-.25, .25), zVel: fRandom [sfx] (-.25, .25),
                flags: SXF_NoCheckPosition | SXF_Clientside);
            }
        }
        stop;
    }
}

class S7_FatFuckFlame_HitFire : S7_FatFuckFlame_Fire {
    override void PostBeginPlay () {
        S7_FireBase.PostBeginPlay ();

        scale.x = scale.y = fRandom [sfx] (0.25, 0.3);
    }
}

class S7_FatFuckFlame : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_EdgeCenters | ColMode_Corners | ColMode_Center;
        S7_Projectile.EffectStepMul 0.45;

        Radius 8;
        Height 8;
        Speed 60;

        MissileType "S7_FatFuckFlame_Trail";
        MissileHeight 8;

        DamageFunction (random (3, 6));
        DamageType "Fire";

        Obituary "$OBFATSOFLAMETHROWER";
    }

    states {
    Spawn:
        TNT1 A 4 A_SpawnItemEx ("S7_FatFuckFlame_Trail", flags: SXF_NoCheckPosition | SXF_Clientside);
        stop;
    
    Death:
        TNT1 AA 1 {
            for (int i = random [sfx] (3, 5); i > 0; i--) {
                A_SpawnItemEx ("S7_FatFuckFlame_Fire",
                yOfs: fRandom [sfx] (-3, 3), zOfs: fRandom [sfx] (-3, 3),
                xVel: fRandom [sfx] (-3, 3), yVel: fRandom [sfx] (-3, 3), zVel: fRandom [sfx] (-3, 3),
                flags: SXF_NoCheckPosition | SXF_Clientside);
            }
        }
        stop;
    }
}

class S7_FatFuckShot : FatShot {
    default {
        Obituary "$OBFATSOFIREBALL";
    }
}