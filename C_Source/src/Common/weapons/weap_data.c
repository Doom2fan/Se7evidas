/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015  Chronos Ouroboros
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License along
**  with this program; if not, write to the Free Software Foundation, Inc.,
**  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include "includes.h"
#include "weapons/weap_data.h"

const string WeaponNames [] = {
    s"S7_PrettyShootyIonCannonGun",
    s"S7_PlasmaGun",
    s"S7_AMG",
    s"S7_ManxCarbine",
    s"S7_Shotgun",
    s"S7_Raptor",
    s"S7_Revolver",
    s"S7_TEC9",
    s"S7_SoulLance",
    s"S7_Thumper",
    s"S7_HitterSMG",
    s"S7_Fauchard",
    s"S7_SSG",
    s"S7_BerserkWeap",
};
const int WeaponNames_Length = ArraySize (WeaponNames);

const string ClipNames [] = {
    s"S7_AMGMag",
    s"S7_FauchardMag",
    s"S7_HitterSMGClip",
    s"S7_ManxCarbineClip",
    s"S7_PlasmaGunMag",
    //s"S7_PrettyShootyIonCannonGunMag",
    s"S7_ShotgunMagCounter",
    s"S7_ThumperMag",
    s"S7_RaptorClip",
    s"S7_RevolverClip",
    s"S7_TEC9Clip",
    s"S7_SSGFauxClip",
};
const int ClipNames_Length = ArraySize (ClipNames);

const string AmmoNames [] = {
    s"S7_BackpackToken",
    s"S7_9mmCartridges",
    s"S7_45ACPCartridges",
    s"S7_44MCartridges",
    s"S7_762x39Cartridges",
    s"S7_20gaShells",
    s"S7_12gaShells",
    s"S7_Cells",
    s"S7_FBSysCells",
    s"S7_Thumper_PExp",
    s"S7_Thumper_PFrag",
    s"S7_Thumper_PTherm",
    s"S7_Thumper_PFlare",
    s"S7_Thumper_PCluster",
    s"S7_Thumper_PNail",
    s"S7_Thumper_PNGas",
    s"S7_Thumper_PUnified",
};
const int AmmoNames_Length = ArraySize (AmmoNames);

const string S7_HW_2ModeWpns [] [4] = {
    {
        s"S7_TEC9",
        s"S7_TEC9_Burst",
        s"BrstFire",
        s"FullAuto"
    },
    {
        s"S7_AMG",
        s"S7_AMG_Burst",
        s"BrstFire",
        s"FullAuto"
    },
    {
        s"S7_PlasmaGun",
        s"S7_PlasmaGun_Semi",
        s"SemiAuto",
        s"FullAuto"
    },
    {
        s"S7_ManxCarbine",
        s"S7_ManxCarbine_Semi",
        s"SemiAuto",
        s"FullAuto"
    }
};
const int S7_HW_2ModeWpns_Length = ArraySize (S7_HW_2ModeWpns);