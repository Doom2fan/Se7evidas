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
// Cronus Corps Combat Armor
//
//-------------------------------------------------------------------------------------------
class S7_CCCombatArmorData : S7_ArmorData {
    const NormalStartHeight = 26;
    const NormalEndHeight = 47;
    const CrouchStartHeight = 5;
    const CrouchEndHeight = 22;

    const weaveDMGLimit = 100.0;
    const platesDMGLimit = 100.0;

    double weaveDMG;
    double platesDMG;

    void UpdateAmount (S7_BasicArmor armor) {
        armor.amount = int (clamp (100 * ((1 - weaveDMG / weaveDMGLimit) + (1 - platesDMG / platesDMGLimit)), 0, 200));
    }

    override void FixArmor (S7_BasicArmor armor, int amount) {
        weaveDMG = max (weaveDMG - (amount / 2.), 0.);
        platesDMG = max (platesDMG - (amount / 2.), 0.);

        UpdateAmount (armor);
    }

    override void GotBonus (S7_BasicArmor armor, int amount) {
        FixArmor (armor, amount);
    }

    protected double, double, int CalcBulletDamage (int dmg, double baseWeaveDMG, double maxBulletShred,
        double pltShift = 0, double pltMin = 0,
        double usrPltM = 0, double usrWeaveM = 0, double usrWeaveMShift = 0, double usrMin = 0
    ) {
        double pltDMGFactor = platesDMG / platesDMGLimit;
        double weaveDMGFactor = weaveDMG / weaveDMGLimit;
        double bulletShredding = clamp (1-(pltDMGFactor), 0.0, maxBulletShred);
        double pltDMG = clamp ((pltDMGFactor - pltShift) / (1-pltShift), pltMin, 1.0);
        double wevDMG = baseWeaveDMG * (1-bulletShredding);

        double usrModPlt = usrPltM + pltDMGFactor - usrPltM*pltDMGFactor;
        double usrModWeaveP1 = 1 - bulletShredding + usrWeaveM * bulletShredding;
        double usrModWeave = usrModWeaveP1 * clamp ((weaveDMGFactor - usrWeaveMShift) / (1-usrWeaveMShift), 0.0, 1.0);
        double usrDMG = clamp (usrModPlt * usrModWeave, usrMin, 1.0);

        return dmg * wevDMG, dmg * pltDMG, int (dmg * usrDMG);
    }

    override void Init (S7_BasicArmor armor) {
        weaveDMG = 0;
        platesDMG = 0;
    }

    override void Tick (S7_BasicArmor armor) {
        UpdateAmount (armor);
    }

    override double GetSpeedFactor () {
        return 0.95;
    }

    override int HandleDamage (S7_BasicArmor armor, Actor inflictor, Actor source, int damage, Name damageType) {
        if (!armor)
            return damage;

        let pPawn = PlayerPawn (armor.Owner);
        if (!pPawn)
            return damage;

        int ret;
        double wevDMG = 0;
        double pltDMG = 0;

        double startHeight = S7_Math.Lerp (NormalStartHeight, CrouchStartHeight, (1 - pPawn.player.crouchfactor) * 2);
        double   endHeight = S7_Math.Lerp (  NormalEndHeight,   CrouchEndHeight, (1 - pPawn.player.crouchfactor) * 2);

        if (inflictor &&
            (inflictor.pos.z + inflictor.height/2) >= (pPawn.pos.z + startHeight) &&
            (inflictor.pos.z + inflictor.height/2) <= (pPawn.pos.z + endHeight)) {
            double weaveInt = weaveDMG / weaveDMGLimit;
            double pltInt = platesDMG / platesDMGLimit;

            switch (damageType) {
            case 'PistolTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.3 , 0.85, pltShift: 0.3 , pltMin: 0.2 , usrPltM: 0.55, usrWeaveM: 0.35, usrWeaveMShift: 0.25, usrMin: 0.25);
                break;
            case 'RevolverTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.33, 0.85, pltShift: 0.35, pltMin: 0.18, usrPltM: 0.6 , usrWeaveM: 0.35, usrWeaveMShift: 0.25, usrMin: 0.25);
                break;
            case 'ShotgunTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.15, 0.95, pltShift: 0.5 , pltMin: 0.15, usrPltM: 0.5 , usrWeaveM: 0.2 , usrWeaveMShift: 0.70, usrMin: 0.25);
                break;
            case 'RifleTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.5 , 0.8 , pltShift: 0.15, pltMin: 0.5 , usrPltM: 0.55, usrWeaveM: 0.4 , usrWeaveMShift: 0.2 , usrMin: 0.3);
                break;
            case 'SniperRifleTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.6 , 0.5 , pltShift: 0.15, pltMin: 0.6 , usrPltM: 0.6 , usrWeaveM: 0.65, usrWeaveMShift: 0.1 , usrMin: 0.6);
                break;
            case 'Fire':
                pltDMG = max (damage - 15, 0) * 0.25;
                wevDMG = damage * (fRandom [S7_Armor] (0.75, 1.2) * pltInt);
                ret = int (damage * clamp (pltInt, .25, 1.));
                break;
            default:
                pltDMG = damage * (0.15 * (1-pltInt));
                wevDMG = damage * (0.15 * pltInt);
                ret = int (damage * clamp ((weaveInt + pltDMG) / 2, 0.7, 1.0));
                break;
            }
        } else {
            if (damageType == 'Crush') {
                wevDMG = 0;
                pltDMG = damage * fRandom [S7_Armor] (0.2, 0.3);
                ret = damage;
            } else
                ret = damage;
        }

        weaveDMG = clamp (weaveDMG + max (wevDMG, 0), 0, weaveDMGLimit);
        platesDMG = clamp (platesDMG + max (pltDMG, 0), 0, platesDMGLimit);
        UpdateAmount (armor);

        return ret;
    }
}

