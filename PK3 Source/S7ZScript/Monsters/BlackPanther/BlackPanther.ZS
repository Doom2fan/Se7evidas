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
// Black Panther
//
//-------------------------------------------------------------------------------------------
class S7_BlackPanther : S7_HellNobleBase {
    default {
        Health 750;
        Speed 8;
        PainChance 50;
        BloodColor "00 67 67";
        SeeSound "BlackPanther/Sight";
        ActiveSound "BlackPanther/Active";
        PainSound "BlackPanther/Pain";
        DeathSound "BlackPanther/Death";
        HitObituary "$OBBPANTHER_MELEE";
        Species "HellNoble";
        Tag "$BLCKPNTTAG";

        // (Mini-)Boss damage reduction
        DamageFactor "ExplosionSplashDMG", 0.75;
        DamageFactor "Shrapnel", 0.85;
    }

    S7_XPSystem xpSys;

    override void PostBeginPlay () {
        if (!xpSys) {
            GiveInventory ("S7_XPSystem", 1);
            xpSys = S7_XPSystem (FindInventory ("S7_XPSystem", true));
        }

        let serverData = S7_ServerData.Get ();
        xpSys.level = int (random [monsterStats] (1, 5) * max (1.0, double (serverData.avgLevel) / 10));
        int attrPts = int (floor (xpSys.level * 2.25));
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
        damageMultiply = 1.0 + (0.0225 * xpSys.GetStat (S7Stat_Strength));
        // Defense
        damageFactor = clamp (1.0 - (0.0125 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (1000 * max (1, level / 2.5)));
            GiveCash (source, int (1000 * max (1, level / 2.5)));
        }
    }

    states {
    Spawn:
        BPNT A 10 A_S7Look;
        loop;
    See:
        BPNT AABBCCDD 2 A_S7ChaseDef;
        loop;
    Melee:
    Missile:
        BPNT EEEEEEFFFFFF 1 A_FaceTarget (30, 15);

        BPNT G 6 {
            A_FaceTarget (0, 0);
            A_CustomComboAttack ("S7_BlackPantherBall", 32, int (fRandom [monsterDMG] (1.0, 4.0) * 8), "baron/melee");
        }
        goto See;
    Pain:
        BPNT H 2;
        BPNT H 2 A_Pain;
        goto See;
    Death:
        BPNT I 5;
        BPNT J 5 {
            A_Scream ();
            A_NoBlocking ();
        }
    Death_AirLoop:
        BPNT J 5;
        TNT1 A 0 A_CheckFloor ("Death_HitGround");
        loop;
    Death_HitGround:
        BPNT KLMN 5;
        BPNT O   -1;
        stop;
    Raise:
        BPNT O      5;
        BPNT NMLKJI 5;
        goto See;
    }
}

//-------------------------------------------------------------------------------------------
//
// Black Panther ball
//
//-------------------------------------------------------------------------------------------
class S7_BlackPantherBall : S7_FireballBase {
    default {
        DamageFunction (fRandom [monsterDMG] (1.0, 4.0) * 8);
        Speed 18;
        Obituary "$OBBPANTHER";
    }

    states {
    Spawn:
        PNTB AB 2 bright;
        loop;
    Death:
        TNT1 A      0 A_Explode (16, 16, 0);
        PNTB CDEFGH 2 bright;
        stop;
    }
}