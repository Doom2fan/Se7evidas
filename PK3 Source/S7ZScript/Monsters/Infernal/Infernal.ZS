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
// Infernal
//
//-------------------------------------------------------------------------------------------
class S7_Infernal : S7_MonsterBase {
    default {
        Radius 31;
        Height 56;
        Mass 400;
        Health 600;
        GibHealth -300;
        Speed 8;
        PainChance 128;

        BloodColor "00 FF FF";

        SeeSound "Monsters/Infernal/Sight";
        ActiveSound "Monsters/Infernal/Active";
        PainSound "Monsters/Infernal/Pain";
        DeathSound "Monsters/Infernal/Death";

        Tag "$INFERNALTAG";

        +FLOAT +NOGRAVITY +DONTFALL
    }

    S7_XPSystem xpSys;

    override void PostBeginPlay () {
        if (!xpSys) {
            GiveInventory ('S7_XPSystem', 1);
            xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
        }

        let serverData = S7_ServerData.Get ();
        xpSys.level = int (random [monsterStats] (1, 5) * max (1.0, double (serverData.avgLevel) / 9.5));
        int attrPts = int (floor (xpSys.level * 2.5));

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
        startHealth = int (health * (1.0 + (.075 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;
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
        damageMultiply = 1.0 + (0.0225 * xpSys.GetStat (S7Stat_Strength));
        // Defense
        damageFactor = clamp (1.0 - (0.012 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (250 * max (1, level / 3.5)));
            GiveCash (source, int (250 * max (1, level / 3.5)));
        }
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * 0.075;
    }

    states {
    Spawn:
        INFR A 10 bright A_S7Look;
        loop;
    See:
        INFR A 3 bright A_S7ChaseDef;
        loop;

    Missile:
        INFR HHHHIIII 1 A_FaceTarget (90, 45);

        INFR J 6 {
            A_FaceTarget (0, 0);
            
            let proj = S7_InfernalBall (A_SpawnProjectile ('S7_InfernalBall', 32));

            if (proj)
                proj.bonusDMGFactor = GetDamageBonus ();
        }
        goto See;

    Pain:
        INFR K 2 bright;
        INFR K 2 bright A_Pain;
        goto See;

    Death.Massacre: // No XDeath, since it already blows up anyway.
    Death:
        INFR K      5 bright;
        INFR L      3 bright {
            A_Scream ();
            A_NoBlocking ();
        }
        INFR MNOPQ  3 bright;
        TNT1 A     -1;
        stop;

    Raise:
        INFR Q      5 bright { bDontGib = false; }
        INFR PONMLK 5 bright;
        goto See;
    }
}

//-------------------------------------------------------------------------------------------
//
// Infernal ball
//
//-------------------------------------------------------------------------------------------
class S7_InfernalBall : S7_FireballBase {
    double bonusDMGFactor;

    default {
        Radius 16;
        Height 25;
        DamageFunction (fRandom [monsterDMG] (1.0, 6.0) * 5 * (1+bonusDMGFactor));
        Speed 15;
        Obituary "$OBINFERNAL";
        Decal 'Scorch';

        SeeSound "Monsters/Infernal/Attack";
    }

    states {
    Spawn:
        INFP AB 2 bright;
        loop;
    Death:
        TNT1 A      0 A_PlaySound ("baron/shotx", CHAN_5);
        INFP CDEFGH 2 bright;
        stop;
    }
}