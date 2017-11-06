/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015-???  Chronos Ouroboros
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
#include "weapons/weapon_stuff.h"
#include "utils/damage.h"

// Scripts
/*#define PSICGFIREBOOL s"S7_PSICG_CanFire"
Script_C void S7_PSICG_FireTest () {
    accum puffX, puffY, puffZ;
    accum shooterX, shooterY, shooterZ;
    accum diff;

    puffX = GetActorX (0);
    puffY = GetActorY (0);
    puffZ = GetActorZ (0);

    SetActivator (0, AAPTR_TARGET);

    shooterX = GetActorX (0);
    shooterY = GetActorY (0);
    shooterZ = GetActorZ (0);

    diff = Distance2 (puffX, puffY, puffZ,
                      shooterX, shooterY, shooterZ);

    if (abs (diff) > 192)
        GiveInventory (PSICGFIREBOOL, 1);
    else
        TakeInventory (PSICGFIREBOOL, 0x7FFFFFFF);
}*/

/*Script_C void S7_BerserkWeapToggle () {
    if (!PlayerInGame (PLN))
        return;
    
    DisableWeapon (s"S7_BerserkWeap", s"", &PlayerData [PLN]);
}*/

/*Script_C void S7_AMGRadiusDamage (int damage, int radius) {
    Thing_ChangeTID (0, UniqueTID (-32768, 0));
    RadiusDMGNoBlock (GetActorPositionVec (0), damage, radius, ActivatorTID (), s"S7_Antimatter", RDNBF_ForceDMG);
}*/