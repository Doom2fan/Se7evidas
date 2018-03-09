//-------------------------------------------------------------------------------------------
//
// Projectiles
//
//-------------------------------------------------------------------------------------------
class S7_PlasmaGunRailCharge1 : S7_PlasmaGunRail {
    default {
        S7_BaseTracer.TrueSpeed 306;
        Scale 0.03;
        DamageFunction (21 + fRandom [weaponDamage] (-1.0, 1.0));
        MissileType "S7_PlasmaGunRailTrail_Charge1";
        Decal "S7_PlasmaGunRail_Charge1";

        +RIPPER
    }

    states {
    Death:
        HTS0 A       1 A_SetScale (scale.X * 10);
        HTS0 BCDEFGH 1;
        stop;
    }
}

class S7_PlasmaGunRailCharge2 : S7_PlasmaGunRailCharge1 {
    default {
        S7_BaseTracer.TrueSpeed 315;
        Scale 0.035;
        DamageFunction (24 + fRandom [weaponDamage] (-1.0, 1.0));
        MissileType "S7_PlasmaGunRailTrail_Charge2";
        Decal "S7_PlasmaGunRail_Charge2";
    }
}

class S7_PlasmaGunRailCharge3 : S7_PlasmaGunRailCharge1 {
    default {
        S7_BaseTracer.TrueSpeed 324;
        Scale 0.04;
        DamageFunction (27 + fRandom [weaponDamage] (-1.0, 1.0));
        MissileType "S7_PlasmaGunRailTrail_Charge3";
        Decal "S7_PlasmaGunRail_Charge3";
    }
}
class S7_PlasmaGunRailCharge4 : S7_PlasmaGunRailCharge3 {
    default {
        S7_BaseTracer.TrueSpeed 333;
        Scale 0.045;
        DamageFunction (30 + fRandom [weaponDamage] (-1.0, 1.0));
        MissileType "S7_PlasmaGunRailTrail_Charge4";
        Decal "S7_PlasmaGunRail_Charge4";
    }
}


//-------------------------------------------------------------------------------------------
//
// Effects
//
//-------------------------------------------------------------------------------------------
/** Trails **/
class S7_PlasmaGunRailTrail_Charge1 : S7_PlasmaGunRailTrail { default { Scale 0.03;  } }
class S7_PlasmaGunRailTrail_Charge2 : S7_PlasmaGunRailTrail { default { Scale 0.035; } }
class S7_PlasmaGunRailTrail_Charge3 : S7_PlasmaGunRailTrail { default { Scale 0.04;  } }
class S7_PlasmaGunRailTrail_Charge4 : S7_PlasmaGunRailTrail { default { Scale 0.045; } }