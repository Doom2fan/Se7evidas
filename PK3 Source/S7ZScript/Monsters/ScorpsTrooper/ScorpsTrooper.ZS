//-------------------------------------------------------------------------------------------
//
// Shadow Corps Trooper
//
//-------------------------------------------------------------------------------------------
class S7_ManxCarbineTracerEnemy : S7_ManxCarbineTracer {
    default {
        damageFunction (fRandom [monsterDMG] (1.0, 3.0) * 2);
        damageType "EnemyPistolTracer";
    }
}
class S7_ScorpsTrooper : S7_ScorpBase {
    default {
        health 30;
        gibHealth -15;
        painChance 200;
        painSound "Monsters/SCorps1/Pain";
        deathSound "Monsters/SCorps1/Death";
        obituary "$OBSCORPSTROOPER";
        species "ScorpsTrooper";
        tag "$SCRPSTROOTAG";

        +missileMore
    }

    S7_XPSystem xpSys;

    override void PostBeginPlay () {
        SetTag (S7_Utils.GenName_Male_Eng ());
        if (!xpSys) {
            GiveInventory ("S7_XPSystem", 1);
            xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
        }

        let serverData = S7_ServerData.Get ();
        xpSys.level = random [monsterStats] (1, 3) * max (1.0, double (serverData.avgLevel) / 20);
        int attrPts = xpSys.level * 1;
        int attrPts2 = attrPts * .25;
        attrPts *= .75;

        while (attrPts > 0) {
            int rnd = random [monsterStats] (0, 3);

            switch (rnd) {
            case 0: xpSys.SetStat (S7Stat_Strength, 1); break;
            case 1: xpSys.SetStat (S7Stat_Defense, 1); break;
            case 2: xpSys.SetStat (S7Stat_Vitality, 1); break;
            case 3:
                int rnd2 = random (0, 4);
                if (rnd > 1)
                    xpSys.SetStat (S7Stat_Agility, 1);
                else
                    xpSys.SetStat (S7Stat_Will, 1);
                break;
            }

            attrPts--;
        }

        // Vitality
        startHealth = health *= 1.0 + (.05 * xpSys.GetStat (S7Stat_Vitality));
    }

    override void Tick () {
        Super.Tick ();

        if (!xpSys) {
            xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
            if (!xpSys) {
                GiveInventory ("S7_XPSystem", 1);
                xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
            }
        }

        // Strength
        damageMultiply = 1.0 + (0.02 * xpSys.GetStat (S7Stat_Strength / 2));
        // Defense
        damageFactor = clamp (1.0 - (0.01 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, 50 * max (1, level / 3));
            source.GiveInventory ("S7_Cash", 50 * max (1, level / 4));
        }
    }

