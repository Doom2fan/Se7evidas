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
// Shadow Corps Trooper
//
//-------------------------------------------------------------------------------------------
class S7_ScorpsHunterTracer : S7_SSGTracer {
    default {
        DamageFunction (fRandom [weaponDamage] (1.75, 5.) * (1. + bonusDMGFactor));
        S7_BaseTracer.TrueSpeed 200;
        DamageType 'ShotgunTracer';
        MissileType 'S7_SSGTracerTrail';
    }
}
class S7_ScorpsHunter : S7_ScorpBase {
    default {
        //$Category "Se7evidas/Monsters"
        //$Color 12
        //$Title "Shadow Corps. Hunter"
        //$Angled

        Health 45;
        GibHealth -22;
        PainChance 200;
        SeeSound "Monsters/ScorpsHunter/Sight";
        ActiveSound "Monsters/ScorpsHunter/Active";
        PainSound "Monsters/ScorpsHunter/Pain";
        DeathSound "Monsters/ScorpsHunter/Death";
        Obituary "$OBSCORPSHUNTER";
        Species 'ScorpsTrooper';
        Tag "$SCRPSHNTRTAG";
    }

    override void PostBeginPlay () {
        Super.PostBeginPlay ();

        SetTag (S7_Utils.GenName_Male_Eng ());
    }

