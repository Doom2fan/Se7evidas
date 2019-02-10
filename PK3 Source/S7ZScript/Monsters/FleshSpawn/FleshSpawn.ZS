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
// Tick
//
//-------------------------------------------------------------------------------------------
class S7_FleshSpawn : S7_MonsterBase {
    const FS_ChargeSpeed = 25;

    default {
        Health 150;
        GibHealth -75;
        Speed 10;
        PainChance 240;
        Radius 14;
        Height 31;
        Mass 50;

        BloodColor "Blue";

        SeeSound "Monsters/FleshSpawn/Sight";
        ActiveSound "Monsters/FleshSpawn/Active";
        PainSound "Monsters/FleshSpawn/Pain";
        DeathSound "Monsters/FleshSpawn/Death";
        AttackSound "Monsters/FleshSpawn/Attack";

        Tag "$FLESHSPAWNTAG";
        Obituary "$OBFLESHSPAWN";

        // Quick-melee weakness
        DamageFactor "QuickMelee", 2.;

        +NOGRAVITY      +FLOAT +MISSILEMORE +MISSILEEVENMORE
        +NODAMAGETHRUST
    }

    bool hasProjAttack;
    S7_XPSystem xpSys;

    override void PostBeginPlay () {
        if (!xpSys) {
            GiveInventory ('S7_XPSystem', 1);
            xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
        }

        let serverData = S7_ServerData.Get ();
        xpSys.level = int (max (1.0, double (serverData.avgLevel) / 2.5));
        int attrPts = xpSys.level * 4;

        while (attrPts > 0) {
            int rnd = random [monsterStats] (0, 5);

            switch (rnd) {
            case 0:
            case 1: xpSys.SetStat (S7Stat_Strength, 1); break;
            case 2: xpSys.SetStat (S7Stat_Defense, 1); break;
            case 3: xpSys.SetStat (S7Stat_Vitality, 1); break;
            case 4:
            case 5: xpSys.SetStat (S7Stat_Agility, 1); break;
            }

            attrPts--;
        }

        hasProjAttack = ((serverData.avgLevel >= 10) && (random [monsterSpc] (0, 255) < 64));

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
        damageMultiply = 1.0 + (0.025 * xpSys.GetStat (S7Stat_Strength));
        // Defense
        damageFactor = clamp (1.0 - (0.02 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);
        // Agility
        speed = default.Speed + clamp (xpSys.GetStat (S7Stat_Agility) * 0.075, -default.Speed * .75, default.Speed);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (175 * max (1, level / 2.5)));
            GiveCash (source, int (160 * max (1, level / 12.5)));
        }
    }

    action bool CanCharge () {
        if (!target || target.health <= 0 || target.bKilled || !CheckSight (target)) // Stop charging if the target is null, dead, or not in sight
            return false;

        if (!CheckIfTargetInLOS (90.0, JLOSF_DeadNoJump | JLOSF_AllyNoJump | JLOSF_CombatantOnly | JLOSF_NoAutoAim)) // Stop charging if the target isn't in the FOV
            return false;

        return true;
    }

    action void FS_SpawnGib (class<Actor> gibClass, double zOffs, double xyOffs, double gibPitch) {
        double gibSpeed = 8;
        double vX = 0., vY, vZ = 0.;

        double horzSpeed = abs (gibSpeed * cos (gibPitch));
        vZ = (gibSpeed * sin (gibPitch)) * -1;

        double ang = fRandom [sfx] (-360, 360);
        vX = horzSpeed * cos (ang);
        vY = horzSpeed * sin (ang);

        A_SpawnItemEx (gibClass, xOfs: xyOffs * cos (angle), yOfs: xyOffs * sin (angle), zOfs: zOffs, xVel: vX, yVel: vY, zVel: vZ, flags: SXF_NoCheckPosition | SXF_AbsoluteAngle);
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * 0.045;
    }

    states {
    Spawn:
        FLSP A 8 A_S7Look;
        loop;
    See:
        FLSP AABB 2 {
            StateLabel missileState = null;

            if (hasProjAttack)
                missileState = "Missile";

            A_S7Chase ("Melee", missileState);

            if (target && !CheckMeleeRange () && Distance3D (target) >= (radius + target.radius + 256) && random [monsterSpc] (0, 255) < 32)
                return ResolveState ("Charge");

            return ResolveState (null);
        }
        loop;

    Melee:
        FLSP FFAA 1 A_FaceTarget (45, 22.5);
        FLSP B    2 A_CustomMeleeAttack (damage: int (max (ceil ((2.5 + fRandom [monsterDMG] (-.5, .5)) * (1. + GetDamageBonus ())), 2)), damagetype: 'Bite');
        FLSP AFE  2;
        goto See;

    Missile:
        FLSP CCCC 2 A_FaceTarget (30, 15);
        FLSP GG   2 A_FaceTarget (30, 15);
        FLSP H    4 bright {
            let proj = S7_FleshSpawnBall (A_SpawnProjectile ('S7_FleshSpawnBall', 12));

            if (proj)
                proj.bonusDMGFactor = GetDamageBonus ();
        }
        FLSP EA   2;
        goto See;

    Charge:
        FLSP CCDD 2 {
            if (!CanCharge ())
                return ResolveState ("See");

            A_FaceTarget (45, 22.5);

            return ResolveState (null);
        }
        TNT1 A 0 { Thrust (Speed / 2., angle); }
        goto Charging;

    Charging:
        FLSP FABAFE 2 {
            if (!CanCharge () || CheckMeleeRange ())
                return ResolveState ("Brake");

            if (vel.Length () <= 0.1) {
                A_Stop ();
                return ResolveState ("See");
            }

            VelFromAngle (FS_ChargeSpeed);
            vel.Z = (target.pos.Z + (target.Height / 2) - pos.Z) / DistanceBySpeed (target, FS_ChargeSpeed);

            return ResolveState (null);
        }
        loop;
    Brake:
        FLSP A 1 {
            if (vel.Length () <= 0.1) {
                A_Stop ();
                return ResolveState ("See");
            }

            vel *= .5;

            return ResolveState (null);
        }
        loop;

    Pain:
        FLSP I 3;
        FLSP I 3 A_Pain;
        goto See;

    Death.Massacre:
    Death:
        FLSP J 3 { bNoGravity = false; }
        FLSP K 3 {
            A_Scream ();
            A_NoBlocking ();
            bThruActors = true;
        }
    Death_AirLoop:
        FLSP L 3;
        TNT1 A 0 A_CheckFloor ("Death_HitGround");
        loop;
    Death_HitGround:
        FLSP MN 3;
        FLSP O -1;
        stop;

    XDeath:
        FLSP P 3 {
            bDontGib = false;
            bNoGravity = true;
        }
        FLSP Q 3 {
            A_XScream ();

            A_SpawnItemEx ('S7_FleshSpawnGib6', zVel: fRandom [sfx] (-3., 0.), flags: SXF_NoCheckPosition);
            FS_SpawnGib ('S7_FleshSpawnGib1',  14,  0, fRandom [sfx] (-40, -10));
            FS_SpawnGib ('S7_FleshSpawnGib2',   6,  2, fRandom [sfx] (-25,   0));
            FS_SpawnGib ('S7_FleshSpawnGib2B', 10, -2, fRandom [sfx] (-25,   0));
            FS_SpawnGib ('S7_FleshSpawnGib3',   8,  0, fRandom [sfx] (-35,   0));
            FS_SpawnGib ('S7_FleshSpawnGib4',  12,  5, fRandom [sfx] (-40,   5));
            FS_SpawnGib ('S7_FleshSpawnGib4B',  5, -5, fRandom [sfx] (-30,   0));
            FS_SpawnGib ('S7_FleshSpawnGib5',   6,  3, fRandom [sfx] (-60, -10));
            FS_SpawnGib ('S7_FleshSpawnGib5',   8,  0, fRandom [sfx] (-55,  10));
        }
        FLSP RSTU 3;
        stop;

    Raise:
        TNT1 A 0 { bThruActors = false; }
        FLSP ONMLKJ 5;
        goto See;
    }
}

//-------------------------------------------------------------------------------------------
//
// Flesh Spawn ball
//
//-------------------------------------------------------------------------------------------
class S7_FleshSpawnBall : S7_FireballBase {
    default {
        Radius 3;
        Height 5;

        S7_Projectile.MovementMode FastProjectile;
        S7_Projectile.FastProjCollision ColMode_EdgeCenters;
        Speed 15;

        DamageFunction int ((14. + fRandom [monsterDMG] (-6., 2.)) * (1. + bonusDMGFactor));
        Obituary "$OBFLESHSPAWNBALL";
        RenderStyle "Add";
        Decal 'Scorch';

        SeeSound "Monsters/FleshSpawn/Fireball";
        DeathSound "";
    }

    states {
    Spawn:
        FLBL ABCBABCBABCBABCBIJKLM 4 bright;
        stop;
    Death:
        TNT1 A     0 A_PlaySound ("Monsters/FleshSpawn/FireballExplode", CHAN_5);
        FLBL DEFGH 4 bright;
        stop;
    }
}