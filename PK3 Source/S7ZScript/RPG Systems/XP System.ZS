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
}

class S7_StatModifier { // Buffs and debuffs, essentially.
    S7_StatType stats;
    double factor;
    int ticsLeft;

    bool hasFactorFunc;
    virtual double FactorFunc (Actor act, S7_XPSystem xpSys, S7_StatType stat) { return double.NaN; } // Returns NaN to make sure you notice if you set hasFactorFunc but don't override this

    bool hasTickFunc;
    virtual void Tick (actor act, S7_XPSystem xpSys) {
        if (ticsLeft > 0)
            ticsLeft--;
        else
            ticsLeft = -1;
    }
}

class S7_XPSystem : Inventory {
    const BaseXPGoal = 2500;
    bool canLevelUp;
    bool randomStats;
    property canLevelUp: canLevelUp;
    property randomStats: canLevelUp;

    default {
        inventory.maxAmount 1;
        inventory.interHubAmount 1;
        S7_XPSystem.canLevelUp false;
        S7_XPSystem.randomStats false;

        +inventory.undroppable +inventory.untossable
        -inventory.invBar
    }

    Array<S7_StatModifier> statMods;
    int level, xpPoints;
    int strengthStat, agilityStat, vitalityStat, defenseStat, willStat, magicStat, techStat;
    double softness;

    clearscope double GetStatMod (S7_StatType stat) {
        double ret = 1.0;

        int statMask = 1 << (stat - 1);
        for (int i = 0; i < statMods.Size (); i++) {
            if (statMods [i] && statMods [i].stats & statMask) {
                if (!statMods [i].hasFactorFunc)
                    ret *= statMods [i].factor;
                else
                    ret *= statMods [i].FactorFunc (Owner, self, stat);
            }
        }

        return ret;
    }

    clearscope double GetStat (S7_StatType stat, bool noMods = false) {
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

        if (!noMods)
            return ret * GetStatMod (stat);
        else
            return ret;
    }

    bool SetStat (S7_StatType stat, int amount, bool additive = true) {
        int setAmount = -1;

        if (additive) {
            int curAmount = GetStat (stat);
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
            int reqXP = BaseXPGoal * (1.0 + 2 * level),
                nextLevel = level + 1;

            if (xpPoints >= reqXP && level < S7_MaxLevel) {
                level = nextLevel;
                xpPoints -= reqXP;
                OnLevelUp ();
            }
        }

        for (int i = 0; i < statMods.Size (); i++) {
            if (statMods [i] && statMods [i].hasTickFunc)
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
        if (Owner is "S7_BasePlayer" && Owner.player)
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