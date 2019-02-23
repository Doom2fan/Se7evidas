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
        xpSys.level = int (max (1.0, (double (serverData.avgLevel) / 4.75) + random [monsterStats] (-2, 2)));
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
        startHealth = int (health * (1.0 + (.075 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;

        // Attack/aggressiveness stuff
        painAttackThreshold = random [monsterSpc] (80, 160);
        chainAttackThreshold = random [monsterSpc] (96, 144);

        bMissileMore = (random [monsterSpc] (0, 255) < 72);
        bMissileEvenMore = (random [monsterSpc] (0, 255) < 24);
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
        // Agility
        speed = default.Speed + clamp (xpSys.GetStat (S7Stat_Agility) * 0.1, -default.Speed * .75, default.Speed);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (250 * max (1, level / 3.5)));
            GiveCash (source, int (250 * max (1, level / 10.)));
        }
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * 0.075;
    }

    action bool FlamethrowerDistCheck (double targDist) {
        return (
            targDist >= (MeleeRange + target.radius) &&
            targDist < (radius + 75)
        );
    }

    int painAttackThreshold;
    int chainAttackThreshold;

    bool doFlamethrower;
    int flamethrowerCount;
    bool flameChance;

    action state DoChainAttack () {
        if (random [monsterAtk] (0, 255) < invoker.chainAttackThreshold) {
            if (FlamethrowerDistCheck (Distance3D (target)) && (random [monsterAtk] (0, 255) < 128))
                return ResolveState ("Melee");
            else
                return ResolveState ("Missile");
        }

        return ResolveState (null);
    }

    states {
    Spawn:
        INFR A 10 bright A_S7Look;
        loop;
    See:
        INFR A 3 bright A_S7ChaseDef;
        loop;

    Melee: // EFG
        INFR EEEFFF 1 bright A_FaceTarget (90, 45);
        goto FlameInit;
    FlameInit:
        TNT1 A 0 {
            if (!target) // WTF??
                return;

            invoker.doFlamethrower = (
                (random [monsterAtk] (0, 2) == 0) ||
                FlamethrowerDistCheck (Distance3D (target))
            );

            invoker.flamethrowerCount = random [monsterAtk] (5, 15);

            if (invoker.doFlamethrower)
                A_PlaySound ("Monsters/Infernal/FlameAttack", CHAN_Body);
        }
        goto FlameStart;
    FlameStart:
        INFR G 4 bright {
            if (invoker.doFlamethrower) {
                A_FaceTarget (120, 60);
                A_SpawnProjectile ("S7_InfernalFlame");
            }
        }
        INFR F 2 bright A_JumpIf (invoker.doFlamethrower && invoker.flamethrowerCount--, "FlameStart");
        INFR E 2 bright;
        TNT1 A 0 DoChainAttack ();
        goto See;

    Missile:
        TNT1 A 0 { invoker.flameChance = (random [monsterAtk] (0, 255) < 80); }
        INFR HHHH 1 {
            if (invoker.flameChance && FlamethrowerDistCheck (Distance3D (target)))
                return ResolveState ("Melee");

            A_FaceTarget (90, 45);

            return ResolveState (null);
        }
        INFR IIII 1 A_FaceTarget (90, 45);

        INFR J 6 {
            if (FlamethrowerDistCheck (Distance3D (target)) && (random [monsterAtk] (0, 255) < 128))
                return ResolveState ("FlameInit");

            A_FaceTarget (0, 0);
            
            let proj = S7_InfernalBall (A_SpawnProjectile ('S7_InfernalBall', 32));

            if (proj)
                proj.bonusDMGFactor = GetDamageBonus ();

            return ResolveState (null);
        }
        TNT1 A 0 DoChainAttack ();
        goto See;

    Pain:
        INFR K 2 bright;
        INFR K 2 bright A_Pain;
        TNT1 A 0 {
            if (random [monsterSpc] (0, 255) < invoker.painAttackThreshold) {
                if (CheckMeleeRange ())
                    return ResolveState ("Melee");
                else if (CheckMissileRange ())
                    return ResolveState ("Missile");
            }

            return ResolveState ("See");
        }

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
    default {
        Radius 16;
        Height 25;
        DamageFunction ((18. + fRandom [monsterDMG] (-2., 2.)) * (1. + bonusDMGFactor));
        Speed 15;
        Obituary "$OBINFERNAL";
        Decal 'Scorch';

        SeeSound "Monsters/Infernal/Attack";
        DeathSound "";
    }

    states {
    Spawn:
        INFP AB 2 bright;
        loop;
    Death:
        TNT1 A      0 A_PlaySound ("Misc/Common/FireballHit", CHAN_5);
        INFP CDEFGH 2 bright;
        stop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Infernal flame
//
//-------------------------------------------------------------------------------------------
class S7_InfernalFlame : S7_FireballBase {
    default {
        Radius 16;
        Height 25;

        DamageType "Fire";
        DamageFunction (CalcFlameDamage ());

        Speed 15;
        Obituary "$OBINFERNAL_FLAME";

        SeeSound "";//"Monsters/Infernal/Attack";
        DeathSound "";

        +RIPPER +BLOODLESSIMPACT
    }

    Array<Actor> hitActors;

    override int SpecialMissileHit (Actor victim) {
        if (victim == target)
            return 1;

        if (hitActors.Find (victim) == hitActors.Size ()) {
            hitActors.Push (victim);
            return -1;
        } else
            return 1;

        return -1;
    }

    int flameStage;
    int CalcFlameDamage () {
        if (flameStage >= 3)
            return 0;

        return (int (ceil (
            (5. + fRandom [monsterDMG] (-.5, .5))
            *
            (1. + bonusDMGFactor) / min (flameStage + 1., 1.)
        )));
    }

    states {
    Spawn:
        INFP CDE 2 bright;
        INFP FGH 2 bright { invoker.flameStage++; }
        stop;
    }
}