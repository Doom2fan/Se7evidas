//-------------------------------------------------------------------------------------------
//
// Terminator
//
//-------------------------------------------------------------------------------------------
class S7_Terminator : S7_DemonBase {
    default {
        health 5000;
        radius 24;
        height 64;
        speed 12;
        painChance 15;
        mass 12000;
        minMissileChance 176;
        species "S7Terminator";
        tag "$TERMTAG";

        seeSound "Terminator/sight";
        painSound "Terminator/pain";
        deathSound "Terminator/death";
        activeSound "Terminator/active";

        // Demon/Reanimated flesh damage reduction
        damageFactor "PistolTracer", 0.7;
        damageFactor "RevolverTracer", 0.8;
        damageFactor "RifleTracer", 0.9;
        // Plasma/Laser damage bonus
        damageFactor "Plasma", 1.5;
        damageFactor "LaserTracer", 1.25;
        // Boss damage reduction
        damageFactor "ExplosionSplashDMG", 0.25;
        damageFactor "Shrapnel", 0.35;

        monster;
        +floorClip +dontMorph +boss +bossDeath
        +missileMore +missileEvenMore
    }

    int shotsCount;

    virtual Vector3 LeadTarget (Actor targ, double projSpeed) {
        if (!target)
            return (double.NaN, double.NaN, double.NaN);

        Vector3 targPos = targ.pos;
        targPos.z += targ.height / 2;
        if (targ.vel.x != 0 || targ.vel.y != 0 || targ.vel.z != 0) { // If the target is moving, lead it.
            Vector3 tempTargPos = S7_Math.CalculateInterceptShotPosition (pos, targPos, targ.vel, projSpeed);

            if (targPos.x != double.NaN && targPos.y != double.NaN && targPos.z != double.NaN)
                targPos = tempTargPos;
        }

        let marker = Spawn ("S7_PositionMarker", targPos);
        A_Face (marker, 0, 0);
        marker.Destroy ();
        return targPos;
    }

    virtual double PitchCorrection (Vector3 targPos, double xyOffs, double zOffs, double projSpeed, double grav, bool retX1 = false) {
        double x1, x2;
        [x1, x2] = S7_Math.InterceptShotPitch ((pos.x + cos (angle)*xyOffs, pos.y + sin (angle)*xyOffs, pos.z + zOffs), targPos, projSpeed, grav);

        if (!(x1 != double.NaN) && !(x2 != double.NaN)) // If these are null, well fuck. Probably means we can't hit.
            return double.NaN;
        else if (!(x1 != double.NaN))
            return x2;
        else if (!(x2 != double.NaN))
            return x1;

        if (retX1)
            return x1;
        else
            return x2;
    }

