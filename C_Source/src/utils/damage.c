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
#include "utils/damage.h"

// Unblocked radius damage (i.e. pure distance check)
// AAAAAAAAAAAAAAAAAAAAAAAAAAGHHHHHHHHHHHHHHHHHHH
/*RadiusDMGNB_Data_t RadiusDMGNB_Data;

#define RDNB_MINTID (-32768)
#define RDNB_MAXTID (+32767)
void RadiusDMGNoBlock (vec3_k pos, int damage, int radius, int inflictorTID, string damageType, RDNB_Flags flags) {
    if (radius == 0)
        return;

    RadiusDMGNB_Data.pos = pos;
    RadiusDMGNB_Data.damage = damage;
    RadiusDMGNB_Data.radius = AbsA (radius);
    RadiusDMGNB_Data.inflictorTID = inflictorTID;
    RadiusDMGNB_Data.damageType = damageType;
    RadiusDMGNB_Data.flags = flags;

    for (int i = RDNB_MINTID; i <= RDNB_MAXTID; i++)
        GiveActorInventory (i, s"S7_RunRadiusDMGNoBlock", 1);
}

Script_C void S7_RadiusDMGNoBlock_Runner () {
    accum damage, splashFactor = GetCVarFixed (s"splashfactor");
    vec5_k pos = GetActorInfoVec (0);
    bool oldRadiusDMG = (RadiusDMGNB_Data.flags & RDNBF_OldRDMGPure)  | CheckFlag (0, s"oldRadiusDMG"); // Get some useful stuff (And make sure the OLDRADIUSDMG actor flag is respected)
    bool noDMGThrust  = (RadiusDMGNB_Data.flags & RDNBF_NoDMGThrust)  | CheckFlag (0, s"oldRadiusDMG") | CheckFlag (0, s"dontThrust") | CheckFlag (0, s"iceCorpse"); // Also respect the ICECORPSE flag here.
    bool ignoreHeight = (RadiusDMGNB_Data.flags & RDNBF_IgnoreHeight) | CheckFlag (0, s"oldRadiusDMG");

    if (RadiusDMGNB_Data.flags & RDNBF_DontHurtSrc && ActivatorTID () == RadiusDMGNB_Data.inflictorTID) // Skip if RDNBF_DontHurtSrc is set and we're the source
        return;

    if (!(CheckFlag (0, s"shootable") || CheckFlag (0, s"vulnerable")) || (CheckFlag (0, s"noRadiusDMG") && !(RadiusDMGNB_Data.flags & RDNBF_ForceDMG)))
        return;

    if (RadiusDMGNB_Data.flags & RDNBF_FullDMGRadius)
        damage = RadiusDMGNB_Data.damage;
    else {
        accum dx = AbsA (pos.x - RadiusDMGNB_Data.pos.x),
              dy = AbsA (pos.y - RadiusDMGNB_Data.pos.y);
        accum dist = dx > dy ? dx : dy;

        if (!ignoreHeight && RadiusDMGNB_Data.pos.z < pos.z || RadiusDMGNB_Data.pos.z >= pos.z + pos.h) {
            accum dz = (RadiusDMGNB_Data.pos.z > pos.z) ? (RadiusDMGNB_Data.pos.z - (pos.z + pos.h)) : (pos.z - RadiusDMGNB_Data.pos.z);

            if (dist <= pos.w)
                dist = dz;
            else {
                dist -= pos.w;
                dist = FixedSqrt (dist*dist + dz*dz);
            }
        }

        if (!oldRadiusDMG) {
            damage = RadiusDMGNB_Data.damage * (1k - dist * (1k / RadiusDMGNB_Data.radius));

            if (ActivatorTID () == RadiusDMGNB_Data.inflictorTID)
                damage *= splashFactor;
        } else {
            dist -= pos.w;

            if (dist >= RadiusDMGNB_Data.radius)
                return;

            damage = (RadiusDMGNB_Data.damage * (RadiusDMGNB_Data.radius - dist)) / RadiusDMGNB_Data.radius;
            damage *= splashFactor;
        }
    }

    damage = AbsA (damage);

    if (damage > 0)
        DamageActor (0, AAPTR_DEFAULT, RadiusDMGNB_Data.inflictorTID, AAPTR_DEFAULT, damage, RadiusDMGNB_Data.damageType);
    Log ("%k\n%d", pos.h, pos.h);

    if (!noDMGThrust && damage > 0) {
        accum thrust = damage * 0.5k / GetActorProperty (0, APROP_Mass), velz;

        if (ActivatorTID () == RadiusDMGNB_Data.inflictorTID)
            thrust *= 1k / splashFactor;

        velz = (pos.z + (pos.h >> 1) - RadiusDMGNB_Data.pos.z) * thrust;

        if (ActivatorTID () == RadiusDMGNB_Data.inflictorTID)
            velz *= 0.5k;
        else
            velz *= 0.8k;

        accum ang = atan2A (pos.x - RadiusDMGNB_Data.pos.x, pos.y - RadiusDMGNB_Data.pos.y);
        SetActorVelocity (0, CosA (ang) * thrust, SinA (ang) * thrust, velz, TRUE, FALSE);
    }
}*/