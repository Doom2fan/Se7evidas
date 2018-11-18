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
// Mechdemon
//
//-------------------------------------------------------------------------------------------
class S7_Mechdemon : S7_DemonBase {
    const S7_ChargeSpeed = 25;

    default {
        Health 150;
        GibHealth -75;
        PainChance 180;
        Mass 400;

        Radius 30;
        Height 56;
        Speed 10;

        SeeSound "Monsters/Mechdemon/Sight";
        ActiveSound "Monsters/Mechdemon/Active";
        PainSound "Monsters/Mechdemon/Pain";
        DeathSound "Monsters/Mechdemon/Death";

        Obituary "$OBMECHDEMON";
        Species 'Mechdemon';
        Tag "$MECHDEMONTAG";

        +MISSILEMORE +MISSILEEVENMORE
    }

    S7_XPSystem xpSys;
    int chargeCooldown;

    override void PostBeginPlay () {
        if (!xpSys) {
            GiveInventory ('S7_XPSystem', 1);
            xpSys = S7_XPSystem (FindInventory ('S7_XPSystem', true));
        }

        let serverData = S7_ServerData.Get ();
        xpSys.level = int (random [monsterStats] (1, 4) * max (1.0, double (serverData.avgLevel) / 6.5));
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
        startHealth = int (health * (1.0 + (.065 * xpSys.GetStat (S7Stat_Vitality))));
        health = startHealth;

        // Misc
        chargeCooldown = int (ceil (fRandom [monsterSpc] (5, 15) * 35));
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
        damageMultiply = 1.0 + (0.0265 * xpSys.GetStat (S7Stat_Strength));
        // Defense
        damageFactor = clamp (1.0 - (0.0215 * xpSys.GetStat (S7Stat_Defense)), 0.1, 1.0);

        Super.Tick ();
    }

    override void OnDeath (Actor source, Actor inflictor, int dmgflags) {
        if (source) {
            let xpSys = GetXPSystem ();
            double level = xpSys ? xpSys.level : 1;
            GiveXP (source, int (150 * max (1, level / 2.5)));
            GiveCash (source, int (140 * max (1, level / 2.5)));
        }
    }

    bool CanCharge () {
        if (!target)
            return false;

        if (chargeCooldown > 0)
            return false;
        if (target.bFloat || (target.pos.Z > target.floorZ))
            return false;

        double distance = Distance2D (target);
        if (distance < 32 || distance > 512)
            return false;

        return true;
    }

    action void S7_DoChase (int tics) {
        StateLabel missileLabel = null;

        if (invoker.CanCharge ())
            missileLabel = "Missile";

        A_S7Chase ("Melee", missileLabel);
        invoker.chargeCooldown = max (invoker.chargeCooldown - tics, 0);
    }

    action state S7_DoCharge () {
        Vector3 oldPos = pos;

        if (!TryMove (pos.XY + AngleToVector (angle, S7_ChargeSpeed), true, false)) {
            if (BlockingMobj) {
                BlockingMobj.DamageMobj (self, self, int (random [monsterDMG] (5, 15) * (1 + invoker.GetDamageBonus ())), "Melee");
                invoker.chargeCooldown = int (ceil (fRandom [monsterSpc] (5, 15) * 35));

                return ResolveState ("See");
            }

            if (BlockingLine) {
                invoker.chargeCooldown = int (ceil (fRandom [monsterSpc] (5, 15) * 35));
                return ResolveState ("See");
            }
        }

        Prev = oldPos;
        
        return ResolveState (null);
    }

    double GetDamageBonus () {
        if (!xpSys)
            return 0.;

        return xpSys.GetStat (S7Stat_Strength, false) * 0.07;
    }

    states {
    Spawn:
        MDMN A 10 A_S7Look;
        loop;
    See:
        TNT1 A 0 A_PlaySound ("Monsters/Mechdemon/Step", CHAN_5);
        MDMN AA 2 S7_DoChase (2);
        MDMN BB 2 S7_DoChase (2);
        TNT1 A 0 A_PlaySound ("Monsters/Mechdemon/Step", CHAN_5);
        MDMN CC 2 S7_DoChase (2);
        MDMN DD 2 S7_DoChase (2);
        loop;

    Melee:
        TNT1 A      0 A_PlaySound ("Monsters/Mechdemon/Attack", CHAN_Voice);
        MDMN EEEFF  2 Fast A_FaceTarget ();
        MDMN G      4 Fast {
            A_FaceTarget ();
            A_CustomMeleeAttack (int (fRandom (2, 10) * 4 * GetDamageBonus ()), "", "", 'Bite');
        }
        goto See;

    Missile:
        MDMN AAAA 0 A_FaceTarget (0, 0);
    Charge.RunLoop:
        TNT1 A 0 A_PlaySound ("Monsters/Mechdemon/Step", CHAN_5);
        MDMN AA 2 S7_DoCharge ();
        MDMN BB 2 S7_DoCharge ();
        TNT1 A 0 A_PlaySound ("Monsters/Mechdemon/Step", CHAN_5);
        MDMN CC 2 S7_DoCharge ();
        MDMN DD 2 S7_DoCharge ();
        loop;

    Pain:
        MDMN H 2;
        MDMN H 2 A_Pain;
        goto See;

    Death.Massacre:
    Death:
        MDMN I  3 A_Scream;
        MDMN J  3;
        MDMN K  3 A_NoBlocking;
        MDMN LM 3;
        MDMN N -1;
        stop;

    /*Death.Fire:
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
        wait;*/

    XDeath:
        MDMN H 1 { bDontGib = true; }
        MDMN H 2 {
            A_XScream ();
            A_NoBlocking ();
        }
        TNT1 A 0 {
            double defHeight = default.height / 2;

            for (int i = random [sfx] (8, 16); i >= 0; i--) {
                double xo = fRandom [sfx] (-2, 2), yo = fRandom [sfx] (-2, 2), zo = fRandom [sfx] (-2, 2);
                double xvel = fRandom [sfx] (0, 6), zvel = fRandom [sfx] (4, 12);

                A_SpawnItemEx ('S7_GibbingBlood', xofs: xo, yofs: yo, zofs: defHeight + zo, xvel: xvel, zvel: zvel, angle: fRandom [sfx] (0, 360), flags: SXF_UseBloodColor | SXF_NoCheckPosition);
            }

            for (int i = random [sfx] (6, 8); i >= 0; i--) {
                bool MUDA; Actor cloud;
                [MUDA, cloud] = A_SpawnItemEx ('S7_GoreBloodCloud', xofs: fRandom [sfx] (-14, 14), yofs: fRandom [sfx] (-14, 14), zofs: defHeight + fRandom [sfx] (-18, 24),
                 flags: SXF_UseBloodColor | SXF_NoCheckPosition | SXF_Clientside
                );
            }

            for (int i = random [sfx] (8, 15); i >= 0; i--) {
                bool MUDA; Actor gib;
                [MUDA, gib] = A_SpawnItemEx ('S7_GenericGoreBits', zofs: defHeight + fRandom [sfx] (-7, 7),
                    xvel: fRandom [sfx] (2.5, 4.5) * randomPick [sfx] (-1, 1), yvel: fRandom [sfx] (2.5, 4.5) * randomPick [sfx] (-1, 1), zvel: fRandom [sfx] (3.5, 12),
                    flags: SXF_UseBloodColor | SXF_NoCheckPosition | SXF_Clientside
                );
            }
        }
        TNT1 A 1;
        wait;

    Raise:
        MDMN N     3 { bDontGib = false; }
        MDMN LMKJI 3;
        goto See;
    }
}