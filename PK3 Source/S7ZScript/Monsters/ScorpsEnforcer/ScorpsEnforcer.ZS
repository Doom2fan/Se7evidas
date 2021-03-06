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
// Shadow Corps Enforcer
//
//-------------------------------------------------------------------------------------------
class S7_ScorpsEnforcerTracer : S7_BulletTracer {
    default {
        DamageFunction ((6. + fRandom [monsterDMG] (-2., 1.)) * (1. + bonusDMGFactor));
        S7_BaseTracer.TrueSpeed 250;
        DamageType 'RifleTracer';
    }
}
class S7_ScorpsEnforcer : S7_ScorpBase {
    default {
        //$Category "Se7evidas/Monsters"
        //$Color 12
        //$Title "Shadow Corps. Enforcer"
        //$Angled

        Health 105;
        GibHealth -15;
        PainChance 200;
        SeeSound "Monsters/ScorpsEnforcer/Sight";
        PainSound "Monsters/ScorpsEnforcer/Pain";
        DeathSound "Monsters/ScorpsEnforcer/Death";
        Obituary "$OBSCORPSENFORCER";
        Species 'ScorpsEnforcer';
        Tag "$SCRPSENFRTAG";

        +MISSILEMORE
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        SetTag (S7_Utils.GenName_Male_Eng ());
    }