class S7_CCCombatArmor : S7_BasicArmorPickup {
    default {
        Radius 20;
        Height 16;
        Armor.SaveAmount 200;
        Inventory.PickupSound "Inventory/ArmorPickup";
        Inventory.PickupMessage "$CBTARMR_CC";
        Inventory.Icon "ARCAA0";
        Tag "$CBTARMR_CC";

        S7_BasicArmorPickup.DataClass 'S7_CCCombatArmorData';
    }

    states {
    Spawn:
        ARCA A 6;
        ARCA A 6 bright;
        loop;
    }
}

//-------------------------------------------------------------------------------------------
//
// Sigma BTK Combat Armor
//
//-------------------------------------------------------------------------------------------
class S7_SBTKCombatArmorData : S7_CCCombatArmorData {
    override double GetSpeedFactor () {
        return 0.935;
    }

    override int HandleDamage (S7_BasicArmor armor, Actor inflictor, Actor source, int damage, Name damageType) {
        if (!armor)
            return damage;

        let pPawn = PlayerPawn (armor.Owner);
        if (!pPawn)
            return damage;

        int ret;
        double wevDMG = 0;
        double pltDMG = 0;

        double startHeight = S7_Math.Lerp (NormalStartHeight, CrouchStartHeight, (1 - pPawn.player.crouchfactor) * 2);
        double   endHeight = S7_Math.Lerp (  NormalEndHeight,   CrouchEndHeight, (1 - pPawn.player.crouchfactor) * 2);

        if (inflictor &&
            (inflictor.pos.z + inflictor.height/2) >= (pPawn.pos.z + startHeight) &&
            (inflictor.pos.z + inflictor.height/2) <= (pPawn.pos.z + endHeight)) {
            double weaveInt = weaveDMG / weaveDMGLimit;
            double pltInt = platesDMG / platesDMGLimit;

            switch (damageType) {
            case 'PistolTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.3 , 0.85, pltShift: 0.255, pltMin: 0.32 , usrPltM: 0.55, usrWeaveM: 0.26, usrWeaveMShift: 0.25, usrMin: 0.18);
                break;
            case 'RevolverTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.33, 0.85, pltShift: 0.298, pltMin: 0.288, usrPltM: 0.6 , usrWeaveM: 0.26, usrWeaveMShift: 0.25, usrMin: 0.18);
                break;
            case 'ShotgunTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.15, 0.95, pltShift: 0.425, pltMin: 0.24 , usrPltM: 0.5 , usrWeaveM: 0.15, usrWeaveMShift: 0.70, usrMin: 0.18);
                break;
            case 'RifleTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.5 , 0.8 , pltShift: 0.128, pltMin: 0.8  , usrPltM: 0.55, usrWeaveM: 0.3 , usrWeaveMShift: 0.2 , usrMin: 0.225);
                break;
            case 'SniperRifleTracer':
                [wevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.6 , 0.5 , pltShift: 0.128, pltMin: 0.96 , usrPltM: 0.6 , usrWeaveM: 0.49, usrWeaveMShift: 0.1 , usrMin: 0.45);
                break;
            case 'Fire':
                pltDMG = max (damage - 12, 0) * 0.26;
                wevDMG = damage * (fRandom [S7_Armor] (0.25, 0.65) * pltInt);
                ret = int (damage * clamp (pltInt, .25, 1.));
                break;
            default:
                pltDMG = damage * (0.15 * (1-pltInt));
                wevDMG = damage * (0.15 * pltInt);
                ret = int (damage * clamp ((weaveInt + pltDMG) / 2, 0.7, 1.0));
                break;
            }
        } else {
            if (damageType == 'Crush') {
                wevDMG = damage * fRandom [S7_Armor] (0.0, 0.075);
                pltDMG = damage * fRandom [S7_Armor] (0.2, 0.3);
                ret = damage;
            } else
                ret = damage;
        }

        weaveDMG = clamp (weaveDMG + max (wevDMG, 0), 0, weaveDMGLimit);
        platesDMG = clamp (platesDMG + max (pltDMG, 0), 0, platesDMGLimit);
        UpdateAmount (armor);

        return ret;
    }
}

class S7_SBTKCombatArmor : S7_BasicArmorPickup {
    default {
        Radius 20;
        Height 16;
        Armor.SaveAmount 200;
        Inventory.PickupSound "Inventory/ArmorPickup";
        Inventory.PickupMessage "$CBTARMR_SBTK";
        Inventory.Icon "ARCAB0";
        Tag "$CBTARMR_SBTK";

        S7_BasicArmorPickup.DataClass 'S7_SBTKCombatArmorData';
    }

    states {
    Spawn:
        ARCA B 6;
        ARCA B 6 bright;
        loop;
    }
}