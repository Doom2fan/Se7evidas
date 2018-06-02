//-------------------------------------------------------------------------------------------
//
// Monster bases
//
//-------------------------------------------------------------------------------------------
class S7_MonsterBase : Actor {
    default {
        Health 60;
        Radius 20;
        Height 56;
        Mass 100;
        Speed 8;

        /** Damage factors **/
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.5;
        DamageFactor "LaserTracer", 1.25;

        Monster;

        +FLOORCLIP +DONTHARMCLASS
    }

    int monsDeathType;
    Actor grabbedShooter;

    override void Die (Actor source, Actor inflictor, int dmgflags) {
        Super.Die (source, inflictor, dmgflags);

        if (source is "S7_PlayerSummon") {
            if (source.master && source.master.player && multiplayer)
                source.player.killcount++;
        }

        OnDeath (source, inflictor, dmgflags);
    }
    virtual void OnDeath (Actor source, Actor inflictor, int dmgflags) { }

    S7_XPSystem GetXPSystem () {
        return S7_XPSystem (FindInventory ("S7_XPSystem", true));
    }

    void GiveXP (Actor act, int amount) {
        if (!act || amount <= 0)
            return;

        S7_XPSystem xpSys = S7_XPSystem (act.FindInventory ("S7_XPSystem", true));

        if (!xpSys && act is "S7_PlayerSummon" && act.master)
            xpSys = S7_XPSystem (act.master.FindInventory ("S7_XPSystem", true));

        if (!xpSys)
            return;

        xpSys.GiveXP (amount);
    }

    void GiveCash (Actor act, int amount, class<Inventory> cashItem = 'S7_Cash') {
        if (!act || amount <= 0)
            return;

        if (act is "S7_PlayerSummon") {
            if (!act.master)
                return;

            act = act.master;
        }

        act.GiveInventory (cashItem, amount);
    }
}

class S7_DemonBase : S7_MonsterBase {
    default {
        // Demon flesh damage reduction
        DamageFactor "PistolTracer", 0.7;
        DamageFactor "RevolverTracer", 0.8;
        DamageFactor "ShotgunTracer", 0.86;
        DamageFactor "RifleTracer", 0.9;
    }
}

class S7_HellNobleBase : S7_DemonBase {
    default {
        Health 1000;
        Radius 24;
        Height 64;
        Mass 1000;
        PainChance 50;

        /** Damage factors **/
        // Demon flesh damage reduction
        DamageFactor "PistolTracer", 0.7;
        DamageFactor "RevolverTracer", 0.8;
        DamageFactor "RifleTracer", 0.9;
        // Hell Noble buckshot damage bonus
        DamageFactor "ShotgunTracer", 1.2;
    }
}

class S7_SuccubusBase : S7_DemonBase {
    default {
        Health 400;
        Radius 18;
        Height 50;
        Mass 200;
        PainChance 90;

        /** Damage factors **/
        // Demon flesh damage reduction
        // Succubi get lower reduction because they're mostly human
        DamageFactor "PistolTracer", 0.75;
        DamageFactor "RevolverTracer", 0.85;
        DamageFactor "ShotgunTracer", 0.91;
        DamageFactor "RifleTracer", 0.95;
    }
}

class S7_ScorpBase : S7_MonsterBase {
    default {
        Radius 16;
        Height 56;
        ActiveSound "Monsters/Nova/RadioChatter";

        /** Damage factors **/
        // Reanimated flesh damage reduction
        DamageFactor "PistolTracer", 0.75;
        DamageFactor "RevolverTracer", 0.85;
        DamageFactor "ShotgunTracer", 0.91;
        DamageFactor "RifleTracer", 0.95;
        // Plasma/Laser damage bonus
        DamageFactor "Plasma", 1.6;
        DamageFactor "LaserTracer", 1.35;
    }

    // Default variables
    int fireMode, ammo;
    double turn, spreadX, spreadY;
}