    states {
    Spawn:
        TERM A 1 noDelay ACS_NamedExecuteAlways ("S7_TerminatorScript", 0);
    Idle:
        TERM A 10 A_Look;
        loop;

    See:
        TERM A   4 A_PlaySound ("Footsteps/Large", CHAN_5);
        TERM ABB 4 A_Chase;
        TERM C   4 A_PlaySound ("Footsteps/Large", CHAN_6);
        TERM CDD 4 A_Chase;
        loop;

    Missile:
        TNT1 A 0 A_Jump (171, "Missile.Plasma");//, "Missile.Grenade");
        goto Missile.Machinegun;
    Missile.NoGrenade:
        TNT1 A 0 A_Jump (128, "Missile.Plasma");
        goto Missile.Machinegun;

    /** Plasma Cannon **/
    Missile.Plasma:
        TNT1 A 0 A_PlaySound ("Terminator/PlasmaStart", CHAN_Weapon); // Play the plasma attack begin sound

        TERM EEEEEE 1 A_FaceTarget (60, 30); // Spin to face target

        TERM F  1 bright {
            Vector3 targPos = LeadTarget (target, 75);
            double sprMod = Clamp (1 - (targPos.Length () / 512), 0.065, 1.0);
            A_PlaySound ("Terminator/PlasmaFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ("S7_TerminatorPlasma", 35.0, 18, fRandom [monsterSpread] (-2.0, 2.0) * sprMod, CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-1.0, 1.0) * sprMod);
        }
        TERM FF 1 bright;

        TERM EEE 1 A_FaceTarget (120, 60);
        TERM F   1 bright {
            Vector3 targPos = LeadTarget (target, 75);
            double sprMod = Clamp (1 - (targPos.Length () / 512), 0.065, 1.0);
            A_PlaySound ("Terminator/PlasmaFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ("S7_TerminatorPlasma", 35.0, 18, fRandom [monsterSpread] (-2.0, 2.0) * sprMod, CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-1.0, 1.0) * sprMod);
        }
        TERM FF  1 bright;

        TERM EEE 1 A_FaceTarget (120, 60);
        TERM F   1 bright {
            Vector3 targPos = LeadTarget (target, 75);
            double sprMod = Clamp (1 - (targPos.Length () / 512), 0.065, 1.0);
            A_PlaySound ("Terminator/PlasmaFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ("S7_TerminatorPlasma", 35.0, 18, fRandom [monsterSpread] (-2.0, 2.0) * sprMod, CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-1.0, 1.0) * sprMod);
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

            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-1.75, 1.75), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.875, 0.875));

            return ResolveState (null);
        }
        TERM GG 1;
        TERM I  1 bright {
            if (!CheckIfCloser (target, 256.0))
                LeadTarget (target, 200.0);

            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-1.75, 1.75), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.875, 0.875));
        }
        TERM GG 1;
        TERM H  1 bright {
            if (!CheckIfCloser (target, 256.0))
                LeadTarget (target, 200.0);

            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-1.75, 1.75), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.875, 0.875));
        }
        TERM GG 1;
        TNT1 A  0 A_MonsterRefire (35, "Missile.Machinegun.End");
        goto Missile.Machinegun.Choose;

    Missile.Machinegun.Mid2Speed:
        TERM H   1 bright {
            A_FaceTarget (0, 0);
            if (!target || !CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 3200.0, 0.0, 0, 0, 35.0, 9.0))
                return ResolveState ("Missile.Machinegun.End");

            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-1.0, 1.0), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.5, 0.5));

            return ResolveState (null);
        }
        TERM GGG 1;
        TERM I   1 bright {
            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-1.0, 1.0), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.5, 0.5));
        }
        TERM GGG 1;
        TERM H   1 bright {
            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-1.0, 1.0), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.5, 0.5));
        }
        TERM GGG 1;
        TNT1 A   0 A_MonsterRefire (35, "Missile.Machinegun.End");
        goto Missile.Machinegun.Choose;

    Missile.Machinegun.Mid1Speed:
        TERM H    1 bright {
            A_FaceTarget (0, 0);
            if (!target || !CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 3200.0, 0.0, 0, 0, 35.0, 9.0))
                return ResolveState ("Missile.Machinegun.End");

            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-0.5, 0.5), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.25, 0.25));

            return ResolveState (null);
        }
        TERM GGGG 1;
        TERM I    1 bright {
            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-0.5, 0.5), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.25, 0.25));
        }
        TERM GGGG 1;
        TERM H    1 bright {
            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-0.5, 0.5), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.25, 0.25));
        }
        TERM GGGG 1;
        TNT1 A    0 A_MonsterRefire (35, "Missile.Machinegun.End");
        goto Missile.Machinegun.Choose;

    Missile.Machinegun.MinSpeed:
        TERM H     1 bright {
            A_FaceTarget (0, 0);
            if (!target || !CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 3200.0, 0.0, 0, 0, 35.0, 9.0))
                return ResolveState ("Missile.Machinegun.End");

            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-0.25, 0.25), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.125, 0.125));

            return ResolveState (null);
        }
        TERM GGGGG 1;
        TERM I     1 bright {
            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-0.25, 0.25), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.125, 0.125));
        }
        TERM GGGGG 1;
        TERM H     1 bright {
            LeadTarget (target, 200.0);
            A_PlaySound ("Terminator/MachinegunFire", CHAN_Weapon);
            A_SpawnProjectile ("S7_RifleCasingSpawn2", 40.0, -14, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_TerminatorTracer", 40.0, -15, fRandom [monsterSpread] (-0.25, 0.25), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-0.125, 0.125));
        }
        TERM GGGGG 1;
        TNT1 A     0 A_MonsterRefire (35, "Missile.Machinegun.End");
        goto Missile.Machinegun.Choose;

    Missile.Machinegun.End:
        TERM G 4;
        goto Missile.End;

    /** Launcher **/
    /**Missile.Grenade: // Well, right now pitch calculation is broken. And probably always was. We'll fix that later.
        TERM J 1 {
            //if (!CheckIfCloser (target, 875.0))
                //return ResolveState ("Missile.NoGrenade");

            A_PlaySound ("Terminator/LauncherStart", CHAN_Weapon); // Play the launcher attack begin sound
            A_FaceTarget (90, 45); // Spin to face target

            return ResolveState (null);
        }
        TERM JJJ 1 A_FaceTarget (90, 45); // Spin to face target

        TERM K  1 bright {
            Vector3 targPos = LeadTarget (target, 75.0);
            double newPitch = PitchCorrection (targPos, -18.0, 35.0, 75.0, 0.2);

            if (newPitch == double.NaN)
                return ResolveState ("Missile.GrenadeStronger");

            A_SetPitch (-newPitch);
            A_PlaySound ("Terminator/GrenadeFire", CHAN_Weapon); // Play the firing sound
            A_SpawnProjectile ("S7_TerminatorGrenade", 35.0, -18, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);

            newPitch = PitchCorrection (targPos, -18.0, 35.0, 75.0, 0.2, true);
            A_SetPitch (-newPitch);
            A_SpawnProjectile ("S7_TerminatorGrenade", 35.0, -18, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);

            return ResolveState (null);
        }
        TERM KK 1 bright;
        goto Missile.Grenade.End;
    Missile.GrenadeStronger: // speed 110
        TNT1 A  0 A_PlaySound ("Terminator/GrenadeStrongerFire", CHAN_Weapon); // Play the firing sound
        TERM K  1 bright A_SpawnProjectile ("S7_TerminatorGrenadeStronger", 35.0, -18, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        TERM KK 1 bright;
        goto Missile.Grenade.End;
    Missile.Nail: // speed 130
        TNT1 A 0 A_PlaySound ("Terminator/NailFire", CHAN_Weapon); // Play the firing sound
        TERM K 1 bright A_SpawnProjectile ("S7_TerminatorNail", 35.0, -18, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        TERM KK 1 bright A_FaceTarget (180, 90);
        TERM J 1 A_FaceTarget (0, 0);
        TNT1 A 0 A_PlaySound ("Terminator/NailFire", CHAN_Weapon); // Play the firing sound
        TERM K 1 bright A_SpawnProjectile ("S7_TerminatorNail", 35.0, -18, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        TERM KK 1 bright A_FaceTarget (180, 90);
        TERM J 1 A_FaceTarget (0, 0);
        TNT1 A 0 A_PlaySound ("Terminator/NailFire", CHAN_Weapon); // Play the firing sound
        TERM K 1 bright A_SpawnProjectile ("S7_TerminatorNail", 35.0, -18, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        TERM K 1 bright;
        goto Missile.Grenade.End;

    Missile.Grenade.End:
        TERM JJJJJ 1;
        goto Missile.End;*/

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
                A_SpawnItemEx ("S7_Flying_Blood", fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 35 + fRandom [sfx] (-2.5, 2.5),
                    fRandom [sfx] (2.0, 4.0), 0.0, fRandom [sfx] (1.5, 8.0), fRandom (0, 359), SXF_TransferTranslation | SXF_UseBloodColor);
            }
        }
        TERM Q    4;
        TERM R    4 {
            A_SpawnItemEx ("S7_Terminator_Arm",      5.0, 25.0, 30.0,   0.0, 10.0, 0.0);
            A_SpawnItemEx ("S7_Terminator_Shoulder", 0.0, 25.0, 58.0,   0.0, 15.0, fRandom [sfx] (1.5, 3.5));
            A_SpawnItemEx ("S7_Terminator_Head",     0.0,  0.0, 64.0, -15.0,  0.0, fRandom [sfx] (3.5, 5.5));
        }
        TERM STUV 4;
        TERM W    4 {
            for (int i = 0; i < 32; i++) {
                A_SpawnItemEx ("S7_Flying_Blood", fRandom [sfx] (-2.5, 2.5), fRandom [sfx] (-2.5, 2.5), 35 + fRandom [sfx] (-2.5, 2.5),
                    fRandom [sfx] (2.0, 4.0), 0.0, fRandom [sfx] (1.5, 8.0), fRandom (0, 359), SXF_TransferTranslation | SXF_UseBloodColor);
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
        bounceType "Doom";
        bounceFactor 0.65;
        wallBounceFactor 0.65;
        bounceCount 3;
        projectile;

        -noGravity
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
class S7_TerminatorTracer : S7_BaseTracer {
    default {
        damageFunction (fRandom [monsterDMG] (1.0, 3.0) * 8.5);
        S7_BaseTracer.trueSpeed 200;
        damageType "TerminatorTracer";
        obituary "$OBTERMMGUN";
    }
}

class S7_TerminatorGrenade : Actor {
    default {
        damageFunction (fRandom [monsterDMG] (1.0, 3.8) * 10);
        speed 1;
        deathSound "Explosions/Explosion1";
        gravity 0.2;
        obituary "$OBTERMGREN";

        projectile;
        -noGravity
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_ScaleVelocity (75.0);
    Flight:
        GRN2 BA 1;
        loop;
    Death:
        XPL1 A    3 {
            bNoGravity = true;
            S7_ActorExtensions.A_S7SpawnShrapnel (self, 200);
            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (96, 128);
        }
        XPL1 BCDE 3;
        stop;
    }
}

class S7_TerminatorGrenadeStronger : S7_TerminatorGrenade {
    default {
        damageFunction (fRandom [monsterDMG] (1.0, 6.0) * 14.166666666666666666666666666667);
        speed 1;
        deathSound "Explosions/Explosion2";
        obituary "$OBTERMSGREN";
        /*missileType "S7_TerminatorGrenadeShockwave";
        missileHeight 8;*/
    }

    states {
    Spawn:
        TNT1 A 0 noDelay A_ScaleVelocity (110.0);
    Flight:
        GRN2 BB 1 A_SpawnItemEx ("S7_TerminatorGrenadeShockwave");
        GRN2 AA 1 A_SpawnItemEx ("S7_TerminatorGrenadeShockwave");
        loop;
    Death:
        XPL2 A     3 {
            bNoGravity = true;
            S7_ActorExtensions.A_S7SpawnShrapnel (self, 100);
            A_SetDamageType ("ExplosionSplashDMG");
            A_Explode (72, 104);
        }
        XPL2 BCDEF 3;
        stop;
    }
}
class S7_TerminatorGrenadeShockwave : S7_FastProjTrailBase {
    default {
        scale 0.25;
        renderStyle "add";
    }

    states {
    Spawn:
        SSHK ABCDEFGHIJKLMNOPQR 1 A_FadeOut (0.03);
        stop;
    }
}

class S7_TerminatorNail : fastProjectile {
    default {
        /*radius 2;
        height 2;*/
        damageFunction (fRandom [monsterDMG] (1.0, 4.0) * 15);
        speed 1;
        missileType "S7_HeatSmokeStatic";
        missileHeight 8;
        gravity 0.5;
        obituary "$OBTERMNAIL";

        projectile;
        +noGravity +bloodSplatter +noExtremeDeath +noDamageThrust
    }

    states {
    Spawn:
        NAIL A 5 noDelay A_ScaleVelocity (130.0);
        TNT1 A 0 { bNoGravity = false; }
    Flight:
        NAIL A 1;
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

class S7_TerminatorPlasma : fastProjectile {
    default {
        damageFunction (fRandom [monsterDMG] (1.0, 8.0) * 22);
        speed 75;
        renderStyle "add";
        scale 0.08;
        missileType "S7_TerminatorPlasma_Trail";
        missileHeight 8;
        obituary "$OBTERMPLASMA";
    }

    states {
    Spawn:
        FLR1 A 1 bright;
        loop;
    Death:
        stop;
    }
}

class S7_TerminatorPlasma_Trail : S7_FastProjTrailBase {
    default {
        scale 0.08;
        renderStyle "add";
    }

    states {
    Spawn:
        FLR1 AAA 1 bright A_FadeOut (0.25);
        stop;
    }
}