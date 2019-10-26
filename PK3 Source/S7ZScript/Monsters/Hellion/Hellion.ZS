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
// Hellion
//
//-------------------------------------------------------------------------------------------
class S7_Hellion : S7_DemonBase {
    default {
        Health 75;
        GibHealth -30;
        Radius 20;
        Height 56;
        Speed 8;
        PainChance 200;
        SeeSound "Monsters/Hellion/Sight";
        ActiveSound "Monsters/Hellion/Active";
        PainSound "Monsters/Hellion/Pain";
        DeathSound "Monsters/Hellion/Death";
        Obituary "$OBHELLION";
        Species 'Hellion';
        Tag "$HELLIONTAG";

        // Fire damage reduction
        DamageFactor "Fire", 0.75;
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
        startHealth = int (health * (1.0 + (.05 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;
    }

    override void UpdateStats () {
        // Strength
        damageMultiply = 1.0 + (0.02 * xpSys.GetStat (S7Stat_Strength));
        // Defense
        damageFactor = clamp (1.0 - (0.01 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);
        // Agility
        speed = default.Speed + clamp (xpSys.GetStat (S7Stat_Agility) * 0.075, -default.Speed * .75, default.Speed);
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (120 * max (1, level / 3.)));
            GiveCash (source, int (clamp (100 * (level / 15.), 100, 100 * 3.25)));
        }
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * 0.065;
    }

    states {
    Spawn:
        HELN A 10 A_S7Look;
        loop;
    See:
        HELN AABBCCDDEEFF 2 A_S7ChaseDef;
        loop;

    Missile:
        TNT1 A 0 A_PlaySound ("Monsters/Hellion/Attack", CHAN_Voice);

        HELN GGGGGGHHHHIIIJJ 1 bright A_FaceTarget (26, 13);

        HELN K 4 bright {
            A_FaceTarget (0, 0);

            let proj = S7_HellionBall (A_SpawnProjectile ('S7_HellionBall', 35.0, 0, 0.0, CMF_AimDirection | CMF_AbsolutePitch, pitch));

            if (proj)
                proj.bonusDMGFactor = GetDamageBonus ();
        }
        HELN L 6;
        goto See;

    Pain:
        HELN M 2;
        HELN M 2 A_Pain;
        goto See;

    Death.Massacre:
    Death:
        HELN N  5;
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
        HELN N 1 { bDontGib = true; }
        HELN N 2 {
            A_XScream ();
            A_NoBlocking ();
        }
        TNT1 A 0 S7_SpawnGibs ();
        CRSH A 1 { translation = bloodTranslation; }
        wait;
    /*XDeath:
        HELN U    6 { monsDeathType = 1; }
        HELN V    6 A_XScream;
        HELN W    6;
        HELN X    6 A_NoBlocking;
        HELN YZ[\ 6;
        HELN ]   -1;
        stop;*/

    Raise:
        HELN T      6 { bDontGib = false; }
        HELN SRQPON 6;
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
        DamageFunction ((15. + fRandom [monsterDMG] (-2., 2.)) * (1. + bonusDMGFactor));
        DamageType 'Fire';
        Speed 12;
        FastSpeed 24;
        Obituary "$OBHELLIONFB";
        SeeSound "Monsters/Hellion/Fireball";
    }

    states {
    Spawn:
        CP00 AABBCC 1 bright {
            for (int i = 0; i < 2; i++) {
                A_SpawnItemEx ('S7_FireballSmoke',
                    -2.5 * i,
                    fRandom [S7_SmokeRNG] (-3.0, 3.0),
                    -1 + fRandom [S7_SmokeRNG] (-3.0, 3.0),
                    xVel: fRandom [S7_SmokeRNG] (-1.8, -2.2),
                    flags: SXF_NoCheckPosition | SXF_Clientside
                );
            }
        }
        loop;
    Death:
        TNT1 A     0 A_PlaySound ("Misc/Common/FireballHit", CHAN_5);
        CP00 DEFGH 2 bright;
        stop;
    }
}