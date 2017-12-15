//-------------------------------------------------------------------------------------------
//
// Monster bases
//
//-------------------------------------------------------------------------------------------
class S7_MonsterBase : actor {
    default {
        health 60;
        radius 20;
        height 56;
        mass 100;
        speed 8;

        /** Damage factors **/
        // Plasma/Laser damage bonus
        damageFactor "Plasma", 1.5;
        damageFactor "LaserTracer", 1.25;

        monster;
        +floorClip +dontHarmClass
    }

    int monsDeathType;
    Actor grabbedShooter;

    action void S7_A_GrabBeam () {
        
    }
}

class S7_DemonBase : S7_MonsterBase {
    default {
        // Demon flesh damage reduction
        damageFactor "PistolTracer", 0.7;
        damageFactor "RevolverTracer", 0.8;
        damageFactor "ShotgunTracer", 0.86;
        damageFactor "RifleTracer", 0.9;
    }
}

class S7_HellNobleBase : S7_DemonBase {
    default {
        health 1000;
        radius 24;
        height 64;
        mass 1000;
        painChance 50;

        /** Damage factors **/
        // Demon flesh damage reduction
        damageFactor "PistolTracer", 0.7;
        damageFactor "RevolverTracer", 0.8;
        damageFactor "RifleTracer", 0.9;
        // Hell Noble buckshot damage bonus
        damageFactor "ShotgunTracer", 1.2;
    }
}

class S7_SuccubusBase : S7_DemonBase {
    default {
        health 400;
        radius 18;
        height 50;
        mass 200;
        painChance 90;

        /** Damage factors **/
        // Demon flesh damage reduction
        // Succubi get lower reduction because they're mostly human
        damageFactor "PistolTracer", 0.75;
        damageFactor "RevolverTracer", 0.85;
        damageFactor "ShotgunTracer", 0.91;
        damageFactor "RifleTracer", 0.95;
    }
}

class S7_ScorpBase : S7_MonsterBase {
    default {
        radius 16;
        height 56;
        activeSound "Monsters/Nova/RadioChatter";
        seeSound "Monsters/Nova/RadioSight";

        /** Damage factors **/
        // Reanimated flesh damage reduction
        damageFactor "PistolTracer", 0.75;
        damageFactor "RevolverTracer", 0.85;
        damageFactor "ShotgunTracer", 0.91;
        damageFactor "RifleTracer", 0.95;
        // Plasma/Laser damage bonus
        damageFactor "Plasma", 1.6;
        damageFactor "LaserTracer", 1.35;
    }

    // Default variables
    int fireMode, ammo;
    double turn, spreadX, spreadY;
}