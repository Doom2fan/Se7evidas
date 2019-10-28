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

extend class S7_BaseWeapon {
    enum S7_WeaponReadyFlags {
        S7WRF_ChangeModeWhileSprinting = 1 << 0,
        S7WRF_MeleeWhileSprinting      = 1 << 1,
    }

    enum S7_CheckButtonMode {
        CB_Down,
        CB_Up,
        CB_Pressed,
        CB_Released,
    }

    enum S7_A_FireBullets_Flags {
        S7_FB_SpeedOffs       = 1 << 0,
        S7_FB_UseAmmo         = 1 << 1,
        S7_FB_AbsoluteAngle   = 1 << 2,
        S7_FB_AbsolutePitch   = 1 << 3,
        S7_FB_PhysRelVelocity = 1 << 4,
    }
}