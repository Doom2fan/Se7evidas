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
// XP System
//
//-------------------------------------------------------------------------------------------
enum S7_StatType {
    S7Stat_Strength = 1,
    S7Stat_Agility,
    S7Stat_Vitality,
    S7Stat_Defense,
    S7Stat_Will,
    S7Stat_Magic,
    S7Stat_Tech,
    S7Stat_Special = 1 << 16,
}

class S7_Effect { // Status effects
    int ticsLeft;

    virtual bool Init (actor act, S7_XPSystem xpSys) {
        return true;
    }

    virtual void Tick (actor act, S7_XPSystem xpSys) {
        if (ticsLeft > 0)
            ticsLeft--;
        else
            ticsLeft = -1;
    }
}
class S7_StatModifier : S7_Effect { // Buffs and debuffs to stats, essentially.
    S7_StatType stats;
    double factor;
    bool addFactor; // Adds the factor value instead of multiplying

    string specialStatName; // Only used with S7Stat_Special

    bool hasFactorFunc;
    virtual double FactorFunc (Actor act, S7_XPSystem xpSys, S7_StatType stat) { return double.NaN; } // Returns NaN to make sure you notice if you set hasFactorFunc but don't override this
}

class S7_XPSystem : Inventory {
    const BaseXPGoal = 2500;
    bool canLevelUp;
    bool randomStats;
    property CanLevelUp: canLevelUp;
    property RandomStats: randomStats;

    default {
        Inventory.MaxAmount 1;
        inventory.interHubAmount 1;
        S7_XPSystem.canLevelUp false;
        S7_XPSystem.randomStats false;

        +INVENTORY.UNDROPPABLE +INVENTORY.UNTOSSABLE
        -INVENTORY.INVBAR
    }

    protected Array<S7_StatModifier> statMods;
    protected Array<S7_Effect> statusEffects;
    int level, xpPoints;
    int strengthStat, agilityStat, vitalityStat, defenseStat, willStat, magicStat, techStat;
    double softness;

    bool AddStatMod (S7_StatModifier mod) {
        if (!mod.Init (Owner, self))
            return false;

        statMods.Push (mod);
        return true;
    }
    bool RemoveStatMod (S7_StatModifier mod) {
        for (int i = statMods.Size () - 1; i >= 0; i--) {
            if (statMods [i] == mod) {
                statMods.Delete (i, 1);
                return true;
            }
        }

        return false;
    }

    bool AddStatusEffects (S7_Effect effect) {
        if (effect is 'S7_StatModifier')
            return false;

        if (!effect.Init (Owner, self))
            return false;

        statusEffects.Push (effect);
        return true;
    }
    bool RemoveStatusEffects (S7_Effect effect) {
        if (effect is 'S7_StatModifier') // Don't even bother, we're not gonna find that here.
            return true;

        for (int i = statusEffects.Size () - 1; i >= 0; i--) {
            if (statusEffects [i] == effect) {
                statusEffects.Delete (i, 1);
                return true;
            }
        }

        return false;
    }

    clearscope double, double GetStatMod (S7_StatType stat, string specialName = "") {
        if (stat == S7Stat_Special && specialName == "")
            return double.NaN, double.NaN;

        double ret1 = 1.0;
        double ret2 = 0.0;

        for (int i = 0; i < statMods.Size (); i++) {
            if (statMods [i] && statMods [i].stats == stat) {
                if (stat == S7Stat_Special && specialName && statMods [i].specialStatName != specialName)
                    continue;

                double factor;
                if (!statMods [i].hasFactorFunc)
                    factor = statMods [i].factor;
                else
                    factor = statMods [i].FactorFunc (Owner, self, stat);

                if (statMods [i].addFactor)
                    ret2 += factor;
                else
                    ret1 *= factor;
            }
        }

        return ret1, ret2;
    }

