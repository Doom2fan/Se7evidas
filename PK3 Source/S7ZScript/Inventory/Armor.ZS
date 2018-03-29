//-------------------------------------------------------------------------------------------
//
// Cronus Corps Security Vest
//
//-------------------------------------------------------------------------------------------
class S7_CCSecVestData : S7_ArmorData {
    const startHeight = 26;
    const endHeight = 47;
    const kevlarDMGLimit = 100.0;

    double kevlarDMG;

    override int HandleDamage (S7_BasicArmor armor, Actor inflictor, Actor source, int damage, Name damageType) {
        if (!armor)
            return damage;

        int ret;
        double kevDMG = 0;

        if (inflictor &&
            (inflictor.pos.z + inflictor.height/2) >= (armor.Owner.pos.z + startHeight) &&
            (inflictor.pos.z + inflictor.height/2) <= (armor.Owner.pos.z + endHeight)) {
            double kevInt = kevlarDMG / kevlarDMGLimit;

            switch (damageType) {
            case 'PistolTracer':   kevDMG = damage * 0.5 ; ret = damage * clamp ((kevInt - 0.5 ) / 0.5 , 0.25,  1.0); break;
            case 'RevolverTracer': kevDMG = damage * 0.55; ret = damage * clamp ((kevInt - 0.4 ) / 0.6 , 0.35,  1.0); break;
            case 'ShotgunTracer':  kevDMG = damage * 0.6 ; ret = damage * clamp ((kevInt - 0.65) / 0.35, 0.125, 1.0); break;
            case 'RifleTracer':    kevDMG = damage * 0.9 ; ret = damage * clamp ((kevInt - 0.1 ) / 0.9 , 0.65,  1.0); break;
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
        armor.amount = clamp (100 * (1 - kevlarDMG / kevlarDMGLimit), 0, 100);

        return ret;
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
    const startHeight = 26;
    const endHeight = 47;
    const kevlarDMGLimit = 100.0;
    const platesDMGLimit = 100.0;

    double kevlarDMG;
    double platesDMG;

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

        return dmg * kevDMG, dmg * pltDMG, dmg * usrDMG;
    }

    override void Init (S7_BasicArmor armor) {
        kevlarDMG = 0;
        platesDMG = 0;
    }

    override int HandleDamage (S7_BasicArmor armor, Actor inflictor, Actor source, int damage, Name damageType) {
        if (!armor)
            return damage;

        int ret;
        double kevDMG = 0;
        double pltDMG = 0;

        if (inflictor &&
            (inflictor.pos.z + inflictor.height/2) >= (armor.Owner.pos.z + startHeight) &&
            (inflictor.pos.z + inflictor.height/2) <= (armor.Owner.pos.z + endHeight)) {
            double kevInt = kevlarDMG / kevlarDMGLimit;
            double pltInt = platesDMG / platesDMGLimit;

            switch (damageType) {
            case 'PistolTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.15, 0.95, pltShift: 0.5 , pltMin: 0.1 , usrPltM: 0.5 , usrKevM: 0.25, usrKevMShift: 0.25, usrMin: 0.2);
                break;
            case 'RevolverTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.17, 0.9 , pltShift: 0.4 , pltMin: 0.15, usrPltM: 0.54, usrKevM: 0.33, usrKevMShift: 0.2 , usrMin: 0.22);
                break;
            case 'ShotgunTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.1 , 0.95, pltShift: 0.65, pltMin: 0.15, usrPltM: 0.5 , usrKevM: 0.2 , usrKevMShift: 0.33, usrMin: 0.2 );
                break;
            case 'RifleTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.20, 0.8 , pltShift: 0.3 , pltMin: 0.18, usrPltM: 0.6 , usrKevM: 0.48, usrKevMShift: 0.18, usrMin: 0.32);
                break;
            case 'SniperRifleTracer':
                [kevDMG, pltDMG, ret] = CalcBulletDamage (damage, 0.25, 0.5 , pltShift: 0.3 , pltMin: 0.4 , usrPltM: 0.7 , usrKevM: 0.75, usrKevMShift: 0.08, usrMin: 0.64);
                break;
            case 'Fire':
                pltDMG = max (damage - 25, 0) * 0.25;
                kevDMG = damage * (fRandom [S7_Armor] (0.75, 1.2) * pltInt);
                ret = damage  * pltInt;
                break;
            default:
                pltDMG = damage * (0.15 * (1-pltInt));
                kevDMG = damage * (0.15 * pltInt);
                ret = damage * clamp ((kevInt + pltDMG) / 2, 0.7, 1.0);
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
        armor.amount = clamp (100 * ((1 - kevlarDMG / kevlarDMGLimit) + (1 - platesDMG / platesDMGLimit)), 0, 200);

        return ret;
    }
}

class S7_CCCombatArmor : S7_BasicArmorPickup {
    default {
        Radius 20;
        Height 16;
        Armor.SaveAmount 200;
        //Inventory.PickupMessage "$SECVEST_CC";
        Inventory.Icon "ARM2A0";
        //Tag "$SECVEST_CC";

        S7_BasicArmorPickup.DataClass "S7_CCCombatArmorData";
    }

    states {
    Spawn:
        ARM2 A 6;
        ARM2 B 6 bright;
        loop;
    }
}

