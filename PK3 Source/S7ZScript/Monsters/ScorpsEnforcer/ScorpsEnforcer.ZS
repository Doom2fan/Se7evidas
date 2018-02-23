//-------------------------------------------------------------------------------------------
//
// Shadow Corps Trooper
//
//-------------------------------------------------------------------------------------------
class S7_ScorpsEnforcerTracer : S7_BulletTracer {
    default {
        damageFunction (fRandom [monsterDMG] (1.0, 3.0) * 5.5);
        S7_BaseTracer.trueSpeed 250;
        damageType "EnemyRifleTracer";
    }
}
class S7_ScorpsEnforcer : S7_ScorpBase {
    default {
        health 105;
        gibHealth -15;
        painChance 200;
        painSound "Monsters/SCorps1/Pain";
        deathSound "Monsters/SCorps1/Death";
        obituary "$OBSCORPSENFORCER";
        species "ScorpsEnforcer";
        tag "$SCRPSENFRTAG";

        +missileMore
    }

    override void PostBeginPlay () {
        SetTag (S7_Utils.GenName_Male_Eng ());
    }

    states {
    // Initialize
    Spawn:
    Idle:
        SCR2 AAA 1 A_LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted"); // Look for enemies

        SCR2 U  1 {
            if (random [monsterSpc] (0, 255) < 96)
                A_SetAngle (angle + fRandom [monsterSpc] (-5, 5), SPF_Interpolate);

            A_SetTics (random [monsterSpc] (5, 15));
        }
        SCR2 UU 1 A_SetTics (random [monsterSpc] (5, 15));

        SCR2 U 3 {
            if (random [monsterSpc] (0, 255) < 220)
                return ResolveState ("Idle2");

            A_SetAngle (angle + fRandom [monsterSpc] (-8, 8), SPF_Interpolate);
            A_LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetTics (random [monsterSpc] (10, 35));

            return ResolveState (null);
        }
    Idle2:
        TNT1 A 0 {
            if (bAmbush) // If the ambush flag is set, go to special ambush state
                return ResolveState ("Idle.Ambush");
            if (random [monsterSpc] (0, 255) < 100)
                return ResolveState ("Idle");

            return ResolveState (null);
        }
        goto Idle.Wander;
    Idle.Ambush: // Stay still and ambush enemies
        SCR2 U 3 {
            A_LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetTics (random [monsterSpc] (3, 5));
        }
        SCR2 U 3 {
            if (random [monsterSpc] (0, 255) < 96)
                return ResolveState ("Idle.Ambush");

            A_LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetAngle (angle + fRandom [monsterSpc] (-8, 8), SPF_Interpolate);
            A_SetTics (random [monsterSpc] (3, 5));

            return ResolveState (null);
        }
        loop;
    Idle.Wander: // Wander around looking for enemies
        SCR2 ABCD 5 {
            A_Wander ();
            A_LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
        }
        TNT1 A 0 A_Jump (random [monsterSpc] (0, 255) < 18, "Idle");
        loop;

    // Found enemy
    EnemySighted:
        TNT1 A 0 {
            A_AlertMonsters (); A_AlertMonsters (); A_AlertMonsters ();
        }
        goto See;
    // Chasing
    See:
        SCR2 AABBCCDD 3 A_Chase;
        SCR2 AABBCCDD 3 A_Chase;
        loop;

    // Firing
    Missile:
        SCR2 CD 2 A_FaceTarget (90, 45);
        SCR2 U  1 A_SetTics (random [monsterSpc] (3, 8));
    DoShoot:
        TNT1 A 0 {
            if (CheckIfCloser (target, 256) && !(random [monsterSpc] (0, 255) < 128)) {
                fireMode = 1;
                turn = 35.0;
                spreadX = 5.5;
                spreadY = 4.5;
            } else {
                fireMode = 0;
                turn = 25.0;
                spreadX = 4.5;
                spreadY = 3.5;
            }

            if (fireMode)
                return ResolveState ("DoShoot2");

            return ResolveState (random [monsterSpc] (1, 4));
        }
        SCR2 UUUUU 1 A_FaceTarget (abs (turn), abs (turn));
    DoShoot2:
        SCR2 E 1 A_FaceTarget (turn * 2, turn * 2);
        SCR2 F 1 {
            A_FaceTarget (0, 0);
            A_PlaySound ("Monsters/ScorpsEnforcer/Fire", CHAN_Weapon);
            A_SpawnProjectile ("S7_ScorpsEnforcerTracer", 35.0, 10, fRandom [monsterSpread] (-spreadX, spreadX), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-spreadY, spreadY));
            A_SpawnProjectile ("S7_RifleCasingSpawn",     35.0, 10, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_ShotSmoke_2_Spawner",  35.0, 10, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
        }
        SCR2 U 1 A_Jump (fireMode, 1); // If we're firing full auto, skip this frame
        TNT1 A 0 {
            if (CheckIfTargetInLOS (90.0, JLOSF_DeadNoJump)) // If the target is in LOS, keep firing
                return ResolveState ("DoShoot");
            else if (random [monsterSpc] (0, 255) < 160) // Sometimes keep firing even if the target isn't in LOS anyway
                return ResolveState ("CoverFire");

            return ResolveState (null);
        }
        goto EndShoot;

    CoverFire:
        SCR2 E 1 A_JumpIf (!target || target.health <= 0, "EndShoot"); // If the target is dead or we have no target, stop firing
        SCR2 F 1 {
            A_PlaySound ("Monsters/ScorpsEnforcer/Fire", CHAN_Weapon);
            A_SpawnProjectile ("S7_ScorpsEnforcerTracer", 35.0, 10, fRandom [monsterSpread] (-spreadX, spreadX), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-spreadY, spreadY));
            A_SpawnProjectile ("S7_RifleCasingSpawn",     35.0, 10, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_ShotSmoke_2_Spawner",  35.0, 10, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
        }
        SCR2 U 1 A_Jump (fireMode, 1); // If we're firing full auto, skip this frame
        TNT1 A 0 {
            if (CheckIfTargetInLOS (90.0, JLOSF_DeadNoJump)) // If the target comes into LOS, go back to normal shooting
                return ResolveState ("DoShoot");
            else if (random [monsterSpc] (0, 255) < 50) // Sometimes stop firing
                return ResolveState ("EndShoot");

            return ResolveState (null);
        }
        loop;

    EndShoot:
        SCR2 U 5;
        goto See;

    // Flinching
    Pain:
        SCR2 G 2;
        SCR2 G 2 A_Pain;
        goto See;

    // Dead
    Death.Massacre:
    Death:
        SCR2 H 5;
        SCR2 I 5 A_Scream;
        SCR2 J 5 A_NoBlocking;
    Death_AirLoop:
        SCR2 J 1 A_CheckFloor ("Death_HitGround");
        loop;
    Death_HitGround:
        SCR2 KL 5;
        SCR2 M -1;
        stop;

    Death.Fire:
        TNT1 A 0 A_JumpIfHealthLower (-7, "RealDeath.Fire");
        goto Death;
    Death.Fire2:
    RealDeath.Fire:
        BURN ABC        5 bright A_Pain;
        BURN D          5 bright A_Pain;
        TNT1 A          0 A_NoBlocking;
        BURN EFGHIJKLMN 5 bright;
        BURN O          5 bright;
        BURN PQRSTU     5 bright;
        BURN V          1;
        wait;

    XDeath:
        SCR2 H 1;
        SCR2 H 2 A_XScream;
        TNT1 A 0 {
            double defHeight = default.height / 2;

            for (int i = random [sfx] (8, 16); i >= 0; i--) {
                double xo = fRandom [sfx] (-2, 2), yo = fRandom [sfx] (-2, 2), zo = fRandom [sfx] (-2, 2);
                double xvel = fRandom [sfx] (0, 6), zvel = fRandom [sfx] (4, 12);

                A_SpawnItemEx ("S7_GibbingBlood", xofs: xo, yofs: yo, zofs: defHeight + zo, xvel: xvel, zvel: zvel, angle: fRandom [sfx] (0, 360), flags: S7_BloodSXFFlags);
            }

            for (int i = random [sfx] (6, 8); i >= 0; i--) {
                bool MUDA; Actor cloud;
                [MUDA, cloud] = A_SpawnItemEx ("S7_GoreBloodCloud", xofs: fRandom [sfx] (-14, 14), yofs: fRandom [sfx] (-14, 14), zofs: defHeight + fRandom [sfx] (-18, 24),
                 flags: SXF_UseBloodColor | SXF_NoCheckPosition | SXF_Clientside
                );
            }

            for (int i = random [sfx] (8, 15); i >= 0; i--) {
                bool MUDA; Actor gib;
                [MUDA, gib] = A_SpawnItemEx ("S7_GenericGoreBits", zofs: defHeight + fRandom [sfx] (-7, 7),
                    xvel: fRandom [sfx] (2.5, 4.5) * randomPick [sfx] (-1, 1), yvel: fRandom [sfx] (2.5, 4.5) * randomPick [sfx] (-1, 1), zvel: fRandom [sfx] (3.5, 12),
                    flags: SXF_UseBloodColor | SXF_NoCheckPosition | SXF_Clientside
                );
            }
        }
        TNT1 A 1;
        wait;
    /*XDeath:
        SCR2 N  5 { monsDeathType = 1; }
        SCR2 O  5 A_XScream;
        SCR2 P  5 A_NoBlocking;
        SCR2 QR 5;
        SCR2 S -1;
        stop;*/

    // Being revived
    Raise:
        SCR2 LK  5;
        SCR2 JIH 5;
        goto See;
    }
}