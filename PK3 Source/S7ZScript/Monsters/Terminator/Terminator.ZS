/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
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
// Terminator
//
//-------------------------------------------------------------------------------------------
class S7_Terminator : S7_DemonBase {
    default {
        Health 5000;
        Radius 24;
        Height 64;
        Speed 12;
        PainChance 15;
        Mass 12000;
        MinMissileChance 176;
        Species 'S7Terminator';
        Tag "$TERMTAG";

        SeeSound "Terminator/sight";
        PainSound "Terminator/pain";
        DeathSound "Terminator/death";
        ActiveSound "Terminator/active";

        // Demon/Reanimated flesh damage reduction
        DamageFactor "PistolTracer", 0.7;
        DamageFactor "RevolverTracer", 0.8;
        DamageFactor "RifleTracer", 0.9;
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.5;
        DamageFactor "LaserTracer", 1.25;
        // Boss damage reduction
        DamageFactor "ExplosionSplashDMG", 0.25;
        DamageFactor "Shrapnel", 0.35;

        Monster;

        +FLOORCLIP   +DONTMORPH       +BOSS +BOSSDEATH
        +MISSILEMORE +MISSILEEVENMORE
    }

    int shotsCount;

    states {
    Spawn:
        TERM A 10 A_S7Look;
        loop;

    See:
        TERM A   4 A_PlaySound ("Footsteps/Large", CHAN_5);
        TERM ABB 4 A_S7ChaseDef;
        TERM C   4 A_PlaySound ("Footsteps/Large", CHAN_6);
        TERM CDD 4 A_S7ChaseDef;
        loop;

    Missile:
        TNT1 A 0 A_Jump (171, "Missile.Plasma", "Missile.Grenade");
        goto Missile.Machinegun;
    Missile.NoGrenade:
        TNT1 A 0 A_Jump (128, "Missile.Plasma");
        goto Missile.Machinegun;

    /** Plasma Cannon **/
    Missile.Plasma:
        TNT1 A 0 A_PlaySound ("Terminator/PlasmaStart", CHAN_Weapon); // Play the plasma attack begin sound

        TERM EEEEEE 1 A_FaceTarget (60, 30); // Spin to face target

        TERM F  1 bright {
            Vector3 targPos = LeadTarget (target, 75, (18., 35.));
            double sprMod = Clamp (1 - (targPos.Length () / 512), 0.065, 1.0);
            A_PlaySound ("Terminator/PlasmaFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ('S7_TerminatorPlasma', 35.0, 18, fRandom [monsterSpread] (-2.0, 2.0) * sprMod, CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-1.0, 1.0) * sprMod);
        }
        TERM FF 1 bright;

        TERM EEE 1 A_FaceTarget (120, 60);
        TERM F   1 bright {
            Vector3 targPos = LeadTarget (target, 75, (18., 35.));
            double sprMod = Clamp (1 - (targPos.Length () / 512), 0.065, 1.0);
            A_PlaySound ("Terminator/PlasmaFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ('S7_TerminatorPlasma', 35.0, 18, fRandom [monsterSpread] (-2.0, 2.0) * sprMod, CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-1.0, 1.0) * sprMod);
        }
        TERM FF  1 bright;

        TERM EEE 1 A_FaceTarget (120, 60);
        TERM F   1 bright {
            Vector3 targPos = LeadTarget (target, 75, (18., 35.));
            double sprMod = Clamp (1 - (targPos.Length () / 512), 0.065, 1.0);
            A_PlaySound ("Terminator/PlasmaFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ('S7_TerminatorPlasma', 35.0, 18, fRandom [monsterSpread] (-2.0, 2.0) * sprMod, CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-1.0, 1.0) * sprMod);
        }
        TERM FF  1 bright;

        TERM EEEEE 1;
        goto Missile.End;

    /** Machinegun **/
    Missile.Machinegun:
        TERM GGGG 1 {
            shotsCount = 0;
            A_PlaySound ("Terminator/MachinegunStart", CHAN_Weapon); // Play the machinegun attack begin sound
            A_FaceTarget (90, 45); // Spin to face target
        }
    Missile.Machinegun.Choose:
        TNT1 A 0 {
            if (shotsCount >= 120)
                return ResolveState ("Missile.Machinegun.End");

            shotsCount += 3;

            if (CheckIfCloser (target,  512.0))
                return ResolveState ("Missile.Machinegun.MaxSpeed");
            if (CheckIfCloser (target, 1024.0))
                return ResolveState ("Missile.Machinegun.Mid2Speed");
            if (CheckIfCloser (target, 2048.0))
                return ResolveState ("Missile.Machinegun.Mid1Speed");

            return ResolveState ("Missile.Machinegun.MinSpeed");
        }

    Missile.Machinegun.MaxSpeed:
        TERM H  1 bright {
            A_FaceTarget (0, 0);
            if (!target || !CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 3200.0, 0.0, 0, 0, 35.0, 9.0))
                return ResolveState ("Missile.Machinegun.End");

            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-1.75, 1.75), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.875, 0.875));

            return ResolveState (null);
        }
        TERM GG 1;
        TERM I  1 bright {
            if (!CheckIfCloser (target, 256.0))
                LeadTarget (target, 200.0, (15., 40.));

            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-1.75, 1.75), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.875, 0.875));
        }
        TERM GG 1;
        TERM H  1 bright {
            if (!CheckIfCloser (target, 256.0))
                LeadTarget (target, 200.0, (15., 40.));

            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-1.75, 1.75), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.875, 0.875));
        }
        TERM GG 1;
        TNT1 A  0 A_MonsterRefire (35, "Missile.Machinegun.End");
        goto Missile.Machinegun.Choose;

    Missile.Machinegun.Mid2Speed:
        TERM H   1 bright {
            A_FaceTarget (0, 0);
            if (!target || !CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 3200.0, 0.0, 0, 0, 35.0, 9.0))
                return ResolveState ("Missile.Machinegun.End");

            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-1.0, 1.0), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.5, 0.5));

            return ResolveState (null);
        }
        TERM GGG 1;
        TERM I   1 bright {
            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-1.0, 1.0), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.5, 0.5));
        }
        TERM GGG 1;
        TERM H   1 bright {
            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-1.0, 1.0), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.5, 0.5));
        }
        TERM GGG 1;
        TNT1 A   0 A_MonsterRefire (35, "Missile.Machinegun.End");
        goto Missile.Machinegun.Choose;

    Missile.Machinegun.Mid1Speed:
        TERM H    1 bright {
            A_FaceTarget (0, 0);
            if (!target || !CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 3200.0, 0.0, 0, 0, 35.0, 9.0))
                return ResolveState ("Missile.Machinegun.End");

            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-0.5, 0.5), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.25, 0.25));

            return ResolveState (null);
        }
        TERM GGGG 1;
        TERM I    1 bright {
            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-0.5, 0.5), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.25, 0.25));
        }
        TERM GGGG 1;
        TERM H    1 bright {
            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-0.5, 0.5), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.25, 0.25));
        }
        TERM GGGG 1;
        TNT1 A    0 A_MonsterRefire (35, "Missile.Machinegun.End");
        goto Missile.Machinegun.Choose;

    Missile.Machinegun.MinSpeed:
        TERM H     1 bright {
            A_FaceTarget (0, 0);
            if (!target || !CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 3200.0, 0.0, 0, 0, 35.0, 9.0))
                return ResolveState ("Missile.Machinegun.End");

            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-0.25, 0.25), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.125, 0.125));

            return ResolveState (null);
        }
        TERM GGGGG 1;
        TERM I     1 bright {
            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-0.25, 0.25), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.125, 0.125));
        }
        TERM GGGGG 1;
        TERM H     1 bright {
            LeadTarget (target, 200.0, (15., 40.));
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ('S7_RifleCasingSpawn2', 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ('S7_TerminatorTracer', 40.0, -15, fRandom [monsterSpread] (-0.25, 0.25), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.125, 0.125));
        }
        TERM GGGGG 1;
        TNT1 A     0 A_MonsterRefire (35, "Missile.Machinegun.End");
        goto Missile.Machinegun.Choose;

    Missile.Machinegun.End:
        TERM G 4;
        goto Missile.End;

    /** Launcher **/
    Missile.Grenade:
        TERM J 1 {
            if (!CheckIfCloser (target, 875.0))
                return ResolveState ("Missile.NoGrenade");

            A_PlaySound ("Terminator/LauncherStart", CHAN_Weapon); // Play the launcher attack begin sound
            A_FaceTarget (90, 45); // Spin to face target

            return ResolveState (null);
        }
        TERM JJJ 1 A_FaceTarget (90, 45); // Spin to face target

        TERM K  1 bright {
            Vector3 targPos = LeadTarget (target, 75.0, (18., 35.));
            double newPitch = PitchCorrection (targPos, -18.0, 35.0, 75.0, 0.2);

            if (newPitch != newPitch)
                return ResolveState ("Missile.GrenadeStronger");

            A_SetPitch (-newPitch);
            A_SpawnProjectile ('S7_TerminatorGrenade', 35.0, -18, fRandom [monsterSpread] (-1.0, 1.0), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.75, 0.75));
            A_PlaySound ("Terminator/GrenadeFire", CHAN_Weapon); // Play the firing sound

            return ResolveState (null);
        }
        TERM KK 1 bright;
        goto Missile.Grenade.End;
    Missile.GrenadeStronger:
        TERM K  1 bright {
            Vector3 targPos = LeadTarget (target, 110.0, (18., 35.));
            double newPitch = PitchCorrection (targPos, -18.0, 35.0, 110.0, 0.2);

            if (newPitch != newPitch)
                return ResolveState ("Missile.Nail");

            A_SetPitch (-newPitch);
            A_SpawnProjectile ('S7_TerminatorGrenadeStronger', 35.0, -18, fRandom [monsterSpread] (-1.5, 1.5), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-1.0, 1.0));
            A_PlaySound ("Terminator/GrenadeStrongerFire", CHAN_Weapon); // Play the firing sound

            return ResolveState (null);
        }
        TERM KK 1 bright;
        goto Missile.Grenade.End;
    Missile.Nail: // Speed 130
        TNT1 A 0 A_PlaySound ("Terminator/NailFire", CHAN_Weapon); // Play the firing sound
        TERM K 1 bright A_SpawnProjectile ('S7_TerminatorNail', 35.0, -18, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        TERM KK 1 bright A_FaceTarget (180, 90);
        TERM J 1 A_FaceTarget (0, 0);
        TNT1 A 0 A_PlaySound ("Terminator/NailFire", CHAN_Weapon); // Play the firing sound
        TERM K 1 bright A_SpawnProjectile ('S7_TerminatorNail', 35.0, -18, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        TERM KK 1 bright A_FaceTarget (180, 90);
        TERM J 1 A_FaceTarget (0, 0);
        TNT1 A 0 A_PlaySound ("Terminator/NailFire", CHAN_Weapon); // Play the firing sound
        TERM K 1 bright A_SpawnProjectile ('S7_TerminatorNail', 35.0, -18, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        TERM K 1 bright;
        goto Missile.Grenade.End;

    Missile.Grenade.End:
        TERM JJJJJ 1;
        goto Missile.End;

    Missile.End:
        goto See;

    /*Melee:
        goto See*/

    Pain:
        TERM L 6;
        TERM L 6 A_Pain;
        goto See;

    Death:
        TERM M   15 A_Pain;
        TERM N    4 A_Scream;
        TERM O    4;
        TERM P    4 {
            A_NoBlocking ();

            for (int i = 0; i < 64; i++) {
                A_SpawnItemEx ('S7_Flying_Blood', fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 35 + fRandom [sfx] (-2.5, 2.5),
                    fRandom [sfx] (2.0, 4.0), 0.0, fRandom [sfx] (1.5, 8.0), fRandom [sfx] (0, 360), SXF_TransferTranslation | SXF_UseBloodColor);
            }
        }
        TERM Q    4;
        TERM R    4 {
            A_SpawnItemEx ('S7_Terminator_Arm',      5.0, 25.0, 30.0,   0.0, 10.0, 0.0);
            A_SpawnItemEx ('S7_Terminator_Shoulder', 0.0, 25.0, 58.0,   0.0, 15.0, fRandom [sfx] (1.5, 3.5));
            A_SpawnItemEx ('S7_Terminator_Head',     0.0,  0.0, 64.0, -15.0,  0.0, fRandom [sfx] (3.5, 5.5));
        }
        TERM STUV 4;
        TERM W    4 {
            for (int i = 0; i < 32; i++) {
                A_SpawnItemEx ('S7_Flying_Blood', fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 35 + fRandom [sfx] (-2.5, 2.5),
                    fRandom [sfx] (2.0, 4.0), 0.0, fRandom [sfx] (1.5, 8.0), fRandom [sfx] (0, 360), SXF_TransferTranslation | SXF_UseBloodColor);
            }
        }
        TERM XYZ  4;
        TERM [   -1;
        stop;

    Raise:
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Gore bits
//
//-------------------------------------------------------------------------------------------
class S7_Terminator_Head : S7_GoreBase {
    default {
        BounceType "Hexen";
        BounceFactor 0.65;
        WallBounceFactor 0.65;
        BounceCount 3;

        Projectile;

        -NOGRAVITY
    }

    states {
    Spawn:
        THAD ABCDEFGH 2;
        loop;
    Death:
        THAD I -1;
        stop;
    //Crush:

    }
}

class S7_Terminator_Shoulder : S7_Terminator_Head {
    states {
    Spawn:
        TSHO ABCDEFGH 2;
        loop;
    Death:
        TSHO I -1;
        stop;
    //Crush:

    }
}

class S7_Terminator_Arm : S7_GoreBase {
    states {
    Spawn:
        TARM AB 1;
        wait;
    Crash:
        TARM CDE 1;
        TARM F  -1;
        stop;
    //Crush:

    }
}

//-------------------------------------------------------------------------------------------
//
// Projectiles
//
//-------------------------------------------------------------------------------------------
class S7_TerminatorTracer : S7_BulletTracer {
    default {
        DamageFunction (17 + random [monsterDMG] (-3, 2));
        S7_BaseTracer.TrueSpeed 200;
        DamageType 'RifleTracer';
        Obituary "$OBTERMMGUN";
    }
}

class S7_TerminatorGrenade : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        DamageFunction (24 + random [monsterDMG] (-2, 2));
        //Speed 1;
        Speed 75;
        DeathSound "Explosions/Explosion1";
        Gravity 0.2;
        Obituary "$OBTERMGREN";

        -NOGRAVITY
    }

    states {
    Spawn:
        GRN2 BA 1;
        loop;
    Death:
        XPL1 A    3 {
            bNoGravity = true;
            S7_ActorExtensions.A_S7SpawnShrapnel (self, 100);
            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (96, 128);
        }
        XPL1 BCDE 3;
        stop;
    }
}

class S7_TerminatorGrenadeStronger : S7_TerminatorGrenade {
    default {
        DamageFunction (50 + random [monsterDMG] (-2, 2));
        Speed 110;
        DeathSound "Explosions/Explosion2";
        Obituary "$OBTERMSGREN";
        /*MissileType 'S7_TerminatorGrenadeShockwave';
        MissileHeight 8;*/
    }

    states {
    Spawn:
        GRN2 BB 1 A_SpawnItemEx ('S7_TerminatorGrenadeShockwave');
        GRN2 AA 1 A_SpawnItemEx ('S7_TerminatorGrenadeShockwave');
        loop;
    Death:
        XPL2 A     3 {
            bNoGravity = true;
            S7_ActorExtensions.A_S7SpawnShrapnel (self, 50);
            A_SetDamageType ('ExplosionSplashDMG');
            A_Explode (72, 104);
        }
        XPL2 BCDEF 3;
        stop;
    }
}
class S7_TerminatorGrenadeShockwave : S7_FastProjTrailBase {
    default {
        Scale 0.25;
        RenderStyle "add";
    }

    states {
    Spawn:
        SSHK ABCDEFGHIJKLMNOPQR 1 A_FadeOut (0.03);
        stop;
    }
}

class S7_TerminatorNail : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        /*Radius 2;
        Height 2;*/
        DamageFunction (38 + random [monsterDMG] (-2, 2));
        Speed 130;
        Gravity 0.35;
        Obituary "$OBTERMNAIL";

        +BLOODSPLATTER +NOEXTREMEDEATH +NODAMAGETHRUST
        -NOGRAVITY
    }

    override void Tick () {
        Super.Tick ();
        vel.Z += -GetGravity ();
    }

    states {
    Spawn:
        NAIL A 3;
    Flight:
        NAIL A 1 A_SpawnItemEx ('S7_HeatSmokeStatic', flags: SXF_NoCheckPosition | SXF_Clientside);
        loop;
    Death:
        NAIL A 500;
    Loople:
        NAIL A 1 A_FadeOut (0.03);
        wait;
    XDeath:
        TNT1 A 3 A_PlaySound ("Bullet/HitFlesh", CHAN_Body, 0.5);
        stop;
    }
}

class S7_TerminatorPlasma : S7_Projectile {
    default {
        S7_Projectile.MovementMode FastProjectile;
        DamageFunction (45 + random [monsterDMG] (-2, 2));
        Speed 75;
        RenderStyle "add";
        Scale 0.08;
        MissileType 'S7_TerminatorPlasma_Trail';
        MissileHeight 8;
        Obituary "$OBTERMPLASMA";
    }

    states {
    Spawn:
        FLR1 A 1 bright;
        loop;
    Death:
        TNT1 A 1;
        stop;
    }
}

class S7_TerminatorPlasma_Trail : S7_FastProjTrailBase {
    default {
        Scale 0.08;
        RenderStyle "add";
    }

    states {
    Spawn:
        FLR1 AAA 1 bright A_FadeOut (0.25);
        stop;
    }
}