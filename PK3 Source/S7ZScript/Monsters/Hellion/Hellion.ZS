//-------------------------------------------------------------------------------------------
//
// Hellion
//
//-------------------------------------------------------------------------------------------
class S7_Hellion : S7_DemonBase {
    default {
        health 75;
        gibHealth -30;
        radius 20;
        height 56;
        speed 8;
        painChance 200;
        seeSound "Hellion/Sight";
        activeSound "Hellion/Active";
        painSound "Hellion/Pain";
        deathSound "Hellion/Death";
        obituary "$OBHELLION";
        species "Hellion";
        tag "$HELLIONTAG";

        // Fire damage reduction
        damageFactor "Fire", 0.75;
    }

    S7_XPSystem xpSys;

    override void PostBeginPlay () {
        if (!xpSys) {
            GiveInventory ("S7_XPSystem", 1);
            xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
        }

        let serverData = S7_ServerData.Get ();
        xpSys.level = random [monsterStats] (1, 5) * max (1.0, double (serverData.avgLevel) / 20);
        int attrPts = xpSys.level * 2;
        int attrPts2 = attrPts * .25;
        attrPts *= .75;

        while (attrPts > 0) {
            int rnd = random [monsterStats] (0, 3);

            switch (rnd) {
            case 0: xpSys.SetStat (S7Stat_Strength, 1); break;
            case 1: xpSys.SetStat (S7Stat_Defense, 1); break;
            case 2: xpSys.SetStat (S7Stat_Vitality, 1); break;
            case 3:
                int rnd2 = random [monsterStats] (0, 1);
                if (rnd)
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
        if (!xpSys) {
            xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
            if (!xpSys) {
                GiveInventory ("S7_XPSystem", 1);
                xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
            }
        }

        // Strength
        damageMultiply = 1.0 + (0.02 * xpSys.GetStat (S7Stat_Strength));
        // Defense
        damageFactor = clamp (1.0 - (0.01 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, 120 * max (1, level / 3));
            source.GiveInventory ("S7_Cash", 100 * max (1, level / 3));
        }
    }

    states {
    Spawn:
        HELN A 10 A_Look;
        loop;
    See:
        HELN AABBCCDDEEFF 2 A_Chase;
        loop;

    Missile:
        HELN GGGGGGHHIIJJKK 1 A_FaceTarget (26, 13);

        HELN L 6 {
            A_FaceTarget (0, 0);
            A_SpawnProjectile ("S7_HellionBall", 35.0, 0, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch);
        }
        goto See;

    Pain:
        HELN M 2;
        HELN M 2 A_Pain;
        goto See;

    Death:
        HELN N  5 { monsDeathType = 0; }
        HELN O  5 A_Scream;
        HELN P  5;
        HELN Q  5 A_NoBlocking;
        HELN RS 5;
        HELN T -1;
        stop;
    Death.Fire:
        TNT1 A 0 A_JumpIfHealthLower (-15, "RealDeath.Fire");
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
        HELN U    6 { monsDeathType = 1; }
        HELN V    6 A_XScream;
        HELN W    6;
        HELN X    6 A_NoBlocking;
        HELN YZ[\ 6;
        HELN ]   -1;
        stop;

    Raise:
        HELN T      6 A_JumpIf (monsDeathType, "XRaise");
        HELN SRQPON 6;
        goto See;
    XRaise:
        HELN ]        6;
        HELN \[ZYXWVU 6;
        goto See;
    }
}

//-------------------------------------------------------------------------------------------
//
// Hellion fireball
//
//-------------------------------------------------------------------------------------------
class S7_HellionBall : S7_FireballBase {
    default {
        damageFunction (fRandom [monsterDMG] (1.0, 4.0) * 6);
        damageType "Fire";
        speed 12;
        fastSpeed 24;
        obituary "$OBHELLIONFB";
    }

    states {
    Spawn:
        CP00 AABBCC 1 bright {
            A_SpawnItemEx ("S7_FireballSmoke",  0.0, fRandom [sfx] (-3.0, 3.0), -1 + fRandom [sfx] (-3.0, 3.0), fRandom [sfx] (-1.8, -2.2), 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_Clientside);
            A_SpawnItemEx ("S7_FireballSmoke", -2.5, fRandom [sfx] (-3.0, 3.0), -1 + fRandom [sfx] (-3.0, 3.0), fRandom [sfx] (-1.8, -2.2), 0.0, 0.0, 0, SXF_NoCheckPosition | SXF_Clientside);
        }
        loop;
    Death:
        CP00 DEFGH 2 bright;
        stop;
    }
}