    override void InitializeXPSystem () {
        let serverData = S7_ServerData.Get ();
        xpSys.level = int (max (1.0, double (serverData.avgLevel) + random [monsterStats] (-3, 3)));
        int attrPts = xpSys.level * 2;

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
        startHealth = int (health * (1.0 + (.065 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;

        ammo = random [monsterAmmo] (4, 8);
    }

    override void UpdateStats () {
        // Strength
        damageMultiply = 1.0 + (0.035 * xpSys.GetStat (S7Stat_Strength / 2));
        // Defense
        damageFactor = clamp (1.0 - (0.015 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);
        // Agility
        speed = default.Speed + clamp (xpSys.GetStat (S7Stat_Agility) * 0.05, -default.Speed * .75, default.Speed);
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (100 * max (1, level / 3.)));
            GiveCash (source, int (clamp (85 * (level / 20.), 85, 85 * 4.)));
        }
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * .045;
    }

    override bool S7_Chase_CanMissileTarget () {
        double curAngle = angle, curPitch = pitch;

        A_Face (target, 0., 0.);
        bool ret = CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 65535.0, offsetHeight: 35.0, offsetWidth: 9.0);
        angle = curAngle; pitch = curPitch;

        return ret;
    }

    void DoFireGun () {
        A_PlaySound ("Monsters/ScorpsHunter/Fire", CHAN_Weapon);

        double agilityStat = xpSys ? xpSys.GetStat (S7Stat_Agility, false) : 0.;
        double accuracyMod = clamp ((1. - (agilityStat * .005)), .25, 1.);

        double missOffsetHorz = fRandom [monsterSpread] (-3.5 , 3.5 ) * accuracyMod;
        double missOffsetVert = fRandom [monsterSpread] (-1.25, 1.25) * accuracyMod;

        for (int i = 0; i < 9; i++) {
            let tracer = S7_BaseTracer (
                A_SpawnProjectile ('S7_ScorpsHunterTracer', 35., 9,
                            missOffsetHorz + fRandom [monsterSpread] (-.375, .375), CMF_AimDirection | CMF_AbsolutePitch,
                    pitch + missOffsetVert + fRandom [monsterSpread] (-.375, .375)
                )
            );

            if (tracer)
                tracer.bonusDMGFactor = GetDamageBonus ();
        }

        A_SpawnProjectile ('S7_12gaShellCasingSpawn', 35., 9, 0., CMF_AbsolutePitch | CMF_AimDirection, 0.);
        A_SpawnProjectile ('S7_ShotSmoke_2_Spawner',   35., 9, 0., CMF_AbsolutePitch | CMF_AimDirection, 0.);

        ammo--;
    }

    action void A_UnblockAndDrop () {
        A_NoBlocking ();

        let shotty = S7_Loot_ScorpsHunterSG (S7_ActorExtensions.DropItem (self, 'S7_Loot_ScorpsHunterSG', 1, 128));
        if (shotty) {
            if (random [monsterSpc] () <= 128) { // Don't always drop with ammo, either!
                double level = invoker.xpSys ? invoker.xpSys.level : 1;

                shotty.isBroken = (random [monsterSpc] () <= clamp (96 * (1. + level * 0.04), 96, 256));
                shotty.shellsCount = invoker.ammo;
                invoker.ammo = 0;

                shotty.shellsCount -= int (shotty.shellsCount * fRandom [monsterSpc] (0., min (level * .005, .5)));

                if (random [monsterSpc] () <= clamp (64 * (level * 0.025), 96, 256))
                    shotty.shellsCount /= 2;
            } else
                shotty.shellsCount = 0;
        }
    }

    states {
    // Initialize
    Spawn:
    Idle:
        SCR3 AAA 1 {
            if (random [monsterSpc] () < 160 && ammo < 4) // Maybe reload if less than 5 shots
                return ResolveState ("Reload");

            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted"); // Look for enemies

            return ResolveState (null);
        }

        SCR3 E  1 {
            if (random [monsterSpc] () < 96)
                A_SetAngle (angle + fRandom [monsterSpc] (-5, 5), SPF_Interpolate);

            A_SetTics (random [monsterSpc] (5, 15));
        }
        SCR3 EE 1 A_SetTics (random [monsterSpc] (5, 15));

        SCR3 E 3 {
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
        SCR3 E 3 {
            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetTics (random [monsterSpc] (3, 5));
        }
        SCR3 E 3 {
            if (random [monsterSpc] () < 96)
                return ResolveState ("Idle.Ambush");

            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetAngle (angle + fRandom [monsterSpc] (-8, 8), SPF_Interpolate);
            A_SetTics (random [monsterSpc] (3, 5));

            return ResolveState (null);
        }
        loop;
    Idle.Wander: // Wander around looking for enemies
        SCR3 ABCD 5 {
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
        SCR3 AABBCCDD 3 S7_DoScorpsChase ();
        SCR3 AABBCCDD 3 S7_DoScorpsChase ();
        TNT1 A        0 A_Jump (!(random [monsterSpc] () < 192) && ammo < 2, "Reload");
        loop;
    }

    /** Attacks **/
    states {
    // Firing
    Missile:
        SCR3 CD 2 A_FaceTarget (90, 45);
        SCR3 E  1 {
            A_FaceTarget (0, 0);
            A_SetTics (random [monsterSpc] (2, 4));
        }
    DoAim:
        TNT1 A 0 {
            turn = 20.0;

            if (!ammo)
                return ResolveState ("DryFire");

            return ResolveState (random [monsterSpc] (0, 3));
        }
        SCR3 EEEEEE 1 A_FaceTarget (abs (turn), abs (turn));
    DoShoot:
        SCR3 E 1 A_FaceTarget (turn / 4, turn / 4);
        SCR3 F 1 {
            if (!CheckLOF (CLOFF_NoAim | CLOFF_FromBase, 3200.0, 0.0, 0, 0, 35.0, 9.0))
                return ResolveState ("See");

            DoFireGun ();

            return ResolveState (null);
        }
        goto EndShoot;

    EndShoot:
        SCR3 E 8;
        goto See;

    DryFire:
        SCR3 E 3 A_PlaySound ("Weapons/DryFireRifle", CHAN_7);
        TNT1 A 0 A_Jump (random [monsterSpc] () < 192, "Reload");
    DryFire.FindCover:
        TNT1 A        0 { bFrightened = true; }
        SCR3 AABBCCDD 4 S7_Wander;
        TNT1 A        0 {
            bFrightened = false;
            return A_JumpIfInTargetLOS ("Reload", 225.0, JLOSF_NoSight);
        }
        loop;

    // Reloading
    Reload:
        SCR3 A  5;
        SCR3 A  6;
        SCR3 E  5;
        SCR3 E  1 A_PlaySound ("Monsters/ScorpsHunter/ClipOut", CHAN_5);
        SCR3 E  8;
        SCR3 E  1 {
            A_PlaySound ("Monsters/ScorpsHunter/ClipIn", CHAN_6);
            ammo = 8;
        }
        SCR3 EA 5;
        SCR3 A  3;
        goto Idle;
    }

    /** Pain & Death **/
    states {
    // Flinching
    Pain:
        SCR3 G 2;
        SCR3 G 2 A_Pain;
        goto See;

    // Dead
    Death.Massacre:
    Death:
        SCR3 H 5 {
            A_UnblockAndDrop ();
            bThruActors = true;
        }
    Death_AirLoop:
        SCR3 H 5;
        TNT1 A 0 A_CheckFloor ("Death_HitGround");
        loop;
    Death_HitGround:
        SCR3 I  5 A_Scream;
        SCR3 J  5;
        SCR3 K  5;
        SCR3 LM 3;
        SCR3 N -1;
        stop;

    Death.Fire:
        TNT1 A 0 A_JumpIfHealthLower (-7, "RealDeath.Fire");
        goto Death;
    Death.Fire2:
    RealDeath.Fire:
        BURN ABC        5 bright A_Pain;
        BURN D          5 bright A_Pain;
        TNT1 A          0 A_UnblockAndDrop ();
        BURN EFGHIJKLMN 5 bright;
        BURN O          5 bright;
        BURN PQRSTU     5 bright;
        BURN V          1;
        wait;

    XDeath:
        SCR3 H 1 { bDontGib = true; }
        SCR3 H 2 {
            A_XScream ();
            A_UnblockAndDrop ();
        }
        TNT1 A 0 S7_SpawnGibs ();
        CRSH A 1 { translation = bloodTranslation; }
        wait;
    /*XDeath:
        SPOS O     5 { monsDeathType = 1; }
        SPOS P     5 A_XScream;
        SPOS Q     5 A_UnblockAndDrop ();
        SPOS RSTUV 5;
        SPOS W    -1;
        stop;*/

    // Being revived
    Raise:
        SCR3 M    3 {
            bDontGib = false;
            bThruActors = false;
        }
        SCR3 L    3;
        SCR3 KJIH 5;
        goto See;
    }
}