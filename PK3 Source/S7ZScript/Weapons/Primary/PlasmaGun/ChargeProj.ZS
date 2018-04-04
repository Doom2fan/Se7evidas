//-------------------------------------------------------------------------------------------
//
// Projectiles
//
//-------------------------------------------------------------------------------------------
class S7_PlasmaGunRailCharge1 : S7_PlasmaGunRail {
    default {
        S7_BaseTracer.TrueSpeed 337;
        Scale 0.03;
        DamageFunction (fRandom [weaponDamage] (1.0, 2.0) * 35);
        MissileType "S7_PlasmaGunRailTrail_Charge1";
        Decal "S7_PlasmaGunRail_Charge1";

        +RIPPER
    }
}

class S7_PlasmaGunRailCharge2 : S7_PlasmaGunRail {
    default {
        S7_BaseTracer.TrueSpeed 382;
        Scale 0.035;
        DamageFunction (fRandom [weaponDamage] (1.0, 2.0) * 40);
        MissileType "S7_PlasmaGunRailTrail_Charge2";
        Decal "S7_PlasmaGunRail_Charge2";

        +RIPPER
    }
}

class S7_PlasmaGunRailCharge3 : S7_PlasmaGunRail {
    default {
        S7_BaseTracer.TrueSpeed 427;
        Scale 0.045;
        DamageFunction (fRandom [weaponDamage] (1.0, 2.0) * 47.5);
        MissileType "S7_PlasmaGunRailTrail_Charge3";
        Decal "S7_PlasmaGunRail_Charge3";

        +RIPPER
    }
}
class S7_PlasmaGunRailCharge4 : S7_PlasmaGunRail {
    default {
        S7_BaseTracer.TrueSpeed 472;
        Scale 0.055;
        DamageFunction (fRandom [weaponDamage] (1.0, 2.0) * 52.5);
        MissileType "S7_PlasmaGunRailTrail_Charge4";
        Decal "S7_PlasmaGunRail_Charge4";

        +RIPPER
    }
}


//-------------------------------------------------------------------------------------------
//
// Effects
//
//-------------------------------------------------------------------------------------------
/** Trails **/
class S7_PlasmaGunRailTrail_Charge1 : S7_PlasmaGunRailTrail { default { Scale 0.03; } }
class S7_PlasmaGunRailTrail_Charge2 : S7_PlasmaGunRailTrail { default { Scale 0.035; } }
class S7_PlasmaGunRailTrail_Charge3 : S7_PlasmaGunRailTrail { default { Scale 0.045; } }
class S7_PlasmaGunRailTrail_Charge4 : S7_PlasmaGunRailTrail { default { Scale 0.055; } }