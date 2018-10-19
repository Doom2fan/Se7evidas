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
// Projectiles
//
//-------------------------------------------------------------------------------------------
class S7_PlasmaGunRailCharge1 : S7_PlasmaGunRail {
    default {
        S7_Projectile.FastProjCollision ColMode_Center | ColMode_Corners | ColMode_EdgeCenters;
        S7_BaseTracer.TrueSpeed 337;

        Radius 4;
        Height 4;
        Scale 0.03;
        DamageFunction (fRandom [weaponDamage] (1.0, 2.0) * 35);
        MissileType "S7_PlasmaGunRailTrail_Charge1";
        Decal "S7_PlasmaGunRail_Charge1";

        +RIPPER
    }
}

class S7_PlasmaGunRailCharge2 : S7_PlasmaGunRailCharge1 {
    default {
        Radius 5;
        Height 5;

        S7_BaseTracer.TrueSpeed 382;
        Scale 0.035;
        DamageFunction (fRandom [weaponDamage] (1.0, 2.0) * 40);
        MissileType "S7_PlasmaGunRailTrail_Charge2";
        Decal "S7_PlasmaGunRail_Charge2";
    }
}

class S7_PlasmaGunRailCharge3 : S7_PlasmaGunRailCharge1 {
    default {
        Radius 6;
        Height 6;

        S7_BaseTracer.TrueSpeed 427;
        Scale 0.045;
        DamageFunction (fRandom [weaponDamage] (1.0, 2.0) * 47.5);
        MissileType "S7_PlasmaGunRailTrail_Charge3";
        Decal "S7_PlasmaGunRail_Charge3";
    }
}
class S7_PlasmaGunRailCharge4 : S7_PlasmaGunRailCharge1 {
    default {
        Radius 7;
        Height 7;

        S7_BaseTracer.TrueSpeed 472;
        Scale 0.055;
        DamageFunction (fRandom [weaponDamage] (1.0, 2.0) * 52.5);
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
class S7_PlasmaGunRailTrail_Charge1 : S7_PlasmaGunRailTrail { default { Scale 0.03; } }
class S7_PlasmaGunRailTrail_Charge2 : S7_PlasmaGunRailTrail { default { Scale 0.035; } }
class S7_PlasmaGunRailTrail_Charge3 : S7_PlasmaGunRailTrail { default { Scale 0.045; } }
class S7_PlasmaGunRailTrail_Charge4 : S7_PlasmaGunRailTrail { default { Scale 0.055; } }