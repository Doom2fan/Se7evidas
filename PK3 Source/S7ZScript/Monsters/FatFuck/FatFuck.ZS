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

//-------------------------------------------------------------------------------------------
//
// Corpulent
//
//-------------------------------------------------------------------------------------------
class S7_FatFuck : S7_DemonBase {
    default {
        //$Category "Se7evidas/Monsters"
        //$Color 12
        //$Title "Corpulent"
        //$Angled

        Health 900;
        Radius 48;
        Height 64;

        Speed 175;
        S7_MonsterBase.MaxAccel 25;

        S7_MonsterBase.AngularVelocityDecay .03;
        S7_MonsterBase.MaxTurnSpeed 90.;
        S7_MonsterBase.MaxTurnAccel 60;

        PainChance 80;
        Mass 1500;
        BloodColor "DA E1 00";
        Species 'S7FatFuck';
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

    override void InitializeXPSystem () {
        let serverData = S7_ServerData.Get ();
        xpSys.level = int (max (1.0, (double (serverData.avgLevel) / 4.) + fRandom [monsterStats] (-1.5, 2.5)));
        int attrPts = xpSys.level * 4;

        while (attrPts > 0) {
            int rnd = random [monsterStats] (0, 3);

            switch (rnd) {
            case 0: xpSys.SetStat (S7Stat_Strength, 1); break;
            case 1: xpSys.SetStat (S7Stat_Defense, 1); break;
            case 2: xpSys.SetStat (S7Stat_Vitality, 1); break;
            case 3: xpSys.SetStat (S7Stat_Agility, 1); break;
            }

            attrPts--;
        }

        // Vitality
        startHealth = int (health * (1.0 + (.1 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;
    }

    override void UpdateStats () {
        // Strength
        damageMultiply = 1.0 + (0.0225 * xpSys.GetStat (S7Stat_Strength));
        // Defense
        damageFactor = clamp (1.0 - (0.0125 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);
        // Agility
        speed = default.Speed + clamp (xpSys.GetStat (S7Stat_Agility) * 0.1, -default.Speed * .75, default.Speed);
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (850 * max (1, level / 3.5)));
            GiveCash (source, int (clamp (650 * (level / 15.), 650, 650 * 2.5)));
        }
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * 0.065;
    }

    states {
    Spawn:
        FAT1 A 15 A_S7Look;
        loop;

    See:
        TNT1 A      0 A_StartSound ("Footsteps/Huge", slot: CHAN_5);
        FAT1 AABBCC 5 A_S7ChaseDef;
        TNT1 A      0 A_StartSound ("Footsteps/Huge", slot: CHAN_6);
        FAT1 DDEEFF 5 A_S7ChaseDef;
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
        FAT1 GGG 2 A_FaceTarget (90, 45);
        FAT1 HGHGHGHGH 2 {
            A_SpawnProjectile ('S7_FatFuckFlame', 25.0, -25, -2.5 + fRandom [monsterSpread] (-1.5, 1.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ('S7_FatFuckFlame', 25.0,  25,  2.5 + fRandom [monsterSpread] (-1.5, 1.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 I 5 { attackRepeatCount++; }
        goto See;

    FireballAttack:
        TNT1 A 0 A_StartSound ("fatso/raiseguns", slot: CHAN_Voice);
        FAT1 GGGGGGGGGG 1 A_FaceTarget (36, 18);

        FAT1 H     10 bright {
            A_StartSound ("fatso/attack", slot: CHAN_Weapon);
            A_SpawnProjectile ('S7_FatFuckShot', 25.0, -25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ('S7_FatFuckShot', 25.0,  25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 IIIGGG 2;

        FAT1 H     10 bright {
            A_FaceTarget (0, 0);
            A_StartSound ("fatso/attack", slot: CHAN_Weapon);
            A_SpawnProjectile ('S7_FatFuckShot', 25.0, -25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ('S7_FatFuckShot', 25.0,  25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 IIIGGG 2;

        FAT1 H 10 bright {
            A_StartSound ("fatso/attack", slot: CHAN_Weapon);
            A_SpawnProjectile ('S7_FatFuckShot', 25.0, -25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
            A_SpawnProjectile ('S7_FatFuckShot', 25.0,  25, fRandom [monsterSpread] (-3.5, 3.5), CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        FAT1 IG 6;
        goto See;

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

        scale.x = scale.y = fRandom [S7_FireRNG] (0.2, 0.3);
    }

    states {
    Spawn:
        FIR1 ABCDEFHIJKL 1 A_SetTics (random [S7_FireRNG] (1, 2));
        stop;
    }
}

class S7_FatFuckFlame_Trail : S7_EffectsBase {
    default {
        +NOGRAVITY
    }

    override void Tick () {
        if (isFrozen ())
            return;

        CheaperTick ();
    }

    states {
    Spawn:
        TNT1 A 0 noDelay {
            for (int i = random [S7_ProjSFXRNG] (1, 3); i > 0; i--) {
                A_SpawnItemEx ('S7_FatFuckFlame_Fire',
                yOfs: fRandom [S7_ProjSFXRNG] (-6, 6), zOfs: fRandom [S7_ProjSFXRNG] (-6, 6),
                xVel: fRandom [S7_ProjSFXRNG] (-.25, .25), yVel: fRandom [S7_ProjSFXRNG] (-.25, .25), zVel: fRandom [S7_ProjSFXRNG] (-.25, .25),
                flags: SXF_NoCheckPosition | SXF_Clientside);
            }
        }
        stop;
    }
}

class S7_FatFuckFlame_HitFire : S7_FatFuckFlame_Fire {
    override void PostBeginPlay () {
        S7_FireBase.PostBeginPlay ();

        scale.x = scale.y = fRandom [S7_HitsparksRNG] (0.25, 0.3);
    }
}

class S7_FatFuckFlame : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_EdgeCenters | ColMode_Corners | ColMode_Center;
        S7_Projectile.EffectStepMul 0.3;

        Radius 8;
        Height 8;
        Speed 50;

        MissileType 'S7_FatFuckFlame_Trail';
        MissileHeight 8;

        DamageFunction (random (1, 2));
        DamageType 'Fire';

        Obituary "$OBFATSOFLAMETHROWER";
    }

    states {
    Spawn:
        TNT1 A 3;
        stop;

    Death:
        TNT1 AA 1 {
            for (int i = random [S7_HitsparksRNG] (3, 5); i > 0; i--) {
                A_SpawnItemEx ('S7_FatFuckFlame_Fire',
                yOfs: fRandom [S7_HitsparksRNG] (-3, 3), zOfs: fRandom [S7_HitsparksRNG] (-3, 3),
                xVel: fRandom [S7_HitsparksRNG] (-3, 3), yVel: fRandom [S7_HitsparksRNG] (-3, 3), zVel: fRandom [S7_HitsparksRNG] (-3, 3),
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