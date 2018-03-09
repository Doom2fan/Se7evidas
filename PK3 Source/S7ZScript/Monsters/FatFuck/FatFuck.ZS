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
        TNT1 A 0 A_PlaySound ("fatso/raiseguns", CHAN_Voice);
        FAT1 GGGGGGGGGG 1 A_FaceTarget (36, 18);

        FAT1 H     10 bright {
            A_FaceTarget (0, 0);
            A_PlaySound ("fatso/attack", CHAN_Weapon);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0, -25, fRandom [monsterSpread] (-3.5, 3.5), 0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0,  25, fRandom [monsterSpread] (-3.5, 3.5), 0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 IIIGGG 2 A_FaceTarget (60, 30);

        FAT1 H     10 bright {
            A_FaceTarget (0, 0);
            A_PlaySound ("fatso/attack", CHAN_Weapon);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0, -25, fRandom [monsterSpread] (-3.5, 3.5), 0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0,  25, fRandom [monsterSpread] (-3.5, 3.5), 0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 IIIGGG 2 A_FaceTarget (60, 30);

        FAT1 H 10 bright {
            A_FaceTarget (0, 0);
            A_PlaySound ("fatso/attack", CHAN_Weapon);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0, -25, fRandom [monsterSpread] (-3.5, 3.5), 0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ("S7_FatFuckShot", 25.0,  25, fRandom [monsterSpread] (-3.5, 3.5), 0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
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

class S7_FatFuckShot : FatShot {
    default {
        Obituary "$OBFATSOFIREBALL";
    }
}