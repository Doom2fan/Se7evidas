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
// Cronus Corps Security Vest
//
//-------------------------------------------------------------------------------------------
class S7_CCSecVestData : S7_ArmorData {
    const NormalStartHeight = 26;
    const NormalEndHeight = 47;

    const CrouchStartHeight = 5;
    const CrouchEndHeight = 22;

    const kevlarDMGLimit = 100.0;

    double kevlarDMG;

    void UpdateAmount (S7_BasicArmor armor) {
        armor.amount = int (clamp (100 * (1 - kevlarDMG / kevlarDMGLimit), 0, 100));
    }

    override void GotBonus (S7_BasicArmor armor, int amount) {
        kevlarDMG = max (kevlarDMG - amount, 0.);

        UpdateAmount (armor);
    }

    override void Tick (S7_BasicArmor armor) {
        UpdateAmount (armor);
    }

    override int HandleDamage (S7_BasicArmor armor, Actor inflictor, Actor source, int damage, Name damageType) {
        if (!armor)
            return damage;

        let pPawn = PlayerPawn (armor.Owner);
        if (!pPawn)
            return damage;

        double ret;
        double kevDMG = 0;

        double startHeight = S7_Math.Lerp (NormalStartHeight, CrouchStartHeight, (1 - pPawn.player.crouchfactor) * 2);
        double   endHeight = S7_Math.Lerp (  NormalEndHeight,   CrouchEndHeight, (1 - pPawn.player.crouchfactor) * 2);

        if (inflictor &&
            (inflictor.pos.z + inflictor.height/2) >= (pPawn.pos.z + startHeight) &&
            (inflictor.pos.z + inflictor.height/2) <= (pPawn.pos.z + endHeight)) {
            double kevInt = kevlarDMG / kevlarDMGLimit;

            switch (damageType) {
            case 'PistolTracer':   kevDMG = damage * 0.5 ; ret = damage * clamp ((kevInt - 0.5 ) / 0.5 , 0.25,  1.0); break;
            case 'RevolverTracer': kevDMG = damage * 0.55; ret = damage * clamp ((kevInt - 0.4 ) / 0.6 , 0.35,  1.0); break;
            case 'ShotgunTracer':  kevDMG = damage * 0.6 ; ret = damage * clamp ((kevInt - 0.65) / 0.35, 0.125, 1.0); break;
            case 'RifleTracer':    kevDMG = damage       ; ret = damage * clamp ((kevInt       ) / 0.9 , 0.65,  1.0); break;
            case 'SniperRifleTracer':
                kevDMG = damage * fRandom [S7_Armor] (0.95, 1.15);
                ret = damage;
                break;
            case 'Fire':
                kevDMG = damage * fRandom [S7_Armor] (0.75, 1.2);
                ret = damage;
                break;
            default:
                kevDMG = damage * 0.25;
                ret = damage * clamp (kevInt, 0.85, 1.0);
                break;
            }
        } else
            ret = damage;

        kevlarDMG = clamp (kevlarDMG + max (kevDMG, 0), 0, kevlarDMGLimit);
        UpdateAmount (armor);

        return int (ret);
    }
}

class S7_CCSecVest : S7_BasicArmorPickup {
    default {
        Radius 20;
        Height 16;
        Armor.SaveAmount 100;
        Inventory.PickupMessage "$SECVEST_CC";
        Inventory.Icon "ARSVA0";
        Tag "$SECVEST_CC";

        S7_BasicArmorPickup.DataClass "S7_CCSecVestData";
    }

