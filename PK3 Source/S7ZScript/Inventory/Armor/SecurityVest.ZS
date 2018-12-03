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

    override void FixArmor (S7_BasicArmor armor, int amount) {
        kevlarDMG = max (kevlarDMG - amount, 0.);

        UpdateAmount (armor);
    }

    override void GotBonus (S7_BasicArmor armor, int amount) {
        FixArmor (armor, amount);
    }

    override void Tick (S7_BasicArmor armor) {
        UpdateAmount (armor);
    }

    override double GetSpeedFactor () {
        return 0.975;
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
        Inventory.PickupSound "Inventory/ArmorPickup";
        Inventory.PickupMessage "$SECVEST_CC";
        Inventory.Icon "ARSVA0";
        Tag "$SECVEST_CC";

        S7_BasicArmorPickup.DataClass 'S7_CCSecVestData';
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
// Cronus Corps Security Vest
//
//-------------------------------------------------------------------------------------------
class S7_SBTKSecVestData : S7_ArmorData {
    const NormalStartHeight = 26;
    const NormalEndHeight = 47;

    const CrouchStartHeight = 5;
    const CrouchEndHeight = 22;

    const scalesDMGLimit = 100.0;

    double scalesDMG;

    void UpdateAmount (S7_BasicArmor armor) {
        armor.amount = int (clamp (100 * (1 - scalesDMG / scalesDMGLimit), 0, 100));
    }

    override void FixArmor (S7_BasicArmor armor, int amount) {
        scalesDMG = max (scalesDMG - amount, 0.);

        UpdateAmount (armor);
    }

    override void GotBonus (S7_BasicArmor armor, int amount) {
        FixArmor (armor, amount);
    }

    override void Tick (S7_BasicArmor armor) {
        UpdateAmount (armor);
    }

    override double GetSpeedFactor () {
        return 0.96;
    }

    override int HandleDamage (S7_BasicArmor armor, Actor inflictor, Actor source, int damage, Name damageType) {
        if (!armor)
            return damage;

        let pPawn = PlayerPawn (armor.Owner);
        if (!pPawn)
            return damage;

        double ret;
        double vestDMG = 0;

        double startHeight = S7_Math.Lerp (NormalStartHeight, CrouchStartHeight, (1 - pPawn.player.crouchfactor) * 2);
        double   endHeight = S7_Math.Lerp (  NormalEndHeight,   CrouchEndHeight, (1 - pPawn.player.crouchfactor) * 2);

        if (inflictor &&
            (inflictor.pos.z + inflictor.height/2) >= (pPawn.pos.z + startHeight) &&
            (inflictor.pos.z + inflictor.height/2) <= (pPawn.pos.z + endHeight)) {
            double vestInt = scalesDMG / scalesDMGLimit;

            switch (damageType) {
            case 'PistolTracer':   vestDMG = damage * 0.25 ; ret = damage * clamp ((vestInt - 0.5 ) / 0.5 , 0.187, 1.0); break;
            case 'RevolverTracer': vestDMG = damage * 0.275; ret = damage * clamp ((vestInt - 0.4 ) / 0.6 , 0.262, 1.0); break;
            case 'ShotgunTracer':  vestDMG = damage * 0.3  ; ret = damage * clamp ((vestInt - 0.65) / 0.35, 0.094, 1.0); break;
            case 'RifleTracer':    vestDMG = damage * 0.95 ; ret = damage * clamp ((vestInt       ) / 0.85, 0.49,  1.0); break;
            case 'SniperRifleTracer':
                vestDMG = damage * fRandom [S7_Armor] (0.0, 0.25);
                ret = damage - vestDMG;
                break;
            case 'Fire':
                vestDMG = damage * fRandom [S7_Armor] (0.0, 0.2);
                ret = S7_Math.Lerp (damage * fRandom [S7_Armor] (0.0, 0.5), damage, vestInt);
                break;
            default:
                vestDMG = damage * 0.2;
                ret = damage * clamp (vestInt, 0.85, 1.0);
                break;
            }
        } else if (damageType == 'Crush') {
            vestDMG = damage * fRandom [S7_Armor] (0.2, 0.3);
            ret = damage;
        } else
            ret = damage;

        scalesDMG = clamp (scalesDMG + max (vestDMG, 0), 0, scalesDMGLimit);
        UpdateAmount (armor);

        return int (ret);
    }
}

class S7_SBTKSecVest : S7_BasicArmorPickup {
    default {
        Radius 20;
        Height 16;
        Armor.SaveAmount 100;
        Inventory.PickupSound "Inventory/ArmorPickup";
        Inventory.PickupMessage "$SECVEST_SBTK";
        Inventory.Icon "ARSVB0";
        Tag "$SECVEST_SBTK";

        S7_BasicArmorPickup.DataClass 'S7_SBTKSecVestData';
    }

    states {
    Spawn:
        ARSV B 6;
        ARSV B 6 bright;
        loop;
    }
}