//-------------------------------------------------------------------------------------------
//
// Projectiles
//
//-------------------------------------------------------------------------------------------
class S7_PlasmaGunRailCharge1 : S7_PlasmaGunRail {
    default {
        S7_BaseTracer.trueSpeed 306;
        scale 0.03;
        damageFunction (21 + fRandom [weaponDamage] (-1.0, 1.0));
        missileType "S7_PlasmaGunRailTrail_Charge1";
        decal "S7_PlasmaGunRail_Charge1";

        +ripper
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
        S7_BaseTracer.trueSpeed 315;
        scale 0.035;
        damageFunction (24 + fRandom [weaponDamage] (-1.0, 1.0));
        missileType "S7_PlasmaGunRailTrail_Charge2";
        decal "S7_PlasmaGunRail_Charge2";
    }
}

class S7_PlasmaGunRailCharge3 : S7_PlasmaGunRailCharge1 {
    default {
        S7_BaseTracer.trueSpeed 324;
        scale 0.04;
        damageFunction (27 + fRandom [weaponDamage] (-1.0, 1.0));
        missileType "S7_PlasmaGunRailTrail_Charge3";
        decal "S7_PlasmaGunRail_Charge3";
    }
}
class S7_PlasmaGunRailCharge4 : S7_PlasmaGunRailCharge3 {
    default {
        S7_BaseTracer.trueSpeed 333;
        scale 0.045;
        damageFunction (30 + fRandom [weaponDamage] (-1.0, 1.0));
        missileType "S7_PlasmaGunRailTrail_Charge4";
        decal "S7_PlasmaGunRail_Charge4";
    }
}


//-------------------------------------------------------------------------------------------
//
// Effects
//
//-------------------------------------------------------------------------------------------
/** Trails **/
class S7_PlasmaGunRailTrail_Charge1 : S7_PlasmaGunRailTrail { default { scale 0.03;  } }
class S7_PlasmaGunRailTrail_Charge2 : S7_PlasmaGunRailTrail { default { scale 0.035; } }
class S7_PlasmaGunRailTrail_Charge3 : S7_PlasmaGunRailTrail { default { scale 0.04;  } }
class S7_PlasmaGunRailTrail_Charge4 : S7_PlasmaGunRailTrail { default { scale 0.045; } }