    override void InitializeXPSystem () {
        let serverData = S7_ServerData.Get ();
        xpSys.level = int (max (1.0, (double (serverData.avgLevel) / 2.5) + random [monsterStats] (-2, 2)));
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
        startHealth = int (health * (1.0 + (.07 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;
    }

    override void UpdateStats () {
        // Strength
        damageMultiply = 1.0 + (0.0385 * xpSys.GetStat (S7Stat_Strength / 3));
        // Defense
        damageFactor = clamp (1.0 - (0.02 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);
        // Agility
        speed = default.Speed + clamp (xpSys.GetStat (S7Stat_Agility) * 0.05, -default.Speed * .75, default.Speed);
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (150 * max (1, level / 3.)));
            GiveCash (source, int (clamp (120 * (level / 15.), 120, 120 * 3)));
        }
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * .025;
    }

    void DoFireGun () {
        A_StartSound ("Monsters/ScorpsEnforcer/Fire", slot: CHAN_Weapon);

        double agilityStat = xpSys ? xpSys.GetStat (S7Stat_Agility, false) : 0.;
        double accuracyMod = clamp ((1. - (agilityStat * .005)), .45, 1.);

        let tracer = S7_BaseTracer (
            A_SpawnProjectile ('S7_ScorpsEnforcerTracer', 35.0, 10, fRandom [monsterSpread] (-spreadX, spreadX) * accuracyMod,
                CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-spreadY, spreadY) * accuracyMod
            )
        );

        if (tracer)
            tracer.bonusDMGFactor = GetDamageBonus ();

        A_SpawnProjectile ('S7_RifleCasingSpawn',     35.0, 10, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
        A_SpawnProjectile ('S7_ShotSmoke_2_Spawner',  35.0, 10, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
    }

    states {
    // Initialize
    Spawn:
    Idle:
        SCR2 AAA 1 A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted"); // Look for enemies

        SCR2 U  1 {
            if (random [monsterSpc] () < 96)
                A_SetAngle (angle + fRandom [monsterSpc] (-5, 5), SPF_Interpolate);

            A_SetTics (random [monsterSpc] (5, 15));
        }
        SCR2 UU 1 A_SetTics (random [monsterSpc] (5, 15));

        SCR2 U 3 {
            if (random [monsterSpc] () < 220)
                return ResolveState ("Idle2");

            A_SetAngle (angle + fRandom [monsterSpc] (-8, 8), SPF_Interpolate);
            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetTics (random [monsterSpc] (10, 35));

            return ResolveState (null);
        }
    Idle2:
        TNT1 A 0 {
            if (bAmbush) // If the ambush flag is set, go to special ambush state
                return ResolveState ("Idle.Ambush");
            if (random [monsterSpc] () < 100)
                return ResolveState ("Idle");

            return ResolveState (null);
        }
        goto Idle.Wander;
    Idle.Ambush: // Stay still and ambush enemies
        SCR2 U 3 {
            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetTics (random [monsterSpc] (3, 5));
        }
        SCR2 U 3 {
            if (random [monsterSpc] () < 96)
                return ResolveState ("Idle.Ambush");

            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetAngle (angle + fRandom [monsterSpc] (-8, 8), SPF_Interpolate);
            A_SetTics (random [monsterSpc] (3, 5));

            return ResolveState (null);
        }
        loop;
    Idle.Wander: // Wander around looking for enemies
        SCR2 ABCD 5 {
            S7_Wander ();
            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
        }
        TNT1 A 0 A_Jump (random [monsterSpc] () < 18, "Idle");
        loop;

    // Found enemy
    EnemySighted:
        TNT1 A 0  A_AlertMonsters (256.);
        goto See;
    // Chasing
    See:
        SCR2 AABBCCDD 3 S7_DoScorpsChase ();
        SCR2 AABBCCDD 3 S7_DoScorpsChase ();
        loop;

    // Firing
    Missile:
        SCR2 CD 2 A_FaceTarget (90, 45);
        SCR2 U  1 A_SetTics (random [monsterSpc] (3, 8));
    DoShoot:
        TNT1 A 0 {
            if (CheckIfCloser (target, 192) && !(random [monsterSpc] () < 128)) {
                fireMode = 1;
                turn = 25.0;
                spreadX = 5.5;
                spreadY = 4.5;
            } else {
                fireMode = 0;
                turn = 18.0;
                spreadX = 4.5;
                spreadY = 3.5;
            }

            if (fireMode) {
                A_StartSound ("Monsters/ScorpsEnforcer/Attack", slot: CHAN_Voice);
                return ResolveState (3);
            }

            return ResolveState (random [monsterSpc] (0, 4));
        }
        SCR2 UUUUUU 1 A_FaceTarget (abs (turn), abs (turn));
        TNT1 A      0 A_StartSound ("Monsters/ScorpsEnforcer/Attack", slot: CHAN_Voice);
    DoShoot2:
        SCR2 E 1 A_FaceTarget (turn / 4, turn / 4);
        SCR2 F 1 DoFireGun ();
        SCR2 U 2;
        SCR2 U 1 A_JumpIf (fireMode, 1); // If we're firing full auto, skip this frame
        TNT1 A 0 {
            if (CheckIfTargetInLOS (90.0, JLOSF_DeadNoJump)) // If the target is in LOS, keep firing
                return ResolveState ("DoShoot2");
            else if (random [monsterSpc] () < 160) // Sometimes keep firing even if the target isn't in LOS anyway
                return ResolveState ("CoverFire");

            return ResolveState ("EndShoot");
        }

    CoverFire:
        SCR2 E 1 A_JumpIf (!target || target.health <= 0, "EndShoot"); // If the target is dead or we have no target, stop firing
        SCR2 F 1 DoFireGun ();
        SCR2 U 2;
        SCR2 U 1 A_JumpIf (fireMode, 1); // If we're firing full auto, skip this frame
        TNT1 A 0 {
            if (CheckIfTargetInLOS (90.0, JLOSF_DeadNoJump)) // If the target comes into LOS, go back to normal shooting
                return ResolveState ("DoShoot");
            else if (random [monsterSpc] () < 50) // Sometimes stop firing
                return ResolveState ("EndShoot");

            return ResolveState ("CoverFire");
        }

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
        SCR2 J 5 {
            A_NoBlocking ();
            bThruActors = true;
        }
    Death_AirLoop:
        SCR2 J 5;
        TNT1 A 0 A_CheckFloor ("Death_HitGround");
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
        SCR2 H 1 { bDontGib = true; }
        SCR2 H 2 {
            A_XScream ();
            A_NoBlocking ();
        }
        TNT1 A 0 S7_SpawnGibs ();
        CRSH A 1 { translation = bloodTranslation; }
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
        SCR2 L   5 {
            bDontGib = false;
            bThruActors = false;
        }
        SCR2 K   5;
        SCR2 JIH 5;
        goto See;
    }
}