    clearscope double GetStat (S7_StatType stat, bool noMods = false, string specialName = "", double specialStatAmount = 0.0) {
        if (stat == S7Stat_Special) {
            if (noMods || specialName == "")
                return double.NaN;

            double mod1, mod2;
            [mod1, mod2] = GetStatMod (S7Stat_Special, specialName);

            return (specialStatAmount * mod1) + mod2;
        }

        double ret;

        switch (stat) {
            case S7Stat_Strength: ret = strengthStat; break;
            case S7Stat_Agility:  ret = agilityStat; break;
            case S7Stat_Vitality: ret = vitalityStat; break;
            case S7Stat_Defense:  ret = defenseStat; break;
            case S7Stat_Will:     ret = willStat; break;
            case S7Stat_Magic:    ret = magicStat; break;
            case S7Stat_Tech:     ret = techStat; break;
        }

        if (!noMods) {
            double mod1, mod2;
            [mod1, mod2] = GetStatMod (stat);

            return (ret * mod1) + mod2;
        } else
            return ret;
    }

    bool SetStat (S7_StatType stat, int amount, bool additive = true) {
        int setAmount = -1;

        if (additive) {
            int curAmount = int (GetStat (stat, true));
            setAmount = curAmount + amount;

            if ((setAmount > 0 && setAmount < curAmount) || // If this is true it means we over/underflowed, so nope the fuck out of there.
                (setAmount < 0 && setAmount > curAmount))
                return false;
        } else
            setAmount = amount;

        if (setAmount < 0) // Nope.
            return false;

        switch (stat) {
            case S7Stat_Strength: strengthStat = setAmount; break;
            case S7Stat_Agility:  agilityStat  = setAmount; break;
            case S7Stat_Vitality: vitalityStat = setAmount; break;
            case S7Stat_Defense:  defenseStat  = setAmount; break;
            case S7Stat_Will:     willStat     = setAmount; break;
            case S7Stat_Magic:    magicStat    = setAmount; break;
            case S7Stat_Tech:     techStat     = setAmount; break;
        }

        return true;
    }

    void GiveXP (int amount) {
        if (amount <= 0)
            return;

        xpPoints += amount;
    }

    override void DoEffect () {
        if (!Owner)
            return;

        if (canLevelUp) {
            int reqXP = int (BaseXPGoal * (1.0 + .75 * level)),
                nextLevel = level + 1;

            if (xpPoints >= reqXP && level < S7_MaxLevel) {
                level = nextLevel;
                xpPoints -= reqXP;
                OnLevelUp ();
            }
        }

        for (int i = 0; i < statMods.Size (); i++) {
            if (statMods [i])
                statMods [i].Tick (Owner, self);
        }

        for (int i = statMods.Size () - 1; i >= 0; i--) {
            if (!statMods [i] || statMods [i].ticsLeft == -1) {
                let tmp = statMods [i];
                statMods.Delete  (i, 1);
                if (tmp)
                    tmp.Destroy ();
            }
        }
    }

    static const S7_StatType MonsterUsableStats [] = {
        S7Stat_Strength,
        S7Stat_Agility,
        //S7Stat_Vitality,
        S7Stat_Defense,
        S7Stat_Will
        //S7Stat_Magic
    };
    virtual void OnLevelUp () {
        if (Owner is 'S7_BasePlayer' && Owner.player)
            return;

        int attrPoints = random [XPSys] (3, 5);
        S7_StatType statToSet = S7Stat_Strength;

        while (attrPoints > 0) {
            if (randomStats)
                statToSet = MonsterUsableStats [random [XPSys] (0, MonsterUsableStats.Size ())];
            else {
                for (int i = 0; i < MonsterUsableStats.Size (); i++)
                    if (GetStat (MonsterUsableStats [i], true) < GetStat (statToSet, true))
                        statToSet = MonsterUsableStats [i];
            }

            SetStat (statToSet, 1);
            attrPoints--;
        }
    }
}