/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

//-------------------------------------------------------------------------------------------
//
// Infernal Guardian
//
//-------------------------------------------------------------------------------------------
class S7_InfernalGuardian : S7_HellNobleBase {
    default {
        Health 1500;
        GibHealth -750;
        Speed 8;
        PainChance 50;

        SeeSound "Monsters/InfernalGuardian/Sight";
        ActiveSound "Monsters/InfernalGuardian/Active";
        PainSound "Monsters/InfernalGuardian/Pain";
        DeathSound "Monsters/InfernalGuardian/Death";

        HitObituary "$OBINFERNALGUARDIAN_MELEE";
        Species "HellNoble";
        Tag "$INFERNALGUARDIANTAG";

        // Boss damage reduction
        DamageFactor "ExplosionSplashDMG", 0.75;
        DamageFactor "Shrapnel", 0.85;

        +BOSSDEATH
    }

    S7_XPSystem xpSys;

    override void PostBeginPlay () {
        if (!xpSys) {
            GiveInventory ("S7_XPSystem", 1);
            xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
        }

        let serverData = S7_ServerData.Get ();
        xpSys.level = int (random [monsterStats] (1, 5) * max (1.0, double (serverData.avgLevel) / 10));
        int attrPts = int (floor (xpSys.level * 2.5));
        attrPts = int (attrPts * .85);

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
        startHealth = int (health * (1.0 + (.1 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;
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
        damageMultiply = 1.0 + (0.025 * xpSys.GetStat (S7Stat_Strength));
        // Defense
        damageFactor = clamp (1.0 - (0.015 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (1250 * max (1, level / 2.5)));
            GiveCash (source, int (1300 * max (1, level / 2.5)));
        }
    }

    action void DoMeleeAttack () {
        A_CustomMeleeAttack (int (fRandom (1, 4) * 10), "Monsters/InfernalGuardian/MeleeHit", "Monsters/InfernalGuardian/MeleeMiss", "Melee");
    }

    action void DoShieldAttack () {
        A_FaceTarget (0, 0);
        A_SpawnProjectile ("S7_InfernalGuardianShieldShot", 32, -4);
    }

    states {
    Spawn:
        BOS0 A 10 A_S7Look;
        loop;
    See:
        BOS0 AABBCCDD 2 A_S7ChaseDef;
        loop;

    Melee:
        BOS0 EEEEEFFFFF 1 A_FaceTarget (36, 18);

        BOS0 G 5 {
            A_FaceTarget (0, 0);
            DoMeleeAttack ();
        }
        goto See;

    Missile:
        TNT1 A 0 {
            if (random [CustomJump] (0, 255) < 128)
                return ResolveState ("Missile.ShieldAttack");

            A_PlaySound ("Monsters/InfernalGuardian/Attack", CHAN_Voice);

            return ResolveState (null);
        }
        BOS0 EEEEEEFFFFFF 1 A_FaceTarget (30, 15);

        BOS0 G 6 {
            A_FaceTarget (0, 0);

            if (!CheckMeleeRange ())
                A_SpawnProjectile ("S7_InfernalGuardianBall", 32);
            else
                DoMeleeAttack ();
        }
        goto See;

    Missile.ShieldAttack:
        BOS0 HHHH 1 A_FaceTarget (90, 45);

        BOS0 I   3 DoShieldAttack ();
        BOS0 HHH 2 A_FaceTarget (180, 90);
        BOS0 I   3 DoShieldAttack ();
        BOS0 HHH 2 A_FaceTarget (180, 90);
        BOS0 I   3 DoShieldAttack ();
        BOS0 HHH 2 A_FaceTarget (180, 90);
        goto See;

    Pain:
        BOS0 J 2;
        BOS0 J 2 A_Pain;
        goto See;

    Death.Massacre:
    Death:
        BOS0 K 5;
        BOS0 L 5 {
            A_Scream ();
            A_NoBlocking ();
        }
    Death_AirLoop:
        BOS0 L 5;
        TNT1 A 0 A_CheckFloor ("Death_HitGround");
        loop;
    Death_HitGround:
        BOS0 MNOPQRS 5;
        BOS0 T      -1 A_BossDeath;
        stop;

    XDeath:
        BOS0 J 1 { bDontGib = true; }
        BOS0 J 2 {
            A_XScream ();
            A_NoBlocking ();
        }
        TNT1 A 0 {
            double defHeight = default.height / 2;

            for (int i = random [sfx] (8, 16); i >= 0; i--) {
                double xo = fRandom [sfx] (-2, 2), yo = fRandom [sfx] (-2, 2), zo = fRandom [sfx] (-2, 2);
                double xvel = fRandom [sfx] (0, 6), zvel = fRandom [sfx] (4, 12);

                A_SpawnItemEx ("S7_GibbingBlood", xofs: xo, yofs: yo, zofs: defHeight + zo, xvel: xvel, zvel: zvel, angle: fRandom [sfx] (0, 360), flags: SXF_UseBloodColor | SXF_NoCheckPosition);
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

    Raise:
        BOS0 T         5 { bDontGib = false; }
        BOS0 SRQPONMLK 5;
        goto See;
    }
}

//-------------------------------------------------------------------------------------------
//
// Infernal Guardian ball
//
//-------------------------------------------------------------------------------------------
class S7_InfernalGuardianBall : S7_FireballBase {
    default {
        DamageFunction (fRandom [monsterDMG] (1.0, 4.0) * 16);
        Speed 15;
        Obituary "$OBINFERNALGUARDIAN";

        SeeSound "Monsters/InfernalGuardian/AttackFireball";
        DeathSound "baron/shotx";
    }

    states {
    Spawn:
        BS0P AB 2 bright;
        loop;
    Death:
        TNT1 A      0 A_Explode (32, 24, 8);
        BS0P CDEFGH 2 bright;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Infernal Guardian shield shot
//
//-------------------------------------------------------------------------------------------
class S7_InfernalGuardianShieldShot : S7_FireballBase {
    default {
        DamageFunction (fRandom [monsterDMG] (1.0, 4.0) * 4);
        Speed 18;
        Obituary "$OBINFERNALGUARDIAN";

        SeeSound "Monsters/InfernalGuardian/AttackShield";
        DeathSound "baron/shotx";
    }

    states {
    Spawn:
        BS0P I 1 bright;
        loop;
    Death:
        BS0P JKLMNOP 2 bright;
        stop;
    }
}