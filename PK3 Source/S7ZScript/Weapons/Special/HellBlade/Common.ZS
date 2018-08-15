/*
 *  Se7evidas - A GZDoom mod
 *  Copyright (C) 2018 Chronos "phantombeta" Ouroboros
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

// Stuff that's common to all forms
class S7_HellhunterBladeLust : S7_Counter { default { Inventory.MaxAmount 150; } } // For special attacks
class S7_HellhunterBladeExperience : S7_Counter { } // For increasing affinity
class S7_HellhunterBladeAffinity : S7_Counter { default { Inventory.MaxAmount 10; } } // Controls the blade's damage

enum HellWarriorBladeForms {
    HELLBLADE_FORM1 = 1,
    HELLBLADE_FORM2 = 2,
    HELLBLADE_FORM3 = 3,
};

class S7_HBPuff_Base : Actor {
    default {
        Radius 0;
        Height 1;

        +PUFFONACTORS   +PUFFGETSOWNER +FORCEXYBILLBOARD +BLOODSPLATTER
        +NOEXTREMEDEATH
    }

    states {
    Spawn:
        TNT1 A 3 noDelay {
            A_GiveToTarget ("S7_HellhunterBladeExperience", 4);
            A_GiveToTarget ("S7_HellhunterBladeLust", 5);
        }
        stop;
    Crash:
        TNT1 A 3;
        stop;
    }
}