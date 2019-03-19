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

class S7_WeapData {
    static const String WeaponNames [] = {
        "S7_PrettyShootyIonCannonGun",
        "S7_PlasmaGun",
        "S7_AMG",
        "S7_ManxCarbine",
        "S7_Shotgun",
        "S7_Raptor",
        "S7_Revolver",
        "S7_TEC9",
        "S7_SoulLance",
        "S7_Thumper",
        "S7_HitterSMG",
        "S7_Fauchard",
        "S7_SSG",
        "S7_LaserPewPew",
        "S7_BerserkWeap",
        "S7_GrenadeWeap",
        "S7_ConquerorRifle",
        "S7_AntimatterGun",
        "S7_AK47"
    };

    static const String ClipNames [] = {
        "S7_AMGMag",
        "S7_FauchardMag",
        "S7_HitterSMGClip",
        "S7_ManxCarbineClip",
        "S7_PlasmaGunMag",
        //s"S7_PrettyShootyIonCannonGunMag",
        "S7_ShotgunMag",
        "S7_ThumperMag",
        "S7_RaptorClip",
        "S7_RevolverClip",
        "S7_TEC9Clip",
        "S7_SSGFauxClip",
        "S7_LaserPewPewClip",
        "S7_LaserPewPewClipSecond",
        "S7_ConquerorRifleClip",
        "S7_AntimatterGunClip",
        "S7_AK47Clip"
    };

    static const String AmmoNames [] = {
        "S7_BackpackToken",
        "S7_9mmCartridges",
        "S7_45ACPCartridges",
        "S7_44MCartridges",
        "S7_762x39Cartridges",
        "S7_20gaShells",
        "S7_12gaShells",
        "S7_Cells",
        "S7_FBSysCells",
        "S7_45WWCartridges",
        "S7_AntimatterShells",
        "S7_Thumper_PExp",
        "S7_Thumper_PFrag",
        "S7_Thumper_PTherm",
        "S7_Thumper_PFlare",
        "S7_Thumper_PCluster",
        "S7_Thumper_PNail",
        "S7_Thumper_PNGas",
        "S7_Thumper_PUnified"
    };

    static const String AmmoTypesData [] = {
        "S7_9mmCartridges:75",
        "S7_45ACPCartridges:62",
        "S7_44MCartridges:6:8",
        "S7_762x39Cartridges:35:8",
        "S7_45WWCartridges:75",
        "S7_20gaShells:10",
        "S7_12gaShells:12",
        "S7_Cells:36",
        "S7_FBSysCells:32",
        "S7_AntimatterShells:1",
        "S7_Thumper_PUnified:5",
        "S7_Thumper_PExp:5",
        "S7_Thumper_PFrag:5",
        "S7_Thumper_PTherm:5",
        "S7_Thumper_PFlare:5",
        "S7_Thumper_PCluster:5",
        "S7_Thumper_PNail:5",
        "S7_Thumper_PNGas:5"
    };

    static const String WeaponDescs [] = {
        // Sidearms
        "S7_TEC9:$WPDSC_TEC9",
        "S7_Revolver:$WPDSC_REVOLVER",
        "S7_Raptor:$WPDSC_RAPTOR",
        // SMGs
        "S7_HitterSMG:$WPDSC_HITTER",
        "S7_LaserPewPew:$WPDSC_BUTTFLY",
        // Rifles
        "S7_AK47:$WPDSC_AK47",
        "S7_AMG:$WPDSC_AMG",
        "S7_Fauchard:$WPDSC_FAUCHARD",
        "S7_ManxCarbine:$WPDSC_MANX",
        // Machineguns
        "S7_PlasmaGun:$WPDSC_PLASMAMG",
        "S7_CaesarChaingun:$WPDSC_CAESARCHAINGUN",
        // Shotguns
        "S7_Shotgun:$WPDSC_SHOTGUN",
        "S7_SSG:$WPDSC_SSG",
        // Area-damage
        "S7_Thumper:$WPDSC_THUMPER",
        "S7_PrettyShootyIonCannonGun:$WPDSC_IONCANNON",
        // Sniper rifles
        "S7_ConquerorRifle:$WPDSC_CONQUEROR",
        // Throwables
        "S7_GrenadeWeap:$WPDSC_GRENADES"
    };
}