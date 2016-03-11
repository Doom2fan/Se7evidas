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

#ifndef WEAP_DATA_H
#define WEAP_DATA_H

#include <ACS_ZDoom.h>

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
};

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

#endif