    states {
    // Initialize
    Spawn:
        TNT1 A 0 noDelay {
            ammo = random [monsterAmmo] (8, 23);
        }
    Idle:
        SCR1 AAA 1 {
            if (random [monsterSpc] (0, 255) < 160 && ammo < 10) // Maybe reload if less than 10 shots
                return ResolveState ("Reload");

            A_LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted"); // Look for enemies

            return ResolveState (null);
        }

        SCR1 E  1 {
            if (random [monsterSpc] (0, 255) < 96)
                A_SetAngle (angle + fRandom [monsterSpc] (-5, 5), SPF_Interpolate);

            A_SetTics (random [monsterSpc] (5, 15));
        }
        SCR1 EE 1 A_SetTics (random [monsterSpc] (5, 15));

        SCR1 E 3 {
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
        SCR1 E 3 {
            A_LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetTics (random [monsterSpc] (3, 5));
        }
        SCR1 E 3 {
            if (random [monsterSpc] (0, 255) < 96)
                return ResolveState ("Idle.Ambush");

            A_LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetAngle (angle + fRandom [monsterSpc] (-8, 8), SPF_Interpolate);
            A_SetTics (random [monsterSpc] (3, 5));

            return ResolveState (null);
        }
        loop;
    Idle.Wander: // Wander around looking for enemies
        SCR1 ABCD 5 {
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
        SCR1 AABBCCDD 3 A_Chase;
        SCR1 AABBCCDD 3 A_Chase;
        TNT1 A        0 A_Jump (!(random [monsterSpc] (0, 255) < 192) && ammo < 5, "Reload");
        loop;

    // Firing
    Missile:
        SCR1 CD 2 A_FaceTarget (90, 45);
        SCR1 E  1 {
            A_FaceTarget (0, 0);
            A_SetTics (random [monsterSpc] (3, 8));
        }
    DoShoot:
        TNT1 A 0 {
            if (!CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 3200.0, 0.0, 0, 0, 35.0, 9.0))
                return ResolveState ("See");

            if (CheckIfCloser (target, 512)) {
                fireMode = 1;
                turn = 30.0;
                spreadX = 4.0;
                spreadY = 3.0;
            } else {
                fireMode = 0;
                turn = 20.0;
                spreadX = 3.625;
                spreadY = 2.625;
            }

            if (!ammo)
                return ResolveState ("DryFire");

            if (fireMode)
                return ResolveState ("DoShoot2");

            return ResolveState (random [monsterSpc] (1, 4));
        }
        SCR1 EEEEE 1 A_FaceTarget (abs (turn), abs (turn));
    DoShoot2:
        SCR1 E 1 A_FaceTarget (turn * 2, turn * 2);
        SCR1 F 1 {
            A_FaceTarget (0, 0);
            A_PlaySound ("Weapons/ManxCarbine/Fire", CHAN_Weapon);
            A_SpawnProjectile ("S7_ManxCarbineTracerEnemy", 35.0, 9, fRandom [monsterSpread] (-spreadX, spreadX), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-spreadY, spreadY));
            A_SpawnProjectile ("S7_9mmCasingSpawn",         35.0, 9, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_ShotSmoke_2_Spawner",    35.0, 9, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            ammo--;
        }
        SCR1 EEE 1 A_FaceTarget (turn * 1.5, turn * 1.5);
        TNT1 A 0 {
            if (CheckIfTargetInLOS (90.0, JLOSF_DeadNoJump)) // If the target is in LOS, keep firing
                return ResolveState ("DoShoot");
            else if (random [monsterSpc] (0, 255) < 128) // Sometimes keep firing even if the target isn't in LOS anyway
                return ResolveState ("CoverFire");

            return ResolveState (null);
        }
        goto EndShoot;

    CoverFire:
        SCR1 E 1 {
            if (!target) // If the target is dead or we have no target, stop firing
                return ResolveState ("EndShoot");
            if (!ammo) // If we ran out of ammo, dryfire
                return ResolveState ("DryFire");
            if (fireMode) // If we're firing full auto, skip this.
                return ResolveState (1);

            A_SetTics (random [monsterSpc] (1, 3));

            return ResolveState (null);
        }
        SCR1 E 1;
        SCR1 F 1 {
            A_PlaySound ("Weapons/ManxCarbine/Fire", CHAN_Weapon);
            A_SpawnProjectile ("S7_ManxCarbineTracerEnemy", 35.0, 9, fRandom [monsterSpread] (-spreadX, spreadX), CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-spreadY, spreadY));
            A_SpawnProjectile ("S7_9mmCasingSpawn",         35.0, 9, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            A_SpawnProjectile ("S7_ShotSmoke_2_Spawner",    35.0, 9, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
            ammo--;
        }
        SCR1 E 3;
        TNT1 A 0 {
            if (CheckIfTargetInLOS (90.0, JLOSF_DeadNoJump)) // If the target comes into LOS, go back to normal shooting
                return ResolveState ("DoShoot");
            else if (random [monsterSpc] (0, 255) < 96) // Sometimes stop firing
                return ResolveState ("EndShoot");

            return ResolveState (null);
        }
        loop;

    EndShoot:
        SCR1 E 2;
        goto See;

    DryFire:
        SCR1 E 3 A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
        TNT1 A 0 A_Jump (random [monsterSpc] (0, 255) < 192, "Reload");
    DryFire.FindCover:
        TNT1 A        0 { bFrightened = true; }
        SCR1 AABBCCDD 4 A_Wander;
        TNT1 A        0 {
            bFrightened = false;
            return A_JumpIfInTargetLOS ("Reload", 225.0, JLOSF_NoSight);
        }
        loop;

    // Reloading
    Reload:
        SCR1 A      5 { ammo = 23; }
        SCR1 AAAEE  2;
        SCR1 EEEEEE 1;
        SCR1 E      1 A_PlaySound ("Weapons/ManxCarbine/In", CHAN_Weapon);
        SCR1 E      1;
        SCR1 EEEAAA 2;
        SCR1 A      3;
        goto Idle;

    // Flinching
    Pain:
        SCR1 G 2;
        SCR1 G 2 A_Pain;
        goto See;

    // Dead
    Death:
        SCR1 H 5 { monsDeathType = 0; }
        SCR1 I 5 A_Scream;
        SCR1 J 5 A_NoBlocking;
    Death_AirLoop:
        SCR1 J 1 A_CheckFloor ("Death_HitGround");
        loop;
    Death_HitGround:
        SCR1 K  5;
        SCR1 L -1;
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
        SPOS M     5 { monsDeathType = 1; }
        SPOS N     5 A_XScream;
        SPOS O     5 A_NoBlocking;
        SPOS PQRST 5;
        SPOS U    -1;
        stop;

    // Being revived
    Raise:
        SCR1 K   5 A_JumpIf (monsDeathType, "XRaise");
        SCR1 JIH 5;
        goto See;
    XRaise:
        SPOS T       5;
        SPOS SRQPONM 5;
        goto See;
    }
}