    states {
    Spawn:
        ARSV A 6;
        ARSV A 6 bright;
        loop;
    }
}

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

    const kevlarDMGLimit = 100.0;
    const platesDMGLimit = 100.0;

    double kevlarDMG;
    double platesDMG;

    void UpdateAmount (S7_BasicArmor armor) {
        armor.amount = int (clamp (100 * ((1 - kevlarDMG / kevlarDMGLimit) + (1 - platesDMG / platesDMGLimit)), 0, 200));
    }

    override void GotBonus (S7_BasicArmor armor, int amount) {
        kevlarDMG = max (kevlarDMG - (amount / 2.), 0.);
        platesDMG = max (platesDMG - (amount / 2.), 0.);

        UpdateAmount (armor);
    }

    protected double, double, int CalcBulletDamage (int dmg, double baseKevDMG, double maxBulletShred,
        double pltShift = 0, double pltMin = 0,
        double usrPltM = 0, double usrKevM = 0, double usrKevMShift = 0, double usrMin = 0
    ) {
        double pltDMGFactor = platesDMG / platesDMGLimit;
        double kevDMGFactor = kevlarDMG / kevlarDMGLimit;
        double bulletShredding = clamp (1-(pltDMGFactor), 0.0, maxBulletShred);
        double pltDMG = clamp ((pltDMGFactor - pltShift) / (1-pltShift), pltMin, 1.0);
        double kevDMG = baseKevDMG * (1-bulletShredding);

        double usrModPlt = usrPltM + pltDMGFactor - usrPltM*pltDMGFactor;
        double usrModKevP1 = 1 - bulletShredding + usrKevM * bulletShredding;
        double usrModKev = usrModKevP1 * clamp ((kevDMGFactor - usrKevMShift) / (1-usrKevMShift), 0.0, 1.0);
        double usrDMG = clamp (usrModPlt * usrModKev, usrMin, 1.0);

        return dmg * kevDMG, dmg * pltDMG, int (dmg * usrDMG);
    }

    override void Init (S7_BasicArmor armor) {
        kevlarDMG = 0;
        platesDMG = 0;
    }

    override void Tick (S7_BasicArmor armor) {
        UpdateAmount (armor);
    }

    override int HandleDamage (S7_BasicArmor armor, Actor inflictor, Actor source, int damage, Name damageType) {
        if (!armor)
            return damage;

        let pPawn = PlayerPawn (armor.Owner);
        if (!pPawn)
            return damage;

        int ret;
        double kevDMG = 0;
        double pltDMG = 0;

        double startHeight = S7_Math.Lerp (NormalStartHeight, CrouchStartHeight, (1 - pPawn.player.crouchfactor) * 2);
        double   endHeight = S7_Math.Lerp (  NormalEndHeight,   CrouchEndHeight, (1 - pPawn.player.crouchfactor) * 2);

        if (inflictor &&
            (inflictor.pos.z + inflictor.height/2) >= (pPawn.pos.z + startHeight) &&
            (inflictor.pos.z + inflictor.height/2) <= (pPawn.pos.z + endHeight)) {
            double kevInt = kevlarDMG / kevlarDMGLimit;
            double pltInt = platesDMG / platesDMGLimit;

            switch (damageType) {
            case 'PistolTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.3 , 0.85, pltShift: 0.3 , pltMin: 0.2 , usrPltM: 0.55, usrKevM: 0.35, usrKevMShift: 0.25, usrMin: 0.25);
                break;
            case 'RevolverTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.33, 0.85, pltShift: 0.35, pltMin: 0.18, usrPltM: 0.6 , usrKevM: 0.35, usrKevMShift: 0.25, usrMin: 0.25);
                break;
            case 'ShotgunTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.15, 0.95, pltShift: 0.5 , pltMin: 0.15, usrPltM: 0.5 , usrKevM: 0.2 , usrKevMShift: 0.70, usrMin: 0.25);
                break;
            case 'RifleTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.5 , 0.8 , pltShift: 0.15, pltMin: 0.5 , usrPltM: 0.55, usrKevM: 0.4 , usrKevMShift: 0.2 , usrMin: 0.3);
                break;
            case 'SniperRifleTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.6 , 0.5 , pltShift: 0.15, pltMin: 0.6 , usrPltM: 0.6 , usrKevM: 0.65, usrKevMShift: 0.1 , usrMin: 0.6);
                break;
            case 'Fire':
                pltDMG = max (damage - 15, 0) * 0.25;
                kevDMG = damage * (fRandom [S7_Armor] (0.75, 1.2) * pltInt);
                ret = int (damage * pltInt);
                break;
            default:
                pltDMG = damage * (0.15 * (1-pltInt));
                kevDMG = damage * (0.15 * pltInt);
                ret = int (damage * clamp ((kevInt + pltDMG) / 2, 0.7, 1.0));
                break;
            }
        } else {
            if (damageType == 'Crush') {
                kevDMG = 0;
                pltDMG = damage * fRandom [S7_Armor] (0.2, 0.3);
                ret = damage;
            } else
                ret = damage;
        }

        kevlarDMG = clamp (kevlarDMG + max (kevDMG, 0), 0, kevlarDMGLimit);
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
        Inventory.PickupMessage "$CBTARMR_CC";
        Inventory.Icon "ARCAA0";
        Tag "$CBTARMR_CC";

        S7_BasicArmorPickup.DataClass "S7_CCCombatArmorData";
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
// Armor bonus
//
//-------------------------------------------------------------------------------------------
/* Credits:
**  Sprites: id Software, Chronos "phantombeta" Ouroboros
**  Brightmaps: Chronos "phantombeta" Ouroboros
*/
class S7_ArmorBonus : Inventory {
    default {
        Inventory.Amount 4;
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$S7_ARMORBONUS";

        Tag "$S7_ARMORBONUS";
    }

    override void PostBeginPlay () {
        amount = random [invItems] (3, 5);
    }

    override bool TryPickup (in out Actor toucher) {
        let basicArmor = S7_BasicArmor (toucher.FindInventory ("S7_BasicArmor"));

        if (basicArmor && basicArmor.armorData && basicArmor.ArmorType != 'None') {
            basicArmor.armorData.armorBonuses += amount;
            basicArmor.armorData.GotBonus (basicArmor, amount);

            GoAwayAndDie();

            return true;
        }

        return false;
    }

    states {
    Spawn:
        BON2 A  9;
        BON2 BC 3 bright;
        BON2 D  9 bright;
        BON2 CB 3 bright;
        loop;
    }
}

/* Credits:
**  Sprites: id Software, Chronos "phantombeta" Ouroboros
**  Brightmaps: Chronos "phantombeta" Ouroboros
*/
class S7_LargeArmorBonus : S7_ArmorBonus {
    default {
        Inventory.Amount 7;
        Inventory.MaxAmount 0;
        Inventory.PickupMessage "$S7_LARGEARMORBONUS";

        Tag "$S7_LARGEARMORBONUS";
    }

    override void PostBeginPlay () {
        amount = random [invItems] (7, 8);
    }

    states {
    Spawn:
        BON3 A  9;
        BON3 BC 3 bright;
        BON3 D  9 bright;
        BON3 CB 3 bright;
        loop;
    }
}