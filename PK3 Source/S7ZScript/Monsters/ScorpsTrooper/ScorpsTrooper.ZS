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
// Shadow Corps Trooper
//
//-------------------------------------------------------------------------------------------
class S7_ManxCarbineTracerEnemy : S7_ManxCarbineTracer {
    default {
        DamageFunction (fRandom [monsterDMG] (1.0, 3.0) * 2 * (1+bonusDMGFactor));
        DamageType 'PistolTracer';
    }
}
class S7_ScorpsTrooper : S7_ScorpBase {
    default {
        Health 30;
        GibHealth -15;
        PainChance 200;
        SeeSound "Monsters/ScorpsTrooper/Sight";
        ActiveSound "Monsters/ScorpsTrooper/Active";
        PainSound "Monsters/ScorpsTrooper/Pain";
        DeathSound "Monsters/ScorpsTrooper/Death";
        Obituary "$OBSCORPSTROOPER";
        Species 'ScorpsTrooper';
        Tag "$SCRPSTROOTAG";

        +MISSILEMORE
    }

    S7_XPSystem xpSys;

    override void PostBeginPlay () {
        SetTag (S7_Utils.GenName_Male_Eng ());
        if (!xpSys) {
            GiveInventory ('S7_XPSystem', 1);
            xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
        }

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
        startHealth = int (health * (1.0 + (.05 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;

        ammo = random [monsterAmmo] (12, 23);
    }

    override void Tick () {
        if (!xpSys) {
            xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
            if (!xpSys) {
                GiveInventory ('S7_XPSystem', 1);
                xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
            }
        }

        // Strength
        damageMultiply = 1.0 + (0.02 * xpSys.GetStat (S7Stat_Strength / 2));
        // Defense
        damageFactor = clamp (1.0 - (0.01 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);
        // Agility
        speed = default.Speed + clamp (xpSys.GetStat (S7Stat_Agility) * 0.05, -default.Speed * .75, default.Speed);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (80 * max (1, level / 3.)));
            GiveCash (source, int (75 * max (1, level / 20.)));
        }
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * .05;
    }

    void DoFireGun () {
        A_PlaySound ("Weapons/ManxCarbine/Fire", CHAN_Weapon);

        double agilityStat = xpSys ? xpSys.GetStat (S7Stat_Agility, false) : 0.;
        double accuracyMod = clamp ((1. - (agilityStat * .007)), .25, 1.);
        let tracer = S7_BaseTracer (
            A_SpawnProjectile ('S7_ManxCarbineTracerEnemy', 35.0, 9, fRandom [monsterSpread] (-spreadX, spreadX) * accuracyMod,
                CMF_AimDirection | CMF_AbsolutePitch, pitch + fRandom [monsterSpread] (-spreadY, spreadY) * accuracyMod
            )
        );

        if (tracer)
            tracer.bonusDMGFactor = GetDamageBonus ();

        A_SpawnProjectile ('S7_9mmCasingSpawn',         35.0, 9, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);
        A_SpawnProjectile ('S7_ShotSmoke_2_Spawner',    35.0, 9, 0.0, CMF_AbsolutePitch | CMF_AimDirection, 0.0);

        ammo--;
    }

    action void A_UnblockAndDrop () {
        A_NoBlocking ();

        if (invoker.ammo < 1)
            return;

        let droppedMag = S7_9mmCartridges (S7_ActorExtensions.DropItem (self, 'S7_9mmCartridges'));
        if (droppedMag) {
            droppedMag.Amount = invoker.ammo;
            invoker.ammo = 0;
        }
    }

    states {
    // Initialize
    Spawn:
    Idle:
        SCR1 AAA 1 {
            if (random [monsterSpc] (0, 255) < 160 && ammo < 10) // Maybe reload if less than 10 shots
                return ResolveState ("Reload");

            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted"); // Look for enemies

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
            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
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
            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetTics (random [monsterSpc] (3, 5));
        }
        SCR1 E 3 {
            if (random [monsterSpc] (0, 255) < 96)
                return ResolveState ("Idle.Ambush");

            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
            A_SetAngle (angle + fRandom [monsterSpc] (-8, 8), SPF_Interpolate);
            A_SetTics (random [monsterSpc] (3, 5));

            return ResolveState (null);
        }
        loop;
    Idle.Wander: // Wander around looking for enemies
        SCR1 ABCD 5 {
            S7_Wander ();
            A_S7LookEx (0, 0.0, 0.0, 0.0, 0.0, "EnemySighted");
        }
        TNT1 A 0 A_Jump (random [monsterSpc] (0, 255) < 18, "Idle");
        loop;

    // Found enemy
    EnemySighted:
        TNT1 A 0  A_AlertMonsters (512.);
        goto See;
    // Chasing
    See:
        SCR1 AABBCCDD 3 S7_DoScorpsChase ();
        SCR1 AABBCCDD 3 S7_DoScorpsChase ();
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
            
            DoFireGun ();
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
        SCR1 F 1 DoFireGun ();
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
        SCR1 AABBCCDD 4 S7_Wander;
        TNT1 A        0 {
            bFrightened = false;
            return A_JumpIfInTargetLOS ("Reload", 225.0, JLOSF_NoSight);
        }
        loop;

    // Reloading
    Reload:
        SCR1 A      5;
        SCR1 AAAEE  2;
        SCR1 EEEEEE 1;
        SCR1 E      1 {
            A_PlaySound ("Weapons/ManxCarbine/In", CHAN_Weapon);
            ammo = 23;
        }
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
    Death.Massacre:
    Death:
        SCR1 H 5;
        SCR1 I 5 A_Scream;
        TNT1 A 0 {
            A_UnblockAndDrop ();
            bThruActors = true;
        }
    Death_AirLoop:
        SCR1 J 5;
        TNT1 A 0 A_CheckFloor ("Death_HitGround");
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
        TNT1 A          0 A_UnblockAndDrop ();
        BURN EFGHIJKLMN 5 bright;
        BURN O          5 bright;
        BURN PQRSTU     5 bright;
        BURN V          1;
        wait;

    XDeath:
        SCR1 H 1 { bDontGib = true; }
        SCR1 H 2 {
            A_XScream ();
            A_UnblockAndDrop ();
        }
        TNT1 A 0 S7_SpawnGibs ();
        CRSH A 1 { translation = bloodTranslation; }
        wait;
    /*XDeath:
        SPOS M     5 { monsDeathType = 1; }
        SPOS N     5 A_XScream;
        SPOS O     5 A_UnblockAndDrop ();
        SPOS PQRST 5;
        SPOS U    -1;
        stop;*/

    // Being revived
    Raise:
        SCR1 K   5 {
            bDontGib = false;
            bThruActors = false;
        }
        SCR1 JIH 5;
        goto See;
    }
}